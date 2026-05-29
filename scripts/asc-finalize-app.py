"""
ASC version finalizer — Tend Pets edition.

Adapted from apps/mirrorbite/scripts/asc-finalize-app.py (2026-05-28 ship retro).
Collapses the 3 manual steps that bit us during the Mirrorbite 1.0 ship into one
idempotent command. Run after each TestFlight build to drive the version all
the way to "Submit button active".

Steps (all idempotent — safe to re-run):
  1. Find the latest VALID build for the app.
  2. Attach it to the in-flight appStoreVersion (re-points if stuck on an old build).
  3. Attach it to the internal beta group (eas/codemagic submit silently skips this).
  4. Ensure a price schedule exists; if not, set the app to Free.
  5. Print a readiness report for every required submission field.

Prerequisite:
  Set TENDPETS_APP_APPLE_ID environment variable to the 10-digit App Apple ID
  from ASC -> Apps -> Tend Pets -> App Information -> Apple ID.

Usage:
  set TENDPETS_APP_APPLE_ID=1234567890
  python scripts/asc-finalize-app.py
  python scripts/asc-finalize-app.py --no-price   # skip price step
"""
from __future__ import annotations
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

# ─────────────────────────── per-app config ───────────────────────────
APP_APPLE_ID = os.environ.get("TENDPETS_APP_APPLE_ID")
if not APP_APPLE_ID:
    sys.stderr.write(
        "ERROR: set TENDPETS_APP_APPLE_ID env var.\n"
        "Find it at ASC -> Apps -> Tend Pets -> App Information -> Apple ID.\n"
    )
    sys.exit(1)

CONFIG = {
    "app_id": APP_APPLE_ID,
    # Internal Beta Tester group ID — auto-discovered on first run.
    # ASC creates a default "App Store Connect Users" internal group automatically.
    "internal_group_id": os.environ.get("TENDPETS_INTERNAL_GROUP_ID", ""),
    "base_territory": "USA",
    "free_price_point_id": "",
}
# ───────────────────────────────────────────────────────────────────────

BASE = "https://api.appstoreconnect.apple.com"
SCRIPT_DIR = Path(__file__).parent


def token() -> str:
    return subprocess.run(
        ["python", str(SCRIPT_DIR / "asc-jwt.py")],
        capture_output=True, text=True, check=True,
    ).stdout.strip()


def api(method: str, url: str, tok: str, body: dict | None = None, ok_empty=False):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {tok}")
    if body is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        if ok_empty and e.code in (404, 409):
            return {"__err": e.code}
        print(f"[HTTP {e.code}] {method} {url}\n{e.read().decode()[:600]}", file=sys.stderr)
        raise


def latest_valid_build(tok: str) -> dict:
    r = api("GET", f"{BASE}/v1/builds?filter[app]={CONFIG['app_id']}&sort=-uploadedDate&limit=10", tok)
    for b in r.get("data", []):
        if b["attributes"].get("processingState") == "VALID":
            return b
    raise RuntimeError("no VALID build found")


def inflight_version(tok: str) -> dict:
    r = api("GET", f"{BASE}/v1/apps/{CONFIG['app_id']}/appStoreVersions?limit=5", tok)
    editable = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
                "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW"}
    for v in r.get("data", []):
        if v["attributes"].get("appStoreState") in editable:
            return v
    return r["data"][0]


def step_attach_build_to_version(tok, ver_id, build) -> str:
    cur = api("GET", f"{BASE}/v1/appStoreVersions/{ver_id}/build", tok, ok_empty=True)
    cur_id = (cur.get("data") or {}).get("id")
    if cur_id == build["id"]:
        return f"already attached (build {build['attributes']['version']})"
    api("PATCH", f"{BASE}/v1/appStoreVersions/{ver_id}/relationships/build", tok,
        {"data": {"type": "builds", "id": build["id"]}})
    return f"attached build {build['attributes']['version']} (was {cur_id or 'none'})"


def discover_internal_group(tok) -> str:
    """Auto-find the internal beta group if env var not set."""
    if CONFIG["internal_group_id"]:
        return CONFIG["internal_group_id"]
    r = api("GET", f"{BASE}/v1/apps/{CONFIG['app_id']}/betaGroups?limit=20", tok)
    for g in r.get("data", []):
        attrs = g["attributes"]
        if attrs.get("isInternalGroup"):
            print(f"[auto] internal group = {attrs.get('name')} ({g['id']})", file=sys.stderr)
            CONFIG["internal_group_id"] = g["id"]
            return g["id"]
    raise RuntimeError("no internal beta group found — create one in ASC first")


