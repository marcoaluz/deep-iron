extends Node
## Autoload "SaveManager": salvar/carregar o progresso em JSON (user://savegame.json).
##
## Cada sistema expõe get_save_data() -> Dictionary e load_save_data(data) -> void;
## aqui só se junta tudo, escreve/lê o arquivo e decide QUANDO salvar:
##   - F5 salva, F9 carrega (teclas tratadas no main.gd);
##   - autosave a cada autosave_interval segundos (0 = desligado);
##   - ao fechar a janela (NOTIFICATION_WM_CLOSE_REQUEST).
## Rede de segurança: partida nova por cima de um save existente (Novo Jogo, ou main.tscn
## aberta direto) guarda o save em user://backups/ com data/hora no nome; ficam os
## max_backups mais recentes e a tela inicial lista e carrega qualquer um deles.
## Ajuste os números na cena res://scenes/core/save_manager.tscn (Inspector).
##
## ---------------------------------------------------------------------------
## INVENTÁRIO — estado que só vivia em memória e agora vai pro save
## (nomes reais das variáveis; "nome do nó" = chave usada pra achar o objeto):
##
##   economy.gd (nó Economy)
##     credits, recruited_count (custo do próximo recrutamento), total_earned,
##     max_workers (a melhoria Moradias aumenta em tempo de jogo), auto_sell.
##     Preços (ore_price, copper_price, coal_price) são fixos no Inspector: não vão.
##   day_night.gd (nó DayNight)
##     day, time. (_night é recalculado a partir de time.)
##   centro_vila.gd (Centro da Vila)
##     level (estágio 1-5), upgrades {moradias, enfermaria, trilhas}.
##     O EFEITO das melhorias já está salvo nos outros sistemas (max_workers,
##     casas construídas); speed_mult/recovery_mult são calculados de upgrades.
##   casa.gd (cada casa, pelo nome do nó)
##     built. Casas POSICIONADAS pelo jogador (Bloco 12) também vão em
##     "placed_houses" [{name, position}] e são recriadas antes dos ipezinhos;
##     as 3 iniciais são fixas na cena e não precisam de posição.
##     Quem dorme em qual cama é salvo no ipezinho (home + home_slot).
##   armazem.gd (cada armazém, pelo nome do nó)
##     stock {ferro, cobre, carvao}, lifetime_stored (marco dos estágios da vila).
##     total_stored é a soma do stock (recalculado).
##   mineral_node.gd (cada jazida, pelo nome do nó)
##     ore_remaining, _cooldown (esgotada/regenerando), variante do sprite
##     (índice da textura + flip, só pra ela não "mudar de cara" ao carregar).
##     _unlocked é recalculado a partir da Oficina.
##   oficina.gd (Oficina)
##     crafted {picareta_aco, lampiao}, crafting, craft_left.
##     Quais minérios estão liberados sai de crafted (TOOL_UNLOCKS).
##   enfermaria.gd (Enfermaria, Bloco 17)
##     memorial [{name, cause, severity, day, position}] — quem morreu; as cruzes
##     são recriadas a partir dele. Leitos saem de upgrades.enfermaria do Centro da Vila;
##     quem está internado não é salvo (volta andando pro leito ao carregar).
##     No ipezinho: injury_severity ("leve"/"grave") e care_left (relógio sem leito).
##   morale.gd (nó Morale, Bloco 18)
##     on_strike, strike_left (ultimato), below_time, grief (luto), festa_left,
##     last_festa_day e a taverna {position, level} (recriada antes dos ipezinhos).
##     No ipezinho: happiness (save antigo começa em happiness_start).
##   defense.gd (nó Defense, Bloco 21)
##     weapons (receitas já forjadas), wave, warned_day e o campo de treino {posição}.
##     Bloco 35: rack (armas no cavalete), broken (pra consertar), queue (fila da forja:
##     what/id/left/total/ordered_at) e o Arsenal {posição}. No ipezinho: weapon,
##     weapon_durability, broken_weapon, got_porrete. Barricadas pelo nome do nó: level, hp. No ipezinho: combat_skill
##     (e role "guarda"). Criaturas NÃO vão pro save (carregar de noite encerra a invasão).
##   diary.gd (nó Diary): pages [{id, day}].
##   sun.gd (nó Sun, Bloco 23): onda do dia (wave_today, wave_at, wave_left,
##     wave_intensity, warned), won (vitória) e o gerador do escudo {posição, etapas}.
##     A estação sai do dia (não precisa salvar).
##   research.gd (nó Research, Bloco 22): done (pesquisadas), current, progress e o
##     laboratório {posição}. Efeitos de capacidade são reaplicados ao carregar.
##     No ipezinho: role "pesquisador".
##   abyss_shaft.gd (ElevadorAbismo, Bloco 20)
##     unlocked, repairing, repair_left. Jazidas do abismo (solarita) entram em
##     "minerios"; o estoque de solarita no armazém; o Traje de chumbo na Oficina.
##   finds.gd (nó Finds, Bloco 19)
##     rare_parts, items {cristal, solar, bobina}, finds_total, deep_finds, robot_found
##     e o robô {state, position, repair_left} (quem estava sendo carregado volta pro chão).
##     Na escavadeira: reactor, built_reactors, drill_on, outage_left.
##   escavadeira.gd (Escavadeira)
##     installed {estrutura, motor, hidraulica, cabine, broca}, fabricating, fab_left.
##     complete é recalculado (todas instaladas) e NÃO repete a fanfarra/banner.
##   ipezinho.gd (cada ipezinho — recriados a partir do save)
##     name, posição, hunger, carrying, cargo_type, injured, _recovery_left,
##     _mined_since_roll, _facing, casa (nome do nó) + cama (_home_slot).
##     Estado da IA (_ai_state, estação reservada, ordem manual) NÃO é salvo:
##     ao carregar cada um decide de novo o que fazer (de noite volta pra cama).
##   comedouro.gd (cada comedouro, pelo nome do nó) — Bloco 10
##     food_stock.
##   food_source.gd (horta de cogumelos, pelo nome do nó) — Bloco 10
##     food_remaining, _cooldown.
##   ipezinho.gd — Blocos 9 e 10: anger, overtime, role (cozinheiro), food_carrying.
##   ipezinho.gd — Bloco 11: gender ("menino"/"menina") e look (variação de roupa);
##     save antigo sem esses campos sorteia uma vez e passa a guardar.
##   Bloco 13: armazem.gd wood_stored; tree_node.gd (cada árvore da clareira)
##     wood_remaining + _cooldown; ipezinho.gd role "lenhador" + wood_carrying.
##   Bloco 14: deep_shaft.gd (elevador) unlocked; jazidas do nível 2 (prata etc.)
##     entram no grupo minerios normalmente; estoque de prata no armazém.
##   Bloco 16: ipezinho.gd injury_cause ("mina"/"galho") e _chopped_since_roll.
##   Bloco 90: decoracoes.gd "decoracoes" {pecas: [[id, x, y]]} — a lista própria da decoração do jogador (as
##     tochas do mapa sorteadas pela seed não entram). Save antigo: sem decoração.
##   Bloco 106: o "estacao_mina" (o vagonete da boca, no save do Centro da Vila) ganha "etapa" (0 ruína .. 4 funcionando),
##     "pago", "progresso" e "obra" (a restauração). Save antigo sem a chave: funcionando (ninguém perde o vagonete que
##     andava). O armazém NÃO ganha chave: os compartimentos saem do nível; save antigo acima do limite de um compartimento
##     fica com tudo (só não recebe mais daquilo até abrir espaço). O ipezinho pode estar em "esperando_espaco" (estado
##     comum: no load ele decide de novo).
##   Bloco 105: "logistica" {entregas}; "manutencao" {consertos [{maquina (caminho), segundos, progresso, obra}],
##     preventivas, consertos_feitos, quebras {tipo: n}}; o ipezinho ganha as funções "carregador" e "mecânico" e
##     "entrega_mao" (o que o carregador levava volta pro armazém); a escavadeira, os coletores, o robô e cada ventilador
##     (fundo: [x, y, condição]) ganham "desgaste" {c, q}; a fornalha ganha "barras_prontas"; o comedouro "raw_local";
##     a fila de produção converte o "a caminho" em começado. Save antigo: as funções de sempre, as máquinas novas
##     inteiras (100%), nada a caminho, a cozinha sem estoque.
##   Bloco 104: "expedicoes" {reveladas [ids], em_curso [{regiao, fase, dias, volta_dia, volta_t, decisoes, ... e "saves"
##     (o save de cada ipezinho que está FORA: eles não estão no grupo da vila, então voltam por aqui)}], cadeia (0..5 a
##     cadeia do robô), sorte_robo, relatorios, voltou_de, totais}; centro_vila "upgrades" ganha "posto"; o ipezinho ganha
##     a função "batedor". Save antigo: nenhuma expedição, a floresta revelada, a cadeia no passo certo (robô achado = 5;
##     Ferrugento estudado = 1) e a sorte do robô continua como reserva (sorte_robo) se o robô ainda não apareceu.
##   Bloco 103: "catalogo" ganha "descida_liberada" [andares que o jogador mandou descer sem reconhecimento]; "defense"
##     ganha "patrulhas" {andar: guardas}; o ipezinho ganha "xp_pesquisa" e "animo_descoberta". Os CORPOS de criatura e os
##     MORADORES do fundo não entram (os moradores renascem quando o andar está aberto). Save antigo: nada liberado,
##     nenhuma patrulha, xp 0 (o andar que já estava aberto entra reconhecido pela migração do Bloco 102).
##   Bloco 102: "catalogo" {estados {id: 1 avistado / 2 estudado} (o desconhecido não entra), bruto {tipo: minério
##     desconhecido que era desse tipo}, amostras {criatura: n}, estudo_lab {id, pontos} (o plano B)}; "research" ganha
##     "guardados" (pontos dos estudos sem pesquisa); o ipezinho ganha "nota_campo" (a entrada que a pesquisadora
##     estudou e ainda vai entregar); o armazém pode ter "desconhecido" no stock (é um tipo do ores.gd). Save antigo
##     (sem a chave): o estado inicial + Estudado tudo que o jogo já tinha liberado (minério no armazém ou com jazida
##     destravada, tocas visíveis, andares abertos, criaturas com página no diário, o que as pesquisas feitas pediam).
##   Bloco 101: "migrantes" {proximo (s até o próximo grupo), esperando [{ipezinho (o save do ipezinho), name,
##     condicao, funcao, prazo}]}. Acabou o "Recrutar": "economy" ainda guarda max_workers e recruited_count (o save
##     antigo carrega), mas eles não mandam em nada — a capacidade são as camas. Save antigo: ninguém no portão, o
##     primeiro grupo no prazo de uma partida nova, a população que tinha.
##   Bloco 100: "missoes" {capitulo_liberado, cumpridas [ids], feitos {id: [índices dos objetivos]}, contadores
##     {invasoes, vendido, mortes, obras {tipo: n}}}. Save antigo (sem a chave): a campanha começa no capítulo certo —
##     refaz os contadores do estado (invasões que já passaram, mortes) e entrega o que a vila já tinha cumprido.
##   Bloco 99: "elevador" (deep_shaft.gd) ganha "etapa" (0 ruína .. 3 restaurado), "pago", "progresso", "obra" e
##     "cabine" {pos, viagens, total, quebrada, consertando, conserto_left} (cabine.gd); as plataformas (abismo e
##     "ligacoes") ganham "cabine". estacao_vagonete "rail_left" vira fração (desgaste por minério). Save antigo: o
##     elevador ABERTO vem restaurado e inteiro (etapa 3); fechado, ruína; a cabine nova, em cima. A escada em espiral
##     e quem está dentro da mina não entram no save (o mineiro volta pela boca).
##   Bloco 97: armazem.gd ganha "nivel" (1..3), "ampliando", "amp_total", "amp_left" e "obra" (a ampliação é obra
##     com material); centro_vila "armazens_novos" [{name, position}] — os armazéns construídos pelo jogador,
##     recriados pelo nome antes de "armazens" (o estoque de cada um entra pelo nome, como sempre). Save antigo:
##     nível 1, sem armazém novo; o que já está guardado fica (mesmo passando do limite: só não recebe mais).
##   Bloco 96: obras com material. Todo "obra" (ObraSite: canteiros, casa, centro_vila, coletor, escavadeira,
##     escudo, cemitério, e agora abyss_shaft, robo e barricada) ganha "necessario" {item: qtd}, "entregue"
##     {item: qtd} e "creditos" (pagos, devolvidos se cancelar) — só quando a obra tem material. ipezinho.gd
##     "material_mao" {item: qtd} (volta pro armazém ao carregar). abyss_shaft.gd e robo.gd ganham "obra";
##     barricada.gd "obra_tipo" ("" / "nivel" / "conserto"), "obra_total", "obra_left" e "obra". Save antigo:
##     obra sem "necessario" = sem material = tudo entregue (anda como antes); conserto do abismo/robô que estava
##     em andamento continua, agora com o engenheiro; barricada sem obra.
##   Bloco 94: centro_vila "carpintarias" [{position, fila [...]}] (a mesma fila da fornalha); casa.gd
##     "camas_boas" (camas de tábua montadas) e "camas_pedidas" (pagas, esperando o carpinteiro); ipezinho.gd
##     "mochila" (bool) e "wearing" aceita "botas"; equipment.gd "pool"/"broken" ganham "botas"; os novos itens
##     (tabua, cama_boa, mochila) vão no "itens" do armazém. Save antigo: nada disso (carrega com os padrões);
##     a função "carpinteiro" é um job novo; o que já foi feito/pago (lança de prata, bobinas, casa e barricada
##     nível 3, ferrovias, picareta) continua valendo — os custos novos só valem pro que for encomendado depois.
##   Bloco 93: calendario.gd "calendario" + {cemiterios [{rect [x, y, w, h], total, feito, pronto, covas [{nome, dia,
##     estacao, causa, tipo, variante, vaga}], obra}], corpos [{info {nome, dia, estacao, causa}, pos [x, y]}]} (o
##     corpo que o padre carregava volta pro chão); funerais ganham "onde" ("igreja"/"cemiterio"); morale.gd
##     "funeral_left". Save antigo: sem cemitério, sem corpos, funeral na igreja.
##   Bloco 89: caminhos.gd "caminhos" {tamanho, terra [[x, y]], cascalho [...], pedra [...]} (células da grade;
##     save antigo: sem caminhos).
##   Bloco 88: calendario.gd "calendario" {padre_chegou, escolha, escolha_dia, funerais [{nome, dia}], avisou_dia,
##     igreja [x, y]}; o padre é um ipezinho (job "padre", salvo com os outros); ipezinho.gd "animo_fe".
##     Save antigo: sem padre (chega no estágio), sem igreja, nenhum funeral.
##   Bloco 87: oficina.gd "encomendas" [fila de pregos/ferragens do ferreiro] (save antigo: nenhuma). Os custos
##     em barra são só regra (Economy.metal): nada novo no save.
##   Bloco 86: centro_vila "fornalhas" [{position, fila [{receita, quantidade, feitas, comecadas, progresso,
##     ordered_at}]}] (production_queue.gd); ipezinho.gd "barras_mao" {item: qtd}. Save antigo: nenhuma.
##   Bloco 85: ipezinho.gd "animo_social" (ânimo de ter conversado na hora social; save antigo: 0). Os
##     pontos sociais e as vagas não vão pro save (refeitos ao carregar).
##   Bloco 84: ipezinho.gd "refeicoes_hoje" [refeições feitas hoje: "cafe"/"almoco"/"jantar"] e
##     "refeicoes_perdidas" (seguidas: rende menos). Save antigo: nenhuma feita, nenhuma perdida. A agenda
##     (Schedule) não salva nada: é só horário.
##   Bloco 83: day_night "relogio": 24 (relógio de 24 h; "time" continua = segundos reais desde o amanhecer,
##     o dia inteiro = duracao_dia_real). Save antigo (sem "relogio"): o ciclo era 180 s de dia + 60 s de
##     noite — o "time" vira a mesma fração do dia/noite novos. Estações: 14 dias (sun.semanas_por_estacao).
##   Bloco 82: armazem.gd "itens" {id: quantidade} — os itens processados do catálogo (items.gd: barras, aço,
##     lingote, prego), fora do "stock" de minério. Save antigo: sem itens.
##   Bloco 81: centro_vila "coletores" ganha, em cada entrada, "fixo" (a ruína da cena), "etapa" (0 ruína ..
##     4 funcionando), "pago", "progresso" (s de engenheiro) e "obra". Save antigo (sem "fixo"): o primeiro
##     coletor construído vira o da floresta, restaurado (sem "etapa" = 4); sem coletor: a ruína (etapa 0).
##   Bloco 80: o portão do poço saiu: "barricadas"."BarricadaPoco" de save antigo é ignorado (não há o
##     nó) e ipezinho.gd downed_gate "poco" vira "" (sem brecha).
##   Bloco 77: work_areas.gd "areas_trabalho" {proximo_id, areas [{id, tipo, rect, ativa, total}]} —
##     carregado antes dos ipezinhos; ipezinho.gd area_id (religa na área; save antigo: sem área).
##   Bloco 31: obras. casa.gd build_left/build_total/obra (canteiro esperando engenheiro);
##     centro_vila.gd pending_upgrade/upgrade_left/upgrade_total/obra; oficina.gd e
##     escavadeira.gd ganham "obra" (ordered_at, a ordem da fila). Quem está trabalhando
##     não vai pro save: o engenheiro volta sozinho. Save antigo: nenhuma obra pendente.
##   Bloco 31b: "canteiros" [{kind, position, total, left, obra}] (taverna, laboratório,
##     campo, ampliação da taverna) — recriados antes dos ipezinhos; escudo.gd ganha "obra";
##     escavadeira.gd building_reactor/reactor_left/reactor_total; a expansão da vila é
##     pending_upgrade = "expandir" no centro_vila.gd.
##   Bloco 30: nada novo — "médico" é mais um valor de job; quem está de plantão
##     (enfermaria._doctors) é derivado e volta sozinho pra dentro ao carregar.
##   Bloco 27: armazem.gd raw_stored (matéria-prima); hunt_spot.gd (cada toca, grupo
##     "caca") game_remaining + cooldown; ipezinho.gd raw_carrying, raw_units, prep_left;
##     o arco e flecha é mais uma ferramenta em oficina.crafted. Save antigo: tudo zerado/cheio.
##   Bloco 25 (save_version 3): ipezinho.gd "job" substitui "role" — ocioso, minerador,
##     cozinheiro, lenhador, guarda, pesquisador. Save < 3: role "" vira "minerador"
##     (ver _migrate), então ninguém que trabalhava fica parado ao carregar.
##   Bloco 35 (save_version 4): arma por guarda com desgaste. Save < 4: cada guarda recebe a
##     melhor arma que a vila já tinha forjado (durabilidade cheia) e a forja que andava
##     sozinha (forging/forge_left) vira a primeira encomenda da fila do Arsenal.
##   Bloco 42: equipment.gd (nó Equipment) pool (durabilidade de cada casaco/traje no
##     vestiário), broken, queue; ipezinho.gd wearing {tipo: durabilidade} e leather_carrying;
##     armazem.gd leather_stored. Save antigo: vestiário vazio, ninguém vestindo nada.
##   Bloco 45: centro_vila.gd "coletor" {position, total}; ipezinho.gd operates_coletor
##     (o operador volta pro posto sozinho). Save antigo: sem coletor.
##   Bloco 47: prédios que agora podem ter vários viram LISTAS: research "labs", defense
##     "campos"/"arsenais", morale "tavernas" [{position, level}], centro_vila "coletores"
##     [{position, total}] e "enfermarias_extra" [posições]; ipezinho coletor_pos (qual
##     máquina opera). Save antigo: as chaves de um só ("lab", "campo", "arsenal",
##     "taverna", "coletor") viram lista de um; sem enfermaria extra.
##   Bloco 44: equipment.gd "vestiario" (posição do prédio). Save antigo: sem Vestiário
##     (o equipamento guardado fica contado e volta a ser usado quando ele for construído).
##   Bloco 41: morale.gd "parques" [posições] — recriados ao carregar (save antigo: nenhum).
##   Bloco 37: "layout" {hub, armazens {nome: pos}, comedouros [{name, position}]} — onde o
##     jogador fundou a vila e os comedouros que construiu. Aplicado ANTES de tudo: as casas
##     e o comedouro que vêm na cena somem e o Centro/Armazém vão pro lugar salvo. Save
##     antigo (sem "layout") fica com o layout da cena, como antes. No Centro da Vila:
##     founded, starter_houses_left; na casa: starter_house.
##   Bloco 36: ipezinho.gd downed (caído em combate) + downed_gate; a posição, a gravidade
##     e o relógio (care_left) já iam. Quem carregava NÃO vai: ao carregar ele está caído no
##     chão onde estava e o médico vem buscar de novo. Criaturas continuam fora do save.
##   Bloco 33/34: nada novo no save — galerias lacradas saem do estágio da vila e a horta
##     (pelo nome do nó) carrega já no lugar novo, na clareira.
##   camera_controller.gd (Camera2D)
##     posição e zoom (conforto: volta a olhar pro mesmo lugar).
##
##   Fica de fora (transitório ou só visual): timers de som/popup, animações,
##   partículas, seleção atual, _inside das casas, decoração do mapa (vem de
##   map_seed, sempre igual), preferências de áudio.
## ---------------------------------------------------------------------------

