#!/usr/bin/env python
"""Bloco 116: teste OFFLINE da ferramenta gerar_sons.py (nenhuma chamada à API de verdade, nenhum crédito): troca a chamada por um som sintético.

    python tools/elevenlabs/testa_ferramenta.py

Confere: --dry-run, cache de chamadas (o mesmo pedido nunca paga duas vezes), hash (prompt mudou = desatualizado), candidatos e --aprovar, teto de
gerações, confirmação de custo, pós-processamento (corta silêncio, emenda de loop, só sobe volume) e que a chave nunca vai pra tela.
"""
import contextlib
import io
import json
import math
import os
import struct
import sys
import tempfile
import urllib.error

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gerar_sons as gs  # noqa: E402
import posprocessa as pos  # noqa: E402

CHAVE_FALSA = "sk_chave_falsa_so_pro_teste_1234567890abcdef"
falhas = 0
chamadas = 0
modo_erro = False


def check(ok, msg):
    global falhas
    print(("  OK   " if ok else "  FALHOU ") + msg)
    if not ok:
        falhas += 1


def sintetico(taxa, seg, silencio_ini=0.0, amp=8000.0, salto_loop=False):
    """PCM estéreo de 16 bits intercalado: um tom com silêncio no começo (e, se salto_loop, um fim que não bate com o começo)."""
    n = int(taxa * seg)
    ini = int(taxa * silencio_ini)
    out = []
    for i in range(n):
        v = 0 if i < ini else int(amp * math.sin(2 * math.pi * 220 * i / taxa))
        if salto_loop and i > n - 40:
            v = 12000
        out.append(v)
        out.append(v)
    return struct.pack("<%dh" % len(out), *out)


def pede_falso(metodo, caminho, k, corpo=None):
    global chamadas
    if metodo == "GET":
        return json.dumps({"tier": "teste", "character_count": 0, "character_limit": 1000}).encode()
    chamadas += 1
    if modo_erro:
        raise urllib.error.HTTPError("http://x", 400, "x", {}, io.BytesIO(("chave %s recusada" % k).encode()))
    taxa = int(caminho.split("pcm_")[1])
    return sintetico(taxa, corpo["duration_seconds"], silencio_ini=0.3 if not corpo["loop"] else 0.0, salto_loop=corpo["loop"])


def roda(*args):
    """Roda o main da ferramenta com esses argumentos; devolve (código, saída)."""
    sys.argv = ["gerar_sons.py"] + list(args)
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        try:
            cod = gs.main()
        except SystemExit as e:
            cod = e.code
    return cod, buf.getvalue()


