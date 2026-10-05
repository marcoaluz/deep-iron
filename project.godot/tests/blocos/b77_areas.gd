extends SceneTree
## Bloco 77: ÁREAS DE TRABALHO com postos (Frostpunk). Confere: marcar área (madeira, alimentos, mina) com a
## ferramenta, os limites (5 por área, não passa dos disponíveis, área inválida), disponível -> alocado ->
## disponível, quem está na área só usa o que está DENTRO dela (e quem não está não usa o que é da área), a
## troca de função à mão tirando da área, a mina (desligada / sem mineiro / operando; o carrinho só anda
## operando), a produção de verdade acompanhando a quantidade (5 rende mais que 2) e o save (áreas,
## quem está em cada uma, mina ligada) voltando igual.
## RODAR SÓ COM APPDATA ISOLADO.
const PATH := "user://savegame.json"
## (as funções do ipezinho.gd: o teste não pode dar preload nele — compila antes dos autoloads)
const IDLE := "ocioso"
const LUMBER := "lenhador"
const HUNTER := "caçador"
const MINER := "minerador"
var main: Node
var t := 0.0
var t_mark := 0.0
var step := 0
var fails := 0
var wa: Node
var madeira = null
var comida = null
var mina = null
var total_antes := 0.0
var d5 := 0.0
var d2 := 0.0
var salvo := {}


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


func g(grupo: String) -> Node:
	return get_first_node_in_group(grupo)


func ws() -> Array:
	return get_nodes_in_group("ipezinhos")


func _process(delta: float) -> bool:
	t += delta
	if t > 260.0:
		Engine.time_scale = 1.0
		print("TIMEOUT (passo %d)\nFALHAS: %d" % [step, fails + 1])
		return true
	match step:
		0:
			if t > 4.0:
				_prepara()
				_cria()
				_aloca()
				_restricao()
				_troca_manual()
				_mina()
				_producao_comeca()
				step = 1
				t_mark = t
		1:  # 5 na área: chegam e começam (20 s de jogo) e medimos 30 s (o delta do _process já vem escalado)
			_mantem()
			if t - t_mark > 20.0 and total_antes == 0.0:
				total_antes = madeira.total + 0.0001
				t_mark = t
			elif total_antes > 0.0 and t - t_mark > 30.0:
				d5 = madeira.total - total_antes
				wa.definir(madeira, 2)
				total_antes = 0.0
				step = 2
				t_mark = t
		2:  # 2 na área: assenta e medimos o mesmo tanto
			_mantem()
			if t - t_mark > 10.0 and total_antes == 0.0:
				total_antes = madeira.total + 0.0001
				t_mark = t
			elif total_antes > 0.0 and t - t_mark > 30.0:
				d2 = madeira.total - total_antes
				Engine.time_scale = 1.0
				_producao_confere()
				_salva()
				step = 3
				t_mark = t
		3:
			if t - t_mark > 0.5:
				root.get_node("SaveManager").load_game()
				step = 4
				t_mark = t
		4:
			if t - t_mark > 5.0:
				_carregado()
				print("FALHAS: %d" % fails)
				return true
	return false


func _prepara() -> void:
	print("== preparando: 9 ipezinhos, todos sem função")
	wa = g("work_areas")
	check(wa != null, "o sistema de áreas existe (grupo work_areas)")
	var eco = g("economy")
	eco.max_workers = 30
	while ws().size() < 9:
		if eco.recruit_free() == null:
			break
	for w in ws():
		w.set_job(IDLE)
		w.overtime = true  # o teste não pode cair na noite
	check(ws().size() >= 9, "ipezinhos: %d" % ws().size())
	check(wa.disponiveis().size() == ws().size(), "todos disponíveis (%d)" % wa.disponiveis().size())
	check(g("area_placer") != null, "a ferramenta de marcar área existe")
	var hud = g("hud")
	check(hud._panels.has("trabalho"), "a janela TRABALHADORES está no HUD")


