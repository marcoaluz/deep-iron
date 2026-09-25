"""Gera os sprites de protótipo do DEEP IRON em project.godot/assets/game/.

Uso:  python tools/gen_sprites.py   (precisa de Pillow: pip install pillow)

Parte dos sprites é recortada dos packs em assets/Sprites (Kenney Roguelike
Characters, Free_OreSheet, StewV Minerals) e parte é desenhada aqui pixel a
pixel (comedouro, armazém, chão, parede, tocha, escora, picareta). É arte de
protótipo — a arte final vem numa fase posterior.
"""
from pathlib import Path
import random

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "project.godot" / "assets"
RAW = ROOT / "Sprites"
OUT = ROOT / "game"
OUT.mkdir(parents=True, exist_ok=True)

KENNEY = RAW / "kenney_roguelike-characters" / "Spritesheet" / "roguelikeChar_transparent.png"
ORES = RAW / "Free_OreSheet" / "Free_OreSheet" / "Free_OreSheet_VerySmallSquares.png"
STEWV = RAW / "Mineral & Ore Asset Collection - StewV" / "Mineral & Ore Asset Collection - StewV" / "sprite_sheets" / "transparent_background" / "StewV_Minerals_Sheet_01.png"

CLEAR = (0, 0, 0, 0)


# ----------------------------------------------------------------- helpers
def new(w, h):
    return Image.new("RGBA", (w, h), CLEAR)


def rect(img, x0, y0, x1, y1, c):
    """Retângulo preenchido, coordenadas inclusivas."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                img.putpixel((x, y), c)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def from_rows(rows, pal):
    img = new(len(rows[0]), len(rows))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), pal[ch])
    return img


def outline(img, color):
    """Contorno de 1px em volta de tudo que é opaco (estilo dos packs de minério)."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < img.width and 0 <= ny < img.height and src.getpixel((nx, ny))[3] > 0:
                    img.putpixel((x, y), color)
                    break
    return img


def pad(img, n=1):
    out = new(img.width + n * 2, img.height + n * 2)
    out.alpha_composite(img, (n, n))
    return out


def trim(img):
    box = img.getbbox()
    return img.crop(box) if box else img


def tile(sheet, col, row, size=16, margin=0):
    step = size + margin
    return sheet.crop((col * step, row * step, col * step + size, row * step + size))


def save(img, name):
    img.save(OUT / name)
    print("ok", name, img.size)


# ------------------------------------------------------------ paleta base
OUTLINE_WOOD = (43, 30, 22, 255)
WOOD_DARK = (107, 84, 52, 255)
WOOD = (159, 124, 77, 255)
WOOD_ALT = (146, 112, 68, 255)
WOOD_LIGHT = (184, 146, 92, 255)
ROOF_DARK = (122, 58, 30, 255)
ROOF = (163, 84, 34, 255)
ROOF_LIGHT = (198, 101, 39, 255)
STONE_DARK = (84, 82, 88, 255)
STONE = (116, 113, 118, 255)
STONE_LIGHT = (146, 142, 146, 255)
WINDOW_LIT = (250, 208, 110, 255)
WINDOW_LIT2 = (255, 236, 170, 255)


# ------------------------------------------------------------ ipezinho
def build_ipezinho():
    kenney = Image.open(KENNEY).convert("RGBA")
    base = tile(kenney, 0, 8, 16, 1).copy()

    # capacete de mineiro com lanterna por cima do coque de cabelo
    helmet_rows = [
        "......yyyy......",
        ".....YYllYY.....",
        "....YYYllYYY....",
        "...DDDDDDDDDD...",
    ]
    pal = {
        "y": (252, 222, 96, 255),
        "Y": (232, 184, 48, 255),
        "D": (168, 120, 30, 255),
        "l": (255, 250, 214, 255),
    }
    for y in range(3):
        for x in range(16):
            base.putpixel((x, y), CLEAR)
    helmet = from_rows(helmet_rows, pal)
    base.alpha_composite(helmet, (0, 0))

    def frame(lift, left_up, right_up):
        out = new(16, 17)
        upper = base.crop((0, 0, 16, 14))
        out.alpha_composite(upper, (0, 1 - lift))
        for x0, x1, up in ((0, 8, left_up), (8, 16, right_up)):
            leg_top = base.crop((x0, 14, x1, 15))
            foot = base.crop((x0, 15, x1, 16))
            if lift and not up:  # perna apoiada enquanto o corpo sobe: estica
                out.alpha_composite(leg_top, (x0, 14))
                out.alpha_composite(leg_top, (x0, 15))
                out.alpha_composite(foot, (x0, 16))
            elif lift and up:  # perna levantada
                out.alpha_composite(leg_top, (x0, 14))
                out.alpha_composite(foot, (x0, 15))
            else:
                out.alpha_composite(leg_top, (x0, 15))
                out.alpha_composite(foot, (x0, 16))
        return out

    frames = [frame(0, False, False), frame(1, False, True), frame(0, False, False), frame(1, True, False)]
    sheet = new(16 * 4, 17)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * 16, 0))
    save(sheet, "ipezinho_walk.png")


