# Device Size Standard

## Canonical Design Target

Use one iPhone size for UI decisions:

```text
iPhone 15 logical portrait size
393 x 852 pt
```

## Why This Size

- Modern mainstream iPhone proportion
- Good baseline for App Store screenshots and SwiftUI previews
- Close enough to current iPhone 15/16 class devices for layout decisions
- Avoids the earlier problem where presentation mockups used multiple unrelated phone sizes

## Rules

- Native app UI reference uses `393 x 852`.
- Sales page may show product mockups, but app UI decisions come from the native reference.
- Do not judge real app spacing from the marketing board.
- SwiftUI should remain responsive, but design QA starts from this size.
- After this size passes, test narrow fallback such as iPhone SE.

## Source Files

- `ios-native.html`
- `ios-native.css`
- `ios-native.js`

The CSS defines:

```css
--device-width: 393px;
--device-height: 852px;
```

