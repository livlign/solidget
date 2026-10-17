#!/usr/bin/env python3
"""Draws everything around the desk pet and packs it into one sprite sheet.

Run: python3 tools/props.py   (needs Pillow)
Writes package/contents/images/props.png and package/contents/code/props.js
(where each picture sits in the sheet, in pixels). Prop.qml shows one at a
time, scaled up with sharp pixels, like the poodle.

Small things are drawn by hand as text (one letter per pixel, "." is empty);
bigger ones (trees, the bed, the bathtub...) are drawn with shapes. Shapes get
a dark outline added automatically.
"""
import os

COLORS = {
    "k": "#2b2118", "x": "#141414", "w": "#ffffff", "a": "#d5dbe1", "s": "#9aa5b1", "S": "#5f6b78",
    "r": "#e5484d", "R": "#9b1c22", "o": "#f59e0b", "O": "#c2410c", "y": "#f5c84c", "Y": "#c8962c",
    "g": "#4caf50", "G": "#2e7d32", "l": "#8bd36a", "b": "#8d5a3b", "B": "#5d3a24", "t": "#c99a6b",
    "u": "#4aa3e8", "U": "#2b6cb0", "c": "#9bd9fb", "p": "#f9a8d4", "P": "#db2777", "m": "#a78bfa",
    "M": "#6d28d9", "e": "#ecd7a0", "E": "#c9ac6a", "f": "#f3f8ff", "F": "#c7d8ea", "h": "#f3e1c7",
    "H": "#d9b98f", "n": "#334155", "A": "#d99a7e", "D": "#b8705a", "C": "#9fb79a", "N": "#3b4254", "V": "#2a2f3d", "L": "#5c667d",
    "T": "#2f6f73", "I": "#4fa3a0", "j": "#28365a", "i": "#3b4d7a", "J": "#d9ea52", "Q": "#a9bd2e", "W": "#f2e6cf", "X": "#cdb994", "K": "#f28cb1", "v": "#7c5cbf", "z": "#e8e2d6", "Z": "#b9b0a0", "q": "#3a7d44",
}

SPRITES = {}


