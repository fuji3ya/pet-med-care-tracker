# Tend Pets Site Deploy Notes

The App Store listing needs public URLs for:

- Privacy Policy: `https://tendpets.app/privacy`
- Terms of Use: `https://tendpets.app/terms`
- Support: `https://tendpets.app/support`

Current local files:

- `privacy.html`
- `terms.html`
- `support.html`

## Simple Static Deploy

Deploy the `prototype` folder as a static site.

Recommended options:

- Cloudflare Pages
- GitHub Pages
- Netlify
- Vercel static project

## Required URL Mapping

If the host supports clean URLs, map:

- `/privacy` to `privacy.html`
- `/terms` to `terms.html`
- `/support` to `support.html`

If clean URLs are not configured yet, use:

- `https://tendpets.app/privacy.html`
- `https://tendpets.app/terms.html`
- `https://tendpets.app/support.html`

Then update:

- `ios-app/AppStore/metadata.md`
- App Store Connect listing fields
- any in-app external URL fields if added later

## Pre-Deploy Check

From the project root:

```powershell
python -m http.server 4173 --bind 127.0.0.1 --directory prototype
```

Then open:

```text
http://127.0.0.1:4173/index.html
http://127.0.0.1:4173/privacy.html
http://127.0.0.1:4173/terms.html
http://127.0.0.1:4173/support.html
```
