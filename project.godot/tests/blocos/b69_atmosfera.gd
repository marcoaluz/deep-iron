extends SceneTree
## Bloco 69: camadas de desenho e atmosfera por nível (docs/arte/CAMADAS.md). A atmosfera de cada
## nível vem do .tres (tom da laje, névoa, partículas), fica na camada 4 (acima de toda fixa e de quem
## anda), luzes pulsando nas zonas de perigo, intensidade e "reduzir efeitos" nas Configurações,
## decoração por dados nas lajes de baixo, e nada se duplica no save/load. RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
const Niveis := preload("res://scripts/core/niveis.gd")
const Settings := preload("res://scripts/core/settings.gd")
const Efeitos := preload("res://scripts/core/efeitos.gd")
const IsoFx := preload("res://scripts/iso/iso_fx.gd")
const Order := preload("res://scripts/iso/iso_order.gd")
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var _energias := []
var _n_deco := 0
var _n_atmos := 0


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


func g(grupo: String) -> Node:
	return current_scene.get_tree().get_first_node_in_group(grupo)


func iso() -> Node:
	return current_scene.get_node("IsoView")


func _process(delta: float) -> bool:
	t += delta
	if current_scene != null and current_scene != main:
		main = current_scene
	if t > 90.0:
		print("TIMEOUT no passo %d\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 4.0:
				_camadas()
				_atmosfera_dos_dados()
				_decoracao()
				_energias = _luzes()
				step = 1
				t_mark = t
		1:
			if t - t_mark > 1.0:
				_pulso()
				_configuracoes()
				root.get_node("SaveManager").save_game("teste")
				step = 2
				t_mark = t
		2:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 3
				t_mark = t
		3:
			if t - t_mark > 4.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _camadas() -> void:
	print("== camadas (docs/arte/CAMADAS.md)")
	var v := iso()
	check(v._atmos.size() == 5, "atmosfera de S1 a S5 (%d)" % v._atmos.size())
	_n_atmos = v._atmos.size()
	var ids := []
	var ok_z := true
	for a in v._atmos:
		ids.append(a.nivel.id)
		ok_z = ok_z and a.raiz.z_index == 3700 and not a.raiz.z_as_relative
	ids.sort()
	check(ids == ["S1", "S2", "S3", "S4", "S5"], "um nó por nível jogável (%s)" % str(ids))
	check(ok_z, "atmosfera na camada 4 (z 3700 absoluto)")
	var fixas: int = (v._order as Order).order.size()
	var topo_fixa: int = Order.BASE + fixas * Order.K
	check(topo_fixa < 3700, "toda fixa e quem anda ficam embaixo da atmosfera (%d fixas: z até %d)" % [fixas, topo_fixa])
	check(v.BACK_Z.moldura < Order.BASE and v.BACK_Z.fundo < Order.BASE, "camada 0 (moldura e fundo) embaixo do terreno")


func _atmosfera_dos_dados() -> void:
	print("== atmosfera por nível (data/niveis)")
	var v := iso()
	for a in v._atmos:
		var n: Resource = a.nivel
		check(a.nevoa.color.is_equal_approx(n.cor_nevoa), "%s: névoa = cor_nevoa do .tres" % n.id)
		if n.particulas != "":
			var tex: Texture2D = IsoFx.tex(v.PARTICULA_TEX[n.particulas])
			check(a.part != null and a.part.texture == tex and a.part.emitting, "%s: partículas '%s' ligadas" % [n.id, n.particulas])
	for lv in v._levels:
		var area: String = v.AREA_DO_ANDAR.get(lv.nome, lv.nome)
		var n: Resource = v._nivel_da_area(area)
		check(n != null and lv.sprite.self_modulate.is_equal_approx(n.cor_ambiente), "laje %s com a luz ambiente do %s" % [lv.nome, n.id if n else "?"])
	# mudar o .tres muda o tom (o recurso é o mesmo que o jogo lê)
	var s2 := Niveis.por_id("S2")
	var antes: Color = s2.cor_ambiente
	s2.cor_ambiente = Color(0.5, 0.2, 0.9)
	check(v._tom_do_andar("nivel2").is_equal_approx(Color(0.5, 0.2, 0.9)), "tom do andar segue o recurso")
	s2.cor_ambiente = antes
	check(Niveis.por_id("S2").particulas == "acido" and Niveis.por_id("S3").particulas == "calor", "S2 ácido, S3 calor")


func _decoracao() -> void:
	print("== decoração por dados")
	var env = g("environment")
	var decos: Array = main.get_tree().get_nodes_in_group("nivel_deco")
	_n_deco = decos.size()
	var declarados := 0
	for n in Niveis.jogaveis():
		declarados += n.decoracao.size()
		for e in n.decoracao:
			if not decos.any(func(d): return Vector2(e[1], e[2]).distance_to(d.global_position) < 1.0):
				print("    %s: %s em (%d, %d) não coube" % [n.id, e[0], e[1], e[2]])
	check(decos.size() == declarados, "%d de %d props declarados no lugar" % [decos.size(), declarados])
	var por_nivel := {}
	var ok_dados := true
	for d in decos:
		var nv = Niveis.do_ponto(env, d.global_position)
		var id: String = nv.id if nv else "?"
		por_nivel[id] = por_nivel.get(id, 0) + 1
		var achou := false
		for e in nv.decoracao if nv else []:
			var nome := String(d.get_meta("iso_prop", "")) if d.has_meta("iso_prop") else "fx:" + String(d.get_meta("iso_fx", ""))
			if String(e[0]) == nome and Vector2(e[1], e[2]).distance_to(d.global_position) < 1.0:
				achou = true
		ok_dados = ok_dados and achou
	check(ok_dados, "cada prop = uma linha do .tres do nível dele")
	check(por_nivel.get("S2", 0) >= 4 and por_nivel.get("S3", 0) >= 4, "cristais no S2 (%d) e no S3 (%d)" % [por_nivel.get("S2", 0), por_nivel.get("S3", 0)])
	var com_arte := 0
	for d in decos:
		var bb = iso().billboard_of(d)
		if bb != null:
			com_arte += 1
	check(com_arte == decos.size(), "todos aparecem na vista iso (%d/%d)" % [com_arte, decos.size()])


func _luzes() -> Array:
	print("== luzes das zonas de perigo")
	var v := iso()
	var kinds := {}
	for zn in main.get_tree().get_nodes_in_group("zonas_perigo"):
		kinds[String(zn.get("kind"))] = true
	print("    zonas: %s, luzes pulsando: %d" % [str(kinds.keys()), v._luzes_zona.size()])
	check(not v._luzes_zona.is_empty(), "há luz pulsando nas zonas de perigo")
	var ok := true
	for e in v._luzes_zona:
		var l: PointLight2D = e[0]
		ok = ok and l.is_in_group("cullable_lights") and l.range_item_cull_mask == v.LIGHT_ISO
	check(ok, "luzes no orçamento (cullable_lights, máscara LIGHT_ISO)")
	return v._luzes_zona.map(func(e): return e[0].energy)


func _pulso() -> void:
	var v := iso()
	var mudou := false
	for i in v._luzes_zona.size():
		if absf(v._luzes_zona[i][0].energy - _energias[i]) > 0.001:
			mudou = true
	check(mudou, "as luzes pulsam")


func _configuracoes() -> void:
	print("== configurações (intensidade e reduzir efeitos)")
	var v := iso()
	var tree := main.get_tree()
	var a0: Dictionary = v._atmos[0]
	for a in v._atmos:
		if a.part != null:
			a0 = a
			break
	Settings.set_value("video", "atmosfera", 0.5)
	tree.call_group("efeitos", "efeitos_mudaram")
	check(is_equal_approx(a0.nevoa.color.a, a0.alfa * 0.5), "50%%: névoa pela metade (%.3f)" % a0.nevoa.color.a)
	check(a0.part.amount <= maxi(int(a0.qtd * 0.5), 1), "50%%: metade das partículas (%d de %d)" % [a0.part.amount, a0.qtd])
	Settings.set_value("video", "atmosfera", 0.0)
	tree.call_group("efeitos", "efeitos_mudaram")
	var todos_escondidos := true
	for a in v._atmos:
		todos_escondidos = todos_escondidos and not a.raiz.visible
	check(todos_escondidos and is_equal_approx(v._pulso_k, 0.0), "0%: atmosfera desligada, sem pulso")
	Settings.set_value("video", "atmosfera", 1.0)
	Efeitos.set_reduzidos(true, tree)
	check(a0.raiz.visible and not a0.part.emitting and is_equal_approx(a0.nevoa.color.a, a0.alfa * 0.5), "reduzir efeitos: sem partículas, névoa mais leve")
	check(v._pulso_k < 0.5, "reduzir efeitos: pulso mais fraco")
	Efeitos.set_reduzidos(false, tree)
	check(a0.part.emitting and is_equal_approx(a0.nevoa.color.a, a0.alfa), "volta ao normal")


func _carregado() -> void:
	print("== depois de carregar")
	var v := iso()
	check(v._atmos.size() == _n_atmos, "atmosfera sem duplicar (%d)" % v._atmos.size())
	check(main.get_tree().get_nodes_in_group("nivel_deco").size() == _n_deco, "decoração sem duplicar (%d)" % main.get_tree().get_nodes_in_group("nivel_deco").size())
	var n := 0
	for c in v._things.get_children():
		if String(c.name).begins_with("Atmosfera_"):
			n += 1
	check(n == _n_atmos, "um nó de atmosfera por nível na cena (%d)" % n)
