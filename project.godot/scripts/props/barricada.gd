extends Node2D
## Barricada (grupo "barricadas"): o muro no portão por onde as criaturas da floresta entram.
##   "tunel" — o portão da floresta na paliçada (Lumívoros). É o ÚNICO portão: o do poço do elevador
##             saiu no Bloco 80 (o que sobe do fundo entra direto; os guardas fazem posto lá).
## Níveis: 0 = só as estacas (não segura nada), 1 = paliçada de madeira, 2 = muro de
## pedra, 3 = portão de ferro. Tem vida: as criaturas param aqui e batem até quebrar.
## Os ipezinhos passam pelo portão normalmente. Conserto e ampliação: janela de Defesa (G).
## Bloco 98: ABRE de dia e FECHA ao anoitecer (hora_fecha / hora_abre, do DayNight), com a animação das folhas (frames
## aberto_N / meio_N / nivel_N no predios.json). Fechado, o portão tira as FAIXAS de passagem da malha de navegação
## (NavigationLink2D ligados e desligados: nada de refazer a malha) e só abre por regra: um guarda abre pra quem da vila
## espera junto do portão (sem guarda, depois de um tempo maior); criatura por perto = não abre. Derrubado ou sem muro
## (nível 0) = sempre aberto: a brecha continua abrindo o caminho.
## Bloco 96: subir de nível e o conserto GRANDE viram OBRA de engenheiro, com o material levado por ele (ObraSite);
## o muro sobe/fica inteiro quando a obra acaba. Conserto pequeno (até conserto_na_hora de madeira): na hora.

signal broken
signal repaired
## Bloco 98: a passagem abriu / fechou de verdade (as faixas ligaram / desligaram).
signal passagem_mudou(livre: bool)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 96
const LEVEL_NAMES := ["sem muro", "Paliçada de madeira", "Muro de pedra", "Portão de ferro"]

@export_enum("tunel") var gate_id: String = "tunel"
## Bloco 74: o portão numa paliçada de norte a sul (a vila fica a leste): a arte vira de lado.
@export var vertical := false
@export var display_name: String = "Portão do túnel"
## Vida por nível (índice = nível).
@export var hp_per_level: Array[float] = [0.0, 120.0, 260.0, 450.0]
## Ampliar pro nível i: x = créditos, y = minério, z = madeira. (índice 0 não usado)
## Bloco 94: o nível 3 baixou de 200 pra 170 ferro (85 barras) e pede pregos e ferragens (upgrade_itens).
@export var upgrade_costs: Array[Vector3i] = [Vector3i.ZERO, Vector3i(80, 0, 60), Vector3i(250, 120, 40), Vector3i(500, 170, 30)]
## Minério gasto em cada nível ("" = qualquer).
@export var upgrade_ore: Array[String] = ["", "", "ferro", "ferro"]
## Bloco 94: itens a mais de cada nível ({item: qtd}); antes da fornalha, pregos e ferragens viram ferro (Economy).
@export var upgrade_itens: Array[Dictionary] = [{}, {}, {}, {"prego": 12, "ferragem": 4}]
## Madeira gasta por ponto de vida consertado.
@export var repair_wood_per_hp: float = 0.25
## Bloco 96: segundos de engenheiro pra subir pro nível i (índice 0 não usado).
@export var upgrade_tempos: Array[float] = [0.0, 30.0, 45.0, 60.0]
## Bloco 96: conserto de até esta madeira é feito NA HORA (pequeno); acima, vira obra de engenheiro.
@export var conserto_na_hora: float = 10.0
## Bloco 96: segundos de engenheiro por unidade de madeira do conserto grande.
@export var conserto_segundos_por_madeira: float = 0.8

