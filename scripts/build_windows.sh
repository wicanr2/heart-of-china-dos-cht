#!/usr/bin/env bash
# Cross-compile the patched ScummVM (dgds only) for Windows x86_64 via mingw-w64 + SDL2
# in Docker (host stays clean; HOC patched source copied, not built in place), then
# assemble the full Windows bundle (scummvm.exe + DLLs + CHT assets + .bat) and zip it.
# Output: dist/hoc-cht-windows-x86_64/ + dist/hoc-cht-windows-x86_64.zip
set -e
cd "$(dirname "$0")/.."
SRC="${SCUMMVM_SRC:-$PWD/scummvm-src}"
SDL2VER=2.30.9
[ -d "$SRC/engines/dgds" ] || { echo "ERROR: HOC patched scummvm-src not found at $SRC"; exit 1; }
for a in build/zh.dtr build/hoc_zh24.dcjk build/hoc_zh16.dcjk; do [ -f "$a" ] || { echo "ERROR: missing $a"; exit 1; }; done

docker run --rm -v "$PWD":/work -v "$SRC":/src:ro -w /work rotd-emu:latest bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq g++-mingw-w64-x86-64 mingw-w64-tools curl xz-utils >/dev/null 2>&1
  cd /tmp
  curl -fsSL -o sdl2.tar.gz \
    https://github.com/libsdl-org/SDL/releases/download/release-'"$SDL2VER"'/SDL2-devel-'"$SDL2VER"'-mingw.tar.gz
  tar xf sdl2.tar.gz
  SDLDIR=/tmp/SDL2-'"$SDL2VER"'/x86_64-w64-mingw32
  export PATH="$SDLDIR/bin:$PATH"
  mkdir -p /tmp/build && cp -a /src/. /tmp/build/ 2>/dev/null || true
  cd /tmp/build
  rm -rf .git; rm -f scummvm scummvm.exe config.log config.mk 2>/dev/null || true
  find . -name "*.o" -delete 2>/dev/null || true
  HOST=x86_64-w64-mingw32
  ./configure --host=$HOST --disable-all-engines --enable-engine=dgds \
    --with-sdl-prefix="$SDLDIR/bin" \
    --disable-fluidsynth --disable-flac --disable-mad --disable-vorbis \
    --disable-theoradec --disable-faad --disable-mpeg2 --disable-a52 \
    --disable-libcurl --disable-sndio --disable-timidity --disable-sparkle \
    --disable-nuked-opl --disable-eventrecorder \
    >/tmp/wincfg.log 2>&1 || { echo "CONFIGURE FAILED"; tail -30 /tmp/wincfg.log; exit 1; }
  echo "=== configure OK; building dgds (few min) ==="
  make -j"$(nproc)" >/tmp/winmake.log 2>&1 || { echo "MAKE FAILED"; tail -40 /tmp/winmake.log; exit 1; }
  $HOST-strip scummvm.exe || true
  OUT=/work/dist/hoc-cht-windows-x86_64
  mkdir -p "$OUT/extra"
  cp scummvm.exe "$OUT/"
  cp "$SDLDIR/bin/SDL2.dll" "$OUT/" 2>/dev/null || true
  # Bundle only the non-system DLLs the exe ACTUALLY imports (ScummVM statically links
  # the mingw C++ runtime, so libstdc++/libgcc/winpthread are usually NOT imported).
  IMPORTS=$($HOST-objdump -p scummvm.exe | awk "/DLL Name/{print tolower(\$3)}")
  for dll in libgcc_s_seh-1 libstdc++-6 libwinpthread-1; do
    echo "$IMPORTS" | grep -q "$dll.dll" || continue
    f=$(find /usr/lib/gcc/$HOST /usr/$HOST/lib -name "$dll.dll" 2>/dev/null | head -1)
    [ -n "$f" ] && cp "$f" "$OUT/" && echo "  + $dll.dll (imported)"
  done
  ls -la "$OUT/scummvm.exe"
  echo BUILD_OK
  chmod -R a+rw "$OUT"
'

OUT="dist/hoc-cht-windows-x86_64"
[ -f "$OUT/scummvm.exe" ] || { echo "Windows build failed (no exe)"; exit 1; }

# CHT assets (engine loads dragon_zh{24,16}.dcjk by name)
cp build/hoc_zh24.dcjk "$OUT/extra/dragon_zh24.dcjk"
cp build/hoc_zh16.dcjk "$OUT/extra/dragon_zh16.dcjk"
cp build/zh.dtr        "$OUT/extra/zh.dtr"

# .bat launcher: drag-drop game folder, or auto-detect, else launcher
cat > "$OUT/玩-中國之心-中文版.bat" <<'BAT'
@echo off
chcp 65001 >nul
set HERE=%~dp0
if not "%~1"=="" (
  "%HERE%scummvm.exe" --extrapath="%HERE%extra" --path="%~1" --auto-detect
  goto :eof
)
if exist "%HERE%VOLUME.RMF" (
  "%HERE%scummvm.exe" --extrapath="%HERE%extra" --path="%HERE%" --auto-detect
  goto :eof
)
"%HERE%scummvm.exe" --extrapath="%HERE%extra"
BAT

cat > "$OUT/README.txt" <<'DOC'
中國之心 (Heart of China) 繁體中文版 — Windows (patched ScummVM)
=============================================================
把你合法擁有的《Heart of China》遊戲資料夾（含 VOLUME.RMF + VOLUME.001..007）
拖放到「玩-中國之心-中文版.bat」上即可；或把本資料夾放進遊戲資料夾後直接執行 .bat。
遊戲中按 F8 循環：英文 → 中文 24×24 → 中文 16×16。
中文是疊在原始遊戲上的 overlay，不改動遊戲檔。不含任何遊戲原始檔。
DOC

( cd dist && zip -qr "hoc-cht-windows-x86_64.zip" "hoc-cht-windows-x86_64" )
echo "----"
echo "Windows bundle: $OUT"
echo "zip: dist/hoc-cht-windows-x86_64.zip ($(du -h dist/hoc-cht-windows-x86_64.zip | cut -f1))"
echo "DLLs: $(ls "$OUT"/*.dll 2>/dev/null | xargs -n1 basename | paste -sd' ')"
