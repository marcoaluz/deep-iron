extends SceneTree
## Bloco 125: o POSTO DE TROCA e a CARAVANA (Prompt 13). RODAR SÓ COM APPDATA ISOLADO.
##   (A) o posto: obra em etapas com arte do PixelLab (obra 1/2/3/pronto), cartão do menu CONSTRUIR com imagem, @export; só um por vila;
##   (B) a comerciante: arte própria (caminhada, negociar, retrato com 5 expressões), roupa e falas editáveis;
##   (C) o ciclo: sem posto ela não para, a cada 14 dias ela chega, fica 3 dias e parte;
##   (D) os preços: estação, situação do mercado, evento, dificuldade e a variação por item;
##   (E) negociar: comprar dela (peças raras, sementes, carne), vender barras e gemas (teto de demanda), recusas;
##   (F) as encomendas (pedidos da vila) com bônus; (G) nada compra nem vende sozinho; (H) save, save antigo e save quebrado; (I) o F3 e o som.
const Caravana := preload("res://scripts/core/caravana.gd")
const Pedidos := preload("res://scripts/core/pedidos.gd")
const Items := preload("res://scripts/core/items.gd")
const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
const Retratos := preload("res://scripts/ui/retratos.gd")
var main: Node
var car: Node
var ped: Node
var eco: Node
var hub: Node
var dn: Node
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


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _dia() -> int:
	return int(dn.day)


## Muda o dia como o relógio faz (o sinal que a caravana escuta).
func _vai_pro_dia(d: int) -> void:
	dn.day = d
	car._novo_dia(d)


func _posto() -> Node:
	var p: Node = car.posto()
	if p == null:
		p = hub.spawn_obra107("posto_troca", (hub as Node2D).global_position + Vector2(-170, 90))
	return p


func _tira_posto() -> void:
	for p in get_nodes_in_group("postos_troca"):
		p.get_parent().remove_child(p)
		p.queue_free()


