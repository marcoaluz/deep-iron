# Bloco 101 — Migrantes e população inicial (PLANO, esperando aprovação do Marco)

Pedido: o "Prompt M". Acabar com a compra de ipezinhos. Como mexe no começo do jogo, este plano vem antes do código.

## O que existe hoje (auditoria)

- **Recrutar:**
  - tecla R e `Economy.recruit()`: 150 cr, com +50% a cada um;
  - o botão "Recrutar ipezinho" na gaveta da força de trabalho do HUD e na janela do Centro da Vila;
  - a ajuda de atalhos diz "R recrutar".
- **Limite:** `max_workers` (8 no começo), que sobe +4 a cada Moradia, mais a regra "precisa de cama livre". O limite e as
  camas são duas contas separadas.
- **Recrutamento de graça:** `recruit_free()`, usado pela pesquisa do satélite (um colono de graça) e pelos testes.
- **Partida nova:** a cena tem **3 ipezinhos**.
  - A Fundação dá as **3 casas iniciais** (4 camas cada = **12 camas**) e **1 cozinha**, mas é o engenheiro quem as
    constrói: **a primeira noite é sem cama**.
  - A cozinha começa com **60 de comida** (cabe 120).
- **Comida** (medida com `tests/bench_comida.gd`, 10 ipezinhos, 3 dias, invasão desligada):
  - **Consumo:** 10 × 3 refeições × 8 = **240 por dia**.
  - **A horta** (só tem 1 na partida) regenera 0,35/s = **189 por dia**. As 2 tocas só rendem com arco (da Oficina).

  | Cenário | Dia 2 | Dia 3 | Dia 4 | Entregue na cozinha por dia |
  |---|---|---|---|---|
  | Os 10 **sem função** | comida 0, fome 33 | fome **0** (passando fome) | fome 0 | 0 |
  | **1 cozinheiro + 2 caçadores** | comida 55, fome 81, 0 refeições perdidas | comida 55, fome 74 | comida 40, fome 81 | 155 → 158 → 223 |
  | 1 cozinheiro + 3 caçadores | comida 55, fome 81 | comida 40, fome 81 | comida 42, fome 80 | 155 → 223 → 232 (sobra matéria-prima: 258) |
  | 1 coz. + 2 caç. **com B + C** (comida 240, cabe 300, horta 0,5/s) | comida 235 | comida 220 | comida 220 | 155 → 225 → 240 |

  **O que os números mostram:**
  - **Com 1 cozinheiro e 2 caçadores, os números de hoje seguram 10 ipezinhos:** a fome fica em ~80 e ninguém perde
    refeição em 3 dias.
  - **O aperto é o 1º dia.** A comida inicial (60) acaba no almoço do dia 1, e se o jogador não puser ninguém pra cozinhar e
    colher logo, a vila passa fome no dia 2.
  - **O gargalo é o cozinheiro (~230/dia), não a horta**, que fica quase cheia (150 → 106). Mais caçadores só empilham
    matéria-prima. Com mais de ~10 bocas, precisa de um 2º cozinheiro (isso já é jogo).

- **"Refugiados" (Prompt 11):** não existe no código; o Prompt 11 ainda não foi feito. Quando vier, ele usa este sistema
  (fica anotado no CLAUDE.md).
- **Tutorial:** não há tutorial à parte; só a ajuda de atalhos (H) cita "R recrutar". As missões do Capítulo 1 não falam de
  recrutar.

## A proposta

### 1) Sai o "Recrutar"
- **Some:**
  - a tecla R (a ação "recrutar" sai das teclas e das Configurações);
  - os botões do HUD e da janela do Centro da Vila;
  - o texto da ajuda;
  - `recruit()`, `recruit_cost()` e `recruit_block_reason()`.
- **Fica:** `recruited_count` e `max_workers` continuam sendo lidos e salvos (pro save antigo não estranhar), mas não mandam
  em mais nada.
- **O satélite** (pesquisa que dava um colono de graça) passa a **chamar um grupo de migrantes** na hora.
- **Testes afetados:** b25, b31, b37, b39, b55, b77, b93 e hud_frostpunk. Eles passam a usar o nascimento interno
  (`Economy.novo_ipezinho`) em vez de recrutar.

### 2) Partida nova com 10 ipezinhos
- **5 homens e 5 mulheres**, nomes e aparências sorteados como hoje, todos sem função. Nascem na frente do Centro da Vila
  depois da Fundação. Os 3 da cena entram na conta.
- **Camas:** as 3 casas iniciais dão 12 camas (folga de 2), mas só depois que o engenheiro as constrói. **Proposta A:** a
  Fundação já entrega as 3 casas **prontas**, e a cozinha continua sendo obra. Sem isso, os 10 dormem ao relento na 1ª noite
  (ânimo cai).
- **Comida** — propostas, **nenhuma aplicada sem o seu OK**:
  - **B. Comida inicial 60 → 240** (1 dia de folga pra 10, o tempo de o jogador montar a cozinha e a colheita) e a cozinha
    cabendo **300** (era 120). Medido: com B a cozinha fica em ~220 o tempo todo.
  - **C. A horta rendendo mais: não precisa.** A horta não é o gargalo. Fica como está.
  - **D. Uma dica no começo** ("10 bocas: ponha 1 cozinheiro e 2 caçadores"), num aviso da Fundação. Custo zero, e ensina o
    sistema.

