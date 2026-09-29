# Rota A (isométrico): endurecimento antes da arte final

Data: 2026-09-29. Tudo **isolado** em `project.godot/prototipos/camera/`, com arte provisória
(caixas e bonecos desenhados em código). Nada foi integrado ao jogo e nenhuma arte foi
gerada. Os números vêm de testes automáticos que comparam o que é desenhado com a
"verdade" 3D.

## Veredito

**A Rota A está pronta pra receber arte de verdade,** desde que a arte siga o contrato da
seção 7. Os 5 riscos têm solução sistemática testada contra todos os prédios do jogo:

| Risco | Solução | Resultado medido |
|---|---|---|
| Prédio grande × boneco passando do lado | **Ordem por caixas, incremental** (sem fatiar) | **0 erros** em 21 mil sobreposições; 0,4 a 2,4 ms/quadro com 200 a 850 objetos |
| Clique com relevo | **Raio da câmera** | **100%** em todos os tipos de lugar |
| 4 × 8 direções | **4 de losango** (2 desenhos + espelho) | cobre 92,4% do movimento a menos de 30° |
| 71 ajustes + 17 cliques | mapeados (§4) | sobram só **2 manuais** (ferramenta na mão, por direção) + 1 ponto por luz/fumaça, que sai da arte |
| Picareta híbrida | funciona com **2 configurações** (de frente/de costas) | ver o GIF |

**O que ainda falta, mas não bloqueia a arte** (é trabalho de integração, §8): reordenar
só o pedaço afetado ao construir/demolir, prédio em "L" virar 2 caixas, e um verificador
automático de que o sprite cabe na caixa.

## Como abrir

No editor, F6 em cada cena de `prototipos/camera/`:

| Cena | O que é |
|---|---|
| `rota_a_estresse.tscn` | todos os prédios + relevo difícil + 14 ipezinhos |
| `direcoes_demo.tscn` | 4 × 8 direções e a picareta |
| `rota_a_iso.tscn` / `rota_b_relevo.tscn` | protótipo anterior, sem mudanças |

**Teclas na cena de estresse:**

| Tecla | O quê |
|---|---|
| 1 | ordenação ingênua |
| 2 | fatiada (**+/-** muda o tamanho do pedaço) |
| 3 | caixas, ordem completa |
| **4** | **caixas incremental (produção)** |

O painel mostra, ao vivo, quantos pares boneco×coisa se sobrepõem na tela e quantos
estão desenhados na ordem errada. O mouse mostra o que o raio da câmera acha embaixo dele.

**Números sem janela:** rode a cena de estresse com `-- bench` (ordenação, direções,
clique e custo) ou `-- bench_clique` (só o clique).

## A cena de estresse

- **Prédios:** todos os tipos do jogo, como caixas com pegada e altura:
  - os 5 estágios do Centro da Vila (de 120×66×58 a 180×100×152);
  - Escavadeira (160×120×190), Arsenal, Oficina, Coletor, Armazém e todos os outros;
  - elevador fino e alto (48×48×120);
  - barricada comprida nos dois sentidos (16×76 e 76×16).
- **Relevo:**
  - 3 platôs em sequência (alturas 36, 36, 54), com vales estreitos entre eles;
  - um 2º andar em cima do 1º platô (72);
  - uma casa e uma taverna em cima de platôs;
  - galeria rebaixada (−36) com escada;
  - abismo (−110) sem acesso;
  - 5 rampas.
- **14 ipezinhos** passeando por tudo, inclusive subindo nos platôs e descendo na galeria.

## 1. Prédio grande: fatiar ou ordenar por caixa

Testei o fatiamento automático pedido (regra: pedaços quadrados de até N px, cada um com a
sua chave, sem configurar nada por prédio) contra a alternativa: **ordenar as caixas
inteiras** pela verdade 3D (quem está inteiramente atrás de quem em x, em y ou em altura).
60 s simulados por modo, 14 ipezinhos.

