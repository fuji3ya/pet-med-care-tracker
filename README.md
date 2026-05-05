# Tend Pets

Pet medication and care tracker for iPhone.

This repository contains:

- native SwiftUI iOS app source under `ios-app`
- fixed iPhone 15 browser prototype under `prototype`
- App Store metadata and submission notes
- no-local-Mac cloud build path through Codemagic and GitHub Actions

## Canonical QA Device

Use one baseline for app UI review:

```text
iPhone 15 portrait, 393 x 852 pt
```

SwiftUI can adapt to other iPhone sizes, but layout decisions should first pass this reference.

## No-Local-Mac Release Path

Windows remains the editing environment.

Cloud macOS handles Apple-only work:

- GitHub Actions: iPhone 15 Simulator compile gate
- Codemagic: signed `.ipa`, TestFlight upload, App Store release workflow

Start here:

```text
ios-app/DevTools/no-local-mac-release-runbook.md
```

## Required Before TestFlight

- Apple Developer Program membership
- App Store Connect app record
- App Store Connect API key with App Manager access
- Apple Distribution certificate
- App Store provisioning profile for `com.tendpets.app`
- `APP_STORE_APPLE_ID` replaced in `codemagic.yaml`
- Codemagic integration name aligned with `codemagic.yaml`

## Release Safety

Tend Pets is a care record and reminder app.

Do not describe it as:

- diagnosis
- dosage recommendation
- treatment recommendation
- emergency triage
- veterinarian replacement

Use:

- reminders
- care logs
- vaccine history
- weight records
- vet visit notes
- follow your veterinarian's instructions
