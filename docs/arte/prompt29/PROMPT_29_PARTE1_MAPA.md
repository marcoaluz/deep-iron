# Prompt 29, parte 1: o mapa novo no jogo

Data: 2026-10-01. Branch `isometrico`. Sem geração no PixelLab (saldo **1.439**).

O Prompt 29 é grande e sai em partes testáveis. Esta é a 1ª: **o mapa novo jogável** (o
layout aprovado no Prompt 27, com o céu). Personagens, prédios, objetos e o nível 2/abismo
com a arte nova vêm nas próximas partes.

## Como testar

Abra o jogo: a vista isométrica já abre ligada, no mapa novo. O **F3** ainda volta pra vista
de cima (só pra conferir; ela some no fim do Prompt 29). **F4** mostra as caixas.

**O que olhar:**

- a vila em terraços: terraço de cima (Centro da Vila, casas, enfermaria), terraço do meio
  (oficina, armazém), fundo da pedreira (jazidas, escavadeira no oeste, elevador no leste);
- os bonecos sobem e descem **pelas escadas e rampas**; penhasco bloqueia;
- as 4 galerias na frente das 4 bocas de mina, no paredão do terraço de cima;
- a paliçada entre a floresta e a vila, com o portão da floresta na abertura; o portão do
  poço junto do elevador;
- o céu muda com a hora (manhã, dia, fim de tarde, noite; mais cinza na chuva), com a serra
  e as montanhas atrás da moldura de morros; embaixo do corte do terreno, névoa;
- construir: só em chão plano (o aviso diz o porquê: beira do penhasco, escada, paredão,
  paliçada);
- **os andares de baixo em camadas** (o formato do "Layers Exploded View" que você mandou):
  a superfície em cima, a laje do **nível 2** embaixo e a do **abismo** por último, alinhadas
  no canto da frente; as zonas pintam o chão (gás e radiação no nível 2, calor no abismo); o
  subsolo fica sempre mais escuro e o céu some quando a câmera desce.

## Como ficou

Capturas nesta pasta: `mapa_inteiro.png`, `vila.png`, `norte_ceu.png`, `dia.png`,
`tarde.png`, `noite.png`, `camadas.png` (a superfície e os 2 andares de baixo), `nivel2.png`,
`abismo.png`.

**Os prédios, bonecos e árvores ainda são a arte antiga**, em pé no mapa novo (a troca é a
parte 2 em diante). A arte antiga aparece 1,5× maior pra ficar proporcional ao mapa.

## Decisões

