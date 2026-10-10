# Bloco 108 — Políticas da Vila (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido: "Prompt L" + os 7 acréscimos. Plano: `docs/BLOCO108_PLANO.md`. Decisões do Marco:
cortar a "Farta"; aprovar a vigilância, o treinamento e o teto de 125%; o satélite chama mesmo com a migração fechada; a janela
libera no Vilarejo; a tecla é **F6** (o "=" não); espera de 1 dia; o desperdício de comida fica a critério (ver a seção 6).
Teste: `tests/blocos/b108_politicas.gd`. Medição: `tests/bench_politicas.gd` (resultados em `docs/telemetria/bloco108/`).
Fotos: `docs/arte/bloco108/` (`tests/capturas_bloco108.gd`).

## 1) Arquivos

| Arquivo | O quê |
|---|---|
| `scripts/core/politicas.gd` (novo) | O nó `Politicas` (grupos `politicas` e `modificadores`): as opções, a espera, a fraqueza, a cobrança da vigilância, o treino acima de 100%, a proteção contra a greve, os textos da janela e o save. |
| `scripts/core/modificadores.gd` (novo) | O ponto único dos multiplicadores (`Modificadores.mult(arvore, chave, quem)`). A Dificuldade (Prompt 5) só entra no grupo. |
| `scripts/core/politicas_panel.gd` (novo) | A janela "Políticas da Vila" (F6, menu Janelas). |
| `scripts/workers/ipezinho.gd` | `work_mult` (produção), `_roll_injury`/`_roll_branch` (acidente), `happiness_factors` (o ânimo das políticas), `train`/`teto_treino` (até 125%), o load aceita habilidade acima de 1,0, contador `acidentes_trabalho`. |
| `scripts/props/comedouro.gd` | Porção e fome = básico × prato × ração, presas entre ×0,6 e ×1,5 (o teto é o ensopado); `servido_total`. |
| `scripts/core/schedule.gd` | Vigilância paga = todos os guardas de vigia; `porcoes_em_estoque` na porção de verdade. |
| `scripts/core/migrantes.gd` | Fechada para o relógio (a rede de segurança e o satélite valem); seletiva espera cama, grupo do tamanho das camas, intervalo ×1,5, prazo ×2; portão vigiado não é atacado. |
| `scripts/core/defense.gd`, `scripts/creatures/creature.gd` | Saque da brecha e roubo do Ferrugento × a chave `roubo`. |
| `scripts/props/campo_treino.gd` | Ritmo do treino × a chave `treino`. |
| `scripts/core/telemetria.gd` | 8 colunas novas. |
| `scripts/core/save_manager.gd` | A chave `politicas` (cabeçalho documentado). |
| `scripts/core/hud.gd`, `main.gd`, `teclas.gd`, `scripts/props/centro_vila.gd` | A janela no menu, a tecla F6 (trocável), a ajuda, o "Libera: Políticas da Vila" do Vilarejo, a porção real na dica da comida. |
| `scenes/game/main.tscn` | O nó `Politicas`. |
| Testes e docs | `b108_politicas.gd`, `bench_politicas.gd`, `capturas_bloco108.gd`, `test_blocos.gd`, `TESTING.md`, `CLAUDE.md`, `BALANCEAMENTO.md`. |

## 2) Regras implementadas

- **Padrão = o jogo de antes.** Todo multiplicador vale 1,0, nenhum motivo de ânimo, porção 8 enchendo 45 (o teste confere; a
  medição confirma, seção 4).
- **Jornada** (normal / estendida / reduzida): produção, acidente de trabalho e ânimo de quem PRODUZ. Nenhum horário muda; o
  cozinheiro, o médico, o guarda e o padre ficam de fora; o turno extra da noite (T) também.
- **Ração** (normal / reduzida): porção e fome caem na mesma proporção (não cria comida). Com o ensopado, os dois multiplicam,
  com teto. Reduzida por 3 amanheceres seguidos → **fraqueza** (produção ×0,9, acidente ×1,25 em quem produz) até 2 dias depois
  de voltar. Ninguém morre por causa da política.
- **Segurança** (padrão / vigilância reforçada / treinamento):
  - vigilância: cobra 5 cr por guarda ao anoitecer (sem créditos, aquela noite vale o padrão, com aviso e sem dívida); todos os
    guardas de vigia; saque da brecha e roubo do Ferrugento pela metade; quem espera no portão não é atacado;
  - treinamento: precisa de campo de treino; treino ×1,5; a habilidade sobe até 125% (dano ×1,125 e vida 55 pela fórmula de
    sempre); ânimo −6 só nos guardas; fora dele, o excesso cai 0,002/s até 100%.
- **Migração** (aberta / seletiva / fechada): ver o item `migrantes.gd` acima. Quem já espera no portão quando fecha fica até o
  prazo normal, sem punição.
