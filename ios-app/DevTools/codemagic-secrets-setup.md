# Codemagic Secrets Setup — Tend Pets

**目的**: Apple Developer 承認後、Codemagic で TestFlight / App Store ビルドを成功させるために必要なシークレット 2 本を Codemagic Secret Group `tendpets_app_store_connect` に登録する。

**所要時間**: 約 5 分 (Apple 承認済み + Codemagic ログイン済前提)。

## 0. 前提

- Apple Developer Program **承認済み** (Apple ID `REDACTED-EMAIL`)
- Codemagic アカウントに GitHub repo `fuji3ya/pet-med-care-tracker` を接続済み
- App Store Connect で Tend Pets app record 作成済 (Bundle ID `app.starvingeffort.tendpets`)
- App Store Connect API Key (.p8) 発行済 + Codemagic Integration `codemagic` 設定済

## 1. 必要な 2 つの値を Apple 側で取得

| 値 | 取得場所 | 例 |
|---|---|---|
| **APPLE_TEAM_ID** | developer.apple.com → Membership Details → Team ID | `ABC1234567` (10桁英数字) |
| **APP_STORE_APPLE_ID** | App Store Connect → Apps → Tend Pets → App Information → Apple ID | `1234567890` (10桁数字、ASCで自動採番) |

## 2. Codemagic Secret Group 登録

Codemagic UI:
1. Teams → Personal Account → Integrations → Environment variables
2. **Add group** → name: `tendpets_app_store_connect`
3. 以下 2 環境変数を追加 (Secure ON):

| Name | Value | Secure |
|---|---|---|
| `APPLE_TEAM_ID` | (Step 1 の値) | ✅ |
| `APP_STORE_APPLE_ID` | (Step 1 の値) | ✅ |

4. Save group

## 3. ワークフロー実行

Codemagic UI → Tend Pets → **Start new build** → workflow `ios-testflight` 選択 → Start。

ビルドが `Inject signing values into project.yml and StoreKit config` step で 2 環境変数を読み取り、`project.yml` の `DEVELOPMENT_TEAM` と `TendPets.storekit` の `_developerTeamID` / `_applicationInternalID` を runtime で置換する。

ビルド成功後、自動的に TestFlight に submit される (codemagic.yaml の `publishing.app_store_connect.submit_to_testflight: true`)。

## 4. トラブルシュート

### `ERROR: APPLE_TEAM_ID and APP_STORE_APPLE_ID must be set`
→ Secret group が ワークフロー で reference されていない。`codemagic.yaml` の `environment.groups` に `tendpets_app_store_connect` が含まれていることを確認。

### Build success but TestFlight に表示されない
→ App Store Connect Integration `codemagic` が `tendpets_app_store_connect` Secret group に含まれていない可能性。Codemagic UI → Teams → Integrations → App Store Connect で確認。

### Signing error: profile not found
→ App Store Connect で Bundle ID `app.starvingeffort.tendpets` が登録されていない。developer.apple.com → Identifiers → 追加 → Tend Pets / `app.starvingeffort.tendpets` 作成。

## 5. ロールバック

`codemagic.yaml` の旧版に戻したい場合:
```bash
cd REDACTED-PATH/generated/pet-med-care-tracker
git log --oneline -- codemagic.yaml
git checkout <commit> -- codemagic.yaml
```

## 6. セキュリティノート

- `APPLE_TEAM_ID` と `APP_STORE_APPLE_ID` は **本来 機密 ではない** (App Store ページ・証明書から外部から見える) が、Codemagic の運用統一のため Secure 扱い
- 真のクレデンシャル (App Store Connect API Key .p8 / Apple ID password / Distribution Certificate p12) は Codemagic Integration 側で管理され、本リポには **絶対 commit しない**
