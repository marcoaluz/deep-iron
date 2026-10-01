"""PROTÓTIPO: esboço do layout do mapa novo (Prompt 27, passo 1 - pra aprovação do Marco).

  python esboco.py  -> esboco_layout.png (planta vista de cima, coordenadas do chão do jogo)

Coordenadas = as do jogo (chão cartesiano, mesma escala de main.tscn). A planta mostra as
zonas, as alturas (terraços) e onde cada coisa do gameplay fica. Não é a arte final.
"""
from PIL import Image, ImageDraw, ImageFont

ESC = 0.42          # px por unidade do jogo
X0, Y0 = -820, -1080
W, H = 1640, 1560
img = Image.new("RGB", (int(W * ESC) + 300, int(H * ESC) + 60), (28, 26, 24))
d = ImageDraw.Draw(img)
try:
    F = ImageFont.truetype("arial.ttf", 12); FB = ImageFont.truetype("arialbd.ttf", 13); FT = ImageFont.truetype("arialbd.ttf", 16)
except Exception:
    F = FB = FT = ImageFont.load_default()


def P(x, y):
    return (int((x - X0) * ESC) + 10, int((y - Y0) * ESC) + 40)


def R(x0, y0, x1, y1, cor, borda=None, w=1):
    d.rectangle([P(x0, y0), P(x1, y1)], fill=cor, outline=borda, width=w)


def T(x, y, txt, cor=(240, 230, 210), f=None):
    d.text(P(x, y), txt, fill=cor, font=f or F)


def ponto(x, y, cor, txt=None, r=5):
    px, py = P(x, y)
    d.ellipse([px - r, py - r, px + r, py + r], fill=cor, outline=(10, 10, 10))
    if txt:
        d.text((px + r + 3, py - 7), txt, fill=(240, 230, 210), font=F)


d.text((10, 8), "DEEP IRON - esboco do mapa novo (vista de cima, chao do jogo)   |   cor mais clara = terraco mais alto", fill=(255, 230, 150), font=FT)

# 1) FLORESTA (a clareira atual, maior): começo do mapa
R(-760, -1040, 760, -470, (46, 70, 40))
T(-740, -1030, "1  FLORESTA (comeco do mapa) - arvores esparsas, caca, madeira", (200, 230, 170), FB)
for (x, y) in [(-600, -950), (-450, -820), (-300, -980), (-120, -900), (60, -1000), (250, -880), (420, -960), (600, -860),
               (-650, -640), (-520, -560), (520, -600), (650, -700), (300, -560), (-260, -600)]:
    ponto(x, y, (70, 120, 60), None, 7)
ponto(-380, -700, (150, 120, 80), "toca de coelho")
ponto(180, -780, (150, 120, 80), "toca de coelho")
ponto(560, -800, (110, 80, 60), "toca do javali")
ponto(-100, -700, (200, 180, 120), "horta de cogumelos (clareira)")
ponto(-620, -780, (220, 190, 60), "MAQUINA DE CORTAR ARVORES (quebrada -> conserta)", 7)
ponto(380, -700, (160, 160, 160), "robo gigante achado (exploracao)", 6)
# cerca de estacas na borda da floresta com a pedreira
d.line([P(-760, -470), P(-60, -470)], fill=(150, 110, 70), width=4)
d.line([P(60, -470), P(760, -470)], fill=(150, 110, 70), width=4)
T(-740, -500, "cerca de estacas (ate o muro)", (200, 170, 120))

# 2) PORTÃO: a única entrada (onde hoje é o túnel)
R(-60, -490, 60, -440, (120, 90, 60), (255, 200, 80), 2)
T(70, -505, "2  PORTAO (unica entrada) - quebrado -> nivel 1/2/3", (255, 210, 120), FB)
T(70, -488, "   robo gigante fica aqui a noite; invasores entram por aqui", (230, 200, 150))

