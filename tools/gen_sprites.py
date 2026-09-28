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
STONE_BLACK = (28, 25, 31, 255)  # Bloco 24: pedra esquentada (era cinza-azulado)
STONE_SHADOW = (41, 37, 45, 255)
STONE_DARK = (57, 52, 59, 255)
STONE = (76, 70, 75, 255)
STONE_LIGHT = (101, 94, 96, 255)
STONE_HIGHLIGHT = (136, 128, 124, 255)
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

COPPER_DARK = (116, 58, 42, 255)  # minério de cobre (acento quente, mas ainda gasto)
COPPER = (168, 94, 58, 255)
COPPER_LIGHT = (206, 132, 82, 255)
COPPER_GLINT = (238, 184, 128, 255)
VERDIGRIS = (76, 128, 112, 255)  # zinabre: a pátina verde do cobre
VERDIGRIS_LIGHT = (108, 160, 138, 255)
COPPER_RAMP = (COPPER_DARK, COPPER, COPPER_LIGHT, COPPER_GLINT)

COAL_DARK = (12, 12, 17, 255)  # carvão: preto azulado com brilho vítreo
COAL = (22, 22, 29, 255)
COAL_SHINE = (88, 94, 116, 255)
COAL_GLINT = (150, 158, 180, 255)
COAL_RAMP = (COAL_DARK, COAL, COAL, COAL_SHINE)
COAL_ROCK_RAMP = (COAL_DARK, COAL, (36, 38, 48, 255), (54, 58, 72, 255), COAL_SHINE, COAL_GLINT)  # rocha de carvão inteira

SILVER_DARK = (104, 112, 132, 255)  # prata: branca-azulada, o brilho mais forte da mina
SILVER = (156, 164, 182, 255)
SILVER_LIGHT = (206, 212, 226, 255)
SILVER_GLINT = (240, 244, 252, 255)
SILVER_RAMP = (SILVER_DARK, SILVER, SILVER_LIGHT, SILVER_GLINT)
DEEP_RAMP = ((14, 16, 24, 255), (22, 25, 36, 255), (31, 35, 48, 255), (42, 47, 62, 255), (56, 62, 80, 255))  # rocha do nível 2

STEEL_DARK = (66, 76, 96, 255)  # aço temperado (picareta nova)
STEEL = (104, 118, 138, 255)
STEEL_LIGHT = (160, 178, 196, 255)
STEEL_HIGHLIGHT = (216, 228, 238, 255)

IRON_SHADOW = (38, 40, 49, 255)
IRON_DARK = (60, 63, 73, 255)
IRON = (90, 93, 103, 255)
IRON_LIGHT = (128, 131, 139, 255)
IRON_HIGHLIGHT = (170, 172, 177, 255)
IRON_RAMP = (IRON_SHADOW, IRON_DARK, IRON, IRON_LIGHT, IRON_HIGHLIGHT)

SHADOW_INK = (6, 6, 12, 255)
BANDAGE = (214, 204, 184, 255)  # curativo (ícone de ipezinho machucado)
BANDAGE_SHADOW = (168, 156, 140, 255)
BLOOD = (178, 38, 40, 255)  # sinal de alerta: saturado de propósito
ANGER = (224, 58, 46, 255)  # "veia saltando" do ipezinho zangado (alerta: saturado)
ANGER_DARK = (138, 26, 30, 255)  # sombra projetada no chão (usada com alpha)

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

# roupas extras (variações dos ipezinhos) — mesmas regras: dessaturadas, gastas
SHIRT_MOSS = ((46, 64, 52, 255), (64, 86, 64, 255), (86, 108, 80, 255))  # (escuro, médio, claro)
SHIRT_OCHRE = ((106, 80, 44, 255), (142, 110, 58, 255), (172, 138, 78, 255))
BLOUSE_PLUM = ((72, 44, 62, 255), (100, 62, 82, 255), (128, 86, 104, 255))
BLOUSE_TEAL = ((40, 68, 72, 255), (56, 94, 96, 255), (78, 120, 118, 255))
BLOUSE_ROSE = ((114, 68, 68, 255), (146, 94, 90, 255), (174, 122, 112, 255))
CLOTH_DENIM = ((52, 62, 79, 255), (70, 84, 101, 255))  # (escuro, médio) — calça/saia
CLOTH_CANVAS = ((70, 54, 42, 255), (96, 76, 56, 255))
CLOTH_SLATE = ((56, 60, 72, 255), (78, 84, 96, 255))
CLOTH_MOSS = ((38, 52, 44, 255), (54, 72, 58, 255))
HAIR_BROWN = ((50, 34, 30, 255), (82, 56, 42, 255))  # (escuro, claro)
HAIR_BLACK = ((24, 22, 28, 255), (44, 40, 50, 255))
HAIR_AUBURN = ((84, 38, 30, 255), (122, 62, 42, 255))
HAIR_BLONDE = ((128, 104, 68, 255), (166, 138, 92, 255))

# superfície (clareira): mato escuro e pinheiros, ainda dessaturados
GRASS_RAMP = ((30, 44, 32, 255), (38, 58, 38, 255), (50, 74, 44, 255), (66, 92, 52, 255), (86, 110, 62, 255))  # Bloco 24: mais viva
PINE_RAMP = ((22, 36, 32, 255), (30, 48, 40, 255), (40, 62, 48, 255), (54, 78, 58, 255), (70, 94, 68, 255))
BARK_RAMP = ((40, 30, 26, 255), (58, 42, 34, 255), (78, 58, 44, 255), (98, 74, 54, 255))
WOOD_CUT = (170, 138, 96, 255)  # miolo claro da madeira cortada

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

# --- roupas/peles extras do Bloco 24 (mais variedade na colônia) ------------
SHIRT_SKY = ((58, 76, 98, 255), (80, 104, 128, 255), (110, 134, 152, 255))
SHIRT_BRICK = ((96, 44, 36, 255), (132, 64, 48, 255), (162, 92, 68, 255))
SHIRT_CREAM = ((140, 126, 100, 255), (176, 162, 132, 255), (206, 194, 164, 255))
BLOUSE_MUSTARD = ((118, 90, 40, 255), (158, 124, 56, 255), (190, 158, 86, 255))
BLOUSE_LAVENDER = ((88, 74, 110, 255), (118, 102, 140, 255), (148, 132, 166, 255))
BLOUSE_SAGE = ((72, 88, 66, 255), (100, 118, 88, 255), (132, 148, 112, 255))
CLOTH_BROWN = ((62, 44, 34, 255), (88, 64, 46, 255))
HAIR_GREY = ((92, 90, 96, 255), (138, 136, 140, 255))
HAIR_GINGER = ((130, 62, 30, 255), (176, 98, 50, 255))
# tons de pele: (sombra, escuro, base, bochecha)
SKIN_TONE_LIGHT = (SKIN_SHADOW, SKIN_DARK, SKIN, BLUSH)
SKIN_TONE_TAN = ((104, 64, 52, 255), (140, 92, 68, 255), (176, 124, 90, 255), (168, 90, 76, 255))
SKIN_TONE_DEEP = ((66, 40, 38, 255), (92, 58, 48, 255), (122, 82, 62, 255), (128, 66, 60, 255))
# acessórios (camadas por cima do corpo, sorteadas independente da roupa)
SCARF_RED = (APPLE_DARK, APPLE, APPLE_LIGHT)
SCARF_MUSTARD = BLOUSE_MUSTARD
SCARF_TEAL = ((44, 86, 80, 255), VERDIGRIS, VERDIGRIS_LIGHT)
BOOT_BLACK = ((28, 26, 32, 255), (52, 48, 56, 255))  # (escuro, claro)
BOOT_RED = ((92, 36, 34, 255), (140, 60, 50, 255))
BOOT_YELLOW = ((122, 94, 36, 255), (176, 140, 58, 255))  # galocha

# =================================================================== GRADAÇÃO
# Bloco 24: a paleta acima é a "fonte"; na hora de salvar, todo sprite passa por
# esta gradação de cor. É ela que dá o clima geral: meios-tons mais claros, luz
# puxada pro âmbar, sombra puxada pro roxo-azulado e mais contraste entre as duas
# (Stardew: cores levemente dessaturadas, mas luz/sombra bem separadas).
# Pra mudar o clima do jogo inteiro, mexa AQUI — não cor por cor.
GRADE_GAMMA = 0.82  # < 1 levanta os meios-tons
GRADE_CONTRAST = 1.18  # separa luz e sombra em torno de GRADE_PIVOT
GRADE_PIVOT = 0.40
GRADE_SHADOW_TINT = (0.97, 0.95, 1.05)  # multiplicador RGB nas sombras
GRADE_LIGHT_TINT = (1.07, 1.01, 0.90)  # multiplicador RGB nas luzes
GRADE_SAT = 1.10

# Ícones de HUD congelados: a pedra esquentou no Bloco 24, mas a interface fica igual.
HUD_STONE_DARK = (51, 53, 64, 255)

# Cores de fonte de luz: nunca são graduadas nem sombreadas (continuam "acesas").
EMISSIVE = {c[:3] for c in (
    *TORCH_RAMP, LAMP_GLOW, LAMP_CORE, WINDOW_DIM, WINDOW_LIT, WINDOW_BRIGHT,
    GOLD_LIGHT, GOLD_HIGHLIGHT, BLOOD, ANGER,
)}
# Sprites de interface/alerta: ficam bit a bit iguais (HUD está fora do escopo).
UNGRADED = {
    "coin.png", "anger.png", "bandage.png", "strike_sign.png", "note.png", "shadow_blob.png",
    "find_bobina.png", "find_cristal.png", "find_peca.png", "find_solar.png",
}
# Sprites que são fonte de luz inteira: não gradua (mas podem ganhar detalhe).
NO_GRADE = {"crystal_0.png", "crystal_1.png", "crystal_2.png", "crystal_3.png"}


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


def is_emissive(c):
    return c[:3] in EMISSIVE


