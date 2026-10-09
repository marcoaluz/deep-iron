# Bloco 106 — Coleta, armazém por compartimento e ociosidade

Data: 2026-10-09. Branch `isometrico`. Teste: `b106_coleta_armazem`. Pedido: o prompt URGENTE do balanceamento da coleta.

**Sobre as duas etapas:** o prompt pedia a etapa A (diagnóstico e propostas), a aprovação, e só depois a etapa B (implementar).
O Marco mandou junto: "após terminar tudo aplicar este prompt urgente e se achar algo que deixe melhor pode aplicar e depois so
me documenta para ver o como q ficou e o que foi alterado". Por isso fiz as duas etapas seguidas e documentei tudo aqui.
- Tudo que mudou de balanceamento é `@export` e está listado na seção 6, com o valor de antes.
- Pra voltar atrás um número, é só mudar o `@export`.
- Pra voltar atrás o bloco inteiro, é o commit dele.

**Skills usadas:**
- `survival-crafting` (o ritmo da coleta contra o consumo e o limite);
- `ai-behavior-trees-utility-ai` (o estado de espera e as prioridades);
- `godot-gdscript`, `godot-ui-control` e `save-systems`;
- `godot-gdscript-headless-testing`;
- `performance-optimization` (a checagem de espaço roda a cada decisão: ficou barata).

## 1) O diagnóstico (etapa A)

### A medição
`tests/bench_coleta.gd` mede uma **partida nova de verdade**:
- **A Fundação do jogo:** 10 ipezinhos sem função, 400 cr, 90 de ferro e 80 de madeira. O Centro da Vila fica no lugar
  sugerido.
- **O relógio normal:** o dia tem 540 s reais e a hora de jogo 22,5 s, com a agenda de verdade. O `time_scale` só acelera
  a simulação.
- **A amostra:** o armazém por categoria a cada 0,25 h, o que entrou e saiu, o ponto do vagonete, as horas em cada estado e
  em cada motivo.

**Os cenários:**
- **abertura:** 1 engenheiro (3 casas + a cozinha da Fundação encomendadas na hora), 4 mineradores, 3 lenhadores,
  1 caçador e 1 cozinheiro.
- **coleta:** os 10 coletando (6 mineradores e 4 lenhadores), o pior caso.
- Cada um rodou com o vagonete como estava (ligado) e com ele parado.

Os dados estão em `docs/telemetria/bloco106/` (`antes_*` e `depois_*`). **Tudo nas tabelas foi medido.** Onde houver conta,
está escrito "calculado".

### O que encontrei no código (o código real, não a documentação)

| Coleta | Taxa no código | Medido por trabalhador (antes) |
|---|---|---|
| Minerador | `mineral_node.MINE_RATE` = 3 minério/s batendo (prata 2,2; cristais 2,0 e 1,4), carga 16 (+4 com mochila) | **~27 a 35 minério por hora de jogo** |
| Lenhador | `tree_node.CHOP_RATE` = 1,5/s, carga 8 | ~5 madeira/h |
| Caçador | horta 3/s, caça 1/s, carga 10 | ~6,6 comida crua/h |
| Coletor de madeira | 0,6/s com o operador | (não entra na partida nova: começa em ruína) |
| Coletor de minério | 0,5/s com o operador | (construído depois) |
| Escavadeira | reator a vapor 0,3/s, até 1,5/s no último | 162/dia (Bloco 105); entra no meio do jogo |
| Galeria de dentro (Bloco 99) | `taxa_dentro` = 21/h por mineiro | igual à de fora, decisão do Bloco 99 |
| Vagonete | 100 por viagem, o ponto guarda 240, espera 60 s | 2 viagens no 1º dia |

- **A capacidade (Bloco 97):** 400 / 1.000 / 2.000, de **tudo junto**. A Fundação já começa com 170 dentro.
- **Sem espaço, antes:**
  - quem vinha entregar ficava **no estado "storing", encostado na porta do armazém, com a carga nas costas, sem fim**;
  - o coletor de minério e a escavadeira **tiravam o minério e ele sumia** (o `_deliver` não achava armazém e não fazia
    nada; a escavadeira ainda contava o desgaste);
  - o vagonete esperava carregado.
