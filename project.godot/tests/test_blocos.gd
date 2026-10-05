extends GutTest
## Bloco 43: roda os testes de cada bloco pelo GUT (painel ou linha de comando).
##
## Os testes de bloco (tests/blocos/*.gd) são scripts SceneTree que abrem a partida
## inteira (main.tscn), mexem nela e imprimem "OK"/"FALHOU" e no fim "FALHAS: N". Eles
## precisam de um Godot só deles, então cada teste aqui chama um Godot headless separado
## e confere a saída. Nada de jogo muda: isto só organiza e roda o que já existia.
##
## SEGURANÇA DO SAVE: o Godot filho roda com a pasta de usuário trocada (APPDATA /
## XDG_DATA_HOME) por uma pasta temporária "fake_appdata". Os próprios testes ainda
## abortam se não estiverem nela — o save de verdade nunca é tocado.
##
## Leva tempo: cada bloco abre a partida e espera coisas acontecerem (≈ 1 a 4 min cada).
## Dá pra rodar um só pelo painel (clique no teste) ou pela linha de comando
## (-gunit_test_name=b35). Ver TESTING.md na raiz do repositório.

const BLOCOS := "res://tests/blocos/"

## Linhas que contam como falha na saída do teste de bloco.
const BAD := ["FALHOU", "TIMEOUT", "ABORTADO", "Parse Error"]


## Pasta de usuário de mentira (fora do projeto e fora do save de verdade). Cada bloco
## começa com ela LIMPA: sem save, backups nem settings.cfg de outro teste (senão uma
## preferência salva por um bloco muda o ponto de partida do seguinte).
static func fake_appdata() -> String:
	var base := OS.get_environment("TEMP")
	if base == "":
		base = OS.get_environment("TMPDIR")
	if base == "":
		base = "/tmp"
	var dir := base.path_join("deep_iron_testes").path_join("fake_appdata")
	_wipe(dir)
	DirAccess.make_dir_recursive_absolute(dir)
	return dir


## Apaga a pasta temporária dos testes (só ela: confere o nome antes).
static func _wipe(path: String) -> void:
	if not ("deep_iron_testes" in path and path.ends_with("fake_appdata")) or not DirAccess.dir_exists_absolute(path):
		return
	_wipe_inside(path)


