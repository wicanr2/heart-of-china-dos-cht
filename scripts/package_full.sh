#!/usr/bin/env bash
# FULL 自留包：把遊戲本體一起包進去，開機直接進中文版（不需自備遊戲、不退啟動器）。
# 產物標「請勿散布」（含 Dynamix/Sierra 版權遊戲資料）。dist/ gitignore，永不 push。
# 用法: package_full.sh [linux|appimage|windows|all]
set -euo pipefail
cd "$(dirname "$0")/.."
WHAT="${1:-all}"
GAME=game_en
# ScummVM dgds 需要的遊戲資料檔（不含 DOS 執行檔）
gamefiles() { for f in "$GAME"/VOLUME.* "$GAME"/*.RMF "$GAME"/RESOURCE.CFG "$GAME"/TANK.*; do [ -f "$f" ] && echo "$f"; done; }
[ -n "$(gamefiles)" ] || { echo "ERROR: no game data in $GAME/ (VOLUME.RMF…)"; exit 1; }

do_linux() {
  echo ">> Linux FULL tar.gz"
  bash scripts/package_linux.sh >/dev/null
  local B=dist/hoc-cht-FULL-linux-x86_64
  rm -rf "$B"; cp -a dist/hoc-cht-linux-x86_64 "$B"
  mkdir -p "$B/game"; for f in $(gamefiles); do cp "$f" "$B/game/"; done
  # 直接進遊戲的 launcher（遊戲在 game/，永遠存在）
  cat > "$B/玩-中國之心-中文版.sh" <<'L'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/lib:${LD_LIBRARY_PATH:-}"
exec "$HERE/bin/scummvm" --extrapath="$HERE/share/hoc-cht" --path="$HERE/game" --auto-detect "$@"
L
  chmod +x "$B/玩-中國之心-中文版.sh"; rm -f "$B/hoc-cht.sh"
  echo "請勿散布（含遊戲版權資料，僅供合法擁有者自留）。開機：./玩-中國之心-中文版.sh" > "$B/請勿散布.txt"
  ( cd dist && tar czf hoc-cht-FULL-linux-x86_64.tar.gz hoc-cht-FULL-linux-x86_64 )
  echo "   -> dist/hoc-cht-FULL-linux-x86_64.tar.gz ($(du -h dist/hoc-cht-FULL-linux-x86_64.tar.gz|cut -f1))"
}

do_appimage() {
  echo ">> AppImage FULL（開機直接進遊戲）"
  [ -d dist/hoc-cht-linux-x86_64 ] || bash scripts/package_linux.sh >/dev/null
  local A=dist/HOC-CHT-FULL.AppDir
  rm -rf "$A"; mkdir -p "$A/usr/bin" "$A/usr/lib" "$A/usr/share/hoc-cht/game"
  cp dist/hoc-cht-linux-x86_64/bin/scummvm "$A/usr/bin/"
  cp -r dist/hoc-cht-linux-x86_64/lib/. "$A/usr/lib/"
  cp -r dist/hoc-cht-linux-x86_64/share/hoc-cht/. "$A/usr/share/hoc-cht/"
  for f in $(gamefiles); do cp "$f" "$A/usr/share/hoc-cht/game/"; done
  cat > "$A/AppRun" <<'R'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
E="$HERE/usr/share/hoc-cht"
exec "$HERE/usr/bin/scummvm" --extrapath="$E" --path="$E/game" --auto-detect "$@"
R
  chmod +x "$A/AppRun"
  cat > "$A/hoc-cht.desktop" <<'D'
[Desktop Entry]
Type=Application
Name=Heart of China CHT (FULL)
Exec=AppRun
Icon=hoc-cht
Categories=Game;
Terminal=false
D
  cp dist/HOC-CHT.AppDir/hoc-cht.png "$A/hoc-cht.png" 2>/dev/null || : > "$A/hoc-cht.png"
  cp "$A/hoc-cht.png" "$A/.DirIcon" 2>/dev/null || true
  docker run --rm -v "$PWD":/work -w /work rotd-emu:latest bash -c '
    set -e
    command -v curl >/dev/null || { apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq curl file >/dev/null 2>&1; }
    cd /tmp
    curl -fsSL -o ait.AppImage https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x ait.AppImage; ./ait.AppImage --appimage-extract >/dev/null 2>&1
    cd /work; ARCH=x86_64 /tmp/squashfs-root/AppRun dist/HOC-CHT-FULL.AppDir dist/Heart-of-China-CHT-FULL-x86_64.AppImage 2>&1 | tail -3
    chmod a+rwx dist/Heart-of-China-CHT-FULL-x86_64.AppImage 2>/dev/null || true'
  echo "   -> dist/Heart-of-China-CHT-FULL-x86_64.AppImage ($(du -h dist/Heart-of-China-CHT-FULL-x86_64.AppImage 2>/dev/null|cut -f1))"
}

do_windows() {
  echo ">> Windows FULL zip"
  [ -f dist/hoc-cht-windows-x86_64/scummvm.exe ] || bash scripts/build_windows.sh >/dev/null
  local B=dist/hoc-cht-FULL-windows-x86_64
  rm -rf "$B"; cp -a dist/hoc-cht-windows-x86_64 "$B"
  mkdir -p "$B/game"; for f in $(gamefiles); do cp "$f" "$B/game/"; done
  cat > "$B/玩-中國之心-中文版.bat" <<'L'
@echo off
chcp 65001 >nul
"%~dp0scummvm.exe" --extrapath="%~dp0extra" --path="%~dp0game" --auto-detect
L
  echo "請勿散布（含遊戲版權資料，僅供合法擁有者自留）。" > "$B/請勿散布.txt"
  ( cd dist && rm -f hoc-cht-FULL-windows-x86_64.zip && zip -qr hoc-cht-FULL-windows-x86_64.zip hoc-cht-FULL-windows-x86_64 )
  echo "   -> dist/hoc-cht-FULL-windows-x86_64.zip ($(du -h dist/hoc-cht-FULL-windows-x86_64.zip|cut -f1))"
}

case "$WHAT" in
  linux) do_linux;; appimage) do_appimage;; windows) do_windows;;
  all) do_linux; do_appimage; do_windows;;
  *) echo "usage: $0 [linux|appimage|windows|all]"; exit 1;;
esac
echo "FULL 打包完成（含遊戲，自留勿散布）。"
