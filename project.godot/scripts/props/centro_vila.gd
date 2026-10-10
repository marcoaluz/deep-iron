extends "res://scripts/props/station.gd"
## Centro da Vila: hub de progressão (grupo "village_hub").
##
## - Mostra o progresso geral (população, minério coletado no total, estágio).
## - "Expandir a vila": sobe o estágio (1 a 5). Precisa de um marco de minério
##   coletado no total (tudo que já entrou nos armazéns, mesmo o que foi vendido)
##   e custa créditos.
##   Bloco 33 — o que EXPANDIR faz (e o que NÃO faz):
##     * NÃO muda o tamanho do mapa: a mina (map_rect do environment) é fixa.
##     * Abre uma GALERIA LACRADA dentro da mina de sempre (nível 1): uma jazida atrás
##       de entulho (mineral_node: min_village_level). 2 Vilarejo = ferro (oeste),
##       3 Vila = cobre (sudeste), 4 Vila Mineira = carvão (norte), 5 Cidade Mineira =
##       veio rico de ferro (nordeste). Cobre e carvão ainda pedem a ferramenta da Oficina.
##     * Continua liberando o que pede "vila nível N" (melhorias, peças da Escavadeira,
##       ferramentas, laboratório, escudo, conserto do abismo).
##     * Os NÍVEIS DE PROFUNDIDADE são outra coisa e não mudaram: o nível 2 abre com a
##       Escavadeira pronta (elevador) e o abismo com o conserto da plataforma.
## - Melhorias compradas com créditos + minério do armazém. Cada melhoria só pode
##   ter no máximo tantos níveis quanto o estágio atual da vila.
##     Moradias:         +workers_per_moradia no limite de ipezinhos e uma casa
##                       nova (4 camas) que o JOGADOR posiciona no mapa (HousePlacer).
##                       O custo só é pago quando ele confirma o lugar; Esc cancela.
##     Enfermaria:       +1 leito na Enfermaria e -recovery_cut_per_level no tempo de cura (por nível).
##     Trilhas batidas:  Bloco 89 — aumenta o BÔNUS DOS CAMINHOS (+trilhas_bonus_por_nivel do bônus por nível);
##                       não acelera mais todo mundo.
##
## Bloco 31: comprar uma melhoria (ou uma casa) paga na hora e ENCOMENDA a obra —
## ela só anda com um engenheiro trabalhando (melhoria: aqui na frente do Centro;
## casa: no canteiro). Uma melhoria da vila por vez; casas, quantas quiser.
## O +limite de ipezinhos da casa só entra quando ela fica pronta (on_house_built).
##
## Os ipezinhos consultam recovery_mult() e speed_mult(); a economia guarda o limite.
## Ninguém trabalha aqui (sem slots): é só a base que bloqueia a navegação.
##
## Bloco 37 — FUNDAÇÃO e RAIO DAS CASAS:
##   - Partida nova começa com a fundação (founding.gd): o jogador escolhe onde fica o
##     Centro da Vila e depois o Armazém (na hora, sem custo). Aí ganha o pacote inicial
##     (founding_*): dá pra 3 CASAS INICIAIS + 1 COMEDOURO, construídos pelo engenheiro.
##   - Casas iniciais (starter_houses): não gastam nível de Moradias nem somam no limite
##     de ipezinhos (o limite inicial, 8, já conta com elas — eram as 3 casas prontas da
##     cena). Depois delas, casa nova é a melhoria Moradias, como antes.
##   - Casa (inicial ou Moradias) só pode ser posicionada até house_radius() do Centro.
##     (Prompt 29: raio desligado por padrão — casa em qualquer lugar da pedreira.)
##     ESCOLHA: o raio cresce a cada ESTÁGIO da vila (Expandir) — Moradias já é a própria
##     casa, e "a vila cresceu" é o que o estágio mede. O mapa continua do mesmo tamanho.
##     Casas que já existem (saves antigos) não são checadas: a regra é só pra posicionar.
##   - Comedouro: dá pra construir mais (build_comedouro), um canteiro por vez.
##   - Save antigo (sem "layout"): tudo fica onde a cena põe, como antes.
##
## Bloco 38 — o PRÉDIO cresce com a vila (puramente visual): um quadro por estágio
## (barraca -> cabana -> salão -> salão com alas -> cidade com torre alta; gen_sprites:
## build_centro_vila). Enquanto a expansão está em obra, o próximo estágio aparece por
## cima como fantasma que fica nítido com o progresso (mesma cor do canteiro); ao
## terminar ele "assenta" (fica sólido) e troca de quadro sem pulo. Carregar o save
## mostra direto o quadro do estágio salvo (e o fantasma, se a expansão estava em obra).

## Bloco 100: uma obra do tipo `tipo` ficou pronta (o tipo do canteiro: "taverna", "comedouro"...; "casa" pras casas).
## Só AVISA (as missões contam): não muda nada de ninguém.
signal obra_pronta(tipo: String)
signal level_changed(level: int)
signal upgrade_bought(id: String, new_level: int)

const SocialSpot := preload("res://scripts/props/social_spot.gd")  # Bloco 85
const SaveUtil := preload("res://scripts/core/save_util.gd")
const ObraSite := preload("res://scripts/core/obra_site.gd")
const ObraEstagio := preload("res://scripts/core/obra_estagio.gd")
const Ores := preload("res://scripts/core/ores.gd")
const STAGE_NAMES := ["Acampamento", "Vilarejo", "Vila", "Vila Mineira", "Cidade Mineira"]
const UPGRADE_IDS := ["moradias", "enfermaria", "trilhas", "posto"]  # (Bloco 104: o Posto de expedição)
const CASA_SCENE := preload("res://scenes/props/casa.tscn")
const COMEDOURO_SCENE := preload("res://scenes/props/comedouro.tscn")
const COMEDOURO_TEXTURE := preload("res://assets/game/comedouro.png")
const CASA_TEXTURE := preload("res://assets/game/casa.png")
const Canteiro := preload("res://scripts/props/canteiro.gd")
## Pegadas (em volta do pé do prédio) pro posicionador.
const HOUSE_FOOTPRINT := Rect2(-32, -54, 64, 78)
## Bloco 38, por estágio (quadro 0..4): topo do desenho e meia-largura (px do mundo),
## luz das janelas/fogueira (x, y, energia) e tamanho do brilho.
const STAGE_TOP := [-58.0, -70.0, -100.0, -100.0, -152.0]
const STAGE_HALF_W := [60.0, 60.0, 58.0, 86.0, 90.0]
const STAGE_LIGHT := [Vector3(30, -14, 0.6), Vector3(0, -26, 0.75), Vector3(0, -34, 0.9), Vector3(0, -34, 1.05), Vector3(0, -50, 1.25)]
const STAGE_LIGHT_SCALE := [0.7, 0.85, 1.1, 1.35, 1.6]
const COMEDOURO_FOOTPRINT := Rect2(-44, -40, 88, 60)
## Bloco 45: coletor de madeira (serraria na clareira).
const COLETOR_SCENE := preload("res://scenes/props/coletor_madeira.tscn")
const COLETOR_TEXTURE := preload("res://assets/game/coletor_madeira.png")
## Bloco 57: coletor de minério (broca perto de uma jazida).
const COLETOR_MIN_SCENE := preload("res://scenes/props/coletor_minerio.tscn")
const COLETOR_MIN_TEXTURE := preload("res://assets/game/coletor_minerio.png")
## Bloco 64: ponto de carga do vagonete (trilho até o armazém).
const VAGONETE_SCENE := preload("res://scenes/props/estacao_vagonete.tscn")
const COLETOR_FOOTPRINT := Rect2(-52, -78, 104, 90)
## Bloco 47: enfermaria extra (a principal vem com a vila).
const ENFERMARIA_SCENE := preload("res://scenes/props/enfermaria.tscn")
const ENFERMARIA_TEXTURE := preload("res://assets/game/enfermaria.png")
const Tipo := preload("res://scripts/ui/tipografia.gd")
const ENFERMARIA_FOOTPRINT := Rect2(-40, -64, 80, 84)
const UPGRADE_NAMES := {
	"moradias": "Moradias",
	"enfermaria": "Enfermaria",
	"trilhas": "Trilhas batidas",
	"posto": "Posto de expedição",  # Bloco 104
}

@export_group("Estágios da vila")
## Minério coletado no total pra chegar em cada estágio (índice 0 = estágio 1). Bloco 106: era [0, 375, 1250, 3100,
## 6250], feito pro ritmo antigo (4 mineradores davam o estágio 2 em ~2 h de jogo); com o ritmo novo da mineração
## (~0,19x por mineiro) ficou ~0,52x, pro estágio 2 sair perto do 2º dia com a abertura padrão.
@export var level_ore_required: Array[int] = [0, 200, 650, 1600, 3200]
## Créditos pra expandir pra cada estágio (índice 0 = estágio 1, não usado).
@export var level_credit_cost: Array[int] = [0, 190, 625, 1500, 3100]

@export_group("Melhoria: Moradias")
## Custo de cada nível: x = créditos, y = minério do armazém.
## Casa = créditos (x) + PEDRA (y). "Pedra" = minério de ferro (Bloco 13: o jogo não tem
## um recurso pedra separado; o ferro é a rocha que a mina já dá).
@export var moradias_costs: Array[Vector2i] = [Vector2i(190, 40), Vector2i(375, 60), Vector2i(750, 150), Vector2i(1250, 310)]
## Madeira de cada casa (por nível de Moradias).
@export var moradias_wood: Array[int] = [20, 30, 45, 60]
## Minério usado como "pedra" nas casas.
@export var house_stone_ore: String = "ferro"
@export var workers_per_moradia: int = 4

@export_group("Melhoria: Enfermaria")
@export var enfermaria_costs: Array[Vector2i] = [Vector2i(125, 25), Vector2i(310, 75), Vector2i(625, 190)]
## Fração do tempo de cura cortada por nível (0.2 = -20% por nível).
@export_range(0.0, 0.3) var recovery_cut_per_level: float = 0.2

@export_group("Melhoria: Trilhas batidas")
@export var trilhas_costs: Array[Vector2i] = [Vector2i(150, 25), Vector2i(375, 100), Vector2i(810, 250)]
## (Antes do Bloco 89: velocidade extra pra todo mundo por nível. Não é mais usado; fica pro save/inspector.)
@export var speed_bonus_per_level: float = 0.1
## Bloco 89: quanto cada nível de Trilhas aumenta o bônus de velocidade dos CAMINHOS (0.5 = +50% do bônus).
@export var trilhas_bonus_por_nivel: float = 0.5

@export_group("Obras (Bloco 31)")
## Segundos de trabalho de engenheiro pra cada nível de cada melhoria.
@export var enfermaria_build_times: Array[float] = [30.0, 45.0, 60.0]
@export var trilhas_build_times: Array[float] = [25.0, 40.0, 55.0]
## Bloco 104: o Posto de expedição (créditos, ferro; um nível): libera mais uma expedição ao mesmo tempo.
@export var posto_costs: Array[Vector2i] = [Vector2i(500, 80)]
@export var posto_build_times: Array[float] = [60.0]
## Estágio da vila que libera o Posto.
@export var posto_estagio: int = 3
## Segundos de trabalho de engenheiro pra erguer cada casa (por nível de Moradias).
@export var house_build_times: Array[float] = [35.0, 45.0, 55.0, 65.0]
## Bloco 31b: segundos de engenheiro pra EXPANDIR a vila (estágio 2, 3, 4, 5).
@export var expand_build_times: Array[float] = [60.0, 90.0, 120.0, 150.0]

@export_group("Fundação (Bloco 37)")
## Casas iniciais da partida nova (fora das Moradias; não somam no limite de ipezinhos).
@export var starter_houses: int = 3
## Custo de cada casa inicial: x = créditos, y = pedra (ferro), z = madeira.
@export var starter_house_cost: Vector3i = Vector3i(80, 20, 15)
@export var starter_house_build_time: float = 25.0
## Comedouro novo: x = créditos, y = ferro, z = madeira; e segundos de engenheiro.
@export var comedouro_cost: Vector3i = Vector3i(100, 20, 25)
@export var comedouro_build_time: float = 20.0
## Pacote que entra quando a vila é fundada (dá pras 3 casas + 1 comedouro, com folga).
@export var founding_credits: int = 460  # Bloco 107: + a horta (60 cr e 30 de madeira: ela já não vem pronta na clareira)
@export var founding_ore: int = 90
@export var founding_wood: int = 110