- **Como o ipezinho pega tarefa:** pelo `_choose_state`. Nesta ordem: a emergência, a agenda, as necessidades, a entrega
  da carga e a função (a estação mais perto pelo `_find_best_station`). Ele decide de novo a cada tick de decisão.
- **Os bugs que procurei:** produção duplicada, coleta contada duas vezes, timer acelerado e velocidade ou expediente
  multiplicando taxas.
  - **Nenhum encontrado.** A jazida tira uma vez por corpo por quadro, com `delta`. O armazém soma uma vez por entrega. O
    vagonete descarrega uma vez. Tudo usa `delta`, então o `time_scale` acelera o relógio junto e a taxa por hora de jogo
    não muda.
  - **O que achei foi PERDA:** o minério sumia nas duas máquinas com o armazém cheio. Está corrigido (seção 2).

### As regras documentadas contra o código
- **Bloco 97 (400 / 1.000 / 2.000 e "a coleta para sem espaço"):** a capacidade estava certa. **A coleta não parava.**
  - O minerador já tinha minerado a carga inteira e ficava preso na porta.
  - As máquinas perdiam o que tiravam.
- **Bloco 77 ("a mina começa desativada; o vagonete só opera com o jogador ativando, com mineiro"):** **só valia DENTRO de
  uma área de mina.**
  - O `work_areas._sincroniza_carrinhos` só para o vagonete quando existe uma área de mina desligada em volta. **Sem área
    nenhuma**, que é a partida nova, o vagonete da boca operava desde o primeiro segundo.
  - Mas ele **não era a causa** do enchimento: com ele parado, o armazém enchia ainda mais depressa (2,36 h contra
    2,92–3,71 h), porque o ponto dele servia de depósito a mais de 240.

### Por que "40 s"?

| Cenário (antes, medido) | Metade do armazém | Armazém cheio (400) | Em segundos reais (1x) |
|---|---|---|---|
| abertura, vagonete ligado (2 rodadas) | 0,76–1,04 h | **2,92 h / 3,71 h** | **66 s / 83 s** |
| abertura, vagonete parado | 0,85 h | **2,36 h** | **53 s** |
| coleta (10), vagonete ligado | 1,11 h | **2,58 h** | **58 s** |
| coleta (10), vagonete parado | 1,06 h | **2,44 h** | **55 s** |

Na velocidade 2x, isso dá **26 a 42 s**. É o "40 s" que o Marco viu.

### A causa raiz do enchimento rápido
1. **A mineração produzia ~6x mais que o resto.**
   - Um mineiro tirava ~30 por hora de jogo, um lenhador 5 e um caçador 6,6.
   - 4 mineradores = ~120–140 minério por hora de jogo = **~5 por segundo real**.
2. **Um limite só, de tudo junto.** O minério ocupava o lugar da comida e da madeira, e a Fundação já entrava com 170 de 400.
3. **A meta antiga dos estágios** (375 de minério pro estágio 2) foi feita pra esse ritmo: o estágio 2 saía em ~2 h de jogo.

### A causa raiz da ociosidade
- **É de ESTADO, não de animação.** Com o armazém cheio, quem trazia carga ficava no estado `storing` parado na porta, pra
  sempre.
- **Medido no 1º dia, no cenário "coleta":**
  - os mineradores ficaram **64,8 h-trabalhador em "storing"** contra **13,2 h minerando**;
  - os lenhadores ficaram 45,2 h "hauling" contra 6,8 h cortando;
  - **o caçador também esperava** (3,7–7 h na abertura): o minério tomava o lugar da comida.
- **As fotos** (`docs/arte/bloco106/antes_armazem_cheio_porta.png`): os 3 mineradores parados na porta, de saco cheio
  (16). Só 2 dos 3 mostravam o balão.

![antes](arte/bloco106/antes_armazem_cheio_porta.png)

### O estado real do vagonete (antes)
Operava sozinho, sem área e sem comando: 2 viagens no 1º dia. O ponto lotado (240) ficava esperando espaço no armazém.

## 2) O que foi feito (etapa B)

