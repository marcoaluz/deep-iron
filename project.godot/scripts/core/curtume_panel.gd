extends "res://scripts/core/fornalha_panel.gd"
## Bloco 107: janela do CURTUME — a janela de ordens da Fornalha com os nomes e as chamadas do Centro da Vila do curtume.
## Nada é feito sem ordem (regra 9).


func _init() -> void:
	grupo = "curtumes"
	titulo = "CURTUME"
	nome_predio = "Curtume"
	nome_operador = "Caçador"
	nome_operadores = "Caçadores"
	intro_texto = "Couro cru + madeira (a casca) viram COURO CURTIDO — só por ORDEM: escolha a quantidade e encomende. Um CAÇADOR deixa a caça, busca os insumos no armazém, cura o couro aqui e leva o curtido pro armazém. Com um curtume na vila, botas, mochila e trajes pedem couro curtido no lugar do cru (o casaco continua no cru)."


func _construir() -> void:
	_hub.build_curtume()


func _motivo_construir() -> String:
	return _hub.curtume_block_reason()


func _custo_construir() -> String:
	return _hub.curtume_cost_text()


func _estagio() -> int:
	return int(_hub.curtume_estagio)
