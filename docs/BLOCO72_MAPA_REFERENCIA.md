# Bloco 72 — Mapa do jogo × imagem de referência (Passo 0: auditoria)

Data: 2026-10-02. Branch `isometrico`. Referência: `docs/arte/referencia_mapa_mundo.jpg`.
Fotos: `docs/arte/bloco72/antes/` (geradas por `project.godot/tests/capturas_bloco72.gd`, com os andares
abertos e o leste desbravado, como a referência mostra). Prancha: `docs/arte/bloco72/comparativo_antes.jpg`.

**Nada foi mudado no jogo neste passo.** Abaixo, o que já bate, o que falta e quanto custa fechar cada
lacuna. A ordem proposta está no fim, à espera do seu ok.

## A diferença que mais pesa

A referência é **uma coluna compacta**: a superfície em cima e os 5 subsolos colados, como fatias da
mesma rocha, com uma **escada em espiral contínua** do lado direito ligando tudo e o lago no fundo.

No jogo (foto `02_pilha_inteira`), a superfície é um retângulo enorme e os andares são **lajes pequenas,
soltas no vazio**, longe umas das outras e deslocadas pra direita. Cada andar é bom de perto, mas o
conjunto não lê como "um corte da mina". A tela **Corte da mina (F2)** (`11_corte_f2`) é a vista que mais
lembra a referência: faixas empilhadas, elevadores, escavadeira. Só que as faixas do **S4 e do S5 estão
vazias** (cor lisa, sem arte), não há espiral e o S5 fica cortado embaixo da janela.

Juntar as lajes numa coluna na vista de jogo não é viável sem refazer o mapa. Os andares são grandes
(o nível 2 tem 1120 × 620 de chão), e empilhados de perto um esconderia o outro. O caminho
realista tem duas frentes:
1. Fazer do **corte F2 o "mapa do mundo"** da referência.
2. Na vista de jogo, **preencher o vazio entre as lajes** com rocha e um eixo vertical, pra elas não
   parecerem soltas.

## Quadro comparativo

Nota de 0 a 5 em **estrutura** (andares, ligação, proporção) / **densidade** (props por área) /
**atmosfera** (luz, névoa, brilho).

