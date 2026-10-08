extends "res://scripts/props/station.gd"
## Ponto de carga do vagonete (grupo "pontos_carga") — Bloco 64: trilho + vagonete automático.
##
## Fica perto das jazidas. O minerador entrega aqui quando é mais perto que o armazém (menos
## caminhada); o VAGONETE leva o que juntou pelo trilho até o armazém mais perto e volta, sozinho.
## O trilho gasta a cada viagem; quebrou, o vagonete para e o engenheiro conserta (obra). Parado ou
## cheio, o ponto não aceita mais carga e os mineradores voltam pro armazém: nada trava.
## Construído pelo engenheiro (canteiro "vagonete", dono: Centro da Vila).
##
## Bloco 99: CARGAS GRANDES (100 por viagem, o ponto guarda 240, espera até 60 s pra juntar) e o trilho gasta POR
## MINÉRIO levado (`desgaste_ref` minério = 1 "viagem" de desgaste: o mesmo desgaste por minério de antes, com as viagens
## mais espaçadas). O ponto da BOCA DA MINA (`tem_interior`, grupo "bocas_mina") tem a galeria de dentro: o mineiro da
## área de mina em volta, com o trilho e o vagonete funcionando, ENTRA pela boca e trabalha lá dentro (some do mundo,
## "dentro da mina N/5", lanterna acesa e o som da picareta na boca), tirando da jazida da área no ritmo `taxa_dentro`
## (o mesmo de hoje nas galerias: a renda fica igual) direto pro ponto. Sem trilho, quebrado, ponto cheio ou armazém
## cheio: não aceita e ele sai e minera na mão, como antes.

const Iso := preload("res://scripts/iso/iso_core.gd")

@export_group("Vagonete (Bloco 64)")
## Minério que o ponto guarda esperando o vagonete, e quanto o vagonete leva por viagem (Bloco 99: 60 -> 240, 25 -> 100).
@export var buffer_capacity: float = 240.0
@export var cart_capacity: float = 100.0
## Velocidade do vagonete (px da lógica / s) e quanto espera juntar carga antes de sair (s; Bloco 99: 8 -> 60).
@export var cart_speed: float = 55.0
@export var cart_wait: float = 60.0
## Desgaste do trilho até quebrar, em "viagens" de `desgaste_ref` minério cada (Bloco 99: gasta por minério levado, não
## por viagem), e segundos de engenheiro pra consertar.
@export var rail_trips: int = 25
## Minério que vale 1 viagem de desgaste (o carrinho de antes levava 25: 25 x 25 = 625 minério até quebrar).
@export var desgaste_ref: float = 25.0
@export var repair_seconds: float = 20.0

@export_group("Dentro da mina (Bloco 99)")
## Esta é a boca da mina (tem galeria de dentro onde o mineiro trabalha escondido)?
@export var tem_interior := false
## Quantos mineiros cabem lá dentro.
@export var vagas_dentro: int = 5
## Minério por mineiro por HORA DE JOGO lá dentro (o mesmo que eles tiram hoje nas galerias da montanha, contando a
## caminhada até o armazém: a renda fica igual; ver tests/bench_minerio.gd).
@export var taxa_dentro: float = 21.0
## A área de mina conta se a boca estiver dentro dela ou a até esta distância da borda (px).
@export var alcance_area: float = 80.0
## Bloco 74: o da mina (fixo): o trilho sai do batente da boca, desce reto e vira pra porta do armazém
## (em vez do caminho da navegação).
@export var rota_fixa := false
## Bloco 79: FERROVIA DE CARGA — o id do andar (S2..S5) onde fica a estação ("" = o vagonete comum). O trilho
## no chão é só o pedaço até a doca; o resto da viagem é a SUBIDA pelo cavalete até a superfície (a vista iso
## desenha o cavalete e o carrinho subindo), e a carga vai pro armazém.
@export var ferrovia := ""
## Bloco 79: o comprimento da subida (px da lógica) = base + por andar de profundidade.
const SUBIDA_BASE := 260.0
const SUBIDA_POR_ANDAR := 150.0
var _len_chao := 0.0

