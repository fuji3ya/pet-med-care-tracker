# Tend Pets UI/UX Audit

Updated: 2026-05-05

## Pass 1 Findings And Fixes

### Fixed

| Issue | Why it mattered | Fix |
|---|---|---|
| Mobile hero spacing was tight between feature chips and phone mockup | The first viewport felt cramped for a paid app sales page | Added mobile-only spacing before the phone composition |
| Major interactive targets were below iOS 44pt guidance | Medication actions must be thumb-friendly and accessible | Raised app buttons, tabs, brand target, and hero CTAs |
| Section anchors landed too close to the sticky header | Clicking nav could make headings feel clipped | Added section scroll margin |
| Screen thumbnails were visually present but unnamed | The expanded page set was harder to scan | Added labels under each phone thumbnail |
| Today screen was static | Core UX should demonstrate the paid-quality completion loop | Added Done, Snooze, Skip, and Undo state changes |
| Favicon request created browser noise | Prototype should load cleanly | Added a project favicon |

## Pass 2 Findings And Fixes

| Issue | Why it mattered | Fix |
|---|---|---|
| Notifications were only represented as a settings row | Reminder apps fail if permission timing and recovery are weak | Added notification primer and notification-off recovery screens |
| Vet Summary was only a CTA card | Export is a major paid value and needs visible substance | Added detailed Vet Summary PDF preview screen |
| Paywall lacked purchase and failure states | App Store subscriptions need trust-preserving recovery paths | Added trial active, restore, failure, and expired subscription states |
| Mobile product section showed notes before the app screen | Users should see the product immediately after selecting a tab | Reordered mobile prototype stage to show the phone first |
| Navigation tap area was still slightly under target | Header links are frequent actions on the sales page | Raised nav link target height to 44px |
| Records CTA did not demonstrate the export flow | Paid moment needed a visible path | Linked Records preview button to Vet Summary screen |

## Current UX Strengths

- The design system is coherent: Care Ring, sage primary, warm off-white background, white cards.
- The sales TOP clearly says what the app is before showing the product.
- Today puts the next medication task first and keeps secondary actions nearby.
- Records has a clear paid moment through Vet Summary PDF.
- Family screen focuses on completion certainty, not complex scheduling.
- Settings exposes trust-critical rows: notifications, restore purchase, data, privacy.

## Remaining UI/UX Risks

| Risk | Recommendation |
|---|---|
| Mock pet avatars are abstract | Generate or source a consistent set of realistic pet photos/avatars for dog, cat, rabbit, bird, reptile, and small animal |
| Phone UI is HTML-based, not native SwiftUI yet | Convert components into SwiftUI views once visual direction is approved |
| Paywall still needs App Store purchase state coverage | Add loading, trial active, purchase failed, restore success, and subscription expired states |
| Notifications are represented only in Settings | Add a dedicated notification permission primer and disabled-notification recovery screen |
| Vet Summary is only a card | Build a detailed PDF preview with sections and export states |
| Accessibility needs deeper verification | Add Dynamic Type, reduced motion, VoiceOver label, and contrast checks during SwiftUI implementation |

Resolved in Pass 2: paywall state coverage, notification primer/recovery, Vet Summary preview.

Still open: real pet photo/avatar assets, native SwiftUI conversion, deeper native accessibility verification.

## Next Build Priorities

1. Generate missing visual assets: app icon, pet avatar set, Vet Summary PDF preview, App Store screenshot background.
2. Add notification permission and notification-disabled recovery screens.
3. Expand Paywall into purchase states.
4. Create SwiftUI component map from the current HTML components.
5. Build the first native slice: Today + Add Care + local notification.

## Verification Notes

- Desktop, mobile, and narrow mobile viewports checked for horizontal overflow.
- New tabs checked: Vet Summary, Notifications, Recovery, Purchase States.
- Records to Vet Summary interaction checked.
- Today Done/Snooze/Skip/Undo loop checked in the active prototype frame.
- Browser console checked after changes.
