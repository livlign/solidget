#!/usr/bin/env python3
"""Draws the poodle desk pet and saves it as one sprite sheet.

Run: python3 tools/poodle.py   (needs Pillow)
Writes package/contents/images/poodle.png: one row per activity (in MOODS
order), up to 4 frames each, every frame CELL_W x CELL_H pixels. PetTile.qml
shows one cell at a time, scaled up with sharp pixels.

Every pose shares one look (the napping pose): flat apricot coat with dotted
curls, a round face-on head with round bear ears, a light muzzle, button
eyes and nose, dark outlines and softer lines where parts overlap. The body
faces left; the tile mirrors it to walk right. No tail, like the real dog.
"""
import os

W, H = 32, 25
GROUND = 23          # bottom row of the paws (the outline sits just below)
N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))


class Pose:
    def __init__(self):
        self.g = [["." for _ in range(W)] for _ in range(H)]

    def ell(self, cx, cy, rx, ry, ch="b"):
        for y in range(H):
            for x in range(W):
                if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1:
                    self.g[y][x] = ch

    def ring(self, cx, cy, rx, ry, pad=0.7):
        """A soft line just outside an oval, where it covers what's behind."""
        for y in range(H):
            for x in range(W):
                d = ((x + .5 - cx) / (rx + pad)) ** 2 + ((y + .5 - cy) / (ry + pad)) ** 2
                if d <= 1 and self.g[y][x] != ".":
                    self.g[y][x] = "K"

    def pt(self, pts, ch):
        for x, y in pts:
            x, y = round(x), round(y)
            if 0 <= x < W and 0 <= y < H:
                self.g[y][x] = ch

    def curls(self, skip=lambda x, y: False):
        for y in range(H):
            for x in range(W):
                if self.g[y][x] == "b" and (x * 2 + y * 3) % 5 == 0 and not skip(x, y):
                    self.g[y][x] = "h"

    def rows(self):
        g = self.g
        for y in range(H):
            for x in range(W):
                if g[y][x] == "." and any(0 <= x + a < W and 0 <= y + b < H and g[y + b][x + a] not in ".k" for a, b in N4):
                    g[y][x] = "k"
        return ["".join(r) for r in g]


def leg(p, x, top, bot=GROUND, dx=0, lift=0, coat="b"):
    """A 3-wide fluffy leg; its lower half shifts by dx, the paw lifts by lift."""
    bot -= lift
    mid = (top + bot) / 2
    for y in range(round(top), bot + 1):
        xx = x + (dx if y > mid else 0)
        p.pt([(xx - 1, y), (xx + 3, y)], "K") if coat == "b" else None
        p.pt([(xx, y), (xx + 1, y), (xx + 2, y)], coat)


def head(p, hx, hy, eyes="open", mouth="", ears_up=0, look_down=0):
    """The napping pose's head: round, face-on, bear ears at the top corners."""
    hx, hy = round(hx), round(hy)     # whole pixels keep the face crisp
    p.ell(hx - 6.2, hy - 1.6 - ears_up, 2.7, 3.0, "s")
    p.ell(hx + 6.2, hy - 1.6 - ears_up, 2.7, 3.0, "s")
    p.ring(hx, hy, 5.9, 4.5)
    p.ell(hx, hy, 5.9, 4.5)
    p.curls(lambda x, y: hx - 5 <= x <= hx + 4 and hy - 2 <= y <= hy + 5)
    p.ell(hx - 0.5, hy + 2.4 + look_down, 2.8, 1.8, "m")
    e1, e2, ey = hx - 4, hx + 2, hy - 1 + look_down
    if eyes == "open":
        p.pt([(e1, ey), (e1 + 1, ey), (e1, ey + 1), (e1 + 1, ey + 1),
              (e2, ey), (e2 + 1, ey), (e2, ey + 1), (e2 + 1, ey + 1)], "e")
        p.pt([(e1 + 1, ey), (e2 + 1, ey)], "w")
    elif eyes == "happy":       # little arches
        p.pt([(e1, ey + 1), (e1 + 1, ey), (e1 + 2, ey + 1), (e2 - 1, ey + 1), (e2, ey), (e2 + 1, ey + 1)], "e")
    else:                       # closed
        p.pt([(e1, ey + 1), (e1 + 1, ey + 1), (e2, ey + 1), (e2 + 1, ey + 1)], "e")
    nx, ny = hx - 1, hy + 1 + look_down
    p.pt([(nx, ny), (nx + 1, ny), (nx, ny + 1), (nx + 1, ny + 1)], "n")
    if mouth == "tongue":
        p.pt([(nx, ny + 2), (nx + 1, ny + 2), (nx, ny + 3), (nx + 1, ny + 3)], "t")
    elif mouth == "pant":
        p.pt([(nx, ny + 2), (nx + 1, ny + 2)], "t")
    elif mouth == "yawn":
        p.pt([(nx - 1, ny + 2), (nx, ny + 2), (nx + 1, ny + 2), (nx + 2, ny + 2), (nx, ny + 3), (nx + 1, ny + 3)], "K")
        p.pt([(nx, ny + 3), (nx + 1, ny + 3)], "t")


