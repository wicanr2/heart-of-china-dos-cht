# Heart of China 繁體中文化（中國之心）

> 把 1991 年的環球冒險《Heart of China》（Dynamix / Sierra）做成可玩的**繁體中文版** —
> 透過自製 patch 的 ScummVM、真實點陣中文字、與一份逐句重譯的中文劇本。
>
> 🚧 **進行中。** 全劇本 **4,651 句**已從遊戲檔挖出（英文原版），中文化引擎機制沿用
> 姊妹作《Rise of the Dragon》已驗證的 **engine-side overlay**：真實 **24×24 點陣中文字**
> 直接畫在遊戲畫面上，按 **F8** 即時切換 **英文 / 中文**。

## 🎬 實機展示

> 「洋基之鷹」號機艙內 —— 老馬剛把凱特救出來，正準備飛往香港。全程繁體中文、真 **24×24 點陣字**，
> 名牌、對白、思考泡泡都中文化。以下截圖都是**引擎內建 autopilot 自動跑出來的**（照腳本跳場景、
> 強制觸發指定 `(DDS檔,對白號)`、截圖存檔，逐句檢查中文排版）。

![showcase 老馬](screenshots/showcase_zh_lucky.png)

> 老馬：「太好了！任務完成！香港，我們來啦！銀子，我們來啦！」

| 趙奇（對話框）| 老馬（思考泡泡）|
|---|---|
| ![chi](screenshots/showcase_zh_chi.png) | ![thought](screenshots/showcase_zh_thought.png) |
| 趙奇：「你不懂。西方醫院治不了這種蛇毒。」| 老馬心想：「唉喲！女人啊！」（thought-bubble 框型）|

**同一句台詞，按 F8 切換 英文（原始）↔ 中文：**

| 原版（英文） | 中文化（本專案）|
|---|---|
| ![en](screenshots/poc_en_d12_1.png) | ![zh](screenshots/poc_zh_d12_1.png) |
| `CHI: Lucky, we can't leave without Nurse Kate!` | `趙奇：老馬，我們不能丟下凱特護士就走！` |

> ✅ **全劇本 4,651 句已翻完**（4,771 個翻譯條目、0 個非 Big5 字），民初冒險通俗派語氣。

---

## 三十年前，我在一款看不懂的遊戲裡「回到了」中國

那是 1990 年代初。14 吋 CRT 的光映在一個孩子臉上，螢幕裡是 1930 年代的香港鴉片館、
成都的軍閥城寨、加德滿都的廟宇、開往伊斯坦堡的東方快車 —— 一個美國飛行員，帶著一個
中國武術家，橫越半個地球去救一個被綁架的報業千金。遊戲叫《Heart of China》，
畫面是當年罕見的真人數位化照片，劇情又急又險。而那個孩子，連主選單都讀不順。

最弔詭的是：這是一款講「中國」的遊戲，裡頭的中國卻是用英文寫的。他看著螢幕上那座
寫著看不懂的字的城寨，在腦子裡替老馬和趙奇配上一整套自己編的中文台詞。卡住了就翻
《電腦玩家》《軟體世界》《PC Game》—— 那個年代沒有 GameFAQ、沒有 wiki、沒有 Discord，
攻略是用印刷油墨換來的。

那個孩子是我。三十年後，我把當年腦補的每一句，換成真正的譯文 —— 一句一句，全劇本 4,651 句。

---

## 關於《Heart of China》

**Dynamix 開發、Sierra On-Line 發行，1991 年，Jeff Tunnell 設計**（與《Rise of the Dragon》
同一位設計師、同一套 DGDS 引擎）。

- **時間是 1930 年代，舞台橫跨半個地球。** 你是 Jake「Lucky」Masters（**老馬**），
  一個落魄、嗜賭、開著一架叫「洋基之鷹」破飛機的美國冒險家。報業富商 E.A. Lomax 雇你去
  成都，從軍閥 **李鄧** 的城寨裡救出他女兒 **凱特**。你拉上了忍術高手 **趙奇** 當搭檔，
  從香港、成都，一路逃到加德滿都、印度，最後上了開往伊斯坦堡的東方快車。
