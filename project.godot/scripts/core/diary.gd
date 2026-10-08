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
		"text": "Robôs pequenos de antes da explosão: um esqueleto de metal comido pela ferrugem, "
			+ "um crânio e dois olhos vermelhos. Passam o dia parados, acumulando restos de energia "
			+ "solar, e despertam à noite. Vivem no fundo da mina e saem pela boca do poço do elevador "
			+ "desde que abrimos o nível 2 — lá não tem muro, só os guardas. Comem metal: vão direto no "
			+ "armazém. Ao amanhecer, desligam e desmontam.",
	},
	"gosmas": {
		"title": "Gosmas ácidas",
		"text": "No nível 2 o ácido das poças ganhou vida. As Gosmas sobem pelo poço à noite, "
			+ "rápidas e moles: o golpe delas corrói o metal das armas e o ácido derrete as "
			+ "barricadas. No armazém, dissolvem o ferro e o cobre. Às vezes deixam cristal verde.",
	},
	"magmantes": {
		"title": "Magmantes",
		"text": "Pedra viva do abismo, quente por dentro. Lentos e duros de derrubar, derretem a "
			+ "barricada e, no armazém, comem o carvão. Quando caem, sobra cristal rubro no meio "
			+ "da casca.",
	},
	"cristais": {
		"title": "Cristais do fundo",
		"text": "O cristal verde cresce nas galerias de ácido do nível 2; o rubro, em volta dos "
			+ "poços de lava do abismo. Os dois valem mais que a prata e a broca da escavadeira "
			+ "também acha. Pra chegar neles, máscara de gás e traje térmico: as poças queimam.",
	},
	"nivel_S4": {
		"title": "A cachoeira do fundo",
		"text": "Embaixo do abismo a água achou o caminho: uma cachoeira despenca do teto da caverna "
			+ "sobre a rocha quente. O vapor não deixa ninguém ouvir nada, mas quem passa pela água "
			+ "fica molhado e aguenta mais perto da lava. Tem cristal de todas as cores nas paredes.",
	},
	"nivel_S5": {
		"title": "O lago azul",
		"text": "O fundo de tudo. Um lago parado de água azul, gemas brilhando na beira e casinhas de "
			+ "pedra vazias — alguém morou aqui antes da explosão, longe do sol. É o lugar mais quieto "
			+ "que a gente já viu: quem trabalha aqui volta mais calmo.",
	},
	"padre": {  # Bloco 88
		"title": "O padre",
		"text": "Um padre chegou à vila, de batina gasta e botas de mina. Diz que veio porque soube que "
			+ "aqui tinha gente cavando no escuro. Reza a missa no domingo, enterra quem se vai e escuta "
			+ "quem anda zangado — a zanga sai mais leve da igreja.",
	},
	"matriarca": {
		"title": "A Matriarca",
		"text": "Os Lumívoros têm uma rainha. É duas vezes maior, coberta de cristais roxos, e "
			+ "aparece uma vez por estação. Ela grita e chama os outros, e o golpe dela come o "
			+ "metal das armas. Quando cai, os cristais dela são solarita pura.",
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
## Bloco 100: páginas que vêm de fora do código (as missões, com o texto do arquivo do capítulo): {id: {title, text}}.
var extras := {}


## Bloco 100: registra (ou troca) o texto de uma página de fora do código.
func registra(id: String, title: String, text: String) -> void:
	extras[id] = {"title": title, "text": text}


## A página de um id (as do código e as registradas), ou {} se não existe.
func entrada(id: String) -> Dictionary:
	if ENTRIES.has(id):
		return ENTRIES[id]
	return extras.get(id, {})


func _ready() -> void:
	add_to_group("diary")


func has_page(id: String) -> bool:
	for p in pages:
		if p.id == id:
			return true
	return false


func unlock(id: String) -> void:
	if entrada(id).is_empty() or has_page(id):
		return
	var dn := get_tree().get_first_node_in_group("day_night")
	pages.append({"id": id, "day": dn.day if dn else 1})
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast("Nova página no diário: %s  (J)" % entrada(id).title, Color(0.8, 0.75, 1.0))


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {"pages": pages.duplicate(true)}


func load_save_data(d: Dictionary) -> void:
	pages = []
	for p in SaveUtil.array(d, "pages"):
		# (Bloco 100: a página de missão volta pelo id; o texto vem quando a Missoes registra — o painel só mostra as que têm)
		if typeof(p) == TYPE_DICTIONARY and str(p.get("id", "")) != "" and not has_page(str(p.id)):
			pages.append({"id": str(p.id), "day": int(p.get("day", 1))})
