# translations/

譯文資料（純資料，改完只要重建 `zh.dtr` 重新部署，免重編引擎）。

- `zh.json` — UTF-8 譯文表。key 兩類：
  - **對白**：`"<ddsFileNum>:<num>"` → 中文（HOC 對白來自 `D<N>.DDS`，key = `(fileNum, num)`）。
  - **UI / 名牌 / TTM**：`"UI:<英文原字串>"` → 中文（trim 頭尾，內部空格逐字對齊）。
- 打包：`python3 tools/build_translation.py translations/zh.json build/zh.dtr`（DTRN、Big5）。

原文劇本 `dialogs_en.json` 由 `tools/extract_dds.py` 從你**合法擁有**的遊戲檔本機重生，
**不入 git**（版權）。
