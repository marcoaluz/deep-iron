# Bloco 96 — Obras com material levado pelo engenheiro (PLANO, esperando aprovação do Marco)

Pedido: o "Prompt O". O próximo número livre é o 96 (o roteiro do guia, que punha a dificuldade no 96, anda mais um).

## Como é hoje

- Toda obra cobra **créditos + material de uma vez, na encomenda**, por `Economy.spend`, `paga_metal` e
  `paga_itens`. O material sai do armazém na hora.
- O engenheiro só gasta **tempo** no lugar (`obra_work(segundos)`), e o progresso é `1 - left/total`.
- Os estágios do desenho (fundação 0–33%, paredes 33–66%, prédio cru 66–100%) seguem esse progresso
  (`obra_estagio.gd`).
- **Não existe "cancelar obra"** hoje, em nenhum tipo (só a fila da Fornalha e da Oficina tem cancelar).
- Distância típica entre o armazém (800, 40) e a vila (Centro em 40, -190): ~700–800 px. O ipezinho anda a
  120 px/s, então uma ida e volta leva **~12–13 s** (a 1x) mais o tempo de pegar e entregar.

## Tabela: tudo que cobra material na encomenda

Custo da 1ª unidade, numa partida nova (texto do próprio jogo). "Viagens" = unidades de material dividido pelo
limite de carga (10 / 20).

| # | Obra (onde é cobrada) | Quem faz | Cobra hoje | Material | Viagens 10 / 20 | Proposta |
|---|---|---|---|---|---|---|
| 1 | Casa nova (Moradias) — `centro_vila._confirm_house` | engenheiro | 190 cr + 40 ferro + 20 madeira | 60 | 6 / 3 | **com material** |
| 2 | Casa inicial — `centro_vila._confirm_starter_house` | engenheiro | 80 cr + 20 ferro + 15 madeira | 35 | 4 / 2 | **com material** |
| 3 | Casa nível 2 / 3 — `casa.start_upgrade` | engenheiro | 220 cr + 40 ferro + 40 madeira / 420 cr + 70 + 70 + pregos | 80 / 140+ | 8 / 4 · 14 / 7 | **com material** |
| 4 | Cozinha — `_confirm_comedouro` (canteiro) | engenheiro | 100 cr + 20 ferro + 25 madeira | 45 | 5 / 3 | **com material** |
| 5 | Nova enfermaria — `_confirm_enfermaria` (canteiro) | engenheiro | 200 cr + 40 ferro + 60 madeira | 100 | 10 / 5 | **com material** |
| 6 | Melhorias do Centro (ampliar enfermaria, trilhas) — `buy_upgrade` | engenheiro | 125–150 cr + 25 minério (qualquer) | 25 | 3 / 2 | **com material** (o minério mais barato, como hoje) |
| 7 | Expandir a vila — `level_up` | engenheiro | só créditos (190 cr) | 0 | — | **sem material** (não há o que levar) |
| 8 | Taverna / Ampliar taverna — `morale` (canteiro) | engenheiro | 120 cr + 40 madeira / 350 cr + 60 madeira + 40 ferro | 40 / 100 | 4 / 2 · 10 / 5 | **com material** |
| 9 | Parque — `morale._confirm_park` (canteiro) | engenheiro | 100 cr + 20 ferro + 40 madeira | 60 | 6 / 3 | **com material** |
| 10 | Laboratório — `research._confirm_lab` (canteiro) | engenheiro | 300 cr + 80 ferro + 60 madeira | 140 | 14 / 7 | **com material** |
| 11 | Arsenal / Campo de treino — `defense` (canteiro) | engenheiro | 150 cr + 40 ferro + 60 madeira / 120 cr + 50 madeira | 100 / 50 | 10 / 5 · 5 / 3 | **com material** |
| 12 | Vestiário — `equipment._confirm_vestiario` (canteiro) | engenheiro | 120 cr + 30 ferro + 50 madeira | 80 | 8 / 4 | **com material** |
| 13 | Ventilador (no S2) — `fundo._confirm_ventilador` (canteiro) | engenheiro | 400 cr + 60 prata + 40 madeira | 100 | 10 / 5 | **com material** (viagem longa: desce pelo elevador) |
| 14 | Oficina (quando não existe) — `_confirm_oficina` (canteiro) | engenheiro | 200 cr + 40 ferro + 60 madeira | 100 | 10 / 5 | **com material** |
| 15 | Coletor de madeira / de minério — `_confirm_coletor*` (canteiro) | engenheiro | 250–280 cr + 40–60 ferro + 60 madeira | 100–120 | 10–12 / 5–6 | **com material** |
| 16 | Fornalha / Carpintaria — `_confirm_fornalha/_carpintaria` (canteiro) | engenheiro | 180 cr + 50 ferro / 220 cr + 40 ferro + 90 madeira | 50 / 130 | 5 / 3 · 13 / 7 | **com material** |
| 17 | Trilho e vagonete — `_confirm_vagonete` (canteiro) | engenheiro | 260 cr + 80 ferro + 80 madeira | 160 | 16 / 8 | **com material** |
| 18 | Ferrovia de carga (por andar) — `build_ferrovia` (canteiro) | engenheiro | 600 cr + 114 ferro + 140 madeira (+ pregos/ferragens depois da fornalha) | 254+ | 26 / 13 | **com material** (o andar é longe: o mais demorado) |
| 19 | Igreja — `_confirm_igreja` (canteiro) | engenheiro | 220 cr + 40 ferro + 80 madeira | 120 | 12 / 6 | **com material** |
| 20 | Cemitério (por tamanho) — `_confirm_cemiterio` | engenheiro (etapas) | 3×3: 64 cr + 16 ferro + 48 madeira | ~64 | 7 / 4 | **com material** |
| 21 | Desbravar o leste — `desbravar_leste` (canteiro) | engenheiro | 900 cr + 120 ferro + 160 madeira | 280 | 28 / 14 | **com material** |
| 22 | Coletor em ruína (etapas) — `coletor_madeira.pedir_etapa` | engenheiro | 30 madeira / 45 ferro / 180 cr + 50 ferro | 30–50 | 3–5 / 2–3 | **com material** |
| 23 | Peças da escavadeira — `escavadeira.start_part` | engenheiro | 500–1500 cr + **190–625 minério** | 190–625 | **19–63** / 10–32 | **com material** (o maior peso: ver a decisão 1) |
| 24 | Reatores da escavadeira — `build_reactor` | engenheiro | 200–800 cr + 0–150 ferro + peças raras | 0–150 | 0–15 / 0–8 | **com material** (as peças raras continuam cobradas na hora: não ficam no armazém) |
| 25 | Etapas do escudo solar — `escudo.start_stage` | engenheiro | 600–2000 cr + 200 ferro + 100 madeira / 110 cobre + 80 prata + 20 aço / 150 solarita (+ 15 peças raras) / 100 prata + 100 solarita | 150–300 | 15–30 / 8–15 | **com material** |
| 26 | Barricada: subir de nível / consertar — `barricada.upgrade/repair` | **ninguém** (é na hora) | barras + itens / madeira | — | — | **fica como está** (não é obra de engenheiro hoje; virar obra muda a defesa) |
| 27 | Conserto do elevador do abismo — `abyss_shaft.start_repair` | **ninguém** (relógio próprio) | créditos + prata + peças | — | — | **fica como está** (pergunta 4) |
| 28 | Conserto do robô — `robo.start_repair` | **ninguém** (relógio próprio) | créditos + ferro + peças | — | — | **fica como está** (pergunta 4) |
| 29 | Conserto do trilho quebrado — `estacao_vagonete` | engenheiro | **nada** (só tempo) | 0 | — | **sem material** (conserto pequeno: não cobra nada hoje) |
| 30 | Ferramentas da Oficina, forja e conserto de armas, equipamento — `oficina/defense/equipment` | **ferreiro** | créditos + metal + itens | — | — | **fica como está** (é produção: fila do ferreiro) |
| 31 | Pesquisa, dinamite, festa | — | créditos + minério | — | — | fica como está (não é obra) |
| 32 | Decoração, caminhos, filas da Fornalha/Carpintaria | — | — | — | — | fica como está (pedido) |

