# Tend Pets App Store Submission Checklist

## Must Complete On Cloud macOS

- Push repository with `codemagic.yaml` at the project root
- Push `.github/workflows/tendpets-ios-cloud-build.yml`
- Run GitHub Actions: Tend Pets iOS Cloud Build
- Confirm iPhone 15 Simulator build passes, or confirm the logged fallback device if hosted images change
- Connect Codemagic to the repository
- Add App Store Connect API key to Codemagic
- Add or fetch Apple Distribution certificate and App Store provisioning profile
- Replace `REPLACE_WITH_APP_STORE_APPLE_ID` in `codemagic.yaml`
- Run Codemagic `ios-testflight`
- Confirm the build appears in App Store Connect > TestFlight
- Run iPhone 15 Simulator visual QA where a hosted simulator/browser bridge is available
- Verify first-run onboarding, Skip, Add first care, and Settings > Replay onboarding
- Run on a physical iPhone
- Test notification permission
- Test local reminders
- Test StoreKit sandbox purchases
- Archive with Release configuration
- Upload through Codemagic TestFlight/App Store workflows
- Capture App Store screenshots after the iPhone 15 layout pass is stable
- Confirm App Icon renders clearly on device home screen, Settings, Spotlight, and App Store preview

## App Store Connect

- Create app record: Tend Pets
- Primary category: Medical or Lifestyle
- Secondary category: Utilities
- Add Privacy Policy URL
- Add Support URL
- Configure subscriptions:
  - `tendpets.plus.monthly`
  - `tendpets.plus.yearly`
  - `tendpets.family.monthly`
  - `tendpets.family.yearly`
- Confirm subscription group display names and localized descriptions
- Add 7-day free trial if desired
- Fill app privacy labels based on final data behavior
- Add Terms of Use URL
- Add Support email or support site matching the in-app support link
- Make subscription prices and product ids match StoreKit configuration exactly
- Confirm restore purchase path before review submission

## Public URLs

- Deploy `prototype/privacy.html`
- Deploy `prototype/terms.html`
- Deploy `prototype/support.html`
- Confirm final public URLs match `metadata.md`
- Confirm support email `support@tendpets.app` can receive mail

## Review Safety

Do not claim:

- diagnosis
- dosage recommendation
- treatment advice
- emergency guidance
- disease prevention
- veterinarian replacement

Use:

- reminders
- records
- care logs
- vet visit notes
- follow your veterinarian's instructions

## In-App Readiness Added

- First-run onboarding and replay onboarding
- Care type-specific Add Care labels and validation
- Medication notification action handling
- Records generated from Done and Skip actions
- Native share path for summary text
- Local data export through the share sheet
- Destructive delete action behind confirmation
- Paywall terms, restore purchase, cancellation language, and no-veterinary-advice copy
- Privacy Policy, Terms, Support, and Medical disclaimer entries in Settings

## Current Build Status

This folder is source-ready and now has a no-local-Mac release route:

- GitHub Actions macOS simulator compile gate
- Codemagic signed TestFlight/App Store upload workflows
- No-local-Mac release runbook under `DevTools/no-local-mac-release-runbook.md`

The cloud workflows have not yet been executed because the repository, Apple Developer account, App Store Connect app record, and Codemagic integration still need to be connected.

Current readiness status is tracked in:

```text
../../release-readiness-audit.md
```