var stock := {}  # minério esperando o vagonete
var rail: Node2D = null  # o trilho (Node2D "trilhos" com os pontos)
var rail_left := 25.0  # viagens de desgaste até quebrar (Bloco 99: fração = minério / desgaste_ref)
var repair_left := 0.0
var total_moved := 0.0
## Vagonete: "esperando", "indo", "voltando"; posição no trilho (0..comprimento) e a carga.
var cart_state := "esperando"
var cart_d := 0.0
var cart_load := {}
var _wait_t := 0.0
var _len := 0.0
var _cart: Node2D
var _obra := preload("res://scripts/core/obra_site.gd").new()
## Bloco 77: a área de mina em volta não está operando (desligada / sem mineiro / sem jazida): o vagonete
## fica parado no ponto e o ponto não recebe carga (work_areas.gd liga e desliga).
var _parado_area := false
var _motivo_area := ""
## Bloco 99: quem está lá dentro, a carga desta viagem (pro desgaste), o som da picareta e a lanterna da boca.
var dentro: Array = []
var _carga_viagem := 0.0
var _som_t := 0.0
var _boca_cache := Vector2.INF
var _lanterna: PointLight2D
var _lampiao: Node2D  # o lampião no poste com as picaretas, na boca (só com gente dentro)

@onready var _label: Label = $StatusLabel


func _ready() -> void:
	super()
	add_to_group("pontos_carga")
	add_to_group("obras")
	if ferrovia != "":
		add_to_group("ferrovias")  # Bloco 79
	var v: Sprite2D = $Visual  # o guindaste da pedreira (arte do pacote de objetos), 1 px de arte = 1 px de tela
	var env := get_tree().get_first_node_in_group("environment")
	var sc: float = env.iso_scale() if env and env.has_method("has_iso_map") and env.has_iso_map() else 0.5
	v.scale = Vector2.ONE * (0.6 / maxf(sc, 0.01))
	v.offset = Vector2(-v.texture.get_width() * 0.5, -v.texture.get_height() + 16.0)
	rail_left = float(rail_trips)
	if tem_interior:
		add_to_group("bocas_mina")
		_lanterna = PointLight2D.new()
		_lanterna.name = "Lamp"  # (a vista iso copia como lampião)
		_lanterna.texture = load("res://assets/game/light_radial.tres")
		_lanterna.color = Color(1.0, 0.72, 0.38)
		_lanterna.energy = 0.0
		_lanterna.texture_scale = 0.45
		_lanterna.position = Vector2(0, -34)
		_lanterna.enabled = false
		add_child(_lanterna)
		_poe_lampiao.call_deferred()
	_make_cart()
	_build_rail.call_deferred()


func _accepts(body: Node2D) -> bool:
	return body.has_method("deposit")


## Recebe carga? (cheio ou trilho quebrado com o ponto lotado: não — o minerador vai pro armazém)
func is_usable() -> bool:
	return not _parado_area and buffered() < buffer_capacity - 1.0 and rail != null and not (is_broken() and buffered() >= cart_capacity)


## Bloco 77: work_areas.gd chama (o estado da área de mina onde fica o ponto).
func parar_por_area(on: bool, motivo: String = "") -> void:
	_parado_area = on
	_motivo_area = motivo


func parado_por_area() -> bool:
	return _parado_area


func accepts_worker(worker: Node) -> bool:
	return worker.get("carrying") != null and worker.carrying > 0.0


func buffered() -> float:
	var s := 0.0
	for k in stock:
		s += stock[k]
	return s


func is_broken() -> bool:
	return rail_left <= 0.0


# ------------------------------------------------------------ dentro da mina (Bloco 99)
## O ponto de pisar na frente da boca (onde o mineiro entra e sai).
func boca_pos() -> Vector2:
	if _boca_cache == Vector2.INF and is_inside_tree():
		var alvo := global_position + Vector2(0, -24)
		var map := get_world_2d().navigation_map
		if map.is_valid() and NavigationServer2D.map_get_iteration_id(map) > 0:
			_boca_cache = NavigationServer2D.map_get_closest_point(map, alvo)
		else:
			return alvo
	return _boca_cache


## O vagonete leva o que sai daqui agora? (trilho inteiro, área operando, ponto com espaço, armazém com espaço)
func operando() -> bool:
	return rail != null and is_instance_valid(rail) and not is_broken() and not _parado_area \
		and buffered() < buffer_capacity - 1.0 and not _sem_espaco


## A área de mina do mineiro em volta desta boca, ligada (null = não).
func _area_de(w: Node) -> Variant:
	var a = w.get("work_area")
	if a == null or a.tipo != "mina" or not a.ativa:
		return null
	return a if a.rect.grow(alcance_area).has_point(global_position) else null


