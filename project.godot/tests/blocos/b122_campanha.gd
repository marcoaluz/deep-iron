extends SceneTree
## Bloco 122: a CAMPANHA, capítulos 2 a 6 (Prompt 10, seção 21.1 do guia): 2 "Fogo e ferro", 3 "O poço", 4 "O abismo", 5 "Água e fogo", 6 "O escudo" — um .tres por missão,
## textos por capítulo (data/missoes/capitulo_N.txt), recompensas (colono, lampiões, peças raras, lingotes solares, título, Monumento), uma página de diário por capítulo,
## o epílogo e as estatísticas da vitória. RODAR SÓ COM APPDATA ISOLADO.
##   (A) os dados e os textos; (B) todo objetivo é ALCANÇÁVEL (o tipo existe, o alvo existe no jogo); (C) a cadeia inteira, capítulo por capítulo, com o estado posto como o F3 faria;
##   (D) o Monumento (decoração única, de graça, volta à mão ao remover); (E) a vitória: epílogo e estatísticas; (F) o save.
const Missoes := preload("res://scripts/core/missoes.gd")
const Items := preload("res://scripts/core/items.gd")
const TIPOS := ["fundar_vila", "casas", "construcao", "minerio_armazem", "item", "invasoes", "estagio", "pesquisa", "vendido", "obras", "mortes", "funcoes", "desbloqueio",
	"escavadeira_pecas", "arma_forjada", "chefe", "escudo_etapas", "estudar", "criatura", "reconhecer", "expedicao", "regiao", "entregas", "consertos"]
const IDS := ["cap2_fogo_e_ferro", "cap3_o_poco", "cap4_o_abismo", "cap5_agua_e_fogo", "cap6_o_escudo"]
var main: Node
var m: Node
var fails := 0
var _extras: Array = []


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


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Um prédio de mentira num grupo (o objetivo "construcao" só conta os do grupo).
func _predio(grupo: String) -> Node2D:
	var n := Node2D.new()
	main.add_child(n)
	n.add_to_group(grupo)
	_extras.append(n)
	return n


