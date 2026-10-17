#!/bin/sh
# Runs every check. Use it before you open a pull request: ./tests/run.sh
cd "$(dirname "$0")/.." || exit 1

check() {   # check "name" command...  (prints the output only when it fails)
    name=$1; shift
    if out=$("$@" 2>&1); then echo "ok    $name"; else echo "FAIL  $name"; echo "$out"; failed=1; fi
}

check "layout engine"   node tests/layout.test.js
check "code and config" node tests/code.test.js
check "hardware script" python3 tests/test_specs.py
check "security guard"  python3 tests/guard.py
# The script is in single quotes on purpose: sh -c expands it, not this shell.
# shellcheck disable=SC2016
check "rpm version"     sh -c 'v=$(python3 -c "import json; print(json.load(open(\"package/metadata.json\"))[\"KPlugin\"][\"Version\"])") &&
    grep -q "^Version: *$v\$" packaging/solidget.spec && grep -q -- "- $v-" packaging/solidget.spec ||
    { echo "packaging/solidget.spec: set Version and add a %changelog entry for $v"; exit 1; }'
if command -v shellcheck >/dev/null; then
    check "shell scripts"   shellcheck install.sh tests/run.sh tools/package.sh
fi

[ -z "$failed" ] && echo "All good." || exit 1