@export_group("Abrir e fechar (Bloco 98)")
## Hora do relógio (0-24) em que o portão de pé FECHA: o anoitecer, depois da hora de voltar (18:00 a 18:30).
@export_range(0.0, 24.0, 0.25) var hora_fecha: float = 18.5
## Hora do relógio (0-24) em que ele ABRE de novo: o amanhecer.
@export_range(0.0, 24.0, 0.25) var hora_abre: float = 5.0
## Segundos reais da animação de abrir ou fechar as folhas.
@export var anima_segundos: float = 1.2
## Segundos que o portão fica aberto quando um guarda abre pra quem espera.
@export var janela_segundos: float = 10.0
## Segundos que quem espera junto do portão fechado aguarda até um GUARDA abrir.
@export var guarda_demora: float = 3.0
## Segundos de espera até abrir quando NÃO tem guarda vivo na vila (alguém ouve a batida).
@export var sem_guarda_demora: float = 20.0
## Raio (px) em volta do portão onde quem espera é contado.
@export var alcance_espera: float = 90.0
## Criatura a menos que isso (px) do portão: não abre pra ninguém.
@export var alcance_criatura: float = 150.0
## Distância (px) da linha da paliçada onde quem espera fica, de cada lado.
@export var espera_afastamento: float = 30.0
## Espaço (px) entre quem espera, ao longo da paliçada.
@export var espera_espaco: float = 10.0
## Quantas faixas de passagem o portão tem (cada uma é um NavigationLink2D).
@export_range(1, 5) var faixas: int = 3
## Distância (px) entre as faixas.
@export var faixa_espaco: float = 14.0

var panel_id := "defesa"
var level: int = 0
var hp: float = 0.0
## Bloco 96: a obra em andamento ("" / "nivel" / "conserto"), o tempo dela e a peça comum de obra.
var obra_tipo := ""
var obra_total := 0.0
var obra_left := 0.0
var _obra := ObraSite.new()
## Bloco 98: 0 = fechado .. 1 = aberto (a animação das folhas), o que o portão quer agora (0 ou 1), os segundos que o
## guarda ainda deixa aberto, o tempo de quem espera, o relógio da vigia e as faixas na malha.
var abertura := 1.0
var _alvo := 1.0
var _janela := 0.0
var _espera_t := 0.0
var _vigia_t := 0.0
var _livre := true
var _snap := true  # no 1º quadro (e depois de carregar o save) vai direto pro estado certo, sem animar nem fazer barulho
var _faixas: Array[NavigationLink2D] = []
const VIGIA_INTERVALO := 0.25

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $StatusLabel
@onready var _bar: ProgressBar = $HpBar


func _ready() -> void:
	add_to_group("barricadas")
	add_to_group("clickable")
	_cria_faixas()
	_liga_faixas()
	_update_visual()


func _process(delta: float) -> void:
	_vigia_t -= delta
	if _vigia_t <= 0.0:
		_vigia_t = VIGIA_INTERVALO
		_vigia_espera(VIGIA_INTERVALO)
	var quer := _alvo_aberto()
	if not quer and _alvo > 0.5 and _alguem_no_vao():
		quer = true  # não fecha na cara de quem está passando
	var novo := 1.0 if quer else 0.0
	if _snap:  # (carregou de noite: já nasce fechado)
		_snap = false
		_alvo = novo
		abertura = novo
	elif novo != _alvo:
		_alvo = novo
		Audio.clank(global_position)
	abertura = move_toward(abertura, _alvo, delta / maxf(anima_segundos, 0.01))
	var livre := _alvo > 0.5 and abertura >= 0.55  # fechando, a passagem some na hora; abrindo, só com a folha aberta
	if livre != _livre:
		_livre = livre
		_liga_faixas()
		passagem_mudou.emit(livre)
		get_tree().call_group("ipezinhos", "portao_mudou")  # quem esperava vai; quem ia passar espera


func contains_point(p: Vector2) -> bool:
	if vertical:  # (a mesma caixa, de lado: a abertura corre de norte a sul)
		return Rect2(global_position + Vector2(-36, -38), Vector2(42, 76)).has_point(p)
	return Rect2(global_position + Vector2(-38, -36), Vector2(76, 42)).has_point(p)


## Bloco 74: pra que lado fica a vila (os guardas ficam desse lado do portão).
func inside_dir() -> Vector2:
	return Vector2.RIGHT if vertical else Vector2.DOWN


