# Bloco 95 — Layout v2 da interface (PLANO, esperando aprovação do Marco)

Pedido: seção 27 do `docs/DEEP_IRON_Guia_completo_e_Analise.docx` (parte A), a janela CONSTRUIR
padronizada (B), a tipografia (C) e uma imagem em todo cartão do CONSTRUIR (D).

**Número do Bloco:** o último é o b94, então este é o **b95**. O roteiro da seção 28 do guia previa o layout
v2 no b98 e a tela de dificuldade no b95. O roteiro anda três números: a dificuldade vira b96, as missões
b97, e assim por diante.

**Capturas do ANTES:** a pasta `docs/layout_v2/antes/` não existia no repositório. As capturas foram tiradas
pelo script novo `tests/capturas_bloco95.gd`, numa partida nova a 1280x720 com 600 cr:
- `hud_jogo.png`, `hud_selecionado.png`;
- `construir_00.png` … `construir_10.png`, uma por aba, na ordem de `TAB_NAMES`.

O mesmo script tira o DEPOIS.

## Checkpoints (paro e espero em cada um)

1. **Este plano.**
2. **Fontes:** uma captura comparando as 3 candidatas no mesmo cartão e na lista de força de trabalho.
   Espero a escolha.
3. **Arte:** a lista do que é reaproveitado e do que é novo, a estimativa e os prompts (abaixo). Espero o OK,
   depois faço 1 piloto de cada tipo e só então o lote.
4. Depois disso vem o código, e no fim o relatório com o DEPOIS.

## Parte C — Tipografia (vem primeiro: as partes A e B dependem dela)

- Escala única num Theme gerado por código, com variações de tipo:

  | Variação | Tamanho |
  |---|---|
  | `TituloJanela` | 20 |
  | `TituloCartao` | 15 |
  | `Corpo` | 13 |
  | `Detalhe` (custo, requisito) | 12 |
  | `Dica` | 12 |

  Todas com contorno de 1 px escuro (`outline_size`). Fica em `scripts/ui/tipografia.gd`, aplicada pelo
  `ui_skin.gd` no tema da raiz.
- Hoje há **287 chamadas** a `_label(texto, tamanho, cor)` e **59** `font_size` soltos, em 53 arquivos. O
  tamanho numérico vira o nome do tipo (`Tipo.CORPO`…). É troca mecânica, mas mexe em muitos arquivos. Um
  teste falha se aparecer `font_size` numérico fora do `tipografia.gd`.
- Cores: o custo vem com ícone de moeda e de minério; o que falta vem com **ícone de "falta"** e cor clara
  (amarelo-palha); o bloqueio vem com **cadeado**. Assim não depende só de vermelho ou laranja, e o
  contraste é conferido (≥ 4,5:1 sobre a placa).
- **Fontes candidatas** (todas OFL, com acentos do português), comparadas com a atual `deep_iron_texto`:
  1. **Pixelify Sans**: pixel, combina com a arte e é legível de 12 a 16 px;
  2. **Barlow Semi Condensed**: grotesca industrial, a mais legível em tamanho pequeno;
  3. **Chakra Petch**: quadrada, "placa de máquina".

  O título (`deep_iron_titulo`) fica como está, a não ser que você queira trocar.

## Parte B — Janela CONSTRUIR

- **Retângulo fixo** em todas as abas: 880x420 lógicos, centrado entre a barra de cima e a barra de baixo.
  Escala junto com a interface (90/100/125%), sem `_encolhe()`.
- **Grade** (`GridContainer`, 4 colunas) de cartões de **200x236** fixos. Quebra em linhas e só rola na
  vertical (`horizontal_scroll_mode = DISABLED`).
- **Cartão fixo**, de cima pra baixo:
  1. imagem de 184x72, com fundo e moldura;
  2. nome (1 linha, reticências);
  3. etiqueta curta;
  4. descrição de até 3 linhas (o texto inteiro vai na dica);
  5. custo numa linha própria, com ícone;
  6. requisito numa linha própria, com cadeado e o motivo;
  7. botão ancorado no rodapé.
- **Abas** de largura igual em duas linhas (11 abas), com "Defesa e equipamento" encurtado para "Defesa e
  equip." e o nome inteiro na dica. A aba ativa fica clara e com sublinhado, e há folga para o X.
- **Cabeçalho** com uma linha curta ("Escolha o prédio e o lugar; o engenheiro ergue") e um botão "?" com o
  resto.
- **Estados do cartão:**
  - construível;
  - bloqueado: imagem escurecida, cadeado e motivo;
  - sem recursos: o que falta fica destacado com ícone.

  Cartões bloqueados continuam visíveis.
