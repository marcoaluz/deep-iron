extends SceneTree
## Bloco 110 (não é teste): MEDE os relacionamentos numa partida nova de verdade com 12 ipezinhos trabalhando (a hora social
## e o trabalho de sempre). Por dia: amizades, casais, casamentos, o ânimo médio, a habilidade média e o tempo real do dia.
##   <Godot>.exe --headless --path . -s res://tests/bench_relacoes.gd -- [dias=5] [semente=7]      (APPDATA isolado)
const ACELERA := 8.0
var main: Node
var t := 0.0
var fase := 0
var dias := 5
var dia_ant := 0
var args := {}
var _t_dia := 0
var _animo := 0.0
var _n := 0


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
	dias = int(args.get("dias", "5"))
	seed(int(args.get("semente", "7")))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(n: String) -> Node:
	return get_first_node_in_group(n)


func _linha(rotulo: String) -> void:
	var rel = g("relacoes")
	var c: Dictionary = rel.contagem() if rel else {}
	var hab := 0.0
	var ws := get_nodes_in_group("ipezinhos")
	for w in ws:
		for k in w.habilidade:
			hab = maxf(hab, float(w.habilidade[k]))
	var niveis := [0, 0, 0, 0, 0, 0]
	if rel:
		for i in ws.size():
			for j in range(i + 1, ws.size()):
				niveis[rel.nivel(ws[i], ws[j])] += 1
	print("%s | %d s reais | amizades %d | casais %d | casamentos %d | pares por nível (conh/amigo/próx/interesse/casal) %s | ânimo %.1f | maior habilidade %.0f%% | %d ipezinhos" % [
		rotulo, (Time.get_ticks_msec() - _t_dia) / 1000, int(c.get("amizades", 0)), int(c.get("casais", 0)), int(c.get("casamentos", 0)),
		str(niveis.slice(1)), _animo / maxf(_n, 1), hab * 100.0, ws.size()])
	var fat := {}
	for w in ws:
		for f in w.happiness_factors():
			if float(f[1]) < 0.0:
				fat[f[0]] = snappedf(float(fat.get(f[0], 0.0)) + float(f[1]) / ws.size(), 0.1)
	print("      ânimo pra baixo (média): %s | estação %s" % [str(fat), g("sun").season_name()])
	_t_dia = Time.get_ticks_msec()
	_animo = 0.0
	_n = 0


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
		var jobs := ["engenheiro", "minerador", "minerador", "caçador", "caçador", "lenhador", "lenhador", "cozinheiro", "minerador",
			"lenhador", "guarda", "minerador"]
		var ws := get_nodes_in_group("ipezinhos")
		for i in ws.size():
			ws[i].set_job(jobs[i] if i < jobs.size() else "ocioso")
		var nunca: Array[float] = [0.0, 0.0, 0.0, 0.0]
		g("sun").season_wave_chance = nunca
		g("defense").first_invasion_day = 999
		dia_ant = dn.day
		_t_dia = Time.get_ticks_msec()
		Engine.time_scale = ACELERA
		return false
	if fase == 1:
		if Engine.get_process_frames() % 20 == 0:
			var s := 0.0
			var ws := get_nodes_in_group("ipezinhos")
			for w in ws:
				s += float(w.happiness)
			_animo += s / maxf(ws.size(), 1)
			_n += 1
		if dn.day != dia_ant:
			dia_ant = dn.day
			_linha("dia %d" % (dn.day - 1))
			if dn.day > dias:
				Engine.time_scale = 1.0
				return true
	if Time.get_ticks_msec() > 1200000:
		print("TIMEOUT")
		return true
	return false
