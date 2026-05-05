# iOS Premium UX Spec

作成日: 2026-05-05

対象: Pet Medication & Care Tracker / iOS first

## 1. Product Bar

このアプリの有料品質は「便利な機能が多い」ではなく、「大事なケアを忘れないと信じられる」ことで成立する。

App Storeで月額課金に耐えるための品質ライン:

- 初回起動から3分以内に、1匹目と最初の薬リマインダーが登録できる
- Todayを開いたら、次にやるケアが3秒以内に分かる
- 通知からDone/Snoozeできる
- 誤操作をUndoできる
- 家族共有で、誰が完了したか分かる
- 病院前にPDFで履歴を出せる
- 無料でも価値が分かり、有料にすると生活が明確に楽になる

## 2. Brand Upgrade

### 推奨ブランド名

Primary: **Tend Pets**

理由:

- 犬猫以外にも広がる
- 薬だけでなく、通院、体重、食事、ケアを含められる
- 「世話をする」「見守る」という意味があり、医療アプリすぎない
- App Store上で `Pet Medication & Care` という説明を添えやすい

避けたい名前:

- PawDose: 分かりやすいが、鳥・爬虫類・小動物に弱い
- PetMeds: 薬に寄りすぎ、通院/食事/体重管理まで広げにくい
- VetNote: 動物病院や獣医師監修に見えやすい

### App Store表示

App Name:

Tend Pets

Subtitle:

Medication & care reminders

Keyword direction:

pet medication, pet medicine, dog medication, cat medication, pet care, vaccine record, vet notes, pet weight

### Brand Promise

Never lose track of the care your pet depends on.

日本語:

大切なケアを、もう見失わない。

## 3. Design Direction

### Aesthetic

Calm Clinical Companion

見た目の印象:

- 清潔
- 静か
- 信頼できる
- 少しだけ温かい
- 毎日使っても疲れない

避ける:

- 子ども向けのかわいさ
- 病院の電子カルテ風の硬さ
- SNSアプリのにぎやかさ
- AI生成っぽい抽象グラデーション
- ペット写真を暗くぼかしたヒーロー表現

### Memorable Anchor

**Care Ring**

ペット写真の周囲に細い進捗リングを置く。今日のケア完了率を表し、未完了があると一部だけ色が残る。

リングの意味:

- Full ring: 今日のケア完了
- Partial ring: 未完了あり
- Small dot: 次の予定あり
- Amber segment: 遅れている

このリングはToday、Pets、Widget、App Storeスクリーンショットで一貫して使う。

## 4. Navigation

### iPhone Tab Bar

| Tab | 役割 | Notes |
|---|---|---|
| Today | 毎日起動する画面 | 初期表示 |
| Pets | ペット別の状態 | 登録・プロフィール |
| Calendar | 予定の見通し | 月表示 + 日リスト |
| Records | 通院/体重/ワクチン履歴 | PDF導線 |
| Settings | 通知/共有/課金 | FamilyはここかPets配下 |

Familyをタブにしない。課金機能なので、必要な文脈で出す。

### Primary Gesture

- Swipe right: 前画面に戻る
- Long press Care Card: Quick actions
- Pull down Today: 今日の予定を再同期
- Tap Care Ring: ペットの今日の詳細

## 5. Core Screen Specs

### 5.1 Today

目的:

今日のケアを迷わず完了する。

Layout:

- Large title: Today
- Header row: 日付、全体完了率
- Pet carousel: 写真 + Care Ring + 名前
- Next care panel: 次にやる1件
- Care list: 時間順
- Floating add button: Add

Care Card contents:

- Time: 08:00
- Pet: Momo
- Type chip: Medicine / Food / Weight / Visit
- Main: Heart med
- Detail: 1 tablet, after breakfast
- Primary: Done
- Secondary: Snooze / Skip

States:

| State | 表示 |
|---|---|
| Upcoming | 白背景、時刻強調 |
| Due now | 薄いセージ背景、Done強調 |
| Overdue | 薄いアンバー背景、"Due 24 min ago" |
| Done | 折りたたみ、完了者と時刻 |
| Skipped | グレー、理由表示 |
| Missed yesterday | Recordsに残し、Todayでしつこく出さない |