## Área onde a decoração do mapa é escondida (environment.gd).
func decor_clear_rect() -> Rect2:
	if vertical:
		return Rect2(global_position + Vector2(-30, -40), Vector2(36, 80))
	return Rect2(global_position + Vector2(-40, -30), Vector2(80, 36))


func max_hp() -> float:
	return hp_per_level[clampi(level, 0, hp_per_level.size() - 1)]


## Segura as criaturas agora?
func is_standing() -> bool:
	return level > 0 and hp > 0.0


func damage(amount: float) -> void:
	if not is_standing():
		return
	hp = maxf(hp - amount, 0.0)
	_visual.position.x = randf_range(-1.5, 1.5)
	create_tween().tween_property(_visual, "position:x", 0.0, 0.12)
	if hp <= 0.0:
		Audio.gate_break(global_position)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("%s foi derrubado! As criaturas estão entrando." % display_name, Color(1.0, 0.4, 0.35))
		broken.emit()
	_update_visual()


## Bloco 94: os itens a mais do próximo nível.
func upgrade_item_cost() -> Dictionary:
	var i := level + 1
	return upgrade_itens[i] if i < upgrade_itens.size() else {}


func upgrade_block_reason() -> String:
	if obra_tipo != "":
		return "em obra (%s)" % _obra.status(obra_progress())  # Bloco 96
	if level >= hp_per_level.size() - 1:
		return "nível máximo"
	var c := upgrade_costs[level + 1]
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.metal_falta(c.x, c.y, upgrade_ore[level + 1], c.z, upgrade_item_cost()) if eco else "sem recursos"  # Bloco 87: barra; 94: peças


func upgrade() -> bool:
	if upgrade_block_reason() != "":
		Audio.error()
		return false
	var c := upgrade_costs[level + 1]
	if not get_tree().get_first_node_in_group("economy").paga_metal(c.x, c.y, upgrade_ore[level + 1], c.z, upgrade_item_cost()):
		return false
	_comeca_obra("nivel", upgrade_tempos[level + 1] if level + 1 < upgrade_tempos.size() else 45.0)  # Bloco 96
	return true


## Bloco 96: o muro sobe quando a obra acaba.
func _sobe_nivel() -> void:
	level += 1
	hp = max_hp()  # muro novo, inteiro
	_visual.scale = Vector2(2.0, 1.4)
	create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.forge(global_position)
	_update_visual()


func repair_cost() -> int:
	return ceili((max_hp() - hp) * repair_wood_per_hp)


func repair_block_reason() -> String:
	if obra_tipo != "":
		return "em obra (%s)" % _obra.status(obra_progress())  # Bloco 96
	if level == 0:
		return "sem muro"
	if hp >= max_hp():
		return "inteiro"
	var eco := get_tree().get_first_node_in_group("economy")
	return eco.missing_text(0, 0, "", repair_cost()) if eco else "sem recursos"


func repair() -> bool:
	if repair_block_reason() != "":
		Audio.error()
		return false
	var madeira := repair_cost()
	if not get_tree().get_first_node_in_group("economy").spend(0, 0, "", madeira):
		return false
	if madeira > conserto_na_hora:  # Bloco 96: conserto grande = obra de engenheiro (a madeira vai nas costas)
		_comeca_obra("conserto", float(madeira) * conserto_segundos_por_madeira)
		return true
	_conserta()
	return true


func _conserta() -> void:
	hp = max_hp()
	Audio.forge(global_position)
	repaired.emit()
	_update_visual()


func _comeca_obra(tipo: String, segundos: float) -> void:
	obra_tipo = tipo
	obra_total = maxf(segundos, 1.0)
	obra_left = obra_total
	_obra.start()
	add_to_group("obras")
	_update_visual()


# ------------------------------------------------------------ abrir e fechar (Bloco 98)
## O ambiente chama pra saber se o portão passa pela malha por faixas (e deixa a paliçada inteira na malha).
func usa_faixas() -> bool:
	return true


