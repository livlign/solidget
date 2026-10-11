#!/usr/bin/env python3
"""Run: python3 tests/test_specs.py

Runs specs.py the way the widget does and checks its output. Works on any
Linux machine, including CI without a GPU, battery or Plasma.
"""
import json
import os
import subprocess
import sys
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


if __name__ == "__main__":
    unittest.main(verbosity=1)
