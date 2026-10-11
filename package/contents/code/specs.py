#!/usr/bin/env python3
"""Collect static PC specs for Solidget and print them as JSON.

Everything here runs without root. RAM type/speed needs dmidecode (root), so
install.sh caches it once in ~/.local/share/solidget/memory.json.

Usage: specs.py            -> full specs
       specs.py battery    -> live battery state only
"""
import glob
import json
import os
import platform
import re
import shutil
import subprocess
import sys


# Tests point this at a fake system (tests/fixtures/...) to check machines
# we don't own: a Raspberry Pi, an Intel laptop, NVIDIA cards, ...
ROOT = os.environ.get("SOLIDGET_SYSROOT", "")


def read(path, default=""):
    try:
        with open(ROOT + path) as f:
            return f.read().strip()
    except OSError:
        return default


def sysglob(pattern):
    """glob() inside ROOT, returning paths as the real system would see them."""
    return sorted(p[len(ROOT):] for p in glob.glob(ROOT + pattern))


def have(tool):
    return shutil.which(tool) is not None


def ok(cmd, timeout=5):
    """True if the command ran and succeeded."""
    try:
        return subprocess.run(cmd, capture_output=True, timeout=timeout).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def run(cmd, timeout=3):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return out.stdout if out.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def vendor_of(text):
    t = text.lower()
    for key, name in (("amd", "amd"), ("advanced micro", "amd"), ("radeon", "amd"),
                      ("intel", "intel"), ("nvidia", "nvidia"), ("geforce", "nvidia"),
                      ("apple", "apple"), ("qualcomm", "qualcomm")):
        if key in t:
            return name
    return ""


def cpu():
    model = ""
    cores = set()
    threads = 0
    package = "0"
    for line in read("/proc/cpuinfo").splitlines():
        key, _, val = line.partition(":")
        key, val = key.strip(), val.strip()
        if key == "model name" and not model:
            model = val
        elif key == "processor":
            threads += 1
        elif key == "physical id":
            package = val
        elif key == "core id":
            cores.add((package, val))
    if not model:
        # ARM: lscpu knows the core type ("Cortex-A76"); the board model
        # ("Raspberry Pi 5 Model B") is nicer when there is one.
        model = read("/proc/device-tree/model").strip("\x00") or \
            (re.search(r"Model name:\s*(.+)", run(["lscpu"])) or [None, ""])[1].strip()
    core_count = len(cores) or threads
    # "AMD Ryzen 5 5600X 6-Core Processor" -> "AMD Ryzen 5 5600X"
    name = re.sub(r"\((R|TM|tm|r)\)", "", model)
    name = re.sub(r"\s+\d+-Core Processor", "", name)
    name = re.sub(r"\s+(CPU|Processor)\b.*", "", name)
    name = re.sub(r"\s+", " ", name).strip()
    max_khz = read("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")
    return {
        "name": name or platform.processor() or "Unknown CPU",
        "vendor": vendor_of(model),
        "cores": core_count,
        "threads": threads or os.cpu_count() or 0,
        "maxGHz": round(int(max_khz) / 1e6, 2) if max_khz.isdigit() else None,
    }


VENDOR_LABEL = {"amd": "AMD Radeon graphics", "intel": "Intel graphics", "nvidia": "NVIDIA graphics"}


def tidy_gpu_name(name, vendor):
    """'Radeon RX 6600/6600 XT/6600M' -> 'AMD Radeon RX 6600'."""
    name = re.sub(r"/\S.*$", "", name.split(" / ")[0]).strip()
    brand = {"amd": "AMD", "intel": "Intel", "nvidia": "NVIDIA"}.get(vendor, "")
    if brand and name and not name.lower().startswith(brand.lower()):
        name = brand + " " + name
    return name


def pci_ids_name(vendor_id, device_id):
    """Look the card up in the PCI id list most distros ship (no lspci needed)."""
    v, d = vendor_id.lower().replace("0x", ""), device_id.lower().replace("0x", "")
    for path in ("/usr/share/hwdata/pci.ids", "/usr/share/misc/pci.ids", "/usr/share/pci.ids"):
        text = read(path)
        if not text:
            continue
        in_vendor = False
        for line in text.splitlines():
            if not line or line.startswith("#"):
                continue
            if not line.startswith("\t"):
                in_vendor = line.startswith(v + " ")
            elif in_vendor and line.startswith("\t" + d + " "):
                name = line.strip()[len(d):].strip()
                m = re.search(r"\[([^\]]+)\]\s*$", name)
                return m.group(1) if m else name
        return ""
    return ""


