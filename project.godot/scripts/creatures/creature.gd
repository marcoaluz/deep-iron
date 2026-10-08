extends Node2D
## Criatura noturna (grupo "criaturas"), criada pela Defesa (defense.gd) nas noites de invasão.
##
##   Lumívoro   — come luz e calor. Vem da clareira pelo túnel. Ataca quem está acordado
##                lá fora e, nas casas/prédios acesos, assusta quem está dentro (ânimo cai).
##   Ferrugento — Bloco 80: um ROBÔ pequeno e enferrujado de antes da explosão (esqueleto de metal,
##                crânio, olhos vermelhos). Sai da boca do poço do elevador (só depois que o nível 2
##                abre) — o poço não tem muro: entra direto e só os guardas do posto do poço param.
##                Ataca quem estiver perto e rouba minério do armazém.
##   Gosma ácida — Bloco 70: do S2 (ácido). Bloco 103: MORA no S2 (de dia e de noite, nunca sobe) e ataca quem
##                está no andar; o golpe num guarda armado corrói a arma (corrosao_gosma).
##   Magmante   — Bloco 70: do S3 (lava). Bloco 103: MORA no S3. Lento e duro. Derrubado, às vezes deixa
##                cristal rubro.
## Bloco 103: os MORADORES do fundo (morador = o andar) nascem pela Defesa (defense.gd: moradores dos dados do andar),
## vagam perto de casa, só miram quem está no MESMO andar e não saem dele; não fogem ao amanhecer. Abatida, a criatura
## deixa um CORPO (corpo_criatura.gd) com o que ela deixou (o drop de sempre): a pesquisadora estuda e colhe; espécie
## já estudada (ou sem catálogo) manda o drop direto pro armazém, como antes.
## O Lumívoro vem da floresta: antes de entrar, precisa derrubar a barricada do portão (se tiver uma
## de pé). Bloco 36: com o guarda do portão dele CAÍDO (brecha), vai direto no armazém saquear
## (defense.gd: raid — uma parte do minério e dos créditos, uma vez por invasão). Bloco 80: o único
## portão é o da floresta ("tunel"); quem sai do poço não tem portão (gate_id "") e não abre brecha.
## Ao amanhecer: o Lumívoro foge da luz e o Ferrugento desliga.
## Bloco 80: VISUAL CONFIGURÁVEL (grupo "Visual (folha de quadros)"): com `visual_textura`, a criatura
## se desenha por uma folha — uma linha por animação (`visual_anims`), `visual_quadros` quadros em cada,
## quadros de `visual_quadro` px, virada pra direita. Trocar os sprites (PixelLab) = trocar esses campos
## na cena, sem mexer aqui. Sem textura, vale a arte isométrica do bonecos.json (iso_bonecos.gd).
## Prompt 17: na vista iso a arte nova vem de iso_bonecos.gd (criatura_pose), pelo estado daqui:
## andando, atacando (_attack_at), levando golpe (_hit_at), morrendo (_died_at, fica deitado um
## pouco antes de sumir) e desligando ao amanhecer. Variante FORTE (bruto/carregador): defense.gd
## escolhe nas ondas altas (make_strong).

const IsoArt := preload("res://scripts/iso/iso_art.gd")
const Ores := preload("res://scripts/core/ores.gd")
signal died(killed: bool)

@export_enum("lumivoro", "ferrugento", "gosma", "magmante") var kind: String = "lumivoro"
@export var max_hp: float = 18.0
@export var speed: float = 68.0
@export var damage: float = 4.0
@export var attack_interval: float = 1.0
@export var attack_range: float = 18.0
## Ipezinho (não guarda) atingido: chance do machucado ser grave.
@export_range(0.0, 1.0) var grave_chance: float = 0.15
## Ferrugento no armazém: minério roubado por golpe.
@export var steal_amount: float = 3.0
## Lumívoro num prédio aceso: ânimo tirado de cada um lá dentro, por golpe.
@export var scare_amount: float = 1.0
## Distância em que ele larga o alvo e parte pra cima de quem está perto.
@export var notice_range: float = 150.0
## Bloco 70: multiplica o dano na barricada (o ácido e a lava derretem).
@export var barricade_mult: float = 1.0
## Bloco 70: derrubado, chance de deixar cristal (minério, quantidade) no armazém (Bloco 103: no corpo, até o estudo).
@export var drop_ore: String = ""
@export var drop_amount: int = 0
@export_range(0.0, 1.0) var drop_chance: float = 0.0