## Quer estar aberto agora? Derrubado, sem muro ou brecha = sempre. Em pé: de dia; de noite, só com a janela do guarda.
func _alvo_aberto() -> bool:
	if not is_standing():
		return true
	var def := get_tree().get_first_node_in_group("defense")
	if def and def.breached(gate_id):
		return true  # a brecha abre o caminho
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn == null or not dn.entre_horas(hora_fecha, hora_abre):
		return true
	return _janela > 0.0


## A passagem está livre (as faixas ligadas)? Quem anda olha isto: fechada, espera junto do portão.
func passagem_livre() -> bool:
	return _livre


func fechado() -> bool:
	return not _livre


## De que lado da paliçada o ponto está: -1 = fora (floresta), +1 = dentro (vila).
func lado_de(p: Vector2) -> int:
	return 1 if (p - global_position).dot(inside_dir()) >= 0.0 else -1


## Esses dois pontos (na superfície) ficam em lados opostos de um portão FECHADO? (então o caminho precisa do portão)
func separa(a: Vector2, b: Vector2) -> bool:
	if _livre or lado_de(a) == lado_de(b):
		return false
	var env := get_tree().get_first_node_in_group("environment")
	return env == null or (env.level_at(a) == 0 and env.level_at(b) == 0)


## Onde quem vem de `de` espera o portão abrir: encostado na paliçada, do lado dele, cada um num lugar.
func espera_pos(quem: Node, de: Vector2) -> Vector2:
	var along := inside_dir()
	var perp := Vector2(along.y, along.x)
	var slot := float(int(quem.get_instance_id()) % 7 - 3) * espera_espaco
	return global_position + along * float(lado_de(de)) * espera_afastamento + perp * slot


## Quem da vila espera pra passar (foi mandado esperar aqui e está perto).
func _esperando() -> Array:
	var out: Array = []
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.get("_esperando_portao") == true and w.global_position.distance_to(global_position) <= alcance_espera:
			out.append(w)
	return out


func _criatura_perto() -> bool:
	for c in get_tree().get_nodes_in_group("criaturas"):
		if is_instance_valid(c) and not c.get("_dying") and c.global_position.distance_to(global_position) <= alcance_criatura:
			return true
	return false


## Tem guarda vivo (em pé) na vila pra abrir o portão?
func _tem_guarda() -> bool:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.is_guard() and not w.get("downed") and not w.get("injured"):
			return true
	return false


## Alguém (gente ou criatura) parado no vão: o portão não fecha em cima.
func _alguem_no_vao() -> bool:
	var along := inside_dir()
	var meia := float(faixas) * faixa_espaco * 0.5 + 6.0
	for grupo in ["ipezinhos", "criaturas"]:
		for n in get_tree().get_nodes_in_group(grupo):
			if not is_instance_valid(n):
				continue
			var d: Vector2 = n.global_position - global_position
			if absf(d.dot(along)) <= 16.0 and absf(d.dot(Vector2(along.y, along.x))) <= meia:
				return true
	return false


## A cada 0,25 s: a janela do guarda corre; quem espera com o portão fechado chama (um guarda abre, ou alguém ouve).
func _vigia_espera(dt: float) -> void:
	_janela = maxf(_janela - dt, 0.0)
	if _livre or _alvo_aberto() or _criatura_perto():
		_espera_t = 0.0
		return
	var espera := _esperando()
	if espera.is_empty():
		_espera_t = 0.0
		return
	_espera_t += dt
	var guarda := _tem_guarda()
	if _espera_t < (guarda_demora if guarda else sem_guarda_demora):
		return
	_espera_t = 0.0
	_janela = janela_segundos
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s abriu o portão pra %s." % ["Um guarda" if guarda else "Alguém", espera[0].display_name if espera.size() == 1 else "%d da vila" % espera.size()], Color(0.8, 0.85, 0.7))


