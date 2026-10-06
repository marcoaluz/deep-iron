extends Node2D
## Bloco 93: o CORPO de quem morreu (grupo "corpos"), envolto na mortalha, no lugar onde caiu — quando a vila tem
## cemitério. Fica ali até o padre buscar (ipezinho._padre_enterro): ele reserva, chega, pega (o corpo some daqui
## e vai nos ombros dele), leva pro cemitério e enterra. Desenhado pelo nome na vista iso (props "corpo").
## O calendario.gd salva os corpos que esperam.

var nome := ""
var dia := 1
var estacao := ""
var causa := ""
## O padre que vem buscar (null = ninguém ainda).
var reservado_por: Node = null


func monta(info: Dictionary) -> void:
	nome = String(info.get("nome", "?"))
	dia = int(info.get("dia", 1))
	estacao = String(info.get("estacao", ""))
	causa = String(info.get("causa", ""))
	name = "Corpo_" + nome.validate_node_name()
	set_meta("iso_prop", "corpo")


func _ready() -> void:
	add_to_group("corpos")


func info() -> Dictionary:
	return {"nome": nome, "dia": dia, "estacao": estacao, "causa": causa}


func livre_pra(padre: Node) -> bool:
	return reservado_por == null or not is_instance_valid(reservado_por) or reservado_por == padre