## Bloco 103: durabilidade que o golpe da Gosma tira a mais da arma do guarda (a corrosão do ácido; 0 = nenhuma).
@export var corrosao_gosma: float = 1.0
## Bloco 103: morador do fundo: distância (px) de casa até onde ele persegue alguém (depois volta).
@export var alcance_casa: float = 260.0
## Bloco 103: morador do fundo: raio (px) e intervalo (s) do passeio em volta de casa quando não tem ninguém por perto.
@export var passeio_raio: float = 90.0
@export var passeio_intervalo: float = 6.0

@export_group("Luz (Bloco 90)")
## Lumívoro: o quanto uma tocha/lampião aceso da decoração atrai mais que um prédio aceso (a distância conta
## dividida por isto: 2 = uma luz a 200 px pesa como um prédio a 100 px).
@export var atracao_luz: float = 2.0

@export_group("Visual (folha de quadros)")
## Bloco 80: a folha de quadros da criatura (uma LINHA por animação, na ordem de visual_anims; quadros da
## esquerda pra direita, virada pra direita). Vazia = a arte isométrica do bonecos.json.
@export var visual_textura: Texture2D
## Tamanho de UM quadro na folha (px).
@export var visual_quadro := Vector2i(24, 32)
## As animações, na ordem das linhas da folha (as que o jogo usa: parado, caminhada, atacar, dano, morrer).
@export var visual_anims: PackedStringArray = PackedStringArray(["parado", "caminhada", "atacar", "dano", "morrer"])
## Quantos quadros cada animação tem (mesma ordem de visual_anims).
@export var visual_quadros: PackedInt32Array = PackedInt32Array([2, 4, 3, 2, 4])
## Quadros por segundo (parado, atacar, dano, morrer).
@export var visual_fps := 8.0
## Px andados por ciclo da caminhada (a perna acompanha o chão: o pé não escorrega).
@export var visual_passada := 34.0
## Escala do desenho (1 = 1 px da folha por px do mundo).
@export var visual_escala := 1.0
## Px entre o pé e a borda de baixo do quadro (o pé fica na origem da criatura).
@export var visual_pe := 2.0
## O que ele leva quando roubou o armazém (desenhado nas costas; vazio = nada).
@export var visual_carga: Texture2D
## Onde fica a carga (px do mundo, a partir do pé, com o desenho virado pra direita: x < 0 = costas).
@export var visual_carga_pos := Vector2(-6, -16)

var hp: float = 0.0
## Portão por onde ele vem ("tunel"; "" = sai do poço, sem portão) — Bloco 36, pra saber se a brecha é
## a dele (Bloco 80: o portão do poço saiu).
var gate_id: String = ""
## Já passou (ou derrubou) a barricada do caminho?
var inside: bool = false
var _gate: Node2D = null
var _target: Node2D = null
var _aggressor: Node2D = null
var _attack_cd := 0.0
var _retarget := 0.0
var _anim := 0.0
var _dying := false
var _leaving := false
## Prompt 17: "" ou "forte" (Lumívoro bruto / Ferrugento carregador).
var variant := ""
## Quando (no relógio _anim) atacou, levou golpe, caiu e começou a ir embora: escolhem a animação.
var _attack_at := -100.0
var _hit_at := -100.0
var _died_at := -100.0
var _left_at := -100.0
## Ferrugento que já roubou minério: sai carregando (visual_carga nas costas).
var looted := false
## Bloco 62: elite (forte do tier alto) e chefe; o golpe do chefe num guarda armado gasta a arma.
var elite := false
var weapon_corrode := 0.0
var _shout_at := -100.0
## Bloco 80: andou neste quadro? e quanto já andou (a caminhada da folha de quadros vai pela distância).
var _andando := false
var _andado := 0.0
var _carga: Sprite2D = null
## Bloco 103: morador do fundo: o andar (id do nível: "S2"...; "" = criatura de invasão), onde nasceu e o passeio.
var morador := ""
var casa := Vector2.ZERO
var _passeio := Vector2.INF
var _passeio_t := 0.0

@onready var _visual: Sprite2D = $Visual
@onready var _agent: NavigationAgent2D = $Agent
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	add_to_group("criaturas")
	hp = max_hp
	_light.add_to_group("cullable_lights")
	_monta_visual()