func _roda() -> void:
	await _frames(5)
	car = g("caravana")
	ped = g("pedidos")
	eco = g("economy")
	hub = g("village_hub")
	dn = g("day_night")
	ped.ligado = false
	g("eventos").ligado = false
	load("res://scripts/workers/ipezinho.gd").secundaria_desligada = true
	check(car != null and car.is_in_group("modificadores"), "o nó Caravana existe e está no grupo dos modificadores")

	print("== (A) o posto de troca")
	check(hub.OBRAS_107.has("posto_troca") and hub.OBRAS_107.posto_troca.grupo == "postos_troca", "o Centro tem a obra 'posto_troca' (OBRAS_107)")
	check(hub.troca_credits > 0 and hub.troca_wood > 0 and hub.troca_build_time > 0.0 and hub.troca_max == 1 and hub.troca_estagio >= 1, "custo, tempo, estágio e máximo nos @export do Centro")
	var kinds: Dictionary = load("res://scripts/props/canteiro.gd").KINDS
	check(kinds.has("posto_troca"), "o canteiro conhece o 'posto_troca'")
	var base := "res://assets/game/iso/predios/posto_troca/"
	var arte_ok := true
	for f in ["obra_1", "obra_2", "obra_3", "pronto"]:
		if not ResourceLoader.exists(base + f + ".png") and not FileAccess.file_exists(ProjectSettings.globalize_path(base + f + ".png")):
			arte_ok = false
			print("      falta " + base + f + ".png")
	check(arte_ok, "a arte do PixelLab do posto: obra 1, 2, 3 e pronto")
	check(ResourceLoader.exists("res://assets/game/posto_troca.png") and ResourceLoader.exists("res://assets/game/ui/icones/predios/posto_troca.png"), "o desenho do posicionador e o ícone do cartão")
	var bm := FileAccess.get_file_as_string("res://scripts/core/build_menu.gd")
	check('"name": "Posto de troca", "img": _predio("posto_troca")' in bm, "o cartão do menu CONSTRUIR tem imagem (_predio)")
	check(FileAccess.get_file_as_string("res://scripts/iso/iso_art.gd").count('"posto_troca": "posto_troca"') == 2, "a vista iso conhece a cena e o canteiro do posto")
	_tira_posto()
	check(car.posto() == null, "sem posto (partida nova)")
	check(hub.troca_block_reason() == "" or hub.troca_block_reason().begins_with("precisa") or hub.troca_block_reason().begins_with("falta") or hub.troca_block_reason() != "", "o Centro responde o motivo de poder ou não construir")
	var p := _posto()
	check(p != null and p.is_in_group("postos_troca") and p.is_in_group("clickable") and String(p.panel_id) == "caravana", "o posto nasce clicável e abre a janela da caravana")
	var nivel_ant: int = hub.level
	hub.level = 5
	check(hub.troca_block_reason().begins_with("já tem o máximo"), "só um posto por vila: '%s'" % hub.troca_block_reason())
	hub.level = nivel_ant
	check(hub.get_save_data().has("postos_troca") and (hub.get_save_data().postos_troca as Array).size() == 1, "o Centro guarda o posto no save")

	print("== (B) a comerciante")
	var bon: Dictionary = IsoBonecos.data()
	var fun: Dictionary = bon.get("funcoes", {})
	check(fun.has("comerciante"), "bonecos.json tem a função 'comerciante'")
	var par: Array = fun.get("comerciante", ["", "", ""])
	var pasta := String(par[1])
	var an: Dictionary = bon.get("pastas", {}).get(pasta, {}).get("anims", {})
	var anims_ok := true
	for a in ["parado", "caminhada", "negociar", "comer", "ferido", "deitar", "mancar_esq"]:
		if not an.has(a):
			anims_ok = false
			print("      falta a animação " + a)
	check(anims_ok, "a arte do PixelLab da comerciante tem parado, caminhada, negociar, comer, ferido, deitar e mancar")
	var ret_ok := true
	for e in ["neutro", "contente", "cansado", "bravo", "ferido"]:
		var rp := "res://assets/game/ui/retratos/%s/%s__parda.png" % [pasta, e]
		if not ResourceLoader.exists(rp):
			ret_ok = false
			print("      falta " + rp)
	check(ret_ok, "o retrato tem as 5 expressões")
	var fal: Dictionary = Caravana.falas()
	var fal_ok := true
	for k in ["chegada", "chegada_primeira", "sem_posto", "saudacao", "venda", "compra", "sem_dinheiro", "sem_estoque", "sem_demanda", "sem_item", "encomenda", "encomenda_cumprida", "despedida",
			"mercado_normal", "mercado_escassez", "mercado_excedente", "mercado_demanda", "mercado_festa"]:
		if not fal.has(k):
			fal_ok = false
			print("      falta a fala " + k)
	check(fal_ok, "as falas editáveis (data/caravana/falas.txt) cobrem chegada, venda, compra, recusas, encomenda e despedida")
	check(car.fala("chegada").find("{") < 0 and car.fala("chegada") != "", "a fala troca os {campos}")

	print("== (C) o ciclo da visita")
	car.ligado = true
	check(car.intervalo_dias == 14 and car.permanencia_dias == 3 and car.primeiro_dia > 0, "frequência (a cada 14 dias, 3 dias no posto) nos @export")
	car.chance_situacao = 0.0
	car.variacao = 0.0
	_tira_posto()
	_vai_pro_dia(car.primeiro_dia)
	check(not car.presente and car._avisou_sem_posto, "sem posto de troca a caravana passa direto (e avisa uma vez)")
	var dia0: int = _dia()
	_vai_pro_dia(dia0 + 1)
	check(not car.presente, "...e continua sem parar no dia seguinte")
	p = _posto()
	_vai_pro_dia(dia0 + 2)
	check(car.presente and car.visitas == 1, "com o posto pronto ela chega (visita 1)")
	check(car.chegou_dia == dia0 + 2 and car.parte_dia == car.chegou_dia + 3 and car.proxima_dia == car.chegou_dia + 14, "fica 3 dias e a próxima é em 14 (dia %d, parte %d, próxima %d)" % [car.chegou_dia, car.parte_dia, car.proxima_dia])
	await _frames(3)
	var m: Node = car.comerciante()
	check(m != null and bool(m.get("visitante")) and bool(m.get("e_comerciante")) and String(m.get("gender")) == "menina" and String(m.display_name) == car.nome_comerciante, "a comerciante é um ipezinho visitante com nome")
	check(m.outfit() == "comerciante" and IsoBonecos.funcao_de(m) == "comerciante", "ela veste a roupa própria (a função 'comerciante')")
	check(not m.is_in_group("ipezinhos") and m.is_in_group("migrantes_gente"), "ela não é da vila (não come, não ocupa cama, não conta)")
	var rt: Texture2D = Retratos.de(m)
	check(rt != null and Retratos.pasta(m) == pasta, "o retrato dela vem da pasta própria")
	_vai_pro_dia(dia0 + 3)
	check(car.presente, "no meio da visita ela segue lá")
	_vai_pro_dia(int(car.parte_dia))
	check(not car.presente, "no dia marcado ela parte")
	var saida: bool = car._saindo
	car._saindo_t = car.saida_limite_s
	car._t = 0.0
	car._process(0.1)
	await _frames(2)
	check(saida and car.comerciante() == null, "...e some do mapa (sem ficar parada na porta)")
	check(not _tem_viva_na_cena(), "nenhuma comerciante sobrando")
	_vai_pro_dia(int(car.proxima_dia) - 1)
	check(not car.presente, "um dia antes da hora ela não chega")
	var sol := g("sun")
	_vai_pro_dia(int(car.proxima_dia))
	check(car.presente and car.visitas == 2, "14 dias depois a visita 2 começa")
	car.parte()
	car.ligado = false
	_vai_pro_dia(int(car.proxima_dia) + 40)
	check(not car.presente, "desligada (Criativo, testes) ela não vem")
	car.ligado = true
	_vai_pro_dia(int(car.proxima_dia) + 1)
	check(car.presente, "religada ela volta ao primeiro dia possível")
	car.parte()
	car._saindo_t = 999.0
	car._t = 0.0
	car._process(0.1)

	print("== (D) os preços")
	car.chance_situacao = 0.0
	car.variacao = 0.0
	var dia_est := {}
	for d in range(1, 400):
		var e: int = sol.season_index(d)
		if not dia_est.has(e):
			dia_est[e] = d
	check(dia_est.size() == 4, "os 4 dias de estação achados")
	dn.day = dia_est[0]
	car.situacao = "normal"
	car._monta_ofertas()
	var barra_prim: float = car.preco_paga["barra_ferro"]
	var carne_prim: float = car.preco_cobra["carne_defumada"]
	dn.day = dia_est[3]
	car._monta_ofertas()
	var barra_inv: float = car.preco_paga["barra_ferro"]
	var carne_inv: float = car.preco_cobra["carne_defumada"]
	check(barra_inv > barra_prim and carne_inv > carne_prim, "preço varia por estação: no inverno a barra paga mais (%d x %d) e a carne cobra mais (%d x %d)" % [barra_inv, barra_prim, carne_inv, carne_prim])
	car.situacao = "demanda"
	car._monta_ofertas()
	check(car.preco_paga["barra_ferro"] > barra_inv, "situação 'metal em alta': ela paga mais pela barra (%d)" % car.preco_paga["barra_ferro"])
	car.situacao = "excedente"
	car._monta_ofertas()
	check(car.preco_cobra["carne_defumada"] < carne_inv, "situação 'carroça cheia': ela cobra menos (%d)" % car.preco_cobra["carne_defumada"])
	car.situacao = "normal"
	car._monta_ofertas()
	var pv0: float = car.preco_pra_vila("carne_defumada")
	var pd0: float = car.preco_da_vila("barra_ferro")
	g("eventos")._efeitos.append({"t": "mult", "chave": "caravana_preco", "v": 1.5, "texto": "teste", "ate_dia": _dia() + 5})
	check(car.preco_pra_vila("carne_defumada") > pv0 and car.preco_da_vila("barra_ferro") > pd0, "um evento (mult 'caravana_preco') mexe nos preços")
	g("eventos")._efeitos.clear()
	var fake := Node.new()
	var gs := GDScript.new()
	gs.source_code = "extends Node