def build_pickaxe():
    rows = [
        "..LLGGGDD..",
        ".LG.hBh.GD.",
        "LG...Bb...D",
        "L....Bb...D",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....bb....",
    ]
    pal = {
        "L": (214, 214, 222, 255),
        "G": (150, 150, 160, 255),
        "D": (88, 88, 98, 255),
        "h": (96, 96, 106, 255),
        "B": WOOD_LIGHT,
        "b": WOOD_DARK,
    }
    save(from_rows(rows, pal), "pickaxe.png")


# ------------------------------------------------------------ minérios
def build_ores():
    ores = Image.open(ORES).convert("RGBA")
    # linha 5 = rochas marrom-ferrugem (minério de ferro)
    for i, col in enumerate((0, 1, 2)):
        save(tile(ores, col, 5), f"ore_iron_{i}.png")
    save(trim(tile(ores, 4, 5)), "ore_chunk.png")
    # rochas comuns / pedregulhos para decoração
    for i, (col, row) in enumerate(((12, 0), (13, 0), (14, 0), (0, 4), (2, 4))):
        save(tile(ores, col, row), f"boulder_{i}.png")
    for i, (col, row) in enumerate(((5, 4), (17, 0), (4, 4), (5, 5))):
        save(trim(tile(ores, col, row)), f"pebble_{i}.png")

    # pilha de minério do armazém: 4 estágios (vazio -> cheio)
    small = trim(tile(ores, 5, 5))
    mid = trim(tile(ores, 4, 5))
    stages = [
        [],
        [(mid, 6, 6), (small, 11, 8)],
        [(mid, 2, 6), (mid, 9, 6), (small, 14, 8), (small, 6, 3)],
        [(mid, 1, 7), (mid, 7, 7), (mid, 13, 7), (mid, 4, 3), (mid, 10, 3), (small, 8, 0)],
    ]
    sheet = new(22 * 4, 14)
    for i, parts in enumerate(stages):
        f = new(22, 14)
        for img, x, y in parts:
            f.alpha_composite(img, (x, y))
        sheet.alpha_composite(f, (i * 22, 0))
    save(sheet, "ore_pile.png")


def build_crystals():
    sheet = Image.open(STEWV).convert("RGBA")
    for i, (col, row) in enumerate(((7, 0), (0, 1), (7, 1), (2, 2))):
        save(trim(tile(sheet, col, row, 32)), f"crystal_{i}.png")


