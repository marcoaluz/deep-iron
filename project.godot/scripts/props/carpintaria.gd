extends "res://scripts/props/fornalha.gd"
## Bloco 94: CARPINTARIA (grupo "carpintarias") — madeira e pregos viram tábuas e camas, SÓ POR ORDEM do
## jogador (production_queue.gd; regra 9 do CLAUDE.md). É a oficina de ordens da Fornalha com outro ofício:
##
## - Posicionada pelo jogador e erguida pelo engenheiro em etapas (canteiro "carpintaria", dono: Centro da
##   Vila; obra 1 -> 2 -> 3 -> pronto na vista iso); libera no estágio centro_vila.carpintaria_estagio.
## - Quem opera é o CARPINTEIRO / a CARPINTEIRA (ipezinho.gd, função "carpinteiro"): busca os insumos no
##   armazém, serra aqui (segundos da receita x o ritmo) e leva o que ficou pronto pro armazém. Sem ordem, nada.
## - Faltou insumo: a ordem fica PAUSADA com o aviso do que falta.
## - A cama de tábua pronta vai pro armazém; o jogador manda TROCAR a cama de uma casa (janela da casa) e o
##   carpinteiro leva e monta (casa.gd, camas boas: mais ânimo pra quem dorme nela).

@export_group("Receitas da carpintaria (Bloco 94)")
## {id, nome, insumos {item: qtd}, produto {item: qtd}, segundos (de carpinteiro por unidade), estagio}.
@export var receitas_carpintaria: Array[Dictionary] = [
	{"id": "tabua", "nome": "Tábuas (4)", "insumos": {"madeira": 3}, "produto": {"tabua": 4}, "segundos": 8.0, "estagio": 0},
	{"id": "cama_boa", "nome": "Cama de tábua", "insumos": {"tabua": 6, "prego": 8}, "produto": {"cama_boa": 1}, "segundos": 20.0, "estagio": 0},
]

@onready var _serragem: CPUParticles2D = $Serragem


func _init() -> void:
	panel_id = "carpintaria"
	grupo = "carpintarias"
	nome_predio = "Carpintaria"
	nome_operador = "carpinteiro"
	estado_trabalho = "serrando"
	verbo = "serrando"


func _ready() -> void:
	receitas = receitas_carpintaria
	super()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-50, -78), Vector2(100, 84)).has_point(p)


func decor_clear_rect() -> Rect2:
	return Rect2(global_position + Vector2(-52, -80), Vector2(104, 88))


func _accepts(body: Node2D) -> bool:
	return body.has_method("is_carpenter")


func e_operador(worker: Node) -> bool:
	return worker.has_method("is_carpenter") and worker.is_carpenter()


func _som_pronto() -> void:
	Audio.chop(global_position)


## Trabalhando: serragem voando e a lamparina da bancada acesa.
func _mostra_trabalho(ativo: bool) -> void:
	_visual.frame = 1 if ativo else 0
	_serragem.emitting = ativo
	_smoke.emitting = false
	_luz.enabled = ativo
