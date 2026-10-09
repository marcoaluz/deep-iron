# Bloco 104 — Robô antigo, batedor e expedições

Data: 2026-10-08. Branch `isometrico`. Teste: `b104_expedicoes`. Plano: `docs/BLOCO104_PLANO.md`.

**O pedido:** o "Prompt E".

**As decisões do Marco:**
1. A Antena improvisada pra quem não tem o Rádio: "pode".
2. O batedor obrigatório: "sim".
3. Onde fica a fábrica: "verifique e analise" (a análise está abaixo).
4. O Posto de expedição: "pode ser".
5. A arte: "sim".
6. As teclas: "ok".

**Onde fica a fábrica (a análise):**
- Os Ferrugentos só existem depois que o S2 abre e saem pela boca do poço do elevador.
- O robô de hoje só era achado no fundo da mina, e o diário diz "achamos no fundo da mina".
- O S2 já tinha uma **zona de radiação** de verdade (a oeste) que não levava a nada, e os Ferrugentos "acumulam restos de
  energia solar".
- **A conclusão:** a fábrica fica **atrás da zona de radiação do S2**. A expedição sai por lá e pede o **traje
  antirradiação**.
- **A ordem natural:** S2 aberto → reconhecido → pesquisa dos Trajes → o traje na Oficina → a expedição.
- A superfície além do leste não combinava com nada do que o jogo já conta.

**Skills usadas:**
- `godot-gdscript`;
- `godot-gdscript-headless-testing`;
- `ai-behavior-trees-utility-ai` (o batedor, a saída e a volta);
- `save-systems` (quem está fora vai no save);
- `godot-ui-control` (a janela e o mapa);
- `survival-crafting` (risco e provisões);
- `create-game-assets` e `deep-iron-arte` (o personagem e o mapa).

## Como ficou

### 1) A cadeia do robô (no lugar da sorte)

| Passo | O que acontece |
|---|---|
| 1. A origem | O corpo do Ferrugento estudado (Bloco 103): a pista "número de série de uma fábrica" no diário. |
| 2. O sinal | De noite, o **Rádio da vila** ou a **Antena improvisada** (Oficina: 150 cr + 30 cobre + 10 madeira + 2 peças raras, estágio 2; só depois da pista) capta o sinal. Página no diário e o banner. |
| 3. As escutas | 3 pistas novas no catálogo (o portão, o alto da pedreira, a boca do poço). A pesquisadora anota em cada uma, com a tarefa de campo do Bloco 102. |
| 4. A região | No fim da 3ª escuta, **"A fábrica soterrada"** aparece no mapa; o banner "O SINAL FOI LOCALIZADO"; o sinal `robo_localizado`. |
| 5. O robô | A expedição à fábrica acha o robô (garantido). Ele chega desligado na saída ("found"). |
| 6. O de sempre | Carregar até a Oficina, o conserto e o guarda: nada mudou. |

- **Partida nova:** o achado por sorte do `finds.gd` **não acontece** mais.
- **Save antigo sem o robô:** a sorte continua como reserva (`sorte_robo`), e a cadeia também vale.
- **Save com o robô achado ou ativo:** igual.

### 2) O batedor e a batedora (função nova, tecla **K**)
- **Na vila:** de dia ele "bate o mato". Vai a pontos na clareira e nas tocas e olha de luneta por 20 s (`segundos_bater`).
  - **Avista de longe:** o alcance do catálogo ×3 (`batedor_alcance_mult`).
  - **Rastreia a toca:** no dia, os bichos dela nascem ×1,5 (`toca_rastreada_mult`), e o balão "Rastro fresco!".
- **Nas expedições:**
  - **lidera** (sem ele, não sai);
  - risco ×0,7;
  - +50% na chance de mapas, pistas e entradas do catálogo;
  - **explora as regiões "?"**.
- **O "machucar" de teste** foi pro **Shift+K** (Ctrl+Shift+K = grave).
- **Arte nova,** com a receita completa do elenco (regra 11, `oficios104.py`):
  - candidatos (piloto), personagem v3;
  - caminhada de 8 quadros, comer, ferido, deitar, mancar;
  - o **bater** (a luneta);
  - o casaco de inverno (caminhada + bater);
  - o **retrato com as 5 expressões** (nota por personagem: o chapéu dele; ela sem chapéu, com o capuz);
  - o ícone da barra (a luneta sobre o mapa).

### 3) As expedições (`expedicoes.gd`; janela `expedicoes_panel.gd`, tecla **;**)
- **A janela:**
  - **o mapa da região** (arte nova): a floresta queimada a oeste, a vila na pedreira com a torre do elevador, a estrada
    velha ao sul e as ruínas a leste;
  - as regiões da superfície no mapa (o nome, "?" se escondida, "?" apagado se trancada, com o motivo na dica) e as
    **da mina** numa coluna;
  - a região escolhida (o texto, o perigo, os dias, o traje);
  - **a equipe** (2 a 4 entre batedor, guarda, pesquisadora e médico);
  - **as provisões:** a ração (2 porções da cozinha por pessoa por dia) e o kit (20 ferro + 15 madeira: risco ×0,85,
    minério ×1,3);
  - **os dias**;
  - **o risco** com as partes ("perigo 8% × escolta ×0,80 × batedor ×0,70…") e a chance de alguém voltar ferido;
  - o Partir (com o motivo quando não dá), as expedições em curso (com a decisão pendente) e os 3 últimos relatórios.
