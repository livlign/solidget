# Solidget TODO

## Editing flow
- [x] Pencil opens the **Settings panel** first. The panel has an **Edit layout**
      button that switches to edit-layout mode (drag/resize on the board).
      Today the pencil goes straight to edit-layout mode and Settings is in its toolbar.

## Layout
- [ ] Presets assume a landscape screen. Add a **Screen orientation** choice
      (Landscape / Portrait, default: detected from the widget's shape) and give
      each preset a tile order and preferred sizes per orientation.

## Appearance
- [ ] More **styles** (how tiles are built): Glass (current), Flat, Transparent
      (macOS-like: light blur, no card, minimal chrome), Pixel (square corners,
      pixel font, stepped bars), and more.
- [ ] **Themes** (colors), fewer than 10 to start. Names must be our own, not
      borrowed from popular themes (no Dracula, Tokyo Night, Nord, …).
      Draft names to refine:
      Aurora (current), Glacier Mint (light, cool), Sandstone (light, warm),
      Ember Dusk (dark, warm), Deep Lagoon (dark, teal), Plum Velvet (dark,
      purple), Moss Lantern (dark, green/amber), Ink & Paper (black & white),
      Lotus Pond (light, pink/green).
- [ ] Decide: one setting or two? Proposal below.

### Style vs theme: proposal
Keep them as **two independent settings**, shown together in one
"Appearance" section, plus a few ready-made combinations:

- **Style = shape and material**: corners, borders, card fill/blur, shadows,
  glow, gauge drawing, font. Glass, Flat, Transparent, Pixel.
- **Theme = colors only**: background tint, text, the per-tile accent pairs,
  the heat ramp. Aurora, Glacier Mint, Ink & Paper, …
- **Overlaps resolved by that split**: "black & white" is a *theme* (Ink & Paper),
  so it works with any style; "pixel" is a *style*, so it works with any theme.
- Every style must look right with every theme (test matrix: styles × themes ×
  light/dark wallpaper).
- Ready-made **looks** (e.g. "Retro terminal" = Pixel + Moss Lantern) are just
  one click that sets both; the user can still change either afterwards.
- Default theme option: **Follow Plasma** (light/dark from the system colors).

## Privacy
- [x] **Mask sensitive information** option, **on by default**: hostname,
      Wi-Fi name, IP address, weather location (and anything similar added
      later) are hidden/blurred on the board and in "Copy specs".

## Units
- [x] **Units** settings: temperature (°C / °F), data rates (bytes vs bits,
      binary KiB vs decimal KB), maybe wind speed for weather. The weather
      °C/°F toggle exists already; generalize it so every tile uses the same choice.
