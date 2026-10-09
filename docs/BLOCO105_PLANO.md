# Bloco 105 — Carregador e Mecânico (plano)

Data: 2026-10-08. Branch `isometrico`. Pedido: "Prompt W1". Teste: `b105_carregador_mecanico`.
**Esperando a aprovação do Marco.**

## O que existe hoje (auditoria)

- **A logística das obras** (Bloco 96, `obra_site.gd` + `ipezinho._material_tick`): o ENGENHEIRO constrói até a fração
  entregue e então vai ao armazém buscar o que falta. Ele leva até `carga_material` por viagem (ou a capacidade da
  mochila). O material da obra fica reservado no armazém (`Economy.livre`). Quem está levando o quê sai dos próprios
  engenheiros (`material_mao`, `material_pedido`, `_material_obra`).
- **A Fornalha e a Carpintaria** (Blocos 86 e 94): o FUNDIDOR (e o carpinteiro) vai ao armazém, paga os insumos das
  unidades que vai fazer (`fila.comecar_unidades`), volta e funde. As barras prontas vão na mão dele de volta pro armazém.
- **A cozinha:** o COZINHEIRO busca a matéria-prima no armazém e prepara na cozinha.
- **A forja** (Arsenal e Oficina, ferreiro): as armas e ferramentas são pagas NA ENCOMENDA (o Bloco 96 manteve assim:
  "produção paga na hora"). **Não tem material pra levar.**

### Os consertos de hoje e o que muda

| O quê | Hoje | Com o Bloco 105 |
|---|---|---|
| Cabine do elevador do S2 (o cabo arrebenta em 60 viagens; conserto com material) | engenheiro (obra) | **mecânico** (sem mecânico: engenheiro) |
| Cabines das plataformas S3–S5 (idem) | engenheiro (obra) | **mecânico** (idem) |
| Trilho do vagonete (gasta por minério levado; quebra e para) | engenheiro (obra) | **mecânico** (idem) |
| Restauração do robô achado (6 peças, 400 cr, 60 ferro) | engenheiro (obra) | **mecânico** (idem) |
| Portão (conserto grande com madeira) | engenheiro (obra) | continua do **engenheiro**: é construção (muro) |
| Escavadeira (a broca) | **não gasta** | **desgaste NOVO** por minério tirado; quebrada, para; manutenção do mecânico |
| Coletor de madeira e coletor de minério | **não gastam** ("nada quebra") | **desgaste NOVO** por produção; quebrado, para |
| Ventiladores do S2 | **não gastam** | **desgaste NOVO** por hora ligado; quebrado, não filtra o gás |
| Robô guarda ativo | cai na luta e religa de manhã, sempre | **desgaste NOVO** por luta (cada vez que cai gasta); quebrado, fica desligado até o conserto |
| Vagonete (o carrinho) | o desgaste é do trilho | junto com o trilho (um conserto só) |

## O plano

### 1) A função CARREGADOR / CARREGADORA (logística)
- **Personagem novo** (homem e mulher) com a receita completa do elenco (regra 11). O trabalho é "carregar": levanta e
  ajeita um caixote pesado. O saco nas costas de quem carrega já existe no boneco.
- **A logística** fica num coordenador novo (`logistica.gd`, nó "Logistica"). Ele monta as ENTREGAS e reserva cada uma pra
  um carregador (dois nunca pegam a mesma). Por prioridade:
  1. **O material das obras** (a mais antiga primeiro): o que ainda precisa de viagem (`ObraSite.a_buscar`). Ele usa os
     mesmos campos do engenheiro (`material_mao`/`material_pedido`), então a reserva e a pilha da obra continuam valendo.
  2. **A Fornalha e a Carpintaria:**
     - Ele busca no armazém os insumos das próximas unidades (`lote`) e leva até a fornalha. As unidades só começam
       quando ele ENTREGA (`fila`: "a caminho").
     - Ele leva as barras prontas da fornalha pro armazém. O fundidor fica na fornalha, fundindo.
  3. **A cozinha:** ele leva matéria-prima do armazém pro estoque da cozinha (um pequeno estoque novo, `@export` 40). O
     cozinheiro prepara direto dali.
