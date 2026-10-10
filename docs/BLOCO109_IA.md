# Bloco 109 — IA: escolha por pontuação, função secundária, perigo e carona (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido: "Prompt 8" (seção 26 do guia). O Marco autorizou executar sem esperar o plano
("pode aplicar ... depois de aplicar tudo eu vou validar") e decidiu: secundária por ipezinho, já com um padrão por função;
combinar viagens só quando a vila não tem carregador. Teste: `tests/blocos/b109_ia.gd`. Medição: `tests/bench_ia.gd`
(`docs/telemetria/bloco109/`). Fotos: `docs/arte/bloco109/` (`tests/capturas_bloco109.gd`).

## 1) O que mudou

| Item | Como ficou | Onde |
|---|---|---|
| **Escolha da estação por PONTUAÇÃO** | Custo em "px de caminho": distância × `peso_distancia` + fila × `peso_fila` − o quanto a estação tem (0..1) × `peso_quantidade` − o que FALTA no armazém (0..1) × `peso_falta` + perigo × `peso_perigo`. O minério mais valioso continua "parecendo mais perto" (como antes). Perigo = andar mais fundo (o multiplicador de acidente − 1), zona de perigo sem o traje e criatura viva a até `perigo_criatura_raio`. | `ipezinho._custo_estacao` (+ `fracao_restante()` na jazida, árvore, horta e toca) |
| **Função SECUNDÁRIA** | Cada ipezinho tem uma: automática (o padrão da função), "nenhuma" ou minerador/lenhador/caçador/agricultor. Padrão: engenheiro, carpinteiro e mecânico → lenhador; ferreiro, fundidor e pesquisador → minerador; guarda → lenhador. Só entra **no expediente**, com a IA ligada, fora de área de trabalho, e só quando a principal não tem **nada** pra fazer (esperar espaço no armazém ou uma entrega do carregador NÃO conta; fundidor/carpinteiro só sem ordem em oficina nenhuma; o guarda de dia e só se não vigiou a noite). O cozinheiro e o carregador nunca. Ele veste a roupa da secundária (a arte que já existe) e o cartão mostra "de lenhador agora". Quando a principal ganha trabalho, ele larga a secundária (entrega a carga da mão antes). | `ipezinho._estado_funcao/_estado_secundario/_sem_trabalho/_pode_secundaria`, o botão no cartão do selecionado (`hud._troca_secundaria`) |
| **Perigo: invasão** | Quem não é guarda já recolhe no **aviso** da invasão (21:00; com o rádio, antes), não só quando ela começa. | `defense.aviso_dado()` |
| **Perigo: criatura** | Quem não é guarda e vê uma criatura viva a até `fuga_raio` (mesmo andar) larga tudo e corre pra casa, e continua longe por `fuga_tempo` (sem ir e voltar). | `ipezinho._foge` |
| **Perigo: onda solar** | Vai pro **abrigo mais perto** (casa pronta ou taverna, de qualquer um) quando a própria cama está mais longe que ele + `abrigo_folga`; **quem não tem cama nunca mais fica do lado de fora** (antes dormia exposto). Sai sozinho quando a onda passa. | estado "abrigo" (`_vai_pro_abrigo/_sai_do_abrigo`) |
| **Carona (combinar viagens)** | Só **sem carregador** na vila: quem acabou de descarregar no armazém, de mãos vazias, leva o material de uma obra a até `carona_raio`, no máximo uma vez a cada `carona_intervalo`. É a mesma entrega do carregador (Bloco 105): a obra conta como "a caminho", a reserva e o cancelar valem. | `ipezinho._quer_carona`, `logistica.reserva_carona` |
| **A ordem fixa** | Continua emergência > agenda > necessidades > função; a secundária e a carona ficam DEPOIS de tudo isso. As ordens manuais continuam valendo (sem IA, nada de secundária). | `_choose_state` |

## 2) A mais (achado na medição)

- **Defeito antigo do Bloco 84 (a vila morria de fome por causa dele):** quem pegava o prato e perdia o lugar no comedouro ficava
  parado em "comendo" **pra sempre**, longe dele, com o prato pela metade (`_prato > 0`, sem estação). Quando isso pegava o
  caçador ou o cozinheiro, a comida da vila parava (a referência também tinha: o cozinheiro preso). Agora ele larga o prato e
  segue. Rastro em `docs/telemetria/bloco109/achado_prato_preso.txt`.
- **Testes antigos que medem o tempo de resposta de quem fica parado** (b105 carregador/fundidor, b86 fornalha, b94
  carpintaria) ligam `ipezinho.secundaria_desligada = true` — o mesmo padrão do `tudo_estudado` e do `limite_desligado`
  (documentado no CLAUDE.md). Neles o assunto é a contagem exata de insumos e quanto o fundidor demora.

