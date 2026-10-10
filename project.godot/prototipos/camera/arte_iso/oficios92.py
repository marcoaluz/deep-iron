"""Bloco 92: os ofícios novos (Blocos 86–88) com arte do PixelLab no padrão do elenco: FUNDIDOR (h/m), FERREIRO
(h/m) e o PADRE (um só, homem). A mesma receita dos 18 do elenco (docs/escala_visual/arte_iso/checkpoint_elenco1):

  1. create_image_pro 48x84 (16 candidatos) com o minerador/médica aprovados + a guia 2:1 como referência;
  2. create_character v3, câmera "high top-down", do candidato escolhido (de frente) -> 8 poses paradas;
  3. caminhada de 8 quadros (caminhadas8.py: walking-8-frames, skeleton-v3), SE e NE (SO/NO = espelho);
  4. comuns: comer, ferido, deitar (v3, 8 quadros, as MESMAS descrições do elenco) e mancar_esq (sad-walk);
  5. trabalho da função (v3, 8 quadros): fundir / forjar / pregar;
  6. casaco de inverno (create_character_state "Casaco inverno") + caminhada + trabalho;
  7. retrato (retratos/retratos.py).

  python oficios92.py candidatos [nomes]   -> <pasta>/candidatos/cNN.png + grade (custo ~25-40 cada)
  python oficios92.py cria <nome> <idx>    -> o personagem v3 do candidato idx (id no elenco.json)
  python oficios92.py anima [nomes]        -> caminhada8 + comuns + trabalho (espera as vagas)
  python oficios92.py baixa [nomes]        -> rotações, prancha/contrato (personagem.py) e as animações
  python oficios92.py casaco [nomes]       -> estado "Casaco inverno" + caminhada + trabalho (casaco_ids.json)
"""
import json, os, re, sys, time, subprocess
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "..", "tools", "pixellab"))
import pl, gen, chars  # noqa: E402

ELENCO = os.path.join(AQUI, "elenco.json")
B = "https://backblaze.pixellab.ai/file/pixellab-characters/731c5e37-851f-4127-aec6-b6ac884bc069/%s/rotations/south.png"
MINERADOR = "bb4bd3f2-6661-445c-a546-ffe7bee5d2cc"
MEDICA = "af135e1a-771f-4127-811c-44c66ce3f549"
GUIA = "https://api.pixellab.ai/mcp/pixel-tools/de7b29da-ae99-4076-a03d-d5bda984b87b/assets/south/full.png"
ESTILO = ("Grimy, dark, desaturated earthy palette: dark browns, rust, lead grey, soot black; %s accent. Darker and "
          "dirtier than the references. Crisp 1px near-black outline around the silhouette like the references; "
          "interior detail drawn with darker shades of the local color rather than black lines. Clear form shading "
          "with light from top-left, low color count, clean readable pixel clusters.")
FIM = ("Same height, proportions and camera angle as the reference %s. Feet on the ground diamond of the layout guide, "
       "figure inside its box. Full body, standing still, facing straight toward the viewer (south), arms relaxed. "
       "Do not draw the guide lines. ")

