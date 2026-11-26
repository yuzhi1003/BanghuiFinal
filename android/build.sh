set -e
BT="$ANDROID_HOME/build-tools/34.0.0"
PLAT="$ANDROID_HOME/platforms/android-34/android.jar"
OUT=".apkout"
rm -rf "$OUT"; mkdir -p "$OUT/classes" "$OUT/dex" "$OUT/assets"
cp index.html "$OUT/assets/index.html"

"$BT/aapt2" link -o "$OUT/base.apk" -I "$PLAT" \
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
