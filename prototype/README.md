# Tend Pets Prototype

High-fidelity browser prototype for the iOS-first pet medication and care tracker.

## Run

```powershell
cd REDACTED-PATH\generated\pet-med-care-tracker\prototype
python -m http.server 4173 --bind 127.0.0.1
```

Open:

```text
http://127.0.0.1:4173
```

## Included

- Sales TOP page
- Native Simulator QA page
- Today
- Onboarding / Add Pet
- Add Care
- Pet Profile
- Calendar
- Records / Vet Summary
- Family
- Notification permission
- Notification disabled recovery
- Settings
- Plus Paywall
- Subscription purchase states
- Pricing section
- Generated image reference boards
- SwiftUI component map
- Asset production plan

## Design System Lock

- Brand: Tend Pets
- Aesthetic: Calm Clinical Companion
- Anchor: Care Ring around pet photos
- Background: `#FAF9F6`
- Primary: `#2F6F5E`
- Medicine: `#3E6FB6`
- Food: `#B8792D`
- Visit / vaccine: `#7A5DB5`

Keep new pages in this system unless deliberately redesigning the product.

## Native iOS Size Lock

Actual iPhone app UI should be reviewed in:

```text
ios-native.html
```

Canonical size:

```text
iPhone 15, 393 x 852 pt
```

The sales mockup may use decorative phone compositions, but implementation decisions should come from the native iOS reference.

## Native Simulator Source Of Truth

After SwiftUI changes, use the macOS `serve-sim` flow in:

```text
../ios-app/DevTools/serve-sim-qa.md
```

That live iOS Simulator stream supersedes browser mockups for final UI decisions.
