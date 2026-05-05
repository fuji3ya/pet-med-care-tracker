# Tend Pets Current Handoff - 2026-05-05

## Product

Tend Pets is an iOS-first pet medication and care tracker.

Core value:

- Prevent missed medication and care routines.
- Keep pet care visible for families.
- Keep vet-ready records for visits.
- Support multi-pet care across cats, dogs, rabbits, birds, reptiles, and small animals.

Medical boundary:

- Records and reminders only.
- No diagnosis, dosage recommendation, treatment recommendation, emergency triage, or veterinarian replacement claims.

## Canonical Device

All app UI review is locked to:

```text
iPhone 15 portrait, 393 x 852 pt
```

Browser native reference:

```text
REDACTED-PATH\generated\pet-med-care-tracker\prototype\ios-native.html
http://127.0.0.1:4173/ios-native.html?v=202605052009
```

Sales top page:

```text
REDACTED-PATH\generated\pet-med-care-tracker\prototype\index.html
http://127.0.0.1:4173/index.html
```

Simulator QA page:

```text
REDACTED-PATH\generated\pet-med-care-tracker\prototype\simulator-qa.html
http://127.0.0.1:4173/simulator-qa.html
```

## Current Browser Prototype Status

Implemented in:

```text
REDACTED-PATH\generated\pet-med-care-tracker\prototype\ios-native.js
REDACTED-PATH\generated\pet-med-care-tracker\prototype\ios-native.css
REDACTED-PATH\generated\pet-med-care-tracker\prototype\ios-native.html
```

Main tabs:

- Today
- Pets
- Add
- Records
- Settings

Detail routes:

- Pet Profile
- Reminder detail
- Calendar
- Vet Summary
- Paywall
- Disclaimer
- Record detail

Interactive states:

- Done
- Snooze
- Skip
- Undo
- Add Care validation
- Add pet demo
- Notification toggle/test
- Purchase/restore demo
- Export/share demo
- Delete demo reset
- Toasts and sheets

Recent UI fixes:

- Static rows are `div` unless truly actionable.
- Records route maps to Records tab.
- Back glyph fixed to `‹`.
- Text navigation actions styled separately.
- Tap/focus states strengthened.
- Add Care has inline validation.
- Pet detail title changed to `Pet Profile` to avoid duplicate naming.

## Onboarding

Browser onboarding is implemented.

Behavior:

- First launch shows onboarding unless `localStorage.tendPetsOnboardingComplete` is true.
- 4 steps explain why the app is needed and how it is used.
- `Skip for now` opens Today.
- `Continue` advances.
- `Back` goes to prior onboarding step.
- `Add first care` completes onboarding and opens Add Care.
- Second load skips onboarding.
- Settings includes `Replay onboarding`.

SwiftUI onboarding has also been ported.

Files:

```text
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\OnboardingView.swift
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\RootView.swift
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\SettingsView.swift
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\TendPets\Views\PreviewDevices.swift
```

SwiftUI behavior:

- Uses `@AppStorage("tendPetsOnboardingComplete")`.
- First-run onboarding appears as `fullScreenCover`.
- Skip routes to Today.
- Add first care routes to Add tab.
- Settings can replay onboarding.
- iPhone 15 preview exists.

## Native iOS Scaffold

Root:

```text
REDACTED-PATH\generated\pet-med-care-tracker\ios-app
```

Important files:

```text
project.yml
README.md
StoreKit\TendPets.storekit
AppStore\metadata.md
AppStore\submission-checklist.md
TendPets\App\AppState.swift
TendPets\App\TendPetsApp.swift
TendPets\Models\PetModels.swift
TendPets\Services\LocalStorage.swift
TendPets\Services\NotificationService.swift
TendPets\Services\SubscriptionStore.swift
TendPets\Views\TodayView.swift
TendPets\Views\PetsView.swift
TendPets\Views\AddCareView.swift
TendPets\Views\RecordsView.swift
TendPets\Views\SettingsView.swift
TendPets\Views\OnboardingView.swift
TendPets\Views\RootView.swift
TendPets\Views\DesignSystem.swift
```

Implemented native foundations:

- SwiftUI TabView
- Today/Add/Pets/Records/Settings
- Local persistence structure
- Local notifications with Done/Snooze action direction
- StoreKit subscription scaffold
- App icon asset catalog
- Privacy manifest
- App Store metadata draft
- Submission checklist

Not yet verified:

- Xcode build/archive
- SwiftUI preview render
- iPhone Simulator runtime
- Physical iPhone notification actions
- StoreKit sandbox purchases

Reason:

```text
Current environment is Windows; xcodebuild/Xcode Simulator are unavailable.
```

## serve-sim Integration

The X link was incorporated as a QA workflow, not an app dependency.

Docs:

```text
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\DevTools\serve-sim-qa.md
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\DevTools\start-serve-sim.sh
```

Mac command:

```bash
npx --yes serve-sim "iPhone 15" -p 3200
```

Purpose:

- Stream real iOS Simulator to browser.
- Let AI/browser tools inspect and control the native SwiftUI build.
- Treat live Simulator as source of truth over browser mockups.

## Qwen / Gemma Opinion

Local Ollama models confirmed:

```text
qwen3:8b
qwen3.6:35b-a3b
gemma4:latest
```

Opinion memo:

```text
REDACTED-PATH\generated\pet-med-care-tracker\prototype\qwen-gemma-ui-opinion-20260505.md
```

Shared verdict:

- Prototype is functional but needed more App Store-level polish.
- Highest-priority fixes were navigation consistency, fake button cleanup, feedback loops, validation, hierarchy, and accessibility/tap states.

Several recommendations were already applied.

## Current Verification

Browser verified:

- iPhone 15 native prototype loads.
- Onboarding first-run works.
- Onboarding Continue/Back/Add first care works.
- Second load skips onboarding.
- Settings > Replay onboarding works.
- Skip from replay works.
- No browser console errors observed after reload.

Static check:

```text
node --check REDACTED-PATH\generated\pet-med-care-tracker\prototype\ios-native.js
```

Status:

```text
Passed.
```

## Round 2 Debug Pass - 2026-05-05 Late

Additional Qwen/Gemma critique was collected and saved here:

```text
REDACTED-PATH\generated\pet-med-care-tracker\prototype\qwen-gemma-ui-opinion-20260505-round2.md
```

Implemented from the second pass:

- Calendar now uses a real May 2026 grid: weekday labels, leading blanks, and only days 1-31.
- Add Care now adapts labels and CTA by type:
  - Medicine: Dose / Save medication
  - Food: Amount / Save food reminder
  - Weight: Weight / Save weight reminder
  - Visit: Clinic / Save visit
- Medicine dose remains required, while Food/Weight/Visit do not show inappropriate dose validation.
- Saved care detail no longer creates an empty leading comma when non-medicine amount is blank.

Verified in the in-app browser:

- Today loads at the fixed iPhone 15 reference.
- Add tab opens.
- Food type replaces Dose with Amount.
- Calendar opens from Records and no longer contains day 32.
- Settings > Replay onboarding opens onboarding.
- Onboarding Skip returns to Today.
- Browser logs are empty.

Swift/Xcode:

```text
xcodebuild is not available in this Windows environment.
```

## Next Best Step

## App Store Readiness Pass - 2026-05-06

Goal is now explicitly:

```text
いつでも出品できる状態
```

New readiness tracker:

```text
REDACTED-PATH\generated\pet-med-care-tracker\app-store-readiness-plan.md
```

Native iOS work completed in this pass:

- SwiftUI Add Care now mirrors the browser prototype:
  - type-specific labels
  - type-specific validation
  - type-specific notification copy
  - type-specific save CTA
  - Medicine requires dose/instructions, while other types do not force dose
- Today and Pets have real empty states.
- Care card action buttons now have specific accessibility labels.
- Done and Skip now generate records automatically.
- Records now uses real `appState.records` where available and has an empty state.
- Vet Summary and Records now have native `ShareLink` paths.
- Settings now has:
  - local data export through share sheet
  - destructive delete confirmation
  - Privacy Policy
  - Terms of Use
  - Support link
  - Medical disclaimer
  - paywall message alert
