"""Gera os sprites do DEEP IRON em project.godot/assets/game/.

Uso:  python tools/gen_sprites.py   (precisa de Pillow: pip install pillow)

Direção de arte: pixel art "estilo Stardew", só que numa mina abandonada.
  - Todas as cores saem da PALETA central abaixo (nada de cor solta nas funções).
  - Ambiente frio e dessaturado (cinza-azulado, marrom terroso, musgo escuro).
  - Fontes de luz (tocha, cristais, lanterna do capacete, janelas) quentes e
    saturadas, pra contrastar com o escuro.
  - Gradientes e sombras com dithering (Bayer 4x4 ou faixa xadrez).
  - Contorno colorido: um tom escurecido (e puxado pro frio) da cor vizinha,
    nunca preto puro.

Quase tudo é desenhado aqui, pixel a pixel. Só os cristais ainda vêm do pack
StewV (em assets/Sprites), com o contorno preto trocado por contorno colorido.
"""
from pathlib import Path
import colorsys
import math
import random

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "project.godot" / "assets"
RAW = ROOT / "Sprites"
OUT = ROOT / "game"
OUT.mkdir(parents=True, exist_ok=True)

STEWV = RAW / "Mineral & Ore Asset Collection - StewV" / "Mineral & Ore Asset Collection - StewV" / "sprite_sheets" / "transparent_background" / "StewV_Minerals_Sheet_01.png"

CLEAR = (0, 0, 0, 0)


# =================================================================== PALETA
# Cada material é uma rampa do mais escuro pro mais claro. As constantes com
# nome são o que as funções de desenho usam; as tuplas *_RAMP servem pro
# dithering. Sprite novo? Use estas cores (ou shade() delas), não invente outras.

# --- ambiente (frio, dessaturado) -------------------------------------------
STONE_BLACK = (24, 26, 33, 255)
STONE_SHADOW = (36, 38, 48, 255)
STONE_DARK = (51, 53, 64, 255)
STONE = (68, 70, 81, 255)
STONE_LIGHT = (92, 94, 104, 255)
STONE_HIGHLIGHT = (126, 128, 136, 255)
STONE_RAMP = (STONE_BLACK, STONE_SHADOW, STONE_DARK, STONE, STONE_LIGHT, STONE_HIGHLIGHT)

WALL_VOID = (13, 14, 19, 255)
WALL_SHADOW = (20, 21, 28, 255)
WALL_DARK = (28, 30, 39, 255)
WALL = (38, 40, 50, 255)
WALL_LIGHT = (50, 52, 63, 255)
WALL_WET = (72, 80, 98, 255)  # brilho de umidade na rocha
WALL_RAMP = (WALL_VOID, WALL_SHADOW, WALL_DARK, WALL, WALL_LIGHT)

EARTH_SHADOW = (33, 31, 34, 255)
EARTH_DARK = (41, 38, 41, 255)
EARTH = (49, 46, 48, 255)
EARTH_LIGHT = (58, 54, 55, 255)
EARTH_HIGHLIGHT = (69, 64, 63, 255)
EARTH_RAMP = (EARTH_SHADOW, EARTH_DARK, EARTH, EARTH_LIGHT, EARTH_HIGHLIGHT)

MOSS_SHADOW = (27, 36, 32, 255)
MOSS_DARK = (36, 48, 39, 255)
MOSS = (49, 63, 47, 255)
MOSS_LIGHT = (66, 80, 56, 255)
MOSS_RAMP = (MOSS_SHADOW, MOSS_DARK, MOSS, MOSS_LIGHT)

WOOD_ROT = (37, 29, 28, 255)  # frestas / madeira podre
WOOD_DARK = (55, 42, 36, 255)
WOOD = (74, 57, 45, 255)
WOOD_LIGHT = (95, 74, 56, 255)
WOOD_HIGHLIGHT = (117, 93, 68, 255)
WOOD_RAMP = (WOOD_ROT, WOOD_DARK, WOOD, WOOD_LIGHT, WOOD_HIGHLIGHT)

RUST_SHADOW = (64, 34, 30, 255)
RUST_DARK = (96, 49, 35, 255)
RUST = (130, 69, 43, 255)
RUST_LIGHT = (163, 96, 57, 255)
RUST_ACCENT = (194, 128, 78, 255)
RUST_GLINT = (228, 178, 124, 255)  # brilho do minério de ferro
RUST_RAMP = (RUST_SHADOW, RUST_DARK, RUST, RUST_LIGHT, RUST_ACCENT)

IRON_SHADOW = (38, 40, 49, 255)
IRON_DARK = (60, 63, 73, 255)
IRON = (90, 93, 103, 255)
IRON_LIGHT = (128, 131, 139, 255)
IRON_HIGHLIGHT = (170, 172, 177, 255)
IRON_RAMP = (IRON_SHADOW, IRON_DARK, IRON, IRON_LIGHT, IRON_HIGHLIGHT)

SHADOW_INK = (6, 6, 12, 255)  # sombra projetada no chão (usada com alpha)

# --- ipezinho ----------------------------------------------------------------
SKIN_SHADOW = (128, 84, 74, 255)
SKIN_DARK = (168, 116, 94, 255)
SKIN = (204, 154, 122, 255)
SKIN_LIGHT = (226, 184, 148, 255)
BLUSH = (190, 110, 96, 255)
EYE = (40, 30, 38, 255)

HELMET_DARK = (84, 67, 46, 255)  # capacete de latão sujo e amassado
HELMET = (122, 98, 60, 255)
HELMET_LIGHT = (160, 132, 80, 255)
HELMET_HIGHLIGHT = (190, 164, 104, 255)

DENIM_SHADOW = (38, 44, 58, 255)  # macacão desbotado
DENIM_DARK = (52, 62, 79, 255)
DENIM = (70, 84, 101, 255)
DENIM_LIGHT = (92, 108, 122, 255)

FLANNEL_DARK = (78, 42, 44, 255)  # camisa de flanela gasta
FLANNEL = (110, 58, 52, 255)
FLANNEL_LIGHT = (138, 80, 64, 255)

