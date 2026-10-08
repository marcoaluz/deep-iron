# Bloco 99 — Entrada da mina, elevador, escadas e vagonete (PLANO, esperando aprovação do Marco)

Pedido: o "Prompt Q". Antes de codar: a auditoria de como os ipezinhos descem hoje, as opções e a recomendação.

Fotos da auditoria: `docs/arte/bloco99/auditoria/` (`antes_01` a `antes_08`). Medição: `tests/bench_minerio.gd`.

## 1. Auditoria: como é hoje

| Peça | O que faz hoje | Onde |
|---|---|---|
| **Elevador do S2** (`deep_shaft.gd`, nó `Elevador`) | Uma ligação de navegação (`NavigationLink2D`) da superfície (580,320) até o S2. Abre quando a **escavadeira** fica pronta. O ipezinho chega na gaiola, some, espera `1,6 s × (fila)` (4 por viagem) e aparece lá embaixo. **Não tem cabine andando, nem quebra, nem conserto.** O desenho em cima é a torre (`elevador` ruína/pronto) e embaixo a gaiola parada (`antes_04`, `antes_07`). | superfície ↔ S2 |
| **Plataformas S3, S4, S5** (`abyss_shaft.gd`) | O mesmo esquema de ligação. Começam em ruína; o conserto é obra de engenheiro com material (Bloco 96). Também não têm cabine andando nem quebra por uso. | S2 ↔ S3 ↔ S4 ↔ S5 |
| **Escada em espiral** | **Só desenho.** A espiral na coluna dos andares (`andares.json` "espiral") e a casinha "boca_espiral" na superfície (744,320). Ninguém anda nela (`antes_06`, `antes_07`). | coluna |
| **Escadas da montanha** (`mapa.json` "escadas", 2 de 12 tiles) | **Funcionam**: são rampas na navegação, sobem os degraus 6/12/18 até as galerias. | montanha da mina |
| **Escadas de mão e andaime** (`escada_mao` ×3, `andaime`) | **Só decoração**, encostadas no paredão e no S1. Parecem um caminho, mas não são (`antes_01`, `antes_02`). | paredão, S1 |
| **Bocas da mina** (`mapa.json` "bocas", 5) | Buracos desenhados na montanha. As 4 de cima têm uma **galeria** cada (uma jazida na porta: oeste, sudeste, norte e nordeste, que abrem com o estágio da vila). O mineiro minera **parado na porta, do lado de fora**. **A boca principal (882,-165) não tem jazida**: é só onde fica o vagonete. | montanha |
| **Vagonete da boca** (`estacao_vagonete.gd`, "EstacaoMina") | Um ponto de carga fixo na frente da boca principal, com o trilho reto até o armazém. O mineiro só entrega ali **se for mais perto que o armazém**. O carrinho leva 25 por viagem, guarda 60 e espera 8 s. O trilho quebra a cada 25 viagens e o engenheiro conserta (obra sem material). | boca → armazém |
| **Ferrovia de carga S2–S5** (Bloco 79) | O mesmo ponto, com a subida pelo cavalete da coluna. Lá embaixo o ponto sempre fica mais perto que o armazém, então os mineiros de lá **já entregam nele e não sobem**. | andares |
| **Guindaste** | `guindaste_pedreira` é decoração no 2º degrau. Os vagonetes que o jogador constrói usam o desenho do guindaste; o da boca o esconde. | montanha |
| **Área de mina** (`work_areas.gd`) | Precisa ser ligada. Desligada, para o carrinho dela e ninguém minera ali. | — |

### A medição de hoje (5 mineradores, 4 h de jogo, partida nova)

| Cenário | Vagonete | Minério que entrou no armazém | Minerado (inclui o que ficou no caminho) | O vagonete levou |
|---|---|---|---|---|
| Pedreira (as jazidas soltas perto da vila) | parado | **175/h** | 184/h | 0 |
| Pedreira | ligado | **158/h** | 181/h | 150 (6 viagens) |
| Galerias da montanha (vila no estágio 5, área de mina com 5) | parado | **89/h** | 105/h | 0 |
| Galerias da montanha | ligado | **87/h** | 106/h | 150 (6 viagens) |