func mult(chave: String, _quem = null) -> float:
	return 1.25 if chave == \"preco_venda\" else 1.0
"
	gs.reload()
	fake.set_script(gs)
	fake.add_to_group("modificadores")
	root.add_child(fake)
	await _frames(2)
	check(absf(car.preco_da_vila("barra_ferro") - roundf(pd0 * 1.25)) <= 1.0 and car.preco_pra_vila("carne_defumada") <= pv0, "a dificuldade (preco_venda 1.25): ela paga mais ao jogador e cobra menos dele")
	fake.queue_free()
	car.variacao = 0.3
	var variou := {}
	for i in 12:
		car._monta_ofertas()
		variou[car.preco_paga["gema_azul"]] = true
	check(variou.size() > 1, "a variação por visita muda o preço de um item (%d valores)" % variou.size())
	car.variacao = 0.0
	car._monta_ofertas()

	print("== (E) negociar")
	car.presente = true
	car.situacao = "normal"
	car._monta_ofertas()
	eco.credits = 1000.0
	var finds: Node = g("finds")
	var pr0: int = int(finds.rare_parts)
	var preco_pr: float = car.preco_pra_vila("pecas_raras")
	var est_pr: int = int(car.estoque.pecas_raras)
	var r: Dictionary = car.compra_da_caravana("pecas_raras", 1)
	check(bool(r.ok) and int(finds.rare_parts) == pr0 + 1 and absf(eco.credits - (1000.0 - preco_pr)) < 0.01 and int(car.estoque.pecas_raras) == est_pr - 1, "comprar peça rara: -%d cr, +1 no inventário, -1 do estoque" % preco_pr)
	var raw0: float = eco.quantidade("comida_crua")
	var c1: float = eco.credits
	r = car.compra_da_caravana("carne_defumada", 2)
	check(bool(r.ok) and absf(eco.quantidade("comida_crua") - (raw0 + 2.0 * car.carne_comida)) < 0.01 and eco.credits < c1, "carne defumada vira comida crua (+%d)" % int(2.0 * car.carne_comida))
	var food: Node = g("coleta_comida")
	var reg0 := 0.0
	if food != null and food.has_method("regen_por_segundo"):
		reg0 = food.regen_por_segundo()
	check(car.mult("horta") == 1.0, "sem sementes a horta não muda")
	r = car.compra_da_caravana("semente", 1)
	check(bool(r.ok) and car.semente_ate_dia >= _dia() + car.semente_dias and absf(car.mult("horta") - (1.0 + car.semente_bonus)) < 0.001, "pacote de sementes: +%d%% na horta por %d dias" % [int(car.semente_bonus * 100.0), car.semente_dias])
	if food != null and food.has_method("regen_por_segundo"):
		check(food.regen_por_segundo() > reg0 or reg0 == 0.0, "a horta de verdade cresce mais rápido com as sementes (%.2f -> %.2f)" % [reg0, food.regen_por_segundo()])
	var dia_ant: int = _dia()
	dn.day = car.semente_ate_dia + 1
	check(car.mult("horta") == 1.0, "passados os dias, as sementes acabam")
	dn.day = dia_ant
	eco.credits = 1.0
	var estq: int = int(car.estoque.pecas_raras)
	r = car.compra_da_caravana("pecas_raras", 1)
	check(not bool(r.ok) and String(r.motivo) != "" and int(car.estoque.pecas_raras) == estq and eco.credits == 1.0, "sem créditos ela recusa (e fala)")
	eco.credits = 100000.0
	var tudo: int = int(car.estoque.carne_defumada)
	r = car.compra_da_caravana("carne_defumada", tudo + 1)
	check(not bool(r.ok), "além do estoque ela recusa")
	var c_ant: float = eco.credits
	car.estoque.carne_defumada = 0
	check(not bool(car.compra_da_caravana("carne_defumada", 1).ok) and eco.credits == c_ant, "estoque zerado: nada é cobrado")
	# vender
	eco.add_item("barra_ferro", 30.0)
	eco.devolve("cristal_verde", 5.0)
	var b0: float = eco.quantidade("barra_ferro")
	var cr0: float = eco.credits
	var pb: float = car.preco_da_vila("barra_ferro")
	r = car.venda_pra_caravana("barra_ferro", 10)
	check(bool(r.ok) and absf(eco.quantidade("barra_ferro") - (b0 - 10.0)) < 0.01 and absf(eco.credits - (cr0 + pb * 10.0)) < 0.01, "vender 10 barras: -10 no armazém, +%d cr" % int(pb * 10.0))
	check(int(car.demanda.barra_ferro) == int(car.demanda_visita.barra_ferro) - 10, "a demanda da visita desce")
	var cv0: float = eco.quantidade("cristal_verde")
	r = car.venda_pra_caravana("cristal_verde", 3)
	check(bool(r.ok) and absf(eco.quantidade("cristal_verde") - (cv0 - 3.0)) < 0.01, "ela compra gema (cristal verde)")
	car.demanda.barra_ferro = 5
	var b1: float = eco.quantidade("barra_ferro")
	r = car.venda_pra_caravana("barra_ferro", 6)
	check(not bool(r.ok) and absf(eco.quantidade("barra_ferro") - b1) < 0.01, "acima da demanda da visita ela recusa e nada sai do armazém")
	r = car.venda_pra_caravana("aco", 3)
	check(not bool(r.ok) and String(r.motivo) != "", "o que a vila não tem livre ela recusa ('Você não tem isso no armazém')")
	check(car.maximo_venda("barra_ferro") <= 5 and car.maximo_compra("pecas_raras") >= 0, "o máximo do botão respeita a demanda e o estoque")
	check(car.vendido_cr > 0.0 and car.gasto_cr > 0.0 and int(car.vendidos.barra_ferro) == 10 and int(car.comprados.semente) == 1, "as estatísticas guardam o que a vila vendeu e comprou")
	car.presente = false
	var cr_s: float = eco.credits
	check(not bool(car.compra_da_caravana("pecas_raras", 1).ok) and not bool(car.venda_pra_caravana("barra_ferro", 1).ok) and eco.credits == cr_s, "com a caravana ausente nada se negocia")

	print("== (F) as encomendas")
	car.presente = false
	car.chance_situacao = 0.0
	ped.abertos.clear()
	_vai_pro_dia(int(car.proxima_dia) + 1)
	check(car.presente, "visita nova")
	var enc: Array = ped.abertos.filter(func(pp): return String(pp.tipo) == "caravana_encomenda")
	check(enc.size() == 1 or (car.visitas >= car.segunda_encomenda_visita and enc.size() == 2), "a caravana abre %d encomenda(s) nos pedidos da vila" % enc.size())
	var e0: Dictionary = enc[0]
	check(String(e0.autor) == car.nome_comerciante and int(e0.meta) > 0 and String(e0.item) != "" and int(e0.bonus) > 0 and int(e0.prazo_dia) == int(car.parte_dia) - 1, "autora Cacilda, quantidade, item, bônus e prazo até ela partir")
	await _frames(3)
	check(ped._acha(String(e0.autor)) == car.comerciante(), "a janela de pedidos acha a comerciante (retrato)")
	var txt: String = ped.texto_de(e0)
	check(txt.find("{") < 0 and txt.find(Items.plural(String(e0.item))) >= 0, "o texto do pedido: '%s'" % txt.substr(0, 60))
	var item: String = String(e0.item)
	var meta: int = int(e0.meta)
	check(ped.progresso(e0)[0] == 0 and ped.progresso(e0)[1] == meta, "andamento 0/%d" % meta)
	check(_n_vila(ped) == 0, "a encomenda não conta pro teto de pedidos abertos da vila")
	# dá o que falta no armazém e entrega
	if Items.onde(item) == "itens":
		eco.add_item(item, float(meta + 5))
	else:
		eco.devolve(item, float(meta + 5))
	car.demanda[item] = meta + 5
	car.preco_paga[item] = maxf(float(car.preco_paga.get(item, 5.0)), 5.0)
	var cr_a: float = eco.credits
	r = car.venda_pra_caravana(item, meta - 1)
	check(bool(r.ok) and ped.progresso(e0)[0] == meta - 1 and ped.abertos.has(e0), "vender quase tudo: %d/%d, ainda aberta" % [meta - 1, meta])
	var cumpridas0: int = car.encomendas_cumpridas
	r = car.venda_pra_caravana(item, 1)
	await _frames(2)
	ped._t = 0.0
	ped._process(0.1)
	check(not ped.abertos.has(e0) and not ped.historico.is_empty() and String(ped.historico.back().estado) == "cumprido", "entregou: a encomenda se cumpre")
	check(eco.credits >= cr_a + float(e0.bonus), "o bônus (%d cr) entra no caixa (além do preço da venda)" % int(e0.bonus))
	check(car.encomendas_cumpridas == cumpridas0 + 1, "a caravana conta a encomenda cumprida")
	var ab_resta: Array = ped.abertos.filter(func(pp): return String(pp.tipo) == "caravana_encomenda")
	var vencidas0: int = ped.historico.filter(func(h): return String(h.estado) == "vencido").size()
	car.parte()
	check(ped.abertos.filter(func(pp): return String(pp.tipo) == "caravana_encomenda").is_empty(), "quando ela parte a encomenda que sobrou vence")
	check(ped.historico.filter(func(h): return String(h.estado) == "vencido").size() == vencidas0 + ab_resta.size(), "...e fica no histórico como vencida")
	car._saindo_t = 999.0
	car._t = 0.0
	car._process(0.1)

	print("== (G) nada compra nem vende sozinho")
	car.presente = true
	car.situacao = "normal"
	car._monta_ofertas()
	eco.credits = 500.0
	eco.add_item("barra_ferro", 20.0)
	var snap_cr: float = eco.credits
	var snap_b: float = eco.quantidade("barra_ferro")
	var snap_est: String = JSON.stringify(car.estoque)
	var snap_dem: String = JSON.stringify(car.demanda)
	for i in 30:
		car._t = 0.0
		car._process(20.0)
	await _frames(30)
	check(eco.credits == snap_cr and absf(eco.quantidade("barra_ferro") - snap_b) < 0.01 and JSON.stringify(car.estoque) == snap_est and JSON.stringify(car.demanda) == snap_dem,
		"com a caravana aberta por muito tempo, os créditos, o armazém e as ofertas ficam como estão")
	var fora := 0
	for dir in ["res://scripts/core/", "res://scripts/props/", "res://scripts/workers/", "res://scripts/ui/", "res://scripts/iso/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd") and f != "caravana.gd" and f != "caravana_panel.gd":
				var tx := FileAccess.get_file_as_string(dir + f)
				if tx.find("compra_da_caravana(") >= 0 or tx.find("venda_pra_caravana(") >= 0:
					fora += 1
	check(fora == 0, "só a janela (botões) chama comprar e vender: nenhum outro script negocia (%d)" % fora)
	var pn := FileAccess.get_file_as_string("res://scripts/core/caravana_panel.gd")
	check(pn.count("compra_da_caravana(") == 2 and pn.count("venda_pra_caravana(") == 2, "a janela chama cada uma só de botão")

	print("== (H) save")
	car.visitas = 5
	car.vendido_cr = 123.0
	car.situacao = "festa"
	car._monta_ofertas()
	car.semente_ate_dia = _dia() + 4
	var abertas_antes: int = ped.abertos.size()
	ped.abre_encomenda("Cacilda", "barra_cobre", 12, int(car.parte_dia) - 1, 40)
	var d: Dictionary = car.get_save_data()
	var dj: Dictionary = JSON.parse_string(JSON.stringify(d))
	var pd: Dictionary = JSON.parse_string(JSON.stringify(ped.get_save_data()))
	check(dj.has("presente") and dj.has("estoque") and dj.has("preco_paga") and dj.has("vendidos") and dj.has("visitas") and dj.has("semente_ate_dia"), "as chaves do save da caravana")
	car.presente = false
	car.visitas = 0
	car.estoque = {}
	car.vendido_cr = 0.0
	ped.abertos.clear()
	car.load_save_data(dj)
	ped.load_save_data(pd)
	await _frames(4)
	check(car.presente and car.visitas == 5 and absf(car.vendido_cr - 123.0) < 0.01 and car.situacao == "festa" and not car.estoque.is_empty() and not car.preco_paga.is_empty(), "o que estava no save volta")
	check(car.comerciante() != null and car.comerciante().get("e_comerciante") == true, "a comerciante é recriada no posto")
	var enc2: Array = ped.abertos.filter(func(pp): return String(pp.tipo) == "caravana_encomenda")
	check(enc2.size() >= 1 and String(enc2.back().item) == "barra_cobre" and int(enc2.back().meta) == 12 and int(enc2.back().bonus) == 40 and int(enc2.back().vendido) == 0, "a encomenda aberta volta com item, meta e bônus")
	check(car.semente_ate_dia == _dia() + 4, "as sementes continuam valendo")
	car.load_save_data({})
	check(not car.presente and car.visitas == 0 and car.proxima_dia == -1 and car.situacao == "normal" and car.comerciante() == null, "save antigo (sem 'caravana'): sem visita, nada quebra")
	car.load_save_data({"presente": true, "estoque": "lixo", "preco_paga": {"barra_ferro": "x", "aco": 3}, "situacao": "inexistente", "visitas": "abc", "demanda": [1]})
	check(car.situacao == "normal" and car.visitas == 0 and not car.preco_paga.has("barra_ferro") and car.preco_paga.get("aco", 0) == 3, "save quebrado vira o padrão (sem erro)")
	check(not car.presente or car.posto() != null, "uma visita 'presente' só vale com posto pronto")
	_tira_posto()
	car.load_save_data(dj)
	check(not car.presente, "sem posto no mundo a visita do save não fica pendurada")
	var sm = root.get_node("SaveManager")
	check(FileAccess.get_file_as_string("res://scripts/core/save_manager.gd").find('"caravana": "caravana"') >= 0, "o save_manager guarda a chave 'caravana'")

	print("== (I) o F3 e o som")
	var dbg := FileAccess.get_file_as_string("res://scripts/core/debug_panel.gd")
	check(dbg.find("caravana: chega/parte") >= 0 and dbg.find("func _caravana()") >= 0, "o F3 tem 'caravana: chega/parte'")
	var sl := FileAccess.get_file_as_string("res://data/audio/slots.json")
	check(sl.find("caravana/chegada") >= 0 and sl.find("caravana/moedas") >= 0, "os sons da caravana estão no slots.json")
	check(FileAccess.file_exists("res://assets/audio/caravana/chegada_0.wav") and FileAccess.file_exists("res://assets/audio/caravana/moedas_0.wav"), "e os arquivos existem (ElevenLabs)")
	var hud := g("hud")
	check(hud != null and hud._panels.has("caravana"), "a janela 'caravana' está registrada no HUD")
	if hud != null and hud._panels.has("caravana"):
		_posto()
		car.presente = true
		car._monta_ofertas()
		hud.open_panel("caravana")
		await _frames(3)
		check(hud._panels.caravana.visible and hud._panels.caravana._loja.get_child_count() >= 3 and hud._panels.caravana._compra.get_child_count() >= 7, "a janela abre com a loja (3) e as compras (7)")
		hud._panels.caravana.visible = false
		car.presente = false
		hud.open_panel("caravana")
		await _frames(2)
		check(hud._panels.caravana.visible, "e abre também com a caravana ausente (banca fechada)")
		hud._panels.caravana.visible = false

	print("FALHAS: %d" % fails)
	quit(1 if fails > 0 else 0)


func _tem_viva_na_cena() -> bool:
	for n in get_nodes_in_group("migrantes_gente"):
		if is_instance_valid(n) and not n.is_queued_for_deletion() and bool(n.get("e_comerciante")):
			return true
	return false


func _n_vila(pe: Node) -> int:
	return pe._n_da_vila()
