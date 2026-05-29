# Tend Pets — App Store Connect 提出フォーム コピペ用

**目的**: ASC dashboard を開いた後、各 form field に**そのままコピペ**できる答えを 1 ファイルに集約。`metadata.md` を form-friendly 化したもの。Mirrorbite `store/app-store-connect-form-fillins.md` の Tend Pets 版。

**書式**: `## Section Name` の下に code block で copy-paste 用文字列。後段に字数 / source / 注記。

---

## App Information

### Name (30 char max)

```
Tend Pets
```

文字数: 9 (≤30 OK)

### Subtitle (30 char max)

```
Medication & care reminders
```

文字数: 27 (≤30 OK)

### Bundle ID

```
app.starvingeffort.tendpets
```

### SKU (internal product code, 内部識別子、英数字とハイフン)

```
tendpets-v1
```

### Primary Language

```
English (U.S.)
```

### Categories

- Primary: **Medical**
- Secondary: **Utilities**

### Content Rights

「Does your app contain, display, or access third-party content?」 → **No**

### Age Rating

すべて **None** (no objectionable content / no medical disclaimers required at content-rating level / no user-generated content)
- 結果: **4+**

---

## Pricing and Availability

### Price

- Free (app itself is free; subscriptions via IAP)

### Availability

- All countries and regions (Apple default)

### Subscription Group: `Tend Pets`

4 products (詳細は metadata.md の Subscription Notes 参照):

| Product ID | Display Name | Reference Name | Price | Period | Trial |
|---|---|---|---|---|---|
| `tendpets.plus.monthly` | Plus Monthly | Plus Monthly | $4.99 | 1 month | 1 month free |
| `tendpets.plus.yearly` | Plus Yearly | Plus Yearly | $35.99 | 1 year | 1 month free |
| `tendpets.family.monthly` | Family Monthly | Family Monthly | $6.99 | 1 month | 1 month free |
| `tendpets.family.yearly` | Family Yearly | Family Yearly | $49.99 | 1 year | 1 month free |

各 product の localization (en-US):

#### `tendpets.plus.monthly`

- Display Name: `Plus Monthly`
- Description: `Unlimited pets and reminders, full vet summary, full care history, JSON export.`

#### `tendpets.plus.yearly`

- Display Name: `Plus Yearly`
- Description: `Best value. Unlimited pets and reminders, full vet summary, full care history, JSON export.`

#### `tendpets.family.monthly`

- Display Name: `Family Monthly`
- Description: `Plus features + Family Sharing for multi-pet households.`

#### `tendpets.family.yearly`

- Display Name: `Family Yearly`
- Description: `Best value. Plus features + Family Sharing for multi-pet households.`

---

## App Privacy

### Data Types Collected

**Nothing**. Tend Pets does not collect any user data.

ASC questionnaire 回答:
- 「Do you or your third-party partners collect data from this app?」 → **No**
- Privacy manifest (`PrivacyInfo.xcprivacy`) declares NSPrivacyTracking=false

### Third-Party SDKs

**None**. App uses only Apple system frameworks (SwiftUI, StoreKit 2, UserNotifications, UIKit).

---

## Version Information (1.0.0)

### What's New in This Version

```
Initial release of Tend Pets — a calm pet medication and care reminder for cats, dogs, rabbits, birds, reptiles, and small animals. Track meds, vaccines, vet visits, weight, and food notes in one place.
```

文字数: ~230 (≤4000 OK)

### Promotional Text (170 char max)

```
Keep pet medication, vet visits, vaccines, weight, food notes, and family care routines organized in one calm iOS app.
```

文字数: 118 (≤170 OK)

### Description (4000 char max)

`metadata.md` § Description を完コピペ。

字数: 908 (≤4000 OK)

### Keywords (100 char max, comma-separated)

```
pet medication,vaccine reminder,vet records,medication tracker,pet care,pet health,weight log
```

文字数: 93 (≤100 OK)

### Support URL

```
https://tendpets.starving-effort.com/support
```

### Marketing URL (optional)

```
https://tendpets.starving-effort.com/
```

### Privacy Policy URL

```
https://tendpets.starving-effort.com/privacy
```

### Terms of Use URL (in-app の Settings からも参照)

```
https://tendpets.starving-effort.com/terms
```

---

## App Review Information

### Sign-in required? → **No**

(Tend Pets has no account model. All data is local on-device.)

### Contact Information

- First name: REDACTED-NAME
- Last name: REDACTED-NAME
- Phone: (Apple Developer Program 登録時の +81 REDACTED-PHONE)
- Email: `REDACTED-EMAIL`

### Notes (Review Notes, 4000 char max)

`metadata.md` § Review Notes を完コピペ。

字数: 1508 (≤4000 OK)

**重要**: Review Notes には以下が必ず含まれていること (post-Round-5 状態):
- 「Account model: no user account, all data local」
- 「No tracking, no third-party SDKs」
- 「Sample data on first launch (Momo cat) — reviewer can delete via Settings → Delete all pet data」
- 「Subscription gating verifiable in sandbox」 + 5 機能 gating 一覧

### Attachment (optional but recommended)

なし。Tend Pets は機能シンプルなので追加 demo video 等不要。

---

## Build Selection

Codemagic で TestFlight upload した build を選択 (e.g., `1.0.0 (1)` / `1.0.0 (2)`).

---

## Export Compliance

- 「Does your app use encryption?」 → **No** (HTTPS のみ、custom encryption なし)
- `ITSAppUsesNonExemptEncryption` in Info.plist = `false` (declared)

→ ASC 提出時 export compliance section は **automatic exemption**。

---

## AI / Machine Learning Disclosure (Apple 2026 新要件)

Tend Pets は AI / ML 機能を**使ってない**。
- ASC questionnaire: 「Does this app use AI/ML for primary features?」 → **No**
- (Mirrorbite は Yes、Vision API 使用)

---

## Pre-Submission Final Checklist

ASC dashboard で submit ボタン押す前に確認:

- [ ] App Information 全 field 入力済
- [ ] Pricing: 4 IAP products すべて Ready to Submit 状態
- [ ] App Privacy: questionnaire 完了
- [ ] What's New / Description / Keywords / URL 全 4 本入力済
- [ ] Screenshots: 6.9" Display (iPhone 16 Pro Max) 5-10 枚 upload 済
- [ ] App Icon 1024×1024 RGB no-alpha upload 済
- [ ] Build selected (Codemagic ビルド)
- [ ] App Review Information: Sign-in No / Contact / Review Notes 全部入力済
- [ ] Export Compliance: No encryption → exemption auto
- [ ] AI/ML disclosure: No

→ **Submit for Review** ボタン押下

平均 24-48h で結果通知。reject 来たら `app-review-reject-playbook.md` 参照。
