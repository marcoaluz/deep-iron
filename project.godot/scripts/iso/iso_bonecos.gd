extends RefCounted
## Prompt 29, parte 3: os BONECOS com a arte nova (o elenco do Prompt 1, as animações do 2, o
## casaco e os trajes do 3, as ferramentas do 4).
##
## A arte foi levada pra assets/game/iso/bonecos/ por `python integra.py bonecos`: por pasta
## (minerador, medica, casaco_lenhador, traje_gas_f...), animação e direção de losango (SE, NE,
## SO, NO) uma TIRA de quadros com a âncora (pé) comum e o topo da cabeça em cada quadro.
##
## pose(ipezinho, direção, relógio) escolhe — só olhando o estado do ipezinho, sem mudar nada
## nele — a pasta (função × gênero, casaco no frio, traje de perigo), a animação (parado, andando,
## mancando, trabalho da função, comendo, ferido, deitado), o quadro, a pele (por paleta, pelo
## `look`) e o que vai por cima: o saco nas costas carregando (Prompt 2) e a ferramenta nas costas
## (regra da picareta: atrás do corpo de frente pra câmera, na frente de costas).

const FILE := "res://assets/game/iso/bonecos/bonecos.json"
const DIR := "res://assets/game/iso/bonecos/"
const SkinPalette := preload("res://scripts/iso/skin_palette.gd")
## IsoView.DIR_* (SE, SW, NW, NE) -> pasta da direção
const DIR_NAMES := ["SE", "SO", "NO", "NE"]
## outfit() do ipezinho -> função no bonecos.json
const OUTFIT_FUNCAO := {"mineiro": "minerador", "civil": "civil", "cozinheiro": "cozinheiro", "lenhador": "lenhador",
	"guarda": "guarda", "pesquisador": "pesquisador", "cacador": "cacador", "medico": "medico", "engenheiro": "engenheiro"}
## desenho antigo da mão (assets/game/<nome>.png) -> ferramenta nova (Prompt 4)
const ITEM_OF := {"pickaxe": "picareta", "pickaxe_aco": "picareta_aco", "axe": "machado", "hammer": "martelo",
	"porrete": "porrete", "lanca": "lanca", "lanca_prata": "lanca_prata", "besta": "besta", "bow": "arco"}
## Ferramenta nas costas (picareta_overlay.py): deslocamento do centro do corpo e do topo da
## cabeça, espelhada?, na frente do corpo? (SO e NO = SE e NE espelhados em volta do pé)
const BACK := {"SE": {"dx": -3.0, "dy": 6.0, "mirror": true, "front": false},
	"NE": {"dx": -2.0, "dy": 8.0, "mirror": false, "front": true}}
const ANIM_FPS := 8.0
const TRAJES := ["gas", "calor", "radiacao"]

static var _data: Dictionary = {}
static var _tex: Dictionary = {}
static var _env_frame := -1
static var _env_ok := false


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(FILE):
		var d = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_data = d if typeof(d) == TYPE_DICTIONARY else {}
	return _data


static func texture(img: String) -> Texture2D:
	if not _tex.has(img):
		var path := DIR + img
		warm_folder(img.get_base_dir())
		# Prompt 30: já pedida em segundo plano? pega de lá (espera só se ainda estiver carregando)
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_tex[img] = ResourceLoader.load_threaded_get(path)
		else:
			_tex[img] = load(path)
	return _tex[img]


## Prompt 30: cada tira levava ~6 ms (até 60) pra carregar na 1ª vez que aparecia, e com a vila
## cheia várias caíam no mesmo quadro (picos de 100+ ms). Na 1ª vez que uma pasta (função ×
## gênero, casaco, traje) aparece, todas as tiras dela são pedidas em segundo plano.
static var _warm := {}


static func warm_folder(folder: String) -> void:
	if folder == "" or _warm.has(folder):
		return
	_warm[folder] = true
	for f in DirAccess.get_files_at(DIR + folder):
		var name := f.trim_suffix(".remap").trim_suffix(".import")  # (no jogo exportado só há .import)
		if not name.ends_with(".png"):
			continue
		var p := DIR + folder + "/" + name
		if not _tex.has(folder + "/" + name) and ResourceLoader.load_threaded_get_status(p) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_request(p, "Texture2D")


## Só com o mapa novo (a vista iso nova); sem ele, o boneco de sempre.
static func enabled_for(w: Node) -> bool:
	if not w.is_inside_tree() or not w.is_in_group("ipezinhos") or data().is_empty():
		return false
	var f := Engine.get_process_frames()
	if f != _env_frame:  # uma consulta por quadro pra todos os bonecos
		_env_frame = f
		var env := w.get_tree().get_first_node_in_group("environment")
		_env_ok = env != null and env.has_method("has_iso_map") and env.has_iso_map()
	return _env_ok


