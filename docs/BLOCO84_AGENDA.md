# Bloco 84 — a agenda dos ipezinhos e a fome controlada

O pedido veio como "Bloco 53" (teste b53). O número já existe no histórico, então ficou **Bloco 84**, teste `b84`.

**Skills usadas:**
- `godot-gdscript`
- `ai-behavior-trees-utility-ai` (camadas de prioridade da decisão)
- `survival-crafting` (refeições e fome)
- `save-systems`
- `godot-gdscript-headless-testing`

## Plano (mostrado antes de codar)

1. **Nó novo `Schedule`** (`scripts/core/schedule.gd`, na `main.tscn`, grupo "schedule"), com os horários em
   `@export` e `periodo(ipezinho)`.
2. **No `_choose_state` do ipezinho, uma camada entre as emergências e as necessidades**, sem reescrever o que já
   funcionava: o horário de trabalho cai na lógica de sempre.
3. **Fome controlada:** a fome cai devagar, uma porção por refeição, e refeição perdida rende menos.
4. **HUD:** porções no estoque x refeições que ainda faltam hoje.
5. **Save** das refeições.
6. **Teste `b84`.**

## Prioridade

**Emergência > agenda > necessidades.**

- **Emergência** (como já era, mais a invasão):
  - caído;
  - ferido (enfermaria);
  - resgate do médico;
  - onda solar (abrigo);
  - **invasão em andamento**: quem não é guarda fica em casa (o médico, no plantão);
  - greve.
- **Agenda:** este nó.
- **Necessidades:** comer fora de hora **só com fome braba** (abaixo de 30), taverna e o resto da lógica de
  sempre.

## Os horários

Os 4 marcos são do relógio (`day_night.gd`, Bloco 83), para ficar um lugar só pra eles. O `Schedule` completa.

| Hora | Período | O que fazem |
|---|---|---|
| 05:00–07:00 | café | comem a 1ª refeição; depois já podem ir trabalhar |
| 07:00–12:00 | trabalho | a lógica de sempre (função, área de trabalho...) |
| 12:00–13:00 | almoço | 2ª refeição, depois voltam ao trabalho |
| 13:00–18:00 | trabalho | |
| 18:00–18:30 | voltar | largam a carga no armazém (madeira, minério, matéria-prima) e vão pra casa |
| 18:30–21:30 | hora social | jantam (3ª refeição); depois taverna (se estão pra baixo) ou casa. O Bloco 85 faz a hora social de verdade. |
| 21:30–05:00 | dormir | casa |

- **Fim do café e almoço:** `cafe_fim` 07:00, `almoco_inicio` 12:00 e `almoco_fim` 13:00.
- **Carga atrasada:** "voltar" dura meia hora de jogo (cerca de 11 s reais). Quem ainda está com carga quando
  ela acaba **termina a entrega** antes de ir pra casa, mesmo na hora social ou de dormir.
- **Turno extra:** continua trabalhando fora de hora, como antes, menos nas refeições.

### Exceções

- **Médico:**
  - sempre de **plantão**, de dia e de noite; não vai dormir em casa;
  - come em **turnos** (`medico_turno` = meia hora): o médico 1 come na 1ª meia hora de cada refeição, o 2º na
    seguinte… A enfermaria nunca fica sem ninguém.
- **Guardas:**
  - **vigília noturna em rodízio:** `vigilia_fracao` (metade) dos guardas por noite, pelo menos 1, girando a
    cada dia; quem não está de vigia faz a noite normal;
  - **na noite de invasão, todos**;
  - o de vigia **janta antes** de ir pro posto.
- **Cozinheiro:** começa às **04:00** (`cozinheiro_inicio`, prepara o café). De **16:00** (`jantar_preparo`)
  até o anoitecer fica cozinhando o jantar, sem o "voltar" das 18:00.

## Fome controlada

- **A fome cai devagar:** `ipezinho.hunger_decay` foi de 0,8 para **0,2 por segundo** (4,5 por hora de jogo).
  Dormindo cai menos, como antes.
- **Cada refeição** (café, almoço, jantar) é **uma porção** do comedouro:
  - `porcao` = 8 unidades de comida, que restauram `refeicao_fome` = 45 de fome;
  - o comedouro serve a porção quando ele chega e ele come o prato aos poucos;
  - sem porção inteira, serve o que tiver.
- **Sem fome**, acima de `refeicao_dispensa` (90%), ele **pula a refeição** sem problema.
- **Refeição perdida:**
  - acontece quando ele estava com fome e a hora passou sem comer (sem comida, por exemplo);
  - aparece "Perdi o almoço!" e ele rende **12% a menos** por refeição perdida (`perda_por_refeicao`, até
    `perda_max` = 3 seguidas);
  - volta ao normal na próxima refeição;
  - ferido ou caído não perde.
- **O dia zera as refeições** no amanhecer.

## HUD

O chip da comida mostra **"11 (hoje 14)"**: as porções no estoque e as refeições que ainda faltam hoje para a
vila, ou seja, as de cada um que ainda não fez e cuja hora não passou.

- **Cor:** amarelo quando não dá pra todos, vermelho quando falta mais da metade.
- **Na dica:** a conta e quantas porções faltam.

## Save

- `ipezinho.gd` salva `refeicoes_hoje` (as refeições feitas hoje) e `refeicoes_perdidas`.
- **Save antigo:** nenhuma refeição feita hoje, nenhuma perdida.

## Testes

- **`b84_agenda.gd` (novo, passa):**
  - os períodos do minerador;
  - o médico de plantão comendo no turno dele;
  - o cozinheiro às 04:00 e até o anoitecer;
  - a vigília de 1 de 2 guardas girando, e todos na noite de invasão;
  - **com a simulação rodando:**
    - o almoço gasta exatamente 1 porção por pessoa e enche a fome;
    - eles voltam a trabalhar;
    - às 18:00 o lenhador leva a madeira e o minerador o minério, e vão pra casa;
    - médico de plantão;
    - sem comida, perde o jantar e rende menos;
    - às 21:30 todos em casa;
    - à noite, um guarda de vigia e o outro dormindo;
    - jantar de novo tira a penalidade;
  - a invasão manda o minerador pra casa;
  - a fome a 4,5 por hora;
  - o HUD;
  - o save novo e antigo;
  - o amanhecer zera.
- A onda solar é emergência e manda todo mundo pro abrigo, então o teste desliga as ondas sorteadas para não
  misturar.
- **Bateria dos testes antigos de comportamento:** 20 passaram (b25 funções e troca, b26, b27, b28, b29_30,
  b31, b31b, b33, b34, b35, b36, b37, b41, b44, b45) e mais b83, p28_save, b56 e b77 rodados à parte. O sistema
  encerrou a bateria em segundo plano por falta de memória, não por falha. **Não conferidos depois do
  Bloco 84:** b51, b57, b61, b64, b79, b81, p2, p29_bonecos e p29_mapa.