LEATHER_DARK = (44, 33, 31, 255)
LEATHER = (66, 47, 39, 255)
LEATHER_LIGHT = (90, 65, 49, 255)
BRASS = (176, 146, 84, 255)

# --- comida ------------------------------------------------------------------
BREAD_DARK = (116, 70, 42, 255)
BREAD = (164, 110, 62, 255)
BREAD_LIGHT = (200, 150, 94, 255)
BREAD_HIGHLIGHT = (226, 190, 136, 255)
APPLE_DARK = (92, 30, 38, 255)
APPLE = (146, 44, 46, 255)
APPLE_LIGHT = (186, 76, 64, 255)
SHROOM_DARK = (104, 38, 44, 255)
SHROOM = (150, 58, 56, 255)
SHROOM_STEM = (176, 166, 150, 255)
SHROOM_SPOT = (214, 206, 192, 255)

# --- fontes de luz (quentes, saturadas: o contraste é proposital) -----------
TORCH_EMBER = (156, 36, 18, 255)
TORCH_FLAME = (226, 88, 26, 255)
TORCH_GLOW = (255, 152, 38, 255)
TORCH_BRIGHT = (255, 212, 84, 255)
TORCH_CORE = (255, 248, 204, 255)
TORCH_RAMP = (TORCH_EMBER, TORCH_FLAME, TORCH_GLOW, TORCH_BRIGHT, TORCH_CORE)

LAMP_GLOW = (255, 196, 64, 255)
LAMP_CORE = (255, 250, 218, 255)
WINDOW_DIM = (214, 110, 34, 255)
WINDOW_LIT = (255, 182, 62, 255)
WINDOW_BRIGHT = (255, 230, 150, 255)

GOLD_DARK = (116, 64, 18, 255)
GOLD = (206, 140, 36, 255)
GOLD_LIGHT = (244, 194, 64, 255)
GOLD_HIGHLIGHT = (255, 238, 150, 255)


# =================================================================== helpers
def new(w, h):
    return Image.new("RGBA", (w, h), CLEAR)


