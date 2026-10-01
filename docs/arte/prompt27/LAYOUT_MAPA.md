# Prompt 27, passo 1: proposta de layout do mapa (CHECKPOINT do Marco)

Data: 2026-09-30. Esboço: `esboco_layout.png` (planta de cima, em coordenadas do chão do jogo).
Base: a visão do Marco (`docs/arte/MAPA_VISAO.md`) + o que o jogo já usa (`main.tscn`,
`environment.gd`, `defense.gd`).

## Hoje no jogo

| Área | Onde | Observação |
|---|---|---|
| Colônia | `map_rect` (-720,-440)–(720,440) | a vila fica **dentro da caverna da mina** |
| Clareira | ao norte, ligada por um **túnel** (x = 0) | árvores, tocas, horta |
| Nível 2 e abismo | embaixo, pelos elevadores | não mudam |
| Portões | **2**: túnel e poço | o invasor entra pelos dois |

## Proposta

1. **Floresta (começo do mapa):** a clareira atual, maior, com árvores esparsas e boa
   visibilidade. Tem 2 tocas de coelho e a toca do javali, a horta de cogumelos, a **máquina
   de cortar árvores quebrada** (que vira o Coletor de madeira) e o lugar onde o pesquisador
   acha o **robô gigante**. Uma cerca de estacas marca a borda até o muro ser construído.
2. **Portão (a única entrada):** fica onde hoje é o túnel. Começa quebrado e sobe pros níveis
   1, 2 e 3. Os invasores vêm da floresta por aqui, e à noite o robô fica parado nele.
3. **Pedreira = a área da colônia, a céu aberto e em terraços:**
   - **terraço de cima (+2 degraus):** entrada, Centro da Vila, casas (dentro do raio do
     Centro), taverna, enfermaria, parque, cozinha;
   - **terraço do meio (+1):** oficina (forja), fundição, arsenal, armazém, laboratório,
     vestiário, campo de treino, guindaste da pedreira;
   - **fundo da pedreira (0):** boca da mina e as galerias lacradas no paredão, jazidas,
     **plataforma de perfuração (escavadeira) no canto oeste**, **elevador pro nível 2** no
     leste;
   - escadas de pedra e rampas ligam os terraços. As rampas são o caminho de carroça e
     vagonete;
   - **trilho com vagonete** da boca da mina até o armazém.
4. **Nível 2 e abismo:** iguais a hoje, embaixo, pelos elevadores.

## O que muda no código (Prompts 28–29)

- **1 portão em vez de 2:** sai o do poço (`BarricadaPoco`) e o túnel vira o portão. Mexe no
  `defense.gd` (rota dos invasores, brecha).
- **Relevo:** terraços em mapa de altura (`environment.gd`); navegação com escada e rampa.
- **Posições:** escavadeira vai pro oeste, elevador pro leste, prédios por terraço. Saves
  antigos migram pela regra do Prompt 29: o que cair em lugar inválido vai pro ponto válido
  mais próximo.
- **Prédios novos no menu:** fundição, muro/portão com níveis. O guindaste é decoração.
- **A vila sai de dentro da caverna pra pedreira a céu aberto.** Isso muda a luz: tem dia e
  noite de verdade, e não fica escuro o tempo todo. Hoje a colônia usa o escuro da caverna
  com tochas.

## Pra aprovar

- [ ] layout geral (floresta → portão → pedreira em terraços → mina → elevadores);
- [ ] 1 portão só (sai o do poço);
- [ ] escavadeira no oeste, elevador no leste;
- [ ] a vila a céu aberto (luz de dia e noite em vez do escuro da caverna).

## Decisão do Marco (2026-09-30)

- **Layout aprovado** como no esboço.
- **Os 2 portões ficam:** o da floresta (a entrada principal, onde o robô fica à noite) e o do
  **poço**, junto ao elevador (invasores vindos de baixo). O `defense.gd` continua com 2 rotas.
- **Céu aberto:** a vila sai da caverna e vai pra pedreira com dia e noite de verdade. A mina e
  os níveis de baixo continuam escuros.

## Passo 2: mapa montado com a arte nova (pra o Marco ver antes da integração)

Imagens nesta pasta:

- `mapa_montado_quarto.png`: o mapa inteiro a 25%;
- `mapa_montado_meio.png`: a 50%;
- `mapa_montado.png`: tamanho real, 4816×2736;
- zooms `zoom_vila_terracos.png`, `zoom_floresta.png`, `zoom_fundo_pedreira.png`.

Gerado por `arte_iso/mapa/monta.py`, a partir do layout aprovado.

