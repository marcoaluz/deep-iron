# Bloco 94 — a cadeia de produção fechada: Carpintaria, carpinteiro e os usos de pregos, aço e couro

Data: 2026-10-07. Branch `isometrico`. Teste: `b94_carpintaria`.

**O pedido do Marco:** fechar a cadeia de produção, dando uso ao que já se fabrica mas só servia para vender.
- **Carpintaria** nova: obra em etapas e arte do PixelLab.
- **Carpinteiro/carpinteira:** receita completa do elenco.
- **Usos:** pregos e ferragens na casa 3, na barricada 3 e na ferrovia; aço na picareta de aço, na lança de prata e
  nas bobinas; couro nas botas e na mochila; camas melhores.
- **Antes de tudo,** uma tabela de custo atual x novo para aprovação.

**A aprovação:**
- A tabela foi mostrada e o Marco aprovou.
- **"Botas anulam lentidão na neve, pode criar"**: a lentidão na neve não existia e foi criada.
- **"Picareta: sim, pode ficar"**: a solução "temperada + de aço nova", explicada abaixo.

**Skills usadas:**
- `godot-gdscript`
- `survival-crafting` (a escada da cadeia)
- `save-systems`
- `godot-gdscript-headless-testing`
- `deep-iron-arte` (contrato de arte)

## A picareta (o porquê da mudança)

A "picareta de aço" de antes custava **ferro**, não cobre: é ela que libera o cobre. Pedir aço nela trancaria o jogo
em círculo: aço ← carvão ← lampião ← cobre ← picareta.

- **A de antes passou a se chamar "Picareta temperada".** O id `picareta_aco` ficou, então save e testes não mudam.
  Continua liberando o cobre e custando o mesmo.
- **"Picareta de aço" nova** (`picareta_de_aco`):
  - liberada no estágio 3;
  - custa 400 cr + 20 madeira + **12 aço** (40 s de ferreiro);
  - dá **+25% de minério por golpe** a todos os mineradores (`oficina.picareta_aco_mult`).

## Custos: o que mudou

**Regra para não travar:** pregos e ferragens só entram no custo **a partir do estágio da fornalha**. Antes disso, cada
peça vira o ferro equivalente: 1 prego = 0,34 ferro e 1 ferragem = 6,7 ferro (`Economy.ferro_por_prego` e
`Economy.ferro_por_ferragem`). Tudo isso fica em `Economy.itens_efetivos`.

| Item | Antes | Agora |
|---|---|---|
| Casa nível 3 | 420 cr + 90 ferro + 70 madeira | 420 cr + **70 ferro** + 70 madeira + **24 pregos + 2 ferragens** |
| Barricada nível 3 (com fornalha) | 500 cr + 100 barras + 30 madeira | 500 cr + **85 barras** + 30 madeira + **12 pregos + 4 ferragens** (antes da fornalha: 205 ferro) |
| Ferrovia S2 / S3 / S4 / S5 | 600/750/900/1050 cr + 120/150/180/210 ferro **bruto** + madeira | mesmos cr e madeira + **45/58/70/83 barras** + **30/36/42/48 pregos + 2/3/4/5 ferragens** |
| Picareta temperada | 310 cr + 150 ferro + 30 madeira | igual (só o nome) |
| Picareta de aço (nova) | — | 400 cr + 20 madeira + **12 aço**, estágio 3 |
| Lança de prata | 600 cr + 30 barras de prata + 20 madeira | 600 cr + **24 barras de prata + 6 aço** + 20 madeira (conserto: 3 aço) |
| Escudo: Bobinas | 900 cr + 150 cobre + 80 prata | 900 cr + **110 cobre** + 80 prata + **20 aço** |
| Botas (novas) | — | 20 cr + 2 couro + 4 pregos (vestiário, gastam como o casaco) |
| Mochila (nova) | — | 3 couro + 2 pregos (encomenda do ferreiro); não gasta |
| Carpintaria (prédio) | — | 220 cr + 40 ferro + 90 madeira, 45 s de engenheiro, estágio 2 |
| Tábuas | — | 3 madeira → 4 tábuas (8 s) |
| Cama de tábua | — | 6 tábuas + 8 pregos → 1 cama (20 s) |

