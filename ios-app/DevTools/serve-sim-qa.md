# serve-sim Simulator QA Workflow

Source:

- https://github.com/EvanBacon/serve-sim
- https://x.com/qingq77/status/2050155769803468999

## Decision

Use `serve-sim` as a development and QA bridge, not as an app dependency.

The browser prototype remains useful for fast layout iteration, but final UI judgment should move to the real SwiftUI app running in iOS Simulator. `serve-sim` streams that simulator to a browser, so AI tools can inspect and operate the native app instead of judging a static or browser-only mock.

## Why It Fits Tend Pets

- The canonical review target is iPhone 15 portrait.
- The product has many flows that need real navigation validation: Today, pet detail, Add Care, Records, Settings, paywall, notifications, and permission states.
- Native SwiftUI behavior matters: safe areas, dynamic type, tab bars, sheets, StoreKit views, keyboard behavior, and alert presentation.
- Simulator logs forwarded to the browser are useful for AI-assisted QA.

## Requirements

Run this on macOS:

- Xcode installed
- Xcode command line tools available through `xcrun simctl`
- Node.js 18+
- XcodeGen installed for this project

## One-Time Native Setup

```bash
cd /path/to/C/workspace/generated/pet-med-care-tracker/ios-app
brew install xcodegen
xcodegen generate
open TendPets.xcodeproj
```

In Xcode:

- Set the Apple Developer Team when signing is needed.
- Select an iPhone 15 simulator.
- Build and run Tend Pets.

## Start serve-sim

With the Tend Pets app running in the simulator:

```bash
npx --yes serve-sim "iPhone 15" -p 3200
```

Open:

```text
http://localhost:3200
```

If there is only one booted simulator, this also works:

```bash
npx --yes serve-sim
```

Stop helper processes:

```bash
npx --yes serve-sim --kill
```

List active streams:

```bash
npx --yes serve-sim --list
```

## QA Pass

Use one pass per build:

1. Confirm the simulator is iPhone 15 portrait.
2. Confirm Today is the first useful screen, not a marketing page.
3. Tap every bottom tab: Today, Pets, Add, Records, Settings.
4. Open a pet detail screen and return without losing tab context.
5. Create a medication reminder with valid time and repeat settings.
6. Trigger Done, Snooze, Skip, and Undo states.
7. Check notification permission disabled and enabled states.
8. Open Plus paywall, purchase sandbox product, restore purchase.
9. Review all sheets and alerts for clipped text at 393 x 852 pt.
10. Check dynamic type at at least one larger accessibility size.
11. Check that medical copy stays in record/reminder language only.
12. Export or preview records if that flow exists in the current build.

## AI Review Prompt

Use this after opening `http://localhost:3200` in an AI-controlled browser:

```text
Review this live iOS Simulator build of Tend Pets on iPhone 15 portrait.

Focus only on native iOS app quality:
- navigation correctness
- clipped or overlapping UI
- tap targets
- safe area and tab bar behavior
- sheet and alert presentation
- paywall clarity
- settings and notification flows
- medical safety copy

Do not judge the old browser mockup. Treat this simulator stream as source of truth.
Return concrete issues with screen, action, expected behavior, actual behavior, and severity.
```

## Do Not

- Do not ship `serve-sim` inside the app.
- Do not add it to the iOS target dependencies.
- Do not use it as proof that physical iPhone notification behavior is correct.
- Do not skip StoreKit sandbox or physical device testing.
