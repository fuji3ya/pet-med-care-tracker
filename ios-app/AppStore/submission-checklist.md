# Tend Pets App Store Submission Checklist

**Last refreshed**: 2026-05-25 (post pre-ship audit + cross-opinion pricing + URL/wording fixes)

## Phase 1: Pre-Apple-Approval (AI 側で完了済)

- [x] Push repository to `github.com/fuji3ya/pet-med-care-tracker`
- [x] GitHub Actions iPhone 15 Simulator build passing
- [x] Code base ship-quality scan: no `TODO/FIXME/fatalError/localhost/prototype` user-facing
- [x] `codemagic.yaml`: REPLACE_WITH_* 削除済、Codemagic Secret Group 経由で runtime injection
- [x] StoreKit JSON pricing 確定 ($4.99/$35.99/$6.99/$49.99, 21-day trial)
- [x] StoreKit JSON プレースホルダー (TEAMID / 1234567890) を Codemagic build script で自動置換
- [x] PaywallView: 21-day trial 明示 + Terms/Privacy リンク追加 + subscription disclosure 完全化
- [x] SettingsView: "prototype" 文言削除済
- [x] Legal pages (privacy/terms/support/index) を `legal/` ディレクトリに self-contained 化
- [x] Cloudflare Pages config (wrangler.toml + _headers + _redirects + DEPLOY.md) 完備
- [x] AppStore/metadata.md URL を `tendpets.starving-effort.com` に更新
- [x] AppStore/metadata.md に account-model + tracking disclosure 追加
- [x] AppStore/app-icon-prompts.md 作成 (4 gpt-image-2 variant)

## Phase 2: Apple Developer 承認後 (user 操作必須)

### 2a. Apple Developer / Developer Portal
- [x] **Apple Developer Program 承認済** (Mirrorbite Day 6 で使用済 / Team ID `YXFS993Z4K`)
- [x] **Team ID 確定**: `YXFS993Z4K`
- [x] **Bundle ID `app.starvingeffort.tendpets` 登録済** (2026-05-25 ASC API 経由、internal id `JHVY32X2U7`、IAP capability auto 付与)
- [ ] Apple Distribution Certificate 作成 (Codemagic Integration 経由で自動)
- [ ] Provisioning Profile (App Store) 作成 (Codemagic Integration 経由で自動)

### 2b. App Store Connect
- [ ] App record 作成: Tend Pets, primary=Medical, secondary=Utilities
- [ ] App Apple ID (10桁数字) 控える
- [ ] API Key 発行 (App Manager role, .p8 ダウンロード)
- [ ] Codemagic Integration `codemagic` に API Key 登録
- [ ] Secret Group `tendpets_app_store_connect` 作成 + `APPLE_TEAM_ID` / `APP_STORE_APPLE_ID` 投入 (ios-app/DevTools/codemagic-secrets-setup.md 参照)
- [ ] Subscription Group `Tend Pets` 作成 → **`python store/setup-asc-iap.py` で全自動化可** (App Apple ID 取得後 env var 投入)
- [ ] 4 products 作成 — 上記 script で 1 コマンド完結 (ID + 価格 + 3週 trial):
  - `tendpets.plus.monthly` $4.99/月 + 3週 trial
  - `tendpets.plus.yearly` $35.99/年 + 3週 trial
  - `tendpets.family.monthly` $6.99/月 + 3週 trial (family shareable)
  - `tendpets.family.yearly` $49.99/年 + 3週 trial (family shareable)
- [ ] App Privacy ラベル (no data collected; UserDefaults 用途のみ)
- [ ] Support email `support@starving-effort.com` 受信可能化 (既存 starving-effort.com zone で Cloudflare Email Routing 設定 ~5 min、forwarding 先は REDACTED-EMAIL 推奨)

### 2c. Legal site
- [x] **Cloudflare Pages deploy 完了** (2026-05-25 AI 側で Mirrorbite credentials 流用)
- [x] **Custom domain `tendpets.starving-effort.com` attach 完了** (REST API、CNAME proxied、Cloudflare auto SSL)
- [x] **全 URL HTTP 200 確認**: `/`, `/privacy`, `/terms`, `/support`
- [x] **Security headers 適用済**: HSTS / CSP / X-Frame-Options / Permissions-Policy