## A pasta base (função × gênero) e as que vestem por cima (traje, casaco), na ordem de procura.
static func folders(w: Node) -> Array:
	var f: String = OUTFIT_FUNCAO.get(w.outfit() if w.has_method("outfit") else "mineiro", "minerador")
	var pair: Array = data().get("funcoes", {}).get(f, ["minerador", "mineradora", "minerar"])
	var woman: bool = String(w.get("gender")) == "menina"
	var base: String = pair[1] if woman else pair[0]
	var out: Array = []
	var wearing: Dictionary = w.get("wearing") if w.get("wearing") != null else {}
	for k in TRAJES:
		if wearing.has(k):
			out.append("traje_%s_%s" % [k, "f" if woman else "m"])
	if wearing.has("casaco"):
		out.append("casaco_" + base)
	out.append(base)
	for fo in out:
		warm_folder(fo)  # Prompt 30: as tiras dessa roupa já vão carregando em segundo plano
	return out


static func work_anim(w: Node) -> String:
	var f: String = OUTFIT_FUNCAO.get(w.outfit() if w.has_method("outfit") else "mineiro", "minerador")
	var pair: Array = data().get("funcoes", {}).get(f, [])
	var a = pair[2] if pair.size() > 2 else null
	if a == null and w.get("_ai_state") in ["mining", "storing"]:
		return "minerar"  # sem função própria minerando (pesquisador sem laboratório)
	return a if a != null else ""


## A primeira das pastas que tem essa animação nessa direção: [pasta, info] ([] = nenhuma).
static func _find(fs: Array, anim: String, d: String) -> Array:
	var p: Dictionary = data().get("pastas", {})
	for f in fs:
		var a: Dictionary = p.get(f, {}).get("anims", {}).get(anim, {})
		if a.has(d):
			return [f, a[d]]
	return []


## Bloco 73: o ajuste do quadro (pé no chão, cabeça na mesma vertical: integra.py pes) em px de arte.
static func _aj(info: Dictionary, frame: int) -> Vector2:
	var aj = info.get("aj")
	if aj == null or aj.is_empty():
		return Vector2.ZERO
	var a: Array = aj[mini(frame, aj.size() - 1)]
	return Vector2(a[0], a[1])


