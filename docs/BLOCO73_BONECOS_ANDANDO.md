# Bloco 73 — os bonecos andando no chão

Pedido do Marco (2026-10-04): "melhorar a movimentação dos npcs... deixar mais fluido e natural e parecer
que eles estão andando no mapa, pq alguns olhando parece que eles flutuam um pouco".

## O que fazia eles flutuarem (medido)

1. **O pé de cada quadro numa altura.** Os quadros da caminhada vieram do PixelLab cada um numa altura, e a
   tira usava uma âncora só (a do contrato). Nas 168 tiras de caminhada de gente o pé ficava em média
   **6 px acima do chão** em algum quadro (até 9; o robô até 13; mancando até 11). O boneco subia e descia
   a cada passo, solto da sombra. As animações de trabalho já estavam certas (âncora por quadro).
2. **A perna pelo relógio.** O quadro da caminhada trocava a 9 por segundo, fosse qual fosse o
   deslocamento: andando a 180 px/s o chão escorregava embaixo do pé (cada passo da arte cobre ~20 px, o
   boneco andava ~40), e empurrando alguém ele "marchava no lugar".
3. **Aos trancos.** A posição muda só nos passos da física (60/s) e a tela desenha em outro ritmo: em
   alguns quadros ele não anda, em outros anda dobrado.

## O que mudou

- `integra.py pes` (também no fim de `integra.py bonecos`): calcula, por quadro, o ajuste `aj` = [dx, dy]
  das animações de andar e grava no `bonecos.json` — o pé mais baixo encosta na linha da âncora e, na
  caminhada de gente, a cabeça fica na mesma vertical (sem o tranco pra frente e pra trás). **Os PNGs não
  mudam.** 266 tiras ajustadas; a gosma ficou de fora (ela pula de propósito).
- `iso_bonecos.gd`: a pose aplica o ajuste do quadro (âncora, topo da cabeça, altura — o saco e a
  ferramenta nas costas acompanham).
- `iso_billboard.gd`: o quadro da caminhada vem da **distância andada** no chão da vista (um ciclo de 2
  passos a cada 56 px de arte); "andando" sem sair do lugar fica parado; a posição desenhada fica **entre
  o passo anterior e o atual da física** (pela fração do passo, ~16 ms de atraso). Pulo de lugar (gaiola do
  elevador, porta, save) vai direto e não conta passo.
- `ipezinho.gd`: o relógio antigo da caminhada (o som do passo) no mesmo ritmo (13 quadros/s na
  velocidade normal; devagar = passo devagar).

Antes e depois: `docs/arte/bloco73/andar_antes_depois.gif` (no jogo, zoom 2) e
`docs/arte/bloco73/tiras_antes_depois.png` (as tiras com a linha do chão; à direita, todos os quadros
sobrepostos). Teste: `tests/blocos/b73_andar.gd`. Captura: `tests/capturas_andar.gd`.

## E o Blender?

Dá pra ajudar num passo seguinte, não era a causa: o problema estava no alinhamento dos quadros e no
ritmo, e isso se resolve sem arte nova. Se quiser a caminhada ainda mais macia, o caminho é ter **8
quadros** em vez de 4. Duas formas: (a) refazer as caminhadas no PixelLab com 8 quadros (a animação de
modelo dele) — 9 funções × 2 gêneros + casacos + trajes, 4 direções cada; (b) um boneco 3D simples no
Blender andando (pé travado no chão, 8 poses por direção) como guia de pose pro PixelLab. A (a) é a mais
barata e mantém o estilo; a (b) só vale se a (a) sair com o pé escorregando.

## Fica pra depois

- Criaturas e robô continuam com o quadro pelo relógio (só ganharam o pé no chão).
- `p29_natureza` falhava desde o Bloco 72 ("a gaiola fica no chão do nível 2"): com a coluna, o nível 2
  ficou logo embaixo da vila (564 px na tela, não mais 1000+). O teste agora pede só que fique embaixo.
