# Prompt 28: motor isométrico no jogo principal

Data: 2026-10-01. Branch `isometrico`. Sem geração no PixelLab: é só código (saldo continua
**1.439**).

## Como testar jogando

| Tecla | O quê |
|---|---|
| **F3** | liga/desliga a vista isométrica (a qualquer momento, inclusive no meio da partida) |
| **F4** | (com a iso ligada) mostra as caixas: amarelas = coisas paradas, verdes = quem anda |

Tudo continua igual: selecionar (clique e arrasto), dar ordens (botão direito), minerar,
construir (Espaço), salvar/carregar (F5/F9), dia e noite. A vista de cima continua existindo
até o Prompt 29, pra comparar e pra voltar se algo estranhar.

**O que olhar:**

- quem passa atrás de um prédio some atrás dele, quem passa na frente fica na frente;
- o clique pega o que se vê: o boneco, o prédio (abre o painel), a jazida (botão direito
  manda minerar), o chão;
- mandar andar clicando na PAREDE de um prédio leva o boneco ao pé da parede;
- construir: a pegada aparece achatada no chão (verde/vermelha) e o prédio em pé no ponto do
  mouse;
- obra: o prédio sobe em **3 estágios** (ver abaixo), nas duas vistas;
- a câmera (WASD, roda, F pra seguir, Home) continua olhando o mesmo ponto quando troca de vista.

## Como ficou

Capturas nesta pasta: `vista_cima.png` e `vista_iso.png` (o mesmo ponto nas duas vistas),
`iso_caixas.png` (F4), `iso_longe.png`, `iso_noite.png`, `obra_cima.png` / `obra_iso.png`
(obras em 15%, 50% e 90%) e `fantasma_iso.png` (posicionando uma casa).

**A arte ainda é a de hoje** (o prompt pede: "SEM trocar a arte ainda"). Na vista iso cada
coisa em pé aparece com o desenho atual, de pé no ponto certo; o chão é o de hoje, achatado
em losango. A arte isométrica nova entra no Prompt 29, presa nas mesmas caixas.

## Como funciona (resumo)

A lógica **não mudou**: o mundo continua no chão cartesiano (navegação, física, saves,
posições). A vista iso só desenha esse mundo de outro jeito:

- **Chão** (piso, paredes, pedrinhas, manchas de perigo, e o que o jogo desenha no chão:
  marcador, pegada do posicionador, raio do parque): renderizado como sempre numa textura e
  essa textura é desenhada achatada em losango. Não precisa mexer em nenhuma cena.
- **O que fica em pé** (prédios, ipezinhos, árvores, pedras, tochas, criaturas, canteiros):
  cada um ganha um **espelho** na posição isométrica do pé, que acompanha a arte de verdade
  (quadro da animação, textura, visível, cor, luzes, rótulos).
- Cada coisa em pé tem uma **caixa** (pegada no chão + altura). A caixa decide a **ordem de
  desenho** e o **clique**.

| Item do prompt | Como ficou |
|---|---|
| Projeção tela = (x−y, (x+y)/2) e a volta pro mouse | `scripts/iso/iso_core.gd`; as 2 funções de mouse do jogo passam pela vista iso |
| Ordem por caixas incremental | `iso_order.gd`: o cenário é ordenado uma vez; quem anda é encaixado a cada quadro |
| Reordenar só o pedaço afetado ao construir/demolir | construir **encaixa só a caixa nova**; demolir só tira. 0 reordenações completas nos testes (era 10–100 ms) |
| Verificador sprite-cabe-na-caixa | `iso_art_check.gd`, mesma conta do `predio.py` (concorda pixel a pixel); confere os 17 desenhos de prédio que já têm contrato |
| Prédio em "L" = 2 caixas | a coisa declara `iso_parts()`; cada parte vira uma caixa e um pedaço da arte (recortado pela silhueta), com o z da sua caixa |
| Clique por raio da câmera; parede redireciona/recusa | `Iso.pick`. Ordem de andar numa parede vai pro pé dela; construir numa parede é recusado (a pegada cai em cima do prédio) |
| Posicionador (fantasma) em iso | pegada achatada no chão + prédio em pé no ponto isométrico, com a cor de pode/não pode |
| Estágios de obra por progresso no lugar do fantasma | `scripts/core/obra_estagio.gd`: 0–33% fundação (1/3 de baixo do desenho), 33–66% paredes (2/3), 66–100% o prédio inteiro ainda cru; vale pro canteiro, a expansão do Centro e as peças/reatores da Escavadeira, **nas duas vistas** |
| 4 direções de losango + picareta nas costas | direção pela velocidade NA TELA, com histerese de 15° (não pisca na fronteira); fica em `iso_dir` (meta do ipezinho) pro Prompt 29. Picareta nas costas: atrás do corpo de frente pra câmera (SE/SO), na frente de costas (NE/NO) |
| Paletas de pele por código | `scripts/iso/skin_palette.gd`: a regra do `tons_de_pele.py` (cores do rosto, troca por luminosidade, quadro a quadro), com cache por textura e tom. Dá **exatamente** o resultado do pipeline nos 3 tons |
| Relevo como mapa de altura | `environment.height_at()` (hoje 0 em todo lugar: o mapa atual é plano); as caixas e o espelho já usam a altura. Os terraços do mapa novo entram no Prompt 29 |

## O que mudou, por arquivo

**Novos:**