- **Teclas:** Esc fecha, ←/→ trocam de aba, e a última aba usada é lembrada (configurações, não save).

## Parte D — Imagem em todo cartão

**Auditoria** (pelo código do `build_menu.gd`, confirmada nas capturas): estes cartões ficam **sem imagem** hoje.

| Aba | Cartão | Solução |
|---|---|---|
| Moradia | Escola (em breve) | **nova** |
| Coleta | Trilho e vagonete | reaproveita `props/vagonete_cheio_SE.png` |
| Coleta | Ferrovia de carga | **nova** (estação com cavalete) |
| Decoração | Tocha, Lampião, Banco, Mesa, Cerca, Canteiro de flores, Bandeira | reaproveita o sprite iso de cada peça (`decoracoes.gd` `iso`) |
| Decoração | Remover decoração | **nova** (pé de cabra) |
| Vila | Caminho: terra / cascalho / pedra | **novas**, 3 amostras de chão |
| Vila | Apagar caminhos | **nova** (pá) |
| Vila | Desbravar o leste | **nova** (mapa com seta) |
| Vila | Trilhas batidas | **nova** (bota numa trilha) |

O "Expandir a vila" **tem** imagem (Centro da Vila). Na captura da Vila ele aparece só cortado na borda.

- Cada definição de cartão ganha o campo `img` (o caminho da imagem), em lugar de `tex` e `frames`.
- Sem imagem, o cartão mostra um **placeholder claro** (moldura com "?"). O teste `b95` lista os que
  faltam e falha se houver algum.
- Regra nova no CLAUDE.md: todo cartão novo do Construir precisa de imagem.

## Parte A — Layout v2

| Item | Como |
|---|---|
| Força de trabalho | Aba fina na esquerda (36 px) com os ícones Pessoas, Alertas, Obras e Missões. A lista abre com **Tab** ou ao passar o mouse. Ordem: ociosos, depois com problema (ferido, fome, zangado), depois o resto. |
| Coluna da direita | Sai a coluna de 15 botões. Entra a coluna de **ALERTAS** (ícone + número): sem comida, obra parada, ferido, invasão 21h e onda solar. Clicar leva a câmera ao lugar (alternando entre eles). As janelas dos prédios abrem clicando no mapa, como já é. As que não têm prédio (Diário, Pesquisa, Corte, Calendário) vão para um menu "≡" na barra de cima, com as mesmas teclas. |
| Barra de funções | Grupos **Produção** (Min, Len, Caç, Coz, Fun, Fer, Car), **Serviço** (Eng, Méd, Pes, Pad) e **Defesa** (Gua), mais Sem função e Turno. Botão de 44 px com ícone e contador; o nome e a tecla na dica. Só aparecem as funções liberadas (o fundidor com a Fornalha, o padre com o estágio 2…). |
| Cartão do selecionado | Acima da barra, à esquerda: retrato, nome, função e o que está fazendo. |
| Barra de cima | Hora grande no centro (`17:38 QUA · dia 3`). "Vender" e "auto" vão para a janela do Armazém. |
| Rótulos do mapa | Só o nome, menor (`Detalhe`). "60/120" e o resto aparecem ao passar o mouse ou ao selecionar. |
| Obras no mapa | Barrinha de progresso com o ícone do martelo: colorido trabalhando, **cinza** esperando engenheiro. Sai o texto "45% — esperando engenheiro". |
| Avisos | Os toasts e as faixas viram uma **pilha** no canto de baixo à direita, com ícone e no máximo 4; clicar leva ao lugar. As faixas grandes (invasão, vitória) continuam. |
| Escala | Já existe um controle deslizante (Bloco 54, de 80 a 150%). Passa a ter **3 opções: 90 / 100 / 125%**. O save antigo com outro valor vai para a opção mais próxima. |
| Missões | Um retângulo reservado no canto direito (240x110) com `MissionTracker` vazio, escondido, pronto para o próximo prompt. |
| Balões de motivo | Ícone num balão sobre o ipezinho parado: sem trabalho, sem ferramenta, armazém cheio, caminho bloqueado, sem comida. O motivo sai de `ipezinho.motivo_parado()`, novo, lido dos estados que já existem (sem mudar a IA). É ligado/desligado nas configurações (padrão ligado). |

**Save:** só entram configurações (`ui_scale`, a última aba do Construir, os balões), no `Settings`, não no
savegame. Nada muda em `save_manager.gd`.

## Testes

- `tests/blocos/b95_layout_v2.gd`:
  - a aba Pessoas abre e fecha com Tab, e os ociosos vêm primeiro;
  - os alertas contam certo e clicar foca a câmera;
  - a barra só mostra as funções liberadas;
  - a hora fica no centro, e o Vender vai para o armazém;
  - o martelo da obra fica cinza sem engenheiro;
  - a pilha de avisos;
  - a escala de 90, 100 e 125%;
  - os balões de cada motivo e o liga/desliga;
  - nenhum `font_size` numérico solto.
