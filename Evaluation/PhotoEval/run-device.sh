#!/bin/zsh
# Runs the photo eval on a connected iPhone and copies the report here.
# Usage: Evaluation/PhotoEval/run-device.sh <device identifier> [photo folder]
# OCR=1 also runs every photo with OCRTool, for a side-by-side report.
# Find the identifier with `xcrun devicectl list devices`. Install the Debug app from Xcode first.
set -euo pipefail

device=${1:?device identifier}
here=${0:A:h}
photos=${2:-$here/../Photos/japan}
# The bundle ID comes from your local signing config; BUNDLE_ID overrides it.
local_config="$here/../../Config/Signing.local.xcconfig"
bundle=${BUNDLE_ID:-$(sed -n 's/^PRODUCT_BUNDLE_IDENTIFIER *= *//p' "$local_config" 2>/dev/null)}
bundle=${bundle:-com.example.TravelJournal}
container=(--domain-type appDataContainer --domain-identifier "$bundle")

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
mkdir "$staging/PhotoEval"
cp "$photos"/* "$here/cases.json" "$staging/PhotoEval"/

xcrun devicectl device copy to --device "$device" "${container[@]}" \
    --source "$staging/PhotoEval" --destination Documents/PhotoEval > /dev/null
args=(-photoEval)
[[ -n "${OCR:-}" ]] && args+=(-ocr)
xcrun devicectl device process launch --device "$device" --terminate-existing "$bundle" -- "${args[@]}" > /dev/null
echo "Running on the iPhone… keep it unlocked with the app open."

for _ in {1..240}; do
    sleep 10
    if xcrun devicectl device copy from --device "$device" "${container[@]}" \
        --source Documents/PhotoEval/report.md --destination "$here/report-device.md" > /dev/null 2>&1; then
        cat "$here/report-device.md"
        exit 0
    fi
done
echo "No report after 40 minutes." >&2
exit 1