### 3) A capacidade da vila = as camas
- Quem pode entrar depende das **camas livres** (`Economy.free_beds()`), sem o limite separado.
- A Moradia continua dando casa nova (+4 camas).
- O HUD mostra "10 / 12 camas".

### 4) Migrantes (`migrantes.gd`, nó "Migrantes", grupo "migrantes")
- **Chegada:**
  - um **grupo de 1 a 3** chega pela floresta e anda até o **portão (o único)**, do lado de fora;
  - são ipezinhos de verdade, do elenco, com retrato, mas ficam **fora** do grupo "ipezinhos" até serem aceitos (não comem
    da cozinha nem contam pra nada);
  - aparecem um **alerta** na coluna da direita, o **som de chegada** (gancho `Audio.migrantes`, arquivo depois) e o aviso.
- **O cartão** (janela "Migrantes"), pra cada pessoa:
  - o retrato, o nome, o sexo e a condição (**saudável, com fome, ferido ou doente**);
  - a **função de que gostaria** (nunca padre).
- **Os botões:**
  - **Aceitar:** exige uma cama livre por pessoa; sem cama, o botão fica desabilitado com a dica "falta cama". O portão abre
    pra eles, eles entram e ficam **sem função**. Feridos e doentes aceitos vão direto pra **enfermaria** (o médico cuida;
    "doente" é um machucado leve com a causa "doença").
  - **Recusar:** vão embora.
  - **Esperar:** ficam no portão até o prazo.
- **O prazo:** sem resposta em **~1 dia** (`@export`), vão embora (com aviso).
- **À noite no portão:**
  - **risco de ataque das criaturas** (`@export`): quem é atacado fica ferido; quem já estava ferido morre;
  - o portão fechado (Bloco 98) não abre pra eles enquanto não forem aceitos.

### 5) Frequência
- **Atratividade da vila**, um número de 0 a 1 com pesos `@export`, somando:
  - estágio da vila;
  - comida estocada;
  - ânimo médio;
  - camas livres;
  - beleza da decoração;
  - missões cumpridas.
- **O intervalo** entre grupos vai de **1,5 dia** (muito atraente) a **4 dias** (pouco); `@export`, com o mínimo de 1 dia.
  **Sempre com aviso.**
- **Sem cama livre** nenhuma: o grupo vem mesmo assim (dá pra construir casa durante o prazo), mas com menos frequência.
- **Rede de segurança:** com **menos de 4 ipezinhos** (`@export`), chega ajuda (2 a 3 pessoas) em até meio dia, mesmo com a
  vila pouco atraente.
- **Mistura:** sorteio meio a meio de homens e mulheres.
- **O padre:** continua único (chega pelo evento dele) e nunca vem como migrante.

### 6) "Refugiados" (Prompt 11)
Fica dito no CLAUDE.md e no CONTEXTO que o evento "refugiados" do Prompt 11 é este sistema.

## Arte, som, save e testes
- **Arte:** o elenco e os retratos que já existem (`Retratos.de`). O cartão usa a pele da interface, sem arte nova.
- **Som:** o gancho `Audio.migrantes(pos)` (com o arquivo vazio, fica mudo) e `Audio.portao` reaproveitado na entrada.
- **Save:**
  - a chave `"migrantes"`: os grupos esperando (nome, sexo, aparência, condição, função desejada, prazo) e o relógio da
    próxima chegada;
  - `"economy"` continua com `max_workers` e `recruited_count`, ignorados;
  - **save antigo:** carrega com a população que tinha; a capacidade passa a ser as camas.
- **Tutorial e missões:** a ajuda de atalhos troca "R recrutar" por "migrantes chegam no portão". O Capítulo 1 não cita
  recrutamento: fica como está.
- **Teste `b101_migrantes`:**
  - partida nova com 10 (5 e 5), sem função;
  - o "Recrutar" sumiu (a tecla, os botões e a ajuda);
  - a capacidade = camas;
  - um grupo chega e espera no portão, com o alerta e o cartão;
  - Aceitar com cama (entram, ficam sem função, o ferido vai pra enfermaria) e sem cama (desabilitado, com a dica);
  - Recusar e Esperar, e o prazo (vão embora);
  - o ataque à noite;
  - a frequência pela atratividade e a rede de segurança;
  - o padre nunca vem;
  - o satélite chama migrantes;
  - o save e o save antigo.

## As decisões do Marco
1. Pode seguir com 1) a 6) como estão?
2. **Proposta A**: a Fundação entrega as 3 casas iniciais **prontas** (pra os 10 não dormirem ao relento na 1ª noite)?
3. **Proposta B**: comida inicial **240** e a cozinha cabendo **300**?
4. **Proposta D**: o aviso "10 bocas: ponha 1 cozinheiro e 2 caçadores" na Fundação?
5. O satélite passa a chamar migrantes: ok?