## Uma jazida da área com minério (a mais valiosa) pra tirar lá de dentro.
func _jazida(a) -> Node:
	var melhor: Node = null
	var melhor_v := -INF
	var env := get_tree().get_first_node_in_group("environment")
	for j in get_tree().get_nodes_in_group("minerios"):
		if not a.contem(j.global_position) or not j.is_usable():
			continue
		if env and env.has_method("trancado") and env.trancado(j.global_position):
			continue
		if j.get("hazard") != "" and j.get("hazard") != null:
			continue  # (zona de perigo: precisa do traje; lá dentro não tem vestiário)
		var v: float = j.get_value_weight()
		if v > melhor_v:
			melhor_v = v
			melhor = j
	return melhor


## Esse mineiro pode trabalhar (ou continuar) lá dentro agora?
func aceita_dentro(w: Node) -> bool:
	if not tem_interior or not operando():
		return false
	var a = _area_de(w)
	if a == null or _jazida(a) == null:
		return false
	return dentro.has(w) or dentro.size() < vagas_dentro


func entra(w: Node) -> void:
	if not dentro.has(w):
		dentro.append(w)
	_update_label()


func sai(w: Node) -> void:
	dentro.erase(w)
	_update_label()


## A produção de quem está dentro (por quadro): tira da jazida da área e põe no ponto.
func _produz_dentro(delta: float) -> void:
	dentro = dentro.filter(func(w): return is_instance_valid(w) and w.has_method("dentro_da_mina") and w.dentro_da_mina())
	if dentro.is_empty():
		return
	var dn := get_tree().get_first_node_in_group("day_night")
	var sph: float = dn.segundos_por_hora() if dn and dn.has_method("segundos_por_hora") else 22.5
	for w in dentro:
		if not operando():
			w.set("_decision_timer", 0.0)  # parou (cheio, trilho quebrado): ele sai e decide de novo
			continue
		var a = _area_de(w)
		var j: Node = _jazida(a) if a != null else null
		if j == null:
			w.set("_decision_timer", 0.0)
			continue
		var quer: float = taxa_dentro * delta / maxf(sph, 0.01) * float(w.mult_mineracao())
		var taken: float = j.extract(minf(quer, buffer_capacity - buffered()))
		if taken > 0.0:
			var t: String = j.ore_type
			stock[t] = stock.get(t, 0.0) + taken
			w.minerou_dentro(taken, t)
	_som_t -= delta
	if _som_t <= 0.0:
		_som_t = randf_range(0.7, 1.3)
		Audio.pick(boca_pos())  # a picareta lá dentro, ouvida na boca


# ------------------------------------------------------------ trilho
func armazem() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for a in get_tree().get_nodes_in_group("armazens"):
		var d := global_position.distance_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best


## O trilho vai pelo caminho andável até o armazém mais perto (refeito se o armazém mudar).
func _build_rail() -> void:
	if not is_inside_tree():
		return
	var a := armazem()
	if a == null:
		return
	var map := get_world_2d().navigation_map
	var pts := PackedVector2Array([global_position + Vector2(0, 18), a.global_position + Vector2(0, 30)])
	if ferrovia != "":  # Bloco 79: o trilho no chão vai só até a doca (a leste); dali o cavalete sobe
		pts = PackedVector2Array([global_position + Vector2(-6, 18), global_position + Vector2(52, 18)])
	elif rota_fixa:
		var porta := a.global_position + Vector2(0, 30)
		# (a boca é rocha: o trilho começa no batente, no chão da frente — o vagonete espera ali)
		pts = PackedVector2Array([global_position + Vector2(0, -30), Vector2(global_position.x, porta.y), porta])
	elif map.is_valid() and NavigationServer2D.map_get_iteration_id(map) > 0:
		var path := NavigationServer2D.map_get_path(map, pts[0], pts[1], true)
		if path.size() >= 2:
			pts = path
	if rail == null or not is_instance_valid(rail):
		rail = Node2D.new()
		rail.set_script(preload("res://scripts/props/trilho.gd"))
		rail.name = "Trilho_" + String(name)
		get_parent().add_child(rail)
	rail.set_points(pts)
	rail.broken = is_broken()
	_len = rail.length()
	_len_chao = _len
	if ferrovia != "":
		_len += subida()
	cart_d = clampf(cart_d, 0.0, _len)
	_place_cart()


func _make_cart() -> void:
	_cart = Node2D.new()
	_cart.set_script(preload("res://scripts/props/vagonete.gd"))
	_cart.name = "Vagonete_" + String(name)
	_cart.station = self
	get_parent().add_child.call_deferred(_cart)


