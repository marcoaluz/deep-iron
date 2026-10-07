# Bloco 83 — relógio de 24 horas

O pedido veio como "Bloco 52" (teste b52). O número já existe no histórico, então ficou **Bloco 83**, teste `b83`.

**Skills usadas:**
- `godot-gdscript`
- `godot-ui-control` (barra de cima)
- `save-systems` (save antigo convertido)
- `game-feel` (velocidade / pular dia)
- `godot-gdscript-headless-testing`

## Plano (mostrado antes de codar)

1. **`day_night.gd`**
   - Relógio de 24 h por cima do ciclo de sempre. **`time` continua sendo "segundos reais desde o amanhecer"**,
     que é o que o resto do jogo, o save e os testes usam.
   - `day_duration` e `night_duration` passam a ser calculados pelos marcos (só leitura).
2. **`sun.gd`**: estações em semanas; a onda solar por horário.
3. **`defense.gd`**: o aviso às 21:00 e a invasão às 22:00.
4. **HUD**: hh:mm, o dia da semana, as semanas, a velocidade (pausa / 1x / 2x / 4x) e o "Pular dia".
5. **Testes:** adaptar os que dependiam do dia de 180 s e criar o `b83`.

## O relógio (`day_night.gd`)

| `@export` | Padrão | O quê |
|---|---|---|
| `duracao_dia_real` | 540 s (9 min) | 24 h de jogo; **1 hora = 22,5 s** |
| `hora_amanhecer` | 05:00 | o turno começa; o dia do jogo vira |
| `hora_fim_expediente` | 18:00 | marco pra agenda (Bloco 84) |
| `hora_anoitecer` | 18:30 | `is_night()`: todo mundo pra casa |
| `hora_dormir` | 21:30 | marco pra agenda / hora social |
| `pular_velocidade` | 8x | velocidade do "Pular dia" |

- **Dia do jogo:** continua virando no **amanhecer**. Então 01:00 ainda é a noite do mesmo dia (invasão,
  telemetria e marcos de "dia" seguem como antes).
- **Semana:** de 7 dias; o dia 1 é segunda e **o 7º é domingo**.
  - `dia_semana()`, `nome_dia()`, `semana()` e `e_domingo()`.
- **API que ficou igual:**
  - `time`, `day`, `is_night()`, `phase_changed`, `day_started`;
  - `torch_level()`, `darkness()`, `time_left_in_phase()`, `phase_progress()`, `cycle_length()`;
  - `skip_phase()` (tecla N);
  - `day_duration` / `night_duration`, que agora são só leitura: 05:00→18:30 = 303,75 s e 18:30→05:00 =
    236,25 s.
- **Funções novas:**
  - `hora()`, `hora_texto()` ("hh:mm");
  - `tempo_da_hora(h)` e `segundos_ate_hora(h)`;
  - `entre_horas(a, b)`, `marcos()` e `proximo_marco()`;
  - o sinal **`marco(nome)`**, ao passar por "amanhecer", "fim_expediente", "anoitecer" e "dormir", na ordem
    em que acontecem.
- **Helpers dos testes:**
  - `ir_para_hora(h, seguinte)` e `avancar(segundos)`: passam pelos marcos e anunciam a fase, sem rodar a
    simulação;
  - `_pula_para(t)`: muda a hora sem passar pelo meio.

## Estações e onda solar (`sun.gd`)

- **`semanas_por_estacao`** (`@export`, padrão **2** = 14 dias).
- `days_per_season` continua existindo, agora só leitura. A defesa e os testes usam esse nome.
- **A estação não muda mais o tamanho do dia.** Saíram `season_day_mult`, `season_night_mult` e
  `adjust_day_length`, porque os marcos são fixos. A estação continua mudando a fome, a horta, a luz e a chance
  de onda.
- **Onda solar:** chega numa hora sorteada entre **`onda_hora_min` 08:00 e `onda_hora_max` 16:00**.
- **Chance por dia:** baixou um pouco, para [0,25; 0,5; 0,25; 0,12]. As estações ficaram 3,5x mais longas e os
  dias 2,25x mais longos, e com a chance antiga o verão teria onda quase todo dia.

## Invasão (`defense.gd`)

- **`hora_aviso_invasao` 21:00:** toca o aviso "Às 22:00 eles atacam — todo mundo em casa, guardas nos
  portões!". O rádio adianta `radio_warning_bonus` segundos.
- **`hora_invasao` 22:00:** a invasão começa quando o relógio **passa** pela hora.
  - Carregar um save depois das 22:00 não recomeça a invasão (as criaturas não vão pro save, como antes).
- **Acaba no amanhecer**, como antes.
- **Às 22:00 todo mundo já está em casa e os guardas nos postos.** O teste confere isso com a simulação
  rodando.
- **Saiu** `warn_before` (segundos antes do anoitecer).

## HUD

- **Relógio:** `17:38 QUA` e, embaixo, `dia 3 · sem. 1`.
- **Na dica** (passando o mouse): o próximo marco e todos os horários.
- **Velocidade:** pausa, 1x, 2x, **4x** (era 3x). O F3 usa o mesmo `set_speed`.
- **Pular dia (⏭)** (`hud.pular_dia()` / `DayNight.pular_dia()`):
  - acelera (8x) **com a simulação rodando de verdade** até as 05:00 do dia seguinte e volta pra 1x;
  - **para sozinho** se começar a invasão, tocar o alarme ou chegar uma onda solar, alguém se ferir grave,
    alguém morrer ou começar uma greve, e avisa o motivo;
  - mexer na velocidade cancela o pulo.

Foto: `docs/arte/bloco83/barra_relogio.png`.

## Save

- **DayNight:** salva `"relogio": 24`.
- **Save antigo** (sem `relogio`, ciclo de 180 s de dia + 60 s de noite): converte na **mesma fração** do dia
  ou da noite. Exemplo: 90 s de dia vira o meio do dia (11:45); 200 s (20 da noite) vira 1/3 da noite (22:00).
- **Ondas:** o `wave_at` de um save antigo continua valendo como "segundos desde o amanhecer".
- **Estações:** um save antigo cai na estação pela regra nova (14 dias por estação). Um save no dia 10, que era
  outono com estações de 4 dias, agora é primavera.

## Testes

- **`b83_relogio_24h.gd` (novo, passa):**
  - 05:00 e 22,5 s por hora;
  - 18:30 é noite;
  - 02:00 ainda é o mesmo dia;
  - semana e domingo;
  - um dia inteiro passa pelos 4 marcos na ordem;
  - o HUD;
  - estações em semanas;
  - a onda entre 08:00 e 16:00;
  - aviso às 21:00 e invasão às 22:00, e a invasão acaba no amanhecer;
  - **com a simulação rodando:** às 22:00 os não-guardas estão em casa e o guarda no posto;
  - velocidade 4x;
  - o "Pular dia" para em ferido grave, greve e morte, é cancelado pela velocidade, vai até o amanhecer
    sozinho e para na invasão;
  - save novo e antigo.
- **Ajustados:**
  - `p18_efeitos`: "noite" era `time = 215`;
  - `b40_clima`: os números de estação não têm mais multiplicador de dia;
  - `b60_dinamite_radio`: o aviso agora é pela hora da invasão;
  - `p19_luz`: "noite" era `time = 215`;
  - `tests/ciclo_luz.gd` (fotos, não é teste): os horários viraram horas do relógio.
- **Passaram também:** b35, b36, b40, b42, b52, b55, b60, b61, b62, b80, p17, p18, p19, p20 e b25.
