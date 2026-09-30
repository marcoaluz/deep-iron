# Prompt 7: terreno da mina

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/relevo/final/mina/`,
montador em `relevo/mina.py`, trilhos em `relevo/trilhos.py`. Nada integrado ao jogo.

## O que o jogo tem (conferido no código)

| Área | No código | Arte |
|---|---|---|
| Nível 1: a mina onde fica a colônia | `floor_cave` | terra batida + parede de rocha (relevo, já aprovados) |
| Nível 2 | `floor_deep`, `deep_shaft.gd` | ardósia (relevo) |
| Abismo | `floor_abyss`, `abyss_shaft.gd` | basalto com brasa (relevo) |
| Zonas de perigo | `hazard_zone.gd`: `gas`, `calor`, `radiacao` | **novas** (abaixo) |
| Galerias lacradas (Bloco 33) | `mineral_node.gd`: jazida atrás de entulho com tábuas em X, abre com a vila | **nova**, em 3 estágios |
| Carrinhos de mina (pesquisa) | `research.gd`: `carrinhos` | **trilhos novos** |
| Escoramento (pesquisa) | `research.gd`: `escoramento` | **escora nova** |

## O que ficou pronto

- **Pisos das zonas** (5 variações cada), no mesmo bloco dos outros pisos:
  - gás: terra com musgo tóxico e poças verdes;
  - calor: rocha escurecida com rachaduras em brasa;
  - radiação: rocha com cristais baixos verde-limão.

  Misturam com o chão comum pela transição por vértice (sem tile de canto).
- **Galeria na parede de rocha, como obra:** `galeria_lacrada` (entulho + tábuas em X) →
  `galeria_abrindo` (entulho pela metade, tábuas arrancadas, picareta e pá) →
  `galeria_aberta` (escorada com vigas).
  - Mesmo quadro (100×150) e mesma âncora nos 3: trocam no lugar.
  - Caixa: 2×1 tiles, 3 degraus, abertura da altura de um minerador.
  - A aberta também serve de **túnel** entre áreas.
- **Escora de madeira:** par de postes com viga e mão-francesa, pra pôr ao longo das
  galerias.
- **Trilhos**, desenhados por script na geometria exata do tile: reto (2 eixos), curva (4),
  cruzamento, fim de linha com para-choque (4). Junção = reto + curva sobrepostos. Encaixam
  tile com tile (testado num circuito fechado).
- **Poço do elevador / da escavadeira:** é um buraco fundo do próprio relevo (paredes de trás
  visíveis, 20% mais escuro por degrau), sem arte nova. A gaiola do elevador e a escavadeira
  são do Prompt 13.

## Entregas (nesta pasta)

| Arquivo | O que é |
|---|---|
| `prancha_mina.png` | zonas ladrilhadas 5×5, escora, galeria nos 3 estágios, as 11 peças de trilho |
| `cena_nivel1.png` (+ `_x2`) | a colônia na caverna: paredão de rocha com as 3 galerias, trilho saindo da galeria aberta com cruzamento e para-choques, escoras, poço do elevador de 4 degraus, as 3 zonas no chão com os trajes certos em cada uma |
| `cena_nivel2_abismo.png` (+ `_x2`) | nível 2 (ardósia) e abismo (basalto + mancha de calor), cada um com trilho e poço |

**Cena de estresse:** a geometria é a mesma do Prompt 6 (degrau 32, buraco, rampa), e ele
passou com 0 erros de ordenação e 100% de clique por face. Galeria e trilho não criam
geometria nova: a galeria é uma caixa 2×1×3 como a boca de mina, e o trilho fica em cima do
chão.

## Custo

**~200 gerações** (saldo 3.863 → **3.663**):

| Item | Gerações |
|---|---|
| 3 pisos de zona | 60 |
| Trilhos pela IA (reto, curva, fim), usados só pra tirar a cor | 60 |
| Galeria aberta + lacrada + abrindo | 75 |
| Escora | 20 |

(As 3 referências de rocha, nível 2 e abismo foram copiadas pra bancada com link permanente:
custo 0.)

## Desvios e decisões (reportando)

1. **Trilhos por script, não pela IA.** Os candidatos saíram bonitos, mas cortados no quadro
   e no eixo errado, e não encaixariam. O script calcula cada pixel em coordenada de mundo, e
   as pontas caem sempre no meio da borda. Cores do ferro e da madeira tiradas dos candidatos.
   São mais simples que um desenho à mão, mas encaixam 100%.
2. **Galeria mais clara que a rocha** (brilho 0,295 × 0,25): escurecida 15%. A lacrada saiu
   1 px abaixo das outras e foi alinhada (sobreposição 93% → encaixa).
3. **Topo da galeria:** na montagem, é coberto pelo chão da rocha do paredão, como na boca de
   mina. Sobra uma linha clara fina na borda de cima, visível só com zoom alto.
4. **A tábua encostada da "abrindo" é cortada na borda direita do quadro.** Na parede ela fica
   escondida pelo bloco vizinho, então só aparece cortada fora do jogo.
5. **Radiação:** os cristais altos seriam cortados pelo recorte do losango. Ficaram os
   candidatos de cristal baixo. Cristal grande de verdade é prop (Prompt 8).
6. **Cenas de teste com corte de maquete:** a borda da frente desce até o fundo do poço. Num
   mapa inteiro, o chão da frente esconde isso.
7. **Visão do mapa do Marco** (floresta → portão → pedreira → mina → plataforma de perfuração):
   registrada em `docs/arte/MAPA_VISAO.md`. Acrescentou ao inventário o **javalizinho**, o
   **portão da vila** (quebrado → obra → pronto) e o **Coletor de madeira como máquina
   grande estragada**.