signal saved(path: String)
signal loaded
signal save_failed(message: String)

const Carregando := preload("res://scripts/ui/carregando.gd")
const SAVE_PATH := "user://savegame.json"
const TEMP_PATH := "user://savegame.tmp"
## Backups rotativos: "partida nova" com save existente (Novo Jogo no menu, ou main.tscn
## aberta direto no editor) move o save pra cá com data/hora no nome, em vez de
## sobrescrever um backup único. Ficam só os `max_backups` mais recentes.
const BACKUP_DIR := "user://backups"
const BACKUP_PREFIX := "savegame_backup_"
## Backup único das versões antigas do jogo: é adotado pra dentro de BACKUP_DIR no _ready.
const LEGACY_BACKUP_PATH := "user://savegame_backup.json"
## JSON ilegível vai pra cá (pra dar pra investigar), e o jogo começa do zero.
const CORRUPT_PATH := "user://savegame_corrompido.json"
## 3 = Bloco 25: função única "job" por ipezinho ("ocioso" de padrão).
## 4 = Bloco 35: arma e durabilidade por guarda; fila da forja no Arsenal.
const SAVE_VERSION := 4
## Versão 1 tinha 4 lotes fixos na cena; um lote construído vira casa posicionada no mesmo lugar.
const LEGACY_LOTS := {
	"Lote1": Vector2(-170, 245),
	"Lote2": Vector2(-530, 300),
	"Lote3": Vector2(-80, 370),
	"Lote4": Vector2(-640, 365),
}
const MAIN_SCENE := "res://scenes/game/main.tscn"
const SaveUtil := preload("res://scripts/core/save_util.gd")
const Canteiro := preload("res://scripts/props/canteiro.gd")

