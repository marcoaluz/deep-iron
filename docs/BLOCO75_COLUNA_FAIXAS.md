# Bloco 75 — a coluna da maquete: andares em faixas

Depois da superfície (Bloco 74), a coluna de baixo no formato da maquete aprovada
(`docs/arte/bloco72/maquete/coluna_v3.png`). Comparação: `docs/arte/bloco75/comparativo.jpg`.

## Como ficou

- **Cada andar é uma faixa** larga e rasa ao longo da face sul do mapa, debaixo da floresta e da vila:
  1400 × 260 px da lógica (antes 1120 × 620 no nível 2), na escala da superfície. A parede de trás sobe até a
  laje do andar de cima; a frente é o corte aberto.
- **Bem mais juntos:** 22 degraus entre um andar e o outro (antes 36) — o chão de cada faixa aparece inteiro e
  sobra a parede de trás.
- **As galerias de madeira** logo abaixo da superfície (o "1º nível" da maquete): uma faixa de terra com o
  trilho de ponta a ponta, vagonetes, escoras e tochas. É só desenho (ninguém anda lá).
- **Parede de trás** de cada faixa com escoras de madeira e lampiões a cada tanto, e os cristais do andar
  (verde no S2, brasa no S3, ciano no S5).
- O **poço do elevador** continua na vertical da torre da vila, com a gaiola de cada andar na ponta leste da
  faixa; a **escada em espiral** fica no poço dela, à direita (nenhuma rocha dos andares na frente dela).
- A cor de cada andar (verde, laranja, frio, azul) e a decoração por dados continuam.

## Na lógica

Os andares ganharam retângulos novos, longe dos antigos (nível 2 em y=3600, abismo 4000, S4 4400, S5 4800).
Tudo dos dados (jazidas, zonas, poças, decoração, lago, ligações) foi pro mesmo lugar relativo na faixa
(`mapa/faixas_remapeia.py`, rodado uma vez); as gaiolas de chegada foram exatamente pra gaiola de cada faixa.
**Save antigo:** o que estava num retângulo antigo (gente, robô, coletor, ventilador, câmera) vai pro mesmo
lugar relativo na faixa ao carregar (`environment.posicao_nova`, `_migra_andares_antigos`).

Na faixa as coisas ficaram mais juntas (o andar encolheu na profundidade): o enfeite declarado aceita chegar
mais perto das jazidas, e o sorteio do nível 2 põe os cristais antes das pedrinhas.

## Como refazer

```
cd project.godot/prototipos/camera/arte_iso/mapa && python andares.py     # faixas, galerias, poço, espiral
<Godot> --headless --path . --import
```

Constantes no topo do `andares.py` (ANDARES com `rect`/`antigo`/`k_chao`, GALERIAS, FAIXA_FUNDO,
FAIXA_PONTAS, P). Teste `tests/blocos/b75_faixas.gd`; capturas `tests/capturas_bloco75.gd`.

## Ainda diferente da maquete

- O S3 tem poças de lava; a maquete tem um rio de lava correndo a faixa.
- A cachoeira do S4 é pequena; na maquete ela despenca da parede de trás numa poça.
- As paredes podiam ter mais coisa (lava escorrendo no S3, raízes perto da superfície).