def side_head(p, hx, hy, eyes="open", mouth="", ears_up=0):
    """Head in profile, nose pointing left (the way the body walks): a round
    curly crown, a short muzzle, one eye, and a round bear ear on top, like
    the face-on head."""
    hx, hy = round(hx), round(hy)
    p.ring(hx, hy, 4.6, 4.2)
    p.ell(hx, hy, 4.6, 4.2)                                        # skull
    p.ell(hx - 0.5, hy - 3.2, 3.2, 1.8)                             # top-knot
    p.curls(lambda x, y: x < hx - 1 and y > hy - 1)
    ey_ = hy - 3.4 - ears_up                                        # round bear ear on top, toward the back
    p.ring(hx + 2.5, ey_, 2.5, 2.4)
    p.ell(hx + 2.5, ey_, 2.5, 2.4, "s")
    p.ell(hx + 2.5, ey_ + 0.3, 1.2, 1.1, "m")
    p.ring(hx - 4, hy + 1.6, 2.3, 1.7)
    p.ell(hx - 4, hy + 1.6, 2.3, 1.7, "m")                          # short muzzle
    p.pt([(hx - 6, hy + 0.8), (hx - 5, hy + 0.8), (hx - 6, hy + 1.8)], "n")
    ex, ey = hx - 3, hy - 1
    if eyes == "open":
        p.pt([(ex, ey), (ex + 1, ey), (ex, ey + 1), (ex + 1, ey + 1)], "e")
        p.pt([(ex, ey)], "w")
    elif eyes == "happy":
        p.pt([(ex - 1, ey + 1), (ex, ey), (ex + 1, ey + 1)], "e")
    else:
        p.pt([(ex, ey + 1), (ex + 1, ey + 1)], "e")
    if mouth in ("tongue", "pant"):
        p.pt([(hx - 5, hy + 3.2), (hx - 4, hy + 3.2)] + ([(hx - 5, hy + 4.2)] if mouth == "tongue" else []), "t")


def stand(legs=(0, 0, 0, 0), lifts=(0, 0, 0, 0), bob=0, eyes="open", mouth="", ears_up=0, head_dy=0, head_dx=0, wiggle=0, bow=0, side=False):
    """Standing side-on, head turned to you (or in profile, `side`, looking
    where it goes). legs: lower-leg shifts for (near front, far front, near
    back, far back)."""
    p = Pose()
    nf, ff, nb, fb = legs
    lnf, lff, lnb, lfb = lifts
    by = 18 - bob      # low body, short legs
    leg(p, 15, by + 1 + bow, dx=ff, lift=lff, coat="s")           # far legs, darker
    leg(p, 23, by + 1, dx=fb, lift=lfb, coat="s")
    p.ell(19 + wiggle, by - bow * 0.3, 6.6, 3.8)                    # round body (no tail)
    p.ell(14.5, by + 0.4 + bow * 0.6, 3.4, 3.4)                     # chest
    p.curls()
    leg(p, 12, by + 2 + bow, dx=nf, lift=lnf)                     # near legs
    leg(p, 21 + wiggle, by + 2, dx=nb, lift=lnb)
    if side:
        side_head(p, 10 + head_dx, by - 5.5 + head_dy + bow, eyes, mouth, ears_up)
    else:
        head(p, 10 + head_dx, by - 6.5 + head_dy + bow, eyes, mouth, ears_up, look_down=1 if head_dy > 2 else 0)
    return p.rows()