## Como vai funcionar

1. **Encomenda.**
   - Os créditos saem na hora, como hoje.
   - O material vira uma **lista** na obra ({ferro: 40, madeira: 20}), com o tipo resolvido na hora:
     - "minério qualquer" vira o mais barato, como o `spend` já faz;
     - antes da fornalha o metal é minério, depois vira barras;
     - pregos e ferragens antes da fornalha viram ferro.
   - O material fica **reservado**: continua no armazém, mas não conta como livre.
   - A encomenda exige estoque **livre** suficiente.
   - **Como:** um modo de encomenda na `Economy`. As funções de sempre (`spend`, `paga_metal`, `paga_itens`)
     cobram os créditos e **anotam** o material em vez de tirar. São ~3 linhas em cada ponto da tabela; nenhum
     custo é recalculado.
2. **Reserva.**
   - `Economy.livre(item) = no armazém − reservado`.
   - O reservado é **calculado a partir das obras** (necessário − entregue − nas mãos), então não entra no save.
   - Os testes de custo (`can_afford`, `missing_text`, `metal_falta`, `itens_falta`) olham o livre.
   - O **vender** (tudo, por item e o "auto") **não vende o reservado**.
   - As filas da Fornalha e da Carpintaria também não usam o reservado.
3. **Viagens do engenheiro.** Enquanto a obra pede material:
   - ele vai ao **armazém mais perto que tem o item**;
   - pega até `carga_material` (`@export`, limite por viagem);
   - leva, entrega e volta.
   - **Vários engenheiros:** cada viagem "reserva" o que vai pegar (`a_caminho` na obra), então ninguém pega o
     mesmo item duas vezes.
   - **Carga no corpo:** o ícone de carga que já existe (`_carry_icon`) — a tora pra madeira, a pedra do minério
     pro minério, o ícone do item pras barras, tábuas e pregos. Na vista iso ele cresce com a quantidade, como o
     do minerador.