- **畫面在當年是狠角色。** 跟《Rise of the Dragon》一樣，用**真人演員的數位化照片**合成
  漫畫分鏡，搭配手繪背景，像在演一部互動電影。
- **它有即時時鐘、有多重結局、會讓你死很多次** —— 並且穿插坦克、火車、街頭「三杯猜豆」
  等小遊戲。

> 資料來源：[Wikipedia](https://en.wikipedia.org/wiki/Heart_of_China_(video_game))、
> [MobyGames](https://www.mobygames.com/game/207/heart-of-china/)、
> [Dynamix Wiki](https://dynamix.fandom.com/wiki/Heart_of_China)。

---

## 譯名：為什麼主角叫「老馬」？

這一作走的是**民初冒險通俗派**：一款講 1930 年代中國的遊戲，名字就該有那個年代的江湖味。
主角 Jake "Lucky" Masters 是個吊兒郎當、神運氣護身、心裡藏著俠氣的美國冒險飛行員 ——
我們不音譯成「拉奇」，而叫他**老馬**（取其姓 Masters，又帶一股「老江湖」的味道）。
中國角色給道地的中文名（趙奇、軍閥李鄧），西方與各地配角依時代與地域音譯。

完整譯名對照見 [`CONTEXT.md`](CONTEXT.md)。

---

## 這個專案做了什麼

ScummVM 的 `dgds` 引擎已經能執行這款遊戲，所以我們**不碰遊戲本體的執行邏輯**，
而是在 ScummVM 這一層動手腳（與《Rise of the Dragon》中文化同一套機制）：

1. **把劇本挖出來** — HOC 的對白藏在 72 個壓縮過的 `D<N>.DDS` 對白檔裡（不像前作放在場景檔）。
   我們照著 ScummVM 引擎原始碼寫了 `tools/extract_dds.py`，抽出全部 **4,651 句**英文對白。
2. **重新翻成繁體中文** — 以英文原典為準。
3. **讓引擎看得懂中文** — 替 ScummVM 加上**真實 24×24 點陣中文字**。
4. **可以切換語言** — 遊戲中按 **F8** 即時切 **英文 / 中文**。原始遊戲檔完全不動，中文是「疊」上去的。

> 你手上那份合法擁有的原版遊戲檔不會被改壞；中文是一層可開可關的外掛。

---

## 目前進度

| 階段 | 內容 | 狀態 |
|---|---|---|
| Phase 0 | 格式逆向、劇本抽取（4,651 句）、引擎基線 | ✅ 抽取完成 |
| Phase 1 | 24×24 中文字型 + 引擎渲染 PoC（中文已上畫面）| ✅ |
| Phase 2 | 翻譯 overlay + F8 語言切換（機制驗證）| ✅ |
| Phase 3 | 全量翻譯（**4,651 句對白 + 122 名牌全翻**，0 非 Big5）・UI/TTM | 🚧 對白✅ ・ UI/TTM 進行中 |
| Phase 4 | game-tester 自動截圖 QA | ⬜ |
| Phase 5 | 打包 Linux / Windows / macOS | ⬜ |

完整工程計畫見 [`PLAN.md`](PLAN.md)、術語/譯名見 [`CONTEXT.md`](CONTEXT.md)。

---

## 版權聲明

《Heart of China》原始版權屬 **Dynamix / Sierra**（現屬其權利繼承者）。
**本專案不包含、也不重新發布任何遊戲原始檔。** 這裡所有的工具、patch、譯文、字型，
皆為衍生的中文化作品，僅供**已合法擁有原版遊戲**的玩家使用。
遊戲執行倚賴開源的 [ScummVM](https://www.scummvm.org/)。

## 致謝

- **ScummVM 團隊** — `dgds` 引擎讓這款老遊戲在現代機器上重生，也是逆向格式的權威依據。
- **Dynamix / Jeff Tunnell** — 在 1991 年就把環球冒險電影搬進遊戲。
- 繁體點陣字採用開源字型（Noto Sans CJK TC、文泉驛、AR PL UMing）rasterize 而成。
- 前作經驗：[Rise of the Dragon 繁中化](https://github.com/wicanr2/Rise-of-the-dragon-cht)。