## O que desenhar agora. {} = sem arte nova (o boneco de sempre).
##   hidden (dentro de casa), tex/n/frame/ancora/quadro (corpo), top (topo da cabeça no quadro,
##   relativo ao pé), altura, anim, pasta, e as camadas saco/item: {tex, pos, flip, front}.
## Bloco 73: passo = fase da caminhada em ciclos (o espelho conta pela distância andada no chão, então
## a perna acompanha o deslocamento de verdade); mexendo = false quando ele "anda" sem sair do lugar
## (empurrando alguém, travado): fica parado em vez de marchar no lugar. Sem passo, o relógio antigo.
static func pose(w: Node, iso_dir: int, clock: float, passo: float = -1.0, mexendo: bool = true) -> Dictionary:
	if not enabled_for(w):
		return {}
	if w.get("_inside"):
		return {"hidden": true}
	var d: String = DIR_NAMES[clampi(iso_dir, 0, 3)]
	var fs := folders(w)
	var vel: Vector2 = w.velocity if w is CharacterBody2D else Vector2.ZERO
	var moving := vel.length() > 5.0 and mexendo
	var injured: bool = w.get("injured") == true
	var downed: bool = w.get("downed") == true
	var lying: bool = (w.get("_resting") == true and not w.get("_inside")) or downed
	var cargo: bool = float(w.get("carrying")) > 0.0 or float(w.get("wood_carrying")) > 0.0 \
		or float(w.get("food_carrying")) > 0.0 or float(w.get("raw_carrying")) > 0.0
	var item_name := _item_name(w)
	var anim := "parado"
	var hold_last := false
	var walk_clock := false
	var with_item := item_name != ""
	if lying:
		anim = "deitar"
		hold_last = true
		with_item = false
	elif moving:
		walk_clock = true
		if injured:
			anim = "mancar_esq"
		elif not cargo and item_name.begins_with("picareta") and not _find(fs.slice(fs.size() - 1), "com_picareta", d).is_empty():
			anim = "com_picareta"  # a picareta já desenhada nas costas (Prompt 1)
			with_item = false
		else:
			anim = "caminhada"
	elif float(w.get("_work_timer")) > 0.0 and work_anim(w) != "":
		anim = work_anim(w)
		with_item = false  # a ferramenta faz parte da animação de trabalho
		# pendências dos Prompts 2 e 29: colher fruta, treinar no campo, o ataque com a arma dele
		var st = w.get("_ai_state")
		if st == "foraging" and not _find(fs, "colher", d).is_empty():
			anim = "colher"
		elif st == "training" and not _find(fs, "treinar", d).is_empty():
			anim = "treinar"
		elif anim == "atacar":
			var arma := String(w.get("weapon")) if w.get("weapon") != null else ""
			var a2: String = {"lanca": "atacar_lanca", "lanca_prata": "atacar_lanca", "besta": "atacar_besta"}.get(arma, "")
			if a2 != "" and not _find(fs, a2, d).is_empty():
				anim = a2
	elif w.get("_ai_state") == "eating":
		anim = "comer"
		with_item = false
	elif injured:
		anim = "ferido"  # senta e mostra a tala: fica sentado (último quadro)
		hold_last = true
	var hit := _find(fs, anim, d)
	if hit.is_empty() and anim != "caminhada" and moving:
		hit = _find(fs, "caminhada", d)
	if hit.is_empty():
		hit = _find(fs, "parado", d)
	if hit.is_empty():
		return {}
	var info: Dictionary = hit[1]
	var n: int = maxi(int(info.n), 1)
	var frame := 0
	if hold_last:
		frame = n - 1
	elif walk_clock:
		frame = int(passo * n) % n if passo >= 0.0 else int(float(w.get("_anim_time"))) % n
	else:
		frame = int(clock * ANIM_FPS) % n
	# pele: a tira já pintada no tom (integra.py, mesma regra do skin_palette.gd); sem ela, pinta aqui
	var tone := _tone(w)
	var tex: Texture2D
	if tone != "" and data().get("tons", []).has(tone):
		tex = texture(String(info.img).trim_suffix(".png") + "__%s.png" % tone)
	else:
		tex = texture(info.img)
		if tone != "":
			tex = SkinPalette.texture_for(tex, tone, n)
	var top: Array = info.topo[mini(frame, info.topo.size() - 1)]
	var aj := _aj(info, frame)
	var out := {"hidden": false, "tex": tex, "n": n, "frame": frame, "ancora": Vector2(info.ancora[0], info.ancora[1]) - aj,
		"quadro": Vector2(info.quadro[0], info.quadro[1]), "top": Vector2(top[0], top[1]) + aj, "altura": -(float(top[1]) + aj.y),
		"anim": anim, "pasta": hit[0], "dir": d}
	if cargo and moving and not lying:
		out["saco"] = _saco(d, out.top)
	# Prompts 2 e 14: na MÃO — a placa de greve (protestando) e o cesto de coleta (caçador sem arco)
	var hand := ""
	if w.get("_ai_state") == "strike" and not lying:
		hand = "placa_greve"
	elif not lying and anim != "cacar" and _hand_tex_name(w) == "forage_basket":
		hand = "cesto"
	if hand != "":
		out["item"] = _hand(hand, d, out.top)
	elif with_item:
		out["item"] = _item(item_name, d, out.top)
	return out


static func _tone(w: Node) -> String:
	var tones: Array = SkinPalette.tones()
	var lk: int = int(w.get("look")) if w.get("look") != null else 0
	if tones.is_empty() or lk < 0:
		return ""
	return tones[lk % tones.size()]


static func _hand_tex_name(w: Node) -> String:
	if not w.has_method("_hand_item"):
		return ""
	var t: Texture2D = w._hand_item()
	return t.resource_path.get_file().get_basename() if t else ""


const PROPS_DIR := "res://assets/game/iso/props/"


## Coisa segura na mão (px de arte, relativo ao pé): a mão fica do lado da frente, na altura do
## quadril; a placa vai erguida (o cabo na mão). De costas (NE/NO), atrás do corpo.
static func _hand(name: String, d: String, top: Vector2) -> Dictionary:
	if not _tex.has("p:" + name):
		var p := PROPS_DIR + name + ".png"
		_tex["p:" + name] = load(p) if ResourceLoader.exists(p) else null
	var tex: Texture2D = _tex["p:" + name]
	if tex == null:
		return {}
	var right := d == "SE" or d == "NE"
	var hx: float = top.x + (7.0 if right else -7.0)
	var hy: float = top.y * 0.45
	var sz := tex.get_size()
	var y: float = hy - sz.y + 4.0 if name == "placa_greve" else hy - sz.y * 0.3
	return {"tex": tex, "pos": Vector2(hx - sz.x * 0.5, y).round(), "flip": not right, "front": d == "SE" or d == "SO"}


