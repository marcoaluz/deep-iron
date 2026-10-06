"""Esboço do layout (hoje x proposta) para o documento."""
import os
from PIL import Image, ImageDraw, ImageFont

import tempfile
SP = tempfile.gettempdir()  # (o esboço é gerado de novo a cada vez)


def _fonte(t):
    for f in ("C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, t)
    return ImageFont.load_default()


def esboco_layout():
    """A tela de hoje (em cima) x a proposta (embaixo), 800x450 cada, só caixas e nomes."""
    W, H, Y = 800, 450, 34
    out = Image.new("RGB", (W, (H + Y) * 2 + 10), (30, 26, 22))
    d = ImageDraw.Draw(out)
    f, fp, ft = _fonte(14), _fonte(12), _fonte(20)

    def caixa(oy, r, cor, linhas, fonte=f):
        x0, y0, x1, y1 = r
        d.rectangle((x0, oy + y0, x1, oy + y1), fill=cor, outline=(205, 175, 125), width=2)
        d.multiline_text((x0 + 6, oy + y0 + 4), "\n".join(linhas), fill=(248, 238, 218), font=fonte, spacing=2)

    for k, titulo in enumerate(("HOJE", "PROPOSTA")):
        oy = k * (H + Y + 10)
        d.text((6, oy + 6), titulo, fill=(240, 190, 110), font=ft)
        d.rectangle((0, oy + Y, W, oy + Y + H), fill=(74, 66, 52))
    oy = Y
    caixa(oy, (0, 0, 800, 26), (55, 40, 30), ["relógio | créditos | minério | Vender | auto | madeira | matéria | comida | camas | ânimo | estação | velocidade"], fp)
    caixa(oy, (6, 32, 206, 300), (62, 46, 36), ["FORÇA DE TRABALHO", "lista de TODOS os", "ipezinhos, 3 barras", "cada, sempre aberta", "", "= 25% da largura"])
    caixa(oy, (668, 40, 794, 370), (62, 46, 36), ["CONSTRUÇÕES", "15 botões de texto", "(muitos cortados)", "", "Vila: Acamp...", "Trabalhadores...", "Armazém: 41...", "Coletor (ruína)...", "Calendário: Mis...", "..."], fp)
    caixa(oy, (290, 150, 470, 190), (100, 84, 40), ["Centro da Vila", "Acampamento (rótulo grande)"], fp)
    caixa(oy, (0, 398, 800, 450), (55, 40, 30), ["                  Construir | Min | Caç | Méd | Eng | Coz | Len | Gua | Pes | Fun | Fer | Pad | Sem | Turno"], fp)
    caixa(oy, (6, 372, 120, 450), (90, 60, 42), ["cartão do", "selecionado", "(cobre o", "Construir)"], fp)
    oy = 2 * Y + H + 10
    caixa(oy, (0, 0, 800, 26), (55, 40, 30), ["créditos  minério  madeira  comida(hoje)  camas  ânimo        [ 17:38  QUA  dia 3 ]        estação   pausa 1x 2x 4x pular"], fp)
    caixa(oy, (6, 32, 44, 250), (62, 46, 36), ["P", "", "A", "", "O", "", "M"], f)
    caixa(oy, (50, 32, 250, 140), (62, 46, 36), ["Pessoas (abre com Tab", "ou passando o mouse)", "Ociosos: 2", "Com problema: 1"], fp)
    caixa(oy, (722, 40, 794, 250), (62, 46, 36), ["ALERTAS", "comida 0", "obra 2", "ferido 1", "invasão", "  21h"], fp)
    caixa(oy, (560, 262, 794, 380), (90, 60, 42), ["MISSÃO ATUAL", "Cap. 2  Fogo e ferro", "[ ] 10 barras de ferro", "[x] igreja", "[ ] 2 lanças"], fp)
    caixa(oy, (6, 290, 190, 388), (90, 60, 42), ["cartão do selecionado", "(acima da barra,", "sem cobrir nada)"], fp)
    caixa(oy, (330, 160, 450, 182), (100, 84, 40), ["Centro da Vila"], fp)
    caixa(oy, (0, 398, 800, 450), (55, 40, 30), ["[Construir] | PRODUÇÃO: Min Len Caç Coz Fun Fer | SERVIÇO: Eng Méd Pes Pad | DEFESA: Gua | [Sem] [Turno]",
                                               "(botões de ícone com contador; o nome aparece na dica)"], fp)
    d.text((54, oy + 258), "P = pessoas   A = alertas   O = obras   M = missões", fill=(230, 220, 200), font=fp)
    p = os.path.join(SP, "esboco_layout.png")
    out.save(p)
    return p