Microcopy:

- Empty: "No care scheduled for today."
- Done toast: "Marked as done."
- Undo: "Undo"
- Overdue: "Still open"
- Skipped: "Skipped with note"

Paid polish:

- Done時に軽いhaptic
- 完了後カードが消えず、履歴として残る
- Undoは3秒
- 通知からDoneした場合もTodayに即反映

Acceptance criteria:

- 片手で主要操作ができる
- iPhone SE幅で薬名が潰れない
- Dynamic Type LargeでもDoneボタンが見切れない
- VoiceOverで「Momo, Heart med, 1 tablet, due at 8 AM, Done button」と読める

### 5.2 Add First Care

目的:

オンボーディング中に最初の価値を作る。

Input minimum:

- Pet
- Care type
- Name
- Time
- Repeat

Medicine detail optional:

- Dose
- Food timing
- Start date
- End date
- Instructions
- Side effect note

UI rule:

最初から細かく聞きすぎない。初回は「薬名 + 時刻 + 毎日」だけで登録できる。

Good defaults:

- Repeat: Daily
- End: Until stopped
- Notification: On
- Snooze options: 10 min / 30 min / 1 hour

Premium features:

- Multiple times per day
- Custom interval
- Care templates
- Duplicate from previous pet

Paywall trigger:

無料では「active reminders 2件まで」。3件目を作る瞬間にPlusを出す。

### 5.3 Pet Profile

目的:

ペットごとの健康状態と履歴を俯瞰する。

Top:

- Photo
- Care Ring
- Name
- Species
- Age
- Current weight

Sections:

- Today
- Active meds
- Next vaccine / visit
- Weight trend
- Recent records
- Documents

Species:

- Dog
- Cat
- Rabbit
- Bird
- Reptile
- Small mammal
- Fish
- Other

Unit design:

- Dogs/Cats: kg/lb
- Rabbits/Birds/Reptiles/Small animals: g/kg/lb
- ユーザーが自由に選べる。種別で固定しない。

Premium features:

- More than 1 pet
- Documents
- Advanced history

### 5.4 Records

目的:

病院で説明しやすい履歴を作る。

Default view:

- Timeline

Filters:

- Medicine
- Weight
- Vaccine
- Visit
- Food
- Attachment

Vet Summary:

- Date range
- Pet profile
- Active medications
- Recent missed/skipped meds
- Weight chart
- Vaccine history
- Visit notes
- Owner notes

Paywall trigger:

PDF作成ボタンを押したとき。

Paywall headline:

"Prepare a clear vet summary in seconds."

日本語:

"通院前の説明を、数秒でまとめる。"

### 5.5 Calendar

目的:

予定の見通し。

Rules:

- カレンダーを主役にしすぎない
- 投薬の毎日予定で月表示を埋め尽くさない
- 毎日薬は小さな連続表示、通院/ワクチンを目立たせる

Display:

- Visit and vaccine: label
- Medication: small dot
- Weight check: small dot

### 5.6 Settings

Sections:

- Pets & Family
- Notifications
- Subscription
- Data & Export
- Privacy
- Help

Must include:

- Test notification
- Restore purchase
- Manage subscription
- Export data
- Delete account
- Privacy policy
- Terms
- Medical disclaimer

## 6. Onboarding Spec

Goal:

3分以内に、Todayに1件のケアが表示される状態まで進める。

### Screens

1. Welcome
   - Title: "Care routines, remembered."
   - Body: "Track medications, visits, weight, and notes for every pet."
   - CTA: "Add my pet"

2. Pet
   - Name
   - Species
   - Photo optional

3. First care
   - "What should we help you remember first?"
   - Medication / Vaccine / Visit / Weight / Food

4. Reminder
   - Name
   - Time
   - Repeat

5. Notification permission primer
   - "Tend Pets can remind you when Momo's care is due."
   - CTA: "Enable reminders"

6. Today preview
   - 作成されたCare Cardを表示

