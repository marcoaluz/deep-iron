# Arte isométrica: CHECKPOINT de relevo 1 (1 platô com transições)

Data: 2026-09-29. **Parado aqui esperando a aprovação do Marco** antes de gerar o resto do
terreno. Nada foi integrado ao jogo. A arte está em
`project.godot/prototipos/camera/arte_iso/relevo/final/`, e o montador em
`relevo/tiles.py`.

## O que ficou pronto

| Peça | Arquivo | Para que serve |
|---|---|---|
| Chão (4 variações) | `chao_0..3.png` (64×32) | chão e topo de platô; sorteio fixo por tile + espelho |
| Bloco de platô | `bloco.png` (64×64) | 1 degrau: topo + as 2 faces visíveis, com borda de terra pendurada |
| Bloco sem borda | `bloco_sem_beira.png` | os blocos de baixo de um penhasco de 2+ degraus (sem borda no meio) |
| Escada | `escada_N.png` / `escada_O.png` (espelho) | sobe 1 degrau; fica na frente da face da esquerda ou da direita |

- `cena_plato_x2.png` mostra um platô de 1 degrau, um 2º andar, um penhasco de 2 degraus
  direto do chão, 3 escadas e 5 bonecos para dar a escala.
- Uma das bonecas está **atrás** do platô, com as pernas cobertas pela beira: a oclusão
  está certa.

## Geometria (regra 6: mapa de altura, degraus fixos)

- **Tile = 32×32 no chão**, que vira um losango de **64×32** na tela (2:1 exato).
- **Degrau = 32 de altura.** O platô de 1 degrau bate na cintura do minerador (70); o de 2
  degraus (64) fica quase da altura de uma pessoa.
  - O protótipo usava 36, 54 e 72. **Pra confirmar:** degraus fixos de 32.
- **Não existe tile de canto nem de transição de canto.**
  - Desenho em ordem de coluna (i+j), de baixo pra cima dentro de cada coluna.
  - A face escondida por um vizinho fica coberta sozinha, e os cantos de fora e de dentro
    saem certos.
  - Com isso, um platô de qualquer formato usa só estas peças.
- **Na integração:** cada platô (um retângulo do mapa de altura) vira **uma imagem montada
  destes tiles**, e essa imagem é a caixa dele na ordenação (regra 2). O resto do sistema já
  foi testado no protótipo da Rota A.

## Custo

| Etapa | Gerações |
|---|---|
| Guias 2:1 do bloco e da escada (`pixelart_workbench`) | 0 |
| Bloco de terreno: 16 candidatos | 20 |
| Escada: 16 candidatos | 20 |
| **Total** | **40** (saldo 966 → **926**) |

As variações de chão saíram dos mesmos 16 candidatos do bloco: o topo de cada um vira um
chão. Espelho, bloco sem borda e escada espelhada não custaram nada.

## Desvios e problemas (reportando, não contornei sozinho sem avisar)

1. **Os blocos da IA saem 1 a 2 px menores que a guia e com contorno preto em volta.** Com o
   contorno, os tiles lado a lado formariam uma grade preta.
   - Criei a **retificação** (`tiles.py`): acho os vértices do bloco desenhado e reamostro
     topo e faces na geometria exata, pulando 2 a 3 px da borda.
   - Isso é reamostragem de pixel (vizinho mais próximo, deforma ~3%). Na prática não se
     nota, mas é uma troca de pixels da arte original. Ver `retificacao_antes_depois.png`.
2. **A borda do topo vinha escurecida,** o que formava uma grade fraca no chão.
   - Corrigi trocando cada pixel da faixa da borda pela cor mais parecida **da própria
     paleta do tile** (não cria cor nova).
   - **Ainda se nota de leve** em zoom alto em algumas emendas.
   - Na etapa de objetos, pedras e tufos soltos por cima quebram a repetição.
3. **A escada veio com fundo branco sólido,** mesmo pedindo transparente. Tirei o branco no
   script.
4. **A escada saiu de madeira escura,** e não "cortada na terra" como pedi. Lê bem como
   degraus e combina com a casa, mas é mais escura que o terreno. Se preferir escada de
   terra, é outro lote de 20.
5. **O topo do platô é igual ao chão:** só o penhasco separa os níveis. É o jeito comum do
   isométrico, mas dá pra ter um chão de platô diferente (mais pedra) se quiser.

## Próximo (depois da aprovação)

- **Buraco/galeria** com as regras de borda: só as paredes de dentro, e a borda da frente
  tão grossa quanto o buraco é fundo.
- **Escada nos lados de trás** do platô (descendo pra longe da câmera).
- **Variações de face** de penhasco, pra a repetição ficar menos visível em paredões longos.
- **Chão com transição** terra ↔ pedra/cascalho, onde houver mina.
- Depois: prédios restantes com a sequência de obra, e por fim os objetos.