### Ritmo (só o que produzia acima do necessário)
- **`Economy.ritmo_mineracao` = 0,045** (novo; 1 = o de antes) multiplica o `MINE_RATE` de toda jazida. Cada jazida
  continua com o dela, e a proporção entre os minérios fica a mesma.
  - **Medido depois:** ~3,1 minério por hora de expediente por minerador (247 em 2 dias com 4).
  - **Por que tanto:** a meta do Marco (o minério leva 2 dias pra encher, sem vender nem gastar) pede ≤155 por dia com os
    4 da abertura. Testei 0,08 primeiro: 227 por dia, enchia em ~1,4 dia.
- **`taxa_dentro` (a galeria de dentro) = 3,5/h** (era 21). Continua igual à de fora, a decisão do Bloco 99, que não muda.
- **A madeira e a comida não mudaram:** não estavam acima do necessário. 3 lenhadores fazem ~170 por dia, e a madeira é o
  material das obras. A comida é comida no mesmo dia.
- **`centro_vila.level_ore_required` = [0, 200, 650, 1.600, 3.200]** (era [0, 375, 1.250, 3.100, 6.250]). Assim a vila
  não trava no ritmo novo: o estágio 2 sai perto do dia 1,5 com a abertura (calculado pelo medido: ~123 minério por dia).
- **3 casas + a cozinha:** prontas em **12,5 h de jogo**, igual a antes (3,5 / 6,6 / 9,5 / 12,5 h; medido). Usam o
  material da Fundação, então o ritmo novo não atrasa.
- **A folga pras habilidades (Prompt R, que ainda não existe):** o minério fica em 337 de 400 em 2 dias sem gastar
  (calculado pelo medido). Um bônus de até +15% ainda cabe nos 2 dias.

### Armazém por compartimento (lógico, no mesmo prédio)
- **Os 4 compartimentos** (`items.gd` `COMPARTIMENTOS`):
  - **Alimentos:** comida crua.
  - **Madeira:** madeira e tábua.
  - **Minérios e barras:** todo minério e o metal.
  - **Manufaturados e demais:** couro, pregos, ferragens, camas, mochilas.
- **Por que não "Pedra":** o jogo não tem pedra separada. O **ferro é a pedra das obras** (`house_stone_ore`, Bloco 13).
  Separar seria um recurso novo, e isso precisa da aprovação do Marco.
- **Capacidade por nível** (`armazem.gd`, `@export` por compartimento). A ampliação multiplica como antes (2,5x e 5x):

  | | Nível 1 | Nível 2 | Nível 3 |
  |---|---|---|---|
  | Alimentos | 150 | 375 | 750 |
  | Madeira | 350 | 875 | 1.750 |
  | Minérios e barras | 400 | 1.000 | 2.000 |
  | Manufaturados | 100 | 250 | 500 |
  | Total | 1.000 | 2.500 | 5.000 |

  - **O critério:** cada compartimento aguenta pelo menos 1 dia da coleta inicial, e o minério 2, sem gastar.
  - **A madeira foi pra 350 por causa do caso "10 coletando":** com 300, enchia no fim do 1º expediente (medido).
  - O total subiu de 400 pra 1.000, mas o que resolve é o ritmo da mineração: o minério, sozinho, continua com 400.
- **O que continua funcionando:**
  - um cheio não bloqueia os outros;
  - **nada some:** a devolução, o prêmio, o cancelar e a fundação entram mesmo cheio, e as máquinas param ANTES de
    produzir;
  - as reservas das obras (Bloco 96), as entregas em curso, as vendas e o consumo continuam iguais (`livre` e
    `quantidade` não mudaram);
  - o save antigo acima do limite fica com tudo, só não recebe mais daquilo.
- **A janela do Armazém:** uma linha com barra por compartimento, em vermelho quando cheio.
- **O alerta:** **"Armazém de minérios e barras cheio"** (o nome do compartimento), dizendo que os outros continuam
  recebendo.
- **A placa** do armazém mostra "CHEIO: minérios e barras".

![janela](arte/bloco106/depois_janela_armazem.png)

