extends SceneTree
## Bloco 95 (não é teste): compara uma FONTE candidata no mesmo cartão do CONSTRUIR e na lista de força de
## trabalho, já na escala nova (nada abaixo de 12, título do cartão 15) e com a sombra fina. Sem fonte = a de
## hoje. Uma fonte por execução (o tema entra antes da cena abrir). Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_fontes95.gd -- <pasta de saída> <nome> [fonte.ttf]
const PATH := "user://savegame.json"
const ABA_PRODUCAO := 7
const TELAS := ["lista", "cartao"]
var main: Node
var out_dir := ""
var nome := "atual"
var t := 0.0
var cur := -1
var t_mark := 0.0
var sombra := false


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_fontes95")
	DirAccess.make_dir_recursive_absolute(out_dir)
	nome = args[1] if args.size() > 1 else "atual"
	if args.size() > 2:  # o tema da raiz não chega no CanvasLayer do HUD: troca a fonte de reserva global
		var f := FontFile.new()
		f.load_dynamic_font(args[2])
		f.fallbacks = [ThemeDB.fallback_font]
		if "Pixel" in args[2]:  # fonte pixel: nítida, como as do jogo (ui_skin.fonte)
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		ThemeDB.fallback_font = f
		ThemeDB.get_default_theme().default_font = f  # o tema padrão tem a fonte dele antes da reserva
		sombra = true
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func node(g: String) -> Node:
	return main.get_tree().get_first_node_in_group(g)


func _process(delta: float) -> bool:
	t += delta
	if t > 90.0:
		print("TIMEOUT")
		return true
	if cur < 0:
		if t > 4.0:
			node("day_night").time_scale = 0.0
			node("economy").credits = 600.0
			_next()
		return false
	if t - t_mark > 1.2:
		root.get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [nome, TELAS[cur]]))
		print("foto: ", nome, " ", TELAS[cur])
		if cur + 1 >= TELAS.size():
			return true
		_next()
	return false


## A escala proposta: nada abaixo de 12; o nome do cartão em 15.
func _escala_nova(n: Node) -> void:
	if n is Label and sombra:
		n.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))  # a sombra fina da proposta
		n.add_theme_constant_override("shadow_offset_x", 1)
		n.add_theme_constant_override("shadow_offset_y", 1)
	if n is Label or n is Button:
		var s: int = n.get_theme_font_size("font_size")
		if s <= 11:
			n.add_theme_font_size_override("font_size", 12)
		elif s == 14:
			n.add_theme_font_size_override("font_size", 15)
	for c in n.get_children():
		_escala_nova(c)


func _next() -> void:
	cur += 1
	if TELAS[cur] == "cartao":
		for c in node("hud").get_children():
			if c.get_script() != null and String(c.get_script().resource_path).ends_with("build_menu.gd"):
				c.toggle()
				c._show_tab(ABA_PRODUCAO)
	_escala_nova(node("hud"))
	t_mark = t
