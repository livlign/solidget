#!/bin/sh
# Builds dist/solidget-<version>.plasmoid: the widget as one file, ready for
# the KDE Store, GitHub Releases, or "Install Widget From Local File".
set -eu
cd "$(dirname "$0")/.."

version=$(python3 -c 'import json; print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')
out="dist/solidget-$version.plasmoid"

mkdir -p dist
rm -f "$out"
# A .plasmoid is a zip with metadata.json at the top. Leave out caches.
(cd package && zip -q -r -X "../$out" . -x '*__pycache__*' '*.pyc' '*~')

echo "$out"
