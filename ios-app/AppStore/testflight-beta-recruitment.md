# Tend Pets — TestFlight Beta Recruitment Templates

**目的**: TestFlight upload 完了後、**Day 8-11 で 50 名 beta tester** を集めるための DM / 投稿テンプレ。Mirrorbite `store/testflight-beta-recruitment.md` の Tend Pets 版 (pet-owner target + medical-safe wording)。

**前提**: TestFlight Internal Testing で自分の Apple ID は install 済 → External Testing tab で Public Link を発行 (ASC → TestFlight → Public Link / Generate)

**target**: 50 名 (Mirrorbite と同じ baseline)、3 日で集める

---

## Tier 構造 (Mirrorbite pattern)

| Tier | チャネル | ターゲット数 | 期待 conversion |
|---|---|---:|---:|
| 1 | X (@synth_founder_, AI Builders Lab) | 10-20 | 30% click → install (3-6 名) |
| 2 | Reddit (r/CatAdvice, r/Dogtraining, r/Vet) | 50-100 | 5% click → install (3-5 名) |
| 3 | Pet コミュニティ FB Group + Pinterest | 100-300 | 3% click → install (3-9 名) |
| 4 | 個人 DM (友人/知人で pet 飼ってる人) | 20-30 | 50% click → install (10-15 名) |
| **合計** | | | **20-35 install** (50 目標まで 残り 15-30 名は Tier 1 重複募集) |

Mirrorbite と違う点: Tend Pets は **pet owner という具体的 niche** がある (Mirrorbite は「食事気にする人」で広い)。Tier 2 (Reddit) と Tier 4 (個人 DM) の hit rate が高い見込み。

---

## Tier 1: X (Twitter) — 短文 (280 chars)

### @synth_founder_ (English, AI-only ブランド)

```
TestFlight beta: Tend Pets 🐾

Calm iOS app for pet medication, vaccines, weight, and vet visits. No
account, no tracking, all data on-device.

Looking for 20 testers (cat/dog/rabbit/bird/reptile owners). Reply for
TestFlight invite.

#iOSDev #PetCare #TestFlight
```

文字数: ~250 (≤280 OK)

### @ai_builders_lab (Japanese)

```
TestFlight ベータ募集 🐾

Tend Pets — iOS の落ち着いた投薬リマインダー & ペット健康記録アプリ。
アカウント不要・追跡なし・データは端末のみ。

20名募集 (犬/猫/うさぎ/鳥/爬虫類飼育者)。
リプライで TestFlight 招待を送ります。
```

文字数: ~140 (≤140 OK = X 旧上限内)

---

## Tier 2: Reddit — moderation-safe (medical app の self-promo は厳しい)

### r/CatAdvice / r/dogs / r/RabbitHelp / r/Birding 等

⚠️ **Reddit self-promo rule**: 多くの pet sub は self-promotion 禁止。
→ 先に sub の rules を読み、 mod に DM で許可を取る or "Beta Testing" 専用 thread を探す。

### Safe template (mod 許可前提)

```
[Beta] Free iOS app to track pet medication, vaccines, vet visits — looking
for 50 testers

Hi r/{SUBREDDIT}, I built a tiny iOS app called Tend Pets to track my own
cat's medication after I missed a dose. It does:

- Daily/scheduled reminders for meds, food, weight, vet visits, vaccines
- Vet Summary builder (30 days of meds + skipped care + weight trend +
  vaccine history) you can text to your vet before the appointment
- No account, no tracking, all data stays on-device
- iOS only for now (iPhone 6.5"+ / iOS 17+)

Free during TestFlight beta. Paid Plus tier ($4.99/mo) for unlimited pets +
unlimited reminders after launch.

Not a vet tool — just reminders and records. Always follow your vet's advice.

If you want the TestFlight invite, reply or DM with your Apple ID email.

Mod note: I checked the sub rules and DM'd /u/{mod} on {date}; if this
violates a rule I missed, please remove and I apologize.
```

---

## Tier 3: Pet コミュニティ FB Group + Pinterest

### Pinterest (Calm Nook account 経由)

既存 AutoPoster-CalmNook が稼働中 → 1 pin を beta recruitment 用に手動投稿:

- Image: app screenshot (TestFlight 実機から取得した Today / Records 画面)
- Title: `Free pet medication tracker (iOS beta)`
- Description: `Reminders for meds, vaccines, vet visits. No account, on-device. TestFlight beta open — 50 testers wanted.`
- Link: TestFlight Public Link

### FB Group (例: "Senior Dog Owners", "Cat Parents", "Exotic Pet Care")

```
Hi everyone,

I'm an indie developer with one cat (heart medication every morning), and
I built an iOS app called Tend Pets after missing his dose three times in
two weeks. The app is in TestFlight beta and I'm looking for 50 testers.

What it does: medication / vet visit / vaccine / weight reminders, plus a
"Vet Summary" you can text to your vet before the next appointment (last
30 days of meds, skipped doses, weight trend, vaccines).

It does NOT give medical advice. It's reminders and records only.

iOS 17+. Free during beta, then $4.99/month Plus tier after launch (1
free pet + 3 free reminders permanently).

If interested, DM me your Apple ID email and I'll send the TestFlight
invite.

Thanks!
```

---

## Tier 4: 個人 DM (友人/知人)

### Short JP

```
件名: ベータテスター頼みたい (5分でいい)

最近 iOS アプリ作ってて、Tend Pets って投薬リマインダーアプリ。

{name} 確か {pet種} 飼ってたよね？
TestFlight でベータ配ってるから入れてみてもらえる？感想だけくれれば
ok、無料。Apple ID 教えて。
```

### Short EN

```
Hey, I made a tiny iOS app for pet medication reminders. You have {PET},
right? Free TestFlight beta — just need your Apple ID. 5 min install,
text me thoughts. Thanks!
```

---

## TestFlight Public Link 発行

ASC → Tend Pets → TestFlight tab → External Testing → Add Group "Public Beta" →

1. Build を該当 group に attach
2. **"Enable Public Link"** ON
3. URL コピー (例: `https://testflight.apple.com/join/XXXXXXXX`)
4. 各 Tier の post / DM に貼る

⚠️ **Apple は public link で 10000 testers まで** OK (Mirrorbite も同 spec)。50 名 target は十分余裕。

---

## Monitoring (Day 8-11)

毎日 ASC TestFlight tab で確認:

| 指標 | target | watch out |
|---|---|---|
| Sessions | 累計 50+ | 10 名以下 → recruitment 追加 |
| Crash count | 0 | 1 以上 → 即 fix + 新 build |
| Beta feedback | 5+ | low engagement = onboarding issue 疑い |
| Average session length | 60s+ | <30s = aha moment 不足 |

ASC crash reports → 即 Xcode で symbolicate → 該当 plan/reminder type 特定 → fix → 新 build → external testers に push notification 自動再配信。

---

## Beta 完了後 → Production submit

Day 11 終了時点で:
- Crash 0 ✓
- 30 名以上 install ✓
- 1 件以上 feedback 「使える」「役立つ」 ✓

満たせば → ASC で 1.0.0 を **Submit for Review** (本提出)。
満たせなければ → 1.0.1 build に critical fix 入れて beta cycle 1 回追加。

---

## Related

- `app-store-connect-form-fillins.md` — beta build を ASC group に attach する手順
- `app-review-reject-playbook.md` — 本提出 reject 時の response template
- Mirrorbite `store/testflight-beta-recruitment.md` — 原型 (food AI niche)
- [[mobai-mobile-automation]] — 物理 iPhone QA 自動化 skip 確定 (TestFlight 手動 install path 採用)
