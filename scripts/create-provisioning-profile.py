"""Create an App Store provisioning profile for Tend Pets, reusing the
team-wide iOS Distribution certificate (shared with Mirrorbite).

Output:
  .secrets/TendPets_AppStore.mobileprovision
  .secrets/ios_distribution.p12          (copied from Mirrorbite cert+key)
  .secrets/ios_distribution_password.txt (copied)
"""
import base64, json, pathlib, time
import jwt
import requests

KEY_ID = 'REDACTED-ASC-KEY-ID'
ISSUER_ID = 'REDACTED-ASC-ISSUER-ID'
CERT_ID = '6HR8JDH7HJ'              # team-wide iOS Distribution cert
BUNDLE_ID_RESOURCE = 'JHVY32X2U7'  # app.starvingeffort.tendpets

MB_SECRETS = pathlib.Path('REDACTED-PATH')
P8_PATH = MB_SECRETS / 'AuthKey_REDACTED-ASC-KEY-ID.p8'

SECRETS = pathlib.Path(__file__).parent.parent / '.secrets'
SECRETS.mkdir(exist_ok=True)


def jwt_token():
    return jwt.encode({
        'iss': ISSUER_ID, 'iat': int(time.time()),
        'exp': int(time.time()) + 60 * 19, 'aud': 'appstoreconnect-v1',
    }, P8_PATH.read_text(), algorithm='ES256',
       headers={'alg': 'ES256', 'kid': KEY_ID, 'typ': 'JWT'})


print('=== Create App Store provisioning profile for Tend Pets ===')
token = jwt_token()
payload = {
    'data': {
        'type': 'profiles',
        'attributes': {
            'name': 'Tend Pets App Store Profile',
            'profileType': 'IOS_APP_STORE',
        },
        'relationships': {
            'bundleId': {'data': {'type': 'bundleIds', 'id': BUNDLE_ID_RESOURCE}},
            'certificates': {'data': [{'type': 'certificates', 'id': CERT_ID}]},
        },
    }
}
r = requests.post(
    'https://api.appstoreconnect.apple.com/v1/profiles',
    headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
    json=payload)
print('Profile create status:', r.status_code)
data = r.json()
if r.status_code not in (200, 201):
    print('ERROR:', json.dumps(data, indent=2)[:1200])
    raise SystemExit(1)

profile_id = data['data']['id']
mobileprov = base64.b64decode(data['data']['attributes']['profileContent'])
mp_path = SECRETS / 'TendPets_AppStore.mobileprovision'
mp_path.write_bytes(mobileprov)
print(f'Saved profile: {mp_path} ({len(mobileprov)} bytes), id={profile_id}')
print('UUID:', data['data']['attributes'].get('uuid'))

# Copy the shared distribution cert + key (.p12) and password into Tend Pets secrets
p12_src = (MB_SECRETS / 'ios_distribution.p12').read_bytes()
pw_src = (MB_SECRETS / 'ios_distribution_password.txt').read_text().strip()
(SECRETS / 'ios_distribution.p12').write_bytes(p12_src)
(SECRETS / 'ios_distribution_password.txt').write_text(pw_src)
print(f'Copied p12 ({len(p12_src)} bytes) + password into {SECRETS}')
print('DONE')
