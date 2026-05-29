"""Fix the real bug: Tend Pets subscriptions were available/priced in only USA (1
territory) while the app ships in all 175 -> stuck in MISSING_METADATA. Mirrorbite
(shipped) has all 175 priced -> READY_TO_SUBMIT.

This expands every subscription to all territories and sets Apple's OWN equalized
prices (from the price point /equalizations endpoint, NOT guessed values) so the
products reach READY_TO_SUBMIT and the paywall actually serves.

Runs plus.monthly first and prints its resulting state; only continues to the
other products if that one flips out of MISSING_METADATA.
"""
import time, json, pathlib, sys
import urllib.request, urllib.error
import jwt

KEY_ID = 'REDACTED-ASC-KEY-ID'
ISSUER_ID = 'REDACTED-ASC-ISSUER-ID'
P8 = pathlib.Path('REDACTED-PATH/AuthKey_REDACTED-ASC-KEY-ID.p8')
APP = '6774483480'
BASE = 'https://api.appstoreconnect.apple.com'


def tok():
    return jwt.encode({'iss': ISSUER_ID, 'iat': int(time.time()), 'exp': int(time.time()) + 60 * 18,
                       'aud': 'appstoreconnect-v1'}, P8.read_text(), algorithm='ES256',
                      headers={'alg': 'ES256', 'kid': KEY_ID, 'typ': 'JWT'})


def api(method, path, body=None):
    url = BASE + path if path.startswith('/') else path
    data = json.dumps(body).encode() if body is not None else None
    last = None
    for attempt in range(4):
        req = urllib.request.Request(url, data=data, method=method,
                                     headers={'Authorization': f'Bearer {tok()}', 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                t = r.read().decode()
                return r.status, (json.loads(t) if t else {})
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read().decode() or '{}')
        except (TimeoutError, urllib.error.URLError, OSError) as e:
            last = e
            time.sleep(2 * (attempt + 1))
    raise last


def paged(path):
    out = []
    while path:
        _, r = api('GET', path)
        out += r.get('data', [])
        nxt = (r.get('links') or {}).get('next')
        path = nxt.replace(BASE, '') if nxt else None
    return out


def all_territories():
    return [t['id'] for t in paged('/v1/territories?limit=200')]


def fix_availability(sid, all_ids):
    _, av = api('GET', f'/v1/subscriptions/{sid}/subscriptionAvailability')
    aid = (av.get('data') or {}).get('id')
    if aid:
        have = {t['id'] for t in paged(f'/v1/subscriptionAvailabilities/{aid}/availableTerritories?limit=200')}
        missing = [i for i in all_ids if i not in have]
        if not missing:
            return 'avail: already all'
        st, r = api('POST', f'/v1/subscriptionAvailabilities/{aid}/relationships/availableTerritories',
                    {'data': [{'type': 'territories', 'id': i} for i in missing]})
        if st in (200, 201, 204):
            return f'avail: +{len(missing)} territories'
        # fallback: recreate
        api('DELETE', f'/v1/subscriptionAvailabilities/{aid}')
    st, r = api('POST', '/v1/subscriptionAvailabilities', {
        'data': {'type': 'subscriptionAvailabilities', 'attributes': {'availableInNewTerritories': True},
                 'relationships': {'subscription': {'data': {'type': 'subscriptions', 'id': sid}},
                                   'availableTerritories': {'data': [{'type': 'territories', 'id': i} for i in all_ids]}}}})
    return f'avail: recreate {st} {"" if st in (200,201) else r}'


def fix_prices(sid):
    pr = api('GET', f'/v1/subscriptions/{sid}/prices?include=subscriptionPricePoint,territory&limit=200')[1]
    priced = set()
    for p in pr.get('data', []):
        terr = p.get('relationships', {}).get('territory', {}).get('data', {})
        if terr:
            priced.add(terr.get('id'))
    base_pts = [i for i in pr.get('included', []) if i['type'] == 'subscriptionPricePoints']
    if not base_pts:
        return 'price: no base point'
    base = base_pts[0]['id']
    eq = paged(f'/v1/subscriptionPricePoints/{base}/equalizations?limit=200')
    created = failed = 0
    for pt in eq:
        terr = pt.get('relationships', {}).get('territory', {}).get('data', {}).get('id')
        if terr and terr in priced:
            continue
        st, r = api('POST', '/v1/subscriptionPrices', {
            'data': {'type': 'subscriptionPrices', 'attributes': {'startDate': None, 'preserveCurrentPrice': False},
                     'relationships': {'subscription': {'data': {'type': 'subscriptions', 'id': sid}},
                                       'subscriptionPricePoint': {'data': {'type': 'subscriptionPricePoints', 'id': pt['id']}}}}})
        if st in (200, 201):
            created += 1
        else:
            failed += 1
    return f'price: +{created} (fail {failed})'


def state_of(pid):
    r = api('GET', f'/v1/apps/{APP}/subscriptionGroups?include=subscriptions&limit=10')[1]
    for s in r.get('included', []):
        if s['type'] == 'subscriptions' and s['attributes']['productId'] == pid:
            return s['attributes'].get('state'), s['id']
    return None, None


def process(pid, all_ids):
    _, sid = state_of(pid)
    print(f'[{pid}]')
    print('  ', fix_availability(sid, all_ids), flush=True)
    print('  ', fix_prices(sid), flush=True)
    time.sleep(8)
    st, _ = state_of(pid)
    print(f'  -> state={st}', flush=True)
    return st


def main():
    all_ids = all_territories()
    print(f'{len(all_ids)} territories')
    first = process('tendpets.plus.monthly', all_ids)
    if first == 'MISSING_METADATA':
        print('plus.monthly still MISSING_METADATA after full territory fix — STOP, needs investigation (not just territories).')
        return
    for pid in ['tendpets.plus.yearly', 'tendpets.family.monthly', 'tendpets.family.yearly']:
        process(pid, all_ids)
    print('--- final ---')
    for pid in ['tendpets.plus.monthly', 'tendpets.plus.yearly', 'tendpets.family.monthly', 'tendpets.family.yearly']:
        print('  ', pid, '->', state_of(pid)[0])


if __name__ == '__main__':
    main()
