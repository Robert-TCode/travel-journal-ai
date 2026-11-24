#!/bin/zsh
# Writes the story of every trip on a connected iPhone with the on-device model and copies the report here.
# Usage: Evaluation/StoryEval/run-device.sh <device identifier>
# The report quotes your journal: report-device.md is ignored by git, keep it that way.
set -euo pipefail

device=${1:?device identifier}
here=${0:A:h}
local_config="$here/../../Config/Signing.local.xcconfig"
bundle=${BUNDLE_ID:-$(sed -n 's/^PRODUCT_BUNDLE_IDENTIFIER *= *//p' "$local_config" 2>/dev/null)}
bundle=${bundle:-com.example.TravelJournal}
container=(--domain-type appDataContainer --domain-identifier "$bundle")

xcrun devicectl device process launch --device "$device" --terminate-existing "$bundle" -- -storyEval > /dev/null
echo "Running on the iPhone… keep it unlocked with the app open."

for _ in {1..60}; do
    sleep 10
    if xcrun devicectl device copy from --device "$device" "${container[@]}" \
        --source Documents/StoryEval/report.md --destination "$here/report-device.md" > /dev/null 2>&1; then
        cat "$here/report-device.md"
        exit 0
    fi
done
echo "No report after 10 minutes." >&2
exit 1
