ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p "$ROOT/export/linux" "$ROOT/export/web" "$ROOT/export/android"
find "$ROOT/export/web" -mindepth 1 -maxdepth 1 -name 'build.*' -exec rm -rf {} + 2>/dev/null || true

godot --headless --export-release "Linux" "$ROOT/export/linux/build.x86_64"
godot --headless --export-release "Web" "$ROOT/export/web/index.html"
godot --headless --export-release "Android" "$ROOT/export/android/build.apk"

rm -f "$ROOT/export/web.zip"
(cd "$ROOT/export/web" && zip -q -r "$ROOT/export/web.zip" . -x '*/.*' '.*')
echo "Built into export/linux, export/web/index.html, export/android"
echo "Packaged the Web build into export/web.zip"