### 2d. App Icon
- [ ] gpt-image-2 で 4 variant 生成 (AppStore/app-icon-prompts.md)
- [ ] 選定 → 1024×1024 RGB no-alpha PNG 保存 → AppIcon-1024.png 上書き
- [ ] 派生 7 size 自動生成 (script in app-icon-prompts.md §選定→派生)

### 2e. Build & Submit
- [ ] Codemagic で `ios-testflight` workflow 実行
- [ ] TestFlight に build 表示確認
- [ ] **物理 iPhone QA**:
  - [ ] First-run onboarding + Skip + Add first care
  - [ ] Settings > Replay onboarding
  - [ ] Notification permission grant + test notification
  - [ ] Care reminder スケジュール + Done/Snooze action 動作
  - [ ] StoreKit sandbox: 4 product 購入 + restore + cancellation
  - [ ] Settings > Delete all pet data confirmation
  - [ ] PaywallView: Terms/Privacy リンク Safari で開く
- [ ] App Store screenshots 5 size 撮影 — Simulator or gpt-image-2 で
- [ ] App Store Connect で metadata 入力 + screenshots upload + Review Notes (metadata.md より)
- [ ] App Review に submit

## Review Safety (絶対遵守)

公開コピーで **使ってはいけない** 単語:
- diagnosis / diagnose
- dosage recommendation / dosing
- treatment advice / prescription
- emergency guidance
- disease prevention
- veterinarian replacement / replace your vet

**使う** 単語:
- reminders / scheduled notifications
- records / care logs / activity logs
- vet visit notes / appointment notes
- follow your veterinarian's instructions

## Risk Watch

- **Support email 開設** — user 操作必須。`support@starving-effort.com` が実在しないと App Review reject 確実
- **Privacy Manifest 完全性** — 2026 Apple 要件で UserNotifications API 宣言が必要な可能性 (二次情報、要 verify)。現状は UserDefaults `CA92.1` のみ
- **AppState の "Momo" demo cat** — review notes に明記済だが、production user は最初に削除する必要あり。UX 影響 minor

## Files Referenced

- `/codemagic.yaml` — Codemagic build pipeline (Phase 1 完成)
- `/legal/` — Cloudflare Pages 配布 source (Phase 1 完成)
- `/ios-app/AppStore/metadata.md` — App Store メタデータ (Phase 1 完成)
- `/ios-app/AppStore/app-icon-prompts.md` — App Icon 4-variant prompts (Phase 2d で実行)
- `/ios-app/AppStore/app-store-connect-form-fillins.md` — **ASC 全 form field copy-paste 用** (Round 5 末追加, Mirrorbite pattern)
- `/ios-app/AppStore/app-review-reject-playbook.md` — **Reject 10 pattern × 英文 response template** (Round 5 末追加)
- `/ios-app/AppStore/testflight-beta-recruitment.md` — **Day 8-11 で 50 名 beta tester 集める Tier 4 template** (Round 5 末追加)
- `/store/derive-assets-from-icon.py` — **1024×1024 から 7 iOS size 自動派生** (Round 5 末追加)
- `/ios-app/DevTools/codemagic-secrets-setup.md` — Codemagic Secret 設定 (Phase 2 用 user manual)
- `/ios-app/DevTools/no-local-mac-release-runbook.md` — End-to-end runbook
- `/release-readiness-audit.md` — overall status tracker

## Step 8 (Screenshots) — Mirrorbite Vault pattern 準拠

⚠️ **AI mockup ではなく TestFlight 実機 screenshot を使う** (Mirrorbite `screenshots-from-testflight.md` 準拠):

| 観点 | gpt-image-2 mockup | TestFlight 実機 |
|---|---|---|
| 真正性 | AI mock → reviewer "fabricated" 疑念 | 実機 native → 異論なし |
| 作業時間 | 5 枚 × 5-10 min = 25-50 min | iPhone で 5 min |
| Guideline 2.3.10 | 不一致 reject リスク | 100% 一致 |

→ Step 7 (物理 iPhone QA) と同じ session で iPhone screenshot 5-10 枚撮影、~5 min で完了。
