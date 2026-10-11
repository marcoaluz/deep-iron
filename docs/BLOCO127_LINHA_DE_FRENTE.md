# Bloco 127 — Linha de frente, portão como segunda defesa e invasão dentro da vila

Plano aprovado pelo Marco (com as respostas: o médico só resgata se não há criatura perto; o Centro da Vila nunca vira ruína;
posto externo também na vigília de noite comum; ícone: o que ficasse melhor). Teste `b127_linha_de_frente` (66 verificações,
registrado no GUT, linha no `TESTING.md`). Simulação headless em `tools/sim_invasao.gd` (resumo: `tools/resume_sim_invasao.py`,
números brutos em `docs/telemetria/bloco127/`).

## O problema (confirmado no código)

1. `creature.gd`: `if _gate != null: _target = _gate` — toda criatura com portão de pé atacava o portão, ignorando os guardas.
2. `defense.guard_post()` punha o posto DENTRO do portão e, fechado, o portão é parede na malha (`portao_por_faixas`): o
   `_guard_tick` via a criatura a 200 px e não conseguia sair. O guarda ficava parado até o portão quebrar.

## O que mudou

**Linha de frente (guarda FORA do portão)**
- `barricada.gd`: o **postigo** — um `NavigationLink2D` a mais (`postigo_offset` do centro), na camada de navegação 2
  (`CAMADA_GUARDA`), sempre ligado. Só agente com a camada passa: o guarda, e o médico indo buscar o caído que ficou lá fora
  (`ipezinho.pode_postigo()`, `_atualiza_camadas()`). `separa(a, b, quem)` não separa pro guarda. O portão aparece **entreaberto**
  (`abertura_visual()`, quadro `meio_N`, ~1 s) quando um guarda cruza; a passagem dos outros (as faixas) segue fechada.
- `defense.gd`: `guard_post_ativo()` = o posto de verdade da vigília e da invasão, `frente_dist` px à frente do portão da floresta,
  encaixado na malha. `guard_post()` ficou como o posto de DENTRO (o do recuo; b74 e b80 o usam). O posto do poço não mudou.
- `ipezinho._recuo_tick`: o guarda ferido (`guard_recua_pct`, 35% da vida de luta) larga o inimigo, volta pelo postigo ao posto de
  dentro, regenera (`guard_recuo_regen`/s) e volta a sair em `guard_volta_pct` (70%). Portão caído, já dentro ou invasor em cima
  dele: luta, não recua.
- Mantidos: o caído, o resgate do médico e a brecha do Bloco 36. O médico só sai pro caído se não há criatura viva a menos de
  `medico_resgate_raio` (170 px) dele; senão espera e o relógio do caído corre como sempre (`_resgate_perigoso`).

**Portão = segunda defesa** (`creature._alvo_com_portao`, no lugar do `_target = _gate`)
1. guarda de serviço ou robô em pé ao alcance (`notice_range`) e **alcançável** (portão fechado entre os dois = não alcança: o
   guarda que recuou pelo postigo não prende a criatura na paliçada);
2. quem a atacou por último, se perto e alcançável;
3. a brecha (guarda do portão caído): o portão abre e ela entra pra saquear (Bloco 36);
4. só então o portão. Barricada, vida por nível, política de Segurança e a luz que atrai o Lumívoro seguem valendo.

**Invasão dentro da vila**
- **Roubo**: o Lumívoro que passou o portão (`inside`) vai no armazém quando não tem gente acordada perto e leva minério e itens por
  golpe (`defense.saque_invasor`), com TETO por noite (`saque_teto_fracao`: 25% do estoque saqueável de quando a invasão começou,
  nunca abaixo de `saque_teto_piso`: 30). O Ferrugento continua levando minério como antes e, acabando o minério, leva itens (com o
  mesmo teto). O `raid()` do Bloco 36 ficou igual.