@export_group("Coletor de madeira (Bloco 45)")
## Construir: créditos e ferro (não gasta madeira: é ele que faz madeira); segundos de engenheiro.
@export var coletor_credits: int = 250
@export var coletor_ore: int = 60
@export var coletor_build_time: float = 40.0
@export_group("Igreja (Bloco 88)")
## Construir a igreja (uma por vila): créditos, pedra (ferro) e madeira; segundos de engenheiro.
@export var igreja_credits: int = 220
@export var igreja_ore: int = 40
@export var igreja_wood: int = 80
@export var igreja_build_time: float = 50.0
## Estágio mínimo da vila pra construir.
@export_range(1, 5) var igreja_estagio: int = 2
@export_group("Cemitério (Bloco 93)")
## O jogador marca o tamanho: o custo é por VAGA (túmulo) e por TRECHO de cerca (24 px); a obra também.
@export var cemiterio_credits_base: int = 40
@export var cemiterio_credits_por_vaga: int = 6
@export var cemiterio_wood_por_trecho: int = 3
@export var cemiterio_ore_por_trecho: int = 1
@export var cemiterio_segundos_base: float = 12.0
@export var cemiterio_segundos_por_trecho: float = 1.2
## Tamanho em trechos de cerca (mínimo 3 x 2 sempre; máximo aqui).
@export var cemiterio_max_trechos: Vector2i = Vector2i(10, 8)
## Estágio mínimo da vila.
@export_range(1, 5) var cemiterio_estagio: int = 2
@export_group("Fornalha (Bloco 86)")
## Construir a fornalha: SÓ créditos e minério (madeira nenhuma: não trava o começo); segundos de engenheiro.
@export var fornalha_credits: int = 180
@export var fornalha_ore: int = 50
@export var fornalha_build_time: float = 35.0
## Estágio da vila em que a fornalha libera (2 = Vilarejo).
@export_range(1, 5) var fornalha_estagio: int = 2
@export_group("Carpintaria (Bloco 94)")
## Construir a carpintaria: créditos, ferro e madeira; segundos de engenheiro (obra em etapas).
@export var carpintaria_credits: int = 220
@export var carpintaria_ore: int = 40
@export var carpintaria_wood: int = 90
@export var carpintaria_build_time: float = 45.0
## Estágio da vila em que a carpintaria libera (2 = Vilarejo: os pregos vêm do ferreiro, que vem com a fornalha).
@export_range(1, 5) var carpintaria_estagio: int = 2
@export_group("Horta, estufa, carvoaria e curtume (Bloco 107)")
## HORTA (construída dentro da vila; a da clareira some na partida nova): créditos, madeira, segundos de engenheiro e o
## estágio da vila (1 = já). Cabem `horta_max`; as próximas custam mais (extra_building_cost_growth).
@export var horta_credits: int = 60
@export var horta_wood: int = 30
@export var horta_build_time: float = 20.0
@export_range(1, 5) var horta_estagio: int = 1
@export var horta_max: int = 3
## ESTUFA (horta coberta; no inverno rende mais que a horta aberta): créditos, ferro, madeira, pregos, segundos, estágio.
@export var estufa_credits: int = 220
@export var estufa_ore: int = 50
@export var estufa_wood: int = 90
@export var estufa_pregos: int = 20
@export var estufa_build_time: float = 60.0
@export_range(1, 5) var estufa_estagio: int = 2
@export var estufa_max: int = 2
## CARVOARIA (madeira vira carvão vegetal, operada pelo lenhador).
@export var carvoaria_credits: int = 150
@export var carvoaria_ore: int = 30
@export var carvoaria_wood: int = 60
@export var carvoaria_build_time: float = 35.0
@export_range(1, 5) var carvoaria_estagio: int = 2
## CURTUME (couro vira couro curtido, operado pelo caçador).
@export var curtume_credits: int = 160
@export var curtume_ore: int = 40
@export var curtume_wood: int = 60
@export var curtume_pregos: int = 15
@export var curtume_build_time: float = 40.0
@export_range(1, 5) var curtume_estagio: int = 2

@export_group("Escola (Bloco 111)")
## ESCOLA (dentro da vila; as crianças estudam e se animam; sem professor): créditos, ferro, madeira, pregos, segundos de
## engenheiro, estágio da vila e o máximo.
@export var escola_credits: int = 140
@export var escola_ore: int = 20
@export var escola_wood: int = 80
@export var escola_pregos: int = 10
@export var escola_build_time: float = 45.0
@export_range(1, 5) var escola_estagio: int = 2
@export var escola_max: int = 2
## Bloco 97: o ARMAZÉM NOVO (construção nova; o jogador escolhe o lugar). Custo do primeiro, em créditos
## (os próximos crescem, como as outras construções repetíveis).
@export var armazem_credits: int = 300
## Armazém novo: minério de ferro (unidades; como a Carpintaria).
@export var armazem_ore: int = 80
## Armazém novo: madeira (unidades).
@export var armazem_wood: int = 120
## Armazém novo: segundos de engenheiro na obra.
@export var armazem_build_time: float = 50.0
## Armazém novo: estágio da vila em que libera (o Marco: "só desbloqueia nível 2 da vila").
@export_range(1, 5) var armazem_estagio: int = 2
@export_group("Oficina (Bloco 58)")
@export var oficina_credits: int = 200
@export var oficina_ore: int = 40
@export var oficina_wood: int = 60
@export var oficina_build_time: float = 40.0
@export_group("Desbravar o leste (Bloco 67)")
@export var leste_credits: int = 900
@export var leste_ore: int = 120
@export var leste_wood: int = 160
@export var leste_build_time: float = 80.0
@export var leste_min_stage: int = 2
@export_group("Trilho e vagonete (Bloco 64)")
@export var vagonete_credits: int = 260
@export var vagonete_ore: int = 80
@export var vagonete_wood: int = 80
@export var vagonete_build_time: float = 50.0
@export_group("Ferrovia de carga (Bloco 79)")
## Custo da estação de cada andar: base + por andar de profundidade (créditos, ferro, madeira, segundos de obra).
## Bloco 94: o ferro vira barra a partir do estágio da fornalha (Economy.metal) e a estação pede pregos e
## ferragens (os dormentes e as talas dos trilhos): o ferro baixou pra compensar.
@export var ferrovia_base := Vector4i(300, 40, 100, 60)
@export var ferrovia_por_andar := Vector4i(150, 25, 20, 15)
## Pregos e ferragens da estação: base + por andar de profundidade (x = pregos, y = ferragens).
@export var ferrovia_pecas_base := Vector2i(18, 0)
@export var ferrovia_pecas_por_andar := Vector2i(6, 1)
@export_group("Coletor de minério (Bloco 57)")
@export var coletor_min_credits: int = 280
@export var coletor_min_ore: int = 40
@export var coletor_min_wood: int = 60
@export var coletor_min_build_time: float = 45.0

@export_group("Enfermaria extra (Bloco 47)")
## Custo da 1ª enfermaria extra (a da vila é de graça); as seguintes crescem com
## Economy.extra_building_cost_growth. Segundos de engenheiro pra erguer.
@export var enfermaria_extra_credits: int = 200
@export var enfermaria_extra_ore: int = 40
@export var enfermaria_extra_wood: int = 60
@export var enfermaria_extra_build_time: float = 45.0

@export_group("Raio das casas (Bloco 37)")
## Casa só pode ser posicionada até essa distância do Centro da Vila no estágio 1...
@export var house_radius_base: float = 230.0
## ...e o raio cresce isso a cada estágio da vila.
@export var house_radius_per_stage: float = 70.0
## false = sem limite (casa em qualquer lugar livre da mina).
## Prompt 29 (decisão do Marco, 2026-10-01): DESLIGADO — casa em qualquer lugar da pedreira (o
## lado da vila da paliçada), não precisa ficar perto do Centro. O parque também (usa o mesmo raio).
@export var house_radius_enabled: bool = false

## Pro HUD saber qual janela abrir quando clicam aqui.
var panel_id := "hub"
## Melhoria da vila encomendada e ainda em obra ("" = nenhuma).
var pending_upgrade: String = ""
var upgrade_left: float = 0.0
var upgrade_total: float = 0.0
var _obra := ObraSite.new()
var level: int = 1
var upgrades: Dictionary = {"moradias": 0, "enfermaria": 0, "trilhas": 0, "posto": 0}
## Bloco 37: a vila já foi fundada? (false só durante a fundação da partida nova)
var founded: bool = true
## Casas iniciais que ainda dá pra encomendar (partida nova começa com starter_houses).
var starter_houses_left: int = 0

@onready var _visual: Sprite2D = $Visual
@onready var _name_label: Label = $NameLabel
@onready var _next_stage: Sprite2D = $NextStage
@onready var _window_light: PointLight2D = $WindowLight
@onready var _shadow: Sprite2D = $Shadow
## A troca de quadro pro estágio novo está acontecendo (Bloco 38).
var _growing := false


func _ready() -> void:
	super()
	add_to_group("village_hub")
	add_child(SocialSpot.criar("praca", "Praça", false, 3, 3, Vector2(0, 34)))  # Bloco 85
	add_to_group("obras")
	add_to_group("clickable")
	$WindowLight.add_to_group("cullable_lights")
	_update_visual()


## Área clicável do prédio (coordenadas globais).
func contains_point(p: Vector2) -> bool:
	var i := _stage_index()
	var hw: float = STAGE_HALF_W[i]
	return Rect2(global_position + Vector2(-hw, STAGE_TOP[i]), Vector2(hw * 2.0, -STAGE_TOP[i] + 4.0)).has_point(p)


## Pro ambiente não espalhar pedras/tochas em cima do prédio.
func get_clear_center() -> Vector2:
	return global_position + Vector2(0, -45)


func get_clear_radius() -> float:
	return 85.0


## Área onde a decoração some quando o Centro é posicionado (Bloco 37) — já do tamanho
## do maior estágio (Bloco 38), pra nenhuma pedra aparecer "dentro" do prédio quando ele crescer.
func decor_clear_rect() -> Rect2:
	return Rect2(global_position + Vector2(-92, -154), Vector2(184, 166))


# ------------------------------------------------------------ efeitos (consultados pelos ipezinhos)
func recovery_mult() -> float:
	return maxf(0.1, 1.0 - recovery_cut_per_level * upgrades.enfermaria)


## Bloco 89: a velocidade não sobe mais pra todo mundo (fica 1.0); quem acelera é o caminho (caminhos.gd).
func speed_mult() -> float:
	return 1.0


## Bloco 89: o bônus dos caminhos é multiplicado por isto (Trilhas batidas).
func trilhas_bonus_mult() -> float:
	return 1.0 + trilhas_bonus_por_nivel * upgrades.trilhas


# ------------------------------------------------------------ progresso
func stage_name(lvl: int = level) -> String:
	return STAGE_NAMES[clampi(lvl, 1, STAGE_NAMES.size()) - 1]


func max_level() -> int:
	return STAGE_NAMES.size()


## Minério que já entrou nos armazéns desde o começo do jogo (inclui o vendido).
func lifetime_ore() -> float:
	var total := 0.0
	for a in get_tree().get_nodes_in_group("armazens"):
		total += a.lifetime_stored
	return total


func next_level_ore() -> int:
	return level_ore_required[level] if level < max_level() else 0


func next_level_cost() -> int:
	return level_credit_cost[level] if level < max_level() else 0


func can_level_up() -> bool:
	var eco := _economy()
	return level < max_level() and eco != null and pending_upgrade == "" \
		and lifetime_ore() >= next_level_ore() and eco.credits >= next_level_cost()


func level_up() -> bool:
	if not can_level_up():
		Audio.error()
		return false
	_economy().spend(next_level_cost(), 0)
	# Bloco 31b: pagou -> vira obra (uma obra da vila por vez, como as melhorias)
	pending_upgrade = "expandir"
	upgrade_total = build_time("expandir")
	upgrade_left = upgrade_total
	_obra.start()
	_update_visual()
	_popup("Expansão encomendada — precisa de engenheiro", Color(1.0, 0.8, 0.45))
	Audio.click()
	return true


func _finish_expansion() -> void:
	pending_upgrade = ""
	upgrade_left = 0.0
	upgrade_total = 0.0
	level += 1
	_grow_to_stage(_stage_index())  # Bloco 38: o fantasma assenta e vira o prédio novo
	_update_visual()
	_popup("A vila agora é: %s!" % stage_name(), Color(1.0, 0.85, 0.4))
	Audio.stinger("estagio_novo")  # Bloco 114 (sem arquivo: a fanfarra)
	_refresh_galleries(true)
	var opened := galleries_for_level(level)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and not opened.is_empty():
		var names: Array[String] = []
		for m in opened:
			names.append(_gallery_text(m))
		hud.show_banner("A VILA AGORA É: %s" % stage_name().to_upper(),
			"Galeria aberta dentro da mina: %s." % ", ".join(names))
	level_changed.emit(level)


# ------------------------------------------------------------ galerias lacradas (Bloco 33)
## Jazidas que abrem quando a vila chega nesse estágio.
func galleries_for_level(lvl: int) -> Array:
	return get_tree().get_nodes_in_group("minerios").filter(
		func(m): return m.get("min_village_level") == lvl)


## "galeria oeste (ferro)" (+ a ferramenta que ainda falta, se faltar).
func _gallery_text(m: Node) -> String:
	var t := "galeria %s (%s)" % [m.gallery_name, Ores.display_name(m.ore_type).to_lower()]
	var oficina := get_tree().get_first_node_in_group("oficina")
	if oficina and not oficina.is_ore_unlocked(m.ore_type):
		t += " — precisa de %s" % oficina.TOOL_NAMES[oficina.tool_for_ore(m.ore_type)]
	return t


