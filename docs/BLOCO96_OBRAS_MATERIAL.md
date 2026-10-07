# Bloco 96 — Obras com material levado pelo engenheiro

Data: 2026-10-07. Branch `isometrico`. Teste: `b96_obras_material`.

**O pedido:** o "Prompt O" (`Claude outputs/deep-iron-prompts-O-P-Q-M-S1-S2.md`). Obras realistas: o material fica
reservado no armazém e o engenheiro leva.

O plano, com a tabela de tudo que cobrava material na encomenda, está em `docs/BLOCO96_PLANO.md`.

**As decisões do Marco:**
- limite de **10 por viagem**;
- cancelar devolve **também os créditos**, e vale para **todas as obras**;
- barricada, plataforma do abismo e robô **seguem o que o prompt propôs**: os consertos grandes viram obra com
  material.

**Skills usadas:**
- `save-systems` (a lista no save, save antigo = tudo entregue);
- `godot-gdscript`;
- `godot-gdscript-headless-testing`;
- `survival-crafting` (reserva, carga e viagem).

## Como ficou

1. **Encomenda.**
   - Os créditos saem na hora.
   - O que o pagamento tirou do armazém **volta pro mesmo armazém** e vira a **lista de material** da obra
     ({madeira: 40, ferro: 20}).
   - Como funciona: a `Economy` anota um **recibo** de tudo que os pagamentos tiram neste quadro, e o
     `ObraSite.start()` da obra que nasce no mesmo quadro pega esse recibo. Por isso **nenhum dos ~30 pontos de
     encomenda precisou mudar**. O tipo já vem resolvido pelo custo de hoje: minério qualquer = o mais barato,
     barras a partir da fornalha, pregos/ferragens antes da fornalha viram ferro.
   - A obra da **forja** (ferreiro: Oficina e Arsenal) continua pagando na hora, porque é produção.
2. **Reserva.**
   - `Economy.livre(item) = no armazém − reservado`.
   - O reservado é calculado das obras (falta chegar e não está nas mãos de ninguém), sem estado solto no save.
   - Encomendas novas, `can_afford`, `missing_text`, `metal_falta` e `itens_falta` olham o **livre**.
   - **Vender** (tudo, por item, o "auto") **não vende o reservado**.
   - As filas da Fornalha e da Carpintaria também não usam o reservado.
3. **Viagens.** Quando a parte liberada está feita, o engenheiro:
   - vai ao **armazém mais perto (dele) que tem o item**;
   - pega até `carga_material` (**10**, `@export` no ipezinho), juntando outros itens da lista que estejam no mesmo
     armazém;
   - leva, entrega ("+10 madeira") e constrói.

   **Vários engenheiros:** cada viagem é uma **promessa** (`material_pedido`) que os outros descontam, então ninguém
   busca o mesmo item duas vezes. O teste mede que a soma das promessas nunca passa do que falta.
4. **Progresso limitado** ao entregue (`ObraSite.fracao()`). Os estágios (fundação, paredes, prédio cru) aparecem
   conforme o material chega. O teste mediu 0,1% de folga no máximo, ou seja, um quadro.
5. **Visual e textos.**
   - **Carga no corpo:** o ícone de carga que já existia — tora pra madeira, pedra do minério, o ícone do item pras
     barras, tábuas e pregos. Cresce com a quantidade.
   - **Pilha ao lado da obra:** o material entregue e ainda não usado, com as pilhas que já existiam no jogo (tábuas,
     pedra P/M/G, aço, carvão, caixote). **Sem arte nova.** Diminui conforme a obra anda.
   - **Estado da obra:** "esperando engenheiro" / "buscando material" / "levando N/M" / "falta material no armazém" /
     "construindo". Aparece no rótulo do mapa (o inteiro, com o mouse), na gaveta Obras e nas janelas que mostram a
     obra.
   - **Gaveta Obras:** **entregue/necessário por item** ("madeira 30/40 · ferro 0/20") e o botão **Cancelar**.
   - **Texto do engenheiro:** "buscando 10 madeira no armazém (Taverna)" / "levando 10 madeira pra Taverna (20/40)" /
     "esperando material no armazém (Taverna)".
