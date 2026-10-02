# Prompt 18: efeitos visuais, partículas e clima

Data: 2026-10-02. Branch `isometrico`. Geração: **~37** (22 texturas pixen, 9 bases, 4 animações,
2 refeitas). O resto é **por código**, com critério (abaixo).

## Como testar (vista iso)

- **trabalho:** lascas na jazida, serragem no machado, faíscas na forja/oficina/arsenal/escavadeira,
  poeira de obra e do martelo: agora são pixels desenhados (antes, quadradinhos lisos);
- **fogo e fumaça:** a forja acesa tem **chama animada** no ponto do fogo; fumaça de chaminé em
  pixel; a fogueira do Centro (estágio 1) também;
- **mina:** nuvem de gás verde, brasa no calor, brilho de radiação; **ar tremendo** em cima das
  fendas de calor; **gotas pingando** quando a câmera está nos andares de baixo; **pedras caindo**
  no acidente da mina;
- **grandes eventos:** na **onda solar** a tela esquenta e treme; com o **escudo ativado** aparece o
  **domo** sobre a vila (nasce do gerador); com o **satélite** pesquisado, a antena ao lado do
  laboratório solta pulsos; com os **explosivos** pesquisados, aparece um caixote de dinamite perto
  do poço;
- **clima:** chuva, neve, folhas e pólen com textura de pixel (no tamanho do pixel da arte em
  qualquer zoom) e **neblina** de manhã cedo e na chuva;
- **festa:** bandeirinhas em mastros na frente do Centro, **fogos** à noite, confete no começo;
- **greve:** **barril em chamas** com fumaça escura e placas perto do Centro; os ipezinhos seguram a
  **placa de greve** erguida (antes era um ícone por cima da cabeça);
- **interface no mundo:** anel de seleção de pixel no chão, **marcador de destino** (anel encolhendo
  + setinha), **certo/xis** em cima da pegada ao construir, **brilho piscando** nos achados da mina,
  e a **cova** nova no cemitério.

GIFs: `festa_noite.gif`, `greve.gif`, `escudo.gif`, `mina_gotas_calor.gif`, `oficina_fogo.gif` e
`acidente.gif`. Fotos: `onda_solar.png`, `chuva_neblina.png`, `cemiterio.png` (e um PNG de cada GIF).

## O que virou o quê (o critério)

| Efeito | Como | Por quê |
|---|---|---|
| Lascas, faísca, brasa, serragem, poeira, fumaça, vapor, gota, pedra, chuva, neve, pólen, confete, fogos | **textura pequena feita por script** (`efeitos/particulas.py`), em faixas de cor, como partícula do Godot | 3 a 13 px: o gerador fez metade com fundo xadrez/rosto/bicho (ver abaixo); por script o tamanho e o tom saem exatos, e as cinzas pegam a cor de cada partícula do jogo |
| Nuvem de fumaça, de gás e de poeira, folha, brilho de achado, martelada | **gerado** (pixen, recortado) | nesses o gerado ficou bom |
| Chama pequena/grande, barril em chamas, bandeirinhas | **gerado + animate_image** (8 quadros) | animação de verdade, laço sem emenda |
| Onda solar, ar tremendo, domo do escudo | **shader** (lê a tela, em degraus de pixel) | tela inteira/área grande: um spritesheet ficaria enorme e repetitivo |
| Pulsos do satélite, mastros | desenhado por código | linhas simples |
| Anel de seleção, marcador de destino, certo/xis | pixel por script | formas geométricas exatas (elipse 2:1) |
| Cesto, placa de greve, cova, explosivos, antena | gerados (pendências dos Prompts 2 e 14) | — |

As partículas que já existiam no jogo **não mudaram de lugar nem de quantidade**: a cópia da vista
iso troca o quadradinho pela textura (`iso_fx.particula`, pelo nome/dono: `Sparks`, `Smoke`, `Dust`,
`Chips`, zona de perigo...). A vista de cima continua igual.

## Geração que não serviu

Das 22 texturas pequenas do pixen, 10 vieram ruins (fumaça escura com rosto, neblina virou bicho,
fogos e vapor com fundo xadrez, lasca/neve/gota/pólen com fundo). Troquei pelas feitas por script.
Custo perdido: ~10 gerações.

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `scripts/iso/iso_fx.gd` (novo) | texturas por papel, poeira, efeitos animados, e o nó dos grandes eventos (onda solar, domo, festa, greve, satélite, explosivos, gotas) |
| `scripts/iso/iso_billboard.gd` | partícula copiada com textura; chama animada nos pontos de fogueira/forja; brilho nos achados; anel de seleção |
| `scripts/iso/iso_view.gd` | cria o nó de efeitos; marcador de destino e certo/xis em pixel; ar tremendo nas fendas de calor |
| `scripts/iso/iso_sky.gd` | clima com textura de pixel (pixel inteiro em qualquer zoom) e neblina |
| `scripts/iso/iso_art.gd` | barril (meta `iso_fx`) e cova do cemitério |
| `scripts/iso/iso_bonecos.gd` | placa de greve e cesto de coleta na mão |
| `scripts/iso/iso_luz.gd` | luz `FireLight` = fogueira (barril da greve) |
| `scripts/workers/ipezinho.gd` | pedrinhas caindo no acidente da mina (só visual) |
| `prototipos/camera/arte_iso/efeitos/` | `particulas.py`, bases e animações geradas |
| `prototipos/camera/arte_iso/integra.py` | `fx` (texturas + tiras com caixa); peças novas no `props` |
| `assets/game/iso/fx/` (novo), `assets/game/iso/props/{cova,explosivos,antena,cesto,placa_greve}.png` | arte |
| `tests/blocos/p18_efeitos.gd` (novo), `tests/capturas_fx.gd` (fotos/GIFs) | teste (23 verificações) e capturas |

## Limites

1. O domo é desenhado por cima de tudo, translúcido: a metade de trás também fica na frente dos
   prédios.
2. Os mastros das bandeirinhas são finos (2 px) e quase somem à noite.
3. A antena e os explosivos aparecem perto do laboratório/poço sem bloquear o caminho (são enfeite).