def pci_device_name(slot):
    # lspci -mm fields: slot "class" "vendor" "device" ...; device looks like
    # 'Navi 23 [Radeon RX 6600/6600 XT/6600M]' -> prefer the bracketed part.
    fields = re.findall(r'"([^"]*)"', run(["lspci", "-mm", "-s", slot]))
    if len(fields) < 3:
        return ""
    m = re.search(r"\[([^\]]+)\]\s*$", fields[2])
    return m.group(1) if m else fields[2]


def gpus():
    result = []
    # Marketing names from the drivers beat PCI ids ("Navi 23 [RX 6600/6600 XT]").
    nvidia = run(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader,nounits"])
    for line in nvidia.splitlines():
        name, _, mem = line.partition(",")
        result.append({"name": name.strip(), "vendor": "nvidia",
                       "vramBytes": int(mem.strip()) * 1024 * 1024 if mem.strip().isdigit() else None})

    renderer = ""
    m = re.search(r"OpenGL renderer string:\s*(.+)", run(["glxinfo", "-B"]))
    if m:
        renderer = re.sub(r"\s*\(.*\)\s*$", "", m.group(1)).strip()

    for card in sysglob("/sys/class/drm/card[0-9]"):
        dev = os.path.join(card, "device")
        vendor_id = read(os.path.join(dev, "vendor"))
        vendor = {"0x1002": "amd", "0x8086": "intel", "0x10de": "nvidia"}.get(vendor_id, "")
        if vendor == "nvidia" and nvidia:
            continue
        vram = read(os.path.join(dev, "mem_info_vram_total"))
        name = ""
        if renderer and vendor_of(renderer) == vendor:
            name, renderer = renderer, ""
        if not name:
            name = pci_device_name(os.path.basename(os.path.realpath(ROOT + dev)))
        if not name:
            name = pci_ids_name(vendor_id, read(os.path.join(dev, "device")))
        if not vendor and not name:
            continue
        # Integrated GPUs report tiny "VRAM" carve-outs; hide those.
        vram_bytes = int(vram) if vram.isdigit() else None
        if vram_bytes is not None and vram_bytes < 1024 ** 3:
            vram_bytes = None
        name = tidy_gpu_name(name, vendor) if name else VENDOR_LABEL.get(vendor, "Graphics")
        result.append({"name": name, "vendor": vendor, "vramBytes": vram_bytes})
    # Laptops with two GPUs: the dedicated one first (its own memory, or
    # at least not the Intel chip built into the CPU).
    result.sort(key=lambda g: (-(g["vramBytes"] or 0), g["vendor"] == "intel"))
    return result


def memory():
    kb = re.search(r"MemTotal:\s*(\d+)", read("/proc/meminfo"))
    total = int(kb.group(1)) * 1024 if kb else 0
    gib = total / 1024 ** 3
    # Installed RAM is a bit more than MemTotal (firmware reserves some); round up to even GB.
    nominal = int(-(-gib // 2) * 2) if gib > 2 else round(gib, 1)
    info = {"totalBytes": total, "nominalGB": nominal, "type": "", "speed": "", "layout": ""}
    cache = os.path.expanduser("~/.local/share/solidget/memory.json")
    try:
        with open(cache) as f:
            # Short strings only, whatever ends up in the file.
            info.update({k: str(v)[:40] for k, v in json.load(f).items() if k in ("type", "speed", "layout")})
    except (OSError, ValueError, AttributeError):
        pass
    return info


def board():
    vendor = read("/sys/class/dmi/id/board_vendor")
    name = read("/sys/class/dmi/id/board_name")
    vendor = re.sub(r"(?i)\s*(technology|computer|international)?\s*(co\.?,?\s*ltd\.?|inc\.?|corporation|corp\.?|gmbh)\s*$", "", vendor).strip(" ,.")
    vendor = {"ASUSTeK": "ASUS", "Micro-Star": "MSI", "Gigabyte": "Gigabyte"}.get(vendor.split()[0] if vendor else "", vendor)
    if vendor.lower().startswith("gigabyte"):
        vendor = "Gigabyte"
    product = read("/sys/class/dmi/id/product_name")
    if name in ("", "Default string", "To be filled by O.E.M."):
        name = product
    return {"vendor": vendor, "name": name}


def drives():
    out = run(["lsblk", "-J", "-b", "-d", "-o", "NAME,MODEL,SIZE,ROTA,TRAN,TYPE"])
    result = []
    try:
        for d in json.loads(out).get("blockdevices", []):
            if d.get("type") != "disk" or d["name"].startswith(("zram", "loop", "sr")):
                continue
            tran = (d.get("tran") or "").lower()
            kind = "NVMe" if tran == "nvme" or d["name"].startswith("nvme") else \
                   "HDD" if d.get("rota") in (True, "1", 1) else "SSD"
            if tran == "usb":
                kind = "USB"
            result.append({"model": (d.get("model") or d["name"]).strip(),
                           "sizeBytes": int(d.get("size") or 0), "kind": kind})
    except ValueError:
        pass
    return result


def displays():
    result = []
    try:
        data = json.loads(run(["kscreen-doctor", "-j"]))
        for o in data.get("outputs", []):
            if not o.get("enabled"):
                continue
            mode = next((m for m in o.get("modes", []) if m.get("id") == o.get("currentModeId")), None)
            if mode:
                w, h = mode["size"]["width"], mode["size"]["height"]
                if o.get("rotation") in (2, 8):     # turned 90°: a portrait screen
                    w, h = h, w
                result.append({"name": o.get("name", ""), "width": w, "height": h,
                               "hz": round(mode.get("refreshRate", 0))})
    except ValueError:
        pass
    result.sort(key=lambda d: -(d["width"] * d["height"]))
    return result


def system():
    rel = {}
    for line in read("/etc/os-release").splitlines():
        k, _, v = line.partition("=")
        rel[k] = v.strip('"')
    os_name = rel.get("NAME", "Linux")
    version = rel.get("VERSION_ID", "")
    # Rolling releases (Arch, Tumbleweed) put a build date here; it's noise.
    if re.match(r"\d{8}", version):
        version = ""
    m = re.search(r"(\d+\.\d+(\.\d+)?)", run(["plasmashell", "--version"]))
    return {
        "os": f"{os_name} {version}".strip(),
        "osId": rel.get("ID", ""),
        "kernel": platform.release().split("-")[0],
        "plasma": m.group(1) if m else "",
        "hostname": platform.node(),
    }


def live_sensors():
    """ksystemstats ids that differ per machine: fans, NVMe temperature,
    and the interface carrying the default route."""
    out = {"fans": [], "nvmeTemp": "", "netIface": ""}
    raw = run(["busctl", "--user", "--json=short", "call", "org.kde.ksystemstats1",
               "/org/kde/ksystemstats1", "org.kde.ksystemstats1", "allSensors"])
    try:
        sensors = json.loads(raw)["data"][0]
    except (ValueError, KeyError, IndexError):
        sensors = {}
    # GPUs ksystemstats knows about (gpu0, gpu1, ...), so laptops with two
    # GPUs read temperature and power from both.
    out["gpuIds"] = sorted({m.group(1) for m in (re.match(r"gpu/(gpu\d+)/", sid) for sid in sensors) if m})
    for sid in sorted(sensors):
        if re.search(r"/fan\d*$", sid):
            label = sensors[sid][0]
            if sid.startswith("gpu/"):
                label = "GPU fan" if sid.endswith("fan1") else "GPU " + sid.rsplit("/", 1)[1]
            out["fans"].append({"id": sid, "label": label})
        elif not out["nvmeTemp"] and re.match(r"lmsensors/nvme-[^/]+/temp1$", sid):
            out["nvmeTemp"] = sid
    # amdgpu exposes board power as power1_average (µW), which ksystemstats
    # reports as 0 on some cards; the widget reads this file directly.
    out["gpuPowerFile"] = ""
    for f in sysglob("/sys/class/drm/card[0-9]/device/hwmon/hwmon*/power1_average") + \
             sysglob("/sys/class/drm/card[0-9]/device/hwmon/hwmon*/power1_input"):
        if read(f).isdigit():
            out["gpuPowerFile"] = f
            break
    m = re.search(r"\bdev\s+(\S+)", run(["ip", "route", "get", "1.1.1.1"]))
    if m:
        out["netIface"] = m.group(1)
    return out


# Small programs some tiles use. Missing ones only switch off a detail; the
# Settings "System check" says which package to install.
TOOLS = {
    # tool: (what it's for, {distro family: package})
    "notify-send": ("Focus timer alerts",
                    {"debian": "libnotify-bin", "fedora": "libnotify", "arch": "libnotify",
                     "suse": "libnotify-tools"}),
    "lspci": ("Graphics card name",
              {"debian": "pciutils", "fedora": "pciutils", "arch": "pciutils", "suse": "pciutils"}),
    "kscreen-doctor": ("Screen sizes in PC specs",
                       {"debian": "kscreen", "fedora": "kscreen", "arch": "kscreen", "suse": "kscreen6"}),
    "busctl": ("Fan speeds", {}),
}
# Shown to the user as a hint; never run.
INSTALL = {"debian": "sudo apt install", "fedora": "sudo dnf install",  # guard: text only
           "arch": "sudo pacman -S", "suse": "sudo zypper install"}     # guard: text only


def family():
    rel = {}
    for line in read("/etc/os-release").splitlines():
        k, _, v = line.partition("=")
        rel[k] = v.strip('"')
    ids = (rel.get("ID", "") + " " + rel.get("ID_LIKE", "")).split()
    for fam, names in (("debian", ("debian", "ubuntu")), ("fedora", ("fedora", "rhel")),
                       ("arch", ("arch",)), ("suse", ("suse", "opensuse"))):
        if any(i in names or i.startswith(names) for i in ids):
            return fam
    return ""


def check():
    """What's missing, and the command that installs it."""
    fam = family()
    missing = []
    for tool, (purpose, packages) in TOOLS.items():
        if tool == "notify-send" and (have("gdbus") or have("busctl")):
            continue        # notify() has a fallback
        if not have(tool):
            pkg = packages.get(fam, "")
            missing.append({"tool": tool, "purpose": purpose,
                            "install": INSTALL[fam] + " " + pkg if fam and pkg else ""})
    return {"family": fam, "missing": missing}


def notify(title, body):
    """Desktop notification: notify-send if installed, else straight over D-Bus."""
    title, body = title[:200], body[:500]
    if have("notify-send"):
        return ok(["notify-send", "-a", "Solidget", "-i", "chronometer", "--", title, body])
    if have("gdbus"):
        return ok(["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
                         "--object-path", "/org/freedesktop/Notifications",
                         "--method", "org.freedesktop.Notifications.Notify",
                         "Solidget", "0", "chronometer", title, body, "[]", "{}", "5000"])
    if have("busctl"):
        return ok(["busctl", "--user", "call", "org.freedesktop.Notifications",
                         "/org/freedesktop/Notifications", "org.freedesktop.Notifications", "Notify",
                         "susssasa{sv}i", "Solidget", "0", "chronometer", title, body, "0", "0", "5000"])
    return False


def battery():
    for ps in sysglob("/sys/class/power_supply/*"):
        if read(os.path.join(ps, "type")) == "Battery" and read(os.path.join(ps, "scope"), "System") == "System":
            cap = read(os.path.join(ps, "capacity"))
            return {"present": True,
                    "percent": int(cap) if cap.isdigit() else None,
                    "status": read(os.path.join(ps, "status"), "Unknown")}
    return {"present": False}


def tz_offsets(zones):
    """Current UTC offset in minutes for each IANA zone (DST-aware)."""
    from datetime import datetime
    try:
        from zoneinfo import ZoneInfo
    except ImportError:
        return {}
    out = {}
    for z in zones[:12]:
        # Only "Area/City"-style names: never a path like "../../etc/passwd".
        if not re.fullmatch(r"[A-Za-z0-9_+-]+(/[A-Za-z0-9_+-]+){0,2}", z):
            continue
        try:
            off = datetime.now(ZoneInfo(z)).utcoffset()
            out[z] = int(off.total_seconds() // 60)
        except Exception:
            pass
    return out


if __name__ == "__main__":
    if sys.argv[1:] == ["battery"]:
        print(json.dumps(battery()))
    elif sys.argv[1:2] == ["tz"]:
        print(json.dumps(tz_offsets(sys.argv[2:])))
    elif sys.argv[1:2] == ["notify"] and len(sys.argv) == 4:
        print(json.dumps({"sent": notify(sys.argv[2], sys.argv[3])}))
    else:
        print(json.dumps({
            "cpu": cpu(), "gpus": gpus(), "memory": memory(), "board": board(),
            "drives": drives(), "displays": displays(), "system": system(),
            "battery": battery(), "sensors": live_sensors(), "check": check(),
        }))