## Bloco 79: o comprimento da subida pelo cavalete (0 = vagonete comum).
func subida() -> float:
	if ferrovia == "":
		return 0.0
	var n := preload("res://scripts/core/niveis.gd").por_id(ferrovia)
	return SUBIDA_BASE + SUBIDA_POR_ANDAR * float(n.profundidade if n else 3)


## Bloco 79: quanto da subida o carrinho já fez (0..1); -1 = está no chão do andar (no trilho de verdade).
func progresso_subida() -> float:
	if ferrovia == "" or cart_d <= _len_chao:
		return -1.0
	return clampf((cart_d - _len_chao) / maxf(_len - _len_chao, 1.0), 0.0, 1.0)


## Bloco 99: quanto minério está no carrinho agora.
func carga_no_carrinho() -> float:
	var s := 0.0
	for k in cart_load:
		s += float(cart_load[k])
	return s


## Bloco 99: o lampião do poste (a peça "lanterna_boca" da vista iso), do lado da boca.
func _poe_lampiao() -> void:
	if not is_inside_tree() or _lampiao != null:
		return
	_lampiao = Node2D.new()
	_lampiao.name = "LampiaoBoca_" + String(name)
	_lampiao.set_meta("iso_prop", "lanterna_boca")
	_lampiao.position = global_position + Vector2(26, -20)
	_lampiao.visible = false
	get_parent().add_child(_lampiao)


func carrinho_cheio() -> bool:
	return not cart_load.is_empty()


func _place_cart() -> void:
	if _cart == null or rail == null or not is_instance_valid(rail):
		return
	if ferrovia != "":  # Bloco 79: na subida o carrinho é da vista iso (no cavalete), não do chão
		_cart.visible = cart_d <= _len_chao
		if not _cart.visible:
			return
	_cart.global_position = rail.point_at(cart_d)
	_cart.full = not cart_load.is_empty()
	_cart.dir = rail.dir_at(cart_d) * (1.0 if cart_state != "voltando" else -1.0)


# ------------------------------------------------------------ andamento
func _process(delta: float) -> void:
	if tem_interior:  # Bloco 99: quem está dentro da mina
		_produz_dentro(delta)
		if _lampiao:
			_lampiao.visible = not dentro.is_empty()
		if _lanterna:
			_lanterna.enabled = not dentro.is_empty()
			_lanterna.energy = 0.9 + 0.12 * sin(Time.get_ticks_msec() / 180.0) if _lanterna.enabled else 0.0
	# recebe a carga dos mineradores
	for body in _working_bodies():
		if body.get_state() != "storing" or not is_usable():
			continue
		var t: String = body.cargo_type
		var got: float = body.deposit(minf(8.0 * delta, buffer_capacity - buffered()))
		if got > 0.0:
			stock[t] = stock.get(t, 0.0) + got
	if rail == null or not is_instance_valid(rail):
		_update_label()
		return
	if is_broken():
		_update_label()
		return
	match cart_state:
		"esperando":
			_wait_t += delta
			if _parado_area:
				_wait_t = 0.0  # Bloco 77: a mina não está operando: o carrinho não sai
			elif buffered() >= cart_capacity or (buffered() > 0.0 and _wait_t >= cart_wait):
				_load_cart()
				_carga_viagem = 0.0
				for k in cart_load:
					_carga_viagem += float(cart_load[k])
				cart_state = "indo"
				_wait_t = 0.0
		"indo":
			cart_d = minf(cart_d + cart_speed * delta, _len)
			var arm_c := armazem()
			var carga := 0.0
			for k in cart_load:
				carga += float(cart_load[k])
			_sem_espaco = arm_c != null and arm_c.has_method("espaco") and arm_c.espaco() < carga
			if cart_d >= _len and not _sem_espaco:  # Bloco 97: armazém cheio = o carrinho espera carregado
				_unload_cart()
				cart_state = "voltando"
		"voltando":
			cart_d = maxf(cart_d - cart_speed * delta, 0.0)
			if cart_d <= 0.0:
				cart_state = "esperando"
				rail_left -= maxf(_carga_viagem, 1.0) / maxf(desgaste_ref, 1.0)  # Bloco 99: o desgaste é por minério levado
				if is_broken():
					rail.broken = true
					_obra.start()
					var hud := get_tree().get_first_node_in_group("hud")
					if hud:
						hud.show_toast("O trilho do vagonete quebrou — precisa de engenheiro (tecla 4).", Color(1.0, 0.6, 0.4))
	_place_cart()
	if Engine.get_process_frames() % 15 == 0:
		_update_label()