| Região | Referência | Jogo (foto) | Nota E/D/A | Já bate | Falta / destoa |
|---|---|---|---|---|---|
| **Superfície / vila** | floresta densa, vila de mineração com guindastes e torre de poço, encosta com casas | `01`, `03`, `12` | 3 / 3 / 3 | vila com casas, oficina, torre do elevador, guindaste da pedreira, paliçada, floresta ao norte, tochas, noite e chuva | a pedreira a leste é um chão vazio enorme (cascalho e manchas); poucas árvores dentro da área de jogo; nenhum trilho ou vagonete na superfície se o jogador não construir |
| **Encosta e entrada da mina** | penhasco com bocas de túnel em moldura de madeira, trilhos entrando, guindaste | `04` | 2 / 2 / 2 | torre do poço com gaiola, portão do poço, jazidas | a "boca da mina" é a torre no meio da pedreira; não há túnel no paredão, nem trilhos ou passarelas descendo |
| **Vila antiga (leste)** | — (a referência tem a vila na encosta) | `05` | 3 / 1 / 3 | igreja, torre do relógio, 3 casas enxaimel | muito chão vazio entre os prédios; faltam cercas, caminhos, poço, lixo, vegetação |
| **S1 — mina e vila** | galeria subterrânea com escoras, lampiões, trabalhadores | (é a pedreira a céu aberto) | 2 / 2 / 2 | no corte F2, a faixa do S1 é galeria com escoras | no jogo o S1 é a superfície: diferença de desenho do jogo, não de arte (a Rota A pôs a vila na pedreira) |
| **S2 — ácido** | chão de musgo verde, cristais roxos, estruturas de madeira, túneis | `06` | 3 / 3 / 4 | névoa verde, poças de ácido com bolhas e luz, cristais verde/roxo/ciano, rocha corroída, pedras na borda, ventilador | sem escoras, lampiões, vagonetes, placas ou bocas de túnel nas paredes; o piso repete muito; poucos trabalhadores (depende do jogo) |
| **S3 — lava** | rios e cascatas de lava, cristais vermelhos, máquinas, escoras | `07` | 3 / 2 / 3 | poços de lava com brilho e brasas, cristais rubros, solarita, fenda de calor | sem **rio/canal de lava** nem lava escorrendo da parede; quase nenhuma estrutura; muito chão liso entre os poços |
| **S4 — cachoeira e lava** | lava e água no mesmo andar, vapor | `08` | 3 / 2 / 3 | cachoeira animada, poças d'água, poços de lava, passarela, ponte, cristais | a cachoeira é pequena e não forma riacho; água e lava não se encontram (sem vapor); o piso tem um risco repetido que forma faixas diagonais |
| **S5 — lago azul** | lago grande no fundo da coluna, gemas azuis, casinhas | `09` | 3 / 2 / 4 | lago com borda de seixos, luz azul, brilho na água, píer, gemas, 2 casinhas | o lago é pequeno pro andar e tem borda em degraus; só 2 casinhas (a referência sugere um vilarejo); paredes lisas |
| **Rampa em espiral** | eixo central contínuo do topo ao fundo | `10` | 1 / – / – | peças da rampa (reta, curva, patamar) perto de cada chegada | as peças ficam soltas; não há espiral contínua nem eixo central (nem na vista nem no corte F2) |
| **Atmosfera geral** | cada andar com sua cor: verde, laranja, misto, azul | `02` | – / – / 4 | na pilha a leitura de cor já bate: S2 verde, S3 laranja, S4 cinza-azul com lava, S5 azul | dá pra reforçar (névoa mais densa no S2, brilho de lava no S3/S4, reflexo no S5) |
| **Corte da mina (F2)** | é o "mapa do mundo" da referência | `11` | 4 / 3 / 3 | faixas S0–S3 com arte rica, escavadeira, gaiolas, ipezinhos, perigos | faixas do **S4 e S5 sem arte**; sem espiral; o S5 fica cortado embaixo |
| **Kit de peças** | casas, árvores, pedras, máquinas, ferramentas, cristais, escadas, trilhos, placas, ventilador, lava, pisos | — | — | quase tudo existe: casas, igreja, árvores, rochas, guindaste, escavadeira, furadeira, vagonetes, escadas, trilhos, placas, ventilador, cristais de 4 cores, poços de lava, pisos | **~60 objetos do Prompt 14 prontos e nunca registrados** como props (andaime, barris, tambor de óleo, escada de mão, carcaça de máquina, furadeira velha, lampião de poste, placas de gás e raio, sucata, trilho quebrado, vagonetes vazio e velho...) |
| **Camadas / composição A→D** | 5 camadas | — | 4 / – / – | feito no Bloco 69 (`docs/arte/CAMADAS.md`) | — |

**Artefato visível só no zoom muito afastado:** manchas ovais cinzas flutuando no vazio, de efeito de
clima ou sombra de nuvem fora do mapa. No zoom normal a câmera não chega lá.

## Medidas (antes de qualquer mudança)

Janela 1920×1080, vsync desligado, i3-8100 + RX 580. Cada vista assenta 2 s e é medida por 2 s
(`docs/arte/bloco72/antes/medidas.txt`).

