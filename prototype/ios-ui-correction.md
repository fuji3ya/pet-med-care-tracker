# iPhone UI Correction

## Direct Answer

The previous browser prototype was **not** a correct iPhone app UI. It was a useful product and sales concept board, but it mixed website presentation patterns with app screens.

## What Was Wrong For Native iOS

| Problem | Why it is wrong |
|---|---|
| Web-style pill tabs controlled the app screens | A real iPhone app should use a bottom tab bar or navigation stack, not external chip navigation |
| Screen notes sat beside the phone | Good for presentation, not part of an iOS app |
| Too many floating cards and marketing layout cues | Native iOS favors grouped lists, navigation bars, sheets, and system controls |
| Buttons looked visually nice but were not consistently native | iOS needs 44pt targets and familiar actions |
| Settings looked like a custom web list | Settings should be a grouped iOS list |
| Add Care looked like a web form | It should feel like an iOS grouped form with segmented control and navigation actions |
| Paywall and notifications were conceptually right but too presentation-like | StoreKit and notification permission flows need native states |

## Corrected Direction

Created a separate native iOS reference:

`ios-native.html`

This version uses:

- Bottom tab bar
- Large titles
- Grouped iOS lists
- Native-feeling forms
- Contextual action sheet
- Safe-area-style bottom navigation
- 44pt primary controls

## Fixed Device Size

The native reference now uses one canonical app size:

`iPhone 15 logical portrait, 393 x 852 pt`

Earlier mixed-size phone frames should not be used for judging the actual iOS app.
- Clear separation from sales page UI

## Rule Going Forward

Use `index.html` for sales/marketing presentation.

Use `ios-native.html` as the source of truth for actual iPhone app UI direction.