static func _item_name(w: Node) -> String:
	if not w.has_method("_hand_item"):
		return ""
	var t: Texture2D = w._hand_item()
	if t == null:
		return ""
	var it: String = ITEM_OF.get(t.resource_path.get_file().get_basename(), "")
	return it if data().get("ferramentas", {}).has(it) else ""


## Saco nas costas (saco.py): canto de cima-esquerdo relativo ao pé, na escala da altura do
## boneco naquele quadro (sobe e desce com o passo). SE atrás; SO espelho atrás; NE/NO na frente.
static func _saco(d: String, top: Vector2) -> Dictionary:
	var s: Dictionary = data().get("saco", {})
	var tex := texture(s.get("img", "saco_costas.png"))
	var off: Array = s.get("offset_do_pe", [-20.7, -67])
	var esc: float = -top.y / maxf(float(s.get("altura_ref", 76)), 1.0)
	var flip := d == "SO" or d == "NE"
	var x: float = off[0] if not flip else -off[0] - tex.get_width()
	return {"tex": tex, "pos": Vector2(x, off[1] * esc), "flip": flip, "front": d == "NE" or d == "NO"}


## Ferramenta nas costas (picareta_overlay.py): SE/NE configuradas; SO/NO espelhadas no pé.
static func _item(name: String, d: String, top: Vector2) -> Dictionary:
	var tex := texture(data().ferramentas[name])
	var base: String = "SE" if d in ["SE", "SO"] else "NE"
	var c: Dictionary = BACK[base]
	var cx := top.x if d == base else -top.x
	var x: float = cx + float(c.dx) - tex.get_width() * 0.5
	var flip: bool = c.mirror
	if d != base:
		x = -(x + tex.get_width())
		flip = not flip
	return {"tex": tex, "pos": Vector2(x, top.y + float(c.dy)), "flip": flip, "front": c.front}


# ------------------------------------------------------------ robô (Prompt 5 / parte 4)
## Robô antigo: no chão (achado, arrastado, conserto 1→2→3 pelo progresso) os estados parados,
## todos no mesmo quadro e âncora; ativo, boneco de 4 direções (anda, ataca, desligado quando
## apanha demais e fica atordoado até de manhã).
static func robo_pose(r: Node, iso_dir: int, clock: float, moving: bool) -> Dictionary:
	var env := r.get_tree().get_first_node_in_group("environment") if r.is_inside_tree() else null
	if env == null or not env.has_method("has_iso_map") or not env.has_iso_map() or not data().has("robo_parado"):
		return {}
	var st: String = r.get("state")
	var rp: Dictionary = data().robo_parado
	if st != "active":
		var name := "achado"
		match st:
			"carried":
				name = "arrastado"
			"base":
				name = "conserto_1"
			"repairing":
				var total: float = float(r.get("repair_time")) if r.get("repair_time") != null else 1.0
				var prog := 1.0 - float(r.get("repair_left")) / maxf(total, 0.001)
				name = "conserto_%d" % (1 + mini(int(prog * 3.0), 2))
		var tex := texture(rp.estados[name])
		return {"hidden": false, "tex": tex, "n": 1, "frame": 0, "ancora": Vector2(rp.ancora[0], rp.ancora[1]),
			"quadro": tex.get_size(), "top": Vector2(0, -60), "altura": 60.0, "anim": name, "pasta": "robo", "dir": "SE",
			"deitado": true}
	var d: String = DIR_NAMES[clampi(iso_dir, 0, 3)]
	var anim := "parado"
	var hold_last := false
	if r.get("stunned"):
		anim = "desligar"
		hold_last = true
	elif r.get("_foe") != null and is_instance_valid(r.get("_foe")) and float(r.get("_attack_cd")) > float(r.get("robot_attack_interval")) - 0.5:
		anim = "atacar"
	elif moving:
		anim = "caminhada"
	var hit := _find(["robo"], anim, d)
	if hit.is_empty():
		hit = _find(["robo"], "caminhada", d)
	if hit.is_empty():
		return {}
	var info: Dictionary = hit[1]
	var n: int = maxi(int(info.n), 1)
	var frame := n - 1 if hold_last else (int(clock * ANIM_FPS) % n if anim != "parado" else 0)
	var top: Array = info.topo[mini(frame, info.topo.size() - 1)]
	var aj := _aj(info, frame)
	return {"hidden": false, "tex": texture(info.img), "n": n, "frame": frame, "ancora": Vector2(info.ancora[0], info.ancora[1]) - aj,
		"quadro": Vector2(info.quadro[0], info.quadro[1]), "top": Vector2(top[0], top[1]) + aj, "altura": -(float(top[1]) + aj.y),
		"anim": anim, "pasta": "robo", "dir": d}