## O que o estágio `lvl` libera (pro painel da vila).
func stage_unlocks_text(lvl: int) -> String:
	var parts: Array[String] = []
	for m in galleries_for_level(lvl):
		parts.append(_gallery_text(m))
	parts.append("melhorias até o nível %d" % lvl)
	var pol := get_tree().get_first_node_in_group("politicas")
	if pol and int(pol.estagio_minimo) == lvl:
		parts.append("Políticas da Vila (%s)" % preload("res://scripts/core/teclas.gd").nome("painel_politicas"))  # Bloco 108
	return ", ".join(parts)


func _refresh_galleries(animate: bool) -> void:
	for m in get_tree().get_nodes_in_group("minerios"):
		if m.has_method("on_unlock_changed"):
			m.on_unlock_changed(animate)


# ------------------------------------------------------------ melhorias
func upgrade_costs(id: String) -> Array[Vector2i]:
	match id:
		"moradias":
			return moradias_costs
		"enfermaria":
			return enfermaria_costs
		"trilhas":
			return trilhas_costs
		"posto":
			return posto_costs
	return []


func upgrade_max(id: String) -> int:
	return upgrade_costs(id).size()


## Custo do próximo nível (Vector2i(-1, -1) se já está no máximo).
func upgrade_cost(id: String) -> Vector2i:
	var lvl: int = upgrades[id]
	var costs := upgrade_costs(id)
	return costs[lvl] if lvl < costs.size() else Vector2i(-1, -1)


## "" se pode comprar; senão o motivo (pra mostrar no botão).
func upgrade_block_reason(id: String) -> String:
	if pending_upgrade == id:
		return "em obra"
	if pending_upgrade != "" and id != "moradias":
		return "outra melhoria em obra"
	var lvl: int = upgrades[id]
	if lvl >= upgrade_max(id):
		return "nível máximo"
	if id == "posto" and level < posto_estagio:
		return "requer vila nível %d" % posto_estagio  # Bloco 104
	if lvl >= level:
		return "requer vila nível %d" % (lvl + 1)
	var cost := upgrade_cost(id)
	var eco := _economy()
	if eco == null:
		return "sem recursos"
	var missing: String = eco.missing_text(cost.x, cost.y, upgrade_ore_type(id), upgrade_wood(id), upgrade_ore_label(id))
	return missing


## Madeira do próximo nível (só as casas usam).
func upgrade_wood(id: String) -> int:
	if id != "moradias":
		return 0
	var lvl: int = upgrades[id]
	return moradias_wood[lvl] if lvl < moradias_wood.size() else 0


## Tipo de minério gasto ("" = qualquer, o mais barato primeiro). Casas usam ferro como pedra.
func upgrade_ore_type(id: String) -> String:
	return house_stone_ore if id == "moradias" else ""


func upgrade_ore_label(id: String) -> String:
	return "pedra (%s)" % house_stone_ore if id == "moradias" else "minério"


func buy_upgrade(id: String) -> bool:
	if upgrade_block_reason(id) != "":
		Audio.error()
		return false
	if id == "moradias":
		return _start_house_placement()  # paga só ao confirmar o lugar
	var cost := upgrade_cost(id)
	if not _economy().spend(cost.x, cost.y):
		return false
	# Bloco 31: pagou -> vira obra; o nível só sobe quando o engenheiro terminar
	pending_upgrade = id
	upgrade_total = build_time(id)
	upgrade_left = upgrade_total
	_obra.start()
	_update_visual()
	_popup("Encomendado: %s %d — precisa de engenheiro" % [UPGRADE_NAMES[id], upgrades[id] + 1], Color(1.0, 0.8, 0.45))
	Audio.click()
	return true


## Segundos de engenheiro pro PRÓXIMO nível dessa melhoria.
func build_time(id: String) -> float:
	if id == "expandir":
		return expand_build_times[clampi(level - 1, 0, expand_build_times.size() - 1)] if not expand_build_times.is_empty() else 60.0
	var lvl: int = upgrades[id]
	var times: Array[float] = house_build_times
	if id == "enfermaria":
		times = enfermaria_build_times
	elif id == "trilhas":
		times = trilhas_build_times
	elif id == "posto":
		times = posto_build_times
	return times[mini(lvl, times.size() - 1)] if not times.is_empty() else 30.0


func _finish_upgrade() -> void:
	if pending_upgrade == "expandir":
		_finish_expansion()
		return
	var id := pending_upgrade
	pending_upgrade = ""
	upgrade_left = 0.0
	upgrade_total = 0.0
	upgrades[id] += 1
	_apply_upgrade(id)
	_update_visual()
	_popup("%s %d pronta!" % [UPGRADE_NAMES[id], upgrades[id]], Color(0.55, 1.0, 0.5))
	Audio.recruit()
	upgrade_bought.emit(id, upgrades[id])


# ------------------------------------------------------------ obra (Bloco 31)
func obra_pending() -> bool:
	return pending_upgrade != ""


func obra_title() -> String:
	if pending_upgrade == "expandir":
		return "Expandir vila → %s" % stage_name(level + 1)
	return "%s %d" % [UPGRADE_NAMES.get(pending_upgrade, "melhoria"), upgrades.get(pending_upgrade, 0) + 1]


func obra_progress() -> float:
	return clampf(1.0 - upgrade_left / upgrade_total, 0.0, 1.0) if upgrade_total > 0.0 else 0.0


func obra_position(worker: Node) -> Vector2:
	return IsoArt.front(self, Vector2(0, 40)) + _obra.offset_for(worker)


## O engenheiro trabalhou `seconds` na melhoria: só assim ela anda.
func obra_work(seconds: float) -> void:
	if pending_upgrade == "":
		return
	upgrade_left -= seconds
	if upgrade_left <= 0.0:
		_finish_upgrade()
	else:
		_update_visual()  # (o fantasma do próximo estágio acompanha o progresso)


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)
	_update_visual()


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)
	_update_visual()


func obra_workers() -> Array[Node]:
	return _obra.workers()


## Bloco 96: cancelada (melhoria ou expansão): nada sobe (ObraSite.cancelar já devolveu créditos e material).
func obra_cancelar() -> void:
	pending_upgrade = ""
	upgrade_left = 0.0
	upgrade_total = 0.0
	_update_visual()


## "Trilhas batidas 2: 40% — esperando engenheiro" (pra UI).
func obra_status() -> String:
	return "%s: %s" % [obra_title(), _obra.status(obra_progress())] if obra_pending() else ""


## Texto do efeito atual e do próximo nível (pra UI).
func upgrade_effect_text(id: String, lvl: int) -> String:
	match id:
		"moradias":
			return "+%d camas por casa (%d casas)" % [workers_per_moradia, lvl]  # Bloco 101: a capacidade são as camas
		"enfermaria":
			var mult := maxf(0.1, 1.0 - recovery_cut_per_level * lvl)
			var inf := get_tree().get_first_node_in_group("enfermarias")
			if inf == null:
				return "cura em %ds" % roundi(_base_recovery_time() * mult)
			return "%d leitos, cura %ds/%ds" % [inf.base_beds + inf.beds_per_level * lvl,
				roundi(inf.heal_time_leve * mult), roundi(inf.heal_time_grave * mult)]
		"trilhas":
			return "bônus dos caminhos +%d%%" % roundi(trilhas_bonus_por_nivel * lvl * 100.0)
		"posto":
			return "%d expedições ao mesmo tempo" % (2 if lvl > 0 else 1)
	return ""


func upgrade_description(id: String) -> String:
	match id:
		"moradias":
			return "+%d no limite de ipezinhos e uma casa nova (4 camas) — você escolhe onde. Custa madeira e pedra." % workers_per_moradia
		"enfermaria":
			return "+1 leito na Enfermaria e cura %d%% mais rápida por nível. Machucado só se cura lá." % roundi(recovery_cut_per_level * 100.0)
		"trilhas":
			return "Os CAMINHOS (menu Construir, aba Vila) aceleram %d%% mais por nível." % roundi(trilhas_bonus_por_nivel * 100.0)
		"posto":
			return "Mapas, mochilas e cordas guardados: duas EXPEDIÇÕES ao mesmo tempo (janela Expedições, ;)."
	return ""


func _apply_upgrade(_id: String) -> void:
	pass  # Moradias é aplicada em _confirm_house (depois de escolher o lugar)


# ------------------------------------------------------------ casas posicionadas
func _start_house_placement() -> bool:
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		push_warning("Centro da Vila: sem HousePlacer na cena")
		return false
	placer.begin(_confirm_house, CASA_TEXTURE, 3, "a casa nova", house_placer_opts())
	return true


# ------------------------------------------------------------ fundação / raio (Bloco 37)
## Até onde (do Centro da Vila) dá pra posicionar casa agora. 0 = sem limite.
func house_radius() -> float:
	if not house_radius_enabled:
		return 0.0
	return house_radius_base + house_radius_per_stage * (level - 1)


func house_placer_opts() -> Dictionary:
	return {"footprint": HOUSE_FOOTPRINT, "radius": house_radius(), "radius_center": global_position}


func starter_cost_text() -> String:
	return "%d cr + %d pedra (ferro) + %d madeira" % [starter_house_cost.x, starter_house_cost.y, starter_house_cost.z]


func comedouro_cost_text() -> String:
	return "%d cr + %d ferro + %d madeira" % [comedouro_cost.x, comedouro_cost.y, comedouro_cost.z]


func starter_block_reason() -> String:
	if starter_houses_left <= 0:
		return "sem casas iniciais"
	var eco := _economy()
	return eco.missing_text(starter_house_cost.x, starter_house_cost.y, house_stone_ore, starter_house_cost.z, "pedra (ferro)") if eco else "sem recursos"


## Casa inicial: escolhe o lugar (dentro do raio) e paga só ao confirmar.
func build_starter_house() -> bool:
	if starter_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_starter_house, CASA_TEXTURE, 3, "a casa inicial (%d/%d)" % [starter_houses - starter_houses_left + 1, starter_houses], house_placer_opts())
	return true


func _confirm_starter_house(pos: Vector2) -> bool:
	if starter_block_reason() != "":
		Audio.error()
		return false
	if not _economy().spend(starter_house_cost.x, starter_house_cost.y, house_stone_ore, starter_house_cost.z):
		return false
	starter_houses_left -= 1
	var casa := spawn_house(pos)
	casa.starter_house = true  # não soma no limite de ipezinhos quando ficar pronta
	casa.start_construction(starter_house_build_time)
	_popup("Casa inicial encomendada — precisa de engenheiro", Color(1.0, 0.8, 0.45))
	Audio.click()
	return true


func comedouro_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "comedouro")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	return eco.missing_text(comedouro_cost.x, comedouro_cost.y, "ferro", comedouro_cost.z) if eco else "sem recursos"


## Comedouro novo: o jogador escolhe o lugar (qualquer lugar livre da mina).
func build_comedouro() -> bool:
	if comedouro_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_comedouro, COMEDOURO_TEXTURE, 3, "a cozinha", {"footprint": COMEDOURO_FOOTPRINT})
	return true


