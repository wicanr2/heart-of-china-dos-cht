#!/usr/bin/env bash
# Rebuild the patched ScummVM (dgds engine + CHT overlay) from patches/dgds-cjk.patch.
# Run once on a fresh machine after unpacking the dev tarball (or cloning the repo).
# Output: scummvm-src/scummvm  (point SCUMMVM at it for the packaging scripts).
set -e
cd "$(dirname "$0")"
SCUMMVM_COMMIT=f4526cf007688d02b8c558f048f0889088545fd5   # patch base; keep in sync with patches/

if [ ! -d scummvm-src/.git ]; then
  echo ">> cloning ScummVM @ $SCUMMVM_COMMIT (一次性, ~250MB)"
  git clone https://github.com/scummvm/scummvm scummvm-src
fi
cd scummvm-src
git checkout -q "$SCUMMVM_COMMIT"
# clean any prior CHT changes, then apply the current patch
git checkout -q -- engines/dgds 2>/dev/null || true
echo ">> applying patches/dgds-cjk.patch"
git apply ../patches/dgds-cjk.patch || patch -p1 < ../patches/dgds-cjk.patch
echo ">> configure + build (dgds only)"
./configure --disable-all-engines --enable-engine=dgds --enable-release
make -j"$(nproc)"
echo
echo "OK -> $PWD/scummvm"
echo "下一步："
echo "  export SCUMMVM=\"$PWD/scummvm\"  SCUMMVM_SRC=\"$PWD\""
echo "  # CJK 資產若沒帶到，重建： (需 fonts-noto-cjk + python3 freetype-py)"
echo "  python3 tools/build_cjk_font.py --size 24 --out build/hoc_zh24.dcjk"
echo "  python3 tools/build_cjk_font.py --size 16 --out build/hoc_zh16.dcjk"
echo "  python3 tools/build_translation.py translations/zh.json build/zh.dtr"
echo "  # 然後打包： bash scripts/package_full.sh all   （含遊戲 FULL 自留包）"
