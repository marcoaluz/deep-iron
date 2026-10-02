# Bloco 71 — S4 (cachoeira e lava) e S5 (lago azul)

Data: 2026-10-02. Branch `isometrico`. Teste: `tests/blocos/b71_s4_s5.gd`. Fotos: `tests/capturas_fundo.gd`
(s4_cachoeira, s4_lava, s5_lago, s5_casas).

O documento pedia "só depois da Rota A, com a arte desses ambientes aprovada". A Rota A (vista
isométrica) já é o jogo; a arte dos dois ambientes foi gerada neste bloco (abaixo) e está pra revisão.

## Passo 0

- Os andares de baixo eram **dois retângulos fixos** no ambiente (`deep_rect`, `abyss_rect`), com
  `is_deep`/`is_abyss`/`level_at` e a navegação montados à mão pra cada um; S4/S5 existiam só como
  "em breve" nos dados (Bloco 68).
- A **plataforma do abismo** (`abyss_shaft.gd`) era a única ligação "consertável", com o grupo, o nível
  e os textos fixos.
- As **lajes** da vista iso saem do `prototipos/camera/arte_iso/mapa/andares.py` (ladrilhos do Prompt 7
  empilhados embaixo da superfície, `andares.json`).

## O que entrou

| Peça | Como |
|---|---|
| **Nível novo = só dados** | `NivelMina` ganhou `rect`, a ligação (`ligacao_topo`, `ligacao_fundo`, `ligacao_acima`, `conserto`, `conserto_minerio`, `conserto_estagio`), `obstaculos`, `animo`/`animo_motivo` e `titulo_abertura`. O ambiente lê os níveis com `rect` (`niveis_extra()`, guardado): área andável, `is_deep`, `level_at` (4, 5), `area_at`, perigo de acidente (= abismo), câmera e navegação (cada nível é uma ilha ligada pela plataforma). |
| **Plataformas S3→S4→S5** | a mesma plataforma do abismo, parametrizada (`grupo`, `nivel_id`, `requer_grupo`, `repair_ore`), montada pelo ambiente a partir do `.tres` (`ElevadorS4`, `ElevadorS5`). Conserto em cadeia: o S4 pede o abismo aberto + pesquisa **Bombas d'água** + vila no estágio 5 + 14 peças raras + 2.500 cr + 120 solarita; o S5 pede o S4 aberto + 18 peças + 3.500 cr + 80 cristal rubro. A janela de conserto do abismo serve pra todas (clicar na plataforma troca o alvo). Abriu: faixa e página no diário. Todas no grupo `elevadores` (a gaiola com tempo e lotação do Bloco 68 vale pra elas). |
| **S4 — cachoeira e lava** | poças d'água (tipo novo `agua`: sem traje, atrasa 80% e **molha** por 20 s — molhado, a lava queima a 30%), 4 poços de lava, cristal rubro/verde e solarita, a cachoeira animada na parede do fundo, cristais de 4 cores; ânimo −4 ("o barulho e o vapor da cachoeira"). Magmantes continuam vindo do fundo. |
| **S5 — lago azul** | o lago (elipse) não anda (`obstaculos` na navegação) e brilha azul; **gema azul** (minério novo, 30 cr, sem ferramenta — o difícil é chegar) em 4 jazidas na beira; casinhas de pedra da vila antiga; ânimo +10 ("a calma do lago azul"). |
| **Pesquisa Bombas d'água** | ramo Mina, depois de Ventilação (600 cr + 60 solarita). |
| **Corte da mina (F2)** | 6 faixas (S0–S5); o ponto de cada coisa vem do nível (`Niveis.do_ponto` + o `rect` do .tres); as plataformas novas aparecem com a gaiola. |
| **Jazidas trancadas** | a jazida de um nível novo espera toda a cadeia de ligações e mostra o motivo do nível ("precisa pesquisar: Bombas d'água", "consertar a plataforma..."). |
| **Save** | as plataformas novas pelo nome (`ligacoes`); jazidas pelo nome; poças/decoração dos dados. Save antigo: tudo fechado. |

## Arte (PixelLab, ~160 gerações)

| Peça | Como | Gerações |
|---|---|---|
| Piso de rocha molhada (S4), rocha azulada (S5) e água rasa (lago) | 16 candidatos de bloco inteiro cada (`create_image_pro`, bloco do nível 2 de referência) → `tiles.retifica` / `topo_de`. `relevo/fundo71.py`; lajes por `mapa/andares.py` (`andar_s4.png`, `andar_s5.png`) | 60 |
| Cachoeira | candidato pro (c01) + 6 quadros por script (a água rola dentro da própria máscara) → efeito animado `cachoeira` (`integra.py fx`) | 25 |
| Casinhas de pedra (2) | `create_image_pro`, estilo do coletor de minério; c05 (porta em arco) e c15 (brilho azul) | 25 |
| Poças d'água (2) | no losango, referência = a poça de ácido aprovada → `assets/game/iso/chao/` | 25 |
| Jazidas de gema azul (cheia, meia, quase) | edição da jazida de prata (como os cristais) | ~25 |

Brilho: pisos 0,29 (S4) e 0,33 (S5), como o nível 2 (0,33); água 0,35; gema 0,19–0,24; casinhas 0,16 e
0,26; cachoeira 0,34 (é água caindo). O primeiro piso do S4 tinha um ladrilho cheio de reflexos que
repetia demais: trocado por variações calmas.

## Desvios e decisões

1. **Plataformas, não rampa em espiral**: a ligação de cada nível é a plataforma (como a do abismo), com
   tempo e lotação de viagem. A rampa em espiral da referência fica pros "Itens de arte" (peças
   modulares) — a lógica já é a mesma (uma ligação por nível).
2. **Água é bônus, não risco**: atrasa um pouco, mas protege da lava. O risco do S4 é a lava + o ânimo.
3. **Lago por ladrilho**: a água é o piso dentro da elipse (degraus de ladrilho na borda); a luz azul
   suaviza. Reflexo animado não entrou (o piso é imagem montada).
4. **Casinhas de pedra são cenário** (a vila antiga, página no diário), não moradia.

## Como testar no jogo

Com o abismo aberto, pesquise **Bombas d'água** e clique na plataforma arruinada no canto do abismo:
o conserto abre o S4. Lá, mande alguém passar pela água e depois pela lava (a lava demora mais pra
queimar). Conserte a plataforma do S4 (cristal rubro) pra descer ao S5: o lago, as gemas e as casinhas.
F2 mostra os 6 andares.
