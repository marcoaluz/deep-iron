# Escala visual: auditoria e proposta

Data: 2026-09-29. **Só leitura.** Nenhum asset, cena, `project.godot` ou código de jogo foi
alterado. Este documento serve pro Marco escolher o número antes de qualquer arte começar.

Base: o código e os assets do repositório, `docs/pixellab_teste/gerado/RELATORIO.md` e o
briefing. (O `deep-iron-dev-log.md` citado no briefing não está no repositório. A conclusão
do teste do PixelLab veio do RELATORIO.md.)

---

## 1. Como está hoje (números exatos)

### 1.1 Regra geral de pixel

- Toda a arte é desenhada pequena e mostrada em **escala 2**: `environment.gd`
  `pixel_scale = 2.0`, e `scale = Vector2(2, 2)` em todas as cenas de prédio e personagem.
  **1 pixel de arte = 2 px de mundo.**
- Filtro de textura "nearest" (`default_texture_filter=0`). Não tem snap de pixel 2D ligado.
- Toda a arte é **procedural**: `tools/gen_sprites.py` (4.263 linhas, 55 funções `build_*`)
  gera 219 PNGs em `assets/game/`. O que está em `assets/Sprites/` (Kenney, StewV, OreSheet)
  não é usado por nenhuma cena ou script.

### 1.2 Personagens

| Peça | Arte por quadro | Quadros | No mundo (escala 2) |
|---|---|---|---|
| Ipezinho (todas as funções) | **16×17** | 4 (caminhada; o 0 é o parado) | 32×34 |
| Acessórios (bota, lenço, detalhe) | 16×17 (folha 64×51 = 3 variantes) | 4 | 32×34 |
| Item na mão (picareta, machado, arco, armas…) | 11×13 a 14×13 | 1 | 22×26 a 28×26 |
| Ícones sobre a cabeça (raiva, curativo, chapéu, carga) | 7×7 a 11×13 | 1 | 14×14 a 22×26 |
| Lumívoro | 20×16 | 2 | 40×32 |
| Ferrugento | 22×16 | 2 | 44×32 |
| Robô | 20×22 | 3 | 40×44 |

- **Não existe sprite de personagem diferente por função.** Engenheiro, guarda, médico,
  cozinheiro etc. usam o **mesmo corpo 16×17** com outra roupa pintada por cima: 9 funções ×
  menino/menina = 18 roupas, cada uma com 6 variações de pele/cor = **108 folhas 64×17**.
  Mais a base `ipezinho_walk.png` e os 3 acessórios, são **112 PNGs de personagem** que saem
  de **1 corpo + 18 roupas** no gerador.
- Só existe a vista de frente. Esquerda e direita são a mesma imagem espelhada.

### 1.3 Chão, paredes e galerias

**Não existe tileset nem TileMap.** Nenhuma cena usa TileMap/TileSet. O chão é **uma
textura sem emenda repetida** por área (`_tiled_sprite` com `texture_repeat`):

| Área | Textura | Arte | Repete a cada (mundo) |
|---|---|---|---|
| Mina (superfície, galerias) | `floor_cave.png` | 64×64 | 128 px |
| Clareira | `floor_clareira.png` | 64×64 | 128 px |
| Fundo | `floor_deep.png` | 64×64 | 128 px |
| Abismo | `floor_abyss.png` | 64×64 | 128 px |
| Parede de rocha (atrás de tudo) | `wall_rock.png` | 32×32 | 64 px |

A borda do mapa e as paredes das galerias são **pedras soltas** espalhadas por cima.

| Decoração | Arte | Variantes | Escala usada |
|---|---|---|---|
| Pedregulho (borda/galeria) | 16×16 | 5 | 2 × **1,2 a 1,9** (sorteada) |
| Pedrinha | 4×5 a 9×7 | 4 | 2 |
| Cristal | ~20×24 | 4 | 2 × **1,1 a 1,7** (sorteada) |
| Árvore | 24×42 | 3 quadros | 2 × **0,9 a 1,2** (sorteada) |
| Jazidas de minério | 16×16 | 5 minérios × 3 estágios = 15 | 2 |

**Peças distintas de terreno hoje:** 5 texturas de chão/parede + 5 pedregulhos + 4 pedrinhas
+ 4 cristais + 1 árvore. A "falta de variedade" tem causa concreta: cada área inteira é
**uma** textura de 64×64 repetindo a cada 128 px de mundo, o que dá cerca de 170 px de tela
no zoom inicial. O olho acha o padrão.

**Densidade inconsistente:** pedregulhos, cristais e árvores são esticados por escalas
sorteadas não inteiras. Um pixel de arte vira de 2,4 a 3,8 px de mundo, contra 2 em todo o
resto. O ícone de raiva usa escala 1,5.

### 1.4 Prédios e objetos

