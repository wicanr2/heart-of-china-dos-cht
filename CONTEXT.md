# CONTEXT — Heart of China 繁體中文化

Domain glossary。寫程式、命名變數、寫文件時一律使用以下術語。姊妹作見
[`rise-of-the-dragon`](../rise-of-the-dragon/CONTEXT.md)（同 DGDS 引擎）。

## Game / engine

- **HOC** — Heart of China（Dynamix / Sierra On-Line，1991）。本案中文化目標。
- **DGDS** — Dynamix Game Development System；資源/腳本引擎。ScummVM `dgds` 引擎可跑
  （game id `GID_HOC`）。引擎本身已完整支援 HOC（`hoc_intro.cpp`、`minigames/china_tank`、
  `china_train`、`shell_game`）。_Avoid_：「SCUMM 引擎」（那是別款）。
- **Volume** — `VOLUME.00x` 資源封裝。**`VOLUME.RMF` 是索引**（salt + 每卷資源表）。
  格式與 ROTD 的 `VOLUME.VGA` 相同，`tools/dgds_volume.py` 直接可用。
- **Resource** — volume 內具名項（12-char 名 + size header + 資料）。HOC 共 1206 個。
- **Chunk** — resource 內的具型區塊：4-byte id 以 `:` 結尾（`DDS:`、`SDS:`、`TT3:`…）+ size。
  size 高位 = container。部分 LZW/RLE 壓縮。
- **SDS** — 場景腳本（`s<NN>.sds`）。HOC 版本 ` 1.216`（ROTD 為 ` 1.211`）。
  **HOC 的 SDS 不含對白**（version ≥1.214 改由 DDS 載入）。
- **DDS** — ⭐ **對白資料**（`d<N>.dds`）。HOC 把玩家可見對白放在 **72 個 `D<N>.DDS`** 檔，
  經 `Scene::loadDialogData` 載入。每筆對白 = `(fileNum, num)`。_這是與 ROTD 最大的差異。_
- **TDS** — 對話頭像/動畫資料（talk data），**非**玩家可見文字。
- **TTM / ADS** — 動畫/序列腳本。readable 字串多為內部 TAG 標籤；少數 `TT3:` 內的
  drawString 是畫面文字（電腦/電報/站名等），要中文化。
- **REQ / RST** — UI request（選單/物品欄/對話框）版面 + 按鈕文字。HOC：`hinv.req`（物品欄）、
  `hvcr.req`、`hoc.rst`。
- **內建中文字型** — HOC 本身就帶 `chinese.fnt` / `china.fnt` / `hoc.fnt`（劇情有中文場景）。
  作排版/字距參照，但我們的 CJK overlay 用自製 24×24 Big5 點陣字。

## Localization

- **Dialog slot** — 單一可譯單位，key = **`(ddsFileNum, num)`**（HOC）。原文一個 `_str`，
  行以 `\r` 分隔。_Avoid_：用 `(scene, num)`（那是 ROTD 的鍵）。
- **Base game** — **英文版**。英翻中以英文為原典。
- **Source encoding** — DOS **CP437**。
- **三條繪字路徑**（漏一條就有英文殘留）：①對白內文 `dialog.cpp drawForeground`
  ②名牌/選單/REQ 標題 `request.cpp drawHeader` ③TTM 畫面文字 `ttm.cpp`。
- **顯示模式 / F8** — 英文（原始）↔ 中文 24×24，執行時即時切換 + 重繪（架構預留 16×16/日文）。
- **產物**：`zh.json`（UTF-8 譯文）→ `build_translation.py` → `zh.dtr`（DTRN、Big5）；
  `build_cjk_font.py` → `hoc_zh{24,16}.dcjk`；引擎改動 = `patches/dgds-cjk.patch`。

## 譯名表（character / proper-noun glossary）— 官方軟體世界譯名（譯名考古）

**主要角色一律採 1990s 軟體世界中文版說明書的官方譯名**（攻略/珍108 手冊還原；
`tools/build_zh_json.py` 的 `RENAME`/`CANON` 強制套用，覆蓋初版機翻草稿）。
說話人標籤格式：`LUCKY:` → `來福：`（全形冒號）；名牌鍵大寫對齊。

