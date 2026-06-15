# Heart of China 中文化

- ScummVM `dgds` 引擎支援此遊戲（`GID_HOC`，引擎本就完整支援）。
- 做法**完全比照姊妹作 Rise of the Dragon**（同 DGDS 引擎，engine-side overlay，patched ScummVM）。
  參考 `~/rise-of-the-dragon/` 與 skill `rise-of-the-dragon-cht`。
- 畫面放大 640×400；中文字 24×24 點陣（Big5），字形選用參考 ~/claude memory。
- **英翻中**，以英文版為原典。
- **對白在 `D<N>.DDS`（不在 SDS）**，key = `(ddsFileNum, num)`；用 `tools/extract_dds.py` 抽取。
- 三條繪字路徑都要 hook（對白 / 名牌+REQ標題 / TTM 畫面文字），漏一條就有英文殘留。
- 遊戲檔案 `@HeartOfChina.zip`；**遊戲本體不入 git**（見 `.gitignore`）。
- github repo：https://github.com/wicanr2/heart-of-china-dos-cht
- 工程計畫見 [`PLAN.md`](PLAN.md)，術語/譯名見 [`CONTEXT.md`](CONTEXT.md)。
