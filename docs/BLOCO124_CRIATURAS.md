# Bloco 124 — Criaturas novas: rato-de-cinza, morcego de brasa e sombra solar (plano, arte e relatório)

Pedido: Prompt 12 (seção 24.4 do guia). O Marco mandou "faz tudo e depois eu valido", então este plano foi escrito **antes** da geração e a geração seguiu o padrão recomendado; o piloto (os 3 personagens) foi conferido antes das animações.

## 1) As três criaturas (receita completa do projeto)

| | **Rato-de-cinza** (`rato`) | **Morcego de brasa** (`morcego`) | **Sombra solar** (`sombra`) |
|---|---|---|---|
| Papel | invasão **pequena** que rouba **comida** do armazém | **morador do S3**: apaga lampiões e tochas da mina | só nas **ondas solares fortes do fim do jogo** |
| Vida / velocidade / dano | 6 / 82 / 1 (mordida) | 5 / 96 (voa, ignora a malha) / 2 | 30 / 52 (flutua) / 6 (queimadura), 35% grave |
| Quando aparece | noites SEM invasão grande, a cada 3 a 5 dias, do dia 5 em diante, **só se há comida pra roubar** (>= 3 porções por morador) | quando o S3 abre (`moradores` do `S3_lava.tres`), até 3, repõe 1 por dia | onda solar com intensidade >= 3,0 (dia >= 26), vila no estágio >= 4, escudo ainda não pronto |
| O que faz | corre pro armazém (comida crua) ou pra cozinha, rouba até 6 de comida e foge; abatido, solta o que levava | voa de lâmpada em lâmpada no andar dele, apaga cada uma até o amanhecer, e importuna quem trabalha lá (-1 ânimo, mordida pequena) | flutua atrás de quem está **fora de abrigo** e dos prédios acesos (-ânimo); **a luz queima**: lampião/tocha acesos a até 140 px o machucam e fazem recuar |
| Defesa possível | guardas (ele é fraco), armazém vigiado (a política "vigilância reforçada": roubo x0,5), cozinha com comida em dia | guardas na patrulha do S3; lampiões **perto do poço** (a luz volta no amanhecer) | **abrigo** (todo mundo já se abriga na onda), lampiões e **holofotes**, lança de prata (dano x1,5) |
| Teto de dano (justiça) | no máximo 20% da comida crua por noite e nunca abaixo de 20 porções | luz apagada sobe o acidente do S3 em +15% por luz, teto +60% (volta no amanhecer) | só ataca quem está fora de casa; some quando a onda acaba; nenhum ataque a quem está abrigado |
| Drop | 15% de couro cru | 25% de cristal rubro | 20% de solarita |
| Diário / catálogo | entrada `rato` (estudar com a pesquisadora) | entrada `morcego` | entrada `sombra` |

**Dados da telemetria usados** (`docs/telemetria/bloco111`): a comida da vila fica em torno de **3 a 7 porções por morador** e chega a **0 (FOME)** perto do dia 56 na simulação sem casas; por isso o rato **só vem com estoque** e **nunca tira mais que 20%** da comida crua por noite, sem levar abaixo de um piso. Taxa de baixa de invasões: `defense.last_result` (não há série longa de invasões na telemetria; o teste fixa os tetos em vez de simular).

## 2) Arte (PixelLab, receita do `fundo.py` do Bloco 70: personagem "pro" no estilo do Lumívoro, 4 animações em SE e NE, SO/NO por espelho)

Estilo comum (no fim de todo prompt): *dark gritty post-apocalyptic mining game, grimy desaturated earthy palette, crisp 1px near-black outline, pixel art.*

1. **Rato-de-cinza** (56 px): *Ash rat, a fat cat-sized rat of a ruined mining colony: soot-grey matted fur dusted with pale ash, a long bare pink-grey tail, tiny red eyes, a torn ear, two yellowed gnawing teeth, hunched and scurrying low to the ground, a smudge of ash on its muzzle.* Animações: caminhada (corre baixo, a cauda balança), atacar (avança e estala os dentes), dano (recua e guincha), morrer (cai de lado, as patas tremem, fica parado).
2. **Morcego de brasa** (72 px): *Ember bat from a lava cavern: a bat the size of a crow, leathery charcoal-black wings edged with glowing orange ember veins, a small furry body, big pointed ears, tiny glowing orange eyes, a few tiny embers drifting off the wing tips; flying with wings spread.* Animações: caminhada (= voo, bate as asas), atacar (mergulha de boca aberta), dano (as asas tremem, as brasas piscam), morrer (dobra as asas e cai).
3. **Sombra solar** (96 px): *Solar shadow: a tall thin humanoid silhouette of living darkness, a corona of thin white-gold sun flares around its edges, no face but two pale white pinpoint eyes, ragged smoky edges trailing like heat haze, slightly translucent, long thin arms ending in sharp wisps, burned out by the sun; eerie but sober.* Animações: caminhada (desliza), atacar (estica os braços e um clarão pulsa), dano (tremula como miragem), morrer (dissolve em cinza e faíscas).