- **As regras:**
  - respeita a **carga** (`capacidade_carga`: com mochila leva mais);
  - respeita as **reservas** do armazém: pra obra, leva o reservado DELA; pra fornalha e cozinha, só o LIVRE;
  - respeita o **armazém cheio**: na volta com as barras, espera como todos (Bloco 97).
- **O engenheiro passa a só construir quando há carregador:**
  - ele espera no canteiro ("esperando o carregador trazer o material");
  - **sem carregador na vila** (ou ninguém pegou a entrega em `espera_carregador`, `@export` 30 s de jogo), ele mesmo
    busca, como hoje. **Nada trava.**
  - O mesmo vale pro fundidor e pro cozinheiro.
- **A forja** não tem o que levar (paga na encomenda). Fica como está.

### 2) A função MECÂNICO / MECÂNICA (manutenção)
- **Personagem novo** (homem e mulher), com a receita completa. O trabalho é "consertar": de joelhos, com a chave inglesa.
- **O coordenador da manutenção** (`manutencao.gd`, nó "Manutencao"): cada máquina tem uma interface (duck typing):
  `manut_condicao()` (0 a 1), `manut_quebrada()`, `manut_titulo()`, `manut_pos(w)` e `manut_trabalha(segundos)`.
  - **As cabines e o trilho:** a condição é o desgaste que eles já têm (viagens, minério). Quebrou, vira a obra de
    conserto de sempre (com material), agora do mecânico.
  - **A escavadeira, os coletores, os ventiladores e o robô:** desgaste novo (`@export` por máquina: tantos de minério,
    tantas unidades, tantas horas, tantas quedas). Em 0 a máquina QUEBRA e para.
- **O que o mecânico faz:**
  - **conserta o que quebrou** primeiro (a obra com material);
  - depois a **manutenção preventiva**: a máquina mais gasta abaixo de 60% (`@export`). Trabalha uns segundos no local
    (`@export` por máquina) e ela volta a 100%, sem parar e sem material. Manter é mais barato que consertar.
- **Sem mecânico na vila:** o engenheiro faz os consertos de máquina quebrada (como hoje) quando não tem obra. A
  preventiva não acontece. **Nada trava.**
- **O desgaste visível:**
  - uma barrinha de condição embaixo da máquina na vista iso (o mesmo desenho da barrinha da obra), a partir de 60%;
  - na placa: "desgaste 40%";
  - quebrada: a máquina escurece, a placa diz "QUEBRADA — mecânico" e aparece o alerta novo **"Máquina quebrada"** na
    coluna da direita.

### 3) Integrações
- **A barra de funções:** os dois em SERVIÇO, com o botão e a dica.
- **As teclas:** todas as letras livres já foram usadas. Proposta: **[** (carregador) e **]** (mecânico). Dá pra
  trocar nas Configurações.
- **A agenda:** trabalham no horário de trabalho como todos, e param pras refeições, a hora social e o sono.
- **Os balões de motivo:**
  - carregador sem nada pra levar: "sem trabalho";
  - entrega sem o item no armazém: **"sem material"** (ícone novo);
  - mecânico sem máquina gasta: "sem trabalho".
- **As missões:** os contadores `entregas` e `consertos` (objetivos novos) e os sinais `entrega_feita` e
  `manutencao_feita`.
- **O save:**
  - as funções novas no ipezinho;
  - a condição de cada máquina nova (escavadeira, coletores, ventiladores, robô) e o "a caminho" da fila da fornalha;
  - o estoque da cozinha;
  - **save antigo:** as funções de sempre, as máquinas novas inteiras (100%), nada a caminho.

### 4) Arte (PixelLab, regra 11)
- **Carregador e carregadora, mecânico e mecânica:** os 4 com a receita do elenco (candidatos/piloto, v3, caminhada 8,
  comer/ferido/deitar/mancar, o trabalho, o casaco, o retrato com 5 expressões, o ícone).
- **O ícone "sem material"** e o do alerta "Máquina quebrada".
- **Estimativa: ~300 a 400 gerações** (o batedor e a batedora custaram ~170 com o mapa fora). Saldo: 6.141.

