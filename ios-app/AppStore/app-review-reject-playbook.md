# Tend Pets — App Review Reject Playbook

**目的**: Apple Review から reject が来た場合に、**英文 response template** を即返信できるよう pattern 別に用意。Mirrorbite `store/app-review-reject-playbook.md` の Tend Pets 適応版 (medical/pet-care 固有 issue 追加)。

**返信先**: App Store Connect → Resolution Center → Reply。reject message を読んで該当 pattern を選び、template を user 情報 (build version etc.) で埋めて返信。

---

## Pattern Index

| # | Guideline | 想定 reject 理由 | Template § |
|---|---|---|---|
| 1 | 2.1 App Completeness | Crashes / bugs on review | [§1](#1-2-1-completeness-crash-bug) |
| 2 | 2.3.10 Accurate Metadata | Screenshot と実装の不一致 | [§2](#2-2-3-10-accurate-metadata) |
| 3 | 3.1.2(a) Subscription Disclosure | Paywall に required disclosure 欠落 | [§3](#3-3-1-2-a-subscription) |
| 4 | 4.0 Design | UI が iOS HIG 違反 | [§4](#4-4-0-design) |
| 5 | 5.1.1 Privacy / Manifest | 宣言と実装の不一致 | [§5](#5-5-1-1-privacy-manifest) |
| 6 | 5.1.1(v) Account Deletion | Account 削除 path 不在 | [§6](#6-5-1-1-v-account-deletion) |
| 7 | 1.4.1 Safety (medical) | Medical claim / disclaimer 不足 | [§7](#7-1-4-1-safety-medical) |
| 8 | 4.3 Spam (low effort) | Cookie cutter app / 競合との差別化不足 | [§8](#8-4-3-spam-low-effort) |
| 9 | Metadata rejected | Description / Keywords に問題 | [§9](#9-metadata-rejected) |
| 10 | Guideline 改訂 retroactive | 提出時には OK だった項目が新 guideline 違反 | [§10](#10-guideline-retroactive) |

---

## §1 2.1 Completeness (crash / bug)

### 想定 reject

「During review, the app crashed on launch on iPhone X running iOS Y.」

### Pre-action (返信前)

1. Codemagic / Xcode crash log を確認 (ASC → TestFlight → Crashes)
2. 該当 device + iOS version で **必ず手元 (or BrowserStack) で再現**
3. fix → 新 build upload → ASC で **build を新版に差し替え**

### Response template

```
Thank you for your review.

We were able to reproduce the crash on iPhone {DEVICE} running iOS {OS}. The
root cause was {ROOT CAUSE}. We have fixed it in build {NEW_BUILD_NUMBER},
which is now uploaded.

Please use the latest build for re-review. The fix has been verified locally
on iPhone {DEVICE}/iOS {OS} (the exact configuration where the crash occurred).

Thank you.
```

### よくある真因 (Tend Pets specific)

- LocalStorage JSON corruption (v1 schema 変更時) → Round 2 で fix 済
- onAppear race (RootView) → Round 2 で fix 済
- StoreKit purchase double-tap → Round 2 で fix 済

---

## §2 2.3.10 Accurate Metadata

### 想定 reject

「Your screenshots do not accurately reflect the app's user interface.」

### Pre-action

- Apple Reviewer は実機で起動して screenshot 比較
- AI mockup を使ってる場合は **TestFlight 実機 screenshot に差し替え必須** ([[screenshots-from-testflight]] 参照)

### Response template

```
Thank you. We have replaced all screenshots with native iOS captures taken
directly from the TestFlight build on an iPhone {DEVICE} (iOS {OS}). The new
screenshots show the exact UI that ships in build {BUILD_NUMBER}.

The previous screenshots used approximate mockups for the launch announcement
and we apologize for the inconsistency.

Please re-review with the updated screenshots.
```

---

## §3 3.1.2(a) Subscription

### 想定 reject

- 「Subscription paywall lacks required disclosures」
- 「Features advertised in paywall are available without subscription」 ← Round 3 で fix 済 issue
- 「Subscription term, length, price not displayed before purchase」

### Pre-action

- `PaywallView` 確認: 21-day trial 明示 ✓ / Terms+Privacy リンク ✓ / 自動 renewal 文言 ✓
- `AppState.freeMaxPets/freeMaxActiveCarePlans` で gating 実装 ✓
- 5 View で `store.hasPlus` check ✓

→ Round 3 fixes でこの pattern は予防済。reject 来たら **build 差し替えなしで** response 可。

### Response template

```
Thank you. The paywall (PaywallView in SettingsView.swift) includes all
required disclosures:

1. Subscription length (1 month / 1 year) — shown in product row
2. Subscription price — shown in product row (e.g., $4.99)
3. Free trial (1 month) — shown as "Start with 1 month free. Cancel anytime."
4. Auto-renewal terms — full paragraph below product buttons
5. Cancellation instructions — "Manage or cancel in your Apple ID account settings"
6. Terms of Use link — opens https://tendpets.starving-effort.com/terms in Safari
7. Privacy Policy link — opens https://tendpets.starving-effort.com/privacy in Safari

Subscription features are actually gated:
- Free tier: 1 pet, 3 active reminders, 7 days of history (enforced in AppState)
- Plus tier: unlimited (verifiable in sandbox by purchasing any of the 4 products)

Could you please clarify which specific disclosure or gating you found
insufficient? We are happy to address it directly.
```

---

## §4 4.0 Design

### 想定 reject

「The app does not follow iOS Human Interface Guidelines.」

### Pre-action

- 44pt tap target ✓ (PrimaryPillButtonStyle / NeutralPillButtonStyle で `minHeight: 44`)
- Safe area inset ✓ (List + `.safeAreaInset(edge: .bottom)`)
- Dark Mode: 未対応 → Info.plist `UIUserInterfaceStyle = Light` で固定宣言済 ✓ (Round 3)
- Dynamic Type: OnboardingView `.dynamicTypeSize(...)` 対応 ✓ (Round 4)

### Response template

```
Thank you. Tend Pets follows iOS HIG with the following implementation:

1. Tap targets: all interactive controls use minHeight: 44pt (PillButtonStyle)
2. Safe area: TabView + NavigationStack + List handles all safe area insets
3. Dynamic Type: critical Text uses .largeTitle + .dynamicTypeSize for scaling
4. Dark Mode: app declares UIUserInterfaceStyle = Light in Info.plist
   (Dark Mode support is planned for v1.1; the light-only declaration is
   explicit per Apple guidance.)
5. Accessibility: VoiceOver labels on all action buttons (Done/Snooze/Skip etc.)

Could you please indicate which specific HIG section you found violated? We
will address it in the next build.
```

---

## §5 5.1.1 Privacy / Manifest

### 想定 reject

「Privacy manifest is incomplete」 or 「Privacy policy contradicts in-app data behavior」

### Pre-action

- `PrivacyInfo.xcprivacy` declares `NSPrivacyTracking: false` + UserDefaults `CA92.1` ✓
- `legal/privacy.html` と `metadata.md` Review Notes が一致 ✓ (Round 3 で in-code text 削除、外部 Link 統一)

### Response template

```
Thank you. Tend Pets does not collect, track, or transmit any user data:

- PrivacyInfo.xcprivacy declares NSPrivacyTracking: false and only the
  UserDefaults Required Reason API (CA92.1) for app functionality.
- No third-party SDKs are linked (App uses only Apple system frameworks:
  SwiftUI, StoreKit, UserNotifications, UIKit).
- All pet data is stored locally on-device via UserDefaults.
- The hosted Privacy Policy at https://tendpets.starving-effort.com/privacy
  describes this behavior in detail and is the single source of truth
  (in-app Settings links to the same URL).

Please indicate which specific privacy concern was raised and we will provide
additional evidence or fix the issue.
```

---

## §6 5.1.1(v) Account Deletion

### 想定 reject

「Apps that allow users to create accounts must also allow users to delete accounts.」

### Pre-action

- Tend Pets has **no account model** (local-only)
- Settings → "Delete all data" → confirmation → wipes UserDefaults + cancels all notifications ✓ (Round 5 で notification orphan も fix 済)
- `metadata.md` Review Notes で「no account model」明示済

### Response template

```
Thank you. Tend Pets does not require users to create accounts:
- No sign-in screen
- No remote user profile
- No personally identifying information collected

All pet care data is stored locally on-device using iOS UserDefaults. The
"Delete all pet data" button in Settings (visible to all users including
reviewers) permanently removes all locally stored data and cancels every
scheduled notification.

This satisfies the spirit of Guideline 5.1.1(v) — users have full control
over their data and can wipe it in-app.

The "Delete all data" path is documented in Review Notes for the reviewer's
convenience.
```

---

## §7 1.4.1 Safety (medical / pet health)

### 想定 reject

- 「Medical claim without proper disclaimer」
- 「App provides veterinary advice」
- 「Critical safety information could be missed」

### Pre-action

- App description / metadata: 「does not provide veterinary medical advice, diagnosis, dosage recommendations, treatment recommendations, or emergency guidance」 ✓
- Settings → Medical disclaimer 1 ステップで到達可 ✓
- PaywallView にも disclaimer 1 行 ✓

### Response template

```
Thank you. Tend Pets is positioned strictly as a reminder and record-keeping
utility, not as a source of veterinary medical advice:

1. App description (line 4): "Tend Pets does not provide veterinary medical
   advice, diagnosis, dosage recommendations, treatment recommendations, or
   emergency guidance. Always follow your veterinarian's instructions."

2. Settings → Medical disclaimer (in-app, reachable in 2 taps) contains the
   same wording.

3. Paywall view (PaywallView in SettingsView.swift) includes:
   "Tend Pets helps organize reminders and records. It does not provide
   veterinary medical advice."

4. Privacy Policy and Terms of Use both restate the medical boundary.

If the reviewer found specific wording that suggested medical advice, please
indicate the exact location and we will revise it immediately.

Tend Pets does not predict, diagnose, prescribe, or warn about medical
emergencies. It only schedules user-defined reminders and logs user-entered
records.
```

---

## §8 4.3 Spam (low effort)

### 想定 reject

「App appears to be a cookie-cutter version of existing apps」

### Pre-action

- Tend Pets の差別化: 多種動物対応 (cat/dog/rabbit/bird/reptile/fish/small mammal) + offline-first + no-tracking + vet-summary builder
- 競合 (11pets, WAGS, VetRecs) との比較を Response で明示

### Response template

```
Thank you. Tend Pets is differentiated from existing pet care apps in
several substantive ways:

1. Multi-species coverage: explicit support for dogs, cats, rabbits, birds,
   reptiles, fish, and small mammals (most competitors are dog/cat only).

2. Vet Summary builder: aggregates 30 days of medication, weight history,
   skipped care, vaccine records, and visit notes into one shareable text
   summary for the vet appointment (Plus feature). Competitors require
   manual note-taking.

3. Offline-first / no-tracking: all data is local, no analytics, no cloud,
   no third-party SDKs. Privacy-conscious pet owners are the target user.

4. Free tier provides real value: 1 pet + 3 active reminders + 7 days
   history fully usable without payment, with clear upgrade path.

5. iOS-native SwiftUI implementation (not Expo wrapper), full HIG
   compliance, Light mode polished.

The app is the v1.0.0 ship of an independent solo developer building a
medication-tracker for multi-species households. We would appreciate
specific direction on what aspect appeared spam-like so we can address it.
```

---

## §9 Metadata rejected

### 想定 reject

「Description / Keywords / Promotional Text contains issues」

### Pre-action

- `metadata.md` の Description は medical-safe ✓
- Keywords は 93/100 chars OK ✓ (Round 5 で 102 → 93 に trim 済)
- 競合名 / 商標未使用 ✓

### Response template

```
Thank you. We have reviewed the metadata against your feedback and made the
following changes:

- {SPECIFIC CHANGE 1}
- {SPECIFIC CHANGE 2}

The updated metadata is now submitted. Could you please re-review?

If the issue was about competitor names, trademarks, or pricing claims:
Tend Pets metadata does not reference competitor product names, does not
claim "best" / "fastest" / "only", and does not list prices in description
text (prices are shown by Apple StoreKit, not by us).
```

---

## §10 Guideline retroactive

### 想定 reject

提出時には OK だった項目が、新しい Apple Guideline 改訂で違反扱いに。

### Pre-action

- Apple Developer Forum / Twitter で改訂内容を把握
- 該当箇所を fix → 新 build upload

### Response template

```
Thank you for the update on the new Guideline {X.Y.Z}. We were not aware
of the requirement at the time of submission.

We have updated the relevant code/metadata to comply:
- {CHANGE 1}
- {CHANGE 2}

Build {NEW_BUILD_NUMBER} is uploaded and contains the fix.

We appreciate the patience and will monitor the Apple Developer changelog
more closely going forward.
```

---

## 一般原則 (どの response でも守る)

1. **謝罪は短く** (一文)、**事実と修正は具体的に** (build number / 行番号 / 該当 file 名)
2. **「could you please clarify」** は reviewer 側がもう一度 escalate しても良いと感じさせる safe な聞き方
3. **誇張しない** (「we are the best」「unique solution」 はむしろ怪しまれる)
4. **Apple Reviewer は一個人** — defensive ではなく cooperative tone
5. **24h 以内** に reply するのが Apple standard、長く放置すると app stale 扱い
6. **同じ build で 3 回 reject** されたら **build を一度 reject (Withdraw) → 修正 → 新 build → resubmit** の方が早い (resolution center loop は重い)

## Related

- `metadata.md` — copy source
- `app-store-connect-form-fillins.md` — ASC dashboard 入力 copy-paste 用
- Mirrorbite `store/app-review-reject-playbook.md` — 原型 (food AI 固有の reject pattern が違う)
- [[multi-angle-ship-ready-audit]] — 5 round audit で予防した reject pattern
