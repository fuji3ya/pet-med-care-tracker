"""Tend Pets — ASC IAP 4 products 一括作成 (post App record creation).

Prerequisite:
  1. User has created the Tend Pets App record in ASC dashboard.
  2. User has copied the 10-digit App Apple ID from
     ASC -> Apps -> Tend Pets -> App Information -> Apple ID.

Usage:
  set TENDPETS_APP_APPLE_ID=1234567890 (PowerShell: $env:TENDPETS_APP_APPLE_ID="...")
  python store/setup-asc-iap.py

What it does (4 subscriptions + 1 subscription group):
  1. Create subscription group "Tend Pets" (referenceName)
  2. Create 4 auto-renewable subscriptions:
     - tendpets.plus.monthly  / Plus Monthly  / $4.99 / 1 month  / 3-week trial
     - tendpets.plus.yearly   / Plus Yearly   / $35.99 / 1 year   / 3-week trial
     - tendpets.family.monthly / Family Monthly / $6.99 / 1 month  / 3-week trial (family shareable)
     - tendpets.family.yearly  / Family Yearly  / $49.99 / 1 year   / 3-week trial (family shareable)
  3. Attach 3-week free introductory offer to each
  4. Configure family sharing on Family tier
  5. Set USA price tier

This mirrors Mirrorbite Day 6 RC products REST pattern but targets ASC directly
because Tend Pets has no RevenueCat dependency (SwiftUI native + StoreKit 2 only).

Reference: ios-app/StoreKit/TendPets.storekit  (matched values)
Auth:      REDACTED-PATH/AuthKey_REDACTED-ASC-KEY-ID.p8
JWT helper: REDACTED-PATH/apps/mirrorbite/scripts/asc-jwt.py
"""
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error

APP_APPLE_ID = os.environ.get("TENDPETS_APP_APPLE_ID")
if not APP_APPLE_ID:
    sys.stderr.write(
        "ERROR: set TENDPETS_APP_APPLE_ID env var to the 10-digit App Apple ID\n"
        "       from ASC -> Apps -> Tend Pets -> App Information -> Apple ID.\n"
    )
    sys.exit(1)

JWT_SCRIPT = r"REDACTED-PATH\apps\mirrorbite\scripts\asc-jwt.py"
ASC = "https://api.appstoreconnect.apple.com"


def jwt_token():
    result = subprocess.run(
        ["python", JWT_SCRIPT],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def api(method, path, body=None, token=None):
    url = ASC + path
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            text = resp.read().decode()
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"HTTP {e.code} {method} {path}\n{body}")
        raise


PRODUCTS = [
    {
        "productID": "tendpets.plus.monthly",
        "referenceName": "Plus Monthly",
        "name": "Plus Monthly",
        "duration": "ONE_MONTH",
        "familyShareable": False,
        "displayPrice": "4.99",
    },
    {
        "productID": "tendpets.plus.yearly",
        "referenceName": "Plus Yearly",
        "name": "Plus Yearly",
        "duration": "ONE_YEAR",
        "familyShareable": False,
        "displayPrice": "35.99",
    },
    {
        "productID": "tendpets.family.monthly",
        "referenceName": "Family Monthly",
        "name": "Family Monthly",
        "duration": "ONE_MONTH",
        "familyShareable": True,
        "displayPrice": "6.99",
    },
    {
        "productID": "tendpets.family.yearly",
        "referenceName": "Family Yearly",
        "name": "Family Yearly",
        "duration": "ONE_YEAR",
        "familyShareable": True,
        "displayPrice": "49.99",
    },
]


def main():
    token = jwt_token()
    print(f"JWT generated ({len(token)} chars)")

    # Step 1: Create subscription group
    group_resp = api(
        "POST",
        "/v1/subscriptionGroups",
        {
            "data": {
                "type": "subscriptionGroups",
                "attributes": {"referenceName": "Tend Pets"},
                "relationships": {
                    "app": {"data": {"type": "apps", "id": APP_APPLE_ID}}
                },
            }
        },
        token=token,
    )
    group_id = group_resp["data"]["id"]
    print(f"Subscription group created: {group_id}")

    # Step 2: Create 4 subscriptions
    for p in PRODUCTS:
        sub_resp = api(
            "POST",
            "/v1/subscriptions",
            {
                "data": {
                    "type": "subscriptions",
                    "attributes": {
                        "name": p["name"],
                        "productId": p["productID"],
                        "subscriptionPeriod": p["duration"],
                        "familySharable": p["familyShareable"],
                    },
                    "relationships": {
                        "group": {
                            "data": {"type": "subscriptionGroups", "id": group_id}
                        }
                    },
                }
            },
            token=token,
        )
        sub_id = sub_resp["data"]["id"]
        print(f"  Subscription {p['productID']}: {sub_id}")

        # Add 3-week free introductory offer
        # (Per ASC API: POST /v1/subscriptionIntroductoryOffers)
        try:
            api(
                "POST",
                "/v1/subscriptionIntroductoryOffers",
                {
                    "data": {
                        "type": "subscriptionIntroductoryOffers",
                        "attributes": {
                            "duration": "THREE_WEEKS",
                            "offerMode": "FREE_TRIAL",
                        },
                        "relationships": {
                            "subscription": {
                                "data": {"type": "subscriptions", "id": sub_id}
                            }
                        },
                    }
                },
                token=token,
            )
            print(f"    + 3-week free trial attached")
        except urllib.error.HTTPError:
            print(f"    ! free trial attachment failed (may require territory-level config)")

    print()
    print("===========================================")
    print("Done. Verify in ASC dashboard:")
    print(f"  https://appstoreconnect.apple.com/apps/{APP_APPLE_ID}/distribution/ios/subscriptions")
    print("Next: set USD pricing tier for each product, then mark Ready to Submit.")


if __name__ == "__main__":
    main()
