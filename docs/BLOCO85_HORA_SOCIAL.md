# Bloco 85 — a hora social

O pedido veio como "Bloco 54" (teste b54). O número já existe no histórico, então ficou **Bloco 85**, teste `b85`.

**Skills usadas:**
- `godot-gdscript`
- `godot-nodes-scenes` (o componente do ponto social)
- `ai-behavior-trees-utility-ai` (escolha do ponto por nota)
- `performance-optimization` (custo baixo)
- `create-game-assets` (balão provisório)
- `godot-gdscript-headless-testing`

## Como funciona

Das **18:30 às 21:30** (o período "social" da agenda do Bloco 84), cada ipezinho:

1. **Janta primeiro** (a refeição da agenda).
2. **Escolhe um ponto social.** A nota soma perto, ponto que já tem gente e um pouco de sorte, para não irem
   todos pro mesmo lugar.
3. **Reserva um lugar numa roda.** Prefere a roda que já tem 1–2 pessoas, e assim forma o par ou o grupo.
4. **Vai até lá passando por outro ponto no caminho** (um waypoint), se o desvio for curto
   (`passeio_desvio`).
5. **Conversa.** Vira pro companheiro e, de tempos em tempos, aparece um **balão de fala com um ícone** do
   assunto. O assunto depende dele: fome, frio, zanga, a função, a estação, dinheiro, minério, madeira.
6. **Depois de `conversa_min`–`conversa_max` segundos troca de ponto** (de novo passeando).
7. **Às 21:30 vai pra casa**; o lugar fica livre.

Quem está pra baixo e tem taverna continua indo **pra dentro** da taverna (lazer, como antes). Sem nenhum ponto
com lugar, vai pra casa.

## Pontos sociais (grupo `social_spots`)

`scripts/props/social_spot.gd` é um **componente**: o prédio cria um no `_ready` (`SocialSpot.criar(...)`).
Bancos, fogueira e igreja (Blocos 88 e 90) entram do mesmo jeito.

| Ponto | Onde | Coberto | Rodas × lugares |
|---|---|---|---|
| Refeitório | Comedouro (a cozinha); as rodas de 4 são as **mesas** | sim | 2 × 4 |
| Praça | Centro da Vila | não | 3 × 3 |
| Taverna | na porta (anima mais: 1,4x) | sim | 2 × 3 |
| Parque | anima mais: 1,2x | não | 2 × 3 |

- **Vagas fixas e reservadas:** ninguém empilha no mesmo pixel.
- **Onde ficam os lugares:** na frente do prédio, fora da pegada da arte (`IsoArt.front`), encaixados na
  navegação.
- **Chuva ou onda solar:** só valem os **cobertos**. Quem estava num descoberto troca na próxima olhada.

## Ânimo

- **Conversando com alguém na roda:** ganha `animo_por_segundo` (x o do ponto), até `animo_max` (8).
- Isso vira o fator **"conversou com os amigos"** no ânimo, e depois some devagar (`animo_decai`).
- Fica salvo no ipezinho (`animo_social`; save antigo: 0).

## Custo de CPU

- **Nada roda por quadro nos pontos.** Reservar, liberar e procurar companheiro são consultas pequenas, feitas
  quando alguém chega, sai ou na hora do balão (a cada 2–4,5 s).
- **Por quadro, no ipezinho:** só os contadores (tempo no ponto, balão, ânimo).
- **A escolha de ponto** acontece quando ele troca, olhando só os pontos (poucos), não os outros ipezinhos.

## Números (`@export` no Schedule, grupo "Hora social")

- `conversa_min` / `conversa_max` (10–22 s);
- `animo_por_segundo` (0,5), `animo_max` (8), `animo_decai` (0,01);
- `balao_min` / `balao_max` (2–4,5 s);
- `passeio_desvio` (160 px).

No ponto: `rodas`, `por_roda`, `raio_roda` (18), `espaco_rodas` (62), `coberto` e `animo_mult`.

Balão provisório: `assets/game/ui/balao.png`, com o ícone do jogo dentro.

Foto: `docs/arte/bloco85/hora_social_praca.png` (três rodas na praça, com balões).

## Testes

- **`b85_hora_social.gd` (novo, passa):**
  - os 4 tipos de ponto e quais são cobertos;
  - as mesas de 4;
  - lugares sem sobreposição e na navegação;
  - a roda com gente é preferida;
  - liberar;
  - **com a simulação rodando:**
    - os 8 vão pra hora social;
    - 4 conversando em roda;
    - balão;
    - todos trocam de ponto;
    - passeio com waypoint;
    - todos ganham o ânimo;
    - com chuva, ninguém em ponto descoberto;
    - às 21:30, todos em casa e os lugares livres;
  - save antigo.
- **Passou também:** `b41_parque` (o parque ganhou o ponto).