7. Soft upgrade
   - "Add more pets, family sharing, and vet summaries with Plus."

Important:

- アカウント登録は後回し
- 通知許可は、通知の価値を作った後に出す
- Paywallは初回完了後に薄く出す。強制しない

## 7. Notification Experience

### Notification categories

Medication:

- Done
- Snooze 10 min
- Open

Visit:

- Open details
- Get ready

Weight:

- Log now
- Remind later

### Copy examples

Medication:

- "Momo's heart med is due"
- "1 tablet, after breakfast"

Overdue:

- "Momo's heart med is still open"
- "Mark done or snooze when you have a moment."

Visit:

- "Luna has a vet visit tomorrow"
- "10:00 AM at Green Vet Clinic"

Japanese:

- "モモの心臓の薬の時間です"
- "朝食後に1錠"
- "ルナの通院は明日10:00です"

Rules:

- 薬名、ペット名、用量を短く入れる
- 不安を煽りすぎない
- "urgent" は使わない
- Critical Alertsは使わない

## 8. Paywall Quality

### Paywall hierarchy

1. Outcome headline
2. Pet-specific preview
3. Feature list
4. Plan selector
5. Trial CTA
6. Restore / Terms / Privacy

### Plus Paywall

Headline:

"Keep every routine organized."

Subcopy:

"For pets with daily care, multiple reminders, or records you want to keep."

Bullets:

- Unlimited care reminders
- Up to 5 pets
- Weight and vaccine history
- Photo attachments
- Vet summary export
- Cloud backup

CTA:

"Start 7-day free trial"

Secondary:

"Continue with Free"

### Family Paywall

Headline:

"Know who handled each dose."

Subcopy:

"Share care routines with family and see when each task was completed."

Bullets:

- Share with up to 5 caregivers
- Completion history
- Care assignments
- Shared pet records
- Vet summary export

CTA:

"Start Family trial"

### Pricing display

Recommended:

- Plus Monthly: $4.99
- Plus Annual: $39.99, Save 33%
- Family Monthly: $8.99
- Family Annual: $69.99, Save 35%

Trial:

- 7 days

Annualをおすすめ表示にする。ただし月額も見やすく置く。

Trust requirements:

- 閉じるボタンを隠さない
- Restore Purchaseを明示
- 課金開始日を表示
- Trial終了後の価格を表示
- Terms/Privacyを表示
- Appleの標準サブスク管理に導線を置く

## 9. Free vs Paid Boundaries

| Feature | Free | Plus | Family |
|---|---:|---:|---:|
| Pets | 1 | 5 | 10 |
| Active reminders | 2 | Unlimited | Unlimited |
| Weight records | Basic | Unlimited | Unlimited |
| Vaccine records | Basic | Unlimited | Unlimited |
| Visit notes | 5 | Unlimited | Unlimited |
| Photo attachments | 3 | Unlimited or high cap | Unlimited or high cap |
| PDF Vet Summary | Preview only | Export | Export |
| Family sharing | No | No | Yes |
| Cloud backup | Basic | Yes | Yes |
| Widgets | Basic Today | Full | Full |

Freeで価値を感じさせるが、「本気で使う人」は自然に足りなくなる設計にする。

## 10. Widget Strategy

### Home Screen Widget

Small:

- ペット写真
- 次のケア
- 時刻

Medium:

- 今日の未完了ケア3件
- Care Ring

Large:

- 複数ペットの進捗
- 次の通院/ワクチン

### Lock Screen Widget

- Next care time
- Open care count

Widgetは課金価値に寄与する。無料はSmallのみ、PlusでMedium/Largeを解放してもよい。

## 11. Empty, Error, Edge States

### Empty states

No pets:

"Add your first pet to start tracking care."

No care today:

"Nothing scheduled today."

No records:

"Records will appear here as you log care."

No family:

"Invite someone you trust to help with care."

### Error states

Notification disabled:

"Reminders are off in iOS Settings."

CTA:

"Open Settings"

Sync issue:

"Some updates haven't synced yet."

CTA:

"Try again"