**Mudanças em relação à tabela aprovada:**
- **A mochila ficou sem os 40 cr.** A fila de encomendas (`production_queue.gd`) só cobra itens. Para cobrar
  crédito seria preciso um caminho só para ela, então ficou mais barata.
- **A ferrovia antes cobrava ferro bruto**, mesmo com fornalha. Agora segue a regra das barras do Bloco 87, como a
  tabela previa.

Os números são `@export` e estão listados em `docs/BALANCEAMENTO.md`:
- `casa.upgrade_ore/upgrade_pregos/upgrade_ferragens`;
- `barricada.upgrade_costs/upgrade_itens`;
- `centro_vila.ferrovia_*`;
- `oficina.tool_*`, `tool_itens`, `picareta_aco_mult`;
- `defense.weapon_costs/weapon_itens`;
- `escudo.stage_costs/stage_itens`;
- `equipment.botas_*`, `neve_speed_mult`;
- `ipezinho.mochila_carga`;
- `casa.conforto_cama_boa/cama_segundos`;
- `carpintaria.receitas_carpintaria`.

## A Carpintaria e o carpinteiro

**O prédio:**
- `carpintaria.gd` é a oficina de ordens da Fornalha com outro ofício. A `fornalha.gd` ganhou variáveis para
  isso: grupo, operador, estado de trabalho e nomes. O resto é igual:
  - só por ORDEM;
  - quantidade escolhida pelo jogador;
  - insumo pago quando a unidade começa;
  - pausa com aviso se falta insumo;
  - cancelar devolve.
- A janela `carpintaria_panel.gd` também herda da janela da Fornalha.
- Fica na aba **Produção** do CONSTRUIR, no estágio 2. É posicionada pelo jogador e erguida pelo engenheiro em
  etapas: canteiro `carpintaria`, obra 1 → 2 → 3 → pronto na vista iso.

**Carpinteiro / carpinteira:**
- Função **[9]** na barra (15 botões; cada um foi para 78 px). Vale para homem e mulher.
- Busca os insumos no armazém, serra na carpintaria e leva o que ficou pronto para o armazém.
- **Antes das ordens**, monta as camas que o jogador mandou trocar.

**Camas de tábua:**
- Na janela da casa, o botão **"Trocar uma cama"**:
  - a cama de tábua sai do armazém na hora;
  - o carpinteiro vai até a porta e monta (12 s);
  - **quem dorme numa cama de tábua ganha +3 de ânimo** (fator "cama de tábua").
- As camas de tábua são as primeiras da casa.

**Mochila:**
- O minerador sem mochila pega uma quando entrega no armazém.
- Com ela, carrega **16 → 20** por viagem (`capacidade_carga()`).

**Botas e neve:**
- As botas são um tipo novo do vestiário (`equipment.gd`). O ferreiro as faz na fila de equipamento.
- No inverno, cada um pega um par sozinho, como o casaco. As botas gastam só andando na neve.
- Quem anda **sem botas no inverno, na superfície**, vai a **85%** da velocidade.

**Itens novos no catálogo:**
- **tábua** (madeira, 2 cr);
- **cama de tábua** (equipamento, 30 cr);
- **mochila de couro** (equipamento, 15 cr).

A seção "Equipamento" do armazém passa a aparecer.

**A janela da Oficina** agora mostra o ícone de cada ferramenta e equipamento. Os ícones das ferramentas já
existiam e não eram usados.

## Arte (PixelLab, regra 11)

**Carpinteiro e carpinteira** (`prototipos/camera/arte_iso/oficios94.py`, que reaproveita o `oficios92.py`):
1. **Candidatos:** 16 de cada. O primeiro piloto saiu "mineiro": o modelo copiou a referência. Foi refeito com
   "NOT a miner: NO helmet…". Escolhidos: c08 (ele) e c04 (ela).
2. **Personagem v3** "high top-down".
3. **Caminhada:** 8 quadros, skeleton-v3, ajustada (`caminhadas8 baixa/troca`, pé no chão).
4. **Comer, ferido, deitar e mancar.**
5. **Serrar:**
   - A 1ª leva saiu com o serrote quase invisível. Foi refeita com uma descrição literal (`REFAZ["serrar"]`).
   - A da carpinteira foi refeita mais uma vez.
   - O zip do personagem traz também o estado do casaco, com o mesmo nome. Por isso o trabalho é extraído com
     `estado=Idle`.
