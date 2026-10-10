extends SceneTree
## Bloco 108 (não é teste): MEDE as Políticas da Vila numa partida nova de verdade, com 10 ipezinhos trabalhando
## (1 cozinheiro, 2 caçadores, 3 mineradores, 2 lenhadores, 1 engenheiro, 1 guarda). Por dia imprime: minério e madeira que
## entraram, a comida SERVIDA (o que saiu do comedouro) e a que sobrou no prato, a fome e o ânimo médios, as refeições
## perdidas, os acidentes, a greve e o resultado da invasão.
##   <Godot>.exe --headless --path . -s res://tests/bench_politicas.gd -- [jornada=estendida] [racao=reduzida]
##        [seguranca=vigilancia] [migracao=fechada] [dias=4] [inverno=1] [semente=7]      (APPDATA isolado)
##        [pop=4] (só os 4 primeiros ofícios) [base=45] (ânimo de partida de todos: uma vila já triste — o teste da greve)
##        [sem_cozinha=1] (sem cozinheiro e a cozinha vazia: a falta de comida)
## Sem o nó Politicas (o jogo de antes do Bloco 108) mede a referência.
const ACELERA := 8.0
var main: Node
var t := 0.0
var fase := 0
var dias := 4
var dia_ant := 0
var args := {}
var _comida_ant := -1.0
var _servida := 0.0
var _servida_total := 0.0
var _madeira_ant := -1.0
var _madeira := 0.0
var _minerio_ant := 0.0
var _acidentes := 0
var _acidentes_total := 0
var _fome_soma := 0.0
var _animo_soma := 0.0
var _amostras := 0
var _greve_s := 0.0
var _resumo: Array = []
var _migrantes := 0
var _cred_ini := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	preload("res://scripts/core/catalogo.gd").tudo_estudado = true
	load("res://scripts/core/defense.gd").moradores_desligados = true
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	for a in OS.get_cmdline_user_args():
		var kv := String(a).split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	dias = int(args.get("dias", "4"))
	seed(int(args.get("semente", "7")))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(n: String) -> Node:
	return get_first_node_in_group(n)


func _comida() -> float:
	var s := 0.0
	for c in get_nodes_in_group("comedouros"):
		s += float(c.food_stock)
	return s


func _minerio() -> float:
	var s := 0.0
	for a in get_nodes_in_group("armazens"):
		s += float(a.lifetime_stored)
	return s


func _madeira_agora() -> float:
	var s := 0.0
	for a in get_nodes_in_group("armazens"):
		s += float(a.wood_stored)
	return s


func _perdidas() -> int:
	var n := 0
	for w in get_nodes_in_group("ipezinhos"):
		n += int(w.refeicoes_perdidas)
	return n


func _linha(rotulo: String) -> void:
	var ws := get_nodes_in_group("ipezinhos")
	var n := maxf(_amostras, 1)
	var defe = g("defense")
	var res: Dictionary = defe.last_result if defe and defe.get("last_result") != null else {}
	var minerio := _minerio() - _minerio_ant
	_minerio_ant = _minerio()
	var l := "%s | minério %4.0f | madeira %4.0f | comida servida %5.1f | fome média %5.1f | ânimo médio %5.1f | perdidas %d | acidentes %d | greve %.0f s | onda %s | %d ipezinhos" % [
		rotulo, minerio, _madeira, _servida, _fome_soma / n, _animo_soma / n, _perdidas(), _acidentes, _greve_s,
		str(res) if not res.is_empty() else "-", ws.size()]
	print(l)
	_resumo.append([minerio, _madeira, _servida, _fome_soma / n, _animo_soma / n, _acidentes])
	_servida = 0.0
	_madeira = 0.0
	_acidentes = 0
	_fome_soma = 0.0
	_animo_soma = 0.0
	_amostras = 0