def grid(name, rows):
    assert all(len(r) == len(rows[0]) for r in rows), name + ": uneven rows"
    SPRITES[name] = rows


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [["." for _ in range(w)] for _ in range(h)]

    def put(self, x, y, ch):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = ch

    def rect(self, x, y, w, h, ch):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.put(xx, yy, ch)

    def ell(self, cx, cy, rx, ry, ch):
        for y in range(self.h):
            for x in range(self.w):
                if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1:
                    self.g[y][x] = ch

    def tri(self, cx, top, half, bottom, ch):
        """A triangle pointing up: apex at (cx, top), base `half` wide each side."""
        for y in range(top, bottom + 1):
            k = (y - top + 1) / (bottom - top + 1)
            self.rect(int(round(cx - half * k)), y, int(round(half * k * 2)) or 1, 1, ch)

    def dots(self, ch, every, on, seed=0):
        """Sprinkle `ch` over pixels of colour `on` in a fixed pattern."""
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] == on and (x * 3 + y * 5 + seed) % every == 0:
                    self.g[y][x] = ch

    def rows(self, outline=True):
        g = self.g
        if outline:
            out = [r[:] for r in g]
            for y in range(self.h):
                for x in range(self.w):
                    if g[y][x] == "." and any(0 <= x + a < self.w and 0 <= y + b < self.h and g[y + b][x + a] not in ".k"
                                              for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                        out[y][x] = "k"
            g = out
        return ["".join(r) for r in g]


def shape(name, w, h, draw, outline=True):
    c = Canvas(w, h)
    draw(c)
    if outline:
        # A pixel of room left, right and on top, so the outline is never cut
        # off by the edge of the canvas (the bottom stays flush: things stand
        # on the floor).
        big = Canvas(w + 2, h + 1)
        for y in range(h):
            for x in range(w):
                big.g[y + 1][x + 1] = c.g[y][x]
        c = big
    SPRITES[name] = c.rows(outline)


# ---- Home -------------------------------------------------------------------

def bed(c):
    # A round dog bed the dog fits in: a soft rim around a cream cushion.
    c.ell(17, 8, 16, 4.6, "A")
    c.ell(17, 7.4, 12.5, 2.9, "h")
    c.rect(3, 9, 29, 3, "D")
    c.dots("D", 7, "A")
shape("bed", 35, 13, bed)

def cushion(c):
    # The pet's floor cushion in the den: plump, with a tufted button.
    c.ell(16, 6.2, 15.5, 3.8, "M")
    c.ell(16, 5.2, 14.5, 3.4, "v")
    c.ell(15, 4.4, 10, 1.8, "m")
    c.put(16, 5, "M")
    c.put(9, 6, "M")
    c.put(23, 6, "M")
shape("cushion", 32, 10, cushion)

grid("bowl", ["..........",
              "kkkkkkkkkk",
              ".krrrrrrk.",
              "..kRRRRk.."])
grid("bowl_full", ["..tbBtbt..",
                   "kkkkkkkkkk",
                   ".krrrrrrk.",
                   "..kRRRRk.."])
grid("water", ["..........",
               "kcccccccck",
               ".kuuuuuuk.",
               "..kUUUUk.."])
grid("ball", [".kkk.",
              "krrwk",
              "krrrk",
              "kRrrk",
              ".kkk."])
grid("bone", [".kk...kk.",
              "kwwkkkwwk",
              "kwwwwwwwk",
              ".kk...kk."])
grid("duck", ["..kkk..",
              ".kyyxk.",
              ".kyyykO",
              "kkyyykk",
              "kyyyyyk",
              ".kkkkk."])
# Treats, for the Feed button.
grid("biscuit", [".kk...kk.",
                 "kttkkkttk",
                 "ktttEtttk",
                 ".kk...kk."])
grid("jerky", ["kkkk....",
               "kBbbkkk.",
               ".kkbBbbk",
               "....kkkk"])
grid("cheese", ["....kk",
                "..kkyk",
                "kkyyyk",
                "kyYyYk",
                "kkkkkk"])
grid("fish", ["..kkkk...k",
              ".kcxcckkuk",
              "kcccccccuk",
              ".kuuuuukuk",
              "..kkkk...k"])
grid("poop", ["..k..",
              ".kbk.",
              "kbBbk",
              "kkkkk"])


def plant(c):
    # A leafy plant in a terracotta pot.
    c.ell(7, 6, 5.5, 5.8, "g")
    c.ell(3.5, 10, 3.5, 3, "G")
    c.ell(10.5, 10, 3.5, 3, "q")
    c.ell(7, 2.5, 2.5, 2.5, "q")
    c.dots("l", 5, "g")
    c.rect(3, 14, 8, 8, "D")
    c.rect(2, 14, 10, 2, "A")
shape("plant", 14, 22, plant)


def lamp(c):
    # A tall floor lamp: a cream drum shade, a thin pole, a round foot.
    for y in range(1, 10):
        half = 4 + (y - 1) * 0.4
        c.rect(int(round(8 - half)), y, int(round(half * 2)), 1, "h")
    c.rect(3, 9, 10, 1, "H")
    c.rect(7, 10, 2, 28, "S")
    c.rect(7, 10, 1, 28, "s")
    c.ell(8, 38.5, 5, 1.6, "S")
shape("lamp", 16, 40, lamp)


def bookshelf(c):
    # A tall bookcase full of books, a little plant on top.
    c.rect(0, 2, 24, 34, "B")
    c.rect(1, 3, 22, 32, "b")
    colors = "ruygmPUOC"
    for shelf, top in enumerate((4, 12, 20, 28)):
        c.rect(1, top + 6, 22, 1, "B")
        x, i = 2, shelf * 5
        while x < 21:
            w = 1 + (i % 2)
            h = 4 + (i * 7) % 3
            if shelf == 3 and 9 < x < 15:          # a gap with a little box
                c.rect(10, top + 3, 5, 3, "t"); x = 16; continue
            c.rect(x, top + 6 - h, w, h, colors[i % len(colors)])
            x += w + (1 if i % 4 == 3 else 0)
            i += 1
    c.ell(18, 1.5, 3, 1.8, "g")
    c.rect(16, 1, 4, 1, "D")
shape("bookshelf", 24, 36, bookshelf, outline=False)


def clock(c):
    c.ell(5, 5, 5, 5, "b")
    c.ell(5, 5, 3.8, 3.8, "h")
    c.rect(5, 2, 1, 4, "x")
    c.rect(5, 5, 2, 1, "x")
shape("clock", 11, 11, clock)


def frame(c):
    c.rect(0, 0, 18, 13, "Y")
    c.rect(1, 1, 16, 11, "c")
    c.tri(6, 4, 5, 11, "G")
    c.tri(12, 3, 5, 11, "q")
    c.ell(13.5, 3, 1.3, 1.3, "y")
shape("picture", 18, 13, frame, outline=False)


def basket(c):
    c.rect(0, 4, 18, 8, "t")
    c.rect(0, 4, 18, 1, "H")
    for x in range(1, 18, 3):
        c.rect(x, 5, 1, 7, "H")
    c.ell(5, 3, 2, 2, "r")                 # a ball and a bone poking out
    c.rect(10, 2, 5, 1, "w"); c.put(10, 1, "w"); c.put(14, 1, "w")
shape("basket", 18, 13, basket)


def tub(c):
    c.rect(1, 3, 32, 9, "f")
    c.rect(0, 3, 34, 2, "a")
    c.rect(3, 12, 3, 2, "S")
    c.rect(28, 12, 3, 2, "S")
    c.rect(2, 7, 30, 1, "F")
shape("tub", 34, 14, tub)

# ---- The nerd room -----------------------------------------------------------


def poster(c, kind):
    # A framed game cover: a little alien over a laser cannon.
    c.rect(0, 0, 14, 18, "x")          # frame
    c.rect(1, 1, 12, 16, "n")
    c.rect(1, 1, 12, 3, "r")
    for x, y in ((4, 6), (9, 6), (5, 7), (8, 7), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8),
                 (3, 9), (4, 9), (6, 9), (7, 9), (9, 9), (10, 9), (3, 10), (10, 10), (5, 11), (8, 11)):
        c.put(x, y, "l")
    c.rect(6, 14, 2, 1, "g"); c.rect(5, 15, 4, 1, "g")