6. **Casaco de inverno:** caminhada + serrar. O 1º pedido do serrar de casaco foi com `{he}` sem troca. Foi
   corrigido e refeito (`refaz_casaco`).
7. **Retrato com as 5 expressões:**
   - Nota por personagem no `retratos.py`: o bigode dele e o lenço dela.
   - Seis expressões foram refeitas porque o bigode sumia e o lenço mudava de cor.
   - A carpinteira "contente" insistia num pano no pescoço. Ganhou a faixa de baixo (pescoço e camisa) do
     retrato neutro, colada a partir da linha 34.
8. **Ícone da barra:** um serrote.

**Carpintaria** (`predios94.py`):
- Guia 2:1 desenhada localmente: mesmas linhas do `predio.py guia`, caixa 120 × 90 × 80.
- **Pronto:** a oficina e a casa aprovadas + o minerador como referência.
- **Obra 2** (esqueleto no mesmo quadro); **obra 1 e 3** pelo `obras.py`.
- `integra.py predios carpintaria`.
- O desenho do mapa antigo (`assets/game/carpintaria.png`) e o cartão do CONSTRUIR são o pronto reduzido.

**Ícones de itens:** tábua, cama de tábua, mochila, botas e picareta de aço. Carpinteiro, cama e mochila foram
refeitos com descrições mais simples: a 1ª leva trouxe ícones genéricos.

**Cuidados na integração:**
- `integra.py bonecos carpinteiro` só **acrescentou** ao `bonecos.json`.
- O passo `contorno` do `integra.py predios` regravou caminhadas de casaco de outras funções. Elas foram
  devolvidas (`git checkout`). **Atenção para a próxima vez.**

**Gasto:** 485 gerações (7.722 → 7.237). A estimativa era ~400; a diferença são as refações do serrar, das
expressões e dos ícones.

**Fotos** em `docs/arte/bloco94/`, geradas por `tests/capturas_bloco94.gd`:
- obra 1, 2 e 3 e pronta;
- carpinteiros serrando, de longe e de perto;
- janela da carpintaria;
- janela da casa;
- barra de funções;
- prancha da obra;
- prancha dos retratos.

## Save

- **Chaves novas** (documentadas no cabeçalho do `save_manager.gd`):
  - `village.carpintarias` (lugar + fila);
  - `casa.camas_boas` e `camas_pedidas`;
  - `ipezinho.mochila`;
  - `wearing.botas`;
  - `equipment.pool/broken.botas`.
- **Save antigo:** nada disso existe e tudo carrega com o padrão (sem carpintaria, sem cama de tábua, sem mochila,
  sem botas).
- **O que já foi feito ou pago continua valendo:** lança de prata, bobinas, casas e barricadas nível 3,
  ferrovias e picareta. Os custos novos valem só para o que for encomendado depois.

## Testes

**`b94_carpintaria` (novo, 0 falhas):**
- a arte (predios.json, bonecos.json, retratos, ícones);
- construir;
- homem e mulher;
- sem ordem, nada;
- tábuas: 8 tábuas por 6 madeira;
- cama pausada sem pregos e feita quando eles chegam;
- trocar a cama da casa: o carpinteiro monta e o ânimo sobe;
- barricada antes e depois da fornalha;
- casa 3 e ferrovia;
- picareta de aço, lança e bobinas;
- botas e neve;
- mochila;
- save/load e save antigo.

**Ajustados:**
- `b56_casas`: dá pregos e ferragens para o nível 3;
- `b54_configuracoes`: a tecla "livre" do teste era o 9, agora do carpinteiro; virou o ponto;
- `b82_itens_armazem`: a seção Equipamento agora aparece.

**Passaram depois das mudanças:** b31, b31b, b35, b36, b39, b40, b42, b47, b54, b56, b57, b58, b64, b79, b82, b84,
b86, b87, b88, b92, b93, p2, p29_bonecos, p29_predios e hud_frostpunk.

**Bateria inteira (2026-10-07, um teste por vez, APPDATA isolado):** os 77 testes de `tests/blocos`, inclusive o
`b51` (353 s), com 0 falhas; GUT `test_iso` 6/6, `test_iso_arte` 3/3 e `test_iso_pele` 3/3. O `b94` falhava quando os
ipezinhos do começo saíam todos mulheres (o gênero é sorteado): o teste agora força o gênero que faltar (`5bd05115`).
