# Bloco 99 — Entrada da mina, elevador, escadas e vagonete

Data: 2026-10-08. Branch `isometrico`. Teste: `b99_mina_elevador`.

**O pedido:** o "Prompt Q". A auditoria e o plano estão em `docs/BLOCO99_PLANO.md`, com as fotos em
`docs/arte/bloco99/auditoria/`.

**As decisões do Marco:**
1. A restauração do elevador corre **em paralelo** com a escavadeira.
2. A espiral fica **sempre disponível** como rota lenta.
3. As escadas de mão: "faça o que achar que fique melhor".
4. O rendimento dentro da mina é **igual ao de hoje**.
5. Cargas de 100, ponto de 240, espera de 60 s e desgaste por minério: "pode ser".
6. A arte: pode gastar até ~440 gerações.

**Skills usadas:**
- `godot-gdscript`;
- `godot-gdscript-headless-testing`;
- `ai-behavior-trees-utility-ai` (a fila, quem entra e quem sai da mina);
- `survival-crafting` (o ritmo do minério e o desgaste);
- `save-systems` (a etapa, a cabine e o save antigo);
- `deep-iron-arte` (a torre por etapas, a cabine e o vagonete).

## A) Elevador e escadas

### O elevador do S2 (`deep_shaft.gd`)
- **Começa em ruína e é restaurado por 3 etapas**, como a ruína do coletor (Bloco 81). Cada etapa o jogador pede (paga),
  e o engenheiro faz levando o material (Bloco 96):

  | Etapa | Custo | Engenheiro | Pede |
  |---|---|---|---|
  | 1. Limpar o poço | 40 madeira | 30 s | — |
  | 2. Guincho e cabos | 120 cr + 80 ferro (barras a partir da fornalha) | 45 s | vila no estágio 2 |
  | 3. A cabine | 200 cr + 60 ferro + 40 madeira + 10 pregos | 50 s | vila no estágio 2 |

- **Em paralelo com a escavadeira:** dá pra restaurar antes dela acabar. O S2 continua abrindo com a escavadeira.
  - Restaurado antes: a cabine começa a andar quando a escavadeira acaba.
  - Escavadeira antes: a descida vai pela espiral até o elevador ficar pronto.
- **Janela nova** "ELEVADOR DA MINA" (`elevador_panel.gd`, clique na torre): mostra as etapas com custo e tempo, o
  andamento da obra e o estado da cabine (onde está, a fila, quantas viagens o cabo ainda aguenta e o conserto).

### A cabine (`cabine.gd`, a mesma no elevador e nas plataformas S3, S4 e S5)
- Quem chega na gaiola **entra na fila e espera de pé**, do lado onde chegou. Se mudar de ideia, sai da fila; quem espera
  mais de 120 s desiste e procura outro caminho.
- Parada num lado, a cabine **embarca até 4** (`@export`) e **anda pelo poço**: 7 s de ponta a ponta no elevador, 5 s nas
  plataformas.
- Chegou: **todo mundo desembarca** no andar de destino e segue o caminho.
- Sem ninguém esperando, fica parada onde está.
- **A vista iso desenha a cabine andando pelo poço**, vazia ou com mineiros dentro (`iso_view._sync_cabines`, todo quadro).
  A gaiola de baixo fica como a porta da chegada.
- **O cabo gasta:** depois de 60 viagens (`@export`) ele arrebenta, sempre na chegada (ninguém fica preso lá dentro).
  - A ligação some, e quem estava na fila vai pela espiral.
  - **O conserto é pedido sozinho** assim que o armazém tem o material (40 cr + 20 ferro + 10 madeira no elevador; 60 cr
    + 25 ferro + 10 madeira nas plataformas). Vira obra de engenheiro com material: 30 a 35 s.
  - Faltou material: tenta de novo a cada 5 s, e a janela diz o que falta.

### A escada em espiral (`espiral.gd`)
- Antes era só desenho. Agora é **um caminho de verdade e lento**, uma ligação por andar:
  - superfície → S2, a partir da casinha "boca_espiral" (744, 336);
  - depois S2 → S3 → S4 → S5, ao lado de cada gaiola de chegada.
