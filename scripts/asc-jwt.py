"""ASC API JWT generator + helper for Tend Pets.

Same Team (YXFS993Z4K) as Mirrorbite, so reuses the same Account Holder p8
key (mirrorbite-ci). Apple ASC API .p8 keys are Team-scoped, so one key
authorizes API operations on every app in the team.

Usage:
  python scripts/asc-jwt.py
  → prints a fresh JWT (20 min validity) to stdout.

Use:
  TOKEN=$(python scripts/asc-jwt.py)
  curl -H "Authorization: Bearer $TOKEN" https://api.appstoreconnect.apple.com/v1/...
"""
import time
import sys
import jwt
import pathlib

# Shared with Mirrorbite (Team-scope). Reference blueprint:
# wiki/concepts/line-i-app-infra-blueprint.md §再利用される credentials
KEY_PATH = pathlib.Path(r"REDACTED-PATH\AuthKey_REDACTED-ASC-KEY-ID.p8")
KEY_ID = "REDACTED-ASC-KEY-ID"
ISSUER_ID = "REDACTED-ASC-ISSUER-ID"

private_key = KEY_PATH.read_text()
payload = {
    "iss": ISSUER_ID,
    "iat": int(time.time()),
    "exp": int(time.time()) + 60 * 19,  # 20 min - 1 sec
    "aud": "appstoreconnect-v1",
}
headers = {
    "alg": "ES256",
    "kid": KEY_ID,
    "typ": "JWT",
}
token = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
sys.stdout.write(token)