def sit(eyes="open", mouth="", wiggle=0, hop=0, ears_up=0, paw=0, rear=0):
    """Sitting side-on, head turned to you. paw lifts the front paw (begging);
    rear sits the chest up straighter."""
    p = Pose()
    gy = GROUND - hop
    p.ell(21 + wiggle, gy - 3.6, 5.2, 4.2)                          # round rump on the ground
    p.ell(16 + rear * 0.5, gy - 5.5 - rear, 3.8, 3.8 + rear * 0.5)   # upright chest
    p.curls()
    p.ring(23.5 + wiggle, gy - 0.6, 2.4, 1.3)                       # hind paw
    p.ell(23.5 + wiggle, gy - 0.6, 2.4, 1.3)
    if paw:                                                         # front paw up, bent
        leg(p, 13, gy - 6 - rear - paw, gy - paw - 2)
    else:
        leg(p, 14, gy - 4, gy)                                      # front leg
    head(p, 10 + rear * 0.3, gy - 11.5 - rear, eyes, mouth, ears_up)
    return p.rows()


def lie(eyes="closed", mouth="", breathe=0):
    """The napping pose: lying down, head resting on the front paws."""
    p = Pose()
    dy = 4 - breathe
    p.ell(16, 16 + dy, 8, 3.6)                                      # body
    for x0 in (6, 14):                                              # front paws
        for y in (18 + dy, 19 + dy):
            p.pt([(x0 - 1, y), (x0 + 3, y)], "K")
            p.pt([(x0, y), (x0 + 1, y), (x0 + 2, y)], "b")
    p.curls()
    head(p, 11, 13 + dy, eyes, mouth)
    return p.rows()


def scratch(i):
    """Sitting, a hind leg up scratching behind the ear, eyes shut in bliss."""
    p = Pose()
    gy = GROUND
    p.ell(21, gy - 3.6, 5.2, 4.2)                                   # rump
    p.ell(16, gy - 5.5, 3.8, 3.8)                                   # chest
    p.curls()
    leg(p, 14, gy - 4, gy)                                          # front leg
    head(p, 9, gy - 11 + [0, 1, 0, 1][i], "happy" if i % 2 else "closed", "tongue" if i % 2 else "")
    # The hind leg, over it all: from the rump up to the ear, paw a-blur.
    tip = (17 + [0, 1, 0, -1][i], gy - 12 - [0, 1, 2, 1][i])
    for t in (0, 0.25, 0.5, 0.75, 1):
        x, y = 23 + (tip[0] - 23) * t, gy - 2 + (tip[1] - gy + 2) * t
        p.ring(x, y, 1.5, 1.5)
    for t in (0, 0.25, 0.5, 0.75, 1):
        x, y = 23 + (tip[0] - 23) * t, gy - 2 + (tip[1] - gy + 2) * t
        p.ell(x, y, 1.5, 1.5, "s")
    return p.rows()


def roll(i):
    """On its back, belly up, paws waving: a good roll on the rug."""
    p = Pose()
    sway = [0, 1, 0, -1][i]
    for n, x in enumerate((10, 14, 19, 23)):                        # paws in the air
        up = 9 + (1 if (n + i) % 2 else 0)
        for y in range(up, 19):
            p.pt([(x + sway - 1, y), (x + sway + 2, y)], "K")
            p.pt([(x + sway, y), (x + sway + 1, y)], "s" if n % 2 else "b")
    p.ell(17 + sway * 0.5, 19.5, 7.6, 3.4)                         # back on the floor
    p.curls()
    p.ell(17 + sway * 0.5, 18.4, 4.6, 1.6, "m")                    # light belly
    head(p, 7, 18 + (i % 2), "happy", "tongue")
    return p.rows()


WALK = [((1, -1, -1, 1), (0, 0, 0, 0)), ((0, 0, 0, 0), (0, 1, 1, 0)),
        ((-1, 1, 1, -1), (0, 0, 0, 0)), ((0, 0, 0, 0), (1, 0, 0, 1))]
RUN = [((-2, -2, 2, 2), (1, 1, 1, 1)), ((-1, 0, 1, 1), (0, 0, 0, 0)),
       ((2, 1, -2, -1), (1, 1, 0, 0)), ((0, -1, 0, 1), (0, 0, 0, 0))]

