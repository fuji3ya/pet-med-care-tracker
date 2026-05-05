# Tend Pets Release Readiness Audit

Date: 2026-05-06

Goal:

```text
No-local-Mac path to TestFlight and App Store submission readiness.
```

## Current Status

Status: Yellow

Meaning:

- Product/source/docs are prepared for cloud iOS build.
- Windows-side static checks pass.
- GitHub Actions iPhone 15 Simulator build passes.
- Final green status requires external Apple/Codemagic/GitHub execution.

## Green

- Native SwiftUI source exists under `ios-app`.
- Browser product site and app UI reference exist under `prototype`.
- Canonical UI review target is fixed to iPhone 15 portrait, 393 x 852 pt.
- App Store metadata draft exists.
- Review notes include medical safety boundary.
- Privacy Policy, Terms, and Support pages exist in the sales site prototype.
- StoreKit product IDs align across Swift, StoreKit config, and metadata.
- Codemagic TestFlight and App Store workflows exist.
- GitHub Actions iPhone 15 Simulator build workflow exists.
- GitHub Actions iPhone 15 Simulator build passed on run `25407512172`.
- Qwen/Gemma no-local-Mac opinion is saved.

## Yellow

- `codemagic.yaml` still needs the real App Store Apple ID.
- `com.tendpets.app` must be confirmed or replaced in Apple Developer.
- Privacy/Terms/Support URLs must be deployed to a real public domain.
- Screenshots must come from the native SwiftUI app after simulator visual verification.
- StoreKit sandbox and notification behavior must be tested on Apple infrastructure.

## Red

- No signed IPA has been produced yet.
- No TestFlight build has been uploaded yet.
- No physical iPhone QA has been completed yet.
- No App Store review submission should be attempted before the above are done.

## Next Gate

1. Connect the GitHub repository to Codemagic.
2. Add App Store Connect API key and signing files.
3. Replace `REPLACE_WITH_APP_STORE_APPLE_ID`.
4. Run Codemagic: `ios-testflight`.

When steps 1-4 pass, status moves from Yellow to Green for TestFlight.

## GitHub Build Evidence

- Repository: `https://github.com/fuji3ya/pet-med-care-tracker`
- Visibility: private
- Workflow: `Tend Pets iOS Cloud Build`
- Successful run: `https://github.com/fuji3ya/pet-med-care-tracker/actions/runs/25407512172`
- Commit: `35082f39c9a5ef40968c6cada5c7465ea91e65b0`
- Result: iPhone 15 Simulator device created in CI, XcodeGen project generated, SwiftUI app built successfully.
