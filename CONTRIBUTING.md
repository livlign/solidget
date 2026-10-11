# Contributing

Thanks for helping! This page has everything you need. Please read the
**rules** before you write code: they keep Solidget fast, private and safe.

## Get started

```sh
git clone https://github.com/livlign/solidget.git
cd solidget
./install.sh --no-add                          # install your copy
systemctl --user restart plasma-plasmashell    # load it
./tests/run.sh                                 # run all checks
```

Plasma keeps the old widget loaded, so **restart Plasma after every change**.
Don't restart more than 3 times a minute: systemd then gives up. If that
happens: `systemctl --user reset-failed plasma-plasmashell && systemctl --user start plasma-plasmashell`

See errors: `journalctl --user -u plasma-plasmashell -f | grep -i solidget`

## The rules

1. **Keep it light.** Plasma redraws the whole widget whenever anything
   changes. So:
   - Update on the shared 1-second `app.tick`, not with your own fast timers.
   - No animations that run forever.
   - No `Canvas` for things that change often. Use `Shape` or `Rectangle`.
2. **Private by default.** Anything that could identify someone (computer
   name, network name, IP, location) must be hidden when `app.masked` is on.
3. **No new websites or programs** unless there's a real need. The
   security guard (`tests/guard.py`) will stop you. If you do need one, add it
   to the guard's list and to the "What goes online" table in the README, and
   explain why in your pull request.
4. **Build commands with `Shell.command([...])`, never by gluing strings.**
   It quotes every piece, so a city called `x; rm -rf ~` stays just a name.
5. **Show text as plain text.** Every label needs `textFormat: Text.PlainText`
   (the guard checks). Otherwise a song called `<img src=...>` could load
   things from the internet.
6. **Don't trust outside data.** Anything from a website, a music player or
   the config file can be wrong or hostile. Check numbers are numbers, keep
   strings short, only accept https links, and keep sizes in a sane range.
7. **Works in every look.** Check your change in at least Glass + Aurora
   (dark), Flat + Ink & Paper (light) and Pixel + Moss Lantern.
8. **Use the shared helpers** so settings apply everywhere:
   `app.tempText()`, `app.bytesText()`, `app.netRateText()`, `app.accent()`.
   Size things with the tile's `u` so they scale.
9. **Plain words.** In the widget and in docs, write like you'd explain it
   to a friend. Short sentences. No jargon.

## Code style

- Match the code around you. 4 spaces, no tabs.
- Comments explain *why*, not *what*.
- Wrap every visible string in `i18n()`.
- Use `console.warn` for debugging; Plasma drops `console.log`.
- In QML, never write `foo: foo` when an object has the id `foo`. It silently
  binds to itself.
- In `config/main.xml`, never put `--` inside a comment. It breaks the file.

## Adding a tile

1. Create `package/contents/ui/FooTile.qml`, starting from `GlassTile`
   (or `GaugeTile` for a ring gauge). Copy a small tile like `QuoteTile.qml`.
2. In `main.qml`: add `foo` to `allTiles` and `tileInfo`, add a
   `Component { id: fooTile; FooTile { ... } }` and a `case` in the
   `sourceComponent` switch.
3. In `layout.js`: add its sizes to `SPANS`. In `palette.js`: add colors to
   `ACCENTS` and `TILE_HUE`.
4. Run `./tests/run.sh`. It tells you if you missed a step.

## Pull requests

- One change per pull request. Small is great.
- Add a screenshot for anything visual, **with personal info hidden**.
- Commit messages: short and in the present tense, like `Add moon phase to calendar`.
- `./tests/run.sh` must pass. GitHub runs it on every pull request too.

## Where things are

| Path | What's in it |
|---|---|
| `package/contents/ui/main.qml` | Sensors, presets, settings, the board |
| `package/contents/ui/*Tile.qml` | One file per tile |
| `package/contents/ui/EditPanel.qml` | The Settings panel |
| `package/contents/code/layout.js` | Places tiles on the grid |
| `package/contents/code/palette.js` | Styles, themes and colors |
| `package/contents/code/shell.js` | Safe command building (`Shell.command`) |
| `package/contents/code/specs.py` | Reads your hardware, prints JSON |
| `package/contents/config/main.xml` | Every saved setting |
| `tests/` | All checks; `run.sh` runs them |