## Bloco 80: a folha de quadros (se tiver): o Visual passa a recortar um quadro dela.
func _monta_visual() -> void:
	if visual_textura == null:
		return
	_visual.texture = visual_textura
	_visual.hframes = 1
	_visual.vframes = 1
	_visual.region_enabled = true
	_visual.centered = true
	_visual.scale = Vector2.ONE * visual_escala
	_visual.offset = Vector2(0.0, -float(visual_quadro.y) * 0.5 + visual_pe)
	_visual.region_rect = Rect2(Vector2.ZERO, Vector2(visual_quadro))
	if visual_carga:
		_carga = Sprite2D.new()
		_carga.name = "Carga"
		_carga.texture = visual_carga
		_carga.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_carga.visible = false
		add_child(_carga)


## A animação de agora: [nome, segundos desde que começou, toca uma vez só].
func anim_atual() -> Array:
	if _dying:
		return ["morrer", _anim - _died_at, true]
	if _leaving:
		return ["morrer", _anim - _left_at, true]  # o Ferrugento desliga (a mesma queda)
	if _anim - _hit_at < 0.35:
		return ["dano", _anim - _hit_at, true]
	if _anim - _attack_at < 0.6:
		return ["atacar", _anim - _attack_at, true]
	if _andando:
		return ["caminhada", _anim, false]
	return ["parado", _anim, false]


## Bloco 80: escolhe o quadro da folha pela animação de agora.
func _atualiza_visual() -> void:
	if visual_textura == null:
		_visual.frame = int(_anim * (9.0 if kind == "lumivoro" else 5.0)) % 2
		return
	var a := anim_atual()
	var linha := visual_anims.find(String(a[0]))
	if linha < 0:
		linha = maxi(visual_anims.find("parado"), 0)
	var n: int = maxi(visual_quadros[linha] if linha < visual_quadros.size() else 1, 1)
	var i: int
	if String(a[0]) == "caminhada":
		i = int(_andado / maxf(visual_passada, 1.0) * n) % n
	else:
		i = int(float(a[1]) * visual_fps)
		i = mini(i, n - 1) if a[2] else i % n
	_visual.region_rect = Rect2(Vector2(i * visual_quadro.x, linha * visual_quadro.y), Vector2(visual_quadro))
	if _carga:
		_carga.visible = looted and not _dying
		_carga.position = Vector2(visual_carga_pos.x * (-1.0 if _visual.flip_h else 1.0), visual_carga_pos.y)


## Chamado pela Defesa logo depois de nascer: qual barricada fica no caminho e quão forte é a onda.
func setup(gate: Node2D, hp_mult: float) -> void:
	_gate = gate
	max_hp *= hp_mult
	hp = max_hp
	inside = gate == null or not gate.is_standing()


## Prompt 17: a variante forte (mais vida e dano, um pouco mais lenta).
func make_strong(hp_mult: float, damage_mult: float) -> void:
	variant = "forte"
	max_hp *= hp_mult
	hp = max_hp
	damage *= damage_mult
	speed *= 0.9
	_visual.scale *= 1.25


## Bloco 62: elite — o forte das ondas de tier alto (Lumívoro ancião / Ferrugento blindado).
func make_elite(hp_mult: float, damage_mult: float) -> void:
	elite = true
	max_hp *= hp_mult
	hp = max_hp
	damage *= damage_mult
	_visual.modulate = Color(0.85, 0.7, 1.15)
	modulate = Color(0.92, 0.82, 1.1)


## Bloco 62: a Matriarca (chefe): muita vida, dano dobrado, lenta, maior, enxerga de longe.
func make_boss(hp_mult: float, damage_mult: float) -> void:
	variant = "chefe"
	max_hp *= hp_mult
	hp = max_hp
	damage *= damage_mult
	speed *= 0.7
	notice_range *= 1.5
	attack_range += 8.0
	grave_chance = 0.4
	_visual.scale *= 1.8
	_light.energy *= 1.6
	_light.texture_scale *= 1.8
	add_to_group("chefes")


## O grito do chefe (anima "atacar" e faz a luz pulsar).
func shout() -> void:
	_shout_at = _anim
	_attack_at = _anim
	var t := create_tween()
	t.tween_property(_light, "energy", _light.energy * 2.0, 0.15)
	t.tween_property(_light, "energy", _light.energy, 0.5)


func is_alive() -> bool:
	return not _dying and not _leaving


