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

# Programs the widget may start. Commands must be built with
# Shell.command(["program", args...]) (quotes every argument) or
# root.helper([...]) (our own specs.py).
ALLOWED_PROGRAMS = {
    "cat",          # read the GPU power file from sysfs
    "notify-send",  # focus timer notifications
}

# Links the widget may open in the browser (each is checked to be https first).
SAFE_LINKS = {
    "tile.link",    # PhotoTile: Bing's "learn more" link, https only
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
            # Each command must be root.helper(...) or Shell.command(["known program", ...]).
            builders = re.findall(r"root\.helper\(|Shell\.command\(\[\s*\"([^\"]*)\"", expr)
            # A string literal used directly as the command (not inside a builder).
            bare = re.sub(r"Shell\.command\(\[|root\.helper\(\[?", "SAFE(", expr)
            raw = re.search(r"(?:^|[?:]\s*\[|^\[)\s*\"", bare)
            if raw or not builders or any(b and b not in ALLOWED_PROGRAMS for b in builders):
                problems.append("%s  shell command not built safely or not allowed: %s" % (where(path, text, m.start()), expr[:70]))

        # Every label says how to read its text. Qt's default guesses, and
        # treats text that looks like HTML as HTML: a song called
        # <img src="https://..."> would load an image from anywhere. Use
        # Text.PlainText; StyledText only for text we build ourselves.
        if name.endswith(".qml"):
            for m in re.finditer(r"^[ \t]*(?:PlasmaComponents\.|QQC2\.)?(?:Label|Text|TextEdit|TextArea)\s*\{", text, re.M):
                i, depth = m.end(), 1
                while depth and i < len(text):
                    depth += {"{": 1, "}": -1}.get(text[i], 0)
                    i += 1
                block = text[m.end():i]
                if "textFormat" not in block:
                    problems.append("%s  label needs textFormat: Text.PlainText" % where(path, text, m.start()))
                elif re.search(r"textFormat:\s*Text\.(RichText|AutoText|MarkdownText)", block):
                    problems.append("%s  rich text can load remote content; use PlainText or StyledText" % where(path, text, m.start()))

        # Opening links: only https, and only from a variable checked first.
        for m in re.finditer(r"Qt\.openUrlExternally\(([^)]*)\)", text):
            if m.group(1).strip() not in SAFE_LINKS:
                problems.append("%s  opening %s: check it's https first, then add it to SAFE_LINKS" % (where(path, text, m.start()), m.group(1)))

        # Code from strings: never.
        for pattern in (r"Qt\.createQmlObject", r"Qt\.include\(", r"\bpickle\b", r"yaml\.load\("):
            for m in re.finditer(pattern, text if code else ""):
                problems.append("%s  %s runs code built from data" % (where(path, text, m.start()), m.group(0)))

if problems:
    print("Security guard found %d problem(s):" % len(problems))
    print("\n".join("  " + p for p in problems))
    sys.exit(1)
print("security guard passed")
