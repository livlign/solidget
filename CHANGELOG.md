# What's new

## Unreleased

- **Works on more distros and hardware.** The hardware check is tested on
  Arch, Debian, Ubuntu, Fedora and openSUSE, plus simulated Raspberry Pi and
  Intel + NVIDIA laptop setups.
- **System check** in Settings → General: shows what's missing and the
  exact command to install it.
- Laptops with two GPUs show the dedicated one, the hotter temperature
  and the total power.
- Graphics without its own memory shows "Shared" instead of "0 B".
- Better names when `lspci` isn't installed; no build numbers after
  Arch or Tumbleweed.
- Focus timer alerts work even without `notify-send`.

## 0.3.0

The first public release.

- **20 tiles.** System stats (CPU, GPU, memory, temperatures, network,
  storage, fans, top apps, core heatmap, battery) and everyday ones (clock and
  weather, calendar, music controls, photo of the day, world clocks, focus
  timer, sticky note, quote of the day, and a pixel cat that reacts to your CPU).
- **4 styles × 10 color themes**, plus one-click looks like *Retro Terminal*.
- **Fits any space**, landscape or portrait. Drag and resize tiles; they stay
  where you put them.
- **Private by default**: computer name, Wi-Fi name, IP and location are hidden.
- **Light**: about 5% of one CPU core with every tile on.
- **Safe**: text from the internet is never treated as code or HTML, and
  every command the widget runs is checked.
