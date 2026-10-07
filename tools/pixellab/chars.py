"""Personagens do PixelLab: baixa rotações e animações (get_character) pra <pasta>/rotacoes e <pasta>/<anim>/<D>/<i>.png.

  from chars import info, baixa_rotacoes, baixa_anim, anima
"""
import os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pl, gen

D2 = {"south-east": "SE", "north-east": "NE", "south-west": "SO", "north-west": "NO"}


def info(cid):
    t = gen._texto(pl.call("get_character", {"character_id": cid}))
    st = re.search(r"status:\s*(\w+)", t)
    rot = dict(re.findall(r"^\s+([a-z-]+): (https://\S+/rotations/\S+)", t, re.M))
    anims = {}
    cur = None
    for line in t.splitlines():
        m = re.match(r"^  (\S+) — .*\[group: ([0-9a-f-]+)\]", line)
        if m:
            cur = m.group(1); anims.setdefault(cur, {"group": m.group(2), "dirs": {}})
            continue
        m = re.match(r"^    ([a-z-]+): (https://.*)$", line)
        if m and cur:
            anims[cur]["dirs"][m.group(1)] = [u.strip() for u in m.group(2).split(",")]
    return {"status": st.group(1) if st else "?", "rot": rot, "anims": anims, "texto": t}


def baixa_rotacoes(cid, pasta):
    i = info(cid)
    os.makedirs(os.path.join(pasta, "rotacoes"), exist_ok=True)
    for d, u in i["rot"].items():
        gen.baixa(u, os.path.join(pasta, "rotacoes", d + ".png"))
    return i


def baixa_anim(cid, pasta, nome, dest_nome=None):
    i = info(cid)
    a = i["anims"].get(nome)
    if not a:
        return 0
    n = 0
    for d, urls in a["dirs"].items():
        dd = os.path.join(pasta, dest_nome or nome, D2.get(d, d))
        os.makedirs(dd, exist_ok=True)
        for k, u in enumerate(urls):
            gen.baixa(u, os.path.join(dd, "%d.png" % k)); n += 1
    return n


def anima(cid, nome, acao, dirs=("south-east", "north-east"), frames=6, grupo=None):
    args = {"character_id": cid, "action_description": acao, "animation_name": nome, "directions": list(dirs),
            "mode": "v3", "frame_count": frames, "keep_first_frame": False}
    if grupo:
        args["animation_group_id"] = grupo
    t = gen._texto(pl.call("animate_character", args))
    return t