- **Troca:** uma opção por política; espera de 1 dia de jogo por política (a primeira é livre); **voltar ao padrão é imediato em
  greve ou com a vila insatisfeita** (ânimo médio < 40).
- **Greve nunca inevitável:** a penalidade somada das políticas numa pessoa tem teto −12. **Novo, por causa da medição:** se a
  greve começar, as opções que tiram ânimo (jornada estendida, ração reduzida, treinamento) **voltam sozinhas ao padrão**
  ("os grevistas exigiram"), sem espera pra escolher de novo depois (`greve_derruba`, @export). Não é mecânica nova de greve: é a
  política respondendo à greve que já existe.
- **Acesso:** estágio 2 (Vilarejo). Antes disso a janela não aparece no menu e o F6 dá um aviso; ao chegar no Vilarejo aparece
  "Nova janela: Políticas da Vila (F6)".
- **Ânimo num ponto só:** `politicas.fatores_animo(w)`; cada valor passa por `_reacao(w, politica, valor)` — hoje devolve o valor;
  é onde os traços (Prompt R) vão modular.
- **Composição com a Dificuldade (Prompt 5):** as chaves `producao`, `acidente`, `porcao`, `fome_refeicao`, `migracao_intervalo`,
  `treino` e `roubo` já são perguntadas por quem consome. A Dificuldade entra no grupo `modificadores` e responde às mesmas.

## 3) Valores configuráveis (`@export` em `politicas.gd`, listados no `BALANCEAMENTO.md`)

| Grupo | Valor | Padrão |
|---|---|---|
| Geral | `troca_espera_dias` / `animo_penalidade_max` / `estagio_minimo` / `aviso_animo` / `greve_derruba` | 1 / 12 / 2 / 40 / sim |
| Jornada | `estendida_producao` / `_acidente` / `_animo` | 1,15 / 1,30 / −8 |
| | `reduzida_producao` / `_acidente` / `_animo` | 0,85 / 1,0 / +5 |
| | `funcoes_essenciais` | cozinheiro, médico, guarda, padre |
| Ração | `racao_reduzida_porcao` / `_fome` / `_animo` | 0,75 / 0,75 / −6 |
| | `fraqueza_dias` / `fraqueza_recupera_dias` / `fraqueza_producao` / `fraqueza_acidente` | 3 / 2 / 0,9 / 1,25 |
| Segurança | `vigilancia_custo_guarda` / `vigilancia_roubo` | 5 cr / 0,5 |
| | `treino_ritmo` / `treino_teto` / `treino_animo` / `treino_decai` | 1,5 / 1,25 / −6 / 0,002 por s |
| Migração | `seletiva_intervalo` / `seletiva_prazo` | 1,5 / 2,0 |
| Comedouro | `porcao_mult_min` / `porcao_mult_max` | 0,6 / 1,5 |

## 4) Medição (telemetria): antes e depois

Partida nova de verdade, 10 ipezinhos (1 cozinheiro, 2 caçadores, 3 mineradores, 2 lenhadores, 1 engenheiro, 1 guarda), 8×,
primavera, 1ª invasão na noite do dia 3, 4 dias (5 nos de ração). Médias por dia. A madeira bate no limite do armazém (350) no
dia 4 em todos os cenários e o minério no dia 5 (400): por isso a madeira não diferencia os cenários.

| Cenário | Minério | Comida servida | Fome média | Ânimo médio | Greve | Observação |
|---|---|---|---|---|---|---|
| **Referência (código de antes)** | 88 | 210 | 85,6 | 68,7 | 0 | |
| Padrão (código novo) | 94 | 210 | 86,0 | 68,4 | 0 | igual à referência (a diferença do minério é sorteio) |
| Jornada estendida | **110** (+17%) | 206 | 85,5 | **62,3** (−6) | 0 | |
| Jornada reduzida | **82** (−13%) | 208 | 86,0 | **72,3** (+4) | 0 | |
| Ração reduzida (5 dias) | 87 | **158** (−25%) | 85,0 | 62,3 | 0 | fraqueza a partir do dia 4 |
| Estendida + reduzida (5 dias, **antes** da proteção) | 88 | 148 | 82,1 | 56,5 | **177 s** | a morte na invasão (luto) + −12 das políticas → greve; acabou sozinha |
| Inverno, padrão | 100 | 228 | **82,5 estável** | 68,3 | 0 | fome do inverno ×1,25 |
| Inverno, ração reduzida | 93 | 172 | **83 → 76 caindo** | 62,8 | 0 | sem margem: a fome desce dia a dia |
| Vigilância reforçada | 94 | 210 | 85,8 | 68,6 | 0 | +150 cr no fim igual (a vigília custa 5 cr/noite com 1 guarda; nesta invasão não abriu brecha) |
| Migração aberta / seletiva / fechada | — | — | — | — | 0 | chegaram **3 / 1 / 0** migrantes |
| Vila triste (ânimo base 45), padrão | 97 | 206 | 85,8 | 54,2 | 0 | |
| Vila triste, estendida + reduzida (**com** a proteção) | 95 | 172 | 85,6 | 46,3 | **199 s** | a greve derrubou as duas políticas; o ânimo voltou a 51; sem expulsão |
| 3 moradores, fechada | — | 60 | 85,8 | 72,0 | 0 | a rede de segurança trouxe 3 migrantes mesmo fechada |
| Sem cozinheiro e cozinha vazia, ração reduzida | 115 | **0** | 53 → 4 | 53 | 0 | a política não cria comida |

