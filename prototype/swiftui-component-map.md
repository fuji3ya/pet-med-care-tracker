# Tend Pets SwiftUI Component Map

Purpose: Convert the current browser prototype into native iOS implementation without losing design consistency.

## Design Tokens

| Token | Value |
|---|---|
| background | `#FAF9F6` |
| surface | `#FFFFFF` |
| textPrimary | `#1F2420` |
| textSecondary | `#6E746F` |
| primary | `#2F6F5E` |
| medicine | `#3E6FB6` |
| food | `#B8792D` |
| visit | `#7A5DB5` |
| alert | `#B8743A` |

## Native Screens

| Prototype screen | SwiftUI view | Notes |
|---|---|---|
| Today | `TodayView` | First native slice. Owns next care and daily list |
| Onboarding | `OnboardingView` | First-run why/use flow, skip, Add first care, Settings replay |
| Add Care | `AddCareView` | Uses shared `ScheduleEditor` |
| Pet Profile | `PetProfileView` | Care Ring, active meds, weight trend |
| Calendar | `CareCalendarView` | Avoid dense daily-med calendar clutter |
| Records | `RecordsView` | Timeline + filters |
| Vet Summary | `VetSummaryPreviewView` | PDF preview and export gate |
| Family | `FamilySharingView` | Completion history and caregivers |
| Notifications | `NotificationPrimerView` | Before system permission prompt |
| Recovery | `NotificationRecoveryView` | When iOS notifications are disabled |
| Settings | `SettingsView` | Restore, export, delete, privacy |
| Paywall | `PaywallView` | StoreKit product display |
| Purchase States | `SubscriptionStateView` | Trial, restore, failure, expired |

## Shared Components

| Component | SwiftUI candidate | Behavior |
|---|---|---|
| Care Ring | `CareRingView` | Conic progress ring around pet image/avatar |
| Pet avatar | `PetAvatarView` | Photo first, generated fallback second |
| Care card | `CareCardView` | Done, Snooze, Skip, Details |
| Action buttons | `CareActionBar` | 44pt minimum touch targets |
| Status panel | `StatusPanel` | Success, warning, muted, neutral |
| Record row | `RecordTimelineRow` | Type dot, title, subtitle, date |
| Plan selector | `PlanSelector` | Monthly/annual selection |
| PDF preview | `VetSummaryDocumentPreview` | App preview of exportable PDF |
| Empty state | `EmptyStateView` | Calm copy, no decoration overload |

## First Native Build Slice

1. `Pet` model
2. `CarePlan` model
3. `CareOccurrence` model
4. `CareRingView`
5. `CareCardView`
6. `TodayView`
7. `AddCareView`
8. Local notification scheduling
9. Notification actions: Done / Snooze

## Quality Rules

- All tappable native controls must be at least 44pt high.
- Do not use red for normal overdue care; use amber.
- Do not recommend medication dosage.
- Keep notification copy pet-specific.
- Keep PDF language factual and record-based.
- Paywall must show Restore Purchase, Terms, Privacy, trial duration, and renewal price.
