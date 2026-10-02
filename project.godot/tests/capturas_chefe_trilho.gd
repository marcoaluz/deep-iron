extends SceneTree
## Blocos 62 e 64 (não é teste): fotos da Matriarca (chefe) no meio de Lumívoros e do trilho com o
## vagonete e o ponto de carga, na vista iso. Roda COM JANELA e APPDATA isolado:
##   <Godot>.exe --path . -s res://tests/capturas_chefe_trilho.gd -- <pasta de saída>
const PATH := "user://savegame.json"
var main: Node
var out_dir := ""
var t := 0.0
var step := 0
var est: Node
var chefe: Node


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("user://capturas_chefe")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main


func g(grupo: String) -> Node:
	return main.get_tree().get_first_node_in_group(grupo)


func _mira(alvo: Vector2, parada: int) -> void:
	var cam = main.get_node("Camera2D")
	var stops: Array = cam.zoom_stops()
	var z: float = stops[clampi(parada, 0, stops.size() - 1)]
	cam.zoom = Vector2(z, z)
	cam.set_target_zoom(z)
	cam.on_view_changed(alvo)


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		return true
	match step:
		0:
			if t > 4.0:
				var hub = g("village_hub")
				var arm = g("armazens")
				var lugar := Vector2.ZERO
				for j in main.get_tree().get_nodes_in_group("minerios"):
					if j.is_unlocked() and not j.is_sealed() and j.global_position.distance_to(arm.global_position) > 300.0:
						lugar = j.global_position + Vector2(70, 50)
						break
				est = hub.spawn_vagonete(lugar)
				step = 1
		1:
			if t > 6.0 and est.rail != null:
				est.stock["ferro"] = 40.0
				est.cart_d = est._len * 0.12
				est.cart_speed = 0.0
				est.cart_state = "indo"
				est._load_cart()
				_mira(est.global_position, 3)
				step = 2
		2:
			if t > 8.0:
				root.get_texture().get_image().save_png(out_dir.path_join("trilho.png"))
				var vg: Array = main.get_tree().get_nodes_in_group("vagonetes")
				var iso = g("iso_view")
				if not vg.is_empty():
					var bb = iso._ents.get(vg[0])
					print("bb: ", bb != null, " vis ", bb.visible if bb else "-", " pos ", bb.position if bb else "-", " filhos ", bb.get_child_count() if bb else 0, " pares ", bb._pairs.size() if bb else 0, " dyn ", bb.dynamic if bb else "-", " z ", bb.z_index if bb else "-")
					if bb:
						var ap: Vector2 = iso.art(vg[0].global_position)
						print("   caixa ", bb.box.rect, " zb ", bb.box.zb, " zt ", bb.box.zt, " art ", ap)
						for tt in iso._terrain:
							if (tt[0].rect as Rect2).grow(10).has_point(ap):
								print("   terreno ", tt[0].kind, " ", tt[0].name, " rect ", tt[0].rect, " zb ", tt[0].zb, " zt ", tt[0].zt, " z ", tt[1].z_index)
						for pr in bb._pairs:
							print("   par ", pr[0].name, " -> ", pr[1], " tex ", pr[1].get("texture"), " scale ", pr[1].get("scale"), " vis ", pr[1].visible, " gpos ", pr[1].global_position, " offset ", pr[1].offset, " centered ", pr[1].centered, " gscale ", pr[1].global_scale, " mod ", pr[1].modulate, " selfmod ", pr[1].self_modulate, " vis_tree ", pr[1].is_visible_in_tree(), " layer ", pr[1].visibility_layer)
						print("   TELA do vagonete: ", iso.get_viewport().get_canvas_transform() * bb.global_position, " estação na tela: ", iso.get_viewport().get_canvas_transform() * iso._ents[est].global_position, " cart_d ", est.cart_d, "/", est._len, " estado ", est.cart_state)
						print("   bb gscale ", bb.global_scale, " mod ", bb.modulate, " cam centro canvas ", iso.get_viewport().get_canvas_transform().affine_inverse() * (Vector2(1280, 720) * 0.5))
				print("vagonetes: ", vg.size(), " pos ", vg[0].global_position if not vg.is_empty() else "-", " trilho ", est.rail.point_at(est.cart_d), " visivel ", vg[0].visible if not vg.is_empty() else "-", " tex ", vg[0]._sprite.texture if not vg.is_empty() else "-")
				var d = g("defense")
				var c: Node2D = d._spawn("lumivoro")
				c.make_boss(d.boss_hp_mult, d.boss_damage_mult)
				c.global_position = g("village_hub").global_position + Vector2(60, 80)
				c.inside = true
				c._gate = null
				chefe = c
				for i in 2:
					var l: Node2D = d._spawn("lumivoro")
					l.global_position = c.global_position + Vector2(-50 + i * 100, 30)
					l.inside = true
					l._gate = null
				_mira(c.global_position + Vector2(-40, -40), 3)
				step = 3
		3:
			if t > 10.5:
				root.get_texture().get_image().save_png(out_dir.path_join("matriarca.png"))
				print("fotos em ", out_dir)
				return true
	return false