func _confirm_comedouro(pos: Vector2) -> bool:
	if comedouro_block_reason() != "":
		Audio.error()
		return false
	if not _economy().spend(comedouro_cost.x, comedouro_cost.y, "ferro", comedouro_cost.z):
		return false
	Canteiro.order(get_tree(), "comedouro", pos, comedouro_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Cozinha encomendada — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


# ------------------------------------------------------------ coletor de madeira (Bloco 45)
## O primeiro coletor (Bloco 81: a ruína da floresta, quando a cena tem uma).
func coletor() -> Node:
	var f := coletor_fixo()
	return f if f != null else get_tree().get_first_node_in_group("coletores")


## Bloco 81: a ruína da cena (o primeiro coletor, restaurado por etapas). null = cena sem ruína.
func coletor_fixo() -> Node:
	return get_tree().get_first_node_in_group("coletor_fixo")


## Bloco 81: o primeiro coletor já funciona? (sem ruína na cena: sim — vale o fluxo antigo)
func coletor_restaurado() -> bool:
	var f := coletor_fixo()
	return f == null or f.restaurado()


## Bloco 47: pode ter vários — cada um com o SEU operador e a sua produção (independentes).
func coletores() -> Array:
	return get_tree().get_nodes_in_group("coletores")


## Custo do PRÓXIMO coletor (x cr, y ferro): cresce a cada um que já existe.
func coletor_cost() -> Vector3i:
	var base := Vector3i(coletor_credits, coletor_ore, 0)
	var eco := _economy()
	return eco.scaled_cost(base, coletores().size()) if eco else base


func coletor_block_reason() -> String:
	if not coletor_restaurado():  # Bloco 81: os extras só depois de restaurar o da floresta
		return "restaure primeiro o coletor em ruína da floresta (clique nele)"
	var c := Canteiro.pending(get_tree(), "coletor")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	var cost := coletor_cost()
	return eco.metal_falta(cost.x, cost.y, "ferro") if eco else "sem recursos"  # Bloco 87: barra


func coletor_cost_text() -> String:
	var c := coletor_cost()
	var eco := _economy()
	return eco.custo_metal_texto(c.x, c.y, "ferro") if eco else "%d cr + %d ferro" % [c.x, c.y]  # Bloco 87


## Escolher o lugar — só na clareira (onde estão as árvores). Bloco 81: só os EXTRAS (o primeiro é a
## ruína da floresta, restaurada por etapas no próprio coletor).
func build_coletor() -> bool:
	if coletor_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	var env := get_tree().get_first_node_in_group("environment")
	if placer == null or env == null:
		return false
	placer.begin(_confirm_coletor, COLETOR_TEXTURE, 2, "o coletor de madeira (na clareira)",
		{"footprint": COLETOR_FOOTPRINT, "area": env.clearing_rect.grow(-30.0), "area_name": "da clareira",
		"start": env.clearing_rect.get_center()})
	return true


func _confirm_coletor(pos: Vector2) -> bool:
	if coletor_block_reason() != "":
		Audio.error()
		return false
	var cost := coletor_cost()
	if not _economy().paga_metal(cost.x, cost.y, "ferro"):
		return false
	Canteiro.order(get_tree(), "coletor", pos, coletor_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Coletor de madeira encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_coletor(pos: Vector2) -> Node2D:
	var c: Node2D = COLETOR_SCENE.instantiate()
	var n := coletores().size()
	c.name = "ColetorMadeira" if n == 0 else "ColetorMadeira%d" % (n + 1)
	c.position = pos
	get_parent().add_child(c)
	_coletor_mudou()
	return c


## A navegação e a decoração por baixo acompanham um coletor novo ou que mudou de lugar.
func _coletor_mudou() -> void:
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()


## Bloco 45/47/81: os coletores de madeira do save (o operador se religa sozinho: ipezinho
## "operates_coletor"). A ruína da cena (fixo) fica e recebe a etapa dela; os extras são refeitos.
## Save antigo (sem "fixo" nas entradas): o primeiro coletor construído É o da floresta, já restaurado
## (a ruína vai pro lugar dele); save antigo sem coletor: a ruína fica como está na cena (etapa 0).
func _load_coletores(d: Dictionary) -> void:
	var fixo := coletor_fixo()
	for old in coletores():
		if old == fixo:
			continue
		old.get_parent().remove_child(old)
		old.queue_free()
	var list: Array = SaveUtil.array(d, "coletores")
	if list.is_empty() and not SaveUtil.dict(d, "coletor").is_empty():
		list = [SaveUtil.dict(d, "coletor")]  # Bloco 47: save antigo, um só
	var antigo := not list.any(func(cd): return cd is Dictionary and cd.has("fixo"))
	var usou_fixo := false
	for cd in list:
		if typeof(cd) != TYPE_DICTIONARY:
			continue
		var cpos := SaveUtil.vec2(cd, "position", Vector2.INF)
		if cpos == Vector2.INF:
			continue
		if fixo != null and not usou_fixo and (SaveUtil.boolean(cd, "fixo", false) or antigo):
			usou_fixo = true
			if fixo.global_position.distance_to(cpos) > 1.0:
				fixo.global_position = cpos
				_coletor_mudou()
			fixo.load_save_data(cd)  # sem "etapa" (save antigo) = restaurado
			continue
		spawn_coletor(cpos).load_save_data(cd)
	if fixo != null and not usou_fixo:
		fixo.volta_pra_ruina()


# ------------------------------------------------------------ igreja (Bloco 88)
const IGREJA_SCENE := preload("res://scenes/props/igreja.tscn")
const IGREJA_TEXTURE := preload("res://assets/game/igreja.png")


func igreja() -> Node:
	return get_tree().get_first_node_in_group("igrejas")


func igreja_cost_text() -> String:
	return "%d cr + %d ferro + %d madeira" % [igreja_credits, igreja_ore, igreja_wood]


func igreja_block_reason() -> String:
	if igreja() != null:
		return "já construída (é uma só)"
	if level < igreja_estagio:
		return "precisa da vila no estágio %s" % STAGE_NAMES[clampi(igreja_estagio, 1, STAGE_NAMES.size()) - 1]
	var c := Canteiro.pending(get_tree(), "igreja")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	return eco.missing_text(igreja_credits, igreja_ore, "ferro", igreja_wood, "ferro") if eco else "sem recursos"


func build_igreja() -> bool:
	if igreja_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_igreja, IGREJA_TEXTURE, 1, "a Igreja",
		{"footprint": COLETOR_FOOTPRINT, "start": global_position + Vector2(-160, -40)})
	return true


func _confirm_igreja(pos: Vector2) -> bool:
	if igreja_block_reason() != "":
		Audio.error()
		return false
	if not _economy().spend(igreja_credits, igreja_ore, "ferro", igreja_wood):
		return false
	Canteiro.order(get_tree(), "igreja", pos, igreja_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Igreja encomendada — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_igreja(pos: Vector2) -> Node2D:
	var ig: Node2D = IGREJA_SCENE.instantiate()
	ig.name = "Igreja"
	ig.position = pos
	get_parent().add_child(ig)
	_coletor_mudou()  # (navegação e decoração por baixo)
	return ig


# ------------------------------------------------------------ cemitério (Bloco 93)
const CEMITERIO := preload("res://scripts/props/cemiterio.gd")


func cemiterios() -> Array:
	return get_tree().get_nodes_in_group("cemiterios")


## Custo de um cemitério desse tamanho: (créditos, ferro, madeira) e os segundos de engenheiro em w.
func cemiterio_custo(r: Rect2) -> Vector4:
	var a := CEMITERIO.alinha(r)
	var trechos := int(roundf(a.size.x / CEMITERIO.TRECHO) + roundf(a.size.y / CEMITERIO.TRECHO)) * 2
	var tmp: Node2D = CEMITERIO.new()
	tmp.rect = a
	var vagas: int = tmp.vagas_total()
	tmp.free()
	return Vector4(cemiterio_credits_base + cemiterio_credits_por_vaga * vagas, cemiterio_ore_por_trecho * trechos,
		cemiterio_wood_por_trecho * trechos, cemiterio_segundos_base + cemiterio_segundos_por_trecho * trechos)


func cemiterio_custo_texto(r: Rect2) -> String:
	var c := cemiterio_custo(r)
	var a := CEMITERIO.alinha(r)
	var tmp: Node2D = CEMITERIO.new()
	tmp.rect = a
	var vagas: int = tmp.vagas_total()
	tmp.free()
	return "%d vagas  •  %d cr + %d ferro + %d madeira" % [vagas, int(c.x), int(c.y), int(c.z)]


func cemiterio_block_reason() -> String:
	if level < cemiterio_estagio:
		return "precisa da vila no estágio %s" % STAGE_NAMES[clampi(cemiterio_estagio, 1, STAGE_NAMES.size()) - 1]
	return ""


## Por que ESTE terreno não vale ("" = vale): tamanho, chão andável, nada construído por cima, recursos.
func motivo_cemiterio(r: Rect2) -> String:
	var b := cemiterio_block_reason()
	if b != "":
		return b
	var a := CEMITERIO.alinha(r)
	var nx := int(roundf(a.size.x / CEMITERIO.TRECHO))
	var ny := int(roundf(a.size.y / CEMITERIO.TRECHO))
	if nx > cemiterio_max_trechos.x or ny > cemiterio_max_trechos.y:
		return "grande demais (até %d x %d trechos de cerca)" % [cemiterio_max_trechos.x, cemiterio_max_trechos.y]
	var map := get_world_2d().navigation_map
	var y := a.position.y
	while y <= a.end.y:
		var x := a.position.x
		while x <= a.end.x:
			if NavigationServer2D.map_get_closest_point(map, Vector2(x, y)).distance_to(Vector2(x, y)) > 3.0:
				return "o terreno precisa ser chão livre (sem pedra, água ou parede)"
			x += 12.0
		y += 12.0
	var env := get_tree().get_first_node_in_group("environment")
	var grupos: Array = (env.STATION_GROUPS + env.NAV_EXTRA_GROUPS if env else []) + ["casas", "village_hub", "armazens", "comedouros", "cemiterios"]
	grupos = grupos.filter(func(g): return g not in ["arvores", "coleta_comida", "canteiros"])  # (árvore e horta: a decoração sai)
	for g in grupos:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node2D and a.grow(6.0).intersects(_pegada(n)):
				return "tem construção no terreno"
	var c := cemiterio_custo(a)
	var eco := _economy()
	return eco.missing_text(int(c.x), int(c.y), "ferro", int(c.z), "ferro") if eco else "sem recursos"


## A pegada de uma construção no chão (a do desenho da vista iso, ou o obstáculo; sem nenhum, um quadrado no pé).
func _pegada(n: Node2D) -> Rect2:
	if n.has_method("decor_clear_rect") and n.is_in_group("cemiterios"):
		return n.decor_clear_rect()
	var r := IsoArt.base_rect(n)
	if n.has_method("get_obstacle_outline"):
		var o: PackedVector2Array = n.get_obstacle_outline()
		if o.size() >= 3:
			var bb := Rect2(o[0], Vector2.ZERO)
			for q in o:
				bb = bb.expand(q)
			r = bb if not r.has_area() else r.merge(bb)
	return r if r.has_area() else Rect2(n.global_position - Vector2(16, 16), Vector2(32, 32))


func build_cemiterio() -> bool:
	if cemiterio_block_reason() != "":
		Audio.error()
		return false
	var ap := get_tree().get_first_node_in_group("area_placer")
	if ap == null:
		return false
	ap.begin_custom("o cemitério", motivo_cemiterio, _confirm_cemiterio, cemiterio_custo_texto)
	return true


func _confirm_cemiterio(r: Rect2) -> bool:
	if motivo_cemiterio(r) != "":
		return false
	var c := cemiterio_custo(r)
	if not _economy().spend(int(c.x), int(c.y), "ferro", int(c.z)):
		return false
	spawn_cemiterio(r, c.w)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Cemitério encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_cemiterio(r: Rect2, segundos: float) -> Node2D:
	var cem: Node2D = CEMITERIO.new()
	cem.configura(r, segundos)
	var n := cemiterios().size()
	cem.name = "Cemiterio" if n == 0 else "Cemiterio%d" % (n + 1)
	get_parent().add_child(cem)
	var env := get_tree().get_first_node_in_group("environment")
	if env and env.has_method("_limpa_decor"):
		env._limpa_decor(cem.decor_clear_rect())  # (a decoração do mapa não fica dentro da cerca)
	return cem


# ------------------------------------------------------------ fornalha (Bloco 86)
const FORNALHA_SCENE := preload("res://scenes/props/fornalha.tscn")
const FORNALHA_TEXTURE := preload("res://assets/game/fornalha.png")


func fornalhas() -> Array:
	return get_tree().get_nodes_in_group("fornalhas")


## Custo da PRÓXIMA (x cr, y ferro): cresce a cada uma que já existe (Bloco 47).
func fornalha_cost() -> Vector3i:
	var base := Vector3i(fornalha_credits, fornalha_ore, 0)
	var eco := _economy()
	return eco.scaled_cost(base, fornalhas().size()) if eco else base


func fornalha_cost_text() -> String:
	var c := fornalha_cost()
	return "%d cr + %d ferro" % [c.x, c.y]


func fornalha_block_reason() -> String:
	if level < fornalha_estagio:
		return "precisa da vila no estágio %s" % STAGE_NAMES[clampi(fornalha_estagio, 1, STAGE_NAMES.size()) - 1]
	var c := Canteiro.pending(get_tree(), "fornalha")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	var cost := fornalha_cost()
	return eco.missing_text(cost.x, cost.y, "ferro") if eco else "sem recursos"


func build_fornalha() -> bool:
	if fornalha_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_fornalha, FORNALHA_TEXTURE, 2, "a Fornalha",
		{"footprint": COLETOR_FOOTPRINT, "start": global_position + Vector2(140, 60)})
	return true


func _confirm_fornalha(pos: Vector2) -> bool:
	if fornalha_block_reason() != "":
		Audio.error()
		return false
	var cost := fornalha_cost()
	if not _economy().spend(cost.x, cost.y, "ferro"):
		return false
	Canteiro.order(get_tree(), "fornalha", pos, fornalha_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Fornalha encomendada — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_fornalha(pos: Vector2) -> Node2D:
	var f: Node2D = FORNALHA_SCENE.instantiate()
	var n := fornalhas().size()
	f.name = "Fornalha" if n == 0 else "Fornalha%d" % (n + 1)
	f.position = pos
	get_parent().add_child(f)
	_coletor_mudou()  # (navegação e decoração por baixo, como o coletor)
	return f


# ------------------------------------------------------------ carpintaria (Bloco 94)
const CARPINTARIA_SCENE := preload("res://scenes/props/carpintaria.tscn")
const CARPINTARIA_TEXTURE := preload("res://assets/game/carpintaria.png")


func carpintarias() -> Array:
	return get_tree().get_nodes_in_group("carpintarias")


## Custo da PRÓXIMA (x cr, y ferro, z madeira): cresce a cada uma que já existe (Bloco 47).
func carpintaria_cost() -> Vector3i:
	var base := Vector3i(carpintaria_credits, carpintaria_ore, carpintaria_wood)
	var eco := _economy()
	return eco.scaled_cost(base, carpintarias().size()) if eco else base


func carpintaria_cost_text() -> String:
	var c := carpintaria_cost()
	return "%d cr + %d ferro + %d madeira" % [c.x, c.y, c.z]


func carpintaria_block_reason() -> String:
	if level < carpintaria_estagio:
		return "precisa da vila no estágio %s" % STAGE_NAMES[clampi(carpintaria_estagio, 1, STAGE_NAMES.size()) - 1]
	var c := Canteiro.pending(get_tree(), "carpintaria")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	var cost := carpintaria_cost()
	return eco.missing_text(cost.x, cost.y, "ferro", cost.z) if eco else "sem recursos"


func build_carpintaria() -> bool:
	if carpintaria_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_carpintaria, CARPINTARIA_TEXTURE, 2, "a Carpintaria",
		{"footprint": COLETOR_FOOTPRINT, "start": global_position + Vector2(-150, 70)})
	return true


func _confirm_carpintaria(pos: Vector2) -> bool:
	if carpintaria_block_reason() != "":
		Audio.error()
		return false
	var cost := carpintaria_cost()
	if not _economy().spend(cost.x, cost.y, "ferro", cost.z):
		return false
	Canteiro.order(get_tree(), "carpintaria", pos, carpintaria_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Carpintaria encomendada — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_carpintaria(pos: Vector2) -> Node2D:
	var c: Node2D = CARPINTARIA_SCENE.instantiate()
	var n := carpintarias().size()
	c.name = "Carpintaria" if n == 0 else "Carpintaria%d" % (n + 1)
	c.position = pos
	get_parent().add_child(c)
	_coletor_mudou()
	return c


# ------------------------------------------------------------ horta, estufa, carvoaria e curtume (Bloco 107)
const HORTA_SCENE := preload("res://scenes/props/horta.tscn")
const ESTUFA_SCENE := preload("res://scenes/props/estufa.tscn")
const CARVOARIA_SCENE := preload("res://scenes/props/carvoaria.tscn")
const CURTUME_SCENE := preload("res://scenes/props/curtume.tscn")
const ESCOLA_SCENE := preload("res://scenes/props/escola.tscn")  # Bloco 111
const ESCOLA_FOOTPRINT := Rect2(-60, -70, 120, 82)
const HORTA_FOOTPRINT := Rect2(-48, -36, 96, 52)
const ESTUFA_FOOTPRINT := Rect2(-70, -66, 140, 80)
## O que cada construção do Bloco 107 é: grupo dos que existem, nome, textura do fantasma e quadros.
const OBRAS_107 := {
	"horta": {"grupo": "hortas", "nome": "a Horta", "textura": "horta", "hframes": 3, "dentro": true, "f": true},
	"estufa": {"grupo": "estufas", "nome": "a Estufa", "textura": "estufa", "hframes": 2, "dentro": true, "f": true},
	"carvoaria": {"grupo": "carvoarias", "nome": "a Carvoaria", "textura": "carvoaria", "hframes": 2, "dentro": false, "f": true},
	"curtume": {"grupo": "curtumes", "nome": "o Curtume", "textura": "curtume", "hframes": 2, "dentro": false, "f": false},
	"escola": {"grupo": "escolas", "nome": "a Escola", "textura": "escola", "hframes": 2, "dentro": true, "f": true},  # Bloco 111
}


## Os que já existem de cada tipo.
func obras107(kind: String) -> Array:
	return get_tree().get_nodes_in_group(OBRAS_107[kind].grupo)


func hortas() -> Array:
	return obras107("horta")


func estufas() -> Array:
	return obras107("estufa")


func carvoarias() -> Array:
	return obras107("carvoaria")


func curtumes() -> Array:
	return obras107("curtume")


## Os números de um tipo: [créditos, ferro, madeira, {itens}, segundos, estágio, máximo].
func _dados107(kind: String) -> Array:
	match kind:
		"horta":
			return [horta_credits, 0, horta_wood, {}, horta_build_time, horta_estagio, horta_max]
		"estufa":
			return [estufa_credits, estufa_ore, estufa_wood, {"prego": estufa_pregos}, estufa_build_time, estufa_estagio, estufa_max]
		"carvoaria":
			return [carvoaria_credits, carvoaria_ore, carvoaria_wood, {}, carvoaria_build_time, carvoaria_estagio, 99]
		"escola":
			return [escola_credits, escola_ore, escola_wood, {"prego": escola_pregos}, escola_build_time, escola_estagio, escola_max]
	return [curtume_credits, curtume_ore, curtume_wood, {"prego": curtume_pregos}, curtume_build_time, curtume_estagio, 99]


## Custo da PRÓXIMA (x cr, y ferro, z madeira): cresce a cada uma que já existe (Bloco 47). Os itens (pregos) não crescem.
func obra107_cost(kind: String) -> Vector3i:
	var d := _dados107(kind)
	var eco := _economy()
	var base := Vector3i(d[0], d[1], d[2])
	return eco.scaled_cost(base, obras107(kind).size()) if eco else base


func obra107_cost_text(kind: String) -> String:
	var c := obra107_cost(kind)
	var eco := _economy()
	return eco.custo_metal_texto(c.x, c.y, "ferro", c.z, _dados107(kind)[3]) if eco else ""


func obra107_block_reason(kind: String) -> String:
	var d := _dados107(kind)
	if level < int(d[5]):
		return "precisa da vila no estágio %s" % STAGE_NAMES[clampi(int(d[5]), 1, STAGE_NAMES.size()) - 1]
	if obras107(kind).size() >= int(d[6]):
		return "já tem o máximo (%d)" % int(d[6])
	var c := Canteiro.pending(get_tree(), kind)
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	var cost := obra107_cost(kind)
	return eco.metal_falta(cost.x, cost.y, "ferro", cost.z, d[3]) if eco else "sem recursos"


## O jogador escolhe o lugar: horta e estufa DENTRO da vila (o raio do Centro); carvoaria e curtume como a carpintaria.
func obra107_build(kind: String) -> bool:
	if obra107_block_reason(kind) != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	var info: Dictionary = OBRAS_107[kind]
	var tex: Texture2D = load("res://assets/game/%s.png" % info.textura)
	var opts := {"footprint": ({"estufa": ESTUFA_FOOTPRINT, "escola": ESCOLA_FOOTPRINT}.get(kind, HORTA_FOOTPRINT)) if info.dentro else COLETOR_FOOTPRINT,
		"start": global_position + Vector2(-150, 70)}
	if info.dentro:
		opts["radius"] = house_radius()
		opts["radius_center"] = global_position
	var confirma: Callable = func(pos: Vector2) -> bool: return _obra107_confirma(kind, pos)
	placer.begin(confirma, tex, int(info.hframes), String(info.nome), opts)
	return true


func _obra107_confirma(kind: String, pos: Vector2) -> bool:
	if obra107_block_reason(kind) != "":
		Audio.error()
		return false
	var d := _dados107(kind)
	var cost := obra107_cost(kind)
	if not _economy().paga_metal(cost.x, cost.y, "ferro", cost.z, d[3]):  # (Bloco 96: o material vira a lista da obra)
		return false
	Canteiro.order(get_tree(), kind, pos, float(d[4]))
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("%s encomendad%s — precisa de engenheiro (tecla 4)." % [String(OBRAS_107[kind].nome).capitalize(), "a" if OBRAS_107[kind].f else "o"], Color(1.0, 0.8, 0.45))
	return true


func horta_cost_text() -> String:
	return obra107_cost_text("horta")


func horta_block_reason() -> String:
	return obra107_block_reason("horta")


func build_horta() -> bool:
	return obra107_build("horta")


func estufa_cost_text() -> String:
	return obra107_cost_text("estufa")


func estufa_block_reason() -> String:
	return obra107_block_reason("estufa")


func build_estufa() -> bool:
	return obra107_build("estufa")


func carvoaria_cost_text() -> String:
	return obra107_cost_text("carvoaria")


func carvoaria_block_reason() -> String:
	return obra107_block_reason("carvoaria")


func build_carvoaria() -> bool:
	return obra107_build("carvoaria")


func curtume_cost_text() -> String:
	return obra107_cost_text("curtume")


func curtume_block_reason() -> String:
	return obra107_block_reason("curtume")


func build_curtume() -> bool:
	return obra107_build("curtume")


func escolas() -> Array:
	return obras107("escola")


func escola_cost_text() -> String:
	return obra107_cost_text("escola")


func escola_block_reason() -> String:
	return obra107_block_reason("escola")


func build_escola() -> bool:
	return obra107_build("escola")


## Carregando o save: se já existe um do mesmo tipo NO MESMO LUGAR (a horta da cena, ou o de antes de recarregar), usa ele em vez
## de apagar e recriar (cada criação refaz a malha de navegação: 50 recarregamentos seguidos viravam 50 refeitas à toa).
func _reaproveita_ou_cria(kind: String, pos: Vector2, vivos: Array) -> Node2D:
	for v in vivos:
		if is_instance_valid(v) and (v as Node2D).global_position.distance_to(pos) < 1.0 and (kind == "estufa") == (v.get("estufa") == true):
			vivos.erase(v)
			return v
	return spawn_obra107(kind, pos)


## Nasce um deles (obra pronta ou save). Nome: "Horta2", "Estufa", "Carvoaria"... (único, pro save por nome).
func spawn_obra107(kind: String, pos: Vector2) -> Node2D:
	var scene: PackedScene = {"horta": HORTA_SCENE, "estufa": ESTUFA_SCENE, "carvoaria": CARVOARIA_SCENE, "curtume": CURTUME_SCENE,
		"escola": ESCOLA_SCENE}[kind]
	var n: Node2D = scene.instantiate()
	var base: String = String(kind).capitalize()
	var i := obras107(kind).size()
	var nome := base if i == 0 else "%s%d" % [base, i + 1]
	while get_parent().has_node(nome):
		i += 1
		nome = "%s%d" % [base, i + 1]
	n.name = nome
	n.position = pos
	get_parent().add_child(n)
	_coletor_mudou()
	var res := get_tree().get_first_node_in_group("research")
	if res and res.has_method("apply_all"):
		res.apply_all()  # (a Hidroponia vale pra horta nova)
	return n


# ------------------------------------------------------------ armazém novo (Bloco 97)
const ARMAZEM_SCENE := preload("res://scenes/props/armazem.tscn")
const ARMAZEM_TEXTURE := preload("res://assets/game/armazem.png")


## Os armazéns que o jogador construiu (o da mina vem com o mapa).
func armazens_novos() -> Array:
	return get_tree().get_nodes_in_group("armazens").filter(func(a): return a.get("construido") == true)


## Custo do PRÓXIMO (x cr, y ferro, z madeira): cresce a cada um construído (Bloco 47).
func armazem_cost() -> Vector3i:
	var base := Vector3i(armazem_credits, armazem_ore, armazem_wood)
	var eco := _economy()
	return eco.scaled_cost(base, armazens_novos().size()) if eco else base


func armazem_cost_text() -> String:
	var c := armazem_cost()
	return "%d cr + %d ferro + %d madeira" % [c.x, c.y, c.z]


func armazem_block_reason() -> String:
	if level < armazem_estagio:
		return "precisa da vila no estágio %s" % STAGE_NAMES[clampi(armazem_estagio, 1, STAGE_NAMES.size()) - 1]
	var c := Canteiro.pending(get_tree(), "armazem")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	var cost := armazem_cost()
	return eco.missing_text(cost.x, cost.y, "ferro", cost.z) if eco else "sem recursos"


func build_armazem() -> bool:
	if armazem_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_armazem, ARMAZEM_TEXTURE, 1, "o Armazém novo",
		{"footprint": COLETOR_FOOTPRINT, "start": global_position + Vector2(160, 90)})
	return true


func _confirm_armazem(pos: Vector2) -> bool:
	if armazem_block_reason() != "":
		Audio.error()
		return false
	var cost := armazem_cost()
	if not _economy().spend(cost.x, cost.y, "ferro", cost.z):
		return false
	Canteiro.order(get_tree(), "armazem", pos, armazem_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Armazém novo encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_armazem(pos: Vector2, nome: String = "") -> Node2D:
	var a: Node2D = ARMAZEM_SCENE.instantiate()
	a.construido = true
	a.name = nome if nome != "" else "ArmazemNovo%d" % (armazens_novos().size() + 1)
	a.position = pos
	get_parent().add_child(a)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return a


# ------------------------------------------------------------ oficina (Bloco 58)
func oficina() -> Node:
	return get_tree().get_first_node_in_group("oficina")


func oficina_block_reason() -> String:
	var o := oficina()
	if o == null:
		return "sem Oficina no mapa"
	if o.is_built():
		return "já construída (é uma só)"
	var c := Canteiro.pending(get_tree(), "oficina")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	return eco.missing_text(oficina_credits, oficina_ore, "ferro", oficina_wood, "ferro") if eco else "sem recursos"


func oficina_cost_text() -> String:
	return "%d cr + %d ferro + %d madeira" % [oficina_credits, oficina_ore, oficina_wood]


func build_oficina() -> bool:
	if oficina_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_oficina, preload("res://assets/game/oficina.png"), 2, "a Oficina",
		{"footprint": COLETOR_FOOTPRINT, "start": global_position + Vector2(-140, 60)})
	return true


func _confirm_oficina(pos: Vector2) -> bool:
	if oficina_block_reason() != "":
		Audio.error()
		return false
	if not _economy().spend(oficina_credits, oficina_ore, "ferro", oficina_wood):
		return false
	Canteiro.order(get_tree(), "oficina", pos, oficina_build_time)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Oficina encomendada — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


# ------------------------------------------------------------ desbravar o leste (Bloco 67)
func leste_block_reason() -> String:
	var env := get_tree().get_first_node_in_group("environment")
	if env == null or not env.has_method("has_leste") or not env.has_leste():
		return "o mapa não tem leste"
	if env.leste_aberto:
		return "já desbravado"
	var c := Canteiro.pending(get_tree(), "desbravar")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	if level < leste_min_stage:
		return "precisa da vila no estágio %d" % leste_min_stage
	var eco := _economy()
	return eco.missing_text(leste_credits, leste_ore, "ferro", leste_wood, "ferro") if eco else "sem recursos"


func leste_cost_text() -> String:
	return "%d cr + %d ferro + %d madeira" % [leste_credits, leste_ore, leste_wood]


## Encomenda: o engenheiro vai abrindo caminho na fronteira (na pedreira, logo antes da área nova).
func desbravar_leste() -> bool:
	if leste_block_reason() != "":
		Audio.error()
		return false
	if not _economy().spend(leste_credits, leste_ore, "ferro", leste_wood):
		return false
	var env := get_tree().get_first_node_in_group("environment")
	var p: Vector2 = env.nearest_ok(Vector2(env.leste_x() - 40.0, 160.0), 16.0)
	Canteiro.order(get_tree(), "desbravar", p, leste_build_time)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Desbravar o leste: o engenheiro (tecla 4) abre caminho na fronteira.", Color(1.0, 0.8, 0.45))
	return true


# ------------------------------------------------------------ trilho e vagonete (Bloco 64)
func vagonetes() -> Array:
	# (Bloco 74: o da mina é fixo — não conta no custo nem vai na lista do save)
	return get_tree().get_nodes_in_group("pontos_carga").filter(func(v): return not v.is_in_group("ponto_carga_fixo") and String(v.get("ferrovia")) == "")


## Bloco 74: o ponto de carga fixo da boca da mina (null = mapa sem ele).
func estacao_mina() -> Node2D:
	return get_tree().get_first_node_in_group("ponto_carga_fixo")


func vagonete_cost() -> Vector3i:
	var base := Vector3i(vagonete_credits, vagonete_ore, vagonete_wood)
	var eco := _economy()
	return eco.scaled_cost(base, vagonetes().size()) if eco else base


func vagonete_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "vagonete")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	if get_tree().get_first_node_in_group("armazens") == null:
		return "precisa de um armazém (o trilho vai até ele)"
	var eco := _economy()
	var cost := vagonete_cost()
	return eco.missing_text(cost.x, cost.y, "ferro", cost.z, "ferro") if eco else "sem recursos"