func _process(delta: float) -> bool:
	t += delta
	var dn = g("day_night")
	if fase == 0 and t > 3.0:
		fase = 1
		var eco = g("economy")
		eco.max_workers = 99
		var pop := int(args.get("pop", "10"))
		while get_nodes_in_group("ipezinhos").size() < pop:
			if eco.recruit_free() == null:
				break
		var jobs := ["cozinheiro", "caçador", "caçador", "minerador", "minerador", "minerador", "lenhador", "lenhador", "engenheiro", "guarda"]
		var ws := get_nodes_in_group("ipezinhos")
		if args.get("sem_cozinha", "") == "1":
			jobs[0] = "minerador"
			for c in get_nodes_in_group("comedouros"):
				c.food_stock = 0.0
		while ws.size() > pop:
			var sobra: Node = ws.pop_back()
			sobra.queue_free()
		for i in ws.size():
			ws[i].set_job(jobs[i] if i < jobs.size() else "ocioso")
			if args.has("base"):
				ws[i].happiness_base = float(args.base)
				ws[i].happiness = float(args.base) + 10.0
			ws[i].injured_changed.connect(func(on: bool):
				if on:
					_acidentes += 1
					_acidentes_total += 1)
		if args.get("inverno", "") == "1":
			var sun = g("sun")
			var inv: Array[float] = [1.25, 1.25, 1.25, 1.25]
			sun.season_hunger_mult = inv  # só a fome do inverno (o resto da estação não muda)
		var pol = g("politicas")
		for p in ["jornada", "racao", "seguranca", "migracao"]:
			if args.has(p):
				if pol == null:
					print("AVISO: sem o nó Politicas (jogo de antes do Bloco 108): '%s' ignorado" % p)
				else:
					pol.forca(p, String(args[p]))
		print("POLÍTICAS: %s | %d ipezinhos | porção %.1f" % [pol.resumo() if pol else "(referência: sem políticas)", ws.size(), g("schedule").porcao])
		var migr = g("migrantes")
		migr.chegaram.connect(func(n: int): _migrantes += n)
		_cred_ini = float(eco.credits)
		dia_ant = dn.day
		_minerio_ant = _minerio()
		Engine.time_scale = ACELERA
		return false
	if fase == 1:
		var c := _comida()
		if _comida_ant >= 0.0 and c < _comida_ant:
			_servida += _comida_ant - c
			_servida_total += _comida_ant - c
		_comida_ant = c
		var m := _madeira_agora()
		if _madeira_ant >= 0.0 and m > _madeira_ant:
			_madeira += m - _madeira_ant
		_madeira_ant = m
		var ws := get_nodes_in_group("ipezinhos")
		if not ws.is_empty() and Engine.get_process_frames() % 10 == 0:
			var f := 0.0
			var a := 0.0
			for w in ws:
				f += float(w.hunger)
				a += float(w.happiness)
			_fome_soma += f / ws.size()
			_animo_soma += a / ws.size()
			_amostras += 1
		if g("morale").on_strike:
			_greve_s += delta
		if dn.day != dia_ant:
			dia_ant = dn.day
			_linha("dia %d" % (dn.day - 1))
			if dn.day > dias:
				var tot := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
				for r in _resumo:
					for i in 6:
						tot[i] += float(r[i])
				var k := maxf(_resumo.size(), 1)
				var pol = g("politicas")
				print("RESUMO (média/dia) | minério %.0f | madeira %.0f | comida servida %.1f | fome %.1f | ânimo %.1f | acidentes %.2f | greve %.0f s | migrantes chegaram %d | créditos %+d | fraqueza %s | expulso %s" % [
					tot[0] / k, tot[1] / k, tot[2] / k, tot[3] / k, tot[4] / k, tot[5] / k, _greve_s, _migrantes,
					int(float(g("economy").credits) - _cred_ini), str(pol.fraqueza_ativa()) if pol else "-", str(g("morale").is_expelled)])
				Engine.time_scale = 1.0
				return true
	if Time.get_ticks_msec() > 1200000:
		print("TIMEOUT")
		return true
	return false
