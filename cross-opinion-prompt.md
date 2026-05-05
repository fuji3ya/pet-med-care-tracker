# Cross Opinion Prompt: Qwen3 / Gemma4

Please review the Tend Pets iOS app direction and source scaffold as if preparing for App Store submission.

Runtime note:

Use local Ollama models for this review:

- Qwen: `qwen3.6:35b-a3b` or `qwen3:8b`
- Gemma: `gemma4:latest`

## Review Scope

Path:

`REDACTED-PATH\generated\pet-med-care-tracker`

Focus especially on:

- `ios-app`
- `prototype/ios-native.html`
- `prototype/ios-native.css`
- `prototype/ios-ui-correction.md`
- `prototype/device-size-standard.md`

## Product

Tend Pets is an iOS-first pet medication and care tracker.

Core jobs:

- Medication reminders
- Vaccine history
- Weight records
- Vet visit notes
- Food notes
- Multi-pet management
- Family care visibility
- Vet Summary PDF

Important safety boundary:

The app must not provide veterinary diagnosis, dosage recommendation, treatment advice, disease prevention claims, or emergency triage.

## Current Design Standard

Canonical iPhone target:

`iPhone 15 logical portrait, 393 x 852 pt`

Native UI should use:

- SwiftUI
- TabView
- NavigationStack
- Large titles
- Grouped List/Form
- Bottom tab bar
- Sheets / confirmation dialogs for contextual actions
- 44pt minimum touch targets

## Questions

1. Does the native iOS UI direction look appropriate for an App Store-quality iPhone app?
2. Are there any remaining web-like or non-native UI patterns?
3. Are the SwiftUI architecture and file boundaries reasonable for the MVP?
4. Are there App Store review risks, especially around medical claims, notifications, privacy, or subscriptions?
5. What must be fixed before attempting TestFlight?
6. What can safely wait until after the first TestFlight build?

Please return:

- Critical blockers
- High-priority fixes
- Medium-priority improvements
- Positive confirmations
- A concise final verdict