| Ordenação | Pares errados | Quadros com erro visível | Peças desenhadas |
|---|---|---|---|
| Ingênua (1 ponto por prédio) | **2,17%** | **387 de 1200** (32%) | 58 |
| Fatiada, até 64 px | 0,33% | 111 de 1200 | 193 |
| Fatiada, até 40 px | 0,03% | 15 de 1200 | 386 |
| Fatiada, até 24 px | 0,02% | 15 de 1200 | 901 |
| Fatiada, até 12 px | 0,03% | 41 de 1200 | 3.278 |
| Caixas, ordem completa | **0%** | **0** | 58 |
| **Caixas, incremental (produção)** | **0%** | **0** | 58 |

**Na ingênua**, os que mais erram são justamente os grandes e os compridos:

| Prédio | Pares errados |
|---|---|
| Centro estágio 5 | 88 de 1227 |
| Centro estágio 4 | 70 de 2023 |
| Escavadeira | 36 de 2161 |
| Centro estágios 1 e 2 | 33 e 35 |
| Barricada em pé | 17 de 366 |
| Arsenal | 15 |
| Beiras de buraco | 36 de 400 |

**Com caixas, todos ficam em zero,** inclusive a Escavadeira, o Arsenal e os 5 estágios do
Centro.

**Por que não o fatiamento:**
- nunca chega a zero;
- multiplica as peças (6 a 56×);
- **obriga a arte de todo prédio a ser cortada em colunas**, o risco de arte que eu tinha
  apontado.

Na ordem por caixas, **cada prédio só declara a caixa dele** (pegada no chão + altura, a
mesma pegada que o jogo já usa pro posicionador e pra navegação), e o desenho é inteiro.
Não há configuração por prédio: é automático pra qualquer prédio novo.

**Custo (GDScript).** A ordem completa compara todos com todos e não serve pro jogo cheio.
A incremental ordena o cenário fixo **uma vez** e só encaixa quem anda:

| Tamanho | Ordem completa | Incremental por quadro | Reordenar fixo (ao construir/demolir) |
|---|---|---|---|
| 194 fixas + 20 andando | 10,8 ms | **0,41 ms** | 10,5 ms |
| 444 fixas + 40 andando | 45,3 ms | **1,12 ms** | 39,3 ms |
| 844 fixas + 60 andando | 106,7 ms | **2,42 ms** | 96,3 ms |

(A coluna "ms/quadro" do bench de ordenação inclui o próprio verificador de erros, que é o
que mais custa. Os números acima são só da ordenação.)

## 2. Clique com relevo

**Verdade** = o que está desenhado por cima em cada ponto da tela (a tela inteira amostrada
a cada 10 px, ~13 mil pontos). "Prioridade ao topo" é a regra do 1º protótipo; o "raio da
câmera" anda pelo raio de visão de cima pra baixo e pega a 1ª coisa sólida (`Iso.pick`).

| Onde o mouse está | Pontos | Prioridade ao topo | Raio da câmera |
|---|---|---|---|
| chão aberto e vales entre platôs | 4686 | 100% | **100%** |
| topo de platô (inclusive o 2º andar) | 1227 | 100% | **100%** |
| prédio (qualquer face) | 4343 | 100% | **100%** |
| fundo da galeria rebaixada | 326 | 100% | **100%** |
| fundo do abismo | 350 | 100% | **100%** |
| chão na beira de buraco | 1046 | **52%** | **100%** |
| face de penhasco / parede de buraco | 1050 | **0%** | **100%** |
| rampa/escada | 179 | **1%** | **100%** |

**"Prioridade ao topo" não serve:** erra toda face de penhasco, quase toda rampa e metade
da beira dos buracos. **O raio resolve tudo com uma regra só,** sem ordem de prioridade por
tipo. Ele diz também **se o clique caiu numa FACE** (parede). Aí o jogo decide: mandar
andar → vai pro pé da parede; construir → não pode.

**Condição que o teste revelou:** o relevo tem que ser um **mapa de altura** (uma altura por
ponto do chão: platôs, buracos, rampas; sem ponte ou túnel por cima de caminho). Assim a
navegação continua 2D como hoje, e o raio fica exato.

