# Prompt 29, partes 3 a 6: bonecos, natureza, andares de baixo, janela/zoom

Data: 2026-10-01. Branch `isometrico`. Geração: nenhuma nestas partes (o portão da parte 2 gastou
80; saldo **1.359**).

Com estas partes o Prompt 29 fecha **tudo o que já tem arte aprovada**. O que o prompt pede e ainda
não tem arte (invasores, efeitos, UI, ícones, fonte, retratos, ilustrações, telas de título/
loading/vitória/derrota) depende dos prompts 16–26 e fica listado no fim.

## Como testar

Abra o jogo (vista iso no mapa novo; **não tem mais F3**).

- **Bonecos** (parte 3): cada função × gênero com o desenho dela; andando nas 4 direções de
  losango; parado na pose da direção; trabalho da função (minerar, construir, atacar, atender,
  cozinhar, caçar, cortar, pesquisar); comendo; machucado manca e, parado, senta com a tala; caído
  ou dormindo ao relento fica deitado; dentro de casa some. **Pele** em 3 tons (pelo `look`).
  **Casaco** no frio e **traje** de perigo trocam o desenho. **Picareta/ferramenta nas costas**
  (atrás de frente pra câmera, na frente de costas) e **saco nas costas** carregando, subindo e
  descendo com o passo.
- **Natureza e objetos** (parte 4): árvores (pinheiro, carvalho, bétula pelo lugar) e o toco
  quando cortada; jazida de cada minério cheia → meia → quase → esgotada; galeria lacrada cinza com
  entulho; toca do coelho (fora, orelhas, vazia); horta (pronta, crescendo, colhida); rochas com
  musgo em cima e rocha da mina embaixo; cristais nas 4 cores; tocha acesa (chama animada) /
  apagada; placa de perigo; achados; escora.
- **Robô**: achado → arrastado → conserto 1, 2, 3 (pelo progresso) → ativo andando nas 4
  direções, atacando, desligado quando atordoado.
- **Andares de baixo** (parte 5): elevador do poço em ruína até a escavadeira ficar pronta, depois
  pronto; a **gaiola de chegada** desenhada no chão do nível 2 (o rótulo de baixo vai junto); a
  plataforma do abismo arruinada e, em conserto, subindo pelo corte; sem as pedrinhas antigas por
  cima das lajes.
- **Janela/zoom** (parte 6): roda do mouse com paradas nítidas pra arte nova (pixel de arte
  inteiro na tela) + uma parada "longe"; F11/Alt+Enter como no Bloco 48.
- **Nomes**: o "Comedouro" agora é **Cozinha** em todos os textos.

## Decisões