- `tests/blocos/b95b_construir_abas.gd`:
  - abre todas as abas, nas 3 escalas;
  - o retângulo da janela é idêntico em todas;
  - todo cartão fica dentro da área visível do scroll;
  - não há rolagem horizontal;
  - nenhum cartão fica sem imagem.
- Os testes de HUD antigos que mudam: `hud_frostpunk`, `p20_interface`, `b46_menu_construcao`, `b28`, `b29_30`,
  `b54_configuracoes`, `b82` (o Vender), e os que clicam na coluna de construções. Rodam um por vez.
- DEPOIS: `capturas_bloco95.gd -- docs/layout_v2/depois`, com as mesmas telas.

## Arte (checkpoint 3) — reaproveitar x novo

**Reaproveitado, sem custo:**
- os 7 sprites de decoração;
- o vagonete;
- o Centro da Vila;
- os ícones de alerta que já existem (`al_falta_comida`, `al_obra_parada`, `al_invasao`, `al_onda_solar`,
  `ferido_grave`);
- `sem_funcao` (sem trabalho), `fome` (sem comida) e `construir` (o martelo, em cinza por código);
- o `balao.png` do Bloco 85;
- os ícones das funções.

**Novo no PixelLab:**

| # | Peça | Tipo | Tamanho |
|---|---|---|---|
| 1 | Escola (só a ilustração do cartão; a obra 1-2-3 vem quando a escola for construível) | `create_image_pro` com a guia, a casa e o minerador | como os prédios reduzidos |
| 2 | Estação da ferrovia de carga com cavalete | `create_image_pro` com a guia | idem |
| 3–5 | Amostras de caminho: terra batida, cascalho, pedra (losango de chão com bordas) | `create_image_pro` | 184x72 |
| 6 | Pá cravada num caminho (Apagar caminhos) | `create_image_pro` | 184x72 |
| 7 | Mapa velho com seta para o leste (Desbravar) | `create_image_pro` | 184x72 |
| 8 | Bota numa trilha batida (Trilhas) | `create_image_pro` | 184x72 |
| 9 | Pé de cabra arrancando uma estaca (Remover decoração) | `create_image_pro` | 184x72 |
| 10 | Ícone: sem ferramenta (picareta quebrada) | ícone 32 + 24 | |
| 11 | Ícone: armazém cheio (caixote transbordando) | ícone | |
| 12 | Ícone: caminho bloqueado (pedras com um X) | ícone | |
| 13 | Ícone: aba Pessoas (dois capacetes) | ícone | |
| 14 | Ícone: missões (pergaminho com prego) | ícone | |

**Estimativa:**
- 9 ilustrações a ~15 gerações cada (4 candidatas + 1 retoque) = ~135;
- 5 ícones a ~4 = ~20;
- folga de refação: ~50.

**Total: ~200 gerações**, contra um saldo de **7.237** (conferido agora no PixelLab, igual ao do CONTEXTO.md);
renova em 2026-11-02. Os candidatos não escolhidos ficam fora do repositório (ids em
`prototipos/camera/arte_iso/ui95/*_jobs.json`).

**Prompts** (todos levam o sufixo fixo: "isometric 2:1, high top-down, crisp 1px near-black outline, dirty
earthy palette, soot and wear, light from top-left, dark industrial mining colony after a solar flare, no
text, transparent background"):

1. "small one-room village school: timber frame, plank walls, slate roof with a little bell tower, a
   chalkboard by the door, patched and sooty; same style and scale as the reference house"
2. "freight railway loading station at a mine shaft: a short wooden platform with a mine cart on rails and a
   tall timber trestle (cavalete) going up behind it, iron brackets, oil lamp"
3. "a small isometric patch of packed dirt path with wheel ruts and footprints, grass tufts at the edges"
4. "a small isometric patch of gravel path, grey and brown pebbles, worn edges"
5. "a small isometric patch of laid flagstone path, cracked grey stones with moss in the joints"
6. "a worn shovel stuck in a dirt path, a small pile of removed earth beside it"
7. "an old folded parchment map with a red arrow pointing east, pinned to a plank with an iron nail"
8. "a muddy work boot stepping on a beaten dirt trail, dust puff"
9. "a crowbar prying a wooden stake out of the ground, a few splinters"
10–14. Ícones de 32x32 no estilo do `ui/icones.py`: "broken pickaxe", "overflowing crate", "pile of rocks
blocking a path with a red X", "two miner helmets side by side", "parchment scroll pinned with a nail".
