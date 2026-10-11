# What's new

## 0.6.0

- **New Plasma style, now the default.** Tiles use your Plasma Style's own
  widget background, your accent color and plain headings, so the board
  sits in with Plasma's built-in widgets. Busy and hot readings use
  Plasma's green, yellow and red. Boards that already picked a style or
  theme keep it; Glass, Flat, Clear, Pixel and every theme are still in
  Settings → Look.
- In the Plasma style, Settings uses Plasma's own buttons, switches, text
  fields and tabs, on a Plasma dialog background. Media and focus timer
  buttons are flat like Plasma's, and every tile has the same padding.
- The right-click menu says **Configure Solidget…**, like other widgets.
- Now playing no longer pushes the song title and time past the tile's
  edge on wide, short tiles; the cover shrinks to make room.
- The Temperatures tile no longer pushes its last bar (SSD) past the
  bottom edge when it's short.
- Small video thumbnails from browsers (Chrome sends tiny ones) are no
  longer stretched and blurry in Now playing. They show whole, over a
  soft blurred copy of themselves.

## 0.5.0

- **Follow Plasma** now really follows Plasma: your system's background,
  text and accent color. Before, it looked just like Aurora.
- Aurora is now the default theme, so new boards look the same as before.
- Fixed the Follow Plasma card in Settings showing white text on a light
  background.
- **New desk pet:** an apricot teddy-cut poodle with round bear ears and
  short legs. It keeps busy: sits, wiggles, sniffs around, yawns,
  play-bows, trots and takes short naps. When the PC gets busy it hops,
  plays fetch, spins and does zoomies; when it's hot it lies down panting.
  The cat is still there: Settings → General → Desk pet.
- **Redesigned Now playing:** the cover fills the tile's height, the song
  name drops the repeated artist ("Artist - Song"), calmer buttons with the
  time beside them, and a thin progress line. Video thumbnails lose their
  black bars. Nothing spills out of small tiles anymore.
- Photo of the day captions are a sensible size on big tiles.
- **Top apps shows memory and CPU** for every app. Click "by CPU" in its
  corner to sort by memory instead.
- The Temperatures tile no longer cuts off its last bar when it's small.
- Theme and look cards keep the same size when you pick one.
- **Storage shows a read/write chart** like Network, with colored dots
  that match the lines.
- Fans spin smoothly again (a little more CPU than the one-step-a-second
  turn).

## 0.4.0

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
