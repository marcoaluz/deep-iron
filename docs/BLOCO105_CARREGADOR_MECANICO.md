# Bloco 105 — Carregador e mecânico

Data: 2026-10-08. Branch `isometrico`. Teste: `b105_carregador_mecanico`. Pedido: o "Prompt W1".

O plano e a aprovação estão em `docs/BLOCO105_PLANO.md`.

**O que o Marco aprovou:**
- a forja fica como está;
- o desgaste é gradual a partir de 40%;
- os ventiladores avisam antes de falhar;
- a preventiva custa só o tempo, e o conserto custa material;
- as teclas `[` e `]`;
- a arte em etapas: um personagem só.

**O que ainda espera ele:**
- **O balanceamento do desgaste.** Os números ficam PROVISÓRIOS até ele analisar a telemetria (seção 4).
- **A arte do carregador.** É o piloto, e os outros três e os ícones esperam essa aprovação (seção 6).

**Skills usadas:**
- `godot-gdscript`, `godot-signals-groups` e `godot-ui-control`;
- `ai-behavior-trees-utility-ai` (as prioridades do carregador e do mecânico, o fallback);
- `survival-crafting` (desgaste, conserto, material);
- `save-systems`;
- `godot-gdscript-headless-testing`;
- `deep-iron-arte` + `create-game-assets` (o piloto).

## 1) Como ficou

### O carregador (tecla `[`, grupo SERVIÇO)
- **O nó `Logistica`** (`scripts/core/logistica.gd`) monta as entregas na hora. Cada entrega é reservada pra um carregador só.
  - **Obra:** o material que falta da obra (`ObraSite.a_buscar`) sai do armazém e vai pro canteiro. Ele usa os mesmos
    campos do engenheiro (`material_pedido`/`material_mao`), então a reserva, a pilha e o cancelar do Bloco 96 continuam
    valendo. **O engenheiro só constrói.**
  - **Insumo:** a Fornalha ou a Carpintaria com ordem. Ele paga no armazém os insumos do próximo lote (só o livre), e as
    unidades ficam **"a caminho"** (`production_queue.a_caminho`). Elas só começam na entrega. **O fundidor não sai da
    fornalha.**
  - **Barras:** com carregador, as barras prontas ficam na fornalha (`barras_prontas`), e ele leva pro armazém com espaço.
  - **Cozinha:** matéria-prima do armazém vai pro estoque da cozinha (`comedouro.raw_local`, até 40). **O cozinheiro
    prepara dali.**
- **A prioridade:** obras primeiro, depois barras e insumos, depois a cozinha; a encomenda mais antiga primeiro.
- **O fallback:** sem carregador, ou se a entrega espera `espera_carregador` (30 s) sem ninguém pegar, quem precisava vai
  ele mesmo. Nada trava.
- **A forja não mudou:** é paga na encomenda, como o Marco decidiu.

### O mecânico (tecla `]`, grupo SERVIÇO)
- **O desgaste novo** (`scripts/core/desgaste.gd`):
  - a escavadeira gasta por minério tirado;
  - os coletores gastam por unidade produzida;
  - os ventiladores gastam por hora de jogo ligados;
  - o robô guarda gasta por queda na luta.
  - As cabines e o trilho já gastavam (Bloco 99) e ganharam a mesma curva de eficiência.
- **A curva** (`Desgaste.eficiencia_de`, os números no nó `Manutencao`):
  - até **40% de desgaste**, rende 100%;
  - daí até 0%, cai aos poucos até **50%** (`eficiencia_min`);
  - **em 0, quebra e para.**
- **Os ventiladores:**
  - a proteção cai aos poucos, nas regras de sempre do `fundo.gd` (`ventilacao_mult`, `nevoa_mult`);
  - o ar sai mais fraco (mais lento e mais apagado);
  - **avisam a 25%** com um aviso e o alerta, antes de parar.
- **O conserto da quebra** é uma obra com material (`scripts/props/conserto_maquina.gd`, `ObraSite`):
  - **só é pago quando tem o material todo E alguém pra consertar**;
  - pago uma vez só;
  - sem material ou sem ninguém, nada é gasto, e ele tenta de novo a cada 5 s.
