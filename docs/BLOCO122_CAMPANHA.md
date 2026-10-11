# Bloco 122 — A campanha, capítulos 2 a 6 (relatório)

Data: 2026-10-11. Branch `isometrico`. Pedido: Prompt 10 ("Com o sistema de missões do Prompt 3, crie os capítulos 2 a 6 da seção 21.1 do guia, um .tres por missão e textos editáveis por capítulo...
Verifique que os objetivos são alcançáveis e teste a cadeia inteira com os atalhos do F3"). Teste: `tests/blocos/b122_campanha.gd`, **0 falhas**, registrado no GUT. Nada foi jogado de verdade (só o teste).

## 1) Os cinco capítulos (um `.tres` por missão em `data/missoes/`, textos em `capitulo_2.txt` a `capitulo_6.txt`)

| Cap. | Missão | Objetivos (como são medidos) | Recompensa |
|---|---|---|---|
| 2 | **Fogo e ferro** (Vilarejo) | estágio 2 · fornalha · 10 barras de ferro no armazém · arsenal · **forjar 2 lanças** · igreja · um padre | **um colono** (chega pela floresta) · **4 lampiões de graça** · diário · Cap. 3 |
| 3 | **O poço** | laboratório · pesquisar Carrinhos · **5 peças da Escavadeira** · **abrir o S2** · um ventilador | **6 peças raras** · o toque novo (stinger) · diário · Cap. 4 |
| 4 | **O abismo** | pesquisar Trajes · **consertar a plataforma** · 50 de solarita · **derrotar a Matriarca** | **4 lingotes solares** · título **"Vila que não dorme"** · diário · Cap. 5 |
| 5 | **Água e fogo** | pesquisar Bombas d'água · **abrir o S4** · **abrir o S5** · 10 gemas azuis · Vila Mineira (estágio 4) | o **Monumento da vila** (decoração única, de graça) · diário · Cap. 6 |
| 6 | **O escudo** | estudo da explosão · projeto do escudo · **as 4 etapas** | **VITÓRIA** + epílogo + estatísticas · diário |

Cada capítulo pede o anterior (`prerequisitos`) e libera o seguinte (`libera_capitulo`); cada um abre uma **página do diário** (o texto está na seção `[diario.<id>]` do arquivo do capítulo). Mudar um texto no `.txt` muda o jogo, sem tocar no `.tres`.

## 2) O que o sistema de missões ganhou (`missoes.gd`, `missao.gd`)

- **Tipos de objetivo novos:** `desbloqueio` (um andar abriu: o grupo da ligação `elevador`, `elevador_abismo`, `elevador_s4`, `elevador_s5`), `escavadeira_pecas`, `arma_forjada` (só forjar conta, conserto não),
  `chefe` (chefes derrotados, lidos do `defense.bosses`: fica no save sozinho) e `escudo_etapas`.
- **Sinal novo:** `defense.arma_forjada(id)` (só avisa). Save antigo sem as armas contadas: as armas que a vila já sabe fazer contam 1.
- **Recompensas novas:** `colonos` (chama um grupo de migrantes), `pecas_raras`, `decoracoes` ({id: n} de graça), `titulo`, `stinger`, `vitoria` (sem banner: a vitória tem a tela dela). Os `itens` já existiam (lingotes).
- **Save:** `missoes` ganha `titulos`, `decoracoes_gratis` e `contadores.armas` (documentado no cabeçalho do `save_manager.gd`; save antigo = vazio; chave ruim é ignorada).

## 3) O Monumento (decoração única, com arte do PixelLab)

`decor.gd` ganhou a peça **`monumento`** (única na vila, só se ganha como recompensa, beleza 6): um obelisco de pedra escura partido ao meio — de um lado gemas azuis e um fio de água numa bacia, do outro rachaduras de brasa e um braseiro de ferro, com uma placa e uma picareta —
gerado no PixelLab (`predios92.py decor monumento`, 4 candidatos, o c00; integrado por `integra.py props`, o cartão do menu por `ui95.py reaproveita`). A decoração de graça (lampiões e Monumento) é paga pela recompensa (`Decoracoes.colocar`); tirar o Monumento devolve a peça à mão.
No menu CONSTRUIR (aba Decoração) o cartão do Monumento só aparece depois da recompensa.

## 4) A vitória: epílogo e estatísticas

`sun.win()` agora cumpre o capítulo 6 **antes** de pausar o jogo e passa à tela de vitória o **epílogo** (texto editável em `capitulo_6.txt`, seção `[epilogo]`) e as **estatísticas** (`missoes.estatisticas()`: missões cumpridas, invasões vencidas, mortes, minério vendido, pesquisas, Matriarcas derrubadas, dias de vila, títulos).
(O Prompt 15 pede uma tela de estatísticas completa e o modo infinito: vem em outro bloco, em cima disso.)

## 5) A verificação de alcance (nenhum objetivo depende de algo que não existe)

O teste confere, para cada objetivo: o tipo existe, a pesquisa existe na árvore, o grupo do prédio existe nos scripts, o item/minério existe no catálogo, a ligação existe na cena, a arma existe, o estágio existe (≤ 5), a Escavadeira tem 5 peças e o escudo 4 etapas.
**Achado de ordem:** o **ventilador** do capítulo 3 exige a pesquisa Ventilação, que exige **Trajes** (que é o 1º objetivo do capítulo 4). É alcançável, mas o objetivo "Pesquisar Trajes" do capítulo 4 já chega cumprido; o texto do capítulo 3 avisa o jogador. (Se preferir, troco esse 1º objetivo do capítulo 4.)
Também: o capítulo 5 pede o estágio 4 (Vila Mineira), mas o S4 só abre com o estágio 5; o objetivo "abrir o S4" é, portanto, o mais longo da campanha.

## 6) A cadeia inteira (o teste, com o estado posto como o F3 faz)

Capítulo por capítulo: estado → `confere()` → missão cumprida → recompensa conferida (colono/lampiões, peças raras, lingotes + título, Monumento) → capítulo seguinte liberado → diário; o capítulo 6 pela vitória de verdade (`sun.win()`): a missão cumpre, a tela abre com as estatísticas e o epílogo do arquivo. Mais: o Monumento (de graça, único, volta à mão), o save (ida, volta, antigo, ruim).
Vizinhos (um por vez): b100 (ajustado: o capítulo 2 agora existe), b112, b90, b35, b62, b87, p28_save, b95b.

## 7) O que NÃO foi verificado

- Nada foi jogado até o fim: a cadeia foi testada pondo o estado, não construindo tudo. Os objetivos longos (Matriarca, abrir o S4) dependem do balanceamento que já existe.
- O colono da recompensa chama um grupo pela floresta (`migrantes.chama_grupo`): conferi o gancho, não a chegada numa partida.
- A "música nova do S2" do guia **já está no jogo desde o Bloco 121** (o andar fundo tem mais drone e menos melodia); a recompensa do capítulo 3 toca um stinger. Não criei uma trilha só do S2.
- A foto do Monumento no jogo (iso) não foi conferida numa partida (a peça e o cartão carregam, testado).
