extends SceneTree
## Bloco 109 (não é teste): MEDE a IA dos ipezinhos numa partida nova de verdade com 12 (2 engenheiros, ferreiro, fundidor,
## 2 mineradores, 2 lenhadores, cozinheiro, 2 caçadores e guarda). Força uma ONDA SOLAR no dia 2 às 10:00 (aviso curto: sem o
## estudo) e deixa a invasão do dia 3. Por dia imprime: os OCIOSOS (média de quem tem função e está parado no expediente),
## minério e madeira, os machucados por causa e as mortes ("bobas" = quem não é guarda morto por criatura ou radiação).
##   <Godot>.exe --headless --path . -s res://tests/bench_ia.gd -- [dias=4] [semente=7] [sem_secundaria=1]   (APPDATA isolado)
const ACELERA := 8.0
const BOBAS := ["radiacao", "lumivoro", "ferrugento", "gosma", "magmante"]
var main: Node
var t := 0.0
var fase := 0
var dias := 4
var dia_ant := 0
var args := {}
var _ociosos_soma := 0.0
var _amostras := 0
var _minerio_ant := 0.0
var _madeira_ant := -1.0
var _madeira := 0.0
var _feridos := {}
var _mortes := 0
var _bobas := 0
var _onda_feita := false
var _resumo: Array = []
var _onda_viu := false
var _t_dia := 0
var _proc_soma := 0.0
var _fis_soma := 0.0
var _quadros := 0
var _trocas := 0
var _sec_ant := {}
var _expostos_max := 0


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


func _liga(w: Node) -> void:
	w.injured_changed.connect(func(on: bool):
		if on:
			var c := String(w.injury_cause)
			_feridos[c] = int(_feridos.get(c, 0)) + 1)
	w.died.connect(func(_n):
		_mortes += 1
		if not w.is_guard() and String(w.injury_cause) in BOBAS:
			_bobas += 1)


func _linha(rotulo: String) -> void:
	var minerio := _minerio() - _minerio_ant
	_minerio_ant = _minerio()
	var oc := _ociosos_soma / maxf(_amostras, 1)
	var real_s := (Time.get_ticks_msec() - _t_dia) / 1000.0
	_t_dia = Time.get_ticks_msec()
	print("   desempenho: %.0f s reais no dia | processo %.2f ms/quadro | física %.2f ms/quadro | %d quadros | trocas da secundária %d" % [
		real_s, _proc_soma / maxf(_quadros, 1) * 1000.0, _fis_soma / maxf(_quadros, 1) * 1000.0, _quadros, _trocas])
	_proc_soma = 0.0
	_fis_soma = 0.0
	_quadros = 0
	_trocas = 0
	print("%s | ociosos no expediente %.2f | minério %4.0f | madeira %4.0f | machucados %s | mortes %d (bobas %d) | %d ipezinhos" % [
		rotulo, oc, minerio, _madeira, str(_feridos), _mortes, _bobas, get_nodes_in_group("ipezinhos").size()])
	_resumo.append([oc, minerio, _madeira])
	_ociosos_soma = 0.0
	_amostras = 0
	_madeira = 0.0


