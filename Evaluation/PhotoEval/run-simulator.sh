#!/bin/zsh
# Runs the photo eval in the app on a booted simulator and copies the report here.
# Usage: Evaluation/PhotoEval/run-simulator.sh <simulator udid> [photo folder]
# The Debug app must already be installed on that simulator.
set -euo pipefail

udid=${1:?simulator udid}
here=${0:A:h}
photos=${2:-$here/../Photos/japan}
# The bundle ID comes from your local signing config; BUNDLE_ID overrides it.
local_config="$here/../../Config/Signing.local.xcconfig"
bundle=${BUNDLE_ID:-$(sed -n 's/^PRODUCT_BUNDLE_IDENTIFIER *= *//p' "$local_config" 2>/dev/null)}
bundle=${bundle:-com.example.TravelJournal}

data=$(xcrun simctl get_app_container "$udid" "$bundle" data)
eval_dir="$data/Documents/PhotoEval"
rm -rf "$eval_dir" && mkdir -p "$eval_dir"
cp "$photos"/* "$eval_dir"/
cp "$here/cases.json" "$eval_dir"/

xcrun simctl launch --terminate-running-process "$udid" "$bundle" -photoEval > /dev/null
echo "Running… (about 10 s per photo)"
for _ in {1..180}; do
    [[ -f "$eval_dir/report.md" ]] && break
    sleep 5
done
cp "$eval_dir/report.md" "$here/report-simulator.md"
cat "$here/report-simulator.md"
