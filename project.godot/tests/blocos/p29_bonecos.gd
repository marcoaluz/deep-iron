extends SceneTree
## Prompt 29, parte 3: os BONECOS com a arte nova (iso_bonecos.gd + bonecos.json).
## Pasta por função × gênero (casaco no frio, traje de perigo), animação pelo estado (parado,
## andando, mancando, trabalho, comendo, ferido, deitado, dentro de casa), direção de losango,
## pele por paleta (pelo look), saco e ferramenta nas costas (atrás de frente, na frente de
## costas); no jogo o corpo antigo some e o boneco novo aparece. RODAR SÓ COM APPDATA ISOLADO.
const B := preload("res://scripts/iso/iso_bonecos.gd")
const PATH := "user://savegame.json"
const JOBS := {"ocioso": "civil", "minerador": "minerador", "cozinheiro": "cozinheiro", "lenhador": "lenhador",
	"guarda": "guarda", "pesquisador": "pesquisador", "caçador": "cacador", "médico": "medico", "engenheiro": "engenheiro"}
## direções da vista: SE, SW, NW, NE
const SE := 0
const SW := 1
const NW := 2
const NE := 3
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


## Deixa o ipezinho num estado limpo (parado, sem carga, sem machucado, sem roupa extra).
func reset(w) -> void:
	w.auto_mode = false
	w._moving = false
	w.velocity = Vector2.ZERO
	w.injured = false
	w.downed = false
	w._resting = false
	w._inside = false
	w._work_timer = 0.0
	w.carrying = 0.0
	w.wood_carrying = 0.0
	w.food_carrying = 0.0
	w.raw_carrying = 0.0
	w.wearing = {}


func _process(delta: float) -> bool:
	t += delta
	if t > 120.0:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	if step == 0 and t > 3.0:
		step = 1
		_estados()
		t = 3.0
	elif step == 1 and t > 3.6:
		_no_jogo()
		print("FALHAS: %d" % fails)
		return true
	return false