# nome -> gênero, roupa (o que distingue o ofício à distância), acento, trabalho (nome, descrição v3)
OFICIOS = {
    "fundidor": ("h", "Adult MAN SMELTER (foundry worker who runs the furnace) for the same isometric mining colony game: "
                      "soot-blackened brown cloth cap with dark round welding goggles pushed up on it, thick padded "
                      "heat-resistant jacket of scorched dark grey canvas, long heavy leather apron with burn marks, very "
                      "long thick leather gauntlets up to the elbows, a soot-stained rust-red neckerchief, dark trousers "
                      "tucked into heavy boots. Male face covered in soot, short beard.",
                 "dull rust-red neckerchief",
                 ("fundir", "smelting work loop: he holds a long iron stoking rod with both hands from the first frame "
                            "and pushes it forward low into a furnace mouth in front of him at knee-to-waist height (the "
                            "furnace is not drawn), stirs, pulls it back and pushes again, leaning his weight into it, feet "
                            "planted, same body and outfit. Only the character and his iron rod: no furnace, no fire, no "
                            "glow, no sparks, no ground, no motion trails, no white arcs, no effects.")),
    "fundidora": ("m", "Adult WOMAN SMELTER (foundry worker who runs the furnace) for the same isometric mining colony "
                       "game, with subtle feminine curves (not exaggerated): soot-blackened brown cloth cap with dark round "
                       "welding goggles pushed up on it, hair in a short braid, thick padded heat-resistant jacket of "
                       "scorched dark grey canvas, long heavy leather apron with burn marks, very long thick leather "
                       "gauntlets up to the elbows, a soot-stained rust-red neckerchief, dark trousers tucked into heavy "
                       "boots. Clearly a woman: female face with soot smudges.",
                  "dull rust-red neckerchief",
                  ("fundir", "smelting work loop: she holds a long iron stoking rod with both hands from the first frame "
                             "and pushes it forward low into a furnace mouth in front of her at knee-to-waist height (the "
                             "furnace is not drawn), stirs, pulls it back and pushes again, leaning her weight into it, "
                             "feet planted, same body and outfit. Only the character and her iron rod: no furnace, no fire, "
                             "no glow, no sparks, no ground, no motion trails, no white arcs, no effects.")),
    "ferreiro": ("h", "Adult MAN BLACKSMITH for the same isometric mining colony game: bald head, thick dark beard, broad "
                      "strong shoulders and bare muscular forearms, sleeveless dark grey work shirt, a heavy brown leather "
                      "smith's apron down to the knees with a pocket, one thick leather glove, a smithing hammer hanging "
                      "from the apron string and iron tongs tucked in the belt, dark trousers, heavy boots. Male face, "
                      "stern, sweaty and grimy.",
                 "dull steel grey",
                 ("forjar", "blacksmith work loop: he holds iron tongs low in his left hand from the first frame, as if "
                            "gripping a piece of hot iron on an anvil in front of him (the anvil and the iron are not "
                            "drawn), and with his right hand raises a smithing hammer high and strikes down hard at waist "
                            "height, again and again; feet planted, same body and outfit. Only the character, his hammer "
                            "and his tongs: no anvil, no hot metal, no sparks, no ground, no motion trails, no white arcs, "
                            "no effects.")),
    "ferreira": ("m", "Adult WOMAN BLACKSMITH for the same isometric mining colony game, strong build with subtle feminine "
                      "curves (not exaggerated): hair tied back under a dark bandana, bare muscular forearms, sleeveless "
                      "dark grey work shirt, a heavy brown leather smith's apron down to the knees with a pocket, one thick "
                      "leather glove, a smithing hammer hanging from the apron string and iron tongs tucked in the belt, "
                      "dark trousers, heavy boots. Clearly a woman: female face, stern, sweaty and grimy.",
                 "dull steel grey",
                 ("forjar", "blacksmith work loop: she holds iron tongs low in her left hand from the first frame, as if "
                            "gripping a piece of hot iron on an anvil in front of her (the anvil and the iron are not "
                            "drawn), and with her right hand raises a smithing hammer high and strikes down hard at waist "
                            "height, again and again; feet planted, same body and outfit. Only the character, her hammer "
                            "and her tongs: no anvil, no hot metal, no sparks, no ground, no motion trails, no white arcs, "
                            "no effects.")),
    "padre": ("h", "Adult MAN VILLAGE PRIEST for the same isometric mining colony game: a long worn black cassock down to "
                   "the boots with a row of small buttons, a white clerical collar, a narrow faded purple stole hanging "
                   "from the neck, a plain wooden cross on a cord on the chest, a rope belt, dusty dark boots. Older man, "
                   "grey hair and a short grey beard, kind tired face with a little soot, hands relaxed.",
              "faded purple stole",
              ("pregar", "preaching loop: he holds a small dark book (a prayer book) open in his left hand at chest "
                         "height from the first frame and slowly raises his right hand with the palm open in a blessing "
                         "gesture, lowers it and raises it again, speaking calmly; feet planted, same body and outfit. "
                         "Only the character and his book: no altar, no ground, no glow, no light rays, no motion trails, "
                         "no white arcs, no effects.")),
}
# Bloco 92: o trabalho refeito (a 1ª leva trouxe fogo, poça de metal, picareta no lugar do martelo e a barra
# sumindo nos primeiros quadros): descrição mais literal, {he}/{his}/{him} por gênero
REFAZ = {"fundir": "smelting work loop: {he} holds a long plain dark iron rod (cold, dark grey all along, no glow at the tip) with both hands from the very first frame to the last, the rod pointing forward and down in front of {him}, toward the direction {he} faces; {he} slowly pushes it forward and pulls it back, stirring, as if raking coals inside a furnace that is NOT drawn; feet planted, same body and outfit. Only the character and the dark iron rod: no furnace, no fire, no flames, no molten metal, no puddle, no glow, no sparks, no ground, no motion trails, no white arcs, no effects.",
         "forjar": "blacksmith work loop: {he} holds iron tongs low in {his} left hand from the first frame, and in {his} right hand a short smithing hammer with a square iron head (NOT a pickaxe); {he} raises the hammer to shoulder height and strikes straight down at waist height in front of {him}, again and again, as if on an anvil that is NOT drawn; feet planted, same body and outfit. Only the character, the hammer and the tongs: no anvil, no hot metal, no fire, no flames, no glow, no sparks, no ground, no motion trails, no white arcs, no effects."}