### Ociosidade
- **O estado novo `esperando_espaco` ("esperando espaço no armazém"):** quem COLETA aquilo (minerador, lenhador, caçador e
  o operador do coletor), com o compartimento cheio em todos os armazéns:
  - **não coleta mais** (nunca coleta o que não cabe) e **guarda o que carrega**;
  - **espera disponível no Centro da Vila** (ou na área de trabalho dele), andando por ali com o balão "armazém cheio";
  - **volta sozinho** quando abre espaço.
  - Pro minério, ele continua minerando enquanto o ponto do vagonete ainda recebe.
- **Quem tem a carga por outro motivo não trava.** É o caso do engenheiro com sobra de minério ou de quem trocou de função:
  ele fica com ela e segue a função dele, em vez de ir pra porta cheia.
- **A ordem de prioridade continua a mesma:** emergência > agenda > necessidades > função. As ordens manuais também não
  mudaram. Fora do expediente, a carga do compartimento cheio não prende ninguém (Bloco 97, agora por compartimento).
- **Função secundária não existe no código.** Por isso não há "outra tarefa compatível" pra procurar. O que dá pra fazer é
  o minerador continuar enquanto o ponto do vagonete recebe; fora isso, ele espera disponível.
- **Os outros motivos de ociosidade, medidos depois** (abertura, 2 dias):
  - o minerador ficou 0,09 h "sem trabalho" e 0,07 h "caminho bloqueado";
  - o engenheiro ficou 11 h "sem trabalho", e é normal: ele acabou as obras e ninguém encomendou mais;
  - o cozinheiro ficou 2,4 h esperando matéria-prima.
  - Nenhuma rota bloqueada nem destino inválido que prendesse alguém.
- **As máquinas param ANTES de produzir** e mostram o motivo:
  - o coletor de minério ("o armazém de minério está cheio") não tira da jazida;
  - a escavadeira ("PARADA — o armazém de minério está cheio") não perfura, e sem perfurar não gasta;
  - o coletor de madeira também para;
  - o vagonete espera carregado (não mudou).

![depois](arte/bloco106/depois_centro_da_vila.png)

### O vagonete da boca: ruína, restauração e o comando da mina
- **Numa partida nova ele começa em RUÍNA** (`estacao_vagonete.gd`, a boca da mina). A restauração tem 3 etapas, como a
  ruína do coletor (Bloco 81) e o elevador (Bloco 99):

  | Etapa | Custo | Trabalho |
  |---|---|---|
  | 1. Limpar o trilho e o entulho | 30 madeira | 25 s |
  | 2. Trilhos e dormentes novos | 120 cr + 40 ferro + 40 madeira + 10 pregos (antes da fornalha os pregos viram ferro) | 40 s |
  | 3. O vagonete e o freio | 160 cr + 40 ferro + 10 madeira | 45 s |

- **Só com um MECÂNICO na vila.** Sem ele, o botão fica desligado com "precisa de mecânico (tecla ])".
  - O material vai pela obra (Bloco 96): o carregador leva, ou quem trabalha leva.
  - Quem faz é o mecânico. Sem mecânico, o engenheiro continua uma etapa já paga.
- **Em ruína:**
  - o ponto não recebe e o minerador leva na mão pro armazém (nada trava);
  - ninguém entra na galeria;
  - o carrinho não aparece;
  - a placa diz "Vagonete em RUÍNA".
- **Restaurado:**
  - funciona **mesmo que o mecânico saia**;
  - o conserto e a manutenção do trilho são do mecânico (Bloco 105).
- **Restaurar é diferente de ligar a mina:**
  - o comando continua sendo a área de mina do Bloco 77;
  - sem área, o vagonete restaurado leva o que o minerador entrega no ponto;
  - não há produção dupla: o mineiro entrega no ponto OU no armazém, e a galeria só funciona com a área ligada.
  - Medido (restaurado, sem área): 7 viagens e 96 minério pelo carrinho em 2 dias.
- **A janela nova `vagonete_panel.gd`** (clique na boca) mostra as etapas, o custo, a obra e, restaurado, o estado.
- **A arte:**
  - a ruína aparece sem o carrinho e com a placa;
  - o trilho é o de sempre;
  - **NÃO gerei arte nova de ruína** pra não gastar gerações sem aprovação. Se o Marco quiser o trilho velho e a evolução
    (regra 11), é um pedido à parte.
