#!/usr/bin/env python3
"""Draws the poodle desk pet and saves it as one sprite sheet.

Run: python3 tools/poodle.py   (needs Pillow)
Writes package/contents/images/poodle.png: one row per activity (in MOODS
order), up to 4 frames each, every frame CELL_W x CELL_H pixels. PetTile.qml
shows one cell at a time, scaled up with sharp pixels.

The dog is built from round "puffs" so it looks fluffy, drawn back to front
with soft lines where parts overlap, a light top edge and a darker bottom
edge on each part. It faces left; the tile mirrors it to walk right.
"""
W, H = 32, 25
G = 2   # everything sits this much lower, so the topknot fits
COAT = {"b": ("h", "q"), "s": ("r", "S"), "m": ("m", "m")}   # base: (highlight, shadow)

def disc(cx, cy, r):
    return {(x, y) for y in range(H) for x in range(W) if (x + .5 - cx) ** 2 + (y + .5 - cy) ** 2 <= r * r}
def puffs(*ps):
    m = set()
    for p in ps: m |= disc(*p)
    return m
def col(x0, y0, x1, y1):
    return {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1) if 0 <= x < W and 0 <= y < H}
N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))

class Canvas:
    def __init__(self): self.g = {}
    def part(self, mask, base="b", line=True, shade=True, curls=True):
        if line:   # inner line where this part covers something behind it
            for (x, y) in mask:
                for dx, dy in N4:
                    q = (x + dx, y + dy)
                    if q not in mask and q in self.g and self.g[q] not in "eyv": self.g[q] = "K"
        hi, sh = COAT.get(base, (base, base))
        for (x, y) in mask:
            c = base
            if shade == "paw":
                if (x, y + 1) not in mask: c = sh
            elif shade:
                if (x, y - 1) not in mask: c = hi
                elif (x, y + 1) not in mask: c = sh
                elif curls and base == "b" and (x * 3 + (y // 2) * 5) % 7 == 0 and y % 2 == 0: c = hi   # little curls
            self.g[(x, y)] = c
    def put(self, pts, ch):
        for p in pts:
            if 0 <= p[0] < W and 0 <= p[1] < H: self.g[p] = ch
    def rows(self):
        out = [["." for _ in range(W)] for _ in range(H)]
        for (x, y), c in self.g.items():
            if 0 <= x < W and 0 <= y < H: out[y][x] = c
        for y in range(H):              # outer outline
            for x in range(W):
                if out[y][x] == "." and any(0 <= x + dx < W and 0 <= y + dy < H and (x + dx, y + dy) in self.g for dx, dy in N4):
                    out[y][x] = "k"
        return ["".join(r) for r in out]

def leg(x, top, bot, dx=0, lift=0):
    """Stubby fluffy leg from the body down to a round paw."""
    b = bot - lift
    m = set()
    for y in range(round(top), round(b)):
        t = (y - top) / max(1, b - top)
        m |= disc(x + 1.5 + dx * t, y + 0.5, 1.6)
    return m | disc(x + dx + 1.5, b - 0.6, 1.9)

def head(c, hx, hy, eye="open", mouth="", tilt=0):
    """Big round head with a puffy topknot, long round ear, muzzle, face."""
    c.part(puffs((hx, hy, 6.0), (hx - 3, hy - 4.4, 2.6), (hx + 0.2, hy - 5.4, 2.8), (hx + 3.2, hy - 4.4, 2.6),
                 (hx - 3.6, hy + 2.6, 2.6), (hx + 2.6, hy + 3.4, 2.6)))
    mx, my = hx - 4.8, hy + 2.0 + tilt
    c.part(puffs((mx, my, 2.3), (mx + 1.2, my + 0.7, 2.1)), "m", line=False, curls=False)
    c.put([(round(mx - 2.4), round(my - 1.6)), (round(mx - 1.4), round(my - 1.6)), (round(mx - 2.4), round(my - 0.6)), (round(mx - 1.4), round(my - 0.6))], "n")
    c.put([(round(mx - 1.4), round(my - 1.6))], "g")
    ex, ey = round(hx - 3), round(hy - 1)
    if eye == "open":
        c.put([(ex, ey), (ex + 1, ey), (ex, ey + 1), (ex + 1, ey + 1), (ex, ey + 2), (ex + 1, ey + 2)], "e")
        c.put([(ex, ey)], "w"); c.put([(ex + 1, ey + 2)], "o")
    elif eye == "blink":
        c.put([(ex, ey + 2), (ex + 1, ey + 2)], "e")
    elif eye == "happy":    # ^ shaped, squeezed shut with joy
        c.put([(ex - 1, ey + 2), (ex, ey + 1), (ex + 1, ey + 1), (ex + 2, ey + 2)], "e")
    c.put([(round(hx - 1), round(hy + 2)), (round(hx), round(hy + 2))], "p")      # blush
    my_ = round(my + 1.6)
    if mouth == "tongue":
        c.put([(round(mx - 0.5), my_), (round(mx + 0.5), my_), (round(mx), my_ + 1), (round(mx + 0.5), my_ + 1)], "t")
    elif mouth == "yawn":
        c.put([(round(mx - 1), my_ - 1), (round(mx), my_ - 1), (round(mx - 1), my_), (round(mx), my_), (round(mx + 1), my_)], "K")
        c.put([(round(mx), my_ + 1)], "t")

def ear(c, hx, hy, swing=0, up=0):
    ex, ey = hx + 3.4 + swing, hy + 1.5 - up
    c.part(puffs((ex, ey, 2.6), (ex + 0.4 + swing * 0.5, ey + 2.8, 2.5), (ex + 0.2 + swing, ey + 5, 1.9)), "s")

def collar(c, x, y):
    c.put([(x, y), (x + 1, y + 1), (x + 2, y + 1)], "v")
    c.put([(x + 1, y + 2)], "y")

def stand(legs=(0, 0, 0, 0), lifts=(0, 0, 0, 0), bob=0, tail=0, eye="open", mouth="", ear_swing=0, ear_up=0, head_dy=0, head_dx=0, tilt=0, bow=0):
    c = Canvas()
    nf, ff, nb, fb = legs
    lnf, lff, lnb, lfb = lifts
    by = 15 + bob + G
    # far legs (behind the body)
    f = bow   # play bow: the front half drops, the rear stays up
    c.part(leg(16, by + 2 + f, 21 + G, ff, lff), "q", shade=False)
    c.part(leg(24, by + 2, 21 + G, fb, lfb), "q", shade=False)
    # tail pom
    tx, ty = 28.4 + tail * 0.6, by - 4.8 - abs(tail) * 0.3
    c.part(puffs((27, by - 1.5, 1.2), (tx, ty, 2.5), (tx - 1, ty + 1.2, 1.8)))
    # body cloud
    c.part(puffs((17, by + f, 3.5), (20.5, by - 0.6 + f * 0.5, 3.6), (24, by, 3.4), (18.5, by + 2 + f, 3.0), (23, by + 2, 3.0)))
    # near legs
    c.part(leg(14 - f * 0.4, by + 2 + f * 0.6, 21 + G, nf - f, lnf), shade="paw")
    c.part(leg(22.5, by + 2, 21 + G, nb, lnb), shade="paw")
    hx, hy = 10 + head_dx - f * 0.7, 9 + bob + head_dy + G + f * 0.35
    head(c, hx, hy, eye, mouth, tilt)
    ear(c, hx, hy, ear_swing, ear_up)
    collar(c, round(hx + 4), round(hy + 5))
    return c.rows()

def sit(tail=0, eye="open", mouth="", scratch=-1, ear_swing=0, head_dy=0, hop=0):
    c = Canvas()
    gy = 21 + G - hop                                    # paw line
    c.part(puffs((25.5, gy - 2.2 - tail, 1.4), (26.6, gy - 3.4 - tail * 1.2, 2.2)))   # tail, flicks up and down
    c.part(puffs((21.5, gy - 3.2, 4.2), (18, gy - 5.5, 3.4), (17, gy - 2.5, 3.0)))   # round rump and chest
    if scratch >= 0:
        c.part(puffs((22, gy - 2.6, 2.8)))       # thigh; the kicking foot is drawn after the head
    else:
        c.part(puffs((22.5, gy - 2.6, 2.8)), line=False)                        # thigh
        c.part(puffs((20, gy - 0.6, 1.9)))                                      # hind paw
    c.part(leg(14.5, gy - 6, gy, 0, 0), shade="paw")                                         # front legs
    hx, hy = 11, 8 + G - hop + head_dy
    head(c, hx, hy, eye, mouth)
    ear(c, hx, hy, ear_swing)
    collar(c, round(hx + 4), round(hy + 5))
    if scratch >= 0:     # hind foot up at the ear, kicking
        c.part(leg(17.5 - scratch * 0.5, gy - 8 + scratch, gy - 4 + scratch, -2, 0), shade="paw")
    return c.rows()

WALK_L = [((2, -2, -2, 2), (0, 0, 0, 0)), ((0, 0, 0, 0), (0, 1, 1, 0)), ((-2, 2, 2, -2), (0, 0, 0, 0)), ((0, 0, 0, 0), (1, 0, 0, 1))]
RUN_L = [((-4, -3, 4, 3), (0, 0, 0, 0)), ((-2, -1, 2, 2), (0, 0, 1, 1)), ((2, 1, -2, -1), (1, 1, 0, 0)), ((0, -1, 0, 1), (0, 1, 0, 0))]
F = {
    "walk":  [stand(l, k, bob=-(i % 2), tail=[1, 0, -1, 0][i], ear_swing=[0, 0.5, 0, -0.5][i]) for i, (l, k) in enumerate(WALK_L)],
    "run":   [stand(l, k, bob=[-2, 0, -1, 0][i], tail=[-1, 1, -1, 1][i], mouth="tongue", ear_swing=1, ear_up=[2, 1, 2, 1][i]) for i, (l, k) in enumerate(RUN_L)],
    "sit":   [sit(), sit(), sit(eye="blink"), sit()],
    "wag":   [sit(tail=-1, eye="happy", mouth="tongue"), sit(tail=1, eye="happy", mouth="tongue", hop=1),
              sit(tail=-1, eye="happy", mouth="tongue"), sit(tail=1, eye="open", mouth="tongue")],
    "sniff": [stand(head_dy=5, head_dx=-1, tilt=0, tail=1), stand(head_dy=5, head_dx=-2, tail=-1, lifts=(1, 0, 0, 0)),
              stand(head_dy=5, head_dx=-1, tail=1), stand(head_dy=4, head_dx=-1, tail=-1)],
    "bow":   [stand(bow=3, tail=-1, eye="happy", mouth="tongue"), stand(bow=3, tail=1, eye="happy", mouth="tongue"),
              stand(bow=3, tail=-1, eye="open", mouth="tongue"), stand(bow=2, tail=1, eye="open", mouth="tongue", bob=-1)],
    "yawn":  [sit(eye="blink"), sit(eye="blink", mouth="yawn"), sit(eye="blink", mouth="yawn"), sit(eye="blink")],
}


def lie(eyes="closed", tongue=0, breathe=0):
    """Lying down, face-on, head resting on the front paws."""
    c = Canvas()
    gy = 21 + G
    c.part(puffs((26, gy - 4 - breathe, 2.2)))                                  # tail pom
    c.part(puffs((17, gy - 3 - breathe, 4.0), (22, gy - 2.8 - breathe, 3.8)))  # body
    hx, hy = 11, gy - 6
    for ex in (hx - 6.2, hx + 6.2):                                            # ears, relaxed
        c.part(puffs((ex, hy + 1, 2.6), (ex, hy + 3, 2.3)), "s")
    c.part(puffs((hx, hy, 5.6), (hx - 2.6, hy - 4, 2.4), (hx + 0.2, hy - 4.8, 2.6), (hx + 2.8, hy - 4, 2.4)))
    c.part(puffs((hx - 0.5, hy + 2.6, 2.4), (hx + 0.5, hy + 2.6, 2.4)), "m", line=False, curls=False)   # muzzle
    for px in (hx - 5, hx + 3):                                                # paws in front
        c.part(puffs((px + 1, gy - 0.6, 1.8), (px + 2.4, gy - 0.6, 1.8)), shade="paw")
    e1, e2, ey = round(hx - 3), round(hx + 2), round(hy - 1)
    if eyes == "open":
        c.put([(e1, ey), (e1 + 1, ey), (e1, ey + 1), (e1 + 1, ey + 1), (e2, ey), (e2 + 1, ey), (e2, ey + 1), (e2 + 1, ey + 1)], "e")
        c.put([(e1, ey), (e2, ey)], "w")
    else:
        c.put([(e1, ey + 1), (e1 + 1, ey + 1), (e2, ey + 1), (e2 + 1, ey + 1)], "e")
    c.put([(round(hx - 4), round(hy + 1)), (round(hx + 3), round(hy + 1))], "p")      # blush
    c.put([(round(hx - 1), round(hy + 1)), (round(hx), round(hy + 1)), (round(hx - 1), round(hy + 2)), (round(hx), round(hy + 2))], "n")
    c.put([(round(hx - 1), round(hy + 1))], "g")
    if tongue:
        c.put([(round(hx - 1), round(hy + 4)), (round(hx), round(hy + 4))] + ([(round(hx - 1), round(hy + 5)), (round(hx), round(hy + 5))] if tongue > 1 else []), "t")
    return c.rows()

def lie_classic(eyes_open=False, tongue=0, breathe=0):
    """The flat lying pose (head on paws, face-on): reads best when napping."""
    g = [["." for _ in range(W)] for _ in range(H)]
    dx, dy = 1, 4 - breathe     # place it on the shared ground line

    def ell(cx, cy, rx, ry, ch="b"):
        for y in range(H):
            for x in range(W):
                if ((x + .5 - cx - dx) / rx) ** 2 + ((y + .5 - cy - dy) / ry) ** 2 <= 1: g[y][x] = ch

    def pt(pts, ch):
        for x, y in pts:
            if 0 <= x + dx < W and 0 <= y + dy < H: g[y + dy][x + dx] = ch

    ell(21, 14.2, 1.8, 1.8)                       # tail
    ell(15, 16, 8, 3.6)                           # body
    for x0 in (5, 13):                            # front paws
        for y in (18, 19):
            pt([(x0 - 1, y), (x0 + 3, y)], "K")
            pt([(x0, y), (x0 + 1, y), (x0 + 2, y)], "b")
    ell(3.8, 11.4, 2.7, 3.0, "s")                 # ears
    ell(16.2, 11.4, 2.7, 3.0, "s")
    ell(10, 13, 6.6, 5.2, "K")
    ell(10, 13, 5.9, 4.5)                         # head
    for y in range(H):                            # curls
        for x in range(W):
            if g[y][x] == "b" and (x * 2 + y * 3) % 5 == 0 and not (6 <= x - dx <= 14 and 11 <= y - dy <= 18): g[y][x] = "h"
    ell(10, 15.4, 2.8, 1.8, "m")                  # muzzle
    if eyes_open:
        pt([(6, 12), (7, 12), (6, 13), (7, 13), (12, 12), (13, 12), (12, 13), (13, 13)], "e")
        pt([(7, 12), (13, 12)], "w")
    else:
        pt([(6, 13), (7, 13), (12, 13), (13, 13)], "e")
    pt([(9, 14), (10, 14), (9, 15), (10, 15)], "n")
    if tongue:
        pt([(9, 16), (10, 16)] + ([(9, 17), (10, 17)] if tongue > 1 else []), "t")
    for y in range(H):                            # outline
        for x in range(W):
            if g[y][x] == "." and any(0 <= x + a < W and 0 <= y + b < H and g[y + b][x + a] not in ".k" for a, b in N4):
                g[y][x] = "k"
    return ["".join(r) for r in g]

F["sleep"] = [lie_classic(), lie_classic(breathe=1)]
F["hot"] = [lie_classic(True, 2), lie_classic(True, 1)]


MOODS = ["walk", "run", "sit", "wag", "sniff", "bow", "yawn", "sleep", "hot"]
COLORS = {"k": "#4a2c17", "K": "#9a6236", "b": "#e8ad72", "h": "#f7cd96", "q": "#c98a52", "s": "#c98048",
          "r": "#dc9a5e", "S": "#a8652f", "m": "#f6d3a4", "e": "#1f1410", "w": "#ffffff", "o": "#ffffff",
          "n": "#1f1410", "g": "#7a6a60", "t": "#f2879f", "p": "#f4a0a8", "v": "#9b7fe0", "y": "#f5c518"}
CELL_W, CELL_H = W, H

if __name__ == "__main__":
    import os
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