func _estados() -> void:
	var w = main.get_tree().get_nodes_in_group("ipezinhos")[0]
	print("== arte exportada")
	var d: Dictionary = B.data()
	check(d.get("pastas", {}).size() >= 42, "bonecos.json com o elenco, casacos e trajes (%d pastas)" % d.get("pastas", {}).size())
	var bad := 0
	var strips := 0
	for p in d.pastas:
		for a in d.pastas[p].anims:
			for dr in d.pastas[p].anims[a]:
				var i: Dictionary = d.pastas[p].anims[a][dr]
				var tex: Texture2D = load(B.DIR + i.img)
				strips += 1
				if tex == null or tex.get_width() != int(i.quadro[0]) * int(i.n) or i.topo.size() != int(i.n):
					bad += 1
	check(bad == 0, "%d tiras, todas com n quadros do tamanho declarado e o topo de cada quadro" % strips)
	print("== pasta por função × gênero")
	var wrong := []
	for job in JOBS:
		for g in ["menino", "menina"]:
			reset(w)
			w.gender = g
			w.set_job(job)
			var pair: Array = d.funcoes[JOBS[job]]
			var want: String = pair[1] if g == "menina" else pair[0]
			var p: Dictionary = B.pose(w, SE, 0.0)
			if p.get("pasta", "") != want:
				wrong.append("%s/%s -> %s" % [job, g, p.get("pasta", "")])
	check(wrong.is_empty(), "9 funções × 2 gêneros na pasta certa %s" % [wrong])
	reset(w)
	w.gender = "menino"
	w.set_job("minerador")
	print("== animação pelo estado")
	var p := B.pose(w, SE, 0.0)
	check(p.anim == "parado" and p.n == 1, "parado: a pose da rotação")
	check(p.has("item") and not p.item.front, "parado de frente (SE): picareta nas costas, ATRÁS do corpo")
	p = B.pose(w, NE, 0.0)
	check(p.has("item") and p.item.front, "de costas (NE): picareta na FRENTE")
	check(B.pose(w, SW, 0.0).item.flip != B.pose(w, SE, 0.0).item.flip, "SO = SE espelhado (a ferramenta vira junto)")
	w.velocity = Vector2(60, 0)
	w._anim_time = 2.0
	p = B.pose(w, SE, 0.0)
	check(p.anim == "com_picareta" and p.frame == 2 and not p.has("item"), "andando sem carga: caminhada com a picareta já desenhada (quadro pelo passo: %d)" % p.frame)
	w.carrying = 5.0
	p = B.pose(w, SE, 0.0)
	check(p.anim == "caminhada" and p.has("saco") and not p.saco.front, "carregando de frente: caminhada + saco ATRÁS")
	p = B.pose(w, NO_dir(), 0.0)
	check(p.has("saco") and p.saco.front, "carregando de costas: saco na FRENTE")
	var s0: Vector2 = B.pose(w, SE, 0.0).saco.pos
	w._anim_time = 1.0
	var s1: Vector2 = B.pose(w, SE, 0.0).saco.pos
	check(s0 != s1, "saco acompanha a cabeça no passo (%s -> %s)" % [s0, s1])
	w.carrying = 0.0
	w.injured = true
	p = B.pose(w, SE, 0.0)
	check(p.anim == "mancar_esq", "machucado andando: manca")
	w.velocity = Vector2.ZERO
	p = B.pose(w, SE, 0.0)
	check(p.anim == "ferido" and p.frame == p.n - 1, "machucado parado: senta com a tala (último quadro)")
	w.downed = true
	p = B.pose(w, SE, 0.0)
	check(p.anim == "deitar" and p.frame == p.n - 1 and not p.has("item"), "caído: deitado, sem ferramenta")
	reset(w)
	w._resting = true
	check(B.pose(w, SE, 0.0).anim == "deitar", "dormindo ao relento: deitado")
	w._inside = true
	check(B.pose(w, SE, 0.0).get("hidden") == true, "dentro de casa: some")
	reset(w)
	w._work_timer = 1.0
	check(B.pose(w, SE, 0.0).anim == "minerar", "minerando: animação de minerar")
	var works := {}
	for job in ["guarda", "médico", "engenheiro", "caçador", "pesquisador", "lenhador", "cozinheiro"]:
		w.set_job(job)
		reset(w)
		w._work_timer = 1.0
		works[job] = B.pose(w, SE, 0.0).anim
	check(works.values() == ["atacar", "atender", "construir", "cacar", "pesquisar", "cortar", "cozinhar"], "trabalho de cada função %s" % [works])
	w.set_job("ocioso")
	reset(w)
	w._ai_state = "eating"
	check(B.pose(w, SE, 0.0).anim == "comer", "comendo")
	print("== casaco, traje, pele")
	w.set_job("lenhador")
	reset(w)
	w.wearing = {"casaco": 1.0}
	w.velocity = Vector2(60, 0)
	check(B.pose(w, SE, 0.0).pasta == "casaco_lenhador", "no frio com casaco: o casaco do lenhador andando")
	w.velocity = Vector2.ZERO
	check(B.pose(w, SE, 0.0).pasta == "lenhador", "parado com casaco (sem pose de casaco): volta pro lenhador")
	w.set_job("minerador")
	reset(w)
	w.gender = "menina"
	w.wearing = {"gas": 1.0}
	w._work_timer = 1.0
	check(B.pose(w, SE, 0.0).pasta == "traje_gas_f", "traje de gás minerando: traje_gas_f")
	reset(w)
	w.look = 0
	var t0: Texture2D = B.pose(w, SE, 0.0).tex
	w.look = 1
	var t1: Texture2D = B.pose(w, SE, 0.0).tex
	w.look = 3
	var t3: Texture2D = B.pose(w, SE, 0.0).tex
	check(t0 != t1 and t0 == t3, "pele por paleta: look 0 e 1 em tons diferentes, look 3 = look 0 (3 tons)")


func NO_dir() -> int:
	return NW


func _no_jogo() -> void:
	print("== no jogo")
	var iso = main.get_node("IsoView")
	var ok := 0
	var all := main.get_tree().get_nodes_in_group("ipezinhos")
	for w in all:
		reset(w)
		var bb = iso.billboard_of(w)
		bb.sync_dynamic()
		var body_hidden := true
		for pr in bb._pairs:
			if pr[0].name == "Body" and pr[1].visible:
				body_hidden = false
		var corpo: Sprite2D = bb._char.get_node("Corpo") if bb._char else null
		if corpo and corpo.texture and bb._char.visible and body_hidden and bb.box.zt - bb.box.zb > 50.0:
			ok += 1
	check(ok == all.size(), "%d/%d ipezinhos com o boneco novo, o corpo antigo escondido e a caixa da altura nova" % [ok, all.size()])
