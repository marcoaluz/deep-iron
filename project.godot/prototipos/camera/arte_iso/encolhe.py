"""PROTÓTIPO: deixa um personagem mais baixo SEM reescalar (pixel art não aceita escala
quebrada): tira linhas inteiras em alturas fixas acima do pé, as mesmas em todos os quadros
(parado, caminhada, trabalho). O pé (âncora) não mexe; o corpo acima desce.

  python encolhe.py <imagem> <pe_y> <saida> <linhas>
  linhas = alturas acima do pé, separadas por vírgula (ex.: 12,20,28,40,48,56)
"""
import sys
from PIL import Image


def encolhe(im, pe_y, linhas):
    im = im.convert("RGBA")
    tirar = sorted({int(pe_y - d) for d in linhas}, reverse=True)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ys = [y for y in range(im.height) if y not in tirar]
    # as linhas que ficam descem pra encostar no pé: monta de baixo pra cima
    dst = im.height - 1
    for y in reversed(ys):
        out.paste(im.crop((0, y, im.width, y + 1)), (0, dst))
        dst -= 1
    return out   # as linhas abaixo do pé não mudam de lugar: o pé fica na mesma linha


# linhas a tirar, em ordem de prioridade (altura acima do pé): canela, joelho, coxa, quadril,
# barriga, peito... O corte de n linhas usa as n primeiras.
PRIORIDADE = [10, 17, 24, 31, 40, 50, 58, 64, 45, 35]
# corte aprovado pelo Marco (2026-09-30): mulher 3-4 px abaixo do homem da mesma função
CORTE = {"mineradora": 8, "guarda_mulher": 6, "cozinheira": 6, "engenheira": 4, "pesquisadora": 3, "lenhadora": 3}


def linhas(n):
    return sorted(PRIORIDADE[:n])


def pe_de(im):
    a = im.convert("RGBA").split()[3].point(lambda v: 255 if v > 40 else 0)
    return a.getbbox()[3] - 1


if __name__ == "__main__":
    im = Image.open(sys.argv[1])
    encolhe(im, int(sys.argv[2]), [int(v) for v in sys.argv[4].split(",")]).save(sys.argv[3])
