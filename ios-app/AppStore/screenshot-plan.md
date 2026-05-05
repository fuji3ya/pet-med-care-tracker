# App Store Screenshot Plan

Canonical design QA target:

```text
iPhone 15 portrait, 393 x 852 pt
```

App Store screenshots should be captured from the native SwiftUI app after the cloud simulator build passes.

## Required Story

1. Today
   - Shows due medication, Done/Snooze/Skip actions, and multi-pet context.
2. Add Care
   - Shows medication setup with pet, dose, time, repeat, and reminder copy.
3. Pet Profile
   - Shows active medication, next visit, and weight trend.
4. Records
   - Shows completed care history and vet summary sharing.
5. Paywall
   - Shows Plus/Family value, restore, renewal terms, and no-veterinary-advice boundary.

## Capture Rules

- Use real SwiftUI app, not browser prototype, for final App Store screenshots.
- Keep status bar consistent.
- Do not show debug text, placeholder URLs, build logs, or simulator controls.
- Do not claim diagnosis, dosage recommendation, treatment advice, or emergency support.
- Keep visual language consistent with the fixed iPhone 15 reference.

## Copy Overlay Direction

Use short, factual captions if screenshots are edited for the App Store:

- Never miss the next care step
- Log medication, food, weight, and visits
- Keep records ready for the vet
- Manage multiple pets calmly
- Upgrade when care gets more serious

Avoid:

- medical claims
- guaranteed health outcomes
- veterinarian replacement wording
