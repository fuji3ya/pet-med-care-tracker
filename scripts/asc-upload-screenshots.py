"""
Upload App Store screenshots to App Store Connect via the API — Tend Pets edition.

Adapted from apps/mirrorbite/scripts/asc-upload-screenshots.py.
ASC screenshot upload is a 3-phase protocol per image:
  1. POST /v1/appScreenshots          -> reserve, returns uploadOperations[]
  2. PUT bytes to each operation URL  -> upload the file in chunks
  3. PATCH /v1/appScreenshots/{id}    -> commit with uploaded=true + md5

Display order = creation order, so we create them sequentially.

Prerequisite:
  Set TENDPETS_LOCALIZATION_ID environment variable. Find it after the App
  record is created in ASC and a 1.0 version exists. The localization ID
  is for the en-US locale of version 1.0.
  Auto-discovered if TENDPETS_APP_APPLE_ID is set.

Usage:
  set TENDPETS_APP_APPLE_ID=1234567890
  python scripts/asc-upload-screenshots.py screenshots/01_today.png screenshots/02_pets.png ...
"""
from __future__ import annotations
import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

APP_APPLE_ID = os.environ.get("TENDPETS_APP_APPLE_ID")
LOCALIZATION_ID = os.environ.get("TENDPETS_LOCALIZATION_ID")
DISPLAY_TYPE = "APP_IPHONE_65"  # 1242x2688 (iPhone 6.5"). ASC auto-scales to smaller.

BASE = "https://api.appstoreconnect.apple.com"
SCRIPT_DIR = Path(__file__).parent


def token() -> str:
    return subprocess.run(
        ["python", str(SCRIPT_DIR / "asc-jwt.py")],
        capture_output=True, text=True, check=True,
    ).stdout.strip()


def api(method: str, url: str, tok: str, body: dict | None = None) -> dict:
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
        print(f"[HTTP {e.code}] {method} {url}", file=sys.stderr)
        print(e.read().decode()[:1000], file=sys.stderr)
        raise


def discover_localization_id(tok: str) -> str:
    """Find the en-US localization ID for the in-flight 1.0 version."""
    if not APP_APPLE_ID:
        raise RuntimeError("TENDPETS_APP_APPLE_ID env var required to discover localization")
    versions = api("GET", f"{BASE}/v1/apps/{APP_APPLE_ID}/appStoreVersions?limit=5", tok)
    editable = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
                "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW"}
    for v in versions.get("data", []):
        if v["attributes"].get("appStoreState") in editable:
            locs = api("GET", f"{BASE}/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations", tok)
            for l in locs.get("data", []):
                if l["attributes"].get("locale") == "en-US":
                    print(f"[auto] localization en-US = {l['id']}", file=sys.stderr)
                    return l["id"]
    raise RuntimeError("no editable version/localization found")


def get_or_create_set(tok: str, loc_id: str) -> str:
    r = api("GET", f"{BASE}/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets", tok)
    for s in r.get("data", []):
        if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE:
            print(f"[set] reusing existing {DISPLAY_TYPE} set {s['id']}")
            return s["id"]
    body = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                }
            },
        }
    }
    r = api("POST", f"{BASE}/v1/appScreenshotSets", tok, body)
    sid = r["data"]["id"]
    print(f"[set] created {DISPLAY_TYPE} set {sid}")
    return sid


def reserve(tok: str, set_id: str, file_name: str, file_size: int) -> dict:
    body = {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": file_name, "fileSize": file_size},
            "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
            },
        }
    }
    return api("POST", f"{BASE}/v1/appScreenshots", tok, body)["data"]


def put_bytes(op: dict, blob: bytes) -> None:
    method = op["method"]
    url = op["url"]
    offset = op["offset"]
    length = op["length"]
    chunk = blob[offset:offset + length]
    req = urllib.request.Request(url, data=chunk, method=method)
    for h in op.get("requestHeaders", []):
        req.add_header(h["name"], h["value"])
    with urllib.request.urlopen(req, timeout=120) as r:
        if r.status not in (200, 201, 204):
            raise RuntimeError(f"upload chunk failed: {r.status}")


def commit(tok: str, screenshot_id: str, md5_hex: str) -> dict:
    body = {
        "data": {
            "type": "appScreenshots",
            "id": screenshot_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": md5_hex},
        }
    }
    return api("PATCH", f"{BASE}/v1/appScreenshots/{screenshot_id}", tok, body)


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: python scripts/asc-upload-screenshots.py <screenshot1.png> [<screenshot2.png> ...]", file=sys.stderr)
        print("(files in argument order = display order in App Store)", file=sys.stderr)
        return 2
    tok = token()
    loc_id = LOCALIZATION_ID or discover_localization_id(tok)
    set_id = get_or_create_set(tok, loc_id)

    for idx, path_str in enumerate(argv[1:], start=1):
        src = Path(path_str).expanduser().resolve()
        if not src.exists():
            print(f"[skip] missing {src}", file=sys.stderr)
            continue
        asc_name = f"{idx:02d}_{src.stem}.png"
        blob = src.read_bytes()
        size = len(blob)
        md5_hex = hashlib.md5(blob).hexdigest()
        reserved = reserve(tok, set_id, asc_name, size)
        sid = reserved["id"]
        ops = reserved["attributes"]["uploadOperations"]
        for op in ops:
            put_bytes(op, blob)
        res = commit(tok, sid, md5_hex)
        state = res["data"]["attributes"].get("assetDeliveryState", {})
        print(f"[ok] {asc_name} ({size} B) id={sid} state={state.get('state')}")
        time.sleep(1)

    print("\n[done] all screenshots uploaded. Verify in ASC -> 1.0 -> App Previews and Screenshots.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