| Decisão | Por quê |
|---|---|
| Bonecos: `python integra.py bonecos` leva elenco (18), casacos (18), trajes (6) e robô pra `assets/game/iso/bonecos/` em **tiras** por animação × direção, com a **âncora (pé) comum** na tira (cada quadro deslocado pra o pé dele cair no mesmo ponto) e o topo da cabeça de cada quadro | as caminhadas do Prompt 1 têm âncora por quadro (`verificacao.json`); na tira com âncora comum o boneco não treme |
| `scripts/iso/iso_bonecos.gd` escolhe pasta, animação, quadro, pele e camadas só olhando o estado do ipezinho | nenhum sistema de jogo mudou; a vista espelha o estado |
| Pele pelo `skin_palette.gd` do Prompt 28 (3 tons, `look % 3`), em cache por (tira, tom) | a regra do contrato (diversidade por troca de paleta, máscara por quadro) |
| Casaco/traje só têm caminhada e trabalho: parado, comendo etc. volta pro desenho da função | é a arte que existe (Prompt 3) |
| Machucado e traje: o tom de cor antigo do boneco (rosado, esverdeado) **não** vai pro boneco novo; fome (vermelho) e frio (azulado) continuam | a arte nova já mostra a tala e o traje |
| Natureza/objetos: `python integra.py props` (66 peças) e o desenho novo sai do **desenho antigo** da coisa (textura + quadro) | pega de uma vez a decoração do Environment e os props, sem mexer neles |
| Âncora das peças soltas = (meio, base − 3), igual ao `solto` do mapa aprovado (`mapa/monta.py`) | as pastas dos Prompts 8/9/14/15 não anotam âncora; essa é a convenção já aprovada |
| A **navegação** da natureza/objetos não muda | jazidas e galerias encostadas no paredão continuariam acessíveis; a pegada nova delas é pequena |
| Jazida pela **quantidade** (> 60% cheia, > 25% meia, > 0 quase; descansando ou vazia = esgotada) | no jogo antigo as 3 texturas eram variações e o tamanho encolhia |
| Robô passa a ser "coisa que anda" na vista; deitado ocupa 190×70 (a caixa do Prompt 5), em pé 52 | ele anda quando ativo (direção de losango) |
| Elevadores: a ponta de baixo (gaiola, rótulo) desenhada no ponto do andar de baixo dela | na vista empilhada, o filho com deslocamento caía no lugar errado |
| **Portão do poço** movido de (580, 361) pra **(430, 400)**, o lugar dele no layout aprovado (Prompt 27) | com a arte nova ele cobria o elevador; os ferrugentos continuam saindo do elevador e passando por ele |
| Pedrinhas antigas escondidas no mapa novo (o sorteio continua igual) | o chão novo já tem os detalhes; esconder sem tirar do sorteio mantém pedras e cristais dos saves no lugar |
| Zoom: com a arte nova, 1 px de arte = 1 unidade da tela iso; paradas inteiras + uma parada **"longe"** (½ px de tela por px de arte), mínimo 0,3 | o mapa novo tem ~6.000 px: sem a parada longe não dá pra ver a vila inteira. Abaixo de 1:1 não existe pixel inteiro: fica nítido (filtro mais próximo), com algum serrilhado |
| **F3 saiu** (fim do Prompt 29). A vista de cima ficou só pro mapa antigo e pros testes (`DEEP_IRON_ISO=0`) | pedido do Prompt 29 |
| "Comedouro" → **"Cozinha"** só nos textos; nomes de nó e chaves do save iguais | pedido do inventário, sem quebrar save |

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `prototipos/camera/arte_iso/integra.py` | `bonecos` (elenco, casacos, trajes, robô, saco, ferramentas), `props` (66 peças), elevadores e gaiola em `predios` |
| `assets/game/iso/bonecos/`, `assets/game/iso/props/` (novos) | a arte e os `.json` |
| `scripts/iso/iso_bonecos.gd` (novo) | pose do boneco e do robô |
| `scripts/iso/iso_art.gd` | natureza/objetos pelo desenho antigo, jazida pela quantidade, elevadores (+ gaiola no andar de baixo) |
| `scripts/iso/iso_billboard.gd` | boneco novo (corpo + camadas atrás/na frente, ícones acima da cabeça nova, caixa da altura nova), robô, chama da tocha, ponta de baixo do elevador |
| `scripts/iso/iso_view.gd` | robô como coisa que anda |
| `scripts/core/camera_controller.gd` | densidade da arte nova nas paradas, parada longe, mínimo iso |
| `scripts/core/main.gd` | F3 saiu |
| `scripts/core/environment.gd` | pedrinhas escondidas no mapa novo |
| `scenes/game/main.tscn` | portão do poço no lugar do layout aprovado |
| textos: `founding.gd`, `hub_panel.gd`, `hud.gd`, `research.gd`, `centro_vila.gd`, `comedouro.gd`, `canteiro.gd`, `build_menu.gd` | Comedouro → Cozinha |
| `tests/blocos/p29_bonecos.gd`, `p29_natureza.gd` (novos) | testes destas partes |
| `tests/blocos/b48_janela_zoom.gd`, `p28_iso.gd`, `b46_menu_construcao.gd` | **mudados de propósito**: paradas com a densidade nova + parada longe; F3 saiu (o teste liga/desliga direto e confere que o F3 não troca mais); o cartão "Cozinha" |

## Testes

