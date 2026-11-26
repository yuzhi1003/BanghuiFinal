set -e
BT=$(ls -d "$ANDROID_HOME"/build-tools/* 2>/dev/null | sort -V | tail -1)
if [ -f "$ANDROID_HOME/platforms/android-34/android.jar" ]; then
  PLAT="$ANDROID_HOME/platforms/android-34/android.jar"
else
  PLAT=$(ls -d "$ANDROID_HOME"/platforms/android-*/android.jar 2>/dev/null | sort -V | tail -1)
fi
echo "build-tools: $BT"; echo "platform: $PLAT"
OUT=".apkout"
rm -rf "$OUT"; mkdir -p "$OUT/classes" "$OUT/dex" "$OUT/assets"
cp index.html "$OUT/assets/index.html"

RES=""
if [ -d android/res ]; then
  "$BT/aapt2" compile --dir android/res -o "$OUT/res.zip"
  RES="$OUT/res.zip"
fi
"$BT/aapt2" link -o "$OUT/base.apk" -I "$PLAT" $RES \
  --manifest android/AndroidManifest.xml \
  --min-sdk-version 24 --target-sdk-version 34 \
  -A "$OUT/assets" || exit 1

javac -encoding UTF-8 -source 8 -target 8 -bootclasspath "$PLAT" -classpath "$PLAT" \
  -d "$OUT/classes" android/MainActivity.java

"$BT/d8" --min-api 24 --lib "$PLAT" --output "$OUT/dex" $(find "$OUT/classes" -name '*.class')

cd "$OUT"
cp base.apk unsigned.apk
zip -q -j unsigned.apk dex/classes.dex
"$BT/zipalign" -f -p 4 unsigned.apk aligned.apk
keytool -genkeypair -keystore qlz.keystore -alias qlz -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass qlz2026 -keypass qlz2026 -dname "CN=qingpingyue, OU=qlz, O=qlz, L=cn, S=cn, C=CN" >/dev/null 2>&1 || true
"$BT/apksigner" sign --ks qlz.keystore --ks-pass pass:qlz2026 --key-pass pass:qlz2026 \
  --out 清平乐-醉清欢.apk aligned.apk
cd ..
cp "$OUT/清平乐-醉清欢.apk" ./清平乐-醉清欢.apk
ls -lh 清平乐-醉清欢.apk
