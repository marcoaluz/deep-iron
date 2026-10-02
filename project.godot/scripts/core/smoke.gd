extends Node
## Bloco 50: TESTE DE FUMAÇA do executável. Só roda com `-- --smoke` na linha de comando
## (tools/build_windows.ps1 chama assim, com a pasta de usuário isolada): abre o menu, começa uma
## partida nova, salva, carrega e fecha. Imprime "SMOKE OK ..." e sai com 0; qualquer passo que não
## acontece em tempo imprime "SMOKE FALHOU ..." e sai com 1.
## Por segurança, recusa rodar se a pasta de save não for uma pasta isolada (fake_appdata).

var _t := 0.0
var _passo := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var pasta := ProjectSettings.globalize_path("user://")
	print("SMOKE: pasta do save = %s" % pasta)
	if not ("fake_appdata" in pasta):
		print("SMOKE FALHOU: pasta de save não isolada (rode com APPDATA numa pasta fake_appdata)")
		get_tree().quit(1)


func _process(delta: float) -> void:
	_t += delta
	var sm := get_node("/root/SaveManager")
	match _passo:
		0:
			if _t > 2.0:
				_passo = 1
				_t = 0.0
				print("SMOKE: menu aberto, começando partida nova")
				sm.start_new_game()
		1:
			if _t > 8.0:
				if not sm.is_game_running():
					_falha("a partida não abriu")
					return
				_passo = 2
				_t = 0.0
				print("SMOKE: partida aberta (%d ipezinhos), salvando" % get_tree().get_nodes_in_group("ipezinhos").size())
				# Bloco 52: o painel de debug (F3) só existe em build de debug
				var dbg := get_tree().current_scene.get_node_or_null("DebugPanel") if get_tree().current_scene else null
				print("SMOKE: painel de debug %s (build de %s)" % ["presente" if dbg else "ausente", "debug" if OS.is_debug_build() else "release"])
				if dbg != null and not OS.is_debug_build():
					_falha("painel de debug no build de release")
					return
				if not sm.save_game("smoke"):
					_falha("não salvou")
		2:
			if _t > 1.0:
				_passo = 3
				_t = 0.0
				print("SMOKE: carregando")
				sm.load_game()
		3:
			if _t > 8.0:
				var n := get_tree().get_nodes_in_group("ipezinhos").size()
				if not sm.is_game_running() or n == 0:
					_falha("não carregou")
					return
				print("SMOKE OK: SAVE_VERSION=%d, %d ipezinhos depois de carregar" % [sm.SAVE_VERSION, n])
				get_tree().quit(0)
	if _t > 60.0:
		_falha("tempo esgotado no passo %d" % _passo)


func _falha(msg: String) -> void:
	print("SMOKE FALHOU: " + msg)
	get_tree().quit(1)
