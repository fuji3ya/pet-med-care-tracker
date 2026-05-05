# Tend Pets iOS App

Native SwiftUI app scaffold for App Store-oriented development.

## What This Is

This is the start of the actual iPhone app implementation, separate from the browser sales prototype.

Included:

- SwiftUI app entry
- Native TabView navigation
- First-run onboarding with skip and Settings replay
- Today, Pets, Add Care, Records, Settings
- Local Codable persistence
- Local notification service
- StoreKit subscription manager
- Paywall skeleton
- Privacy Manifest
- Info.plist
- StoreKit local configuration draft
- App Store metadata draft
- Asset catalog structure
- Canonical iPhone 15 SwiftUI previews

## Generate Xcode Project

This folder uses XcodeGen.

On macOS:

```bash
cd REDACTED-PATH/generated/pet-med-care-tracker/ios-app
brew install xcodegen
xcodegen generate
open TendPets.xcodeproj
```

If the path is on macOS, use the mounted equivalent path instead of the Windows path.

## Live Simulator QA

Use `serve-sim` on macOS to review the real SwiftUI build through a browser:

```bash
cd /path/to/C/workspace/generated/pet-med-care-tracker/ios-app
xcodegen generate
open TendPets.xcodeproj
```

Run Tend Pets on an iPhone 15 simulator, then:

```bash
bash DevTools/start-serve-sim.sh "iPhone 15"
```

Open:

```text
http://localhost:3200
```

Full workflow:

```text
DevTools/serve-sim-qa.md
```

## Before App Store Submission

Required:

- Set `DEVELOPMENT_TEAM` in `project.yml`
- Replace placeholder App Store URLs
- Confirm subscription product IDs in App Store Connect
- Archive on macOS with Xcode
- Complete a live iPhone 15 simulator QA pass through `serve-sim`
- Test notifications on a physical iPhone
- Test StoreKit purchases in sandbox
- Replace generated app icons with final approved icons if needed
- Add real Privacy Policy and Terms pages

## Canonical Design Size

Use one baseline for design QA:

```text
iPhone 15 logical portrait, 393 x 852 pt
```

SwiftUI remains responsive, but first-pass UI review should use the `iPhone 15` previews in:

```text
TendPets/Views/PreviewDevices.swift
```

## Medical Safety

Do not add diagnosis, dosage recommendation, treatment recommendation, disease prevention claims, or emergency triage features.

Tend Pets is a records and reminders app only.