- **Save:**
  - `estacao_mina` ganhou `etapa`, `pago`, `progresso` e `obra`;
  - **save antigo, sem a chave: funcionando**, então o vagonete que andava continua andando.

![vagonete](arte/bloco106/depois_janela_vagonete.png)

## 3) A telemetria antes e depois (medida)

Partida nova, Fundação de 10, dois dias de jogo depois.

| | Antes — abertura | Depois — abertura | Antes — coleta (10) | Depois — coleta (10) |
|---|---|---|---|---|
| 1º compartimento cheio | o armazém todo, a **2,9–3,7 h** | a madeira, a **h38 (1,6 dia)** | o armazém todo, a **2,6 h** | a madeira, a **h28 (1,2 dia)** |
| Minério | parte dos 400 de tudo junto | **258/400 em 2 dias** (337 sem as obras: calculado) | parte dos 400 | **371/400 em 2 dias** |
| Minério que entrou | ~515 nas primeiras ~4 h (o ponto e o armazém) | 247 em 2 dias | — | 282 em 2 dias |
| Madeira que entrou | 88 no dia (parou cheio) | 338 em 2 dias | 54 no dia | 270 em 2 dias |
| Comida crua (entrou = comida) | 38 no dia (o caçador parado 3,7 h) | 146 = 146 | — | (sem cozinheiro) |
| Mineradores minerando / na porta | 18,9 h / **29,6 h** (1 dia) | **89,4 h / 3,5 h** (2 dias) | 13,2 h / **64,8 h** | 129,4 h / 8,2 h |
| Esperando espaço (estado novo) | — | 0 | — | lenhadores 23 h (madeira cheia: esperando no Centro, não na porta) |
| Casas + cozinha prontas | 3,6 / 6,8 / 9,7 / 12,8 h | 3,5 / 6,6 / 9,5 / 12,5 h | — | — |
| Viagens do vagonete | 2 no dia (ligado sozinho) | 0 (ruína) · restaurado: 7 em 2 dias | 1 | 0 (ruína) |

- **Sobre o "coleta (10)":** no cenário de estresse ninguém cozinha, e eles passam fome e fazem greve no 2º dia. Isso é do
  cenário, não do bloco.
- **Ocupação por categoria no fim** (depois, abertura, 48 h):
  - alimentos 0/150 (tudo comido);
  - madeira 350/350;
  - minérios 258/400;
  - manufaturados 0/100.

## 4) Os arquivos

- **Novos:**
  - `scripts/core/vagonete_panel.gd`;
  - `tests/blocos/b106_coleta_armazem.gd`;
  - `tests/bench_coleta.gd` (a medição);
  - `tests/capturas_bloco106.gd` (as fotos antes e depois, o mesmo script nas duas versões).
- **Alterados:**
  - `scripts/props/armazem.gd` (os compartimentos);
  - `scripts/core/items.gd` (`COMPARTIMENTOS`, `compartimento()`);
  - `scripts/core/economy.gd` (`ritmo_mineracao`, `armazem_com_espaco(perto, n, cat)`, `armazens_cheios(cat)`,
    `categorias_cheias()`);
  - `scripts/props/mineral_node.gd` (o ritmo);
  - `scripts/props/coletor_madeira.gd`, `coletor_minerio.gd` e `escavadeira.gd` (param antes de produzir; nada some);
  - `scripts/props/estacao_vagonete.gd` (a ruína, as etapas, a janela, o compartimento de minério, `taxa_dentro`);
  - `scripts/props/centro_vila.gd` (`level_ore_required`);
  - `scripts/workers/ipezinho.gd` (o estado `esperando_espaco`, `_sem_espaco(cat)`, a entrega e o balão por
    compartimento);
  - `scripts/core/hud.gd` (o alerta, a janela do vagonete);
  - `scripts/core/armazem_panel.gd` (as barras);
  - `scripts/ui/alertas.gd`;
  - `scripts/core/environment.gd` (a boca nasce em ruína);
  - `scripts/core/save_manager.gd` (o cabeçalho).

