# Bloco 103 — Criaturas (corpos e bestiário) e reconhecimento dos andares

Data: 2026-10-08. Branch `isometrico`. Teste: `b103_bestiario`. Plano e decisões: `docs/BLOCO103_PLANO.md`.

**O pedido:** o "Prompt S2" mais o acréscimo (o "por que veio" ligado a uma regra real, com dica; a história; a
pesquisadora realizada).

**As decisões do Marco:**
1. Antes do reconhecimento, a IA não desce e a ordem pede confirmação: "concordo".
2. Os drops: "faça o que fizer mais sentido". Ficaram no corpo, e o total não mudou.
3. A corrosão da Gosma: "podemos implementar".
4. "Estas novas criaturas só ficam na sessão deles, não sobe" → **o andar deles, de dia e de noite** (escolhido na
   pergunta).
5. O desconforto dos corpos: "pode ser".

**Skills usadas:**
- `godot-gdscript`;
- `godot-gdscript-headless-testing`;
- `ai-behavior-trees-utility-ai` (o morador do fundo, a patrulha, a escolha do alvo);
- `save-systems`;
- `godot-ui-control` (a Defesa, o diálogo);
- `game-feel` (o cartão, o balão).

## Como ficou

### 1) O corpo da criatura (`props/corpo_criatura.gd`, grupo "corpos_criatura")
- **Quando nasce:** a criatura abatida (não a que foge ao amanhecer) deixa o corpo onde caiu; ela mesma some como antes.
- **O desenho:** o **último quadro da animação "morrer"** da própria criatura (a vista iso usa a pose dela; o Ferrugento
  recorta o quadro da folha dele). É arte que já existia: **0 gerações**.
- **O prazo:** o corpo some no **amanhecer seguinte + 8 h** (`catalogo.horas_corpo`), ou quando é estudado.
- **O desconforto:** corpo dentro da paliçada, ou a até 120 px do portão, tira **1,5 de ânimo da vila**, até 4,5. Entra
  nos motivos do ânimo: "corpos de criatura na vila".
- **O drop** (as mesmas chances de sempre: Ferrugento 35% de peça rara, Gosma 35% de 2 cristais verdes, Magmante 50% de
  3 cristais rubros):
  - espécie **não estudada:** fica no corpo; a pesquisadora colhe no estudo; no prazo, vai pro armazém. Nada se perde;
  - espécie **já estudada:** vai direto pro armazém, como antes.
- **Não vai pro save.**

### 2) O bestiário
- **A pesquisadora vai no corpo** de uma espécie ainda não estudada, que entra como alvo de campo no lugar da amostra no
  laboratório.
  - Ela vai **de dia**.
  - Corpo **lá fora** só com o **portão aberto**.
  - Ela evita corpo com morador do fundo vivo perto.
  - Anota, colhe o que ele deixou e entrega no laboratório.
  - Várias espécies, uma a uma; duas pesquisadoras nunca no mesmo alvo.
- **O plano B continua:** o laboratório sozinho estuda com a amostra do abate.
- **A ficha:**
  - nome, texto, para que serve;
  - **comportamento** e **fraqueza**;
  - **o que deixa** e **perigo (1 a 5)**, lidos da cena e do código;
  - **POR QUE VEIO** e a **DICA**;
  - **a história.**
  - O texto fica em `data/catalogo/textos.txt`, editável.
- **Por que veio, ligado à regra real:**

  | Criatura | Por que veio (a regra do código) | Dica |
  |---|---|---|
  | Lumívoro | a LUZ (gente acordada lá fora, casas com gente, tochas da decoração: `atracao_luz`) | tirar as tochas do caminho portão→casas |
  | Ferrugento | o POÇO sem muro (sai da boca do poço desde o S2) | guardas no posto do poço, lança de prata (+60%) |
  | Gosma | o S2 é a casa dela (morador) | patrulha no S2 antes dos mineiros; armas de reserva (o ácido gasta) |
  | Magmante | o abismo é a casa dele (morador) | patrulha forte no S3; médico na enfermaria |
  | Matriarca | a estação (uma por estação; só grita dentro da vila) | segurar no portão |

- **O perigo:** lumívoro 1, gosma 2, ferrugento 3, magmante 4, matriarca 5 (a vida × o dano por segundo da cena).
- **A descoberta:**
  - o **cartão narrativo** (o banner: "DESCOBERTA: O LUMÍVORO", quem estudou, a história e a dica);
  - a **página do diário**. As páginas das criaturas **vêm do estudo**, não mais de quando ela aparece. Save antigo com a
    página = estudada;
  - a pesquisadora fica **realizada**: +12 de ânimo (vai sumindo; o motivo "fez uma descoberta"), +1 de **experiência**
    (cada uma deixa o estudo de campo 10% mais rápido, até 50%) e o **balão de comemoração** com o ícone do que ela
    descobriu.

### 3) A Defesa
- **Seção nova "CRIATURAS":**
  - a **previsão da próxima invasão**, com os tipos e as quantidades, pela mesma conta da onda (`composicao`);
  - cada espécie que já apareceu: "???" em silhueta sem estudo; a ficha curta (perigo, fraqueza, deixa, dica) com o
    estudo;
  - a **patrulha do fundo** (S2, S3): quantos guardas descem caçar.