**Leitura:**
- A jornada faz o que promete, com custo de ânimo proporcional, e não mexe na comida (a cozinha fica de fora).
- A ração reduzida economiza 25% da comida **sem quase nenhuma fome no verão** (por causa do desperdício da seção 6): o custo
  de verdade é o ânimo (−6) e a fraqueza a partir do 4º dia. **No inverno ela aperta de verdade** (a fome desce todo dia).
  É a decisão que o prompt pede: boa no aperto do verão, perigosa no inverno.
- **Combinação sem custo relevante?** Não achei: a única que "rende" sem perda (estendida + reduzida: +17% de minério com −25%
  de comida) custa −12 de ânimo e levou à greve na primeira morte. Por isso a proteção nova.
- Nada paralisou a vila e nenhuma missão depende de população ou de política (os tipos de objetivo foram conferidos).

## 5) Testes (um por vez, em primeiro plano, APPDATA isolado; o save real não mudou em nenhum)

**Aprovados:** `b108_politicas` (78 verificações, 0 falhas), b84_agenda, b101_migrantes, b107_agricultor_oficinas,
b35_arsenal_desgaste, b36_guarda_caido, b52_debug_telemetria, b54_configuracoes, b33_cozinha_expansao, b62_tiers_chefe,
b70_fundo, b96_obras_material, b100_missoes, b104_expedicoes, b105_carregador_mecanico, b83_relogio_24h, b85_hora_social,
b88_padre_igreja, b95_layout_v2, b95b_construir_abas, b98_portao_tochas, b106_coleta_armazem, b27_cacador_cozinheiro,
b80_portao_unico_ferrugento, p28_save, manut_backups, hud_frostpunk, b39_economia, b42_equipamento, b86_fornalha,
b94_carpintaria, b25_funcoes.

**Reprovado e corrigido:** b96 e b52 falharam na 1ª rodada por um erro MEU: a telemetria passou a fazer `preload` do
`ipezinho.gd`, e os testes carregam a telemetria antes dos autoloads (o `Audio`). Troquei por `load()` em tempo de execução
(e tirei o `preload` do `ipezinho.gd` do `politicas.gd` pelo mesmo motivo). Os dois passaram depois.

**Intermitente:** b103_bestiario falhou uma vez em "o S2 abriu: não reconhecido" (corrida com a pesquisadora estudando o andar,
nada do 108) e passou ao repetir.

**Não rodados nesta entrega:** os outros ~50 testes de `tests/blocos` (sem relação com o que mudou) e os GUT `test_iso*.gd`.

## 6) O desperdício de comida (achado da auditoria)

O prato sai inteiro do estoque, mas quem fica cheio larga o resto (`ipezinho.come_prato`). Medido: **cada um recebe ~23 de comida
por dia e precisa de ~14** (≈40% vai fora no verão). **Decidi não mexer agora** (o Marco deixou a critério): consertar isso
reduz a demanda de comida da vila em ~40% (o balanceamento do Bloco 101 contava com ela) e, junto, **anula a ração reduzida**
(sem sobra, comer menos por refeição só deixaria a fome igual). Se um dia for consertar, é um bloco de balanceamento próprio,
revendo junto a porção (por exemplo, 6 em vez de 8) — a ração e o ensopado continuam valendo como multiplicadores.

## 7) A mais (fora do pedido, mas pra deixar melhor)

- A **proteção da greve** (seção 2) — veio da medição.
- A dica da comida no HUD e as "porções em estoque" passaram a usar a porção de verdade (prato × ração), não a básica.
- A janela ficou em grade 2×2 pra caber em 1280×720 com o detalhe aberto (a primeira versão passava da barra de baixo).

## 8) Pendências

- A arte: nenhuma (a janela usa a pele e os botões de sempre; nenhum ícone novo foi preciso).
- A política de **Família** tem o espaço reservado na janela (o Prompt F vai usar).
- O Marco valida: os números da seção 3, a proteção da greve e o F6 no teclado real.