O que isso mostra:
- **O vagonete quase não muda a produção** (~0 a −10%). Ele leva no máximo ~37/h (25 por viagem, 6 viagens em 4 h), a maioria vai na mão, e o que fica parado no ponto e no carrinho até atrasa a entrada no armazém.
- **Nas galerias se produz metade da pedreira**: o tempo vai na caminhada até o armazém (subir e descer os degraus).
- **Ninguém entra na mina.** Os mineiros ficam na porta das galerias, e a boca principal, a do trilho, está vazia.

## 2. As propostas

### A) Elevador e escadas

**Recomendação (a do prompt): o ELEVADOR é a entrada principal, restaurável por etapas; a espiral é a rota lenta de emergência.**

1. **Restauração por etapas**, no padrão da ruína do coletor (Bloco 81): obra de engenheiro, com o material levado por ele
   (Bloco 96). A obra aparece no desenho: ruína → obra 1 → 2 → 3 → pronto.
   1. **Limpar o poço** (madeira).
   2. **Guincho e cabos** (ferro, em barras a partir da fornalha).
   3. **A cabine** (ferro, madeira e pregos).
2. **A viagem de verdade.**
   - Quem chega entra na **fila** (lugares visíveis na frente da gaiola).
   - A cabine leva até `capacidade` (4, `@export`), **anda pelo poço** com velocidade `@export` (a vista iso mostra a cabine
     descendo a coluna) e desembarca no andar de destino.
   - Lá embaixo, quem quer subir espera a cabine voltar.
3. **Quebra por uso:** depois de `viagens_ate_quebrar` viagens (~60), o cabo gasta. O elevador para e vira obra de conserto
   (engenheiro, com material).
4. **A espiral vira caminho de verdade, LENTO:** uma ligação com custo alto e travessia demorada (~20 s por andar, `@export`).
   - O caminho escolhe o elevador sempre que ele funciona. Com o elevador quebrado, sai pela espiral: **ninguém fica preso
     embaixo sem comida.**
   - O ipezinho entra na casinha da espiral, some e aparece no patamar do andar.
5. **Vale para as plataformas S3, S4 e S5:** a mesma cabine, fila, quebra e conserto. A espiral segue até o S5.
6. **Sai do mapa:** as 3 escadas de mão (`escada_mao`) e o andaime do paredão, que parecem caminho e não são. As rampas da
   montanha **ficam**: elas funcionam.

| Prós | Contras |
|---|---|
| Uma entrada clara e visível; a descida vira um sistema (fila, cabine, quebra) | Mais uma obra no caminho do S2: o jogo fica um pouco mais longo |
| A espiral deixa de ser enfeite e resolve o "preso embaixo" | A fila pode virar gargalo com muita gente (a capacidade e a velocidade são `@export`) |
| O engenheiro ganha trabalho de manutenção | Os testes de andares (b68, b71, b73, b79) precisam ser ajustados |

**Decisão 1:** a restauração do elevador vem **depois** da escavadeira (ela fura, e então se restaura a cabine), ou **em
paralelo** (as duas abrem o S2)? Eu recomendo **em paralelo**: a escavadeira continua sendo o que abre o S2, a restauração
pode começar antes, e assim o jogo não fica mais longo.

### B) Mineradores dentro da mina com o vagonete

1. **Quando entra:** com a **área de mina ligada**, o trilho inteiro e o vagonete funcionando.
   - O mineiro da área **entra pela boca** e some do mundo.
   - Na boca aparece **"dentro da mina N/5"**, com brilho de lanterna e o som da picareta.
2. **A boca principal ganha a galeria dela**, a de dentro. Os mineiros lá dentro tiram da **jazida das galerias da área**,
   então a jazida acaba e se recompõe como hoje (nada de minério infinito).
3. **O ritmo lá dentro** é `@export` por mineiro e por hora. Para manter a renda: **o mesmo de hoje nas galerias, ~21 por
   mineiro por hora**. Lá dentro ninguém caminha, mas o rendimento é calibrado pra dar o mesmo total (a parte C).
4. **O vagonete com cargas grandes:**
   - **100 por viagem** (`@export`, era 25);
   - ponto que guarda 240 (era 60);
   - espera até 60 s pra juntar (era 8 s);
   - o carrinho cheio, com a pilha, fica visível no trilho.
5. **Desgaste coerente:** o trilho gasta **por minério levado** (hoje, 25 viagens × 25 = 625), não por viagem. Com 100 por
   viagem, quebra a cada ~6 viagens: **o mesmo desgaste por minério**.