- **A saída:** só de dia (até as 15:00). A equipe anda até a saída (o portão da floresta, ou o ponto do andar) e **sai do
  mundo**:
  - escondida e fora do grupo da vila: não trabalha, não come, não defende (os guardas que saíram não estão nos postos);
  - **a cama fica guardada**.
- **As decisões no caminho:** 1 (1 dia) ou 2 (2+ dias), de uma tabela de 12 com texto em arquivo.
  - Cada uma é um cartão com 2 opções que mexem no risco, nos achados e na duração (+½ dia).
  - Sem resposta em 2 h de jogo, vale a prudente.
  - O relatório conta o que escolheram.
- **A volta:** na manhã do dia da volta (de noite esperam o dia).
  - Os ferimentos rolam pelos dias e pelo risco. O grave sem médico pode morrer (30%; com médico 5%).
  - **Quem morre longe não deixa corpo:** vai pro memorial, sem o padre buscar.
  - O **relatório** aparece no banner, na janela e no diário.
- **Os achados** (por região, nos dados): couro, comida crua, madeira, pregos, ferragens, peças raras, minério, **mapas**
  (revelam outra região), **pistas** (páginas do diário), **entradas do catálogo** (com a pesquisadora na equipe, voltam
  estudadas), **sobreviventes** (um grupo de migrantes no portão, Bloco 101) e **o robô**.
- **Uma expedição por vez.** A melhoria **"Posto de expedição"** do Centro (estágio 3, 500 cr + 80 minério; cartão no
  CONSTRUIR, a imagem é um recorte do mapa) libera 2.

### 4) As regiões

| Região | Aparece | Perigo/dia | Dias | Traje | Destaque |
|---|---|---|---|---|---|
| A floresta funda | desde o começo | 8% | 1–2 | — | couro, comida, madeira, sobreviventes, o mapa da estrada |
| A estrada velha | "?" (o batedor explora) | 10% | 1–2 | — | sobreviventes, peças, pregos, o mapa das ruínas |
| As ruínas além do leste | o leste desbravado + "?" | 15% | 2–3 | — | peças, ferragens, pista |
| A fábrica soterrada | a cadeia do robô | 20% | 2–3 | antirradiação | **o robô**, muitas peças, pista |
| As galerias fundas do S2 | o S2 reconhecido | 22% | 1–2 | máscara de gás | cristal verde, prata |
| As fendas do S3 | o S3 reconhecido | 30% | 1–2 | traje térmico | cristal rubro, solarita |
| Os veios da cachoeira (S4) | o S4 reconhecido | 35% | 1–2 | traje térmico | cristais, solarita |
| A margem do lago azul (S5) | o S5 reconhecido | 35% | 1–2 | — | gema azul, pista |

### 5) Sinais, missões, telemetria
- **Os sinais:** `expedicao_saiu`, `expedicao_voltou`, `regiao_revelada` e `robo_localizado`.
- **Os objetivos de missão:** `expedicao` (quantas, ou de uma região) e `regiao` (revelada).
- **A telemetria:** `expedicoes_fora`, `gente_fora`, `expedicoes_voltaram`, `achados_expedicao` e `feridos_expedicao`.

## Save
- **A chave nova `"expedicoes"`:**
  - as reveladas;
  - as **em curso, com o save de cada ipezinho que está fora** (eles não estão no grupo da vila; voltam por aqui, de
    novo fora do mundo, com a cama deles);
  - a cadeia, a `sorte_robo` e os relatórios;
  - as regiões de onde já voltou e os totais.
- **Também mudou:** o Centro ganhou a melhoria `posto`.
- **Save antigo:** nenhuma expedição; a floresta revelada; a cadeia no passo certo (robô achado = 5; Ferrugento estudado =
  1); a sorte como reserva se o robô ainda não apareceu.

## Arte (PixelLab)
- **Gasto: 201 gerações** (6.342 → 6.141). Bem abaixo da estimativa (550–620): os candidatos e as animações custam pouco
  neste tier.
- **O batedor e a batedora completos:** bonecos, casaco, retratos e o ícone. O `integra.py bonecos batedor` só
  **acrescentou** ao `bonecos.json` (conferido: nenhuma outra função regravada).
- **O mapa da região:** uma geração com o mapa do mundo de referência, aprovada de primeira.
- **Os ícones:** a expedição (a mochila) e a Antena.
- **O cartão do Posto:** reaproveita um recorte do mapa (regra 12).
- **As fotos:** `docs/arte/bloco104/` (os batedores na luneta, a janela, o relatório e a prancha dos retratos).

## Testes
- **`b104_expedicoes`** (novo, **0 falhas**).
- **A bateria completa** (87 testes de bloco, um por vez, com o APPDATA isolado):
  - **Falharam 2 na primeira volta:** `b92_arte_oficios` (o casaco do ferreiro) e `p29_predios` (a ordem do vagonete
    contra a montanha). São os dois intermitentes conhecidos.
  - Rodados de novo, **os 2 passaram**. Os outros 85 passaram de primeira, e nenhum teste antigo precisou de ajuste.
- **GUT da vista iso:** 12 testes, todos passaram.
