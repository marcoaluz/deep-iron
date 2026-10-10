# Bloco 108 — Políticas da Vila (PLANO — espera aprovação)

Data: 2026-10-09. Branch `isometrico`. Pedido: "Prompt L" (+ os 7 acréscimos). Teste futuro: `b108_politicas`.
O último bloco é o 107, então este é o **108**.

**Nada foi implementado.** Este documento traz a auditoria do código real e a proposta. Os números marcados *(calculado)* saem de
contas sobre valores que já existem no código. **Na Etapa 5 meço tudo numa partida de verdade**, como nos Blocos 105 a 107.

---

## 1) Auditoria: o que existe (conferido no código, não na documentação)

| Mecânica | Arquivo(s) | Estado | Ponto de integração |
|---|---|---|---|
| **Agenda do dia** (café 05–07, trabalho 07–12 e 13–18, voltar 18–18:30, social até 21:30, dormir) | `schedule.gd` (`periodo`, `periodo_geral`), marcos em `day_night.gd` | Implementado | **Nenhum horário muda.** A jornada só multiplica o que já acontece no expediente. |
| **Domingo** (missa de manhã; à tarde trabalho ou folga, escolha do jogador) | `calendario.gd periodo_domingo` | Implementado | Fica intocado (a missa e a folga ganham da agenda). |
| **Turno extra** (tecla T: trabalha à noite e ganha zanga) | `ipezinho.gd set_overtime`, `_update_anger` | Implementado | **É a "jornada estendida" individual que já existe.** A política NÃO vale no turno extra da noite (senão conta em dobro). |
| **Portão** (fecha 18:30, abre 05:00) | `barricada.gd hora_fecha/hora_abre` | Implementado | Não muda. |
| **Ânimo** (alvo = 60 + motivos pessoais + motivos da vila; anda 0,25/s) | `ipezinho.gd happiness_factors/target`, `morale.gd village_factors` | Implementado | Um motivo novo por política, lido num único ponto (seção 4). |
| **Greve** (média < 30 por 60 s → greve; ultimato de 300 s → expulsão) | `morale.gd` | Implementado | Não muda. O teto de penalidade das políticas (seção 3.5) impede greve inevitável. |
| **Fome** (cai 0,2/s acordado, ×0,2 dormindo, ×1,25 no inverno) | `ipezinho.gd _process`, `sun.gd hunger_mult` | Implementado | Não muda. |
| **Refeição**: porção 8 un. enche 45 de fome; pula se fome > 90%; refeição perdida = −12% de rendimento (até 3) | `schedule.gd porcao/refeicao_fome`, `comedouro.gd _porcao/_fome_da_porcao` | Implementado | **A ração entra aqui**, junto com o prato (seção 2.2). |
| **Cardápio** (comum / ensopado: porção ×1,5, fome ×1,25, +2 de ânimo por prato até +6) e a ordem de ração de expedição | `comedouro.gd`, `cozinha_panel.gd` (Bloco 107) | Implementado | A política combina com o prato, com um teto (seção 2.2). |
| **Produção** (`work_mult`: zanga × faixa de ânimo × frio × refeições perdidas) | `ipezinho.gd work_mult`; usado por mina, corte, caça/colheita, cozinha, obras, Fornalha e oficinas herdadas, coletores, conserto, montagem de cama e estudo de campo | Implementado | Um fator a mais em `work_mult`, só pras funções de produção. |
| **Acidentes de trabalho** (mina: 4% a cada 16 de minério; galho: 5% a cada 8 de madeira) | `ipezinho.gd _roll_injury`, `_roll_branch` | Implementado | Um fator a mais nos dois sorteios. |
| **Doença** | — | **Não existe como sistema.** "doença" é só a causa de um machucado leve (o migrante doente). | A ração reduzida usa o acidente/ferimento que já existe, sem criar doença. |
| **Defesa**: vigília em rodízio (50% dos guardas por noite comum; todos em noite de invasão) | `schedule.gd de_vigia`, `vigilia_fracao` | Implementado | Vigilância reforçada. |
| **Brecha** (guarda caído no portão → saque de 12% do minério e dos créditos) e **roubo do Ferrugento** (3 por golpe) | `defense.gd raid_*_percent`, `creature.gd steal_amount` | Implementado | Vigilância reforçada. |
| **Treino** (`combat_skill` 0→100% no campo, ~110 s; dano = 50%→100%, vida 30→50; **trava em 100%, nunca cai**) | `campo_treino.gd train_rate`, `ipezinho.gd train`, `_golpeia` | Implementado, **mas não serve sozinho pra uma política**: depois de 100% o guarda não treina mais e fica em casa de dia. Ver a dependência em 2.3. | |
| **Migrantes** (intervalo de 1,5 a 4 dias pela atratividade; ×1,5 sem cama; prazo de 1 dia no portão; **rede de segurança: < 4 ipezinhos → ajuda em meio dia**; o satélite chama um grupo) | `migrantes.gd` | Implementado | Multiplicador no `intervalo()`, condição na chegada, prazo. |
| **Traços de personalidade** | — | **Não existem** (o Prompt R é futuro). | Só o ponto de leitura do ânimo, pronto pra ele (seção 4). |
| **Dificuldade** (Prompt 5) | — | **Não existe** (nenhuma linha no código). | O ponto de composição dos multiplicadores, pronto pra ela (seção 4). |
| **Família** (Prompt F) | — | Não existe. | Um espaço reservado na janela. |
| **Missões** (tipos: fundar, casas, construção, minério, item, invasões, estágio, pesquisa, vendido, obras, mortes) | `missoes.gd` | Implementado | **Nenhum tipo depende de população**: nenhuma política trava uma missão. |
| **Telemetria** (uma linha de CSV por dia) | `telemetria.gd` | Implementado | Colunas novas (seção 3.6). |
| **Save** | `save_manager.gd` + `save_util.gd` | Implementado | Chave nova `politicas`. |