6. **Acidentes lá dentro:** a mesma chance por segundo minerando. Quem se machuca sai pela boca ferido (vai pra enfermaria).
7. **Quando saem:** só nas refeições, no fim do expediente e nas emergências da agenda (onda solar, invasão, greve). Saem pela
   boca e voltam.
8. **Sem trilho, com o vagonete quebrado ou o ponto cheio:** tudo como hoje (o mineiro sai e carrega na mão). Nada trava.
9. **Ferrovia S2–S5:** as mesmas cargas grandes e o mesmo desgaste por minério. Lá não tem boca: os mineiros já ficam
   embaixo e entregam no ponto da ferrovia; só sobem pras refeições e pro fim do expediente.

**Decisão 2:** o rendimento lá dentro fica **igual ao de hoje (renda igual)**? Ou um pouco maior (+15%), como prêmio por ter
o trilho? Pelo prompt, qualquer ajuste só depois da sua aprovação: proponho **igual**.

### C) A produção antes e depois

- O `bench_minerio.gd` mede os 4 cenários da tabela acima, antes e depois.
- A meta é **a mesma renda**: as galerias com vagonete ficarem em ~105/h, e a pedreira continuar em ~180/h, porque não
  muda.
- Os números entram no relatório. A telemetria do jogo (`telemetria.gd`) também passa a registrar o minério que entrou por
  dia; o resumo sai em `tools/resumo_telemetria.py`.

## 3. Arte (PixelLab, regra 11)

| Peça | O quê | Gerações (estimativa) |
|---|---|---|
| Elevador (a torre na superfície) | obra 1, 2 e 3 a partir da ruína e do pronto que já existem | ~120 |
| Cabine | a gaiola andando: porta aberta e fechada, vazia e com gente (o desenho de cima e o de baixo) | ~100 |
| Guindaste / guincho | a roda girando (4 quadros) em cima da torre, quando a cabine anda | ~120 |
| Boca da mina "trabalhando" | o batente com a lanterna acesa e o brilho de dentro (a vista desenha o "N/5") | ~60 |
| Carrinho com carga grande | o vagonete cheio de minério (a pilha alta) | ~40 |
| Casinha da espiral | já existe (`boca_espiral`): fica | 0 |
| **Total** | piloto antes de cada lote | **~440** (saldo 6.547) |

## 4. Save, testes e o que muda

- **Save** (`save_manager.gd` + `save_util.gd`):
  - o elevador ganha a etapa da restauração, as viagens até quebrar e a obra;
  - a mina, quem está dentro;
  - o vagonete, a carga nova.
  - **Save antigo:** o elevador do S2 já aberto vem **restaurado e inteiro**. Ninguém perde o acesso, e quem já tinha o S2
    continua lá. Quem estava "dentro" volta pra porta.
- **Teste novo `b99_mina_elevador`:**
  - a restauração por etapas;
  - a fila, a cabine e o desembarque no andar certo;
  - a quebra e o conserto;
  - a espiral quando o elevador quebra (ninguém preso embaixo);
  - o mineiro entrando e saindo pela boca (nas refeições e no fim do expediente);
  - o "N/5", o buffer e a carga de 100;
  - o desgaste por minério;
  - sem trilho, tudo como hoje;
  - o save antigo.
- **Testes antigos a ajustar:** b64 (vagonete), b77 (áreas), b79 (ferrovia), b68, b71 e b73 (andares e ligações), b74 (a
  montanha).
- **Rodar tudo um por vez** com o APPDATA isolado.

## 5. As decisões do Marco

1. **A)** A restauração do elevador em **paralelo** à escavadeira (recomendo) ou **depois** dela?
2. **A)** A espiral **sempre disponível como rota lenta** (recomendo; o caminho prefere o elevador) ou **só quando o elevador
   quebra**?
3. **A)** Pode tirar as 3 **escadas de mão** e o **andaime** do paredão?
4. **B)** O rendimento lá dentro **igual ao de hoje** (recomendo) ou **+15%**?
5. **B)** Cargas de **100** por viagem, ponto de **240**, espera de 60 s e desgaste **por minério**: ok?
6. **Arte:** pode gastar **~440 gerações** (com piloto antes de cada lote)?
