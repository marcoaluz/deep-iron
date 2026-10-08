# Bloco 101 — Migrantes e população inicial

Data: 2026-10-08. Branch `isometrico`. Teste: `b101_migrantes`.

**O pedido:** o "Prompt M": acabar com a compra de ipezinhos. Plano e auditoria em `docs/BLOCO101_PLANO.md`.

**As decisões do Marco:**
1. Os itens 1 a 6 do plano: "pode".
2. As casas iniciais **não** vêm prontas: a Fundação dá **só o recurso pra construir**, como já era. Conferido: os recursos
   pagam as 3 casas e a cozinha.
3. Comida inicial **240** e a cozinha cabendo **300**: "pode".
4. A dica "ponha 1 cozinheiro e 2 caçadores": **não**.
5. O satélite passa a chamar migrantes: "ok".

**Skills usadas:**
- `godot-gdscript`;
- `godot-gdscript-headless-testing`;
- `ai-behavior-trees-utility-ai` (o visitante e quem entra);
- `save-systems` (quem espera no portão; o save antigo);
- `godot-ui-control` (o cartão).

## Como ficou

### 1) Acabou o "Recrutar"
- **Saíram:**
  - `Economy.recruit()`, `recruit_cost()`, `recruit_block_reason()` e os `@export` do custo (150 cr, +50%);
  - a tecla **R** (a ação "recrutar" saiu das teclas e das Configurações);
  - o botão da gaveta da força de trabalho e o da janela do Centro da Vila;
  - o "R recrutar" da ajuda de atalhos.
- **Ficou:** `Economy.novo_ipezinho(gender)`, o nascimento interno usado pela Fundação e pelos testes. `recruit_free()`
  continua como nome antigo dele, pros testes e medições de antes.
- **O save antigo** continua com `max_workers` e `recruited_count` na economia: eles carregam, mas não mandam mais em nada.
- **Testes ajustados:** b25, b39 e b93 (usam o nascimento interno; o b39 agora confere que não há compra e que a capacidade
  são as camas) e hud_frostpunk.

### 2) Partida nova com 10 ipezinhos
- A Fundação (`founding.gd`, `populacao_inicial = 10`, `@export`) completa a vila, contando os que já estão na cena:
  **5 homens e 5 mulheres**, nomes e aparências sorteados, todos **sem função**.
- **Camas:** as 3 casas iniciais dão **12 camas** (cabem os 10). Elas continuam sendo obra do engenheiro.
- **Recursos:** os da Fundação (400 cr, 90 ferro, 80 madeira) pagam as 3 casas (240 cr, 60, 45) e a cozinha (100 cr, 20, 25).
- **Comida:** a cozinha começa com **240** (era 60) e cabe **300** (era 120).

### 3) A capacidade da vila são as camas
- Quem cabe é quem tem cama livre nas casas prontas (`Economy.free_beds`).
- O HUD mostra "10 / 12 camas". A janela do Centro mostra a população e as camas.
- A Moradia continua dando casa nova (o aviso agora diz "+4 camas").

### 4) Migrantes (`migrantes.gd`, nó "Migrantes", grupo "migrantes")
- **A chegada:**
  - um grupo de **1 a 3** nasce no fundo da floresta e **anda até o portão** (o único), esperando **do lado de fora**;
  - são ipezinhos do elenco, com `visitante = true`: **fora do grupo da vila** (não comem da cozinha, não ocupam cama, não
    contam) e sem necessidades nem IA enquanto esperam;
  - a vista iso desenha eles com o elenco, como os moradores.
- **Os avisos:** o alerta **"Migrantes no portão"** na coluna (o clique leva a eles), o aviso no canto, o **som** (gancho
  `Audio.migrantes`, mudo até ter arquivo) e a **janela "Migrantes"**, que abre sozinha.
- **O cartão** de cada um: o **retrato**, o **nome**, o **sexo**, a **condição** (saudável, com fome, ferido, doente, com cor),
  a **função de que gostaria** (nunca padre) e as horas que ainda espera.
- **Os botões:**
  - **Aceitar:** precisa de cama livre. Sem cama, o botão fica desabilitado com a dica **"falta cama"**. Aceito, ele vira
    morador: entra no grupo da vila, sem função, ganha a cama e anda pra dentro (de noite o portão abre pra ele como pra
    qualquer morador, Bloco 98). **Ferido ou doente vai pra enfermaria** (o médico cuida).
  - **Recusar:** volta pra floresta.
  - **Esperar:** fecha a janela; ele fica até o prazo.