### 5) Teste `b105_carregador_mecanico`
Confere:
- o carregador leva o material da obra e o engenheiro só constrói;
- sem carregador, o engenheiro leva (o fallback);
- a reserva respeitada e a carga (mochila);
- duas entregas não repetem;
- a fornalha: os insumos "a caminho" só começam na entrega, e as barras vão pro armazém;
- a cozinha: o estoque e o cozinheiro preparando dali;
- o mecânico: o conserto da cabine e do trilho e a preventiva de um coletor;
- sem mecânico, o engenheiro conserta;
- o desgaste novo (a escavadeira, o coletor, o ventilador e o robô quebram e param);
- a barra, as teclas, o alerta e os balões;
- as missões;
- o save e o save antigo.

## Decisões para o Marco

1. **A forja** (armas e ferramentas) é paga na encomenda, então não tem o que levar. Fica assim? (A alternativa é mudar
   a forja pra ter material como as obras, o que mexe no Bloco 96.)
2. **O desgaste novo** (escavadeira, coletores, ventiladores, robô) com quebra que PARA a máquina. Pode? Ou só deixar
   mais lento quando gasto (mais leve)?
3. **A preventiva sem material** (só o tempo do mecânico) e o conserto da quebra com material (como as cabines hoje).
   Ok?
4. **As teclas [ e ]** (as letras acabaram)?
5. **A arte:** ~300–400 gerações pros 4 personagens e os ícones. Ok?

## A aprovação do Marco (2026-10-08) e o plano de execução

**O que foi aprovado (com limites):**
- **A forja:** fica como está.
- **O desgaste:** gradual. A eficiência começa a cair com **40% de desgaste** (`@export`): até lá, a máquina funciona
  normal; daí até 0% de condição cai aos poucos; em 0% quebra e para.
  - **Os ventiladores** perdem a proteção aos poucos (no `fundo.ventilacao_mult` e no `nevoa_mult`, as regras de
    sempre) e avisam antes de falhar.
- **A telemetria antes do balanceamento:** uma simulação no ritmo padrão (`tests/bench_desgaste.gd`). **O balanceamento
  só vale depois da análise do Marco.**
- **Os custos:** a preventiva só custa tempo; a quebra usa material (as regras de reserva). Nada é consumido se o reparo
  não puder ser feito. Sem mecânico, o engenheiro conserta a quebra quando não tem obra, e não há preventiva. A quebra
  vem antes da preventiva.
- **As teclas:** `[` e `]`, pelo código físico, remapeáveis e com persistência (o sistema de teclas do Bloco 54).
- **A arte por etapas:** **UM personagem completo** primeiro, e para pra aprovação. O orçamento vai no CONTEXTO.

**Os arquivos (nada de sistema paralelo: obra = `ObraSite`, conserto com material = obra, fila = `production_queue`):**
- **Novos:**
  - `scripts/core/desgaste.gd` (RefCounted: a condição de UMA máquina, a eficiência, a quebra);
  - `scripts/core/manutencao.gd` (nó "Manutencao": as máquinas, a preventiva, a obra de conserto);
  - `scripts/props/conserto_maquina.gd` (o dono da obra do conserto de quebra: ObraSite, ofício "mecanico");
  - `scripts/core/logistica.gd` (nó "Logistica": as entregas do carregador, a reserva de cada uma, a espera do fallback);
  - o teste `b105_carregador_mecanico`, a medição `tests/bench_desgaste.gd` e a arte `prototipos/.../oficios105.py`.
- **Alterados:**
  - `ipezinho.gd` (as funções, os estados "carregando" e "manutencao", o fallback do engenheiro, do fundidor e do
    cozinheiro, o ofício das obras);
  - `production_queue.gd` (as unidades "a caminho");
  - `fornalha.gd` (as barras esperando o carregador);
  - `comedouro.gd` (o estoque da cozinha);
  - as máquinas: `escavadeira.gd`, `coletor_madeira.gd`, `coletor_minerio.gd`, `ventilador.gd` + `fundo.gd`,
    `robo.gd`, e a condição visível de `deep_shaft.gd`, `abyss_shaft.gd` e `estacao_vagonete.gd` (o ofício "mecanico"
    no conserto);
  - `iso_billboard.gd` (a barrinha), `ui/alertas.gd` + `hud.gd` (o alerta, os botões);
  - `teclas.gd`, `main.gd`, `save_manager.gd`, `missoes.gd`, `missao.gd`, `telemetria.gd` e a `main.tscn` (os 2 nós);
  - os docs.
