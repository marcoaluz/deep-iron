# Prompt 15: animais

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/animais/`, montador
`animais/animais.py`. Nada integrado ao jogo.

## Conferido no código

O caçador hoje caça na **toca do coelho** (`hunt_spot.gd`): coelho fora, só as orelhas, toca
vazia. Não existe animal andando. O **javali** e os coelhos soltos vêm da visão do mapa
(`docs/arte/MAPA_VISAO.md`).

## O que ficou pronto

| Grupo | Peças |
|---|---|
| **Coelho** | 8 direções; **andar** (pulinhos), **fugir** (saltos longos, orelhas pra trás), **abatido** (deita), em SE/NE + espelho |
| **Javali** (novo) | 8 direções; **andar** (trote farejando), **fugir** (galope), **abatido** |
| **Tocas e restos** | toca do coelho vazia / com coelho fora / só as orelhas (os 3 estados do jogo), **toca do javali** (oca sob raízes), ninho, carcaça de coelho e de javali **de lado, sem sangue**, carne embrulhada, couro, couro enrolado |
| **Fauna de ambiente** (2 quadros cada, GIF) | corvo, pardal, morcego, rato, mariposa |

## Entregas (nesta pasta)

`prancha_animais.png`, `coelho_{andar,fugir,abatido}.gif`, `javali_{andar,fugir,abatido}.gif`,
`corvo.gif`, `pardal.gif`, `morcego.gif`, `rato.gif`, `mariposa.gif`.

## Custo

**~110 gerações.**

## Desvios

1. **O PixelLab não aceita referência pra quadrúpede.** Fiz coelho e javali como personagem
   comum (rotação v3 a partir do desenho), e funcionou bem nas 8 direções.
2. **"Abatido" na direção de trás (NE):** o animal só se abaixa. Pra pose final parada no
   chão, o código usa as **carcaças de lado**, que leem melhor.
3. **Cervo e ave grande** (sugeridos no prompt) não entraram: o jogo não tem e o saldo é
   curto. Ficam pra quando o gameplay de caça crescer.
