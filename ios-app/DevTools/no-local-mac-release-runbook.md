# No-Local-Mac Release Runbook

Goal: build, sign, and upload Tend Pets to TestFlight/App Store without owning, borrowing, or renting a local Mac.

## Decision

Primary route:

- Codemagic for signed `.ipa` builds and TestFlight/App Store upload.
- GitHub Actions macOS runner for every-PR iPhone simulator compile checks.

Fallback route:

- Xcode Cloud after the app record and repository are stable.
- Bitrise only if Codemagic becomes blocked by pricing, signing, or Apple integration issues.

Not current-route tools:

- `codex-plusplus-ios-simulator` is useful only on a local macOS machine with full Xcode and Codex++ installed. It embeds a mirrored iOS Simulator into Codex's right panel, so it can help local simulator UI QA later, but it does not remove the need for macOS/Xcode and does not replace GitHub Actions, Codemagic, TestFlight, or App Store Connect upload.

Why this route:

- Windows cannot run Xcode, iOS Simulator, or produce an App Store-signed iOS archive locally.
- Apple still requires the app binary to be built/uploaded through Xcode tooling, Transporter/altool, Xcode Cloud, or compatible CI that runs macOS/Xcode.
- Codemagic has first-class App Store Connect API key integration, signing file management, and TestFlight/App Store publishing.
- GitHub Actions is cheaper and already tied to GitHub, but iOS distribution signing is more fragile there, so it is better as a build-validation line first.

## Required Accounts

- Apple Developer Program membership.
- App Store Connect app record for Tend Pets.
- GitHub repository containing this project folder as the repository root.
- Codemagic account connected to that GitHub repository.

## Required Apple Values

- Bundle ID: `app.starvingeffort.tendpets`
- App Store Apple ID: numeric ID from App Store Connect > App Information.
- App Store Connect API key:
  - Key ID
  - Issuer ID
  - `.p8` private key, downloadable once
  - Access: App Manager
- Apple Distribution certificate.
- App Store provisioning profile for `app.starvingeffort.tendpets`.

## Repository Files Added

- `codemagic.yaml`
- `.github/workflows/tendpets-ios-cloud-build.yml`
- `ios-app/DevTools/no-local-mac-release-runbook.md`
- `ios-app/DevTools/qwen-gemma-no-local-mac-opinion.md`

## Codemagic Setup

1. Push this project as a GitHub repository with `codemagic.yaml` at the repository root.
2. In Codemagic, add the repository as an application.
3. Add an App Store Connect API key in Team settings > Developer Portal > Manage keys.
4. Name the integration `codemagic` or update `codemagic.yaml` to match the integration name.
5. Add or fetch signing files for `app.starvingeffort.tendpets`:
   - distribution type: `app_store`
   - bundle identifier: `app.starvingeffort.tendpets`
6. Replace `REPLACE_WITH_APP_STORE_APPLE_ID` in `codemagic.yaml`.
7. Run `ios-testflight`.
8. Confirm the build appears in App Store Connect > TestFlight after Apple processing.
9. Use `ios-app-store-release` only after metadata, screenshots, privacy answers, subscription products, and review notes are complete.

## GitHub Actions Setup

1. Push this project as a GitHub repository.
2. Open Actions.
3. Run `Tend Pets iOS Cloud Build` manually.
4. The workflow generates the Xcode project and builds on `macos-15`.
5. The workflow targets iPhone 15 Simulator only. If GitHub's hosted image removes that simulator, the workflow should fail loudly so the canonical QA device is not silently changed.

This workflow does not upload to App Store Connect. It is intentionally a low-risk compile gate.

## Release Gate

Do not run App Store release until all are true:

- GitHub Actions simulator build passes.
- Codemagic TestFlight build passes.
- TestFlight install works on a real iPhone.
- Local notification permission and reminder behavior are tested.
- StoreKit sandbox purchase and restore are tested.
- App Store screenshots exist for required device sizes.
- Privacy Policy URL and Terms URL are live.
- App Store Connect subscriptions match:
  - `tendpets.plus.monthly`
  - `tendpets.plus.yearly`
  - `tendpets.family.monthly`
  - `tendpets.family.yearly`
- Review notes state the app is a care log/reminder, not medical advice.

## Costs

Minimum external cost:

- Apple Developer Program: required.
- GitHub Actions: often enough for simulator compile checks, but macOS minutes may count against plan limits.
- Codemagic: cost depends on build minutes and plan; use for signed builds and release candidates, not every small edit.
- Xcode Cloud: included compute hours exist with Apple Developer Program, but setup is less direct from Windows-only work.

Cost-control rule:

- Use GitHub Actions for frequent compile checks.
- Use Codemagic for TestFlight and release candidates.
- Avoid App Store release workflow until the listing is complete.

## Known Risks

- The first Codemagic run may fail on signing until the App Store Connect API key, distribution certificate, and provisioning profile are aligned.
- Apple may reject `app.starvingeffort.tendpets` if the bundle identifier is unavailable; update both `project.yml` and `codemagic.yaml` together.
- App Store release automation cannot replace human review of screenshots, privacy answers, subscription setup, and medical-safety wording.
- GitHub-hosted macOS images change over time; the workflow logs Xcode and simulator availability for traceability.

## Tool Evaluation Notes

- `codex-plusplus-ios-simulator`: not useful for the current Windows-only path. Keep as an optional future QA tool if a macOS desktop environment becomes available.
