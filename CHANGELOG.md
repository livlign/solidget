# What's new

## 0.7.1

- **RGB theme** is calmer: a thin rim on every tile, cut from one rainbow
  laid over the whole board, flowing slowly from top to bottom at a slight
  angle. No more glow or moving parts, and it no longer redraws the
  desktop ten times a second.
- The widget no longer runs off the bottom of the screen: if it's bigger
  than its screen (the desktop's layout area can be larger than the screen
  after scaling or rotation changes), it trims itself to fit, and the
  placements measure the real screen. A board arranged by hand with more
  rows than fit also shrinks its rows to fit.
- The palm tree's fronds (and the edges of some other pictures, like the
  pines, bush and hydrant) are no longer cut off.

## 0.7.0

- **New Uptime tile.** How long your PC has been on, over a scene you pick:
  the sky outside right now (sunrise, a blue day, sunset, stars and the
  real moon phase, with clouds, rain or snow from the weather), a watch
  dial of 60 ticks around the tile's edge with a sweep going round once a
  minute, a binary clock with 0s and 1s raining behind it (and the uptime
  in hex), a terminal running `uptime -p`, a heart monitor that sweeps across
  drawing beats that race with the CPU, a face that gets sleepier the longer you stay
  up, planets that go round once a minute, hour, day and week, drifting
  colors, your own picture, or just the numbers. Pick the font, weight,
  size, color, position, title and format (3d 2h, words, a ticking
  74:12:05 or days). It can show your longest uptime too (off by default). Click the tile to
  try the next scene. Binary is the default. Settings → Personal.
- **The desk pet has a home:** a room in perspective that fills the whole
  tile, with furniture standing against the back wall and a big window
  that shows the real sky and weather. Two rooms (Settings → Personal →
  Room): the cozy room (warm wallpaper, a honey floor, a bookshelf and
  plant, an armchair and lamp, a picture and a clock, the dog's own bed,
  hills and a cottage outside) and the nerd room (below). No header or
  caption; a thought bubble shows what the pet wants. It roams the whole
  floor (back and front, not just side to side), looks where it's going,
  naps in its bed, drinks and picks toys, and walks up to its bowl to eat.
  The room turns a little golden at sunrise and sunset and dimmer at night.
- **Look after it.** Buttons on the tile pet it, feed it, give it a bath,
  clean up after it, take it for a walk and play with it (or click the
  pet to pet it). It gets hungry, bored and grubby over hours, and needs
  to go out: skip walks and there's a mess to clean up. Time only counts
  while it's on screen. Don't want that? Turn "Needs looking after" off.
- **Walks** go through three places in a row: the park, a meadow by a
  pond, the woods, a snowy field, a frozen pond, snowy pines, the beach or
  desert dunes. The pet sniffs around, finds a tree or hydrant to pee on,
  and chases a bird, butterfly, squirrel, bunny, crab or a doggy friend.
- Pet settings moved to Settings → Personal: name, size, where walks go,
  when to show the buttons, needs on or off, and the room on or off.
- **Nerd room** (the default): a dark den with an LED strip, a bed with a
  tufted headboard and shelves above it, a desk with two monitors and a
  gaming chair, a rug, and a window onto a city that follows
  the real time and weather (lit windows, neon signs and a flying car after
  dark; clouds, rain or snow). The pet naps on the bed and leaves for walks
  through the door in the side wall.
- **Three new themes:** Snow (a true light theme: solid white tiles, dark
  text, vivid colors), Midnight (a true dark theme: solid near-black tiles with a fine edge) and RGB
  (black tiles with a rainbow rim: one rainbow laid across the whole board
  that flows from tile to tile, like an RGB keyboard). Ready-made looks for each: Daylight, Midnight and
  RGB Rig.
- In the Plasma style, tiles fill their space like in the other styles:
  the frame's shadow sits outside the tile instead of shrinking the card,
  and text gets proper padding from the card's edge.
- **Separate units:** pick °C or °F for the weather and for the PC's
  temperatures on their own (Settings → General → Units).
- The edit toolbar (with Done) is now at the top, where the Settings
  button is, so a taskbar along the bottom can't hide it. It and Settings
  stay on the visible part of the screen, even when the widget is taller
  than the screen (for example after changing display scaling). Thanks to a Bazzite user for the report.
- **Power & fans on laptops:** shows whether the charger is plugged in and
  how fast the battery charges or drains, and time until full or empty.
  The Battery tile shows the charger and time left too. Both update every
  10 seconds (was every minute), so plugging in shows up right away.

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