6. **Cancelar** (novo, em todas as obras): **créditos de volta por inteiro**. Volta pro armazém o já entregue e o que
   estiver nas mãos; o reservado só deixa de ser reservado.

   Cada dono desfaz a encomenda:

   | Obra | Ao cancelar |
   |---|---|
   | Canteiro | some |
   | Casa nova | some, e a Moradias (ou a casa inicial) volta um passo |
   | Ampliação de casa / melhoria do Centro | nada sobe |
   | Etapa do coletor em ruína e do escudo | volta a "não encomendada"; as peças raras do núcleo voltam |
   | Peça ou reator da escavadeira | para; as peças raras do reator voltam |
   | Cemitério | o terreno some |
   | Barricada | o muro fica como estava |
   | Plataforma do abismo / robô | voltam a esperar; as peças raras voltam |

   O botão fica na gaveta Obras do HUD. **Diferença do plano:** o plano falava também num botão na janela de cada
   obra. Só fiz o da gaveta, que alcança qualquer obra (ela lista todas).
7. **Consertos grandes** (decisão do Marco):
   - **Barricada:** subir de nível vira obra (30/45/60 s, `upgrade_tempos`), e o muro sobe no fim. O conserto até
     **10 de madeira** (`conserto_na_hora`) continua **na hora**; acima disso vira obra (0,8 s por madeira).
   - **Plataforma do abismo** (S3/S4/S5) e **robô:** o conserto era um relógio que andava sozinho. Agora só anda com o
     engenheiro, e a prata/o ferro vão nas costas dele. As peças raras continuam pagas na hora, porque não ficam no
     armazém.
8. **Sem material, igual a antes:**
   - **Expandir a vila** (só créditos);
   - **o conserto do trilho quebrado** (não custa nada hoje: é o "conserto pequeno" do pedido).
9. **Chave geral:** `Economy.obras_com_material` (`@export`). Desligada, é tudo como antes; ela serve pra medir.

**Save** (documentado no cabeçalho do `save_manager.gd`):
- todo `"obra"` ganha `"necessario"`, `"entregue"` e `"creditos"`;
- o ipezinho ganha `"material_mao"`, que **volta pro armazém ao carregar**: nada se perde nem duplica;
- abismo e robô ganham `"obra"`;
- a barricada ganha `"obra_tipo"`, `"obra_total"`, `"obra_left"` e `"obra"`.

**Save antigo:** obra sem `"necessario"` = **tudo entregue** (os canteiros já pagos andam como antes). Um conserto do
abismo ou do robô que estava em andamento continua, agora esperando o engenheiro.

## Balanceamento: o antes e o depois (item 7)

- **A telemetria** ganhou duas colunas: `obras_prontas_dia` e `obra_tempo_medio_s` (da encomenda ao pronto, em s de
  jogo).
- **A medida:** `tests/bench_obras.gd -- <sem|com> <engenheiros>`. Cada modo roda numa partida nova e igual, com as
  obras nos mesmos lugares, então a caminhada é a mesma nos dois modos.

Segundos de jogo, da encomenda ao pronto (limite de 10 por viagem):

| Obra (material) | 1 engenheiro: antes → depois | 2 engenheiros: antes → depois |
|---|---|---|
| Taverna (40) | 49 → 80 (**1,6x**) | 27 → 42 (**1,5x**) |
| Parque (60) | 33 → 89 (**2,7x**) | 18 → 46 (**2,5x**) |
| Casa (60) | 39 → 71 (**1,8x**) | 22 → 38 (**1,8x**) |
| Trilhas (25 minério) | 26 → 58 (**2,2x**) | 15 → 35 (**2,3x**) |

