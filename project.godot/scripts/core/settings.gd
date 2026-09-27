extends RefCounted
## Preferências do jogador (volumes, dicas do HUD...) em user://settings.cfg.
## Separado do save da partida: valem pra qualquer jogo, novo ou carregado.
## Uso: const Settings := preload("res://scripts/core/settings.gd")

const PATH := "user://settings.cfg"


static func get_value(section: String, key: String, default: Variant) -> Variant:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return default
	var v = cf.get_value(section, key, default)
	return v if typeof(v) == typeof(default) else default  # arquivo editado à mão com tipo errado


static func set_value(section: String, key: String, value: Variant) -> void:
	var cf := ConfigFile.new()
	cf.load(PATH)  # se não existir, começa vazio
	cf.set_value(section, key, value)
	cf.save(PATH)
