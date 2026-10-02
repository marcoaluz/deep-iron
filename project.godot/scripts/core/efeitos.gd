extends RefCounted
## Bloco 54: opção "Reduzir efeitos" (Configurações; [video] reduzir_efeitos no settings.cfg).
## Menos partículas de clima (chuva, neve, folhas, pólen), sem neblina, sem o ar tremendo do calor
## e a onda solar mais fraca. Quem tem efeito pergunta Efeitos.reduzidos(); quem precisa refazer
## algo na troca fica no grupo "efeitos" com efeitos_mudaram().
##   const Efeitos := preload("res://scripts/core/efeitos.gd")

const Settings := preload("res://scripts/core/settings.gd")
## Quanto sobra das partículas de clima com a opção ligada.
const PARTICULAS := 0.3

static var _cache := -1


static func reduzidos() -> bool:
	if _cache < 0:
		_cache = 1 if Settings.get_value("video", "reduzir_efeitos", false) else 0
	return _cache == 1


static func set_reduzidos(on: bool, tree: SceneTree = null) -> void:
	Settings.set_value("video", "reduzir_efeitos", on)
	_cache = 1 if on else 0
	if tree:
		tree.call_group("efeitos", "efeitos_mudaram")


## Quantidade de partículas com a opção (mínimo 1).
static func qtd(base: int) -> int:
	return maxi(int(round(base * (PARTICULAS if reduzidos() else 1.0))), 1)