# as animações comuns: as MESMAS descrições do elenco (Prompt 2), com ele/ela
COMUNS = {
    "comer": "eating standing up: {he} holds a small wooden bowl in {his} left hand at chest height and brings a spoon from the bowl to {his} mouth with {his} right hand, chews, repeats; keeps facing the same direction, feet planted, same body and outfit. Only the character, the bowl and the spoon: no table, no ground, no steam, no motion trails, no white arcs, no effects.",
    "ferido": "badly injured: {he} slowly sits down on the ground and stays sitting, one leg stretched out in a wooden splint wrapped with white bandages, leaning back on one hand, breathing heavily with small chest movements; keeps facing the same direction, same body and outfit. Only the character with the splint: no blood, no ground drawn, no motion trails, no white arcs, no effects.",
    "deitar": "sober collapse: exhausted, {he} sinks slowly to {his} knees and then lies down on {his} side on the ground, and stays still lying down in the last frames; calm and quiet, no dramatic fall; keeps facing the same direction, same body and outfit. Only the character: no blood, no ground drawn, no motion trails, no white arcs, no effects.",
}
CASACO = ("now wearing a heavy worn brown leather winter coat over {his} work clothes, with a thick fur collar and fur-lined "
          "cuffs, coat buttoned and reaching mid-thigh, a knitted scarf; {he} keeps {his} %s, same body, height and pose")
CASACO_MANTEM = {"fundidor": "cloth cap with goggles", "fundidora": "cloth cap with goggles",
                 "ferreiro": "bald head and beard, leather apron over the coat", "ferreira": "bandana, leather apron over the coat",
                 "padre": "white clerical collar and purple stole over the coat, wooden cross"}


def _pron(nome):
    return {"he": "she", "his": "her", "him": "her"} if OFICIOS[nome][0] == "m" else {"he": "he", "his": "his", "him": "him"}


def elenco():
    return json.load(open(ELENCO, encoding="utf-8"))


