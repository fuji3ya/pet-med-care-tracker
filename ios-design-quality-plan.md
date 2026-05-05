# iOS App Design & Paid Quality Plan

作成日: 2026-05-05

対象: Pet Medication & Care Tracker / iOSファースト

## 1. 方針

このアプリは「かわいいペット管理」ではなく、「毎日ミスなくケアできる、静かな安心感のある健康管理アプリ」として設計する。

課金に耐える品質の核は、機能数ではなく次の3つ。

1. 今日やることが3秒で分かる
2. 投薬完了が1タップで終わる
3. 家族共有時に「誰がやったか」が明確に残る

見た目は医療アプリほど冷たくせず、ペットアプリほど軽くしすぎない。方向性は「Calm Clinical Companion」。白、薄いウォームグレー、少量のセージグリーン、状態色だけを使う。信頼感を出すため、過度なイラスト、派手なグラデーション、SNS風のにぎやかさは避ける。

## 2. iOS前提のプロダクト判断

### 推奨スタック

| 項目 | 推奨 |
|---|---|
| App | SwiftUI |
| Local data | SwiftData |
| Sync | CloudKit or Firebase |
| Notification | Local Notification + optional server sync |
| Subscription | StoreKit 2 + RevenueCat optional |
| Widget | WidgetKit |
| Watch | Phase 2以降 |

iOSだけで始めるならSwiftUIを推奨。理由は、通知、ウィジェット、Live Activities、Apple Watch、Dynamic Type、アクセシビリティとの相性がよく、課金アプリらしい手触りを作りやすいから。

将来Androidも出す前提が強い場合はReact Native/Expoでもよい。ただし、有料iOSアプリとしての質感はSwiftUIの方が出しやすい。

## 3. デザインシステム

### Aesthetic

Name: Calm Clinical Companion

DFII:

| 評価軸 | Score |
|---|---:|
| Aesthetic Impact | 3 |
| Context Fit | 5 |
| Implementation Feasibility | 5 |
| Performance Safety | 5 |
| Consistency Risk | -1 |
| Total | 17 |

強く記憶に残す要素は「Pet Health Ring」。各ペットの今日のケア進捗を、写真の周りの細いリングで表す。薬、食事、体重、通院予定を色分けするが、画面全体は静かに保つ。

### Color

| 用途 | 色 |
|---|---|
| Background | #FAF9F6 |
| Surface | #FFFFFF |
| Primary text | #1F2420 |
| Secondary text | #6E746F |
| Primary action | #2F6F5E |
| Medicine | #3E6FB6 |
| Food | #B8792D |
| Vaccine / Visit | #7A5DB5 |
| Alert | #B94A48 |
| Success | #2F7D57 |

単色テーマにしない。ヘルスケアの信頼感はセージ系で統一し、薬・食事・通院だけ状態色を分ける。

### Typography

iOSネイティブではSF Proを基本にする。アプリ内の実用画面はApple標準の読みやすさを優先する。ブランド表現はApp Icon、空状態、オンボーディングの短い見出しだけで出す。

### Components

| Component | 品質要件 |
|---|---|
| Care Card | 時刻、対象ペット、薬名、用量、完了ボタンが1画面で読める |
| Completion Button | 親指で押しやすい高さ、誤タップ時はUndo |
| Pet Switcher | 写真 + 名前 + 今日の進捗リング |
| Dose Sheet | Bottom sheetで用量、メモ、副作用、スキップ理由 |
| Timeline | 通院・体重・ワクチン・投薬履歴を日付順 |
| Paywall | 価格より先に「防げる不安」を見せる |

## 4. 情報設計

タブは5つ以内に抑える。AppleのHIGでも、よく使う主要セクションにはタブバーが向いている。iOSでは下部タブバーを使い、iPadではサイドバー展開も想定する。

### Tab structure

| Tab | Label | SF Symbol候補 | 役割 |
|---|---|---|---|
| Today | Today | checkmark.circle | 今日のケア |
| Pets | Pets | pawprint | ペット別管理 |
| Calendar | Calendar | calendar | 予定 |
| Records | Records | folder | 履歴 |
| Settings | Settings | gearshape | 設定・課金 |

Familyは独立タブにしない。SettingsまたはPets配下に置く。理由は、無料ユーザーには常時必要ではなく、有料導線として文脈内で出した方が自然だから。

## 5. 画面ごとの使い勝手

### 5.1 Today

目的: 開いた瞬間に「次に何をすればいいか」が分かる。