func _process(delta: float) -> void:
	_anim += delta
	_atualiza_visual()
	_andando = false
	if _dying or _leaving:
		return
	_attack_cd -= delta
	_retarget -= delta
	if _gate != null and (not is_instance_valid(_gate) or not _gate.is_standing()):
		_gate = null
		inside = true
	if _gate != null:
		_target = _gate
	elif _retarget <= 0.0 or _target == null or not is_instance_valid(_target) or not _target_ok(_target):
		_retarget = 0.7
		_target = _pick_target()
	if _target == null:
		if morador != "":
			_passeia(delta)  # Bloco 103: ninguém no andar perto: passeia em volta de casa
		return
	var tpos := _target.global_position
	var d := global_position.distance_to(tpos)
	var reach := attack_range + (22.0 if _target.is_in_group("barricadas") or _is_building(_target) else 0.0)
	var wall := IsoArt.base_rect(_target) if _is_building(_target) else Rect2()
	if wall.has_area():
		# Prompt 29: o prédio novo tem fundo de verdade; conta até a parede (o centro fica longe)
		d = global_position.distance_to(global_position.clamp(wall.position, wall.end))
		reach = attack_range + 10.0
	if d > reach:
		if _agent.target_position.distance_to(tpos) > 8.0:
			_agent.target_position = tpos
		var next := _agent.get_next_path_position()
		var step := (next - global_position).limit_length(speed * delta)
		global_position += step
		_andando = step.length() > 0.05
		_andado = fmod(_andado + step.length(), 100000.0)
		if absf(step.x) > 0.01:
			_visual.flip_h = step.x < 0.0
	elif _attack_cd <= 0.0:
		_attack_cd = attack_interval
		_attack(_target)
	queue_redraw()


## Bloco 103: o morador sem alvo anda devagar até um ponto perto de casa e espera um pouco.
func _passeia(delta: float) -> void:
	_passeio_t -= delta
	if _passeio == Vector2.INF or _passeio_t <= 0.0:
		_passeio_t = passeio_intervalo * randf_range(0.7, 1.3)
		var a := randf() * TAU
		_passeio = casa + Vector2(cos(a), sin(a) * 0.6) * randf_range(10.0, passeio_raio)
		_agent.target_position = _passeio
	if global_position.distance_to(_passeio) < 6.0 or _agent.is_navigation_finished():
		return
	var step := (_agent.get_next_path_position() - global_position).limit_length(speed * 0.45 * delta)
	global_position += step
	_andando = step.length() > 0.05
	_andado = fmod(_andado + step.length(), 100000.0)
	if absf(step.x) > 0.01:
		_visual.flip_h = step.x < 0.0


func _is_building(n: Node) -> bool:
	return n.is_in_group("casas") or n.is_in_group("armazens") or n.is_in_group("enfermarias") \
		or n.is_in_group("tavernas") or n.is_in_group("village_hub")


func _target_ok(t: Node2D) -> bool:
	if morador != "":  # Bloco 103: o morador só mira quem está no mesmo andar e perto de casa
		if not t.is_in_group("ipezinhos") or t.get("injured") or t.get("_inside") or not _mesmo_andar(t):
			return false
		return t.global_position.distance_to(casa) <= alcance_casa
	if t.is_in_group("ipezinhos"):
		return not t.get("injured") and not t.get("_inside") and _on_surface(t)
	if t.is_in_group("robos"):
		return t.can_fight()
	return true


func _mesmo_andar(n: Node2D) -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	return env == null or env.level_at(n.global_position) == env.level_at(casa)


func _on_surface(n: Node2D) -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	return env == null or env.level_at(n.global_position) == 0


func _nearest(candidates: Array, max_d: float = INF) -> Node2D:
	var best: Node2D = null
	var best_d := max_d
	for c in candidates:
		var d := global_position.distance_to(c.global_position)
		if d < best_d:
			best_d = d
			best = c
	return best