| Vista | ms/quadro | FPS | nós | draw calls | luzes visíveis | partículas ativas |
|---|---|---|---|---|---|---|
| superfície inteira | 14,4 | 69 | 6.566 | 473 | 51 | 29 |
| pilha inteira (zoom 0,1) | 19,3 | 52 | 6.560 | 820 | 69 | 29 |
| vila (S1) | 10,2 | 98 | 6.542 | 95 | 35 | 29 |
| encosta / boca da mina | 9,1 | 110 | 6.542 | 62 | 37 | 29 |
| leste / vila antiga | 7,8 | 128 | 6.542 | 34 | 31 | 29 |
| S2 ácido | 10,3 | 97 | 6.542 | 236 | 45 | 30 |
| S3 lava | 9,6 | 104 | 6.542 | 181 | 39 | 30 |
| S4 cachoeira | 8,0 | 126 | 6.542 | 71 | 40 | 30 |
| S5 lago | 7,6 | 131 | 6.542 | 52 | 32 | 30 |
| corte F2 | 9,0 | 111 | 6.542 | 394 | 33 | 31 |
| **vila cheia** (40, noite, chuva, invasão) | **20,9** | **48** | 8.416 | 195 | 67 | 35 |

- Os andares estão folgados (97–131 FPS). O gargalo é a **vila cheia**, que fica em 48 FPS (meta: 60).
- O número de nós é o mesmo em toda vista: tudo existe sempre, inclusive o conteúdo dos andares
  fechados e do que está fora da tela.
- Cerca de 30 sistemas de partícula ficam ativos o tempo todo, mesmo fora da tela.

## Lacunas por custo

**Barato (dados e decoração, 0 geração):**
- Registrar os ~60 objetos prontos do Prompt 14 e espalhar por dados. Andares: escoras, lampiões,
  barris, vagonetes, placas, sucata, andaimes, escada de mão. Superfície: trilho e vagonete na
  encosta, sucata e pilhas no leste.
- Adensar a vila antiga do leste: cercas, poço, caminho, árvores.
- Mais cristais e pedras nos andares S3–S5.
- Ajustar a atmosfera por andar: névoa e brilho mais fortes, mais reflexo no lago.

**Código (médio):**
- **Desempenho:** pausar partículas fora da tela e congelar o conteúdo dos andares fechados. Pode
  compensar o que a decoração nova custar e aproximar a vila cheia de 60 FPS.
- **Eixo vertical na vista:** uma coluna de rocha e a rampa em espiral desenhadas no vazio entre as
  lajes (só cenário, na tela iso), pra a pilha ler como uma mina contínua.
- **Corte F2 como "mapa do mundo":** a espiral do lado, rolagem até o S5 e as faixas novas.

**Arte nova (PixelLab), só o que faz diferença:**
- Faixas do **S4** (cachoeira e lava) e do **S5** (lago azul) pro corte F2. É a maior lacuna visual da
  vista que mais lembra a referência.
- **Rio/canal de lava** (peças de decalque) pro S3 e o S4, e lava escorrendo da parede.
- Opcional: parede de rocha em estratos pro vazio entre as lajes.

O piloto sugerido no prompt ("1 tileset de rocha com lava + 2–3 cristais") **já existe**: os pisos do
abismo (Prompt 7) e os cristais de 4 cores × 2 tamanhos (Prompt 8). Proponho trocar o piloto por
**faixa do S4 + faixa do S5 do corte + 1 peça de rio de lava** (~60–75 gerações), pra você aprovar antes
de qualquer lote.

## Ordem proposta (um commit por etapa)

1. **Densidade por dados** com os objetos prontos e a vila antiga adensada (0 geração).
2. **Atmosfera por andar** afinada (código pequeno).
3. **Desempenho:** partículas fora da tela e andares fechados congelados. Meta: a vila cheia acima de
   48 FPS, perto de 60.
4. **Eixo vertical:** coluna de rocha e rampa em espiral entre as lajes; espiral no corte F2.
5. **Piloto de arte** (faixas S4/S5 + rio de lava, ~60–75 gerações). **Para pra sua aprovação.**
6. Depois da aprovação: o lote de arte e o corte F2 completo (cores por andar, rampa, escavadeira,
   criaturas).