- **Integridade dos prédios** (`estruturas.gd` + `props/integridade_predio.gd`, reaproveitando `Desgaste`/`Manutencao` do Bloco 105):
  o golpe do invasor dentro da vila machuca o prédio se ele é forte, elite, chefe ou a onda está no tier `dano_tier_min` ou acima;
  o dano do golpe é o `dano_predio` do bicho (0,04 da condição) x forte 1,5 x elite 2 x chefe 6 x (1 + 0,25 por tier acima do
  mínimo). A Matriarca derruba uma casa em ~4 golpes.
  - ferido: o mecânico faz a preventiva (até 90% de condição); a eficiência cai depois de 40% de dano (curva do Bloco 105) e quem
    trabalha na estação rende menos (`mult("producao")`);
  - **em ruínas** (condição 0): a estação some da escolha da IA e quem estava nela sai; a casa fica sem camas e os moradores
    perdem a cama (`perde_a_cama`: acordam e procuram outra; sem cama livre, dormem ao relento); o armazém para de receber (o que
    está dentro continua lá e sai normal);
  - reconstrução = a obra de conserto de máquina (`conserto_maquina.gd`, mecânico ou, sem ele, engenheiro), paga só com o material
    todo, por `ruina_custo_pct` (50%) do custo original (tabela `custo_base`); `Manutencao` ganhou `custo_de`/`limite_de`;
  - o **Centro da Vila** nunca vira ruína: o dano nele para em `centro_dano_max` (25%);
  - quem está dentro de casa atacada não morre (só se assusta, como antes) e criança nunca é alvo (Bloco 111).
- **Sinais**: banners "Os guardas seguram o portão", "O portão cedeu" e "Invasores dentro da vila" (`defense._frente_tick`,
  `portao_cedeu`); o alerta "Invasão" da coluna da direita passa a mostrar quantos estão dentro; barra de condição e "!" nos prédios
  feridos (`iso_billboard._draw_desgaste`), e o alerta de máquina falhando/quebrada os conta.
- **Ícone de dano**: reaproveitei a barra de desgaste do Bloco 105 + o `p_alerta` ("!") no prédio em ruínas. Desenho novo não
  melhorava: a barra já diz quanto e o "!" já diz que parou; mais um ícone só entrava na frente da arte do prédio.

**Outros**
- Catálogo (`textos.txt`: lumivoro, ferrugento, matriarca) e diário: dizem o que a criatura faz na vila (só o que o código faz).
- F3: "Linha de frente: derrubar o portão / ferir prédio mais perto / consertar tudo".
- Save: chave `estruturas` (só os prédios feridos; save antigo = 100%); `defense.last_result` ganhou os campos da noite.
  Telemetria: 6 colunas (`noite_guardas_caidos`, `noite_portao_cedeu`, `noite_saque`, `noite_predios_feridos`,
  `predios_feridos_agora`, `predios_ruinas`).
- Saiu a **igreja de enfeite** da decoração da vila (`igreja_0` em `environment.MAP_DECOR_V3`): a igreja agora é o prédio do Bloco 88.
  (A `igreja_0` da VILA ANTIGA do leste, as ruínas de antes da explosão, ficou: é história, não a igreja da vila.)

## Equilíbrio (simulação headless, 3 repetições por cenário; antes = HEAD do Bloco 126, depois = este bloco)

Cenário: `main.tscn` sem fundação, portão nível 1 (120 de vida), guardas já no posto quando a invasão começa, sem médico, armazém
com 300 ferro + 100 cobre + 500 cr; "limpou" = todas as criaturas derrubadas antes do amanhecer. Habilidade 0,0 = guarda sem
treino; 0,5 = metade; 1,0 = no máximo.