### 1.1 Multiplicadores que já existem (pra não contar em dobro)

| Grandeza | Hoje multiplica por |
|---|---|
| **Fome (queda)** | `hunger_decay` × `sleep_hunger_mult` (dormindo) × `sun.hunger_mult()` (inverno 1,25) |
| **Porção / fome da refeição** | `Schedule.porcao` × `ensopado_porcao_mult`; `Schedule.refeicao_fome` × `ensopado_fome_mult` |
| **Produção (pessoa)** | zanga (0,8 / 0,55) × faixa de ânimo (0,6 / 0,8 / 1,0 / 1,1) × frio sem casaco × refeições perdidas (−12% cada) |
| **Produção (mina)** | o de cima × pesquisa (explosivos) × picareta da Oficina × `Economy.ritmo_mineracao` (0,045) |
| **Produção (máquinas)** | `work_mult` do operador × `Desgaste.eficiencia()` |
| **Acidente na mina** | `injury_chance` × zanga (2 / 4) × profundidade × escavadeira (vazamento) × pesquisa (escoramento) × andar não reconhecido |
| **Acidente do galho** | `branch_injury_chance` × zanga × noite (2) |

**A política entra como UM fator novo em cada grandeza**, sem mexer nos de cima. A composição é multiplicativa, sempre.

### 1.2 Um achado da auditoria (não vou mudar sem você mandar)

Hoje o prato servido **sai do estoque inteiro**, mas quem enche a barriga **larga o resto no prato** (`ipezinho.come_prato`). As
contas *(calculado)*: um ipezinho perde cerca de **81 de fome por dia** (0,2/s acordado por ~16,5 h + 0,04/s dormindo), mas
come **3 porções = 135 de fome** (24 unidades). Na prática, **cerca de 40% da comida servida vai pro lixo**. No inverno a perda
sobe pra ~101/dia e a sobra cai pra ~25%.

Isso importa pra ração: **a ração reduzida economiza comida de verdade no verão e quase não aperta a barriga; no inverno não
tem margem nenhuma** (3 × 33,75 = 101 = a perda do inverno), e uma refeição perdida já leva à fome. É uma decisão estratégica
boa e não precisa de número inventado. Confirmo na Etapa 5 com o `bench_comida.gd`.