- **Sempre aberta** junto com o andar de baixo, com custo alto: o caminho prefere o elevador e só vem por aqui quando a
  cabine está arruinada, quebrada ou ainda não foi restaurada. **Ninguém fica preso embaixo sem comida.**
- Quem entra na casinha some e aparece no patamar do outro andar depois de **20 s por andar** (`@export`).
- Os patamares se prendem sozinhos à malha de navegação. Isso conserta um problema achado durante o trabalho: na montagem
  a malha ainda não tinha chegado e o "ponto mais perto" saía em (0,0).

### O que saiu do mapa
- **As 2 escadas de mão e o andaime encostados no paredão da montanha** (`environment.gd` MAP_DECOR_V3) e **a escada de mão
  do S1** (`S1_mina.tres`). Pareciam caminho e não eram.
- **Ficam:**
  - as rampas dos degraus da montanha: funcionam, levam às galerias;
  - o andaime do S1, ao lado da torre do elevador (combina com a obra);
  - a escada de mão sorteada no chão do S4 (é entulho do andar, não parece caminho).

## B) Mineradores dentro da mina e o vagonete

1. **A boca principal tem a galeria de dentro** (`estacao_vagonete.gd` `tem_interior`, grupo "bocas_mina").
2. **Quando o mineiro entra:**
   - quando ele é da **área de mina** em volta da boca, a área está ligada, o trilho está inteiro, o ponto tem espaço e a
     área tem jazida com minério;
   - ele entra pela boca e some do mundo (protegido das criaturas e da onda solar).
3. **Na boca aparece:**
   - **"Mina — dentro: N/5"** no rótulo;
   - a **lanterna acesa** e o **lampião do poste com as picaretas** (arte nova);
   - o **som da picareta**.
4. **O rendimento lá dentro** (`taxa_dentro`, @export):
   - **21 minérios por mineiro por hora de jogo**, vezes o humor e a picareta (zanga, explosivos, picareta de aço), como lá
     fora;
   - **sai da jazida mais valiosa da área**: a jazida acaba e se recompõe como sempre;
   - **o acidente e os achados são sorteados pelo minério extraído**, com a mesma função de lá fora: o risco por minério não
     muda.
5. **Quando sai:** nas **refeições**, no **fim do expediente** e nas **emergências da agenda** (ferido, onda solar, invasão,
   greve), pela boca, e volta depois.
6. **Sem trilho, vagonete quebrado, ponto cheio ou armazém cheio:** ele sai e minera na mão, como antes. Nada trava.
7. **O vagonete com cargas grandes** (valem pra todos os pontos, inclusive a ferrovia do S2 ao S5):

   | | Antes | Agora |
   |---|---|---|
   | Por viagem | 25 | **100** |
   | Guarda no ponto | 60 | **240** |
   | Espera pra juntar carga | 8 s | **60 s** |

   - Com 60 ou mais no carrinho, aparece **o carrinho com o monte grande de minério** (arte nova).
8. **O desgaste é por minério levado:** 1 "viagem" de desgaste = 25 minérios, então o trilho continua quebrando a cada 625
   minérios, como antes. O rótulo mostra "trilho N%".
9. **Ferrovia S2–S5:** lá já se entregava no ponto da ferrovia (sempre mais perto que o armazém), e os mineiros só sobem pras
   refeições e pro fim do expediente. Ganhou as cargas grandes e o desgaste por minério.

## C) A produção antes e depois

`tests/bench_minerio.gd`: 5 mineradores, 4 h de jogo, partida nova.

| Cenário | Antes (minerado/h) | Depois (minerado/h) |
|---|---|---|
| Galerias da montanha, **com** vagonete | 106 | **103** (média de 3: 100, 107, 101) — os 5 lá dentro |
| Galerias da montanha, sem vagonete | 105 | **108** (média de 3: 105, 106, 112) |
| Pedreira, com vagonete | 181 | 190 |
| Pedreira, sem vagonete | 184 | 174 |