func vagonete_cost_text() -> String:
	var c := vagonete_cost()
	return "%d cr + %d ferro + %d madeira" % [c.x, c.y, c.z]


## Lugar bom: perto de uma jazida liberada e longe o bastante do armazém (senão não vale o trilho).
func vagonete_spot_reason(pos: Vector2) -> String:
	var r := coletor_minerio_spot_reason(pos)
	if r != "":
		return "longe de uma jazida liberada (o ponto de carga fica perto delas)"
	for a in get_tree().get_nodes_in_group("armazens"):
		if a.global_position.distance_to(pos) < 180.0:
			return "perto demais do armazém (aí nem precisa de trilho)"
	return ""


func build_vagonete() -> bool:
	if vagonete_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	var start := global_position
	var arm := get_tree().get_first_node_in_group("armazens") as Node2D
	var best := INF
	for j in get_tree().get_nodes_in_group("minerios"):
		if j.is_unlocked() and not j.is_sealed() and arm and j.global_position.distance_to(arm.global_position) > 240.0:
			var d: float = j.global_position.distance_to(arm.global_position)
			if d < best:
				best = d
				start = j.global_position + Vector2(70, 50)
	placer.begin(_confirm_vagonete, preload("res://assets/game/iso/props/vagonete_cheio_SE.png"), 1, "o ponto de carga do vagonete (perto das jazidas)",
		{"footprint": Rect2(-30, -20, 60, 30), "check": vagonete_spot_reason, "start": start})
	return true


