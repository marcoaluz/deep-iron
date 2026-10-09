extends "res://scripts/core/fornalha_panel.gd"
## Bloco 107: janela da CARVOARIA — a janela de ordens da Fornalha (receita, quantidade, encomendar, fila, cancelar, PAUSADA
## sem insumo) com os nomes e as chamadas do Centro da Vila da carvoaria. Nada é feito sem ordem (regra 9).


func _init() -> void:
	grupo = "carvoarias"
	titulo = "CARVOARIA"
	nome_predio = "Carvoaria"
	nome_operador = "Lenhador"
	nome_operadores = "Lenhadores"
	intro_texto = "Madeira vira CARVÃO VEGETAL — só por ORDEM: escolha a quantidade e encomende. Um LENHADOR larga o machado, busca a madeira no armazém (cada unidade gasta a dela só quando começa), carvoeja aqui e leva o carvão pronto pro armazém. Faltou madeira: a ordem pausa. A Fornalha gasta o carvão vegetal ANTES do carvão de mina."


func _construir() -> void:
	_hub.build_carvoaria()


func _motivo_construir() -> String:
	return _hub.carvoaria_block_reason()


func _custo_construir() -> String:
	return _hub.carvoaria_cost_text()


func _estagio() -> int:
	return int(_hub.carvoaria_estagio)
