extends "res://scripts/props/fornalha.gd"
## Bloco 107: CARVOARIA (grupo "carvoarias") — madeira vira CARVÃO VEGETAL, SÓ POR ORDEM do jogador (production_queue.gd;
## regra 9 do CLAUDE.md). É a oficina de ordens da Fornalha com o LENHADOR como operador:
##
## - Posicionada pelo jogador e erguida pelo engenheiro em etapas (canteiro "carvoaria", dono: Centro da Vila; obra 1 -> 2
##   -> 3 -> pronto); libera no estágio centro_vila.carvoaria_estagio. O material é levado pelo carregador (Bloco 105).
## - Quem opera é o LENHADOR / a LENHADORA que a vila já tem: com uma ordem na fila, UM deles larga o machado, busca a madeira
##   no armazém (ou o carregador traz), carvoeja aqui e leva o carvão pronto pro armazém. Sem ordem, o lenhador corta
##   árvore como sempre (ipezinho.gd _estado_oficina_extra).
## - O carvão vegetal vale como o mineral nas receitas da Fornalha, gastando o vegetal primeiro (items.gd EQUIVALENTES).

@export_group("Receitas da carvoaria (Bloco 107)")
## {id, nome, insumos {item: qtd}, produto {item: qtd}, segundos (de lenhador por unidade), estagio}.
@export var receitas_carvoaria: Array[Dictionary] = [
	{"id": "carvao_vegetal", "nome": "Carvão vegetal", "insumos": {"madeira": 3}, "produto": {"carvao_vegetal": 1}, "segundos": 15.0, "estagio": 0},
]


func _init() -> void:
	panel_id = "carvoaria"
	grupo = "carvoarias"
	nome_predio = "Carvoaria"
	nome_operador = "lenhador"
	estado_trabalho = "carvoejando"
	verbo = "carvoejando"


func _ready() -> void:
	receitas = receitas_carvoaria
	super()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-46, -80), Vector2(92, 84)).has_point(p)


func _accepts(body: Node2D) -> bool:
	return body.has_method("is_lumber")


func e_operador(worker: Node) -> bool:
	return worker.has_method("is_lumber") and worker.is_lumber()


func _som_pronto() -> void:
	Audio.chop(global_position)
