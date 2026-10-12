# Bloco 134 — O CHÃO DA VILA (arte do PixelLab) e os caminhos sem "tábua solta"

Pedido urgente do Marco: depois dos Blocos 132/133 o terreno da vila parecia "horrível, algo jogado por cima, nada natural":
chão marrom chapado, manchas oliva de borda dura parecendo remendos, caminhos em losangos parecendo tábuas soltas, e a noite
revelando mais as manchas. **Por pedido dele, nenhum teste foi rodado e não há teste novo deste bloco** ("quero que faz os
ajustes e não quero teste, pode deixar que faço").

## 1. Diagnóstico (antes de mexer)

Capturas da vila nos estágios 1, 3 e 5, de dia e de noite, com o código do Bloco 131 (antes da grade) e com o de agora
(`tests/capturas_bloco134.gd`, em `docs/arte/bloco134/`: `antes131_*` e `agora_*`). As duas séries saíram **iguais**: o
defeito não veio da grade nem da área da vila limpa. Ele está no próprio desenho do terreno (`terreno_fundo.png`, a imagem
grande do mapa montada nos Blocos 72–79; recortes em `diag_fundo_vila.png` e `diag_fundo_perto.png`).

| Hipótese do pedido | O que era |
|---|---|
| (a) a área da vila e a decoração removida deixaram o centro liso e de borda reta | Não. Na partida nova, perto do Centro, quase não havia decoração removível; o chão é o mesmo antes e depois. |
| (b) as manchas oliva | **Sim:** pintadas no terreno, em cor quase lisa e com borda dura em degrau. A terra marrom é um pedacinho pequeno repetido (daí o "chapado"). À noite a diferença de cor entre as duas aumenta. |
| (c) os caminhos | **Sim:** o ladrilho do Bloco 130 tinha a escala certa da grade (64x32), mas desenhava cada célula com uma LAJE na ponta. Por isso a trilha lia como tábuas soltas. |
| (d) desenho por código por cima | Nada permanente. A grade do Bloco 132 só aparece construindo, mas pintava manchas de cor (vermelho nas ocupadas, amarelo nas portas). |

## 2. O chão novo (aprovado no piloto pelo Marco)

- **Arte:** PixelLab, `create_tiles_pro` com `tile_feature = "tileset"`, isométrico 64x32, plano (ângulo 30°,
  profundidade 0), sem contorno.
- **Os conjuntos:** 16 peças de transição pelos cantos ("terra batida x mato baixo") e os detalhes soltos (rachadura,
  pedrinha, tufo, talo seco), recortados das variações geradas.
- **Piloto e prompts:** `prototipos/camera/arte_iso/chao134/` (`chao134.py`: `estado`, `baixa`, `espera`, `monta`,
  `integra`, `cartoes`; os ids em `jobs.json`).
- **Gasto:** 12 pedidos ao PixelLab. Ficaram fora: a primeira transição, de contraste fraco; uma de ângulo errado; as
  variações "inteiras" de terra e mato, que viravam tabuleiro de remendos; e a trilha com espessura, que parecia tábua.
- **No jogo:** `scripts/iso/iso_chao_vila.gd`, camada logo acima do desenho antigo do terreno (BASE−49) e abaixo dos
  caminhos, na faixa da vila (`environment.areas["vila"]`: da paliçada até a mina).
  - **Terra batida:** a mancha da vila é a área da vila do estágio (`environment.area_vila`) num retângulo de cantos
    redondos, com a borda ondulada por ruído (`borda_ruido`, `borda_escala`). Não há retângulo visível, e a mancha
    cresce com o estágio.
  - **Terra pisada:** em volta de cada prédio (`terra_em_volta` células), inclusive dos que ficam fora da mancha.
  - **Mato:** fora da mancha. A fronteira sai das peças de transição pelos cantos, sem borda reta nem remendo.
  - **Praça do Centro:** um largo de pedra em volta da base do Centro (`praca_celulas`), com borda irregular e as peças
    "terra x pedra" (o desenho antigo tinha a praça pintada).
  - **Junto da mina** (`faixa_mina`): o chão volta a ser terra.
  - **Variação:** detalhes soltos sorteados por célula (`detalhe_terra`, `detalhe_mato`), nunca ladrilhos inteiros
    diferentes.
- **Arquivos:** `assets/game/iso/chao/chao134.png` (16 máscaras x 4 linhas: mato, terra, cascalho, pedra),
  `chao134_detalhes.png` e `chao134.json`. Máscara: NW<<3 | NE<<2 | SW<<1 | SE, com NW = ponta de cima e SE = ponta de
  baixo; bit ligado = o canto é terra.

## 3. Caminhos

`iso_pisos.gd` foi refeito com a mesma arte: um conjunto "terra batida x caminho" por tipo (terra gasta, cascalho, pedra
irregular).

- **Emenda:** cada célula pintada marca os 4 vértices dela (pedra > cascalho > terra quando dois se encontram), e toda
  célula com vértice de caminho recebe a peça pelos cantos. A borda se mistura com a terra; curva, T, cruzamento e ponta
  saem sozinhos. Acabou a laje.
- **Mesma arte em todo lugar:** o fantasma do pincel e os cartões do CONSTRUIR (`cam_terra`, `cam_cascalho`, `cam_pedra`,
  refeitos por `chao134.py cartoes`) usam o mesmo atlas.
- **Achado no caminho:** o QuadMesh do MultiMesh, no 2D, desenha a textura de cabeça pra baixo. Isso trocava a ponta de
  cima com a de baixo do losango e fazia a borda da trilha sair em dente de serra. Os dois shaders agora desviram o UV.

## 4. A grade de construção

`iso_grade.gd`: só **linhas finas**. A célula livre tem a linha neutra (mais apagada que antes). A célula ocupada tem a
linha em vermelho apagado, sem preencher. A porta só aparece no fantasma, que continua verde ou vermelho célula a célula.
Fora do modo construir, nada.

## 5. Desempenho

- **Desenho em lote:** um MultiMesh pras células (~2.830 na vila), um pros detalhes (~670) e um pros caminhos.
- **Reconstrução:** acontece só quando a vila muda (estágio, lugar do Centro, quantos prédios). A ordem e a posição na tela
  das células são calculadas uma vez só; refazer só troca a peça, escrevendo o buffer do MultiMesh de uma vez. Custo:
  **~9 ms** por reconstrução (era 12).

`bench_cena -Rapido` na mesma máquina, no mesmo dia:

| Cenário | ANTES (Bloco 131) méd / p99 (ms) | DEPOIS méd / p99 (ms) |
|---|---|---|
| A início | 10,62 / 12,12 | 10,76 / 11,11 |
| B vila média | 14,61 / 16,67 | 14,63 / 16,67 |
| C vila cheia + invasão + chuva + noite | 23,75 / 29,49 | 23,92 / 26,15 |

Arquivos: `docs/bench/bench_2026-10-12_b131.txt` e `bench_2026-10-12_b134.txt`. Uma rodada intermediária, ainda com a
reconstrução lenta, deu p99 de 33 ms em B e C; a versão final voltou ao nível de antes.

## 6. Capturas

`docs/arte/bloco134/`:

- `antes131_*` e `depois_*`: estágios 1, 3 e 5, de dia e de noite, mais a de perto e a de longe;
- `antes_depois.png`: a prancha lado a lado;
- `piloto_dia.png`, `piloto_noite.png` e `comparacao_atual_x_piloto.png`: o piloto aprovado.

As capturas pintam os mesmos caminhos no antes e no depois: uma rua de terra, uma de cascalho e um largo de pedra.

## Não verificado / pendente

- **Testes:** nenhum rodado (pedido do Marco). Os que mexem nesta área são o `b130_pisos_flicker`, que confere o atlas
  antigo e as lajes e **vai falhar** (o atlas e a regra mudaram), o `b132_grade_construcao` (a grade) e os `p28`/`p29`.
  Precisam de ajuste quando o Marco quiser rodar.
- **A borda segue a escada das células** (21 px), suavizada pela franja de capim da transição. Se incomodar, o próximo
  passo é uma transição mais larga (`transition_size`) ou uma 2ª camada de capim solto na borda.
- **O mato novo é um verde-oliva** um pouco diferente do capim amarelo da floresta além da paliçada. A paliçada separa os
  dois, mas no canto sul aparece a diferença.
- **As ruas desenhadas no terreno antigo** (gate → Centro → mina) ficaram cobertas. O jogador pinta as dele, com bônus de
  velocidade.
- **O atlas antigo** dos pisos (`assets/game/iso/pisos/`) continua no repositório, sem uso no jogo.
- **Balanceamento:** os `@export` novos (`iso_chao_vila.gd`) são de aparência, não de balanceamento; o
  `lista_balanceamento.py` não varre `scripts/iso`.
