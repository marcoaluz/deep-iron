"""Os ANDARES DE BAIXO na vista do jogo: a coluna da mina DEBAIXO DA VILA (Bloco 72, etapa 2; Bloco 75:
as FAIXAS da maquete aprovada — docs/arte/bloco72/maquete/coluna_v3.png).

Bloco 75: cada andar é uma faixa larga e rasa ao longo da face sul do mapa (1400 x 260 px da lógica, na
escala da superfície), a parede de trás subindo até a laje do andar de cima, os andares bem mais juntos
(22 degraus em vez de 36) e, logo abaixo da superfície, a faixa das GALERIAS de madeira (só desenho). Os
andares ganharam retângulos novos na lógica, longe dos antigos (`antigo` em cada um): o que estava num
retângulo antigo vai pro mesmo lugar relativo na faixa (`novo()`; o jogo faz o mesmo com saves antigos).

  python andares.py [pasta]   -> (padrão: assets/game/iso/mapa) andar_<nome>.png, poco.png, espiral.png e
                                 andares.json (lido pela vista iso e pelo environment.gd)

O modelo é a imagem B do mapa do mundo (docs/arte/bloco72/mapa_pixellab/quadrado.png): a superfície em
cima e os níveis UM EMBAIXO DO OUTRO, debaixo da vila, em forma de caverna, ligados pelo poço do elevador
e pela escada em espiral. Na lógica os andares continuam retângulos separados (deep_rect, abyss_rect,
`rect` do .tres: os saves valem); só a vista muda:
  - cada andar é desenhado na escala K (mais compacto: 1,5 x K px de arte por px da lógica), com a beira
    da frente na face sul do mapa e a gaiola de chegada na mesma vertical da torre do elevador da vila;
  - o chão é uma CAVERNA: superelipse com ruído na borda, que cresce onde há conteúdo (jazida, poça,
    zona, decoração, elevador), mais a plataforma redonda da gaiola. O contorno vai pro json: a navegação
    e a decoração do andar ficam dentro dele;
  - atrás do chão, a rocha sobe até a laje do andar de cima (o nível 2, até a borda de baixo da
    superfície): a coluna. Na frente, vazio (o corte). Atrás da gaiola, o poço do elevador fica aberto.
Nada novo é gerado: usa os blocos e chãos do Prompt 7 (relevo/final/nivel2, abismo, mina...).

Coordenadas: a grade da superfície (monta.py: tile de 32, origem OX/OY). Num andar:
vista(px de arte) = (lógica - centro do retângulo) x F + centro_arte; altura do chão = k_chao x 32.
"""
import sys, os, glob, json, math, re, random
from PIL import Image, ImageDraw
sys.path.insert(0, "../relevo")
import tiles
from monta import OX, OY, NI, NJ, T, FATOR, PALICADA_X

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.join(AQUI, "..", "..", "..", "..")
REL = "../relevo/final"

K = 1.0                                    # Bloco 75: a escala da superfície (a faixa já é menor em área que o andar antigo)
F = FATOR * K                              # px de arte por px da lógica num andar
ELEVADOR = (580, 320)                      # a torre do elevador na vila (main.tscn: Elevador.position)
POCO = (ELEVADOR[0] - ELEVADOR[1]) * FATOR  # x da tela (ax - ay) do poço: todas as gaiolas nessa vertical
FACE_AY = OY + NJ * T                      # a face sul do mapa (px de arte): a beira da frente de cada andar
GAIOLA = (0.90, 0.02)                      # a gaiola de chegada de cada andar (normalizada no retângulo): a ponta leste
RAIO_GAIOLA = 72                           # a plataforma redonda da gaiola (px da lógica)
LAJE = 3                                   # espessura da laje embaixo do chão (degraus)
SUP_KB = -4                                # a base do corte da superfície (monta.py CORTE)
FAIXA_ROCHA = 0.25                         # a rocha de trás vai até isso além da borda (normalizado)
P = 5.0                                    # o chão é uma superelipse |u|^P + |v|^P (Bloco 75: 5, a faixa de pontas redondas)
FAIXA_FUNDO = 60                           # Bloco 75: px da lógica de rocha atrás do chão (o resto fica escondido atrás)
FAIXA_PONTAS = 80                          # ... e além da ponta oeste da faixa (a leste fica o poço e a espiral)
LARGURA_POCO = 52                          # meia largura (tela) do poço aberto na rocha atrás das gaiolas
TOM_ROCHA = (1.12, 1.0, 0.86)              # a rocha da coluna puxada pro marrom (a da imagem B), não azul
## Bloco 76: a rocha de trás de cada andar no tom do tema, como na maquete (coluna_v3): o S2 musgo, o S3
## barro queimado, o S4 cinza molhado, o S5 cinza azulado — a coluna se lê de longe, faixa por faixa
TOM_ANDAR = {"nivel2": (0.92, 1.14, 0.84), "abismo": (1.40, 0.94, 0.72), "s4": (1.04, 1.02, 1.0), "s5": (0.88, 1.0, 1.24)}
ESPIRAL_DX = 250                           # a espiral fica à direita do poço (tela)

# andar: retângulo na lógica (environment.gd: deep_rect / abyss_rect; .tres: rect), degrau do chão
# (36 degraus entre andares), pasta dos blocos/chão, arquivo de dados (data/niveis)
ANDARES = {
    "nivel2": {"rect": (-700, 3600, 1400, 260), "antigo": (-560, 700, 1120, 620), "k_chao": -32, "pasta": "nivel2", "tres": "S2_acido.tres"},
    "abismo": {"rect": (-700, 4000, 1400, 260), "antigo": (-480, 1420, 960, 560), "k_chao": -54, "pasta": "abismo", "tres": "S3_lava.tres"},
    "s4": {"rect": (-700, 4400, 1400, 260), "antigo": (-440, 2120, 880, 520), "k_chao": -76, "pasta": "umido", "tres": "S4_cachoeira.tres"},
    "s5": {"rect": (-700, 4800, 1400, 260), "antigo": (-400, 2760, 800, 480), "k_chao": -98, "pasta": "lago", "tres": "S5_lago.tres"},
}
## Bloco 75: a faixa das galerias de madeira logo abaixo da superfície (só desenho: trilho, vagonetes, escoras)
GALERIAS = {"rect": (-700, 3300, 1400, 150), "k_chao": -12, "pasta": "colonia"}


