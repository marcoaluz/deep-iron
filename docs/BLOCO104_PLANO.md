# Bloco 104 — Robô antigo, batedor e expedições (plano)

Data: 2026-10-08. Branch `isometrico`. Pedido: "Prompt E". Teste: `b104_expedicoes`. **Esperando a aprovação do Marco.**

## O que existe hoje (auditoria)

- **O robô** (`robo.gd`): o ciclo `found → carried → base → repairing → active` (o Guarda Ferrugento).
  - Ele é **achado por sorte** em `finds.roll`: no fundo, a cada achado, 10% (`robot_chance`), garantido no 6º achado do
    fundo (`robot_guarantee_after`). Ele aparece caído do lado de quem minerou.
  - A janela `robo_panel` manda um ipezinho carregar até a Oficina, e o conserto é obra de engenheiro (6 peças raras,
    400 cr, 60 ferro).
- **O rádio** (`research.gd`): pesquisa do ramo Vila, **excludente com a Hidroponia**. Quem escolheu a Hidroponia nunca
  tem rádio, então a cadeia não pode depender só dele (ver a decisão 1).
- **O leste** (`environment._build_leste`): área do mapa trancada até "Desbravar o leste" (Centro). Tem a vila antiga
  (igreja, torre, enxaimel) e jazidas. **É parte do mapa jogável**; o que fica ALÉM dele não existe hoje.