# ------------------------------------------------------------ criaturas (Prompt 17)
## Pasta da criatura (kind + variante) no bonecos.json.
const CRIATURA_PASTA := {"lumivoro": ["criatura_lumivoro", "criatura_lumivoro_bruto"],
	"ferrugento": ["criatura_ferrugento", "criatura_ferrugento_carregador"],
	"gosma": ["criatura_gosma", "criatura_gosma"], "magmante": ["criatura_magmante", "criatura_magmante"]}  # Bloco 70
## Bloco 62: a arte do chefe de cada tipo.
const CRIATURA_CHEFE := {"lumivoro": "criatura_lumivoro_matriarca"}
## Quanto tempo (s) cada reação fica na tela.
const CRIATURA_DANO := 0.35
const CRIATURA_ATAQUE := 0.6


## Invasor com a arte nova: anda, ataca, leva golpe, cai (fica deitado no último quadro) e, o
## Ferrugento, desliga ao amanhecer (a mesma queda). Só lê o estado da criatura (creature.gd).
static func criatura_pose(c: Node, iso_dir: int, moving: bool) -> Dictionary:
	var env := c.get_tree().get_first_node_in_group("environment") if c.is_inside_tree() else null
	if env == null or not env.has_method("has_iso_map") or not env.has_iso_map():
		return {}
	var pastas: Array = CRIATURA_PASTA.get(String(c.get("kind")), [])
	if pastas.is_empty():
		return {}
	var pasta: String = pastas[1] if c.get("variant") == "forte" else pastas[0]
	if c.get("variant") == "chefe" and data().get("pastas", {}).has(CRIATURA_CHEFE.get(String(c.get("kind")), "")):
		pasta = CRIATURA_CHEFE[String(c.get("kind"))]  # Bloco 62: a Matriarca
	if not data().get("pastas", {}).has(pasta):
		return {}
	var d: String = DIR_NAMES[clampi(iso_dir, 0, 3)]
	var t: float = float(c.get("_anim"))
	var anim := "parado"
	var since := t
	var once := false  # toca uma vez e para no último quadro
	if c.get("_dying"):
		anim = "morrer"; since = t - float(c._died_at); once = true
	elif c.get("_leaving") and c.get("kind") == "ferrugento":
		anim = "morrer"; since = t - float(c._left_at); once = true  # desliga
	elif t - float(c.get("_hit_at")) < CRIATURA_DANO:
		anim = "dano"; since = t - float(c._hit_at); once = true
	elif t - float(c.get("_attack_at")) < CRIATURA_ATAQUE:
		anim = "atacar"; since = t - float(c._attack_at); once = true
	elif moving or c.get("_leaving"):
		anim = "caminhada"
	var hit := _find([pasta], anim, d)
	if hit.is_empty():
		hit = _find([pasta], "parado", d)
	if hit.is_empty():
		return {}
	var info: Dictionary = hit[1]
	var n: int = maxi(int(info.n), 1)
	var frame: int = int(since * ANIM_FPS)
	frame = mini(frame, n - 1) if once else frame % n
	var top: Array = info.topo[mini(frame, info.topo.size() - 1)]
	var aj := _aj(info, frame)
	var out := {"hidden": false, "tex": texture(info.img), "n": n, "frame": frame, "ancora": Vector2(info.ancora[0], info.ancora[1]) - aj,
		"quadro": Vector2(info.quadro[0], info.quadro[1]), "top": Vector2(top[0], top[1]) + aj, "altura": -(float(top[1]) + aj.y),
		"anim": anim, "pasta": pasta, "dir": d}
	# Ferrugento que roubou: a caçamba cheia de minério por cima (na frente; de costas, também)
	var carga: Dictionary = data().get("carga_ferrugento", {})
	if c.get("looted") and not c.get("_dying") and carga.has(d) and pasta == pastas[0]:
		var cg: Array = carga[d]  # [x, y, topo do desenho parado]: a carga sobe e desce com o corpo
		out["item"] = {"tex": texture(carga.img), "pos": Vector2(cg[0], cg[1] + top[1] - float(cg[2])), "flip": false, "front": true}
	return out