| 英文 | 官方中文 | 出現 | 備註（初版機翻草稿 → 官方更正）|
|---|---|---|---|
| Lucky（Jake Masters）✓ | **來福** | 1513 | 主角，吊兒郎當的美國冒險飛行員。全名傑克馬斯特斯。〔機翻草稿「老馬」→ 官方**來福**〕|
| Chi（Zhao Chi）✓ | **齊豪** | 552 | **中國忍者**，來福的搭檔。手冊明載「中國忍者齊豪(Zhao Chi)」。短稱「奇」。〔機翻「趙奇」→ 官方**齊豪**〕|
| Kate（Kate Lomax）✓ | **凱蒂** | 552 | 被綁架的報業千金，後成戀人 |
| Lomax（E.A. Lomax）✓ | **羅梅士** | 139 | 凱蒂之父，美國報業富賈。〔機翻「羅麥斯」→ 官方**羅梅士**〕|
| Li Deng / Deng ✓ | **鄧利**（軍閥）| 18 | 反派軍閥，盤據四川成都。手冊作「軍閥鄧利」（姓鄧名利）。〔機翻「李鄧」→ 官方**鄧利**〕|
**配角音譯定案**（手冊只收錄主角群 5 名；以下依角色與名源音譯，鎖進 `build_zh_json.CANON`）：

| 英文 | 中文 ✓ | 出現 | 地域 / 角色 |
|---|---|---|---|
| Sardar ✓ | 薩達爾 | 119 | 尼泊爾/印度・惡漢頭目（波斯/印地語「首領」）|
| Ama ✓ | 阿瑪 | 111 | 尼泊爾・洗衣老婦（Nepali「母親/長者」尊稱）|
| Mohmar / Momar ✓ | 莫瑪 | 76 | 土耳其・男子（自稱第三人稱）|
| Wu ✓ | 吳 | 70 | 中國・草藥店大夫 |
| Ho ✓ | 何 | 56 | 中國 |
| Kubla ✓ | 庫布拉 | 54 | 跨場景・賣油怪咖（原作 Kubla，全音譯，非「忽必」）|
| Lama ✓ | 喇嘛 | 54 | 尼泊爾/西藏・高僧（職稱）|
| Bijaya ✓ | 比賈亞 | 51 | 尼泊爾・當地人（Nepali 名）|
| Almira ✓ | 艾米拉 | 42 | 伊斯坦堡・女子 |
| Hoji ✓ | 霍吉 | 38 | 土耳其・侍者 |
| Kasim ✓ | 卡辛 | 37 | 伊斯坦堡・二手商店老闆（Qasim）|
| Bojon ✓ | 波瓊 | 35 | |
| Hakim ✓ | 哈金 | 31 | 土耳其（Arabic Hakim）|
| Acayib ✓ | 阿賈伊布 | 22 | 土耳其・駱駝行老闆（含尾音 b）|
| Nalini ✓ | 娜莉妮 | 19 | 尼泊爾/印度・搭訕女子（梵「蓮」）|
| Jyapu ✓ | 賈普 | — | 尼泊爾・農夫（Newar 種姓）|
| Nabob ✓ | 納波布 | — | 印度・權貴（nawab）|
| Tong ✓ | 童 | — | 中國・坦克追逐 |
| Disciple ✓ | 弟子 | — | 廟中弟子（職稱）|
| Yankee Eagle ? | 洋基之鷹（號）| — | 來福的飛機 |

職稱/群體一律意譯：守衛(Guard)、士兵(Soldier)、農夫(Peasant)、老婦(Old Woman)、打手(Goon)、
記者(Reporter)、商人(Merchant)、移民官(Immigration Official)、售票員(Ticket Agent) 等。

地名：中國（成都/上海/香港）→ 尼泊爾（加德滿都）→ 印度 → 伊斯坦堡（東方快車）。

## Flagged ambiguities

- 主角 Lucky：官方一律「來福」（軟體世界譯名）。"Jake Masters" 全名作「傑克馬斯特斯」；
  "Mr. Masters" 作「馬斯特斯先生」。`build_zh_json.RENAME` 已把初版機翻「老馬」全數正名為「來福」。
- 尼泊爾/印度/土耳其配角音譯 `?` 項，於翻譯該段落時逐一定案，回填本表。
- `Li Deng` 反派：官方軟體世界譯名作「鄧利」（姓鄧名利）+「軍閥」職稱，已採用。