shape("poster_invader", 14, 18, lambda c: poster(c, "invader"), outline=False)


def shelf_wall(c):
    # Two wall shelves: books, a plant, a box, a little figure.
    for top in (0, 11):
        c.rect(0, top + 8, 20, 2, "b"); c.rect(0, top + 9, 20, 1, "B")
    x, i = 1, 0
    for col in "ruygPU":                       # top shelf: books
        h = 5 + i % 3
        c.rect(x, 8 - h, 2, h, col); x += 2 + (i % 2); i += 1
    c.ell(16.5, 6, 2.5, 2.2, "g"); c.rect(15, 6, 3, 2, "D")        # plant
    c.rect(1, 15, 6, 4, "t"); c.rect(1, 15, 6, 1, "H")            # box
    for x, col in ((9, "m"), (11, "c"), (13, "l"), (15, "o")):     # bottom shelf: books leaning
        c.rect(x, 13, 2, 6, col)
    c.rect(18, 15, 1, 4, "w"); c.ell(18.5, 14, 1, 1, "w")          # figure
shape("shelf_wall", 20, 21, shelf_wall)


def bed_front(c, w=28):
    # A low bed against the wall, seen from the foot end: a padded, button-
    # tufted headboard, soft grey pillows, a deep blue duvet with gentle
    # folds, a teal throw across the foot, and a dark frame. `w` wide: the
    # double has two pillows, a narrow single one.
    m = w / 2
    c.ell(m, 5, m, 5.5, "V")                                      # headboard, rounded top
    c.rect(0, 5, w, 6, "V")
    c.ell(m, 5.2, m - 1.4, 4.4, "N")
    c.rect(1, 5, w - 2, 6, "N")
    for x in ((5, 10, 14, 18, 23) if w > 20 else (4, 8, 12)):     # tufting
        c.put(x, 4, "V"); c.put(x, 8, "V")
    for px in ((8, w - 8) if w > 20 else (m,)):                   # pillows
        c.ell(px, 11, 5.2, 2.3, "s"); c.ell(px, 10.6, 4.6, 1.8, "a")
    c.rect(1, 13, w - 2, 7, "j")                                  # duvet
    c.rect(1, 13, w - 2, 1, "i")                                  # its lit top edge
    for x in range(7 if w > 20 else 5, w - 4, 7):                 # soft folds
        c.rect(x, 14, 1, 2, "i")
    c.rect(1, 16, w - 2, 3, "T")                                  # throw across the foot
    c.rect(1, 16, w - 2, 1, "I")
    c.rect(1, 19, w - 2, 2, "j")                                  # duvet hanging over the end
    c.rect(0, 21, w, 2, "x")                                      # frame
    c.rect(1, 23, 2, 1, "x"); c.rect(w - 3, 23, 2, 1, "x")        # feet
