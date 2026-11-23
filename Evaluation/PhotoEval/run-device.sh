#!/bin/zsh
# Runs the photo eval on a connected iPhone and copies the report here.
# Usage: Evaluation/PhotoEval/run-device.sh <device identifier> [photo folder]
# Find the identifier with `xcrun devicectl list devices`. Install the Debug app from Xcode first.
set -euo pipefail

device=${1:?device identifier}
here=${0:A:h}
photos=${2:-$here/../Photos/japan}
bundle=${BUNDLE_ID:-com.example.TravelJournal}
container=(--domain-type appDataContainer --domain-identifier "$bundle")

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
mkdir "$staging/PhotoEval"
cp "$photos"/* "$here/cases.json" "$staging/PhotoEval"/

xcrun devicectl device copy to --device "$device" "${container[@]}" \
    --source "$staging/PhotoEval" --destination Documents/ > /dev/null
xcrun devicectl device process launch --device "$device" --terminate-existing "$bundle" -photoEval > /dev/null
echo "Running on the iPhone… keep it unlocked with the app open."

for _ in {1..120}; do
    sleep 10
    if xcrun devicectl device copy from --device "$device" "${container[@]}" \
        --source Documents/PhotoEval/report.md --destination "$here/report-device.md" > /dev/null 2>&1; then
        cat "$here/report-device.md"
        exit 0
    fi
done
echo "No report after 20 minutes." >&2
exit 1
