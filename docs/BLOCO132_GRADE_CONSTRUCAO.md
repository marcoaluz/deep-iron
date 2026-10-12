# Bloco 132 — A GRADE DE CONSTRUÇÃO

Pedido do Marco: uma visão de construção com a grade de células, casas encostadas (sem vão), ruas certinhas na mesma
grade e o terreno da vila livre da decoração removível. Plano mostrado e aprovado antes de codar (regra 8). Mudanças em
relação ao pedido, aprovadas com o plano:

- a grade é de **64/3 px** (≈ 21,3 px), não de 20 px: é o ladrilho dos pisos do PixelLab (Bloco 130). Com 20 px a arte
  dos pisos teria que ser esticada ou refeita;
- a tecla da grade é a da **Defesa (G)**, só enquanto se posiciona algo. O F8 foi descartado: com o jogo rodando pelo
  editor do Godot, o F8 é o "parar o projeto" e fecha o jogo. Ele virou tecla reservada (não pode ser remapeada);
- prédio posto em cima de rua apaga o trecho, sem devolução (isso já era assim desde o Bloco 89).

## O que mudou

### 1. A grade única (`scripts/core/grade.gd`)
- `Grade.CELULA` = 64/3 px, a mesma célula dos caminhos (`caminhos.tamanho`).
- A pegada da base é arredondada **pra cima** em células (`Grade.quantas`). Até **2 px de contorno de cada lado** não
  contam (`FOLGA_BORDA`): a "base" da arte traz uns px de contorno. A casa (88,7 px) ocupa 4 células e não 5; sem essa
  tolerância, cada prédio ganharia uma célula inteira de vão.
- `Grade.encaixa(pos, pegada)` põe a pegada **centrada** no bloco de células dela.

### 2. A visão de construção (`scripts/iso/iso_grade.gd`, na `iso_view`)
- Aparece com o menu CONSTRUIR aberto ou com qualquer ferramenta de posicionar ligada (prédio, casa, decoração, pincel de
  caminho), se a grade estiver ligada.
- Desenha losangos no chão da **área da vila** (e em volta do fantasma quando ele sai dela). As cores:
  - livre: só a linha;
  - ocupada: vermelho suave;
  - **porta** de prédio: amarelo bem fraco;
  - fantasma, célula a célula: **verde** onde cabe e **vermelho** onde não cabe, com a porta dele mais clara.
- O motivo aparece escrito no topo da tela. O G liga e desliga a grade, e a escolha fica nas configurações
  (`jogo/grade_construcao`).
- O desenho é barato:
  - o losango de cada célula é calculado uma vez só;
  - a camada da grade só é refeita quando a parte visível ou a ocupação mudam (o teste confere que não refaz parada);
  - o fantasma tem camada própria;
  - cada camada é um único lote de triângulos mais um de linhas.

### 3. Encaixe por células (`house_placer.gd`)
- O fantasma encaixa na grade (`_refresh`). O `check_spot` confere as células que a pegada cobre, então ponto fora da
  grade, vindo dos testes, também é avaliado do lado seguro.
- **A folga entre prédios é zero.** Antes havia 6 px em volta de cada estrutura, mais a faixa da frente e a área de
  trabalho. Agora o que fica livre é a **PORTA**: `porta_celulas` (padrão 1) fileira de células na frente da base (+y),
  na largura do prédio. É onde fica a entrada e onde o trabalhador para (`IsoArt.front`).
- As regras:
  - a pegada não cobre célula ocupada nem a porta de outro prédio ("na frente da porta de X");
  - a porta do prédio novo cai em chão livre ("a entrada ficaria bloqueada por X" / "daria pra fora do chão");
  - **o acesso**: uma busca em largura pela grade da área da vila confere que, com o prédio novo, a porta dele e as portas
    que já chegavam ao Centro continuam ligadas à porta do Centro ("fecharia o acesso de X"). Só são cobradas as portas
    que já chegavam: uma porta tapada de antes não trava o jogador.
- **A área de trabalho das estações deixou de bloquear o vizinho.** Os postos ficavam EM VOLTA do prédio
  (`station.get_slot_position`). Com um vizinho encostado, o posto daquele lado caía dentro dele. Agora o posto que cai
  em outra estrutura vai pra **frente** (a porta, que a grade mantém livre), espalhado na largura. O resultado fica
  guardado e só é recalculado quando as estruturas mudam (`environment.nav_pedidos`). Os canteiros já punham o
  engenheiro na frente.
- **Lotes livres** (Bloco 76): perto de um lote, o prédio vai pro meio exato dele, como antes, sem encaixe na grade.
- **Carga do save**: a migração de sobreposição (`environment._overlaps`) tolera os 2 px de contorno de cada lado, então
  prédios encostados não são mais empurrados ao carregar.

