extends SceneTree
## Prompt 17: os INVASORES com a arte nova (iso_bonecos.criatura_pose + bonecos.json).
## Lumívoro e Ferrugento (e as formas fortes: bruto e carregador) com parado, andar, atacar,
## levar golpe, cair (fica deitado e só depois some) e desligar ao amanhecer; o Ferrugento que
## roubou leva a carga na caçamba; a Defesa manda a forma forte nas ondas altas (1 a cada 3).
## RODAR SÓ COM APPDATA ISOLADO.
const B := preload("res://scripts/iso/iso_bonecos.gd")
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var step := 0
var fails := 0
var lumi: Node2D
var ferr: Node2D


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


func iso() -> Node:
	return main.get_node("IsoView")


func _process(delta: float) -> bool:
	t += delta
	if t > 90.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		step = 1
		_dados()
		_nasce()
		t = 3.0
	elif step == 1 and t > 3.5:
		step = 2
		_estados()
		_no_jogo()
		lumi.die(true)
		lumi.set_process(true)  # caindo: só o relógio da animação anda
		t = 3.5
	elif step == 2 and t > 4.6:
		step = 3
		check(is_instance_valid(lumi) and B.criatura_pose(lumi, 0, false).get("anim") == "morrer", "caiu: continua no chão um pouco (animação de queda, não some na hora)")
		var p := B.criatura_pose(lumi, 0, false)
		check(p.get("frame", -1) == p.get("n", 0) - 1, "caído: parado no último quadro")
		t = 4.6
	elif step == 3 and t > 7.5:
		check(not is_instance_valid(lumi), "depois de cair, some (2 s)")
		_defesa()
		print("FALHAS: %d" % fails)
		return true
	return false


func _dados() -> void:
	print("== arte exportada")
	var d: Dictionary = B.data()
	for pasta in ["criatura_lumivoro", "criatura_lumivoro_bruto", "criatura_ferrugento", "criatura_ferrugento_carregador"]:
		var anims: Dictionary = d.get("pastas", {}).get(pasta, {}).get("anims", {})
		var ok := true
		for an in ["parado", "caminhada", "atacar", "dano", "morrer"]:
			for dd in ["SE", "NE", "SO", "NO"]:
				if not anims.get(an, {}).has(dd):
					ok = false
		check(ok, "%s: 5 animações x 4 direções" % pasta)
	check(d.has("carga_ferrugento"), "carga do Ferrugento (minério na caçamba)")


func _nasce() -> void:
	var world := main.get_node("World")
	lumi = load("res://scenes/creatures/lumivoro.tscn").instantiate()
	lumi.position = Vector2(60, 120)
	world.add_child(lumi)
	lumi.setup(null, 1.0)
	ferr = load("res://scenes/creatures/ferrugento.tscn").instantiate()
	ferr.position = Vector2(-60, 120)
	world.add_child(ferr)
	ferr.setup(null, 1.0)
	for c in [lumi, ferr]:
		c.set_process(false)  # parados: o teste manda no estado


func _estados() -> void:
	print("== animação pelo estado")
	check(B.criatura_pose(lumi, 0, false).get("anim") == "parado", "parado")
	var p := B.criatura_pose(lumi, 0, true)
	check(p.get("anim") == "caminhada" and p.get("pasta") == "criatura_lumivoro", "andando: caminhada do Lumívoro")
	check(B.criatura_pose(lumi, 3, true).get("dir") == "NE", "direção de losango (NE)")
	lumi._attack_at = lumi._anim
	check(B.criatura_pose(lumi, 0, false).get("anim") == "atacar", "atacando")
	lumi._attack_at = -100.0
	var hp0: float = lumi.hp
	lumi.take_hit(1.0, null)
	check(B.criatura_pose(lumi, 0, false).get("anim") == "dano" and lumi.hp < hp0, "levou golpe: dano")
	lumi._hit_at = -100.0
	print("== forma forte")
	var max0: float = lumi.max_hp
	lumi.make_strong(1.6, 1.3)
	check(lumi.variant == "forte" and is_equal_approx(lumi.max_hp, max0 * 1.6), "forte: mais vida (x1.6)")
	check(B.criatura_pose(lumi, 0, false).get("pasta") == "criatura_lumivoro_bruto", "forte: desenho do bruto")
	ferr.make_strong(1.6, 1.3)
	check(B.criatura_pose(ferr, 0, false).get("pasta") == "criatura_ferrugento_carregador", "Ferrugento forte: carregador")
	ferr.variant = ""
	print("== roubo")
	check(not B.criatura_pose(ferr, 0, false).has("item"), "caçamba vazia antes de roubar")
	ferr.looted = true
	var pf := B.criatura_pose(ferr, 0, true)
	check(pf.has("item") and pf.item.front, "roubou: minério na caçamba")
	ferr._leaving = true
	ferr._left_at = ferr._anim
	check(B.criatura_pose(ferr, 0, false).get("anim") == "morrer", "amanhecer: o Ferrugento desliga (cai)")
	ferr._leaving = false


func _no_jogo() -> void:
	print("== na vista iso")
	var bb = iso().billboard_of(lumi)
	check(bb != null, "a criatura tem espelho na vista iso")
	if bb == null:
		return
	bb.never_synced = true
	bb.sync_dynamic()
	check(bb._char != null and bb._char.visible and bb._c_body.texture != null, "desenho novo no lugar")
	var velho_some := true
	for pr in bb._pairs:
		if is_instance_valid(pr[0]) and pr[0].name == "Visual" and pr[1].visible:
			velho_some = false
	check(velho_some, "o desenho antigo some")


func _defesa() -> void:
	print("== Defesa: forma forte nas ondas altas")
	var def := main.get_tree().get_first_node_in_group("defense")
	def.wave = def.strong_from_wave
	def._spawned = 0
	var antes := main.get_tree().get_nodes_in_group("criaturas").size()
	for i in 3:
		def._spawn("lumivoro")
	var novos := main.get_tree().get_nodes_in_group("criaturas").slice(antes)
	var fortes := novos.filter(func(c): return c.variant == "forte").size()
	check(novos.size() == 3 and fortes == 1, "onda %d: 1 forte a cada 3 (%d de %d)" % [def.wave, fortes, novos.size()])
	def.wave = 1
	def._spawned = 0
	var antes2 := main.get_tree().get_nodes_in_group("criaturas").size()
	for i in 3:
		def._spawn("lumivoro")
	var novos2 := main.get_tree().get_nodes_in_group("criaturas").slice(antes2)
	check(novos2.all(func(c): return c.variant == ""), "onda 1: nenhuma forte")
	for c in main.get_tree().get_nodes_in_group("criaturas"):
		c.queue_free()