- **O banner da invasão** usa o nome só das espécies estudadas ("4 Lumívoros e 2 ???").

### 4) A Gosma e o Magmante moram no andar deles
- **Os moradores:** nos dados do nível (`nivel_mina.moradores`): **S2: 2 Gosmas**, **S3: 2 Magmantes**.
  - Nascem quando o andar abre, longe de quem estiver lá, e repõem 1 por dia (no amanhecer).
  - Vagam em volta de casa e atacam só quem está no **mesmo andar** e perto (até 260 px de casa).
  - **Nunca sobem** e não fogem ao amanhecer.
- **Saíram das invasões da superfície:** a onda é Lumívoros + Ferrugentos + a Matriarca. Os `@export` antigos ficam, sem
  uso.
- **A patrulha:**
  - na Defesa, "Patrulha no S2: N guardas" (+/−). De dia, esses guardas (armados, inteiros, os primeiros pelo nome)
    descem pelo caminho de sempre, procuram o morador vivo mais perto e lutam com o combate do posto. De noite voltam
    pros postos;
  - patrulha pra andar não reconhecido pede a confirmação.
- **A corrosão da Gosma:** o golpe num guarda armado gasta a arma a mais (`corrosao_gosma`).
- **Os textos corrigidos:** saíram "sobe pelo poço" e "derrete a barricada" da Gosma e do Magmante, no diário, no
  catálogo e no cabeçalho do `creature.gd`.

### 5) O reconhecimento dos andares
- **O andar não reconhecido:** o andar que abriu e ninguém reconheceu (S2 a S5) aparece como **"aberto — NÃO
  RECONHECIDO"** no corte da mina (F2), com o perigo como "???".
- **A IA não manda ninguém trabalhar lá** (as jazidas e as estações do andar não chamam ninguém). A pesquisadora é a
  exceção.
- **Descer mesmo assim:**
  - a ordem à mão (botão direito), a área de trabalho e a patrulha **pedem confirmação** num diálogo ("Descer mesmo
    assim" / "Esperar o reconhecimento");
  - confirmado, o andar fica liberado e os **acidentes na mina lá dentro ficam ×2** (`acidente_sem_reconhecimento`) até
    o reconhecimento.
- **O reconhecimento:**
  - a pesquisadora vai ao ponto seguro do andar (com morador perto, outro ponto do mesmo andar), pelo caminho de sempre
    (as poças e zonas valem);
  - no fim tem **15% de chance de ferimento** (`risco_reconhecimento`), ×0,25 com o traje do andar no vestiário;
  - revela, na ficha do local e no cartão: os **perigos** (lidos das zonas e poças do andar), as **criaturas** (o
    morador com "mora aqui") e o **equipamento** (o traje e as ferramentas dos minérios de lá).
  - As regras duras (traje de gás, de chumbo, ventilador) não mudaram.

### 6) Sinais e missões
- **Os sinais do catálogo:** `criatura_estudada(id)` e `andar_reconhecido(id)`, além do `entrada_estudada`.
- **Os objetivos novos:** `criatura` (uma espécie ou quantas) e `reconhecer` (um andar ou quantos).

## Save
- **O que entrou:**
  - **catálogo:** `descida_liberada`;
  - **defesa:** `patrulhas`;
  - **ipezinho:** `xp_pesquisa` e `animo_descoberta`.
  - Tudo documentado no cabeçalho do `save_manager.gd`.
- **O que não entra:** os corpos e os moradores. Os moradores renascem com o andar aberto.
- **Save antigo:** nada liberado, nenhuma patrulha, xp 0. O andar que já estava aberto entra reconhecido e a criatura com
  página no diário entra estudada (a migração do Bloco 102).

## Arte
- **0 gerações.** O corpo é o último quadro da animação de morte que cada criatura já tinha. O cartão usa o banner da
  interface; o balão usa o balão de sempre com o ícone do catálogo.
- **As fotos:** `docs/arte/bloco103/`.

## Testes
- **`b103_bestiario`** (novo, **0 falhas**).
- **Ajustados:**
  - `b70_fundo`: a Gosma e o Magmante não vêm mais na onda; o drop direto exige a espécie estudada; a página do diário
    vem do estudo;
  - `b102_catalogo`: a criatura se estuda no corpo; a amostra ficou pro plano B.
- **Uma chave nova pros testes antigos:** `defense.gd moradores_desligados` (com `load`, não `preload`), pro teste que
  desce gente ao S2/S3 sem querer as Gosmas lá. O `b99_mina_elevador` usa.
- **A bateria completa** (86 testes de bloco, um por vez, com o APPDATA isolado):
  - **Falharam 4 na primeira volta:**
    - `b79_ferrovia` e `b99_mina_elevador`: o S2 agora fica "não reconhecido" (a IA não desce) e tem Gosmas morando lá.
      São testes de antes do reconhecimento e ganharam `tudo_estudado` (o b99 também o `moradores_desligados`);
    - `b101_migrantes` e `b58_oficina_construivel`: intermitentes (tempo).
  - Rodados de novo, **os 4 passaram**. Os outros 82 passaram de primeira.
- **GUT da vista iso:** 12 testes, 439 asserts, todos passaram.