def main():
    global chamadas, modo_erro
    sys.stdin = io.StringIO("")  # sem terminal: a ferramenta não pode ficar esperando resposta
    tmp = tempfile.mkdtemp(prefix="teste_eleven_")
    slots = {"slots": [
        {"id": "sfx/curto", "tipo": "tiro", "bus": "SFX", "db": -6, "quando": "x", "duracao": "1 s", "prompt": "A short test thump."},
        {"id": "sfx/variado", "tipo": "tiro", "bus": "SFX", "db": -6, "variacoes": 2, "quando": "x", "duracao": "0.5 s cada", "prompt": "A test click."},
        {"id": "ambiencia/loop", "tipo": "loop", "bus": "Ambience", "db": 0, "quando": "x", "duracao": "loop 2 s", "prompt": "Seamless loop, test hum."},
        {"id": "ui/botao", "tipo": "tiro", "bus": "UI", "db": -6, "quando": "x", "duracao": "0.5 s", "prompt": "A test button."},
        {"id": "musica/tema", "tipo": "tema", "bus": "Music", "db": 0, "quando": "música (nunca gerada)"},
    ]}
    caminho_slots = os.path.join(tmp, "slots.json")
    json.dump(slots, open(caminho_slots, "w", encoding="utf-8"))
    gs.SLOTS = caminho_slots
    gs.GERADOS = os.path.join(tmp, "gerados.json")
    gs.PASTA = os.path.join(tmp, "audio")
    gs.CANDIDATOS = os.path.join(tmp, "cand")
    gs.CACHE = os.path.join(tmp, "cand", "_cache")
    gs.pede = pede_falso
    gs.chave = lambda: CHAVE_FALSA
    gs.time.sleep = lambda s: None
    saida_total = ""

    print("== dry-run")
    cod, so = roda("--so", "sfx", "--dry-run")
    saida_total += so
    check(cod == 0 and chamadas == 0 and not os.path.exists(gs.PASTA), "--dry-run não chama a API nem grava nada")
    check("3 arquivo(s) no plano" in so and "custo estimado" in so, "mostra a contagem (3 arquivos) e o custo estimado")
    cod, so = roda()
    check(cod == 1 and chamadas == 0, "sem --so/--tudo não gera nada")

    print("== gerar e cache")
    cod, so = roda("--so", "sfx/curto")
    saida_total += so
    p = gs.caminho_final("sfx/curto")
    check(cod == 0 and chamadas == 1 and os.path.exists(p), "gera um som (1 chamada) e grava o WAV")
    ch, taxa, x = pos.le_wav(p)
    check(ch == 1 and taxa == 44100, "efeito posicional: mono, 44,1 kHz (%d canais, %d Hz)" % (ch, taxa))
    check(len(x) / taxa < 1.0 - 0.2, "cortou o silêncio do começo (%.2f s de 1,0 s)" % (len(x) / taxa))
    check(pos.pico_db(x) >= pos.PICO_CURTO - 0.6, "o volume subiu até o alvo (pico %.1f dBFS)" % pos.pico_db(x))
    g = gs.gerados()
    check(g["arquivos"]["sfx/curto"]["hash"] == gs.hash_de(gs.carrega_slots()[0]), "gerados.json guarda o hash do pedido")
    chamadas = 0
    cod, so = roda("--so", "sfx/curto")
    check(chamadas == 0 and "0 arquivo(s) no plano" in so, "de novo: pula o que já existe (0 chamadas)")
    os.remove(p)
    cod, so = roda("--so", "sfx/curto")
    check(chamadas == 0 and os.path.exists(p), "apagou o arquivo e gerou de novo: veio do CACHE das chamadas (0 créditos)")
    cod, so = roda("--so", "sfx/curto", "--force")
    check(chamadas == 1, "--force ignora o cache (gasta de novo, pra sortear outra versão)")

    print("== variações, loop, UI e a música")
    chamadas = 0
    roda("--so", "sfx/variado", "ambiencia", "ui")
    check(chamadas == 4 and os.path.exists(gs.caminho_final("sfx/variado_0")) and os.path.exists(gs.caminho_final("sfx/variado_1")), "variações _0 e _1 + loop + UI: 4 chamadas")
    ch, taxa, xl = pos.le_wav(gs.caminho_final("ambiencia/loop"))
    check(ch == 2 and taxa == 24000, "loop de ambiência: estéreo, 24 kHz")
    check(pos.razao_estalo(xl, ch) <= pos.LIMITE_ESTALO, "o loop com salto no fim foi emendado (razão %.1f)" % pos.razao_estalo(xl, ch))
    check(not os.path.exists(gs.caminho_final("musica/tema")), "a música não é gerada")
    ch, taxa, xu = pos.le_wav(gs.caminho_final("ui/botao"))
    check(ch == 2, "interface: estéreo")

    print("== hash e desatualizado")
    s2 = json.load(open(caminho_slots, encoding="utf-8"))
    s2["slots"][0]["prompt"] = "A different thump."
    json.dump(s2, open(caminho_slots, "w", encoding="utf-8"))
    chamadas = 0
    cod, so = roda("--desatualizados")
    check("desatualizado" in so and "sfx/curto" in so, "o prompt mudou: o arquivo aparece como desatualizado")
    roda("--so", "sfx/curto")
    check(chamadas == 0, "sem --atualiza não refaz o desatualizado")
    roda("--so", "sfx/curto", "--atualiza")
    check(chamadas == 1, "--atualiza refaz (1 chamada)")
    cod, so = roda("--desatualizados")
    check("sfx/curto" not in so, "depois de refeito não está mais desatualizado")

    print("== candidatos e aprovar")
    chamadas = 0
    cod, so = roda("--so", "ui/botao", "--candidatos", "3")
    c = [os.path.join(gs.CANDIDATOS, "ui__botao", "%d.wav" % i) for i in range(3)]
    check(chamadas == 2 and all(os.path.exists(f) for f in c), "--candidatos 3: 3 arquivos em audio_candidatos/ (2 chamadas: a candidata 0 já estava no cache da geração normal)")
    chamadas = 0
    roda("--so", "ui/botao", "--candidatos", "3")
    check(chamadas == 0, "pedir as mesmas candidatas de novo vem do cache (0 chamadas)")
    cod, so = roda("--aprovar", "ui/botao", "2")
    a = open(gs.caminho_final("ui/botao"), "rb").read()
    b = open(c[2], "rb").read()
    check(cod == 0 and a == b, "--aprovar ui/botao 2 copia a candidata 2 pro destino final")
    check(gs.gerados()["arquivos"]["ui/botao"]["aprovado"] is True, "fica registrado como aprovado")
    cod, so = roda("--aprovar", "ui/botao", "9")
    check(cod == 1, "candidata que não existe: recusa")

    print("== teto de gerações e confirmação de custo")
    for f in list(os.listdir(os.path.join(gs.CACHE))):
        os.remove(os.path.join(gs.CACHE, f))
    chamadas = 0
    cod, so = roda("--so", "ui/botao", "--candidatos", "5", "--max-geracoes", "2")
    check(cod == 1 and chamadas == 0 and "RECUSADO" in so, "mais chamadas que o teto: recusa antes de gastar")
    cod, so = roda("--so", "ui/botao", "--candidatos", "2", "--confirma-acima", "1")
    check(cod == 1 and chamadas == 0 and "--sim" in so, "custo acima do limite sem confirmação: recusa antes de gastar")
    cod, so = roda("--so", "ui/botao", "--candidatos", "2", "--confirma-acima", "1", "--sim")
    check(cod == 0 and chamadas == 2, "com --sim confirma e gasta")

    print("== a chave nunca aparece")
    modo_erro = True
    chamadas = 0
    cod, so = roda("--so", "sfx/variado", "--force")
    saida_total += so
    modo_erro = False
    check(cod == 1 and "ERRO 400" in so, "erro da API é mostrado")
    check(CHAVE_FALSA not in saida_total and "***" in so, "a chave não aparece na saída (o erro dela é mascarado)")
    check(gs.mascara("oi %s tchau" % CHAVE_FALSA, CHAVE_FALSA) == "oi *** tchau", "mascara() troca a chave por ***")

    print("== pós-processamento")
    ch, taxa = 1, 24000
    mudo = [0] * 24000 + [int(9000 * math.sin(i / 7)) for i in range(24000)] + [0] * 24000
    cortado = pos.corta_silencio(mudo, ch, taxa)
    check(len(cortado) < len(mudo) * 0.45, "corta o silêncio do começo e do fim (%d -> %d amostras)" % (len(mudo), len(cortado)))
    alto = [int(30000 * math.sin(i / 5)) for i in range(4000)]
    check(pos.ganho_para(alto, "curto") == 0.0, "som que já está alto não é abaixado (só sobe)")
    baixo = [int(300 * math.sin(i / 5)) for i in range(4000)]
    check(pos.ganho_para(baixo, "curto") > 20.0, "som baixo sobe (%.0f dB)" % pos.ganho_para(baixo, "curto"))
    print("ffmpeg: %s" % ("instalado" if pos.tem_ffmpeg() else "NÃO instalado (conversão pra OGG indisponível; a ferramenta mantém o WAV e avisa)"))
    print("FALHAS: %d" % falhas)
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