def novo(p):
    """Bloco 75: um ponto que estava no retângulo ANTIGO de um andar -> o mesmo lugar relativo na faixa."""
    for a in ANDARES.values():
        x, y, w, h = a["antigo"]
        if x <= p[0] <= x + w and y <= p[1] <= y + h:
            nx, ny, nw, nh = a["rect"]
            return (nx + (p[0] - x) * nw / w, ny + (p[1] - y) * nh / h)
    return tuple(p)


# a descida pro andar de baixo (a ponta de cima do elevador seguinte): perto da gaiola, mais pra frente
DESCIDA = {"nivel2": novo((381, 917)), "abismo": novo((298, 1644)), "s4": novo((299, 2302))}


def _tres(arquivo):
    return open(os.path.join(RAIZ, "data", "niveis", arquivo), encoding="utf-8").read()


def _dos_dados(arquivo, campo):
    """Lista JSON de um campo do .tres do nível (data/niveis)."""
    m = re.search(r"^%s = (\[.*\])$" % campo, _tres(arquivo), re.M)
    return json.loads(m.group(1)) if m else []


def _da_cena():
    """[(nome, (x, y), raio)] dos nós da cena principal (jazidas, zonas...), menos os elevadores."""
    t = open(os.path.join(RAIZ, "scenes", "game", "main.tscn"), encoding="utf-8").read()
    out = []
    for bloco in re.split(r"\n(?=\[node )", t):
        m = re.match(r'\[node name="([^"]+)"', bloco)
        p = re.search(r"^position = Vector2\(([-\d.]+), ([-\d.]+)\)", bloco, re.M)
        if not m or not p or m.group(1).startswith("Elevador"):
            continue
        r = re.search(r"^radius = ([\d.]+)", bloco, re.M)
        out.append((m.group(1), (float(p.group(1)), float(p.group(2))), float(r.group(1)) if r else 0.0))
    return out


def obst_novo(o):
    """Bloco 75: um retângulo (o lago) do retângulo antigo do andar -> a faixa (os dois cantos)."""
    a = novo((o[0], o[1]))
    b = novo((o[0] + o[2], o[1] + o[3]))
    return (a[0], a[1], b[0] - a[0], b[1] - a[1])


# Bloco 71: o lago do S5 (`obstaculos` no .tres): chão de água rasa, com a borda de seixos em volta
AGUA = [obst_novo(o) for o in _dos_dados("S5_lago.tres", "obstaculos")]
BORDA = 1.25   # o anel da borda: até 1,25x a elipse
# itens de arte: a rocha com ácido em volta das poças de ácido do S2 (`perigos` no .tres)
ACIDO = [(novo((p[1], p[2])), p[3] * 1.3) for p in _dos_dados("S2_acido.tres", "perigos") if p[0] == "acido"]
# zonas de perigo da cena (main.tscn): centro na lógica, raio, tipo
ZONAS = [(novo(pos), r, n[4:].lower()) for n, pos, r in _da_cena() if n.startswith("Zona") and r > 0]


