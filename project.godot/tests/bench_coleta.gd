extends SceneTree
## Bloco 106: MEDIÇÃO da coleta, do armazém e da ociosidade (não é teste: é a telemetria do diagnóstico).
## PARTIDA NOVA DE VERDADE: a Fundação do jogo (founding_on_new_game = true: 10 ipezinhos sem função, 400 cr, 90 de
## ferro, 80 de madeira), o Centro da Vila no meio do mapa (o lugar que o posicionador sugere), o relógio e a agenda
## normais (dia de 540 s reais). O Engine.time_scale só acelera a simulação (as taxas por segundo de jogo são as de sempre).
## Depois da Fundação, a abertura de um jogador (cfg):
##   abertura  : 1 engenheiro (3 casas iniciais + a cozinha encomendadas na hora), 4 mineradores, 3 lenhadores,
##               1 caçador, 1 cozinheiro — pelas teclas (sem área de trabalho), como o jogador que não abre a janela 5.
##   coleta    : os 10 coletando (6 mineradores, 4 lenhadores) — o pior caso do "armazém lotado".
## vagonete=on (como o jogo está: no Bloco 106, em RUÍNA na partida nova) | off (o ponto da boca parado: parar_por_area) |
## restaurado (Bloco 106: a ruína já restaurada, sem área de mina).
## A cada 0,25 h de jogo: "AMOSTRA;..." (o armazém por categoria, o que entrou e saiu de cada coisa, o ponto e o
## carrinho, quem está fazendo o quê e o motivo). No fim: "RESUMO;...".
## Uso: godot --headless --path . -s res://tests/bench_coleta.gd -- cfg=abertura vagonete=on horas=24
## RODAR SÓ COM APPDATA ISOLADO.
var main: Node
var t := 0.0
var cfg := "abertura"
var vagonete := "on"
var horas_max := 24.0
var fase := 0
var horas := 0.0
var prox_amostra := 0.0
var ant := {}  # chave -> valor anterior
var entrou := {}  # chave -> total que entrou (deltas positivos)
var saiu := {}  # chave -> total que saiu (deltas negativos)
var estado_t := {}  # "job/estado" -> horas
var motivo_t := {}  # "job/motivo" -> horas
var cheio_h := -1.0
var meio_h := -1.0
var viagens := 0
var cart_ant := ""
var obras_feitas := {}
var t0_real := 0
var sph := 22.5


func _initialize() -> void:
	if not ("fake_appdata" in ProjectSettings.globalize_path("user://")):
		print("ABORTADO: pasta de save não isolada")
		quit()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("cfg="):
			cfg = a.substr(4)
		elif a.begins_with("vagonete="):
			vagonete = a.substr(9)
		elif a.begins_with("horas="):
			horas_max = float(a.substr(6))
	var sm = root.get_node("SaveManager")
	sm.autosave_interval = 0.0
	sm.save_on_quit = false
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	main = load("res://scenes/game/main.tscn").instantiate()
	root.add_child(main)  # founding_on_new_game fica como no jogo (true)
	current_scene = main
	t0_real = Time.get_ticks_msec()


func g(group: String) -> Node:
	return get_first_node_in_group(group)


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func spot_near(c: Vector2) -> Vector2:
	var p = g("house_placer")
	p._collect_blockers()
	for r in range(0, 500, 12):
		for a in range(24):
			var q: Vector2 = (c + Vector2.RIGHT.rotated(a * TAU / 24.0) * r).round()
			if p.check_spot(q) == "":
				return q
	return Vector2.INF


## Os números do armazém (todos os armazéns somados), dos pontos de carga e da cozinha.
func leitura() -> Dictionary:
	var d := {"madeira": 0.0, "comida_crua": 0.0, "couro": 0.0, "itens": 0.0, "usado": 0.0, "capacidade": 0.0}
	for a in get_nodes_in_group("armazens"):
		d.madeira += a.wood_stored
		d.comida_crua += a.raw_stored
		d.couro += a.leather_stored
		for k in a.stock:
			d["min_" + k] = float(d.get("min_" + k, 0.0)) + float(a.stock[k])
		for k in a.itens:
			d.itens += float(a.itens[k])
		d.usado += a.usado()
		d.capacidade += a.capacidade()
	var ponto := 0.0
	var carrinho := 0.0
	for p in get_nodes_in_group("pontos_carga"):
		ponto += p.buffered()
		for k in p.cart_load:
			carrinho += float(p.cart_load[k])
	d["ponto_vagonete"] = ponto
	d["carrinho"] = carrinho
	var comida := 0.0
	for c in get_nodes_in_group("comedouros"):
		comida += float(c.food_stock)
	d["comida_pronta"] = comida
	return d


