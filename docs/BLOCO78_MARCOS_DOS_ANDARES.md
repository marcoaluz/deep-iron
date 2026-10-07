# Bloco 78 — os marcos de cada andar (maquete v4 aprovada)

O Marco aprovou a maquete v4 (`docs/NovoLayout/maquete_v4_legenda.jpg`) e pediu os marcos visuais primeiro; a
ferrovia de carga vem depois, como Bloco 79.

## O que entrou

| Andar | Marco | Como |
|---|---|---|
| Galerias | **Vila de mineração**: cabanas de mineiro e bocas de túnel na parede de trás, alternadas entre as escoras | Desenhadas junto com a faixa (`andares.py`, `enfeites`). |
| S2 | **Caverna de cristais**: 6 cristais a mais (ciano, violeta, lima) e 2 poças d'água deitadas entre o ácido | `S2_acido.tres` (`decoracao` e `decalques`). |
| S3 | **Câmara do fóssil**: o esqueleto gigante deitado na rocha vulcânica, com rachaduras de lava, uma luz laranja e ossos soltos em volta | `S3_lava.tres`. O fóssil bloqueia a passagem (elipse de 104×44 px). |
| S4 | **Fonte termal**: 3 bicas de água quente com uma coluna de vapor | `S4_cachoeira.tres`. O vapor é partícula da vista iso (`iso_view._marco_fx`), como o vapor da lava. |
| S5 | **Cidade subterrânea**: a torre, mais uma casa de pedra e 4 lampiões de cristal acesos, junto das casinhas que já existiam | `S5_lago.tres`. |

**Arte nova** (PixelLab, `create_image_pro` com o estilo dos prédios do jogo; `prototipos/camera/arte_iso/fundo78/marcos.py`):

| Peça | Escolha |
|---|---|
| `fossil_gigante` | Saiu 1 imagem, e boa. |
| `bica_vapor` | c03, das 16 candidatas. |
| `lampiao_cristal` | c06. |
| `cabana_mina` | c07. |
| `boca_tunel` | c07. |

As candidatas estão em `docs/arte/bloco78/candidatas_pixellab.png`. Gastou umas 115 gerações. Tudo entrou nas
peças do jogo com `integra.py props <nomes>`. A torre e as casas de pedra já existiam.

## Testes

- `b78_marcos.gd` (novo): cada marco está no andar certo, dentro do chão da caverna e longe das jazidas, e a
  vida dos marcos funciona (luz do fóssil e dos lampiões, vapor de cada bica, o fóssil bloqueando). As cabanas
  estão na faixa das galerias, e o caminho da gaiola até cada jazida do S3, S4 e S5 continua aberto.
- Passaram: b69 (2 enfeites declarados mudaram de lugar pra caber), b70, b71, b72, b75, b76, b68, b63,
  p29_mapa, p29_natureza, p18 e b47.
- Fotos de perto: `docs/arte/bloco78/0*.jpg`. A captura é `tests/capturas_bloco78.gd`.

## Observação

O contorno de cada caverna é feito pra cobrir todo o conteúdo do `.tres`. Por isso as faixas do S3, S4 e S5
foram regeradas junto (`andares.py`).