# 3) PEDREIRA = a área da colônia (map_rect atual), em terraços
R(-720, -440, 720, 440, (70, 64, 58))
R(-720, -440, 720, -180, (112, 104, 94))        # terraço de cima (+2)
R(-560, -180, 560, 160, (92, 86, 78))           # terraço do meio (+1)
T(-700, -432, "3  PEDREIRA - VILA EM TERRACOS", (255, 230, 150), FB)
T(-700, -414, "terraco de cima (+2 degraus): entrada, Centro da Vila, casas", (230, 220, 200))
T(-540, -172, "terraco do meio (+1): oficios e servicos", (230, 220, 200))
T(-700, 420, "fundo da pedreira (0): mina, jazidas, maquinas", (230, 220, 200))
# escadas / rampas entre terraços
for (x, y, t) in [(-80, -180, "escada de pedra"), (380, -180, "rampa (carroca/vagonete)"), (-420, 160, "escada"), (200, 160, "rampa")]:
    R(x - 22, y - 10, x + 22, y + 10, (200, 180, 120), (60, 50, 40))
    T(x + 26, y - 7, t, (220, 210, 170))
# prédios
B = [(-300, -300, "CENTRO DA VILA (raio das casas)"), (-520, -360, "casa"), (-560, -260, "casa"), (-420, -230, "casa"),
     (-160, -360, "casa"), (-80, -260, "casa"), (200, -340, "taverna"), (360, -320, "enfermaria"), (540, -320, "parque"),
     (560, -230, "cozinha"),
     (-460, -60, "OFICINA (forja)"), (-260, -40, "FUNDICAO"), (-60, -80, "ARSENAL"), (120, -60, "ARMAZEM"),
     (300, -100, "laboratorio"), (440, 20, "vestiario"), (-420, 80, "campo de treino"), (-180, 90, "guindaste da pedreira")]
for x, y, t in B:
    R(x - 26, y - 18, x + 26, y + 18, (150, 120, 90), (30, 24, 20))
    T(x + 30, y - 7, t)
# trilho da boca da mina ao armazém
d.line([P(120, -42), P(120, 120), P(0, 300), P(0, 400)], fill=(190, 190, 190), width=3)
T(10, 260, "trilho + vagonete: mina -> armazem", (210, 210, 210))
# bocas de mina no paredão do fundo (galerias lacradas)
for x, y, t in [(-640, 300, "galeria oeste (lacrada)"), (-200, 430, "BOCA DA MINA"), (300, 430, "galeria sudeste (lacrada)"),
                (640, 120, "galeria leste (lacrada)")]:
    R(x - 24, y - 10, x + 24, y + 10, (20, 18, 16), (255, 200, 80))
    T(x - 60, y + 14, t, (255, 210, 120))
# jazidas no fundo
for x, y in [(-560, 240), (-360, 330), (-40, 300), (260, 330), (480, 260), (600, 380)]:
    ponto(x, y, (90, 160, 160), None, 5)
T(420, 300, "jazidas", (150, 210, 210))
# máquinas
R(-700, 180, -600, 300, (120, 80, 50), (255, 160, 60), 2)
T(-700, 162, "PLATAFORMA DE PERFURACAO (escavadeira)", (255, 180, 100), FB)
R(560, 200, 640, 280, (90, 90, 110), (180, 180, 255), 2)
T(470, 182, "ELEVADOR -> nivel 2", (190, 190, 255), FB)
ponto(640, -40, (255, 220, 90), "escudo solar (fim de jogo)", 8)

# 4) NÍVEL 2 e ABISMO: embaixo (como hoje)
T(-700, 470, "4  NIVEL 2 e ABISMO: embaixo da pedreira, pelos elevadores (como hoje)", (190, 190, 255), FB)

# legenda / fluxo
lx = int(W * ESC) + 20
d.text((lx, 50), "FLUXO DO JOGADOR", fill=(255, 230, 150), font=FB)
for k, t in enumerate(["1 floresta: madeira, caca,", "  horta, achar o robo", "2 portao (unica entrada)",
                       "3 pedreira: a vila desce", "  em terracos ate a mina", "4 elevador -> nivel 2 -> abismo",
                       "", "INVASORES", "vem da floresta, pelo portao.", "brecha no muro = roubo", "(regra que o jogo ja usa)",
                       "", "MUDA NO CODIGO", "- 1 portao em vez de 2", "  (sai o do poco)", "- tunel vira portao",
                       "- relevo: terracos com", "  escada/rampa", "- escavadeira vai pro", "  canto oeste",
                       "- predios novos: fundicao,", "  muro/portao, guindaste"]):
    d.text((lx, 72 + k * 16), t, fill=(230, 220, 200), font=F)
img.save("esboco_layout.png")
print(img.size)