表示:

- 上部: 今日の日付、全体進捗、ペット切替
- 中央: 時間順のCare Card
- 下部: Add care / Quick log

Care Card:

- 例: 08:00 / Momo / Heart med / 1 tablet / After meal
- Primary action: Done
- Secondary: Snooze, Skip, Details

Interaction:

- Doneを押すとカードが折りたたまれ、完了者名と時刻を表示
- 3秒間Undoを出す
- Skip時は理由を選択: 食べなかった、吐いた、病院指示、その他
- 遅れているケアは赤ではなくアンバー寄りにする。緊急感を出しすぎない

Paid quality:

- 1タップ完了
- haptic feedback
- Undo
- ローカル通知から直接Done/Snoozeできる
- Apple Watch対応を将来追加しやすい構造

### 5.2 Pet Profile

目的: ペットごとに健康状態を俯瞰する。

表示:

- 写真
- Health Ring
- 年齢、種別、体重
- Active medication
- Next visit / vaccine
- Recent notes

重要:

- 犬猫以外でも違和感がないように、種別アイコンを固定しすぎない
- 写真がない場合は毛色や種別を選んで抽象アバターを作る
- 小動物向けにg単位を第一級扱いにする

### 5.3 Add Medication

目的: 入力の面倒さを最小化する。

入力順:

1. どのペットか
2. 薬名
3. 量
4. いつ飲ませるか
5. いつまで続けるか
6. 通知するか

UI:

- Stepper形式ではなく、1画面フォーム + 必要時だけ詳細展開
- 頻度はセグメント: Daily / Weekly / Every X days / Custom
- 時刻はiOS標準のTime Picker
- 期間は「Until stopped」「For 7 days」「Custom date」

Paid quality:

- よく使う薬をテンプレート化
- 前回と同じ設定を複製
- 薬名入力時に履歴候補を出す

### 5.4 Calendar

目的: 通院、ワクチン、投薬期間を見通す。

MVPでは凝りすぎない。月カレンダー + 下部リストで十分。

表示:

- 日ごとの小さなドット
- 薬は青、通院は紫、食事/体重は茶/緑
- 日付タップでその日の予定

### 5.5 Records

目的: 病院に見せられる履歴を作る。

構成:

- Timeline
- Weight chart
- Vaccines
- Visits
- Attachments

Paid quality:

- 「Vet Summary」を作る
- 期間選択: Last 7 days / 30 days / 90 days / Custom
- PDF出力
- CSV出力

この出力機能は課金に強い。病院前に「使っていてよかった」と感じる瞬間を作れる。

### 5.6 Family Sharing

目的: 家族間の投薬ミスを防ぐ。

仕様:

- 招待リンク
- 権限: Owner / Caregiver / View only
- Care Cardに完了者を表示
- 通知を担当者ごとに分ける
- 重要ケアは全員通知、通常ケアは担当者通知

UI:

- 「誰が何をするか」をシフト表のようにしない
- まずはケアごとに担当者を選べるだけでよい
- 完了履歴を見れば家族間の不安が消える設計にする

## 6. 通知設計

薬リマインダーアプリでは、通知品質がプロダクト品質そのもの。

### 通知タイプ

| Type | 内容 |
|---|---|
| Medication due | 投薬時間 |
| Snooze | あとで通知 |
| Missed care | 未完了 |
| Visit reminder | 通院前日/当日 |
| Vaccine due | 次回ワクチン |

### 通知文言

悪い例:

- Reminder
- Medication time

良い例:

- Momo's heart med is due
- Luna has a vet visit tomorrow at 10:00
- Rio's weight check is still open

### iOSならでは

- 通知アクション: Done / Snooze
- Critical Alertsは初期は使わない。医療緊急通知に見え、審査と信頼のリスクがある
- App Badgeは未完了ケア数だけにする
- Focusモードに過度に逆らわない
- 通知テスト画面をSettingsに置く

## 7. オンボーディング

課金に耐えるアプリは、最初の3分で「これは自分の生活に入る」と感じさせる必要がある。

### Flow

1. Welcome
   - ペットの薬とケアを、家族で忘れない

2. Pet setup
   - 名前、種別、写真

3. First care
   - 薬またはケアを1件作る

4. Notification permission
   - 先にリマインダーを作らせてから許可を取る

5. Today preview
   - 作った予定がTodayに出る

6. Optional trial
   - 2匹目、家族共有、履歴バックアップを見せる

ポイント:

- 最初にアカウント登録を要求しない
- 先に価値を作らせる
- ペット写真を入れると愛着が出るので早めに促す
- ただしスキップ可能にする

## 8. Paywall設計

### 課金メッセージ

価格ではなく、不安の解消を売る。

Headline:

Keep every dose, visit, and care note safely organized.

Subcopy:

For pets who need daily care, shared routines, or a clear record for the vet.

### Paywall components

- ペット複数管理
- 無制限リマインダー
- 家族共有
- 通院用PDF
- 写真添付
- クラウドバックアップ

### 表示タイミング

| Moment | 推奨プラン |
|---|---|
| 3件目のリマインダー作成 | Plus |
| 2匹目追加 | Plus |
| 家族招待 | Family |
| PDF出力 | Plus or Family |
| 写真添付上限 | Plus |

### 品質要件

- 月額と年額を明確に表示
- 年額は「Save 33%」のように表示
- Trialの終了日を明記
- Restore Purchaseを必ず置く
- Terms / Privacyを見える位置に置く
- 閉じるボタンを隠さない

AppleのHIGでは、アプリ内課金はアプリ体験に統合し、分かりやすい商品名と直接的な言葉を使うことが推奨されている。Paywallは強引に見せるより、「今やりたいことの延長」に置く。

## 9. 課金に耐える品質ライン

### Must

- 通知からDone/Snooze
- Undo
- 薬リマインダー複製
- ペット別履歴
- 体重グラフ
- 写真添付
- App内データ削除
- Restore Purchase
- オフラインでToday表示
- Dynamic Type対応
- VoiceOver最低限対応

### Should

- Home Screen Widget
- Lock Screen Widget
- PDF Vet Summary
- Family member activity
- iCloud/Cloud sync
- Siri Shortcuts: "Log Momo's medicine"

### Later

- Apple Watch
- Live Activities
- Barcode/label OCR
- Vet clinic sharing link
- Multi-language expansion

## 10. iOS審査・信頼面

医療系に見えやすいため、表現に注意する。

避ける:

- dosage recommendation
- treatment advice
- emergency guidance
- AI diagnosis
- cure / prevent disease claims

使う:

- record
- reminder
- care log
- share with family
- prepare notes for your vet

Termsとオンボーディングに「This app does not provide veterinary medical advice. Follow your veterinarian's instructions.」を入れる。

## 11. App Storeページ設計

### App name候補

- PawDose
- CareTail
- PetMeds Log
- Dose & Paw
- VetNote Pets

一番わかりやすいのは「PetMeds Log」。ブランド性なら「PawDose」。

### Subtitle

Medication, visits, and care

### Screenshots

1. Never miss today's care
2. Track meds for every pet
3. Share routines with family
4. Keep weight and vaccine history
5. Export notes for the vet

### App icon

方向性:

- 薬カプセル + 肉球はありがちなので避ける
- 丸いケアリング + 小さな足跡を抽象化
- 背景はセージグリーン
- 白の細線

## 12. 実装順序

### Phase 1: Paid-quality core

1. Pet setup
2. Today
3. Add medication
4. Local notification
5. Done / Snooze / Skip
6. Weight log
7. Visit note

### Phase 2: Monetization

1. Free limits
2. StoreKit subscription
3. Paywall
4. Restore purchase
5. Trial logic
6. Analytics events

### Phase 3: Retention

1. Widget
2. PDF summary
3. Family sharing
4. Cloud sync
5. App Store screenshots

## 13. Analytics

| Event | 見る理由 |
|---|---|
| pet_created | 初期設定完了 |
| care_created | 価値体験 |
| notification_allowed | 継続利用の前提 |
| care_done | 習慣化 |
| care_skipped | 実利用の摩擦 |
| second_pet_attempted | 課金意図 |
| family_invite_tapped | Family課金意図 |
| vet_summary_tapped | 高価値機能 |
| paywall_viewed | 課金導線 |
| trial_started | 購入意図 |
| subscription_started | 収益 |

最重要は、care_created、care_done、D7 retention。課金率より先に「毎日使われるか」を見る。

## 14. 参考ソース

- Apple HIG Tab Bars: https://developer.apple.com/design/human-interface-guidelines/tab-bars/
- Apple HIG Notifications: https://developer.apple.com/design/human-interface-guidelines/notifications/
- Apple HIG In-App Purchase: https://developer.apple.com/design/human-interface-guidelines/in-app-purchase
- Apple Auto-renewable Subscriptions: https://developer.apple.com/app-store/subscriptions/
