extends RefCounted
## Bloco 105: o DESGASTE de UMA máquina (escavadeira, coletores, ventiladores, robô). Cada dono guarda um em
## `_desgaste` e chama `gasta(fração)` quando trabalha; os números (vida, eficiência, preventiva, conserto) ficam no nó
## Manutencao (manutencao.gd), por tipo.
##
## A condição vai de 1 (nova) a 0 (quebrada). Até o desgaste de `Manutencao.desgaste_inicio_perda` (40%), a máquina rende
## 100%; daí até 0 a EFICIÊNCIA cai aos poucos até `Manutencao.eficiencia_min`; em 0 ela QUEBRA (eficiência 0) e só volta
## com o conserto (obra com material: conserto_maquina.gd). A preventiva do mecânico devolve a 1 sem material.

const SaveUtil := preload("res://scripts/core/save_util.gd")

var tipo := ""
var condicao := 1.0
var quebrada := false
## O dono (a máquina): a Manutencao recebe o aviso da quebra.
var dono: Node = null


func _init(p_tipo := "", p_dono: Node = null) -> void:
	tipo = p_tipo
	dono = p_dono


static func de(no: Object) -> RefCounted:
	if no == null or not is_instance_valid(no):
		return null
	var d = no.get("_desgaste")
	return d if d != null and d is RefCounted and d.has_method("eficiencia") else null


func _manut() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("manutencao") if tree else null


## Gasta `q` da condição (fração 0..1). Em 0, quebra (a Manutencao abre o conserto).
func gasta(q: float) -> void:
	if quebrada or q <= 0.0:
		return
	var antes := condicao
	condicao = maxf(condicao - q, 0.0)
	var m := _manut()
	if m and m.has_method("mudou_condicao"):
		m.mudou_condicao(dono, antes, condicao)
	if condicao <= 0.0:
		quebrada = true
		if m and m.has_method("quebrou"):
			m.quebrou(dono)


## O quanto a máquina rende agora (1 = normal; cai aos poucos depois do desgaste de início; 0 = quebrada).
func eficiencia() -> float:
	return 0.0 if quebrada else eficiencia_de(condicao)


## A eficiência de uma condição qualquer (as cabines e o trilho, que têm o desgaste deles, usam também).
static func eficiencia_de(c: float) -> float:
	if c <= 0.0:
		return 0.0
	var tree := Engine.get_main_loop() as SceneTree
	var m: Node = tree.get_first_node_in_group("manutencao") if tree else null
	var inicio: float = float(m.desgaste_inicio_perda) if m else 0.4
	var minimo: float = float(m.eficiencia_min) if m else 0.5
	var limite := 1.0 - inicio  # a condição em que começa a perder
	if c >= limite or limite <= 0.0:
		return 1.0
	return lerpf(minimo, 1.0, clampf(c / limite, 0.0, 1.0))


func restaura() -> void:
	condicao = 1.0
	quebrada = false


## "desgaste 35%" / "QUEBRADA" (a placa da máquina); "" = nova o bastante pra não falar.
func texto() -> String:
	if quebrada:
		return "QUEBRADA — precisa de mecânico"
	if condicao < 0.995:
		return "desgaste %d%%" % roundi((1.0 - condicao) * 100.0)
	return ""


func get_save_data() -> Dictionary:
	return {"c": condicao, "q": quebrada}


## Save antigo (sem a chave): nova (100%).
func load_save_data(d: Dictionary) -> void:
	condicao = clampf(SaveUtil.num(d, "c", 1.0), 0.0, 1.0)
	quebrada = SaveUtil.boolean(d, "q", false) or condicao <= 0.0
