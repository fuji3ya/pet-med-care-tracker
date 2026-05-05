# Qwen/Gemma UI Opinion Round 2 - 2026-05-05

Context: Tend Pets is fixed to iPhone 15 portrait, 393 x 852 pt. The browser prototype now includes first-run onboarding, Today actions, Pets, Add Care, Records, Calendar, Settings, paywall, vet summary export, and native-style sheets.

## Opinions Collected

- Qwen: `qwen3:8b` was used after `qwen3.6:35b-a3b` timed out during loading/inference.
- Gemma: `gemma4:latest` returned a second opinion after a shorter prompt.
- Both larger first attempts timed out at roughly 3 minutes, so the prompt was shortened for practical local review.

## Shared Remaining Risks

1. Accessibility is still not release-ready: every icon/tab/action needs clear VoiceOver labels, logical focus order, and contrast checks.
2. Empty states need paid-quality copy and actions for first use, no pets, no records, no reminders, and no subscription.
3. Date/time and units need native controls: time picker, calendar picker, timezone handling, kg/lb weight units, and input formatting.
4. Records and vet export need a more credible path: chronological sorting, missed/skipped markers, share sheet, CSV/PDF choices, and print-safe layout.
5. Paywall must become a complete App Store flow: restore, cancellation language, subscription terms, family sharing framing, purchase failure states, and post-purchase route.
6. Add Care should keep adapting per care type, including labels, validation, hints, examples, and saved record detail strings.
7. Premium feel still needs native-feeling transitions, pressed states, undo states, and fewer abrupt hard cuts.
8. Settings needs a clearer information architecture: reminders, sharing, data/privacy, subscription, app/about, and support should not feel like a demo list.

## Applied From This Round

- Rebuilt Calendar so May 2026 cannot show invalid days 32-35.
- Added weekday labels and blank leading cells for a real month grid.
- Made Add Care labels and save CTA adapt to Medicine, Food, Weight, and Visit.
- Made medicine dose required through a shared care-type config, while other care types avoid inappropriate dose validation.
- Saved reminder details now omit empty leading commas for non-medicine care.

## Verified

- `node --check prototype/ios-native.js`
- In-app browser DOM/interaction QA:
  - Today loads.
  - Add tab opens.
  - Food changes Dose to Amount and Save medication to Save food reminder.
  - Calendar opens from Records and no longer contains day 32.
  - Calendar weekday labels render.
  - Settings replay onboarding works.
  - Onboarding Skip returns to Today.
  - Browser console logs are empty.

## Next Fix Queue

1. Add empty states for no reminders/no records/no pets.
2. Replace generic time select with a stronger native picker mock and time-zone copy.
3. Add accessibility labels to browser prototype controls and mirror them in SwiftUI.
4. Expand paywall states and subscription/legal copy.
5. Add PDF/share preview fidelity for vet handoff.
