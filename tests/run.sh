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
if command -v shellcheck >/dev/null; then
    check "shell scripts"   shellcheck install.sh tests/run.sh tools/package.sh
fi

[ -z "$failed" ] && echo "All good." || exit 1