**Leitura:**
- Uma obra comum ficou **1,5x a 2,7x** mais demorada.
- Cada viagem leva ~12–20 s, conforme a distância até o armazém.
- O caso extremo é a **peça da escavadeira**: a broca pede 625 minério, ou seja 63 viagens, **~15–20 min com 1
  engenheiro** contra 90 s antes. Pela conta, não foi medido. A ferrovia do S2 (254 de material, andar longe)
  também fica pesada.

**Propostas (NÃO aplicadas, decisão do Marco):**
1. **Carga por viagem 15** (no lugar de 10): as obras comuns ficam ~1,3–2x.
2. **Carrinho de mão** (pesquisa barata ou item da Oficina): +10 de carga pro engenheiro com ele. Mantém o 10 no
   começo e dá um alvo de progresso.
3. **Escavadeira e escudo:** essas obras grandes recebem o material pelo **vagonete/ferrovia** quando existir (o
   minério já chega por trilho), ou têm uma carga própria maior (ex.: 30 por viagem).
4. **Um 2º armazém perto da vila:** já funciona hoje (o engenheiro busca no mais perto). Vale lembrar o jogador
   disso na dica do armazém.

## Testes

- **Novo:** `b96_obras_material`, **0 falhas**. Confere:
  - **reserva:** a encomenda reserva sem tirar; outra encomenda não usa o reservado; vender não vende o reservado;
    cancelar a cozinha libera;
  - **sem material:** obra sem lista e save antigo = tudo entregue; save no meio;
  - **viagens:** 1 engenheiro com um **2º armazém** mais perto (buscou lá); nunca mais de 10 por viagem; o progresso
    nunca passou do entregue; os estágios vêm 1 → 2 → 3;
  - **2 engenheiros:** os dois viajam, ninguém promete mais do que falta, entregue/necessário por item;
  - **cancelar no meio:** créditos e material de volta, ninguém com material na mão, nada reservado;
  - **save:** o material da mão vai pro save e volta ao armazém;
  - **consertos:** barricada (nível vira obra; conserto pequeno na hora e grande vira obra; cancelar); robô (quando
    ele existe na partida); plataforma;
  - **telemetria:** conta as obras e o tempo médio.
- **Defeito achado e corrigido** antes do teste: com tudo entregue, a obra parava em 99,99%, porque a trava comparava
  com uma margem. Com 1 engenheiro ela passava por sorte; com 2 travava sempre. A medida pegou.
- **Ajustados** (conferiam o estoque físico logo depois da encomenda; agora conferem o **livre**, que é o que cai):

  | Teste | Ajuste |
  |---|---|
  | b41, b44, b45, b81 (o helper `estoque`), b86 | conferem o livre |
  | b56 | confere o livre e entrega o material direto na ampliação (as viagens são do b96) |
  | b71 | o conserto da plataforma anda pelo `obra_work` |
  | b87 | a barricada paga em barras = barras livres; depois cancela |
  | b94 | a barricada 3 vira obra: entrega e termina |

- **A bateria inteira, um teste por vez:**
  - os **80 de `tests/blocos`** passam, inclusive o b51 (362 s);
  - os GUT `test_iso` (6/6), `test_iso_arte` (3/3) e `test_iso_pele` (3/3) passam;
  - o **b25_funcoes** falhou uma vez por um machucado sorteado e passou ao repetir.
- **Fotos:** `docs/arte/bloco96/`:
  - `obra_levando` — o engenheiro com a carga;
  - `obra_pilha` — a entrega "+10 madeira", a tora na cabeça e a pilha de tábuas ao lado;
  - `obra_gaveta` — entregue/necessário e o Cancelar.

  Saem do `tests/capturas_bloco96.gd`.

## O que precisa do Marco

1. Escolher (ou não) um dos ajustes de balanceamento acima. O 10 por viagem deixa a escavadeira muito longa.
2. Jogar uma obra do começo ao fim e ver se o vai-e-vem tem a cara que ele quer.
3. Push só com o OK dele.
