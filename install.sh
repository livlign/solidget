#!/usr/bin/env bash
# Solidget installer: one command, and the widget is on your desktop.
#
#   ./install.sh               install or upgrade, then add to the desktop
#   ./install.sh --no-add      install or upgrade only
#   ./install.sh --ram         (re)read RAM type/speed (asks for sudo once)
#   ./install.sh --place WHERE resize the widget: full, left, right, top, bottom,
#                              tl, tr, bl, br, lthird, rthird, corner
#   ./install.sh --uninstall   remove the widget from desktops and uninstall
set -euo pipefail

PLUGIN_ID="io.github.solidget"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/solidget"

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

qdbus_bin() {
    for q in qdbus6 qdbus-qt6 qdbus; do
        command -v "$q" >/dev/null && { echo "$q"; return; }
    done
}

plasma_script() {
    local q; q="$(qdbus_bin)"
    [[ -n "$q" ]] || { warn "qdbus not found; can't talk to Plasma."; return 1; }
    "$q" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"
}

cache_ram_details() {
    command -v dmidecode >/dev/null || { warn "dmidecode not installed; skipping RAM type/speed."; return; }
    say "Reading RAM type and speed (needs your password once)…"
    local raw
    raw="$(sudo dmidecode -t 17 2>/dev/null)" || { warn "Could not read RAM details; skipping."; return; }
    mkdir -p "$DATA_DIR"
    printf '%s' "$raw" | python3 -c '
import json, re, sys
sizes, types, speeds = [], [], []
for block in sys.stdin.read().split("Memory Device")[1:]:
    f = dict(re.findall(r"^\s*([^:\n]+):\s*(.*)$", block, re.M))
    size = f.get("Size", "")
    if not size or "No Module" in size or "Not Installed" in size:
        continue
    sizes.append(size)
    if f.get("Type") not in (None, "", "Unknown", "Other"):
        types.append(f["Type"])
    m = re.match(r"(\d+)", f.get("Configured Memory Speed") or f.get("Speed") or "")
    if m:
        speeds.append(m.group(1))
layout = ""
if sizes:
    same = len(set(sizes)) == 1
    layout = f"{len(sizes)} × {sizes[0]}" if same else " + ".join(sizes)
json.dump({"type": types[0] if types else "", "speed": min(speeds, key=int) if speeds else "",
           "layout": layout}, sys.stdout)
' > "$DATA_DIR/memory.json"
    say "RAM: $(cat "$DATA_DIR/memory.json")"
}

add_to_desktop() {
    # Top-right of the primary screen's desktop, unless one is already there.
    plasma_script "
const id = '$PLUGIN_ID';
const all = desktops();
if (all.some(d => d.widgets(id).length > 0)) {
    print('already-present');
} else {
    const d = all.find(d => d.screen === 0) || all[0];
    const geo = screenGeometry(d.screen);
    const w = Math.min(560, Math.round(geo.width * 0.3));
    const h = Math.min(860, geo.height - 120);
    d.addWidget(id, geo.width - w - 48, 48, w, h);
    print('added');
}" >/dev/null && say "Solidget is on your desktop (top-right). Hover it and click the pencil to customize."
}

remove_from_desktops() {
    plasma_script "
desktops().forEach(d => d.widgets('$PLUGIN_ID').forEach(w => w.remove()));
" >/dev/null || true
}

place_widget() {
    local where="$1"
    [[ "$where" =~ ^(full|left|right|top|bottom|tl|tr|bl|br|lthird|rthird|corner)$ ]] \
        || die "Unknown placement '$where'. Use: full left right top bottom tl tr bl br lthird rthird corner"
    local out
    out="$(plasma_script "
const ws = [];
desktops().forEach(d => d.widgets('$PLUGIN_ID').forEach(w => ws.push(w)));
ws.forEach(w => { w.currentConfigGroup = ['General']; w.writeConfig('placeRequest', '$where'); });
print(ws.length);")" || exit 1
    [[ "$out" != "0" ]] || die "Solidget isn't on any desktop yet. Run ./install.sh first."
    say "Placed: $where"
}

case "${1:-}" in
    --place)
        place_widget "${2:-}"
        exit 0 ;;
    --uninstall)
        remove_from_desktops
        kpackagetool6 -t Plasma/Applet -r "$PLUGIN_ID" >/dev/null && say "Uninstalled."
        rm -rf "$DATA_DIR"
        exit 0 ;;
    --ram)
        cache_ram_details
        exit 0 ;;
    --no-add|"") ;;
    *) die "Unknown option: $1 (see the top of this script)" ;;
esac

command -v kpackagetool6 >/dev/null || die "kpackagetool6 not found. Is this KDE Plasma 6?"
command -v python3 >/dev/null || die "python3 is required."

if kpackagetool6 -t Plasma/Applet -s "$PLUGIN_ID" >/dev/null 2>&1; then
    say "Upgrading Solidget…"
    kpackagetool6 -t Plasma/Applet -u "$HERE/package" >/dev/null
    UPGRADED=1
else
    say "Installing Solidget…"
    kpackagetool6 -t Plasma/Applet -i "$HERE/package" >/dev/null
    UPGRADED=0
fi

if [[ ! -f "$DATA_DIR/memory.json" && -t 0 ]]; then
    read -r -p "Show RAM type and speed (e.g. DDR4-3200)? This needs sudo once. [Y/n] " ans
    [[ "${ans,,}" == n* ]] || cache_ram_details
fi

[[ "${1:-}" == "--no-add" ]] || add_to_desktop

if [[ "$UPGRADED" == 1 ]]; then
    say "Upgraded. Plasma keeps the old version loaded until it restarts:"
    say "  systemctl --user restart plasma-plasmashell"
fi