func _load_cart() -> void:
	var left := cart_capacity
	cart_load = {}
	for k in stock.keys():
		var n := minf(stock[k], left)
		if n <= 0.0:
			continue
		cart_load[k] = n
		stock[k] -= n
		left -= n
		if stock[k] <= 0.01:
			stock.erase(k)
		if left <= 0.0:
			break


## Bloco 97: o carrinho chegou e o armazém não tem espaço pra carga.
var _sem_espaco := false


func _unload_cart() -> void:
	var a := armazem()
	for k in cart_load:
		if a:
			a.add_ore(cart_load[k], k)
		total_moved += cart_load[k]
	cart_load = {}
	Audio.deposit(rail.point_at(_len))


func _update_label() -> void:
	if _label == null:
		return
	var st: String = "trilho QUEBRADO — engenheiro" if is_broken() else {"esperando": "esperando carga", "indo": "levando", "voltando": "voltando"}.get(cart_state, cart_state)
	if _sem_espaco and cart_state == "indo":
		st = "ARMAZÉM CHEIO — o carrinho espera"  # Bloco 97
	if _parado_area and cart_state == "esperando" and not is_broken():
		st = "parado — mina: %s" % _motivo_area  # Bloco 77
	var trilho := "  •  trilho %d%%" % roundi(100.0 * clampf(rail_left / maxf(float(rail_trips), 1.0), 0.0, 1.0)) if not is_broken() else ""
	if ferrovia != "":  # Bloco 79
		st = {"indo": "subindo pro armazém", "voltando": "descendo"}.get(cart_state, st)
		_label.text = "Ferrovia de carga (%s)\n%s\ncarga: %d/%d  •  levou: %d" % [ferrovia, st, int(buffered()), int(buffer_capacity), int(total_moved)]
		_label.modulate = Color(1.0, 0.6, 0.4) if is_broken() else Color(0.9, 0.86, 0.8)
		return
	_label.text = "Vagonete\n%s\ncarga: %d/%d  •  levou: %d%s" % [st, int(buffered()), int(buffer_capacity), int(total_moved), trilho]
	if tem_interior and not dentro.is_empty():
		_label.text = "Mina — dentro: %d/%d\n" % [dentro.size(), vagas_dentro] + _label.text
	_label.modulate = Color(1.0, 0.6, 0.4) if is_broken() else Color(0.9, 0.86, 0.8)


# ------------------------------------------------------------ conserto (obra do engenheiro)
func obra_pending() -> bool:
	return is_broken()


func obra_title() -> String:
	return "Consertar o trilho"


func obra_progress() -> float:
	return clampf(1.0 - repair_left / maxf(repair_seconds, 0.1), 0.0, 1.0) if repair_left > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return global_position + Vector2(0, 30) + _obra.offset_for(worker)


func obra_work(seconds: float) -> void:
	if not is_broken():
		return
	if repair_left <= 0.0:
		repair_left = repair_seconds
	repair_left -= seconds
	if repair_left <= 0.0:
		repair_left = 0.0
		rail_left = float(rail_trips)
		rail.broken = false

		Audio.build_done(global_position)


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


# ------------------------------------------------------------ save
func get_save_data() -> Dictionary:
	return {"position": [global_position.x, global_position.y], "ferrovia": ferrovia, "stock": stock.duplicate(), "rail_left": rail_left,
		"repair_left": repair_left, "total": total_moved, "cart_state": cart_state, "cart_d": cart_d, "cart_load": cart_load.duplicate()}


func load_save_data(d: Dictionary) -> void:
	stock = {}
	var s: Dictionary = d.get("stock", {}) if d.get("stock") is Dictionary else {}
	for k in s:
		stock[String(k)] = maxf(float(s[k]), 0.0)
	rail_left = clampf(float(d.get("rail_left", rail_trips)), 0.0, float(rail_trips))  # (Bloco 99: fração; save antigo: inteiro)
	repair_left = maxf(float(d.get("repair_left", 0.0)), 0.0)
	total_moved = maxf(float(d.get("total", 0.0)), 0.0)
	cart_state = String(d.get("cart_state", "esperando")) if String(d.get("cart_state", "")) in ["esperando", "indo", "voltando"] else "esperando"
	cart_d = maxf(float(d.get("cart_d", 0.0)), 0.0)
	cart_load = {}
	var cl: Dictionary = d.get("cart_load", {}) if d.get("cart_load") is Dictionary else {}
	for k in cl:
		cart_load[String(k)] = maxf(float(cl[k]), 0.0)
	if is_broken():
		_obra.start()
	_build_rail.call_deferred()