| Arquivo | O quê |
|---|---|
| `scripts/iso/iso_core.gd` | projeção e volta, caixa, "quem está atrás de quem", ordem completa, raio da câmera (veio do protótipo) |
| `scripts/iso/iso_order.gd` | ordem incremental com encaixe/retirada de uma caixa só |
| `scripts/iso/iso_view.gd` | a vista iso: chão achatado, espelhos, ordem, clique, fantasma, direção de losango |
| `scripts/iso/iso_billboard.gd` | o espelho de uma coisa em pé + a caixa dela (e as partes do "L") |
| `scripts/iso/iso_art_check.gd` | verificador "o sprite cabe na caixa" |
| `scripts/iso/skin_palette.gd` | paletas de pele por código |
| `scripts/core/obra_estagio.gd` + `.gdshader` | obra por estágios |
| `tests/test_iso.gd`, `test_iso_arte.gd`, `test_iso_pele.gd` | testes rápidos (GUT) |
| `tests/blocos/p28_iso.gd`, `p28_save.gd` | testes de partida inteira |
| `tests/data/pele/` | as saídas do `tons_de_pele.py` que o teste da pele compara |

**Alterados:**

| Arquivo | O quê |
|---|---|
| `scripts/core/main.gd` | cria a vista iso; F3/F4; clique, arrasto e botão direito pelo raio da câmera quando a iso está ligada; marcador sai na vista iso; `DEEP_IRON_ISO=1` liga a iso no começo (testes) |
| `scripts/core/camera_controller.gd` | anda na tela iso, mas quem chama continua falando em ponto do chão (`focus_on`, seguir, limites, Home); `ground_center()`; troca de vista sem pular |
| `scripts/core/save_manager.gd` | grava sempre o ponto do CHÃO da câmera (na vista de cima é o mesmo de antes) |
| `scripts/core/house_placer.gd` | o mouse vira ponto do chão pelo raio na vista iso |
| `scripts/core/environment.gd` | `height_at()` (mapa de altura); as luzes fora da tela usam o pedaço de chão que a tela iso mostra |
| `scripts/core/obra_site.gd` | sai o `ghost_color` (fantasma) |
| `scripts/props/canteiro.gd`, `centro_vila.gd`, `escavadeira.gd` | obra por estágios no lugar do fantasma |
| `tests/blocos/b32_escavadeira_visual.gd`, `b38_centro_por_estagio.gd` | **mudados de propósito**: conferiam a nitidez do fantasma, agora conferem os estágios |
| `tests/test_blocos.gd`, `TESTING.md` | os blocos novos e como rodar tudo com a iso ligada |

## Testes

Tudo com a pasta de usuário isolada; o save de verdade não foi tocado (md5 conferido antes e
depois de cada rodada).

| Bateria | Resultado |
|---|---|
| GUT completo, **vista de cima** (28 blocos + 11 testes rápidos) | **38/38** (rodada antes do `p28_save` entrar) e **38/39** na seguinte: o `b45` falhou porque o lenhador sorteou um acidente na hora da conferência (sozinho passou 2 de 2; anotado em TESTING.md como intermitente) |
| GUT completo com **a vista iso ligada em todos os blocos** (`DEEP_IRON_ISO=1`) | **39/39**: a lógica do jogo dá igual com a iso ligada |
| `p28_iso` (5 rodadas seguidas) | 0 falhas: 0 pares na ordem errada, 0 reordenações completas ao construir/demolir, clique certo em prédio/parede/chão/boneco, "L" com 2 caixas, fantasma em pé, construir na parede recusado, liga/desliga sem mexer no mundo |
| `p28_save` com uma **cópia do teu save** (feito antes do Prompt 28) | carrega igual nas duas vistas: 7 ipezinhos no lugar, 569 créditos, arquivo intacto (md5) |
| Verificador da arte | 17 desenhos de prédio em 11 pastas cabem na caixa, contando igual ao `predio.py` |
| Pele | igual ao `tons_de_pele.py` nos 3 tons, também quadro a quadro |
| Custo da vista iso | **~2,6 ms por quadro** com 430 coisas espelhadas (mapa de hoje) |

## Limites e desvios (pra o Marco saber antes de jogar)

1. **A arte em pé é o desenho de cima, de pé.** Prédios e bonecos aparecem como hoje (vista
   de 3/4), só que no lugar isométrico. É provisório até o Prompt 29.
2. **As caixas são a pegada da navegação** (o que bloqueia de verdade), não o desenho:
   alguns prédios viram caixas finas e compridas (F4 mostra). É de propósito: se a caixa
   fosse maior que o que bloqueia, os bonecos passariam por dentro dela. No Prompt 29 a
   pegada e o desenho novos são a mesma coisa.
3. **O boneco só vira pros lados.** A direção de losango (4) já é calculada, mas a arte de
   hoje só tem esquerda/direita: o boneco vira pro lado certo da tela, mas não mostra as
   costas. Com a arte nova (Prompt 29) entram as 4.
4. **Pele por código fica pronta, mas não é usada ainda**: os bonecos de hoje têm o sistema
   de "visual" deles. Liga junto com a arte nova.
5. **O mapa ainda é plano** (o de hoje). O mapa de altura está no motor; o mapa novo com
   terraços e os 2 portões é o Prompt 29.
6. **A vista iso não fica gravada**: abre sempre na vista de cima e o F3 liga. No Prompt 29 a
   iso vira a padrão e a de cima sai.
7. **Obra por estágios com a arte de hoje** = um corte do próprio desenho (só a parte de
   baixo aparece, com cor de obra). Os desenhos obra_1/2/3 da arte nova entram no lugar.
8. **Clima** (chuva, neve, folhas) é desenhado pela textura do chão na vista iso, então
   deve aparecer achatado; não conferi na tela. Os efeitos novos entram no Prompt 29.
9. **Testes que mudaram de propósito:** `b32` e `b38` conferiam a nitidez do fantasma da
   obra; agora conferem os estágios.
