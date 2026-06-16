#!/usr/bin/env bash
# Inject the HOC game + CJK assets into the CI-built base APK (assets/games/china/) and re-sign
# -> a self-contained 繁中 Android APK that installs and boots straight into the Chinese game.
# Game data is injected LOCALLY (never goes to GitHub/CI). Runs in Docker (host clean).
# 個人自留：僅供合法擁有遊戲者，請勿散布。
#
# Usage: tools/inject_android.sh [base.apk]   (default: dist/ci/hoc-cht-android.apk)
#   先把 CI 的 hoc-cht-android artifact 放到 dist/ci/hoc-cht-android.apk
set -e
cd "$(dirname "$0")/.."
BASE="${1:-dist/ci/hoc-cht-android.apk}"
GAMES="build/android_games"
GAME_SRC="game_en"
[ -f "$BASE" ] || { echo "base APK not found: $BASE (下載 CI hoc-cht-android artifact 到此)"; exit 1; }
[ -f build/zh.dtr ] || { echo "missing build/zh.dtr (run build_translation.py)"; exit 1; }
[ -f build/android_libs/libc++_shared.so ] || { echo "missing build/android_libs/libc++_shared.so (arm64, NDK r26d sysroot)"; exit 1; }

# Assemble the china game bundle: game data + canonical localization assets (engine loads
# dragon_zh{24,16}.dcjk by name). Refresh assets from build/ so a stale snapshot can't ship old 譯文.
rm -rf "$GAMES/china"; mkdir -p "$GAMES/china"
for f in "$GAME_SRC"/VOLUME.* "$GAME_SRC"/*.RMF "$GAME_SRC"/RESOURCE.CFG "$GAME_SRC"/TANK.*; do [ -f "$f" ] && cp "$f" "$GAMES/china/"; done
cp -f build/zh.dtr "$GAMES/china/zh.dtr"
cp -f build/hoc_zh24.dcjk "$GAMES/china/dragon_zh24.dcjk"
cp -f build/hoc_zh16.dcjk "$GAMES/china/dragon_zh16.dcjk"
echo "android_games china zh.dtr md5: $(md5sum "$GAMES/china/zh.dtr" | cut -d' ' -f1)"

docker run --rm -v "$PWD":/work -w /work ubuntu:24.04 bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq openjdk-17-jdk-headless wget unzip zip >/dev/null 2>&1
  export ANDROID_SDK_ROOT=/opt/asdk
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"; cd /tmp
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O ct.zip
  unzip -q ct.zip -d "$ANDROID_SDK_ROOT/cmdline-tools"
  mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  yes | "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1 || true
  "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" "build-tools;35.0.0" >/dev/null
  BT="$ANDROID_SDK_ROOT/build-tools/35.0.0"

  cd /work
  rm -rf /tmp/stage
  # ScummVM extracts the inner assets/ tree (assets/assets/...) and mass-adds games found under
  # files/assets/games -> game must live at assets/assets/games/<id> (DOUBLE assets) AND be listed
  # in assets/MD5SUMS, else neither extracted nor detected.
  mkdir -p /tmp/stage/assets/assets/games
  cp -r build/android_games/china /tmp/stage/assets/assets/games/
  cp "'"$BASE"'" /tmp/work.apk

  # Runtime native-lib closure the CI base APK is missing (libscummvm -> liboboe -> libc++_shared):
  mkdir -p /tmp/stage/lib/arm64-v8a
  wget -q https://dl.google.com/dl/android/maven2/com/google/oboe/oboe/1.9.0/oboe-1.9.0.aar -O /tmp/oboe.aar
  unzip -q -o /tmp/oboe.aar -d /tmp/oboe
  cp "$(find /tmp/oboe -name liboboe.so -path "*arm64*" | head -1)" /tmp/stage/lib/arm64-v8a/liboboe.so
  cp build/android_libs/libc++_shared.so /tmp/stage/lib/arm64-v8a/libc++_shared.so

  # Append game files to MD5SUMS (paths relative to files/ = "assets/games/china/<f>") so ScummVM
  # treats assets as updated -> re-extracts (incl. game) + runs the one-shot bundled-game mass-add.
  unzip -o -q /tmp/work.apk "assets/MD5SUMS" -d /tmp/md5
  ( cd /tmp/stage/assets && find assets/games -type f | sort | xargs md5sum ) >> /tmp/md5/assets/MD5SUMS
  cp /tmp/md5/assets/MD5SUMS /tmp/stage/assets/MD5SUMS

  ( cd /tmp/stage && zip -qr /tmp/work.apk assets lib )
  zip -q -d /tmp/work.apk "META-INF/*" >/dev/null 2>&1 || true

  "$BT/zipalign" -p -f 4 /tmp/work.apk /tmp/aligned.apk
  keytool -genkeypair -keystore /tmp/debug.ks -alias hoc -storepass android -keypass android \
    -dname "CN=HOC-CHT" -keyalg RSA -keysize 2048 -validity 10000 >/dev/null 2>&1
  "$BT/apksigner" sign --ks /tmp/debug.ks --ks-pass pass:android --key-pass pass:android \
    --out /work/dist/hoc-cht-android-FULL.apk /tmp/aligned.apk
  "$BT/apksigner" verify /work/dist/hoc-cht-android-FULL.apk && echo "SIGNED OK"
  chmod a+rw /work/dist/hoc-cht-android-FULL.apk
'
ls -la dist/hoc-cht-android-FULL.apk 2>/dev/null && \
  echo "完整中文 APK -> dist/hoc-cht-android-FULL.apk（全新安裝即可，開機直接進中文版）"