| Decisão na montagem | Por quê |
|---|---|
| Posições do esboço **× 1,5** (não × 2,1) | com × 2,1 o mapa ficava ralo; os prédios continuam no tamanho real |
| Alturas: floresta e terraço de cima = **3**, oficinas (oeste) = **2**, fundo da pedreira = **0** | a câmera só vê as faces viradas pra ela: o paredão de 3 degraus entre o terraço de cima e o fundo é onde as **bocas de mina** aparecem, cavadas na rocha |
| Terraço de cima | Centro da Vila (praça de laje), 6 casas, taverna, enfermaria, parque, cozinha, laboratório, vestiário |
| Terraço das oficinas | oficina, fundição, arsenal, armazém, campo de treino, guindaste |
| Fundo da pedreira | plataforma de perfuração (oeste), elevador + portão do poço (leste), jazidas, trilho com vagonete da mina ao armazém |
| Floresta | ~70 árvores das 3 espécies, ~90 tufos de vegetação, tocas (coelho e javali), horta com espantalho, máquina de cortar quebrada, robô gigante caído |
| Ligações | escadas de pedra entre os terraços, escada de 3 lances do terraço de cima ao fundo, rampa das oficinas pro fundo |
| Borda floresta/pedreira | paliçada com trechos danificados e o **portão quebrado** no meio |

**Falta no passo 3** (com o motor isométrico no jogo, Prompt 28): testar navegação, clique,
construção nas áreas válidas e a rota dos invasores neste mapa. A imagem é a montagem visual;
o mapa jogável sai na integração.

## Passo 2b: fundo de céu e montanhas (pedido do Marco, 2026-10-01)

O fundo preto virou céu + montanhas, com **5 horas**: manhã, meio-dia, fim de tarde, noite e
chuva. Gerado por `arte_iso/mapa/cenario.py` em cima de `mapa_transparente.png` (`monta.py`).

| Camada (de trás pra frente) | Origem | Muda com a hora |
|---|---|---|
| Céu em degradê, sol (halo em degraus) / lua, estrelas | código | cor do topo e do horizonte, posição do astro |
| Nuvens soltas (recortadas uma a uma da camada de nuvens) | IA | tingidas; 7 no céu limpo, 22 na chuva |
| Montanhas nevadas ao longe | IA | puxadas pra cor do horizonte (névoa) |
| Serra com floresta, atrás da floresta do mapa e nos lados | IA | escurecida pela luz do ambiente |
| Vale de mata fechada embaixo da serra | código | luz do ambiente |
| O mapa + a **moldura de morros** (ver abaixo) | `monta.py` | luz do ambiente; a moldura some na cor da serra com a distância |
| Névoa no pé do corte do terreno; chuva | código | cor do horizonte |

Imagens nesta pasta: `cenario_5_horas.png` (as 5 lado a lado), `cenario_<hora>_quarto.png`
(25%), `cenario_tarde.png` (tamanho real) e `cenario_ciclo.gif` (o ciclo passando).

No jogo, cada camada vira um `Parallax2D` (céu fixo, montanhas devagar, serra um pouco mais
rápida), e a cor por hora sai do `DayNight` (Prompt 28/29).

### Mapa e serra emendados (pedido do Marco: "a montanha integrando ao mapa, natural")

Antes, o mapa acabava numa borda reta e a serra era um quadro atrás dele. Agora o `monta.py`
põe uma **moldura de relevo isométrico** em volta da área jogável, com os mesmos blocos e
árvores do jogo:

- atrás da floresta e do paredão, o chão continua e **sobe em morros com mata fechada**
  (relevo por ruído suave, até 26 tiles pra fora);
- perto da borda o chão continua plano, só com morrinhos soltos. A clareira entra na mata em
  recortes irregulares e não aparece mais a linha reta do limite do mapa;
- encosta de 2+ degraus vira barranco de terra;
- perto da frente a moldura baixa até a altura da borda, pra o corte do relevo continuar igual;
- o topo da moldura é aparado na horizontal, na altura da serra pintada;
- `mapa_nevoa.png` guarda a distância de cada pixel até a área jogável. O `cenario.py` puxa a
  moldura pra cor do pé da serra (que muda com a hora), então o morro de blocos vira a serra
  pintada sem emenda. Embaixo da serra, nos lados, um vale em degradê até a névoa.

Imagens: `zoom_floresta_morro.png` (tamanho real, a floresta do jogo entrando nos morros);
`mapa_montado*.png` também foram refeitos com a moldura.

**No jogo (Prompt 28/29):** a moldura é **só decoração**: não é clicável, não tem navegação e
ninguém constrói nela. A névoa por distância vira um shader simples (ou uma camada por faixa).

**Custo:** 75 gerações (3 camadas: montanhas ao longe 512×160, serra 512×224, nuvens 512×128).
A moldura não gastou geração (reaproveita blocos e árvores).

**Desvios:**

1. As camadas repetem na horizontal alternando normal e espelhado, pra a emenda sempre casar.
   Em tamanho real dá pra ver o eixo do espelho na serra (um "V" simétrico). No jogo, com
   parallax e a câmera mais perto, aparece menos. Se incomodar: uma serra mais larga (~1 geração
   a 1024 px) resolve.
2. Na moldura, as árvores são as mesmas da floresta do jogo, repetidas. Com a névoa,
   a repetição não aparece; de perto, no canto do mapa, dá pra notar.
3. A serra é uma pintura plana em 2,5D (relevo com luz e sombra), não um terreno isométrico de
   verdade. É o mesmo truque dos jogos isométricos com fundo pintado.