shape("bed_front", 28, 24, bed_front)
shape("bed_single", 17, 24, lambda c: bed_front(c, 17))


def desk_front(c):
    # A desk against the wall, seen from the room: top, a drawer unit on the
    # left, a leg on the right, a keyboard and mouse.
    c.rect(0, 4, 28, 3, "n"); c.rect(0, 4, 28, 1, "L")
    c.rect(1, 7, 9, 13, "V")
    for y in (9, 13, 17):
        c.rect(2, y, 7, 3, "n"); c.rect(4, y + 1, 2, 1, "L")
    c.rect(25, 7, 2, 13, "V")
    c.rect(9, 2, 11, 2, "S")                                      # keyboard
    for x in range(10, 20, 2):
        c.put(x, 2, "a")
    c.ell(23, 3, 1.5, 1, "a")                                     # mouse
shape("desk_front", 28, 20, desk_front, outline=False)


def chair_back(c):
    # A gaming chair seen from behind: headrest, tall back with red stripes,
    # armrests, the column and a five-star base on wheels.
    c.rect(4, 0, 8, 3, "x"); c.rect(5, 0, 6, 2, "n")               # headrest
    c.rect(2, 3, 12, 14, "x"); c.rect(3, 4, 10, 12, "n")           # backrest
    c.rect(3, 4, 10, 1, "L")                                      # a soft highlight
    c.rect(0, 13, 2, 5, "x"); c.rect(14, 13, 2, 5, "x")           # armrests
    c.rect(1, 17, 14, 2, "x")                                     # seat edge
    c.rect(7, 19, 2, 4, "S")                                      # column
    c.rect(1, 23, 14, 1, "S")                                     # base
    for x in (1, 7, 14):
        c.rect(x, 24, 2, 1, "x")                                  # wheels
shape("chair_back", 16, 25, chair_back)


def armchair(c):
    # A soft armchair: sage fabric, a cushion, round arms, little wood feet.
    c.ell(11, 5, 9, 5.5, "C")                                     # back
    c.rect(0, 7, 5, 9, "C"); c.rect(17, 7, 5, 9, "C")             # arms
    c.ell(2.5, 7, 2.5, 1.8, "C"); c.ell(19.5, 7, 2.5, 1.8, "C")
    c.rect(4, 9, 14, 7, "q")                                      # seat cushion
    c.rect(4, 9, 14, 1, "C")
    c.rect(2, 16, 2, 2, "B"); c.rect(18, 16, 2, 2, "B")
    c.dots("q", 9, "C")
shape("armchair", 22, 18, armchair)


