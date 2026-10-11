# Security

## Report a problem

Please **don't** open a public issue for security problems. Instead use
[Report a vulnerability](https://github.com/livlign/solidget/security/advisories/new)
on GitHub. It stays private between you and the maintainers.

Tell us what you found and how to reproduce it. We'll reply as soon as we can.

## What Solidget does on your PC

- Runs as part of Plasma, as you. It never needs root.
- Reads hardware info from `/proc`, `/sys` and standard tools (`lspci`, `lsblk`).
- Starts only these programs: its own `specs.py`, `cat` (to read a GPU power
  file) and `notify-send` (for focus timer alerts).
- Contacts only the websites listed in the README under "What goes online",
  always over https.
- Saves its settings in Plasma's normal config file. Nothing else is stored.

`tests/guard.py` checks these promises on every pull request.