def salva_elenco(d):
    json.dump(d, open(ELENCO, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def _alvos(args):
    return [a for a in args if a in OFICIOS] or list(OFICIOS)


def candidatos(nomes):
    itens = []
    for nome in nomes:
        gen_, roupa, acento, _t = OFICIOS[nome]
        ref = B % (MINERADOR if gen_ == "h" else MEDICA)
        quem = "miner" if gen_ == "h" else "woman"
        desc = roupa + " " + (FIM % quem) + (ESTILO % acento)
        usos = [{"url": ref, "usage": "the approved %s of the same game: same %s body height, proportions, camera angle "
                                     "and art style (different job and outfit)" % (quem, "male" if gen_ == "h" else "female")},
                {"url": GUIA, "usage": "layout guide ONLY (do not draw the lines): isometric 2:1 ground diamond under "
                                       "the feet and the character's box"}]
        itens.append((nome, "create_image_pro", {"description": desc, "width": 48, "height": 84,
                                                 "reference_images": usos, "style_image_url": B % MINERADOR,
                                                 "style_copy": ["outline", "detail", "shading", "color_palette"]},
                      os.path.join(AQUI, nome, "candidatos.png")))
    res = gen.lote(itens, registro=os.path.join(AQUI, "oficios92_jobs.json"))
    for nome, r in res.items():
        print(nome, r)


def cria(nome, idx):
    d = elenco()
    if d.get(nome, {}).get("char"):
        print("já existe", d[nome]["char"])
        return
    job = json.load(open(os.path.join(AQUI, "oficios92_jobs.json"), encoding="utf-8"))[nome]["job"]
    gen_, roupa, _a, _t = OFICIOS[nome]
    curto = roupa.split(": ", 1)[1] if ": " in roupa else roupa
    args = {"description": curto, "mode": "v3", "view": "high top-down", "name": "%s Deep Iron ISO" % nome.capitalize(),
            "reference_image_url": "https://api.pixellab.ai/mcp/images/%s/download?index=%d" % (job, idx)}
    t = gen._texto(pl.call("create_character", args))
    m = re.search(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", t)
    print(t[:300])
    d[nome] = {"genero": gen_, "job": job, "escolhido": idx, "char": m.group(1) if m else None, "estado": "gerando",
               "_obs": "Bloco 92"}
    salva_elenco(d)


def espera(cid, max_s=2400):
    t0 = time.time()
    while time.time() - t0 < max_s:
        i = chars.info(cid)
        if i["status"] in ("completed", "complete") and "pending jobs" not in i["texto"]:
            return i
        time.sleep(30)
    return chars.info(cid)


def _pede(args):
    for _ in range(80):  # sem vaga (o PixelLab roda 20 jobs juntos): espera e tenta de novo
        t = gen._texto(pl.call("animate_character", args))
        if "job slots" not in t and "rate limit" not in t.lower():
            return t
        time.sleep(30)
    return t


def anima(nomes):
    d = elenco()
    for nome in nomes:
        cid = d[nome]["char"]
        espera(cid)
        i = chars.info(cid)
        tem = set(i["anims"])
        p = _pron(nome)
        pedidos = []
        if "caminhada8_esq" not in tem:
            pedidos.append({"character_id": cid, "template_animation_id": "walking-8-frames", "mode": "skeleton-v3",
                            "animation_name": "caminhada8_esq", "directions": ["south-east", "north-east"]})
        if "mancar_esq" not in tem:
            pedidos.append({"character_id": cid, "template_animation_id": "sad-walk", "mode": "skeleton-v3",
                            "animation_name": "mancar_esq", "directions": ["south-east", "north-east"]})
        trab, desc_t = OFICIOS[nome][3]
        for an, desc in list(COMUNS.items()) + [(trab, desc_t)]:
            if an not in tem:
                pedidos.append({"character_id": cid, "mode": "v3", "directions": ["south-east", "north-east"],
                                "action_description": desc.format(**p), "frame_count": 8, "keep_first_frame": False,
                                "animation_name": an})
        for a in pedidos:
            t = _pede(a)
            print("  %-10s %-14s %s" % (nome, a["animation_name"], " | ".join(l for l in t.splitlines()[:3])[:140]), flush=True)


def baixa(nomes):
    """rotações + caminhada de 8 quadros (caminhadas8.py baixa/troca: SO/NO por espelho, anim.json com a âncora)
    + as outras animações pelo zip do personagem (trabalho.py: âncora por direção, espelho, limpeza)."""
    d = elenco()
    for nome in nomes:
        cid = d[nome]["char"]
        espera(cid)
        pasta = os.path.join(AQUI, nome)
        chars.baixa_rotacoes(cid, pasta)
        for cmd in ("baixa", "troca"):
            r = subprocess.run([sys.executable, "caminhadas8.py", cmd, nome], cwd=AQUI, capture_output=True, text=True)
            print("  %s caminhada %s: %s" % (nome, cmd, (r.stdout + r.stderr).strip()[-160:]))
        for an in ["comer", "ferido", "deitar", "mancar_esq", OFICIOS[nome][3][0]]:
            extra = ["claro"] if an == "ferido" else []
            r = subprocess.run([sys.executable, "trabalho.py", nome, an, cid, "zip"] + extra, cwd=AQUI,
                               capture_output=True, text=True)
            print("  %s %s: %s" % (nome, an, (r.stdout + r.stderr).strip()[-160:].replace(chr(10), " | ")))
        d[nome]["estado"] = "pronto"
    salva_elenco(d)


CASACO_IDS = os.path.join(AQUI, "casaco_ids.json")


def _trabalho(nome):
    """(nome, descrição) do trabalho da função (a do REFAZ quando foi refeita)."""
    an, desc = OFICIOS[nome][3]
    return an, (REFAZ[an].format(**_pron(nome)) if an in REFAZ else desc)


def casaco(nomes):
    """o estado "Casaco inverno" (a receita do elenco) + caminhada de 8 quadros + o trabalho, no casaco_ids.json."""
    ids = json.load(open(CASACO_IDS, encoding="utf-8"))
    d = elenco()
    for nome in nomes:
        chave = "casaco_" + nome
        if not ids.get(chave, {}).get("char"):
            desc = CASACO.format(**_pron(nome)) % CASACO_MANTEM[nome]
            t = gen._texto(pl.call("create_character_state", {"character_id": d[nome]["char"], "edit_description": desc,
                                                               "state_name": "Casaco inverno"}))
            m = re.search(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", t)
            ids[chave] = {"char": m.group(1) if m else None, "base": nome, "trabalho": OFICIOS[nome][3][0],
                          "enviado": [], "processado": [], "_obs": "Bloco 92"}
            print("  %s: estado pedido %s" % (chave, ids[chave]["char"]))
            json.dump(ids, open(CASACO_IDS, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    for nome in nomes:
        chave = "casaco_" + nome
        cid = ids[chave]["char"]
        espera(cid)
        tem = set(chars.info(cid)["anims"])
        an, desc = _trabalho(nome)
        pedidos = []
        if "caminhada8_esq" not in tem:
            pedidos.append({"character_id": cid, "template_animation_id": "walking-8-frames", "mode": "skeleton-v3",
                            "animation_name": "caminhada8_esq", "directions": ["south-east", "north-east"]})
        if an not in tem:
            pedidos.append({"character_id": cid, "mode": "v3", "directions": ["south-east", "north-east"],
                            "action_description": desc, "frame_count": 8, "keep_first_frame": False, "animation_name": an})
        for a in pedidos:
            t = _pede(a)
            print("  %-18s %-14s %s" % (chave, a["animation_name"], " | ".join(t.splitlines()[:2])[:100]), flush=True)
        ids[chave]["enviado"] = ["caminhada", an]
    json.dump(ids, open(CASACO_IDS, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def casaco_baixa(nomes):
    ids = json.load(open(CASACO_IDS, encoding="utf-8"))
    for nome in nomes:
        chave = "casaco_" + nome
        cid = ids[chave]["char"]
        espera(cid)
        for cmd in ("baixa", "troca"):
            r = subprocess.run([sys.executable, "caminhadas8.py", cmd, chave], cwd=AQUI, capture_output=True, text=True)
            print("  %s caminhada %s: %s" % (chave, cmd, (r.stdout + r.stderr).strip()[-120:]))
        an = OFICIOS[nome][3][0]
        r = subprocess.run([sys.executable, "trabalho.py", chave, an, cid, "zip", "estado=Casaco_inverno", "sem_brilho"],
                           cwd=AQUI, capture_output=True, text=True)
        print("  %s %s: %s" % (chave, an, (r.stdout + r.stderr).strip()[-120:].replace(chr(10), " | ")))
        ids[chave]["processado"] = ["caminhada", an]
    json.dump(ids, open(CASACO_IDS, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def retrato(nomes):
    """o retrato neutro (create_portrait_character a partir do boneco de frente, 48 px, como o Prompt 23) em
    retratos/base/<nome>.png; as expressões saem do retratos.py expressoes (só as que faltam)."""
    d = elenco()
    jobs = {}
    for nome in nomes:
        if os.path.exists(os.path.join(AQUI, "retratos", "base", nome + ".png")):
            continue
        url = B % d[nome]["char"]
        t = gen._texto(pl.call("create_portrait_character", {"image_url": url, "direction": "character_to_portrait",
                                                              "result_size": 48}))
        m = re.search(r"job_id:\s*([0-9a-f-]{36})", t) or re.search(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", t)
        jobs[nome] = m.group(1)
        print("  retrato %s: %s" % (nome, jobs[nome]))
    while jobs:
        time.sleep(15)
        for nome, job in list(jobs.items()):
            t = gen._texto(pl.call("get_portrait_character", {"job_id": job}))
            if re.search(r"status:\s*completed", t):
                u = re.search(r"(https://\S+\.png\S*)", t) or re.search(r"download:\s*(https://\S+)", t)
                gen.baixa(u.group(1), os.path.join(AQUI, "retratos", "base", nome + ".png"))
                print("  retrato %s pronto" % nome)
                jobs.pop(nome)
            elif re.search(r"status:\s*(failed|error)", t):
                print("  retrato %s FALHOU: %s" % (nome, t[:200]))
                jobs.pop(nome)


def refaz(pares):
    """<nome>:<anim> -> apaga a animação no PixelLab (senão o pedido repetido volta 'já existe') e pede de novo,
    com a descrição do REFAZ."""
    d = elenco()
    for par in pares:
        nome, an = par.split(":")
        cid = d[nome]["char"]
        i = chars.info(cid)
        if an in i["anims"]:
            t = gen._texto(pl.call("delete_animation", {"character_id": cid, "animation_group_id": i["anims"][an]["group"]}))
            print("  apagou %s %s: %s" % (nome, an, t[:80].replace(chr(10), " ")))
        a = {"character_id": cid, "mode": "v3", "directions": ["south-east", "north-east"],
             "action_description": REFAZ[an].format(**_pron(nome)), "frame_count": 8, "keep_first_frame": False,
             "animation_name": an}
        t = _pede(a)
        print("  %-10s %-8s %s" % (nome, an, " | ".join(t.splitlines()[:2])[:120]), flush=True)


if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    if cmd == "candidatos":
        candidatos(_alvos(resto))
    elif cmd == "cria":
        cria(resto[0], int(resto[1]))
    elif cmd == "anima":
        anima(_alvos(resto))
    elif cmd == "baixa":
        baixa(_alvos(resto))
    elif cmd == "refaz":
        refaz(resto)
    elif cmd == "casaco":
        casaco(_alvos(resto))
    elif cmd == "casaco_baixa":
        casaco_baixa(_alvos(resto))
    elif cmd == "retrato":
        retrato(_alvos(resto))


# ------------------------------------------------------------ ícones da barra de funções (Prompt 21)
ICONES = {
    "fundidor": "game UI icon: a small clay crucible tilted on iron tongs pouring a thin stream of glowing orange "
                "molten metal into an ingot mould",
    "ferreiro": "game UI icon: a dark iron anvil with a smithing hammer resting on it",
    "padre": "game UI icon: a simple wooden cross with a narrow faded purple stole draped over its arms",
    # Bloco 110 (relacionamentos): gerado com o ícone do ânimo e o do cozinheiro de referência; escolhidos c07 (coracao) e
    # c13 do mesmo lote (coracao_partido: o luto pelo parceiro)
    "coracao": "game UI icon: a small warm red heart, simple rounded heart shape with a soft highlight on the upper left, "
               "slightly worn and muted like the rest of the colony's dusty palette",
}
ICONE_DIR = os.path.join(AQUI, "ui", "icones")
ICONE_DEST = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "ui", "icones"))


def _data_url(path):
    import base64
    return "data:image/png;base64," + base64.b64encode(open(path, "rb").read()).decode()


def icones(nomes):
    eng = _data_url(os.path.join(ICONE_DEST, "engenheiro.png"))
    coz = _data_url(os.path.join(ICONE_DEST, "cozinheiro.png"))
    itens = []
    for nome in nomes:
        args = {"description": ICONES[nome] + ". Same style, size, outline and light as the reference icons of the same "
                               "game: chunky readable pixel art, 1px near-black outline, warm muted palette, centered, "
                               "transparent background, no text, no frame.",
                "width": 32, "height": 32, "no_background": True,
                "reference_images": [{"url": eng, "usage": "the engineer job icon of the same game: style and size"},
                                     {"url": coz, "usage": "the cook job icon of the same game: style and size"}],
                "style_image_url": eng, "style_copy": ["color_palette", "outline", "detail", "shading"]}
        itens.append(("icone_" + nome, "create_image_pro", args, os.path.join(ICONE_DIR, "_cand_" + nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "oficios92_jobs.json"))


def icone_escolhe(pares):
    """<nome>=cNN -> ui/icones/<nome>.png e assets (32 px + p24), como o ui/icones.py faz."""
    import numpy as np
    from PIL import Image

    def limpa(im):
        a = np.array(im.convert("RGBA"))
        a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)
        im = Image.fromarray(a, "RGBA")
        bb = im.getbbox()
        return im.crop(bb) if bb else im

    def quadrado(im, lado):
        w, h = im.size
        if max(w, h) > lado:
            k = lado / max(w, h)
            im = limpa(im.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS))
        q = Image.new("RGBA", (lado, lado))
        q.alpha_composite(im, ((lado - im.width) // 2, (lado - im.height) // 2))
        return q

    for par in pares:
        nome, c = par.split("=")
        im = Image.open(os.path.join(ICONE_DIR, "_cand_" + nome, c + ".png")).convert("RGBA")
        im.save(os.path.join(ICONE_DIR, nome + ".png"))
        im32 = quadrado(limpa(im), 32)
        im32.save(os.path.join(ICONE_DEST, nome + ".png"))
        quadrado(limpa(im32), 24).save(os.path.join(ICONE_DEST, "p24", nome + ".png"))
        lista = json.load(open(os.path.join(ICONE_DEST, "icones.json"), encoding="utf-8"))
        if nome not in lista["icones"]:
            lista["icones"].append(nome)
            json.dump(lista, open(os.path.join(ICONE_DEST, "icones.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        print(nome, c, "ok")


if __name__ == "__main__" and sys.argv[1] == "icones":
    icones([n for n in sys.argv[2:] if n in ICONES] or list(ICONES))
elif __name__ == "__main__" and sys.argv[1] == "icone_escolhe":
    icone_escolhe(sys.argv[2:])
