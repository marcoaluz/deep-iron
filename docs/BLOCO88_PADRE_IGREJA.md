# Bloco 88 — o padre, a igreja, o domingo e o calendário

O pedido veio como "Bloco 57" (teste b57). O número já existe no histórico, então ficou **Bloco 88**, teste `b88`.

**Skills usadas:**
- `godot-gdscript`
- `godot-nodes-scenes` (igreja como cena, padre como ipezinho)
- `ai-behavior-trees-utility-ai` (missa e funeral na agenda)
- `save-systems`
- `godot-ui-control` (janela do calendário)
- `create-game-assets` (igreja provisória)
- `godot-gdscript-headless-testing`

## O que entrou

Um nó novo, **`Calendario`** (`scripts/core/calendario.gd`, na `main.tscn`, grupo "calendario"), cuida do padre,
da missa, dos funerais, da escolha do domingo e dos festivais. Tudo em `@export`.

### Padre

- **Um só, não recrutável.** Chega por **evento** quando a vila atinge `padre_estagio` (2, Vilarejo).
  - Aparece um banner "UM PADRE CHEGOU À VILA" e abre a página "O padre" no diário.
  - Nome: `padre_nome` ("Padre Bento").
- **É um ipezinho com a função "padre":**
  - ninguém troca a função dele;
  - não conta no limite de recrutas nem precisa de cama;
  - fica **na porta da igreja aconselhando**, inclusive de noite; sem igreja, fica na praça;
  - come nas refeições como todo mundo.
- **Roupa provisória:** a de civil com um tom de batina, também na vista isométrica.

### Igreja (`scripts/props/igreja.gd`, `scenes/props/igreja.tscn`)

- **Posicionada pelo jogador** e **erguida pelo engenheiro** (`Canteiro` kind **"igreja"**), uma por vila, a
  partir do estágio `igreja_estagio` (2).
- **Custo:** 220 cr + 40 ferro + 80 madeira.
- **No menu CONSTRUIR**, na aba nova **"Culto"**.
- **É ponto social** (Bloco 85): tipo "igreja", coberto, **6 bancos de 4 lugares** na frente, e anima mais
  (1,3x).
- **Na navegação e na limpeza da decoração** (`NAV_EXTRA_GROUPS`).
- **Placa:** "missa agora", "funeral de …" ou "sem padre".
- **Arte provisória:** `assets/game/igreja.png` (`igreja_provisoria.py`): capela de pedra com campanário,
  sino, cruz e vitrais.

### Missa de domingo (09:00–11:00)

- Com padre e igreja, **todos que não estão em emergência vão.** A agenda vira "missa" e o ponto da hora social
  é forçado pra igreja.
- **O médico segue de plantão**: plantão é serviço de emergência.
- **Quem foi ganha o fator "foi à missa"** (`missa_animo`), que some devagar.

### Aconselhamento

- **Quem está na igreja** (missa, funeral ou hora social) **perde zanga** (`aconselhamento_por_segundo`).
- **Com o padre lá, perde o dobro.**

### Funeral (integrado ao luto do `morale.gd`)

- **Quem morre** (`ipezinho._die`) ganha um funeral **na hora social seguinte**, por `funeral_horas` (1 h), na
  igreja, e todo mundo vai.
- **No fim, o luto da vila cai** `funeral_alivio` (12).
- **Sem padre ou sem igreja:** só o luto de sempre.

### Domingo à tarde (13:00–18:00)

**A janela abre sozinha ao meio-dia** de domingo, com banner. O jogador escolhe:
- **Festival:** a festa do `morale.gd` virou isto. Gasta créditos e comida, dá grande ânimo, e **todos se
  reúnem na praça**. No dia de festa da estação o ânimo é `festival_mult` (1,5x) e o banner traz o nome do
  festival.
- **Dia livre:** a tarde vira hora social (passeiam e conversam).
- **Trabalhar:** a tarde é de trabalho (hora extra), com **+20 de zanga** em todos.

**Sem escolha até a tarde começar: dia livre.** É uma escolha por domingo.

O botão "Dar uma festa" do painel de Ânimo agora abre o Calendário, porque a festa é o Festival do domingo.

### Calendário

- **Um festival com nome próprio por estação,** no **último domingo** dela:
  - Festa das Flores (primavera);
  - Festa do Sol (verão);
  - Festa da Colheita (outono);
  - Festa das Lanternas (inverno).
- **No HUD:**
  - o dia da semana já aparece no relógio (Bloco 83);
  - o **próximo evento** aparece no botão da coluna ("Calendário: Missa · dom 09:00") e na dica do relógio.
- **Janela do Calendário:**
  - hoje;
  - os próximos 6 eventos (missas, domingos, festivais, funerais);
  - a escolha do domingo;
  - o padre e a igreja, com o botão de construir.

## Save

- `calendario.gd` salva:
  - se o padre chegou;
  - a escolha do domingo e o dia dela;
  - os funerais pendentes;
  - a posição da igreja, que é refeita ao carregar.
- O padre é um ipezinho salvo com os outros (job "padre").
- `ipezinho.gd` "animo_fe".
- **Save antigo:** sem padre (chega quando a vila tiver o estágio), sem igreja, sem funeral.

## Testes

- **`b88_padre_igreja.gd` (novo, passa):**
  - estágio 1 sem padre; no estágio 2 o Padre Bento chega;
  - o padre não conta no limite e ninguém troca a função dele;
  - página do diário;
  - igreja construída pelo engenheiro, ponto social coberto com 24 lugares, uma só;
  - festival no último domingo da estação, com nome;
  - a missa nos próximos eventos e no HUD;
  - **com a simulação rodando:**
    - na missa, todos na igreja;
    - o aconselhamento tirou zanga (50 → 12–16);
    - o fator "foi à missa";
    - às 11:00 eles saem;
    - ao meio-dia a janela abre sozinha;
    - Festival pago e todos na praça;
    - **funeral com todos na igreja, e o luto cai**;
  - trabalhar no domingo dá + zanga e a tarde vira trabalho;
  - save e load.
- **`b84_agenda` ajustado.** Ele não tinha rodado depois do Bloco 85:
  - às 19:00, "casa" **ou "hora social"** vale;
  - a penalidade da refeição perdida passou a ser medida no fator da refeição, porque o ânimo da conversa
    mudava o rendimento total.
- **Passaram:** b84, b85 e b88.

Foto: `docs/arte/bloco88/missa_domingo.png`.