- **O prazo:** **1 dia de jogo** (`prazo_dias`). Sem resposta, ele vai embora com aviso.
- **À noite:** com criatura no mapa, quem espera pode ser **atacado** (`risco_ataque_hora`, 8% por hora). Fica ferido; se já
  estava ferido, morre.

### 5) Frequência
- **A atratividade** (0 a 1, com pesos `@export`) junta:
  - o estágio da vila;
  - a comida estocada (porções por morador);
  - o ânimo médio;
  - as camas livres;
  - a beleza (a decoração);
  - as missões cumpridas.
- **O intervalo** entre grupos vai de **4 dias** (pouco atraente) a **1,5 dia** (muito), com esse mínimo. Sem nenhuma cama
  livre, o intervalo fica 1,5 vez maior: eles vêm, mas menos.
- **O relógio** só anda com ninguém esperando. **Sempre com aviso.**
- **Rede de segurança:** com **menos de 4 ipezinhos** (`socorro_abaixo_de`), chega ajuda de **2 a 3** em até meio dia, atraente
  ou não.
- **O primeiro grupo** de uma partida nova vem em 2 dias. Homens e mulheres meio a meio. **O padre continua único** e nunca vem
  como migrante.
- **O satélite** (pesquisa) agora chama um grupo de migrantes, em vez de dar um colono de graça.

### 6) "Refugiados" (Prompt 11)
Ficou anotado no CLAUDE.md e no CONTEXTO: o evento "refugiados" do Prompt 11 é este sistema.

## A comida com 10 (a medição)

`tests/bench_comida.gd`, 3 dias de jogo.

| Cenário | Dia 2 | Dia 4 | Entregue na cozinha por dia |
|---|---|---|---|
| Os 10 sem função | comida 0, fome 33 | fome 0 | 0 |
| 1 cozinheiro + 2 caçadores (os números de antes) | fome 81, nenhuma refeição perdida | fome 81 | 155 → 158 → 223 |
| 1 cozinheiro + 2 caçadores, **com a comida inicial 240 / cabe 300** | cozinha com 235 | cozinha com 220 | até 240 |

- O gargalo é o **cozinheiro (~230/dia)**, não a horta.
- A comida inicial de 240 dá o 1º dia de folga pra o jogador montar a cozinha e a colheita.
- Com mais de ~10 bocas, precisa de um 2º cozinheiro.

## Save

- **A chave `"migrantes"`:** `proximo` (s até o próximo grupo) e `esperando`, com o save de cada ipezinho, o nome, a condição,
  a função e o prazo. Documentada no cabeçalho do `save_manager.gd`.
- **Save antigo:** ninguém esperando, o primeiro grupo no prazo de uma partida nova, a população que tinha. A capacidade
  passa a ser as camas.

## Arte e som

- **Arte:** nada novo. O elenco e os retratos de sempre (`Retratos.de`); o cartão usa a pele da interface. A vista iso passou
  a desenhar o visitante com o elenco.
- **Som:** o gancho `Audio.migrantes(pos)` com o `@export migrantes_sound` vazio. Na entrada do aceito toca o som de chegada.
- **Fotos:** `docs/arte/bloco101/` (o grupo no portão e os cartões).

## Testes

- **`b101_migrantes`** (novo, **0 falhas**). Confere:
  - a compra sumiu (a economia, a tecla R, os botões, a ajuda);
  - os 10 da Fundação (5 e 5, sem função, nomes diferentes) e que os recursos pagam as casas e a cozinha;
  - as 12 camas e a cozinha de 240/300;
  - o "N / camas" do HUD;
  - o grupo de 3 chegando do lado de fora do portão como visitantes;
  - o alerta, a janela que abre sozinha e o cartão completo;
  - aceitar o ferido (vai pra enfermaria) e o são (passa pelo portão pra dentro);
  - sem cama: o botão desabilitado com "falta cama";
  - recusar e o prazo;
  - o ataque à noite (ferido, depois morre);
  - a atratividade encurtando o intervalo, com mínimo, e as 6 partes;
  - a rede de segurança;
  - o padre nunca vem;
  - o satélite chamando migrantes;
  - o save de quem espera e o save antigo (sem a chave; a economia com os campos velhos).
- **A bateria completa** (85 testes de bloco, um por vez, com o APPDATA isolado): **todos passaram**.
  - O `b51_engenheiro_estresse` falhou uma vez na bateria ("vigia forçado age", com o engenheiro parado em (0, 0)). Rodado
    sozinho, passou com **0 falhas**: é intermitente, como os já conhecidos (b25, b58, b77, b85, b92, p29_predios).
  - GUT da vista iso (`test_iso`, `test_iso_arte`, `test_iso_pele`): **12 testes, 439 asserts, todos passaram**.