func _confirm_vagonete(pos: Vector2) -> bool:
	if vagonete_block_reason() != "" or vagonete_spot_reason(pos) != "":
		Audio.error()
		return false
	var cost := vagonete_cost()
	if not _economy().spend(cost.x, cost.y, "ferro", cost.z):
		return false
	Canteiro.order(get_tree(), "vagonete", pos, vagonete_build_time)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Trilho e vagonete encomendados — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_vagonete(pos: Vector2) -> Node2D:
	var c: Node2D = VAGONETE_SCENE.instantiate()
	var n := vagonetes().size()
	c.name = "EstacaoVagonete" if n == 0 else "EstacaoVagonete%d" % (n + 1)
	c.position = pos
	get_parent().add_child(c)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return c


# ------------------------------------------------------------ ferrovia de carga (Bloco 79)
## Os andares que podem ter estação, de cima pra baixo.
const FERROVIA_ANDARES := ["S2", "S3", "S4", "S5"]


func ferrovias() -> Array:
	return get_tree().get_nodes_in_group("ferrovias")


func ferrovia_de(id: String) -> Node:
	for f in ferrovias():
		if String(f.ferrovia) == id:
			return f
	return null


## O próximo andar sem estação (de cima pra baixo), ou "" (todos têm).
func ferrovia_proximo() -> String:
	for id in FERROVIA_ANDARES:
		if ferrovia_de(id) == null:
			return id
	return ""


func ferrovia_custo(id: String) -> Vector4i:
	var n := preload("res://scripts/core/niveis.gd").por_id(id)
	var p: int = n.profundidade if n else 3
	return ferrovia_base + ferrovia_por_andar * p


## Bloco 94: os pregos e as ferragens da estação desse andar ({prego, ferragem}).
func ferrovia_pecas(id: String) -> Dictionary:
	var n := preload("res://scripts/core/niveis.gd").por_id(id)
	var p: int = n.profundidade if n else 3
	var v := ferrovia_pecas_base + ferrovia_pecas_por_andar * p
	return {"prego": v.x, "ferragem": v.y}


func ferrovia_cost_text() -> String:
	var id := ferrovia_proximo()
	if id == "":
		return "todos os andares têm"
	var c := ferrovia_custo(id)
	var eco := _economy()
	if eco == null:
		return "%d cr + %d ferro + %d madeira" % [c.x, c.y, c.z]
	return eco.custo_metal_texto(c.x, c.y, "ferro", c.z, ferrovia_pecas(id))


func ferrovia_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "ferrovia")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var id := ferrovia_proximo()
	if id == "":
		return "todos os andares já têm estação"
	var Niveis := preload("res://scripts/core/niveis.gd")
	var n := Niveis.por_id(id)
	var m: String = Niveis.motivo(get_tree(), n)
	if m != "":
		return "%s fechado: %s" % [id, m]
	if get_tree().get_first_node_in_group("armazens") == null:
		return "precisa de um armazém (a carga sobe até ele)"
	var env := get_tree().get_first_node_in_group("environment")
	if env == null or env.ponto_ferrovia(n) == Vector2.INF:
		return "sem lugar pra estação no %s" % id
	var cost := ferrovia_custo(id)
	var eco := _economy()
	return eco.metal_falta(cost.x, cost.y, "ferro", cost.z, ferrovia_pecas(id)) if eco else "sem recursos"  # Bloco 94


## Encomenda a estação do próximo andar (lugar fixo: a ponta leste da faixa, perto do poço).
func build_ferrovia() -> bool:
	if ferrovia_block_reason() != "":
		Audio.error()
		return false
	var id := ferrovia_proximo()
	var n := preload("res://scripts/core/niveis.gd").por_id(id)
	var pos: Vector2 = get_tree().get_first_node_in_group("environment").ponto_ferrovia(n)
	var cost := ferrovia_custo(id)
	if not _economy().paga_metal(cost.x, cost.y, "ferro", cost.z, ferrovia_pecas(id)):  # Bloco 94: barras + peças
		return false
	Canteiro.order(get_tree(), "ferrovia", pos, float(cost.w))
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Estação da ferrovia no %s encomendada — precisa de engenheiro (tecla 4)." % id, Color(1.0, 0.8, 0.45))
	return true


func spawn_ferrovia(id: String, pos: Vector2) -> Node2D:
	var c: Node2D = VAGONETE_SCENE.instantiate()
	c.ferrovia = id
	c.name = "Ferrovia" + id
	c.position = pos
	c.buffer_capacity = 80.0
	c.cart_capacity = 30.0
	get_parent().add_child(c)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return c


# ------------------------------------------------------------ coletor de minério (Bloco 57)
func coletores_minerio() -> Array:
	return get_tree().get_nodes_in_group("coletores_minerio")


## Custo do PRÓXIMO (x cr, y ferro, z madeira): cresce a cada um que já existe.
func coletor_minerio_cost() -> Vector3i:
	var base := Vector3i(coletor_min_credits, coletor_min_ore, coletor_min_wood)
	var eco := _economy()
	return eco.scaled_cost(base, coletores_minerio().size()) if eco else base


func coletor_minerio_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "coletor_minerio")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	var cost := coletor_minerio_cost()
	return eco.metal_falta(cost.x, cost.y, "ferro", cost.z) if eco else "sem recursos"  # Bloco 87: barra


func coletor_minerio_cost_text() -> String:
	var c := coletor_minerio_cost()
	var eco := _economy()
	return eco.custo_metal_texto(c.x, c.y, "ferro", c.z) if eco else "%d cr + %d ferro + %d madeira" % [c.x, c.y, c.z]  # Bloco 87


## Lugar bom: com uma jazida liberada no alcance da broca.
func coletor_minerio_spot_reason(pos: Vector2) -> String:
	var reach: float = 230.0
	for j in get_tree().get_nodes_in_group("minerios"):
		if j.is_unlocked() and not j.is_sealed() and j.global_position.distance_to(pos) <= reach * 0.85:
			return ""
	return "longe de uma jazida liberada (a broca precisa de uma perto)"


func build_coletor_minerio() -> bool:
	if coletor_minerio_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	var start := global_position
	for j in get_tree().get_nodes_in_group("minerios"):
		if j.is_unlocked() and not j.is_sealed():
			start = j.global_position + Vector2(90, 40)
			break
	placer.begin(_confirm_coletor_minerio, COLETOR_MIN_TEXTURE, 2, "o coletor de minério (perto de uma jazida)",
		{"footprint": COLETOR_FOOTPRINT, "check": coletor_minerio_spot_reason, "start": start})
	return true


func _confirm_coletor_minerio(pos: Vector2) -> bool:
	if coletor_minerio_block_reason() != "" or coletor_minerio_spot_reason(pos) != "":
		Audio.error()
		return false
	var cost := coletor_minerio_cost()
	if not _economy().paga_metal(cost.x, cost.y, "ferro", cost.z):
		return false
	Canteiro.order(get_tree(), "coletor_minerio", pos, coletor_min_build_time)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Coletor de minério encomendado — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_coletor_minerio(pos: Vector2) -> Node2D:
	var c: Node2D = COLETOR_MIN_SCENE.instantiate()
	var n := coletores_minerio().size()
	c.name = "ColetorMinerio" if n == 0 else "ColetorMinerio%d" % (n + 1)
	c.position = pos
	get_parent().add_child(c)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return c


# ------------------------------------------------------------ enfermaria extra (Bloco 47)
## As enfermarias construídas pelo jogador (sem a principal, que vem com a vila).
func extra_enfermarias() -> Array:
	return get_tree().get_nodes_in_group("enfermarias").filter(func(w): return w.extra)


## Custo da PRÓXIMA enfermaria extra (x cr, y ferro, z madeira).
func enfermaria_cost() -> Vector3i:
	var base := Vector3i(enfermaria_extra_credits, enfermaria_extra_ore, enfermaria_extra_wood)
	var eco := _economy()
	return eco.scaled_cost(base, extra_enfermarias().size()) if eco else base