Fora de escopo, como o prompt pede: gameplay, balanceamento, criaturas, Bloco 65 e a Rota A.

---

# Etapas 1 a 5 (feitas em 2026-10-03)

Prancha antes × depois: `docs/arte/bloco72/comparativo_depois.jpg`. Fotos de depois:
`docs/arte/bloco72/depois/` (as mesmas 12 vistas + a da espiral, com `medidas.txt`).

| Etapa | O quê | Commit |
|---|---|---|
| 1. Densidade | 51 objetos prontos do Prompt 14 registrados; `decoracao_sorteada` por nível (S2–S5 com 24–28 peças a mais cada: escoras, barris, placas, sucata, vagonetes, máquinas velhas, casinhas e varais no S5); sucata em volta da boca da mina e da escavadeira; a pedreira do leste com 130 enfeites (era 70); enfeites em volta da vila antiga | `e89b6e67` |
| 2. Atmosfera | S2 mais verde, S3 laranja (laje e névoa), S5 com névoa mais densa; poço de lava ilumina o chão em volta; lago mais brilhante; vapor onde há água e lava (S4) | `ac8178be` |
| 3. Desempenho | fixas em 6 grupos (uma por quadro) em vez de varrer ~800 entidades todo quadro; as fixas de cada andar e do leste somem quando fora da tela; ordem de quem anda a cada 3 quadros com 30+; rajada de fixas refaz a ordem uma vez só (acabaram os 4 trancos do carregamento); bichos procuram ipezinho 5x/s | `172079ab` |
| 4. **Mina contínua** (o pedido do Marco: "natural, não no vazio, tudo conectado") | o mapa inteiro é um **bloco de terra** (faces da frente com rocha em estratos); as **paredes de cada andar sobem até o de cima** — o vão entre as lajes virou um poço escavado; **escada em espiral** num poço próprio na terra, da superfície até o lago, com patamar, corrimão e lampião em cada andar; a mesma espiral no corte F2 | `f3a19d64` |
| 5. Piloto de arte | faixas do S4 e do S5 pro corte F2 e uma peça de rio de lava (decalque no chão do S3 e do S4, por dados: `NivelMina.decalques`) — **esperando aprovação** | este commit |

## Medidas depois (mesmas vistas do Passo 0)

| Vista | antes | depois |
|---|---|---|
| vila cheia (40, noite, chuva, invasão) | 20,9 ms / 48 FPS, 8.416 nós | **20,2 ms / 50 FPS**, 9.519 nós |
| S2 / S3 / S4 / S5 | 97 / 104 / 126 / 131 FPS | 89 / 81 / 95 / 114 FPS |
| pilha inteira (zoom 0,1) | 52 FPS | 44 FPS |
| superfície inteira | 69 FPS | 61 FPS |

A vila cheia ficou melhor que antes do bloco, mesmo com ~1.100 nós a mais. Os andares custam um pouco
mais (as paredes do poço são imagens maiores e há mais decoração), mas seguem acima de 80 FPS. Benchmark
completo: `docs/bench/bench_2026-10-03_bloco72_{antes,depois}.txt` (a vila cheia ainda não chega a 60: o
grosso é a vista iso sincronizando 40 bonecos e a HUD; o próximo passe seria o `IsoBonecos.pose`).

## Piloto de arte (pra aprovar) — 29 gerações

`docs/arte/bloco72/piloto/prancha_piloto.jpg` e as fotos no jogo (`no_jogo_corte_f2.jpg`, `no_jogo_s3_rio.jpg`).

- **Faixa do S4** (cachoeira à esquerda, lava escorrendo e vapor à direita, cristais) e **faixa do S5**
  (lago azul, gemas nas paredes, 2 casinhas): `create_image_pixen` 512×128, como as faixas do Prompt 25
  (1 geração cada, 2 candidatas por faixa). Já estão no corte F2. A outra do S5 foi descartada (saiu um
  "texto" no lago).
