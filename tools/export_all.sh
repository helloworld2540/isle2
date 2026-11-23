ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p "$ROOT/export/linux" "$ROOT/export/web" "$ROOT/export/android"
find "$ROOT/export/web" -mindepth 1 -maxdepth 1 -name 'build.*' -exec rm -rf {} + 2>/dev/null || true

godot --headless --export-release "Linux" "$ROOT/export/linux/build.x86_64"
godot --headless --export-release "Web" "$ROOT/export/web/index.html"
# Stamp the unified build number into the exported Web page before packaging.
BUILD_VERSION="$(sed -n 's/^[[:space:]]*const VERSION := "\([^"]*\)".*/\1/p' scripts/version.gd)"
python3 - "$ROOT/export/web/index.html" "$BUILD_VERSION" <<'PY'
import sys
path, version = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    text = f.read()
if 'name="build"' not in text:
    marker = "</head>"
    meta = '\t\t<meta name="build" content="v' + version + '">'
    text = text.replace(marker, meta + marker, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
PY
godot --headless --export-release "Android" "$ROOT/export/android/build.apk"

rm -f "$ROOT/export/web.zip"
(cd "$ROOT/export/web" && zip -q -r "$ROOT/export/web.zip" . -x '*/.*' '.*')
echo "Built into export/linux, export/web/index.html, export/android"
echo "Packaged the Web build into export/web.zip"
