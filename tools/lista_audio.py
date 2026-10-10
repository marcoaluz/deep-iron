#!/usr/bin/env python
"""Bloco 114: gera docs/AUDIO_ARQUIVOS.md — a lista de TODOS os arquivos de som que o jogo espera
(project.godot/data/audio/slots.json), com o nome exato, onde toca e se o arquivo ja existe.

    python tools/lista_audio.py

Arquivo novo = por na pasta project.godot/assets/audio/<id>.ogg (ou .wav / .mp3) com o nome da lista; o jogo acha sozinho.
"""
import json
import os
import sys

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SLOTS = os.path.join(RAIZ, "project.godot", "data", "audio", "slots.json")
PASTA = os.path.join(RAIZ, "project.godot", "assets", "audio")
SAIDA = os.path.join(RAIZ, "docs", "AUDIO_ARQUIVOS.md")
EXTENSOES = ["ogg", "wav", "mp3"]

TITULOS = {
    "ambiencia": "Ambiência (loops por andar e por clima)",
    "predios": "Prédios (loops posicionais e sinos)",
    "stingers": "Stingers (eventos do jogo)",
    "ui": "Interface (bus UI)",
    "passos": "Passos por tipo de chão",
    "voz": "Voz curta dos ipezinhos (desligável)",
    "musica": "Música: abertura e introdução",
    "intro": "Sons da introdução",
}
TIPOS = {"loop": "loop", "loop_predio": "loop posicional", "tiro": "toca uma vez", "tema": "música"}


def nomes_esperados(s):
    n = int(s.get("variacoes", 0))
    return [s["id"]] if n <= 0 else ["%s_%d" % (s["id"], i) for i in range(n)]


def existe(nome):
    for ext in EXTENSOES:
        if os.path.exists(os.path.join(PASTA, *(nome + "." + ext).split("/"))):
            return ext
    return ""


def main():
    with open(SLOTS, encoding="utf-8") as f:
        dados = json.load(f)
    slots = dados["slots"]
    por_pasta = {}
    for s in slots:
        por_pasta.setdefault(s["id"].split("/")[0], []).append(s)
    total = sum(len(nomes_esperados(s)) for s in slots)
    prontos = sum(1 for s in slots for n in nomes_esperados(s) if existe(n))
    out = []
    out.append("# Arquivos de som que o jogo espera (Bloco 114)\n")
    out.append("Gerado por `python tools/lista_audio.py` a partir de `project.godot/data/audio/slots.json`. **Não edite à mão.**\n")
    out.append("Os sons NÃO são criados pelo jogo nem pelo código: são gerados fora (ElevenLabs) e postos em "
               "`project.godot/assets/audio/` **com o nome exato abaixo**. O jogo procura `<nome>.ogg`, `<nome>.wav` ou `<nome>.mp3` "
               "(nessa ordem). Sem arquivo o som fica mudo (ou toca o som sintetizado de antes, a *reserva*), sem erro.\n")
    out.append("## Regras dos arquivos\n")
    out.append("- **Formato:** `.ogg` pros loops e músicas (menor), `.wav` ou `.ogg` pros curtos. Depois de pôr arquivos novos: "
               "`godot --headless --path project.godot --import`.\n"
               "- **Loops** (ambiência, prédios, música de abertura): o começo e o fim têm que emendar sem corte; o jogo força a repetição "
               "por código (não precisa marcar loop no import). 20 a 60 s.\n"
               "- **Posicionais** (prédios, passos, voz, sinos): **mono**. Os de interface e stingers podem ser estéreo.\n"
               "- **Variações** (`_0`, `_1`...): arquivos diferentes do mesmo som; o jogo sorteia sem repetir seguido.\n"
               "- **Volume:** normalizar em torno de −16 LUFS, pico abaixo de −1 dB. O jogo ajusta o volume de cada slot (coluna dB) e "
               "tem limitador no Master.\n"
               "- **Ducking:** os slots marcados com `duck` abaixam a música (alarme −9 dB, sino −7 dB, aviso −6 dB).\n")
    out.append("**Resumo:** %d slots, %d arquivos esperados, %d já existem.\n" % (len(slots), total, prontos))
    for pasta in ["ambiencia", "predios", "stingers", "ui", "passos", "voz", "musica", "intro"]:
        lista = por_pasta.get(pasta, [])
        if not lista:
            continue
        out.append("\n## %s\n" % TITULOS.get(pasta, pasta))
        out.append("| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |")
        out.append("|---|---|---|---|---|---|---|")
        for s in lista:
            nomes = nomes_esperados(s)
            arqs = "<br>".join("`%s`" % n for n in nomes)
            tem = [existe(n) for n in nomes]
            estado = "pronto" if all(tem) else ("parcial" if any(tem) else "falta")
            extras = []
            if s.get("duck"):
                extras.append("duck %s" % s["duck"])
            if s.get("eco"):
                extras.append("eco %.2f" % s["eco"])
            if s.get("grupo"):
                extras.append("só perto da câmera (%d px), com o prédio em atividade" % int(s.get("raio", 600)))
            quando = s["quando"] + ((" *(%s)*" % "; ".join(extras)) if extras else "")
            out.append("| %s | %s | %s | %s | %s | %s | %s |" % (
                arqs, TIPOS.get(s.get("tipo", ""), s.get("tipo", "")), s.get("bus", ""), s.get("db", 0),
                quando.replace("|", "/"), "o som de antes" if s.get("reserva") else "mudo", estado))
    texto = "\n".join(out) + "\n"
    with open(SAIDA, "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)
    print("%d slots, %d arquivos esperados, %d prontos -> %s" % (len(slots), total, prontos, SAIDA))


if __name__ == "__main__":
    sys.exit(main())