| arma | guardas | hab. | onda | modelo | runs | limpou | guardas caídos (média) | portão % (média) | minério perdido | créditos perdidos | prédios feridos | s até limpar |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| porrete | 2 | 0.0 | 1 | antes | 3 | 2/3 | 0.7 | 33 | 0 | 0 | 0.0 | 72 |
| porrete | 2 | 0.0 | 1 | depois | 3 | 3/3 | 0.0 | 51 | 0 | 0 | 0.0 | 48 |
| porrete | 3 | 0.0 | 1 | antes | 3 | 1/3 | 0.3 | 67 | 0 | 0 | 0.0 | 66 |
| porrete | 3 | 0.0 | 1 | depois | 3 | 3/3 | 0.0 | 100 | 0 | 0 | 0.0 | 30 |
| porrete | 2 | 0.5 | 1 | antes | 3 | 1/3 | 0.3 | 67 | 0 | 0 | 0.0 | 49 |
| porrete | 2 | 0.5 | 1 | depois | 3 | 3/3 | 0.0 | 82 | 0 | 0 | 0.0 | 33 |
| porrete | 3 | 0.5 | 1 | antes | 3 | 3/3 | 0.0 | 0 | 0 | 0 | 0.0 | 49 |
| porrete | 3 | 0.5 | 1 | depois | 3 | 3/3 | 0.0 | 100 | 0 | 0 | 0.0 | 24 |
| porrete | 3 | 0.5 | 2 | antes | 3 | 3/3 | 1.0 | 0 | 32 | 40 | 0.0 | 51 |
| porrete | 3 | 0.5 | 2 | depois | 3 | 3/3 | 0.0 | 100 | 0 | 0 | 0.0 | 28 |
| porrete | 3 | 0.5 | 3 | antes | 3 | 0/3 | 3.0 | 0 | 48 | 60 | 0.0 | — |
| porrete | 3 | 0.5 | 3 | depois | 3 | 3/3 | 0.7 | 37 | 0 | 0 | 0.0 | 47 |
| porrete | 3 | 0.5 | 4 | antes | 3 | 0/3 | 3.0 | 0 | 48 | 60 | 0.0 | — |
| porrete | 3 | 0.5 | 4 | depois | 3 | 0/3 | 3.0 | 0 | 148 | 60 | 2.0 | — |
| lanca | 3 | 0.5 | 4 | antes | 3 | 0/3 | 3.0 | 0 | 48 | 60 | 0.0 | — |
| lanca | 3 | 0.5 | 4 | depois | 3 | 3/3 | 0.3 | 2 | 0 | 0 | 0.0 | 52 |
| lanca | 4 | 0.5 | 4 | antes | 3 | 2/3 | 1.7 | 0 | 48 | 60 | 0.0 | 69 |
| lanca | 4 | 0.5 | 4 | depois | 3 | 3/3 | 0.0 | 79 | 0 | 0 | 0.0 | 40 |
| lanca | 4 | 1.0 | 5 | antes | 3 | 0/3 | 3.0 | 0 | 48 | 60 | 0.0 | — |
| lanca | 4 | 1.0 | 5 | depois | 3 | 2/3 | 0.3 | 25 | 0 | 0 | 0.0 | 54 |

**Leitura**
- A 1ª invasão (onda 1: 2 Lumívoros) é vencível por 2 a 3 guardas de porrete **sem treino**: 3/3 em todos os cenários da onda 1 e
  nenhum guarda caído (antes: só 1/3 a 3/3 limpavam; em vários runs as criaturas ficavam paradas a noite toda com o portão
  intacto).
- Onda 2 com 3 guardas de porrete: antes caía 1 guarda em média, o portão ia a 0% e a vila perdia 32 de minério + 40 cr (média);
  agora 3/3, nenhum guarda cai, portão a 100% e nada é roubado. Onda 3: antes 0/3 limpavam (3 guardas caídos, 48 de minério +
  60 cr); agora 3/3, 0,7 guarda caído em média, portão a 37% e nada roubado.
- A onda 4 (5 criaturas, uma forte) **continua perdida** com 3 guardas de porrete (antes e depois); o que mudou é o que a derrota
  custa: perde 148 de minério + 60 cr (antes 48 + 60: o teto do saque dentro da vila somado ao `raid` do Bloco 36) e 2 prédios
  feridos. Com **lança** ela é vencida (3 guardas: 3/3; 4 guardas: 3/3), antes não era (0/3 e 2/3). A onda 5 com 4 guardas de lança
  no treino máximo: 2/3 (antes 0/3).