func _pick_target() -> Node2D:
	# Bloco 36: guarda do meu portão caído = brecha: direto pro armazém
	var def := get_tree().get_first_node_in_group("defense")
	if def and def.breached(gate_id):
		var stores := get_tree().get_nodes_in_group("armazens")
		if not stores.is_empty():
			return _nearest(stores)
	# quem me bateu por último, se ainda estiver perto
	if _aggressor != null and is_instance_valid(_aggressor) and _target_ok(_aggressor) \
			and global_position.distance_to(_aggressor.global_position) < notice_range:
		return _aggressor
	var awake := get_tree().get_nodes_in_group("ipezinhos").filter(func(w): return _target_ok(w))
	if morador != "":  # Bloco 103: quem está no andar dele, perto; senão ninguém (passeia)
		return _nearest(awake, notice_range)
	if kind == "lumivoro":
		# atraído pela luz: gente acordada lá fora (lanterna na cabeça) ou prédio aceso
		var who := _nearest(awake, notice_range * 1.8)
		if who:
			return who
		var lit: Array = []
		for c in get_tree().get_nodes_in_group("casas"):
			if c.sleeping_count() > 0:
				lit.append(c)
		for g in ["enfermarias", "tavernas"]:
			for n in get_tree().get_nodes_in_group(g):
				if n.has_method("guests") and not n.guests().is_empty():
					lit.append(n)
				elif n.has_method("patients") and not n.patients().is_empty():
					lit.append(n)
		if lit.is_empty():
			lit = get_tree().get_nodes_in_group("village_hub")
		# Bloco 90: tochas e lampiões acesos da decoração atraem mais (atracao_luz)
		var melhor := _nearest(lit)
		var nota := global_position.distance_to(melhor.global_position) if melhor else INF
		for d in get_tree().get_nodes_in_group("decor_luzes"):
			if d.acesa():
				var nd := global_position.distance_to(d.global_position) / maxf(atracao_luz, 0.01)
				if nd < nota:
					nota = nd
					melhor = d
		return melhor
	# ferrugento (e os do fundo): quem estiver perto; senão o minério do armazém
	var near := _nearest(awake, notice_range)
	if near:
		return near
	var full := get_tree().get_nodes_in_group("armazens").filter(func(a): return a.total_stored >= 1.0)
	if not full.is_empty():
		return _nearest(full)
	return _nearest(awake)


func _attack(t: Node2D) -> void:
	_attack_at = _anim
	_visual.position.y = -3.0
	create_tween().tween_property(_visual, "position:y", 0.0, 0.15)
	if t.is_in_group("barricadas"):
		t.damage(damage * barricade_mult)
		if kind == "ferrugento":
			Audio.clank(global_position)
		return
	if t.is_in_group("armazens"):
		var def := get_tree().get_first_node_in_group("defense")
		if def and def.breached(gate_id):
			def.raid(self, t)  # Bloco 36: saque pela brecha
	if t.has_method("take_hit"):
		var corroi := weapon_corrode if weapon_corrode > 0.0 else (corrosao_gosma if kind == "gosma" else 0.0)
		if corroi > 0.0 and t.get("weapon") != null and String(t.weapon) != "" and t.has_method("_wear_weapon"):
			t.weapon_durability -= maxf(corroi - 1.0, 0.0)  # Bloco 62: a Matriarca; Bloco 103: o ácido da Gosma
			t._wear_weapon()
		t.take_hit(damage, self)
		if kind == "lumivoro":
			Audio.screech(global_position)
		else:
			Audio.clank(global_position)
		return
	if kind in ["gosma", "magmante"] and t.is_in_group("armazens"):
		# Bloco 70: a Gosma dissolve o metal; o Magmante come o carvão (some, ninguém leva)
		var tipos: Array = ["ferro", "cobre"] if kind == "gosma" else ["carvao"]
		var gone := 0.0
		for ore in tipos:
			if gone >= steal_amount:
				break
			gone += t.take(steal_amount - gone, ore)
		if gone > 0.0:
			t.show_popup("-%d %s (%s)" % [roundi(gone), "metal" if kind == "gosma" else "carvão", "Gosma" if kind == "gosma" else "Magmante"], Color(1.0, 0.45, 0.35))
		Audio.clank(global_position)
		return
	if kind == "ferrugento" and t.is_in_group("armazens"):
		var left := steal_amount
		for ore in Ores.TYPES:
			if left <= 0.0:
				break
			left -= t.take(left, ore)
		if left < steal_amount:
			looted = true
			t.show_popup("-%d (Ferrugento)" % roundi(steal_amount - left), Color(1.0, 0.45, 0.35))
		Audio.clank(global_position)
		return
	if kind == "lumivoro":
		# prédio aceso: quem está lá dentro morre de medo
		for w in get_tree().get_nodes_in_group("ipezinhos"):
			if w.get("_inside") and w.global_position.distance_to(t.global_position) < 90.0:
				w.happiness = maxf(w.happiness - scare_amount, 0.0)
		Audio.screech(global_position)


func take_hit(amount: float, attacker: Node2D) -> void:
	if not is_alive():
		return
	hp -= amount
	_hit_at = _anim
	_aggressor = attacker
	_visual.modulate = Color(2.2, 2.2, 2.2)
	create_tween().tween_property(_visual, "modulate", Color.WHITE, 0.15)
	if hp <= 0.0:
		die(true)
	queue_redraw()


