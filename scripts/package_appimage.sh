#!/usr/bin/env bash
# Build a single-file AppImage from the relocatable Linux bundle. AppDir assembled on
# host; appimagetool runs in Docker (no host pollution / no FUSE needed).
# Output: dist/Heart-of-China-CHT-x86_64.AppImage
set -euo pipefail
cd "$(dirname "$0")/.."
BUNDLE="dist/hoc-cht-linux-x86_64"
APPDIR="dist/HOC-CHT.AppDir"
[ -d "$BUNDLE" ] || { echo "run scripts/package_linux.sh first (need $BUNDLE)"; exit 1; }

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/hoc-cht"
cp "$BUNDLE/bin/scummvm"          "$APPDIR/usr/bin/"
cp -r "$BUNDLE/lib/."             "$APPDIR/usr/lib/"
cp -r "$BUNDLE/share/hoc-cht/."   "$APPDIR/usr/share/hoc-cht/"

cat > "$APPDIR/AppRun" <<'RUN'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
SV="$HERE/usr/bin/scummvm"; EXTRA="$HERE/usr/share/hoc-cht"
has_game() { [ -f "$1/VOLUME.RMF" ] || [ -f "$1/volume.rmf" ] || [ -f "$1/VOLUME.001" ]; }
if [ $# -ge 1 ] && [ -d "$1" ]; then
  exec "$SV" --extrapath="$EXTRA" --path="$1" --auto-detect
fi
APPDIR_OF_IMG="$(dirname "$(readlink -f "${APPIMAGE:-$0}")")"
for base in "$APPDIR_OF_IMG" "$PWD"; do
  has_game "$base" && exec "$SV" --extrapath="$EXTRA" --path="$base" --auto-detect
  for d in "$base"/*/; do
    [ -d "$d" ] && has_game "$d" && exec "$SV" --extrapath="$EXTRA" --path="$d" --auto-detect
  done
done
exec "$SV" --extrapath="$EXTRA"
RUN
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/hoc-cht.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Heart of China CHT
Comment=中國之心 繁體中文版 (patched ScummVM)
Exec=AppRun
Icon=hoc-cht
Categories=Game;
Terminal=false
DESK

# Icon: crop of a Chinese showcase screenshot (256x256), else a 漢字 placeholder.
if command -v convert >/dev/null 2>&1 && [ -f screenshots/showcase_zh_lucky.png ]; then
  convert screenshots/showcase_zh_lucky.png -gravity center -crop 360x360+0-20 +repage \
    -resize 256x256 "$APPDIR/hoc-cht.png" 2>/dev/null || \
    convert -size 256x256 xc:'#1a2030' -fill '#e8c87a' -gravity center -pointsize 120 \
      -annotate 0 "心" "$APPDIR/hoc-cht.png"
else
  : > "$APPDIR/hoc-cht.png"
fi
cp "$APPDIR/hoc-cht.png" "$APPDIR/.DirIcon" 2>/dev/null || true

docker run --rm -v "$PWD":/work -w /work rotd-emu:latest bash -c '
  set -e
  command -v curl >/dev/null || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq curl file >/dev/null 2>&1; }
  cd /tmp
  curl -fsSL -o appimagetool.AppImage \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool.AppImage
  ./appimagetool.AppImage --appimage-extract >/dev/null 2>&1
  cd /work
  ARCH=x86_64 /tmp/squashfs-root/AppRun dist/HOC-CHT.AppDir \
    dist/Heart-of-China-CHT-x86_64.AppImage 2>&1 | tail -5
  chmod a+rwx dist/Heart-of-China-CHT-x86_64.AppImage 2>/dev/null || true
'
ls -la dist/Heart-of-China-CHT-x86_64.AppImage 2>/dev/null && \
  echo "AppImage built." || echo "AppImage build did not produce output (check log above)."