- **A preventiva** é só o tempo do mecânico (20–30 s): a máquina mais gasta abaixo de 60% de condição volta a 100%.
- **A prioridade:** o conserto de quebra vem antes, e ele larga a preventiva quando aparece um. Depois vem a preventiva.
- **Sem mecânico:**
  - o engenheiro conserta o que quebrou (cabine, trilho, robô e as máquinas novas), mas só quando não tem obra de
    construção;
  - ninguém faz preventiva.
- **Achado na telemetria e corrigido:** o mecânico ficava horas preso tentando chegar numa máquina sem caminho.
  - Agora ele desiste depois de `preventiva_desiste` (60 s de jogo), e a máquina sai da lista por `preventiva_evita`
    (240 s).

### Quais consertos passaram pro mecânico
| Conserto | Antes | Agora |
|---|---|---|
| Cabo das cabines (elevador, plataformas) | engenheiro | **mecânico** (sem ele, engenheiro) |
| Trilho do vagonete | engenheiro | **mecânico** (sem ele, engenheiro) |
| Restauração do robô achado | engenheiro | **mecânico** (sem ele, engenheiro) |
| Escavadeira, coletores, ventiladores, robô (quebra nova) | — | **mecânico** (sem ele, engenheiro) |
| Portão/barricada, restauração do elevador e das plataformas, obras | engenheiro | engenheiro (é construção) |

- O pagamento do conserto do cabo (Bloco 99) também passou a esperar alguém que conserte.

### A interface
- A barra de funções ganhou os dois em SERVIÇO.
  - **Os ícones da barra são provisórios** (a mochila e a ferragem do jogo) até a arte ser aprovada.
  - O mecânico usa a roupa do engenheiro até a arte dele (`iso_bonecos.PROVISORIO`). Isso sai sozinho quando o
    `integra.py` puser a função no `bonecos.json`.
- **A barra do desgaste** aparece em cima da máquina gasta: verde, depois amarela, depois vermelha, e com "!" quando
  quebrada.
- **O alerta "Máquina quebrada ou falhando"** na coluna da direita leva até a máquina. O ícone `al_reator` é provisório.
- **O balão "sem material"** aparece no carregador e no operador com uma ordem parada por falta de insumo. O ícone é
  provisório.
- Esperando o carregador, o fundidor não mostra "sem trabalho".
- O robô quebrado diz que precisa do mecânico. Os textos do trilho e do cabo falam "mecânico".
- **A agenda:** os dois trabalham no horário de trabalho como todo mundo.

### As teclas (pedido: validar no teclado real)
- **O teclado deste PC é ABNT2** (layout 0416, "Português (Brasil ABNT)"), conferido no Windows e no Godot
  (`DisplayServer.keyboard_get_layout_name`).
- **A tecla física `KEY_BRACKETLEFT` no ABNT2 é o acento agudo**, uma tecla morta. O Godot ainda rotula essa tecla
  como "[", mas ela não serve pra atalho.