Tamanho de **um quadro** de arte → no mundo (escala 2):

| Prédio | Arte | Mundo | | Prédio | Arte | Mundo |
|---|---|---|---|---|---|---|
| Casa | 30×26 | 60×52 | | Oficina / Vestiário | 42×34 | 84×68 |
| Comedouro | 32×20 | 64×40 | | Arsenal | 46×38 | 92×76 |
| Enfermaria | 34×28 | 68×56 | | Parque | 50×36 | 100×72 |
| Laboratório | 34×30 | 68×60 | | Coletor de madeira | 52×40 | 104×80 |
| Campo de treino | 34×24 | 68×48 | | Centro da Vila | 90×76 | 180×152 |
| Taverna | 36×28 | 72×56 | | Escavadeira (camadas) | 80×96 | 160×192 |
| Armazém | 38×34 | 76×68 | | Elevador | 24×30 | 48×60 |

- **Mesma densidade dos personagens** (tudo em escala 2): isso está consistente.
- **Nenhum grid.** As larguras são 30, 32, 34, 36, 38, 42, 46, 50, 52, 90, sem múltiplo
  comum. O posicionamento é livre, por pixel (`house_placer.gd`).
- **Proporção "de brinquedo":** a casa tem 26 px de altura contra 17 do personagem, só
  **1,5×** a altura dele. O Centro da Vila tem 4,5×.
- 28 folhas de prédio, **64 quadros** no total (Centro 5 estágios, Arsenal 4, reator 5,
  escudo 5, casa 3…).

### 1.5 Janela e câmera

| Item | Hoje |
|---|---|
| Resolução base | **1152×648** (padrão do Godot: o `project.godot` não define `window/size`) |
| Stretch mode | `canvas_items` |
| Stretch aspect | `expand` |
| Tela cheia | **Não existe:** nenhuma tecla, opção ou chamada de `window_set_mode` |
| Câmera | `Camera2D` própria (`scripts/core/camera_controller.gd`). O plugin **Phantom Camera está ligado mas nenhuma cena usa** |
| Zoom | inicial **1,3**; mín. 0,6; máx. 3,0; passo 1,15, suave |

**O que isso dá na tela:**

| Situação | Pixel de arte na tela | Ipezinho na tela | % da altura | Área visível (px de arte) |
|---|---|---|---|---|
| Janela 1152×648, zoom 1,3 | 2,6 px | 42×44 | 6,8% | 443×249 |
| Maximizado em 1080p (×1,667), zoom 1,3 | **4,33 px** (não inteiro: colunas de pixel desiguais) | 69×74 | 6,8% | 443×249 |

### 1.6 Comparação com o Stardew (referência do briefing)

Stardew: tile 16×16, personagem 16×32, 4× em 1080p. Na tela: tile de 64 px, personagem de
64×128 px (**11,9%** da altura). Mostra 480×270 px de arte (30 × 16,9 tiles).

**Conclusão da auditoria:** o Deep Iron mostra **quase a mesma quantidade de pixels de arte
que o Stardew** (443×249 contra 480×270). O problema não é o zoom: é o **canvas**. O nosso
personagem tem **17 px de arte de altura**, o do Stardew tem **32**. Aumentar só o zoom deixa
o boneco maior mas com os mesmos 16×17 pontos. É a mesma conclusão do teste do PixelLab: em
16×17 nenhuma geração, por IA ou à mão, cabe rosto, lanterna e macacão legíveis.

---

## 2. Opções de novo padrão

As três opções mantêm as **coordenadas do mundo** (mapa 1440×880, posições, raios,
velocidades). Por isso save, navegação e testes quase não mudam. Muda a quantidade de pixels
de arte por pixel de mundo.

> **Descartado de propósito: "dobrar o mundo"** (arte 2× e continuar em escala 2, com o mapa
> dobrando). Na tela fica **idêntico** à Opção A com o dobro de zoom, mas obriga a mexer em
> todas as coordenadas, raios, velocidades, saves e testes. Custa muito e não ganha nada.

### Opção A — Dobrar tudo (2×), mesma cara

- **Arte 2× maior em pixels, mostrada em escala 1:** 1 px de arte = 1 px de mundo.
- Personagem **32×34** (mesma silhueta chibi, 4× mais pixels). Casa 60×52, Centro 180×152,
  chão 128×128 (ou peças de 32 com variantes), jazida 32×32.
- **Tamanho no mundo idêntico ao de hoje.** Nenhuma coordenada, colisão, raio ou save muda.