## 3) Valores configuráveis (`@export` no `ipezinho.gd`, listados no `BALANCEAMENTO.md`)

| Grupo | Valor | Padrão |
|---|---|---|
| Escolha da estação | `peso_distancia` / `peso_fila` / `peso_quantidade` / `peso_falta` / `peso_perigo` | 1 / 40 / 60 / 120 / 250 px |
| | `falta_referencia` / `perigo_criatura_raio` | 120 un. / 160 px |
| Função secundária | `secundaria_padrao` | ver a tabela da seção 1 |
| Perigo | `fuga_raio` / `fuga_tempo` / `abrigo_folga` | 140 px / 20 s / 80 px |
| Carona | `carona_raio` / `carona_intervalo` | 260 px / 45 s |

## 4) Medição antes e depois (telemetria)

Partida nova, 12 ipezinhos (2 engenheiros, ferreiro, fundidor, 2 mineradores, 2 caçadores, 2 lenhadores, cozinheiro e guarda),
8×, **onda solar forçada no dia 2 às 10:00** (aviso curto: sem o estudo) e a invasão do dia 3. Ociosos = média de quem tem função
e está parado no expediente.

| | Ociosos (dia 1 / 2 / 3 / 4) | Média | Minério/dia | Madeira | Expostos na onda | Mortes bobas |
|---|---|---|---|---|---|---|
| **Antes** | 3,43 / 2,70 / 3,71 / 4,83 | 3,67 | 59 | 128, 112, 110 → armazém cheio no dia 4 | **2** | 0 |
| **Depois** | **0,02 / 1,62** / 3,51 / 3,41 | **2,14** | **110 (+86%)** | 274, 75 → armazém cheio no dia 2 | **0** | 0 |

- Nos dias 3 e 4 os dois param no **limite do armazém** (Bloco 106): com a madeira e o minério cheios, nem a secundária tem o que
  fazer — aí o certo é ampliar o armazém (o alerta já avisa). Por isso a secundária NÃO entra em "esperando espaço".
- Mortes: 1 em cada (o guarda na invasão); nenhuma "boba" nas duas. As queimaduras da onda não aconteceram nesta força, mas os
  **expostos** caíram de 2 pra 0 (quem dormia do lado de fora agora entra num abrigo).
- Desempenho: a decisão custa ~0,3 ms por ipezinho por segundo (`tests/perf_ia.gd`); o dia acelerado continua levando ~68 s
  reais, igual a antes. (Uma rodada lenta no meio do trabalho foi a máquina com pouca memória, não o código: refeita, deu normal.)
- A 1ª versão da medição (1 caçador pra 12) virou uma medição de FOME (as duas versões passavam fome e uma rodada terminou em
  greve e expulsão); o cenário passou a ter 2 caçadores, que é o que o Bloco 101 mediu como suficiente.

## 5) Testes (um por vez, em primeiro plano, APPDATA isolado; o save real não mudou)

**Aprovados:** b109_ia (novo, 40 verificações, 0 falhas), b84_agenda, b85_hora_social, b83, b98, b101, b102, b103, b104, b105, b106, b107,
b108, b25_funcoes, b25_troca_funcao, b27, b31, b35, b36, b45, b52, b57, b62, b77, b86, b87, b88, b94, b95_layout_v2, b96, b99,
hud_frostpunk, p28_save.

**Reprovados e corrigidos no caminho:** b105 (fundidor e engenheiro), b106 (o minerador com o armazém cheio virava lenhador), b86
e b94 (contas de insumo). O b106 mostrou um erro de desenho meu (a secundária entrava em "esperando espaço") — corrigido no jogo;
os outros três medem o tempo de resposta / insumos exatos e ganharam `secundaria_desligada` (seção 2).

**Intermitente:** nenhum novo (o b103 da nota do Bloco 108 passou).

**Não rodados:** os demais de `tests/blocos` (sem relação) e os GUT `test_iso*.gd`.

## 6) Pendências / pra o Marco validar

- Os padrões da secundária (seção 1) e os pesos da pontuação (seção 3).
- A troca de roupa na secundária usa a arte que já existe da outra função (o engenheiro vira "lenhador" enquanto corta). Se
  preferir o engenheiro com a própria roupa cortando lenha, precisa de animação nova no PixelLab (~16 por personagem).
- A carona só leva material de OBRA (não insumo da fornalha nem a cozinha) — é o caso simples e seguro do pedido.
