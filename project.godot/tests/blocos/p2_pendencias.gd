extends SceneTree
## Pendências dos Prompts 2 e 29 (feitas junto do Prompt 26): caçador sem arco COLHENDO fruta,
## guarda TREINANDO no campo e o ATAQUE com a arma dele (lança / lança de prata / besta) em vez do
## porrete. RODAR SÓ COM APPDATA ISOLADO.
const B := preload("res://scripts/iso/iso_bonecos.gd")
const PATH := "user://savegame.json"
var main: Node
var t := 0.0
var fails := 0
var feito := false


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


func _process(delta: float) -> bool:
	t += delta
	if t > 60.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if not feito and t > 3.0:
		feito = true
		_testa()
		print("FALHAS: %d" % fails)
		return true
	return false


func _limpo(w) -> void:
	w.auto_mode = false
	w.velocity = Vector2.ZERO
	w.injured = false
	w.downed = false
	w._resting = false
	w._inside = false
	w.carrying = 0.0
	w.wood_carrying = 0.0
	w.food_carrying = 0.0
	w.raw_carrying = 0.0


func _testa() -> void:
	print("== arte exportada")
	var p: Dictionary = B.data().get("pastas", {})
	for par in [["cacador", "colher"], ["cacadora", "colher"], ["guarda", "treinar"], ["guarda_mulher", "treinar"],
			["guarda", "atacar_lanca"], ["guarda", "atacar_besta"], ["guarda_mulher", "atacar_lanca"], ["guarda_mulher", "atacar_besta"]]:
		var a: Dictionary = p.get(par[0], {}).get("anims", {}).get(par[1], {})
		check(a.has("SE") and a.has("NE") and a.has("SO") and a.has("NO"), "%s: %s nas 4 direções" % par)
	print("== pelo estado")
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	_limpo(w)
	w.gender = "menino"
	w.set_job("caçador")
	w._ai_state = "foraging"
	w._work_timer = 0.3
	check(B.pose(w, 0, 0.0).get("anim") == "colher", "caçador colhendo fruta: colher")
	w.set_job("guarda")
	_limpo(w)
	w._ai_state = "training"
	w._work_timer = 0.3
	check(B.pose(w, 0, 0.0).get("anim") == "treinar", "guarda no campo: treinar")
	w._ai_state = "guard"
	for arma in [["porrete", "atacar"], ["lanca", "atacar_lanca"], ["lanca_prata", "atacar_lanca"], ["besta", "atacar_besta"]]:
		w.weapon = arma[0]
		w._work_timer = 0.3
		check(B.pose(w, 0, 0.0).get("anim") == arma[1], "atacando com %s: %s" % arma)
