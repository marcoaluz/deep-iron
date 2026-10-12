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
	var pa := pasta(w)
	var t := tom if tom != "" else "parda"
	var p := DIR + "%s/%s__%s.png" % [pa, expressao(w), t]
	if not _tex.has(p):
		# Bloco 135: SEM ESPERAR — o retrato ainda chegando (aquece pediu em segundo plano), o cartão mostra o neutro da
		# mesma pessoa (ou nada) por um instante. Antes a 1ª vez de cada retrato carregava no quadro (20–60 ms).
		var st := ResourceLoader.load_threaded_get_status(p)
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS and not _espera():
			var neutro := DIR + "%s/neutro__%s.png" % [pa, t]
			return _tex.get(neutro, null)
		if st == ResourceLoader.THREAD_LOAD_LOADED or st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_tex[p] = ResourceLoader.load_threaded_get(p)
		elif ResourceLoader.exists(p):
			if _espera():
				_tex[p] = load(p)
			else:
				ResourceLoader.load_threaded_request(p, "Texture2D")
				return _tex.get(DIR + "%s/neutro__%s.png" % [pa, t], null)
		else:
			_tex[p] = null
	return _tex[p]


## Bloco 135: esperar o retrato carregar (os testes, sem janela, querem o retrato na hora).
static func _espera() -> bool:
	return DisplayServer.get_name() == "headless"


## Bloco 135: todos os retratos começam a carregar em segundo plano (o HUD chama ao montar).
static func aquece_todos() -> void:
	for pasta_r in DirAccess.get_directories_at(DIR):
		for f in DirAccess.get_files_at(DIR + pasta_r):
			var nome := f.trim_suffix(".remap").trim_suffix(".import")
			if not nome.ends_with(".png"):
				continue
			var p := DIR + pasta_r + "/" + nome
			if not _tex.has(p) and ResourceLoader.load_threaded_get_status(p) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				ResourceLoader.load_threaded_request(p, "Texture2D")


## Retrato de criatura/robô (sem tom de pele).
static func de_nome(nome: String, expr := "neutro") -> Texture2D:
	var p := DIR + "%s/%s.png" % [nome, expr]
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]
