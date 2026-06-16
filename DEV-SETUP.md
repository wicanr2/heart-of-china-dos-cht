# 在另一台電腦重建開發環境

從 **dev+materials tarball** 在新機器上重建、編譯、打包整個《中國之心》中文化專案 ——
連遊戲本體與參考資料（軟體世界手冊/雜誌掃描）都包在裡面，**不需另外上 GitHub 抓或外部找**。

> tarball 由 `bash scripts/make_dev_tarball.sh` 產生，含版權素材（遊戲 + 手冊掃描），
> **僅供你個人在自己機器間搬移，請勿散布**。GitHub 上只有不含版權物的 repo。

## 這包裡有什麼

| 路徑 | 是什麼 | 來源 |
|---|---|---|
| `patches/dgds-cjk.patch` | ScummVM dgds 引擎 CHT + Android patch（**source of truth**，1600+ 行）| git |
| `patches/android-*.patch` | Android surface-race + autostart-china | git |
| `translations/zh.json` | 全劇本譯文（UTF-8，4832 條目）→ `build/zh.dtr` | git |
| `translations/ui_supplement.json` | UI/選單/TTM 手譯 | git |
| `tools/` | `extract_dds`(對白) / `build_cjk_font` / `build_translation` / `build_zh_json` / `prep_translation` / `inject_android` / `game_tester` … | git |
| `scripts/` | `package_linux` / `package_appimage` / `build_windows` / `package_full` | git |
| `docs/GAME_TEST_REPORT.md` | QA 三輪驗收 + 修正紀錄 | git |
| `CONTEXT.md` / `PLAN.md` / `CLAUDE.md` | 術語/譯名表（官方軟體世界譯名）/ 工程計畫 / 專案須知 | git |
| `setup-dev.sh` | clone ScummVM@f4526cf + 套 patch + build | git |
| **`game_en/`** | ⭐ **遊戲本體**（VOLUME.RMF + VOLUME.001-007 + RESOURCE.CFG + TANK.*）— 版權，個人自留 | 你的合法副本 |
| **`攻略/`** | ⭐ **參考資料**：軟體世界中文版說明書掃描（珍108，33 頁）+《軟體世界》第30/31期 PDF + `中國之心-說明書.md`(OCR 全文轉錄) | 版權素材，個人自留 |
| `build/hoc_zh{24,16}.dcjk`、`build/zh.dtr` | 編好的 CJK 點陣字 + 譯文包（可由 tools 重建）| 重建 |
| `build/android_libs/libc++_shared.so` | Android 注入用 runtime（arm64, NDK r26d）| 重建/沿用 |
| ~~`scummvm-src/`~~ | **不在包裡**（~900MB）— `setup-dev.sh` clone 重建 | — |
| ~~`dist/`~~、~~`i18n/`~~、~~`res/`~~ | **不在包裡** — 重建即生成 | — |

## 重建步驟

```bash
tar xzf hoc-cht-DEV+MATERIALS.tar.gz && cd heart-of-china

# 依賴 (Debian/Ubuntu)
sudo apt install build-essential git libsdl2-dev libfreetype-dev libpng-dev \
                 fonts-noto-cjk fonts-wqy-zenhei python3-pip docker.io
python3 -m pip install --user freetype-py pillow      # 重建字型用

# 1. 重建 patched ScummVM (clone f4526cf + 套 patch + build dgds)
bash setup-dev.sh
export SCUMMVM="$PWD/scummvm-src/scummvm"  SCUMMVM_SRC="$PWD/scummvm-src"

# 2. （若 build/ 沒帶到）重建 CJK 資產
python3 tools/build_cjk_font.py --size 24 --out build/hoc_zh24.dcjk
python3 tools/build_cjk_font.py --size 16 --out build/hoc_zh16.dcjk
python3 tools/build_translation.py translations/zh.json build/zh.dtr

# 3. 打包（含遊戲的 FULL 自留包）
bash scripts/package_full.sh all     # -> dist/hoc-cht-FULL-{linux,windows}* + AppImage
```

## 從遊戲檔重新抽對白（若要重跑翻譯流程）

```bash
python3 tools/dgds_volume.py game_en --extract res          # 1206 資源
python3 tools/extract_dds.py res dialogs_en.json            # 4651 句對白
python3 tools/prep_translation.py dialogs_en.json i18n      # 拆 unit + 名牌
# (翻譯後) python3 tools/build_zh_json.py → build/zh.dtr
```

## 改東西時

- **只改翻譯**：編 `translations/zh.json` → `python3 tools/build_zh_json.py` → 部署各平台 `zh.dtr`
  （Linux `share/hoc-cht/`、Win/Mac `extra/`、Android bundle、AppImage 在映像內）。**免重編引擎**。
- **改引擎**：改 `scummvm-src/engines/dgds/*` → `make` → 重產 patch：
  `(cd scummvm-src && git diff HEAD -- engines/dgds) > patches/dgds-cjk.patch` → 全平台重編。
- **commit/push**：remote = `git@github.com:wicanr2/heart-of-china-dos-cht.git`。
  `game_en/`、`攻略/`、`dist/`、`i18n/`、`res/`、`scummvm-src/` 全 gitignore，**永不 push**。

## Mac / Android（走 CI，再本地組裝）

`.github/workflows/build.yml`（push `patches/**`、`translations/**`、`tools/**` 觸發）在 CI 編出
不含遊戲的 macOS `.app` 與 Android base APK；本地再把遊戲組進去：

```bash
gh run download <run-id> -n hoc-cht-macos   -D dist/ci && tar xzf dist/ci/*.tar.gz -C dist/
bash scripts/package_full.sh mac            # 注入遊戲 + 包裝執行檔 -> dist/hoc-cht-FULL-mac.tar.gz

gh run download <run-id> -n hoc-cht-android -D dist/ci
mv dist/ci/hoc-cht-android.apk dist/ci/   # (artifact 內就是 apk)
bash tools/inject_android.sh dist/ci/hoc-cht-android.apk   # -> dist/hoc-cht-android-FULL.apk
```

完整 SOP 與所有踩過的坑見 skill `rise-of-the-dragon-cht`（HOC 差異節）與 `docs/GAME_TEST_REPORT.md`。