Custo (medido): 10 + 10 + 15 gerações pelos 3 personagens; cada animação ~4 a 6 por direção (SE e NE) = ~110 no total. Saldo antes: 5.3 mil.

## 3) Código

- `creature.gd`: `kind` ganha `rato`, `morcego` e `sombra`; cada um tem o seu alvo (`_pick_target`), o seu golpe (`_attack`) e o seu fim (`leave_at_dawn`); `defense.gd`: as regras de aparição (`rato_*`, `sombra_*`, o morador `morcego` pelo `.tres` do S3), `composicao`/previsão, F3 "invasão com todos os tipos" chama as três; escuridão do S3 pelo grupo "modificadores" (acidente).
- Cenas em `scenes/creatures/`, entradas no catálogo (`data/catalogo/entradas.json` + `textos.txt`: comportamento, fraqueza, por que veio, dica, história) — a página do diário vem do estudo (Bloco 103).
- Testes (`b124_criaturas_novas`): cada criatura (arte no `bonecos.json`, cena, aparição, comportamento, defesa e os tetos) e o F3.

## 4) Resultado (relatório)

- Teste: `tests/blocos/b124_criaturas_novas.gd`, **0 falhas**, registrado no GUT. Vizinhos (um por vez): b91, b62, b36, b103, b109 (ajustado: `str()` no `kind`), b113, b70, b80, p17, b60, b35, b114 (o gancho do stinger da missão passou a vir do campo `stinger`), b115, b116, p28_save, hud_frostpunk: 0 falhas; save real conferido por md5.
- **Arte:** os 3 personagens do PixelLab ficaram coerentes com o resto (rato 56 px e morcego 72 px sem o estilo do Lumívoro, que só aceita telas de 78 px ou mais; sombra 96 px com ele), 4 animações (caminhada, atacar, dano, morrer) em SE e NE (SO/NO por espelho) e o parado das rotações; integradas por `integra.py criaturas` (`bonecos.json`) e `CRIATURA_PASTA`. Folha de conferência: `docs/arte/bloco124_rotacoes.png`. Custo: ~35 gerações pelos personagens + ~100 pelas animações.
- **Som novo (ElevenLabs, 6 arquivos, 55 créditos):** `criaturas/rato_ataque`, `morcego_ataque` e `sombra_ataque` (2 variações cada), ligados no `Audio.criatura_golpe`.
- **Tetos de justiça conferidos no teste:** o rato leva no máximo 20% da comida crua da noite e nunca deixa a comida crua abaixo de 20; a sombra só mira quem está fora de abrigo e não ganha vida com a onda; a escuridão do S3 sobe o acidente no máximo x1,6; o morcego/sombra/rato não viram "forte" nem "elite".
- **F3** "invasão com todos os tipos" agora chama também 2 ratos, 1 sombra e o morcego do S3.
- Save: `defense` guarda `ratada {proximo_dia, ratadas}` (save antigo = a primeira ratada ainda não veio).

## 5) O que NÃO foi verificado / ficou de fora

- **Nada foi jogado nem ouvido:** o equilíbrio (6 de comida por rato, 3 a 6 ratos a cada 3 a 5 dias, sombra a partir do dia ~26, +15% de acidente por luz apagada) é palpite apoiado na telemetria que existe (comida de 3 a 7 porções por morador, fome perto do dia 56 sem casas); não há série de invasões longa na telemetria. Tudo está em `@export` do `defense.gd` e `creature.gd` (grupos "Rato-de-cinza", "Morcego de brasa e Sombra solar").
- A **ratada** nunca foi disparada pelo relógio numa partida de verdade (o teste chama `start_ratada` e testa as regras de `rato_motivo`); a janela da Defesa **não** mostra a previsão da ratada nem da sombra (só a das invasões grandes).
- O drop do rato (couro) do plano ficou de fora: ele só devolve a comida que levava.
- O morcego e a sombra **voam em linha reta** (ignoram a malha): atravessam paredes e obstáculos; na vista iso não há altura de voo desenhada além do desenho em si.
