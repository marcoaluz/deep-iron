extends SceneTree
## Bloco 113: a DIFICULDADE e a tela de NOVA PARTIDA (seção 25 do guia). RODAR SÓ COM APPDATA ISOLADO.
##   (A) Os dados: perfil_dificuldade.gd + um .tres por perfil em data/dificuldade/ com os números do pedido.
##   (B) O NORMAL é o jogo de antes: o normal.tres bate com os @export de Defesa, Sol, Moral e Comedouro, e o Normal não escreve
##       nada (nem fome nem preço mudam).
##   (C) Ferro, Tranquilo e Personalizado (com as faixas) escrevem os valores; a fome e o preço vão pelo Modificadores; o
##       comedouro novo traz a comida do perfil.
##   (D) Criativo: sem invasão (nem loop infinito em next_invasion_day), pacote da Fundação maior.
##   (E) Save: a chave "dificuldade" volta igual, vai no resumo, e o save ANTIGO (sem a chave) vira Normal.
##   (F) A partida nova entrega a escolha do menu (SaveManager.dificuldade_nova) ao nó Dificuldade.
##   (G) A tela de Nova partida (perfis, sliders só no Personalizado, "Começar" entrega a escolha) e o menu inicial.
##   (H) A janela da Defesa mostra o tier das criaturas, o que o faz subir e a dificuldade.
const Dificuldade := preload("res://scripts/core/dificuldade.gd")
const Perfil := preload("res://scripts/core/perfil_dificuldade.gd")
const Modificadores := preload("res://scripts/core/modificadores.gd")
const Painel := preload("res://scripts/ui/nova_partida_panel.gd")
var main: Node
var fails := 0
var _t0 := 0


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
	sm.dificuldade_nova = {}
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	_t0 = Time.get_ticks_msec()
	_roda()


func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - _t0 > 240000:
		print("TIMEOUT\nFALHAS: %d" % (fails + 1))
		return true
	return false


