#!/usr/bin/env bash
# Compila o APK sem Gradle: aapt2 + javac + d8 + zipalign + apksigner.
# Antes, o workflow coloca o motor (brs-engine) em assets/web/lib e assets/web/assets.
# Uso: ANDROID_HOME=... ./build.sh [versionCode]
set -euo pipefail
cd "$(dirname "$0")"
API=34
BT_VER=${BT_VER:-34.0.0}
BT="$ANDROID_HOME/build-tools/$BT_VER"
JAR="$ANDROID_HOME/platforms/android-$API/android.jar"
CODE=${1:-1}
NAME=$(grep -o 'VERSION = "[^"]*"' src/com/elvanoq/rokusim/Sim.java | cut -d'"' -f2)
for f in assets/web/lib/brs.api.js assets/web/lib/brs.worker.js assets/web/lib/brs-sg.js assets/web/assets/common.zip; do
  test -s "$f" || { echo "faltando $f (motor brs-engine não foi montado)"; exit 1; }
done
rm -rf build && mkdir -p build/classes build/dex
echo "== aapt2 compile"
"$BT/aapt2" compile --dir res -o build/res.zip
echo "== aapt2 link"
"$BT/aapt2" link -o build/base.apk -I "$JAR" --manifest AndroidManifest.xml -A assets build/res.zip \
  --min-sdk-version 21 --target-sdk-version $API --version-code "$CODE" --version-name "$NAME" --auto-add-overlay \
  -0 zip
echo "== javac"
javac -encoding UTF-8 -source 8 -target 8 -Xlint:-options -bootclasspath "$JAR" -classpath "$JAR" -d build/classes $(find src -name '*.java')
echo "== d8"
"$BT/d8" --release --min-api 21 --lib "$JAR" --output build/dex $(find build/classes -name '*.class')
cp build/base.apk build/unsigned.apk
(cd build/dex && zip -q -u ../unsigned.apk classes.dex)
echo "== zipalign + apksigner"
"$BT/zipalign" -f -p 4 build/unsigned.apk build/aligned.apk
"$BT/apksigner" sign --ks keys/sim.jks --ks-pass pass:elvanoqsim --key-pass pass:elvanoqsim --ks-key-alias sim \
  --out build/ELVANOQ-Roku-Sim.apk build/aligned.apk
"$BT/apksigner" verify --print-certs build/ELVANOQ-Roku-Sim.apk | head -3
"$BT/aapt2" dump badging build/ELVANOQ-Roku-Sim.apk | head -3
ls -la build/ELVANOQ-Roku-Sim.apk