- Paywall now has:
  - loading state
  - unavailable-products fallback
  - restore purchase
  - subscription renewal/cancellation language
  - no-veterinary-advice copy
  - close button
- StoreKit file now includes all product ids the code loads:
  - `tendpets.plus.monthly`
  - `tendpets.plus.yearly`
  - `tendpets.family.monthly`
  - `tendpets.family.yearly`
- XcodeGen marketing version is now `1.0.0`.

Windows verification:

```text
node --check prototype/ios-native.js
StoreKit JSON parse check
placeholder/TODO/empty-button search
```

Status:

```text
Passed on checks available from Windows.
Native compile still requires macOS/Xcode.
```

On macOS:

1. Open `REDACTED-PATH\generated\pet-med-care-tracker\ios-app` via the mounted Mac path.
2. Run:

```bash
xcodegen generate
open TendPets.xcodeproj
```

3. Select iPhone 15 Simulator.
4. Verify:
   - first-run onboarding
   - Skip
   - Add first care
   - Today/Pets/Add/Records/Settings tabs
   - Settings > Replay onboarding
   - Add Care validation
   - Done/Snooze/Skip/Undo
   - Paywall/restore
   - Medical disclaimer
5. Start serve-sim:

```bash
npx --yes serve-sim "iPhone 15" -p 3200
```

6. Open:

```text
http://localhost:3200
```

7. Run AI/browser-assisted simulator QA using:

```text
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\DevTools\serve-sim-qa.md
```

## Key Principle Going Forward

The browser prototype is now an interaction/design reference.

Final UI decisions should come from:

```text
SwiftUI app running on iPhone 15 Simulator via serve-sim
```

## No-Local-Mac Release Route - 2026-05-06

User does not want to buy, borrow, or use a local Mac/Mac mini.

Current decision:

- Primary signed build/upload path: Codemagic.
- Compile/simulator validation path: GitHub Actions macOS runner.
- Later optional Apple-native path: Xcode Cloud.

Added files:

```text
REDACTED-PATH\generated\pet-med-care-tracker\codemagic.yaml
REDACTED-PATH\generated\pet-med-care-tracker\.github\workflows\tendpets-ios-cloud-build.yml
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\DevTools\no-local-mac-release-runbook.md
REDACTED-PATH\generated\pet-med-care-tracker\ios-app\DevTools\qwen-gemma-no-local-mac-opinion.md
REDACTED-PATH\generated\pet-med-care-tracker\release-readiness-audit.md
REDACTED-PATH\generated\pet-med-care-tracker\prototype\privacy.html
REDACTED-PATH\generated\pet-med-care-tracker\prototype\terms.html
REDACTED-PATH\generated\pet-med-care-tracker\prototype\support.html
```

Qwen/Gemma shared opinion:

- Codemagic is the fastest practical route from this Windows workspace to TestFlight/App Store upload.
- GitHub Actions is better used as a low-risk iOS simulator compile gate first.
- Xcode Cloud is useful later, but less direct as the first path without local Xcode setup.

Remaining external setup:

- GitHub repository for this project folder.
- Apple Developer Program membership.
- App Store Connect app record.
- App Store Connect API key with App Manager access.
- Codemagic integration named `codemagic`, or update the integration name in `codemagic.yaml`.
- Apple Distribution certificate and App Store provisioning profile for `com.tendpets.app`.
- Replace `REPLACE_WITH_APP_STORE_APPLE_ID` in `codemagic.yaml`.

Latest local verification:

- YAML lint passed for Codemagic and GitHub Actions workflows.
- Browser site routes return 200 for index, privacy, terms, support, native UI, and simulator QA.
- StoreKit product IDs align across Swift, StoreKit config, and metadata.
- No Swift TODO/FIXME/fatalError/localhost debug strings found.

GitHub status:

- Private repository created: `https://github.com/fuji3ya/pet-med-care-tracker`
- Initial source pushed to `main`.
- GitHub Actions workflow ran successfully:
  - Run: `https://github.com/fuji3ya/pet-med-care-tracker/actions/runs/25407592592`
  - Commit: `5da18a84ba6117eb77f6be481c137796b5656276`
  - Result: iPhone 15 Simulator build passed on GitHub macOS runner.