func die(killed: bool) -> void:
	if _dying:
		return
	_dying = true
	_died_at = _anim
	_light.enabled = false
	if killed:
		Audio.creature_down(global_position)  # Bloco 55
	died.emit(killed)
	if killed:
		_deixa_corpo()
	var t := create_tween()
	if _iso_art():
		t.tween_interval(1.4)  # Prompt 17: cai (animação) e fica um pouco no chão antes de sumir
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	t.tween_callback(queue_free)


## Bloco 103: o abate deixa o CORPO no chão (o último quadro da morte) com o drop de sempre (mesmas chances). Espécie
## ainda não estudada: o drop fica no corpo (a pesquisadora colhe no estudo; no prazo, vai pro armazém). Já estudada (ou
## sem catálogo): o drop vai direto pro armazém, como antes. Bloco 102: e a AMOSTRA pro plano B do laboratório.
func _deixa_corpo() -> void:
	var drop := {}
	if kind == "ferrugento" and randf() < 0.35:
		drop["pecas"] = 1
	if drop_ore != "" and drop_amount > 0 and randf() < drop_chance:
		drop[drop_ore] = drop_amount  # Bloco 70: o cristal que ele carregava
	var cat := get_tree().get_first_node_in_group("catalogo")
	if cat:
		cat.amostra(kind, is_in_group("chefes"))
	var corpo: Node2D = preload("res://scripts/props/corpo_criatura.gd").new()
	corpo.monta(self)
	if cat:
		var p: Array = cat.prazo_corpo()
		corpo.prazo_dia = int(p[0])
		corpo.prazo_t = float(p[1])
	if cat == null or cat.estudado(corpo.especie):
		var txt := _drop_ja(drop)  # (já conhecida: direto pro armazém, como antes)
		if txt != "":
			var hud := get_tree().get_first_node_in_group("hud")
			if hud:
				hud.show_toast("Dos restos: %s no armazém." % txt, Color(1.0, 0.85, 0.45))
	else:
		corpo.drop = drop  # (fica no corpo até o estudo ou o prazo)
	get_parent().add_child.call_deferred(corpo)


## O drop direto pro armazém (espécie já estudada), sem esperar o corpo entrar na árvore. Retorna o texto.
func _drop_ja(drop: Dictionary) -> String:
	var partes: Array[String] = []
	for it in drop:
		if it == "pecas":
			var finds := get_tree().get_first_node_in_group("finds")
			if finds:
				finds.rare_parts += int(drop[it])
				partes.append("+%d peça rara" % int(drop[it]))
		else:
			var arm := get_tree().get_first_node_in_group("armazens")
			if arm:
				arm.add_ore(float(drop[it]), String(it))
				partes.append("+%d %s" % [int(drop[it]), Ores.display_name(String(it)).to_lower()])
	drop.clear()
	return ", ".join(partes)


## Amanhecer: o Lumívoro foge voando; o Ferrugento (robô) desliga, desmonta e vira pó de ferrugem.
func leave_at_dawn() -> void:
	if not is_alive():
		return
	_leaving = true
	_left_at = _anim
	var t := create_tween()
	if kind == "lumivoro":
		t.set_parallel(true)
		t.tween_property(self, "global_position", global_position + Vector2(randf_range(-60, 60), -160), 1.6)
		t.tween_property(self, "modulate:a", 0.0, 1.6)
	else:
		_light.enabled = false
		_visual.modulate = Color(0.55, 0.5, 0.5)
		t.tween_interval(1.5)
		t.tween_property(self, "modulate:a", 0.0, 1.2)
	t.chain().tween_callback(queue_free)


## A vista iso está desenhando esta criatura com a arte nova?
func _iso_art() -> bool:
	var env := get_tree().get_first_node_in_group("environment") if is_inside_tree() else null
	return env != null and env.has_method("has_iso_map") and env.has_iso_map()


func _draw() -> void:
	if _dying or hp >= max_hp:
		return
	var w := 22.0
	var y := -32.0
	if visual_textura:  # Bloco 80: acima do desenho da folha (o tamanho vem do quadro)
		y = -(float(visual_quadro.y) - visual_pe) * absf(_visual.scale.y) - 6.0
	draw_rect(Rect2(-w * 0.5, y, w, 3), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 3), Color(0.9, 0.3, 0.25))
