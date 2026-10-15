"""Bloco 138: os BLOCOS NÃO VAZIOS de cada pedaço do terreno (blocos.json, ao lado do mapa.json).

A vista iso (iso_view.gd _em_blocos) parte cada pedaço do terreno em blocos de 256 px e só cria os que têm desenho.
Antes ela descobria isso lendo a textura de volta da placa de vídeo a cada abertura da partida (~0,75 s); agora lê
esta lista. Rode depois de mudar qualquer PNG do terreno (o monta.py exporta e o andares.py já chamam no fim):

    python blocos.py [pasta]        (padrão: ../../../../assets/game/iso/mapa)

O teste b138 confere que a lista bate com os PNGs (lista velha = blocos faltando no mapa).
"""
import json
import os
import sys

from PIL import Image

BLOCO = 256  # = iso_view.gd TERRAIN_BLOCK


def _imagens(pasta):
    """Os PNGs que viram terreno: as regiões do mapa.json e as galerias/andares do andares.json."""
    nomes = []
    mapa = os.path.join(pasta, "mapa.json")
    if os.path.exists(mapa):
        nomes += [r["img"] for r in json.load(open(mapa, encoding="utf-8")).get("regioes", {}).values()]
    andares = os.path.join(pasta, "andares.json")
    if os.path.exists(andares):
        a = json.load(open(andares, encoding="utf-8"))
        if a.get("galerias", {}).get("img"):
            nomes.append(a["galerias"]["img"])
        nomes += [v["img"] for v in a.get("andares", {}).values() if v.get("img")]
    return sorted(set(nomes))


def blocos_de(caminho):
    """[largura, altura, [índices dos blocos com desenho]] (índice = bx + by * colunas, em ordem de linha)."""
    im = Image.open(caminho)
    w, h = im.size
    alfa = im.getchannel("A") if "A" in im.getbands() else None
    cols = (w + BLOCO - 1) // BLOCO
    usados = []
    for y in range(0, h, BLOCO):
        for x in range(0, w, BLOCO):
            if alfa is None or alfa.crop((x, y, min(x + BLOCO, w), min(y + BLOCO, h))).getbbox() is not None:
                usados.append(x // BLOCO + (y // BLOCO) * cols)
    return [w, h, usados]


def main(pasta):
    saida = {}
    for nome in _imagens(pasta):
        p = os.path.join(pasta, nome)
        if os.path.exists(p):
            saida[nome] = blocos_de(p)
    json.dump({"bloco": BLOCO, "imagens": saida}, open(os.path.join(pasta, "blocos.json"), "w", encoding="utf-8"),
              separators=(",", ":"))
    print("blocos.json: %d imagens, %d blocos" % (len(saida), sum(len(v[2]) for v in saida.values())))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                             "../../../../assets/game/iso/mapa"))