def form_shade(img):
    """Sombreamento de forma (Bloco 24): dá volume sem redesenhar o sprite.
    A borda de baixo e a da direita da silhueta escurecem (lado da sombra /
    contato com o chão); a de cima e a da esquerda clareiam (lado da luz).
    Cores de fonte de luz ficam intactas."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            c = src.getpixel((x, y))
            if c[3] == 0 or is_emissive(c):
                continue
            if not opaque(src, x, y + 1):
                k = 0.80
            elif not opaque(src, x + 1, y):
                k = 0.87
            elif not opaque(src, x, y - 1) or not opaque(src, x - 1, y):
                k = 1.14
            else:
                continue
            img.putpixel((x, y), shade(c, k))
    return img


def outline(img, k=0.5, form=True, selout=True):
    """Contorno de 1px "colorido": cada pixel do contorno é a cor do vizinho
    opaco, escurecida por shade(). Nada de preto puro.

    Bloco 24: contorno "selout" — no lado da luz (cima/esquerda) ele é mais
    claro, no lado da sombra (baixo/direita) mais escuro; separa melhor do fundo
    sem ficar pesado. `form=True` aplica também form_shade() antes (sprites
    minúsculos, até 10px, e pedras — que já têm luz própria — passam form=False)."""
    if form and max(img.width, img.height) > 10:
        form_shade(img)
    src = img.copy()
    k_lit = min(0.9, k + 0.16) if selout else k
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3] != 0:
                continue
            lit, dark = [], []
            for dx, dy in ((0, 1), (1, 0), (0, -1), (-1, 0)):
                if opaque(src, x + dx, y + dy):
                    # vizinho embaixo/à direita = este pixel está no topo/esquerda da forma
                    (lit if (dx, dy) in ((0, 1), (1, 0)) else dark).append(src.getpixel((x + dx, y + dy)))
            neigh = (dark or lit) if selout else dark + lit
            if neigh:
                avg = tuple(sum(c[i] for c in neigh) // len(neigh) for i in range(3)) + (255,)
                img.putpixel((x, y), shade(avg, k if dark else k_lit))
    return img


_GRADE_CACHE = {}


def _smooth(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def grade_color(c):
    """Gradação da paleta (ver GRADE_* lá em cima). Mantém o alpha."""
    if c[3] == 0 or is_emissive(c):
        return c
    hit = _GRADE_CACHE.get(c)
    if hit:
        return hit
    r, g, b = (v / 255 for v in c[:3])
    v = max(r, g, b)
    w = _smooth(0.12, 0.65, v)
    tint = [GRADE_SHADOW_TINT[i] + (GRADE_LIGHT_TINT[i] - GRADE_SHADOW_TINT[i]) * w for i in range(3)]
    r, g, b = min(1.0, r * tint[0]), min(1.0, g * tint[1]), min(1.0, b * tint[2])
    h, s, _ = colorsys.rgb_to_hsv(r, g, b)
    v2 = max(0.0, min(1.0, GRADE_PIVOT + (v ** GRADE_GAMMA - GRADE_PIVOT) * GRADE_CONTRAST))
    r, g, b = colorsys.hsv_to_rgb(h, min(1.0, s * GRADE_SAT), v2)
    out = (round(r * 255), round(g * 255), round(b * 255), c[3])
    _GRADE_CACHE[c] = out
    return out


def grade(img):
    out = img.copy()
    data = img.get_flattened_data() if hasattr(img, "get_flattened_data") else img.getdata()
    out.putdata([grade_color(c) for c in data])
    return out


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
    if name not in UNGRADED and name not in NO_GRADE:
        img = grade(img)
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


IRON_VEIN = (RUST_ACCENT, RUST_LIGHT, RUST, RUST_DARK, RUST_GLINT)
COPPER_VEIN = (COPPER_LIGHT, COPPER, COPPER, COPPER_DARK, COPPER_GLINT)
SILVER_VEIN = (SILVER_GLINT, SILVER_LIGHT, SILVER, SILVER_DARK, SILVER_GLINT)
COAL_VEIN = (COAL_GLINT, COAL_SHINE, COAL_DARK, COAL_DARK, (200, 208, 226, 255))  # facetas vítreas


def rock(w, h, seed, ramp=STONE_RAMP, ore=0, moss=0.0, cracks=1, bright=0.0, vein=IRON_VEIN, specks=()):
    """Pedra com facetas, luz de cima-esquerda, sombra de contato na base,
    rachaduras, veios de minério (`ore` = nº de pepitas, cores em `vein`:
    acento, claro, médio, escuro, brilho), pontinhos extras (`specks`, ex.:
    zinabre do cobre) e musgo no topo. Deixa 1px livre em volta pro contorno."""
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
        img.putpixel((x, y), vein[0])
        img.putpixel((x + 1, y), vein[1])
        img.putpixel((x, y + 1), vein[2])
        img.putpixel((x + 1, y + 1), vein[3])
        if rnd.random() < 0.6:
            img.putpixel((x, y), vein[4])

    # pontinhos extras (sorteados por último: não mudam as pedras que não usam)
    for c in specks:
        for _ in range(6):
            x, y = rnd.choice(inner)
            img.putpixel((x, y), c)

    return outline(img, 0.55, form=False)  # a pedra já tem luz própria (lambert + facetas)


# =================================================================== sprites
# ------------------------------------------------------------ ipezinho
# Capacete, lanterna e rosto são IGUAIS nos dois (equipamento de mineração);
# muda o cabelo que aparece por baixo do capacete e a roupa.
IPEZINHO_HELMET = [  # 16 colunas; linha 0 fica livre pro contorno
    "................",
    "......kkHh......",
    "....kkHHHHXh....",
    "...kHHgYYgHHh...",
    "...kHHgWYgHXh...",
    "..hhhhhgghhhhh..",
]
# menino: costeletas curtas sob a aba, camisa + macacão, cinto com fivela
IPEZINHO_UPPER = IPEZINHO_HELMET + [
    "...assssssssa...",
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
# menina: tranças caindo dos lados do rosto até os ombros (fitinha na ponta),
# vestido de trabalho com avental e saia rodada comprida até as botas
IPEZINHA_UPPER = IPEZINHO_HELMET + [
    "..aAssssssssAa..",
    "..ASSeSSSSeSsA..",
    "..ASSeSSSSeSsa..",
    "..aSrSSmmSSrsa..",
    "..AFFCCCCCCFFa..",
    "..tFFcCCCCcFFt..",
    "..SsuZCCCCZuSs..",
    "..cCCCZZZZCCCc..",
]
IPEZINHA_LEG = "...cCCc..cCCc..."  # barra da saia (balança com o passo)
IPEZINHO_PAL = {
    "k": HELMET_HIGHLIGHT, "H": HELMET_LIGHT, "h": HELMET_DARK, "X": (HELMET_LIGHT, HELMET),
    "g": IRON_DARK, "Y": LAMP_GLOW, "W": LAMP_CORE,
    "s": SKIN_DARK, "S": SKIN, "e": EYE, "r": BLUSH, "m": SKIN_SHADOW,
    "F": FLANNEL_LIGHT, "f": FLANNEL, "u": FLANNEL_DARK,
    "C": DENIM, "c": DENIM_DARK, "Z": (DENIM, DENIM_DARK),
    "T": LEATHER, "b": BRASS,
    "L": LEATHER_LIGHT, "l": LEATHER_DARK,
}


# Variações por gênero: (camisa/blusa, calça/saia, cabelo, fita, pele).
# As 3 primeiras de cada são as do Bloco 11 (o índice "look" do save continua
# apontando pra mesma roupa); 3 a 5 são do Bloco 24, com tons de pele variados.
IPEZINHO_LOOKS = {
    "m": [
        ((FLANNEL_DARK, FLANNEL, FLANNEL_LIGHT), CLOTH_DENIM, HAIR_BROWN, None, SKIN_TONE_LIGHT),
        (SHIRT_MOSS, CLOTH_CANVAS, HAIR_BLACK, None, SKIN_TONE_LIGHT),
        (SHIRT_OCHRE, CLOTH_SLATE, HAIR_AUBURN, None, SKIN_TONE_LIGHT),
        (SHIRT_SKY, CLOTH_CANVAS, HAIR_BLONDE, None, SKIN_TONE_TAN),
        (SHIRT_BRICK, CLOTH_MOSS, HAIR_BLACK, None, SKIN_TONE_DEEP),
        (SHIRT_CREAM, CLOTH_BROWN, HAIR_GREY, None, SKIN_TONE_LIGHT),
    ],
    "f": [
        (BLOUSE_PLUM, CLOTH_DENIM, HAIR_AUBURN, SHROOM, SKIN_TONE_LIGHT),
        (BLOUSE_TEAL, CLOTH_CANVAS, HAIR_BLONDE, BRASS, SKIN_TONE_LIGHT),
        (BLOUSE_ROSE, CLOTH_MOSS, HAIR_BLACK, FLANNEL_LIGHT, SKIN_TONE_LIGHT),
        (BLOUSE_MUSTARD, CLOTH_SLATE, HAIR_BROWN, VERDIGRIS_LIGHT, SKIN_TONE_TAN),
        (BLOUSE_LAVENDER, CLOTH_CANVAS, HAIR_BLACK, BLOUSE_ROSE[2], SKIN_TONE_DEEP),
        (BLOUSE_SAGE, CLOTH_DENIM, HAIR_GINGER, BREAD_HIGHLIGHT, SKIN_TONE_LIGHT),
    ],
}


# ------------------------------------------------------------ outfits por função (Bloco 26)
# Cada outfit troca a CABEÇA (linhas 0-5: capacete / gorro / chapéu / cabelo) e o
# RECHEIO do tronco (linhas 10-13), mas mantém a mesma silhueta do tronco, das pernas e
# dos pés — por isso lenço, remendo/bolso e botas (Bloco 24) encaixam em todos.
# Linhas 6-9 (rosto) vêm do mineiro, exceto no civil (sem aba: testa iluminada).
# Outfit novo (guarda, pesquisador...) = mais uma entrada em IPEZINHO_OUTFITS
# + a paleta dele em _outfit_pal() + o mapeamento função -> outfit no ipezinho.gd.
_FACE_M = IPEZINHO_UPPER[6:10]
_FACE_F = IPEZINHA_UPPER[6:10]
_BEANIE = [  # gorro de lã com pompom e barra dobrada (lenhador)
    "................",
    ".......oN.......",
    ".....nNNNNn.....",
    "....nNoNNoNn....",
    "...nNNNNNNNNn...",
    "...RRRRRRRRRR...",
]
_TOQUE = [  # chapéu de cozinheiro: copa fofa + faixa
    "................",
    "....qQQQQQQq....",
    "...qQQQQQQQQq...",
    "...qQQQQQQQQq...",
    "....qQQQQQQq....",
    "....jjjjjjjj....",
]
IPEZINHO_OUTFITS = {
    # lenhador: gorro, flanela xadrez, suspensórios de couro, manga arregaçada
    "lenhador": {
        "m": _BEANIE + _FACE_M + [
            "..fFFTFFFFTFFu..",
            "..SSGTGGGGTGSs..",
            "..SsFTFFFFTFSs..",
            "...cTTTbbTTTc...",
        ],
        "f": _BEANIE + _FACE_F + [
            "..AFFTFFFFTFFa..",
            "..tSGTGGGGTGSt..",
            "..SsFTFFFFTFSs..",
            "..cCTTTbbTTTCc..",
        ],
    },
    # cozinheiro: chapéu branco (sem capacete por baixo) + avental branco sobre a roupa
    "cozinheiro": {
        "m": _TOQUE + _FACE_M + [
            "..fFFQQQQQQFFu..",
            "..fFFqQQQQqFFu..",
            "..SsuQQQQQQuSs..",
            "...cTQQQQQQTc...",
        ],
        "f": _TOQUE + _FACE_F + [
            "..AFFQQQQQQFFa..",
            "..tFFqQQQQqFFt..",
            "..SsuQQQQQQuSs..",
            "..cCQQQQQQQQCc..",
        ],
    },
    # civil (ocioso): cabelo à mostra, camisa/blusa abotoada, sem equipamento nem lanterna
    "civil": {
        "m": [
            "................",
            "................",
            "................",
            "....aAAAAAAa....",
            "...aAAAAAAAAa...",
            "...aAaAAAAaAa...",
            "...aSSSSSSSSa...",
        ] + _FACE_M[1:] + [
            "..fFFFFSsFFFFu..",
            "..fFFFFbFFFFFu..",
            "..SsuFFFFFFuSs..",
            "...cTTTbbTTTc...",
        ],
        "f": [
            "................",
            "................",
            "................",
            "....aAAAAAAa....",
            "...aAAAAAAAAa...",
            "..aAAaAAAAaAAa..",
            "..aASSSSSSSSAa..",
        ] + _FACE_F[1:] + [
            "..AFFFFSsFFFFa..",
            "..tFFFFbFFFFFt..",
            "..SsuFFFFFFuSs..",
            "..cCCCCCCCCCCc..",
        ],
    },
}
BEANIE_COLORS = (  # (escuro, médio, claro) — sorteado pela variação, pra colônia não ficar uniforme
    ((36, 70, 52, 255), (52, 96, 68, 255), (76, 122, 88, 255)),  # verde-mata
    ((110, 40, 34, 255), (150, 60, 44, 255), (182, 90, 62, 255)),  # vermelho-ferrugem
    ((120, 92, 36, 255), (160, 124, 50, 255), (194, 160, 80, 255)),  # mostarda
)
CHEF_WHITE = (236, 232, 222, 255)
CHEF_SHADE = (196, 190, 178, 255)
CHEF_BAND = (160, 154, 142, 255)


def _outfit_pal(outfit, look_index, shirt):
    if outfit == "lenhador":
        dark, mid, light = BEANIE_COLORS[look_index % len(BEANIE_COLORS)]
        return {
            "n": dark, "N": mid, "o": light, "R": shade(dark, 0.85),
            "F": (shirt[2], shirt[0]),  # xadrez da flanela (nas cores da camisa da variação)
            "G": shirt[1],
        }
    if outfit == "cozinheiro":
        return {"Q": CHEF_WHITE, "q": CHEF_SHADE, "j": CHEF_BAND}
    return {}


def build_ipezinho():
    """Gera os corpos: 4 outfits x 2 gêneros x 6 variações, mesmo layout de 4 quadros.
    Mineiro (capacete + lanterna): ipezinho_m0..5.png / ipezinho_f0..5.png — os nomes de
    sempre (ipezinho_walk.png = m0, padrão da cena). Os outros: ipezinho_<outfit>_m0.png etc."""
    for gender, looks in IPEZINHO_LOOKS.items():
        for i, (shirt, cloth, hair, ribbon, skin) in enumerate(looks):
            pal = {
                **IPEZINHO_PAL,
                "u": shirt[0], "f": shirt[1], "F": shirt[2],
                "c": cloth[0], "C": cloth[1], "Z": (cloth[1], cloth[0]),
                "a": hair[0], "A": hair[1],
                "t": ribbon or hair[0],
                "m": skin[0], "s": skin[1], "S": skin[2], "r": skin[3],
            }
            leg = IPEZINHO_LEG if gender == "m" else IPEZINHA_LEG
            upper = IPEZINHO_UPPER if gender == "m" else IPEZINHA_UPPER
            sheet = ipezinho_sheet(upper, leg, IPEZINHO_FOOT, pal)
            save(sheet, f"ipezinho_{gender}{i}.png")
            if gender == "m" and i == 0:
                save(sheet, "ipezinho_walk.png")
            for outfit, rows in IPEZINHO_OUTFITS.items():
                opal = {**pal, **_outfit_pal(outfit, i, shirt)}
                save(ipezinho_sheet(rows[gender], leg, IPEZINHO_FOOT, opal), f"ipezinho_{outfit}_{gender}{i}.png")


def side_light(img, first_row, x0=3, x1=12, strength=0.16):
    """Luz lateral (Bloco 24): da esquerda (lado da luz) pra direita (sombra),
    do `first_row` pra baixo — cada peça de roupa/rosto deixa de ser um tom só."""
    for y in range(first_row, img.height):
        for x in range(img.width):
            c = img.getpixel((x, y))
            if c[3] == 0 or is_emissive(c):
                continue
            u = max(0.0, min(1.0, (x - x0) / (x1 - x0)))
            k = 1 + strength * 0.5 - strength * u
            if abs(k - 1) > 0.02:
                img.putpixel((x, y), shade(c, k))
    return img


def ipezinho_sheet(upper_rows, leg_row, foot_row, pal):
    upper = side_light(from_rows(upper_rows, pal), first_row=6)  # linha 6 = abaixo do capacete
    leg = from_rows([leg_row], pal)
    foot = from_rows([foot_row], pal)

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
    return sheet


# ------------------------------------------------------------ acessórios do ipezinho
# Camadas desenhadas por cima do corpo (nós Body/Neck, Body/Detail, Body/Boots na
# cena). Cada folha tem 4 colunas (os mesmos quadros de caminhada do corpo) e uma
# linha por variante. Servem pros meninos e pras meninas: as posições usadas
# (pescoço, peito/avental, botas) são iguais nos dois layouts.
# Coordenadas no quadro "parado"; nos quadros 1 e 3 o corpo sobe 1px (lift).
WALK_LIFT = (0, 1, 0, 1)
WALK_FOOT_UP = ((False, False), (False, True), (False, False), (True, False))  # (esquerdo, direito)


def _acc_sheet(variants, draw):
    sheet = new(16 * 4, 17 * len(variants))
    for v, colors in enumerate(variants):
        for f in range(4):
            frame = new(16, 17)
            draw(frame, colors, f)
            sheet.alpha_composite(frame, (f * 16, v * 17))
    return sheet


def build_ipezinho_accessories():
    # lenço no pescoço: faixa sobre a gola + pontinha do nó
    def neck(img, c, f):
        y = 10 - WALK_LIFT[f]
        dark, mid, light = c
        px(img, 5, y, light)
        rect(img, 6, y, 9, y, mid)
        px(img, 10, y, dark)
        px(img, 7, y + 1, mid)
        px(img, 8, y + 1, dark)
    save(_acc_sheet((SCARF_RED, SCARF_MUSTARD, SCARF_TEAL), neck), "acc_neck.png")

    # detalhe na roupa: remendo de lona, remendo xadrez, bolso (costura escura translúcida:
    # funciona em cima de qualquer cor de roupa)
    def detail(img, c, f):
        y = 11 - WALK_LIFT[f]
        if c == "pocket":
            seam = SHADOW_INK[:3] + (120,)
            rect(img, 6, y, 7, y, seam)
            px(img, 7, y + 1, SHADOW_INK[:3] + (70,))
            return
        a, b = c
        rect(img, 8, y, 9, y + 1, (a, b))  # xadrez
        px(img, 9, y, SHIRT_CREAM[2])  # pontinho da costura
    save(_acc_sheet(((SHIRT_OCHRE[1], SHIRT_OCHRE[2]), (FLANNEL_LIGHT, FLANNEL_DARK), "pocket"), detail),
         "acc_detail.png")

    # botas de outra cor: repinta exatamente os pixels do pé do corpo
    # (mesmo formato de IPEZINHO_FOOT e a mesma sombra de base do form_shade)
    def boots(img, c, f):
        dark, light = shade(c[0], 0.80), shade(c[1], 0.80)
        for x0, up in ((3, WALK_FOOT_UP[f][0]), (9, WALK_FOOT_UP[f][1])):
            y = 14 if (WALK_LIFT[f] and up) else 15
            rect(img, x0, y, x0 + 2, y, light)
            px(img, x0 + 3, y, dark)
    save(_acc_sheet((BOOT_BLACK, BOOT_RED, BOOT_YELLOW), boots), "acc_boots.png")


def build_pickaxe_steel():
    """Picareta de aço temperado (desbloqueia cobre): mesmo desenho, cabeça azulada."""
    rows = [
        "..LLGGGDD..",
        ".LG.hBh.GD.",
        "LG...Bb...D",
        "L....Bb...d",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....Bb....",
        ".....yy....",
        ".....Bb....",
        ".....ww....",
        ".....Ww....",
        ".....bb....",
    ]
    pal = {
        "L": STEEL_HIGHLIGHT, "G": STEEL_LIGHT, "D": STEEL, "d": STEEL_DARK, "h": STEEL_DARK,
        "B": WOOD_HIGHLIGHT, "b": WOOD_DARK, "y": BRASS,  # anel de latão no cabo
        "W": LEATHER_LIGHT, "w": LEATHER,
    }
    save(from_rows(rows, pal), "pickaxe_aco.png")


def build_padlock():
    """Cadeado sobre jazidas que ainda precisam de ferramenta."""
    rows = [
        ".sSs.",
        "s...S",
        "s...S",
        "BBBBb",
        "BBkBb",
        "BBkBb",
        "bbbbb",
    ]
    pal = {"s": IRON_HIGHLIGHT, "S": IRON, "B": BRASS, "b": shade(BRASS, 0.7), "k": IRON_SHADOW}
    save(outline(pad(from_rows(rows, pal)), 0.5), "cadeado.png")


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
def ore_chunk(w, h, seed, ramp=RUST_RAMP, speck=STONE_DARK, glint=RUST_GLINT):
    """Pedaço de minério (ícone de carga / HUD / pilha do armazém). Padrão = ferro."""
    rnd = random.Random(seed)
    img = new(w, h)
    cx, cy = (w - 1) / 2, (h - 1) / 2 + 0.3
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            nx, ny = (x - cx) / ((w - 2) / 2), (y - cy) / ((h - 2) / 2)
            if nx * nx + ny * ny <= 1.05 + rnd.uniform(-0.12, 0.05):
                t = 0.55 - 0.45 * nx - 0.55 * ny
                img.putpixel((x, y), dither(ramp, t, x, y))
    # pontinhos de rocha escura e um brilho
    for _ in range(max(1, (w * h) // 25)):
        x, y = rnd.randrange(1, w - 1), rnd.randrange(1, h - 1)
        if opaque(img, x, y):
            img.putpixel((x, y), speck)
    for y in range(h):
        for x in range(w):
            if opaque(img, x, y) and not opaque(img, x, y - 1) and not opaque(img, x - 1, y):
                img.putpixel((x, y), glint)
                break
        else:
            continue
        break
    return outline(img, 0.5)


def build_ores():
    for i, (seed, n) in enumerate(((101, 4), (202, 5), (303, 4))):
        save(rock(16, 16, seed, ramp=STONE_RAMP, ore=n, moss=0.0, cracks=1, bright=-0.04), f"ore_iron_{i}.png")
    save(trim(ore_chunk(9, 8, 5)), "ore_chunk.png")
    # cobre: pepitas cor de cobre + zinabre verde
    for i, (seed, n) in enumerate(((401, 6), (402, 7), (403, 6))):
        save(rock(16, 16, seed, ore=n, cracks=1, bright=-0.02, vein=COPPER_VEIN,
                  specks=(VERDIGRIS, VERDIGRIS_LIGHT)), f"ore_cobre_{i}.png")
    save(trim(ore_chunk(9, 8, 6, ramp=COPPER_RAMP, speck=VERDIGRIS, glint=COPPER_GLINT)), "chunk_cobre.png")
    # carvão: rocha mais escura cheia de pedaços pretos brilhantes
    for i, (seed, n) in enumerate(((501, 4), (502, 5), (503, 4))):
        save(rock(16, 16, seed, ramp=COAL_ROCK_RAMP, ore=n, cracks=2, bright=-0.05, vein=COAL_VEIN), f"ore_carvao_{i}.png")
    save(trim(ore_chunk(9, 8, 7, ramp=COAL_RAMP, speck=COAL_DARK, glint=COAL_GLINT)), "chunk_carvao.png")
    # prata (nível 2): rocha funda e escura com veios brancos brilhantes
    for i, (seed, n) in enumerate(((601, 5), (602, 6), (603, 5))):
        save(rock(16, 16, seed, ramp=DEEP_RAMP, ore=n, cracks=2, bright=0.08, vein=SILVER_VEIN,
                  specks=(SILVER_LIGHT,)), f"ore_prata_{i}.png")
    save(trim(ore_chunk(9, 8, 8, ramp=SILVER_RAMP, speck=SILVER_DARK, glint=SILVER_GLINT)), "chunk_prata.png")

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
        save(crystal_sparkle(recolor_dark_outline(trim(tile(sheet, col, row, 32))), i), f"crystal_{i}.png")


def crystal_sparkle(img, seed):
    """Bloco 24: brilhinho em estrela nas facetas mais claras (1-2 por cristal).
    Só pinta por cima de pixels já opacos: o tamanho do sprite não muda."""
    rnd = random.Random(900 + seed)
    spots = sorted(((luminance(img.getpixel((x, y))), x, y)
                    for y in range(2, img.height - 2) for x in range(2, img.width - 2)
                    if all(opaque(img, x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))),
                   reverse=True)
    placed = []
    for _, x, y in spots:
        if len(placed) >= 1 + rnd.randrange(2):
            break
        if any(abs(x - a) + abs(y - b) < 6 for a, b in placed):
            continue
        placed.append((x, y))
        img.putpixel((x, y), (255, 255, 255, 255))
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            c = img.getpixel((x + dx, y + dy))
            img.putpixel((x + dx, y + dy), tuple(min(255, (v + 255) // 2) for v in c[:3]) + (255,))
    return img


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


def plank_grain(img, x, y0, y1, rnd):
    """Veio de madeira numa coluna de tábua já pintada (Bloco 24): riscos curtos
    escurecendo o tom que já está ali (não quebra o dithering) e, às vezes, um nó."""
    y = y0 + rnd.randrange(2)
    while y <= y1:
        run = rnd.randint(2, 4)
        for k in range(run):
            if y + k <= y1 and opaque(img, x, y + k):
                img.putpixel((x, y + k), shade(img.getpixel((x, y + k)), 0.82))
        y += run + rnd.randint(2, 5)
    if rnd.random() < 0.3 and y1 - y0 > 3:
        ky = rnd.randint(y0 + 1, y1 - 1)
        px(img, x, ky, WOOD_ROT)
        px(img, x, ky - 1, WOOD_HIGHLIGHT)


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
    grain_rnd = random.Random(361)  # rnd separado: não muda o resto do armazém
    for x in range(2, W - 2):
        if (x - 2) % 4 == 2:
            plank_grain(img, x, 15, 27, grain_rnd)
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
    """Casinha de pedra e tábua com telhado de ardósia. 3 quadros lado a lado:
    0 = vazia (janelas escuras), 1 = alguém dormindo (janelas acesas),
    2 = lote ainda não construído (estacas, corda, madeira e pedras)."""
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
                # blocos de pedra em fiadas de 2px, juntas desencontradas;
                # face de cima de cada bloco pega luz, a de baixo fica na sombra
                course, top = (y - 18) // 2, (y - 18) % 2 == 0
                if (x + course * 2) % 4 == 0:
                    t = 0.06
                else:
                    t = (0.64 if top else 0.40) - course * 0.06
                c = dither(STONE_RAMP, t, x, y)
            elif (x - 2) % 3 == 0:
                c = WOOD_ROT
            else:
                c = dither(WOOD_RAMP, 0.55 - ((x - 2) % 3 - 1) * 0.12, x, y)
            base.putpixel((x, y), c)
    grain_rnd = random.Random(281)
    for x in range(2, W - 2):
        if (x - 2) % 3 == 2:
            plank_grain(base, x, 13, 17, grain_rnd)
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
    frames.append(casa_lot(W, H))

    sheet = new(frames[0].width * len(frames), frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "casa.png")


def casa_lot(W, H):
    """Lote da casa ainda por construir: baixo, pra ler como "canteiro" no chão."""
    rnd = random.Random(29)
    img = new(W, H)
    # corda entre as estacas (frente e fundo)
    for x in range(3, W - 3):
        px(img, x, 14, LEATHER_LIGHT if x % 3 else LEATHER)
        px(img, x, 21 + (1 if 8 < x < W - 9 else 0), LEATHER_LIGHT if x % 3 else LEATHER)
    # estacas
    for sx, top in ((2, 11), (W - 3, 11), (2, 18), (W - 3, 18)):
        for y in range(top, top + 6):
            px(img, sx, y, WOOD_LIGHT)
            px(img, sx + 1, y, WOOD_DARK)
        px(img, sx, top, WOOD_HIGHLIGHT)
    # pilha de tábuas
    for i, y in enumerate((20, 18, 16)):
        x0 = 5 + i
        for x in range(x0, x0 + 9):
            px(img, x, y, dither(WOOD_RAMP, 0.7 - (x - x0) * 0.03, x, y))
            px(img, x, y + 1, WOOD_DARK)
        px(img, x0, y, WOOD_ROT)
    # pedras empilhadas
    for cx, cy, r in ((20, 20, 2.2), (23, 20, 2.0), (21, 17, 1.8)):
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    px(img, x, y, dither(STONE_RAMP, 0.6 - (y - cy) * 0.15 - (x - cx) * 0.05, x, y))
    # plaquinha do lote
    rect(img, 14, 12, 14, 19, WOOD_DARK)
    rect(img, 12, 9, 17, 12, WOOD_LIGHT)
    rect(img, 12, 12, 17, 12, WOOD_DARK)
    px(img, 13, 10, WOOD_ROT)
    px(img, 15, 10, WOOD_ROT)
    px(img, 16, 11, WOOD_ROT)
    # tufos de musgo no chão batido
    for _ in range(5):
        x, y = rnd.randrange(4, W - 4), rnd.randrange(15, 21)
        if not opaque(img, x, y):
            px(img, x, y, MOSS_DARK)
    return outline(pad(img), 0.5)


# ------------------------------------------------------------ centro da vila
def build_centro_vila():
    """Prédio principal: salão de enxaimel com torre do sino. 3 quadros por estágio:
    0 = começo (torre vazia), 1 = sino + estandartes, 2 = lanternas + ponta dourada."""
    W, H = 56, 48
    rnd = random.Random(56)
    base = new(W, H)

    # telhado principal de ardósia (trapézio), cumeeira de ferro enferrujado
    for y in range(12, 25):
        inset = round((24 - y) * 8 / 12)
        for x in range(inset, W - inset):
            t = 0.55 - (y - 12) * 0.02
            if (y - 12) % 3 == 2:
                t -= 0.2
            elif (x + ((y - 12) // 3) * 2) % 5 == 0:
                t = 0.12
            c = dither(STONE_RAMP, t, x, y)
            if rnd.random() < 0.08 + (y - 12) * 0.012:
                c = dither(MOSS_RAMP, t + 0.1, x, y)
            base.putpixel((x, y), c)
    rect(base, 8, 12, W - 9, 12, RUST_DARK)
    for x in range(9, W - 9, 4):
        px(base, x, 12, RUST_LIGHT)
    rect(base, 0, 24, W - 1, 24, STONE_BLACK)  # beiral

    # paredes: enxaimel (vigas escuras sobre reboco encardido) em cima, pedra embaixo
    for y in range(25, 42):
        for x in range(2, W - 2):
            if y >= 36:
                t = 0.5 if (x + (y % 2) * 3) % 6 else 0.1
                c = dither(STONE_RAMP, t - (y - 36) * 0.05, x, y)
            else:
                c = dither(EARTH_RAMP, 0.95 - (y - 25) * 0.03, x, y)  # reboco velho
            base.putpixel((x, y), c)
    for x in range(2, W - 2):
        px(base, x, 25, WOOD_ROT)
        if x & 1:
            px(base, x, 26, WOOD_DARK)
        px(base, x, 35, WOOD_DARK)
    for vx in (2, 11, 20, 35, 44, W - 3):
        rect(base, vx, 25, vx, 35, WOOD_DARK)
    for x0, x1 in ((2, 11), (44, W - 3)):  # travessas diagonais do enxaimel
        for i in range(x1 - x0 + 1):
            px(base, x0 + i, 26 + round(i * 9 / (x1 - x0)), WOOD)

    # janelas sempre acesas (é o coração da vila)
    for wx in (14, 37):
        rect(base, wx, 27, wx + 4, 32, WOOD_ROT)
        rect(base, wx + 1, 28, wx + 3, 31, WINDOW_LIT)
        px(base, wx + 1, 28, WINDOW_BRIGHT)
        rect(base, wx + 1, 31, wx + 3, 31, WINDOW_DIM)
        rect(base, wx + 2, 28, wx + 2, 31, WOOD_DARK)
        rect(base, wx, 32, wx + 4, 32, WOOD_LIGHT)
        for x in range(wx, wx + 5):
            if x & 1:
                px(base, x, 33, shade(WINDOW_DIM, 0.55))

    # torre do sino (na frente do telhado)
    tx0, tx1 = 22, 33
    for y in range(9, 25):
        for x in range(tx0, tx1 + 1):
            t = 0.6 - (x - tx0) * 0.05
            base.putpixel((x, y), dither(WOOD_RAMP, t, x, y))
    rect(base, tx0, 9, tx0, 24, WOOD_ROT)
    rect(base, tx1, 9, tx1, 24, WOOD_ROT)
    rect(base, tx0, 17, tx1, 17, WOOD_DARK)
    # vão do sino
    rect(base, tx0 + 2, 11, tx1 - 2, 16, WALL_VOID)
    rect(base, tx0 + 2, 11, tx1 - 2, 11, WALL_SHADOW)
    # relógio redondo abaixo do vão
    for y in range(19, 24):
        for x in range(25, 31):
            if (x - 27.5) ** 2 + (y - 21) ** 2 <= 7:
                px(base, x, y, IRON_LIGHT if y < 21 else IRON)
    px(base, 27, 20, IRON_SHADOW)
    px(base, 28, 21, IRON_SHADOW)
    # telhado pontudo da torre
    for y in range(0, 9):
        half = 1 + y * 0.8
        for x in range(round(27.5 - half), round(27.5 + half) + 1):
            t = 0.65 if x < 27.5 else 0.3
            px(base, x, y, dither(STONE_RAMP, t - y * 0.02, x, y))
    rect(base, tx0 - 1, 8, tx1 + 1, 8, STONE_BLACK)

    # portão principal (duplo, arredondado, com cintas de ferro)
    dx0, dx1 = 23, 32
    for y in range(29, 42):
        for x in range(dx0, dx1 + 1):
            if y == 29 and x in (dx0, dx0 + 1, dx1 - 1, dx1):
                continue
            if y == 30 and x in (dx0, dx1):
                continue
            t = 0.5 if x < (dx0 + dx1) / 2 else 0.35
            px(base, x, y, dither(WOOD_RAMP, t, x, y))
    rect(base, 27, 30, 28, 41, WOOD_ROT)
    for by in (32, 38):
        rect(base, dx0, by, dx1, by, (IRON, IRON_DARK))
    px(base, 26, 35, BRASS)
    px(base, 29, 35, BRASS)
    # placa acima do portão: picaretas cruzadas
    rect(base, 21, 25, 34, 28, WOOD_LIGHT)
    rect(base, 21, 25, 34, 25, WOOD_HIGHLIGHT)
    rect(base, 21, 28, 34, 28, WOOD_DARK)
    for i in range(4):
        px(base, 25 + i, 26 + (i // 2), IRON_HIGHLIGHT if i < 2 else WOOD_DARK)
        px(base, 30 - i, 26 + (i // 2), IRON_HIGHLIGHT if i < 2 else WOOD_DARK)

    # fundação + escadaria
    for x in range(1, W - 1):
        for y in (42, 43):
            px(base, x, y, dither(STONE_RAMP, 0.45 if y == 42 else 0.25, x, y))
    for i, y in enumerate((44, 45, 46)):
        rect(base, 21 - i, y, 34 + i, y, (STONE_LIGHT, STONE, STONE_DARK)[i])

    frames = []
    for tier in range(3):
        img = base.copy()
        if tier >= 1:
            # sino de bronze no vão
            for y in range(12, 16):
                w = 1 + (y - 12)
                for x in range(28 - w // 2 - 1, 28 + w // 2 + 1):
                    px(img, x, y, GOLD if x < 28 else GOLD_DARK)
            px(img, 27, 12, GOLD_LIGHT)
            px(img, 27, 11, IRON_DARK)
            # estandartes pendurados nas pontas da fachada
            for bx in (4, W - 7):
                rect(img, bx, 26, bx + 2, 33, FLANNEL)
                rect(img, bx, 26, bx, 33, FLANNEL_LIGHT)
                px(img, bx + 1, 34, FLANNEL_DARK)
                px(img, bx + 1, 29, GOLD)  # emblema
                rect(img, bx - 1, 25, bx + 3, 25, WOOD_DARK)  # varão
        if tier >= 2:
            # lanternas acesas ladeando o portão
            for lx in (19, 36):
                px(img, lx, 29, IRON_DARK)
                rect(img, lx - 1, 30, lx + 1, 30, IRON)
                rect(img, lx - 1, 31, lx + 1, 32, LAMP_GLOW)
                px(img, lx, 31, LAMP_CORE)
                rect(img, lx - 1, 33, lx + 1, 33, IRON_DARK)
            # ponta dourada na torre e friso dourado na placa
            px(img, 27, 0, GOLD_HIGHLIGHT)
            px(img, 28, 0, GOLD)
            rect(img, 22, 25, 33, 25, GOLD_LIGHT)
        frames.append(outline(pad(img), 0.5))

    sheet = new(frames[0].width * len(frames), frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "centro_vila.png")


# ------------------------------------------------------------ oficina de ferramentas
def build_oficina():
    """Oficina: galpão aberto na frente com forja, bigorna e ferramentas penduradas.
    2 quadros: 0 = forja em brasa (parada), 1 = forja acesa (fabricando)."""
    W, H = 40, 32
    rnd = random.Random(40)
    base = new(W, H)

    # chaminé de pedra da forja
    for y in range(0, 16):
        for x in range(29, 35):
            base.putpixel((x, y), dither(STONE_RAMP, 0.62 - (x - 29) * 0.1, x, y))
    rect(base, 28, 0, 35, 1, STONE_LIGHT)
    rect(base, 30, 0, 33, 0, STONE_BLACK)
    # telhado de tábuas (uma água), com musgo
    for y in range(6, 14):
        for x in range(0, W):
            if x in range(29, 35) and y < 9:
                continue
            t = 0.62 - (y - 6) * 0.05
            if (x + y * 2) % 5 == 0:
                t = 0.12  # junta entre tábuas
            c = dither(WOOD_RAMP, t, x, y)
            if rnd.random() < 0.08:
                c = dither(MOSS_RAMP, 0.4, x, y)
            base.putpixel((x, y), c)
    rect(base, 0, 13, W - 1, 13, WOOD_ROT)
    # interior escuro (frente aberta)
    rect(base, 2, 14, W - 3, 27, WALL_SHADOW)
    for y in range(14, 17):  # sombra do telhado no fundo
        for x in range(2, W - 2):
            if (x + y) & 1 or y == 14:
                px(base, x, y, WALL_VOID)
    # postes da frente
    for x0 in (1, W - 3):
        for y in range(13, 28):
            px(base, x0, y, WOOD_LIGHT)
            px(base, x0 + 1, y, WOOD_DARK)
    # ferramentas penduradas no fundo
    for tx in (5, 9, 13):
        rect(base, tx, 17, tx, 22, WOOD)
        rect(base, tx - 1, 17, tx + 1, 17, IRON_LIGHT)
    rect(base, 16, 17, 17, 18, IRON)
    rect(base, 16, 19, 16, 22, WOOD)
    # barril de água
    for y in range(22, 28):
        for x in range(4, 9):
            px(base, x, y, dither(WOOD_RAMP, 0.6 - (x - 4) * 0.08, x, y))
        if y in (23, 26):
            rect(base, 4, y, 8, y, IRON_DARK)
    rect(base, 5, 22, 7, 22, WALL_WET)
    # bigorna
    rect(base, 13, 22, 21, 23, IRON_LIGHT)
    rect(base, 13, 22, 21, 22, IRON_HIGHLIGHT)
    px(base, 12, 22, IRON)
    rect(base, 15, 24, 19, 25, IRON_DARK)
    rect(base, 14, 26, 20, 27, IRON)
    # forja de tijolo (a boca fica em cada quadro)
    for y in range(18, 28):
        for x in range(25, 36):
            brick = (x + (y % 2) * 2) % 4 == 0 or y % 2 == 0 and x % 2 == 0
            px(base, x, y, dither(STONE_RAMP, 0.25 if brick else 0.45, x, y))
    rect(base, 25, 18, 35, 18, STONE_LIGHT)
    # chão/fundação
    for x in range(0, W):
        for y in (28, 29):
            px(base, x, y, dither(STONE_RAMP, 0.45 if y == 28 else 0.25, x, y))
    # placa com martelo na testeira do telhado
    rect(base, 14, 10, 22, 12, WOOD_LIGHT)
    rect(base, 14, 12, 22, 12, WOOD_DARK)
    rect(base, 16, 11, 19, 11, IRON_LIGHT)
    px(base, 20, 11, WOOD_DARK)

    frames = []
    for hot in (False, True):
        img = base.copy()
        ramp = TORCH_RAMP if hot else (TORCH_EMBER, TORCH_EMBER, TORCH_FLAME, TORCH_FLAME)
        for y in range(21, 26):  # boca da forja com brasas
            for x in range(27, 34):
                t = 0.9 - abs(x - 30) * 0.12 - (25 - y) * 0.08
                px(img, x, y, dither(ramp, t, x, y))
        if hot:
            px(img, 17, 21, TORCH_BRIGHT)  # peça em brasa na bigorna
            px(img, 18, 21, TORCH_GLOW)
            for x in range(25, 36):  # clarão no tijolo
                if x & 1:
                    px(img, x, 19, shade(TORCH_FLAME, 0.7))
        frames.append(outline(pad(img), 0.5))

    sheet = new(frames[0].width * 2, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "oficina.png")


# ------------------------------------------------------------ escavadeira (projeto de fim de jogo)
# Todas as camadas têm o mesmo quadro (DIG_W x DIG_H) e se encaixam uma sobre a
# outra na cena: canteiro (base) -> estrutura -> hidráulica -> motor -> broca -> cabine.
DIG_W, DIG_H = 80, 96


def _line(img, x0, y0, x1, y1, c):
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        px(img, round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)


def dig_base():
    """Canteiro: laje de concreto com faixa de perigo, buraco da broca, canos, caixote e placa."""
    img = new(DIG_W, DIG_H)
    for y in range(84, 93):
        for x in range(2, 78):
            if y <= 87:
                c = dither(STONE_RAMP, 0.62 - (y - 84) * 0.06 - (x - 2) * 0.002, x, y)
            elif y <= 89:
                c = HELMET if ((x + y) // 3) % 2 else STONE_BLACK  # faixa de perigo desbotada
            else:
                c = dither(STONE_RAMP, 0.3 - (y - 90) * 0.1, x, y)
            px(img, x, y, c)
    for y in range(84, 89):  # buraco onde a broca entra
        for x in range(31, 49):
            if ((x - 39.5) / 8) ** 2 + ((y - 86) / 2.4) ** 2 <= 1:
                px(img, x, y, WALL_VOID if y > 84 else STONE_SHADOW)
    for i, y in enumerate((78, 80, 82)):  # pilha de canos
        x0 = 4 + (i % 2)
        rect(img, x0, y, x0 + 10, y, IRON_LIGHT)
        rect(img, x0, y + 1, x0 + 10, y + 1, IRON_DARK)
        px(img, x0 + 10, y, IRON_SHADOW)
        px(img, x0 + 10, y + 1, IRON_SHADOW)
        px(img, x0 + 3 + i, y, RUST_LIGHT)
    for y in range(75, 84):  # caixote
        for x in range(66, 76):
            px(img, x, y, dither(WOOD_RAMP, 0.65 - (x - 66) * 0.04, x, y))
    rect(img, 66, 75, 75, 75, WOOD_HIGHLIGHT)
    _line(img, 66, 76, 75, 83, WOOD_DARK)
    rect(img, 20, 72, 20, 83, WOOD_DARK)  # placa
    rect(img, 16, 69, 25, 73, WOOD_LIGHT)
    rect(img, 16, 73, 25, 73, WOOD_DARK)
    for x in (18, 20, 22):
        px(img, x, 71, RUST_DARK)
    return outline(img, 0.5)


def dig_estrutura():
    """Torre treliçada (estilo torre de perfuração) + convés de aço sobre pilares."""
    rnd = random.Random(81)
    img = new(DIG_W, DIG_H)
    for x0 in (5, 73, 27, 51):  # pilares do convés
        for y in range(60, 85):
            px(img, x0, y, IRON)
            px(img, x0 + 1, y, IRON_DARK)
    _line(img, 7, 62, 26, 82, IRON_DARK)
    _line(img, 72, 62, 53, 82, IRON_DARK)

    def legs(y):
        t = (84 - y) / 80
        return round(26 + t * 9), round(53 - t * 9)

    braces = list(range(10, 84, 9))
    for y in range(4, 85):
        lx, rx = legs(y)
        for x, c in ((lx, IRON_LIGHT), (lx + 1, IRON), (rx - 1, IRON), (rx, IRON_DARK)):
            px(img, x, y, c)
    for i, y in enumerate(braces):
        lx, rx = legs(y)
        rect(img, lx, y, rx, y, IRON)
        if i + 1 < len(braces):  # X entre uma travessa e a próxima
            y2 = braces[i + 1]
            lx2, rx2 = legs(y2)
            _line(img, lx + 1, y, rx2 - 1, y2, IRON_DARK)
            _line(img, rx - 1, y, lx2 + 1, y2, IRON_DARK)
    # coroa no topo com polia
    rect(img, 31, 1, 48, 4, IRON)
    rect(img, 31, 1, 48, 1, IRON_LIGHT)
    rect(img, 31, 4, 48, 4, IRON_SHADOW)
    for x, c in ((38, IRON_SHADOW), (39, IRON_HIGHLIGHT), (40, IRON_HIGHLIGHT), (41, IRON_SHADOW)):
        px(img, x, 2, c)
        px(img, x, 3, c)
    # convés de chapa com grade
    for x in range(3, 77):
        px(img, x, 56, IRON_LIGHT)
        px(img, x, 57, IRON if x % 2 else IRON_DARK)
        px(img, x, 58, IRON_DARK)
        px(img, x, 59, IRON_SHADOW)
    for x in range(4, 76, 6):  # corrimão
        rect(img, x, 52, x, 55, IRON_DARK)
    rect(img, 3, 52, 25, 52, IRON)
    rect(img, 54, 52, 76, 52, IRON)
    # ferrugem espalhada
    for _ in range(90):
        x, y = rnd.randrange(DIG_W), rnd.randrange(DIG_H)
        if opaque(img, x, y) and img.getpixel((x, y)) in (IRON, IRON_DARK, IRON_LIGHT):
            px(img, x, y, rnd.choice((RUST, RUST_DARK, RUST_LIGHT)))
    return outline(img, 0.5)


def dig_hidraulica():
    """Dois cilindros hidráulicos empurrando a travessa da broca + tanque sob o convés."""
    img = new(DIG_W, DIG_H)
    for cx in (33, 45):
        for y in range(38, 56):  # camisa do cilindro
            px(img, cx, y, IRON_LIGHT)
            px(img, cx + 1, y, IRON)
            px(img, cx + 2, y, IRON_DARK)
        rect(img, cx - 1, 38, cx + 3, 38, IRON_SHADOW)
        rect(img, cx + 1, 21, cx + 1, 37, IRON_HIGHLIGHT)  # haste cromada
        px(img, cx + 2, 30, IRON)
    # travessa que segura a broca
    rect(img, 32, 19, 48, 21, HELMET)
    rect(img, 32, 19, 48, 19, HELMET_HIGHLIGHT)
    rect(img, 32, 21, 48, 21, HELMET_DARK)
    px(img, 34, 20, IRON_DARK)
    px(img, 46, 20, IRON_DARK)
    # tanque de óleo (cápsula) debaixo do convés, pintura ocre gasta
    for y in range(64, 75):
        for x in range(56, 72):
            if x in (56, 71) and y in (64, 74):
                continue
            t = 0.75 - (y - 64) * 0.06
            c = dither((HELMET_DARK, HELMET, HELMET_LIGHT, HELMET_HIGHLIGHT), t, x, y)
            if (x * 7 + y * 3) % 11 == 0:
                c = RUST
            px(img, x, y, c)
    for y in range(66, 70):  # manômetro
        for x in range(58, 62):
            px(img, x, y, BANDAGE if (x, y) not in ((58, 66), (61, 66), (58, 69), (61, 69)) else HELMET_DARK)
    px(img, 60, 67, BLOOD)
    # mangueiras do tanque até a base dos cilindros
    _line(img, 56, 67, 47, 60, LEATHER_DARK)
    _line(img, 47, 60, 46, 56, LEATHER_DARK)
    _line(img, 56, 70, 36, 62, LEATHER)
    _line(img, 36, 62, 34, 56, LEATHER)
    return outline(img, 0.5)


def dig_motor():
    """Motor a diesel enferrujado no convés, com volante e escapamento."""
    img = new(DIG_W, DIG_H)
    for y in range(42, 56):
        for x in range(6, 24):
            t = 0.7 - (x - 6) * 0.025 - (y - 42) * 0.02
            c = dither(IRON_RAMP, t, x, y)
            if y > 50 and (x * 5 + y) % 4 == 0:
                c = RUST_DARK  # ferrugem escorrida embaixo
            px(img, x, y, c)
    for i in range(4):  # cabeçotes
        x0 = 7 + i * 4
        rect(img, x0, 38, x0 + 2, 41, IRON)
        rect(img, x0, 38, x0 + 2, 38, IRON_HIGHLIGHT)
        px(img, x0 + 2, 41, IRON_SHADOW)
    for x in range(7, 13):  # grade do radiador
        if x % 2:
            rect(img, x, 45, x, 53, IRON_SHADOW)
    rect(img, 15, 46, 20, 48, FLANNEL)  # placa de aviso
    rect(img, 15, 46, 20, 46, FLANNEL_LIGHT)
    px(img, 17, 47, BANDAGE)
    for y in range(43, 56):  # volante
        for x in range(19, 30):
            d = ((x - 24.5) ** 2 + (y - 49.5) ** 2) ** 0.5
            if d <= 5.5:
                if d > 4.4:
                    px(img, x, y, IRON_LIGHT if y < 49 else IRON_DARK)
                elif d < 1.5:
                    px(img, x, y, IRON_HIGHLIGHT)
                elif (x + y) % 3 == 0:
                    px(img, x, y, IRON_DARK)
    for y in range(22, 38):  # escapamento
        px(img, 9, y, IRON_LIGHT)
        px(img, 10, y, IRON_DARK)
    rect(img, 8, 21, 11, 21, IRON_SHADOW)
    rect(img, 8, 20, 11, 20, IRON)
    px(img, 9, 30, RUST)
    return outline(img, 0.5)


def dig_broca(phase):
    """Eixo + broca helicoidal. `phase` desloca a espiral (2 quadros = girando)."""
    img = new(DIG_W, DIG_H)
    for y in range(5, 58):  # eixo
        px(img, 39, y, IRON_HIGHLIGHT)
        px(img, 40, y, IRON_DARK)
    rect(img, 35, 57, 44, 59, IRON_DARK)  # colar
    rect(img, 35, 57, 44, 57, IRON_LIGHT)
    cx = 39.5
    for y in range(60, 93):
        hw = 5.5 if y < 70 else 5.5 * (92 - y) / 22
        for x in range(round(cx - hw), round(cx + hw) + 1):
            u = (x - cx) / max(hw, 0.5)  # -1..1 na largura
            flute = ((y * 2 - round(u * 4) + phase * 3) % 6) < 2
            if y >= 86:
                c = IRON_HIGHLIGHT if u < 0 else IRON_LIGHT  # ponta de metal duro
            elif flute:
                c = IRON_SHADOW
            else:
                c = dither(IRON_RAMP, 0.75 - (u + 1) * 0.28, x, y)
            px(img, x, y, c)
    return outline(img, 0.5)


def dig_cabine(lit):
    """Cabine do operador (chapa pintada de vermelho gasto), escada até o chão."""
    img = new(DIG_W, DIG_H)
    for y in range(33, 56):
        for x in range(57, 76):
            c = dither((FLANNEL_DARK, FLANNEL, FLANNEL_LIGHT), 0.8 - (x - 57) * 0.03 - (y - 33) * 0.01, x, y)
            if (x * 3 + y * 7) % 13 == 0:
                c = RUST_DARK  # pintura descascando
            px(img, x, y, c)
    rect(img, 55, 30, 77, 32, IRON_DARK)  # teto
    rect(img, 55, 30, 77, 30, IRON)
    rect(img, 60, 36, 73, 43, IRON_DARK)  # janela
    if lit:
        rect(img, 61, 37, 72, 42, WINDOW_LIT)
        rect(img, 61, 37, 64, 38, WINDOW_BRIGHT)
        rect(img, 61, 42, 72, 42, WINDOW_DIM)
        rect(img, 66, 28, 67, 29, TORCH_GLOW)  # giroflex no teto
    else:
        rect(img, 61, 37, 72, 42, WALL_VOID)
        _line(img, 62, 42, 66, 37, WALL_WET)
        rect(img, 66, 28, 67, 29, IRON_DARK)
    rect(img, 66, 37, 66, 42, IRON_DARK)
    rect(img, 62, 46, 62, 55, FLANNEL_DARK)  # porta
    px(img, 64, 50, BRASS)
    for y in range(56, 85):  # escada até o chão
        px(img, 58, y, IRON)
        px(img, 61, y, IRON_DARK)
        if y % 3 == 0:
            rect(img, 59, y, 60, y, IRON_LIGHT)
    return outline(img, 0.5)


def build_escavadeira():
    save(dig_base(), "escavadeira_base.png")
    save(dig_estrutura(), "escavadeira_estrutura.png")
    save(dig_hidraulica(), "escavadeira_hidraulica.png")
    save(dig_motor(), "escavadeira_motor.png")
    for name, frames in (("broca", [dig_broca(0), dig_broca(1)]), ("cabine", [dig_cabine(False), dig_cabine(True)])):
        sheet = new(DIG_W * 2, DIG_H)
        for i, f in enumerate(frames):
            sheet.alpha_composite(f, (i * DIG_W, 0))
        save(sheet, f"escavadeira_{name}.png")


# ------------------------------------------------------------ clareira: árvore, chão, machado, tora
def _tree_frame(stage):
    """stage 0 = pinheiro cheio, 1 = metade dos galhos, 2 = toco."""
    W, H = 22, 40
    rnd = random.Random(90 + stage)
    img = new(W, H)
    cx = 10.5
    trunk_top = 22 if stage < 2 else 31
    for y in range(trunk_top, 38):  # tronco
        for x in range(9, 13):
            px(img, x, y, dither(BARK_RAMP, 0.8 - (x - 9) * 0.22, x, y))
    for x in range(8, 14):  # raízes
        px(img, x, 38, BARK_RAMP[1])
    if stage == 2:
        rect(img, 9, trunk_top, 12, trunk_top, WOOD_CUT)  # corte com anéis
        px(img, 10, trunk_top, BARK_RAMP[3])
        px(img, 8, 36, PINE_RAMP[2])
        px(img, 13, 37, PINE_RAMP[1])
        return img
    # copa em "andares" triangulares, luz vindo da esquerda
    tiers = [(2, 10, 5), (8, 17, 8), (14, 25, 10)]
    if stage == 1:
        tiers = [(8, 17, 6), (15, 25, 8)]  # menos galhos, mais magro
    for top, bottom, half in tiers:
        for y in range(top, bottom):
            w = half * (y - top + 1) / (bottom - top)
            for x in range(round(cx - w), round(cx + w) + 1):
                u = (x - (cx - w)) / max(2 * w, 1)
                t = 0.85 - u * 0.6 - (y - top) / (bottom - top) * 0.25
                c = dither(PINE_RAMP, t, x, y)
                if rnd.random() < 0.06:
                    c = PINE_RAMP[0]
                px(img, x, y, c)
    return img


def build_arvore():
    frames = [outline(pad(_tree_frame(i)), 0.5) for i in range(3)]
    sheet = new(frames[0].width * 3, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "arvore.png")


def build_floor_clareira():
    """Chão da clareira: mato escuro com trilhas de terra, emenda sem costura."""
    size = 64
    rnd = random.Random(64)
    field = seamless_noise(size, 80, 17, (3, 9))
    dirt = seamless_noise(size, 14, 23, (4, 10))
    img = new(size, size)
    for y in range(size):
        for x in range(size):
            v = field[y][x] + rnd.uniform(-0.2, 0.2)
            c = dither(GRASS_RAMP, 0.5 + v * 0.25, x, y, mode="bayer")
            if dirt[y][x] > 0.7 and BAYER4[y % 4][x % 4] < (dirt[y][x] - 0.7) * 30:
                c = dither(EARTH_RAMP, 0.55 + v * 0.1, x, y, mode="bayer")
            img.putpixel((x, y), c)
    def put(x, y, c):
        img.putpixel((x % size, y % size), c)

    for _ in range(55):  # tufos de capim: lâminas em "V", ponta clara, pé escuro
        x, y = rnd.randrange(size), rnd.randrange(size)
        put(x, y, GRASS_RAMP[4])
        put(x - 1, y + 1, GRASS_RAMP[3])
        put(x + 1, y + 1, GRASS_RAMP[3])
        put(x, y + 1, GRASS_RAMP[2])
        for dx in (-1, 0, 1):
            put(x + dx, y + 2, GRASS_RAMP[1])
    for _ in range(18):  # fiapos soltos
        x, y = rnd.randrange(size), rnd.randrange(size)
        put(x, y, GRASS_RAMP[4])
        put(x, y + 1, GRASS_RAMP[2])
    for _ in range(9):  # florzinhas de 4 pétalas com miolo
        x, y = rnd.randrange(size), rnd.randrange(size)
        petal = rnd.choice((SHROOM_SPOT, BLOUSE_ROSE[2], BLOUSE_LAVENDER[2]))
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            put(x + dx, y + dy, petal)
        put(x, y, BRASS)
        put(x + 1, y + 2, GRASS_RAMP[1])  # sombrinha
    save(img, "floor_clareira.png")


def build_floor_deep():
    """Chão do nível 2: rocha mais escura e fria, com pontinhos de mineral brilhando."""
    size = 64
    rnd = random.Random(128)
    field = seamless_noise(size, 90, 31, (3, 9))
    img = new(size, size)
    for y in range(size):
        for x in range(size):
            v = field[y][x] + rnd.uniform(-0.2, 0.2)
            img.putpixel((x, y), dither(DEEP_RAMP, 0.45 + v * 0.25, x, y, mode="bayer"))
    for _ in range(14):  # rachaduras fundas
        x, y = rnd.randrange(size), rnd.randrange(size)
        for _ in range(rnd.randint(4, 8)):
            img.putpixel((x % size, y % size), DEEP_RAMP[0])
            x += rnd.choice((1, 1, 0))
            y += rnd.choice((1, 0, -1))
    for _ in range(10):  # pontinhos de prata/cristal
        x, y = rnd.randrange(size), rnd.randrange(size)
        img.putpixel((x, y), rnd.choice((SILVER, WALL_WET, (70, 110, 140, 255))))
    save(img, "floor_deep.png")


def build_elevador():
    """Elevador (gaiola de ferro com polia) que desce pro nível 2."""
    W, H = 24, 30
    img = new(W, H)
    for x0 in (2, W - 4):  # colunas
        for y in range(3, H - 1):
            px(img, x0, y, IRON_LIGHT)
            px(img, x0 + 1, y, IRON_DARK)
    rect(img, 1, 2, W - 2, 4, IRON)  # viga de cima
    rect(img, 1, 2, W - 2, 2, IRON_LIGHT)
    for y in range(0, 5):  # polia
        for x in range(9, 15):
            if (x - 11.5) ** 2 + (y - 2) ** 2 <= 6:
                px(img, x, y, RUST_LIGHT if y < 2 else RUST)
    px(img, 11, 2, IRON_SHADOW)
    for y in range(5, 18):  # correntes
        px(img, 8, y, IRON_HIGHLIGHT if y % 2 else IRON)
        px(img, 15, y, IRON_HIGHLIGHT if y % 2 else IRON)
    rect(img, 4, 17, W - 5, 18, WOOD_LIGHT)  # plataforma de tábua
    rect(img, 4, 19, W - 5, 19, WOOD_DARK)
    for x in range(4, W - 4, 2):  # grade da gaiola
        rect(img, x, 20, x, 24, IRON_DARK)
    rect(img, 4, 25, W - 5, 25, IRON)
    for y in range(26, H - 1):  # poço escuro embaixo
        for x in range(4, W - 4):
            px(img, x, y, (WALL_VOID, STONE_BLACK))
    rect(img, 5, 21, 6, 22, LAMP_GLOW)  # lanterninha de sinal
    save(outline(img, 0.5), "elevador.png")


def build_axe():
    """Machado do lenhador: mesmo layout 11x13 da picareta (encaixa na mão igual)."""
    rows = [
        ".....DLL...",
        "....DLLGL..",
        "....DLGGL..",
        ".....Bdd...",
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
    pal = {"L": IRON_HIGHLIGHT, "G": IRON_LIGHT, "D": IRON_DARK, "d": IRON,
           "B": WOOD_HIGHLIGHT, "b": WOOD_DARK, "W": LEATHER_LIGHT, "w": LEATHER}
    save(from_rows(rows, pal), "axe.png")


def build_branch():
    """Galho de pinheiro que cai na cabeça do lenhador (Bloco 16)."""
    rows = [
        "..n.n..n....",
        ".nNnNnnNn.n.",
        "bBBBBBBBBBBb",
        ".nNnnNnNnn..",
        "..n..n.n....",
    ]
    pal = {"b": BARK_RAMP[1], "B": BARK_RAMP[2], "n": PINE_RAMP[1], "N": PINE_RAMP[3]}
    save(outline(pad(from_rows(rows, pal)), 0.5), "branch.png")


def build_enfermaria():
    """Enfermaria: casinha caiada (encardida) com placa da cruz vermelha e telhado de
    ardósia. 2 quadros: 0 = vazia (janelas escuras), 1 = com pacientes (janelas acesas)."""
    W, H = 32, 26
    rnd = random.Random(32)
    base = new(W, H)
    wall_ramp = (STONE_DARK, STONE_LIGHT, BANDAGE_SHADOW, BANDAGE)  # reboco claro e sujo
    for y in range(2, 11):  # telhado de ardósia
        inset = round((10 - y) * 5 / 8)
        for x in range(inset, W - inset):
            t = 0.5 - (y - 2) * 0.03 - (0.18 if (y - 2) % 2 else 0.0)
            c = dither(STONE_RAMP, t, x, y)
            if rnd.random() < 0.08:
                c = dither(MOSS_RAMP, 0.4, x, y)
            base.putpixel((x, y), c)
    rect(base, 5, 1, W - 6, 1, STONE_SHADOW)
    rect(base, 0, 10, W - 1, 10, STONE_BLACK)
    for y in range(11, 23):  # paredes caiadas, sujas embaixo
        for x in range(2, W - 2):
            t = 0.72 - (y - 11) * 0.025 - (0.15 if (x - 2) % 7 == 0 else 0.0)
            if y > 19:
                t -= 0.25
            base.putpixel((x, y), dither(wall_ramp, t, x, y))
    for x in range(2, W - 2):  # sombra do beiral
        px(base, x, 11, STONE_DARK)
        if x & 1:
            px(base, x, 12, STONE_LIGHT)
    for x in range(2, W - 2):  # manchas de umidade/musgo na base
        if rnd.random() < 0.35:
            px(base, x, 22, dither(MOSS_RAMP, 0.4, x, 22))
    # placa com a cruz vermelha
    rect(base, 12, 12, 19, 16, BANDAGE)
    rect(base, 12, 16, 19, 16, BANDAGE_SHADOW)
    rect(base, 15, 12, 16, 16, BLOOD)
    rect(base, 13, 14, 18, 14, BLOOD)
    # porta
    rect(base, 13, 17, 18, 22, WOOD_DARK)
    rect(base, 14, 18, 17, 22, (WOOD, WOOD_DARK))
    px(base, 17, 20, BRASS)
    # degrau e fundação
    rect(base, 12, 23, 19, 23, STONE_LIGHT)
    for x in range(1, W - 1):
        if not 12 <= x <= 19:
            px(base, x, 23, dither(STONE_RAMP, 0.3, x, 23))
    frames = []
    for lit in (False, True):
        img = base.copy()
        for wx in (4, 23):
            rect(img, wx, 14, wx + 4, 18, WOOD_DARK)
            if lit:
                rect(img, wx + 1, 15, wx + 3, 17, WINDOW_LIT)
                px(img, wx + 1, 15, WINDOW_BRIGHT)
            else:
                rect(img, wx + 1, 15, wx + 3, 17, WALL_VOID)
                px(img, wx + 1, 15, WALL_WET)
            px(img, wx + 2, 15, WOOD_DARK)
            px(img, wx + 2, 16, WOOD_DARK)
            px(img, wx + 2, 17, WOOD_DARK)
        frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 2, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "enfermaria.png")


def build_grave():
    """Cruz de madeira sobre um montinho de terra (ipezinho que morreu)."""
    rows = [
        "...Bb....",
        "...Bb....",
        ".BBBBbb..",
        ".bbBbbb..",
        "...Bb....",
        "...Bb..f.",
        "...Bb.fFf",
        ".sEEEEEs.",
        "eEEEEEEEe",
        ".eeeeeee.",
    ]
    pal = {"B": WOOD_LIGHT, "b": WOOD_DARK, "E": EARTH_HIGHLIGHT, "e": EARTH_DARK, "s": STONE_LIGHT,
           "f": BLOUSE_ROSE[1], "F": BRASS}
    save(outline(pad(from_rows(rows, pal)), 0.5), "grave.png")


def build_taverna():
    """Taverna: casa de tábuas quentes com telhado de telha de madeira, placa com uma
    caneca pendurada, barril na porta. 2 quadros: 0 = vazia, 1 = com gente (janelas
    acesas e lampião da porta aceso)."""
    W, H = 34, 26
    rnd = random.Random(34)
    base = new(W, H)
    # chaminé de pedra
    for y in range(0, 6):
        for x in range(24, 28):
            base.putpixel((x, y), dither(STONE_RAMP, 0.6 - (x - 24) * 0.12, x, y))
    # telhado de telhas de madeira (fileiras)
    for y in range(2, 11):
        inset = round((10 - y) * 6 / 8)
        for x in range(inset, W - inset):
            t = 0.55 - (y - 2) * 0.03
            if (y - 2) % 2 == 1:
                t -= 0.2
            elif (x + (y // 2) * 3) % 5 == 0:
                t = 0.1
            c = dither(WOOD_RAMP, t, x, y)
            if rnd.random() < 0.06:
                c = dither(MOSS_RAMP, 0.4, x, y)
            base.putpixel((x, y), c)
    rect(base, 6, 1, W - 7, 1, WOOD_ROT)
    rect(base, 0, 10, W - 1, 10, WOOD_ROT)
    # paredes de tábua (verticais) com viga no meio
    for y in range(11, 23):
        for x in range(2, W - 2):
            if (x - 2) % 4 == 0:
                c = WOOD_ROT
            else:
                c = dither(WOOD_RAMP, 0.7 - ((x - 2) % 4) * 0.1 - (0.2 if y > 19 else 0.0), x, y)
            base.putpixel((x, y), c)
    for x in range(2, W - 2):
        px(base, x, 11, WOOD_ROT)
        if x & 1:
            px(base, x, 12, WOOD_DARK)
    rect(base, 2, 18, W - 3, 18, WOOD_DARK)
    # porta dupla
    rect(base, 14, 14, 20, 22, WOOD_ROT)
    rect(base, 15, 15, 16, 22, WOOD_LIGHT)
    rect(base, 18, 15, 19, 22, WOOD)
    px(base, 16, 18, BRASS)
    px(base, 18, 18, BRASS)
    # degrau e fundação de pedra
    rect(base, 13, 23, 21, 23, STONE_LIGHT)
    for x in range(1, W - 1):
        if not 13 <= x <= 21:
            px(base, x, 23, dither(STONE_RAMP, 0.3, x, 23))
    # braço da placa + placa com caneca (lado esquerdo)
    rect(base, 0, 12, 5, 12, IRON_DARK)
    rect(base, 0, 13, 5, 17, WOOD_LIGHT)
    rect(base, 0, 17, 5, 17, WOOD_DARK)
    rect(base, 2, 14, 3, 16, BRASS)
    px(base, 4, 15, BRASS)
    px(base, 2, 14, (230, 220, 190, 255))  # espuma
    px(base, 3, 14, (230, 220, 190, 255))
    # barril ao lado da porta
    for y in range(19, 24):
        for x in range(24, 29):
            t = 0.7 - abs(x - 26) * 0.18
            px(base, x, y, dither(WOOD_RAMP, t, x, y))
    rect(base, 24, 20, 28, 20, IRON_DARK)
    rect(base, 24, 22, 28, 22, IRON_DARK)
    frames = []
    for lit in (False, True):
        img = base.copy()
        for wx in (6, 23):
            rect(img, wx, 13, wx + 4, 16, WOOD_ROT)
            if lit:
                rect(img, wx + 1, 14, wx + 3, 15, WINDOW_LIT)
                px(img, wx + 1, 14, WINDOW_BRIGHT)
            else:
                rect(img, wx + 1, 14, wx + 3, 15, WALL_VOID)
                px(img, wx + 1, 14, WALL_WET)
            px(img, wx + 2, 14, WOOD_ROT)
            px(img, wx + 2, 15, WOOD_ROT)
        # lampião ao lado da porta
        px(img, 12, 14, IRON_DARK)
        px(img, 12, 15, WINDOW_BRIGHT if lit else IRON_LIGHT)
        px(img, 12, 16, WINDOW_LIT if lit else IRON_DARK)
        frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 2, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "taverna.png")


def build_strike_sign():
    """Plaquinha de protesto (ipezinho em greve): tábua num cabo, com um X vermelho."""
    rows = [
        "WWWWWWWWW",
        "WwwwwwwwW",
        "WwRwwwRwW",
        "WwwRwRwwW",
        "WwwwRwwwW",
        "WwwRwRwwW",
        "WwRwwwRwW",
        "WWWWWWWWW",
        "....s....",
        "....s....",
        "....S....",
    ]
    pal = {"W": WOOD_DARK, "w": BANDAGE, "R": ANGER, "s": WOOD_LIGHT, "S": WOOD}
    save(outline(pad(from_rows(rows, pal)), 0.5, form=False, selout=False), "strike_sign.png")


def build_note():
    """Notinha musical que sai da taverna quando tem gente se divertindo."""
    rows = [
        "..NNN",
        "..N.N",
        "..N.N",
        "..N..",
        "NNN..",
        "NNN..",
    ]
    save(outline(pad(from_rows(rows, {"N": WINDOW_BRIGHT})), 0.5, form=False, selout=False), "note.png")


def build_robo():
    """Robô antigo (um Ferrugento desligado): caixote enferrujado com cúpula e um olho
    grande. 3 quadros: 0 = desligado (tombado, olho apagado, musgo), 1 e 2 = ligado
    andando (pernas alternadas, olho aceso ciano)."""
    W, H = 18, 20
    frames = []
    for mode in ("off", "a", "b"):
        img = new(W, H)
        rnd = random.Random(18)
        # cúpula (cabeça)
        for y in range(1, 7):
            half = [3, 4, 5, 5, 5, 5][y - 1]
            for x in range(9 - half, 9 + half):
                t = 0.75 - (y - 1) * 0.06 - abs(x - 8) * 0.04
                px(img, x, y, dither(IRON_RAMP, t, x, y))
        # olho
        eye = (60, 70, 78, 255) if mode == "off" else (120, 240, 230, 255)
        rect(img, 7, 3, 10, 5, IRON_SHADOW)
        rect(img, 8, 3, 9, 4, eye)
        if mode != "off":
            px(img, 8, 3, (220, 255, 250, 255))
        # antena
        px(img, 12, 0, RUST_ACCENT)
        px(img, 12, 1, IRON_DARK)
        # corpo (caixote) com ferrugem
        for y in range(7, 15):
            for x in range(3, 15):
                t = 0.6 - (y - 7) * 0.04 - (0.2 if x >= 12 else 0.0)
                c = dither(IRON_RAMP, t, x, y)
                if rnd.random() < 0.28:
                    c = dither(RUST_RAMP, 0.5, x, y)
                px(img, x, y, c)
        rect(img, 3, 7, 14, 7, IRON_LIGHT)
        rect(img, 6, 9, 11, 12, IRON_SHADOW)  # painel
        px(img, 7, 10, (200, 60, 50, 255) if mode == "off" else (120, 240, 230, 255))
        px(img, 9, 10, BRASS)
        px(img, 10, 11, BRASS)
        # braços
        rect(img, 1, 8, 2, 13, IRON_DARK)
        rect(img, 15, 8, 16, 13, IRON_DARK)
        px(img, 1, 13, RUST)
        px(img, 16, 13, RUST)
        # pernas
        if mode == "off":
            rect(img, 4, 15, 7, 16, IRON_DARK)
            rect(img, 10, 15, 13, 16, IRON_DARK)
        else:
            up = 0 if mode == "a" else 1
            rect(img, 5, 15, 7, 18 - up, IRON_DARK)
            rect(img, 10, 15, 12, 17 + up, IRON_DARK)
            rect(img, 4, 18 - up, 7, 18 - up, IRON_SHADOW)
            rect(img, 10, 17 + up, 13, 17 + up, IRON_SHADOW)
        if mode == "off":
            for _ in range(10):  # musgo e ferrugem de décadas parado
                x, y = rnd.randrange(3, 15), rnd.randrange(2, 15)
                if opaque(img, x, y):
                    px(img, x, y, dither(MOSS_RAMP, 0.5, x, y))
            img = img.rotate(-12, resample=0, expand=False, center=(9, 16))
        frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 3, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "robo.png")


def build_find_icons():
    """Ícones dos achados: peça rara (engrenagem), cristal ressonante, núcleo solar e
    bobina de plasma (8x8, pro popup e pro painel)."""
    gear = [
        ".b.bb.b.",
        "bbBBBBbb",
        ".BBooBB.",
        "bBo..oBb",
        "bBo..oBb",
        ".BBooBB.",
        "bbBBBBbb",
        ".b.bb.b.",
    ]
    save(outline(pad(from_rows(gear, {"B": BRASS, "b": RUST_ACCENT, "o": IRON_DARK})), 0.5, form=False, selout=False), "find_peca.png")
    crystal = [
        "...cC...",
        "..cCCc..",
        "..cCWc..",
        ".ccCCcc.",
        ".cCCCCc.",
        "..cCCc..",
        "...cc...",
        "..dddd..",
    ]
    save(outline(pad(from_rows(crystal, {"c": (150, 110, 220, 255), "C": (200, 170, 255, 255), "W": (245, 235, 255, 255), "d": HUD_STONE_DARK})), 0.5, form=False, selout=False), "find_cristal.png")
    solar = [
        "..yYYy..",
        ".yYWWYy.",
        "yYWWWWYy",
        "YWWWWWWY",
        "YWWWWWWY",
        "yYWWWWYy",
        ".yYWWYy.",
        "..yYYy..",
    ]
    save(outline(pad(from_rows(solar, {"y": (200, 110, 40, 255), "Y": (255, 180, 60, 255), "W": (255, 240, 170, 255)})), 0.5, form=False, selout=False), "find_solar.png")
    coil = [
        "iiiiiiii",
        ".cCcCcC.",
        ".CcCcCc.",
        ".cCcCcC.",
        ".CcCcCc.",
        ".cCcCcC.",
        "iiiiiiii",
        "..p..p..",
    ]
    save(outline(pad(from_rows(coil, {"i": IRON_DARK, "c": COPPER, "C": (120, 220, 255, 255), "p": COPPER_LIGHT})), 0.5, form=False, selout=False), "find_bobina.png")


# nível 3 (abismo): basalto quase preto com rachaduras incandescentes
ABYSS_RAMP = ((12, 9, 11, 255), (20, 15, 17, 255), (29, 22, 24, 255), (40, 31, 32, 255), (54, 42, 41, 255))
EMBER = (255, 132, 42, 255)
EMBER_DARK = (170, 60, 24, 255)
EMBER_GLINT = (255, 214, 120, 255)
SOLAR_RAMP = (EMBER_DARK, (220, 96, 32, 255), EMBER, EMBER_GLINT)
SOLAR_VEIN = (EMBER_GLINT, EMBER, EMBER, EMBER_DARK, (255, 240, 190, 255))


def build_abyss():
    """Nível 3: chão de basalto com rachaduras em brasa, minério de solarita (rocha
    que guardou a energia da explosão solar) e a plataforma arruinada que desce."""
    size = 64
    rnd = random.Random(333)
    field = seamless_noise(size, 90, 47, (3, 9))
    img = new(size, size)
    for y in range(size):
        for x in range(size):
            v = field[y][x] + rnd.uniform(-0.2, 0.2)
            img.putpixel((x, y), dither(ABYSS_RAMP, 0.42 + v * 0.25, x, y, mode="bayer"))
    for _ in range(4):  # rachaduras em brasa (com borda escura) — poucas, pra não virar padrão
        x, y = rnd.randrange(size), rnd.randrange(size)
        for _ in range(rnd.randint(4, 9)):
            img.putpixel((x % size, y % size), EMBER_DARK if rnd.random() < 0.8 else EMBER)
            img.putpixel(((x + 1) % size, y % size), ABYSS_RAMP[0])
            x += rnd.choice((1, 1, 0))
            y += rnd.choice((1, 0, -1))
    for _ in range(4):
        x, y = rnd.randrange(size), rnd.randrange(size)
        img.putpixel((x, y), rnd.choice((EMBER_DARK, EMBER_DARK, EMBER)))
    save(img, "floor_abyss.png")
    # solarita
    for i, (seed, n) in enumerate(((701, 5), (702, 6), (703, 5))):
        save(rock(16, 16, seed, ramp=ABYSS_RAMP, ore=n, cracks=2, bright=0.1, vein=SOLAR_VEIN,
                  specks=(EMBER_GLINT,)), f"ore_solarita_{i}.png")
    save(trim(ore_chunk(9, 8, 9, ramp=SOLAR_RAMP, speck=EMBER_DARK, glint=EMBER_GLINT)), "chunk_solarita.png")
    # plataforma arruinada: colunas tortas, viga caída, sem polia, tábuas quebradas
    W, H = 24, 30
    r = new(W, H)
    for y in range(6, H - 1):
        px(r, 2, y, IRON_LIGHT)
        px(r, 3, y, IRON_DARK)
    for y in range(12, H - 1):  # coluna da direita quebrada
        px(r, W - 4 + (1 if y < 18 else 0), y, IRON_LIGHT)
        px(r, W - 3 + (1 if y < 18 else 0), y, IRON_DARK)
    for i in range(14):  # viga caída na diagonal
        px(r, 3 + i, 6 + i // 2, RUST if i % 3 else RUST_DARK)
        px(r, 3 + i, 7 + i // 2, RUST_DARK)
    for x in range(4, W - 5):  # plataforma com buracos
        if x in (9, 10, 15):
            continue
        px(r, x, 20, WOOD_LIGHT if x % 3 else WOOD_DARK)
        px(r, x, 21, WOOD_DARK)
    for y in range(22, H - 1):  # poço escuro com brasa lá no fundo
        for x in range(4, W - 4):
            px(r, x, y, (WALL_VOID, STONE_BLACK))
    px(r, 11, 27, EMBER_DARK)
    px(r, 12, 28, EMBER)
    px(r, 7, 17, IRON_DARK)  # corrente solta
    px(r, 7, 18, IRON)
    px(r, 7, 19, IRON_DARK)
    save(outline(r, 0.5), "elevador_ruina.png")


LUMI_BODY = ((22, 16, 30, 255), (38, 28, 50, 255), (58, 44, 74, 255))
LUMI_WING = ((96, 84, 128, 255), (140, 128, 176, 255), (190, 180, 222, 255))
LUMI_EYE = (236, 240, 255, 255)


def build_creatures():
    """Lumívoro (bicho que come luz: corpo escuro, asas de membrana clara, olhos
    brancos) e Ferrugento hostil (sucata-aranha enferrujada de olho vermelho).
    2 quadros cada (bater de asas / passo)."""
    frames = []
    for up in (True, False):
        img = new(18, 14)
        # corpo
        for y in range(4, 11):
            for x in range(7, 11):
                px(img, x, y, LUMI_BODY[2] if x == 7 else (LUMI_BODY[1] if y < 9 else LUMI_BODY[0]))
        # antenas
        px(img, 7, 3, LUMI_BODY[2])
        px(img, 6, 2, LUMI_WING[1])
        px(img, 10, 3, LUMI_BODY[2])
        px(img, 11, 2, LUMI_WING[1])
        # olhos (brancos, sem pupila)
        px(img, 8, 5, LUMI_EYE)
        px(img, 9, 5, LUMI_EYE)
        # asas (duas poses)
        if up:
            for i in range(6):
                for j in range(6 - i):
                    px(img, 6 - j, 2 + i, LUMI_WING[1 if j < 2 else 0])
                    px(img, 11 + j, 2 + i, LUMI_WING[1 if j < 2 else 0])
            px(img, 2, 3, LUMI_WING[2])
            px(img, 15, 3, LUMI_WING[2])
        else:
            for i in range(4):
                for j in range(6):
                    if j + i < 7:
                        px(img, 6 - j, 7 + i, LUMI_WING[1 if j < 2 else 0])
                        px(img, 11 + j, 7 + i, LUMI_WING[1 if j < 2 else 0])
            px(img, 1, 8, LUMI_WING[2])
            px(img, 16, 8, LUMI_WING[2])
        px(img, 8, 11, LUMI_BODY[1])  # rabinho
        px(img, 9, 12, LUMI_BODY[0])
        frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 2, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "lumivoro.png")

    frames = []
    for step in (0, 1):
        img = new(20, 14)
        rnd = random.Random(20)
        # carapaça de sucata
        for y in range(3, 9):
            half = [4, 6, 7, 7, 7, 6][y - 3]
            for x in range(10 - half, 10 + half):
                c = dither(IRON_RAMP, 0.55 - (y - 3) * 0.07, x, y)
                if rnd.random() < 0.4:
                    c = dither(RUST_RAMP, 0.45, x, y)
                px(img, x, y, c)
        rect(img, 7, 3, 12, 3, IRON_LIGHT)
        # olho vermelho
        rect(img, 8, 5, 11, 6, IRON_SHADOW)
        px(img, 9, 5, (255, 60, 40, 255))
        px(img, 10, 5, (255, 140, 110, 255))
        # pernas (alternam)
        legs = ((3, 8), (6, 9), (13, 9), (16, 8))
        for k, (lx, ly) in enumerate(legs):
            dy = 1 if (k + step) % 2 else 0
            px(img, lx, ly, IRON_DARK)
            px(img, lx + (-1 if lx < 10 else 1), ly + 1 + dy, IRON_DARK)
            px(img, lx + (-1 if lx < 10 else 1), ly + 2 + dy, RUST_DARK)
        frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 2, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "ferrugento.png")


def build_defense():
    """Barricada (4 quadros: 0 = só as estacas marcando o lugar, 1 = paliçada de
    madeira, 2 = muro de pedra, 3 = portão de ferro), campo de treino e a lança."""
    W, H = 36, 18
    rnd = random.Random(36)
    frames = []
    # 0: estacas e corda no chão
    img = new(W, H)
    for x0 in (3, 17, 31):
        rect(img, x0, 9, x0 + 1, 16, WOOD)
        px(img, x0, 9, WOOD_LIGHT)
    for x in range(4, 31):
        px(img, x, 11 + (1 if 8 < x < 26 else 0), (150, 130, 90, 255))
    frames.append(outline(pad(img), 0.5))
    # 1: paliçada de estacas pontudas com vão no meio
    img = new(W, H)
    for x0 in list(range(1, 13, 3)) + list(range(24, 35, 3)):
        h = rnd.randint(11, 14)
        wood_post(img, x0, H - h, 3, h - 1, rnd)
        px(img, x0 + 1, H - h - 1, WOOD_LIGHT)
    rect(img, 1, 10, 13, 10, WOOD_DARK)
    rect(img, 23, 10, 35, 10, WOOD_DARK)
    frames.append(outline(pad(img), 0.5))
    # 2: muro de pedra com portão de tábua
    img = new(W, H)
    for y in range(4, H - 1):
        for x in range(0, W):
            if 14 <= x <= 21:
                continue
            t = 0.6 - (y - 4) * 0.03 if (x + (y // 3) * 3) % 6 else 0.15
            if y % 3 == 0:
                t = 0.2
            px(img, x, y, dither(STONE_RAMP, t, x, y))
    for x in range(14, 22):
        for y in range(7, H - 1):
            px(img, x, y, dither(WOOD_RAMP, 0.55 - (0.2 if x % 2 else 0.0), x, y))
    rect(img, 14, 6, 21, 6, IRON_DARK)
    frames.append(outline(pad(img), 0.5))
    # 3: portão de ferro rebitado entre torres de pedra
    img = new(W, H)
    for tx in (0, 28):
        for y in range(1, H - 1):
            for x in range(tx, tx + 8):
                px(img, x, y, dither(STONE_RAMP, 0.65 - (y * 0.02) - (0.15 if x in (tx, tx + 7) else 0.0), x, y))
        rect(img, tx, 1, tx + 7, 1, STONE_HIGHLIGHT)
        px(img, tx + 3, 5, WINDOW_LIT)
    for y in range(4, H - 1):
        for x in range(8, 28):
            c = dither(IRON_RAMP, 0.6 - (y - 4) * 0.02, x, y)
            if x % 5 == 0:
                c = IRON_SHADOW
            px(img, x, y, c)
    for x in range(9, 28, 5):
        for y in (6, 11, 15):
            px(img, x + 1, y, IRON_HIGHLIGHT)
    rect(img, 8, 4, 27, 4, RUST)
    frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 4, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "barricada.png")

    # campo de treino: boneco de palha num poste + suporte de lanças + areia
    W, H = 32, 22
    img = new(W, H)
    for y in range(16, 21):
        for x in range(1, W - 1):
            if (x - 16) ** 2 / 225 + (y - 18) ** 2 / 9 <= 1:
                px(img, x, y, dither(EARTH_RAMP, 0.75, x, y))
    rect(img, 9, 4, 10, 18, WOOD_DARK)  # poste do boneco
    for y in range(5, 12):  # boneco de palha
        for x in range(6, 14):
            if abs(x - 9.5) + abs(y - 8) * 0.5 < 4.5:
                px(img, x, y, dither(((150, 120, 60, 255), (196, 164, 88, 255), (226, 200, 120, 255)), 0.6, x, y))
    rect(img, 7, 3, 12, 5, (196, 164, 88, 255))  # cabeça
    px(img, 8, 4, BLOOD)
    px(img, 11, 4, BLOOD)
    rect(img, 4, 8, 15, 8, WOOD)  # braços
    rect(img, 20, 6, 29, 6, WOOD_DARK)  # suporte de lanças
    rect(img, 20, 13, 29, 13, WOOD_DARK)
    rect(img, 21, 6, 21, 18, WOOD)
    rect(img, 28, 6, 28, 18, WOOD)
    for x in (23, 25, 27):
        rect(img, x, 3, x, 16, WOOD_LIGHT)
        px(img, x, 2, IRON_HIGHLIGHT)
        px(img, x, 3, IRON_LIGHT)
    save(outline(pad(img), 0.5), "campo_treino.png")

    # lança (ferramenta do guarda)
    rows = [
        "..........hH",
        ".........wHh",
        "........w...",
        ".......w....",
        "......w.....",
        ".....w......",
        "....w.......",
        "...w........",
        "..w.........",
        ".W..........",
        "W...........",
    ]
    save(outline(pad(from_rows(rows, {"w": WOOD_LIGHT, "W": WOOD_DARK, "h": IRON_LIGHT, "H": IRON_HIGHLIGHT})), 0.5), "lanca.png")


LAB_GLOW = (120, 230, 150, 255)
LAB_GLOW_DIM = (60, 150, 100, 255)


def build_lab():
    """Laboratório: base de pedra, paredes de tábua, janelão com frascos borbulhando
    (verde quando tem pesquisa) e uma antena. 2 quadros: 0 = parado, 1 = pesquisando.
    Mais a antena parabólica do Satélite (aparece em cima quando é pesquisado)."""
    W, H = 32, 28
    rnd = random.Random(320)
    base = new(W, H)
    # antena
    rect(base, 25, 0, 25, 8, IRON_LIGHT)
    px(base, 24, 1, IRON)
    px(base, 26, 1, IRON)
    px(base, 25, 0, BLOOD)
    # telhado de ferro corrugado
    for y in range(5, 12):
        inset = round((11 - y) * 4 / 6)
        for x in range(inset, W - inset):
            t = 0.55 - (y - 5) * 0.04 - (0.2 if x % 3 == 0 else 0.0)
            c = dither(IRON_RAMP, t, x, y)
            if rnd.random() < 0.15:
                c = dither(RUST_RAMP, 0.5, x, y)
            base.putpixel((x, y), c)
    rect(base, 0, 11, W - 1, 11, IRON_SHADOW)
    # paredes: tábua em cima, pedra embaixo
    for y in range(12, 25):
        for x in range(2, W - 2):
            if y >= 21:
                c = dither(STONE_RAMP, 0.5 if (x + (y % 2) * 2) % 5 else 0.15, x, y)
            elif (x - 2) % 3 == 0:
                c = WOOD_ROT
            else:
                c = dither(WOOD_RAMP, 0.55, x, y)
            base.putpixel((x, y), c)
    for x in range(2, W - 2):
        px(base, x, 12, WOOD_ROT)
    # porta
    rect(base, 22, 15, 27, 24, WOOD_DARK)
    rect(base, 23, 16, 26, 24, (WOOD, WOOD_DARK))
    px(base, 25, 20, BRASS)
    rect(base, 21, 25, 28, 25, STONE_LIGHT)
    for x in range(1, W - 1):
        if not 21 <= x <= 28:
            px(base, x, 25, dither(STONE_RAMP, 0.3, x, 25))
    frames = []
    for on in (False, True):
        img = base.copy()
        rect(img, 4, 14, 19, 20, IRON_DARK)  # janelão
        for x in range(5, 19):
            for y in range(15, 20):
                px(img, x, y, (LAB_GLOW_DIM if on else WALL_VOID) if (x + y) % 5 else (LAB_GLOW if on else WALL_WET))
        for fx, fy in ((7, 17), (11, 16), (15, 17)):  # frascos
            px(img, fx, fy, LAB_GLOW if on else STONE_LIGHT)
            px(img, fx, fy + 1, LAB_GLOW if on else STONE_LIGHT)
            px(img, fx, fy + 2, (200, 255, 210, 255) if on else STONE)
            if on:
                px(img, fx, fy - 2, (200, 255, 210, 255))
        rect(img, 4, 20, 19, 20, WOOD_LIGHT)  # peitoril
        frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 2, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "laboratorio.png")
    rows = [
        "..IIIII.......",
        ".IiiiiiI......",
        "Iii....iI.....",
        "Ii......iI....",
        "Ii...r...iI...",
        ".Ii.....iI....",
        "..IIi..iI.....",
        "....IIII......",
        ".....pp.......",
        ".....pp.......",
        "....pppp......",
    ]
    save(outline(pad(from_rows(rows, {"I": IRON_LIGHT, "i": IRON, "r": BLOOD, "p": IRON_DARK})), 0.5), "satelite.png")


SHIELD_GLOW = (140, 220, 255, 255)
SHIELD_GLOW_DIM = (70, 130, 190, 255)


def build_escudo():
    """Gerador do escudo solar em 5 quadros (obra): 0 = lote marcado, 1 = fundação de
    pedra, 2 = + bobinas de cobre, 3 = + núcleo de solarita brilhando, 4 = pronto, com o
    emissor e a cúpula de energia."""
    W, H = 30, 36
    frames = []
    for stage in range(5):
        img = new(W, H)
        # lote: estacas e corda
        for x0 in (2, 27):
            rect(img, x0, 28, x0, 34, WOOD)
        for x in range(3, 27):
            px(img, x, 30, (150, 130, 90, 255))
        if stage >= 1:  # fundação octogonal de pedra
            for y in range(27, 35):
                for x in range(3, 27):
                    if abs(x - 14.5) + abs(y - 31) * 1.6 <= 14:
                        px(img, x, y, dither(STONE_RAMP, 0.6 - (y - 27) * 0.05 - (0.2 if (x + y) % 5 == 0 else 0.0), x, y))
            rect(img, 6, 27, 23, 27, STONE_HIGHLIGHT)
        if stage >= 2:  # bobinas de cobre dos lados
            for bx in (5, 21):
                for y in range(16, 27):
                    for x in range(bx, bx + 4):
                        c = COPPER_LIGHT if (y % 2 == 0) else COPPER_DARK
                        if x in (bx, bx + 3):
                            c = IRON_DARK
                        px(img, x, y, c)
                rect(img, bx, 15, bx + 3, 15, IRON_LIGHT)
        if stage >= 3:  # núcleo de solarita
            for y in range(18, 27):
                for x in range(11, 19):
                    if abs(x - 14.5) + abs(y - 22.5) * 0.9 <= 4.5:
                        px(img, x, y, EMBER_GLINT if abs(x - 14.5) + abs(y - 22.5) < 2 else EMBER)
            rect(img, 10, 26, 19, 26, IRON_DARK)
        if stage >= 4:  # emissor + cúpula
            rect(img, 14, 5, 15, 17, IRON_LIGHT)
            rect(img, 12, 5, 17, 5, IRON_HIGHLIGHT)
            for y in range(0, 12):
                for x in range(3, 27):
                    d = ((x - 14.5) / 12) ** 2 + ((y - 11) / 11) ** 2
                    if 0.8 <= d <= 1.0:
                        px(img, x, y, SHIELD_GLOW)
                    elif d < 0.8 and (x + y) % 4 == 0 and y < 10:
                        px(img, x, y, SHIELD_GLOW_DIM)
            px(img, 14, 4, (255, 255, 255, 255))
            px(img, 15, 4, (255, 255, 255, 255))
        frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 5, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "escudo.png")


def build_log():
    """Tora de madeira (carga do lenhador)."""
    rows = [
        ".bBBBBbc.",
        "bBBBBBbcC",
        "bbbbbbbcc",
    ]
    pal = {"B": BARK_RAMP[3], "b": BARK_RAMP[1], "c": WOOD_CUT, "C": shade(WOOD_CUT, 1.1)}
    save(outline(pad(from_rows(rows, pal)), 0.5), "wood_log.png")


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

    # 3 quadros pelo estoque: 0 = cheio, 1 = pela metade, 2 = vazio (só farelo)
    frames = []
    for level in (2, 1, 0):
        f = img.copy()
        _comedouro_food(f, level, W)
        frames.append(outline(pad(f), 0.5))
    sheet = new(frames[0].width * 3, frames[0].height)
    for i, fr in enumerate(frames):
        sheet.alpha_composite(fr, (i * fr.width, 0))
    save(sheet, "comedouro.png")


def _comedouro_food(img, level, W):
    """Comida em cima do cocho. level 2 = cheio, 1 = metade, 0 = vazio."""
    if level == 0:
        for x, y in ((6, 6), (12, 6), (19, 6), (25, 6)):  # farelo
            px(img, x, y, BREAD_DARK)
        return
    # "papa" da comida no topo
    rect(img, 2, 6, W - 3, 6, (BREAD_DARK, WOOD_DARK))
    # pães
    for bx in ((3, 16) if level == 2 else (3,)):
        rect(img, bx, 3, bx + 5, 5, BREAD)
        rect(img, bx + 1, 2, bx + 4, 2, BREAD_LIGHT)
        rect(img, bx + 1, 3, bx + 3, 3, BREAD_HIGHLIGHT)
        rect(img, bx, 5, bx + 5, 5, (BREAD_DARK, BREAD))
        px(img, bx + 2, 4, BREAD_DARK)
        px(img, bx + 4, 3, BREAD_DARK)
    # maçãs
    for ax, ay in (((10, 4), (13, 3)) if level == 2 else ((10, 4),)):
        rect(img, ax, ay, ax + 2, ay + 2, APPLE)
        px(img, ax + 2, ay + 2, APPLE_DARK)
        px(img, ax + 1, ay + 2, (APPLE, APPLE_DARK))
        px(img, ax, ay, APPLE_LIGHT)
        px(img, ax + 1, ay - 1, WOOD_DARK)
    if level < 2:
        return
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


# ------------------------------------------------------------ horta de cogumelos (ponto de coleta)
def _mushroom(img, x, y, big, red):
    """Cogumelo com o pé em (x, y). big = chapéu de 5px, senão 3px."""
    cap, cap_dark = (SHROOM, SHROOM_DARK) if red else (SHROOM_STEM, shade(SHROOM_STEM, 0.7))
    h = 3 if big else 2
    for yy in range(y - h + 1, y + 1):
        px(img, x, yy, SHROOM_STEM if yy < y else shade(SHROOM_STEM, 0.8))
    w = 2 if big else 1
    top = y - h
    rect(img, x - w, top, x + w, top, cap)
    rect(img, x - w + 1, top - 1, x + w - 1, top - 1, cap)
    px(img, x + w, top, cap_dark)
    if big:
        px(img, x - 1, top - 1, SHROOM_SPOT if red else SHROOM_SPOT)
        px(img, x + 1, top, SHROOM_SPOT if red else cap_dark)


def build_horta():
    """Canteiro de cogumelos de caverna. 3 quadros: cheio, pela metade, colhido."""
    W, H = 24, 14
    rnd = random.Random(24)
    base = new(W, H)
    # monte de terra escura e úmida
    for y in range(5, H - 1):
        for x in range(1, W - 1):
            if ((x - (W - 1) / 2) / ((W - 2) / 2)) ** 2 + ((y - 9) / 4.2) ** 2 <= 1.0:
                t = 0.7 - (y - 5) * 0.08
                c = dither(EARTH_RAMP, t, x, y)
                if rnd.random() < 0.12:
                    c = dither(MOSS_RAMP, 0.4, x, y)
                px(base, x, y, c)
    # bordinha de pedras
    for x in range(2, W - 2, 3):
        px(base, x, H - 3, STONE_LIGHT)
        px(base, x + 1, H - 3, STONE_DARK)
    spots = [(5, 8, True, True), (11, 7, True, False), (17, 8, True, True), (8, 11, False, True),
             (14, 11, False, False), (20, 11, False, True), (3, 11, False, False)]
    frames = []
    for n in (len(spots), 3, 0):
        img = base.copy()
        for i, (x, y, big, red) in enumerate(spots):
            if i < n:
                _mushroom(img, x, y, big, red)
            else:
                px(img, x, y, shade(SHROOM_STEM, 0.6))  # toco colhido
        frames.append(outline(pad(img), 0.5))
    sheet = new(frames[0].width * 3, frames[0].height)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * f.width, 0))
    save(sheet, "horta.png")


def build_food_icons():
    """Cesta de comida (carga do cozinheiro) e chapéu de cozinheiro."""
    basket = [
        ".r.W...",
        "rRrWWw.",
        "wwwwwww",
        "BbBbBbB",
        "bBbBbBb",
        ".BbBbB.",
    ]
    pal = {"r": SHROOM_DARK, "R": SHROOM, "W": SHROOM_STEM, "w": shade(SHROOM_STEM, 0.75),
           "B": WOOD_LIGHT, "b": WOOD_DARK}
    save(outline(pad(from_rows(basket, pal)), 0.5), "food_basket.png")
    hat = [
        ".wWw.",
        "wWWWw",
        "wWWWW",
        ".WWW.",
        ".sss.",
    ]
    save(outline(pad(from_rows(hat, {"W": BANDAGE, "w": BANDAGE_SHADOW, "s": BANDAGE_SHADOW})), 0.5), "cook_hat.png")


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

    # tocha apagada (de dia): mesma moldura, ponta de pano carbonizado no lugar da chama.
    # No jogo a chama acesa é desenhada POR CIMA desta, com transparência (fade).
    unlit = ["......"] * 4 + [
        "..cd..",
        ".cddc.",
        "..cc..",
    ] + rows[7:]
    pal_unlit = {**pal, "c": STONE_BLACK, "d": WOOD_ROT}
    save(outline(pad(from_rows(unlit, pal_unlit)), 0.5), "torch_unlit.png")


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


def build_bandage():
    """Curativo em cruz: aparece sobre o ipezinho machucado."""
    rows = [
        ".wwW.",
        "wwrwW",
        "wrrrW",
        "wwrWW",
        ".wWW.",
    ]
    pal = {"w": BANDAGE, "W": BANDAGE_SHADOW, "r": BLOOD}
    save(outline(pad(from_rows(rows, pal)), 0.5, form=False, selout=False), "bandage.png")


def build_anger():
    """Símbolo de zanga (a "veia saltando" dos quadrinhos) sobre o ipezinho irritado/furioso."""
    rows = [
        ".r...r.",
        "rRr.rRr",
        ".rR.Rr.",
        ".......",
        ".rR.Rr.",
        "rRr.rRr",
        ".r...r.",
    ]
    save(outline(pad(from_rows(rows, {"r": ANGER_DARK, "R": ANGER})), 0.5, form=False, selout=False), "anger.png")


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
    build_bandage()
    build_anger()
    build_ipezinho()
    build_ipezinho_accessories()
    build_pickaxe()
    build_ores()
    build_crystals()
    build_shadow()
    build_armazem()
    build_casa()
    build_centro_vila()
    build_escavadeira()
    build_oficina()
    build_pickaxe_steel()
    build_padlock()
    build_comedouro()
    build_horta()
    build_arvore()
    build_floor_clareira()
    build_axe()
    build_floor_deep()
    build_elevador()
    build_log()
    build_branch()
    build_enfermaria()
    build_grave()
    build_taverna()
    build_strike_sign()
    build_note()
    build_robo()
    build_find_icons()
    build_abyss()
    build_creatures()
    build_defense()
    build_lab()
    build_escudo()
    build_food_icons()
    build_floor()
    build_wall()
    build_torch()
    build_support()