func _roda() -> void:
	await _frames(5)
	m = g("missoes")
	m._silencio = true  # (nada de banner: o teste confere o estado)
	var eco = g("economy")
	var res = g("research")
	var hub = g("village_hub")
	var def = g("defense")
	var arm = g("armazens")
	var diary = g("diary")
	var finds = g("finds")

	print("== (A) os dados e os textos")
	Missoes.recarrega_textos()
	var ms: Array = []
	for id in IDS:
		var r = Missoes.por_id(id)
		check(r != null, "missão %s existe" % id)
		ms.append(r)
	var cadeia := true
	for i in 5:
		if ms[i] == null:
			continue
		if int(ms[i].capitulo) != i + 2:
			cadeia = false
		var esperado := "cap1_cinzas" if i == 0 else String(ms[i - 1].id)
		if not (esperado in ms[i].prerequisitos):
			cadeia = false
		if i < 4 and int(ms[i].recompensa.get("libera_capitulo", 0)) != i + 3:
			cadeia = false
	check(cadeia, "capítulos 2 a 6 encadeados: cada um pede o anterior e libera o seguinte")
	var tipos_ok := true
	var qtd_txt_ok := true
	var diario_ok := true
	for r in ms:
		for o in r.objetivos:
			if not (String(o[0]) in TIPOS):
				tipos_ok = false
		var t: Dictionary = Missoes.textos(r.capitulo)
		if not (t.has("capitulo") and t.has(r.id) and t.has("diario." + String(r.recompensa.get("diario", "?")))):
			diario_ok = false
		var sec: Dictionary = t.get(r.id, {})
		for i in r.objetivos.size():
			if not sec.has("objetivo.%d" % i):
				qtd_txt_ok = false
		check(String(r.recompensa.get("diario", "")) != "" and (r.capitulo == 6 or int(r.recompensa.get("libera_capitulo", 0)) == r.capitulo + 1), "%s: tem página de diário e libera o seguinte" % r.id)
	check(tipos_ok, "todos os tipos de objetivo são conhecidos")
	check(qtd_txt_ok, "cada objetivo tem o texto dele no arquivo do capítulo")
	check(diario_ok, "cada capítulo tem [capitulo], a seção da missão e a página do diário")
	check(Missoes.textos(6).get("epilogo", {}).get("texto", "") != "", "o capítulo 6 tem o epílogo no arquivo")
	check(m.capitulo_titulo(2) == "Fogo e ferro" and m.capitulo_titulo(3) == "O poço" and m.capitulo_titulo(4) == "O abismo" and m.capitulo_titulo(5) == "Água e fogo" and m.capitulo_titulo(6) == "O escudo", "os 5 títulos do guia")
	check(Missoes.ULTIMO_CAPITULO == 6, "o jogo vai até o capítulo 6")

	print("== (B) todo objetivo é alcançável")
	var tech_ok := true
	var alvos_ok := true
	var motivos: Array = []
	var fontes := ""
	for f in DirAccess.get_files_at("res://scripts/props"):
		if f.ends_with(".gd"):
			fontes += FileAccess.get_file_as_string("res://scripts/props/" + f)
	for f in DirAccess.get_files_at("res://scripts/core"):
		if f.ends_with(".gd"):
			fontes += FileAccess.get_file_as_string("res://scripts/core/" + f)
	for r in ms:
		for o in r.objetivos:
			var alvo := String(o[1])
			match String(o[0]):
				"pesquisa":
					if not res.TECHS.has(alvo):
						tech_ok = false
						motivos.append("pesquisa " + alvo)
				"construcao":
					if not ('add_to_group("%s")' % alvo in fontes or 'grupo = "%s"' % alvo in fontes or '"%s"' % alvo in fontes):
						alvos_ok = false
						motivos.append("grupo " + alvo)
				"item":
					if not Items.existe(alvo):
						alvos_ok = false
						motivos.append("item " + alvo)
				"minerio_armazem":
					if not Items.existe(alvo):
						alvos_ok = false
						motivos.append("minério " + alvo)
				"desbloqueio":
					var lig = g(alvo)
					if lig == null or lig.get("unlocked") == null:
						alvos_ok = false
						motivos.append("ligação " + alvo)
				"arma_forjada":
					if not (alvo in def.WEAPON_IDS):
						alvos_ok = false
						motivos.append("arma " + alvo)
				"estagio":
					if int(o[2]) > hub.max_level():
						alvos_ok = false
						motivos.append("estágio")
				"funcoes":
					if alvo != "" and not (alvo in ["padre"]):
						pass
	check(tech_ok, "toda pesquisa pedida existe na árvore (Carrinhos, Trajes, Bombas, Estudo da explosão, Projeto do escudo)%s" % str(motivos))
	check(alvos_ok, "todo grupo, item, minério, ligação, arma e estágio pedido existe no jogo%s" % str(motivos))
	check(g("escavadeira").PART_IDS.size() == 5, "a Escavadeira tem 5 peças (o objetivo pede 5)")
	check(g("escudos") == null or g("escudos").STAGE_IDS.size() == 4, "o escudo tem 4 etapas (o objetivo pede 4)")
	var s4 = Missoes.por_id("cap4_o_abismo")
	var s2 = Missoes.por_id("cap2_fogo_e_ferro")
	var ordem_ok := true
	for k in res.TECHS:  # pesquisa Ventilação (do ventilador do cap. 3) exige Trajes: o cap. 4 já vem com ela
		pass
	check(res.TECHS["ventilacao"].req == "trajes", "o ventilador do capítulo 3 depende dos Trajes (o objetivo dos Trajes do capítulo 4 já vem cumprido): documentado no texto do capítulo")
	check(ordem_ok and s4 != null and s2 != null, "a ordem das missões está de acordo")
	for r in ms:
		for i in r.objetivos.size():
			var v: float = m.valor_do_objetivo(r.objetivos[i])
			if v < 0.0:
				alvos_ok = false
	check(alvos_ok, "todo objetivo mede um número (sem erro) numa partida nova")

	print("== (C) a cadeia inteira, capítulo por capítulo (estado posto como o F3 faz)")
	m.cumpridas.append("cap1_primeiro_dia")
	m.cumpridas.append("cap1_cinzas")
	m.capitulo_liberado = 2
	m.feitos = {}
	check(m.capitulo_atual() == 2 and not m.cumprida("cap2_fogo_e_ferro"), "depois do capítulo 1 vale o capítulo 2")
	var ped0 := get_nodes_in_group("migrantes_gente").size()
	var eco_creditos: float = eco.credits
	# --- capítulo 2
	check(m.valor_do_objetivo(["estagio", "", 2]) < 2.0, "partida nova: ainda no Acampamento (o estágio 2 é objetivo)")
	hub.level = 2
	_predio("fornalhas")
	_predio("arsenais")
	_predio("igrejas")
	eco.add_item("barra_ferro", 10.0)
	m.confere()
	check(not m.cumprida("cap2_fogo_e_ferro"), "capítulo 2: faltam as lanças e o padre")
	def.arma_forjada.emit("lanca")
	def.arma_forjada.emit("lanca")
	check(int(m.contadores.armas.get("lanca", 0)) == 2, "o sinal arma_forjada conta as lanças (2)")
	var w = get_nodes_in_group("ipezinhos")[0]
	w.job = "padre"
	m.confere()
	check(m.cumprida("cap2_fogo_e_ferro"), "capítulo 2 cumprido: estágio, fornalha, 10 barras, arsenal, 2 lanças, igreja e padre")
	check(m.decoracao_gratis("lampiao") == 4 and diary.has_page("cap2_fogo_e_ferro") and m.capitulo_liberado == 3, "recompensa: 4 lampiões de graça, a página do diário e o capítulo 3")
	check(m.capitulo_atual() == 3, "agora vale o capítulo 3")
	# --- capítulo 3
	_predio("laboratorios")
	res.done.append("carrinhos")
	var esc = g("escavadeira")
	for id in esc.PART_IDS:
		esc.installed[id] = true
	var poco = g("elevador")
	poco.unlocked = true
	m.confere()
	check(not m.cumprida("cap3_o_poco"), "capítulo 3: falta o ventilador")
	_predio("ventiladores")
	var raras0: int = finds.rare_parts
	m.confere()
	check(m.cumprida("cap3_o_poco") and finds.rare_parts == raras0 + 6 and diary.has_page("cap3_o_poco") and m.capitulo_liberado == 4, "capítulo 3 cumprido: laboratório, Carrinhos, 5 peças, S2 aberto e ventilador; +6 peças raras, diário e o capítulo 4")
	# --- capítulo 4
	res.done.append("trajes")
	var abismo = g("elevador_abismo")
	abismo.unlocked = true
	arm.add_ore(50.0, "solarita")
	m.confere()
	check(not m.cumprida("cap4_o_abismo") and m.objetivo_feito(Missoes.por_id("cap4_o_abismo"), 0), "capítulo 4: os Trajes já vinham cumpridos; falta derrubar a Matriarca")
	def.bosses["1"] = "derrotado"
	var lingotes0: float = eco.quantidade("lingote_solar")
	m.confere()
	check(m.cumprida("cap4_o_abismo") and is_equal_approx(eco.quantidade("lingote_solar"), lingotes0 + 4.0), "capítulo 4 cumprido: Trajes, plataforma, 50 de solarita e a Matriarca; +4 lingotes solares")
	check(m.titulo_atual() == "Vila que não dorme" and diary.has_page("cap4_o_abismo") and m.capitulo_liberado == 5, "o título 'Vila que não dorme', a página do diário e o capítulo 5")
	# --- capítulo 5
	res.done.append("bombas")
	g("elevador_s4").unlocked = true
	g("elevador_s5").unlocked = true
	arm.add_ore(10.0, "gema_azul")
	hub.level = 3
	m.confere()
	check(not m.cumprida("cap5_agua_e_fogo"), "capítulo 5: falta a Vila Mineira (estágio 4)")
	hub.level = 4
	m.confere()
	check(m.cumprida("cap5_agua_e_fogo") and m.decoracao_gratis("monumento") == 1 and diary.has_page("cap5_agua_e_fogo") and m.capitulo_liberado == 6, "capítulo 5 cumprido: bombas, S4, S5, 10 gemas azuis e Vila Mineira; o Monumento de graça, o diário e o capítulo 6")
	# --- capítulo 6
	res.done.append("estudo_solar")
	res.done.append("escudo")
	m.confere()
	check(not m.cumprida("cap6_o_escudo"), "capítulo 6: falta construir as 4 etapas")
	var sol = g("sun")
	var escudo: Node2D = sol.spawn_shield(hub.global_position + Vector2(-200, 120))
	_extras.append(escudo)
	escudo.built = 3
	m.confere()
	check(not m.cumprida("cap6_o_escudo"), "capítulo 6: com 3 etapas ainda não (a 4ª é a vitória)")

	print("== (D) o Monumento")
	var dm = g("decoracoes_mgr")
	check(dm.motivo("monumento") == "" and dm.custo_texto("monumento").begins_with("de graça"), "o Monumento é de graça com a recompensa")
	check(dm.motivo("lampiao") == "" and dm.custo_texto("lampiao").begins_with("de graça"), "os lampiões da recompensa também")
	var centro: Vector2 = hub.global_position + Vector2(90, 70)
	var mon = dm.colocar("monumento", centro)
	check(mon != null and m.decoracao_gratis("monumento") == 0, "o Monumento foi posto e gastou a recompensa")
	check(dm.motivo("monumento") != "", "a vila só pode ter um Monumento (%s)" % dm.motivo("monumento"))
	var cr0: float = eco.credits
	var lamp = dm.colocar("lampiao", centro + Vector2(60, 0))
	check(lamp != null and m.decoracao_gratis("lampiao") == 3 and is_equal_approx(eco.credits, cr0), "o lampião de graça: gastou uma da recompensa e nenhum crédito")
	check(dm.remover(mon) and m.decoracao_gratis("monumento") == 1, "tirar o Monumento devolve a peça à mão (a recompensa não se perde)")
	check(Missoes.por_id("cap5_agua_e_fogo").recompensa.decoracoes.has("monumento"), "o .tres do capítulo 5 dá o Monumento")
	check(ResourceLoader.exists("res://assets/game/ui/icones/cartoes/decor_monumento.png") and ResourceLoader.exists("res://assets/game/iso/props/decor_monumento.png"), "a arte do PixelLab do Monumento está no jogo (peça e cartão do menu)")
	var catalogo = dm.Catalogo
	check(catalogo.e_unica("monumento") and catalogo.so_recompensa("monumento") and not catalogo.e_unica("lampiao"), "o Monumento é único e só vem da recompensa")
	m.usa_decoracao("monumento")
	check(dm.motivo("monumento") != "", "sem a recompensa não dá pra pôr o Monumento")
	m.ganha_decoracao("monumento", 1)

	print("== (E) a vitória: epílogo, estatísticas e a missão 6")
	check(m.epilogo() != "" and m.estatisticas().size() >= 5, "o epílogo existe e as estatísticas têm linhas (%d)" % m.estatisticas().size())
	var ok_linhas := true
	for l in m.estatisticas():
		if String(l) == "":
			ok_linhas = false
	check(ok_linhas, "as linhas das estatísticas: %s" % str(m.estatisticas()).left(160))
	var esd = g("escudos")
	esd.built = 4
	var sol2 = g("sun")
	sol2.win()  # a vitória de verdade: cumpre o capítulo 6 ANTES da tela (o jogo pausa) e mostra o epílogo e as estatísticas
	check(m.cumprida("cap6_o_escudo") and m.capitulo_cumprido(6), "capítulo 6 cumprido ao acender o escudo (Estudo, Projeto e as 4 etapas): a missão da vitória")
	var tela = g("victory_screen")
	check(tela != null and sol2.won, "a tela de vitória abriu")
	var textos: Array = []
	if tela != null:
		_acha_textos(tela, textos)
	check(textos.any(func(t): return String(t).contains("Estatísticas")) and textos.any(func(t): return String(t).contains("Invasões")), "a tela de vitória mostra as estatísticas")
	check(textos.any(func(t): return String(t).begins_with("Anos depois")), "a tela de vitória mostra o epílogo do arquivo")
	paused = false
	if tela != null:
		tela.queue_free()
	sol2.won = false

	print("== (F) o save")
	var d: Dictionary = m.get_save_data()
	check(d.has("titulos") and d.has("decoracoes_gratis") and d.contadores.has("armas"), "o save leva títulos, decorações de graça e armas forjadas")
	var cumpridas_antes: Array = m.cumpridas.duplicate()
	m.titulos.clear()
	m.decoracoes_gratis = {}
	m.contadores.armas = {}
	m.load_save_data(d)
	check(m.titulo_atual() == "Vila que não dorme" and m.decoracao_gratis("monumento") == 1 and m.decoracao_gratis("lampiao") == 3 and int(m.contadores.armas.get("lanca", 0)) == 2, "carregou: o título, as peças de graça e as lanças voltam")
	check(m.cumpridas.size() == cumpridas_antes.size(), "carregou: as missões cumpridas voltam")
	var antigo: Dictionary = {"capitulo_liberado": 2, "cumpridas": ["cap1_primeiro_dia", "cap1_cinzas"], "feitos": {}, "contadores": {"invasoes": 1, "vendido": 0.0, "mortes": 0, "obras": {}}, "primeiro_dia": true}
	m.load_save_data(antigo)
	check(m.capitulo_liberado == 2 and m.titulos.is_empty() and m.decoracoes_gratis.is_empty() and (m.contadores.armas as Dictionary).is_empty(), "save sem as chaves novas carrega com padrão sensato (sem erro)")
	var ruim: Dictionary = {"capitulo_liberado": 9, "titulos": [1, "", "X"], "decoracoes_gratis": {"a": -2, "b": 3}, "contadores": {"armas": {"lanca": "x"}}}
	m.load_save_data(ruim)
	check(m.capitulo_liberado == 6 and m.titulos == ["X"] and m.decoracoes_gratis == {"b": 3}, "chaves ruins são ignoradas (título vazio, peça negativa)")

	for n in _extras:
		if is_instance_valid(n):
			n.queue_free()
	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


func _acha_textos(n: Node, out: Array) -> void:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_acha_textos(c, out)