func _process(delta: float) -> bool:
	t += delta
	var dn = g("day_night")
	if fase == 0 and t > 3.0:
		fase = 1
		var eco = g("economy")
		eco.max_workers = 99
		while get_nodes_in_group("ipezinhos").size() < 12:
			if eco.recruit_free() == null:
				break
		var jobs := ["engenheiro", "engenheiro", "ferreiro", "fundidor", "minerador", "minerador", "caçador", "lenhador", "lenhador",
			"cozinheiro", "caçador", "guarda"]  # (2 caçadores: com 1 a vila passa fome e a medição vira de fome, não de IA)
		var ws := get_nodes_in_group("ipezinhos")
		for i in ws.size():
			ws[i].set_job(jobs[i] if i < jobs.size() else "ocioso")
			_liga(ws[i])
			if args.get("sem_secundaria", "") == "1" and ws[i].get("funcao_secundaria") != null:
				ws[i].funcao_secundaria = "nenhuma"
		var sun = g("sun")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		sun.season_wave_chance = nunca  # (só a onda forçada)
		print("IA: %d ipezinhos, camas livres %d, secundária %s" % [ws.size(), eco.free_beds(), "desligada" if args.get("sem_secundaria", "") == "1" else ("padrão" if ws[0].get("funcao_secundaria") != null else "(não existe: código de antes)")])
		dia_ant = dn.day
		_minerio_ant = _minerio()
		_t_dia = Time.get_ticks_msec()
		Engine.time_scale = ACELERA
		return false
	if fase == 1:
		var sun = g("sun")
		if not _onda_feita and dn.day == 2 and dn.hora() >= 6.0:
			_onda_feita = true
			sun.wave_today = true
			sun.warned = false
			sun.wave_at = dn.tempo_da_hora(10.0)
			sun.wave_intensity = 1.5
		if sun.wave_active():
			var env = g("environment")
			var fora := get_nodes_in_group("ipezinhos").filter(func(w): return not w.get("_inside") and not w.injured and env.level_at(w.global_position) == 0).size()
			_expostos_max = maxi(_expostos_max, fora)
			if not _onda_viu:
				_onda_viu = true
				print("  ONDA SOLAR começou às %s: %d na superfície fora de abrigo" % [dn.hora_texto(), fora])
		elif _onda_viu and _expostos_max >= 0:
			print("  ONDA SOLAR acabou: no máximo %d expostos ao mesmo tempo" % _expostos_max)
			_expostos_max = -1
		var m := _madeira_agora()
		if _madeira_ant >= 0.0 and m > _madeira_ant:
			_madeira += m - _madeira_ant
		_madeira_ant = m
		if Engine.get_process_frames() % 1500 == 0 and dn.day >= int(args.get("rastro_dia", "99")):
			var est := {}
			for w in get_nodes_in_group("ipezinhos"):
				est[w.get_state()] = int(est.get(w.get_state(), 0)) + 1
			var fat := {}
			var hs := 0.0
			for w in get_nodes_in_group("ipezinhos"):
				hs += float(w.happiness)
				for f in w.happiness_factors():
					fat[f[0]] = snappedf(float(fat.get(f[0], 0.0)) + float(f[1]) / get_nodes_in_group("ipezinhos").size(), 0.1)
			print("   [ânimo] média %.1f fatores %s" % [hs / maxf(get_nodes_in_group("ipezinhos").size(), 1), str(fat)])
			var coz = g("comedouros")
			var quem := {}
			for w in get_nodes_in_group("ipezinhos"):
				if w.job in ["cozinheiro", "caçador"]:
					quem[w.job + ":" + w.get_state()] = int(quem.get(w.job + ":" + w.get_state(), 0)) + 1
			for w in get_nodes_in_group("ipezinhos"):
				if w.job in ["caçador", "cozinheiro"] and w.get_state() == "eating":
					print("   [preso] %s fome %.0f prato %.1f servido %s movendo %s dist_coz %.0f estação %s inside %s abrigo %s" % [w.job, w.hunger, float(w._prato),
						str(w._servido), str(w._moving), w.global_position.distance_to(coz.global_position), str(w._station), str(w._inside),
						str(w.get("_abrigado_em"))])
			print("   [comida] pronta %.0f | estoque da cozinha %.0f | crua no armazém %.0f | %s | cheios %s" % [coz.food_stock, coz.raw_local,
				g("economy").quantidade("comida_crua"), str(quem), str(g("economy").categorias_cheias())])
			print("   [rastro] dia %d %s pausado=%s escala=%.1f criaturas=%d invasao=%s estados=%s" % [dn.day, dn.hora_texto(), str(paused), Engine.time_scale,
				get_nodes_in_group("criaturas").size(), str(g("defense").invasion_active), str(est)])
		_proc_soma += Performance.get_monitor(Performance.TIME_PROCESS)
		_fis_soma += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		_quadros += 1
		for w in get_nodes_in_group("ipezinhos"):
			if w.has_method("na_secundaria"):
				var ns: bool = w.na_secundaria()
				if _sec_ant.get(w, ns) != ns:
					_trocas += 1
				_sec_ant[w] = ns
		var sch = g("schedule")
		if Engine.get_process_frames() % 10 == 0:
			var n := 0
			var conta := false
			for w in get_nodes_in_group("ipezinhos"):
				if w.job == "ocioso" or w.is_doctor():
					continue
				if sch.periodo(w) != "trabalho":
					continue
				conta = true
				if w.get_state() in ["idle", "esperando_espaco"]:
					n += 1
			if conta:
				_ociosos_soma += n
				_amostras += 1
		if dn.day != dia_ant:
			dia_ant = dn.day
			_linha("dia %d" % (dn.day - 1))
			if dn.day > dias:
				var tot := [0.0, 0.0, 0.0]
				for r in _resumo:
					for i in 3:
						tot[i] += float(r[i])
				var k := maxf(_resumo.size(), 1)
				print("RESUMO (média/dia) | ociosos %.2f | minério %.0f | madeira %.0f | machucados %s | mortes %d | bobas %d" % [
					tot[0] / k, tot[1] / k, tot[2] / k, str(_feridos), _mortes, _bobas])
				Engine.time_scale = 1.0
				return true
	if Time.get_ticks_msec() > 1200000:
		print("TIMEOUT")
		return true
	return false
