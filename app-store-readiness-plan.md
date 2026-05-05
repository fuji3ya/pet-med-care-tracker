# Tend Pets App Store Readiness Plan

Goal: make Tend Pets ready to submit at any time, with remaining work clearly separated between work that can be completed on Windows and work that requires macOS, Xcode, App Store Connect, StoreKit sandbox, or a physical iPhone.

## Current Target

- Product: Tend Pets, pet medication and care tracker
- Platform: iOS
- Canonical UI QA device: iPhone 15 portrait
- Pricing direction: Plus subscription, monthly/yearly, with family tier
- Submission posture: utility app, not veterinary medical advice

## Ready Before Submission

- First-run onboarding explains why the app exists and can be skipped on repeat use.
- Today supports Done, Snooze, Skip, and notification action state updates.
- Add Care supports Medication, Food, Weight, Visit, and Vaccine.
- Add Care labels, validation, notification copy, and CTA adapt to the selected care type.
- Records can show automatically generated completed/skipped care records.
- Vet summary has a preview and native share path.
- Settings includes notifications, subscription, restore, onboarding replay, export entry, disclaimer, privacy, terms, support, and delete confirmation.
- Paywall includes restore, subscription terms, cancellation language, and medical disclaimer copy.
- Info.plist includes notification usage and non-exempt encryption declaration.
- Privacy manifest declares no tracking and UserDefaults usage.
- Browser prototype is fixed to iPhone 15, 393 x 852 pt.

## No-Local-Mac Release Route

Primary route:

- Codemagic builds the signed `.ipa` and uploads to TestFlight/App Store Connect.
- GitHub Actions macOS validates the SwiftUI project on an iPhone 15 Simulator target before release builds.
- Xcode Cloud remains a later Apple-native option, but it is not the fastest first route from this Windows-only workspace.

Added files:

- `codemagic.yaml`
- `.github/workflows/tendpets-ios-cloud-build.yml`
- `ios-app/DevTools/no-local-mac-release-runbook.md`
- `ios-app/DevTools/qwen-gemma-no-local-mac-opinion.md`

## Remaining Release Blockers

1. GitHub Actions macOS simulator compile verification.
2. Codemagic signed TestFlight build.
3. iPhone 15 Simulator visual QA through Xcode, GitHub-hosted logs, or serve-sim where available.
4. StoreKit sandbox purchase, restore, pending, failure, and entitlement testing.
5. Physical iPhone notification permission and notification action testing.
6. Final App Store Connect subscription setup matching product ids:
   - `tendpets.plus.monthly`
   - `tendpets.plus.yearly`
   - `tendpets.family.monthly`
   - `tendpets.family.yearly`
7. Final privacy policy and terms URLs.
8. Support email or support page must exist before submission.
9. Production cloud/sync decision: if added, update PrivacyInfo.xcprivacy and App Store privacy answers.
10. App icon final review on real iOS home screen.
11. Screenshots for required App Store device sizes.

## QA Commands

Windows static checks:

```powershell
node --check REDACTED-PATH\generated\pet-med-care-tracker\prototype\ios-native.js
where.exe xcodebuild
```

macOS build:

```bash
cd ios-app
xcodegen generate
xcodebuild -scheme TendPets -destination 'platform=iOS Simulator,name=iPhone 15' build
```

GitHub Actions cloud simulator build:

```text
Actions > Tend Pets iOS Cloud Build > Run workflow
```

Codemagic TestFlight build:

```text
Codemagic > Tend Pets > ios-testflight
```

serve-sim QA:

```bash
npx --yes serve-sim "iPhone 15" -p 3200
```

## Next Implementation Queue

1. Replace placeholder export/delete actions with actual local data export and reset behavior.
2. Add edit pet and add pet flows.
3. Add calendar/month record view in SwiftUI.
4. Add in-app subscription management deep link after purchase.
5. Add screenshot capture checklist and App Store description final copy.
