extends RefCounted
## Prompt 23: o RETRATO de um ipezinho (assets/game/ui/retratos/, retratos/retratos.py): a mesma
## pasta do boneco (função × gênero), o tom de pele dele e a expressão pelo estado:
##   ferido/caído -> ferido; greve ou furioso -> bravo; ânimo baixo ou com fome -> cansado;
##   ânimo alto -> contente; senão neutro.

const IsoBonecos := preload("res://scripts/iso/iso_bonecos.gd")
const DIR := "res://assets/game/ui/retratos/"

static var _tex: Dictionary = {}


static func expressao(w: Node) -> String:
	if w.get("injured") == true or w.get("downed") == true:
		return "ferido"
	if w.get("_ai_state") == "strike" or int(w.get("_mood")) >= 2:
		return "bravo"
	var h: float = float(w.get("happiness")) if w.get("happiness") != null else 60.0
	var fome: float = float(w.get("hunger")) if w.get("hunger") != null else 100.0
	if (h >= 0.0 and h < 35.0) or fome < 25.0:
		return "cansado"
	if h >= 70.0:
		return "contente"
	return "neutro"


static func pasta(w: Node) -> String:
	var f: String = IsoBonecos.OUTFIT_FUNCAO.get(w.outfit() if w.has_method("outfit") else "mineiro", "minerador")
	var par: Array = IsoBonecos.data().get("funcoes", {}).get(f, ["minerador", "mineradora"])
	return par[1] if String(w.get("gender")) == "menina" else par[0]


static func de(w: Node) -> Texture2D:
	if w.has_method("e_bebe") and w.e_bebe():
		return preload("res://scripts/ui/icones.gd").tex("bebe")  # Bloco 111: o bebê é só o ícone
	var tom := IsoBonecos._tone(w)
	var p := DIR + "%s/%s__%s.png" % [pasta(w), expressao(w), tom if tom != "" else "parda"]
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]


## Retrato de criatura/robô (sem tom de pele).
static func de_nome(nome: String, expr := "neutro") -> Texture2D:
	var p := DIR + "%s/%s.png" % [nome, expr]
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]
