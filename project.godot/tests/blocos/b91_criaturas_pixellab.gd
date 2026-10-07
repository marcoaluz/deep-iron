extends SceneTree
## Bloco 91: as criaturas do PixelLab no jogo (Lumívoro, Matriarca dos Lumívoros, Gosma ácida, Magmante e o
## Ferrugento robô) — TESTE DE CARGA das cenas e da arte: cada cena abre com sombra, luz e navegação; a vista iso
## acha os quadros do PixelLab de cada animação (parado, caminhada, atacar, dano, morrer) nas direções;
## a escala fica coerente com o ipezinho; o chefe usa a arte da Matriarca; o Ferrugento usa a folha dele;
## o diário e a defesa conhecem todas; o atalho do F3 chama uma de cada. RODAR SÓ COM APPDATA ISOLADO.
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
const ANIMS := ["parado", "caminhada", "atacar", "dano", "morrer"]
var main: Node
var t := 0.0
var step := 0
var fails := 0


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


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func _process(delta: float) -> bool:
	t += delta
	if t > 200.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		var hub = g("village_hub")
		var world: Node = hub.get_parent()
		var base: Vector2 = Vector2(-600, 330)
		print("== as cenas abrem")
		for kind in ["lumivoro", "gosma", "magmante", "ferrugento"]:
			var cena: PackedScene = load("res://scenes/creatures/%s.tscn" % kind)
			var c = cena.instantiate() if cena else null
			check(c != null and c.kind == kind and c.get_node_or_null("Shadow") is Sprite2D and c.get_node_or_null("Light") is PointLight2D
				and c.get_node_or_null("Agent") is NavigationAgent2D and c.get_node_or_null("Visual") is Sprite2D,
				"%s: cena com sombra, luz, navegação e desenho" % kind)
			if c:
				c.free()
		print("== a arte do PixelLab de cada uma")
		var pastas: Dictionary = IsoBonecos.data().get("pastas", {})
		for pasta in ["criatura_lumivoro", "criatura_lumivoro_matriarca", "criatura_gosma", "criatura_magmante"]:
			var p: Dictionary = pastas.get(pasta, {})
			var anims: Dictionary = p.get("anims", {})
			var falta := []
			for a in ANIMS:
				for d in ["SE", "NE"]:
					if not anims.get(a, {}).has(d):
						falta.append("%s/%s" % [a, d])
			check(not p.is_empty() and falta.is_empty(), "%s: as 5 animações em SE e NE (falta: %s)" % [pasta, falta])
		var w = get_nodes_in_group("ipezinhos")[0]
		w.global_position = base + Vector2(-60, 0)
		var alt_ipe: float = float(IsoBonecos.pose(w, 0, 0.0).get("altura", 40.0))
		var def = g("defense")
		check(def.CENA.has("lumivoro") and def.CENA.has("gosma") and def.CENA.has("magmante") and def.CENA.has("ferrugento"), "a defesa tem a cena de cada uma")
		var bichos := {}
		for kind in ["lumivoro", "gosma", "magmante"]:
			var c = def.CENA[kind].instantiate()
			c.position = base + Vector2(60 * bichos.size(), 0)
			world.add_child(c)
			c.set_process(false)
			bichos[kind] = c
		var chefe = def.CENA["lumivoro"].instantiate()
		chefe.position = base + Vector2(200, 40)
		world.add_child(chefe)
		chefe.set_process(false)
		chefe.make_boss(2.0, 1.5)
		bichos["matriarca"] = chefe
		for nome in bichos:
			var c = bichos[nome]
			var ok := true
			var alturas := []
			for d in 4:
				for mov in [false, true]:
					var pose: Dictionary = IsoBonecos.criatura_pose(c, d, mov, 30.0)
					if pose.is_empty() or pose.tex == null:
						ok = false
					else:
						alturas.append(float(pose.altura))
			var alt: float = alturas.max() if not alturas.is_empty() else 0.0
			check(ok, "%s: a vista iso desenha os quadros do PixelLab (parado e caminhada, 4 direções)" % nome)
			var r := alt / maxf(alt_ipe, 1.0)
			var faixa := [1.1, 3.2] if nome == "matriarca" else [0.45, 2.2]
			check(r >= faixa[0] and r <= faixa[1], "%s: escala coerente com o ipezinho (altura %.0f / %.0f = %.2f)" % [nome, alt, alt_ipe, r])
		var pc: Dictionary = IsoBonecos.criatura_pose(chefe, 0, false)
		check(pc.get("pasta", "") == "criatura_lumivoro_matriarca", "o chefe usa a arte da Matriarca")
		var f = def.CENA["ferrugento"].instantiate()
		world.add_child(f)
		check(f.visual_textura != null and IsoBonecos.criatura_pose(f, 0, false).is_empty(), "o Ferrugento usa a folha de quadros dele (Bloco 80)")
		f.queue_free()
		print("== diário")
		var diary = g("diary")
		check(["lumivoros", "ferrugentos", "gosmas", "magmantes", "matriarca"].all(func(k): return diary.ENTRIES.has(k)), "uma página do diário pra cada")
		for c in bichos.values():
			c.queue_free()
		print("== atalho do F3")
		var dbg: Node = null
		for ch in main.get_children():
			if ch.get_script() and String(ch.get_script().resource_path).ends_with("debug_panel.gd"):
				dbg = ch
		if dbg == null:
			print("  (sem painel de debug neste build: atalho não conferido)")
		else:
			dbg._todas_criaturas()
			var kinds := {}
			for c in get_nodes_in_group("criaturas"):
				kinds[c.kind + ("_chefe" if c.get("variant") == "chefe" else "")] = true
			print("  na invasão: ", kinds.keys())
			check(def.invasion_active and kinds.has("gosma") and kinds.has("magmante") and kinds.has("ferrugento") and kinds.has("lumivoro_chefe"),
				"F3 'invasão com todos os tipos': uma de cada, com a Matriarca")
		step = 99
	if step == 99:
		print("\nFALHAS: %d" % fails)
		return true
	return false
