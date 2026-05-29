# Tend Pets App Store Metadata

## Name

Tend Pets

## Subtitle

Medication & care reminders

## Promotional Text

Keep pet medication, vet visits, vaccines, weight, food notes, and family care routines organized in one calm iOS app.

## Description

Tend Pets helps pet owners remember and record daily care routines.

Track medication reminders, vet visits, vaccine history, weight, food notes, and care records for every pet. Build a clear history that is easier to review before a veterinary appointment.

Tend Pets is designed for dogs, cats, rabbits, birds, reptiles, and small animals.

Free features:

- 1 pet with UNLIMITED reminders
- FULL, permanent care history (your pet's data is never gated)
- One-tap Done, Snooze, and Skip
- Ad-hoc logging of weight, symptoms, and notes
- Today / Pets / Add / Records tabs

Tend Pets Plus (subscription) adds:

- Unlimited pets (for multi-pet households)
- Medication refill tracking with low-supply alerts
- Vet Summary with weight trend chart and PDF export for vet visits
- Photo & document attachments (vaccine certificates, lab results) — a vet binder
- Twice-daily and 3-times-daily medication schedules
- Export all data via share sheet

Tend Pets does not provide veterinary medical advice, diagnosis, dosage recommendations, treatment recommendations, or emergency guidance. It is a reminder and record-keeping tool only. Always follow your veterinarian's instructions.

Tend Pets Plus is an auto-renewing subscription. Plus Monthly is $4.99 per month and Plus Yearly is $35.99 per year (Family tiers also available). Each plan starts with a 1-month free trial. Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew at the same price unless cancelled at least 24 hours before the end of the current period. You can manage or cancel your subscription any time in your Apple ID account settings after purchase. See the Terms of Use and Privacy Policy linked in the app and on the support site.

## Keywords

pet medication,vaccine reminder,vet records,medication tracker,pet care,pet health,weight log

<!-- 93/100 chars. Removed redundant "pet medicine" (covered by "pet medication"),
     "dog medication" / "cat medication" (Apple ASO auto-broadcasts species variants),
     added high-intent terms "tracker" and "reminder" per 2026 ASO playbook. -->


## Support URL

https://tendpets.starving-effort.com/support

## Privacy Policy URL

https://tendpets.starving-effort.com/privacy

## Terms of Use URL

https://tendpets.starving-effort.com/terms

> URL は Cloudflare Pages auto-domain。`starvingeffort.app/tendpets/*` or `tendpets.app` に custom domain 切替後は `legal/DEPLOY.md` §3 と本ファイルを同期更新する。

## Review Notes

Tend Pets is a reminder and record-keeping utility for pet owners. It does not diagnose, recommend medication dosage, replace veterinary care, or provide emergency guidance.

The app uses one local SAMPLE pet on first launch ("Momo" the cat, badged "SAMPLE" in the UI, with photo, reminders, and history) so reviewers can immediately test Today, Add Care, Records, Settings, and the subscription paywall without creating data first. The sample does not count toward the free 1-pet limit and is automatically replaced the moment the user adds their own pet (no paywall to add a first pet). Reviewers can also swipe-to-delete it or use Settings → Delete all data. StoreKit products are configured in `StoreKit/TendPets.storekit` for sandbox testing.

**Subscription gating** (verifiable in sandbox):
- Free tier: 1 pet (PetsView shows "Free plan supports 1 pet" footer when limit hit), UNLIMITED reminders, ad-hoc weight/symptom/note logging, FULL permanent care history (no history gating), Vet Summary builder locked (RecordsView shows "Unlock with Plus" button), Export data locked (SettingsView shows "Plus" badge).
- Plus tier (any of 4 products): all of the above unlocked.

**Account model**: Tend Pets does not require a user account. All data is stored locally on device. There is no sign-in, no cloud sync, no server-side user profile. Settings → Delete all pet data permanently removes all locally stored data, satisfying the Apple Account Deletion guideline 5.1.1(v) requirement equivalent for local-only apps.

**No tracking**: Privacy manifest declares NSPrivacyTracking=false. The app does not use third-party analytics, advertising SDKs, or cross-app tracking.

## Subscription Notes

| Product ID | Display | Price (USD) | Period | Trial |
|---|---|---|---|---|
| `tendpets.plus.monthly` | Plus Monthly | $4.99 | 1 month | 1 month free |
| `tendpets.plus.yearly` | Plus Yearly | $35.99 | 1 year | 1 month free |
| `tendpets.family.monthly` | Family Monthly | $6.99 | 1 month | 1 month free |
| `tendpets.family.yearly` | Family Yearly | $49.99 | 1 year | 1 month free |

**Subscription group**: `Tend Pets` (single group, products are upgrade/downgrade exchangeable).

**Trial strategy**: 3 weeks (21 days) — based on RevenueCat 2026 data showing 17-32 day trials produce ~42.5% median conversion vs ~25.5% for trials under 4 days.

**Pricing rationale**:
- Plus Monthly $4.99: utility-category mid-range, low psychological barrier
- Plus Yearly $35.99: 40% off vs monthly (= $3.00/mo equivalent), within RevenueCat conversion sweet spot
- Family tiers: compressed to $6.99/$49.99 (was $8.99/$69.99) to narrow gap with Plus tier
- Hard paywall is NOT used in Phase 0 — freemium model with subscription upsell. Reassess after DAU 100+ milestone.

Final App Store Connect products must match these IDs and prices, or the StoreKit config and code must be updated.
