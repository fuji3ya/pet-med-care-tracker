# App Review Notes Draft

Tend Pets is a pet medication and care reminder app. It is intended for record keeping, reminders, family coordination, and vet-visit preparation. It does not provide veterinary medical advice, diagnosis, dosage recommendations, treatment recommendations, disease prevention claims, or emergency guidance.

## Reviewer Test Path

1. Launch the app.
2. Complete or skip onboarding.
3. On Today, tap Done, Snooze, and Skip on the sample medication reminder.
4. Open Add and create a new care reminder:
   - Medicine requires dose/instructions.
   - Food, Weight, Visit, and Vaccine adapt the labels and copy.
5. Open Records to confirm completed/skipped care creates history.
6. Open Vet Summary and use Share.
7. Open Settings:
   - Enable notifications.
   - Test notification.
   - Open Tend Pets Plus.
   - Restore purchase.
   - Export local data.
   - View disclaimer, Privacy Policy, and Terms.
8. Test subscriptions with StoreKit sandbox products:
   - `tendpets.plus.monthly`
   - `tendpets.plus.yearly`
   - `tendpets.family.monthly`
   - `tendpets.family.yearly`

## Subscription Disclosure

Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Users can manage or cancel subscriptions in App Store account settings. Restore Purchase is available in Settings and on the paywall.

## Privacy Summary

This build stores care data locally through UserDefaults. If production cloud backup, analytics, support ticketing, or account login are added, App Privacy answers and `PrivacyInfo.xcprivacy` must be updated before submission.
