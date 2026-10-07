"""Prompt 30 (item 2): CONTORNO de 1 px quase preto (regra do CONTRATO_ARTE.md: "Crisp 1px
near-black outline") nos desenhos que vieram sem ele.

  python tools/contorno.py [--antes <pasta>]   -> aplica em ALVOS (no lugar), guarda o antes

Cada pixel desenhado que encosta no transparente (vizinho de 4) e ainda é claro vira a própria cor
escurecida (mantém o tom, fica quase preto). Já escuro: fica igual — dá pra rodar de novo sem
mudar nada. O integra.py chama `aplica()` depois de copiar a arte, pra o contorno não se perder.
"""
import sys, os, glob, shutil
import numpy as np
from PIL import Image

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "project.godot", "assets", "game", "iso"))
# relativos a assets/game/iso (glob)
ALVOS = ["predios/escavadeira/peca_*.png", "predios/escavadeira/reator_*.png",
         "predios/portao/quebrado.png", "predios/campo_treino/obra_1.png",
         "bonecos/casaco_civil/caminhada_NE*.png", "bonecos/casaco_engenheira/caminhada_NE*.png",
         "bonecos/casaco_engenheiro/caminhada_NE*.png", "bonecos/casaco_lenhadora/caminhada_NE*.png",
         "props/arvore_betula_*.png", "props/toco_betula.png", "props/horta_pronto.png"]
# Exceção (como o chão no contrato): capim e flores ficam SEM contorno — são folhas de 1 px; o
# contorno viraria uma mancha escura.
CLARO = 0.22    # valor (max RGB) acima disso, na borda, recebe contorno
FATOR = 0.3     # cor do contorno = a própria cor x isso


def contorna(path):
    a = np.array(Image.open(path).convert("RGBA")).astype(np.float32)
    op = a[..., 3] > 40
    pad = np.pad(op, 1, constant_values=False)
    viz = pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
    borda = op & ~viz
    v = a[..., :3].max(-1) / 255.0
    m = borda & (v > CLARO)
    n = int(m.sum())
    if n:
        # leva a borda a um valor fixo (abaixo de CLARO): mantém o tom e rodar de novo não muda nada
        k = np.minimum(FATOR, (CLARO * 0.8) / np.maximum(v[m], 1e-3))
        a[..., :3][m] = a[..., :3][m] * k[:, None]
        Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA").save(path)
    return n, int(borda.sum())


def aplica(antes=None):
    tot = 0
    for g in ALVOS:
        for f in sorted(glob.glob(os.path.join(RAIZ, g))):
            if antes:
                d = os.path.join(antes, os.path.relpath(f, RAIZ))
                os.makedirs(os.path.dirname(d), exist_ok=True)
                if not os.path.exists(d):
                    shutil.copy2(f, d)
            n, b = contorna(f)
            tot += n
            print("%-55s %5d de %5d px da borda" % (os.path.relpath(f, RAIZ).replace("\\", "/"), n, b))
    return tot


if __name__ == "__main__":
    antes = sys.argv[sys.argv.index("--antes") + 1] if "--antes" in sys.argv else None
    print("total: %d px" % aplica(antes))
