"""Set up internal TestFlight testing for Tend Pets:
1. Create an internal beta group (idempotent)
2. Attach the latest build
3. Add the team users as internal beta testers
"""
import time, sys, pathlib
import jwt, requests

KEY_ID = 'REDACTED-ASC-KEY-ID'
ISSUER_ID = 'REDACTED-ASC-ISSUER-ID'
P8 = pathlib.Path('REDACTED-PATH/AuthKey_REDACTED-ASC-KEY-ID.p8')
APP = '6774483480'
BASE = 'https://api.appstoreconnect.apple.com'
GROUP_NAME = 'Internal Testers'
TESTERS = [
    ('REDACTED-EMAIL', 'REDACTED-NAME', 'REDACTED-NAME'),
    ('REDACTED-EMAIL', 'REDACTED-NAME', 'REDACTED-NAME'),
]


def tok():
    return jwt.encode({'iss': ISSUER_ID, 'iat': int(time.time()),
                       'exp': int(time.time()) + 60 * 19, 'aud': 'appstoreconnect-v1'},
                      P8.read_text(), algorithm='ES256',
                      headers={'alg': 'ES256', 'kid': KEY_ID, 'typ': 'JWT'})


def H():
    return {'Authorization': f'Bearer {tok()}', 'Content-Type': 'application/json'}


# latest build
r = requests.get(f'{BASE}/v1/builds?filter[app]={APP}&limit=1&sort=-uploadedDate', headers=H())
build = r.json()['data'][0]
bid = build['id']
print(f"build {build['attributes']['version']} state={build['attributes']['processingState']} id={bid}")

# find or create internal group
r = requests.get(f'{BASE}/v1/apps/{APP}/betaGroups?limit=20', headers=H())
gid = None
for g in r.json().get('data', []):
    if g['attributes'].get('isInternalGroup'):
        gid = g['id']
        print(f"found internal group: {g['attributes'].get('name')} ({gid})")
        break

if not gid:
    payload = {
        'data': {
            'type': 'betaGroups',
            'attributes': {'name': GROUP_NAME, 'isInternalGroup': True},
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP}}},
        }
    }
    r = requests.post(f'{BASE}/v1/betaGroups', headers=H(), json=payload)
    print('create group status:', r.status_code)
    if r.status_code not in (200, 201):
        print(r.text[:800]); sys.exit(1)
    gid = r.json()['data']['id']
    print(f"created internal group ({gid})")

# attach build to group
r = requests.get(f'{BASE}/v1/betaGroups/{gid}/builds?limit=50', headers=H())
if any(b['id'] == bid for b in r.json().get('data', [])):
    print('build already in group')
else:
    r = requests.post(f'{BASE}/v1/betaGroups/{gid}/relationships/builds', headers=H(),
                      json={'data': [{'type': 'builds', 'id': bid}]})
    print('attach build status:', r.status_code, r.text[:300] if r.status_code >= 300 else 'OK')

# add testers
for email, fn, ln in TESTERS:
    payload = {
        'data': {
            'type': 'betaTesters',
            'attributes': {'email': email, 'firstName': fn, 'lastName': ln},
            'relationships': {'betaGroups': {'data': [{'type': 'betaGroups', 'id': gid}]}},
        }
    }
    r = requests.post(f'{BASE}/v1/betaTesters', headers=H(), json=payload)
    if r.status_code in (200, 201):
        print(f'added tester {email}')
    elif r.status_code == 409 or 'already exists' in r.text.lower():
        print(f'tester {email} already exists')
    else:
        print(f'tester {email} status {r.status_code}: {r.text[:300]}')

print('DONE')
