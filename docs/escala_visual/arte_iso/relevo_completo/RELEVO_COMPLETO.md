# Arte isométrica: tileset de relevo completo

Data: 2026-09-29. Continuação do checkpoint de relevo 1, que o Marco aprovou (degrau de 32 e
escada de madeira ficam). Nada foi integrado ao jogo. Arte em
`project.godot/prototipos/camera/arte_iso/relevo/final/<ambiente>/`, montador em
`relevo/tiles.py` e conjuntos em `relevo/conjuntos.py`.

## Os 5 ambientes (os mesmos do jogo hoje)

| Ambiente | Pasta | No jogo hoje | Peças |
|---|---|---|---|
| Colônia (terra batida) | `colonia/` | `floor_cave` | 4 chãos, 2 blocos (+2 sem borda) |
| Clareira (grama) | `clareira/` | `floor_clareira` | 2 chãos (+espelho), bloco (+sem borda) |
| Nível 2 (ardósia azulada) | `nivel2/` | `floor_deep` | 4 chãos, bloco (+sem borda) |
| Abismo (basalto com brasa) | `abismo/` | `floor_abyss` | 4 chãos, bloco (+sem borda) |
| Rocha maciça (parede da caverna) | `rocha/` | `wall_rock` | 3 topos, 4 blocos alternados, sem borda |
| Escada (todos) | `escada_N.png`, `escada_O.png` | — | sobe 1 degrau, espelhada pro outro lado |

Imagens:

- `folha_tiles_completa.png`: todas as peças.
- `cena_colonia_caverna_x2.png`: a colônia fechada pela parede de rocha (alta no fundo, baixa
  na frente), com platô, escada, galeria rebaixada e a transição terra → grama num canto.
- `cena_ambientes_x2.png`: clareira, nível 2 e abismo, cada um com platô, escada, galeria e
  bonecos.
- `buracos_x2.png`: galeria de 1 degrau com escada e poço de 3 degraus.
- `variacao_de_face.png`: penhasco longo com 1, 2 e 3 faces alternadas.

## As regras de borda de buraco (regra 6), conferidas

- **Só as paredes de dentro do fundo aparecem.** As do lado da câmera ficam enterradas e
  nunca são desenhadas.
- **A borda da frente fica tão grossa quanto o buraco é fundo, sem tile especial.** O chão em
  volta do buraco é coluna cheia desde o fundo, então no poço de 3 degraus o fundo nunca
  "vaza" por cima do chão da frente.
  - O mesmo teste mostra que um boneco no fundo de um poço de 3 degraus aparece só da cabeça
    pra cima. Buraco fundo tem que ser área sem acesso, como o abismo do protótipo.
- **O fundo escurece 20% por degrau** abaixo do chão, o que ajuda a ler a profundidade.
- **Escada dentro do buraco:** encostada na parede do fundo, que é a visível.

## Transição entre tipos de chão

- O tipo de chão é marcado nos **vértices** do grid.
- Dentro do tile, a mistura dos 4 cantos com um ruído calculado em **coordenada de mundo**
  decide pixel a pixel qual textura aparece. Por isso a borda irregular continua certinha de
  um tile pro outro.
- Não precisa desenhar os 16 tiles de canto de cada par: vale pra qualquer par
  (terra/grama, terra/pedra...) de graça.

## Custo

| Etapa | Gerações |
|---|---|
| Checkpoint 1 (bloco da colônia + escada) | 40 |
| Clareira, nível 2, abismo, rocha (16 candidatos cada) | 80 |
| **Total do relevo** | **120** (saldo 966 → **846**) |

Variações de chão, faces alternadas, blocos sem borda, escada espelhada, buracos e transições:
tudo montado de graça a partir desses 6 lotes.

## Desvios e decisões (reportando)

1. **Bug meu, corrigido:** o sorteio de variação também espelhava os **blocos**, e o espelho
   troca a face clara com a escura. Isso aparecia como xadrez de luz nos penhascos (também na
   cena do checkpoint 1, mais discreto).
   - Agora só o chão espelha.
   - As cenas deste relatório já estão corrigidas.
2. **Clareira:** 12 dos 16 candidatos tinham uma mancha de terra no meio, que vira padrão
   repetido. Ficaram só os 2 de grama uniforme, com espelho.
3. **Abismo:** misturar 2 faces diferentes dava xadrez de brilho, então ficou 1 face só. A
   brasa aparece no chão.
4. **Faces da colônia:** com 1 bloco só, a mesma raiz se repetia em cada tile. Alternei 2
   blocos (#15 e #13) de brilho parecido.
5. **Parede da caverna:** alta (3 degraus) nas bordas do fundo e baixa (1) nas da frente, pra
   não tapar a vila. É o "corte" comum do isométrico. Se preferir as 4 bordas iguais, é só um
   número no mapa.
6. **Escada:** só na frente de uma face visível (sul/leste do platô) ou encostada na parede do
   fundo de um buraco. Uma escada descendo pra longe da câmera ficaria escondida atrás do
   próprio platô. Por isso não gerei essa versão, e isso vira **regra de posicionamento**.
7. **Continua valendo:** a emenda do chão ainda se nota de leve em zoom alto. Os objetos
   soltos (pedras, tufos) da etapa 4 quebram a repetição.

## Na integração (não feito agora)

Cada platô ou buraco (um retângulo do mapa de altura) vira **uma imagem montada destes tiles**,
e essa imagem é a caixa dele na ordenação por caixas (regra 2). No buraco, a imagem inclui a
borda da frente com a espessura da profundidade.
