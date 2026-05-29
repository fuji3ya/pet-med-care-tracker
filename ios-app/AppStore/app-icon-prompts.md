# Tend Pets App Icon — gpt-image-2 Prompts (v2, reference-driven)

**Date**: 2026-05-29 — v2 rewrite per design-reference-first rule.
**Status**: v1 prompts (2026-05-25) は私の想像で書かれてた = 規約違反。本 v2 は実物 top performer reference を見てから書き直し。

## なぜ v1 を捨てたか

v1 は「私はこうだろう」で書かれてた。design-reference-first rule:
> 「売れてる実プロダクトを北極星に固定 → 必ず実物の画像を Read して見る → 記憶で語らない」

実物を見るまで prompt 書くなというルール。v2 はその通り実行した。

## 北極星: Pet Care Tracker Dog Cat Log

- App Store ID: 1551003273
- Rating: **4.82⭐ / 923 reviews** ← pet category 内で唯一の信頼できる sample
- icon の特徴 (実物確認 2026-05-29):
  - 明るい黄色背景 (#FFD700 系)
  - ネイビー (#1a2a4a) 犬+猫シルエット
  - 高 contrast = ホーム画面で 1 秒テスト pass
  - 主題明確 (= 「ペットアプリ」即伝達)
  - 装飾フラット OK だが subject が立ってる

→ reference: `generated/research/tend-pets-design-refs/Pet_Care_Tracker_Dog_Cat_Log_icon.png`

## 現状 Tend Pets icon (v1) の問題

- 緑背景 + 白 progress ring + オレンジ arc = pet 要素ゼロ
- Apple Fitness / Strava と区別つかない generic tracker icon
- Anti-Flat checklist 全項目 fail
- 1 秒テスト不合格

→ `ios-app/TendPets/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` (要差し替え)

## 戦略

**目的**: Pet Care Tracker level の「pet で 1 秒テスト pass」を達成。ただし copy せず差別化。

**差別化軸**:
- Pet Care Tracker = 鮮やかな yellow + 黒シルエット (popular family-pet feel)
- Tend Pets = **calm sage green** + 暖色 accent + ペット要素 (premium / medical / vet-ready feel)
- 11pets = scammy banner / 古い UI → **絶対真似ない**

**Brand color** (Tend Pets):
- Primary: sage green `#2E6F5E` (現状維持、calm 訴求)
- Accent: warm apricot/peach `#E8A87C` or cream `#F4DBC0`
- Subject ink: deep ink `#1A1A1A` or warm brown `#3E2C1C`

## 4 variant prompts (v2)

### A. 主案 — 犬+猫の頭部上半身シルエット (Top performer pattern 直接適用)

```
A bold flat-style app icon, square 1:1 aspect ratio.
Background: solid calm sage green (#2E6F5E), no gradient, fills entire canvas.
Subject: silhouettes of a cat (left, smaller, sitting) and a medium dog (right, slightly taller, sitting attentively, head tilted slightly toward the cat) — both rendered in warm cream color (#F4DBC0), facing forward, simple flat shapes.
The cat and dog touch shoulders, forming a gentle "family" pair, centered on the canvas with 12% breathing-room padding (Apple iOS safe zone).
No text, no logos, no shadows, no medical symbols.
Style: editorial flat illustration, modern indie iOS app icon, friendly but adult/premium feel.
Reference style: app store "Best Free Pet App" winners — high contrast, identifiable in 1 second at small sizes, recognizable even at 40×40 px.
Output: solid PNG, 1024×1024, RGB, no transparency.
```

### B. 副案 — 単一動物 + 投薬ハート (medical 訴求強い)

```
A flat app icon, square 1:1 ratio.
Background: solid sage green (#2E6F5E).
Subject: silhouette of a cat or small dog face viewed from front, centered, rendered in warm cream (#F4DBC0), simple geometric flat shapes with rounded edges. The animal has a tiny heart shape on its chest/collar in soft apricot (#E8A87C).
Composition: centered with generous breathing room (Apple iOS safe zone), no text, no medical cross icon (avoid clinical feel).
Style: friendly editorial flat illustration, premium indie iOS app, suitable for a pet health utility.
Output: solid PNG, 1024×1024, RGB, no transparency.
```

### C. 抽象 — 抱きしめる手 + ペット (関係性訴求)

```
A flat app icon, square 1:1.
Background: warm cream (#F4DBC0).
Subject: a stylized sage-green silhouette of a small cat or dog being gently held — represented by a curved abstract hand/arm shape cradling the animal silhouette. Both rendered as flat geometric shapes, sage green (#2E6F5E) on cream background.
The composition conveys "care" without being literal (no fingernails, no realistic anatomy).
No text, no medical symbols, centered with 12% padding.
Style: minimal editorial flat illustration, modern indie iOS app.
Output: solid PNG, 1024×1024, RGB, no transparency.
```

### D. パターン破り — 動物の足跡 (subject-less だが pet 要素確実)

```
A flat app icon, square 1:1.
Background: solid sage green (#2E6F5E), with a subtle warm cream (#F4DBC0) circular halo softly glowing in the center.
Subject: one large stylized cat-paw print, centered, rendered in warm cream color, flat geometric shape (no realistic fur texture). The paw print has 4 toe pads and one main pad, classic cat/dog paw silhouette.
Composition: centered with 15% padding (more generous — paw print is the only element).
No text, no medical icons.
Style: minimal editorial flat illustration, premium iOS app feel.
Output: solid PNG, 1024×1024, RGB, no transparency.
```

## 共通生成ガイド

- ChatGPT (gpt-image-2) で 1 prompt ずつ実行
- 各 prompt から 1-2 候補生成 → 計 4-8 候補から 1 つ選定
- 選定後: 1024×1024 PNG → RGB no-alpha flatten 確認 (Apple 必須)
- `python store/derive-assets-from-icon.py` で 7 size 自動派生

## NG 例 (これは作らない)

- 注射器 / シリンジ / 薬瓶 = 医療臭強すぎ、calm 印象崩す
- 赤十字 = WHO 商標問題 + 商標訴訟リスク
- 心電図波形 = clinical 過ぎ、user 怖がる
- 漫画調 / chibi 風 / 大きい目 = Pet Care Tracker と同じになる
- グラデーション = flat 系 reference と一貫しない
- 影/反射 = 不要、Apple iOS は影自動付与

## 選定 → 派生 size 生成

選定後の処理:

```bash
cd REDACTED-PATH/generated/pet-med-care-tracker
python store/derive-assets-from-icon.py
# → AppIcon-{40,58,60,80,87,120,180}.png 全自動派生
```

## 1 秒テスト (合格基準)

ホーム画面 60×60 px サイズで:
- [ ] 「これはペットアプリ」と即わかる
- [ ] Apple Fitness / 一般 tracker と区別つく
- [ ] ペット要素 (silhouette / paw / pet face) が読める
- [ ] sage green ベースで brand 一貫

1 つでも fail なら再生成。

## 関連

- design audit: `generated/research/tend-pets-design-refs/DESIGN_AUDIT.md`
- top performer reference: `generated/research/tend-pets-design-refs/Pet_Care_Tracker_Dog_Cat_Log_icon.png`
- rule: `.claude/rules/design-reference-first.md`
- rule: `.claude/rules/design-and-branding.md`
- skill: `art-direction-memory` (合格資産の蓄積)
