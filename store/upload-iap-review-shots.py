"""Upload an App Store review screenshot to each subscription via the 3-phase
ASC flow (reserve -> PUT bytes -> commit). This moves the products out of
MISSING_METADATA toward READY_TO_SUBMIT.

Image: store/review-shots/pw_84.png (a real paywall frame from the device recording).
NOTE: ideally replace with a screenshot that shows live prices before final App
Store submission; this one is enough to flip product state and to submit.
"""
import time, json, hashlib, pathlib
import urllib.request, urllib.error
import jwt

KEY_ID = 'REDACTED-ASC-KEY-ID'
ISSUER_ID = 'REDACTED-ASC-ISSUER-ID'
P8 = pathlib.Path('REDACTED-PATH/AuthKey_REDACTED-ASC-KEY-ID.p8')
APP = '6774483480'
BASE = 'https://api.appstoreconnect.apple.com'
IMG = pathlib.Path(__file__).parent / 'review-shots' / 'paywall-750.png'


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


def get_subs():
    _, r = api('GET', f'/v1/apps/{APP}/subscriptionGroups?include=subscriptions&limit=10')
    return [i for i in r.get('included', []) if i['type'] == 'subscriptions']


def upload_for(sub_id, pid, data):
    # Replace any existing screenshot — a FAILED/incorrect one keeps the product
    # in MISSING_METADATA, so we delete and re-upload rather than skip.
    _, ex = api('GET', f'/v1/subscriptions/{sub_id}/appStoreReviewScreenshot')
    cur = ex.get('data') or {}
    if cur.get('id'):
        adv = cur['attributes'].get('assetDeliveryState', {}).get('state')
        if adv == 'COMPLETE':
            return f'{pid}: screenshot already COMPLETE'
        api('DELETE', f"/v1/subscriptionAppStoreReviewScreenshots/{cur['id']}")

    # 1. reserve
    st, r = api('POST', '/v1/subscriptionAppStoreReviewScreenshots', {
        'data': {'type': 'subscriptionAppStoreReviewScreenshots',
                 'attributes': {'fileName': 'paywall.png', 'fileSize': len(data)},
                 'relationships': {'subscription': {'data': {'type': 'subscriptions', 'id': sub_id}}}}})
    if st not in (200, 201):
        return f'{pid}: reserve {st} {r}'
    sid = r['data']['id']
    ops = r['data']['attributes']['uploadOperations']

    # 2. PUT bytes to each operation
    for op in ops:
        chunk = data[op['offset']:op['offset'] + op['length']]
        req = urllib.request.Request(op['url'], data=chunk, method=op['method'])
        for h in op.get('requestHeaders', []):
            req.add_header(h['name'], h['value'])
        try:
            urllib.request.urlopen(req, timeout=60).read()
        except urllib.error.HTTPError as e:
            return f'{pid}: PUT failed {e.code} {e.read()[:200]}'

    # 3. commit
    md5 = hashlib.md5(data).hexdigest()
    st, r = api('PATCH', f'/v1/subscriptionAppStoreReviewScreenshots/{sid}', {
        'data': {'type': 'subscriptionAppStoreReviewScreenshots', 'id': sid,
                 'attributes': {'uploaded': True, 'sourceFileChecksum': md5}}})
    return f'{pid}: commit {st} {"OK" if st in (200, 201) else r}'


def main():
    data = IMG.read_bytes()
    print(f'image {IMG.name} {len(data)} bytes')
    for s in get_subs():
        print(' ', upload_for(s['id'], s['attributes']['productId'], data))
    print('--- states ---')
    for s in get_subs():
        a = s['attributes']
        sh = api('GET', f"/v1/subscriptions/{s['id']}/appStoreReviewScreenshot")[1].get('data')
        print('  ', a['productId'], '->', a.get('state'), '| shot:', bool(sh))


if __name__ == '__main__':
    main()
