#!/usr/bin/env bash
# The soak test (M13): whole runs through main.tscn with the bot, every hero on every path policy, with
# and without Pressure, on many seeds, and a scan of the output for errors and stuck runs. A tuning
# aid's machinery used as a gate before a release build: it must end SOAK PASSED.
#   tests/tools/soak.sh [seeds, default 1-3] [limit in seconds per combination, default 900]
set -u
cd "$(dirname "$0")/../.." || exit 1
GODOT="${GODOT:-$HOME/Downloads/Godot_v4.7.2-stable_linux.x86_64}"
SEEDS="${1:-1-3}"
LIMIT="${2:-900}"
LOG_DIR="${CLAUDE_JOB_DIR:-/tmp}/soak"
mkdir -p "$LOG_DIR"
failures=0
combos=0
for hero in knight huntress necromancer; do
	for path in fights balanced safe; do
		for pressure in none all; do
			combos=$((combos + 1))
			log="$LOG_DIR/$hero-$path-$pressure.log"
			args=(--seeds="$SEEDS" --path="$path" --hero-kind="$hero" --quiet)
			[ "$pressure" = "all" ] && args+=(--pressure=all)
			timeout "$LIMIT" "$GODOT" --headless --fixed-fps 60 --path . --script res://tests/tools/map_balance.gd -- "${args[@]}" >"$log" 2>&1
			code=$?
			runs=$(grep -c -E "^[0-9]+ +(fights|balanced|safe)" "$log")
			errors=$(grep -c -E "SCRIPT ERROR|^ERROR:|Parse Error|Invalid access|Cannot call" "$log")
			if [ "$code" -ne 0 ] || [ "$errors" -ne 0 ] || [ "$runs" -lt 1 ]; then
				echo "FAIL  $hero / $path / pressure $pressure (exit $code, $errors errors, $runs runs) $log"
				failures=$((failures + 1))
			else
				echo "ok    $hero / $path / pressure $pressure ($runs runs)"
			fi
		done
	done
done
echo "$combos combinations, $failures failed"
if [ "$failures" -eq 0 ]; then echo "SOAK PASSED"; else echo "SOAK FAILED"; exit 1; fi