| Proporção | Valor |
|---|---|
| Personagem ÷ casa (altura) | 34 ÷ 52 (igual a hoje) |
| Largura da cabeça (com capacete) | 12 px → **24 px** |
| Tela 1080p, base 1280×720, zoom 2 (3 px por px de arte) | personagem **102 px** (9,4%); vê 640×360 do mundo |
| Tela 1080p, zoom 4/3 (2 px por px de arte) | personagem 68 px (6,3%, igual a hoje, com o dobro de detalhe); vê 960×540 |
| Tela 1080p, zoom 8/3 (4 px por px de arte) | personagem 136 px (**12,6%, tamanho Stardew**); vê 480×270 |

**Prós:** menor risco. O visual já aprovado só ganha detalhe, e dá pra trocar asset por
asset sem quebrar nada. 32×34 é um canvas onde o PixelLab consegue trabalhar (o
`create_image_pro` aceita até 42 px com 64 candidatos pelo mesmo preço).

**Contras:** mantém a proporção "de brinquedo" (casa só 1,5× a altura do personagem). Não
cria um grid de tiles: a variedade do chão tem que vir de variantes da textura.

### Opção B — Proporção Stardew (grid de 16, personagem de 2 tiles)

- **Grid de 16 px de arte = 16 px de mundo** (escala 1). O chão vira **tileset de verdade**
  (peças 16×16 com variantes e transições), o que ataca direto a falta de variedade.
- Personagem **16×32** (1×2 tiles; ou 20×32 pra manter o cabeção). Mesma altura no mundo de
  hoje (32 contra 34), porém mais estreito: menos chibi, mais "gente".
- **Prédios em tiles e maiores em relação ao personagem**, como no Stardew: casa ~5×5 tiles
  (80×80, contra 60×52 hoje); Centro ~12×10 (192×160). A casa passa a ter ~2,5× a altura
  do personagem.

| Proporção | Valor |
|---|---|
| Personagem | 2 tiles de altura (igual ao Stardew) |
| Casa ÷ personagem | ~2,5× (hoje 1,5×; Stardew 3 a 4,5×) |
| Tela 1080p, base 1280×720, zoom 8/3 (4 px) | tile 64 px, personagem 128 px (**11,9% = Stardew**); vê 30×16,9 tiles |
| Tela 1080p, zoom 2 (3 px) | tile 48 px, personagem 96 px (8,9%); vê 40×22,5 tiles |

**Prós:** é a proporção que o briefing cita como a que funciona. Tileset de verdade dá
variedade. Os prédios ficam "de verdade".

**Contras:** é **redesenho**, não ampliação: o ipezinho muda de proporção. Os prédios mudam
de tamanho no mundo, então as pegadas do posicionador, `contains_point` (39 retângulos no
código), raios de vaga (~48 valores) e `offset` de sprite precisam de ajuste. Save antigo
carrega, mas prédios vizinhos podem ficar encavalados (só se valida a posição ao construir).
Alguns testes que dependem de posição perto de prédio provavelmente precisam de ajuste.

### Opção C — Só janela, tela cheia e zoom (sem redesenho)

- Mesma arte 16×17. Resolução base 1280×720, tela cheia (F11), zoom inicial maior e com
  paradas "nítidas".
- 1080p, zoom 2 (6 px por px de arte, já que a escala 2 continua): personagem **102 px**
  (9,4%), mas com os mesmos 16×17 pontos.

**Prós:** 1 bloco e nenhuma arte. Serve de **Fase 0** pra A ou B de qualquer jeito.

**Contras:** não resolve a legibilidade. O boneco só fica maior e mais "quadradão". Não
destrava o PixelLab.

---

## 3. Janela e tela cheia propostas (valem pra A, B e C)

| Configuração | Proposta | Por quê |
|---|---|---|
| Resolução base | **1280×720** | ×1 em 720p, ×1,5 em 1080p, **×2 em 1440p, ×3 em 4K** (inteiros). Com 1920×1080 de base, a HUD e o menu de construção (cartões de 190 px, fontes 11–20) encolheriam 1,67× numa tela 1080p. Com 1280×720 encolhem só ~10% em relação a hoje. |
| Stretch mode | **`canvas_items`** (manter) | A câmera é RTS com zoom suave. O modo `viewport` renderiza num buffer pequeno e o zoom contínuo tremeria. |
| Stretch aspect | **`expand`** (manter) | Monitor ultrawide vê mais mapa em vez de ganhar faixa preta. |
| Tela cheia | **F11** alterna (Alt+Enter também), opção "Tela cheia" nas configurações, lembrada no `settings.cfg`; começa maximizado | Hoje não existe. |
| Zoom | Paradas "nítidas": zoom em que 1 px de arte vira um número **inteiro** de px de tela. Em 1080p/base 720: 4/3, 2, 8/3. A rodinha continua suave e, ao parar, assenta na parada mais perto (opcional). | Hoje, maximizado em 1080p, o pixel de arte vira 4,33 px: colunas desiguais. |
| Decoração | Trocar as escalas sorteadas (1,2–1,9) por **variantes desenhadas em tamanhos diferentes** | Densidade de pixel única em tudo. |