func check(ok: bool, msg: String) -> void:
	print(("  OK   " if ok else "  FALHOU ") + msg)
	if not ok:
		fails += 1


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func perto(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _roda() -> void:
	await _frames(12)
	var sm = root.get_node("SaveManager")
	var dif = g("dificuldade")
	var def = g("defense")
	var sun = g("sun")
	var moral = g("morale")
	var eco = g("economy")
	var hub = g("village_hub")

	print("== A) os dados")
	var tr := Dificuldade.perfil_de("tranquilo")
	var no := Dificuldade.perfil_de("normal")
	var fe := Dificuldade.perfil_de("ferro")
	var cr := Dificuldade.perfil_de("criativo")
	check(tr.id == "tranquilo" and no.id == "normal" and fe.id == "ferro" and cr.id == "criativo", "um .tres por perfil (tranquilo, normal, ferro, criativo)")
	check(tr.primeira_invasao_dia == 5 and no.primeira_invasao_dia == 3 and fe.primeira_invasao_dia == 2, "1ª invasão: dia 5 / 3 / 2")
	check(tr.invasao_a_cada == 3 and no.invasao_a_cada == 2 and fe.invasao_a_cada == 2, "invasão a cada: 3 / 2 / 2 dias")
	check(perto(tr.vida_por_onda, 0.08) and perto(no.vida_por_onda, 0.15) and perto(fe.vida_por_onda, 0.22), "vida das criaturas por onda: +8% / +15% / +22%")
	check(perto(tr.fome_mult, 0.8) and perto(no.fome_mult, 1.0) and perto(fe.fome_mult, 1.2), "fome: x0,8 / x1,0 / x1,2")
	check(perto(tr.onda_verao, 0.3) and perto(no.onda_verao, 0.5) and perto(fe.onda_verao, 0.65), "onda solar de verão: 30 / 50 / 65%")
	check(perto(tr.ultimato_greve, 480) and perto(no.ultimato_greve, 300) and perto(fe.ultimato_greve, 200), "ultimato da greve: 480 / 300 / 200 s")
	check(perto(tr.comida_inicial, 300) and perto(no.comida_inicial, 240) and perto(fe.comida_inicial, 160), "comida inicial: 300 / 240 / 160 (100 / 80 / 53% do que o comedouro guarda)")
	check(perto(tr.preco_venda_mult, 1.2) and perto(no.preco_venda_mult, 1.0) and perto(fe.preco_venda_mult, 0.85), "preço de venda: x1,2 / x1,0 / x0,85")
	check(cr.sem_invasao and not no.sem_invasao and not tr.sem_invasao and not fe.sem_invasao and cr.recursos_pacote_mult > 1.0 and cr.creditos_extras > 0, "só o Criativo é sem invasão e com recursos à vontade")
	check(Dificuldade.PERFIS == ["tranquilo", "normal", "ferro", "personalizado", "criativo"], "os 5 perfis, nessa ordem")
	check(Dificuldade.perfil_de("lixo").id == "normal", "perfil desconhecido = Normal")

	print("== B) o Normal é o jogo de antes")
	check(dif != null and dif.is_in_group("modificadores") and dif.perfil_id == "normal", "o nó Dificuldade está na cena (grupo modificadores) e começa no Normal")
	var cmd = load("res://scenes/props/comedouro.tscn").instantiate()
	check(no.primeira_invasao_dia == def.first_invasion_day and no.invasao_a_cada == def.invasion_every and perto(no.vida_por_onda, def.hp_growth),
		"normal.tres = Defesa (1ª invasão %d, a cada %d, vida +%d%%)" % [def.first_invasion_day, def.invasion_every, roundi(def.hp_growth * 100)])
	check(perto(no.onda_verao, sun.season_wave_chance[1]) and perto(no.ultimato_greve, moral.strike_ultimatum), "normal.tres = Sol (verão %.2f) e Moral (ultimato %d s)" % [sun.season_wave_chance[1], moral.strike_ultimatum])
	check(perto(no.comida_inicial, cmd.start_food), "normal.tres = comedouro (comida inicial %d)" % cmd.start_food)
	cmd.free()
	check(perto(Modificadores.mult(self, "fome"), 1.0) and perto(Modificadores.mult(self, "preco_venda"), 1.0), "o Normal não mexe na fome nem no preço")
	check(perto(eco.price_of("ferro"), eco.ore_price), "preço do ferro no Normal = o do jogo (%.2f)" % eco.ore_price)
	check(not def.sem_invasao() and def.next_invasion_day() > 0, "Normal tem invasão")

	print("== C) Ferro, Tranquilo e Personalizado")
	dif.escolhe({"perfil": "ferro"})
	check(def.first_invasion_day == 2 and def.invasion_every == 2 and perto(def.hp_growth, 0.22), "Ferro: Defesa (dia 2, a cada 2, +22%)")
	check(perto(sun.season_wave_chance[1], 0.65) and perto(sun.season_wave_chance[0], 0.25) and perto(sun.season_wave_chance[3], 0.12), "Ferro: onda de verão 65% e as outras estações não mudam")
	check(perto(moral.strike_ultimatum, 200), "Ferro: ultimato da greve 200 s")
	check(perto(Modificadores.mult(self, "fome"), 1.2), "Ferro: fome x1,2 pelo Modificadores")
	check(perto(eco.price_of("ferro"), eco.ore_price * 0.85), "Ferro: venda x0,85 (%.2f)" % eco.price_of("ferro"))
	var itens: Array = []
	for id in ["barra_ferro", "prego"]:
		if preload("res://scripts/core/items.gd").existe(id) and preload("res://scripts/core/items.gd").preco_base(id) > 0.0:
			itens.append(id)
	check(not itens.is_empty() and perto(eco.price_of(itens[0]), preload("res://scripts/core/items.gd").preco_base(itens[0]) * 0.85), "Ferro: o preço dos itens processados também (%s)" % [itens])
	var c1 = load("res://scenes/props/comedouro.tscn").instantiate()
	main.add_child(c1)
	check(perto(c1.food_stock, 160.0), "Ferro: o comedouro novo traz 160 de comida (%.0f)" % c1.food_stock)
	c1.queue_free()
	dif.escolhe({"perfil": "tranquilo"})
	check(def.first_invasion_day == 5 and def.invasion_every == 3 and perto(def.hp_growth, 0.08) and perto(sun.season_wave_chance[1], 0.3) and perto(moral.strike_ultimatum, 480),
		"Tranquilo: dia 5, a cada 3, +8%, verão 30%, ultimato 480 s")
	check(perto(Modificadores.mult(self, "fome"), 0.8) and perto(eco.price_of("ferro"), eco.ore_price * 1.2), "Tranquilo: fome x0,8 e venda x1,2")
	var primeira: int = def.first_day()
	check(def.is_invasion_night(primeira) and not def.is_invasion_night(primeira - 1) and not def.is_invasion_night(primeira + 1) and not def.is_invasion_night(primeira + 2) and def.is_invasion_night(primeira + 3),
		"Tranquilo: a 1ª invasão no dia %d e depois de 3 em 3 dias" % primeira)
	var c2 = load("res://scenes/props/comedouro.tscn").instantiate()
	main.add_child(c2)
	check(perto(c2.food_stock, 300.0), "Tranquilo: o comedouro novo traz 300 de comida (o máximo)")
	c2.queue_free()
	dif.escolhe({"perfil": "personalizado", "custom": {"primeira_invasao_dia": 7, "invasao_a_cada": 99, "fome_mult": 1.1, "onda_verao": -3.0, "ultimato_greve": 120.0}})
	check(dif.perfil_id == "personalizado" and def.first_invasion_day == 7, "Personalizado: dia 7 na Defesa")
	check(def.invasion_every == 6 and perto(sun.season_wave_chance[1], 0.0), "Personalizado: valor fora da faixa é ajustado (99 -> 6 dias, -3 -> 0%)")
	check(perto(moral.strike_ultimatum, 120.0) and perto(Modificadores.mult(self, "fome"), 1.1) and perto(def.hp_growth, 0.15), "Personalizado: o que não foi mexido fica como o Normal")
	check(dif.nome() == "Personalizado" and (dif.get_save_data().custom as Dictionary).size() == Perfil.AJUSTAVEIS.size(), "Personalizado guarda os 8 números")

	print("== D) Criativo")
	dif.escolhe({"perfil": "criativo"})
	var tem := false
	for d in range(1, 60):
		tem = tem or def.is_invasion_night(d)
	check(def.sem_invasao() and not tem, "Criativo: nenhuma noite de invasão")
	check(def.next_invasion_day() == -1, "Criativo: next_invasion_day = -1 (sem travar)")
	def._moradores_t = 0.0
	def._moradores_tick(1.0)
	check(def.moradores().is_empty(), "Criativo: os moradores hostis do fundo não nascem")
	var arm = g("armazens")
	var antes_cr: int = eco.credits
	var antes_ore: float = arm.stock.get(hub.house_stone_ore, 0.0)
	var antes_madeira: float = arm.wood_stored
	var fnd = g("founding")
	fnd._fresh = false
	fnd._finish()
	check(eco.credits - antes_cr == roundi(hub.founding_credits * cr.recursos_pacote_mult) + cr.creditos_extras,
		"Criativo: o pacote da Fundação vem x%d e +%d créditos (%d)" % [roundi(cr.recursos_pacote_mult), cr.creditos_extras, eco.credits - antes_cr])
	check(perto(arm.stock.get(hub.house_stone_ore, 0.0) - antes_ore, hub.founding_ore * cr.recursos_pacote_mult) and perto(arm.wood_stored - antes_madeira, hub.founding_wood * cr.recursos_pacote_mult),
		"Criativo: pedra e madeira do pacote x%d" % roundi(cr.recursos_pacote_mult))

	print("== E) save")
	dif.escolhe({"perfil": "personalizado", "custom": {"primeira_invasao_dia": 4, "preco_venda_mult": 1.25}})
	var data: Dictionary = sm._collect()
	check(data.has("dificuldade") and data.dificuldade.perfil == "personalizado" and perto(float(data.dificuldade.custom.preco_venda_mult), 1.25), "a chave 'dificuldade' vai no save")
	check(data.summary.dificuldade == "Personalizado", "o resumo do save mostra o perfil")
	var json = JSON.parse_string(JSON.stringify(data))
	dif.escolhe({"perfil": "ferro"})
	dif.load_save_data(json.dificuldade)
	check(dif.perfil_id == "personalizado" and perto(dif.perfil().preco_venda_mult, 1.25) and dif.perfil().primeira_invasao_dia == 4, "o ciclo do save (JSON) volta igual")
	dif.load_save_data({"perfil": "lixo", "custom": "x"})
	check(dif.perfil_id == "normal", "perfil ilegível no save = Normal (sem erro)")
	dif.escolhe({"perfil": "criativo"})
	var antigo: Dictionary = data.duplicate(true)
	antigo.erase("dificuldade")
	antigo.summary.erase("dificuldade")
	sm.pending_load = true
	sm._pending_data = antigo
	sm.apply_pending(main)
	check(dif.perfil_id == "normal" and not def.sem_invasao(), "SAVE ANTIGO (sem a chave) vira Normal")
	sm.pending_load = false

	print("== F) a partida nova entrega a escolha do menu")
	root.remove_child(main)
	main.free()
	await _frames(3)
	sm.dificuldade_nova = {"perfil": "ferro"}
	main = load("res://scenes/game/main.tscn").instantiate()
	main.founding_on_new_game = false
	root.add_child(main)
	current_scene = main
	await _frames(12)
	check(g("dificuldade").perfil_id == "ferro" and g("defense").first_invasion_day == 2 and perto(g("morale").strike_ultimatum, 200),
		"SaveManager.dificuldade_nova (Ferro) chega no nó e nos @export")
	sm.dificuldade_nova = {}

	print("== G) a tela de Nova partida")
	var p: VBoxContainer = Painel.new()
	root.add_child(p)
	await _frames(2)
	check(p.perfil_escolhido() == "normal" and (p.escolha().perfil == "normal"), "a tela abre no Normal")
	for id in Dificuldade.PERFIS:
		check(p._botoes.has(id), "botão do perfil %s" % id)
	p.seleciona("ferro")
	check(p.perfil_escolhido() == "ferro" and p._valores["primeira_invasao_dia"].text == "dia 2" and p._valores["ultimato_greve"].text == "3:20" and p._valores["vida_por_onda"].text == "+22%",
		"escolher o Ferro mostra os números dele (%s / %s / %s)" % [p._valores["primeira_invasao_dia"].text, p._valores["ultimato_greve"].text, p._valores["vida_por_onda"].text])
	check(not p.slider("fome_mult").editable and (p.escolha().custom as Dictionary).is_empty(), "os sliders ficam travados fora do Personalizado")
	p.seleciona("personalizado")
	check(p.slider("fome_mult").editable, "no Personalizado os sliders ficam livres")
	p.slider("fome_mult").value = 1.3
	p.slider("primeira_invasao_dia").value = 6
	var esc: Dictionary = p.escolha()
	check(esc.perfil == "personalizado" and perto(float(esc.custom.fome_mult), 1.3) and int(esc.custom.primeira_invasao_dia) == 6 and p._valores["fome_mult"].text == "x1,3",
		"mexer nos sliders muda a escolha (%s)" % [esc])
	p.seleciona("ferro")
	p.seleciona("personalizado")
	check(perto(p.slider("fome_mult").value, 1.3), "os números do Personalizado ficam guardados ao trocar de perfil")
	p.seleciona("criativo")
	check(p._extra.text.contains("Sem invasões"), "o Criativo avisa: sem invasões e recursos à vontade")
	var recebida := []
	p.comecar.connect(func(e): recebida.append(e))
	(p.get_meta("comeca_button") as Button).pressed.emit()
	check(recebida.size() == 1 and recebida[0].perfil == "criativo", "'Começar' entrega a escolha")
	var voltou := [false]
	p.voltar.connect(func(): voltou[0] = true)
	(p.get_meta("volta_button") as Button).pressed.emit()
	check(voltou[0], "'Voltar' devolve pro menu")
	p.free()
	# o menu inicial: "Novo jogo" abre a tela de dificuldade (sem save e sem backups, o primeiro jogo também)
	var menu = load("res://scenes/ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	await _frames(3)
	var tem_menu: bool = menu.get("_nova") != null and menu.get("_box") != null
	check(tem_menu, "o menu inicial tem a tela de Nova partida")
	if tem_menu:
		menu._abre_nova()
		check(menu._nova.visible and not menu._box.visible, "'Novo jogo' mostra a tela de dificuldade no lugar do menu")
		menu._nova.voltar.emit()
		check(not menu._nova.visible and menu._box.visible, "'Voltar' mostra o menu de novo")
	menu.free()

	print("== H) a janela da Defesa")
	var hud = g("hud")
	var def2 = g("defense")
	def2.wave = 7
	var t: Dictionary = def2.tier_detalhe()
	var pesq: int = (g("research").done as Array).size()
	check(t.tier == def2.tier() and t.tier == 1 + 7 / 3 + pesq / 4 and t.da_onda == 2 and t.prox_onda == 9 and t.pesquisas == pesq, "tier_detalhe: 1 + onda/3 + pesquisas/4 (onda 7, %d pesquisas = tier %d)" % [pesq, t.tier])
	check(t.prox_pesquisas >= 1 and t.prox_pesquisas <= 4 and (pesq + t.prox_pesquisas) % 4 == 0, "faltam %d pesquisa(s) pro próximo tier" % t.prox_pesquisas)
	hud.open_panel("defesa")
	var painel = hud._panels["defesa"]
	painel.refresh()
	var tx: Label = painel.find_child("Tier", true, false)
	var dx: Label = painel.find_child("Dificuldade", true, false)
	check(tx != null and tx.text.contains("TIER %d" % t.tier) and tx.text.contains("onda 7") and tx.text.contains("pesquisa") and tx.text.contains("ELITE") and tx.text.contains("+12%"),
		"a janela mostra o tier e o que o faz subir: %s" % (tx.text.replace("\n", " | ") if tx else "?"))
	check(dx != null and dx.text.contains("Ferro") and dx.text.contains("dia 2"), "a janela mostra a dificuldade da partida: %s" % (dx.text if dx else "?"))
	g("dificuldade").escolhe({"perfil": "criativo"})
	painel.refresh()
	check(painel._status.text.contains("Sem invasões") and painel.button_text() == "Defesa (G)" and not painel.has_available_action(), "Criativo: a janela e o botão não prometem invasão")

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)
