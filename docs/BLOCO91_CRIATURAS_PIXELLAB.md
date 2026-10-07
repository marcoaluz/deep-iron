# Bloco 91 — as criaturas do PixelLab no jogo

Pedido: "encaixe os sprites do PixelLab" (o prompt-modelo) **e** "sobre as criaturas criadas no PixelLab,
precisamos implementar elas no jogo: o Magmante, a Gosma Ácida, a Matriarca dos Lumívoros e a criatura_lumivoro".

**Skills usadas:**
- `create-game-assets` (conferir escala, sombra e quadros no jogo)
- `godot-nodes-scenes` (cenas das criaturas)
- `godot-gdscript-headless-testing` (teste de carga)

## O que encontrei

As quatro **já estavam no jogo com a arte do PixelLab**. Elas foram integradas em blocos anteriores, pela vista
isométrica (`bonecos.json`, `iso_bonecos.criatura_pose`):

| Criatura | Personagem no PixelLab | Onde entrou | Pasta no jogo |
|---|---|---|---|
| Lumívoro | `criatura_lumivoro` (84 px) | Prompts 17/28 | `criatura_lumivoro` (+ o "bruto") |
| Matriarca dos Lumívoros | `Matriarca dos Lumivoros` (128 px) | Bloco 62 (`criaturas/chefe.py`) | `criatura_lumivoro_matriarca` |
| Gosma ácida | `Gosma acida` (96 px) | Bloco 70 (`criaturas/fundo.py`) | `criatura_gosma` |
| Magmante | `Magmante` (96 px) | Bloco 70 (`criaturas/fundo.py`) | `criatura_magmante` |
| (Ferrugento) | `Ferrugento robo` (80 px) | Bloco 80 | folha própria (`visual_textura`) |

- **Animações:** cada uma tem no PixelLab **caminhada, atacar, dano e morrer** nas direções SE e NE (SO e NO são
  espelho), e o "parado" sai das rotações.
- **A contagem da conta:** a listagem mostra "8 anim" porque conta direção × animação. Não há animação nova
  sem usar. A Gosma tem um "morrer2" de reserva; o jogo usa o derretimento do Bloco 70.

**Por que você não estava vendo:**
- a **Gosma** só invade com o **S2** aberto;
- o **Magmante**, com o **S3**;
- a **Matriarca** vem como chefe **uma vez por estação**, a partir de `boss_from_season`.

Numa partida curta, só aparece o Lumívoro.

## O que entrou

- **F3 → "Criaturas: invasão com todos os tipos":** vira a noite (22:00), começa uma invasão e chama **uma de
  cada**: Lumívoro, Gosma, Magmante, Ferrugento e a **Matriarca**. Assim dá pra ver todas na hora, sem esperar
  os andares nem a estação do chefe.
- **Conferência no jogo** (`docs/arte/bloco91/criaturas_lado_a_lado.png`, na clareira, com um ipezinho pra
  comparar):

| Criatura | Altura / ipezinho |
|---|---|
| Lumívoro | 0,88 |
| Gosma | 0,88 |
| Magmante | 1,02 |
| Matriarca | 1,49 |

  - Ferrugento: um pouco menor que o ipezinho (Bloco 80).
  - **Sombra no padrão** (o Sprite2D "Shadow" de cada cena) e **filtro nearest** (o espelho iso desenha os
    quadros em nearest).
  - **Animação:** caminhada pela distância andada (Bloco 76); reação de dano e de ataque e morte pelo estado.

## Por que não troquei por SpriteFrames / AnimatedSprite2D

O prompt-modelo pede SpriteFrames/AnimatedSprite2D. **Nestas quatro, isso seria um passo pra trás:**
- a vista isométrica já desenha os quadros do PixelLab em **4 direções**;
- um AnimatedSprite2D na cena seria um **sistema paralelo** (regra 6 do CLAUDE.md) e só valeria pra vista de
  cima, que o jogador não vê.

**Pra criatura nova**, os dois caminhos já prontos são:
1. **Pasta no `bonecos.json`** (como estas). É o melhor, com direções:
   - `criaturas/<nome>.py` (cria / anima / baixa);
   - `integra.py criaturas`;
   - `CRIATURA_PASTA` no `iso_bonecos.gd`.
2. **Folha de quadros na cena** (como o Ferrugento): os campos `visual_*` do `creature.gd`, com uma direção
   espelhada.

Pra **kind novo**, além disso:
- o kind no `creature.gd` (`@export_enum`);
- a cena em `scenes/creatures/`;
- a regra de invasão no `defense.gd` (`CENA` e a quantidade por onda);
- a página no `diary.gd`.

## Testes

- **`b91_criaturas_pixellab.gd` (novo, passa): teste de carga.**
  - As 4 cenas abrem com sombra, luz, NavigationAgent2D e desenho.
  - As 4 pastas têm as 5 animações em SE e NE.
  - A defesa tem a cena de cada uma.
  - A vista iso acha os quadros (parado e caminhada) nas 4 direções.
  - Escala coerente com o ipezinho (faixas acima).
  - O chefe usa a arte da Matriarca; o Ferrugento usa a folha dele.
  - Uma página do diário pra cada.
  - **O atalho do F3 chama uma de cada, com a Matriarca.**
