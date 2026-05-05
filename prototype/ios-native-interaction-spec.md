# Tend Pets Native iOS Interaction Spec

Updated: 2026-05-05

Canonical device:

```text
iPhone 15 portrait, 393 x 852 pt
```

## Design Direction

Aesthetic: calm clinical utility.

The app should feel like a reliable daily care tool, not a marketing page. The memorable anchor is the pet care ring paired with grouped iOS lists and one-tap care actions.

DFII:

- Aesthetic impact: 3
- Context fit: 5
- Implementation feasibility: 5
- Performance safety: 5
- Consistency risk: 1
- Score: 17

## Implemented Prototype Flow

### Global

- First launch opens onboarding unless `tendPetsOnboardingComplete` is set in local storage.
- Onboarding can be skipped, continued, completed into Add Care, or replayed from Settings.
- Bottom tabs: Today, Pets, Add, Records, Settings.
- Detail screens keep the current tab context active.
- Back returns to the current tab root.
- Toast confirms state-changing actions.
- Sheets are used for choices that should not become full pages.

### Onboarding

- Four cards explain:
  - why routine tracking matters
  - how Today prevents missed care
  - how family/vet handoff works
  - why starting with one pet and one routine is enough
- Skip for now sets onboarding complete and opens Today.
- Add first care sets onboarding complete and opens Add Care.
- Settings includes Replay onboarding for review/testing.

### Today

- Summary card opens pet detail.
- Due card supports:
  - Done: marks reminder complete, records completion, shows undo.
  - Snooze: opens action sheet, moves reminder to upcoming.
  - Skip: opens reason sheet, marks reminder skipped.
  - Undo: returns reminder to due.
- Later rows open reminder detail.

### Pets

- Pet rows open pet detail.
- Add pet opens sheet and appends a sample bird profile for multi-pet testing.
- Pet detail exposes active care, calendar, records, and weight trend.

### Add Care

- Segmented control switches care type.
- Form supports pet, name, dose, time, repeat, note.
- Save validates name, creates a reminder, returns to Today, and shows confirmation.

### Records

- PDF button opens Vet Summary.
- Timeline rows open record detail.
- Calendar link opens May 2026 calendar.

### Calendar

- Month grid displays event dots.
- Day cells are tappable.
- May 5 shows medication and visit rows.

### Settings

- Notifications row toggles On/Off.
- Test notification shows confirmation.
- Plus row opens paywall.
- Restore Purchase shows confirmation.
- Export data shows confirmation.
- Medical disclaimer opens a dedicated safety page.
- Delete account opens a destructive confirmation sheet.

### Paywall

- Plus benefits, monthly and yearly options, trial language, restore purchase, terms/privacy reminder are visible.
- Start free trial updates subscription status to Plus.

## Still Needed For App Store Quality

- Real SwiftUI build on macOS.
- Physical iPhone notification action tests.
- StoreKit sandbox purchase tests.
- Final App Store screenshots from the SwiftUI app, not the browser prototype.
- Final icon and App Store metadata.