# ---- Outside ----------------------------------------------------------------


def tree(c):
    c.rect(9, 18, 4, 11, "b")
    c.rect(10, 18, 1, 11, "B")
    c.ell(11, 9, 9.5, 8.5, "G")
    c.ell(8, 8, 6, 5.5, "g")
    c.ell(14, 12, 5, 4, "g")
    c.dots("l", 6, "g")
shape("tree", 22, 30, tree)


def pine(c, snow=False):
    c.rect(7, 24, 3, 5, "b")
    for top, half, bottom in ((0, 4, 8), (5, 6, 15), (11, 8, 24)):
        c.tri(8.5, top, half, bottom, "q")
        if snow:
            c.tri(8.5, top, half * 0.55, top + (bottom - top) // 2, "f")
    c.dots("G", 5, "q")
shape("pine", 18, 29, pine)
shape("pine_snow", 18, 29, lambda c: pine(c, True))


def palm(c):
    for i in range(18):                      # curved trunk
        x = int(12 + (i / 18) ** 2 * 4)
        c.rect(x, 11 + i, 3, 1, "H" if i % 3 == 0 else "t")
    # Fronds: arcs out from the top that droop at the ends.
    for dx, lift in ((-10, 1), (10, 1), (-9, -6), (9, -6), (-4, -11), (4, -11)):
        for t in range(12):
            k = t / 11
            x = 13 + dx * k
            y = 11 + lift * k + 8 * k * k
            c.rect(int(round(x)), int(round(y)), 2, 2 if t < 9 else 1, "g" if t % 4 else "G")
    c.ell(13.5, 11, 2.2, 1.8, "B")
shape("palm", 27, 30, palm)


def bush(c):
    c.ell(6, 5, 6, 4, "G")
    c.ell(4, 4, 3.5, 3, "g")
    c.ell(9, 4.5, 3, 2.6, "g")
    c.dots("r", 9, "g", 2)
shape("bush", 13, 9, bush)

grid("flower", [".p.p.", "ppypp", ".p.p.", "..g..", ".gg..", "..g.."])
grid("flower2", [".y.y.", "yyoyy", ".y.y.", "..g..", "..gg.", "..g.."])
grid("tuft", ["l...l.l", ".l.l.l.", ".glglg.", "ggggggg"])
grid("shell", [".kkk.", "kphpk", "kphpk", ".kkk."])


def bench(c):
    c.rect(0, 3, 20, 2, "b")         # seat
    c.rect(0, 0, 20, 2, "t")         # back
    c.rect(2, 2, 1, 1, "B"); c.rect(17, 2, 1, 1, "B")
    c.rect(2, 5, 2, 4, "S"); c.rect(16, 5, 2, 4, "S")
shape("bench", 20, 9, bench)


def mushroom(c):
    c.ell(4, 2.5, 4, 2.6, "r")
    c.put(2, 1, "w"); c.put(5, 2, "w"); c.put(3, 3, "w")
    c.rect(3, 4, 3, 3, "h")
shape("mushroom", 8, 7, mushroom)


def reeds(c):
    for x, h in ((1, 9), (3, 11), (5, 8), (7, 10)):
        c.rect(x, 12 - h, 1, h, "q")
        c.rect(x, 12 - h, 1, 2, "B")
shape("reeds", 9, 12, reeds)


def cactus(c):
    c.rect(4, 0, 3, 14, "q")
    c.rect(1, 4, 2, 5, "q"); c.rect(1, 8, 3, 2, "q")
    c.rect(8, 2, 2, 5, "q"); c.rect(7, 6, 3, 2, "q")
    c.dots("g", 4, "q")
shape("cactus", 11, 14, cactus)


def rock(c):
    c.ell(5, 4, 5, 3.4, "s")
    c.ell(4, 3, 2.5, 1.4, "a")
shape("rock", 11, 7, rock)


def hydrant(c):
    c.rect(2, 0, 4, 2, "R")
    c.rect(1, 2, 6, 9, "r")
    c.rect(0, 4, 8, 2, "R")
    c.rect(1, 11, 6, 1, "R")
    c.put(3, 3, "w")
shape("hydrant", 10, 13, hydrant)


def fence(c):
    for x in (0, 6, 12):
        c.rect(x, 0, 4, 10, "h")
        c.put(x + 1, 0, ".")
        c.put(x + 2, 0, ".")
    c.rect(0, 3, 16, 2, "H")
    c.rect(0, 7, 16, 2, "H")
shape("fence", 17, 11, fence)


def snowman(c):
    c.ell(7, 14, 6, 5, "f")
    c.ell(7, 6.5, 4.2, 3.8, "f")
    c.rect(4, 0, 6, 3, "x")
    c.rect(3, 3, 8, 1, "x")
    c.put(5, 6, "x"); c.put(8, 6, "x")
    c.put(7, 7, "o"); c.put(8, 7, "o")
    c.rect(3, 9, 8, 1, "r")
    c.put(7, 13, "x"); c.put(7, 15, "x")
    c.dots("F", 7, "f")
shape("snowman", 15, 20, snowman)


def castle(c):
    c.rect(1, 5, 14, 7, "e")
    c.rect(0, 2, 5, 10, "e")
    c.rect(11, 2, 5, 10, "e")
    for x in (0, 2, 4, 11, 13, 15):
        c.put(x, 1, "e")
    c.rect(6, 8, 4, 4, "E")
    c.dots("E", 6, "e")
    c.rect(13, 0, 1, 2, "B")
    c.put(14, 0, "r")
shape("sandcastle", 17, 13, castle)


def umbrella(c):
    for y in range(7):
        half = 2 + y * 1.6
        for x in range(int(9 - half), int(9 + half) + 1):
            c.put(x, y, "r" if (x // 3) % 2 else "w")
    c.rect(8, 7, 2, 14, "S")
shape("umbrella", 19, 21, umbrella)

# ---- Animal friends (two frames each, facing left) --------------------------

grid("bird1", ["......",
               "..kk..",
               ".kuxk.",
               "okuuuk",
               ".kuUuk",
               "..k.k."])
grid("bird2", [".k..k.",
               "kUkkUk",
               ".kxuuk",
               "okuuuk",
               ".kkkk.",
               "......"])
grid("butterfly1", ["kk.kk", "kmkmk", ".kxk.", "kpkpk", "kk.kk"])
grid("butterfly2", [".....", ".kmk.", ".kxk.", ".kpk.", "....."])
grid("squirrel1", ["......kkk.",
                   "..kk.koOk.",
                   ".koxkkoOOk",
                   "koooookoOk",
                   ".kooooookk",
                   "..kOkkOk..",
                   "..kk..kk.."])
grid("squirrel2", ["..kk..kkk.",
                   ".koxk.koOk",
                   "koooookoOk",
                   ".kooooookk",
                   "..kooooo..",
                   ".kOk..kOk.",
                   ".kk....kk."])
grid("rabbit1", [".k.k....",
                 ".kwkw...",
                 ".kwkwk..",
                 "kwxwwwkk",
                 ".kwwwwwk",
                 "..kwwwwk",
                 "..kk.kk."])
grid("rabbit2", ["........",
                 ".k.k....",
                 "kwkwk...",
                 "kwxwwkkk",
                 ".kwwwwwk",
                 ".kwwwwk.",
                 "kk...kk."])
grid("crab1", ["k.k..k.k", "kokkkkok", ".kxooxk.", "kkookook", "k.k..k.k"])
grid("crab2", [".k.kk.k.", "kokkkkok", ".kxooxk.", ".koooook", "k.k..k.k"])
grid("pal1", ["..kk.........",
              ".kSSk......k.",
              "kSxSSkkkkkksk",
              "kSSSSSSSSSSk.",
              ".kkSSSSSSSSk.",
              "..kSkkSkkSk..",
              "..kk..kk.kk.."])
grid("pal2", ["..kk.......k.",
              ".kSSk.....ks.",
              "kSxSSkkkkkkk.",
              "kSSSSSSSSSSk.",
              ".kkSSSSSSSSk.",
              ".kSk.kSkSk...",
              ".kk..kk.kk..."])

# ---- Button icons (9 x 9) and little pictures -------------------------------

grid("i_pet", ["...k.k...",
               "..kwkwk..",
               ".kkwkwkk.",
               "kwkwwwkwk",
               "kwwwwwwwk",
               ".kwwwwwk.",
               "..kwwwk..",
               "...kkk...",
               "........."])
grid("i_feed", ["........",
                "..tbBt..",
                ".tBtbtb.",
                "kkkkkkkk",
                "krrrrrrk",
                ".krrrrk.",
                "..kkkk..",
                "........"])
grid("i_bath", ["...k....",
                "..kck...",
                "..kck...",
                ".kccck..",
                "kcccwck.",
                "kccwcck.",
                ".kccck..",
                "..kkk..."])
grid("i_clean", [".......kk",
                 "......kbk",
                 ".....kbk.",
                 "....kbk..",
                 "..kkbk...",
                 ".kyyyk...",
                 "kyYyk....",
                 "kYyk.....",
                 "kkk......"])
grid("i_walk", ["..kk.....",
                ".krrk....",
                ".kr.rk...",
                "..k..rk..",
                "......rk.",
                ".......rk",
                "......kSk",
                ".......k.",
                "........."])
grid("i_play", ["..kkk..",
                ".krrwk.",
                "krrrrrk",
                "krrrrrk",
                "kRrrrrk",
                ".kRrrk.",
                "..kkk.."])
grid("i_home", ["....k....",
                "...krk...",
                "..krrrk..",
                ".krrrrrk.",
                "kkhhhhhkk",
                ".khkkhhk.",
                ".khkkhhk.",
                ".kkkkkkk."])
grid("heart", [".kk.kk.",
               "krrkrrk",
               "krrrrrk",
               ".krrrk.",
               "..krk..",
               "...k..."])
grid("sparkle", ["..y..", "..y..", "yyfyy", "..y..", "..y.."])
grid("drop", [".c.", "ccc", ".c."])


def pack():
    """Shelf-pack every sprite (tallest first) into one sheet, 1px apart."""
    names = sorted(SPRITES, key=lambda n: (-len(SPRITES[n]), n))
    width, x, y, shelf, where = 160, 0, 0, 0, {}
    for n in names:
        w, h = len(SPRITES[n][0]), len(SPRITES[n])
        if x + w > width:
            x, y, shelf = 0, y + shelf + 1, 0
        where[n] = (x, y, w, h)
        x += w + 1
        shelf = max(shelf, h)
    return where, width, y + shelf


if __name__ == "__main__":
    from PIL import Image
    where, W, H = pack()
    sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for name, (x0, y0, w, h) in where.items():
        for y, line in enumerate(SPRITES[name]):
            for x, ch in enumerate(line):
                if ch != ".":
                    rgb = tuple(int(COLORS[ch][i:i + 2], 16) for i in (1, 3, 5))
                    sheet.putpixel((x0 + x, y0 + y), rgb + (255,))
    here = os.path.dirname(os.path.abspath(__file__))
    png = os.path.join(here, "..", "package", "contents", "images", "props.png")
    sheet.save(png, optimize=True)
    js = os.path.join(here, "..", "package", "contents", "code", "props.js")
    with open(js, "w") as f:
        f.write(".pragma library\n\n// Made by tools/props.py: where each picture sits in images/props.png,\n"
                "// as [x, y, width, height] in pixels. Don't edit by hand.\n\nvar SHEET = [%d, %d];\n\nvar AT = {\n" % (W, H))
        f.write(",\n".join('    "%s": [%d, %d, %d, %d]' % ((n,) + where[n]) for n in sorted(where)))
        f.write("\n};\n")
    print("wrote", os.path.normpath(png), sheet.size, len(where), "pictures")