## Um retângulo em volta de `n` coisas do grupo (as mais perto da primeira liberada).
func _rect_em_volta(grupo: String, n: int, lado: float) -> Rect2:
	var env = g("environment")
	var nodes: Array = get_nodes_in_group(grupo).filter(func(x): return (not x.has_method("is_usable") or x.is_usable()) and not (env.has_method("trancado") and env.trancado(x.global_position)))
	if nodes.is_empty():
		return Rect2()
	var c: Vector2 = nodes[0].global_position
	var r := Rect2(c - Vector2(lado, lado) * 0.5, Vector2(lado, lado))
	return r


func _dentro(grupo: String, r: Rect2) -> int:
	return get_nodes_in_group(grupo).filter(func(x): return r.has_point(x.global_position)).size()


func _cria() -> void:
	print("== marcar as áreas")
	var placer = g("area_placer")
	placer.begin("madeira")
	check(placer.active, "a ferramenta liga pro corte de árvores")
	var r := _rect_em_volta("arvores", 4, 420.0)
	placer.drag(r.position, r.position + Vector2(10, 10))
	check(placer.try_confirm() == null and placer.reason != "", "área minúscula não vale (%s)" % placer.reason)
	placer.drag(r.position, r.end)
	madeira = placer.try_confirm()
	check(madeira != null and not placer.active, "área de madeira criada arrastando (%d árvores dentro)" % _dentro("arvores", r))
	check(_dentro("arvores", r) >= 3, "tem árvores dentro da área")
	check(wa.motivo_invalido("madeira", r.grow(-20.0)) != "", "não deixa outra área de madeira em cima (%s)" % wa.motivo_invalido("madeira", r.grow(-20.0)))
	var hud = g("hud")
	check(hud._panels["trabalho"].visible and hud._panels["trabalho"].selected_area() == madeira, "a janela abriu com a área nova destacada")
	check(wa.estado(madeira) == wa.ESTADO_SEM_GENTE, "estado: %s" % wa.estado(madeira))
	var rc := _rect_em_volta("coleta_comida", 1, 220.0)
	comida = wa.criar("comida", rc)
	check(comida != null, "área de alimentos criada (%d fontes dentro)" % _dentro("coleta_comida", rc))


func _aloca() -> void:
	print("== disponíveis -> alocados (até 5) -> disponíveis")
	var n: int = ws().size()
	check(wa.definir(madeira, 9) == 5, "pedir 9 numa área dá 5 (o limite)")
	check(madeira.quantos() == 5 and wa.disponiveis().size() == n - 5, "5/5 e %d disponíveis" % wa.disponiveis().size())
	check(wa.adicionar(madeira) != "", "área cheia não aceita mais (%s)" % wa.adicionar(madeira))
	var ok := true
	for w in madeira.trabalhadores:
		ok = ok and w.job == LUMBER and w.work_area == madeira and not wa.disponiveis().has(w)
	check(ok, "os 5 viraram lenhadores da área e saíram dos disponíveis")
	check(wa.remover(madeira) == "" and madeira.quantos() == 4 and wa.disponiveis().size() == n - 4, "tirar um: 4/5 e ele volta pros disponíveis")
	var livres: int = wa.disponiveis().size()
	check(wa.definir(comida, 5) == mini(5, livres), "alimentos pede 5 e fica com o que tem (%d)" % comida.quantos())
	check(comida.trabalhadores.all(func(w): return w.job == HUNTER), "na área de alimentos eles colhem (caçador)")
	if wa.disponiveis().is_empty():
		check(wa.adicionar(comida) == "nenhum trabalhador disponível" or comida.cheia(), "sem disponível não aloca (%s)" % wa.adicionar(comida))
	wa.definir(comida, 1)
	check(comida.quantos() == 1, "alimentos: 1/5")
	check(wa.definir(madeira, 5) == 5, "madeira de volta a 5/5")