func enfermaria_cost_text() -> String:
	var c := enfermaria_cost()
	return "%d cr + %d ferro + %d madeira" % [c.x, c.y, c.z]


func enfermaria_block_reason() -> String:
	var c := Canteiro.pending(get_tree(), "enfermaria")
	if c:
		return "em obra (%s)" % c._obra.status(c.obra_progress())
	var eco := _economy()
	var cost := enfermaria_cost()
	return eco.missing_text(cost.x, cost.y, "ferro", cost.z) if eco else "sem recursos"


func build_enfermaria() -> bool:
	if enfermaria_block_reason() != "":
		Audio.error()
		return false
	var placer := get_tree().get_first_node_in_group("house_placer")
	if placer == null:
		return false
	placer.begin(_confirm_enfermaria, ENFERMARIA_TEXTURE, 2, "a nova enfermaria", {"footprint": ENFERMARIA_FOOTPRINT})
	return true


func _confirm_enfermaria(pos: Vector2) -> bool:
	if enfermaria_block_reason() != "":
		Audio.error()
		return false
	var cost := enfermaria_cost()
	if not _economy().spend(cost.x, cost.y, "ferro", cost.z):
		return false
	Canteiro.order(get_tree(), "enfermaria", pos, enfermaria_extra_build_time)
	Audio.click()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Nova enfermaria encomendada — precisa de engenheiro (tecla 4).", Color(1.0, 0.8, 0.45))
	return true


func spawn_enfermaria(pos: Vector2) -> Node2D:
	var inf: Node2D = ENFERMARIA_SCENE.instantiate()
	inf.extra = true
	inf.name = "EnfermariaExtra%d" % (extra_enfermarias().size() + 1)
	inf.position = pos
	get_parent().add_child(inf)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()
	return inf


