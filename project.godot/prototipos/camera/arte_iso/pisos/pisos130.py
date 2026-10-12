"""Bloco 130: PISOS (caminhos) — dos ladrilhos do PixelLab ao atlas que o jogo usa.

A FONTE são as folhas que o Marco gerou no PixelLab (docs/arte/chão -> docs/arte/bloco130/fontes/):
  cascalho.png  4x4 ladrilhos de 64x48 (cascalho, brita, cinza, areia...)
  pedra.png     4x4 (lajes e paralelepípedos, musgo, rachado)
  terra.png     4x4 (terra batida com sulcos e tufos de mato)
Cada ladrilho: o losango de 64x32 (2:1) em cima + a laje de 16 px embaixo. A célula do caminho do jogo é de 64/3 px do
chão (= 32 px de arte de cada lado do losango, em escala 1,5: o losango da célula é exatamente 64x32).

O ATLAS (assets/game/iso/pisos/pisos.png), por tipo: VARIANTES colunas x 4 linhas de 64x64:
  coluna = a variação do ladrilho (escolhida por hash da célula, então um trecho nunca "muda");
  linha  = que laterais ficam à mostra: 0 nenhuma, 1 só a da esquerda (sem vizinho em +y: o chão cai pra SW), 2 só a da direita
           (sem vizinho em +x: cai pra SE), 3 as duas. A laje só aparece onde o caminho acaba; entre dois ladrilhos
           vizinhos só o topo — a trilha lê contínua (a emenda automática pelos vizinhos).
O losango fica no MEIO da célula (o centro dela é o do chão) e a laje embaixo.

Uso:
  python pisos130.py integra     grava assets/game/iso/pisos/pisos.png + pisos.json
  python pisos130.py cartoes     regrava cam_terra/cascalho/pedra.png (96x64) do CONSTRUIR com a MESMA arte
  python pisos130.py folha       a folha de conferência (docs/arte/bloco130/folha_atlas.png)
"""
import json
import os
import sys

from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, "..", "..", "..", ".."))  # project.godot
DOCS = os.path.abspath(os.path.join(RAIZ, "..", "docs", "arte", "bloco130"))
SAIDA = os.path.join(RAIZ, "assets", "game", "iso", "pisos")

W, H = 64, 32  # o losango da célula (px de arte)
ESP = 16  # a laje
FONTE_W, FONTE_H = 64, 48  # o ladrilho na folha
CEL_H = H + 2 * ESP  # a célula do atlas: o losango no meio (centro = centro do losango), a laje embaixo
TIPOS = ["terra", "cascalho", "pedra"]
VARIANTES = 8
LINHAS_EXPOSICAO = 4
# Que ladrilhos de cada folha (índice de 0 a 15, linha por linha) entram como variação. Só os parecidos entre si: os que têm
# desenho próprio (o "Y" escuro, as faixas, o aro de musgo) não servem de chão corrido.
ESCOLHA = {
    "terra": [1, 2, 5, 6, 9, 10, 13, 14],
    "cascalho": [0, 7, 8, 14, 6, 0, 7, 8],  # o castanho-claro e o escuro de brita (sem o cinza e o preto: remendo demais)
    "pedra": [7, 10, 12, 14, 8, 0, 10, 12],  # o paralelepípedo marrom (um com musgo, um rachado)
}


def ladrilho(tipo, indice):
    folha = Image.open(os.path.join(DOCS, "fontes", tipo + ".png")).convert("RGBA")
    c, r = indice % 4, indice // 4
    return folha.crop((c * FONTE_W, r * FONTE_H, c * FONTE_W + FONTE_W, r * FONTE_H + FONTE_H))


def parte_de_cima_e_lados(til):
    """(topo, esq, dir): o losango (com o contorno) e as duas lajes de baixo, cada uma na posição do ladrilho."""
    y0 = til.getbbox()[1]
    topo = Image.new("RGBA", (W, H + ESP), (0, 0, 0, 0))
    esq = Image.new("RGBA", (W, H + ESP), (0, 0, 0, 0))
    dir_ = Image.new("RGBA", (W, H + ESP), (0, 0, 0, 0))
    pt = til.load()
    pT, pE, pD = topo.load(), esq.load(), dir_.load()
    for y in range(y0, min(FONTE_H, y0 + H + ESP)):
        for x in range(W):
            px = pt[x, y]
            if px[3] == 0:
                continue
            # a aresta de baixo da face de cima: do vértice esquerdo (y = H/2) ao de baixo (y = H-1) e de volta
            borda = H / 2.0 + (H / 2.0 - 1.0) * (1.0 - abs(x - (W - 1) / 2.0) / ((W - 1) / 2.0))
            yy = y - y0
            if yy <= borda + 0.5:
                pT[x, yy] = px
            elif x < W // 2:
                pE[x, yy] = px
            else:
                pD[x, yy] = px
    # O ladrilho tem os cantos chanfrados e a borda um pouco pra dentro do losango: lado a lado ficam frestas. A "argamassa"
    # (o losango inteiro, no preto do contorno) por baixo fecha a trilha: as frestas viram juntas escuras, como numa calçada.
    base = Image.new("RGBA", (W, H + ESP), (0, 0, 0, 0))
    cor = (26, 19, 17, 255)  # o preto-quente do contorno dos ladrilhos (a mesma cor em todos: a junta lê como contorno)
    ImageDraw.Draw(base).polygon([((W - 1) / 2.0, 0), (W - 1, (H - 1) / 2.0), ((W - 1) / 2.0, H - 1), (0, (H - 1) / 2.0)], fill=cor)
    base.alpha_composite(topo)
    return base, esq, dir_