static func _wipe_inside(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for f in d.get_files():
		DirAccess.remove_absolute(path.path_join(f))
	for sub in d.get_directories():
		_wipe_inside(path.path_join(sub))
		DirAccess.remove_absolute(path.path_join(sub))


## Roda um teste de bloco num Godot separado e confere a saída.
func run_bloco(file: String) -> void:
	var fake := fake_appdata()
	var saved := {"APPDATA": OS.get_environment("APPDATA"), "XDG_DATA_HOME": OS.get_environment("XDG_DATA_HOME")}
	OS.set_environment("APPDATA", fake)
	OS.set_environment("XDG_DATA_HOME", fake)
	var out: Array = []
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", BLOCOS + file]
	var code := OS.execute(OS.get_executable_path(), args, out, true)
	for k in saved:
		if saved[k] == "":
			OS.unset_environment(k)
		else:
			OS.set_environment(k, saved[k])
	var text := "\n".join(out)
	var bad: Array[String] = []
	var falhas := -1
	var oks := 0
	for raw in text.split("\n"):
		var l := raw.strip_edges()
		if l.begins_with("FALHAS:"):
			falhas = int(l.trim_prefix("FALHAS:").strip_edges())
		elif l.begins_with("OK") or "RESULTADO: OK" in l or "-> OK" in l:
			oks += 1
		if "SCRIPT ERROR" in l and not "Steam" in l:
			bad.append(l)
		for b in BAD:
			if b in l:
				bad.append(l)
				break
	var passed := bad.is_empty() and (falhas == 0 or (falhas < 0 and oks > 0))
	if not passed:
		gut.p("---- saída de %s (código %d) ----\n%s" % [file, code, text.right(4000)])
	assert_true(passed, "%s: %s" % [file, ("FALHAS: %d" % falhas) if bad.is_empty() else " | ".join(bad.slice(0, 4))])


# ------------------------------------------------------------ um teste por bloco
func test_manut_backups() -> void:
	run_bloco("manut_backups.gd")


func test_b25_funcoes() -> void:
	run_bloco("b25_funcoes.gd")


func test_b25_troca_funcao() -> void:
	run_bloco("b25_troca_funcao.gd")


func test_b26_outfits() -> void:
	run_bloco("b26_outfits.gd")


func test_b27_cacador_cozinheiro() -> void:
	run_bloco("b27_cacador_cozinheiro.gd")


func test_b28_cacador_outfit() -> void:
	run_bloco("b28_cacador_outfit.gd")


func test_hud_frostpunk() -> void:
	run_bloco("hud_frostpunk.gd")


func test_b29_30_item_mao_medico() -> void:
	run_bloco("b29_30_item_mao_medico.gd")


func test_b31_obras_engenheiro() -> void:
	run_bloco("b31_obras_engenheiro.gd")


func test_b31b_obras_restantes() -> void:
	run_bloco("b31b_obras_restantes.gd")


func test_b32_escavadeira_visual() -> void:
	run_bloco("b32_escavadeira_visual.gd")


func test_b33_cozinha_expansao() -> void:
	run_bloco("b33_cozinha_expansao.gd")


func test_b34_horta_clareira() -> void:
	run_bloco("b34_horta_clareira.gd")


func test_b35_arsenal_desgaste() -> void:
	run_bloco("b35_arsenal_desgaste.gd")


func test_b36_guarda_caido() -> void:
	run_bloco("b36_guarda_caido.gd")


func test_b37_fundacao_raio() -> void:
	run_bloco("b37_fundacao_raio.gd")


func test_b38_centro_por_estagio() -> void:
	run_bloco("b38_centro_por_estagio.gd")


func test_b39_economia() -> void:
	run_bloco("b39_economia.gd")


func test_b40_clima() -> void:
	run_bloco("b40_clima.gd")


func test_b41_parque() -> void:
	run_bloco("b41_parque.gd")


func test_b42_equipamento() -> void:
	run_bloco("b42_equipamento.gd")


func test_b44_vestiario() -> void:
	run_bloco("b44_vestiario.gd")


func test_b45_coletor_madeira() -> void:
	run_bloco("b45_coletor_madeira.gd")


func test_b46_menu_construcao() -> void:
	run_bloco("b46_menu_construcao.gd")


func test_b47_varios_predios() -> void:
	run_bloco("b47_varios_predios.gd")


func test_b48_janela_zoom() -> void:
	run_bloco("b48_janela_zoom.gd")


func test_p28_iso() -> void:
	run_bloco("p28_iso.gd")


func test_p28_save() -> void:
	run_bloco("p28_save.gd")


func test_p29_mapa() -> void:
	run_bloco("p29_mapa.gd")


func test_p29_predios() -> void:
	run_bloco("p29_predios.gd")


func test_p29_bonecos() -> void:
	run_bloco("p29_bonecos.gd")


func test_p29_natureza() -> void:
	run_bloco("p29_natureza.gd")


func test_p19_luz() -> void:
	run_bloco("p19_luz.gd")


func test_p17_criaturas() -> void:
	run_bloco("p17_criaturas.gd")


func test_p18_efeitos() -> void:
	run_bloco("p18_efeitos.gd")


func test_p20_interface() -> void:
	run_bloco("p20_interface.gd")


func test_p2_pendencias() -> void:
	run_bloco("p2_pendencias.gd")


func test_b51_engenheiro_estresse() -> void:
	run_bloco("b51_engenheiro_estresse.gd")


func test_b52_debug_telemetria() -> void:
	run_bloco("b52_debug_telemetria.gd")


func test_b54_configuracoes() -> void:
	run_bloco("b54_configuracoes.gd")


func test_b55_audio() -> void:
	run_bloco("b55_audio.gd")


func test_b56_casas() -> void:
	run_bloco("b56_casas.gd")


func test_b57_coletor_minerio() -> void:
	run_bloco("b57_coletor_minerio.gd")


func test_b60_dinamite_radio() -> void:
	run_bloco("b60_dinamite_radio.gd")


func test_b61_fauna() -> void:
	run_bloco("b61_fauna.gd")


func test_b62_tiers_chefe() -> void:
	run_bloco("b62_tiers_chefe.gd")


func test_b63_corte_mina() -> void:
	run_bloco("b63_corte_mina.gd")


func test_b64_vagonete() -> void:
	run_bloco("b64_vagonete.gd")


func test_b67_mapa_leste() -> void:
	run_bloco("b67_mapa_leste.gd")


func test_b68_niveis() -> void:
	run_bloco("b68_niveis.gd")


func test_b69_atmosfera() -> void:
	run_bloco("b69_atmosfera.gd")


func test_b70_fundo() -> void:
	run_bloco("b70_fundo.gd")


func test_b71_s4_s5() -> void:
	run_bloco("b71_s4_s5.gd")


func test_b72_coluna() -> void:
	run_bloco("b72_coluna.gd")


func test_b73_andar() -> void:
	run_bloco("b73_andar.gd")


func test_b74_superficie() -> void:
	run_bloco("b74_superficie.gd")


func test_b75_faixas() -> void:
	run_bloco("b75_faixas.gd")


func test_b77_areas() -> void:
	run_bloco("b77_areas.gd")
