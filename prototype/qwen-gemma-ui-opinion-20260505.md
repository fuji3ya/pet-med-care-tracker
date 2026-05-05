# Qwen / Gemma4 UI Opinion - 2026-05-05

Target: Tend Pets native iOS prototype, iPhone 15 portrait, 393 x 852 pt.

Models used:

- `qwen3:8b`
- `gemma4:latest`

## Shared Verdict

The prototype is structurally useful, but it still reads closer to a functional wireframe than an App Store-quality app. The next quality jump should come from interaction feedback, visual hierarchy, validation behavior, and native iOS polish.

## Qwen Emphasis

- Navigation consistency must be strict. Back controls, Records routing, and detail exits should behave the same everywhere.
- Fake tappable states are risky. Static information should not be exposed as buttons.
- Contrast and accessibility need explicit checking, especially muted labels and colored category accents.
- Category color should be functional and restrained, not decorative.
- Before review, verify tap targets, route correctness, and VoiceOver-style labels.

## Gemma4 Emphasis

- The app needs stronger feedback loops: success toasts, error messages, and clear post-action state.
- Add Care must show field-level validation, not only a generic toast.
- Typography hierarchy is still weak: title, body, caption, metadata, and primary data need clearer scale and weight.
- Cards should create clearer information chunks for medication, food, visit, and records.
- The app needs a production habit: every important flow should be tested from action to result.

## Applied Immediately

- Static rows are rendered as `div` unless they have a real route or action.
- Records route now maps back to the Records tab instead of an invalid detail route.
- Back glyph was corrected to a clean `‹` control.
- Text navigation actions now have a separate `text-action` style.
- Tap/focus states were tightened for buttons, tab bar items, rows, cards, and calendar cells.
- Add Care now shows inline validation for missing name and dose.
- Pet detail title changed from duplicated pet name to `Pet Profile`.

## Next Implementation Targets

1. Add screen-specific empty states for Records, Calendar, and Pets.
2. Replace symbolic tab glyphs with real iOS/SF Symbol equivalents in SwiftUI.
3. Add a short onboarding flow before App Store-level screenshots.
4. Test dynamic type and VoiceOver labels in the real SwiftUI simulator.
5. Run the serve-sim QA pass on macOS once Xcode Simulator is available.