def borda_de_baixo(x, ia, ja, kb):
    """y (tela do python) da borda de baixo de uma laje que encosta no canto da frente (NI-1, NJ-1),
    com chão i >= ia, j >= ja e base no degrau kb, na coluna de tela x (reta pelos vértices de baixo)."""
    ys = []
    i = (x - T) / T + (NJ - 1)            # borda da frente esquerda (j = NJ-1)
    if ia - 0.5 <= i <= NI - 0.5:
        ys.append((i + NJ - 1) * (T // 2) - kb * 32 + 64)
    j = (NI - 1) - (x - T) / T            # borda da frente direita (i = NI-1)
    if ja - 0.5 <= j <= NJ - 0.5:
        ys.append((NI - 1 + j) * (T // 2) - kb * 32 + 64)
    return max(ys) if ys else None


def ld(p):
    return [Image.open(f).convert("RGBA") for f in sorted(glob.glob(p))]


def tinge(img, tom):
    r, g, b, a = img.split()
    return Image.merge("RGBA", [c.point(lambda v, m=m: min(255, int(v * m))) for c, m in zip((r, g, b), tom)] + [a])


def compoe(itens):
    itens.sort(key=lambda t: (t[0], t[1]))
    x0 = min(t[3][0] for t in itens); y0 = min(t[3][1] for t in itens)
    x1 = max(t[3][0] + t[2].width for t in itens); y1 = max(t[3][1] + t[2].height for t in itens)
    c = Image.new("RGBA", (x1 - x0, y1 - y0))
    for t in itens:
        c.alpha_composite(t[2], (t[3][0] - x0, t[3][1] - y0))
    bb = c.getbbox()
    return c.crop(bb), (x0 + bb[0], y0 + bb[1])


def zona_em(p):
    for x, y, w, h in AGUA:  # o lago é a elipse dentro do retângulo (o jogo usa a mesma no obstáculo)
        dx, dy = (p[0] - (x + w / 2)) / (w / 2), (p[1] - (y + h / 2)) / (h / 2)
        if dx * dx + dy * dy <= 1.0:
            return "agua"
        if dx * dx + dy * dy <= BORDA * BORDA:
            return "borda"
    for (cx, cy), r in ACIDO:
        dx, dy = p[0] - cx, p[1] - cy
        if (dx * dx) / (r * r) + (dy * dy) / (r * r * 0.36) <= 1.0:
            return "acido"
    for (cx, cy), r, kind in ZONAS:
        dx, dy = p[0] - cx, p[1] - cy
        if (dx * dx) / (r * r) + (dy * dy) / (r * r * 0.36) <= 1.0:
            return kind
    return None


# ---------------------------------------------------------------- a geometria de um andar
class Andar:
    BINS = 180

    def __init__(self, nome, a, semente):
        self.nome = nome
        x, y, w, h = a["rect"]
        self.rect = (x, y, w, h)
        self.c = (x + w / 2.0, y + h / 2.0)
        self.hl = (w / 2.0, h / 2.0)                       # meia largura/altura na lógica
        self.hw, self.hh = self.hl[0] * F, self.hl[1] * F    # ... e na arte
        cy = FACE_AY - self.hh
        u, v = GAIOLA
        cx = cy + POCO - (u * self.hw - v * self.hh)
        self.centro = (cx, cy)
        self.kc = a["k_chao"]
        self.gaiola = (self.c[0] + u * self.hl[0], self.c[1] + v * self.hl[1])
        rnd = random.Random(semente)
        self.fases = [rnd.random() * math.tau for _ in range(4)]
        self.raio = [self._ruido(2 * math.pi * b / self.BINS) for b in range(self.BINS)]

    # lógica <-> arte <-> normalizado
    def arte(self, p):
        return ((p[0] - self.c[0]) * F + self.centro[0], (p[1] - self.c[1]) * F + self.centro[1])

    def logica(self, a):
        return ((a[0] - self.centro[0]) / F + self.c[0], (a[1] - self.centro[1]) / F + self.c[1])

    def uv(self, p):
        return ((p[0] - self.c[0]) / self.hl[0], (p[1] - self.c[1]) / self.hl[1])

    @staticmethod
    def rho(u, v):
        return (abs(u) ** P + abs(v) ** P) ** (1.0 / P)

    def _ruido(self, th):
        f = self.fases
        n = (0.45 * math.sin(3 * th + f[0]) + 0.3 * math.sin(5 * th + f[1]) + 0.15 * math.sin(8 * th + f[2])
             + 0.1 * math.sin(13 * th + f[3]))
        return 0.82 + 0.11 * n

    def _bin(self, th):
        return int(round((th % math.tau) / math.tau * self.BINS)) % self.BINS

    def cobre(self, pontos):
        """a borda cresce pra cobrir cada (ponto, raio) com folga: calombos redondos, não pontas."""
        need = [0.0] * self.BINS
        for p, r in pontos:
            for s in range(24):
                a = math.tau * s / 24
                q = (p[0] + math.cos(a) * r, p[1] + math.sin(a) * r)
                u, v = self.uv(q)
                b = self._bin(math.atan2(v, u))
                need[b] = max(need[b], self.rho(u, v) + 0.03)
            u, v = self.uv(p)
            b = self._bin(math.atan2(v, u))
            need[b] = max(need[b], self.rho(u, v) + 0.03)
        for b in range(self.BINS):
            if need[b] <= 0.0:
                continue
            for d in range(-10, 11):  # calombo estreito: um bolsão da caverna, não o canto inteiro
                val = need[b] - 0.3 * (d / 10.0) ** 2
                k = (b + d) % self.BINS
                self.raio[k] = max(self.raio[k], val)

    def raio_em(self, th):
        x = (th % math.tau) / math.tau * self.BINS
        b0 = int(math.floor(x)) % self.BINS
        b1 = (b0 + 1) % self.BINS
        t = x - math.floor(x)
        return self.raio[b0] * (1 - t) + self.raio[b1] * t

    def tile(self, p):
        a = self.arte(p)
        return (int(math.floor((a[0] - OX) / T)), int(math.floor((a[1] - OY) / T)))

    def dentro(self, p):
        """o ponto da lógica é chão da caverna?"""
        x, y, w, h = self.rect
        if not (x + 10 <= p[0] <= x + w - 10 and y + 10 <= p[1] <= y + h - 10):
            return False
        if math.hypot(p[0] - self.gaiola[0], p[1] - self.gaiola[1]) <= RAIO_GAIOLA:
            return True
        u, v = self.uv(p)
        return self.rho(u, v) <= self.raio_em(math.atan2(v, u))

    def contorno(self, n=72):
        """o contorno da caverna (lógica), n pontos: o mais longe de dentro em cada direção."""
        pts = []
        for s in range(n):
            th = math.tau * s / n
            t = 1.6
            while t > 0.05:
                p = (self.c[0] + math.cos(th) * t * self.hl[0], self.c[1] + math.sin(th) * t * self.hl[1])
                if self.dentro(p):
                    break
                t -= 0.004
            pts.append([round(p[0], 1), round(p[1], 1)])
        return pts


def conteudo(nome, a):
    """[(ponto, raio)] do que tem que ficar dentro do chão do andar (px da lógica)."""
    x, y, w, h = a["rect"]
    dentro = lambda p: x <= p[0] <= x + w and y <= p[1] <= y + h
    out = []
    for n, p, r in _da_cena():
        p = novo(p)  # (Bloco 75: os dados antigos vão pro lugar relativo na faixa)
        if dentro(p):
            out.append((p, r * 0.5 if n.startswith("Zona") else 40.0))
    tres = a["tres"]
    for j in _dos_dados(tres, "jazidas"):
        out.append((novo((j[1], j[2])), 40.0))
    for pz in _dos_dados(tres, "perigos"):
        out.append((novo((pz[1], pz[2])), pz[3] + 12.0 if len(pz) > 3 else 40.0))
    for d in _dos_dados(tres, "decoracao"):
        # só a decoração de lugar escolhido (ponte, píer): a solta que cair fora do chão o jogo não põe
        if len(d) >= 4 and d[3] is True:
            out.append((novo((d[1], d[2])), 30.0))
    for d in _dos_dados(tres, "decalques"):
        out.append((novo((d[1], d[2])), 50.0))
    for ox, oy, ow, oh in [obst_novo(o) for o in _dos_dados(tres, "obstaculos")]:  # o lago e a borda de seixos dele
        for s in range(32):
            ang = math.tau * s / 32
            out.append(((ox + ow / 2 + math.cos(ang) * ow / 2 * BORDA, oy + oh / 2 + math.sin(ang) * oh / 2 * BORDA), 16.0))
    if nome in DESCIDA:
        out.append((DESCIDA[nome], 64.0))
    return [o for o in out if dentro(o[0])]


# ---------------------------------------------------------------- desenho
def tela_jogo(px, py):
    """tela do python -> tela do jogo (monta.exporta)."""
    return px + OX - OY - 32, py + (OX + OY) / 2.0


def py_de_jogo(gx, gy):
    return gx - (OX - OY - 32), gy - (OX + OY) / 2.0


PROPS = os.path.join(RAIZ, "assets", "game", "iso", "props")
_PROPS = json.load(open(os.path.join(PROPS, "props.json"), encoding="utf-8"))["props"]
_cache_prop = {}


def prop(nome):
    """(imagem, âncora) de um prop da arte do jogo (assets/game/iso/props)."""
    if nome not in _cache_prop:
        d = _PROPS[nome]
        _cache_prop[nome] = (Image.open(os.path.join(PROPS, d["img"])).convert("RGBA"), d["ancora"])
    return _cache_prop[nome]


def enfeites(an, piso, kc, tema):
    """Bloco 75: o que vai desenhado JUNTO com a faixa (não é coisa do jogo): na fileira de trás do chão,
    escoras de madeira e lampiões a cada tanto (a parede da maquete); nas galerias, o trilho correndo a faixa
    inteira com vagonetes. Itens no formato do compoe: (i + j, k, imagem, (x, y))."""
    itens = []
    rnd = random.Random(sum(ord(c) * (k + 1) for k, c in enumerate(an.nome)))  # (hash() de str muda a cada execução)
    fundo = {}  # coluna i -> a fileira mais de trás (menor j) do chão
    for (i, j) in piso:
        if i not in fundo or j < fundo[i]:
            fundo[i] = j
    cols = sorted(fundo)
    if not cols:
        return itens

    def poe(nome, i, j, dk=0.5, dx=0, dy=0):
        im, anc = prop(nome)
        x, y = tiles.tela(i, j, kc)
        itens.append((i + j + 0.6, kc + dk, im, (int(x + 32 - anc[0] + dx), int(y + 16 - anc[1] + dy))))
    passo = 7
    for n, i in enumerate(cols[2:-6:passo]):
        j = fundo[i]
        poe("escora", i, j)
        if n % 2 == 0:
            poe("tocha_chao_f0", i + 3, fundo.get(i + 3, j), 0.5, 0, -2)
        if tema in CRISTAIS and rnd.random() < 0.7:
            poe(CRISTAIS[tema] % rnd.randrange(2), i + 1, fundo.get(i + 1, j) + 1)
    if tema == "galerias":  # o trilho na fileira do meio, de ponta a ponta, e vagonetes nele
        meio = {}
        for (i, j) in piso:
            meio.setdefault(i, []).append(j)
        trilho = Image.open(REL + "/mina/trilhos/reto_i.png").convert("RGBA")
        jm = int(round(sum(sorted(js)[len(js) // 2] for js in meio.values()) / len(meio)))
        for i in cols:
            if (i, jm) in piso:
                x, y = tiles.tela(i, jm, kc)
                itens.append((i + jm, kc + 0.1, trilho, (x, y)))
        for i in cols[6::23]:
            if (i, jm) in piso:
                poe(rnd.choice(["vagonete_velho", "vagonete_cheio_SE"]), i, jm, 0.6)
        for i in cols[11::31]:
            poe(rnd.choice(["tabuas", "caixote", "barril"]), i, fundo[i] + 1)
        # Bloco 78 (maquete v4): a VILA DE MINERAÇÃO — cabanas de mineiro e bocas de túnel na parede de trás,
        # alternadas, nos vãos entre as escoras
        for n, i in enumerate(cols[5:-8:16]):
            if n % 2 == 0:
                poe("cabana_mina", i, fundo[i] + 1, 0.55)
            else:
                poe("boca_tunel", i, fundo[i], 0.45, 0, 6)
    return itens


## Bloco 76: o RIO DE LAVA do S3 (a maquete: um rio correndo a faixa) — as 2 fileiras de rocha logo atrás do
## chão, ao pé da parede (não é chão: ninguém anda nele); fios de lava saindo de fendas da parede até ele; e a
## CACHOEIRA do S4 despencando pela parede até uma poça.
def _lava_tiles():
    out = []
    mask = tiles.mascara_topo().load()
    cores = [(110, 26, 8), (176, 52, 12), (228, 96, 20), (255, 160, 44), (255, 222, 120)]
    for s_ in range(4):
        rnd = random.Random(700 + s_)
        im = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        px = im.load()
        for y in range(0, 32, 2):
            for x in range(0, 64, 2):
                n = 0.5 + 0.28 * math.sin(x * 0.19 + y * 0.43 + s_ * 1.7) + 0.22 * math.sin((x - 2 * y) * 0.13 + s_) + 0.2 * (rnd.random() - 0.5)
                c = cores[max(0, min(len(cores) - 1, int(n * len(cores))))]
                for dy in (0, 1):
                    for dx in (0, 1):
                        if mask[x + dx, y + dy]:
                            px[x + dx, y + dy] = c + (255,)
        out.append(im)
    return out


LAVA = None


def pinta_queda(b, q, k, nasce=False):
    """um fio de lava descendo pela face da frente (sul: a da esquerda) do bloco.
    q = ("lava", k de onde nasce); `nasce`: o bloco de onde ele sai (a fenda acesa no meio da face, o fio só
    dali pra baixo). O fio serpenteia contínuo de um bloco pro outro
    (a fase usa a altura na tela, y - 32k) e abre um pouco embaixo."""
    tipo, k_nasce = q[0], q[1]
    b = b.copy()
    px = b.load()
    if tipo == "lava":
        cores = [(110, 30, 8), (200, 70, 16), (245, 124, 28), (255, 196, 70), (255, 236, 150), (255, 196, 70),
                 (245, 124, 28), (200, 70, 16), (110, 30, 8)]
        y_de = 32 if nasce else 16
        for x in range(32):
            for y in range(y_de + x // 2, 48 + x // 2):
                if not (0 <= y < b.height and px[x, y][3] > 0):
                    continue
                yg = y - x // 2 - 32 * k                  # a altura na tela (contínua entre blocos)
                desce = (k_nasce - k) * 32 + (y - x // 2)  # quanto já desceu desde a fenda
                meio = 15 + 3.0 * math.sin(yg * 0.09) + 1.5 * math.sin(yg * 0.23 + 1.3)
                meia = 4.0 + min(3.0, desce / 70.0)
                dx = abs(x + 0.5 - meio)
                if dx < meia:
                    c = cores[min(len(cores) - 1, int((x + 0.5 - meio + meia) / (2 * meia) * len(cores)))]
                    px[x, y] = c + (255,)
                elif dx < meia + 4:                        # o halo: a rocha em volta pega o brilho
                    f = 1.0 - (dx - meia) / 4.0
                    r_, g_, b_, a_ = px[x, y]
                    px[x, y] = (min(255, int(r_ + 110 * f)), min(255, int(g_ + 34 * f)), b_, a_)
        if nasce:  # a fenda acesa de onde a lava sai: uma boca escura com brasa dentro
            yg = 32 - 32 * k
            meio = 15 + 3.0 * math.sin(yg * 0.09) + 1.5 * math.sin(yg * 0.23 + 1.3)
            for x in range(32):
                for y in range(18 + x // 2, 40 + x // 2):
                    if not (0 <= y < b.height and px[x, y][3] > 0):
                        continue
                    lado = ((x + 0.5 - meio) / 12.0) ** 2 + ((y - x // 2 - 29) / 7.0) ** 2
                    if lado < 1.0:
                        px[x, y] = (34, 10, 6, 255) if lado > 0.6 else ((255, 214, 96, 255) if lado < 0.22 else (226, 88, 20, 255))
    return b


def pinta_raiz(b, i, k, k_topo, comp):
    """Bloco 76: RAÍZES da floresta de cima descendo pela face da frente do bloco (a da esquerda): 1–3 fios
    escuros, ondulando contínuos de um bloco pro outro, afinando até `comp` px abaixo do topo da parede."""
    b = b.copy()
    px = b.load()
    h = (i * 2654435761) & 0xFFFF
    fios = 1 + h % 3
    for f in range(fios):
        x0 = 4 + ((h >> (3 + f * 4)) % 24)
        fase = (h >> f) % 7
        lim = comp * (0.55 + 0.45 * ((h >> (2 + f)) % 5) / 4.0)
        for yl in range(0, 32):
            desce = (k_topo - k) * 32 + yl          # px abaixo do topo da parede
            if desce > lim:
                break
            xc = x0 + 2.2 * math.sin(desce * 0.11 + fase) + 0.8 * math.sin(desce * 0.37 + f)
            grosso = 2.2 * (1.0 - desce / max(lim, 1.0)) + 0.6
            for x in range(int(xc - grosso), int(xc + grosso) + 1):
                if not 0 <= x < 32:
                    continue
                y = 16 + x // 2 + yl
                if 0 <= y < b.height and px[x, y][3] > 0:
                    luz = x < xc - grosso * 0.3
                    px[x, y] = (76, 55, 35, 255) if luz else (42, 29, 18, 255)
            # um raminho pro lado de vez em quando
            if desce > 8 and int(desce) % 23 == (h + f * 5) % 23:
                for t in range(1, 6):
                    x = int(xc + t * (1 if (h + f) % 2 else -1))
                    y = 16 + max(0, min(31, x)) // 2 + yl + t // 2
                    if 0 <= x < 32 and 0 <= y < b.height and px[x, y][3] > 0:
                        px[x, y] = (50, 35, 22, 255)
    return b


def pinta_cortina(b, lo, hi, k):
    """Bloco 76: a CORTINA da cachoeira — todo pixel do bloco (faces e topo) cuja x da tela cai na faixa
    [lo, hi) (x local do quadro do bloco; a faixa vem da coluna da tela, então todas as fileiras e degraus
    da parede alinham numa cortina reta). Listras pela x global, brilho correndo pela altura da tela."""
    b = b.copy()
    px = b.load()
    cores = [(120, 170, 220), (200, 230, 255), (150, 200, 240), (230, 245, 255), (110, 160, 215),
             (200, 230, 255), (90, 140, 200), (170, 210, 250)]
    larg = hi - lo
    for x in range(max(0, lo), min(b.width, hi)):
        gx = x - lo
        c = (40, 60, 90) if gx < 2 or gx >= larg - 2 else cores[(gx * len(cores)) // larg]
        for y in range(b.height):
            if px[x, y][3] > 0:
                brilho = 0.9 + 0.1 * math.sin((y - k * 32) * 0.7 + gx)
                px[x, y] = (min(255, int(c[0] * brilho)), min(255, int(c[1] * brilho)), min(255, int(c[2] * brilho)), 255)
    return b


def queda_da_cachoeira(an):
    """o ponto (lógica) da cachoeira do S4 (decoração fx:cachoeira do .tres), ou None."""
    for d in _dos_dados("S4_cachoeira.tres", "decoracao"):
        if str(d[0]).startswith("fx:cachoeira"):
            return novo((d[1], d[2]))
    return None


## Bloco 75: o cristal de cada andar (na parede de trás)
CRISTAIS = {"nivel2": "cristal_lima_%d", "abismo": "cristal_brasa_%d", "s5": "cristal_ciano_%d"}


def desenha_andar(an, a, acima, rocha):
    """devolve (imagem, (x, y) na tela do python, chão {(i, j)}, quina da direita (y, x) do chão)."""
    chao = ld(REL + "/%s/chao_*.png" % a["pasta"])
    bloco = ld(REL + "/%s/bloco.png" % a["pasta"])
    zchao = {k: ld(REL + "/mina/zona_%s/chao_*.png" % k) for k in ("gas", "calor", "radiacao", "agua", "acido", "borda")}
    kc = an.kc
    # a grade (a mesma da superfície) que cobre o retângulo do andar com folga pra rocha de trás
    ax0, ax1 = an.centro[0] - an.hw * 1.5, an.centro[0] + an.hw * 1.5
    ay0, ay1 = an.centro[1] - an.hh * 1.5, an.centro[1] + an.hh * 1.5
    i_de = range(int(math.floor((ax0 - OX) / T)), int(math.ceil((ax1 - OX) / T)) + 1)
    j_de = range(int(math.floor((ay0 - OY) / T)), int(math.ceil((ay1 - OY) / T)) + 1)
    centro_tile = lambda i, j: (OX + (i + 0.5) * T, OY + (j + 0.5) * T)
    ga = an.arte(an.gaiola)
    soma_gaiola = ga[0] + ga[1]
    piso = set()
    for i in i_de:
        for j in j_de:
            if an.dentro(an.logica(centro_tile(i, j))):
                piso.add((i, j))
    tema = a.get("tema", an.nome)
    rio = set()           # (o rio de lava do S3 entra depois da rocha: ele É a 1ª fileira de rocha atrás do chão)
    quedas = {}           # coluna i -> "lava" / "agua": o que escorre pela parede de trás
    poca = set()
    cachoeira = queda_da_cachoeira(an) if tema == "s4" else None
    if cachoeira:
        qi, qj = an.tile(cachoeira)
        poca = {(qi + di, qj + dj) for di in (-2, -1, 0, 1, 2) for dj in (-1, 0, 1, 2) if (qi + di, qj + dj) in piso}
    rocha_de = {}
    for i in i_de:
        for j in j_de:
            if (i, j) in piso or (i, j) in rio:
                continue
            axy = centro_tile(i, j)
            pl = an.logica(axy)
            u, v = an.uv(pl)
            alem = abs(pl[0] - an.c[0]) - an.hl[0]  # > 0: além da ponta da faixa
            if v > -0.15 + 0.12 * math.sin(u * 9.0 + an.fases[3]) and alem < 0:
                continue                            # na frente: o corte (vazio)
            if pl[1] < an.rect[1] - FAIXA_FUNDO or alem > FAIXA_PONTAS:
                continue                            # longe demais: a terra de fundo aparece
            if pl[0] > an.c[0] and (alem > -30 or u > 0.8 and v > -0.6):
                continue                            # a ponta leste: aberta pro poço e pra espiral
            if abs((axy[0] - axy[1]) - POCO) < LARGURA_POCO and axy[0] + axy[1] < soma_gaiola:
                continue                            # o poço do elevador, atrás da gaiola
            if (axy[0] - axy[1]) > POCO + LARGURA_POCO + 10:
                continue                            # Bloco 75: a leste do poço é a espiral (o poço dela)
            if axy[0] < OX + 8:
                continue                            # Bloco 75: a parede oeste da coluna fica no alinhamento do mapa
            rocha_de[(i, j)] = True
    # anel de cada rocha (1 = encostada no chão): perto do chão a rocha é mais baixa (saliências e
    # prateleiras em degraus, como parede de caverna); do 3º anel pra trás sobe inteira
    anel = {}
    fila = [t for t in rocha_de if any(v in piso or v in rio for v in ((t[0] + 1, t[1]), (t[0], t[1] + 1), (t[0] - 1, t[1]), (t[0], t[1] - 1)))]
    for t in fila:
        anel[t] = 1
    while fila:
        nova = []
        for (i, j) in fila:
            for v in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
                if v in rocha_de and v not in anel:
                    anel[v] = anel[(i, j)] + 1
                    nova.append(v)
        fila = nova
    if tema == "abismo":  # Bloco 76: o rio de lava ao pé da parede — as 2 fileiras de rocha logo atrás do chão
        cols = sorted({i for i, _ in piso})
        lo, hi = cols[int(len(cols) * 0.03)], cols[int(len(cols) * 0.88)]
        rio = {t for t, r in anel.items() if r == 1 and (t[0], t[1] + 1) in piso and lo <= t[0] <= hi}
        rio |= {(i, j - 1) for (i, j) in rio if anel.get((i, j - 1)) == 2}
        for t in rio:
            rocha_de.pop(t, None)
            anel.pop(t, None)
        for n, i in enumerate(sorted({i for i, _ in rio})[2::7]):
            quedas[i] = ("lava", kc + 4 + (n * 5) % 8)
    # Bloco 76: raízes da floresta de cima descendo do alto da parede (galerias e S2, só a oeste da paliçada)
    raizes = {}  # coluna i -> comprimento (px)
    if tema in ("galerias", "nivel2"):
        for i in i_de:
            x_logica = an.logica(centro_tile(i, min(j_de)))[0]
            hh = (i * 40503) & 0xFF
            if x_logica < PALICADA_X - 20 and hh % 3 != 0:
                raizes[i] = 40 + hh % 90
    cortina = None  # a cachoeira: a coluna da tela (i - j) atrás do fx:cachoeira — o meio dele é a divisa
    if cachoeira:   # entre as colunas qi-qj e qi-qj+1; a cortina tem 2 colunas (64 px) de largura
        cortina = qi - qj
    itens = []
    # a rocha de trás: da laje até a laje do de cima (o nível 2: até a borda de baixo da superfície)
    kb = kc - LAJE + 1
    fs = an.fases
    for (i, j) in rocha_de:
        if acima is None:
            xc = tiles.tela(i, j, kc)[0] + T
            yo = borda_de_baixo(xc, 0, 0, SUP_KB)
            topo = kb
            while yo is not None and topo < kc + 70 and tiles.tela(i, j, topo)[1] + 16 > yo:
                topo += 1
        else:
            topo = acima - LAJE
        r = anel.get((i, j), 9)
        onda = 0.5 + 0.5 * math.sin(i * 0.37 + fs[0]) * math.sin(j * 0.29 + fs[1])
        if r == 1:
            topo = min(topo, kc + 1 + int(4 * onda))
        elif r == 2:
            topo = min(topo, kc + 4 + int(9 * onda))
        for k in range(kb, topo + 1):
            perto = k - kc <= 3
            b = tiles.escolhe(bloco if perto else rocha, i, j, k, False)
            h = ((i * 73856093) ^ (j * 19349663) ^ (k * 83492791)) & 0xFF
            f = (0.7 if perto else 0.6) * (0.86 + 0.22 * h / 255.0) * (1.0 - 0.003 * max(0, k - kc))
            # estratos: faixas de 3 degraus, onduladas ao longo da parede
            camada = int(math.floor((k + 1.6 * math.sin((i - j) * 0.11 + fs[2]) + math.sin((i + j) * 0.07)) / 3.0))
            f *= 1.05 if camada % 2 else 0.86
            if k == topo and r <= 2:
                f *= 1.12  # o topo da saliência pega a luz
            if k < kc:
                f *= 0.82 ** (kc - k)
            bb = tiles.escurece(b, f)
            if i in quedas and r <= 4 and kc <= k <= quedas[i][1]:  # Bloco 76: lava escorrendo pela parede
                bb = pinta_queda(bb, quedas[i], k, k == min(topo, quedas[i][1]))
            elif cortina is not None and k >= kc and cortina - 1 <= i - j <= cortina + 1:  # Bloco 76
                bb = pinta_cortina(bb, (cortina - (i - j)) * T, (cortina + 2 - (i - j)) * T, k)
            elif raizes and 3 <= r <= 4 and i in raizes and k >= topo - raizes[i] // 32 - 1:  # Bloco 76: raízes
                # (só no paredão de altura cheia: raiz vem do teto, não do alto de uma saliência)
                bb = pinta_raiz(bb, i, k, topo, raizes[i])
            itens.append((i + j, k, bb, tiles.tela(i, j, k)))
    # Bloco 76: o rio de lava (no nível do chão, com a laje de rocha embaixo)
    global LAVA
    if rio and LAVA is None:
        LAVA = _lava_tiles()
    for (i, j) in rio:
        top = tiles.escolhe(LAVA, i, j, 7)
        b = tiles.escolhe(bloco, i, j, kc, False).copy()
        b.paste(top, (0, 0), top)
        itens.append((i + j, kc, b, tiles.tela(i, j, kc)))
    margem = {t for t in piso if any((t[0] + a_, t[1] + b_) in rio for a_, b_ in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    # o chão (e a laje embaixo dele onde a frente fica aberta: mais funda e irregular, rocha pendurada)
    for (i, j) in piso:
        if (i + 1, j) not in piso and (i + 1, j) not in rocha_de or (i, j + 1) not in piso and (i, j + 1) not in rocha_de:
            funda = LAJE + int(3 * (0.5 + 0.5 * math.sin(i * 0.53 + fs[3]) * math.cos(j * 0.41 + fs[0])))
            for k in range(kc - funda + 1, kc):
                b = tiles.escolhe(bloco if kc - k < LAJE else rocha, i, j, k, False)
                itens.append((i + j, k, tiles.escurece(b, 0.82 ** (kc - k)), tiles.tela(i, j, k)))
        kind = zona_em(an.logica(centro_tile(i, j)))
        if (i, j) in margem:
            kind = "calor"  # Bloco 76: a margem do rio, rocha rachada com brasa
        elif (i, j) in poca:
            kind = "agua"   # Bloco 76: a poça embaixo da cachoeira
        tex = zchao[kind] if kind and zchao.get(kind) else chao
        top = tiles.escolhe(tex, i, j, 3)
        b = tiles.escolhe(bloco, i, j, kc, False).copy()
        b.paste(top, (0, 0), top)
        itens.append((i + j, kc, b, tiles.tela(i, j, kc)))
    itens += enfeites(an, piso, kc, a.get("tema", an.nome))  # Bloco 75
    img, (tx, ty) = compoe(itens)
    if acima is None:  # a rocha não passa da borda de baixo da superfície (ela é desenhada atrás)
        px = img.load()
        for x in range(img.width):
            yo = borda_de_baixo(tx + x + 0.5, 0, 0, SUP_KB)
            if yo is None:
                continue
            for y in range(0, max(0, min(img.height, int(yo) - ty))):
                px[x, y] = (0, 0, 0, 0)
        bb = img.getbbox()
        img = img.crop(bb)
        tx, ty = tx + bb[0], ty + bb[1]
    # a quina da direita do chão (o patamar da espiral liga ali)
    i, j = max(piso, key=lambda t: (t[0] - t[1], -(t[0] + t[1])))
    x, y = tiles.tela(i, j, kc)
    return img, (tx, ty), piso, (y + 16, x + 64)


def desenha_poco(topo_y, fundo_y, x_centro):
    """o poço do elevador: rasgo escuro na rocha com as guias de madeira e o cabo, do pé da superfície
    até a gaiola do último andar (atrás dos andares: o chão de cada um cobre o pé das guias)."""
    rnd = random.Random(29)
    W = LARGURA_POCO * 2 + 24
    H = int(fundo_y - topo_y) + 24
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = W // 2
    for y in range(0, H, 2):
        e = 8 + int(5 * math.sin(y * 0.045) + rnd.random() * 4)
        dd = 8 + int(5 * math.sin(y * 0.038 + 2.0) + rnd.random() * 4)
        xa, xb = e, W - dd
        for x in range(xa, xb, 2):
            k = 0.55 + 0.45 * abs((x - cx) / (W / 2))
            c = (int(20 * k), int(18 * k), int(18 * k), 255)
            d.rectangle([x, y, x + 1, y + 1], fill=c)
        d.rectangle([xa - 2, y, xa - 1, y + 1], fill=(56, 48, 42, 255))
        d.rectangle([xb, y, xb + 1, y + 1], fill=(40, 34, 30, 255))
    madeira = [(92, 64, 40), (74, 50, 32), (58, 40, 26)]
    contorno = (22, 16, 12)
    # travessas a cada 48 px (atrás das guias)
    for y in range(10, H, 48):
        d.rectangle([cx - 30, y, cx + 30, y + 5], fill=madeira[2], outline=contorno)
    for gx in (cx - 24, cx + 18):  # as duas guias
        d.rectangle([gx, 0, gx + 6, H], fill=madeira[1], outline=contorno)
        d.line([(gx + 2, 0), (gx + 2, H)], fill=madeira[0])
    d.line([(cx - 3, 0), (cx - 3, H)], fill=(120, 116, 110))  # o cabo
    d.line([(cx - 2, 0), (cx - 2, H)], fill=(70, 68, 66))
    return img, (int(x_centro - W / 2), int(topo_y))


def contorno_terra(imagens, topo_de):
    """o corpo de terra em volta da coluna (tela do jogo): pelas linhas da tela, do ponto mais à
    esquerda ao mais à direita de tudo que é desenhado, com folga e borda irregular, afinando no fundo."""
    PASSO = 24
    y0 = min(p[1] for _, p in imagens)
    y1 = max(p[1] + im.height for im, p in imagens)
    linhas = []
    for y in range(int(y0), int(y1) + 1, PASSO):
        xs = []
        for im, (px, py) in imagens:
            if not (py <= y < py + im.height):
                continue
            row = im.crop((0, int(y - py), im.width, int(y - py) + 1)).getbbox()
            if row:
                xs += [px + row[0], px + row[2]]
        if xs:
            linhas.append((y, min(xs), max(xs)))
    # folga e suavização (máximo numa janela: nada de dente entrando na coluna)
    jan = 6
    rnd = random.Random(72)
    esq, dir_ = [], []
    for n, (y, a, b) in enumerate(linhas):
        viz = linhas[max(0, n - jan): n + jan + 1]
        esq.append((y, min(v[1] for v in viz) - 110 - rnd.randrange(40)))
        dir_.append((y, max(v[2] for v in viz) + 110 + rnd.randrange(40)))
    # o fundo afina até um bico (lado direito descendo, depois o esquerdo subindo)
    yb = linhas[-1][0]
    xa, xb = esq[-1][1], dir_[-1][1]
    pts = [(esq[0][1], topo_de(esq[0][1]) - 40), (dir_[0][1], topo_de(dir_[0][1]) - 40)]
    pts += [(x, y) for y, x in dir_ if y > topo_de(x)]
    for s in range(1, 8):
        t = (s / 8.0) ** 0.8
        pts.append((xb - (xb - xa) * 0.5 * t + rnd.randrange(-20, 20), yb + 60 * s + rnd.randrange(20)))
    pts.append(((xa + xb) / 2, yb + 520))
    for s in range(7, 0, -1):
        t = (s / 8.0) ** 0.8
        pts.append((xa + (xb - xa) * 0.5 * t + rnd.randrange(-20, 20), yb + 60 * s + rnd.randrange(20)))
    pts += [(x, y) for y, x in reversed(esq) if y > topo_de(x)]
    return [[round(x, 1), round(y, 1)] for x, y in pts]


def faixa_terra(topo_de):
    """a faixa fina de terra embaixo das duas faces da frente do mapa (tela do jogo)."""
    rnd = random.Random(7)
    esq = (OX - FACE_AY, (OX + FACE_AY) / 2.0 - SUP_KB * 32)          # canto oeste da face sul
    frente = (OX + NI * T - FACE_AY, (OX + NI * T + FACE_AY) / 2.0 - SUP_KB * 32)
    dir_ = (OX + NI * T - OY, (OX + NI * T + OY) / 2.0 - SUP_KB * 32)  # canto norte da face leste
    cima = [esq, frente, dir_]
    baixo = []
    for (a, b) in ((esq, frente), (frente, dir_)):
        n = int(abs(b[0] - a[0]) / 48)
        for s in range(n + 1):
            t = s / n
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            baixo.append((x, y + 70 + rnd.randrange(60)))
    pts = cima + list(reversed(baixo))
    return [[round(x, 1), round(y, 1)] for x, y in pts]


def main(pasta):
    os.makedirs(pasta, exist_ok=True)
    rocha = [tinge(b, TOM_ROCHA) for b in ld(REL + "/rocha/bloco.png") + ld(REL + "/rocha/bloco_[0-9].png")]
    meta ={"fator": FATOR, "escala": K, "nivel_arte": 32, "poco_x": POCO, "andares": {}}
    acima = None      # degrau do chão do andar de cima; None = a superfície
    quinas = []
    gaiolas = []
    desenhos = []     # (imagem, posição na tela do jogo) pro corpo de terra
    # Bloco 75: a faixa das galerias de madeira (terra marrom, trilho, vagonetes) — só desenho
    gal = Andar("galerias", GALERIAS, 71)
    ref = Andar("nivel2", ANDARES["nivel2"], 72)
    gal.centro = (ref.centro[0], FACE_AY - gal.hh)
    terra_blocos = ld(REL + "/colonia/bloco.png") + ld(REL + "/colonia/bloco_[0-9].png")
    img, (tx, ty), piso_g, _ = desenha_andar(gal, dict(GALERIAS, tema="galerias"), None, terra_blocos)
    img.save(os.path.join(pasta, "galerias.png"))
    tela = tela_jogo(tx, ty)
    desenhos.append((img, tela))
    gxs = [OX + i * T for i, _ in piso_g]
    gys = [OY + j * T for _, j in piso_g]
    meta["galerias"] = {"img": "galerias.png", "tela": [tela[0], tela[1]], "z_chao": gal.kc * 32,
                        "caixa": [min(gxs), min(gys), max(gxs) + T - min(gxs), max(gys) + T - min(gys)],
                        "z": [(gal.kc - LAJE) * 32, gal.kc * 32]}
    print("galerias chão %d tiles, k=%d, imagem %dx%d" % (len(piso_g), gal.kc, img.width, img.height))
    acima = gal.kc
    for n, (nome, a) in enumerate(ANDARES.items()):
        an = Andar(nome, a, 72 + n)
        an.cobre(conteudo(nome, a))
        tom = TOM_ANDAR.get(nome)
        img, (tx, ty), piso, quina = desenha_andar(an, a, acima, [tinge(b, tom) for b in rocha] if tom else rocha)
        img.save(os.path.join(pasta, "andar_%s.png" % nome))
        quinas.append(quina)
        tela = tela_jogo(tx, ty)
        desenhos.append((img, tela))
        ga = an.arte(an.gaiola)
        gaiolas.append((ga[0] - ga[1], (ga[0] + ga[1]) / 2.0 - an.kc * 32))
        xs = [OX + i * T for i, _ in piso]
        ys = [OY + j * T for _, j in piso]
        x, y, w, h = a["rect"]
        meta["andares"][nome] = {
            "img": "andar_%s.png" % nome, "tela": [tela[0], tela[1]],
            "rect": [x, y, w, h], "z_chao": an.kc * 32, "k": K,
            "centro_arte": [round(an.centro[0], 2), round(an.centro[1], 2)],
            # caixa (na vista, px de arte): o chão inteiro, da laje até o chão
            "caixa": [min(xs), min(ys), max(xs) + T - min(xs), max(ys) + T - min(ys)],
            "z": [(an.kc - LAJE) * 32, an.kc * 32],
            "gaiola": [round(an.gaiola[0], 1), round(an.gaiola[1], 1)],
            "contorno": an.contorno()}
        fora = [p for p, r in conteudo(nome, a) if not an.dentro(p)]
        print("%-7s chão %d tiles, chão k=%d, imagem %dx%d, gaiola (%.0f, %.0f)%s" % (
            nome, len(piso), an.kc, img.width, img.height, an.gaiola[0], an.gaiola[1],
            ("  FORA DO CHÃO: %s" % fora) if fora else ""))
        acima = an.kc
    # o poço do elevador (atrás dos andares, na vertical das gaiolas)
    px_poco = py_de_jogo(POCO, 0)[0]
    topo_poco = borda_de_baixo(px_poco + T, 0, 0, SUP_KB) - 16
    fundo_poco = py_de_jogo(0, gaiolas[-1][1])[1] + 8
    img, (ex, ey) = desenha_poco(topo_poco, fundo_poco, px_poco)
    img.save(os.path.join(pasta, "poco.png"))
    meta["poco"] = {"img": "poco.png", "tela": list(tela_jogo(ex, ey))}
    desenhos.append((img, tuple(meta["poco"]["tela"])))
    print("poço     imagem %dx%d" % img.size)
    # a escada em espiral, à direita do poço, com um patamar na quina da direita de cada andar
    import espiral
    xc = px_poco + ESPIRAL_DX
    topo = borda_de_baixo(xc + T, 0, 0, SUP_KB) - 8
    img, (sx, sy) = espiral.desenha(topo, quinas[-1][0] + 40, xc, quinas)
    img.save(os.path.join(pasta, "espiral.png"))
    meta["espiral"] = {"img": "espiral.png", "tela": list(tela_jogo(sx, sy))}
    desenhos.append((img, tuple(meta["espiral"]["tela"])))
    print("espiral  imagem %dx%d" % img.size)
    # a terra: o corpo em volta da coluna e a faixa embaixo das faces do mapa (polígonos na tela do jogo)
    def topo_de(gx):
        # (Bloco 75: fora da largura da superfície vale a borda mais perto — nada de ponta pro céu)
        x0, x1 = OX - FACE_AY, OX + NI * T - OY
        y = borda_de_baixo(py_de_jogo(min(max(gx, x0 + 2), x1 - 2), 0)[0] + T, 0, 0, SUP_KB)
        return tela_jogo(0, y)[1] if y is not None else -1e9
    meta["terra"] = {"coluna": contorno_terra(desenhos, topo_de), "faixa": faixa_terra(topo_de)}
    json.dump(meta, open(os.path.join(pasta, "andares.json"), "w"), indent=1)
    print("andares.json  (gaiolas na tela: %s)" % ", ".join("(%.0f, %.0f)" % g for g in gaiolas))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(RAIZ, "assets", "game", "iso", "mapa"))
