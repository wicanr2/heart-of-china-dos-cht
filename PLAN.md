# PLAN — Heart of China 繁體中文化

工程計畫與進度。術語見 [`CONTEXT.md`](CONTEXT.md)。做法與姊妹作
[Rise of the Dragon CHT](https://github.com/wicanr2/Rise-of-the-dragon-cht) 相同
（同 DGDS 引擎，engine-side overlay）。

## 目標

把 Dynamix《Heart of China》(1991) 做成可玩的**繁體中文版**，透過自製 patch 的 ScummVM 渲染。
- 對話、UI 按鈕、名牌、TTM 畫面文字全中文。
- 真實 24×24 點陣中文字（畫面放大到 640×400 時清晰）。
- **執行期語言切換鍵 F8**：英文（原始）↔ 中文。
- Ship 三平台：Linux AppImage / Windows / macOS。
- **不重新發布遊戲本體**；本 repo 只放工具、patch、譯文、字型、文件。

## 架構決策（與 ROTD 一致）

1. **基底 = 英文版**。英翻中以英文為原典。
2. **引擎端 overlay，不破壞性注入**。原始遊戲檔不動；ScummVM 繪字當下查譯文表並改用 CJK 字型。
   → 支援語言切換與多語言的唯一乾淨解。
3. **翻譯包**：外部 DTRN（Big5），key 穩定。對白 = **`(ddsFileNum, num)`**（HOC 特有）；
   UI/名牌/TTM = `UI:<src>`。
4. **CJK 字型**：24×24 雙位元組 Big5 點陣字，從 Noto Sans CJK TC rasterize。
5. **語言切換鍵 F8**：dgds keymap 自訂動作，循環顯示模式 + 即時重繪。

## HOC vs ROTD 關鍵差異

| 項目 | ROTD | HOC |
|---|---|---|
| 索引 | `VOLUME.VGA` | `VOLUME.RMF`（同格式）|
| SDS 版本 | ` 1.211` | ` 1.216` |
| **對白存放** | inline SDS，key `scene:num` | **72 個 `D<N>.DDS`**，key `fileNum:num` ⭐ |
| 對白量 | 2,386 句 | **4,651 句** |
| UI | `*.req` | `hinv.req` / `hvcr.req` / `hoc.rst` |

## 元件（deep modules，窄介面）

| 元件 | 路徑 | 狀態 |
|---|---|---|
| 封裝抽取（RMF）| `tools/dgds_volume.py` | ✅ |
| Chunk 解壓（RLE/LZW）| `tools/dgds_chunks.py` | ✅ |
| **DDS 對白抽取（1.216）** | `tools/extract_dds.py` | ✅ 4651 句 |
| TTM 字串抽取 | `tools/extract_ttm_strings.py` | ⬜ |
| UI 抽取（REQ/RST）| `tools/extract_ui.py` | ⬜ |
| CJK 字型產生 | `tools/build_cjk_font.py` | ✅ |
| 翻譯打包（DTRN）| `tools/build_translation.py` | ✅（鍵格式待調）|
| 引擎 patch | `patches/dgds-cjk.patch` | 🚧 移植 + HOC 鍵改 |
| game-tester（autopilot）| `tools/game_tester.py` | ⬜ |

## 階段與進度

### Phase 0 — 逆向 & 抽取 ✅
- [x] `VOLUME.RMF` 索引 / chunk / RLE+LZW 解壓（沿用 ROTD 工具，1206 資源）
- [x] 確認 HOC SDS/DDS 版本 ` 1.216`
- [x] **`extract_dds.py`：抽出全部 4651 句英文對白**（0 失敗）→ `dialogs_en.json`
- [x] Cast 盤點：LUCKY 1513 / CHI 552 / KATE 552 / LOMAX / LI DENG …
- [x] 確認 ScummVM dgds 引擎已支援 `GID_HOC`

### Phase 1 — CJK 字型 + 引擎渲染 PoC ✅
- [x] ScummVM @ `f4526cf` + `dgds-cjk.patch`，build dgds 引擎，HOC 可跑（headless）
- [x] `build_cjk_font.py --size 24` → `hoc_zh24.dcjk`（13709 glyphs，1.4MB）
- [x] **對白鍵改 game-agnostic**：`dialog.cpp drawForeground` 用 `_fileNum ? _fileNum : sceneNum`
      （HOC 走 DDS fileNum、ROTD 走 scene；同一 binary 兩款通吃）
- [x] **autopilot `dlg` 支援 `F:N`**（HOC DDS 對白）：`autopilot.cpp` showDialog(fileNum,num)
- [x] **驗收**：scene d12 對白渲染為「來福，我們不能丟下凱特護士不管！」+ 名牌「賽奇」（官方軟體世界譯名）
      真 24×24（`screenshots/poc_zh_d12_1.png`、`poc_zh_d12_27.png`）

### Phase 2 — 翻譯 overlay + F8 語言切換 ✅（機制）
- [x] `build_translation.py` 鍵格式 `fileNum:num`（對白）+ `UI:<src>`（名牌/UI）— 打包器本就泛用
- [x] 引擎載 `zh.dtr`，對白（drawForeground）+ 名牌（drawHeader lookupUI）查表替換實機驗證
- [x] F8 顯示模式切換 = ROTD patch 既有（setMode；autopilot `lang` 同機制），HOC 沿用
- [ ] 全劇本/全 UI 翻譯後再做逐場景 F8 英↔中視覺複查

### Phase 3 — UI 中文化 + 全量翻譯（4651 句）🚧
- [x] **對白 + 名牌全量翻譯**：`prep_translation.py` 拆出 4508 unique units（4386 對白 + 122 名牌/道具），
      46 批多代理平行機翻（套譯名表、民初冒險語氣、Big5 約束）→ `build_zh_json.py` 合併 +
      正規化（`‧`→`·` 等）+ 強制套譯名表 → **4771/4771 keys、0 缺、0 非 Big5** → `zh.dtr`（228KB，0 缺字）
- [x] **16×16 字型**：`build_cjk_font.py --size 16` → `hoc_zh16.dcjk`（13709 glyphs）；
      F8 循環 `_avail` = 英文 → 中文24 → 中文16（HOC 無 de.dtr，cycleMode 自動略過德文模式）
- [x] 實機驗證：scene d12 多句中文上畫面、24/16 兩種字級（`screenshots/showcase_zh*.png`）
- [x] **UI/選單中文化**：抽 `hvcr.req`/`hinv.req` 玩家可見字串 → `translations/ui_supplement.json`
      （存檔/檔案/選項/控制設定/校準/離開/遊玩 + 確認框 + 校準提示 + GIVE/DROP/EXIT…）；
      `build_zh_json.py` 合併。autopilot 加 `menu` op → 實機驗證**主選單整套中文**
      （`screenshots/showcase_zh_menu.png`）
- [x] **TTM 畫面文字**：HOC 僅 1 條（`ftank3s.ttm` "MEANWHILE"→「與此同時」），已補
- [x] **遊戲文案專家潤稿**：46 批 multi-agent review（資深在地化編輯，套官方手冊劇情脈絡 +
      角色聲音 + 軟體世界語感），**1,879 句改寫**（來福痞氣/賽奇忍者簡潔腔/凱特機伶/鄧利軍閥威）。
      `build_zh_json` overlay `i18n/review/` 於機翻之上。0 非 Big5。

### Phase 4 — game-tester QA + 視覺驗證 ⬜
- [ ] HOC autopilot 腳本，逐場景截圖、排版/斷行 QA、showcase

### Phase 5 — 打包 ✅（Linux/Windows）・📄（macOS CI）
- [x] **Linux**：`scripts/package_linux.sh` → relocatable bundle + `hoc-cht-linux-x86_64.tar.gz`（28M，106 libs）；
      `scripts/package_appimage.sh` → `Heart-of-China-CHT-x86_64.AppImage`（27M）。皆對乾淨遊戲目錄實機驗證中文（--extrapath）。
- [x] **Windows**：`scripts/build_windows.sh`（Docker mingw 交叉編譯 dgds）→ `scummvm.exe`(27M)+SDL2.dll+資產+`.bat` → `hoc-cht-windows-x86_64.zip`（12M）。
      exe 靜態連 C++ runtime（objdump 確認只依 SDL2.dll + 系統 DLL）；wine 下 --version + 偵測/執行 HOC 驗證通過。
- [x] **macOS**：`.github/workflows/build.yml`（macos-14 runner clone scummvm@f4526cf + 套 patch + 產資產 + dylibbundler `.app`）。push 後可在 GitHub Actions 跑出 `Heart of China CHT.app`。
- 安全：dist/ 產物（含/不含遊戲）皆 gitignore，不發布。

## 參考

- ScummVM `dgds` 引擎原始碼（格式權威）。patch base ScummVM `f4526cf`。
- 前作經驗：[Rise of the Dragon CHT](https://github.com/wicanr2/Rise-of-the-dragon-cht)
  + skill `rise-of-the-dragon-cht`（DGDS 中文化完整 SOP）。
