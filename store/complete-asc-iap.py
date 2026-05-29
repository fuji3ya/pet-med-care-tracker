"""Complete IAP metadata for the 4 existing Tend Pets subscriptions so they leave
MISSING_METADATA and the paywall actually works:
  1. en-US localization (display name + description)
  2. USD base price (via the matching subscription price point)
  3. 1-month FREE_TRIAL introductory offer (Apple has no 3-week option)

Idempotent: skips a step if it already exists. Prices are reversible in ASC.
"""
import time, json, pathlib, urllib.request, urllib.error, urllib.parse
import jwt

KEY_ID = 'REDACTED-ASC-KEY-ID'
ISSUER_ID = 'REDACTED-ASC-ISSUER-ID'
P8 = pathlib.Path('REDACTED-PATH/AuthKey_REDACTED-ASC-KEY-ID.p8')
APP = '6774483480'
BASE = 'https://api.appstoreconnect.apple.com'

# productId -> (display name <=30, description <=45, USD customer price)
META = {
    'tendpets.plus.monthly':   ("Plus Monthly",  "Unlimited pets, charts, PDF and export",  "4.99"),
    'tendpets.plus.yearly':    ("Plus Yearly",   "Unlimited pets, charts, PDF and export",  "35.99"),
    'tendpets.family.monthly': ("Family Monthly","Family sharing for multi-pet homes",      "6.99"),
    'tendpets.family.yearly':  ("Family Yearly", "Family sharing for multi-pet homes",      "49.99"),
}


def tok():
    return jwt.encode({'iss': ISSUER_ID, 'iat': int(time.time()), 'exp': int(time.time()) + 60 * 19,
                       'aud': 'appstoreconnect-v1'}, P8.read_text(), algorithm='ES256',
                      headers={'alg': 'ES256', 'kid': KEY_ID, 'typ': 'JWT'})


def api(method, path, body=None):
    url = BASE + path if path.startswith('/') else path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={'Authorization': f'Bearer {tok()}', 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=40) as r:
            txt = r.read().decode()
            return r.status, (json.loads(txt) if txt else {})
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')


def get_subs():
    _, r = api('GET', f'/v1/apps/{APP}/subscriptionGroups?include=subscriptions&limit=10')
    return [i for i in r.get('included', []) if i['type'] == 'subscriptions']


def ensure_availability(sub_id):
    _, r = api('GET', f'/v1/subscriptions/{sub_id}/subscriptionAvailability')
    if (r.get('data') or {}).get('id'):
        return 'availability exists'
    st, r = api('POST', '/v1/subscriptionAvailabilities', {
        'data': {'type': 'subscriptionAvailabilities',
                 'attributes': {'availableInNewTerritories': True},
                 'relationships': {
                     'subscription': {'data': {'type': 'subscriptions', 'id': sub_id}},
                     'availableTerritories': {'data': [{'type': 'territories', 'id': 'USA'}]}}}})
    return f'availability {st} {"OK (USA)" if st in (200,201) else r}'


def ensure_localization(sub_id, name, desc):
    _, r = api('GET', f'/v1/subscriptions/{sub_id}/subscriptionLocalizations?limit=10')
    if any(l['attributes'].get('locale') == 'en-US' for l in r.get('data', [])):
        return 'loc exists'
    st, r = api('POST', '/v1/subscriptionLocalizations', {
        'data': {'type': 'subscriptionLocalizations',
                 'attributes': {'name': name, 'description': desc, 'locale': 'en-US'},
                 'relationships': {'subscription': {'data': {'type': 'subscriptions', 'id': sub_id}}}}})
    return f'loc {st} {"OK" if st in (200,201) else r}'


def find_price_point(sub_id, usd):
    # Page through USA price points to find the one matching the target customer price.
    path = f'/v1/subscriptions/{sub_id}/pricePoints?filter[territory]=USA&limit=200'
    while path:
        _, r = api('GET', path)
        for pp in r.get('data', []):
            if pp['attributes'].get('customerPrice') == usd:
                return pp['id']
        path = (r.get('links') or {}).get('next')
    return None


def ensure_price(sub_id, usd):
    _, r = api('GET', f'/v1/subscriptions/{sub_id}/prices?limit=5')
    if r.get('data'):
        return 'price exists'
    pp = find_price_point(sub_id, usd)
    if not pp:
        return f'NO price point for {usd}'
    st, r = api('POST', '/v1/subscriptionPrices', {
        'data': {'type': 'subscriptionPrices',
                 'attributes': {'startDate': None, 'preserveCurrentPrice': False},
                 'relationships': {
                     'subscription': {'data': {'type': 'subscriptions', 'id': sub_id}},
                     'subscriptionPricePoint': {'data': {'type': 'subscriptionPricePoints', 'id': pp}}}}})
    return f'price {st} {"OK ($"+usd+")" if st in (200,201) else r}'


def ensure_trial(sub_id):
    _, r = api('GET', f'/v1/subscriptions/{sub_id}/introductoryOffers?limit=5')
    if r.get('data'):
        return 'trial exists'
    st, r = api('POST', '/v1/subscriptionIntroductoryOffers', {
        'data': {'type': 'subscriptionIntroductoryOffers',
                 'attributes': {'duration': 'ONE_MONTH', 'offerMode': 'FREE_TRIAL', 'numberOfPeriods': 1},
                 'relationships': {
                     'subscription': {'data': {'type': 'subscriptions', 'id': sub_id}},
                     'territory': {'data': {'type': 'territories', 'id': 'USA'}}}}})
    return f'trial {st} {"OK (1mo free)" if st in (200,201) else r}'


def ensure_group_localization():
    _, r = api('GET', f'/v1/apps/{APP}/subscriptionGroups?limit=10')
    gid = r['data'][0]['id']
    _, gl = api('GET', f'/v1/subscriptionGroups/{gid}/subscriptionGroupLocalizations?limit=5')
    if any(l['attributes'].get('locale') == 'en-US' for l in gl.get('data', [])):
        return 'group loc exists'
    st, r = api('POST', '/v1/subscriptionGroupLocalizations', {
        'data': {'type': 'subscriptionGroupLocalizations',
                 'attributes': {'name': 'Tend Pets', 'locale': 'en-US'},
                 'relationships': {'subscriptionGroup': {'data': {'type': 'subscriptionGroups', 'id': gid}}}}})
    return f'group loc {st} {"OK" if st in (200,201) else r}'


def main():
    print(' ', ensure_group_localization())
    subs = get_subs()
    print(f'found {len(subs)} subscriptions')
    for s in subs:
        pid = s['attributes']['productId']
        sid = s['id']
        if pid not in META:
            print(f'  {pid}: SKIP (unknown)'); continue
        name, desc, usd = META[pid]
        print(f'  {pid}:')
        print('     ', ensure_availability(sid))
        print('     ', ensure_localization(sid, name, desc))
        print('     ', ensure_price(sid, usd))
        print('     ', ensure_trial(sid))
    print('--- re-checking states ---')
    for s in get_subs():
        a = s['attributes']
        print('  ', a['productId'], '->', a.get('state'))


if __name__ == '__main__':
    main()
