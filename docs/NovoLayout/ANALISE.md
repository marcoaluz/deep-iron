# NovoLayout — análise e maquete v4 (2026-10-05)

Material do Marco: `leia.txt` e `NewLayout.jpeg`, um corte isométrico gerado como conceito.
Maquete: `maquete_v4.png` e `maquete_v4_legenda.jpg`. O comparativo com a v3 aprovada está em
`comparativo_v3_v4.jpg`. O script é `project.godot/prototipos/camera/arte_iso/blender/coluna_maquete_v4.py`
(a v3 com os acréscimos, que ficam marcados no fim do arquivo).

## A conclusão em uma linha

**A estrutura do NewLayout já é a do jogo, e não vale trocar.** Vale aproveitar o que ele tem de mais forte:
um **marco visual por andar**, a **ferrovia de carga** e o **monitor de perigos** no HUD. A maquete v4 é a
v3 aprovada com esses acréscimos.

## O que o NewLayout propõe e como fica no jogo

| NewLayout | No jogo hoje | Proposta |
|---|---|---|
| Floresta, aldeia, buraco e armazém, ferrovia (superfície) | Floresta, paliçada, vila, mina com o armazém e o vagonete (Bloco 74) | **Manter.** É a mesma ideia; o "buraco" é a nossa boca de mina. |
| Hierarquia vertical, camada por camada | As 4 faixas debaixo da vila, mais as galerias (Blocos 75 e 76) | **Manter.** Já está assim. |
| Vila de mineração (1º nível) | Galerias de madeira: só trilho e vagonetes | **Aproveitar:** cabanas, bocas de túnel e lampiões. Fica com cara de lugar onde se vive. |
| Caverna de cristais | S2 com ácido e cristais | **Aproveitar:** mais aglomerados de cristal e poças d'água entre o ácido. |
| Câmara do fóssil e magma | S3: rio de lava e fios de lava | **Aproveitar:** um esqueleto gigante como marco do S3. |
| Fonte termal de vapor | S4: cachoeira e poças de lava | **Aproveitar:** bicas de vapor e canos de captação. Combina com a cachoeira caindo na lava. |
| Cidade subterrânea | S5: lago e as casinhas de pedra abandonadas (Bloco 71) | **Aproveitar:** crescer as casinhas até uma cidade pequena, com torre e luz de cristal. |
| Zona de gás e câmara de radiação | Já existem como zonas de perigo dentro dos andares, com traje no vestiário | **Não criar andar novo.** O que dá pra fazer é deixar cada zona mais visível (névoa, placas). |
| Núcleo magmático e "Ultimate Core" | O objetivo do jogo é o **escudo solar** na superfície | **Não aproveitar.** Um núcleo no fundo muda a história do jogo. |
| Ferrovia de carga descendo pela coluna | Elevador (gaiola) e escada em espiral. O minério sobe nas costas, pela gaiola. | **Aproveitar, também como jogabilidade:** uma linha de carga com uma estação por andar. Veja o próximo bloco. |
| Painel de dados, inventário e minimapa em corte | Barra de recursos em cima e corte da mina no F2 | Já existem. O corte do F2 pode ganhar os marcos novos. |
| Monitor de perigos | Rótulo de perigo em cada zona | **Aproveitar:** um painel pequeno com o perigo de cada andar e quantos trajes há no vestiário. |

## Minha ideia (além do NewLayout)

A **ferrovia de carga** é o que mais mexe no jogo, e pra melhor. Hoje, quanto mais fundo o minério, mais o
mineiro anda. Uma linha de carga funcionaria assim:

- Uma estação em cada andar, construída pelo engenheiro, como o vagonete do Bloco 64.
- O vagonete sobe a carga pelo cavalete até a plataforma da superfície, perto do armazém.
- O trilho gasta e quebra, como já é no Bloco 64.

Ela também combina com as **áreas de trabalho** (Bloco 77): a mina de cada andar pode ter o seu carrinho.
No visual, o cavalete encosta na coluna, como na maquete. A rampa fica do lado de fora e cada andar tem uma
boca de túnel até a linha.

Os **marcos por andar** são arte e decoração, com risco baixo. Uma ordem possível:

1. Fóssil no S3 (arte nova no PixelLab, como as casinhas de pedra).
2. Fonte termal no S4 (vapor com as partículas que já existem e canos).
3. Cidade no S5 (as casinhas de pedra que já existem, mais uma torre e lampiões de cristal).
4. Cristais e poças no S2.
5. Vila de mineração nas galerias.

Nada disso muda a estrutura aprovada.

## O que precisa do Marco

- Aprovar (ou ajustar) a **maquete v4**.
- Escolher a ordem entre:
  - **(a)** os marcos visuais primeiro, mais rápido;
  - **(b)** a ferrovia de carga primeiro, que é jogabilidade nova e vira um bloco próprio, com o
    balanceamento da distância do lenhador e do mineiro.
