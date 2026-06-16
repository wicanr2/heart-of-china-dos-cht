#!/usr/bin/env bash
# Produce a self-contained dev+materials tarball so the WHOLE project can be rebuilt on another
# machine — including the game and the copyrighted reference materials (軟體世界 manual/magazine).
# Excludes the big rebuildable dirs (scummvm-src ~900MB, dist, i18n, res, build cache).
# Output: ../hoc-cht-DEV+MATERIALS.tar.gz  (含版權物，個人自留勿散布)
set -e
cd "$(dirname "$0")/.."
ROOT="$(pwd)"; NAME="$(basename "$ROOT")"
TMP="/tmp/hoc-cht-DEV+MATERIALS.tar.gz"
OUT="$(cd .. && pwd)/hoc-cht-DEV+MATERIALS.tar.gz"

[ -f build/hoc_zh24.dcjk ] || echo "  (note: build/hoc_zh24.dcjk 不存在，新機需跑 build_cjk_font.py 重建)"

echo ">> packing $NAME (stage in /tmp, move to parent)"
echo "   include: 原始碼 + .git + game_en/ + 攻略/ + build/(資產)"
echo "   exclude: scummvm-src/ dist/ i18n/ res/ build/android_games/ *.o __pycache__"
( cd .. && tar czf "$TMP" \
    --exclude="$NAME/scummvm-src" \
    --exclude="$NAME/dist" \
    --exclude="$NAME/i18n" \
    --exclude="$NAME/res" \
    --exclude="$NAME/build/android_games" \
    --exclude="*.o" --exclude="__pycache__" --exclude="*.pyc" \
    --exclude="$NAME/game_en/HOC.EXE" \
    --exclude="$NAME/game_en/INSTALL.COM" \
    "$NAME" )
mv -f "$TMP" "$OUT"
echo
echo "OK -> $OUT"
du -h "$OUT" 2>/dev/null | cut -f1 | sed 's/^/   size: /'
echo "新機重建：tar xzf hoc-cht-DEV+MATERIALS.tar.gz && cd $NAME && bash setup-dev.sh  （見 DEV-SETUP.md）"
