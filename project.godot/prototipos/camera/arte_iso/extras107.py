"""Bloco 107: as animações de trabalho NOVAS do lenhador/lenhadora (carvoejar, na carvoaria) e do caçador/caçadora (curtir, no
curtume), nos personagens e nos casacos que já existem (a receita do elenco: v3, 8 quadros, SE e NE; SO/NO por espelho).

  python extras107.py pede [nomes]      -> pede as animações (base e casaco de inverno) de cada um
  python extras107.py baixa [nomes]     -> baixa e processa (trabalho.py: âncora por direção, espelho, limpeza)
nomes: lenhador lenhadora cacador cacadora (sem nome = os 4)
"""
import json, os, subprocess, sys, time
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "..", "tools", "pixellab"))
import pl, gen, chars  # noqa: E402

PRON = {"lenhador": {"he": "he", "his": "his", "him": "him"}, "cacador": {"he": "he", "his": "his", "him": "him"},
        "lenhadora": {"he": "she", "his": "her", "him": "her"}, "cacadora": {"he": "she", "his": "her", "him": "her"}}
CARVOEJAR = ("charcoal-burning work loop: {he} holds a long wooden pole with both hands from the very first frame to the last and "
             "pushes it forward low in front of {him} as if feeding split logs into a low kiln door, pulls it back and pushes again, "
             "then wipes {his} brow with the back of the hand once; feet planted, same body and outfit. Only the character and "
             "the pole: no kiln, no logs, no fire, no smoke, no ground drawn, no motion trails, no white arcs, no effects.")
CURTIR = ("tanning work loop: {he} holds a DRAWKNIFE with both hands from the very first frame to the last: a short straight "
          "flat steel blade (about 30 cm) with a small wooden handle at EACH end, NOT curved, NOT a scythe, NOT a sickle; {he} "
          "pulls it toward {his} body in front of {him} at chest height in short strokes, as if scraping a hide stretched on a "
          "beam, steps back to look, and scrapes again; feet planted, same body and outfit. Only the character and the "
          "drawknife: no beam, no hide, no ground drawn, no motion trails, no white arcs, no effects.")
ANIM = {"lenhador": ("carvoejar", CARVOEJAR), "lenhadora": ("carvoejar", CARVOEJAR),
        "cacador": ("curtir", CURTIR), "cacadora": ("curtir", CURTIR)}
ELENCO = os.path.join(AQUI, "elenco.json")
CASACO_IDS = os.path.join(AQUI, "casaco_ids.json")


def _ids(nome):
    e = json.load(open(ELENCO, encoding="utf-8"))
    c = json.load(open(CASACO_IDS, encoding="utf-8"))
    return e[nome]["char"], c["casaco_" + nome]["char"]


def _pede(args):
    for _ in range(80):  # sem vaga: espera e tenta de novo
        t = gen._texto(pl.call("animate_character", args))
        if "job slots" not in t and "rate limit" not in t.lower():
            return t
        time.sleep(30)
    return t


def pede(nomes):
    for nome in nomes:
        an, desc = ANIM[nome]
        base, casaco = _ids(nome)
        for cid, rot in [(base, nome), (casaco, "casaco_" + nome)]:
            if an in chars.info(cid)["anims"]:
                print("  já existe", rot, an)
                continue
            t = _pede({"character_id": cid, "mode": "v3", "directions": ["south-east", "north-east"],
                       "action_description": desc.format(**PRON[nome]), "frame_count": 8, "keep_first_frame": False,
                       "animation_name": an})
            print("  %-18s %-10s %s" % (rot, an, " | ".join(t.splitlines()[:2])[:110]), flush=True)


def refaz(nomes):
    """apaga a animação no PixelLab (senão o pedido repetido volta 'já existe') e pede de novo com a descrição de agora."""
    for nome in nomes:
        an, _d = ANIM[nome]
        base, casaco = _ids(nome)
        for cid in (base, casaco):
            i = chars.info(cid)
            if an in i["anims"]:
                t = gen._texto(pl.call("delete_animation", {"character_id": cid, "animation_group_id": i["anims"][an]["group"]}))
                print("  apagou", nome, an, t[:60].replace(chr(10), " "))
    pede(nomes)


def espera(cid, max_s=2400):
    t0 = time.time()
    while time.time() - t0 < max_s:
        i = chars.info(cid)
        if i["status"] in ("completed", "complete") and "pending jobs" not in i["texto"]:
            return i
        time.sleep(30)
    return chars.info(cid)


def baixa(nomes):
    for nome in nomes:
        an, _d = ANIM[nome]
        base, casaco = _ids(nome)
        espera(base)
        espera(casaco)
        r = subprocess.run([sys.executable, "trabalho.py", nome, an, base, "zip", "estado=Idle"], cwd=AQUI, capture_output=True, text=True)
        print("  %s %s: %s" % (nome, an, (r.stdout + r.stderr).strip()[-120:].replace(chr(10), " | ")))
        r = subprocess.run([sys.executable, "trabalho.py", "casaco_" + nome, an, casaco, "zip", "estado=Casaco_inverno", "sem_brilho"],
                           cwd=AQUI, capture_output=True, text=True)
        print("  casaco_%s %s: %s" % (nome, an, (r.stdout + r.stderr).strip()[-120:].replace(chr(10), " | ")))


if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    alvos = [a for a in resto if a in ANIM] or list(ANIM)
    {"pede": pede, "baixa": baixa, "refaz": refaz}[cmd](alvos)