### 4. Ruas (`caminho_placer.gd`, `caminhos.gd`)
- O pincel usa a mesma grade. **Shift + arrastar** traça uma **reta** (no eixo em que o mouse andou mais). **Ctrl +
  arrastar** traça um **retângulo** cheio, até `max_retangulo` = 600 células. Os dois pintam ao soltar o botão, e a
  prévia aparece na grade.
- A rua pode passar colada no prédio: os 2 px de contorno da base não tapam a célula vizinha. Rua não é obstáculo pra
  construir, e o prédio por cima apaga o trecho.

### 5. Terreno livre (`environment.gd`)
- **Área da vila** (`area_vila(estagio)`): um retângulo em volta do Centro que cresce com o estágio
  (`area_vila_meia`, meia largura x meia altura por estágio: 260 → 500 px). Fica sempre dentro da paliçada e antes da vila
  antiga do leste.
- **Removível** (`decor_removivel`): mato e entulho (`DECOR_REMOVIVEL`: arbustos, capim, flores, samambaia, cogumelos,
  moita, tronco com musgo, pedras pequenas, tábuas, caixotes, barris, sacos, entulho, palete, sucata, pneus) e as pedras
  soltas, seixos e escoras do desenho antigo.
- **Fica**: a mata, a decoração dos andares e da boca da mina (`nivel_deco`), as tochas (dão luz), o poço, os marcos, o
  fóssil, a vila antiga do leste e tudo a menos de `area_vila_raio_entradas` (70 px) de uma entrada (portão, boca da
  mina, espiral, elevadores).
- A removível sai ao montar o mapa, ao carregar e quando a vila sobe de estágio (`limpa_area_vila`, que refaz a malha se
  saiu alguma peça).
- **Limpar**:
  - no modo de construção, se o que atrapalha é uma peça do mapa que dá pra limpar (removível ou tocha), o aviso diz
    "clique pra LIMPAR (N cr)";
  - o clique cobra `custo_limpar` (5 cr) por peça, sem reembolso, solta poeira e tira a peça;
  - o clique seguinte constrói.
- **Save**: a decoração do mapa é refeita pela semente a cada carga, por isso só o que o jogador limpou à mão vai pro
  save, na chave nova **`decor_limpa`** (`[[x, y]]`). Save antigo, sem a chave, carrega normalmente: nenhuma peça limpa
  à mão, e a área da vila sai limpa na carga. Nenhuma peça de decoração do mapa é item de missão.

## Medição: quantos prédios cabem

`tests/medir_area_vila.gd` faz a medição com as regras do código que estiver rodando:

```
godot --headless --path project.godot -s res://tests/medir_area_vila.gd -- <arquivo>
```

- **Método:** partida nova; cada tamanho é medido sozinho. A vila é varrida em ordem e o prédio entra em todo lugar que o
  posicionador aceita; cada um posto vira obstáculo pros próximos.
- **ANTES:** o código do Bloco 131, varrido de 8 em 8 px.
- **DEPOIS:** a grade. Arquivos em `docs/bloco132/medicao_antes.txt` e `medicao_depois.txt`.

| Região | Tamanho (base) | ANTES | DEPOIS |
|---|---|---|---|
| Área da vila, estágio 1 (520 x 520) | pequeno (carvoaria 57x46) | 20 | 27 |
| | casa (88x76) | 9 | 11 |
| | médio (armazém 104x92) | 4 | 7 |
| | grande (taverna 116x97) | 4 | 6 |
| | alto (igreja 97x102) | 4 | 7 |
| Área da vila, estágio 5 (832 x 1000) | pequeno | 82 | 94 |
| | casa | 45 | 54 |
| | médio | 26 | 35 |
| | grande | 21 | 27 |
| | alto | 26 | 35 |
| Vila toda (paliçada até a pedreira, 920 x 1480) | pequeno | 151 | 168 |
| | casa | 90 | 91 |
| | médio | 46 | 55 |
| | grande | 39 | 45 |
| | alto | 46 | 55 |

O ganho é de +20% a +75% dentro da área da vila. Na vila toda as casas quase empatam, e a explicação está nas regras
novas:

- cada prédio agora reserva a fileira da porta;
- todos precisam ter caminho até o Centro;
- o encaixe de 21 px é menos fino que a varredura antiga de 8 px.

Em troca, o que cabe é previsível e as casas encostam: na captura, a fileira de casas passou de 116 px entre uma e outra
para 85,3 px.

### O plano de 5 estágios cabe? Proposta (NÃO aplicada)

- **A conta:** a vila cheia tem uns 24 prédios fora as casas (escola, posto de troca, cozinha, estufa, enfermarias,
  tavernas, parque, laboratório, arsenais, campo, vestiário, oficina, fornalha, carpintaria, carvoaria, curtume, igreja,
  cemitério, armazéns, posto de expedição, escudo) e 8 a 10 casas. Isso dá ~88% da capacidade "perfeita" da área do
  estágio 5 (24/35 + 10/54). Com ruas e praças, fica apertado.
