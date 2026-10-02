# Bloco 70 — Conteúdo do S2 (ácido) e do S3 (lava)

Data: 2026-10-02. Branch `isometrico`. Teste: `tests/blocos/b70_fundo.gd`. Fotos: `tests/capturas_fundo.gd`.

## Passo 0 (o que já existia)

- **Zonas de perigo** (`hazard_zone.gd`, Bloco 42): gás e radiação no nível 2, calor no abismo. São
  "não entra sem traje": o ipezinho sem o traje no vestiário é mandado pra fora. Os trajes saem da
  Oficina (pesquisa Trajes) e ficam no Vestiário (`equipment.gd`).
- **Minérios** (`ores.gd`): ferro, carvão, cobre, prata (nível 2, broca) e solarita (abismo, traje de
  chumbo). A lista `Ores.TYPES` alimenta armazém, HUD, venda e save; faltava só o armazém, a telemetria
  e a criatura (que tinham a lista escrita à mão).
- **Criaturas** (`creature.gd`, `defense.gd`): Lumívoro (túnel) e Ferrugento (poço, com o S2 aberto).
- **Escavadeira**: os reatores mandam minério pro armazém sozinhos; não tinha nada a ver com o fundo.
- **Níveis por dados** (Bloco 68): `data/niveis/*.tres` já tinham perigo/traje/minérios/criaturas, só
  informativos.

## O que entrou

| Peça | Onde | Como |
|---|---|---|
| **Poças de perigo** (ácido no S2, lava no S3) | `scripts/props/poca_perigo.gd`; dados em `NivelMina.perigos` | Diferente da zona: é de **passagem**. Sem o traje anda devagar (60% no ácido, 50% na lava) e, ficando, queima — ácido em 5 s (leve), lava em 2,5 s (30% grave). Com o traje no vestiário, veste ao pisar (como nas zonas) e nada acontece. A queimadura vai pra enfermaria como qualquer machucado (médico, ânimo "machucado"). |
| **Cristal verde** (S2) e **cristal rubro** (S3) | `ores.gd`, `economy.gd` (10 e 18 cr), `oficina.gd` (broca / traje de chumbo); jazidas em `NivelMina.jazidas` | 3 jazidas por nível, com nome fixo (`JazidaS2_1`...) pro save. Vendem, aparecem no HUD e no armazém. Página "Cristais do fundo" no diário. |
| **Ventilador** (S2) | `scripts/props/ventilador.gd`, `scripts/core/fundo.gd`; pesquisa **Ventilação** (ramo Mina, depois de Trajes) | Menu de construção → posicionador só no chão do nível 2 → obra do engenheiro (Canteiro). No alcance (260): a máscara gasta metade e o ácido arde na metade do ritmo; cada um tira 20% da névoa verde do S2 (até 60%). Máximo 4. |
| **Gosma ácida** (S2) | `scenes/creatures/gosma.tscn` | Sobe pelo poço a partir da onda 2 com o S2 aberto (1 por onda a mais, até 4). Rápida e fraca; o golpe corrói a arma do guarda e derrete barricada 1,5×; no armazém dissolve ferro/cobre (some). 35%: deixa 2 cristais verdes. |
| **Magmante** (S3) | `scenes/creatures/magmante.tscn` | A partir da onda 3 com o abismo aberto (até 3). Lento e duro (70 de vida); derrete barricada 2×; no armazém come o carvão. 50%: deixa 3 cristais rubros. |
| **Escavadeira no fundo** | `escavadeira.gd` + `fundo.gd` | S2 aberto: 12% do que a broca tira vira cristal verde; S3 aberto: 8% cristal rubro e a broca rende ×1,25. |
| **Telemetria** | `telemetria.gd` | colunas novas no fim: cristal_verde, cristal_rubro, queimaduras_acido, queimaduras_lava, ventiladores. |
| **Save** | `save_manager.gd` (chave `fundo`) | ventiladores e contadores; as jazidas novas pelo nome (lista `minerios`); poças vêm dos dados. Save antigo: sem ventilador, contadores zerados. |

Todos os números estão em `@export` no nó **Fundo** (`scripts/core/fundo.gd`), na Defesa (`gosma_*`,
`magmante_*`) e nas cenas das criaturas; posições e tamanhos das poças/jazidas no `.tres` do nível.

## Arte (PixelLab, ~260 gerações)

| Peça | Como | Gerações |
|---|---|---|
| Jazidas de cristal verde e rubro (cheia, meia, quase) | `edit_image` (pro) da jazida de prata, os 3 estados numa chamada (saem coerentes); quadro e âncora = os da prata. `prototipos/camera/arte_iso/fundo70/jazidas.py` | ~50 |
| Ventilador (prop iso) + ícone do menu | `create_image_pro`, 16 candidatos, estilo do coletor de minério; escolhido c02 (motor atrás). `fundo70/objetos.py` | 25 |
| Poças de ácido e de lava | vista de cima (16 candidatos cada) e depois **no losango, no tamanho da tela** com a escolhida como referência (2 variações cada) → `assets/game/iso/chao/` | 100 |
| Gosma ácida e Magmante | personagem pro no estilo do Lumívoro + 4 animações v3 (caminhada, atacar, dano, morrer; SE/NE, SO/NO por espelho). `criaturas/fundo.py` | ~90 |

**Brilho** (contrato: 0,18–0,26): jazidas 0,21–0,25 (a verde cheia 0,268); ventilador 0,171; poça de
ácido 0,26–0,29; **lava 0,40–0,43** — fora de propósito (é a fonte de luz do nível; a luz 2D da poça e
o pulso vêm do Bloco 69).

**Como a poça entra na vista iso:** é um decalque deitado na laje do andar (filho do desenho da laje,
`iso_view._poca_add`): fica por cima do chão e embaixo de tudo que está em pé, sem entrar na ordem por
caixas. A luz pulsando e as bolhas/brasas ficam na camada 4 (`docs/arte/CAMADAS.md`).

## Desvios e decisões

1. **Ventilador não muda o raio das zonas de gás**: ele poupa a máscara e alivia o ácido em volta
   (mais fácil de ler e de balancear do que zona encolhendo).
2. **"Escavadeira e reatores operando no S3"** virou: a broca (que já existe na superfície) acha
   cristal e rende mais com o fundo aberto. Não tem prédio novo lá embaixo.
3. As criaturas do fundo **não roubam** (o minério some): a Gosma dissolve metal, o Magmante come carvão.
4. Poça não desvia o caminho dos ipezinhos (a malha de navegação não tem custo por área); o jogador
   sente pela lentidão/queimadura e resolve com traje ou ventilador.

## Como testar no jogo

Abra o nível 2 (escavadeira pronta) — ou F3 → liberar — e mande um minerador pras jazidas de cristal
verde (precisa da Broca manual). Ele passa pelas poças de ácido: sem máscara no vestiário anda devagar
e, se ficar, queima. Pesquise **Ventilação** e construa um ventilador lá embaixo (menu Defesa e
equipamento). Nas noites de invasão a partir da onda 2 sobem Gosmas pelo poço; com o abismo aberto, a
partir da onda 3, Magmantes.