F = {
    "walk":  [stand(l, k, bob=i % 2, side=True) for i, (l, k) in enumerate(WALK)],
    "run":   [stand(l, k, bob=[2, 0, 1, 0][i], mouth="tongue", ears_up=[1, 0, 1, 0][i], side=True) for i, (l, k) in enumerate(RUN)],
    "sit":   [sit(), sit(), sit(eyes="closed"), sit()],
    "wag":   [sit(eyes="happy", mouth="tongue", wiggle=-1), sit(eyes="happy", mouth="tongue", wiggle=1, hop=1),
              sit(eyes="happy", mouth="tongue", wiggle=-1), sit(eyes="open", mouth="tongue", wiggle=1)],
    "sniff": [stand(head_dy=5, head_dx=-1, side=True), stand(head_dy=6, head_dx=-2, lifts=(1, 0, 0, 0), side=True),
              stand(head_dy=5, head_dx=-1, side=True), stand(head_dy=4, head_dx=-1, lifts=(0, 0, 1, 0), side=True)],
    "bow":   [stand(bow=3, eyes="happy", mouth="tongue", wiggle=-1), stand(bow=3, eyes="happy", mouth="tongue", wiggle=1),
              stand(bow=3, mouth="tongue", wiggle=-1), stand(bow=2, mouth="tongue", bob=1)],
    "yawn":  [sit(eyes="closed"), sit(eyes="closed", mouth="yawn"), sit(eyes="closed", mouth="yawn"), sit(eyes="closed")],
    "sleep": [lie(), lie(breathe=1)],
    "hot":   [lie("open", "tongue"), lie("open", "pant", breathe=1)],
    # Head down in the bowl, chewing.
    "eat":   [stand(head_dy=5, head_dx=-3, eyes="closed", side=True), stand(head_dy=6, head_dx=-3, eyes="closed", side=True),
              stand(head_dy=5, head_dx=-3, eyes="closed", lifts=(0, 0, 0, 1), side=True), stand(head_dy=6, head_dx=-3, eyes="closed", side=True)],
    # A back leg up by the tree.
    "pee":   [stand(lifts=(0, 0, 5, 0), legs=(0, 0, 3, 0), eyes="happy", side=True), stand(lifts=(0, 0, 5, 0), legs=(0, 0, 3, 0), eyes="closed", side=True)],
    # Shaking off the bath water.
    "shake": [stand(wiggle=-2, eyes="closed", ears_up=1), stand(wiggle=2, eyes="closed"),
              stand(wiggle=-2, eyes="closed", ears_up=1), stand(wiggle=1, eyes="happy", mouth="tongue")],
    # Sitting up, one paw raised: asking for something.
    "beg":   [sit(paw=2, rear=1, mouth="tongue"), sit(paw=3, rear=1, eyes="happy", mouth="tongue")],
    # Lying down awake: resting, looking about, blinking.
    "rest":  [lie("open"), lie("open", breathe=1), lie("closed"), lie("open", "tongue", breathe=1)],
    "scratch": [scratch(i) for i in range(4)],
    "roll":  [roll(i) for i in range(4)],
    # Sitting up, ears up, woofing at something.
    "bark":  [sit(ears_up=1), sit(ears_up=1, mouth="yawn", hop=1), sit(ears_up=1), sit(ears_up=1, mouth="yawn", hop=1)],
}

MOODS = ["walk", "run", "sit", "wag", "sniff", "bow", "yawn", "sleep", "hot", "eat", "pee", "shake", "beg",
         "rest", "scratch", "roll", "bark"]
COLORS = {"k": "#4a2c17", "K": "#8a5530", "b": "#e2a66b", "h": "#d0904f", "s": "#c27f45",
          "m": "#f0c590", "e": "#1a1110", "w": "#ffffff", "n": "#1a1110", "t": "#f28ba8"}
CELL_W, CELL_H = W, H

if __name__ == "__main__":
    from PIL import Image
    cols = max(len(F[m]) for m in MOODS)
    sheet = Image.new("RGBA", (CELL_W * cols, CELL_H * len(MOODS)), (0, 0, 0, 0))
    for row, mood in enumerate(MOODS):
        for col, frame in enumerate(F[mood]):
            for y, line in enumerate(frame):
                for x, ch in enumerate(line):
                    if ch in COLORS:
                        rgb = tuple(int(COLORS[ch][i:i + 2], 16) for i in (1, 3, 5))
                        sheet.putpixel((col * CELL_W + x, row * CELL_H + y), rgb + (255,))
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "package", "contents", "images", "poodle.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out, optimize=True)
    print("wrote", os.path.normpath(out), sheet.size, "frames:", {m: len(F[m]) for m in MOODS})
