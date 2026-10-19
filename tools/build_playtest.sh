#!/usr/bin/env bash
# Builds the internal playtest version of LAST STAND for Linux and Windows (x86_64) and zips each:
#   builds/LastStand-<version>-linux.zip, builds/LastStand-<version>-windows.zip
# <version> is `git describe` (e.g. m5-playable-12-g9f8fd65, "-dirty" with uncommitted changes).
# Runs the full test suite first (a playtest build must be green); --skip-tests skips it.
# Needs Godot's official export templates for the same Godot version (Editor > Manage Export
# Templates > Download and Install, or unpack the .tpz from godotengine.org into the folder below).
# --pack-check needs no templates: it exports only the game data (.pck), checks that no tests/ or
# tools/ file went in, and runs it outside the project for 300 frames (what a build would contain).
# Usage: tools/build_playtest.sh [--skip-tests | --pack-check]   (Godot binary from $GODOT)
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-$HOME/Downloads/Godot_v4.7.2-stable_linux.x86_64}"
VERSION_DIR="4.7.2.stable"
TEMPLATES="$HOME/.local/share/godot/export_templates/$VERSION_DIR"

[[ -x "$GODOT" ]] || { echo "Godot not found at $GODOT (set GODOT=/path/to/godot)"; exit 1; }

if [[ "${1:-}" == "--pack-check" ]]; then
	rm -rf builds/check && mkdir -p builds/check
	"$GODOT" --headless --path . --import >/dev/null 2>&1
	"$GODOT" --headless --path . --export-pack "Linux" builds/check/LastStand.pck 2>&1 | grep -iE "error" && exit 1
	if grep -aq -e "res://tests/" -e "res://tools/" builds/check/LastStand.pck; then
		echo "The pack contains tests/ or tools/ files"; exit 1
	fi
	errors="$(cd /tmp && timeout 60 "$GODOT" --headless --main-pack "$OLDPWD/builds/check/LastStand.pck" --quit-after 300 2>&1 | grep -iE "error|warning" || true)"
	[[ -z "$errors" ]] || { echo "$errors"; exit 1; }
	echo "Pack check OK: builds/check/LastStand.pck ($(du -h builds/check/LastStand.pck | cut -f1)) runs on its own"
	exit 0
fi
missing=0
for template in linux_debug.x86_64 linux_release.x86_64 windows_debug_x86_64.exe windows_release_x86_64.exe; do
	if [[ ! -f "$TEMPLATES/$template" ]]; then
		echo "Missing export template: $TEMPLATES/$template"
		missing=1
	fi
done
if [[ $missing -eq 1 ]]; then
	echo "Install the Godot $VERSION_DIR export templates first (Editor > Manage Export Templates)."
	exit 1
fi

if [[ "${1:-}" != "--skip-tests" ]]; then
	tests/run_tests.sh | tail -n 1 | grep -q "ALL PASSED" || { echo "Tests failed: no build. Run tests/run_tests.sh"; exit 1; }
fi

version="$(git describe --tags --always --dirty)"
echo "Building LAST STAND $version"
rm -rf builds/linux builds/windows
mkdir -p builds/linux builds/windows
"$GODOT" --headless --path . --import >/dev/null 2>&1
for preset in Linux Windows; do
	echo "  exporting $preset"
	"$GODOT" --headless --path . --export-release "$preset" 2>&1 | grep -iE "error|warning" || true
done
[[ -f builds/linux/LastStand.x86_64 && -f builds/windows/LastStand.exe ]] || { echo "Export failed"; exit 1; }

for platform in linux windows; do
	{
		echo "LAST STAND internal playtest build"
		echo "Version: $version"
		echo "Built:   $(date -u +%Y-%m-%dT%H:%MZ)"
		echo "See PLAYTEST.md for how to play and what feedback we need."
	} > "builds/$platform/BUILD_INFO.txt"
	cp PLAYTEST.md "builds/$platform/"
	(cd "builds/$platform" && rm -f "../LastStand-$version-$platform.zip" && zip -qr "../LastStand-$version-$platform.zip" .)
	echo "  builds/LastStand-$version-$platform.zip"
done
