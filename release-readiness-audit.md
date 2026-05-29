# Tend Pets Release Readiness Audit

**Date**: 2026-05-25 (was 2026-05-06)
**Goal**: No-local-Mac path to TestFlight and App Store submission readiness.

## Current Status: Yellow → Green-Pending-Approval (Round 2 audit done)

実態:
- AI 側で直せる ship-blocker は **2 round audit で計 28 件駆除済** (Round 1: 8 件 config / Round 2: 20 件 SwiftUI 偽 UI + lifecycle)
- 残ブロッカーは Apple Developer 承認待ち + Apple 承認後の user 操作 (~2h) のみ
- 承認来れば Codemagic + 物理 iPhone QA → submit まで一気通貫
- Round 2 で発見した CRITICAL bug 8 件は Round 1 で完全に見落とした (Mirrorbite 6周 audit と同パターン)

## 2026-05-25 セッション変更履歴

### Round 1: config / metadata / OPSEC 駆除 (8 件)

| ファイル | 変更内容 |
|---|---|
| `ios-app/TendPets/Views/SettingsView.swift` | "prototype" 文言全消 / PaywallView を ScrollView 化 + 21-day trial 明示 + Terms/Privacy リンク追加 |
| `ios-app/StoreKit/TendPets.storekit` | Yearly $39.99→$35.99, Family $8.99/$69.99→$6.99/$49.99, Trial P1W→P3W |
| `codemagic.yaml` | `REPLACE_WITH_APP_STORE_APPLE_ID` 削除、Secret Group 経由 runtime injection + StoreKit JSON / project.yml の placeholder sed 置換 |
| `ios-app/AppStore/metadata.md` | URL 4本を `tendpets.starving-effort.com` に更新 / Subscription Notes に価格表追加 / Review Notes に account-model + tracking 開示追加 |
| `ios-app/AppStore/submission-checklist.md` | Phase 1 (AI 側完了済) / Phase 2 (Apple 承認後 user 操作) に再構成 |
| `ios-app/AppStore/app-icon-prompts.md` | 新規 — gpt-image-2 4 variant prompts (現状アイコンは placeholder) |
| `ios-app/DevTools/codemagic-secrets-setup.md` | 新規 — Codemagic Secret Group `tendpets_app_store_connect` 設定手順 |
| `legal/{index,privacy,terms,support}.html` | self-contained 化 (./styles.css 依存削除)、production 級 copy 追加 (data deletion / no tracking / response time 等) |
| `legal/{wrangler.toml,_headers,_redirects,DEPLOY.md}` | Cloudflare Pages config 新規 (Mirrorbite legal/ pattern 流用) |

### Round 2: SwiftUI 偽 UI 駆除 + lifecycle 改善 (20 件)

CRITICAL 8 件 + HIGH 8 件 + MEDIUM 2 件 + LOW 2 件。詳細は `generated/cross-opinion/2026-05-25-tend-pets-round2-audit.md`

| ファイル | 主な変更 |
|---|---|
| `ios-app/TendPets/Views/TodayView.swift` | ハードコード "Tue May 5 4 of 6 done" / 67% / "Rio"/"Luna" を全て動的計算に置換 (todayProgress / dueOccurrences / laterTodayOccurrences) + Skip dialog に Other 追加 |
| `ios-app/TendPets/Views/PetsView.swift` | "Health overview" 偽 Label 削除、per-pet `activePlans` / `nextVisitText` / `weightSummary` で動的化 + 空ハンドラ Add ボタンを `AddPetSheet` 実装で本物化 |
| `ios-app/TendPets/Views/RecordsView.swift` | `VetSummary` value type で `AppState` から動的構築 (5 section + shareText)、ハードコード demo text 全消 + "Preview PDF" 嘘ラベル→"Open summary" |
| `ios-app/TendPets/Views/SettingsView.swift` | Privacy/Terms in-code text 削除 → 外部 Cloudflare Pages Link に統一 (5.1.1 単一情報源) + Test notification の silent fail に alert + sendTestNotification 確認メッセージ |
| `ios-app/TendPets/Views/AddCareView.swift` | "Heart med"/"1 tablet" prefilled state 空に + save 後 form リセット + Notifications subtext を `isAuthorized` 統一 |
| `ios-app/TendPets/Views/RootView.swift` | onAppear → `.task` + `hasCheckedFirstLaunch` guard で onboarding race fix |
| `ios-app/TendPets/Views/OnboardingView.swift` | step 4 "Momo"/"Heart med" hardcoded → "One pet"/"One routine" generic |
| `ios-app/TendPets/App/AppState.swift` | `addPet()` 追加 + "Alex" hardcoded user name → `currentCaregiverName` "Caregiver" 統一 |
| `ios-app/TendPets/Services/SubscriptionStore.swift` | `isPurchasing` busy state + `Transaction.updates` listener (auto-renew/cancel 反映) + refreshEntitlements flicker fix |
| `ios-app/TendPets/Services/NotificationService.swift` | snooze action 10 min hardcoded → `snoozeDefaultMinutes = 30` static、SnoozeSheet と一貫 |
| `ios-app/TendPets/Services/LocalStorage.swift` | JSON corruption silent → 破損 blob を `*-corrupted-backup` key に保存して recovery 可能化 |
| `ios-app/TendPets/Resources/Info.plist` | `CFBundleIdentifier` / `CFBundleName` / `LSRequiresIPhoneOS` / `UIRequiredDeviceCapabilities` 明示追加 |