4. **Progresso limitado ao entregue.**
   - O engenheiro só trabalha até `progresso ≤ entregue / necessário`. Os estágios (fundação, paredes, prédio
     cru) vêm conforme o material chega.
   - Com a parte liberada feita, ele volta a buscar.
   - Vale pra todo tipo de obra pelo `ObraSite`: um limite no `obra_work` do engenheiro, sem mexer em cada prédio.
   - Obra sem material (Expandir, trilho quebrado) funciona como hoje.
5. **Visual e textos.**
   - **Pilha ao lado da obra** com o que foi entregue e ainda não usado: diminui conforme a obra anda e muda de
     tamanho (P/M/G). É feita com **as pilhas que já existem no jogo** (pedra, tábuas, aço, carvão, caixote), sem
     arte nova.
   - **Estado da obra:** "esperando engenheiro" / "buscando material" / "levando N/M" / "falta material no
     armazém" / "construindo". Aparece no rótulo do mapa (o inteiro, ao passar o mouse), na gaveta Obras do HUD,
     com **entregue/necessário por item**, e nas janelas que já mostram a obra (casa, Centro, coletor,
     escavadeira, escudo), porque elas usam o `ObraSite.status`.
   - **Texto do engenheiro:** "buscando 10 madeira (Taverna)" / "levando 10 madeira pra Taverna (20/40)" /
     "construindo: Taverna (45%)".
6. **Cancelar** (não existe hoje).
   - Um botão "Cancelar" na gaveta Obras e na janela de cada obra.
   - Devolve ao armazém o **já entregue** e o que estiver **nas mãos**; o reservado só deixa de ser reservado.
   - O dono da obra desfaz a encomenda (ex.: a casa nova some e a Moradias volta um nível).
7. **Save.**
   - A lista, o entregue e o `a_caminho` entram no `ObraSite.get_save_data()`, que toda obra já salva no campo
     "obra".
   - **Save antigo** (sem a lista): conta como **tudo entregue**. A obra anda como antes.
   - O material nas mãos de um engenheiro volta ao armazém ao carregar (assim nada se perde nem duplica).
   - A chave nova é documentada no cabeçalho do `save_manager.gd`.
8. **Chave geral.** `@export var obras_com_material := true` na `Economy`. Com ela desligada, tudo é como hoje.
   Serve pra medir o antes e o depois e de garantia.

## Balanceamento (item 7)

- A telemetria **não mede obra hoje**. Ela ganha 2 colunas por dia: obras concluídas e tempo médio da
  encomenda ao pronto.
- Um teste de medida (`tests/bench_obras.gd`) roda as mesmas obras com a chave desligada e ligada, com 1 e 2
  engenheiros, e dá o tempo médio de cada uma: taverna, casa, laboratório, uma peça da escavadeira.
- **Estimativa antes de medir,** com 1 engenheiro e o limite de 10:

  | Obra | Hoje | Com material |
  |---|---|---|
  | Taverna | 30 s | ~80 s (2,7x) |
  | Casa | 35 s | ~110 s (3x) |
  | Laboratório | — | ~4x |
  | Broca da escavadeira (625 minério) | 90 s | ~13 min |

  **Com 20:** mais ou menos metade da caminhada.
- O relatório traz os números medidos e uma proposta (limite, velocidade de quem carrega). Eu **não aplico**
  sozinho.

## Testes

`tests/blocos/b96_obras_material.gd`:
- encomenda: reserva sem tirar e exige estoque livre;
- vender não vende o reservado;
- viagens com o limite (o engenheiro pega no máximo N por vez, do armazém mais perto com estoque);
- progresso travado no entregue, com os estágios seguindo;
- dois engenheiros sem pegar o mesmo item;
- cancelar devolve;
- save no meio e save antigo (tudo entregue);
- obra sem material (Expandir) igual a hoje.

Ajuste dos testes antigos que terminam obra "na mão" ou contam o estoque logo depois da encomenda: b31, b31b,
b37, b45, b47, b51, b56, b57, b58, b64, b79, b81, b86, b88, b93, b94 e outros (lista exata no relatório). A
maioria só precisa do helper "entrega tudo" antes de `obra_work`.

## Decisões do Marco

1. **Limite de carga padrão:** 10 (como no pedido) ou 20? A escavadeira e a ferrovia ficam muito longas com
   10 (63 e 26 viagens).
2. **Cancelar devolve os créditos também?** A minha proposta é sim, por inteiro, como já é na fila da Fornalha.
3. **Cancelar em todas as obras** (canteiros, casas, melhorias do Centro, etapas do coletor e do escudo, peças
   da escavadeira, cemitério)? A minha proposta é sim.
4. **Barricada, conserto do elevador do abismo e conserto do robô** ficam como estão (não são obras de
   engenheiro hoje)? A minha proposta é sim.
5. A **fonte do Bloco 95** continua esperando a escolha.