func _restricao() -> void:
	print("== cada um só trabalha na área dele")
	var w: Node = madeira.trabalhadores[0]
	var fora: Node = null
	var dentro: Node = null
	for tr in get_nodes_in_group("arvores"):
		if madeira.contem(tr.global_position):
			dentro = tr
		elif fora == null:
			fora = tr
	check(dentro != null and wa.pode_usar(w, dentro.global_position, "arvores"), "o da área usa árvore de dentro")
	check(fora != null and not wa.pode_usar(w, fora.global_position, "arvores"), "o da área NÃO usa árvore de fora")
	var avulso: Node = wa.disponiveis()[0] if not wa.disponiveis().is_empty() else null
	if avulso:
		avulso.set_job(LUMBER)
		check(not wa.pode_usar(avulso, dentro.global_position, "arvores") and wa.pode_usar(avulso, fora.global_position, "arvores"),
			"lenhador sem área (tecla L) não usa a árvore da área, só as de fora")
		check(not wa.disponiveis().has(avulso), "com função à mão ele também não conta como disponível")
		avulso.set_job(IDLE)
	check(wa.pode_usar(w, Vector2(99999, 99999), "armazens"), "o armazém continua liberado (só o recurso da área é preso)")


func _troca_manual() -> void:
	print("== trocar a função à mão tira da área")
	var w: Node = madeira.trabalhadores[0]
	w.set_job(MINER)
	check(w.work_area == null and madeira.quantos() == 4, "virou minerador pela tecla: saiu da área (4/5)")
	w.set_job(IDLE)
	check(wa.disponiveis().has(w), "e sem função volta a ser disponível")
	wa.definir(madeira, 5)


func _mina() -> void:
	print("== a mina: ligar o carrinho, precisa de mineiro")
	var cart: Node = null
	for st in get_nodes_in_group("pontos_carga"):
		if st.get("rota_fixa"):
			cart = st
	check(cart != null, "o ponto de carga da mina (vagonete fixo) existe")
	var jaz: Array = get_nodes_in_group("minerios").filter(func(j): return j.is_usable() and j.global_position.distance_to(cart.global_position) < 500.0)
	check(not jaz.is_empty(), "tem jazida liberada perto do carrinho (%d)" % jaz.size())
	var r := Rect2(cart.global_position, Vector2.ZERO)
	for j in jaz:
		r = r.expand(j.global_position)
	r = r.grow(30.0)
	mina = wa.criar("mina", r)
	check(mina != null, "área de mina criada")
	if mina == null:
		return
	check(not mina.ativa and wa.estado(mina) == wa.ESTADO_DESATIVADA, "nasce desligada: %s" % wa.estado(mina))
	check(wa.carrinhos(mina).has(cart), "o carrinho da mina está na área")
	wa._sincroniza_carrinhos()
	check(cart.parado_por_area() and not cart.is_usable(), "mina desligada: o carrinho para e o ponto não recebe")
	wa.definir(mina, 1)
	var m: Node = mina.trabalhadores[0] if mina.quantos() > 0 else null
	check(m != null and m.job == MINER, "1 mineiro na mina")
	check(m != null and not wa.pode_usar(m, jaz[0].global_position, "minerios"), "desligada: o mineiro não minera")
	wa.ativar(mina, true)
	check(wa.estado(mina) == wa.ESTADO_OPERANDO, "ligada com 1 mineiro: %s" % wa.estado(mina))
	check(not cart.parado_por_area(), "operando: o carrinho anda")
	check(wa.pode_usar(m, jaz[0].global_position, "minerios"), "operando: o mineiro minera dentro")
	wa.definir(mina, 0)
	check(wa.estado(mina) == wa.ESTADO_SEM_MINEIRO, "ligada sem mineiro: %s" % wa.estado(mina))
	wa._sincroniza_carrinhos()
	check(cart.parado_por_area(), "sem mineiro o carrinho não anda")
	wa.definir(mina, 1)
	wa._sincroniza_carrinhos()
	var sem := 0
	for j in get_nodes_in_group("minerios"):
		if j.has_method("accepts_worker") and m and not wa.pode_usar(m, j.global_position, "minerios"):
			sem += 1
	check(sem > 0, "o mineiro da área não vai em jazida de fora (%d de fora)" % sem)


