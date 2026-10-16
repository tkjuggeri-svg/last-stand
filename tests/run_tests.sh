#!/usr/bin/env bash
# Runs every check for LAST STAND with Godot 4.7.2:
#   1. editor import   2. every .gd script with all warnings treated as errors
#   3. automated tests (tests/automated/test_*.gd)   4. main + every scene in entities/, ui/ and tests/ for 120 frames
# Usage: tests/run_tests.sh            (override the Godot binary with GODOT=/path/to/godot)
set -u
cd "$(dirname "$0")/.."

GODOT="${GODOT:-$HOME/Downloads/Godot_v4.7.2-stable_linux.x86_64}"
EXPECTED_VERSION="4.7.2.stable"
failures=0

# Strips the version banner and blank lines; anything left is treated as a problem.
clean() { grep -v -e '^Godot Engine v' -e '^[[:space:]]*$' || true; }

# Runs Godot with the given arguments; sets $out (cleaned output) and $code (Godot's exit code).
# The exit code is captured inside the substitution: a pipeline's status is lost after "$(...)".
run_godot() {
	local raw
	raw="$("$GODOT" "$@" 2>&1; echo "__exit=$?")"
	code="${raw##*__exit=}"
	out="$(printf '%s\n' "${raw%__exit=*}" | clean)"
}

report() {  # name, output, exit code
	if [[ -z "$2" && "$3" -eq 0 ]]; then
		echo "  ok    $1"
	else
		echo "  FAIL  $1 (exit $3)"
		[[ -n "$2" ]] && echo "$2" | sed 's/^/        /'
		failures=$((failures + 1))
	fi
}

if [[ ! -x "$GODOT" ]]; then
	echo "Godot not found at $GODOT (set GODOT=/path/to/godot)"; exit 1
fi
version="$("$GODOT" --version 2>/dev/null | tail -n 1)"
[[ "$version" == "$EXPECTED_VERSION"* ]] || echo "WARNING: expected Godot $EXPECTED_VERSION, found $version"

trap 'rm -f override.cfg' EXIT

echo "== Import =="
run_godot --headless --path . --import
report "editor import" "$(echo "$out" | grep -iE 'error|warning' || true)" "$code"

echo "== Scripts (warnings = errors) =="
"$GODOT" --headless --path . --script res://tests/tools/write_strict_override.gd 2>&1 | clean | sed 's/^/  /'
while IFS= read -r script; do
	run_godot --headless --path . --check-only --script "res://${script#./}"
	report "${script#./}" "$out" "$code"
done < <(find . -name '*.gd' -not -path './.godot/*' | sort)

echo "== Automated tests =="
for test in tests/automated/test_*.gd; do
	# --fixed-fps: simulate game time as fast as possible, with a deterministic 1/60 s step.
	run_godot --headless --fixed-fps 60 --path . --script "res://$test"
	problems="$(echo "$out" | grep -E 'FAIL|ERROR|WARNING' || true)"
	summary="$(echo "$out" | grep -c '^\[ok\]') checks"
	report "$test ($summary)" "$problems" "$code"
done

echo "== Scenes (120 frames each) =="
for scene in main/main.tscn $(find entities ui -name '*.tscn' | sort) tests/*.tscn; do
	run_godot --headless --path . "res://$scene" --quit-after 120
	report "$scene" "$out" "$code"
done

echo
if [[ $failures -eq 0 ]]; then echo "ALL PASSED"; else echo "$failures FAILED"; fi
exit $(( failures > 0 ))