- **O catálogo e o bestiário** (Blocos 102 e 103): o estudo do corpo do Ferrugento já existe (a história dele fala de "o
  número de série de uma fábrica de antes da explosão"). Os locais S2–S5 e o Leste têm o reconhecimento.
- **A agenda** acorda às 05:00, o trabalho vai até as 18:00 e o portão fecha às 18:30. **Os migrantes** (Bloco 101) já
  nascem fora e andam até o portão: o mesmo caminho serve pra quem sai e pra quem volta.
- **O mapa:** hoje só existe o corte vertical (F2, `mapa_mundo.png`). Não há um mapa da superfície em volta da vila. As
  regiões das expedições precisam de um mapa novo (ver a arte).

## O plano

### 1) A cadeia de descoberta do robô (no lugar da sorte)

| Passo | O que acontece | Onde |
|---|---|---|
| 1. A origem | Estudar o **corpo de um Ferrugento** (Bloco 103) revela a pista: "número de série de uma fábrica de antes da explosão". | catálogo + diário |
| 2. O sinal | Com a pista e o **Rádio da vila**, o rádio capta um sinal fraco à noite. Sem rádio, a **Antena improvisada** (decisão 1). | aviso + diário |
| 3. A triangulação | Uma pesquisadora vai a **3 pontos de escuta** (o portão, o alto da pedreira, a boca do poço) e anota em cada um (a mesma tarefa de campo do catálogo, 40 s cada). No 3º, marca a região. | catálogo (entrada nova "Sinal antigo") |
| 4. A região | Aparece no mapa das expedições: **"A fábrica soterrada"**. | janela Expedições |
| 5. A expedição | Uma expedição vai e **acha o robô**; ele volta com a equipe e é largado no portão, no estado "found". | relatório |
| 6. O de sempre | Carregar até a Oficina, o conserto e o guarda. Nada muda daqui pra frente. | robo.gd |

- **O achado por sorte** sai das partidas novas. Fica só como reserva pros saves de antes do Bloco 104 em que o robô
  ainda não apareceu. A cadeia também vale pra eles.
- **Save com o robô achado, consertando ou ativo:** igual a hoje.

### 2) A função BATEDOR / BATEDORA (tecla **B**? ver a decisão 6)
- **Personagem novo** (homem e mulher) com a receita completa do elenco (regra 11):
  - `create_image_pro` 48×84 e `create_character` v3;
  - caminhada de 8 quadros;
  - comer, ferido, deitar e mancar;
  - o trabalho ("batendo o mato": a luneta / o facão);
  - o casaco de inverno;
  - o retrato com as 5 expressões;
  - o ícone da barra.
  - **Piloto primeiro.**
- **Na vila (sem expedição):** ele "bate o mato". De dia vai a pontos na beira da floresta e da clareira.
  - Avista de longe: o alcance de avistar do catálogo ×3 pra animais e locais.
  - **Rastreia tocas:** a toca rastreada no dia ganha +50% no nascer de bichos (`@export`), e o caçador acha mais.
- **Nas expedições:**
  - **lidera** (a decisão 2);
  - **revela a névoa** das regiões vizinhas (uma expedição curta de batedor tira o "?");
  - dá **+50% nas pistas e nos achados de mapa** (`@export`).

### 3) As expedições (`expedicoes.gd`, nó "Expedicoes", grupo "expedicoes"; janela `expedicoes_panel.gd`)
- **A janela** (estilo do layout v2) tem quatro partes:
  - **o mapa da região** com as regiões ("?" até serem reveladas), clicáveis;
  - **a equipe:** 2 a 4 entre batedor, guardas, pesquisadora e médico, escolhidos pelo nome, com a arma, o traje e a
    saúde de cada um;
  - **as provisões:** a **ração** (comida da cozinha, porções por pessoa por dia, `@export` 3) e o **kit de
    ferramentas** opcional (ferro + madeira: menos risco e mais achado de minério);
  - **a duração** (1 a 3 dias de jogo; cada região tem a mínima).
- **A partida e a volta:**
  - **Saem de dia:** a equipe anda até o portão e **sai do mundo** (como os migrantes, ao contrário).
  - **Fora:** não trabalham, não comem na vila, não dormem nas casas (a cama fica guardada) e não contam pra defesa.
    **A vila fica mais fraca** se a invasão cair nesses dias (os guardas estão fora).
  - **Na volta** (manhã do último dia), aparecem na floresta e entram pelo portão. Se a volta cair de noite, chegam de
    manhã.
- **O risco** (calculado e mostrado na janela antes de sair, com as partes):
  - **perigo da região** (0,08 a 0,35 por pessoa por dia, nos dados);
  - **escolta:** cada guarda armado ×0,8 (até ×0,5);
  - **equipamento:** traje exigido pela região, ×3 sem ele;
  - **provisões:** sem ração inteira ×2; o kit ×0,85;
  - **batedor:** ×0,7.
  - Cada pessoa, a cada dia, rola o ferimento (leve/grave). Grave sem médico na equipe pode virar **morte** (`@export`
    0,3; com médico 0,05).
- **As decisões no caminho:** 1 ou 2 por expedição, sorteadas da tabela da região (texto em arquivo). Um cartão com 2
  opções, e o relógio não para. Sem resposta em 2 h de jogo, vale a mais prudente.
  - Exemplos: "Atravessar o rio cheio (mais rápido, risco ×1,5) ou dar a volta (+½ dia)"; "Seguir o rastro do javali
    (couro e carne) ou ficar na trilha".
- **O resultado:** um **relatório narrativo** (janela + diário) com o que aconteceu, os achados, os feridos e mortos.
  Achados possíveis:
  - **peças raras** e minério;
  - **mapas** (revelam uma região);
  - **pistas** e **entradas do catálogo** (avistadas: a pesquisadora estuda depois);
  - **sobreviventes**, que viram um **grupo de migrantes** no portão (Bloco 101);
  - **o robô** (só na fábrica soterrada, garantido).
- **Uma expedição por vez** (`max_expedicoes`, `@export` 1). A **melhoria "Posto de expedição"** do Centro (estágio 3)
  libera 2.

### 4) As regiões (dados: `data/expedicoes/regioes.json` + textos em `data/expedicoes/textos.txt`)

| Região | Como aparece ("?" até…) | Perigo/dia | Dias | Exige | Achados principais |
|---|---|---|---|---|---|
| **A floresta funda** (oeste) | revelada desde o começo (a 1ª expedição) | 0,08 | 1 | — | couro, carne, uma toca nova, sobreviventes (25%) |
| **A estrada velha** (sul) | o batedor revela (expedição curta) | 0,10 | 1–2 | — | sobreviventes (50%), peças raras, um mapa |
| **As ruínas além do leste** | o leste desbravado + o batedor | 0,15 | 2 | — | peças raras, ferragens, mapa, catálogo (javali/lumívoro) |
| **A fábrica soterrada** | a cadeia do robô (passo 4) | 0,20 | 2 | máscara de gás (o gás do S2) | **o robô**, peças raras (muitas) |
| **As galerias fundas do S2** | o S2 reconhecido | 0,22 | 1 | máscara de gás | cristal verde, prata, pista |
| **As fendas do S3** | o S3 reconhecido | 0,30 | 1 | traje térmico | cristal rubro, solarita |
| **(S4/S5)** | reconhecidos | 0,35 | 1 | os trajes deles | gema azul, cristais |

A equipe:

| Quem | O que faz na expedição |
|---|---|
| Batedor (1, obrigatório: decisão 2) | lidera; risco ×0,7; +50% pistas e mapas; revela a névoa |
| Guarda (0–3) | escolta: ×0,8 cada (até ×0,5); defende nas decisões de luta |
| Pesquisadora (0–1) | as entradas do catálogo voltam **estudadas** (em vez de avistadas) e +1 pista |
| Médico (0–1) | o ferido grave quase nunca morre (×0,05 em vez de 0,3) e volta tratado (leve) |

### 5) O mapa, as pistas e os sinais
- **O mapa da região** (arte nova): o entorno visto de cima (a floresta, a estrada, o leste, a encosta com a fábrica,
  as bocas da mina), com o "?" (por código) nas regiões escondidas e o ícone da expedição em curso.
- **As pistas** vão pro diário (páginas novas, com o texto do arquivo) e pro catálogo (a entrada "Sinal antigo" e as
  regiões como locais).
- **Os sinais pras missões:** `expedicao_saiu(regiao)`, `expedicao_voltou(regiao, resultado)`, `regiao_revelada(id)`,
  `robo_localizado`. Os objetivos: `expedicao` e `regiao`.

### 6) Balanceamento, telemetria, save
- **Balanceamento:** tudo em `@export` (risco, ração, chances, multiplicadores, `max_expedicoes`) e nos dados das regiões.
- **Telemetria:** as colunas `expedicoes_dia`, `fora_da_vila`, `achados_expedicao`, `feridos_expedicao`.
- **Save:**
  - **a chave nova `"expedicoes"`:** as regiões reveladas, as em andamento (a equipe pelo nome, o destino, o dia da volta,
    a decisão pendente, os achados sorteados), as pistas da cadeia e os pontos de escuta feitos;
  - **os membros fora** vão no save com `fora = true` (sem posição);
  - **save antigo:** nenhuma expedição; a floresta revelada; o leste revelado se já desbravado; a cadeia do robô no passo
    certo (robô achado = cadeia cumprida; Ferrugento estudado = passo 1).

### 7) Arte (PixelLab, regra 11)
- **O batedor e a batedora** (a receita do elenco): ~450 a 500 gerações (a Carpintaria custou 485).
- **O mapa da região:** 1 ilustração 480×320 no estilo do mapa do mundo, com a piloto e as refações: ~60 a 100.
- **Os ícones** (batedor na barra; a expedição na janela): ~20.
- **Total estimado: ~550 a 620 gerações** do saldo de ~6.340. Piloto antes de cada lote.

### 8) Teste `b104_expedicoes`
Confere:
- a cadeia (corpo → pista → sinal → 3 pontos → região);
- sem sorte numa partida nova e a sorte no save antigo;
- o batedor (a função, a tecla, avistar de longe, a toca rastreada);
- a janela (as regiões com "?", a equipe 2–4, a ração, o risco calculado e as partes);
- a saída pelo portão e os membros fora do mundo (não comem, não contam na defesa);
- a decisão no caminho;
- a volta com o relatório e os achados (o robô no portão em "found", os migrantes);
- o ferimento e a morte possíveis;
- uma por vez e a melhoria;
- os sinais;
- o save, o save antigo e os membros fora no save.

## Decisões para o Marco

1. **O sinal sem rádio:** o Rádio é excludente com a Hidroponia. Proposta: a **Antena improvisada** (encomenda da
   Oficina, cobre + 2 peças raras) também capta o sinal, então ninguém fica sem o robô. Ok?
2. **O batedor obrigatório em toda expedição** (lidera)? Proposta: sim. Sem batedor, não sai.
3. **A fábrica soterrada** fica atrás das galerias do S2 e exige a máscara de gás de todos. Ok? (A alternativa é ser na
   superfície, além do leste.)
4. **A melhoria "Posto de expedição"** (estágio 3) pra 2 expedições. Ok?
5. **A arte:** ~550–620 gerações (batedor e batedora completos + o mapa + ícones). Ok?
6. **A tecla:** a **B** é do Bem-estar. Proposta: **Shift+B**? Ou a **K**, que hoje é só o "machucar (teste)" e iria pro
   Shift+K? E a janela das Expedições na tecla **X**? (a **X** é a função guarda.) Sugiro: a função Batedor na **K** e a
   janela Expedições na **;** (ponto e vírgula, ao lado da vírgula das Missões).