**Galerias e abismo do jogo real:** hoje o nível 2 e o abismo são áreas separadas no mapa
(ligadas por elevador), não buracos visíveis da superfície. Mantendo assim, **não existe
ambiguidade nenhuma** entre níveis. Se algum dia virar buraco aberto, o teste acima mostra
que o raio já trata.

**Erro de desenho que o teste achou:** as paredes de FORA das beiras dos buracos ficam
enterradas e não podem ser desenhadas. E a massa de chão da frente do buraco tem que ser
tão grossa quanto o buraco é fundo, senão o fundo do abismo "vaza" por cima do chão da
frente na projeção. Já corrigido: vira regra do tileset de buraco (§7).

## 3. Personagem: 4 ou 8 direções

**Medido:** as direções em que os 14 ipezinhos realmente andam na tela (117 mil amostras),
seguindo a navegação de verdade:

| Direções | Desenhos por animação | Erro médio | Movimento a mais de 30° do desenho |
|---|---|---|---|
| **4 "de losango"** (bordas do chão = diagonais da tela) | **2 + espelho** | 11,9° | **7,6%** |
| 4 "de tela" (cima/baixo/lados) | 2 + espelho | 21,9° | 17,7% |
| 8 | 5 + espelho | 7,5° | 0,1% |

**Recomendação: 4 de losango.**
- O caminho da navegação segue muito as bordas dos prédios, que no isométrico são as
  diagonais da tela.
- 92% do tempo o boneco está a menos de 30° do desenho.
- **É 2,5× menos arte que 8 direções:** 2 desenhos por animação contra 5, vezes 18 roupas,
  vezes cada animação (andar, minerar, cortar, carregar, lutar…).
- Com histerese de 15°, ele troca de desenho **menos** que o de 8 no mesmo caminho (9 trocas
  contra 16 no GIF), então fica mais estável.
- O custo visual são os 7,6%: andando reto pra cima/baixo na tela, ele aparece meio de lado.
  É o "jeitão" comum do isométrico de 4 direções.

**Com o PixelLab:** o `create_character` já devolve as 8 direções da pose parada de
qualquer jeito, então dá pra guardar as 8 poses paradas sem custo a mais e **animar só
as 4 diagonais**. É na animação que o custo multiplica.

**Saída se o "de lado" incomodar na arte real:** 6 direções (acrescentar N e S = 4
desenhos + espelho). Decide olhando a 1ª animação pronta.

Exemplo visual: `direcoes_4x8_e_picareta.gif` (esquerda 4, direita 8, mesmo caminho; a
linha verde é pra onde ele anda de verdade) e `direcoes_4x8_quadros.png`.

## 4. Os 71 ajustes de posição e as 17 áreas de clique

Levantei um por um (`offset = Vector2` em scripts e cenas; `contains_point` nos scripts):

| O que é | Quantos | No isométrico |
|---|---|---|
| **Áreas de clique** (`contains_point`) | 16 funções (17 arquivos citam) | **Resolve sozinho:** somem os 16 retângulos feitos à mão; o clique vem da caixa (`Iso.pick`) |
| **Âncora da arte** (sprite com a base no ponto: prédios, árvore, cova, fantasma do posicionador, entulho, criaturas) | 45 | **Regra de exportação da arte:** 1 número por arte (a base do losango no ponto), sai junto com a arte nova. Zero código |
| **Pegada de navegação** (`obstacle_offset/size`) | 16 | Já é chão, não muda de sentido. Muda de **valor** (hoje é uma faixa fina na base; vira a pegada inteira), e é **o mesmo retângulo da caixa**: um dado só por prédio |
| Placas dos portões (`sign_offset`) | 3 | **Resolve sozinho** (deslocamento no chão) |
| **Ferramenta na mão** (`_tool.offset`) | 2 | **Manual, por direção:** 2 conjuntos com 4 direções (5 com 8) |
| Não é desenho (câmera, formação, passeio) | 5 | nada |

**Além dos 71 `offset`,** as cenas têm peças presas nos prédios e bonecos:

| Peça | Quantas | No isométrico |
|---|---|---|
| Rótulos | 26 | **sozinho:** ficam em cima da caixa (altura) |
| Sombras | 24 | **sozinho:** um sistema de sombra gerado da pegada, no lugar de 24 sprites |
| Luzes | 22 | 1 ponto por luz, **sai da arte** (a janela/forja está no desenho) |
| Partículas | 10 | idem luzes |
| Colisões/áreas de vaga | ~33 | ficam na lógica (chão): **não mudam** |

**Sobra de trabalho manual de verdade:** a ferramenta na mão (2 conjuntos) e ~40 pontos de
luz/fumaça/peça que vêm junto com cada arte nova (anotar no momento de importar).

## 5. Picareta híbrida no isométrico

**Continua funcionando,** com uma regra só: **a ordem da picareta em relação ao corpo
depende de o boneco olhar pra câmera ou não.**

- **De frente** (SE/SO): a picareta nas costas fica **atrás** do corpo; aparece o cabo por
  cima do ombro, do lado de trás.
- **De costas** (NE/NO): ela fica **na frente** do corpo (são as costas que estão viradas
  pra câmera).
- **No golpe:** some das costas e é **parte do desenho da animação de minerar** (1 desenho
  por direção de losango = 2 + espelho). Minerar sempre vira pra jazida (uma das 4).

Com 4 direções são **2 configurações** (posição + frente/atrás), espelhadas pro outro lado.
Com 8 seriam 5, e de costas-reto (N) a picareta cobre boa parte do boneco. Ver o GIF.

## 6. O que foi construído (reutilizável)

| Arquivo | O que é |
|---|---|
| `iso_core.gd` | projeção e volta; `behind` (a verdade 3D); `topo_order`; `slice_rect` (o fatiamento, mantido pra comparação); `pick` (raio da câmera, com rampa) |
| `iso_incremental.gd` | a ordem de produção (fixas uma vez, quem anda encaixado) |
| `box_view.gd` | desenho de qualquer caixa/rampa, com faces enterradas escondidas |
| `estresse_mundo.gd` | o mundo de teste (mapa de altura + catálogo de prédios) |
| `rota_a_estresse.gd` | a cena com os 4 modos, o verificador e os benchmarks |
| `direcoes_demo.gd` | 4 × 8 direções + picareta |

## 7. Contrato de arte (pra gastar o crédito sem refazer)

1. **Ângulo 2:1 exato** (as bordas do chão a 26,57° na tela), em tudo: tiles, prédios,
   personagens.
2. **Todo prédio declara uma caixa** (largura × profundidade no chão + altura) e **o desenho
   tem que caber dentro dela.** Não fatiar a arte. Prédio em "L" = 2 caixas.
3. **Âncora:** a base do losango da pegada no ponto do nó (anotar 1 número por arte).
4. **Personagem:** animações nas **4 diagonais** (2 desenhos + espelho); poses paradas nas 8
   se vierem de graça.
5. **Picareta/ferramentas:** sprite separado + 2 conjuntos de posição (de frente/de costas).
6. **Relevo = mapa de altura:**
   - degraus de altura fixos;
   - faces de penhasco (as duas visíveis) e topo em tiles;
   - buraco: só as paredes de dentro, e a borda da frente tão grossa quanto o buraco é
     fundo.
7. **Luz, fumaça e peças presas:** 1 ponto anotado por arte, na importação.

## 8. O que ainda falta (integração, não arte)

- **Reordenar só o pedaço afetado** ao construir/demolir: hoje é o fixo inteiro (10 a
  100 ms, um tranco em mapa cheio). Encaixar a caixa nova igual a quem anda resolve.
- **Verificador automático** "o sprite cabe na caixa" (olhar a parte desenhada da imagem
  contra o hexágono da caixa), pra rodar a cada arte importada.
- **Prédio côncavo** (em "L") = várias caixas; rampas são caixas com topo inclinado (já
  tratadas).
- **Levar pro jogo:**
  - a camada de desenho separada da lógica;
  - as sombras geradas;
  - os rótulos em cima da caixa;
  - trocar os 16 `contains_point` por `Iso.pick`;
  - a direção do boneco pelo vetor de andar (com histerese).