- Nenhum valor foi ajustado depois da simulação: os padrões (`frente_dist` 70, `guard_recua_pct` 0,35, `guard_volta_pct` 0,7,
  `guard_recuo_regen` 1,5, `medico_resgate_raio` 170, `saque_teto_fracao` 0,25, `saque_teto_piso` 30, `dano_predio` 0,04,
  `dano_tier_min` 2, `mult_chefe` 6, `ruina_custo_pct` 0,5, `centro_dano_max` 0,25) são os do primeiro palpite.
- O Normal não mudou (nenhum `@export` novo entra nos perfis; o b113 confere): Tranquilo e Ferro usam os multiplicadores que já
  tinham sobre vida e dano das criaturas.

**O que a simulação NÃO cobre**: partida inteira (só a noite da invasão), médico no resgate (isso é do b127), Ferrugentos e o posto
do poço, tochas atraindo o Lumívoro, chefe, ondas acima da 5, política de Segurança, portão de nível 2/3 e o ritmo de conserto dos
prédios pelo mecânico. 3 repetições por cenário: os números são tendência, não estatística. Houve **1 caso** (nas execuções das
ondas 4 e 5 com o código novo) em que uma criatura e um guarda ficaram a ~20 px um do outro, parados, até o amanhecer (alvo fora
da malha; hipótese: o guarda para 2 px além do alcance de 18); não reproduzi em 12 repetições seguidas. O diário dele está em
`docs/telemetria/bloco127/sim_depois_lanca.txt`. No código antigo apareceram criaturas paradas longe do portão em 5 de 12 execuções
da onda 1; não investiguei a causa lá.

## Como ajustar (nome do `@export`)

| O quê | Onde | Nome |
|---|---|---|
| Quão à frente do portão fica o posto | `defense.gd` | `frente_dist` |
| Quando o guarda recua / volta / quanto regenera | `defense.gd` | `guard_recua_pct`, `guard_volta_pct`, `guard_recuo_regen` |
| Distância de criatura que segura o médico | `defense.gd` | `medico_resgate_raio` |
| Teto do roubo dentro da vila | `defense.gd` | `saque_teto_fracao`, `saque_teto_piso` |
| Dano em prédio por golpe / de quem | `creature.gd` (cena), `estruturas.gd` | `dano_predio`, `mult_forte`, `mult_elite`, `mult_chefe`, `dano_por_tier`, `dano_tier_min` |
| Centro da Vila, conserto e custo da reconstrução | `estruturas.gd` | `centro_dano_max`, `limite_conserto`, `ruina_custo_pct`, `custo_base` |
| Postigo | `barricada.gd` | `postigo_offset`, `postigo_anima_segundos`, `postigo_raio` |

## Testes

- `b127_linha_de_frente` (66 OK): guarda fora com o portão FECHADO, criatura prefere o guarda, portão só apanha sem defensor,
  recuo pelo postigo, invasor dentro rouba (minério e itens, teto), Matriarca derruba uma casa (sem camas, moradores vivos), o
  Centro não vira ruína, o custo da reconstrução, o médico espera com criatura perto, banners, save/save antigo/save quebrado e a
  igreja de enfeite fora do mapa.
- Regressão (um por vez, `fake_appdata`, md5 do save real igual antes e depois): b35, b36, b62, b74, b80, b91, b98, b103, b105,
  b108, b113, b124 (b91, b105, b108 e b113 rodaram antes do último ajuste de `creature.gd` — a brecha entrando em vez de bater no
  portão aberto —, que não toca o que eles medem). O resto da bateria não foi rodado.

## Não verificado

- Nada foi jogado nem visto na tela: o entreaberto do portão, a barra e o "!" nos prédios, os banners e a posição do posto externo
  na floresta (árvores, decoração) estão conferidos por teste e por código, não por olho.
- Guarda fora da paliçada à noite em noite SEM invasão (pedido do Marco): o rato-de-cinza segue sendo caçado (pelo postigo), mas
  não medi o efeito no ritmo da vigília.
- Custo por tick de `guard_post_ativo` (lista de guardas + consulta de malha): sem medição de desempenho.
- `estruturas.gd` e `integridade_predio.gd` ainda não têm `.uid` (o editor gera na próxima abertura).