---

## 2) As quatro políticas

Todas começam no padrão, que é **exatamente o jogo de hoje** (todos os multiplicadores valem 1,0).

### 2.1 Jornada de trabalho

**Não cria horário nenhum.** O expediente continua das 07:00 às 12:00 e das 13:00 às 18:00, e a política nunca passa da volta
pra casa, do portão, da invasão, da missa nem da folga de domingo. Ela muda só três coisas **dentro do expediente**: o quanto
rende, o risco de acidente e o ânimo.

| Opção | Produção | Acidente | Ânimo | Por que escolher | Custo |
|---|---|---|---|---|---|
| **Normal** | ×1,0 | ×1,0 | 0 | O equilíbrio de sempre. | — |
| **Estendida** ("ritmo puxado") | **×1,15** | **×1,30** | **−8** | Correr com uma obra, juntar minério pra uma meta. | Ânimo e machucados (mais trabalho pro médico). |
| **Reduzida** | **×0,85** | ×1,0 | **+5** | Segurar uma vila triste longe da greve, sem gastar créditos. | Produção. |

- **Quem é afetado:** só quem PRODUZ (minerador, lenhador, caçador e agricultor, engenheiro, fundidor, ferreiro, carpinteiro,
  pesquisador no campo, mecânico, carregador). **Ficam de fora os serviços essenciais**: cozinheiro, médico, guarda e padre
  (lista em `@export`). Assim a reduzida não derruba a cozinha e não leva a vila à fome.
- **Turno extra** (tecla T, à noite): segue como está, sem o multiplicador.
- Pra comparar *(calculado)*: a taverna dá +5 de ânimo por 120 cr. A jornada reduzida dá +5 em troca de 15% da produção.

### 2.2 Rações (só a PORÇÃO; o cardápio continua escolhendo o PRATO)

| Opção | Porção | Fome que enche | Ânimo | Consequência longa |
|---|---|---|---|---|
| **Normal** | ×1,0 | ×1,0 | 0 | — |
| **Reduzida** | **×0,75** (6 un.) | **×0,75** (34) | **−6** | **Fraqueza** depois de **3 dias seguidos**: produção ×0,9 e acidente ×1,25, até **2 dias** depois de voltar ao normal. |
| ~~Farta~~ | — | — | — | **Proponho cortar** (abaixo). |

- **Não cria comida:** porção e fome caem na MESMA proporção, então cada unidade rende o mesmo. Sem comida no comedouro nada
  muda (ele serve o que tiver, como hoje). **Não há morte causada pela política**: a fome de verdade continua sendo a mesma de
  sempre.
- **Como combina com o prato** (os dois multiplicam, com teto):
  `porção = 8 × prato × ração`, presa entre **×0,6 e ×1,5** do básico (o teto é o próprio ensopado).

  | Prato × ração | Porção | Fome | Ânimo |
  |---|---|---|---|
  | Comum × normal | 8 | 45 | 0 |
  | Comum × reduzida | 6 | 34 | −6 |
  | Ensopado × normal | 12 | 56 | até +6 |
  | Ensopado × reduzida | 9 | 42 | até +6 −6 = 0 (gasta mais que o comum normal e não alegra: sem vantagem escondida) |

- **Por que cortar a "Farta":** ela seria porção ×1,25, fome ×1,25 e um pouco de ânimo, ou seja, **o ensopado de novo**, só que
  sem o custo do cozinheiro (o ensopado prepara 1,3× mais devagar). E por causa do achado 1.2, a porção maior **iria quase toda
  pro lixo**. A alavanca de "comer melhor" já existe e é o cardápio. A ração fica com Normal e Reduzida.
  *(Se você preferir manter as três: Farta = porção ×1,25, fome ×1,25, +4 de ânimo, presa no mesmo teto ×1,5, e o ânimo dela
  NÃO soma com o do ensopado: vale o maior.)*

