extends "res://scripts/core/fornalha_panel.gd"
## Bloco 94: janela da CARPINTARIA — a janela de ordens da Fornalha (receitas, quantidade, encomendar, fila,
## cancelar, PAUSADA sem insumo) com os nomes e as chamadas do Centro da Vila da carpintaria. Nada é feito sem
## ordem (regra 9). As camas de tábua prontas vão pro armazém; trocar a cama de uma casa é na janela da casa.


func _init() -> void:
	grupo = "carpintarias"
	titulo = "CARPINTARIA"
	nome_predio = "Carpintaria"
	nome_operador = "Carpinteiro"
	nome_operadores = "Carpinteiros"
	intro_texto = "Madeira vira tábuas; tábuas e pregos viram camas de tábua — só por ORDEM: escolha a receita e a quantidade e encomende. O CARPINTEIRO busca os insumos no armazém (cada unidade gasta os dela só quando começa), serra aqui e leva o que ficou pronto pro armazém. Faltou insumo: a ordem pausa. A cama de tábua vai pra casa pela janela da casa (\"Trocar uma cama\"): o carpinteiro monta."


func _construir() -> void:
	_hub.build_carpintaria()


func _motivo_construir() -> String:
	return _hub.carpintaria_block_reason()


func _custo_construir() -> String:
	return _hub.carpintaria_cost_text()


func _estagio() -> int:
	return int(_hub.carpintaria_estagio)
