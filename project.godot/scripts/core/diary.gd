extends Node
## Diário da vila (nó Diary, grupo "diary"): páginas que abrem conforme a vila descobre
## as coisas do mundo depois da explosão solar. Janela: tecla J.
## (O memorial de quem morreu vem da Enfermaria e aparece junto.)

const SaveUtil := preload("res://scripts/core/save_util.gd")
const ENTRIES := {
	"lumivoros": {
		"title": "Lumívoros",
		"text": "Criaturas que se alimentam da luz e do calor que sobraram da explosão solar. "
			+ "De dia somem; à noite são atraídas justamente pelo que nos protege: tochas, janelas "
			+ "acesas e as lanternas dos capacetes. Descem da clareira pelo túnel. A luz ajuda a "
			+ "gente a trabalhar... e chama eles.",
	},
	"ferrugentos": {
		"title": "Ferrugentos",
		"text": "Máquinas de antes da explosão, cobertas de ferrugem. Passam o dia paradas, "
			+ "acumulando restos de energia solar, e despertam à noite. Vivem no fundo da mina e "
			+ "sobem pelo poço desde que abrimos o nível 2. Comem metal: vão direto no armazém. "
			+ "Ao amanhecer, desligam.",
	},
	"robo": {
		"title": "O robô antigo",
		"text": "Achamos no fundo da mina um Ferrugento desligado, parado há décadas. Consertado "
			+ "na Oficina, ele acordou do nosso lado: de dia vigia o Centro da Vila, à noite "
			+ "patrulha as casas. Não sabemos por que ele é diferente dos outros.",
	},
	"solarita": {
		"title": "Solarita",
		"text": "Rocha do abismo que guardou a energia da explosão solar. Brilha e esquenta na "
			+ "mão; sem traje de chumbo, ninguém aguenta minerar. Vale mais que qualquer outro "
			+ "minério — e talvez seja a chave pra nos proteger do sol.",
	},
}

## Ids na ordem em que foram descobertos, com o dia: [{id, day}].
var pages: Array = []


func _ready() -> void:
	add_to_group("diary")


func has_page(id: String) -> bool:
	for p in pages:
		if p.id == id:
			return true
	return false


func unlock(id: String) -> void:
	if not ENTRIES.has(id) or has_page(id):
		return
	var dn := get_tree().get_first_node_in_group("day_night")
	pages.append({"id": id, "day": dn.day if dn else 1})
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Nova página no diário: %s  (J)" % ENTRIES[id].title, Color(0.8, 0.75, 1.0))


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"pages": pages.duplicate(true)}


func load_save_data(d: Dictionary) -> void:
	pages = []
	for p in SaveUtil.array(d, "pages"):
		if typeof(p) == TYPE_DICTIONARY and ENTRIES.has(str(p.get("id", ""))) and not has_page(str(p.id)):
			pages.append({"id": str(p.id), "day": int(p.get("day", 1))})