# ------------------------------------------------------------ armazém
def build_armazem():
    W, H = 36, 32
    img = new(W, H)
    # telhado (trapézio) com faixas de telha
    for y in range(1, 12):
        inset = round((11 - y) * 8 / 10)
        x0, x1 = inset, W - 1 - inset
        for x in range(x0, x1 + 1):
            c = ROOF
            if (y - 1) % 3 == 0:
                c = ROOF_DARK
            elif (y - 1) % 3 == 1 and (x + (y // 3) * 2) % 4 == 0:
                c = ROOF_DARK
            elif (y - 1) % 3 == 2:
                c = ROOF_LIGHT
            img.putpixel((x, y), c)
    rect(img, 8, 0, W - 9, 0, ROOF_DARK)  # cumeeira
    # paredes em tábuas verticais
    for y in range(12, 30):
        for x in range(2, W - 2):
            c = WOOD if (x // 4) % 2 == 0 else WOOD_ALT
            if x % 4 == 1:
                c = WOOD_DARK
            img.putpixel((x, y), c)
    rect(img, 2, 12, W - 3, 12, WOOD_DARK)  # viga superior
    rect(img, 2, 12, 3, 29, (120, 90, 55, 255))  # colunas dos cantos
    rect(img, W - 4, 12, W - 3, 29, (120, 90, 55, 255))
    # porta dupla com travas em X
    dx0, dx1, dy0, dy1 = 12, 23, 17, 29
    rect(img, dx0, dy0, dx1, dy1, WOOD_DARK)
    rect(img, dx0 + 1, dy0 + 1, dx1 - 1, dy1, WOOD_LIGHT)
    rect(img, (dx0 + dx1) // 2, dy0 + 1, (dx0 + dx1) // 2 + 1, dy1, WOOD_DARK)
    for half in ((dx0 + 1, (dx0 + dx1) // 2 - 1), ((dx0 + dx1) // 2 + 2, dx1 - 1)):
        hx0, hx1 = half
        w = hx1 - hx0
        h = dy1 - (dy0 + 1)
        for i in range(h + 1):
            t = i / h
            px(img, hx0 + round(t * w), dy0 + 1 + i, WOOD)
            px(img, hx1 - round(t * w), dy0 + 1 + i, WOOD)
    # placa com ícone de minério
    rect(img, 14, 13, 21, 16, (206, 176, 118, 255))
    rect(img, 14, 16, 21, 16, WOOD_DARK)
    for x, y, c in ((16, 14, (150, 80, 50, 255)), (17, 14, (90, 88, 96, 255)), (18, 14, (150, 80, 50, 255)),
                    (17, 15, (150, 80, 50, 255)), (19, 15, (90, 88, 96, 255)), (16, 15, (90, 88, 96, 255))):
        px(img, x, y, c)
    # janelas acesas
    for wx in (5, W - 10):
        rect(img, wx, 16, wx + 4, 21, WOOD_DARK)
        rect(img, wx + 1, 17, wx + 3, 20, WINDOW_LIT)
        px(img, wx + 1, 17, WINDOW_LIT2)
        rect(img, wx + 2, 17, wx + 2, 20, WOOD_DARK)
        rect(img, wx + 1, 18, wx + 3, 18, WOOD_DARK)
    # fundação de pedra
    for x in range(1, W - 1):
        for y in (30, 31):
            c = STONE if (x + (y * 3)) % 6 else STONE_DARK
            if y == 30 and x % 6 == 0:
                c = STONE_LIGHT
            img.putpixel((x, y), c)
    save(outline(pad(img), OUTLINE_WOOD), "armazem.png")


# ------------------------------------------------------------ comedouro
def build_comedouro():
    W, H = 30, 18
    img = new(W, H)
    # pernas
    rect(img, 3, 13, 4, 17, WOOD_DARK)
    rect(img, W - 5, 13, W - 4, 17, WOOD_DARK)
    # cocho
    for y in range(7, 14):
        inset = 1 if y >= 11 else 0
        for x in range(1 + inset, W - 1 - inset):
            c = WOOD
            if y == 7:
                c = WOOD_LIGHT
            elif y == 10:
                c = WOOD_DARK
            elif y == 13:
                c = (120, 90, 55, 255)
            img.putpixel((x, y), c)
    rect(img, 1, 7, 1, 10, WOOD_DARK)
    rect(img, W - 2, 7, W - 2, 10, WOOD_DARK)
    # "papa" da comida no topo
    rect(img, 2, 6, W - 3, 6, (150, 108, 58, 255))
    # pães
    for bx in (3, 16):
        rect(img, bx, 3, bx + 5, 5, (214, 160, 90, 255))
        rect(img, bx + 1, 2, bx + 4, 2, (214, 160, 90, 255))
        rect(img, bx + 1, 3, bx + 3, 3, (240, 204, 136, 255))
        rect(img, bx, 5, bx + 5, 5, (170, 110, 55, 255))
        px(img, bx + 2, 4, (170, 110, 55, 255))
        px(img, bx + 4, 3, (170, 110, 55, 255))
    # maçãs
    for ax, ay in ((10, 4), (13, 3)):
        rect(img, ax, ay, ax + 2, ay + 2, (196, 48, 44, 255))
        px(img, ax, ay, (236, 110, 96, 255))
        px(img, ax + 1, ay - 1, (90, 60, 30, 255))
    # cogumelo da caverna
    rect(img, 23, 1, 27, 3, (180, 62, 58, 255))
    rect(img, 24, 0, 26, 0, (180, 62, 58, 255))
    px(img, 24, 1, (245, 240, 230, 255))
    px(img, 26, 2, (245, 240, 230, 255))
    rect(img, 24, 4, 26, 6, (232, 222, 200, 255))
    # folhas verdes
    for x, y in ((9, 6), (10, 5), (14, 6), (15, 5), (22, 5), (22, 6)):
        px(img, x, y, (104, 164, 72, 255))
    save(outline(pad(img), OUTLINE_WOOD), "comedouro.png")


# ------------------------------------------------------------ ambiente
def seamless_noise(size, blobs, seed, radius=(2, 6)):
    rnd = random.Random(seed)
    field = [[0.0] * size for _ in range(size)]
    for _ in range(blobs):
        cx, cy = rnd.uniform(0, size), rnd.uniform(0, size)
        r = rnd.uniform(*radius)
        s = rnd.choice((-1.0, 1.0))
        for y in range(size):
            for x in range(size):
                dx = min(abs(x - cx), size - abs(x - cx))
                dy = min(abs(y - cy), size - abs(y - cy))
                d = (dx * dx + dy * dy) ** 0.5
                if d < r:
                    field[y][x] += s * (1 - d / r)
    return field


def build_floor():
    size = 64
    rnd = random.Random(7)
    field = seamless_noise(size, 90, 11, (3, 9))
    shades = [(58, 51, 48, 255), (66, 58, 54, 255), (72, 64, 59, 255), (79, 70, 64, 255)]
    img = new(size, size)
    for y in range(size):
        for x in range(size):
            v = field[y][x] + rnd.uniform(-0.25, 0.25)
            idx = 0 if v < -0.8 else 1 if v < 0.0 else 2 if v < 0.8 else 3
            img.putpixel((x, y), shades[idx])
    # pedrinhas com sombra
    for _ in range(14):
        x, y = rnd.randrange(size), rnd.randrange(size)
        w = rnd.choice((1, 2, 2, 3))
        for i in range(w):
            img.putpixel(((x + i) % size, y), (104, 95, 88, 255))
            img.putpixel(((x + i) % size, (y + 1) % size), (46, 40, 38, 255))
        img.putpixel((x, (y - 1) % size), (122, 112, 102, 255))
    # rachaduras
    for _ in range(4):
        x, y = rnd.randrange(size), rnd.randrange(size)
        for _ in range(rnd.randint(3, 6)):
            img.putpixel((x % size, y % size), (44, 38, 36, 255))
            x += rnd.choice((1, 1, 0))
            y += rnd.choice((1, 0, -1))
    save(img, "floor_cave.png")


def build_wall():
    size = 32
    rnd = random.Random(3)
    img = new(size, size)
    rect(img, 0, 0, size - 1, size - 1, (26, 23, 25, 255))
    for _ in range(16):
        cx, cy = rnd.randrange(size), rnd.randrange(size)
        r = rnd.uniform(2.5, 5.5)
        for y in range(-6, 7):
            for x in range(-6, 7):
                d = ((x * x) + (y * y) * 1.3) ** 0.5
                if d < r:
                    c = (44, 40, 43, 255)
                    if y < -r * 0.4:
                        c = (58, 53, 56, 255)
                    elif y > r * 0.5:
                        c = (35, 31, 34, 255)
                    img.putpixel(((cx + x) % size, (cy + y) % size), c)
    save(img, "wall_rock.png")


def build_torch():
    rows = [
        "..o...",
        ".oyo..",
        ".oywo.",
        "oyywo.",
        ".oyyo.",
        "..oo..",
        ".gggg.",
        "..Bb..",
        "..Bb..",
        "..Bb..",
        "..Bb..",
        "..Bb..",
        "..Bb..",
        "..Bb..",
        "..bb..",
    ]
    pal = {
        "o": (232, 118, 40, 255),
        "y": (255, 204, 84, 255),
        "w": (255, 246, 206, 255),
        "g": (96, 96, 106, 255),
        "B": WOOD,
        "b": WOOD_DARK,
    }
    save(from_rows(rows, pal), "torch.png")


def build_support():
    W, H = 26, 28
    img = new(W, H)
    for x0 in (2, W - 6):
        for y in range(4, H):
            for x in range(x0, x0 + 4):
                c = WOOD if x - x0 in (1, 2) else WOOD_DARK
                if x - x0 == 1:
                    c = WOOD_LIGHT
                img.putpixel((x, y), c)
    for y in range(1, 5):
        for x in range(0, W):
            c = WOOD
            if y == 1:
                c = WOOD_LIGHT
            elif y == 4:
                c = WOOD_DARK
            img.putpixel((x, y), c)
    for i in range(4):  # mãos-francesas
        px(img, 6 + i, 5 + i, WOOD_DARK)
        px(img, W - 7 - i, 5 + i, WOOD_DARK)
    for x in (4, W - 5):  # pregos
        px(img, x, 2, (70, 70, 78, 255))
    save(outline(pad(img), OUTLINE_WOOD), "support_beam.png")


if __name__ == "__main__":
    build_ipezinho()
    build_pickaxe()
    build_ores()
    build_crystals()
    build_armazem()
    build_comedouro()
    build_floor()
    build_wall()
    build_torch()
    build_support()
