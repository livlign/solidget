# Publishing on the KDE Store

Our page: https://store.kde.org/p/2378131/

For maintainers. Takes about 10 minutes the first time.

## First time

1. Make a free account at [store.kde.org](https://store.kde.org) (top right, **Register**).
2. Build the file: `./tools/package.sh` → `dist/solidget-<version>.plasmoid`
   (or download it from the latest GitHub release).
3. Click **Add Product** and fill in:

   | Field | Value |
   |---|---|
   | Category | **Plasma 6 Applets** (under Plasma 6 Extensions) |
   | Title | Solidget |
   | Summary | Live stats, your PC's specs and your day, in one good-looking board. |
   | Description | Copy the text below |
   | License | GPLv2 or later |
   | Link to source | https://github.com/livlign/solidget |
   | Logo | `docs/screenshots/aurora-glass.jpg` (crop to square) |
   | Gallery | `docs/hero.png`, then the three files in `docs/screenshots/` |
   | Files | the `.plasmoid` file, version from `package/metadata.json` |

4. Save. It shows up in Plasma's **Get New Widgets** within an hour or so.

## Each new version

1. Update `Version` in `package/metadata.json` and add a section to `CHANGELOG.md`.
2. Tag it: `git tag v0.5.0 && git push origin v0.5.0`. GitHub builds the
   `.plasmoid` and makes a release by itself.
3. On the store page: **Edit → Files**, upload the new `.plasmoid`, set its
   version, and paste the changelog section. Users get it as an update in Discover.

## Description to paste

```
One solid widget for your KDE desktop: live system stats, your PC's specs, and the little everyday things, all in one good-looking board.

WHAT YOU GET
- 20 tiles: CPU, GPU, memory, temperatures, network, storage, fans, top apps, clock and weather, calendar, music controls, photo of the day, world clocks, focus timer, sticky note, quote of the day, and a pixel pet (a poodle or a cat) that reacts to your CPU.
- 5 styles (Plasma, Glass, Flat, Clear, Pixel) x 10 color themes, or one-click looks like Retro Terminal and Paper.
- Fits any space: a corner card, a sidebar, or a whole spare monitor, landscape or portrait.
- Drag and resize tiles. They stay exactly where you put them.
- Private by default: your computer name, Wi-Fi name, IP and location are hidden, so screenshots are safe to share.
- Light: about 5% of one CPU core with every tile on.

HOW TO USE
Add it to your desktop, hover over it and click Settings.

WHAT GOES ONLINE
Only the weather (open-meteo.com, ipwho.is), world clock city lookups (open-meteo.com) and the photo of the day (bing.com), and only when those tiles are shown. No accounts, no tracking.

Optional: to show your RAM type and speed, clone the repo and run ./install.sh --ram (asks for your password once).

Source, bug reports and ideas: https://github.com/livlign/solidget
```