## As faixas de passagem: uma ponta de cada lado da paliçada, ligadas à malha (portão fechado = desligadas).
func _cria_faixas() -> void:
	var env := get_tree().get_first_node_in_group("environment")
	var alcance: float = env.portao_faixa_alcance() if env and env.has_method("portao_faixa_alcance") else 14.0
	var along := inside_dir()
	var perp := Vector2(along.y, along.x)
	for i in faixas:
		var off := (float(i) - float(faixas - 1) * 0.5) * faixa_espaco
		var l := NavigationLink2D.new()
		l.name = "Faixa%d" % i
		l.bidirectional = true
		l.start_position = -along * alcance + perp * off
		l.end_position = along * alcance + perp * off
		add_child(l)
		_faixas.append(l)


func _liga_faixas() -> void:
	for l in _faixas:
		l.enabled = _livre


# ------------------------------------------------------------ obra (Bloco 96)
func obra_pending() -> bool:
	return obra_tipo != ""


func obra_title() -> String:
	return "%s: %s" % [display_name, LEVEL_NAMES[mini(level + 1, LEVEL_NAMES.size() - 1)] if obra_tipo == "nivel" else "conserto"]


func obra_progress() -> float:
	return clampf(1.0 - obra_left / obra_total, 0.0, 1.0) if obra_total > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return global_position + inside_dir() * 34.0 + _obra.offset_for(worker)


func obra_work(seconds: float) -> void:
	if obra_tipo == "":
		return
	obra_left -= seconds
	if obra_left > 0.0:
		return
	var tipo := obra_tipo
	_fim_obra()
	if tipo == "nivel":
		_sobe_nivel()
	else:
		_conserta()


func _fim_obra() -> void:
	obra_tipo = ""
	obra_total = 0.0
	obra_left = 0.0
	remove_from_group("obras")
	_update_visual()


## Cancelado: o muro fica como estava (créditos e material: ObraSite.cancelar).
func obra_cancelar() -> void:
	_fim_obra()


# ------------------------------------------------------------ obra (Bloco 96: conserto por engenheiro, com material)
func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()



func _update_visual() -> void:
	_visual.frame = level if is_standing() else 0
	_visual.modulate = Color.WHITE if is_standing() or level == 0 else Color(0.7, 0.6, 0.55)
	_bar.visible = level > 0 and hp < max_hp()
	_bar.max_value = maxf(max_hp(), 1.0)
	_bar.value = hp
	if level == 0:
		_label.text = "%s\n(sem muro)" % display_name
		_label.modulate = Color(0.8, 0.75, 0.7, 0.8)
	elif hp <= 0.0:
		_label.text = "%s\nDERRUBADO" % display_name
		_label.modulate = Color(1.0, 0.45, 0.4)
	else:
		_label.text = display_name
		_label.modulate = Color(0.9, 0.85, 0.75, 0.85)


# ------------------------------------------------------------ save/load (SaveManager, pelo nome do nó)
func get_save_data() -> Dictionary:
	return {"level": level, "hp": hp, "obra_tipo": obra_tipo, "obra_total": obra_total, "obra_left": obra_left,
		"obra": _obra.get_save_data()}


## Bloco 96: save antigo = sem obra (as ampliações eram na hora).
func load_save_data(d: Dictionary) -> void:
	level = clampi(SaveUtil.integer(d, "level", 0), 0, hp_per_level.size() - 1)
	hp = clampf(SaveUtil.num(d, "hp", max_hp()), 0.0, max_hp())
	var t := SaveUtil.text(d, "obra_tipo", "")
	obra_tipo = t if t in ["nivel", "conserto"] and not (t == "nivel" and level >= hp_per_level.size() - 1) else ""
	obra_total = maxf(SaveUtil.num(d, "obra_total", 0.0), 1.0) if obra_tipo != "" else 0.0
	obra_left = clampf(SaveUtil.num(d, "obra_left", obra_total), 0.0, obra_total) if obra_tipo != "" else 0.0
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
	_snap = true  # Bloco 98: o relógio carregado decide se está aberto ou fechado, sem animar
	if obra_tipo != "":
		add_to_group("obras")
	elif is_in_group("obras"):
		remove_from_group("obras")
	_update_visual()
