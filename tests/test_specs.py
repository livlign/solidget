#!/usr/bin/env python3
"""Run: python3 tests/test_specs.py

Runs specs.py the way the widget does and checks its output. Works on any
Linux machine, including CI without a GPU, battery or Plasma.
"""
import atexit
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

SPECS = os.path.join(os.path.dirname(__file__), "..", "package", "contents", "code", "specs.py")


def run(*args):
    out = subprocess.run([sys.executable, SPECS, *args], capture_output=True, text=True, timeout=30)
    assert out.returncode == 0, out.stderr
    return json.loads(out.stdout)


class Specs(unittest.TestCase):
    def test_full_report_has_every_section(self):
        data = run()
        for key in ("cpu", "gpus", "memory", "board", "drives", "displays", "system", "battery", "sensors"):
            self.assertIn(key, data)
        self.assertGreater(data["cpu"]["threads"], 0)
        self.assertGreater(data["memory"]["totalBytes"], 0)
        self.assertIsInstance(data["gpus"], list)

    def test_battery_mode(self):
        self.assertIn("present", run("battery"))

    def test_time_zones(self):
        tz = run("tz", "UTC", "Asia/Kolkata", "Not/AZone")
        self.assertEqual(tz.get("UTC"), 0)
        self.assertEqual(tz.get("Asia/Kolkata"), 330)   # half-hour offsets work
        self.assertNotIn("Not/AZone", tz)               # junk is skipped, not a crash

    def test_time_zones_reject_paths_and_tricks(self):
        bad = ["../../../../etc/passwd", "/etc/localtime", "Europe/../../x", "$(id)", "a b", "x" * 300]
        self.assertEqual(run("tz", *bad), {})

    def test_gpu_power_file_is_a_sysfs_path(self):
        # main.qml runs `cat '<this path>'`, so it must never be anything else.
        path = run()["sensors"].get("gpuPowerFile", "")
        if path:
            self.assertRegex(path, r"^/sys/class/drm/card\d/device/hwmon/hwmon\d+/power1_(average|input)$")


FIXTURES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures")
EMPTY_BIN = tempfile.mkdtemp(prefix="solidget-nobin-")   # PATH with no tools at all
atexit.register(shutil.rmtree, EMPTY_BIN, True)


def machine(name, *args):
    """specs.py on a fake machine from tests/fixtures, with no helper tools
    installed (only python itself on PATH)."""
    env = {"SOLIDGET_SYSROOT": os.path.join(FIXTURES, name), "PATH": EMPTY_BIN, "HOME": "/nonexistent"}
    out = subprocess.run([sys.executable, "-I", SPECS, *args], capture_output=True, text=True, timeout=30, env=env)
    assert out.returncode == 0, out.stderr
    return json.loads(out.stdout)


class OtherMachines(unittest.TestCase):
    def test_raspberry_pi(self):
        d = machine("raspberry-pi")
        self.assertEqual(d["cpu"]["name"], "Raspberry Pi 5 Model B Rev 1.0")
        self.assertEqual(d["cpu"]["threads"], 4)
        self.assertEqual(d["gpus"], [])
        self.assertEqual(d["system"]["os"], "Debian GNU/Linux 13")
        self.assertFalse(d["battery"]["present"])

    def test_intel_laptop_with_nvidia(self):
        d = machine("intel-laptop")
        self.assertEqual(d["cpu"]["name"], "12th Gen Intel Core i7-1260P")
        self.assertEqual((d["cpu"]["cores"], d["cpu"]["threads"]), (8, 16))
        names = [g["name"] for g in d["gpus"]]
        self.assertEqual(names, ["NVIDIA GeForce RTX 3050 Ti Mobile", "Intel Iris Xe Graphics"])
        self.assertEqual(d["battery"], {"present": True, "percent": 76, "status": "Discharging"})
        self.assertEqual(machine("intel-laptop", "battery")["percent"], 76)

    def test_rolling_release_has_no_build_date(self):
        self.assertEqual(machine("tumbleweed")["system"]["os"], "openSUSE Tumbleweed")

    def test_system_check_names_the_package(self):
        missing = {m["tool"]: m["install"] for m in machine("intel-laptop")["check"]["missing"]}
        self.assertEqual(missing["lspci"], "sudo apt install pciutils")
        self.assertEqual(machine("tumbleweed")["check"]["family"], "suse")

    def test_no_crash_on_an_empty_system(self):
        d = machine("does-not-exist")
        self.assertEqual(d["gpus"], [])
        self.assertTrue(d["cpu"]["name"])


if __name__ == "__main__":
    unittest.main(verbosity=1)