---

## 4. Tamanho do trabalho de migração

### 4.1 O que existe pra redesenhar

| Categoria | PNGs | Desenhos de verdade | Quadros |
|---|---|---|---|
| Personagem (roupas) | 112 | 1 corpo + 18 roupas + 3 acessórios (as 6 cores saem por paleta) | 4 por folha |
| Itens na mão | 10 | 10 | 1 |
| Ícones pequenos | 20 | 20 | 1 |
| Criaturas / robô | 3 | 3 | 2–3 |
| Prédios / estruturas | 28 | 28 | **64** no total |
| Terreno (chão/parede) | 5 | 5 (+ variantes novas) | — |
| Decoração do mapa | 22 | 22 | — |
| Jazidas | 15 | 5 minérios × 3 estágios | — |
| Clima | 4 | 4 | — |
| **Total** | **219** | **~130 desenhos** | |

### 4.2 Fases (sem quebrar o jogo no meio)

Como o **tamanho no mundo não muda** (A) ou muda pouco (B), cada fase troca um grupo de
assets e o jogo continua funcionando. Entre fases a densidade fica misturada (umas coisas
nítidas, outras em escala 2): é feio por um tempo, mas não quebra.

| Fase | O quê | A (blocos) | B (blocos) |
|---|---|---|---|
| 0 | Janela 1280×720, tela cheia F11, zoom com paradas nítidas | 1 | 1 |
| 1 | Terreno: chão com variantes (A) ou tileset 16 (B), parede, pedras, cristais, árvore, jazidas (~42 PNGs) | 1–2 | 2–3 |
| 2 | Personagens: corpo, 18 roupas, acessórios, itens na mão, ícones, criaturas (~148 PNGs). **Aqui volta o PixelLab**, em 32×34 (A) ou 16×32 (B) | 2–3 | 3–4 |
| 3 | Prédios: 28 folhas / 64 quadros. Em B, também pegadas, `contains_point` e vagas | 2–3 | 3–4 |
| 4 | Clima, sombras, limpeza (tirar `pixel_scale`, conferir `offset`s) | 1 | 1 |
| | **Total** | **~7–10** | **~10–13** |

A Opção C é só a Fase 0 (1 bloco).

### 4.3 Testes GUT, save e menu do Bloco 46

| | A | B | C |
|---|---|---|---|
| **Testes GUT** | Passam se as **folhas mantiverem nome, nº de quadros e ordem** (b26 confere textura por nome e quadro; b32 e b38 conferem índice de quadro). Nenhum teste usa tamanho em pixel. O `tools/sprite_regress.py` precisa de foto nova de referência (é o esperado). | Os de posição perto de prédio (vaga, porta, raio: b31b, b37, b41, b45…) podem precisar de ajuste | Sem impacto |
| **Save antigo** | Sem impacto (mundo igual) | Carrega; prédios vizinhos podem encavalar (maiores) | Sem impacto |
| **Menu de construção (Bloco 46)** | Ícones automáticos (`_icon` calcula a largura do quadro) e mais nítidos | Automáticos; revisar se prédio grande cabe no ícone de 64 px | HUD ~10% menor com a base 1280×720; o menu (860 px) cabe |
| **Código** | `offset` de sprite em px de arte dobra ao passar pra escala 1 (13 lugares); o resto é em px de mundo e não muda | + pegadas, 39 `contains_point`, ~48 raios de vaga, posição da ferramenta na mão | Só `project.godot`, câmera e configurações |

---

## 5. Pra decidir

1. **A, B ou C?** Minha leitura: **C agora (Fase 0) e depois A**. A mantém a cara que você
   já aprovou e não mexe em mundo nem em save. Mas **B** é a escolha certa se o que incomoda
   é também a proporção de brinquedo (casa quase do tamanho do boneco) e o chão sem tileset.
2. **Zoom inicial:** mais mapa (zoom 4/3: personagem 68 px, vê 960×540) ou mais personagem
   (zoom 2: 102 px, vê 640×360)? Colony sim com 8+ ipezinhos pede ver bastante mapa. O zoom
   máximo pode chegar no tamanho Stardew.
3. **Paleta:** o briefing pede densidade de Stardew com paleta mais escura e suja. A paleta
   atual ("gasta", terrosa) já é essa e continua valendo em A e B.

## 6. Fora de escopo, mas anotado

**2.5D** (peças em corte lateral, com rotação e zoom) fica **fora** desta proposta. É mudança
de projeção e de câmera, não de resolução de asset. **Não foi descartado:** o Marco quer
revisitar depois. Qualquer opção acima (A ou B) continua compatível com essa conversa
futura, porque não mexe na câmera nem na projeção.
