extends SceneTree
## Bloco 96 (não é teste): MEDE o tempo das obras (s de jogo, da encomenda ao pronto) com as obras com material
## DESLIGADAS (como antes do bloco) e LIGADAS, com 1 e com 2 engenheiros. Imprime uma tabela pro relatório.
##   <Godot>.exe --headless --path . -s res://tests/bench_obras.gd -- <com|sem> <engenheiros>     (APPDATA isolado)
## Cada modo numa partida nova e igual (as obras ficam nos mesmos lugares: a caminhada é a mesma nas duas).
const ObraSite := preload("res://scripts/core/obra_site.gd")
## [nome, como encomendar]
const OBRAS := ["taverna", "parque", "casa", "trilhas"]
const ACELERA := 8.0
var main: Node
var t := 0.0
var relogio := 0.0
var fila: Array = []  # [obra, material?, engenheiros]
var atual: Array = []
var inicio := 0.0
var alvo: Node = null
var resultados: Array = []
var esperando := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	var args := OS.get_cmdline_user_args()
	var com: bool = args.size() < 1 or args[0] == "com"
	var n_eng: int = int(args[1]) if args.size() > 1 else 1
	for o in OBRAS:
		fila.append([o, com, n_eng])


func g(n: String) -> Node:
	return get_first_node_in_group(n)


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 600, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


func _abastece() -> void:
	var eco = g("economy")
	var arm = g("armazens")
	eco.credits = 99999.0
	for k in ["ferro", "cobre", "carvao"]:
		arm.stock[k] = 2000.0
	arm._recount()
	arm.wood_stored = 2000.0


func _encomenda(o: String) -> Node:
	var hub = g("village_hub")
	hub.upgrades["moradias"] = 0  # (a mesma 1ª casa e as mesmas 1ªs trilhas em toda medida)
	hub.upgrades["trilhas"] = 0
	var pos := spot_near(hub.global_position + Vector2(160, 120))
	match o:
		"taverna":
			g("morale")._confirm_taverna(pos)
			for c in get_nodes_in_group("canteiros"):
				if c.kind == "taverna":
					return c
		"parque":
			g("morale")._confirm_park(pos)
			for c in get_nodes_in_group("canteiros"):
				if c.kind == "parque":
					return c
		"casa":
			var antes := get_nodes_in_group("casas").size()
			hub._confirm_house(pos)
			var cs := get_nodes_in_group("casas")
			return cs[cs.size() - 1] if cs.size() > antes else null
		"trilhas":
			hub.buy_upgrade("trilhas")
			return hub if hub.obra_pending() else null
	return null


func _process(delta: float) -> bool:
	t += delta
	relogio += delta
	if t < 3.0:
		return false
	if t > 4000.0:
		print("TEMPO ESGOTADO")
		_imprime()
		return true
	if not esperando:
		if fila.is_empty():
			_imprime()
			Engine.time_scale = 1.0
			return true
		atual = fila.pop_front()
		g("economy").obras_com_material = atual[1]
		_abastece()
		var ws := get_nodes_in_group("ipezinhos")
		for i in ws.size():
			ws[i].set_job("engenheiro" if i < atual[2] else "ocioso")
			ws[i].hunger = ws[i].hunger_max
		var dn = g("day_night")
		dn.time = dn.tempo_da_hora(7.0)  # de manhã: a agenda deixa trabalhar
		alvo = _encomenda(atual[0])
		if alvo == null:
			resultados.append([atual[0], atual[1], atual[2], -1.0, 0.0])
			return false
		inicio = relogio
		esperando = true
		Engine.time_scale = ACELERA
		return false
	var dn2 = g("day_night")
	if dn2.hora() > 16.0:
		dn2.time = dn2.tempo_da_hora(7.0)  # (não deixa a agenda mandar pra casa no meio da medida)
	var acabou: bool = alvo == null or not is_instance_valid(alvo) or not alvo.obra_pending()
	if acabou or relogio - inicio > 900.0:
		var site = ObraSite.de(alvo) if alvo and is_instance_valid(alvo) else null
		resultados.append([atual[0], atual[1], atual[2], relogio - inicio if acabou else -1.0, site.total_necessario() if site else 0.0])
		esperando = false
		Engine.time_scale = 1.0
	return false


func _imprime() -> void:
	for r in resultados:
		print("BENCH|%s|%s|%d|%.1f|%d" % [r[0], "com" if r[1] else "sem", r[2], r[3], int(r[4])])
