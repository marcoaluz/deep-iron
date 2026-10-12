extends SceneTree
## Bloco 132: QUANTOS PRÉDIOS CABEM NA VILA (não é teste: é medição). RODAR SÓ COM APPDATA ISOLADO.
##   godot --headless --path project.godot -s res://tests/medir_area_vila.gd -- <arquivo de saída>
## Partida nova (a vila do main.tscn: Centro, casas, cozinha, armazém, oficina, enfermaria...). Pra cada tamanho de prédio,
## varre a vila (da paliçada até a pedreira) em ordem e põe o prédio em todo lugar que o POSICIONADOR aceita (house_placer:
## as mesmas regras do jogo), contando cada um posto como obstáculo pros próximos. Mede as regras que estão no código:
## rodado antes do Bloco 132 dá o ANTES; depois, o DEPOIS.
var main: Node
var linhas: PackedStringArray = []
var out_file := ""
const IsoArt := preload("res://scripts/iso/iso_art.gd")
const CELULA := 64.0 / 3.0  # (a grade do Bloco 132: grade.gd)
## os tamanhos medidos: [nome, kind da arte]
const TAMANHOS := [["pequeno (carvoaria)", "carvoaria"], ["casa", "casa"], ["médio (armazém)", "armazem"], ["grande (taverna)", "taverna"],
	["alto (igreja)", "igreja"]]
## onde varrer: da paliçada até a pedreira (as jazidas começam em x ~ 620) e a ÁREA DA VILA do Bloco 132 no estágio 1 e no 5
## (os retângulos do environment.area_vila com o Centro da partida nova; fixos aqui pra medir o antes no mesmo lugar)
const REGIOES := [["vila toda (paliçada até a pedreira)", Rect2(-300, -1040, 920, 1480)],
	["área da vila, estágio 1", Rect2(-220, -450, 520, 520)], ["área da vila, estágio 5", Rect2(-292, -690, 832, 1000)]]


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_file = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://medir_area_vila.txt")
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_roda()


func _linha(t: String) -> void:
	linhas.append(t)
	print(t)


func _textura(kind: String) -> Texture2D:
	for base in IsoArt.KIND_OF_SCENE:
		if IsoArt.KIND_OF_SCENE[base] == kind and ResourceLoader.exists("res://assets/game/%s.png" % base):
			return load("res://assets/game/%s.png" % base)
	return null


func _roda() -> void:
	for i in 8:
		await process_frame
	var hp := get_first_node_in_group("house_placer")
	var novo: bool = hp.has_method("ocupa_simulado")
	_linha("Bloco 132: quantos prédios cabem na vila — regras %s (%s)" % ["NOVAS (grade)" if novo else "ANTIGAS (pixel livre, folgas)", Time.get_datetime_string_from_system()])
	_linha("cada tamanho medido sozinho, com a vila da partida nova; conta só o que cabe INTEIRO na região")
	var env := get_first_node_in_group("environment")
	if env.has_method("area_vila"):
		for e in 5:
			_linha("  área da vila no estágio %d: %s" % [e + 1, str(env.area_vila(e + 1))])
	for reg in REGIOES:
		_linha("")
		_linha("%s: %s" % [reg[0], str(reg[1])])
		for t in TAMANHOS:
			var kind: String = t[1]
			var tex := _textura(kind)
			if tex == null:
				_linha("  %-22s sem textura" % t[0])
				continue
			var fp := IsoArt.footprint_of(self, kind)
			var n := await _conta(hp, tex, kind, novo, reg[1])
			_linha("  %-22s base %3dx%3d px: cabem %3d" % [t[0], int(fp.size.x), int(fp.size.y), n])
	var f := FileAccess.open(out_file, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(linhas) + "\n")
		f.close()
	print("gravado: ", out_file)
	quit()


func _conta(hp: Node, tex: Texture2D, kind: String, novo: bool, regiao: Rect2) -> int:
	hp.begin(func(_p): return true, tex, 1, kind, {})
	var passo: float = CELULA if novo else 8.0
	var n := 0
	var y := regiao.position.y
	while y < regiao.end.y:
		var x := regiao.position.x
		while x < regiao.end.x:
			hp.move_to(Vector2(x, y))
			if hp._reason == "" and regiao.encloses(Rect2(hp._pos + hp._footprint.position, hp._footprint.size)):
				n += 1
				if novo:
					hp.ocupa_simulado(hp._pos)
				else:  # como o posicionador antigo enxerga um prédio pronto: a base + 6 px (+ a faixa da frente nas estações)
					var base := IsoArt.footprint_of(self, kind)
					var r := Rect2(hp._pos + base.position, base.size)
					if kind != "casa":
						r = r.grow(IsoArt.FRONT_GAP + 2.0)
					hp._blockers.append({"rect": r.grow(6.0), "name": "simulado"})
			x += passo
		y += passo
		if int(y) % 160 == 0:
			await process_frame
	hp._end(false)
	return n