def step_attach_build_to_group(tok, build) -> str:
    gid = discover_internal_group(tok)
    existing = api("GET", f"{BASE}/v1/betaGroups/{gid}/builds?limit=50", tok)
    if any(b["id"] == build["id"] for b in existing.get("data", [])):
        return "already in internal group"
    api("POST", f"{BASE}/v1/betaGroups/{gid}/relationships/builds", tok,
        {"data": [{"type": "builds", "id": build["id"]}]})
    return "attached to internal group"


def discover_free_price_point(tok) -> str:
    if CONFIG["free_price_point_id"]:
        return CONFIG["free_price_point_id"]
    terr = CONFIG["base_territory"]
    r = api("GET", f"{BASE}/v1/apps/{CONFIG['app_id']}/appPricePoints?filter[territory]={terr}&limit=200", tok)
    for p in r.get("data", []):
        cp = p["attributes"].get("customerPrice")
        if cp in ("0", "0.0", 0):
            return p["id"]
    raise RuntimeError("free price point not found")


def step_set_price_free(tok) -> str:
    sched = api("GET", f"{BASE}/v1/apps/{CONFIG['app_id']}/appPriceSchedule", tok, ok_empty=True)
    if sched.get("data"):
        mp = api("GET", f"{BASE}/v1/appPriceSchedules/{CONFIG['app_id']}/manualPrices?include=appPricePoint", tok, ok_empty=True)
        inc = {i["id"]: i["attributes"] for i in mp.get("included", [])}
        for p in mp.get("data", []):
            rel = p.get("relationships", {}).get("appPricePoint", {}).get("data", {})
            if inc.get(rel.get("id"), {}).get("customerPrice") in ("0", "0.0", 0):
                return "price already Free"
    pp = discover_free_price_point(tok)
    temp = "${price-free-1}"
    body = {
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": CONFIG["app_id"]}},
                "baseTerritory": {"data": {"type": "territories", "id": CONFIG["base_territory"]}},
                "manualPrices": {"data": [{"type": "appPrices", "id": temp}]},
            },
        },
        "included": [{
            "type": "appPrices", "id": temp,
            "attributes": {"startDate": None},
            "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": pp}}},
        }],
    }
    api("POST", f"{BASE}/v1/appPriceSchedules", tok, body)
    return "set price = Free"


def readiness(tok, ver_id) -> None:
    print("\n=== Readiness ===")
    v = api("GET", f"{BASE}/v1/appStoreVersions/{ver_id}", tok)["data"]["attributes"]
    print(f"  version {v['versionString']} / state={v['appStoreState']}")
    b = api("GET", f"{BASE}/v1/appStoreVersions/{ver_id}/build", tok, ok_empty=True).get("data")
    if b:
        bv = api("GET", f"{BASE}/v1/builds/{b['id']}", tok)["data"]["attributes"]
        print(f"  build {bv['version']} / {bv['processingState']}")
    locs = api("GET", f"{BASE}/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations", tok)["data"]
    for l in locs:
        la = l["attributes"]
        ss = api("GET", f"{BASE}/v1/appStoreVersionLocalizations/{l['id']}/appScreenshotSets", tok)["data"]
        total = 0
        for s in ss:
            c = api("GET", f"{BASE}/v1/appScreenshotSets/{s['id']}/appScreenshots", tok)["data"]
            total += len(c)
        print(f"  [{la['locale']}] desc={len(la.get('description') or '')}c screenshots={total}")
    rd = api("GET", f"{BASE}/v1/appStoreVersions/{ver_id}/appStoreReviewDetail", tok, ok_empty=True).get("data")
    print(f"  reviewDetail={'set' if rd else 'MISSING'}")
    sched = api("GET", f"{BASE}/v1/apps/{CONFIG['app_id']}/appPriceSchedule", tok, ok_empty=True).get("data")
    print(f"  price={'set' if sched else 'MISSING'}")


def main(argv: list[str]) -> int:
    tok = token()
    build = latest_valid_build(tok)
    ver = inflight_version(tok)
    ver_id = ver["id"]
    print(f"[target] version {ver['attributes']['versionString']} ({ver['attributes']['appStoreState']})")
    print(f"[build]  latest VALID = {build['attributes']['version']}")
    print("[1] " + step_attach_build_to_version(tok, ver_id, build))
    print("[2] " + step_attach_build_to_group(tok, build))
    if "--no-price" not in argv:
        print("[3] " + step_set_price_free(tok))
    readiness(tok, ver_id)
    print("\n[done] If all fields show set + screenshots>0, the Submit button should be active.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
