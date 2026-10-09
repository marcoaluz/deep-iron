extends "res://scripts/props/fornalha.gd"
## Bloco 107: CURTUME (grupo "curtumes") — couro cru vira COURO CURTIDO, SÓ POR ORDEM do jogador (production_queue.gd;
## regra 9 do CLAUDE.md). É a oficina de ordens da Fornalha com o CAÇADOR como operador:
##
## - Posicionado pelo jogador e erguido pelo engenheiro em etapas (canteiro "curtume", dono: Centro da Vila; obra 1 -> 2 ->
##   3 -> pronto); libera no estágio centro_vila.curtume_estagio. O material é levado pelo carregador (Bloco 105).
## - Quem opera é o CAÇADOR / a CAÇADORA: com uma ordem na fila, UM deles deixa a caça, busca o couro e a madeira (casca pro
##   curtimento) no armazém, cura aqui e leva o couro curtido pro armazém. Sem ordem, ele caça e colhe como sempre.
## - COM um curtume na vila, botas, mochila e trajes passam a pedir couro CURTIDO no lugar do cru (equipment.gd e oficina.gd);
##   sem curtume, pedem o cru como antes (o mesmo fallback das barras antes da fornalha). O casaco fica no cru.

@export_group("Receitas do curtume (Bloco 107)")
## {id, nome, insumos {item: qtd}, produto {item: qtd}, segundos (de caçador por unidade), estagio}.
@export var receitas_curtume: Array[Dictionary] = [
	{"id": "couro_curtido", "nome": "Couro curtido", "insumos": {"couro": 1, "madeira": 2}, "produto": {"couro_curtido": 1}, "segundos": 20.0, "estagio": 0},
]


func _init() -> void:
	panel_id = "curtume"
	grupo = "curtumes"
	nome_predio = "Curtume"
	nome_operador = "caçador"
	estado_trabalho = "curtindo"
	verbo = "curtindo"


func _ready() -> void:
	receitas = receitas_curtume
	super()


func contains_point(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-50, -78), Vector2(100, 84)).has_point(p)


func _accepts(body: Node2D) -> bool:
	return body.has_method("is_hunter")


func e_operador(worker: Node) -> bool:
	return worker.has_method("is_hunter") and worker.is_hunter()


func _som_pronto() -> void:
	Audio.chop(global_position)


## Trabalhando: a lamparina acesa (sem fumaça nem serragem).
func _mostra_trabalho(ativo: bool) -> void:
	_visual.frame = 1 if ativo else 0
	_smoke.emitting = false
	_luz.enabled = ativo