func _producao_comeca() -> void:
	print("== a produção acompanha a quantidade (rodando)")
	for w in ws():
		w.hunger = w.hunger_max
	check(madeira.quantos() == 5, "madeira 5/5 pra medir")
	Engine.time_scale = 4.0


func _mantem() -> void:
	for w in ws():
		if w.hunger < 60.0:
			w.hunger = w.hunger_max
	# quem está na área de madeira e cortando: a árvore é de dentro
	for w in madeira.vivos():
		var st = w.get("_station")
		if st != null and is_instance_valid(st) and st.is_in_group("arvores") and w.get_state() == "chopping" and not madeira.contem(st.global_position):
			check(false, "%s cortando árvore FORA da área" % w.display_name)


func _producao_confere() -> void:
	check(d5 > 0.0, "com 5 a área produziu (%.1f madeira em 30 s de jogo)" % d5)
	check(d5 > d2 * 1.4, "5 trabalhadores rendem mais que 2 (%.1f contra %.1f)" % [d5, d2])
	check(madeira.producao_min() > 0.0, "a janela mostra a produção por minuto (%.1f)" % madeira.producao_min())


func _salva() -> void:
	print("== salvar")
	wa.definir(madeira, 3)
	salvo = {"madeira": madeira.quantos(), "comida": comida.quantos(), "mina": mina.quantos() if mina else 0,
		"mina_ativa": mina.ativa if mina else false, "disp": wa.disponiveis().size(), "areas": wa.areas.size(),
		"total": int(madeira.total)}
	root.get_node("SaveManager").save_game("teste")
	var f := FileAccess.open(PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text()) if f else {}
	check(data is Dictionary and data.has("areas_trabalho"), "o save tem as áreas")
	var com_area := 0
	for wd in data.get("workers", []):
		if int(wd.get("area_id", 0)) > 0:
			com_area += 1
	check(com_area == salvo.madeira + salvo.comida + salvo.mina, "os ipezinhos guardam a área (%d)" % com_area)


func _carregado() -> void:
	print("== depois de carregar")
	wa = g("work_areas")
	check(wa != null and wa.areas.size() == salvo.areas, "as %d áreas voltaram" % salvo.areas)
	if wa == null or wa.areas.size() != salvo.areas:
		return
	var m2 = wa.areas.filter(func(a): return a.tipo == "madeira")[0]
	var c2 = wa.areas.filter(func(a): return a.tipo == "comida")[0]
	var k2 = wa.areas.filter(func(a): return a.tipo == "mina")
	check(m2.quantos() == salvo.madeira, "madeira %d/5 de volta" % m2.quantos())
	check(c2.quantos() == salvo.comida, "alimentos %d/5 de volta" % c2.quantos())
	check(not k2.is_empty() and k2[0].quantos() == salvo.mina and k2[0].ativa == salvo.mina_ativa, "a mina de volta (ligada, %d mineiro)" % (k2[0].quantos() if not k2.is_empty() else -1))
	check(wa.disponiveis().size() == salvo.disp, "disponíveis de volta (%d)" % wa.disponiveis().size())
	check(int(m2.total) >= salvo.total and m2.total < salvo.total + 60.0, "a produção total da área voltou (%d -> %d, cortando de novo)" % [salvo.total, int(m2.total)])
	check(m2.trabalhadores.all(func(w): return w.job == LUMBER and w.work_area == m2), "os da madeira continuam lenhadores dela")
	check(wa.definir(m2, 5) == mini(5, salvo.madeira + salvo.disp), "e dá pra mexer de novo depois de carregar")