Subscription issue:

"We couldn't verify your subscription."

CTA:

"Restore purchase"

### Edge cases

- 薬が1日複数回
- 隔日投薬
- 週2回投薬
- 終了日ありの抗生物質
- 体重がg単位
- 複数家族が同時にDone
- 通知許可OFF
- タイムゾーン変更
- オフライン

## 12. Data Model Draft

### Pet

- id
- name
- species
- breed optional
- birthDate optional
- sex optional
- photo
- weightUnit
- archivedAt

### CarePlan

- id
- petId
- type
- name
- dosage optional
- instructions optional
- schedule
- startDate
- endDate optional
- notificationEnabled
- assignedUserId optional
- active

### CareOccurrence

- id
- carePlanId
- petId
- dueAt
- status: upcoming / done / skipped / missed
- completedAt
- completedBy
- skipReason
- note

### Record

- id
- petId
- type: weight / vaccine / visit / food / note
- date
- value
- unit
- title
- note
- attachments

### FamilyMember

- id
- role: owner / caregiver / viewer
- displayName
- notificationPreference

ポイント:

CarePlanとCareOccurrenceを分ける。繰り返し予定の定義と、実際の完了履歴を混ぜない。

## 13. Accessibility Bar

Must:

- Dynamic Type対応
- VoiceOver label
- 色だけで状態を伝えない
- Done/Skip/Snoozeは44pt以上
- Reduce Motion対応
- Contrast AA相当
- 重要情報は小さなチップだけに閉じ込めない

VoiceOver examples:

- "Momo, Heart med, 1 tablet, due now, button"
- "Care completed by Alex at 8:14 AM"
- "Skipped, reason: not eating"

## 14. App Review Safety

### Medical disclaimer

Use:

"Tend Pets helps you record and remember care routines. It does not provide veterinary medical advice. Always follow your veterinarian's instructions."

Avoid:

- AI diagnosis
- Dose recommendation
- Treatment recommendation
- Emergency assessment
- Disease prevention claims

### Subscription review

Include:

- Auto-renewable subscription names
- Duration
- Price
- Trial duration
- Restore purchase
- Terms
- Privacy
- Manage subscription

## 15. App Store Screenshot System

### Screenshot 1

Headline:

"Never miss today's care"

Visual:

Today screen with Care Ring and due medication.

### Screenshot 2

Headline:

"Track meds for every pet"

Visual:

Pet profile with active medication.

### Screenshot 3

Headline:

"Share routines with family"

Visual:

Done by Alex / Done by Mina completion history.

### Screenshot 4

Headline:

"Bring clear notes to the vet"

Visual:

Vet Summary preview.

### Screenshot 5

Headline:

"Weight, vaccines, visits, all together"

Visual:

Records timeline and chart.

Rule:

スクリーンショット内の本文は短く。UIそのものが価値を説明する状態にする。

## 16. Build-Ready Component List

SwiftUI component candidates:

- TodayView
- PetCarousel
- CareRingView
- CareCard
- CareActionBar
- AddCareView
- ScheduleEditor
- PetProfileView
- RecordTimelineView
- WeightChartView
- VetSummaryPreview
- PaywallView
- PlanSelector
- NotificationSettingsView
- FamilySharingView
- EmptyStateView
- ErrorBanner

## 17. Quality Gate Before Launch

Before beta:

- 30回連続で薬リマインダー作成/完了が壊れない
- 通知許可ON/OFFの両方で破綻しない
- iPhone SE、標準iPhone、Pro Maxでレイアウト確認
- Dynamic Type Largeで確認
- VoiceOverでTodayの主要操作確認
- オフラインでTodayが開ける
- App Storeサブスクの購入/復元/解約導線確認
- PDFの内容が病院に見せても恥ずかしくない

## 18. Next Design Deliverables

次に作ると実装に入れる成果物:

1. Low-fi wireframes: Today / Add Care / Pet Profile / Records / Paywall
2. High-fi visual mock: Today + Paywall
3. Design tokens: color, type, spacing
4. SwiftUI component skeleton
5. App Store screenshot mock