## Segundos entre autosaves (0 = desligado). Padrão: 3 minutos.
@export var autosave_interval: float = 180.0
## Salva sozinho ao fechar a janela.
@export var save_on_quit: bool = true
## Quantos backups com data/hora manter em user://backups (o mais antigo, por data, sai).
@export_range(1, 50) var max_backups: int = 5

## true = a próxima partida (main.tscn) deve aplicar _pending_data ao ficar pronta.
var pending_load: bool = false
var _pending_data: Dictionary = {}
var _game: Node = null  # nó Main da partida em andamento
var _autosave_timer: float = 0.0
## Já garantimos o backup do save antigo nesta partida nova?
var _backup_checked: bool = false
## Partida perdida (expulso pela greve): não salva mais nada até sair dela.
var game_over: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_auto_accept_quit(false)  # quem fecha é o _notification abaixo
	_adopt_legacy_backup()
	print("DEEP IRON: SAVE_VERSION=%d" % SAVE_VERSION)  # Bloco 50: aparece no log do build
	if "--smoke" in OS.get_cmdline_user_args():  # Bloco 50: teste de fumaça do executável
		add_child(preload("res://scripts/core/smoke.gd").new())


func _process(delta: float) -> void:
	if not is_game_running() or autosave_interval <= 0.0 or get_tree().paused:
		return
	_autosave_timer += delta
	if _autosave_timer >= autosave_interval:
		_autosave_timer = 0.0
		save_game("autosave")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save_on_quit and is_game_running():
			save_game("ao fechar")
		get_tree().quit()


