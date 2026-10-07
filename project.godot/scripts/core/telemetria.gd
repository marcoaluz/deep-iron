extends Node
## Bloco 52: TELEMETRIA LEVE pro balanceamento. A cada dia novo do jogo, uma linha num CSV em
## user://telemetria/partida_<data_hora>.csv (só em build de editor/debug, ou com
## telemetria = true nas configurações). Nada vai pra internet.
## Resumo: python tools/resumo_telemetria.py <pasta ou arquivo>.

const COLUNAS := ["dia", "estacao", "tempo_real_s", "creditos", "ferro", "cobre", "carvao", "prata", "solarita",
	"madeira", "comida", "populacao", "feridos", "animo_medio", "mortes", "onda", "criaturas_derrubadas",
	"invasao_ativa", "pesquisas", "greve", "estagio_vila", "tier", "ultima_onda_total", "ultima_onda_derrubadas", "chefe",
	"cristal_verde", "cristal_rubro", "queimaduras_acido", "queimaduras_lava", "ventiladores", "gema_azul"]  # (Bloco 70: no fim)

var arquivo := ""
var _t0 := 0


func _ready() -> void:
	name = "Telemetria"
	add_to_group("telemetria")
	_t0 = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute("user://telemetria")
	var agora := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	arquivo = "user://telemetria/partida_%s.csv" % agora
	var f := FileAccess.open(arquivo, FileAccess.WRITE)
	if f:
		f.store_line(",".join(COLUNAS))
		f.close()
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn and dn.has_signal("day_started"):
		dn.day_started.connect(func(_d: int): registra())


func _g(grupo: String) -> Node:
	return get_tree().get_first_node_in_group(grupo)


## Uma linha com o estado da vila agora.
func registra() -> void:
	var dn := _g("day_night")
	var sun := _g("sun")
	var eco := _g("economy")
	var arm := _g("armazens")
	var mor := _g("morale")
	var defe := _g("defense")
	var res := _g("research")
	var hub := _g("village_hub")
	var fundo := _g("fundo")  # Bloco 70
	var ws := get_tree().get_nodes_in_group("ipezinhos")
	var comida := 0.0
	for c in get_tree().get_nodes_in_group("comedouros"):
		comida += float(c.get("food_stock")) if c.get("food_stock") != null else 0.0
	var mortes := 0
	for e in get_tree().get_nodes_in_group("enfermarias"):
		mortes += (e.get("memorial") as Array).size() if e.get("memorial") != null else 0
	var stock: Dictionary = arm.stock if arm else {}
	var v := [
		dn.day if dn else 0, sun.season_name() if sun and sun.has_method("season_name") else "",
		int((Time.get_ticks_msec() - _t0) / 1000.0), int(eco.credits) if eco else 0,
		int(stock.get("ferro", 0)), int(stock.get("cobre", 0)), int(stock.get("carvao", 0)), int(stock.get("prata", 0)), int(stock.get("solarita", 0)),
		int(eco.stored_wood()) if eco and eco.has_method("stored_wood") else 0, int(comida), ws.size(),
		ws.filter(func(w): return w.get("injured") == true).size(),
		snappedf(mor.average(), 0.1) if mor and mor.has_method("average") else -1,
		mortes, defe.wave if defe else 0, defe.killed_tonight if defe else 0,
		1 if defe and defe.invasion_active else 0, (res.done as Array).size() if res else 0,
		1 if mor and mor.get("on_strike") else 0, hub.level if hub and hub.get("level") != null else 0,
		defe.tier() if defe and defe.has_method("tier") else 0,
		int((defe.last_result as Dictionary).get("total", 0)) if defe and defe.get("last_result") != null else 0,
		int((defe.last_result as Dictionary).get("derrubadas", 0)) if defe and defe.get("last_result") != null else 0,
		String((defe.last_result as Dictionary).get("chefe", "")) if defe and defe.get("last_result") != null else "",
		int(stock.get("cristal_verde", 0)), int(stock.get("cristal_rubro", 0)),
		int(fundo.queimaduras.get("acido", 0)) if fundo else 0, int(fundo.queimaduras.get("lava", 0)) if fundo else 0,
		fundo.ventiladores().size() if fundo else 0, int(stock.get("gema_azul", 0))]
	var f := FileAccess.open(arquivo, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(",".join(v.map(func(x): return str(x))))
	f.close()
