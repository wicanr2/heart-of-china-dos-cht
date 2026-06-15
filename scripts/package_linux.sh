#!/usr/bin/env bash
# Package the patched ScummVM + Heart of China CHT language assets into a relocatable
# Linux bundle (bin + bundled libs + assets + launcher) and a .tar.gz. Pure host
# file-ops; nothing installed system-wide. Output: dist/. User supplies their own
# legally-owned HOC game data (VOLUME.RMF + VOLUME.00x).
set -euo pipefail
cd "$(dirname "$0")/.."
SV="${SCUMMVM:-$PWD/scummvm-src/scummvm}"
NAME="hoc-cht-linux-x86_64"
OUT="dist/$NAME"
# engine loads dragon_zh{24,16}.dcjk by name -> ship HOC fonts under those names.
FONT24="build/hoc_zh24.dcjk"; FONT16="build/hoc_zh16.dcjk"; DTR="build/zh.dtr"

[ -x "$SV" ] || { echo "ERROR: scummvm binary not found at $SV"; exit 1; }
for a in "$FONT24" "$FONT16" "$DTR"; do [ -f "$a" ] || { echo "ERROR: missing asset $a (run build_cjk_font / build_translation)"; exit 1; }; done

rm -rf "$OUT"; mkdir -p "$OUT/bin" "$OUT/lib" "$OUT/share/hoc-cht"
cp "$SV" "$OUT/bin/scummvm"

# Keep these from the user's SYSTEM (glibc/kernel + GPU/display stack must match host).
KEEP_SYSTEM='ld-linux|/libc\.|/libm\.|/libdl\.|/libpthread\.|/librt\.|/libresolv\.|linux-vdso|/libGL|/libGLX|/libGLdispatch|/libX11|/libxcb|/libXext|/libXcursor|/libXi|/libXrandr|/libXfixes|/libXrender|/libwayland|/libdrm|/libgbm|/libEGL|/libOpenGL'
echo "Bundling libraries (excluding system glibc/display stack)..."
ldd "$SV" | awk '{print $3}' | grep -E '^/' | sort -u | while read -r lib; do
  echo "$lib" | grep -qE "$KEEP_SYSTEM" && continue
  cp -L "$lib" "$OUT/lib/" 2>/dev/null && echo "  + $(basename "$lib")"
done

cp "$FONT24" "$OUT/share/hoc-cht/dragon_zh24.dcjk"
cp "$FONT16" "$OUT/share/hoc-cht/dragon_zh16.dcjk"
cp "$DTR"    "$OUT/share/hoc-cht/zh.dtr"

cat > "$OUT/hoc-cht.sh" <<'LAUNCH'
#!/usr/bin/env bash
# 《中國之心》(Heart of China) 繁體中文版 launcher。
# 用法: ./hoc-cht.sh [你的遊戲資料夾]
#   給資料夾 -> 直接啟動；不給 -> 自動偵測旁邊/CWD 的遊戲，否則開 ScummVM 啟動器。
# 遊戲中按 F8 循環顯示模式：英文 / 中文24 / 中文16。
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/lib:${LD_LIBRARY_PATH:-}"
SV="$HERE/bin/scummvm"; EXTRA="$HERE/share/hoc-cht"
has_game() { [ -f "$1/VOLUME.RMF" ] || [ -f "$1/volume.rmf" ] || [ -f "$1/VOLUME.001" ]; }
if [ $# -ge 1 ] && [ -d "$1" ]; then
  exec "$SV" --extrapath="$EXTRA" --path="$1" --auto-detect
fi
for base in "$HERE" "$PWD"; do
  has_game "$base" && exec "$SV" --extrapath="$EXTRA" --path="$base" --auto-detect
  for d in "$base"/*/; do
    [ -d "$d" ] && has_game "$d" && exec "$SV" --extrapath="$EXTRA" --path="$d" --auto-detect
  done
done
exec "$SV" --extrapath="$EXTRA"
LAUNCH
chmod +x "$OUT/hoc-cht.sh"

cat > "$OUT/README.txt" <<'DOC'
中國之心 (Heart of China) 繁體中文版 (patched ScummVM bundle)
==========================================================

把 Dynamix《Heart of China》(1991) 中文化的 patched ScummVM。中文是「疊」在原始英文
遊戲上的 overlay，不改動你的遊戲檔。角色採 1990s 軟體世界官方譯名（來福/賽奇/凱特）。

需要準備
  你自己合法擁有的一份《Heart of China》遊戲資料夾（內含 VOLUME.RMF + VOLUME.001..007）。

啟動（三選一）
  1) 自動偵測：把本資料夾放到遊戲資料夾旁/裡，執行 ./hoc-cht.sh
  2) 指定路徑： ./hoc-cht.sh /路徑/到/你的/遊戲資料夾
  3) 啟動器：   ./hoc-cht.sh （找不到遊戲時）開 ScummVM 介面，手動加入一次即可。

預設就是中文。遊戲中按 F8 循環：英文(原始) → 中文 24×24 → 中文 16×16。

內容
  bin/scummvm        patched ScummVM（dgds 引擎 + CJK 模組）
  lib/               隨附函式庫（SDL2、freetype、fluidsynth、codecs…）
  share/hoc-cht/     語言資產：zh.dtr(譯文)、dragon_zh24/16.dcjk(點陣字型)

說明
  - 相依你系統的 glibc 與顯示(GL/X11/Wayland)堆疊，適用多數現代 x86_64 Linux。
  - 不含、也不重新發布任何遊戲原始檔；版權屬 Dynamix / Sierra 之權利繼承者。
DOC

mkdir -p dist
( cd dist && tar czf "$NAME.tar.gz" "$NAME" )
echo "----"
echo "bundle : $OUT"
echo "tarball: dist/$NAME.tar.gz ($(du -h "dist/$NAME.tar.gz" | cut -f1))"
echo "libs bundled: $(ls "$OUT/lib" | wc -l)"