def rect(img, x0, y0, x1, y1, c):
    """Retângulo preenchido, coordenadas inclusivas. `c` pode ser um par (a, b) = xadrez."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(img, x, y, c)


def px(img, x, y, c):
    if isinstance(c[0], tuple):  # par de cores -> dithering xadrez
        c = c[(x + y) & 1]
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def opaque(img, x, y):
    return 0 <= x < img.width and 0 <= y < img.height and img.getpixel((x, y))[3] > 0


def from_rows(rows, pal):
    """Desenha a partir de linhas de texto. Um valor da paleta que seja um par
    de cores (a, b) vira xadrez entre elas (dithering)."""
    assert all(len(r) == len(rows[0]) for r in rows), rows
    img = new(len(rows[0]), len(rows))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                px(img, x, y, pal[ch])
    return img


def shade(c, k):
    """Escurece (k < 1) ou clareia (k > 1) uma cor como se faz em pixel art:
    a sombra puxa o matiz pro azul/roxo e ganha saturação; a luz puxa pro amarelo."""
    r, g, b = (v / 255 for v in c[:3])
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    target = 0.70 if k < 1 else 0.13
    d = ((target - h + 0.5) % 1.0) - 0.5
    h = (h + d * min(abs(1 - k), 1.0) * 0.18) % 1.0
    if k < 1:
        s = min(1.0, s * (1 + (1 - k) * 0.4) + 0.04)
    else:
        s = max(0.0, s * (1 - (k - 1) * 0.35))
    v = max(0.0, min(1.0, v * k))
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return (round(r * 255), round(g * 255), round(b * 255), c[3] if len(c) > 3 else 255)


def luminance(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def outline(img, k=0.5):
    """Contorno de 1px "colorido": cada pixel do contorno é a cor do vizinho
    opaco, escurecida por shade(). Nada de preto puro."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3] != 0:
                continue
            neigh = [src.getpixel((x + dx, y + dy)) for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0))
                     if opaque(src, x + dx, y + dy)]
            if neigh:
                avg = tuple(sum(c[i] for c in neigh) // len(neigh) for i in range(3)) + (255,)
                img.putpixel((x, y), shade(avg, k))
    return img


def recolor_dark_outline(img, k=0.45, threshold=40):
    """Troca o contorno preto de sprites prontos por contorno colorido."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            c = src.getpixel((x, y))
            if c[3] == 0 or luminance(c) >= threshold:
                continue
            found = []
            for r in (1, 2, 3):
                for dy in range(-r, r + 1):
                    for dx in range(-r, r + 1):
                        if opaque(src, x + dx, y + dy):
                            n = src.getpixel((x + dx, y + dy))
                            if luminance(n) >= threshold:
                                found.append(n)
                if found:
                    break
            if found:
                avg = tuple(sum(n[i] for n in found) // len(found) for i in range(3)) + (255,)
                img.putpixel((x, y), shade(avg, k))
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


# ------------------------------------------------------------ dithering
BAYER4 = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def dither(ramp, t, x, y, mode="band"):
    """Escolhe a cor da rampa pra um valor contínuo t (0..1) com dithering.

    mode="bayer": Bayer 4x4 (gradiente suave, bom pra texturas grandes).
    mode="band":  faixas chapadas com uma faixa xadrez na transição entre dois
                  tons (o jeito "à mão" de sombrear sprite pequeno).
    """
    t = max(0.0, min(1.0, t))
    f = t * (len(ramp) - 1)
    i = min(int(f), len(ramp) - 2)
    frac = f - i
    if mode == "bayer":
        return ramp[i + 1] if frac > (BAYER4[y % 4][x % 4] + 0.5) / 16 else ramp[i]
    if frac < 0.32:
        return ramp[i]
    if frac > 0.68:
        return ramp[i + 1]
    return ramp[i + 1] if (x + y) & 1 else ramp[i]


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


# ------------------------------------------------------------ rochas
LIGHT_DIR = (-0.5, -0.72, 0.48)  # luz vindo de cima/esquerda, meio de frente


def rock(w, h, seed, ramp=STONE_RAMP, ore=0, moss=0.0, cracks=1, bright=0.0):
    """Pedra com facetas, luz de cima-esquerda, sombra de contato na base,
    rachaduras, veios de minério (`ore` = nº de pepitas) e musgo no topo.
    Deixa 1px livre em volta pro contorno."""
    rnd = random.Random(seed)
    img = new(w, h)
    cx = (w - 1) / 2 + rnd.uniform(-0.4, 0.4)
    rx = (w - 2) / 2 - 0.2
    top, bottom = 1, h - 2
    ry = (bottom - top) / 2 + 0.3
    cy = (top + bottom) / 2 + 0.3
    harm = [(k, rnd.uniform(0.0, 0.09), rnd.uniform(0, math.tau)) for k in (2, 3, 5)]
    facets = [(rnd.uniform(1, w - 2), rnd.uniform(1, h - 2), rnd.uniform(-0.14, 0.14))
              for _ in range(max(3, (w * h) // 30))]
    lx, ly, lz = LIGHT_DIR
    ln = math.sqrt(lx * lx + ly * ly + lz * lz)
    lx, ly, lz = lx / ln, ly / ln, lz / ln

    mask = {}
    for y in range(top, bottom + 1):
        for x in range(1, w - 1):
            nx, ny = (x - cx) / rx, (y - cy) / ry
            if ny > 0:
                ny *= 0.72  # base mais larga e achatada: a pedra "senta" no chão
            else:
                nx *= 1 + 0.3 * -ny  # topo mais estreito: silhueta de pedra, não de caixa
            ang = math.atan2(ny, nx)
            lim = 1 + sum(a * math.cos(k * ang + p) for k, a, p in harm)
            if math.hypot(nx, ny) <= lim:
                mask[(x, y)] = (nx / lim, ny / lim)

    for (x, y), (nx, ny) in mask.items():
        nz = math.sqrt(max(0.0, 1 - nx * nx - ny * ny))
        lam = max(0.0, nx * lx + ny * ly + nz * lz)
        fx = min(facets, key=lambda f: (f[0] - x) ** 2 + (f[1] - y) ** 2)
        t = 0.14 + 0.9 * lam + fx[2] + bright
        if y >= bottom - 1:
            t -= 0.12  # sombra de contato com o chão
        if (x, y - 1) not in mask and lam > 0.55:
            t += 0.18  # aresta de cima pega luz
        img.putpixel((x, y), dither(ramp, t, x, y))

    inner = [p for p in mask if all((p[0] + dx, p[1] + dy) in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]

    # musgo no topo (onde a normal aponta pra cima)
    if moss > 0:
        for (x, y), (nx, ny) in mask.items():
            v = -ny + rnd.uniform(-0.25, 0.25)
            if v > 1.0 - moss:
                depth = min(1.0, (v - (1.0 - moss)) / 0.35)
                img.putpixel((x, y), dither(MOSS_RAMP, 0.25 + 0.6 * depth, x, y))

    # rachaduras: linha escura com um pixel de luz embaixo (parece entalhada)
    for _ in range(cracks):
        if not inner:
            break
        x, y = rnd.choice(inner)
        for _ in range(rnd.randint(2, 4)):
            if (x, y) not in mask:
                break
            img.putpixel((x, y), ramp[0])
            if (x, y + 1) in mask and (x + 1, y + 1) in mask:
                img.putpixel((x + 1, y + 1), ramp[min(3, len(ramp) - 1)])
            x += rnd.choice((-1, 0, 1))
            y += 1

    # pepitas de ferro: acento de ferrugem + brilho
    lit = [p for p in inner if mask[p][1] < 0.5 and (p[0] + 1, p[1] + 1) in mask]
    rnd.shuffle(lit)
    placed = []
    for x, y in lit:
        if len(placed) >= ore:
            break
        if any(abs(x - a) < 3 and abs(y - b) < 3 for a, b in placed):
            continue
        placed.append((x, y))
        img.putpixel((x, y), RUST_ACCENT)
        img.putpixel((x + 1, y), RUST_LIGHT)
        img.putpixel((x, y + 1), RUST)
        img.putpixel((x + 1, y + 1), RUST_DARK)
        if rnd.random() < 0.6:
            img.putpixel((x, y), RUST_GLINT)

    return outline(img, 0.55)


# =================================================================== sprites
# ------------------------------------------------------------ ipezinho
IPEZINHO_UPPER = [  # 16 colunas; linha 0 fica livre pro contorno
    "................",
    "......kkHh......",
    "....kkHHHHXh....",
    "...kHHgYYgHHh...",
    "...kHHgWYgHXh...",
    "..hhhhhgghhhhh..",
    "...ssssssssss...",
    "...SSeSSSSeSs...",
    "...SSeSSSSeSs...",
    "...SrSSmmSSrs...",
    "..fFFCCCCCCFFu..",
    "..fFFcCCCCcFFu..",
    "..SsuZCCCCZuSs..",
    "...cTTTbbTTTc...",
]
IPEZINHO_LEG = "....cCc..cCc...."
IPEZINHO_FOOT = "...LLLl..LLLl..."
IPEZINHO_PAL = {
    "k": HELMET_HIGHLIGHT, "H": HELMET_LIGHT, "h": HELMET_DARK, "X": (HELMET_LIGHT, HELMET),
    "g": IRON_DARK, "Y": LAMP_GLOW, "W": LAMP_CORE,
    "s": SKIN_DARK, "S": SKIN, "e": EYE, "r": BLUSH, "m": SKIN_SHADOW,
    "F": FLANNEL_LIGHT, "f": FLANNEL, "u": FLANNEL_DARK,
    "C": DENIM, "c": DENIM_DARK, "Z": (DENIM, DENIM_DARK),
    "T": LEATHER, "b": BRASS,
    "L": LEATHER_LIGHT, "l": LEATHER_DARK,
}


def build_ipezinho():
    upper = from_rows(IPEZINHO_UPPER, IPEZINHO_PAL)
    leg = from_rows([IPEZINHO_LEG], IPEZINHO_PAL)
    foot = from_rows([IPEZINHO_FOOT], IPEZINHO_PAL)

    def frame(lift, left_up, right_up):
        out = new(16, 17)
        out.alpha_composite(upper, (0, -lift))
        for x0, x1, up in ((0, 8, left_up), (8, 16, right_up)):
            l = leg.crop((x0, 0, x1, 1))
            f = foot.crop((x0, 0, x1, 1))
            if lift and not up:  # perna de apoio enquanto o corpo sobe: estica
                out.alpha_composite(l, (x0, 13))
                out.alpha_composite(l, (x0, 14))
                out.alpha_composite(f, (x0, 15))
            elif lift and up:  # perna levantada
                out.alpha_composite(l, (x0, 13))
                out.alpha_composite(f, (x0, 14))
            else:
                out.alpha_composite(l, (x0, 14))
                out.alpha_composite(f, (x0, 15))
        return outline(out, 0.5)

    frames = [frame(0, False, False), frame(1, False, True), frame(0, False, False), frame(1, True, False)]
    sheet = new(16 * 4, 17)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * 16, 0))
    save(sheet, "ipezinho_walk.png")


def build_pickaxe():
    # mantém 11x13 (o offset da cena depende disso); as bordas já são tons escuros do próprio metal
    rows = [
        "..LLGrGDD..",
        ".LG.hBh.GD.",
        "LG...Bb...D",
        "L....Bb...d",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....ww....",
        ".....Ww....",
        ".....bb....",
    ]
    pal = {
        "L": IRON_HIGHLIGHT, "G": IRON_LIGHT, "D": IRON, "d": IRON_DARK, "h": IRON_DARK,
        "r": RUST_LIGHT, "B": WOOD_HIGHLIGHT, "b": WOOD_DARK,
        "W": LEATHER_LIGHT, "w": LEATHER,  # empunhadura de couro
    }
    save(from_rows(rows, pal), "pickaxe.png")


# ------------------------------------------------------------ minérios e pedras
def ore_chunk(w, h, seed):
    """Pedaço de minério de ferro (ícone de carga / HUD / pilha do armazém)."""
    rnd = random.Random(seed)
    img = new(w, h)
    cx, cy = (w - 1) / 2, (h - 1) / 2 + 0.3
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            nx, ny = (x - cx) / ((w - 2) / 2), (y - cy) / ((h - 2) / 2)
            if nx * nx + ny * ny <= 1.05 + rnd.uniform(-0.12, 0.05):
                t = 0.55 - 0.45 * nx - 0.55 * ny
                img.putpixel((x, y), dither(RUST_RAMP, t, x, y))
    # pontinhos de rocha escura e um brilho
    for _ in range(max(1, (w * h) // 25)):
        x, y = rnd.randrange(1, w - 1), rnd.randrange(1, h - 1)
        if opaque(img, x, y):
            img.putpixel((x, y), STONE_DARK)
    for y in range(h):
        for x in range(w):
            if opaque(img, x, y) and not opaque(img, x, y - 1) and not opaque(img, x - 1, y):
                img.putpixel((x, y), RUST_GLINT)
                break
        else:
            continue
        break
    return outline(img, 0.5)


def build_ores():
    for i, (seed, n) in enumerate(((101, 4), (202, 5), (303, 4))):
        save(rock(16, 16, seed, ramp=STONE_RAMP, ore=n, moss=0.0, cracks=1, bright=-0.04), f"ore_iron_{i}.png")
    save(trim(ore_chunk(9, 8, 5)), "ore_chunk.png")

    for i, (seed, moss, cracks) in enumerate(((11, 0.0, 1), (12, 0.45, 1), (13, 0.0, 2), (14, 0.6, 0), (15, 0.25, 1))):
        save(rock(16, 16, seed, moss=moss, cracks=cracks), f"boulder_{i}.png")
    for i, (w, h, seed, moss) in enumerate(((6, 5, 21, 0.0), (6, 5, 22, 0.0), (9, 8, 23, 0.4), (7, 5, 24, 0.0))):
        save(trim(rock(w, h, seed, moss=moss, cracks=0 if w < 8 else 1, bright=0.12)), f"pebble_{i}.png")

    # pilha de minério do armazém: 4 estágios (vazio -> cheio)
    small = trim(ore_chunk(6, 5, 31))
    mid = trim(ore_chunk(8, 7, 32))
    mid2 = trim(ore_chunk(8, 7, 33))
    stages = [
        [],
        [(mid, 6, 7), (small, 12, 9)],
        [(mid, 3, 7), (mid2, 10, 7), (small, 15, 9), (small, 7, 3)],
        [(mid, 1, 7), (mid2, 7, 7), (mid, 13, 7), (mid2, 4, 3), (mid, 10, 3), (small, 8, 0)],
    ]
    sheet = new(22 * 4, 14)
    for i, parts in enumerate(stages):
        f = new(22, 14)
        for img, x, y in parts:
            f.alpha_composite(img, (x, y))
        sheet.alpha_composite(f, (i * 22, 0))
    save(sheet, "ore_pile.png")


def build_crystals():
    # cristais são fonte de luz: ficam com as cores saturadas do pack, só o contorno muda
    sheet = Image.open(STEWV).convert("RGBA")
    for i, (col, row) in enumerate(((7, 0), (0, 1), (7, 1), (2, 2))):
        save(recolor_dark_outline(trim(tile(sheet, col, row, 32))), f"crystal_{i}.png")


def build_shadow():
    """Sombra projetada no chão, com borda em xadrez de alpha (dithering)."""
    W, H = 24, 9
    img = new(W, H)
    cx, cy = (W - 1) / 2, (H - 1) / 2
    for y in range(H):
        for x in range(W):
            d = math.hypot((x - cx) / (W / 2), (y - cy) / (H / 2))
            if d < 0.62:
                a = 150
            elif d < 0.82:
                a = 150 if (x + y) & 1 else 90
            elif d < 1.0:
                a = 70 if (x + y) & 1 else 0
            else:
                a = 0
            if a:
                img.putpixel((x, y), SHADOW_INK[:3] + (a,))
    save(img, "shadow_blob.png")


# ------------------------------------------------------------ madeira velha
def wood_post(img, x0, y0, w, h, rnd, rot=True):
    """Poste/tábua vertical: luz na esquerda, sombra na direita, podre embaixo."""
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            u = (x - x0) / max(1, w - 1)
            t = 0.72 - 0.42 * u
            if rot:
                t -= max(0.0, (y - (y0 + h * 0.65)) / (h * 0.35)) * 0.35
            px(img, x, y, dither(WOOD_RAMP, t, x, y))
    # veio da madeira
    gx = x0 + 1 + rnd.randrange(max(1, w - 2))
    for y in range(y0 + 1, y0 + h - 1):
        if rnd.random() < 0.55:
            px(img, gx, y, WOOD_DARK)
        if rnd.random() < 0.12:
            gx = min(x0 + w - 2, max(x0 + 1, gx + rnd.choice((-1, 1))))
    # nó
    ky = y0 + 2 + rnd.randrange(max(1, h - 4))
    px(img, x0 + w // 2, ky, WOOD_ROT)
    px(img, x0 + w // 2, ky - 1, WOOD_LIGHT)


def wood_beam(img, x0, y0, w, h, rnd):
    """Viga horizontal: topo claro, base escura, uma rachadura longa."""
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            v = (y - y0) / max(1, h - 1)
            t = 0.8 - 0.55 * v + rnd.uniform(-0.04, 0.04)
            px(img, x, y, dither(WOOD_RAMP, t, x, y))
    cy = y0 + h // 2
    x = x0 + 2 + rnd.randrange(4)
    while x < x0 + w - 3:
        if rnd.random() < 0.7:
            px(img, x, cy, WOOD_ROT)
        if rnd.random() < 0.15:
            cy = min(y0 + h - 2, max(y0 + 1, cy + rnd.choice((-1, 1))))
        x += 1


def nail(img, x, y):
    px(img, x, y, IRON_LIGHT)
    px(img, x + 1, y + 1, RUST_DARK)  # escorrido de ferrugem


# ------------------------------------------------------------ armazém
def build_armazem():
    W, H = 36, 32
    rnd = random.Random(36)
    img = new(W, H)

    # telhado de zinco ondulado e enferrujado (a ferrugem escorre pra baixo)
    rust_from = [rnd.choice((2, 4, 6, 7, 8, 9, 12)) for _ in range(W)]
    for y in range(1, 12):
        inset = round((11 - y) * 8 / 10)
        x0, x1 = inset, W - 1 - inset
        for x in range(x0, x1 + 1):
            wave = (x % 3)  # ondulação: crista / meio / vale
            t = (0.62, 0.45, 0.25)[wave] - (y - 1) * 0.02
            c = dither(IRON_RAMP, t, x, y)
            if y >= rust_from[x] or (y + 1 == rust_from[x] and (x + y) & 1):
                c = dither(RUST_RAMP, t + 0.05, x, y)
            img.putpixel((x, y), c)
    rect(img, 8, 0, W - 9, 0, IRON_DARK)  # cumeeira
    for x in range(9, W - 9, 3):
        px(img, x, 0, IRON_LIGHT)
    # chapa remendada
    rect(img, 22, 5, 27, 8, IRON)
    rect(img, 22, 5, 27, 5, IRON_LIGHT)
    rect(img, 22, 8, 27, 8, IRON_DARK)
    for x, y in ((22, 5), (27, 5), (22, 8), (27, 8)):
        px(img, x, y, RUST_ACCENT)  # rebites
    # beiral: faixa escura + gotas de ferrugem
    rect(img, 0, 11, W - 1, 11, RUST_SHADOW)
    for x in range(1, W - 1, 4):
        px(img, x + rnd.randrange(2), 12, RUST_DARK)

    # paredes de tábua velha
    for y in range(12, 30):
        for x in range(2, W - 2):
            plank = (x - 2) // 4
            u = (x - 2) % 4
            if u == 0:
                c = WOOD_ROT  # fresta entre tábuas
            else:
                t = 0.62 - (u - 1) * 0.12 + ((plank * 7) % 3) * 0.04
                t -= max(0.0, (y - 23) / 7) * 0.4  # podre/sujo perto do chão
                c = dither(WOOD_RAMP, t, x, y)
            img.putpixel((x, y), c)
    # sombra do beiral (longa, dithered)
    for y in (12, 13, 14):
        for x in range(2, W - 2):
            if y == 12 or (y == 13 and (x + y) & 1) or (y == 14 and (x + y) % 4 == 0):
                img.putpixel((x, y), WOOD_ROT)
    # colunas dos cantos
    for cx0 in (2, W - 4):
        for y in range(12, 30):
            px(img, cx0, y, WOOD_LIGHT if y > 14 else WOOD_DARK)
            px(img, cx0 + 1, y, WOOD_DARK)
    # musgo subindo pela base
    for x in range(2, W - 2):
        hgt = rnd.choice((0, 0, 1, 1, 2, 3))
        for k in range(hgt):
            px(img, x, 29 - k, dither(MOSS_RAMP, 0.55 - k * 0.2, x, 29 - k))

    # porta dupla com travas em X e dobradiças de ferro
    dx0, dx1, dy0, dy1 = 12, 23, 17, 29
    rect(img, dx0, dy0, dx1, dy1, WOOD_ROT)
    for y in range(dy0 + 1, dy1 + 1):
        for x in range(dx0 + 1, dx1):
            t = 0.55 - (0.15 if x in ((dx0 + dx1) // 2, (dx0 + dx1) // 2 + 1) else 0) - (y - dy0) * 0.015
            img.putpixel((x, y), dither(WOOD_RAMP, t, x, y))
    rect(img, (dx0 + dx1) // 2, dy0 + 1, (dx0 + dx1) // 2, dy1, WOOD_ROT)
    for hx0, hx1 in ((dx0 + 1, (dx0 + dx1) // 2 - 1), ((dx0 + dx1) // 2 + 1, dx1 - 1)):
        w = hx1 - hx0
        h = dy1 - (dy0 + 1)
        for i in range(h + 1):
            s = i / h
            px(img, hx0 + round(s * w), dy0 + 1 + i, WOOD_HIGHLIGHT)
            px(img, hx1 - round(s * w), dy0 + 1 + i, WOOD_LIGHT)
        for hy in (dy0 + 2, dy1 - 2):
            px(img, hx0, hy, IRON_LIGHT)
            px(img, hx0 + 1, hy, IRON_DARK)
    px(img, (dx0 + dx1) // 2 - 1, 23, BRASS)  # maçaneta
    # soleira escura (luz de dentro não passa: sombra densa)
    rect(img, dx0 + 1, dy1, dx1 - 1, dy1, (WOOD_ROT, STONE_BLACK))

    # placa com ícone de minério
    rect(img, 14, 13, 21, 16, WOOD_LIGHT)
    rect(img, 14, 13, 21, 13, WOOD_HIGHLIGHT)
    rect(img, 14, 16, 21, 16, WOOD_DARK)
    for x, y, c in ((16, 14, RUST_ACCENT), (17, 14, STONE_DARK), (18, 14, RUST_LIGHT),
                    (17, 15, RUST), (19, 15, STONE_DARK), (16, 15, RUST_DARK)):
        px(img, x, y, c)
    nail(img, 14, 13)
    nail(img, 20, 13)

    # janelas acesas (fonte de luz: quente e saturada)
    for wx in (5, W - 10):
        rect(img, wx, 16, wx + 4, 21, WOOD_ROT)
        rect(img, wx + 1, 17, wx + 3, 20, WINDOW_LIT)
        rect(img, wx + 1, 20, wx + 3, 20, WINDOW_DIM)
        px(img, wx + 1, 17, WINDOW_BRIGHT)
        px(img, wx + 3, 17, WINDOW_BRIGHT)
        rect(img, wx + 2, 17, wx + 2, 20, WOOD_DARK)
        rect(img, wx + 1, 18, wx + 3, 18, WOOD_DARK)
        rect(img, wx, 21, wx + 4, 21, WOOD_LIGHT)  # peitoril
        # luz vazando no peitoril/parede (xadrez de brilho)
        for x in range(wx, wx + 5):
            if (x + 22) & 1:
                px(img, x, 22, shade(WINDOW_DIM, 0.55))
    # tábua quebrada/pendurada numa das janelas
    px(img, W - 10, 17, WOOD_LIGHT)
    px(img, W - 9, 18, WOOD_LIGHT)
    px(img, W - 8, 19, WOOD_DARK)

    # fundação de pedra
    for x in range(1, W - 1):
        for y in (30, 31):
            t = 0.55 if y == 30 else 0.3
            if (x + (y == 31) * 3) % 6 == 0:
                t = 0.1  # junta entre pedras
            img.putpixel((x, y), dither(STONE_RAMP, t, x, y))
    save(outline(pad(img), 0.5), "armazem.png")


# ------------------------------------------------------------ casa da vila
def build_casa():
    """Casinha de pedra e tábua com telhado de ardósia. 2 quadros lado a lado:
    0 = vazia (janelas escuras), 1 = alguém dormindo (janelas acesas)."""
    W, H = 28, 24
    rnd = random.Random(28)
    base = new(W, H)

    # chaminé de pedra (atrás do telhado)
    for y in range(0, 7):
        for x in range(19, 23):
            base.putpixel((x, y), dither(STONE_RAMP, 0.6 - (x - 19) * 0.12, x, y))
    rect(base, 18, 0, 23, 0, STONE_LIGHT)

    # telhado de ardósia em fileiras, com musgo
    for y in range(2, 11):
        inset = round((10 - y) * 6 / 8)
        for x in range(inset, W - inset):
            row = (y - 2) // 2
            t = 0.55 - (y - 2) * 0.03
            if (y - 2) % 2 == 1:
                t -= 0.18  # borda de baixo de cada fileira de telhas
            elif (x + row * 2) % 4 == 0:
                t = 0.12  # junta entre telhas
            c = dither(STONE_RAMP, t, x, y)
            if rnd.random() < 0.12 + (y - 2) * 0.02:
                c = dither(MOSS_RAMP, t + 0.1, x, y)
            base.putpixel((x, y), c)
    rect(base, 6, 1, W - 7, 1, STONE_SHADOW)  # cumeeira
    rect(base, 0, 10, W - 1, 10, STONE_BLACK)  # beiral

    # paredes: tábuas em cima, pedra embaixo
    for y in range(11, 22):
        for x in range(2, W - 2):
            if y >= 18:
                t = 0.5 if (x + (y % 2) * 2) % 5 else 0.1
                c = dither(STONE_RAMP, t - (y - 18) * 0.06, x, y)
            elif (x - 2) % 3 == 0:
                c = WOOD_ROT
            else:
                c = dither(WOOD_RAMP, 0.55 - ((x - 2) % 3 - 1) * 0.12, x, y)
            base.putpixel((x, y), c)
    for x in range(2, W - 2):  # sombra do beiral (dithered)
        px(base, x, 11, WOOD_ROT)
        if x & 1:
            px(base, x, 12, WOOD_DARK)

    # porta arredondada
    for y in range(13, 22):
        for x in range(11, 17):
            if y == 13 and x in (11, 16):
                continue
            t = 0.45 if x < 14 else 0.3
            px(base, x, y, dither(WOOD_RAMP, t, x, y))
    rect(base, 13, 14, 13, 21, WOOD_ROT)
    px(base, 15, 17, BRASS)
    rect(base, 11, 21, 16, 21, (WOOD_ROT, STONE_BLACK))
    # degrau
    rect(base, 10, 22, 17, 22, STONE_LIGHT)
    rect(base, 10, 23, 17, 23, STONE_DARK)
    # fundação
    for x in range(1, W - 1):
        if not 10 <= x <= 17:
            px(base, x, 22, dither(STONE_RAMP, 0.3, x, 22))

    frames = []
    for lit in (False, True):
        img = base.copy()
        for wx in (4, 19):
            rect(img, wx, 13, wx + 4, 17, WOOD_ROT)
            if lit:
                rect(img, wx + 1, 14, wx + 3, 16, WINDOW_LIT)
                px(img, wx + 1, 14, WINDOW_BRIGHT)
                rect(img, wx + 1, 16, wx + 3, 16, WINDOW_DIM)
            else:
                rect(img, wx + 1, 14, wx + 3, 16, WALL_VOID)
                px(img, wx + 1, 14, WALL_WET)  # reflexo no vidro
            px(img, wx + 2, 14, WOOD_DARK)
            px(img, wx + 2, 15, WOOD_DARK)
            px(img, wx + 2, 16, WOOD_DARK)
            rect(img, wx, 17, wx + 4, 17, WOOD_LIGHT)  # peitoril
            if lit:
                for x in range(wx, wx + 5):
                    if x & 1:
                        px(img, x, 18, shade(WINDOW_DIM, 0.55))
        frames.append(outline(pad(img), 0.5))

    sheet = new(frames[0].width * 2, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "casa.png")


# ------------------------------------------------------------ comedouro
def build_comedouro():
    W, H = 30, 18
    rnd = random.Random(30)
    img = new(W, H)
    # pernas (podres embaixo)
    for lx in (3, W - 5):
        for y in range(13, 18):
            px(img, lx, y, WOOD_LIGHT if y < 16 else WOOD_DARK)
            px(img, lx + 1, y, WOOD_DARK if y < 16 else WOOD_ROT)
    # cocho: duas tábuas com sombra dithered embaixo
    for y in range(7, 14):
        inset = 1 if y >= 11 else 0
        for x in range(1 + inset, W - 1 - inset):
            t = 0.78 - (y - 7) * 0.09
            if y == 10:
                t = 0.05  # fresta entre as tábuas
            img.putpixel((x, y), dither(WOOD_RAMP, t, x, y))
    for x in range(3, W - 3, 5):  # veio / manchas de podre
        px(img, x + rnd.randrange(3), 8 + rnd.randrange(2), WOOD_DARK)
        px(img, x + rnd.randrange(3), 12, WOOD_ROT)
    rect(img, 1, 7, 1, 10, WOOD_DARK)
    rect(img, W - 2, 7, W - 2, 10, WOOD_ROT)
    # cinta de ferro enferrujada
    for bx in (7, W - 8):
        rect(img, bx, 7, bx, 13, RUST)
        px(img, bx, 7, RUST_LIGHT)
        px(img, bx, 13, RUST_DARK)
    # musgo na quina
    for x, y in ((2, 13), (3, 12), (W - 4, 13), (W - 3, 13), (W - 3, 12)):
        px(img, x, y, (MOSS_DARK, MOSS))
    # "papa" da comida no topo
    rect(img, 2, 6, W - 3, 6, (BREAD_DARK, WOOD_DARK))
    # pães
    for bx in (3, 16):
        rect(img, bx, 3, bx + 5, 5, BREAD)
        rect(img, bx + 1, 2, bx + 4, 2, BREAD_LIGHT)
        rect(img, bx + 1, 3, bx + 3, 3, BREAD_HIGHLIGHT)
        rect(img, bx, 5, bx + 5, 5, (BREAD_DARK, BREAD))
        px(img, bx + 2, 4, BREAD_DARK)
        px(img, bx + 4, 3, BREAD_DARK)
    # maçãs
    for ax, ay in ((10, 4), (13, 3)):
        rect(img, ax, ay, ax + 2, ay + 2, APPLE)
        px(img, ax + 2, ay + 2, APPLE_DARK)
        px(img, ax + 1, ay + 2, (APPLE, APPLE_DARK))
        px(img, ax, ay, APPLE_LIGHT)
        px(img, ax + 1, ay - 1, WOOD_DARK)
    # cogumelo da caverna
    rect(img, 23, 1, 27, 3, SHROOM)
    rect(img, 24, 0, 26, 0, SHROOM)
    rect(img, 23, 3, 27, 3, (SHROOM, SHROOM_DARK))
    px(img, 24, 1, SHROOM_SPOT)
    px(img, 26, 2, SHROOM_SPOT)
    rect(img, 24, 4, 26, 6, SHROOM_STEM)
    px(img, 26, 5, shade(SHROOM_STEM, 0.75))
    px(img, 24, 4, shade(SHROOM_STEM, 0.7))  # sombra do chapéu
    # folhas (musgo/ervas da caverna)
    for x, y in ((9, 6), (10, 5), (14, 6), (15, 5), (22, 5), (22, 6)):
        px(img, x, y, MOSS_LIGHT if y == 5 else MOSS)
    save(outline(pad(img), 0.5), "comedouro.png")


# ------------------------------------------------------------ ambiente
def build_floor():
    size = 64
    rnd = random.Random(7)
    field = seamless_noise(size, 90, 11, (3, 9))
    moss = seamless_noise(size, 26, 19, (3, 7))
    img = new(size, size)
    for y in range(size):
        for x in range(size):
            v = field[y][x] + rnd.uniform(-0.2, 0.2)
            t = 0.5 + v * 0.28
            c = dither(EARTH_RAMP, t, x, y, mode="bayer")
            m = moss[y][x]
            if m > 0.6:  # manchas de musgo escuro, com borda dithered
                mt = min(1.0, (m - 0.6) / 0.7)
                if BAYER4[y % 4][x % 4] < mt * 22:
                    c = dither(MOSS_RAMP, 0.05 + 0.4 * mt + v * 0.08, x, y, mode="bayer")
            img.putpixel((x, y), c)
    # pedrinhas com luz em cima e sombra embaixo
    for _ in range(16):
        x, y = rnd.randrange(size), rnd.randrange(size)
        w = rnd.choice((1, 2, 2, 3))
        for i in range(w):
            img.putpixel(((x + i) % size, y), STONE_DARK)
            img.putpixel(((x + i) % size, (y + 1) % size), EARTH_SHADOW)
        img.putpixel((x, (y - 1) % size), STONE)
    # rachaduras (com lábio claro embaixo)
    for _ in range(6):
        x, y = rnd.randrange(size), rnd.randrange(size)
        for _ in range(rnd.randint(4, 8)):
            img.putpixel((x % size, y % size), EARTH_SHADOW)
            if rnd.random() < 0.5:
                img.putpixel((x % size, (y + 1) % size), EARTH_HIGHLIGHT)
            x += rnd.choice((1, 1, 0))
            y += rnd.choice((1, 0, -1))
    # lascas de ferrugem (restos de trilho/ferramenta)
    for _ in range(5):
        x, y = rnd.randrange(size), rnd.randrange(size)
        img.putpixel((x, y), RUST_DARK)
        if rnd.random() < 0.5:
            img.putpixel(((x + 1) % size, y), RUST_SHADOW)
    save(img, "floor_cave.png")


def build_wall():
    size = 32
    rnd = random.Random(3)
    img = new(size, size)
    rect(img, 0, 0, size - 1, size - 1, WALL_VOID)
    stones = [(rnd.randrange(size), rnd.randrange(size), rnd.uniform(3.0, 6.0)) for _ in range(18)]
    stones.sort(key=lambda s: s[1])  # de cima pra baixo: as de baixo cobrem as de cima
    for cx, cy, r in stones:
        for y in range(-7, 8):
            for x in range(-7, 8):
                d = ((x * x) + (y * y) * 1.3) ** 0.5
                if d >= r:
                    continue
                nx, ny = x / r, y / r
                t = 0.62 - 0.55 * ny - 0.2 * nx - (d / r) * 0.15
                if d > r - 1.0 and ny > 0:
                    t = 0.0  # borda inferior some na escuridão
                ix, iy = (cx + x) % size, (cy + y) % size
                img.putpixel((ix, iy), dither(WALL_RAMP, t, ix, iy))
    # rachaduras
    for _ in range(4):
        x, y = rnd.randrange(size), rnd.randrange(size)
        for _ in range(rnd.randint(3, 5)):
            img.putpixel((x % size, y % size), WALL_VOID)
            x += rnd.choice((1, 0))
            y += 1
    # pontos de umidade brilhando
    for _ in range(5):
        x, y = rnd.randrange(size), rnd.randrange(size)
        if img.getpixel((x, y)) in (WALL, WALL_LIGHT):
            img.putpixel((x, y), WALL_WET)
    # musgo escorrendo
    for _ in range(3):
        x, y = rnd.randrange(size), rnd.randrange(size)
        for k in range(rnd.randint(2, 4)):
            img.putpixel((x, (y + k) % size), MOSS_DARK if k == 0 else MOSS_SHADOW)
    save(img, "wall_rock.png")


def build_torch():
    rows = [
        "...1..",
        "..21..",
        ".1321.",
        ".2432.",
        "124431",
        ".2443.",
        "..32..",
        "gGGGGg",
        ".gGGg.",
        "..Bb..",
        "..Bb..",
        "..rr..",
        "..Bb..",
        "..Bb..",
        "..Bb..",
        "..bd..",
        "..dd..",
    ]
    pal = {
        "1": TORCH_FLAME, "2": TORCH_GLOW, "3": TORCH_BRIGHT, "4": TORCH_CORE,
        "g": IRON_DARK, "G": IRON_LIGHT, "r": RUST,
        "B": WOOD_LIGHT, "b": WOOD_DARK, "d": WOOD_ROT,
    }
    img = pad(from_rows(rows, pal))
    # contorno: brasa vermelha na chama, tom escuro da madeira no cabo
    src = img.copy()
    outline(img, 0.5)
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3] == 0 and img.getpixel((x, y))[3] and y <= 7:
                img.putpixel((x, y), TORCH_EMBER)
    save(img, "torch.png")


def build_support():
    W, H = 26, 28
    rnd = random.Random(26)
    img = new(W, H)
    for x0 in (2, W - 6):
        wood_post(img, x0, 4, 4, H - 4, rnd)
    wood_beam(img, 0, 1, W, 4, rnd)
    # sombra da viga nos postes
    for x0 in (2, W - 6):
        for x in range(x0, x0 + 4):
            px(img, x, 5, WOOD_ROT)
            if (x + 6) & 1:
                px(img, x, 6, WOOD_DARK)
    # mãos-francesas
    for i in range(4):
        px(img, 6 + i, 5 + i, WOOD_LIGHT)
        px(img, 6 + i, 6 + i, WOOD_DARK)
        px(img, W - 7 - i, 5 + i, WOOD)
        px(img, W - 7 - i, 6 + i, WOOD_ROT)
    # chapas de ferro enferrujadas nos encaixes
    for x0 in (2, W - 6):
        rect(img, x0, 3, x0 + 3, 4, (RUST, RUST_DARK))
        nail(img, x0 + 1, 3)
    # musgo e terra na base dos postes
    for x0 in (2, W - 6):
        for x in range(x0, x0 + 4):
            for k in range(rnd.randint(1, 3)):
                px(img, x, H - 1 - k, dither(MOSS_RAMP, 0.5 - k * 0.2, x, H - 1 - k))
    save(outline(pad(img), 0.5), "support_beam.png")


def build_coin():
    rows = [
        "..DDDD..",
        ".DyyyYD.",
        "DyyYYYYD",
        "DyYyYYoD",
        "DyYyYYoD",
        "DYYYYooD",
        ".DYoooD.",
        "..DDDD..",
    ]
    pal = {"y": GOLD_HIGHLIGHT, "Y": GOLD_LIGHT, "o": GOLD, "D": GOLD_DARK}
    save(from_rows(rows, pal), "coin.png")


if __name__ == "__main__":
    build_coin()
    build_ipezinho()
    build_pickaxe()
    build_ores()
    build_crystals()
    build_shadow()
    build_armazem()
    build_casa()
    build_comedouro()
    build_floor()
    build_wall()
    build_torch()
    build_support()
