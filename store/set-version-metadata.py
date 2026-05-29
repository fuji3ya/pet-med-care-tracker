"""Populate the App Store version (1.0) en-US metadata and attach the latest build.
Fixes the live BLOCKER: version description empty. Pulls the description from
metadata.md so the copy stays single-sourced. Idempotent.
"""
import time, json, re, pathlib
import urllib.request, urllib.error
import jwt

KEY_ID = 'REDACTED-ASC-KEY-ID'
ISSUER_ID = 'REDACTED-ASC-ISSUER-ID'
P8 = pathlib.Path('REDACTED-PATH/AuthKey_REDACTED-ASC-KEY-ID.p8')
APP = '6774483480'
BASE = 'https://api.appstoreconnect.apple.com'
META = pathlib.Path(__file__).parent.parent / 'ios-app' / 'AppStore' / 'metadata.md'

KEYWORDS = "pet medication,vaccine reminder,vet records,medication tracker,pet care,pet health,weight log"
PROMO = "Keep pet medication, vet visits, vaccines, weight, food notes, and family care routines organized in one calm iOS app."
SUPPORT_URL = "https://tendpets.starving-effort.com/support"
MARKETING_URL = "https://tendpets.starving-effort.com/"


def tok():
    return jwt.encode({'iss': ISSUER_ID, 'iat': int(time.time()), 'exp': int(time.time()) + 60 * 18,
                       'aud': 'appstoreconnect-v1'}, P8.read_text(), algorithm='ES256',
                      headers={'alg': 'ES256', 'kid': KEY_ID, 'typ': 'JWT'})


def api(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={'Authorization': f'Bearer {tok()}', 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=40) as r:
            t = r.read().decode()
            return r.status, (json.loads(t) if t else {})
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')


def extract_description():
    text = META.read_text(encoding='utf-8')
    m = re.search(r'##\s*Description\s*\n(.*?)(?:\n##\s|\Z)', text, re.S)
    return m.group(1).strip() if m else ''


def main():
    desc = extract_description()
    assert len(desc) > 50, "description extraction failed"
    print(f'description: {len(desc)} chars')

    # 1. find editable IOS version
    _, r = api('GET', f'/v1/apps/{APP}/appStoreVersions?filter[platform]=IOS&limit=10&include=appStoreVersionLocalizations')
    editable = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"}
    vers = r.get('data', [])
    v = next((x for x in vers if x['attributes'].get('appStoreState') in editable), vers[0])
    vid = v['id']
    print(f"version {v['attributes'].get('versionString')} ({v['attributes'].get('appStoreState')}) id={vid}")

    # 2. en-US localization
    loc = next((i for i in r.get('included', [])
                if i['type'] == 'appStoreVersionLocalizations' and i['attributes'].get('locale') == 'en-US'), None)
    attrs = {'description': desc, 'keywords': KEYWORDS, 'promotionalText': PROMO,
             'supportUrl': SUPPORT_URL, 'marketingUrl': MARKETING_URL}
    if loc:
        st, rr = api('PATCH', f"/v1/appStoreVersionLocalizations/{loc['id']}", {
            'data': {'type': 'appStoreVersionLocalizations', 'id': loc['id'], 'attributes': attrs}})
        print('localization PATCH', st, 'OK' if st in (200, 201) else rr)
    else:
        attrs['locale'] = 'en-US'
        st, rr = api('POST', '/v1/appStoreVersionLocalizations', {
            'data': {'type': 'appStoreVersionLocalizations', 'attributes': attrs,
                     'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': vid}}}}})
        print('localization POST', st, 'OK' if st in (200, 201) else rr)

    # 3. attach latest VALID build to the version
    _, br = api('GET', f'/v1/builds?filter[app]={APP}&limit=1&sort=-uploadedDate')
    builds = br.get('data', [])
    if builds:
        bid = builds[0]['id']
        _, cur = api('GET', f'/v1/appStoreVersions/{vid}/build')
        if (cur.get('data') or {}).get('id') == bid:
            print('build already attached')
        else:
            st, rr = api('PATCH', f'/v1/appStoreVersions/{vid}/relationships/build', {
                'data': {'type': 'builds', 'id': bid}})
            print('attach build', builds[0]['attributes'].get('version'), st, 'OK' if st in (200, 204) else rr)

    print('DONE')


if __name__ == '__main__':
    main()