# ------------------------------------------------------------ estado do arquivo
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## "none" (não existe), "ok" ou "corrupt" (existe mas não é um JSON de save).
func save_status() -> String:
	if not has_save():
		return "none"
	return "ok" if read_save() != null else "corrupt"


## Lê e valida o save principal. Retorna o Dictionary ou null se estiver ilegível.
func read_save() -> Variant:
	return read_save_file(SAVE_PATH)


## Lê e valida qualquer arquivo de save (principal ou backup), já migrado pra versão atual.
func read_save_file(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return null
	var json := JSON.new()  # (JSON.parse_string imprime erro no console; assim fica silencioso)
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	return _migrate(json.data)


## Resumo pra tela de Continuar (dia, estágio, população, quando salvou).
func save_summary() -> Dictionary:
	var data = read_save()
	return _summary_of(data) if data != null else {}


func _summary_of(data: Dictionary) -> Dictionary:
	return SaveUtil.dict(data, "summary").merged({"saved_at": SaveUtil.text(data, "saved_at", "?")})


# ------------------------------------------------------------ partida
## Chamado pelo main.gd no _ready de cada partida.
func register_game(main: Node) -> void:
	_game = main
	game_over = false
	_autosave_timer = 0.0
	if not pending_load and has_save() and not _backup_checked:
		# partida nova (ex.: rodando main.tscn direto no editor) com save antigo na pasta:
		# guarda o antigo antes que o autosave o substitua
		backup_existing_save()
	_backup_checked = true


func is_game_running() -> bool:
	return _game != null and is_instance_valid(_game) and _game.is_inside_tree()


## Menu: começa do zero. Se havia save, ele vira um backup com data/hora (user://backups).
func start_new_game() -> void:
	backup_existing_save()
	_backup_checked = true
	pending_load = false
	_pending_data = {}
	Carregando.mostra(get_tree())  # Prompt 26: a tela de carregamento com dica
	get_tree().change_scene_to_file(MAIN_SCENE)


## Menu (Continuar) ou F9: recarrega a partida a partir do arquivo.
func load_game() -> bool:
	var data = read_save()
	if data == null:
		save_failed.emit("save ilegível")
		Audio.error()
		return false
	_start_loaded(data)
	return true


## Tela inicial: carrega um backup. Antes, o save principal atual (se houver) também
## vira backup — "voltar no tempo" não apaga o presente. A partida carregada volta a
## salvar no savegame.json normal.
func load_backup(path: String) -> bool:
	var data = read_save_file(path)  # lê ANTES de mexer nos arquivos
	if data == null:
		save_failed.emit("backup ilegível")
		Audio.error()
		return false
	if save_status() == "corrupt":
		quarantine_corrupt_save()
	else:
		backup_existing_save(path)  # não deixa a poda apagar justo o backup escolhido
	_start_loaded(data)
	return true


func _start_loaded(data: Dictionary) -> void:
	_pending_data = data
	pending_load = true
	_backup_checked = true
	get_tree().paused = false
	Carregando.mostra(get_tree())  # Prompt 26: a tela de carregamento com dica
	get_tree().change_scene_to_file(MAIN_SCENE)


# ------------------------------------------------------------ backups rotativos
## Move o save atual pra user://backups/savegame_backup_AAAA-MM-DD_HH-MM-SS.json e poda
## os antigos (fica com max_backups). `protect` = caminho que a poda não pode apagar.
## Retorna o caminho do backup criado ("" se não havia save).
func backup_existing_save(protect: String = "") -> String:
	if not has_save():
		return ""
	var dir := DirAccess.open("user://")
	if dir == null:
		return ""
	if not dir.dir_exists(BACKUP_DIR.get_file()):
		dir.make_dir(BACKUP_DIR.get_file())
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	var target := "%s/%s%s.json" % [BACKUP_DIR, BACKUP_PREFIX, stamp]
	var n := 2
	while FileAccess.file_exists(target):  # dois backups no mesmo segundo
		target = "%s/%s%s_%d.json" % [BACKUP_DIR, BACKUP_PREFIX, stamp, n]
		n += 1
	# copia (a cópia nasce com a data de AGORA: a poda ordena pela data do backup,
	# não pela de quando o jogo foi salvo) e só depois tira o original
	if dir.copy(SAVE_PATH, target) != OK:
		push_warning("SaveManager: não deu pra criar o backup %s; o save fica onde está" % target)
		return ""
	dir.remove(SAVE_PATH.get_file())
	print("SaveManager: save anterior guardado em %s" % ProjectSettings.globalize_path(target))
	_prune_backups(protect)
	return target


## Backups em user://backups, do mais novo pro mais antigo (pela data do arquivo).
## Cada item: {path, file, time (unix), label ("28/09/2026 23:37"), ok, summary}.
func list_backups() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(BACKUP_DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		if not (f.begins_with(BACKUP_PREFIX) and f.ends_with(".json")):
			continue
		var path := "%s/%s" % [BACKUP_DIR, f]
		var t := FileAccess.get_modified_time(path)
		out.append({"path": path, "file": f, "time": t, "label": _local_time_label(t)})
	out.sort_custom(func(a, b): return a.time > b.time or (a.time == b.time and a.file > b.file))
	return out


## list_backups() + resumo de cada um (lê os arquivos: use só na tela inicial).
func list_backups_with_summary() -> Array[Dictionary]:
	var out := list_backups()
	for b in out:
		var data = read_save_file(b.path)
		b["ok"] = data != null
		b["summary"] = _summary_of(data) if data != null else {}
	return out


func _prune_backups(protect: String = "") -> void:
	var all := list_backups()  # mais novo primeiro
	var keep := 0
	for b in all:
		if keep < max_backups or b.path == protect:
			keep += 1
			continue
		DirAccess.remove_absolute(ProjectSettings.globalize_path(b.path))
		print("SaveManager: backup antigo removido (limite de %d): %s" % [max_backups, b.file])


## O savegame_backup.json das versões antigas vira um backup com data na pasta nova.
func _adopt_legacy_backup() -> void:
	if not FileAccess.file_exists(LEGACY_BACKUP_PATH):
		return
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists(BACKUP_DIR.get_file()):
		dir.make_dir(BACKUP_DIR.get_file())
	var t := FileAccess.get_modified_time(LEGACY_BACKUP_PATH)
	var d := Time.get_datetime_dict_from_unix_time(t + _tz_bias_seconds())
	var target := "%s/%s%04d-%02d-%02d_%02d-%02d-%02d_antigo.json" % [
		BACKUP_DIR, BACKUP_PREFIX, d.year, d.month, d.day, d.hour, d.minute, d.second]
	if FileAccess.file_exists(target) or dir.rename(LEGACY_BACKUP_PATH.get_file(), target.trim_prefix("user://")) != OK:
		return
	_prune_backups()


func _tz_bias_seconds() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _local_time_label(unix_time: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix_time + _tz_bias_seconds())
	return "%02d/%02d/%04d %02d:%02d:%02d" % [d.day, d.month, d.year, d.hour, d.minute, d.second]


## Move um save ilegível pra savegame_corrompido.json.
func quarantine_corrupt_save() -> void:
	var dir := DirAccess.open("user://")
	if dir == null or not has_save():
		return
	if dir.file_exists(CORRUPT_PATH.get_file()):
		dir.remove(CORRUPT_PATH.get_file())
	dir.rename(SAVE_PATH.get_file(), CORRUPT_PATH.get_file())


# ------------------------------------------------------------ salvar
func save_game(reason: String = "manual") -> bool:
	if not is_game_running() or game_over:
		return false
	var data := _collect()
	var json := JSON.stringify(data, "\t")
	# escreve num temporário e troca: se o jogo cair no meio, o save antigo fica inteiro
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if f == null:
		var msg := "não deu pra escrever %s (erro %d)" % [TEMP_PATH, FileAccess.get_open_error()]
		push_warning("SaveManager: " + msg)
		save_failed.emit(msg)
		return false
	f.store_string(json)
	f.close()
	var dir := DirAccess.open("user://")
	if dir.file_exists(SAVE_PATH.get_file()):
		dir.remove(SAVE_PATH.get_file())
	dir.rename(TEMP_PATH.get_file(), SAVE_PATH.get_file())
	_autosave_timer = 0.0
	print("SaveManager: jogo salvo (%s) em %s" % [reason, ProjectSettings.globalize_path(SAVE_PATH)])
	saved.emit(reason)
	return true


func _collect() -> Dictionary:
	var tree := get_tree()
	var data := {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
	}
	var singles := {
		"economy": "economy",
		"day_night": "day_night",
		"village": "village_hub",
		"oficina": "oficina",
		"escavadeira": "escavadeira",
		"elevador": "elevador",
		"abismo": "elevador_abismo",
		"enfermaria": "enfermarias",
		"morale": "morale",
		"finds": "finds",
		"defense": "defense",
		"diary": "diary",
		"research": "research",
		"sun": "sun",
		"equipment": "equipment",
		"fundo": "fundo",  # Bloco 70: ventiladores e contadores
		"areas_trabalho": "work_areas",  # Bloco 77: áreas de trabalho (os ipezinhos guardam o id da área)
		"calendario": "calendario",  # Bloco 88: padre, igreja, escolha do domingo, funerais
		"caminhos": "caminhos",  # Bloco 89: células de caminho por tipo
		"decoracoes": "decoracoes_mgr",  # Bloco 90: as peças de decoração do jogador
		"migrantes": "migrantes",  # Bloco 101: quem espera no portão e o relógio do próximo grupo
		"catalogo": "catalogo",  # Bloco 102: o que a vila avistou e estudou, o minério desconhecido, as amostras
		"expedicoes": "expedicoes",  # Bloco 104: as regiões, as expedições em curso (com quem está fora), a cadeia do robô
		"logistica": "logistica",  # Bloco 105: o contador de entregas do carregador (as em curso recomeçam)
		"manutencao": "manutencao",  # Bloco 105: os consertos abertos, as preventivas, os consertos e as quebras
		"missoes": "missoes",  # Bloco 100: a campanha (capítulo liberado, missões cumpridas, objetivos, contadores)
	}
	for key in singles:
		var node := tree.get_first_node_in_group(singles[key])
		if node and node.has_method("get_save_data"):
			data[key] = node.get_save_data()
	for key in ["casas", "armazens", "minerios", "comedouros", "coleta_comida", "arvores", "barricadas", "caca"]:
		data[key] = _collect_group(key)
	# Bloco 71: as plataformas dos níveis novos (S4, S5), pelo nome (a do abismo já vai em "abismo")
	var ligacoes := {}
	for e in tree.get_nodes_in_group("elevadores"):
		if not e.is_in_group("elevador_abismo") and e.has_method("get_save_data"):
			ligacoes[String(e.name)] = e.get_save_data()
	data["ligacoes"] = ligacoes
	# Bloco 31b: canteiros de obras encomendadas (taverna, laboratório, campo...)
	var canteiros := []
	for c in tree.get_nodes_in_group("canteiros"):
		canteiros.append(c.get_save_data())
	data["canteiros"] = canteiros
	var workers := []
	for w in tree.get_nodes_in_group("ipezinhos"):
		workers.append(w.get_save_data())
	data["workers"] = workers
	var placed := []
	for casa in tree.get_nodes_in_group("casas"):
		if casa.get("placed_by_player"):
			placed.append({"name": String(casa.name), "position": SaveUtil.vec2_to_array(casa.global_position)})
	data["placed_houses"] = placed
	data["layout"] = _collect_layout(tree)
	var cam: Node = _game.get_node_or_null("Camera2D")
	if cam:
		data["camera"] = {"position": SaveUtil.vec2_to_array(cam.ground_center() if cam.has_method("ground_center") else cam.get_screen_center_position()), "zoom": cam.zoom.x}  # Prompt 28: sempre o ponto do chão
	data["summary"] = _summary()
	return data


## {nome do nó: dados} de todos os nós de um grupo.
func _collect_group(group: String) -> Dictionary:
	var out := {}
	for node in get_tree().get_nodes_in_group(group):
		if node.has_method("get_save_data"):
			out[String(node.name)] = node.get_save_data()
	return out


func _summary() -> Dictionary:
	var tree := get_tree()
	var hub := tree.get_first_node_in_group("village_hub")
	var dn := tree.get_first_node_in_group("day_night")
	var eco := tree.get_first_node_in_group("economy")
	return {
		"day": dn.day if dn else 1,
		"stage": hub.stage_name() if hub else "",
		"workers": tree.get_nodes_in_group("ipezinhos").size(),
		"credits": int(eco.credits) if eco else 0,
	}


# ------------------------------------------------------------ carregar
## Chamado pelo main.gd quando a partida está pronta (navegação montada).
func apply_pending(main: Node) -> void:
	if not pending_load:
		return
	pending_load = false
	var data := _pending_data
	_pending_data = {}

	# ordem importa: oficina antes das jazidas (desbloqueio), casas antes dos ipezinhos (camas)
	_apply_single("day_night", SaveUtil.dict(data, "day_night"))
	_apply_single("economy", SaveUtil.dict(data, "economy"))
	_apply_layout(SaveUtil.dict(data, "layout"))  # Bloco 37: antes das casas e da navegação
	_apply_single("village_hub", SaveUtil.dict(data, "village"))
	if not SaveUtil.dict(data, "economy").has("max_workers"):
		_recompute_max_workers()
	_spawn_placed_houses(SaveUtil.array(data, "placed_houses"))
	_apply_single("morale", SaveUtil.dict(data, "morale"))  # recria a taverna (antes dos ipezinhos)
	_apply_single("defense", SaveUtil.dict(data, "defense"))  # armas, ondas e o campo de treino
	_apply_single("diary", SaveUtil.dict(data, "diary"))
	_apply_single("research", SaveUtil.dict(data, "research"))  # recria o laboratório
	_apply_single("sun", SaveUtil.dict(data, "sun"))  # ondas, vitória e o gerador do escudo
	_apply_single("equipment", SaveUtil.dict(data, "equipment"))  # Bloco 42: vestiário e fila
	_apply_single("fundo", SaveUtil.dict(data, "fundo"))  # Bloco 70: ventiladores (save antigo: nenhum)
	_apply_single("calendario", SaveUtil.dict(data, "calendario"))  # Bloco 88: refaz a igreja (antes dos ipezinhos)
	_apply_single("caminhos", SaveUtil.dict(data, "caminhos"))  # Bloco 89 (save antigo: sem caminhos)
	_apply_single("decoracoes_mgr", SaveUtil.dict(data, "decoracoes"))  # Bloco 90 (save antigo: sem decoração)
	for c in get_tree().get_nodes_in_group("canteiros"):  # (troca pelos do save)
		c.remove_from_group("canteiros")
		c.remove_from_group("obras")
		c.queue_free()
	var restored := false
	for cd in SaveUtil.array(data, "canteiros"):
		if typeof(cd) == TYPE_DICTIONARY:
			Canteiro.restore(get_tree(), cd)
			restored = true
	if restored:
		# canteiros carregados também são obstáculo na navegação (como quando encomendados)
		var env := get_tree().get_first_node_in_group("environment")
		if env:
			env.clear_decor_under_extras()
			env.rebuild_navigation()
	_apply_group("barricadas", SaveUtil.dict(data, "barricadas"))
	_apply_group("casas", SaveUtil.dict(data, "casas"))
	_apply_group("armazens", SaveUtil.dict(data, "armazens"))
	_apply_single("oficina", SaveUtil.dict(data, "oficina"))
	_apply_single("elevador", SaveUtil.dict(data, "elevador"))  # antes das jazidas (fundo tranca)
	_apply_single("elevador_abismo", SaveUtil.dict(data, "abismo"))
	var lig := SaveUtil.dict(data, "ligacoes")  # Bloco 71 (save antigo: fechadas)
	for e in get_tree().get_nodes_in_group("elevadores"):
		if lig.has(String(e.name)) and typeof(lig[String(e.name)]) == TYPE_DICTIONARY:
			e.load_save_data(lig[String(e.name)])
	_apply_group("minerios", SaveUtil.dict(data, "minerios"))
	_apply_group("comedouros", SaveUtil.dict(data, "comedouros"))
	_apply_group("coleta_comida", SaveUtil.dict(data, "coleta_comida"))
	_apply_group("arvores", SaveUtil.dict(data, "arvores"))
	_apply_group("caca", SaveUtil.dict(data, "caca"))  # Bloco 27 (save antigo: tocas cheias)
	_apply_single("escavadeira", SaveUtil.dict(data, "escavadeira"))
	_apply_single("finds", SaveUtil.dict(data, "finds"))  # peças raras, achados e o robô
	# sempre (mesmo save antigo sem a chave): limpa as cruzes da partida atual
	var inf := get_tree().get_first_node_in_group("enfermarias")
	if inf:
		inf.load_save_data(SaveUtil.dict(data, "enfermaria"))
	var shaft := get_tree().get_first_node_in_group("elevador")
	if shaft:
		shaft.sync_state()  # escavadeira pronta => descida aberta (save antigo sem "elevador")
	_apply_single("work_areas", SaveUtil.dict(data, "areas_trabalho"))  # Bloco 77: antes dos ipezinhos
	var migr := get_tree().get_first_node_in_group("migrantes")  # Bloco 101 (save antigo: ninguém esperando)
	if migr:
		migr.load_save_data(SaveUtil.dict(data, "migrantes"))
	if data.has("workers") and typeof(data.workers) == TYPE_ARRAY:
		_apply_workers(main, data.workers)
	# Prompt 29: save de antes do mapa novo — o que caiu em penhasco, escada, paliçada ou paredão
	# vai pro lugar válido mais perto (fica anotado em environment.migrated)
	var map_env := get_tree().get_first_node_in_group("environment")
	if map_env and map_env.has_method("migrate_positions") and map_env.migrate_positions() > 0:
		map_env.rebuild_navigation()

	var cat := get_tree().get_first_node_in_group("catalogo")  # Bloco 102: depois do mundo (o save antigo confere o liberado)
	if cat:
		if data.has("catalogo"):
			cat.load_save_data(SaveUtil.dict(data, "catalogo"))
		cat.depois_de_carregar(data.has("catalogo"))
	var exped := get_tree().get_first_node_in_group("expedicoes")  # Bloco 104: depois dos ipezinhos (recria quem está fora)
	if exped:
		if data.has("expedicoes"):
			exped.load_save_data(SaveUtil.dict(data, "expedicoes"))
		exped.depois_de_carregar(data.has("expedicoes"))

	var logi := get_tree().get_first_node_in_group("logistica")  # Bloco 105 (save antigo: 0 entregas)
	if logi:
		logi.load_save_data(SaveUtil.dict(data, "logistica"))
	var manut := get_tree().get_first_node_in_group("manutencao")  # Bloco 105: depois das máquinas (o conserto aponta pra elas)
	if manut:
		manut.load_save_data(SaveUtil.dict(data, "manutencao"))

	var missoes := get_tree().get_first_node_in_group("missoes")  # Bloco 100: depois de tudo (confere o que a vila já fez)
	if missoes:
		if data.has("missoes"):
			missoes.load_save_data(SaveUtil.dict(data, "missoes"))
		missoes.depois_de_carregar(data.has("missoes"))

	var cam_data := SaveUtil.dict(data, "camera")
	var cam: Node = main.get_node_or_null("Camera2D")
	if cam and not cam_data.is_empty():
		var foco := SaveUtil.vec2(cam_data, "position", cam.global_position)
		if map_env and map_env.has_method("posicao_nova"):
			foco = map_env.posicao_nova(foco)  # Bloco 75: câmera salva num andar antigo -> a faixa
		cam.focus_on(foco)
		var z := clampf(SaveUtil.num(cam_data, "zoom", cam.zoom.x), cam.zoom_min, cam.zoom_max)
		if cam.has_method("set_target_zoom"):
			cam.set_target_zoom(z)  # Bloco 48: assenta na parada nítida mais perto
		else:
			cam.set("_target_zoom", z)
	print("SaveManager: save carregado (versão %d, salvo em %s)" % [
		SaveUtil.integer(data, "save_version", 0), SaveUtil.text(data, "saved_at", "?")])
	loaded.emit()


## Bloco 37: onde a vila foi fundada (Centro, Armazém) e os comedouros construídos.
func _collect_layout(tree: SceneTree) -> Dictionary:
	var hub: Node2D = tree.get_first_node_in_group("village_hub")
	var arms := {}
	for a in tree.get_nodes_in_group("armazens"):
		arms[String(a.name)] = SaveUtil.vec2_to_array(a.global_position)
	var coms := []
	for c in tree.get_nodes_in_group("comedouros"):
		coms.append({"name": String(c.name), "position": SaveUtil.vec2_to_array(c.global_position)})
	# casas que vieram na cena e continuam de pé (partida de antes da fundação): ficam
	var scene_casas := []
	for casa in tree.get_nodes_in_group("casas"):
		if not casa.placed_by_player:
			scene_casas.append(String(casa.name))
	return {"hub": SaveUtil.vec2_to_array(hub.global_position) if hub else [], "armazens": arms,
		"comedouros": coms, "scene_casas": scene_casas, "mapa": 74}  # Bloco 74: o mapa da maquete v3


## Save sem "layout" (antigo): não mexe em nada — fica o layout da cena.
func _apply_layout(layout: Dictionary) -> void:
	if layout.is_empty():
		return
	var hub: Node2D = get_tree().get_first_node_in_group("village_hub")
	if hub == null:
		return
	# casas e comedouro que vêm na cena não existem nessa partida (o jogador fez os dele) —
	# menos as casas da cena que o save diz que continuam (partida de antes da fundação)
	var keep: Array = SaveUtil.array(layout, "scene_casas")
	for casa in get_tree().get_nodes_in_group("casas"):
		if not casa.placed_by_player and not keep.has(String(casa.name)):
			casa.get_parent().remove_child(casa)
			casa.queue_free()
	for c in get_tree().get_nodes_in_group("comedouros"):
		c.get_parent().remove_child(c)
		c.queue_free()
	hub.global_position = SaveUtil.vec2(layout, "hub", hub.global_position)
	var arms := SaveUtil.dict(layout, "armazens")
	# Bloco 74: no mapa da maquete v3 o armazém da cena é o da mina (na frente da boca, o vagonete
	# descarrega nele); save de antes desse mapa: ele fica no lugar novo (os construídos depois, não)
	var env74 := get_tree().get_first_node_in_group("environment")
	var mapa_novo: bool = env74 != null and env74.has_method("vertical_palisade") and env74.vertical_palisade()
	var save_antigo := SaveUtil.integer(layout, "mapa", 0) < 74
	for a in get_tree().get_nodes_in_group("armazens"):
		if mapa_novo and save_antigo and a.owner != null:
			continue
		a.global_position = SaveUtil.vec2(arms, String(a.name), a.global_position)
	for cd in SaveUtil.array(layout, "comedouros"):
		if typeof(cd) != TYPE_DICTIONARY:
			continue
		var pos := SaveUtil.vec2(cd, "position", Vector2.INF)
		if pos != Vector2.INF:
			hub.spawn_comedouro(pos, SaveUtil.text(cd, "name", ""), false)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.clear_decor_under_extras()
		env.rebuild_navigation()


## Recria as casas que o jogador posicionou (antes dos ipezinhos, pra camas baterem).
func _spawn_placed_houses(list: Array) -> void:
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub == null or list.is_empty():
		return
	for h in list:
		if typeof(h) != TYPE_DICTIONARY:
			continue
		var house_name := SaveUtil.text(h, "name", "")
		if house_name == "" or hub.get_parent().has_node(house_name):
			continue
		var pos := SaveUtil.vec2(h, "position", Vector2.INF)
		if pos == Vector2.INF:
			continue
		hub.spawn_house(pos, house_name, false)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.rebuild_navigation()  # uma vez só, com todas as casas


func _apply_single(group: String, d: Dictionary) -> void:
	if d.is_empty():
		return
	var node := get_tree().get_first_node_in_group(group)
	if node and node.has_method("load_save_data"):
		node.load_save_data(d)


func _apply_group(group: String, by_name: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group(group):
		var d = by_name.get(String(node.name), null)
		if typeof(d) == TYPE_DICTIONARY and node.has_method("load_save_data"):
			node.load_save_data(d)


## Save sem max_workers (versão velha/editado): refaz a partir das Moradias.
func _recompute_max_workers() -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	var hub := get_tree().get_first_node_in_group("village_hub")
	if eco and hub:
		var base: int = eco.get_script().get_property_default_value("max_workers")
		eco.max_workers = base + hub.workers_per_moradia * int(hub.upgrades.get("moradias", 0))


## Troca os ipezinhos da cena pelos do save (cada um volta pra sua cama).
func _apply_workers(main: Node, list: Array) -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	var parent: Node = main.get_node_or_null("World")
	if eco == null or eco.worker_scene == null or parent == null:
		return
	if main.has_method("select"):
		main.select(null)
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		w.get_parent().remove_child(w)  # _exit_tree devolve estação e cama já agora
		w.free()
	for wd in list:
		if typeof(wd) != TYPE_DICTIONARY:
			continue
		var w: Node2D = eco.worker_scene.instantiate()
		w.name = SaveUtil.text(wd, "name", "Ipezinho")
		w.position = SaveUtil.vec2(wd, "position", Vector2.ZERO)
		w.set("pending_save_data", wd)  # aplicado no _ready do ipezinho
		parent.add_child(w)


## Salvos de versões antigas passam por aqui. (Versão 1 = atual, nada a fazer.)
func _migrate(data: Dictionary) -> Dictionary:
	var version := SaveUtil.integer(data, "save_version", 0)
	if version > SAVE_VERSION:
		push_warning("SaveManager: save da versão %d é mais novo que o jogo (%d); tentando carregar mesmo assim" % [version, SAVE_VERSION])
	if version < 2:
		# lotes fixos construídos -> casas posicionadas no mesmo lugar (mesmo nome: camas batem)
		var placed: Array = SaveUtil.array(data, "placed_houses")
		var casas := SaveUtil.dict(data, "casas")
		for lot in LEGACY_LOTS:
			var d = casas.get(lot, null)
			if typeof(d) == TYPE_DICTIONARY and SaveUtil.boolean(d, "built", false):
				placed.append({"name": lot, "position": SaveUtil.vec2_to_array(LEGACY_LOTS[lot])})
			elif casas.has(lot):
				casas.erase(lot)  # lote vazio: não existe mais
		data["placed_houses"] = placed
	if version < 3:
		# Bloco 25: "role" virou "job". Antes, role "" = fazia de tudo (minerava por padrão);
		# agora quem nasce fica ocioso. Pra carregar um save antigo não parecer que
		# "todo mundo parou de trabalhar", quem não tinha função especial vira minerador.
		for wd in SaveUtil.array(data, "workers"):
			if typeof(wd) != TYPE_DICTIONARY or wd.has("job"):
				continue
			var role := SaveUtil.text(wd, "role", "")
			wd["job"] = role if role in ["cozinheiro", "lenhador", "guarda", "pesquisador"] else "minerador"
			wd.erase("role")
	if version < 4 and data.has("defense"):
		# Bloco 35: antes todo guarda usava a melhor arma já forjada, sem desgaste. Cada
		# guarda sai do save com ela (-1 = durabilidade cheia) e a forja que andava sozinha
		# vira a primeira encomenda da fila do Arsenal (só anda com engenheiro lá).
		var def := SaveUtil.dict(data, "defense")
		var known: Array = SaveUtil.array(def, "weapons")
		var best := "porrete"
		for id in ["porrete", "lanca", "besta", "lanca_prata"]:
			if known.has(id):
				best = id
		for wd in SaveUtil.array(data, "workers"):
			if typeof(wd) != TYPE_DICTIONARY or wd.has("weapon"):
				continue
			if SaveUtil.text(wd, "job", "") == "guarda":
				wd["weapon"] = best
				wd["weapon_durability"] = -1.0
				wd["got_porrete"] = true
		var f := SaveUtil.text(def, "forging", "")
		if f != "" and not def.has("queue"):
			def["queue"] = [{"what": "forjar", "id": f, "left": SaveUtil.num(def, "forge_left", 0.0)}]
		def.erase("forging")
		def.erase("forge_left")
		data["defense"] = def
	# if version < 5: ...
	return data