## O canteiro terminou (canteiro.gd chama o dono do tipo).
func finish_build(kind: String, pos: Vector2) -> void:
	if kind == "enfermaria":  # Bloco 47
		var inf := spawn_enfermaria(pos)
		inf.pop_in()
		Audio.recruit()
		var hh := get_tree().get_first_node_in_group("hud")
		if hh:
			hh.show_toast("Nova enfermaria pronta! Mais leitos pra quem se machuca (o médico vai pra que precisa).", Color(0.55, 1.0, 0.5))
		return
	if kind == "desbravar":  # Bloco 67
		var env0 := get_tree().get_first_node_in_group("environment")
		if env0:
			env0.set_leste_aberto(true)
		Audio.fanfare()
		var hd := get_tree().get_first_node_in_group("hud")
		if hd:
			hd.show_banner("O LESTE ESTÁ ABERTO!", "Floresta nova, a encosta rochosa e outra pedreira com mais jazidas. Dá pra construir lá.")
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("focus_on") and env0:
			cam.bounds = env0.world_rect()
		return
	if kind == "ferrovia":  # Bloco 79
		var nv := preload("res://scripts/core/niveis.gd").do_ponto(get_tree().get_first_node_in_group("environment"), pos)
		if nv:
			spawn_ferrovia(String(nv.id), pos)
		Audio.recruit()
		var hf := get_tree().get_first_node_in_group("hud")
		if hf:
			hf.show_toast("Ferrovia pronta no %s! Os mineradores de lá entregam na estação e o carrinho sobe pro armazém." % (nv.id if nv else "?"), Color(0.55, 1.0, 0.5))
		return
	if kind == "vagonete":  # Bloco 64
		spawn_vagonete(pos)
		Audio.recruit()
		var hv := get_tree().get_first_node_in_group("hud")
		if hv:
			hv.show_toast("Trilho pronto! Os mineradores perto dele entregam no ponto de carga; o vagonete leva pro armazém.", Color(0.55, 1.0, 0.5))
		return
	if kind == "igreja":  # Bloco 88
		var ig := spawn_igreja(pos)
		ig.pop_in()
		Audio.recruit()
		var hi := get_tree().get_first_node_in_group("hud")
		if hi:
			var cal := get_tree().get_first_node_in_group("calendario")
			hi.show_toast("Igreja pronta! %s" % ("Missa no domingo às 09:00." if cal and cal.padre() != null else "Quando o padre chegar, tem missa no domingo."), Color(0.55, 1.0, 0.5))
		return
	if kind == "armazem":  # Bloco 97
		var an := spawn_armazem(pos)
		if an.has_method("show_popup"):
			an.show_popup("Armazém novo!", Color(0.55, 1.0, 0.5))
		Audio.recruit()
		var han := get_tree().get_first_node_in_group("hud")
		if han:
			han.show_toast("Armazém novo pronto! Mais espaço, e quem trabalha perto entrega aqui (e o engenheiro busca aqui).", Color(0.55, 1.0, 0.5))
		return
	if kind in OBRAS_107:  # Bloco 107: horta, estufa, carvoaria, curtume
		var o107 := spawn_obra107(kind, pos)
		if o107.has_method("pop_in"):
			o107.pop_in()
		Audio.recruit()
		var h107 := get_tree().get_first_node_in_group("hud")
		if h107:
			var dica: String = {"horta": "Dê a função AGRICULTOR a alguém (sem agricultor, o caçador colhe).",
				"estufa": "Dê a função AGRICULTOR a alguém: no inverno ela rende mais que a horta aberta.",
				"carvoaria": "Encomende carvão vegetal (clique nela): um LENHADOR opera.",
				"curtume": "Encomende couro curtido (clique nele): um CAÇADOR opera.",
				"escola": "As crianças vêm estudar no horário de trabalho (sem professor): estudam e se animam."}[kind]
			h107.show_toast("%s pront%s! %s" % [String(OBRAS_107[kind].nome).capitalize(), "a" if OBRAS_107[kind].f else "o", dica], Color(0.55, 1.0, 0.5))
		return
	if kind == "carpintaria":  # Bloco 94
		var ca := spawn_carpintaria(pos)
		ca.pop_in()
		Audio.recruit()
		var hc := get_tree().get_first_node_in_group("hud")
		if hc:
			hc.show_toast("Carpintaria pronta! Encomende tábuas e camas (clique nela) e dê a função CARPINTEIRO a alguém.", Color(0.55, 1.0, 0.5))
		return
	if kind == "fornalha":  # Bloco 86
		var fo := spawn_fornalha(pos)
		fo.pop_in()
		Audio.recruit()
		var hf := get_tree().get_first_node_in_group("hud")
		if hf:
			hf.show_toast("Fornalha pronta! Encomende barras (clique nela) e dê a função FUNDIDOR a alguém.", Color(0.55, 1.0, 0.5))
		return
	if kind == "oficina":  # Bloco 58
		var o := oficina()
		if o:
			o.build_at(pos)
			if o.has_method("pop_in"):
				o.pop_in()
		Audio.recruit()
		var ho := get_tree().get_first_node_in_group("hud")
		if ho:
			ho.show_toast("Oficina pronta! Ferramentas novas liberam minérios (tecla O).", Color(0.55, 1.0, 0.5))
		return
	if kind == "coletor_minerio":  # Bloco 57
		var cm := spawn_coletor_minerio(pos)
		cm.pop_in()
		Audio.recruit()
		var hm := get_tree().get_first_node_in_group("hud")
		if hm:
			hm.show_toast("Coletor de minério pronto! Designe um minerador pra operar (clique nele).", Color(0.55, 1.0, 0.5))
		return
	if kind == "coletor":
		var col := spawn_coletor(pos)
		col.pop_in()
		Audio.recruit()
		var h := get_tree().get_first_node_in_group("hud")
		if h:
			h.show_toast("Coletor de madeira pronto! Designe um lenhador pra operar (clique nele).", Color(0.55, 1.0, 0.5))
		return
	if kind != "comedouro":
		return
	var c := spawn_comedouro(pos)
	var v := c.get_node_or_null("Visual") as Sprite2D
	if v:
		v.scale = Vector2(2.0, 0.2)
		create_tween().tween_property(v, "scale", Vector2(2, 2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.recruit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Cozinha pronta! O cozinheiro (tecla C) enche ela de comida.", Color(0.55, 1.0, 0.5))


## Cria um comedouro (também ao carregar o save, com o mesmo nome).
func spawn_comedouro(pos: Vector2, node_name: String = "", rebuild_nav: bool = true) -> Node2D:
	var c: Node2D = COMEDOURO_SCENE.instantiate()
	var n := 1
	while node_name == "" and get_parent().has_node("Comedouro" if n == 1 else "Comedouro%d" % n):
		n += 1
	c.name = node_name if node_name != "" else ("Comedouro" if n == 1 else "Comedouro%d" % n)
	c.position = pos
	get_parent().add_child(c)
	if rebuild_nav:
		var env := get_tree().get_first_node_in_group("environment")
		if env:
			env.clear_decor_under_extras()
			env.rebuild_navigation()
	return c


## HousePlacer chama quando o jogador clica num lugar válido. Só aqui a Moradias é paga.
func _confirm_house(pos: Vector2) -> bool:
	if upgrade_block_reason("moradias") != "":  # recursos podem ter mudado enquanto escolhia
		Audio.error()
		return false
	var cost := upgrade_cost("moradias")
	if not _economy().spend(cost.x, cost.y, upgrade_ore_type("moradias"), upgrade_wood("moradias")):
		return false
	# Bloco 31: o nível sobe já (o preço da próxima casa não repete), mas a casa nasce
	# como CANTEIRO e o +limite de ipezinhos só entra quando ela fica pronta.
	var build_seconds := build_time("moradias")
	upgrades.moradias += 1
	var casa := spawn_house(pos)
	casa.start_construction(build_seconds)
	_popup("Casa encomendada — precisa de engenheiro", Color(1.0, 0.8, 0.45))
	Audio.click()
	return true


## A casa terminou (chamado pela própria casa): agora sim entra o limite de ipezinhos.
func on_house_built(casa: Node) -> void:
	obra_pronta.emit("casa")  # Bloco 100
	if casa.get("starter_house"):
		# Bloco 37: casa inicial — o limite inicial de ipezinhos já conta com ela
		_popup("Casa inicial pronta! (4 camas)", Color(0.55, 1.0, 0.5))
		Audio.recruit()
		return
	var eco := _economy()
	if eco:
		eco.max_workers += workers_per_moradia
	_popup("Casa pronta! +%d camas" % casa.beds_total(), Color(0.55, 1.0, 0.5))  # Bloco 101: a capacidade são as camas
	Audio.recruit()
	upgrade_bought.emit("moradias", upgrades.moradias)


## Casas encomendadas que ainda estão em obra (não contam no limite de ipezinhos ainda).
func pending_houses() -> int:
	return get_tree().get_nodes_in_group("casas").filter(
		func(c): return c.has_method("obra_pending") and c.obra_pending()).size()


## Cria uma casa construída pelo jogador (também usado ao carregar o save).
func spawn_house(pos: Vector2, house_name: String = "", rebuild_nav: bool = true) -> Node2D:
	var casa: Node2D = CASA_SCENE.instantiate()
	casa.name = house_name if house_name != "" else _next_house_name()
	casa.position = pos
	casa.placed_by_player = true
	get_parent().add_child(casa)
	if rebuild_nav:
		var env := get_tree().get_first_node_in_group("environment")
		if env:
			env.rebuild_navigation()
	return casa


func _next_house_name() -> String:
	var n := 1
	while get_parent().has_node("CasaNova%d" % n):
		n += 1
	return "CasaNova%d" % n


# ------------------------------------------------------------ internos
func _economy() -> Node:
	return get_tree().get_first_node_in_group("economy")


## Limite de ipezinhos sem as Moradias (pra mostrar o efeito na UI).
func _base_max_workers() -> int:
	var eco := _economy()
	var current: int = eco.max_workers if eco else 0
	return current - workers_per_moradia * (upgrades.moradias - pending_houses())


func _base_recovery_time() -> float:
	var w := get_tree().get_first_node_in_group("ipezinhos")
	return w.recovery_time if w else 30.0


func _update_visual() -> void:
	# Bloco 38: um quadro por estágio; durante a troca quem manda é o _grow_to_stage
	if not _growing:
		_visual.frame = _stage_index()
		_apply_stage_look(_stage_index())
	# expansão em obra: o próximo estágio sobe por estágios de obra (Prompt 28)
	var expanding := pending_upgrade == "expandir" and level < max_level()
	if not _growing:
		_next_stage.visible = expanding
		if expanding:
			_next_stage.frame = clampi(level, 0, 4)
			ObraEstagio.apply(_next_stage, obra_progress())
	_name_label.text = "Centro da Vila\n%s" % stage_name()
	if obra_pending():
		_name_label.text += "\nobra: " + obra_status()


# ------------------------------------------------------------ aparência por estágio (Bloco 38)
func _stage_index() -> int:
	return clampi(level - 1, 0, STAGE_TOP.size() - 1)


## Texto, luz, sombra do tamanho do prédio do estágio i.
func _apply_stage_look(i: int) -> void:
	_name_label.position.y = STAGE_TOP[i] - 40.0
	var l: Vector3 = STAGE_LIGHT[i]
	_window_light.position = Vector2(l.x, l.y)
	_window_light.energy = l.z
	_window_light.texture_scale = STAGE_LIGHT_SCALE[i]
	_shadow.scale = Vector2(5.2 * STAGE_HALF_W[i] / 58.0, 2.6)


## Subiu de estágio: a obra do prédio novo termina (a cor crua vira a de verdade em ~0,6 s) e
## só então vira o quadro de verdade (sem troca seca), com poeira e um "assentar" de leve.
func _grow_to_stage(i: int) -> void:
	_growing = true
	_next_stage.frame = i
	_next_stage.visible = true
	ObraEstagio.clear(_next_stage)
	_next_stage.modulate = ObraEstagio.TINT[2]
	var tw := create_tween()
	tw.tween_property(_next_stage, "modulate", Color.WHITE, 0.6)
	tw.tween_callback(func():
		_visual.frame = i
		_next_stage.visible = false
		_growing = false
		_apply_stage_look(i)
		_visual.scale = Vector2(2.08, 1.92)
		create_tween().tween_property(_visual, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	_stage_dust(i)


func _stage_dust(i: int) -> void:
	var d := CPUParticles2D.new()
	d.one_shot = true
	d.explosiveness = 0.85
	d.amount = 36
	d.lifetime = 1.1
	d.position = Vector2(0, -12)
	d.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	d.emission_rect_extents = Vector2(STAGE_HALF_W[i], 10)
	d.direction = Vector2(0, -1)
	d.spread = 80.0
	d.gravity = Vector2(0, -8)
	d.initial_velocity_min = 12.0
	d.initial_velocity_max = 40.0
	d.scale_amount_min = 3.0
	d.scale_amount_max = 6.0
	d.color = Color(0.72, 0.64, 0.54, 0.6)
	add_child(d)
	d.emitting = true
	get_tree().create_timer(1.6).timeout.connect(d.queue_free)


func _popup(text: String, color: Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03))
	popup.add_theme_constant_override("outline_size", 4)
	popup.add_theme_font_size_override("font_size", Tipo.MAPA_POPUP)
	# empilha se já houver outro aviso subindo (ex.: expandir + melhorar em seguida)
	var stacked := get_children().filter(func(c): return c.has_meta("popup")).size()
	popup.set_meta("popup", true)
	popup.position = Vector2(-100, -150 - stacked * 20)
	popup.size = Vector2(200, 20)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.z_index = 20
	add_child(popup)
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 30.0, 1.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.8)
	tween.chain().tween_callback(popup.queue_free)
	var bump := create_tween()
	bump.tween_property(_visual, "scale", Vector2(2.1, 1.9), 0.08)
	bump.tween_property(_visual, "scale", Vector2(2, 2), 0.14)


# ------------------------------------------------------------ save/load (SaveManager)
## O efeito das melhorias NÃO é reaplicado aqui: max_workers vem salvo na
## economia e as casas construídas vêm salvas em cada casa.
func get_save_data() -> Dictionary:
	return {"level": level, "upgrades": upgrades.duplicate(), "pending_upgrade": pending_upgrade,
		"upgrade_left": upgrade_left, "upgrade_total": upgrade_total, "obra": _obra.get_save_data(),
		"founded": founded, "starter_houses_left": starter_houses_left,
		"coletores": coletores().map(func(c): return c.get_save_data()),  # Bloco 81: + etapa da restauração e "fixo"
		"fornalhas": fornalhas().map(func(f): return f.get_save_data()),  # Bloco 86: lugar + fila de ordens
		"carpintarias": carpintarias().map(func(f): return f.get_save_data()),  # Bloco 94: lugar + fila de ordens
		"carvoarias": carvoarias().map(func(f): return f.get_save_data()),  # Bloco 107: lugar + fila de ordens
		"curtumes": curtumes().map(func(f): return f.get_save_data()),  # Bloco 107: lugar + fila de ordens
		"escolas": escolas().map(func(f): return f.get_save_data()),  # Bloco 111: lugar
		# Bloco 107: as hortas e estufas que o jogador construiu (a da clareira, da cena, só some na partida nova)
		"hortas": (hortas() + estufas()).map(func(h): return {"estufa": h.estufa, "position": SaveUtil.vec2_to_array(h.global_position), "dados": h.get_save_data()}),
		"armazens_novos": armazens_novos().map(func(a): return {"name": String(a.name), "position": SaveUtil.vec2_to_array(a.global_position)}),  # Bloco 97
		"coletores_minerio": coletores_minerio().map(func(c): return {"position": SaveUtil.vec2_to_array(c.global_position),
			"total": c.total_produced, "jazida": SaveUtil.vec2_to_array(c.chosen_pos) if c.chosen_pos != Vector2.INF else [],
			"desgaste": c._desgaste.get_save_data()}),  # Bloco 57 (Bloco 105: o desgaste)
		"vagonetes": vagonetes().map(func(v): return v.get_save_data()),  # Bloco 64
		"ferrovias": ferrovias().map(func(v): return v.get_save_data()),  # Bloco 79
		"estacao_mina": estacao_mina().get_save_data() if estacao_mina() else {},  # Bloco 74
		"leste_aberto": get_tree().get_first_node_in_group("environment").leste_aberto if get_tree().get_first_node_in_group("environment") else false,  # Bloco 67
		"enfermarias_extra": extra_enfermarias().map(func(w): return SaveUtil.vec2_to_array(w.global_position))}  # Bloco 47


func load_save_data(d: Dictionary) -> void:
	level = clampi(SaveUtil.integer(d, "level", level), 1, max_level())
	var saved := SaveUtil.dict(d, "upgrades")
	for id in UPGRADE_IDS:
		upgrades[id] = clampi(SaveUtil.integer(saved, id, upgrades[id]), 0, upgrade_max(id))
	# Bloco 31 (save antigo: nenhuma obra pendente)
	var p := SaveUtil.text(d, "pending_upgrade", "")
	pending_upgrade = p if (p in UPGRADE_IDS and p != "moradias" and upgrades[p] < upgrade_max(p)) \
		or (p == "expandir" and level < max_level()) else ""
	upgrade_total = maxf(SaveUtil.num(d, "upgrade_total", 0.0), 0.0) if pending_upgrade != "" else 0.0
	upgrade_left = clampf(SaveUtil.num(d, "upgrade_left", upgrade_total), 0.0, upgrade_total)
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
	# Bloco 37 (save antigo: fundada, sem casas iniciais — ela já tinha as da cena)
	founded = SaveUtil.boolean(d, "founded", true)
	starter_houses_left = clampi(SaveUtil.integer(d, "starter_houses_left", 0), 0, starter_houses)
	_load_coletores(d)
	# Bloco 86: fornalhas (save antigo: nenhuma)
	for old in fornalhas():
		old.get_parent().remove_child(old)
		old.queue_free()
	for fd in SaveUtil.array(d, "fornalhas"):
		if typeof(fd) != TYPE_DICTIONARY:
			continue
		var fpos := SaveUtil.vec2(fd, "position", Vector2.INF)
		if fpos != Vector2.INF:
			spawn_fornalha(fpos).load_save_data(fd)
	# Bloco 97: armazéns construídos pelo jogador (o estoque de cada um vem depois, pelo nome: "armazens")
	for old in armazens_novos():
		old.get_parent().remove_child(old)
		old.queue_free()
	for ad in SaveUtil.array(d, "armazens_novos"):
		if typeof(ad) != TYPE_DICTIONARY:
			continue
		var apos := SaveUtil.vec2(ad, "position", Vector2.INF)
		if apos != Vector2.INF:
			spawn_armazem(apos, SaveUtil.text(ad, "name", ""))
	# Bloco 94: carpintarias (save antigo: nenhuma)
	for old in carpintarias():
		old.get_parent().remove_child(old)
		old.queue_free()
	for cd in SaveUtil.array(d, "carpintarias"):
		if typeof(cd) != TYPE_DICTIONARY:
			continue
		var cpos := SaveUtil.vec2(cd, "position", Vector2.INF)
		if cpos != Vector2.INF:
			spawn_carpintaria(cpos).load_save_data(cd)
	# Bloco 107: carvoarias e curtumes (save antigo: nenhum)
	for par in [["carvoaria", "carvoarias"], ["curtume", "curtumes"], ["escola", "escolas"]]:  # (Bloco 111: escolas; save antigo: nenhuma)
		var vivos: Array = obras107(par[0]).filter(func(n): return n.get_parent() == get_parent())  # (só os desta cena: a cena velha, saindo, ainda está nos grupos)
		for od in SaveUtil.array(d, par[1]):
			if typeof(od) != TYPE_DICTIONARY:
				continue
			var opos := SaveUtil.vec2(od, "position", Vector2.INF)
			if opos != Vector2.INF:
				_reaproveita_ou_cria(par[0], opos, vivos).load_save_data(od)
		for old in vivos:  # sobrou: não está no save
			old.get_parent().remove_child(old)
			old.queue_free()
	# Bloco 107: hortas e estufas construídas. Save COM a chave: a horta da clareira (da cena) sai (a vila é do jogador);
	# save antigo (sem a chave): a horta da cena continua como era e nada extra.
	if d.has("hortas"):
		var vivas: Array = (hortas() + estufas()).filter(func(n): return n.get_parent() == get_parent())
		for hd in SaveUtil.array(d, "hortas"):
			if typeof(hd) != TYPE_DICTIONARY:
				continue
			var hpos := SaveUtil.vec2(hd, "position", Vector2.INF)
			if hpos != Vector2.INF:
				var tipo := "estufa" if SaveUtil.boolean(hd, "estufa", false) else "horta"
				_reaproveita_ou_cria(tipo, hpos, vivas).load_save_data(SaveUtil.dict(hd, "dados"))
		for old in vivas:  # sobrou: não está no save (a horta da clareira, numa partida nova)
			old.get_parent().remove_child(old)
			old.queue_free()
		_coletor_mudou()
	# Bloco 57: coletores de minério (save antigo: nenhum; o operador se religa sozinho)
	for old in coletores_minerio():
		old.get_parent().remove_child(old)
		old.queue_free()
	for cd in SaveUtil.array(d, "coletores_minerio"):
		if typeof(cd) != TYPE_DICTIONARY:
			continue
		var mpos := SaveUtil.vec2(cd, "position", Vector2.INF)
		if mpos != Vector2.INF:
			var cm := spawn_coletor_minerio(mpos)
			cm.total_produced = maxf(SaveUtil.num(cd, "total", 0.0), 0.0)
			cm.chosen_pos = SaveUtil.vec2(cd, "jazida", Vector2.INF)
			cm._desgaste.load_save_data(SaveUtil.dict(cd, "desgaste"))  # Bloco 105 (save antigo: novo)
	# Bloco 67: o leste (save antigo: trancado)
	var envl := get_tree().get_first_node_in_group("environment")
	if envl and envl.has_method("set_leste_aberto"):
		envl.set_leste_aberto(SaveUtil.boolean(d, "leste_aberto", false), false)
	# Bloco 64: pontos de carga com o trilho e o vagonete (save antigo: nenhum)
	for old in vagonetes():
		if is_instance_valid(old.rail):
			old.rail.queue_free()
		old.get_parent().remove_child(old)
		old.queue_free()
	for vd in SaveUtil.array(d, "vagonetes"):
		if typeof(vd) != TYPE_DICTIONARY:
			continue
		var vpos := SaveUtil.vec2(vd, "position", Vector2.INF)
		if vpos != Vector2.INF:
			var v := spawn_vagonete(vpos)
			v.load_save_data(vd)
	# Bloco 79: as estações da ferrovia de carga (save antigo: nenhuma)
	for old in ferrovias():
		if is_instance_valid(old.rail):
			old.rail.queue_free()
		old.remove_from_group("ferrovias")
		old.remove_from_group("pontos_carga")
		old.get_parent().remove_child(old)
		old.queue_free()
	for fd in SaveUtil.array(d, "ferrovias"):
		if typeof(fd) != TYPE_DICTIONARY:
			continue
		var fpos := SaveUtil.vec2(fd, "position", Vector2.INF)
		var fid := SaveUtil.text(fd, "ferrovia", "")
		if fpos != Vector2.INF and fid in FERROVIA_ANDARES:
			var f := spawn_ferrovia(fid, fpos)
			f.load_save_data(fd)
	var em := estacao_mina()  # Bloco 74 (save de antes: o da mina começa vazio)
	if em and not SaveUtil.dict(d, "estacao_mina").is_empty():
		em.load_save_data(SaveUtil.dict(d, "estacao_mina"))
	# Bloco 47: enfermarias extras (save antigo: nenhuma)
	for old in extra_enfermarias():
		old.get_parent().remove_child(old)
		old.queue_free()
	for epos in SaveUtil.positions(d, "enfermarias_extra"):
		spawn_enfermaria(epos)
	_update_visual()
	_refresh_galleries(false)  # Bloco 33: galerias batem com o estágio carregado