| Decisão | Por quê |
|---|---|
| **A lógica continua no chão de sempre**; a vista desenha a arte nova na escala **1,5** | o mapa foi montado com as posições do jogo × 1,5 (Prompt 27). Assim velocidades, distâncias, alcances e saves não mudam |
| Terreno **assado em imagens** por região (`monta.py exporta`): alto, meio e paredão = imagem + caixa; cada escada = caixa de rampa; fundo e moldura = fundo da cena | regra do contrato: cada platô = uma imagem = a caixa dele na ordenação |
| **Mapa de altura** exportado junto (`mapa.json`): altura por tile, escadas, bocas | a altura dos bonecos, o clique e a navegação saem dele |
| **Navegação:** penhasco = parede; escada liga os degraus no sentido dela; paliçada = parede menos a abertura do portão | os terraços passam a valer no jogo |
| **Céu aberto**: as cores do ciclo dia/noite viram as do cenário aprovado (dia claro, noite azulada) | decisão do Prompt 27 ("a vila sai da caverna") |
| **Migração**: o que cair em lugar inválido (em cima da beira, escada, paliçada, paredão) vai pro ponto válido mais perto e fica anotado (`environment.migrated`) | regra do Prompt 29 pros saves antigos. Folga pequena (4 px): um prédio construído certinho perto da beira não "anda" ao carregar |
| **Andares de baixo empilhados** (camadas separadas), não colados num corte só | os andares do jogo são grandes no chão (o nível 2 tem ~1.700 px de fundo): num corte colado, quase só se veria a borda de cada um; separados, cada laje aparece inteira e dá pra jogar lá embaixo |
| Os 2 andares que o jogo tem (nível 2, abismo); não os 5 da imagem | sem criar nada: mais andares precisam de gameplay novo (Prompt 31) |

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `prototipos/camera/arte_iso/mapa/monta.py` | `python monta.py exporta`: o terreno por região + `mapa.json`; escadas acham a beira sozinhas (antes 3 ficavam uma fileira fora, sem ligar os terraços); 4ª boca de mina (o jogo tem 4 galerias) |
| `prototipos/camera/arte_iso/mapa/andares.py` (novo) | os andares de baixo em lajes (`andar_nivel2.png`, `andar_abismo.png`, `andares.json`) |
| `assets/game/iso/mapa/`, `assets/game/iso/ceu/` (novos) | as imagens do terreno, dos andares e do céu, e os `.json` |
| `scripts/core/environment.gd` | modo mapa novo: `height_at` (terraços, rampa na escada, andares), penhasco e paliçada na navegação, `footprint_reason` (chão plano), `migrate_positions`, `view_ground` / `level_of` (andares empilhados); sem as bordas de pedra, clareira e túnel antigos no mapa novo |
| `scripts/iso/iso_view.gd` | escala 1,5; terreno (caixas dos terraços e escadas, fundo e moldura atrás); andares de baixo (laje + o que o jogo desenha no chão por cima, tom escuro); clique volta pro andar certo; pegada e raio do posicionador na altura do terraço; ligada por padrão com o mapa novo |
| `scripts/iso/iso_sky.gd` (novo) | céu por hora, nuvens, montanhas e serra com parallax, névoa embaixo |
| `scripts/iso/iso_billboard.gd` | caixas e posições pela vista (escala, andar); tom do subsolo |
| `scripts/iso/iso_core.gd` | "quem está atrás" simétrico: separadas em sentidos opostos = sem restrição (terraços) |
| `scripts/iso/iso_order.gd` | conserto local: quando quem anda fica entre duas coisas paradas que estavam na ordem "errada" pra ele (uma atrás, outra na frente, sem relação entre si), a da frente é adiantada só ali. Antes dava 1 par errado a cada ~10 rodadas do teste; agora 0 em 12 |
| `scripts/core/camera_controller.gd` | o ponto do chão no centro da tela vem do raio (acha o terraço) |
| `scripts/core/house_placer.gd` | recusa construir fora de chão plano (com o motivo) |
| `scripts/core/save_manager.gd` | migração ao carregar save antigo |
| `scripts/core/defense.gd` | "portão do túnel" virou "portão da floresta" |
| `scenes/game/main.tscn` | mapa novo ligado; posições no layout aprovado; cores do dia/noite de céu aberto |
| `tests/blocos/p29_mapa.gd` (novo) | o teste do mapa novo |
| `tests/blocos/b37_…`, `b41_…`, `p28_iso.gd` | mudados de propósito: Centro no lugar novo; o parque mede o ânimo a partir do quadro seguinte (o quadro em que ele nasce é longo); o p28 usa a escala e o layout novos |

## Testes

Tudo com a pasta de usuário isolada.

| Bateria | Resultado |
|---|---|
| GUT completo (29 blocos + 11 testes rápidos), mapa novo e vista iso ligada | **40/40** |
| `p29_mapa` (novo) | alturas (96/64/0, rampa na escada), caminho do fundo pro alto pela escada (914 contra 510 em linha reta: não atravessa o penhasco), floresta → vila só pelo portão, construir recusado na beira/escada/paliçada, **0 pares na ordem errada em ~300** (12 rodadas seguidas), clique no nível 2 e no abismo volta pro ponto certo, céu e ambiente por hora, migração (2 bonecos em lugar impossível mudados; o que estava na escada fica) |
| `p28_save` com uma **cópia do teu save** | carrega no mapa novo: 7 ipezinhos, 569 créditos, nada precisou mudar de lugar |
| Refazer a navegação | ~75 ms (o mapa antigo: ~68 ms) |

**Sobre o teu save de verdade:** a conferência por md5 acusou que o `savegame.json` mudou
desde o começo do Prompt 28: backup às 13:21:50 e save às 13:25:26 de hoje, o jeito de uma
partida jogada (bate com o teu teste do Prompt 28). Todas as minhas execuções usaram a pasta
isolada. Se não foste tu, me avisa.

## Limites e desvios

1. **A arte em pé ainda é a antiga** (prédios, bonecos, árvores, pedras, jazidas), 1,5×
   maior. A troca é a parte 2 em diante.
2. **O nível 2 e o abismo** usam o chão novo, mas a decoração deles (pedras da borda,
   cristais, jazidas) ainda é a antiga. As 2 lajes aparecem separadas da superfície, sem
   coluna de rocha nem poço entre elas; os elevadores ainda são a arte antiga.
3. **Refazer a navegação** (ao construir) leva ~75 ms; já era ~68 ms no mapa antigo (o tranco
   existia antes). Pode virar cálculo em segundo plano depois.
4. **Clima** (chuva, neve) não aparece na vista iso: o céu fica mais cinza na chuva, mas os
   pingos e flocos voltam com os efeitos novos (Prompt 18).
5. **A vista de cima** (F3) fica quase vazia no mapa novo: só serve pra conferir; sai no fim
   do Prompt 29.