## 5) Os testes

- **`b106_coleta_armazem`** (novo): **0 falhas**. Confere:
  - os compartimentos e a categoria de cada item;
  - um cheio com os outros livres (o lenhador entrega madeira);
  - o alerta, a janela e a devolução;
  - o minerador esperando, com a carga guardada, o balão e a volta sozinho;
  - o engenheiro sem travar;
  - o coletor e a escavadeira parando antes;
  - o ritmo;
  - o vagonete em ruína (sem mecânico, as 3 etapas, sem o mecânico depois, a área não ligada);
  - o save e o save antigo.
- **A bateria completa:** ver a seção 8 (o resultado e os testes antigos ajustados).

## 6) Os @export alterados ou novos

| Onde | Parâmetro | Antes | Agora |
|---|---|---|---|
| `economy.gd` | `ritmo_mineracao` (novo) | (1,0) | **0,045** |
| `estacao_vagonete.gd` | `taxa_dentro` (minério/h lá dentro) | 21 | **3,5** |
| `centro_vila.gd` | `level_ore_required` | 0/375/1.250/3.100/6.250 | **0/200/650/1.600/3.200** |
| `armazem.gd` | `capacidade_por_nivel` (tudo junto) | 400/1.000/2.000 | **saiu** → os 4 abaixo |
| `armazem.gd` | `cap_alimentos` / `cap_madeira` / `cap_minerios` / `cap_manufaturados` (novos) | — | 150-375-750 / 350-875-1.750 / 400-1.000-2.000 / 100-250-500 |
| `estacao_vagonete.gd` | `etapa_nomes`, `etapa_custo`, `etapa_itens`, `etapa_segundos` (novos) | — | a tabela da seção 2 |

## 7) Pendências e riscos

- **O ritmo do jogo inteiro ficou mais lento, de propósito.** O minério e os créditos de venda caem ~7x por mineiro. O que
  dependia de minério (estágios, prédios, ampliações, Oficina) chega mais tarde.
  - Os estágios foram ajustados (0,52x).
  - **Os custos em minério dos prédios NÃO mudaram.** É o próximo ponto pra olhar jogando, com a telemetria do CSV.
- **O meio do jogo não foi medido de novo:** a escavadeira, os coletores e a ferrovia nos andares de baixo. A escavadeira
  sozinha dá ~160 minério por dia, o mesmo que a vila inteira no começo. Isso pode pedir um ajuste no Bloco seguinte.
- **A arte de ruína do vagonete** não existe (seção 2). A ruína mostra o trilho comum sem o carrinho.
- **"Pedra" como compartimento separado** precisa de um recurso novo. Não fiz.
- **A meta "1 dia de jogo" no caso de estresse:** a madeira enche com 1,2 dia (medido). Mais de 4 lenhadores enchem antes,
  e é o sinal de gastar ou ampliar.

## 8) A bateria

Rodou um teste por vez, com a pasta `fake_appdata`, no código deste bloco: **88 testes de bloco + o b106**.
- **85 passaram de primeira.**
  - Entre eles estão os de economia (`b39`, `b82`), navegação e mapa (`b74`–`b76`, `p29_*`), áreas (`b77`), ferrovia
    (`b79`) e obras (`b31`, `b96`).
- **3 mudaram porque a regra mudou, e o teste foi ajustado:**
  - `b74_superficie`: o vagonete da boca começa em ruína. O teste confere isso e restaura antes de medir.
  - `b97_armazem_nivel`:
    - o limite agora é por compartimento (o de minério continua 400 / 1.000 / 2.000);
    - o minerador espera "disponível" em vez de ficar na porta;
    - o coletor para antes de produzir.
  - `b99_mina_elevador`: o vagonete da boca começa em ruína (o teste restaura), e a meta de produção da galeria segue o
    `taxa_dentro` novo.
- Depois dos ajustes, os 4 rodaram de novo: **0 falhas**.
- **GUT `test_iso*`:** 12 de 12.
- **Extra:** a telemetria do jogo (CSV) ganhou `compartimentos_cheios` e `esperando_espaco`.