### 2.3 Segurança (cada opção com UMA regra de custo)

**A dependência que achei:** fora da noite de invasão **não acontece nada à noite** (os moradores do fundo nunca sobem, e o
migrante só é atacado com criatura no mapa). Na noite de invasão, **todos os guardas já ficam de vigia**. E o treino trava em
100%. Por isso, "mais guardas acordados" ou "treinar mais" **sozinhos não mudariam nada**. A proposta liga cada opção ao que já
existe na defesa:

| Opção | O que faz | Regra de custo (única) |
|---|---|---|
| **Padrão** | O de hoje. | — |
| **Vigilância reforçada** | Todos os guardas de vigia toda noite (fim do rodízio). **Armazém vigiado**: o roubo do Ferrugento e o saque da brecha ficam **×0,5**. Quem espera no portão **não é atacado** enquanto houver guarda de vigia. | **Créditos:** 5 cr por guarda de vigia, por noite, pagos ao anoitecer (tochas e óleo). Sem créditos, aquela noite vale o padrão, com aviso. |
| **Treinamento** | Precisa de **campo de treino**. Treino **×1,5** mais rápido e o **teto da habilidade sobe de 100% pra 125%** ("veterano"). Pela fórmula que já existe: dano ×1,125 e vida 55 em vez de 50. Ao sair da política, o que passou de 100% **cai devagar** até 100%. | **Ânimo dos guardas:** −6 ("treino puxado"), só neles. |

- **A mudança estrutural no treino** (precisa do seu OK): `combat_skill` deixa de travar em 1,0 e passa a travar no teto da
  política (1,0 no padrão). É a mesma fórmula de dano e vida, só esticada. O save aceita até 1,25.
- Sem nenhum bônus de combate solto: o efeito passa pela habilidade, pelo roubo e pela brecha que já existem.

### 2.4 Migração (a MESMA lógica de chegada; nenhuma contagem nova)

| Opção | O que faz | Custo |
|---|---|---|
| **Aberta** | O de hoje. | — |
| **Seletiva** | Intervalo **×1,5**. **Só vem grupo quando há cama livre**, e do tamanho das camas livres (no máximo 3). O prazo no portão fica **×2** (mais tempo pra avaliar). | Crescimento mais lento. |
| **Fechada** | **O relógio do próximo grupo para** (volta a andar quando reabre). | A vila não cresce. |

- **A rede de segurança vale sempre**, mesmo com a Fechada: com menos de 4 ipezinhos a ajuda chega como hoje.
- **Quem já espera no portão quando fecha:** fica, e o cartão **expira no prazo normal**, sem punição. O jogador ainda pode
  aceitar.
- **O satélite** (pesquisa que chama um grupo na hora): proponho que **funcione mesmo com a Fechada**, porque é uma ordem
  explícita do jogador. *(Decisão sua.)*

---

## 3) Regras gerais

### 3.1 Troca e espera
- Uma opção ativa por política. Escolher mostra **o que ganha, o que custa e por que escolher**, e pede **Confirmar**.
- **Espera de 1 dia de jogo** (`troca_espera_dias`, @export) entre trocas da MESMA política. A primeira troca da partida é livre.
- **Exceção, pra nunca prender a vila:** em greve ou com o aviso de "insatisfeitos", **voltar ao padrão é imediato**.
- O efeito vale na hora (é multiplicador): não mexe em agenda, obra nem fila.

### 3.2 Acesso
- A janela libera no **estágio 2 da vila (Vilarejo)**. É simples, aparece no Centro da Vila ("libera: Políticas da Vila") e chega
  depois de o jogador já ter visto fome, ânimo e uma invasão. *(Alternativa: ao cumprir o Capítulo 1 das missões.)*
- Tecla **`=`** (a tecla física do "=", a mesma no ABNT2 e no americano; está livre e não é tecla morta), trocável nas
  Configurações (`teclas.gd NOMES`).
- Entra no menu **Janelas** do layout v2 (`hud._add_panel`, com `is_available()` pelo estágio). Antes do estágio 2 a tecla dá um
  aviso curto ("Políticas da Vila: libera no Vilarejo").