- **Rio de lava**: `create_image_pro` com o poço de lava aprovado de referência; veio como placa de basalto
  com o rio, então só o leito laranja foi recortado. No chão do S3 ele ficou **pequeno** (parece um
  filete): no lote, a proposta é gerar peças maiores (~320 px) que liguem os poços, e lava escorrendo das
  paredes.

**Se aprovar**, o lote proposto (~150–200 gerações): rios de lava maiores (3–4 peças) pro S3 e S4, lava
escorrendo de parede, 2–3 bocas de túnel com moldura de madeira pras paredes dos andares (como na
referência) e um trecho de trilho com vagonete descendo a encosta pra boca da mina na superfície.

## O que ainda difere da referência (e por quê)

- A referência mostra **galerias com teto** em cada andar (a vista é um corte). No jogo, a câmera vê os
  andares de cima, então o "teto" de cada um é o chão do de cima — é o mesmo empilhamento, visto de
  outro ângulo.
- Na vista bem afastada aparecem manchas ovais (a neblina do clima) fora do mapa: só no zoom de vista
  geral, que o jogador não usa.

---

# Revisão (2026-10-03): a coluna debaixo da vila, no jogo

O Marco rejeitou a etapa 4 (lajes retas num bloco de terra, coluna na ponta leste) e pediu a estrutura
da referência no próprio mapa do jogo. Decisões dele: modelo = imagem B do PixelLab; a imagem vira o
mapa do mundo (F2, `515b5bfa`) E os andares são reconstruídos no jogo; andares mais compactos.

**Feito** (comparação: `docs/arte/bloco72/coluna/comparativo.jpg`; fotos e medidas na mesma pasta):
- `mapa/andares.py` reescrito: cada andar na escala 0,75, com a beira da frente na face sul do mapa,
  DEBAIXO DA VILA (entre a escavadeira e a torre do elevador); um embaixo do outro (degraus -32, -68,
  -104, -140); chão em forma de caverna (superelipse com ruído, que cresce em bolsões onde há conteúdo,
  mais a plataforma da gaiola); a rocha de trás sobe até o andar de cima (o nível 2, até a superfície),
  em degraus e estratos; a frente aberta (o corte). Gera também o poço do elevador (`poco.png`), a espiral
  e os polígonos da terra (faixa das faces + corpo da coluna afinando no fundo).
- Elevadores alinhados num poço único: as 4 gaiolas na vertical da torre da vila (cena e .tres);
  as peças soltas de rampa saíram (a espiral do poço as substitui).
- Conteúdo dos andares puxado pro centro (x0,82) pra a caverna não ser forçada até os cantos.
- `environment.gd`: vista <-> lógica pelo centro e escala do andar; navegação e decoração pelo
  contorno da caverna (rocha não anda). `iso_view.gd`: escala dos andares, névoa no formato da caverna,
  terra/poço/espiral do json.
- Os saves continuam valendo (a lógica dos andares não mudou de lugar).
- Teste `b72_coluna.gd`; b68–b71, b63, b67, p19, p20, p28_iso, p28_save, p29_mapa, b61, b62 passam.
- Vila cheia ~21 ms (46–51 FPS conforme a rodada), andares 95–118 FPS.

**Ainda diferente da referência** (próxima rodada, se o Marco aprovar o rumo):
1. Andares afastados demais (muita rocha escura entre eles): apertar de 36 pra ~24 degraus.
2. A faixa de galerias de madeira logo abaixo da superfície (o "nível 1" da imagem).
3. Paredes da coluna escuras e sem detalhe: lampiões nas paredes, lava escorrendo no S3/S4, a cachoeira
   descendo pela parede do S4, cristais nas paredes, raízes perto da superfície.
4. A coluna é estreita perto da superfície enorme (a superfície é a faixa longa do leste): dá pra alargar
   os andares de volta (escala 0,85) ou deixar a superfície mais escura longe da vila.

