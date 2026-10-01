extends SceneTree
## Prompt 29, parte 1: o mapa novo (terraços, escadas, paliçada, céu). Alturas, navegação
## (penhasco bloqueia, escada e portão passam), construir só em chão plano, migração do que cai
## em lugar inválido (save antigo), ordem com as caixas do terreno, céu por hora.
## RODAR SÓ COM APPDATA ISOLADO.
const Iso := preload("res://scripts/iso/iso_core.gd")
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var fails := 0
var t_mark := 0.0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func env() -> Node:
	return main.get_node("World/Environment")


## Caminho da navegação entre dois pontos.
func path(a: Vector2, b: Vector2) -> PackedVector2Array:
	var map: RID = main.get_world_2d().navigation_map
	return NavigationServer2D.map_get_path(map, a, b, true)


func length(p: PackedVector2Array) -> float:
	var l := 0.0
	for i in range(1, p.size()):
		l += p[i - 1].distance_to(p[i])
	return l


## O caminho passa por algum tile de escada?
func uses_stairs(p: PackedVector2Array) -> bool:
	var e := env()
	for i in range(1, p.size()):
		for k in 20:
			if e.is_stair_tile(e.tile_at(p[i - 1].lerp(p[i], k / 20.0))):
				return true
	return false


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 150.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	if step == 0 and t > 3.0:
		step = 1
		var e := env()
		var iso = main.get_node("IsoView")
		print("== mapa novo carregado")
		check(e.has_iso_map(), "mapa.json do terreno novo carregado")
		check(iso.enabled and is_equal_approx(iso.S, 1.5), "vista iso ligada por padrão, escala 1,5")
		print("== alturas (px de arte, 32 por degrau)")
		check(e.height_at(Vector2(-300, -300)) == 96.0, "terraço de cima (Centro): 96")
		check(e.height_at(Vector2(-300, 0)) == 64.0, "terraço do meio: 64")
		check(e.height_at(Vector2(300, 300)) == 0.0, "fundo da pedreira: 0")
		check(e.height_at(Vector2(0, -800)) == 96.0, "floresta: 96 (mesmo nível do terraço de cima)")
		# a escada de 3 lances (alto -> fundo, x 640): desce do norte pro sul
		var st: Array = []
		for y in range(-190, -110, 4):
			var p := Vector2(646, y)
			if e.is_stair_tile(e.tile_at(p)):
				st.append(e.height_at(p))
		var desce := st.size() > 4
		for i in range(1, st.size()):
			desce = desce and st[i] <= st[i - 1]
		check(desce and st.front() > st.back(), "escada: a altura desce em rampa (%d amostras, %.0f -> %.0f)" % [st.size(), st.front() if st.size() else 0.0, st.back() if st.size() else 0.0])
		print("== navegação")
		var down := Vector2(300, 250)
		var up := Vector2(300, -260)
		var pa := path(down, up)
		check(pa.size() > 1 and pa[-1].distance_to(up) < 12.0, "do fundo dá pra chegar no terraço de cima")
		check(uses_stairs(pa), "o caminho passa por uma escada")
		check(length(pa) > down.distance_to(up) * 1.3, "não atravessa o penhasco (caminho %.0f, reta %.0f)" % [length(pa), down.distance_to(up)])
		var forest := Vector2(400, -800)
		var village := Vector2(400, -300)
		var pf := path(forest, village)
		var through_gate := false
		for i in range(1, pf.size()):
			var a2 := pf[i - 1]
			var b2 := pf[i]
			if (a2.y - e.palisade_y) * (b2.y - e.palisade_y) <= 0.0:
				var x := lerpf(a2.x, b2.x, (e.palisade_y - a2.y) / (b2.y - a2.y) if b2.y != a2.y else 0.0)
				through_gate = absf(x) < e.gate_half_width
		check(pf.size() > 1 and pf[-1].distance_to(village) < 12.0 and through_gate, "da floresta pra vila: só pelo portão")
		print("== construir só em chão plano")
		var hb := Rect2(Vector2(-30, -30), Vector2(60, 60))
		check(e.footprint_reason(Rect2(Vector2(-330, -330), hb.size)) == "", "terraço de cima: pode")
		check("penhasco" in e.footprint_reason(Rect2(Vector2(-330, -200), Vector2(60, 60))), "na beira do penhasco: não")
		check("escada" in e.footprint_reason(Rect2(Vector2(630, -175), Vector2(30, 30))), "em cima da escada: não")
		check("paliçada" in e.footprint_reason(Rect2(Vector2(200, -480), Vector2(60, 40))), "em cima da paliçada: não")
		print("== ordem com as caixas do terreno")
		iso._process(0.0)  # caixas e z do mesmo instante (quem anda muda entre quadros)
		var bad := 0
		var pairs := 0
		var all: Array = []
		for bb in iso._ents.values():
			if bb.visible_src():
				all.append([bb.box, bb.z_index])
		for tr in iso._terrain:
			all.append([tr[0], tr[1].z_index])
		for i in all.size():
			for j in range(i + 1, all.size()):
				var a3 = all[i]
				var b3 = all[j]
				if not Iso.screen_rect(a3[0]).intersects(Iso.screen_rect(b3[0])):
					continue
				var r = Iso.behind(a3[0], b3[0])
				if r == null:
					continue
				pairs += 1
				if a3[1] == b3[1] and a3[0].kind == "ipezinho" and b3[0].kind == "ipezinho":
					continue
				if (r == true and a3[1] >= b3[1]) or (r == false and b3[1] >= a3[1]):
					bad += 1
		check(bad == 0, "%d pares que se sobrepõem (com os terraços), %d na ordem errada" % [pairs, bad])
		print("== andares de baixo empilhados (formato em camadas)")
		var surf_low: float = iso.to_screen(Vector2(755, 432)).y  # canto da frente da superfície
		for pt in [Vector2(-100, 1000), Vector2(200, 1700)]:
			var scr: Vector2 = iso.to_screen(pt)
			var hp: Dictionary = iso.pick(scr)
			check(hp.ground.distance_to(pt) < 2.0, "clique no chão do andar em %s volta pro ponto certo (%s)" % [pt, hp.ground.round()])
			check(scr.y > surf_low, "o andar fica embaixo da superfície na tela")
		check(e.height_at(Vector2(200, 1700)) < e.height_at(Vector2(-100, 1000)), "o abismo fica abaixo do nível 2")
		print("== céu por hora")
		var sky = iso._sky
		check(sky != null and sky._sky_layer.visible, "céu ligado")
		var day: Array = sky.colors_now()
		var dn = main.get_node("DayNight")
		dn.time = dn.day_duration + 5.0  # noite
		dn.snap_lighting()
		var night: Array = sky.colors_now()
		check(night[0].get_luminance() < day[0].get_luminance() * 0.5, "à noite o céu escurece")
		check(main.get_node("Ambient").color.get_luminance() < 0.5, "à noite o ambiente escurece (céu aberto)")
		dn.time = 10.0
		dn.snap_lighting()
		check(main.get_node("Ambient").color.get_luminance() > 0.9, "de dia o ambiente é claro (céu aberto, não caverna)")
		print("== migração: save com coisa em lugar inválido")
		var sm = root.get_node("SaveManager")
		sm.save_game("teste")
		var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		var ws: Array = data.workers
		ws[0].position = [-735, 0]     # dentro do paredão (degrau 4, ninguém chega)
		ws[1].position = [300, -462]   # em cima da paliçada (fora do portão)
		ws[2].position = [646, -170]   # na escada: boneco ANDA em escada, não muda de lugar
		var f := FileAccess.open(PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(data))
		f.close()
		set_meta("names", [ws[0].name, ws[1].name, ws[2].name])
		sm.load_game()
		t_mark = t
		step = 2
	elif step == 2 and t > t_mark + 3.0:
		step = 3
		var e := env()
		var names: Array = get_meta("names")
		var moved: Array = e.migrated.map(func(m): return m.nome)
		print("  migrados: %s" % [e.migrated])
		check(names[0] in moved and names[1] in moved, "os 2 ipezinhos em lugar impossível foram mudados de lugar (e anotados)")
		check(not (names[2] in moved), "o da escada ficou onde estava")
		var ok_all := true
		for ip in main.get_tree().get_nodes_in_group("ipezinhos"):
			if String(ip.name) in names.slice(0, 2):
				ok_all = ok_all and e.spot_ok(ip.global_position, 4.0)
		check(ok_all, "agora estão em chão válido")
		print("FALHAS: %d" % fails)
		return true
	return false