## Green (全部実装済)

- Native SwiftUI source under `ios-app`
- iPhone 15 portrait 393×852 として UI 確定
- App Store metadata draft 完成 (Name/Subtitle/Description/Keywords/Review Notes/Subscription Notes)
- Medical safety boundary (no diagnosis/dosage/treatment) 反映
- Privacy/Terms/Support HTML 完成 (`legal/`)
- StoreKit 4 products ID 整合 (Swift code ↔ StoreKit JSON ↔ metadata)
- Codemagic TestFlight + App Store Release workflows 完成 (secret-driven)
- GitHub Actions iPhone 15 Sim build 成功 (run 25407592592)
- PaywallView: loading state / unavailable fallback / restore / subscription terms / no-vet-advice / 21-day trial / Terms+Privacy links
- SettingsView: Notifications / Subscription / Replay onboarding / Export JSON / Disclaimer / Privacy / Terms / Support / Delete-all-data with confirmation
- AppState: full CRUD + markDone/snooze/skip → records 自動生成 + 永続化
- NotificationService: Categories + Done/Snooze actions + auth + delegate routing
- LocalStorage: UserDefaults JSON serialize/deserialize
- Info.plist: NSUserNotificationsUsageDescription + ITSAppUsesNonExemptEncryption=false
- PrivacyInfo.xcprivacy: NSPrivacyTracking=false + UserDefaults `CA92.1`

## Yellow (Apple 承認後 user 操作)

- Apple Developer Program 本承認確認 (5/13 申請、12日経過 — 状況要確認)
- Bundle ID `com.tendpets.app` 取得
- Apple Distribution Certificate + Provisioning Profile
- App Store Connect app record 作成 + App Apple ID 取得 + API Key 発行
- Codemagic Secret Group `tendpets_app_store_connect` 投入
- Legal site Cloudflare Pages deploy (`npx wrangler pages deploy .`)
- App Icon gpt-image-2 で 4 variant 生成 → 選定 → 派生 size 自動生成
- Support email `support@starving-effort.com` 受信可能化
- ASC で 4 subscription products 作成 + 価格設定
- App Privacy ラベル + Review Notes 入力

## Red (Apple 承認 + 上記完了 後)

- Codemagic 署名 IPA 生成
- TestFlight upload
- 物理 iPhone QA (通知 actions + StoreKit sandbox 全 4 products + restore + Settings delete)
- App Store screenshots (5 size, iPhone 6.9"/6.7"/6.5"/5.5"/iPad if needed) 撮影
- ASC submit → Review

## Next Gate

**Apple Developer 承認状況の確認** が最も近い 1 アクション。`REDACTED-EMAIL` 受信箱 or `developer.apple.com/account` で確認。

承認済みなら `ios-app/AppStore/submission-checklist.md` Phase 2 を 2a → 2b → 2c → 2d → 2e の順で 約 2h で TestFlight 提出可能。

## Files Updated This Session (10 files)

1. `ios-app/TendPets/Views/SettingsView.swift`
2. `ios-app/StoreKit/TendPets.storekit`
3. `codemagic.yaml`
4. `ios-app/AppStore/metadata.md`
5. `ios-app/AppStore/submission-checklist.md`
6. `ios-app/AppStore/app-icon-prompts.md` (new)
7. `ios-app/DevTools/codemagic-secrets-setup.md` (new)
8. `legal/index.html` (new)
9. `legal/privacy.html` / `legal/terms.html` / `legal/support.html` (rewritten self-contained)
10. `legal/wrangler.toml` / `legal/_headers` / `legal/_redirects` / `legal/DEPLOY.md` (new)

## GitHub Build Evidence

- Repository: `https://github.com/fuji3ya/pet-med-care-tracker`
- Visibility: private
- Workflow: `Tend Pets iOS Cloud Build`
- Last successful run: `https://github.com/fuji3ya/pet-med-care-tracker/actions/runs/25407592592`
- Commit: `5da18a84ba6117eb77f6be481c137796b5656276`
- Result: iPhone 15 Simulator device created in CI, XcodeGen project generated, SwiftUI app built successfully.

## Cross-opinion Audit Trail

- `generated/cross-opinion/2026-05-25-tend-pets-blocker-rediagnosis.{md,gemma4.md,qwen3.md}` — Apple 承認 priority + Mirrorbite/Tend Pets 並走判断
- `generated/cross-opinion/2026-05-25-tend-pets-pricing-decision.{md,gemma4.md,qwen3.md}` — pricing 5項目 Q&A (Plus monthly/yearly, Family, Trial, Hard paywall)
