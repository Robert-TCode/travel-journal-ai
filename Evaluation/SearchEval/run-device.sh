#!/bin/zsh
# Runs the search eval on a connected iPhone against its own journal and copies the report here.
# Usage: Evaluation/SearchEval/run-device.sh <device identifier>
# The report lists your entries: report-device.md is ignored by git, keep it that way.
# Find the identifier with `xcrun devicectl list devices`. Install the Debug app first.
set -euo pipefail

device=${1:?device identifier}
here=${0:A:h}
local_config="$here/../../Config/Signing.local.xcconfig"
bundle=${BUNDLE_ID:-$(sed -n 's/^PRODUCT_BUNDLE_IDENTIFIER *= *//p' "$local_config" 2>/dev/null)}
bundle=${bundle:-com.example.TravelJournal}
container=(--domain-type appDataContainer --domain-identifier "$bundle")

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
mkdir "$staging/SearchEval"
cp "$here/queries.txt" "$staging/SearchEval"/

xcrun devicectl device copy to --device "$device" "${container[@]}" \
    --source "$staging/SearchEval" --destination Documents/SearchEval > /dev/null
xcrun devicectl device process launch --device "$device" --terminate-existing "$bundle" -- -searchEval > /dev/null
echo "Running on the iPhone… keep it unlocked with the app open."

for _ in {1..120}; do
    sleep 10
    if xcrun devicectl device copy from --device "$device" "${container[@]}" \
        --source Documents/SearchEval/report.md --destination "$here/report-device.md" > /dev/null 2>&1; then
        cat "$here/report-device.md"
        exit 0
    fi
done
echo "No report after 20 minutes." >&2
exit 1
