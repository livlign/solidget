#!/usr/bin/env python3
"""Render every ready-made look as a full board, side by side, to spot what's off.

    tools/lookbook/lookbook.py                 all looks -> dist/lookbook/
    tools/lookbook/lookbook.py Frost Midnight  just these looks (by name)
    tools/lookbook/lookbook.py bento:espresso  any style:colors pair

Writes one PNG per look and contact.png with them all. Runs offscreen with
made-up readings: Plasma isn't touched. Needs python3-pyside6 (built against
the system Qt, so it loads the KDE QML modules), node and ImageMagick.
"""
import concurrent.futures
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "dist", "lookbook")


def looks():
    """The ready-made looks, in the order Settings shows them."""
    src = os.path.join(ROOT, "package", "contents", "code", "palette.js")
    js = ("const fs = require('fs');"
          "const src = fs.readFileSync(process.argv[1], 'utf8').replace('.pragma library', '');"
          "const LOOKS = new Function(src + '; return LOOKS;')();"
          "console.log(JSON.stringify(LOOKS));")
    return json.loads(subprocess.check_output(["node", "-e", js, src], text=True))


def fake_plasmoid(into):
    """A stand-in org.kde.plasma.plasmoid with the settings' defaults."""
    xml = open(os.path.join(ROOT, "package", "contents", "config", "main.xml")).read()
    props = []
    for m in re.finditer(r'<entry name="(\w+)" type="(\w+)">\s*(?:<default>(.*?)</default>)?', xml, re.S):
        name, kind, default = m.group(1), m.group(2), (m.group(3) or "")
        if kind == "Bool":
            props.append(f"property bool {name}: {default or 'false'}")
        elif kind in ("Int", "Double"):
            props.append(f"property real {name}: {default or 0}")
        else:
            props.append(f"property var {name}: {json.dumps(default)}")
    mod = os.path.join(into, "org", "kde", "plasma", "plasmoid")
    os.makedirs(mod, exist_ok=True)
    open(os.path.join(mod, "qmldir"), "w").write("module org.kde.plasma.plasmoid\nsingleton Plasmoid 1.0 Plasmoid.qml\n")
    open(os.path.join(mod, "Plasmoid.qml"), "w").write(
        "pragma Singleton\nimport QtQuick\nQtObject {\n property var configuration: QtObject {\n  "
        + "\n  ".join(props) + "\n }\n}\n")


def render_one(out, style, theme, power, imports):
    """Child process: draw one board and save it."""
    from PySide6.QtCore import QObject, QTimer, QUrl, Slot, qInstallMessageHandler
    from PySide6.QtGui import QGuiApplication, QIcon
    from PySide6.QtQuick import QQuickView

    seen = set()

    def log(_kind, _ctx, msg):
        if msg not in seen and "onTickChanged" not in msg:
            seen.add(msg)
            print(msg, file=sys.stderr)
    qInstallMessageHandler(log)
    app = QGuiApplication(sys.argv[:1] + [style, theme, str(power)])
    QIcon.setThemeSearchPaths(["/usr/share/icons"])
    QIcon.setThemeName("breeze-dark")

    class I18n(QObject):
        def _f(self, s, *a):
            for i, x in enumerate(a):
                s = s.replace("%" + str(i + 1), str(x))
            return s

        @Slot(str, result=str)
        @Slot(str, "QVariant", result=str)
        @Slot(str, "QVariant", "QVariant", result=str)
        @Slot(str, "QVariant", "QVariant", "QVariant", result=str)
        def i18n(self, s, *a):
            return self._f(s, *a)

        @Slot(str, str, result=str)
        @Slot(str, str, "QVariant", result=str)
        def i18nc(self, _c, s, *a):
            return self._f(s, *a)

        @Slot(str, str, int, result=str)
        @Slot(str, str, int, "QVariant", result=str)
        def i18np(self, one, many, n, *a):
            return self._f(one if n == 1 else many, n, *a)

    view = QQuickView()
    view.engine().addImportPath(imports)
    ctx = I18n()
    view.rootContext().setContextObject(ctx)
    view.setSource(QUrl.fromLocalFile(os.path.join(HERE, "Board.qml")))
    view.show()
    QTimer.singleShot(2500, lambda: (view.grabWindow().save(out), app.quit()))
    app.exec()


def main(argv):
    if argv[:1] == ["--one"]:
        render_one(*argv[1:4], float(argv[4]), argv[5])
        return
    wanted = argv
    todo = []
    for look in looks():
        if not wanted or look["name"] in wanted:
            todo.append((look["name"], look["style"], look["theme"]))
    for w in wanted:
        if ":" in w:
            style, theme = w.split(":", 1)
            todo.append((f"{style} + {theme}", style, theme))
    if not todo:
        sys.exit("No such look. Names are as in Settings, or style:colors (e.g. bento:oat).")

    os.makedirs(OUT, exist_ok=True)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="rhi", QSG_RHI_BACKEND="opengl")
    with tempfile.TemporaryDirectory() as imports:
        fake_plasmoid(imports)

        def run(item):
            name, style, theme = item
            out = os.path.join(OUT, re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-") + ".png")
            r = subprocess.run([sys.executable, os.path.abspath(__file__), "--one", out, style, theme, "20", imports],
                               env=env, capture_output=True, text=True, timeout=120)
            return name, out, r.stderr.strip()

        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            results = list(pool.map(run, todo))

    shots = []
    for name, out, errors in results:
        if os.path.exists(out):
            shots += ["-label", name, out]
            print(f"ok    {name}")
        else:
            print(f"FAIL  {name}")
        if errors:
            print("      " + errors.replace("\n", "\n      "))
    contact = os.path.join(OUT, "contact.png")
    subprocess.run(["magick", "montage", *shots, "-tile", "6x", "-geometry", "536x815+12+12",
                    "-background", "#202020", "-fill", "#eeeeee", "-pointsize", "28", contact], check=True)
    print(contact)


if __name__ == "__main__":
    main(sys.argv[1:])