**A renda ficou parecida.**
- Lá dentro, cada um rende ~23/h (21 × 1,1 do humor).
- A variação entre as medições é o acidente: quando um mineiro se fere, ele sai e vai pra enfermaria.

**O que muda é o ritmo de entrada no armazém:** o minério chega em levas de 100. Por isso, numa janela de 4 h, sempre tem
uma leva no ponto ou no carrinho.

**Telemetria:** o CSV ganhou `minerio_entrou_dia`, `minerio_vagonete_dia` e `mineiros_dentro`.
`tools/resumo_telemetria.py` mostra a média por dia e quanto veio de vagonete.

**Nenhum número de balanceamento foi mexido além do aprovado.**

## Arte (PixelLab)

`prototipos/camera/arte_iso/mina99/mina99.py`, com piloto antes do lote (a etapa 1 da torre). Custo: **205 gerações**
(estimei ~440; saldo 6.547 → **6.342**).

- **A torre do elevador por etapas:** ruína → `obra_1` (o poço limpo, madeiramento novo, sem guincho nem cabine) →
  `obra_2` (a roda e o guincho com os cabos, sem cabine) → pronto. Mesma âncora e quadro (210×320).
- **A cabine que anda:** vazia (com a lanterna) e cheia (com 3 mineiros de capacete), 58×88.
- **O vagonete com carga grande:** SE e SO, 40×41.
- **O lampião da boca:** um poste com lampião aceso, duas picaretas e um saco de minério, 40×64.
- Conferência: `docs/arte/bloco99/arte_nova.png` e as fotos em `docs/arte/bloco99/depois/`.

## Save

Documentado no cabeçalho do `save_manager.gd`.
- **Elevador:** `etapa`, `pago`, `progresso`, `obra` e `cabine` {pos, viagens, total, quebrada, consertando, conserto_left}.
- **Plataformas:** `cabine`.
- **Vagonete:** `rail_left` passou a ser fração.

**Save antigo:**
- o elevador que **já estava aberto vem restaurado e inteiro**: ninguém perde o acesso;
- fechado, começa em ruína;
- a cabine começa nova, em cima;
- o trilho do save antigo (número inteiro) carrega normal.

A espiral e quem está dentro da mina não entram no save: o mineiro volta pela boca.

## Testes

- **`b99_mina_elevador`** (novo, **0 falhas**). Confere:
  - as 3 etapas antes da escavadeira, e o "só anda com o S2 aberto";
  - o caminho preferindo o elevador;
  - a viagem completa (fila → embarque → a cabine descendo → desembarque no S2);
  - o cabo arrebentando: a ligação some, o conserto é pedido com material, e quem estava embaixo sobe pela espiral;
  - o conserto;
  - as cargas e o desgaste;
  - 2 mineiros entrando, o "dentro: 2/5" e a lanterna;
  - o minério saindo da jazida;
  - a saída no almoço e a volta depois;
  - com o trilho quebrado, a saída e a mineração na mão;
  - o save e o save antigo;
  - nada de escadas de mão na superfície.
- **Testes antigos ajustados:**
  - `b68_niveis`: a gaiola agora é a fila da cabine;
  - `b74_superficie`: o carrinho espera até 60 s pra juntar carga, então o teste começa com a espera cumprida;
  - `p29_natureza`: o desenho do elevador segue a restauração, não o "aberto".
- **Bateria completa**, um por vez, em primeiro plano, com a pasta `fake_appdata`:
  - passaram os 83 testes de bloco (b25 → b99, b51 incluído) e `hud_frostpunk`, `manut_backups`, `p17`–`p20`, `p28_*`,
    `p29_*` e `p2_pendencias`;
  - passaram os GUT `test_iso` (6), `test_iso_arte` (3, que conferem as caixas da arte nova) e `test_iso_pele` (3).
- **Intermitentes** (passaram ao repetir):
  - `b25_funcoes`: o ipezinho do teste se machucou num acidente aleatório;
  - `b77_areas`: a medição de madeira de 30 s oscila.
