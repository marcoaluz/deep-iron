extends Node
## Bloco 113: a DIFICULDADE da partida (nó "Dificuldade" da cena principal, grupos "dificuldade" e "modificadores").
## Escolhida na tela de Nova partida (start_menu → nova_partida_panel.gd → SaveManager.start_new_game), vale a partida
## inteira e vai no save (chave "dificuldade"; save antigo = Normal).
##
## Perfis: Tranquilo, Normal, Ferro e Criativo (um .tres cada em data/dificuldade/, perfil_dificuldade.gd) e o
## Personalizado (o Normal com os números que o jogador ajustou). Como o perfil chega no jogo:
##   - os valores ABSOLUTOS (dia da 1ª invasão, de quantos em quantos dias, vida por onda, chance da onda de verão, ultimato
##     da greve) são escritos UMA vez nos @export de Defesa, Sol e Moral (aplica()); a comida inicial é lida pelo
##     comedouro novo (comida_inicial());
##   - a fome e o preço de venda entram como chaves do Modificadores ("fome" e "preco_venda", como as Políticas do Bloco 108);
##   - o Criativo pergunta por sem_invasao() (defense.gd) e pelo pacote maior da Fundação (founding.gd).
## O NORMAL NUNCA ESCREVE NADA: o jogo fica exatamente como era (e os testes antigos, que ajustam esses @export à mão,
## seguem valendo). O teste b113 confere que o normal.tres é igual aos @export de lá.

const Perfil := preload("res://scripts/core/perfil_dificuldade.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")

const PERFIS := ["tranquilo", "normal", "ferro", "personalizado", "criativo"]
const PADRAO := "normal"
const PASTA := "res://data/dificuldade/"
## A estação do "verão" na lista de sun.gd (Primavera, Verão, Outono, Inverno).
const VERAO := 1

var perfil_id: String = PADRAO
## Os 8 números do Personalizado (chave de Perfil.AJUSTAVEIS -> valor).
var custom: Dictionary = {}
var _perfil: Resource


func _ready() -> void:
	add_to_group("dificuldade")
	add_to_group("modificadores")
	if _perfil == null:
		_perfil = perfil_de(perfil_id, custom)


## O perfil `id` (o do arquivo, ou o Normal com os `numeros` do Personalizado). Id estranho = Normal.
static func perfil_de(id: String, numeros: Dictionary = {}) -> Resource:
	var arquivo := PASTA + (id if id != "personalizado" else PADRAO) + ".tres"
	var base: Resource = load(arquivo) if id in PERFIS and ResourceLoader.exists(arquivo) else load(PASTA + PADRAO + ".tres")
	var p: Resource = base.duplicate()  # (o recurso carregado é compartilhado: nunca mexer nele)
	if id == "personalizado":
		p.id = "personalizado"
		p.nome = "Personalizado"
		p.descricao = "Você ajusta cada número."
		p.poe_numeros(numeros)
	return p


func perfil() -> Resource:
	return _perfil


func nome() -> String:
	return String(_perfil.nome)


## Escolha da tela de Nova partida: {perfil, custom}. Chamado ao começar a partida (e pelos testes).
func escolhe(escolha: Dictionary) -> void:
	var id := SaveUtil.text(escolha, "perfil", PADRAO)
	perfil_id = id if id in PERFIS else PADRAO
	custom = SaveUtil.dict(escolha, "custom").duplicate()
	_perfil = perfil_de(perfil_id, custom)
	custom = _perfil.numeros() if perfil_id == "personalizado" else {}  # (já dentro das faixas)
	aplica()


## Escreve os valores do perfil nos @export de Defesa, Sol e Moral. O Normal não escreve nada.
func aplica() -> void:
	if perfil_id == PADRAO or not is_inside_tree():
		return
	var p := _perfil
	var def := get_tree().get_first_node_in_group("defense")
	if def:
		def.first_invasion_day = p.primeira_invasao_dia
		def.invasion_every = p.invasao_a_cada
		def.hp_growth = p.vida_por_onda
	var sun := get_tree().get_first_node_in_group("sun")
	if sun:
		sun.season_wave_chance[VERAO] = p.onda_verao
	var moral := get_tree().get_first_node_in_group("morale")
	if moral:
		moral.strike_ultimatum = p.ultimato_greve


## Modificadores.mult: a fome e o preço de venda.
func mult(chave: String, _quem: Node = null) -> float:
	match chave:
		"fome":
			return _perfil.fome_mult
		"preco_venda":
			return _perfil.preco_venda_mult
	return 1.0


## A comida que o comedouro novo traz (o Normal devolve o que o comedouro já trazia).
func comida_inicial(base: float) -> float:
	return base if perfil_id == PADRAO else float(_perfil.comida_inicial)


## Criativo: sem invasões (nem moradores hostis).
func sem_invasao() -> bool:
	return bool(_perfil.sem_invasao)


## Criativo: o pacote da Fundação sai multiplicado e com créditos a mais.
func recursos_pacote_mult() -> float:
	return float(_perfil.recursos_pacote_mult)


func creditos_extras() -> int:
	return int(_perfil.creditos_extras)


# ------------------------------------------------------------ save
func get_save_data() -> Dictionary:
	return {"perfil": perfil_id, "custom": custom.duplicate()}


## Save antigo (sem a chave): Normal. Perfil desconhecido também.
func load_save_data(d: Dictionary) -> void:
	escolhe(d)
