# Heart of China 中文化 — Game-Test 報告

引擎內建 autopilot（`tools/extract_dds.py` 抽鍵 + scummvm `autopilot.txt` 腳本驅動）逐項驗證。
腳本 op：`scene N` / `dlg F:N`（DDS 檔:對白號）/ `menu` / `lang 0|1|2`（英/中24/中16）/ `shot` / `quit`。

## 驗證項目

| 項目 | 結果 | 證據 |
|---|---|---|
| DDS 對白渲染（`(fileNum,num)` 鍵）| ✅ | `screenshots/poc_zh_d12_1.png` |
| 名牌（drawHeader → lookupUI）| ✅ 賽奇/來福/凱特（官方軟體世界譯名）| 同上 |
| 對話框框型：border（drawType2）| ✅ | `showcase_zh_chi.png` |
| 對話框框型：thought bubble（drawType3）| ✅ | `showcase_zh_thought.png` |
| F8 模式：英文（原始）| ✅ | `poc_en_d12_1.png` |
| F8 模式：中文 24×24 | ✅ | `showcase_zh_lucky.png` |
| F8 模式：中文 16×16 | ✅ 一行放得下 | `showcase_zh16.png` |
| 系統主選單（遊玩/控制設定/選項/校準/檔案/離開）| ✅ 全中文 | `showcase_zh_menu.png` |
| 全劇本 Big5 安全 | ✅ 4832 keys、**0 非 Big5** | `build_zh_json.py` |
| 字型缺字 | ✅ **0 缺字** | `build_translation.py` |

## 已知議題與處置

- **多選項對話框 24px 溢出**：少數含 3 個長選項的談判對話（如 `98:36`）在 24×24 下超出對話框
  下緣（英文小字型才塞得下）。
  - 處置 1：對 **190 條編號選項清單**（含「1. 2.」且有 `\r\r`）做 `\r\r`→`\r` 收斂
    （`build_zh_json.collapse_options`），消除選項間多餘空行，一般情況已正常。
  - 處置 2：極端長者按 **F8 切 16×16** 即完整塞入框內（已驗證 `98:36` 16px 無溢出）。
- **系統選單 "PLAY"**：初版漏譯，已補 `UI:PLAY`→「遊玩」。

## 翻譯抽樣（民初冒險通俗派語氣）

| key | EN | ZH |
|---|---|---|
| 12:23 | Great! Mission accomplished! Hong Kong, here we come! | 太好了！任務完成！香港，我們來啦！銀子，我們來啦！ |
| 12:27 | Antidote can only be found in Nepal... in Kathmandu. | 解藥只有尼泊爾才找得到……在加德滿都。 |
| 12:26 | You no understand. Western hospital no can cure snakebite… | 你不懂。西方醫院治不了這種蛇毒。 |

> 翻譯由 46 批多代理平行 workflow 機翻（套譯名表 + Big5 約束），`build_zh_json.py` 合併 +
> 正規化 + 強制套譯名表一致性。譯名見 [`CONTEXT.md`](../CONTEXT.md)。
