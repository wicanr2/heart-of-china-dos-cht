# patches/

ScummVM `dgds` 引擎的繁中化 patch（engine-side overlay + Big5 點陣字 + F8 語言切換）。
**不改任何遊戲檔。** patch base = ScummVM commit `f4526cf`（與 ROTD 相同樹）。

## dgds-cjk.patch（Phase 1 移入）

沿用 [Rise-of-the-dragon-cht](https://github.com/wicanr2/Rise-of-the-dragon-cht) 的
`dgds-cjk.patch`，針對 HOC 調整：

- **對白查表鍵**：HOC 對白來自 `D<N>.DDS`，draw hook（`dialog.cpp drawForeground`）
  對 `GID_HOC` 改用 `lookupDialog(dlg._fileNum, dlg._num)`（ROTD 維持 `scene:num`）。
- 字型 / 譯文檔名：`hoc_zh24.dcjk` / `zh.dtr`。
- 三條繪字路徑（對白 / 名牌+REQ標題 / TTM）hook 沿用。

### 套用 + build

```sh
git clone https://github.com/scummvm/scummvm && cd scummvm
git checkout f4526cf
git apply /path/to/heart-of-china/patches/dgds-cjk.patch
./configure --disable-all-engines --enable-engine=dgds
make -j$(nproc)
```

### 執行期需要的檔案（放遊戲目錄旁）

- `hoc_zh24.dcjk` — `tools/build_cjk_font.py --size 24` 產的 Big5 點陣字。
- `zh.dtr` — `tools/build_translation.py` 打包的譯文。

引擎啟動自動載入；**F8** 切換 英文 / 中文。
