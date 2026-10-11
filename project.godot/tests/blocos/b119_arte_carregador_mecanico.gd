extends SceneTree
## Bloco 119: a ARTE PRÓPRIA do carregador e do mecânico (antes o carregador vestia a roupa de "sem função" e o mecânico a do engenheiro: `iso_bonecos.PROVISORIO`).
## Carregador/carregadora e mecânico/mecânica do PixelLab (oficios105.py, a receita do elenco): parado, caminhada de 8 quadros, comer, ferido, deitar, mancar, o trabalho
## (carregar / consertar) e o casaco de inverno; o retrato com as 5 expressões nos 3 tons. RODAR SÓ COM APPDATA ISOLADO.
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
const PASTAS := {"carregador": "carregar", "carregadora": "carregar", "mecanico": "consertar", "mecanica": "consertar"}
const COMUNS := ["parado", "caminhada", "comer", "ferido", "deitar", "mancar_esq"]
var main: Node
var fails := 0


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_roda()


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _roda() -> void:
	await _frames(5)
	var d: Dictionary = IsoBonecos.data()
	print("== (A) as 4 pastas de arte no bonecos.json")
	var funcoes: Dictionary = d.get("funcoes", {})
	check(funcoes.get("carregador", []) == ["carregador", "carregadora", "carregar"], "função 'carregador': carregador / carregadora / carregar")
	check(funcoes.get("mecanico", []) == ["mecanico", "mecanica", "consertar"], "função 'mecanico': mecanico / mecanica / consertar")
	var pastas: Dictionary = d.get("pastas", {})
	for pasta in PASTAS:
		var trabalho: String = PASTAS[pasta]
		check(pastas.has(pasta) and pastas.has("casaco_" + pasta), "%s e o casaco de inverno estão no bonecos.json" % pasta)
		var faltam: Array = []
		for an in COMUNS + [trabalho]:
			for dir in ["SE", "NE", "SO", "NO"]:
				var info = pastas.get(pasta, {}).get("anims", {}).get(an, {}).get(dir)
				if info == null or not ResourceLoader.exists(IsoBonecos.DIR + String(info["img"])):
					faltam.append("%s/%s" % [an, dir])
		check(faltam.is_empty(), "%s: parado, caminhada, comer, ferido, deitar, mancar e %s nas 4 direções%s" % [pasta, trabalho, (" — faltam %s" % str(faltam)) if not faltam.is_empty() else ""])
		var cas_ok := true
		for an in ["caminhada", trabalho]:
			for dir in ["SE", "NE"]:
				var info = pastas.get("casaco_" + pasta, {}).get("anims", {}).get(an, {}).get(dir)
				if info == null or not ResourceLoader.exists(IsoBonecos.DIR + String(info["img"])):
					cas_ok = false
		check(cas_ok, "casaco_%s: caminhada e %s" % [pasta, trabalho])

	print("== (B) o jogo veste a roupa certa (não mais a provisória)")
	var m_ := _gente("menino", "carregador")
	var f_ := _gente("menina", "carregador")
	var mm := _gente("menino", "mecânico")
	var mf := _gente("menina", "mecânico")
	check(m_.outfit() == "carregador" and mm.outfit() == "mecanico", "outfit(): carregador e mecanico")
	check(IsoBonecos.funcao_de(m_) == "carregador" and IsoBonecos.funcao_de(mm) == "mecanico", "funcao_de: a própria arte (não 'civil' nem 'engenheiro')")
	check(IsoBonecos.folders(m_)[0] == "carregador" and IsoBonecos.folders(f_)[0] == "carregadora", "homem usa carregador, mulher usa carregadora")
	check(IsoBonecos.folders(mm)[0] == "mecanico" and IsoBonecos.folders(mf)[0] == "mecanica", "homem usa mecanico, mulher usa mecanica")
	check(IsoBonecos.work_anim(m_) == "carregar" and IsoBonecos.work_anim(mm) == "consertar", "o trabalho: carregar e consertar")
	m_.wearing["casaco"] = true
	mm.wearing["casaco"] = true
	check(IsoBonecos.folders(m_)[0] == "casaco_carregador" and IsoBonecos.folders(mm)[0] == "casaco_mecanico", "no frio, o casaco da função")
	var civil := _gente("menino", "")
	check(IsoBonecos.folders(civil)[0] == "civil" and IsoBonecos.folders(civil)[0] != IsoBonecos.folders(m_)[0], "sem função continua a roupa de civil (diferente do carregador)")

	print("== (C) retratos (5 expressões, 3 tons)")
	for pasta in PASTAS:
		var ok := true
		for expr in ["neutro", "contente", "cansado", "bravo", "ferido"]:
			for tom in ["clara", "parda", "negra"]:
				if not ResourceLoader.exists("res://assets/game/ui/retratos/%s/%s__%s.png" % [pasta, expr, tom]):
					ok = false
		check(ok, "retrato de %s: 5 expressões nos 3 tons" % pasta)
	check(Retratos.pasta(m_) == "carregador" and Retratos.pasta(mf) == "mecanica", "o retrato segue a função e o gênero")
	check(Retratos.de(m_) != null and Retratos.de(mf) != null, "o retrato carrega")

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


## Um ipezinho solto, com o gênero e a função (job vazio = sem função).
func _gente(genero: String, job: String) -> Node:
	var w = load("res://scenes/characters/Ipezinho.tscn").instantiate()
	w.gender = genero
	main.add_child(w)
	if job != "":
		w.job = job
	return w