- **As teclas que escrevem `[` e `]` no ABNT2** são as físicas `BracketRight` e `BackSlash`. São essas que ficaram:

  | Ação | Tecla física | No ABNT2 | No americano |
  |---|---|---|---|
  | Carregador | `KEY_BRACKETRIGHT` | `[` | `]` |
  | Mecânico | `KEY_BACKSLASH` | `]` | `\` |

- **O que o teste conferiu:**
  - o mapeamento;
  - nenhuma tecla padrão repetida;
  - que as duas não são reservadas, então dá pra remapear em Configurações > Teclas;
  - que a preferência é gravada no `settings.cfg`, o sistema do Bloco 54.
- **O rótulo na tela agora mostra o caractere do teclado de quem joga.**
  - Antes saía "BraceLeft", e o `;` das Expedições aparecia "Semicolon".
  - No ABNT2 a tecla física `;` escreve **Ç**. O atalho das Expedições continua funcionando, mas agora a tela mostra "Ç".
- **O que NÃO consegui conferir:** apertar as teclas de verdade. Medi o que o Godot lê do layout, mas falta o Marco
  apertar `[` e `]` no jogo pra confirmar.

## 2) Arquivos

- **Novos:**
  - `scripts/core/logistica.gd`, `scripts/core/manutencao.gd`, `scripts/core/desgaste.gd`;
  - `scripts/props/conserto_maquina.gd`;
  - `tests/blocos/b105_carregador_mecanico.gd`;
  - `tests/bench_desgaste.gd` (a medição) e `tests/bench_coleta.gd` (a medição do Bloco 106);
  - `prototipos/camera/arte_iso/oficios105.py`.
- **Alterados:**
  - **O ipezinho e o núcleo:** `ipezinho.gd` (as duas funções, as entregas, a preventiva, `_obra_e_minha`, o balão, o
    save); `obra_site.gd` (o carregador leva o material); `production_queue.gd` (o "a caminho"); `fornalha.gd`
    (`barras_prontas`); `comedouro.gd` (`raw_local`).
  - **As máquinas:** `escavadeira.gd`, `coletor_madeira.gd`, `coletor_minerio.gd`, `centro_vila.gd` (o save do coletor de
    minério), `ventilador.gd`, `fundo.gd`, `robo.gd`, `cabine.gd`, `deep_shaft.gd`, `abyss_shaft.gd`,
    `estacao_vagonete.gd`.
  - **A interface:** `hud.gd`, `alertas.gd`, `icones.gd`, `iso_bonecos.gd`, `iso_billboard.gd`.
  - **O resto:** `teclas.gd`, `main.gd`, `main.tscn` (os nós `Logistica` e `Manutencao`), `save_manager.gd`, `missoes.gd`,
    `missao.gd`, `telemetria.gd`, `environment.gd` (a malha não é refeita com a partida saindo da árvore, achado no teste
    do save).

## 3) Os parâmetros (@export)

**`manutencao.gd`, grupo "Desgaste (Bloco 105) — PROVISÓRIO até a análise da telemetria":**

| Parâmetro | Valor | O que é |
|---|---|---|
| `desgaste_inicio_perda` | 0,4 | desgaste a partir do qual a eficiência cai |
| `eficiencia_min` | 0,5 | a eficiência logo antes de quebrar |
| `limite_preventiva` | 0,6 | condição abaixo da qual o mecânico revisa |
| `condicao_aviso` | 0,25 | condição do aviso "vai falhar" |
| `vida` | escavadeira 600 minério · coletores 300 unidades · ventilador 72 h · robô 4 quedas | vida até quebrar |
| `segundos_preventiva` | 15–30 s por tipo | trabalho da preventiva |
| `conserto` | [créditos, metal, madeira, segundos] por tipo; ex. escavadeira 120/30/10/45 s | o conserto da quebra |
| `conserto_tenta_cada` | 5 s | nova tentativa de pagar |
| `preventiva_desiste` / `preventiva_evita` | 60 s / 240 s | desistir de uma máquina sem caminho |

**Os outros:**
- `logistica.gd espera_carregador` = 30 s;
- `comedouro.gd raw_local_max` = 40.

## 4) A TELEMETRIA (medida, não calculada) — o balanceamento espera a análise do Marco

**Como foi medido:** `tests/bench_desgaste.gd`. Os dados de cada hora estão em `docs/telemetria/bloco105/`.
- A vila está em operação contínua, no relógio NORMAL do jogo: o dia tem 540 s reais e a agenda é a de verdade (dormir,
  refeições, expediente de 10 h).
  - O `time_scale` 10 só acelera a simulação. As taxas por segundo de jogo são as de sempre.
- **As máquinas analisadas:**
  - a escavadeira (reator a vapor, carvão de sobra);
  - o coletor de madeira restaurado, com 1 lenhador designado;
  - o coletor de minério, com 1 minerador designado;
  - 2 ventiladores no S2;
  - a cabine do elevador (S2 aberto como o F3 "abrir todos");
  - o trilho da boca da mina.
- 9 ipezinhos. O armazém fica sem limite, pra medir a máquina, não o armazém cheio. **Sem engenheiro**, pra separar o
  efeito do mecânico.
- **Rodadas de 3 dias de jogo cada:**
  - `sem_desgaste` (a base);
  - `padrao` (os valores de agora, sem mecânico);
  - `com_mecanico` (os valores de agora + 1 mecânico);
  - `vida_meia` (vida ×0,5 + 1 mecânico);
  - `vida_dobro` (vida ×2, sem mecânico).

**Desgaste por tempo de operação e tempo até a 1ª falha (rodada `padrao`):**

| Máquina | Ritmo medido | Desgaste por dia de jogo | Começa a perder (40%) | 1ª falha |
|---|---|---|---|---|
| Escavadeira | 162 minério/dia | 27% | ~36 h | **não falhou em 72 h** (condição 25% no fim); pela conta, ~89 h (3,7 dias) — *calculado* |
| Coletor de madeira | 157 madeira/dia | 52% | ~19 h | **53,0 h** (medido) |
| Coletor de minério | 128 minério/dia | 43% | ~23 h | **59,6 h** (medido) |
| Ventilador (cada) | 24 h ligado/dia | 33% | **28,8 h** | aviso (25%) a ~54 h; **falha a 72,0 h** (medido) |
| Cabine do elevador | 4 viagens em 3 dias (medido) | ~2% | — | não falhou (60 viagens: ~45 dias neste ritmo — *calculado*) |
| Trilho da boca (regra do Bloco 99, sem mudança) | 625 minério até quebrar | — | — | 52–61 h (medido, em todas as rodadas) |
| Robô guarda | 4 quedas | — | — | **não medido** (precisa de invasões; a conta é 4 noites de queda) |

**Quebras por dia (3 dias):**

| Rodada | Quebras | Por dia | Preventivas | Mecânico ocupado |
|---|---|---|---|---|
| `sem_desgaste` | trilho 1 | 0,33 | — | — |
| `padrao` (sem mecânico) | coletor madeira 1, coletor minério 1, ventilador 2, trilho 1 | **1,67** (ficam quebradas: não há quem conserte) | 0 | 0 |
| `com_mecanico` | **nenhuma** | **0** | 9 | 17,1 h (5,7 h/dia = 57% do expediente) |
| `vida_meia` + mecânico | ventilador 1 | 0,33 | 12 | 28,6 h (9,5 h/dia = **95%, no limite**) |
| `vida_dobro` (sem mecânico) | trilho 1 | 0,33 | 0 | 0 |

**Efeito na produção, no total de 3 dias (medido):**

| Rodada | Escavadeira | Coletor de madeira | Coletor de minério |
|---|---|---|---|
| `sem_desgaste` | 485 | 469 | 380 |
| `padrao` | 448 (**−8%**) | 301 (**−36%**, parado depois de quebrar) | 301 (**−21%**) |
| `com_mecanico` | 480 (−1%) | 466 (−1%) | 381 (0%) |
| `vida_meia` + mecânico | 431 (−11%) | 432 (−8%) | 346 (−9%) |
| `vida_dobro` | 486 (0%) | 435 (−7%) | 367 (−3%) |

**Efeito na proteção da mina (`padrao`, medido):**
- O multiplicador da exposição no alcance do ventilador vai de 0,50 (protegido) a 1,00 (sem proteção):

  | Hora | 0–29 | 36 | 48 | 54 (aviso) | 66 | 70 | 72 (quebrou) |
  |---|---|---|---|---|---|---|---|
  | Multiplicador | 0,50 | 0,54 | 0,61 | 0,65 | 0,72 | 0,74 | 1,00 |

  - A névoa do S2 vai de 0,60 a 0,79, e depois a 1,00.
  - **Com mecânico**, fica em 0,50 até a hora 60 e termina em 0,57.
- **Transporte:** o trilho e a cabine ficam mais lentos depois de 40% de desgaste. O mínimo é 0,5 da curva, e o trilho
  nunca cai abaixo de 0,2. **Não medi isso separadamente.** Nas rodadas, o trilho quebrou pela regra do Bloco 99 (625
  minério).

**O que a telemetria diz (a minha leitura, pro Marco decidir):**
1. **Com 1 mecânico, os valores de agora não deixam nada quebrar em 3 dias.** Ele fica ~57% do expediente ocupado.
2. **Sem mecânico**, os coletores param no 3º dia. Com o engenheiro na vila, ele conserta, mas sem fazer preventiva. É o
   peso pra ter um mecânico.
3. **A vida ×0,5 satura o mecânico** (95%): já é a hora de ter um segundo.
4. **O ventilador avisa com 18 h de jogo de antecedência** (6,75 min reais) e perde a proteção aos poucos desde a
   hora 29.
5. Pontos pra decidir:
   - se o coletor de madeira deve durar mais que o de minério (hoje quebra antes, por produzir mais);
   - se 3 dias pro ventilador está bom.

**Nada do balanceamento foi considerado aprovado.** Os valores do `Manutencao` estão marcados PROVISÓRIO.

## 5) Save

As chaves estão no cabeçalho do `save_manager.gd`.
- **Chaves novas:**
  - `logistica` {entregas};
  - `manutencao` {consertos abertos, preventivas, consertos_feitos, quebras};
  - o `desgaste` {c, q} na escavadeira, nos coletores e no robô;
  - a condição de cada ventilador no `fundo`;
  - `barras_prontas` na fornalha e `raw_local` no comedouro;
  - `entrega_mao` no ipezinho (o que o carregador levava volta pro armazém ao carregar);
  - na fila de produção, o "a caminho" vira começado.
- **Save antigo:**
  - as funções de sempre;
  - as máquinas novas inteiras (100%);
  - nada a caminho;
  - a cozinha sem estoque.

## 6) Arte — o PILOTO (só o carregador), esperando a aprovação

A receita do elenco (`oficios92.py`, regra 11), sem mudar nada. `oficios105.py` traz os 4 ofícios descritos, mas **só gera
com o nome explícito** (sem nome, ele para): ninguém gera os outros três sem querer.
- **O que foi feito:**
  - 16 candidatos;
  - o **c04** virou personagem v3 "high top-down";
  - caminhada de 8 quadros;
  - comer, ferido, deitar e mancar;
  - **o trabalho "carregar"** (levanta o saco do chão até o ombro);
  - o casaco de inverno (caminhada + carregar);
  - o retrato com as 5 expressões (uma NOTA pro gorro e a barba no `retratos.py`).
- **Ainda não feito, de propósito:** os ícones (barra, "sem material", alerta da máquina) e a integração no jogo
  (`integra.py bonecos carregador`). Os dois esperam a aprovação.
- **Conferência:**
  - `docs/arte/bloco105/carregador_piloto.png` (as 8 poses, o casaco, o retrato);
  - `carregador_animacoes.png` (todas as folhas);
  - `carregador_trabalho.png` e os GIFs `carregador_*_4dir.gif`.
- **Estilo, escala e perspectiva:** a mesma régua (48×84 com o minerador e a guia 2:1). Paleta suja, contorno de 1 px e o
  gorro índigo como acento.
- **Defeito que vi:** no trabalho **de frente (SE)**, a armação de madeira das costas some na metade, e o saco saiu como
  uma bolsa de couro. De costas (NE) está certo. O casaco tem o mesmo problema. **Dá pra refazer só essa animação**
  (`oficios105.py refaz carregador:carregar`, ~16 gerações) se o Marco quiser.

### Orçamento do PixelLab
| | Gerações |
|---|---|
| Saldo antes do bloco (confirmado no `get_balance`) | **6.141** |
| Gasto neste bloco (real: o carregador inteiro) | **78** |
| Saldo agora (confirmado) | **6.063** |
| Próximos personagens: carregadora, mecânico, mecânica (estimado, pelo custo real do piloto) | ~78 cada = **~234** |
| Ícones: carregador, mecânico, "sem material", alerta da máquina (estimado) | **~40–60** |
| Refazer o "carregar" de frente (opcional, estimado) | ~16 |
| **Total previsto pro resto** (estimado) | **~290–310** → saldo ~5.750 |

## 7) Testes

- **`b105_carregador_mecanico`** (novo): **0 falhas**. Confere:
  - o carregador nas obras e o engenheiro sem carregar;
  - a carga e a reserva;
  - o fallback;
  - que dois carregadores não pegam a mesma entrega;
  - a fornalha ("a caminho", o fundidor fica, as barras);
  - o balão "sem material";
  - a cozinha;
  - o desgaste gradual (escavadeira, ventilador, robô, coletor);
  - o mecânico: o conserto antes da preventiva, o material só quando dá e pago uma vez, a cabine, o trilho;
  - sem mecânico: o engenheiro conserta só a quebra, sem preventiva e com a construção primeiro;
  - a barra, as teclas e o alerta;
  - as missões e a telemetria;
  - o save e o save antigo.
- **A bateria completa:** ver o CONTEXTO.md, onde está o resultado da rodada.