- **A área da vila não limita a construção:** ela só decide onde a decoração some e onde a grade aparece. O posicionador
  aceita a vila toda, que comporta 55 médios e 91 casas (~55% de ocupação pro plano: confortável).
- **Proposta 1 (só configuração, nada de mapa):** subir `area_vila_meia` dos estágios 4 e 5 pra ~(460, 560) e
  ~(520, 680), pra área cobrir o norte da vila até a paliçada. Mexe só na decoração removível que sai e em onde a grade
  aparece.
- **Proposta 2 (se um dia faltar espaço de verdade):** recuar a paliçada ~200 px pro oeste. Mexe em:
  - `superficie_v3` (paliçada e portão);
  - a mata do oeste (`_build_forest_trees`);
  - os coletores de madeira da clareira;
  - a malha de navegação e o caminho dos migrantes até o portão;
  - os saves com prédios perto da paliçada (a `migrate_positions` já move o que cair na paliçada).

## Capturas

Em `docs/arte/bloco132/` (`antes_*` com o código do Bloco 131 e `depois_*`), pelo script `tests/capturas_bloco132.gd`:

- **vila:** quase igual nas duas. Na partida nova, perto do Centro, quase não havia decoração removível; a pedra de musgo
  do canto fica fora da área do estágio 1.
- **construindo:** a grade, a casa vizinha em vermelho e o fantasma verde com a porta.
- **encostadas:** 4 casas postas na primeira posição aceita. Antes ficavam a 116 px uma da outra; agora a 85,3 px,
  alicerce com alicerce.
- **rua:** uma rua de terra na frente delas.

## Testes

`tests/blocos/b132_grade_construcao.gd` (49 OK) confere:

- a grade, o arredondamento e a pegada centrada;
- a taverna e a casa encostadas aceitas;
- um posto de estação com vizinho colado indo pra frente;
- a casa sobre a porta de outro prédio recusada, e a casa cuja porta cairia num vizinho também;
- o acesso pela grade;
- a rua na faixa da porta, a reta, o retângulo, o retângulo grande demais, e construir sobre a rua;
- a área da vila (cresce com o estágio, sem removível dentro, removível fora, poço/andares/tochas ficam, não passa do
  leste);
- o Limpar (custo, sumiu, save, carga, save antigo);
- a grade na vista (aparece, não refaz parada, G liga e desliga, some fora do modo);
- o F8 reservado;
- a malha: há caminho da porta da obra nova até o Centro.

**Regressão rodada** (um por vez, pasta isolada, save real intocado), todos verdes:

- testes de bloco: b31, b31b, b35, b37, b41, b44, b45, b46, b47, b51, b54, b57, b58, b64, b67, b76, b85, b86, b87, b88,
  b89, b90, b92, b94, b95b, b96, b97, b105, b107, b109, b111, b112, b130, b131, p28 e p29;
- GUT: `test_iso`, `test_iso_arte` e `test_iso_pele`.

**Testes ajustados** (o comportamento mudou de propósito):

- **b37, b41, b44, b45:** o prédio fica onde o fantasma encaixou (`placer._pos`), não no ponto pedido. Na comparação
  depois da carga entra meio pixel de tolerância, porque a posição na grade é fracionária e o save guarda uma casa decimal.
- **b47:** a pegada genérica que o teste usa pra achar lugar agora cobre a base inteira do Arsenal. Sem a folga antiga de
  6 px, os prédios que o teste punha se sobrepunham.
- **b58:** a busca começa entre o Centro e o armazém. Com folga zero, o 1º lugar caía a oeste, e as viagens de material
  do engenheiro não cabiam nos 120 s do teste.
- **p28:** o fantasma fica no ponto encaixado.
- **p29:** o posicionador usa a base sem folga.

Observações:

- **b51 e b107:** passam, mas levam mais de 300 s (b51 faz 50 ciclos de salvar e carregar).
- **p29, ordem de desenho:** em 4 rodadas, 1 vez apareceu 1 par fora de ordem entre ~1090 (os bonecos se mexem no quadro
  medido). Não se repetiu nas outras 3 e não descobri a causa.
- **Bateria completa:** não rodada.

## Não verificado

- Nada foi jogado com o mouse. As capturas e os testes headless conferem a grade, o encaixe e o Limpar; Shift, Ctrl e o
  G de verdade, pelo teclado, não foram testados à mão.
- O desempenho da grade com a câmera andando pela vila cheia não foi medido no `bench_picos` (a camada só é refeita
  quando a vista muda de célula).
- O documento do jogo (`docs/DEEP_IRON_Documento_do_Jogo.docx`) estava aberto no Word e não foi tocado.