def atlas_do_tipo(tipo):
    atlas = Image.new("RGBA", (W * VARIANTES, CEL_H * LINHAS_EXPOSICAO), (0, 0, 0, 0))
    for v, idx in enumerate(ESCOLHA[tipo]):
        topo, esq, dir_ = parte_de_cima_e_lados(ladrilho(tipo, idx))
        for exp in range(LINHAS_EXPOSICAO):
            peca = Image.new("RGBA", (W, H + ESP), (0, 0, 0, 0))
            if exp & 1:
                peca.alpha_composite(esq, (0, 0))
            if exp & 2:
                peca.alpha_composite(dir_, (0, 0))
            peca.alpha_composite(topo, (0, 0))  # (o topo cobre a emenda da laje)
            atlas.alpha_composite(peca, (v * W, exp * CEL_H + ESP))
    return atlas


def atlas_geral():
    g = Image.new("RGBA", (W * VARIANTES, CEL_H * LINHAS_EXPOSICAO * len(TIPOS)), (0, 0, 0, 0))
    for i, tipo in enumerate(TIPOS):
        g.alpha_composite(atlas_do_tipo(tipo), (0, CEL_H * LINHAS_EXPOSICAO * i))
    return g


def integra():
    os.makedirs(SAIDA, exist_ok=True)
    atlas_geral().save(os.path.join(SAIDA, "pisos.png"))
    dados = {"largura": W, "altura": H, "celula_h": CEL_H, "espessura": ESP, "colunas": VARIANTES, "variantes": VARIANTES,
             "tipos": TIPOS, "linhas_por_tipo": LINHAS_EXPOSICAO}
    json.dump(dados, open(os.path.join(SAIDA, "pisos.json"), "w", encoding="utf-8"), indent=1)
    print("integrado em", SAIDA)


def trecho(tipo, celulas, fundo=None, escala=1):
    """Monta um trecho de caminho do jeito do jogo (de trás pra frente, a laje só onde o caminho acaba)."""
    atlas = atlas_do_tipo(tipo)
    xs = [(c[0] - c[1]) * (W // 2) for c in celulas]
    ys = [(c[0] + c[1]) * (H // 2) for c in celulas]
    pad = 8
    img = Image.new("RGBA", (max(xs) - min(xs) + W + pad * 2, max(ys) - min(ys) + CEL_H + pad * 2), (fundo or (0, 0, 0, 0)))
    ox, oy = pad - min(xs), pad - min(ys)
    for (cx, cy) in sorted(celulas, key=lambda c: (c[0] + c[1], c[0])):
        x = (cx - cy) * (W // 2) + ox
        y = (cx + cy) * (H // 2) + oy
        v = abs((cx * 73856093) ^ (cy * 19349663)) % VARIANTES
        exp = 0
        if (cx, cy + 1) not in celulas:
            exp |= 1
        if (cx + 1, cy) not in celulas:
            exp |= 2
        img.alpha_composite(atlas.crop((v * W, exp * CEL_H, v * W + W, exp * CEL_H + CEL_H)), (x, y))
    if escala != 1:
        img = img.resize((img.width * escala, img.height * escala), Image.NEAREST)
    return img


def folha():
    celulas = {(i, 0) for i in range(6)} | {(5, j) for j in range(1, 5)} | {(i, j) for i in range(1, 4) for j in range(2, 4)}
    fundo = (104, 92, 66, 255)
    ims = [trecho(t, celulas, fundo, 1) for t in TIPOS]
    s = Image.new("RGBA", (sum(i.width for i in ims), max(i.height for i in ims)), fundo)
    x = 0
    for i in ims:
        s.alpha_composite(i, (x, 0))
        x += i.width
    s.save(os.path.join(DOCS, "folha_atlas.png"))
    print("folha:", s.size)


def cartoes():
    cart = os.path.join(RAIZ, "assets", "game", "ui", "icones", "cartoes")
    for tipo in TIPOS:
        im = trecho(tipo, {(0, 0), (1, 0)})
        im = im.crop(im.getbbox())
        cartao = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
        cartao.alpha_composite(im, ((96 - im.width) // 2, (64 - im.height) // 2))
        cartao.save(os.path.join(cart, "cam_%s.png" % tipo))
        print("cartão cam_%s.png" % tipo, im.size)


if __name__ == "__main__":
    {"integra": integra, "cartoes": cartoes, "folha": folha}[sys.argv[1]]()
