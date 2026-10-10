#!/usr/bin/env python
"""Bloco 114/115/116: gera os documentos de áudio a partir de project.godot/data/audio/slots.json (e do que já existe em assets/audio):

  docs/audio/PEDIDO_DE_SONS.md      cada som: arquivo esperado, duração, loop sim/não, descrição, termos de busca e se já existe (o que falta vem primeiro)
  docs/audio/PROMPTS_ELEVENLABS.md  o prompt de cada som (tudo, menos a música)
  docs/audio/LISTA_DE_ESCUTA.md     a lista pra OUVIR e aprovar, na ordem de prioridade

    python tools/elevenlabs/docs_audio.py        (ou: gerar_sons.py --docs)
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SLOTS = os.path.join(RAIZ, "project.godot", "data", "audio", "slots.json")
GERADOS = os.path.join(RAIZ, "project.godot", "data", "audio", "gerados.json")
PASTA = os.path.join(RAIZ, "project.godot", "assets", "audio")
SAIDA_PEDIDO = os.path.join(RAIZ, "docs", "audio", "PEDIDO_DE_SONS.md")
SAIDA_PROMPTS = os.path.join(RAIZ, "docs", "audio", "PROMPTS_ELEVENLABS.md")
SAIDA_ESCUTA = os.path.join(RAIZ, "docs", "audio", "LISTA_DE_ESCUTA.md")
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
## Termos de busca por pasta (pra procurar o som num banco de sons, se o gerado não servir).
BUSCA = {"ambiencia": "ambience loop", "predios": "loop machinery ambience", "stingers": "stinger jingle", "ui": "ui sound game", "sfx": "sound effect",
         "animais": "animal sound", "perigo": "geiger counter", "criaturas": "monster creature", "maquinas": "machine", "vida": "village",
         "passos": "footstep", "voz": "voice grunt", "pontuais": "nature one shot", "intro": "cinematic", "musica": "game music loop"}
## A ordem em que se ouve (a mesma da geração): o que mais pesa na experiência primeiro.
PRIORIDADE = ["ambiencia/", "predios/fornalha", "predios/sino", "stingers/", "ui/", "predios/", "sfx/", "passos/", "voz/", "animais/", "criaturas/",
              "perigo/", "maquinas/", "vida/", "pontuais/", "intro/", "musica/"]


def nomes_esperados(s):
    n = int(s.get("variacoes", 0))
    return [s["id"]] if n <= 0 else ["%s_%d" % (s["id"], i) for i in range(n)]


def existe(nome):
    for ext in EXTENSOES:
        if os.path.exists(os.path.join(PASTA, *(nome + "." + ext).split("/"))):
            return ext
    return ""


def prioridade_de(s):
    for i, p in enumerate(PRIORIDADE):
        if s["id"].startswith(p):
            return i
    return len(PRIORIDADE)


def termos_de_busca(s):
    """Termos em inglês pra procurar o som num banco: o começo do prompt (sem o 'seamless loop') + a palavra da pasta."""
    p = s.get("prompt", "") or s.get("quando", "")
    p = re.sub(r"^(Seamless loop,\s*)", "", p)
    p = re.sub(r"\(.*?\)", "", p)
    trecho = ", ".join([t.strip() for t in p.split(",")[:2]])
    trecho = re.sub(r"\b(\d+(\.\d+)? seconds?|no music|no voices|no speech|close microphone|dry)\b", "", trecho)
    trecho = re.sub(r"\s+", " ", trecho).strip(" ,.")
    return "%s; %s" % (trecho[:90], BUSCA.get(s["id"].split("/")[0], "sound effect"))


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


def e_loop(s):
    return s.get("tipo") in ("loop", "loop_predio") or (s.get("tipo") == "tema" and bool(s.get("loop")))


def pedido(slots, por_pasta):
    total = sum(len(nomes_esperados(s)) for s in slots)
    prontos = sum(1 for s in slots for n in nomes_esperados(s) if existe(n))
    faltam = [(s, n) for s in slots for n in nomes_esperados(s) if not existe(n)]
    out = ["# Pedido de sons (Bloco 116)\n",
           "Gerado por `python tools/elevenlabs/docs_audio.py` a partir de `project.godot/data/audio/slots.json`. **Não edite à mão.** "
           "Os prompts estão em `docs/audio/PROMPTS_ELEVENLABS.md` e a lista de escuta em `docs/audio/LISTA_DE_ESCUTA.md`.\n",
           "O jogo roda **sem** os arquivos: o slot sem arquivo fica mudo (ou toca o som sintetizado de antes), sem erro. Arquivo novo é só pôr em "
           "`project.godot/assets/audio/<nome>.ogg|wav|mp3` com o nome exato e rodar `godot --headless --path project.godot --import`.\n",
           "**Resumo:** %d slots, %d arquivos esperados, **%d prontos, %d faltam**.\n" % (len(slots), total, prontos, len(faltam))]
    out.append("## O que falta\n")
    if not faltam:
        out.append("Nenhum som de efeito falta: os arquivos de efeitos estão todos na pasta.\n")
    else:
        out.append("| Arquivo | Duração | Loop | Descrição | Termos de busca |")
        out.append("|---|---|---|---|---|")
        for s, n in faltam:
            out.append("| `%s` | %s | %s | %s | %s |" % (n, s.get("duracao", "?"), "sim" if e_loop(s) else "não", s["quando"].replace("|", "/"), termos_de_busca(s).replace("|", "/")))
    mus = por_pasta.get("musica", [])
    if mus:
        out.append("\nA **música** (abertura e introdução) não é gerada pela ferramenta de efeitos: os slots estão no catálogo e o jogo toca quando o arquivo existir.\n")
    for pasta in ORDEM:
        lista = por_pasta.get(pasta, [])
        if not lista:
            continue
        out.append("\n## %s\n" % TITULOS.get(pasta, pasta))
        out.append("| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |")
        out.append("|---|---|---|---|---|---|---|---|---|")
        for s in lista:
            nomes = nomes_esperados(s)
            tem = [existe(n) for n in nomes]
            estado = "pronto" if all(tem) else ("parcial" if any(tem) else "falta")
            e = extras_de(s)
            quando = s["quando"] + ((" *(%s)*" % "; ".join(e)) if e else "")
            out.append("| %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (
                "<br>".join("`%s`" % n for n in nomes), s.get("duracao", "—") or "—", "sim" if e_loop(s) else "não", s.get("bus", ""), s.get("db", 0),
                quando.replace("|", "/"), termos_de_busca(s).replace("|", "/"), "o som de antes" if s.get("reserva") else "mudo", estado))
    return "\n".join(out) + "\n"


def prompts(slots, por_pasta):
    sem_musica = [s for s in slots if s["id"].split("/")[0] != "musica"]
    arquivos = sum(len(nomes_esperados(s)) for s in sem_musica)
    out = ["# Prompts do ElevenLabs — todos os sons do jogo, menos a música\n",
           "Gerado por `python tools/elevenlabs/docs_audio.py` a partir de `project.godot/data/audio/slots.json` (campos `prompt` e `duracao`). "
           "**Não edite à mão: mude o prompt no `slots.json` e rode a ferramenta.**\n",
           "**%d sons (%d arquivos)**. A música da abertura e da introdução fica de fora (lista no fim).\n" % (len(sem_musica), arquivos),
           "## Como usar\n",
           "1. A ferramenta `tools/elevenlabs/gerar_sons.py` já usa estes prompts pela API (`--dry-run` mostra o custo antes). Pra gerar à mão, no ElevenLabs "
           "**Sound Effects**: cole o prompt, ponha a **duração** indicada e ligue **loop** nos sons de loop.\n"
           "2. Prompts em inglês: *dark, dusty, industrial*; *isolated sound, no music, no speech*; *close microphone, dry* nos curtos; *seamless loop* nos loops.\n"
           "3. **Variações** (`_0`, `_1`...): o mesmo prompt gerado várias vezes; o jogo sorteia entre elas. `--candidatos N` gera N pra você escolher.\n"
           "4. Os **stingers** são frases curtas de música/efeito: se o gerador de efeitos não fizer bem, gere na ferramenta de música e salve com o mesmo nome.\n"
           "5. As **vozes curtas** (`voz/`) podem sair do Text to Speech em português se preferir fala de verdade (as frases sugeridas estão entre parênteses).\n"]
    n = 0
    for pasta in ORDEM:
        lista = [s for s in por_pasta.get(pasta, []) if pasta != "musica"]
        if not lista:
            continue
        out.append("\n## %s\n" % TITULOS.get(pasta, pasta))
        for s in lista:
            n += 1
            e = extras_de(s)
            out.append("### %d. `%s`\n" % (n, s["id"]))
            out.append("- **Arquivo(s):** %s" % ", ".join("`%s`" % x for x in nomes_esperados(s)))
            out.append("- **Duração:** %s  •  **Tipo:** %s%s" % (s.get("duracao", "?"), TIPOS.get(s.get("tipo", ""), ""), ("  •  " + "; ".join(e)) if e else ""))
            out.append("- **Onde toca:** %s\n" % s["quando"])
            out.append("> %s\n" % s.get("prompt", "").replace("\n", " "))
    mus = por_pasta.get("musica", [])
    if mus:
        out.append("\n## Fora desta lista: música\n")
        for s in mus:
            out.append("- `%s` (%s): %s" % (s["id"], "loop" if s.get("loop") else "toca uma vez", s["quando"]))
    return "\n".join(out) + "\n"


def escuta(slots, g):
    ordenados = sorted([s for s in slots if not s["id"].startswith("musica/")], key=lambda s: (prioridade_de(s), s["id"]))
    aprovados = sum(1 for s in ordenados for n in nomes_esperados(s) if g["arquivos"].get(n, {}).get("aprovado"))
    total = sum(len(nomes_esperados(s)) for s in ordenados)
    out = ["# Lista de escuta (Bloco 116)\n",
           "Gerado por `python tools/elevenlabs/docs_audio.py`. A ordem é a de prioridade (ambiência por andar, fornalha, igreja, stingers, interface, "
           "depois o resto). **Marque `[x]` o que você ouviu e aprovou.** O estado de aprovação gravado pela ferramenta está em `project.godot/data/audio/gerados.json`.\n",
           "**Resumo:** %d arquivos de efeitos, %d marcados como aprovados.\n" % (total, aprovados),
           "## Como ouvir e trocar um som\n",
           "- **Ouvir no jogo:** o F3 tem \"Ir para…\" (andares) e \"Pular dia\"; os prédios tocam perto da câmera; os sons soltos tocam sozinhos de tempos em tempos.\n"
           "- **Ouvir o arquivo:** `project.godot/assets/audio/<nome>.wav`.\n"
           "- **Não gostou?** `python tools/elevenlabs/gerar_sons.py --so <id> --candidatos 3` gera 3 versões em `audio_candidatos/` (fora do git); ouça e escolha com "
           "`--aprovar <nome> <n>`. Antes, `--dry-run` mostra o custo.\n"
           "- **Muito baixo ou alto?** Mude o `db` do slot em `data/audio/slots.json` (não precisa refazer o arquivo).\n"]
    atual = ""
    for s in ordenados:
        pasta = s["id"].split("/")[0]
        if pasta != atual:
            atual = pasta
            out.append("\n## %s\n" % TITULOS.get(pasta, pasta))
        for n in nomes_esperados(s):
            reg = g["arquivos"].get(n, {})
            marca = "x" if reg.get("aprovado") else " "
            ext = existe(n)
            arq = "assets/audio/%s.%s" % (n, ext) if ext else "(sem arquivo)"
            e = extras_de(s)
            out.append("- [%s] `%s` — %s — %s%s" % (marca, n, s.get("duracao", "?"), s["quando"], (" *(" + "; ".join(e) + ")*") if e else ""))
            out.append("  - arquivo: `%s`  •  ouça: %s" % (arq, "a emenda do loop (sem estalo) e se não cansa" if e_loop(s) else
                                                         ("se está claro e no volume certo, sem cortar" if s.get("tipo") != "pontual" else "se soa natural isolado")))
    return "\n".join(out) + "\n"


def main():
    slots = json.load(open(SLOTS, encoding="utf-8"))["slots"]
    g = json.load(open(GERADOS, encoding="utf-8")) if os.path.exists(GERADOS) else {"arquivos": {}}
    por_pasta = {}
    for s in slots:
        por_pasta.setdefault(s["id"].split("/")[0], []).append(s)
    for pasta in por_pasta:
        if pasta not in ORDEM:
            print("AVISO: pasta sem título/ordem: %s" % pasta)
    os.makedirs(os.path.join(RAIZ, "docs", "audio"), exist_ok=True)
    for caminho, texto in ((SAIDA_PEDIDO, pedido(slots, por_pasta)), (SAIDA_PROMPTS, prompts(slots, por_pasta)), (SAIDA_ESCUTA, escuta(slots, g))):
        with open(caminho, "w", encoding="utf-8", newline="\n") as f:
            f.write(texto)
    sem_prompt = [s["id"] for s in slots if not s.get("prompt") and s["id"].split("/")[0] != "musica"]
    total = sum(len(nomes_esperados(s)) for s in slots)
    prontos = sum(1 for s in slots for n in nomes_esperados(s) if existe(n))
    print("%d slots, %d arquivos esperados, %d prontos -> docs/audio/PEDIDO_DE_SONS.md, PROMPTS_ELEVENLABS.md e LISTA_DE_ESCUTA.md" % (len(slots), total, prontos))
    if sem_prompt:
        print("ERRO: slots sem prompt: %s" % sem_prompt)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