func _process(delta: float) -> bool:
	t += delta
	match fase:
		0:
			if t > 2.0:
				fase = 1
				_funda()
			return false
		1:
			return false
	if vagonete == "off":
		for p in get_nodes_in_group("pontos_carga"):
			p.call_deferred("parar_por_area", true, "desligado (medição)")  # (depois do work_areas, que religa sem área)
	sph = g("day_night").segundos_por_hora()
	var dh: float = delta / sph
	horas += dh
	var d := leitura()
	for k in d:
		if k in ["usado", "capacidade"]:
			continue
		var v: float = d[k]
		var a: float = ant.get(k, v)
		if v > a:
			entrou[k] = float(entrou.get(k, 0.0)) + (v - a)
		elif v < a:
			saiu[k] = float(saiu.get(k, 0.0)) + (a - v)
		ant[k] = v
	if cheio_h < 0.0 and d.usado >= d.capacidade - 1.0:
		cheio_h = horas
	if meio_h < 0.0 and d.usado >= d.capacidade * 0.5:
		meio_h = horas
	for w in ws():
		var chave := "%s/%s" % [w.job, w.get_state()]
		estado_t[chave] = float(estado_t.get(chave, 0.0)) + dh
		var m: String = w.motivo_parado()
		if m != "":
			var cm := "%s/%s" % [w.job, m]
			motivo_t[cm] = float(motivo_t.get(cm, 0.0)) + dh
	for p in get_nodes_in_group("pontos_carga"):
		if p.cart_state == "indo" and cart_ant != "indo":
			viagens += 1
		cart_ant = p.cart_state
	for c in get_nodes_in_group("casas"):
		if c.get("built") == true and not obras_feitas.has(c):
			obras_feitas[c] = horas
	for c in get_nodes_in_group("comedouros"):
		if not obras_feitas.has(c):
			obras_feitas[c] = horas
	if horas >= prox_amostra:
		prox_amostra += 0.25
		_amostra(d)
	if horas >= horas_max:
		_resumo(d)
		Engine.time_scale = 1.0
		quit()
		return true
	return false


func _funda() -> void:
	var fund = g("founding")
	var placer = g("house_placer")
	await process_frame
	await process_frame
	# o jogador aceita o lugar sugerido do Centro da Vila (o meio do mapa)
	if fund and fund.step == "hub":
		placer.move_to(fund._map_center())
		var ok: bool = placer.try_confirm()
		if not ok:
			placer.move_to(spot_near(fund._map_center()))
			placer.try_confirm()
	for i in 60:
		await process_frame
		if fund == null or fund.step == "done":
			break
	print("FUNDACAO;step=%s;ipezinhos=%d;creditos=%d;usado=%d/%d" % [fund.step if fund else "?", ws().size(), int(g("economy").credits), int(leitura().usado), int(leitura().capacidade)])
	var w: Array = ws()
	var hub = g("village_hub")
	if cfg == "coleta":
		for i in w.size():
			w[i].set_job("minerador" if i < 6 else "lenhador")
	else:
		w[0].set_job("engenheiro")
		for i in range(1, 5):
			w[i].set_job("minerador")
		for i in range(5, 8):
			w[i].set_job("lenhador")
		w[8].set_job("caçador")
		w[9].set_job("cozinheiro")
		# as 3 casas iniciais e a cozinha da Fundação, encomendadas na hora
		for i in 3:
			var p := spot_near(hub.global_position + Vector2(-140 + i * 110, 120))
			print("  casa %d: %s" % [i + 1, hub._confirm_starter_house(p)])
		print("  cozinha: %s" % hub._confirm_comedouro(spot_near(hub.global_position + Vector2(160, -40))))
	if vagonete == "restaurado":  # Bloco 106: o vagonete da boca começa em ruína; aqui ele já restaurado
		for p in get_nodes_in_group("bocas_mina"):
			if p.has_method("restaura_tudo"):
				p.restaura_tudo()
	if vagonete == "off":
		for p in get_nodes_in_group("pontos_carga"):
			p.parar_por_area(true, "desligado (medição)")
	print("CFG;%s;vagonete=%s;horas=%.1f;capacidade=%d" % [cfg, vagonete, horas_max, int(leitura().capacidade)])
	for k in leitura():
		ant[k] = leitura()[k]
	Engine.time_scale = 8.0
	fase = 2


func _amostra(d: Dictionary) -> void:
	var trabalhando := {}
	for w in ws():
		var k := "%s:%s" % [w.job, w.get_state()]
		trabalhando[k] = int(trabalhando.get(k, 0)) + 1
	var minerio := 0.0
	for k in d:
		if String(k).begins_with("min_"):
			minerio += float(d[k])
	print("AMOSTRA;%s;%s;h=%.2f;hora=%s;usado=%d/%d;madeira=%d;minerio=%d;%s;comida_crua=%d;comida_pronta=%d;itens=%d;ponto=%d;carrinho=%d;viagens=%d;estados=%s" % [
		cfg, vagonete, horas, g("day_night").hora_texto(), int(d.usado), int(d.capacidade), int(d.madeira), int(minerio),
		",".join(d.keys().filter(func(k): return String(k).begins_with("min_") and float(d[k]) >= 0.5).map(func(k): return "%s=%d" % [String(k).substr(4), int(d[k])])),
		int(d.comida_crua), int(d.comida_pronta), int(d.itens), int(d.ponto_vagonete), int(d.carrinho), viagens, JSON.stringify(trabalhando)])


func _resumo(d: Dictionary) -> void:
	var e := {}
	for k in entrou:
		e[k] = snappedf(entrou[k], 0.1)
	var s := {}
	for k in saiu:
		s[k] = snappedf(saiu[k], 0.1)
	var est := {}
	for k in estado_t:
		est[k] = snappedf(estado_t[k], 0.01)
	var mot := {}
	for k in motivo_t:
		mot[k] = snappedf(motivo_t[k], 0.01)
	var feitas: Array = obras_feitas.values().map(func(x): return snappedf(x, 0.01))
	feitas.sort()
	print("RESUMO;%s;vagonete=%s;horas=%.2f;meio_h=%.2f;cheio_h=%.2f;viagens=%d;tempo_real_s=%d" % [cfg, vagonete, horas, meio_h, cheio_h, viagens, (Time.get_ticks_msec() - t0_real) / 1000])
	print("ENTROU;" + JSON.stringify(e))
	print("SAIU;" + JSON.stringify(s))
	print("ESTADOS_H;" + JSON.stringify(est))
	print("MOTIVOS_H;" + JSON.stringify(mot))
	print("OBRAS_PRONTAS_H;" + JSON.stringify(feitas))