Bateria inteira (GUT, 32 blocos + 12 rápidos): **44/44** (na rodada completa o `b46` falhou só
porque conferia o texto "comedouro" no posicionador; corrigido pra "cozinha" e passou). O save real
não foi tocado (md5 igual antes e depois). Blocos novos:

| Bloco | O que confere |
|---|---|
| `p29_bonecos` | 724 tiras com quadros e topo; 9 funções × 2 gêneros na pasta certa; parado com a picareta atrás (SE) / na frente (NE) e espelhada (SO); andando com a picareta desenhada; carregando com o saco atrás/na frente subindo com o passo; mancando; ferido sentado; caído e dormindo deitados; dentro de casa some; trabalho de cada função; comendo; casaco do lenhador andando; traje de gás minerando; 3 tons de pele; no jogo o corpo antigo some e a caixa tem a altura nova |
| `p29_natureza` | 6/6 árvores, 3 espécies, toco; toca e horta nos 3 estados; 27/27 jazidas do minério certo e pela quantidade; galeria lacrada cinza + entulho; rochas, cristais, tocha acesa/apagada; nada em pé sem desenho novo; elevadores (ruína/pronto, gaiola no nível 2, abismo em conserto); robô nos 6 estados, andando, atordoado, e no jogo |

## Desempenho (critério do Prompt 29: 1080p sem queda perceptível)

`tests/desempenho_iso.gd`, janela 1920×1080, vista iso, arte nova (`desempenho_1080p.txt`). A tela
de teste é de 75 Hz (75 fps = o teto).

| Situação | Arte antiga dos bonecos | Arte nova, 1ª versão | Arte nova, otimizada |
|---|---|---|---|
| Vila de perto | 75 fps | 75 fps | **75 fps** (pior quadro 15 ms) |
| Parada longe (mapa quase inteiro) | 75 fps | 75 fps | **75 fps** |
| Parada longe + 20 ipezinhos a mais trabalhando | 62 fps (pior 96 ms) | 48 fps (pior 100 ms) | **66 fps** (pior 72 ms) |

O que foi otimizado:
- a pele em 3 tons agora é **pintada no integrador** (Python, mesma regra; conferido igual pixel a
  pixel ao `tons_de_pele.py`), não mais no jogo, quadro a quadro na primeira vez (dava os picos);
- o boneco só mexe no sprite quando algo mudou;
- os pedaços escondidos do boneco antigo não são mais copiados;
- os rótulos/ícones são copiados a cada 2 quadros, alternando.

O pior quadro (~70 ms) é o instante em que os 20 bonecos nascem juntos.

GIF de um trecho de partida: `partida_curta.gif`. Capturas finais: `p3_*.png`.

## O que o Prompt 29 pede e ainda não tem arte

| Item | Depende de |
|---|---|
| Invasores (lumívoro, ferrugento, criaturas novas) | Prompts 16–17 |
| Efeitos (poeira, faíscas, fumaça, clima na vista iso) | Prompt 18 |
| UI, ícones, fonte, cursor, menus | Prompts 20–22 |
| Retratos, ilustrações de evento | Prompts 23–24 |
| Tela "Corte da mina", título, loading, vitória/derrota | Prompts 25–26 |
| Animais andando (coelho, javali, pássaros) | o jogo não tem bicho andando (só as tocas, que entraram) |
| Cova (`grave`) | arte ainda não gerada (inventário: falta) |
| Lotação do armazém, satélite do laboratório, escavadeira perfurando, colher fruta/treinar (bonecos), placa de greve, cesto | pendências de arte do inventário |

## Limites

1. Abaixo do zoom 1:1 (parada "longe") o pixel não é inteiro: nítido, com serrilhado.
2. O ícone de carga (pedra/tora/cesto) continua o antigo em cima da cabeça; o saco novo vai nas costas.
3. Os bonecos com casaco/traje parados, comendo ou feridos usam o desenho sem casaco/traje (a arte
   do Prompt 3 só tem andar e trabalhar).
4. Coluna de rocha/poço ligando as lajes empilhadas: não foi pedido no Prompt 29 (era uma ideia da
   parte 1); as lajes continuam separadas, no formato "Layers Exploded View" aprovado.
