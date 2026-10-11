#!/usr/bin/env python3
"""Run: python3 tests/guard.py

Security guard. Fails when the widget starts talking to a new website,
runs a new shell command, or uses something risky. If you really need one
of these, add it to the lists below in the same pull request and explain
why, so a reviewer looks at it on purpose.
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "package")

# Websites the widget may contact. Each one is listed in README "Privacy".
ALLOWED_HOSTS = {
    "api.open-meteo.com",            # weather
    "geocoding-api.open-meteo.com",  # city search (weather, world clocks)
    "ipwho.is",                      # rough location when no city is set
    "get.geojs.io",                  # fallback for the above
    "www.bing.com",                  # photo of the day
}

# Shell commands the widget may start (the start of each command string).
ALLOWED_COMMANDS = {
    "root.helper",     # python3 specs.py [battery | tz <zones>]
    "\"cat '",        # read the GPU power file from sysfs
    "\"notify-send ",  # focus timer notifications
}

# Patterns that are never OK in the package.
FORBIDDEN = [
    (r"\beval\s*\(", "eval() runs arbitrary code"),
    (r"new\s+Function\s*\(", "Function() runs arbitrary code"),
    (r"http://", "plain http: use https"),
    (r"\bsudo\b", "the widget must never need root"),
    (r"shell\s*=\s*True", "subprocess with shell=True"),
    (r"os\.system\s*\(", "os.system runs a shell"),
]

problems = []


def where(path, text, pos):
    return "%s:%d" % (os.path.relpath(path, os.path.dirname(ROOT)), text.count("\n", 0, pos) + 1)


for folder, _, files in os.walk(ROOT):
    for name in files:
        if not name.endswith((".qml", ".js", ".py", ".xml", ".json")):
            continue
        path = os.path.join(folder, name)
        with open(path, encoding="utf-8") as f:
            text = f.read()

        code = name.endswith((".qml", ".js", ".py"))   # not XML namespaces or metadata links
        for pattern, why in FORBIDDEN if code else []:
            for m in re.finditer(pattern, text):
                problems.append("%s  %s" % (where(path, text, m.start()), why))

        for m in re.finditer(r"https://([A-Za-z0-9.-]+)", text if code else ""):
            if m.group(1) not in ALLOWED_HOSTS:
                problems.append("%s  new website %s: add it to ALLOWED_HOSTS and the README" % (where(path, text, m.start()), m.group(1)))

        # Every command run through the "executable" engine must be known.
        for m in re.finditer(r"connectSource\(([^)]*)\)|connectedSources:\s*([^\n]*(?:\n\s*\?[^\n]*)?)", text):
            expr = (m.group(1) or m.group(2) or "").strip()
            if expr in ("", "[]", "source") or expr.startswith("disconnect"):
                continue
            # The command is the first item of each list, or the connectSource() argument.
            starts = re.findall(r"\[\s*(root\.helper|\"[^\"]*)", expr) if m.group(2) else re.findall(r"^(root\.helper|\"[^\"]*)", expr)
            if not starts or not all(any(s.startswith(a) for a in ALLOWED_COMMANDS) for s in starts):
                problems.append("%s  unknown shell command: %s" % (where(path, text, m.start()), expr[:70]))

        # Text from outside (song titles, photo captions, app names, cities)
        # must never be shown as HTML: it could load images from anywhere.
        if name.endswith("Tile.qml"):
            for m in re.finditer(r"text:\s*[^\n]*\b(track|artist|caption|credit|modelData\.name|place)\b[^\n]*\n((?:[^\n]*\n){0,2})", text):
                if "PlainText" not in m.group(2):
                    problems.append("%s  outside text needs textFormat: Text.PlainText" % where(path, text, m.start()))

if problems:
    print("Security guard found %d problem(s):" % len(problems))
    print("\n".join("  " + p for p in problems))
    sys.exit(1)
print("security guard passed")
