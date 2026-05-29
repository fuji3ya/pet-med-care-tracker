# Tend Pets Legal Site — Cloudflare Pages Deploy

**目的**: `tendpets.starving-effort.com/{,privacy,terms,support}` を Apple App Review 提出までに公開する。

**所要時間**: 約 10 分 (user 操作)。

## 0. 前提

- Cloudflare アカウント (既存 starvingeffort.app zone があれば custom domain 同時設定可)
- `npx wrangler` 利用可能 (Node 20+)

## 1. Wrangler ログイン (初回のみ)

```bash
cd REDACTED-PATH/generated/pet-med-care-tracker/legal
npx wrangler login
# → ブラウザで Cloudflare 認証
```

Mirrorbite で既に login 済なら **再ログイン不要** (`~/.wrangler/config/default.toml` に session 保存)。

## 2. Pages プロジェクト作成 + 初回 deploy

```bash
cd REDACTED-PATH/generated/pet-med-care-tracker/legal
npx wrangler pages deploy . \
  --project-name=tendpets-legal \
  --branch=main \
  --commit-dirty=true
```

成功するとプロジェクト URL が表示される:
```
https://tendpets.starving-effort.com/
```

この時点で動作確認:
- `https://tendpets.starving-effort.com/` (index)
- `https://tendpets.starving-effort.com/privacy`
- `https://tendpets.starving-effort.com/terms`
- `https://tendpets.starving-effort.com/support`

**Apple は .pages.dev URL を直接受け付ける** ので、custom domain なしで ASC submit 可能。

## 3. (オプション) カスタムドメイン

将来 `starvingeffort.app/tendpets/*` or `tendpets.app` に切替たい場合:

### 3a. starvingeffort.app/tendpets (Mirrorbite と umbrella 統一)

Cloudflare dashboard → Pages → `tendpets-legal` → Custom domains:
1. **Add Custom Domain** → `starvingeffort.app`
2. Path mapping: `/tendpets/*` をこのプロジェクト root に向ける

### 3b. tendpets.app 独自ドメイン取得

`tendpets.app` を Cloudflare Registrar or 外部で取得 → Cloudflare DNS に追加 → Pages の Custom domain で割当。

→ 切替時は本ファイル + `ios-app/AppStore/metadata.md` の URL を更新して再 commit。

## 4. デプロイ検証チェックリスト

```bash
# レスポンス確認
curl -I https://tendpets.starving-effort.com/privacy
curl -I https://tendpets.starving-effort.com/terms
curl -I https://tendpets.starving-effort.com/support
# すべて 200 / Content-Type: text/html を返すこと

# 本文確認
curl -sS https://tendpets.starving-effort.com/privacy | grep -i "Last updated"

# セキュリティヘッダ確認
curl -I https://tendpets.starving-effort.com/ | grep -iE "Strict-Transport|Content-Security|X-Frame"
```

## 5. ASC metadata 反映

`ios-app/AppStore/metadata.md` の URL 4 本を最新の deploy URL に揃える:

- Privacy Policy URL: `https://tendpets.starving-effort.com/privacy`
- Terms of Use URL: `https://tendpets.starving-effort.com/terms`
- Support URL: `https://tendpets.starving-effort.com/support`

## 6. 以後の更新 deploy

```bash
cd REDACTED-PATH/generated/pet-med-care-tracker/legal
# privacy.html などを編集後:
npx wrangler pages deploy . \
  --project-name=tendpets-legal \
  --branch=main \
  --commit-dirty=true
```

数十秒で世界中に伝播。

## 7. Rollback

事故った場合は Cloudflare dashboard → Pages → `tendpets-legal` → Deployments → 1 つ前を **Promote to production**。手動 30 秒。
