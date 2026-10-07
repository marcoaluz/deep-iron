# Mapa ampliado — o leste (Bloco 67)

## Passo 0 (o que havia)

- **Tamanho:** o terreno é montado em tiles por `prototipos/camera/arte_iso/mapa/monta.py` (tile 32 px de
  arte, 1,5 px de arte por px da lógica): 71 × 69 tiles = x −760…754, y −1040…432 na lógica. Nada de
  TileMap: o `monta.py exporta` grava imagens por **região** (fundo, paredão, terraços, escadas,
  moldura) e o `mapa.json` (mapa de altura, escadas, bocas); o jogo lê isso (`environment.gd`) e a vista
  iso desenha as regiões (`iso_view.gd`, em blocos de 256 px por causa das luzes).
- **Onde o tamanho aparecia:** `map_rect` e `clearing_rect` na cena (`main.tscn`), `deep_rect`/`abyss_rect`
  (andares de baixo, **na lógica ao sul**, y 700+), a câmera (`world_rect`), o posicionador
  (`walkable_rect`), a navegação (todo o terreno anda; penhascos e paliçada bloqueiam — já genérico pelo
  mapa de altura), o clima (`clearing_rect`), as invasões (clareira) e o corte da mina.
- **Save:** posições absolutas na lógica. Crescer sem mexer na origem mantém tudo no lugar.
- **Pra onde dá pra crescer:** o **sul** é dos andares de baixo (na lógica) e o **norte/oeste** é a
  moldura de morros (cenário). Sobra o **leste**.

## O que foi feito

- `monta.py`: `LESTE_EXTRA` (2880 px da lógica antiga; `DEEP_IRON_LESTE` muda) — 206 × 69 tiles,
  **2,9× a área** de antes. As zonas continuam pro leste: floresta (atrás da paliçada, que se estende
  sozinha), a encosta (terraço de cima, com cascalho/laje) e a pedreira nova (fundo). A área nova sai em
  **pedaços** de 48 tiles (`alto_l0`, `fundo_l1`, `moldura_l2`...): a maior imagem nova tem 2,8k × 1,6k
  px; as regiões antigas ficaram com o mesmo nome e tamanho. Os andares de baixo (`andares.py`) se
  reempilham embaixo do novo canto da frente do mapa (a lógica deles não muda).
- **Trancado até desbravar:** parede na navegação na fronteira (x 754), névoa escura por cima na vista
  iso, ninguém escolhe estação de lá, não dá pra construir. Trancado, o terreno e o conteúdo do leste
  nem desenham nem processam. **"Desbravar o leste"** (menu de construção > Vila; Centro da Vila no
  estágio 2; 900 cr + 120 ferro + 160 madeira; obra do engenheiro de 80 s na fronteira) abre: a névoa
  some, a navegação e a área de construir crescem.
- **Conteúdo do leste** (nomes fixos, existem desde o começo: o save acha cada um pelo nome): 7 jazidas
  (ferro, cobre, carvão, prata), 14 árvores, uma toca de coelhos, mata e pedras de enfeite.
- **Save:** `centro_vila.leste_aberto` (save antigo: trancado).
- Câmera cobre o leste desde o começo (com névoa); clima, noite e invasões seguem iguais (as criaturas
  continuam vindo da clareira de sempre e passando pelo portão).

## Desempenho (bench_cena, i3-8100 + RX 580, 1920×1080 sem vsync)

| cenário | mapa antigo (código atual) | mapa com o leste (trancado) |
|---|---|---|
| A — início | 7,8 ms (129 FPS) | 8,9 ms (113 FPS) |
| B — vila média | 10,7 ms (94 FPS) | 11,2 ms (89 FPS) |
| C — vila cheia + invasão + chuva + noite | 19,1 ms (52 FPS) | 21,3 ms (47 FPS) |

O leste trancado custa ~1–2 ms (ordem de desenho com mais caixas, a moldura nova, mais nós). Já
reduzido: trancado ele não desenha nem processa; a textura do chão (só pros andares de baixo) deixou de
cobrir o mundo inteiro. Os números do Bloco 53 (C: 56 FPS) eram antes dos Blocos 54–66 (bichos, chefe,
vagonete...): sem o leste, o código de hoje faz 52 FPS no C.

Fotos: `tests/capturas_leste.gd`.
