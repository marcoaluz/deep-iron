#!/usr/bin/env python
"""Bloco 114/115: gera dois documentos a partir de project.godot/data/audio/slots.json:

  docs/AUDIO_ARQUIVOS.md             a lista de TODOS os arquivos de som que o jogo espera (nome exato, onde toca, se já existe)
  docs/AUDIO_PROMPTS_ELEVENLABS.md   o prompt de cada som pro ElevenLabs (tudo, menos a música)

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
SAIDA_PROMPTS = os.path.join(RAIZ, "docs", "AUDIO_PROMPTS_ELEVENLABS.md")
EXTENSOES = ["ogg", "wav", "mp3"]

ORDEM = ["ambiencia", "predios", "stingers", "ui", "sfx", "animais", "perigo", "criaturas", "maquinas", "vida", "passos", "voz", "pontuais", "intro", "musica"]
TITULOS = {
    "ambiencia": "Ambiência (loops por andar, clima e onda solar)",
    "predios": "Prédios e lugares (loops posicionais e sinos)",
    "stingers": "Stingers (eventos do jogo)",
    "ui": "Interface (bus UI)",
    "sfx": "Efeitos do jogo (trabalho, combate, obras, avisos)",
    "animais": "Animais",
    "perigo": "Perigos (radiação)",
    "criaturas": "Criaturas (um som de ataque por espécie)",
    "maquinas": "Máquinas",
    "vida": "Vida na vila (nascimento, casamento, enterro)",
    "passos": "Passos por tipo de chão",
    "voz": "Voz curta dos ipezinhos (desligável)",
    "pontuais": "Sons soltos pelo ambiente (aleatórios)",
    "intro": "Sons da introdução",
    "musica": "Música (FORA do ElevenLabs de efeitos)",
}
TIPOS = {"loop": "loop", "loop_predio": "loop posicional", "tiro": "toca uma vez", "pontual": "solto e aleatório", "tema": "música"}


def nomes_esperados(s):
    n = int(s.get("variacoes", 0))
    return [s["id"]] if n <= 0 else ["%s_%d" % (s["id"], i) for i in range(n)]


def existe(nome):
    for ext in EXTENSOES:
        if os.path.exists(os.path.join(PASTA, *(nome + "." + ext).split("/"))):
            return ext
    return ""


def extras_de(s):
    e = []
    if s.get("global"):
        e.append("sem posição (na tela toda)")
    if s.get("duck"):
        e.append("abaixa a música (%s)" % s["duck"])
    if s.get("eco"):
        e.append("eco %.2f" % s["eco"])
    if s.get("grupo"):
        e.append("só perto da câmera (%d px), com o prédio em atividade" % int(s.get("raio", 600)))
    if s.get("ctx"):
        i = s.get("intervalo", [10, 25])
        e.append("toca a cada %d a %d s enquanto vale: %s" % (i[0], i[1], "/".join(s["ctx"])))
    return e


def lista_arquivos(slots, por_pasta):
    total = sum(len(nomes_esperados(s)) for s in slots)
    prontos = sum(1 for s in slots for n in nomes_esperados(s) if existe(n))
    out = []
    out.append("# Arquivos de som que o jogo espera (Bloco 114/115)\n")
    out.append("Gerado por `python tools/lista_audio.py` a partir de `project.godot/data/audio/slots.json`. **Não edite à mão.** "
               "Os **prompts** de cada som estão em `docs/AUDIO_PROMPTS_ELEVENLABS.md`.\n")
    out.append("Os sons NÃO são criados pelo jogo nem pelo código: são gerados fora (ElevenLabs; a música à parte) e postos em "
               "`project.godot/assets/audio/` **com o nome exato abaixo**. O jogo procura `<nome>.ogg`, `<nome>.wav` ou `<nome>.mp3` "
               "(nessa ordem). Sem arquivo o som fica mudo (ou toca o som sintetizado de antes, a *reserva*), sem erro. "
               "Arquivo novo substitui o sintetizado.\n")
    out.append("## Regras dos arquivos\n")
    out.append("- **Formato:** `.ogg` pros loops e músicas (menor), `.wav` ou `.ogg` pros curtos. Depois de pôr arquivos novos: "
               "`godot --headless --path project.godot --import`.\n"
               "- **Loops** (ambiência, prédios): o começo e o fim têm que emendar sem corte; o jogo força a repetição "
               "por código (não precisa marcar loop no import). 20 a 40 s.\n"
               "- **Posicionais** (prédios, efeitos, passos, voz, sons soltos): **mono**. Os de interface e stingers podem ser estéreo.\n"
               "- **Variações** (`_0`, `_1`...): arquivos diferentes do mesmo som; o jogo sorteia sem repetir seguido.\n"
               "- **Volume:** normalizar em torno de −16 LUFS, pico abaixo de −1 dB. O jogo ajusta o volume de cada slot (coluna dB) e "
               "tem limitador no Master.\n"
               "- **Ducking:** os slots marcados abaixam a música (alarme −9 dB, sino −7 dB, aviso −6 dB).\n")
    out.append("**Resumo:** %d slots, %d arquivos esperados, %d já existem.\n" % (len(slots), total, prontos))
    for pasta in ORDEM:
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
            e = extras_de(s)
            quando = s["quando"] + ((" *(%s)*" % "; ".join(e)) if e else "")
            out.append("| %s | %s | %s | %s | %s | %s | %s |" % (
                arqs, TIPOS.get(s.get("tipo", ""), s.get("tipo", "")), s.get("bus", ""), s.get("db", 0),
                quando.replace("|", "/"), "o som de antes" if s.get("reserva") else "mudo", estado))
    return "\n".join(out) + "\n"


def lista_prompts(slots, por_pasta):
    sem_musica = [s for s in slots if s["id"].split("/")[0] != "musica"]
    arquivos = sum(len(nomes_esperados(s)) for s in sem_musica)
    out = []
    out.append("# Prompts do ElevenLabs — todos os sons do jogo, menos a música (Bloco 115)\n")
    out.append("Gerado por `python tools/lista_audio.py` a partir de `project.godot/data/audio/slots.json` (campos `prompt` e `duracao`). "
               "**Não edite à mão: mude o prompt no `slots.json` e rode a ferramenta.**\n")
    out.append("**%d sons (%d arquivos)**. A música da abertura e da introdução fica de fora (lista no fim).\n" % (len(sem_musica), arquivos))
    out.append("## Como usar\n")
    out.append("1. No ElevenLabs, **Sound Effects**: cole o prompt, ponha a **duração** indicada e gere. Se a ferramenta tiver a opção de **loop**, "
               "ligue nos sons de loop; senão gere 30 a 40 s e emende (cross-fade de 1 a 2 s entre o fim e o começo).\n"
               "2. Os prompts estão em inglês (o modelo entende melhor). Termos fixos: *seamless loop*, *no music*, *no voices*, *close-up*, *dry*.\n"
               "3. **Variações** (`_0`, `_1`...): gere o mesmo prompt várias vezes e guarde takes **diferentes**; o jogo sorteia entre eles.\n"
               "4. Salve com o **nome exato** do título de cada item, em `project.godot/assets/audio/<pasta>/` (`.ogg` ou `.wav`).\n"
               "5. Conferir: `godot --headless --path project.godot --import` e `python tools/lista_audio.py` (a lista mostra o que já tem).\n"
               "6. Os **stingers** são frases curtas de música/efeito (fanfarra, sino com cordas): se o gerador de efeitos não fizer bem, "
               "gere esses oito na ferramenta de música e salve com o mesmo nome.\n"
               "7. As **vozes curtas** (`voz/`) podem sair do Text to Speech em português se preferir fala de verdade: use as frases sugeridas "
               "entre parênteses, em vozes de homem e de mulher com carácter de trabalhador.\n"
               "8. Loops e sons posicionais em **mono**; normalizar em torno de −16 LUFS, pico abaixo de −1 dB.\n")
    n = 0
    for pasta in ORDEM:
        lista = [s for s in por_pasta.get(pasta, []) if pasta != "musica"]
        if not lista:
            continue
        out.append("\n## %s\n" % TITULOS.get(pasta, pasta))
        for s in lista:
            n += 1
            nomes = nomes_esperados(s)
            arq = ", ".join("`%s`" % x for x in nomes)
            tipo = TIPOS.get(s.get("tipo", ""), "")
            e = extras_de(s)
            out.append("### %d. `%s`\n" % (n, s["id"]))
            out.append("- **Arquivo(s):** %s" % arq)
            out.append("- **Duração:** %s  •  **Tipo:** %s%s" % (s.get("duracao", "?"), tipo, ("  •  " + "; ".join(e)) if e else ""))
            out.append("- **Onde toca:** %s" % s["quando"])
            out.append("")
            out.append("> %s\n" % s.get("prompt", "").replace("\n", " "))
    mus = por_pasta.get("musica", [])
    if mus:
        out.append("\n## Fora desta lista: música\n")
        out.append("Estes slots recebem a música (feita à parte, não é efeito sonoro). O jogo já toca quando o arquivo existe:\n")
        for s in mus:
            out.append("- `%s` (%s): %s" % (s["id"], "loop" if s.get("loop") else "toca uma vez", s["quando"]))
    return "\n".join(out) + "\n"


def main():
    with open(SLOTS, encoding="utf-8") as f:
        dados = json.load(f)
    slots = dados["slots"]
    por_pasta = {}
    for s in slots:
        por_pasta.setdefault(s["id"].split("/")[0], []).append(s)
    for pasta in por_pasta:
        if pasta not in ORDEM:
            print("AVISO: pasta sem título/ordem: %s" % pasta)
    with open(SAIDA, "w", encoding="utf-8", newline="\n") as f:
        f.write(lista_arquivos(slots, por_pasta))
    with open(SAIDA_PROMPTS, "w", encoding="utf-8", newline="\n") as f:
        f.write(lista_prompts(slots, por_pasta))
    total = sum(len(nomes_esperados(s)) for s in slots)
    prontos = sum(1 for s in slots for n in nomes_esperados(s) if existe(n))
    sem_prompt = [s["id"] for s in slots if not s.get("prompt") and s["id"].split("/")[0] != "musica"]
    print("%d slots, %d arquivos esperados, %d prontos -> docs/AUDIO_ARQUIVOS.md e docs/AUDIO_PROMPTS_ELEVENLABS.md" % (len(slots), total, prontos))
    if sem_prompt:
        print("ERRO: slots sem prompt: %s" % sem_prompt)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