### 3.3 Janela "Políticas da Vila" (layout v2, `Tipo.*`, pele da interface)
- **Quatro cartões**, um por política: o nome, a opção ativa em destaque e as opções como botões.
- Clicar numa opção abre o **detalhe** dela embaixo: "Por que escolher", "Ganha" (verde), "Custa" (vermelho), a restrição
  ("precisa de campo de treino") e o botão **Confirmar** (ou o motivo de estar bloqueado: "pode trocar em 14 h").
- **Um quinto cartão reservado: "Família — em breve"** (o Prompt F), desligado.
- Sem gráficos nem painel de números. No rodapé, uma linha: "Efeito no ânimo agora: −8 (jornada estendida)".
- **Arte:** nenhuma estrutura nem personagem novo. A janela usa a pele e os ícones que já existem. Se faltar um ícone pro menu,
  reaproveito um sprite do jogo antes de pensar no PixelLab (regras 11 e 12).

### 3.4 Save
- Chave nova `politicas`: `{jornada, racao, seguranca, migracao, espera {política: s}, racao_dias (dias seguidos na reduzida),
  fraqueza (s restantes), trocas (total), primeira_troca}`.
- **Save antigo** (sem a chave): tudo no padrão, sem espera. Não precisa de `_migrate` (chave ausente = padrão, como as dos blocos
  anteriores). `combat_skill` passa a aceitar até 1,25 no load (saves antigos têm ≤ 1,0).
- Documentado no cabeçalho do `save_manager.gd`.

### 3.5 Greve: nunca inevitável
- **Teto da penalidade somada das políticas: −12** (`animo_penalidade_max`). Estendida (−8) + reduzida (−6) = −14 → vira −12.
- Conta *(calculado)* de uma vila comum: 60 de base + 8 (cama) + 3 (vilarejo) = 71 → **59** com as duas. A greve é abaixo de 30.
  Pra chegar lá a vila já precisaria estar triste por outros motivos (sem cama, fome, luto), e aí a volta imediata ao padrão (3.1)
  devolve os 12 pontos.
- A confirmação mostra o **ânimo previsto** e avisa em vermelho se ficar abaixo de 40 (a faixa de "insatisfeitos").
- Na Etapa 5 testo de propósito: estendida + reduzida numa vila com 10 pessoas, uma em fome e uma em luto. Tem que chegar ao
  aviso, mas não à greve que não tem volta.

### 3.6 Telemetria (colunas novas no CSV do dia)
`pol_jornada`, `pol_racao`, `pol_seguranca`, `pol_migracao`, `trocas_politica` (total), `fraqueza` (0/1),
`comida_servida_dia` (unidades que saíram dos comedouros) e `acidentes_dia` (mina + galho). As duas últimas são o que falta pra
comparar antes e depois.

---

## 4) A arquitetura (pequena, sem sistema paralelo)

- **`scripts/core/politicas.gd`** (nó `Politicas` em `main.tscn`, grupo `politicas`): as opções ativas, as esperas, a fraqueza,
  o save e todos os números em `@export` com comentário.
- **Um único ponto de composição** pros multiplicadores: `scripts/core/modificadores.gd`,
  `Modificadores.mult(arvore, chave, quem = null)`. Ele multiplica o `mult(chave, quem)` de **todo nó do grupo
  `modificadores`**. As Políticas entram nesse grupo. **A Dificuldade (Prompt 5) só precisa entrar no mesmo grupo**, e quem
  consome não muda nada. As chaves: `producao`, `acidente`, `porcao`, `fome_refeicao`, `migracao_intervalo`, `treino`, `roubo`
  (o resultado é guardado por quadro, pra não pesar com muitos ipezinhos).
- **Um único ponto de leitura do ânimo:** `Politicas.fatores_animo(w) -> [[texto, valor], ...]`, chamado de
  `ipezinho.happiness_factors`. Dentro dele, cada valor passa por `_reacao(w, politica, valor)`. Hoje ele devolve o valor sem
  mudar nada. **O Prompt R (traços) só mexe nessa função** pra modular por personalidade, sem tocar nas políticas.
