# Security

## Report a problem

Please **don't** open a public issue for security problems. Use
[Report a vulnerability](https://github.com/livlign/solidget/security/advisories/new)
instead. Only you and the maintainers can see it.

Tell us what you found and how to make it happen. We'll reply as soon as we can.

## What Solidget does on your PC

- Runs inside Plasma, as you. It never needs root.
- Reads hardware info from `/proc`, `/sys` and standard tools (`lspci`, `lsblk`).
- Starts only three programs: its own `specs.py`, `cat` (to read the GPU's
  power use) and `notify-send` (for focus timer alerts).
- Talks only to the websites listed in the README, always over https.
- Saves its settings in Plasma's normal config file. Nothing else.

## How it protects you

| Risk | What we do |
|---|---|
| Someone sneaks a command in (a city name like `x; rm -rf ~`) | Every command is built with `Shell.command()`, which quotes each piece. A test feeds it nasty strings through a real shell. |
| A song or photo title contains HTML that loads things from the internet | All text is shown as plain text. The guard fails if any label forgets. |
| A website sends bad or strange data | Numbers, dates and names are checked and shortened before use. Images and links must be https. |
| The config file is edited by hand or damaged | Sizes and positions are kept in range, so a bad value can't freeze Plasma. A test throws junk at the layout. |
| Running the installer with `sudo` | It refuses. Only one read-only command (`dmidecode`) ever uses sudo. |
| A new website or command slips in unnoticed | `tests/guard.py` only allows the ones listed above. |
| Someone tampers with our GitHub build tools | Actions are pinned to exact versions. CodeQL scans the code every week. |

All of this runs on every pull request (`./tests/run.sh`).