- Quem passa a consultar: `ipezinho.work_mult`, `_roll_injury`, `_roll_branch`, `train` e o load; `comedouro._porcao` e
  `_fome_da_porcao`; `migrantes._process`, `intervalo` e `chama_grupo`; `schedule.de_vigia`; `defense` (saque); `creature`
  (roubo); `campo_treino` (ritmo); `telemetria`; `hud` e `teclas`.

---

## 5) Validação (Etapa 5)

1. **Referência antes:** um banco `tests/bench_politicas.gd` (partida nova de verdade, sem mexer no balanceamento) mede, por dia,
   o minério e a madeira produzidos, a comida servida, a fome média, o ânimo médio, os acidentes e o resultado da 1ª invasão.
2. **Depois:** o mesmo banco com cada opção e com as combinações extremas (estendida + reduzida; reduzida no inverno;
   vigilância e treino numa invasão; fechada e seletiva com a vila crescendo).
3. **Cenários:** poucos moradores (4: a rede de segurança com a Fechada), população crescendo (10 → 16), falta de comida
   (cozinha vazia: a reduzida não cria comida) e invasão.
4. **Caça de exploit:** alguma combinação dá ganho sem custo relevante? Ex.: a reduzida no verão (achado 1.2), ou trocar de manhã
   e de noite (a espera de 1 dia barra).
5. **Nada paralisa a vila e nenhuma missão fica impossível** (nenhum objetivo depende de população nem de política).
6. **Save:** novo, antigo (sem a chave), no meio da espera, com fraqueza e com treino acima de 100%.
7. **Testes:** o `b108_politicas` novo, mais os que tocam no mesmo código, **um por vez, em primeiro plano**: b84/b85 (agenda),
   b83 (relógio), b101 (migrantes), b107 (cardápio), b35/b36 (defesa e brecha), b103 (moradores e patrulha), b105 (carregador),
   b106 (coleta), b95/b95b (layout e tipografia), os de save e os GUT iso. No relatório, separados em **aprovados, reprovados e
   intermitentes** (b84 e b85 já tinham falha rara por sorteio).

---

## 6) Decisões que preciso de você

1. **Ração "Farta":** cortar (recomendo) ou manter com o teto e sem somar ânimo com o ensopado?
2. **Segurança:** aprova a vigilância reforçada (armazém vigiado ×0,5, custo de 5 cr por guarda por noite) e o treinamento
   (teto de 125%, custo de −6 de ânimo nos guardas)? O teto exige mudar a trava do `combat_skill`.
3. **Satélite com a migração Fechada:** chama mesmo assim (recomendo, é uma ordem explícita) ou fica bloqueado?
4. **Acesso:** estágio 2 (Vilarejo, recomendo) ou o fim do Capítulo 1?
5. **Tecla `=`:** ok?
6. **Espera de 1 dia de jogo** entre trocas da mesma política (voltar ao padrão é imediato em greve ou com a vila insatisfeita): ok?
7. **O achado 1.2** (cerca de 40% do prato vai pro lixo): só registro, ou quer que eu proponha a correção num bloco separado?

## 7) Arquivos previstos

Novos: `scripts/core/politicas.gd`, `politicas_panel.gd`, `modificadores.gd`, `tests/blocos/b108_politicas.gd`,
`tests/bench_politicas.gd`, `docs/BLOCO108_POLITICAS.md`.
Alterados: `scenes/game/main.tscn`, `ipezinho.gd`, `comedouro.gd`, `migrantes.gd`, `schedule.gd`, `defense.gd`,
`creature.gd`, `campo_treino.gd`, `telemetria.gd`, `save_manager.gd`, `hud.gd`, `teclas.gd`, `centro_vila.gd` (o texto do que
libera), `tests/test_blocos.gd`, `TESTING.md`, `docs/BALANCEAMENTO.md`, `CLAUDE.md` (próximo = b109), `CONTEXTO.md`.
