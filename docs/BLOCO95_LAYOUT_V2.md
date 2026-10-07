# Bloco 95 — Layout v2 da interface, janela CONSTRUIR padronizada, tipografia e imagem em todo cartão

Data: 2026-10-07. Branch `isometrico`. Testes: `b95_layout_v2` e `b95b_construir_abas`.

**O pedido do Marco:**
- **Parte A — layout v2:** dar mais espaço ao mapa, seguindo a seção 27 do `docs/DEEP_IRON_Guia_completo_e_Analise.docx`.
- **Parte B:** a janela CONSTRUIR padronizada.
- **Parte C:** legibilidade e tipografia.
- **Parte D:** uma ilustração em todos os cartões do CONSTRUIR.

O plano, com as capturas do ANTES, está em `docs/layout_v2/PLANO_BLOCO95.md`. O Marco aprovou com "pode continuar,
aprovado".

**O número:** o último bloco era o 94, então este é o **95**. A seção 28 do guia previa o layout no b98 e a tela de
dificuldade no b95. O roteiro anda: a dificuldade vira o b96, as missões o b97, e assim por diante.

**Pendente com o Marco:** a **fonte do corpo**. A comparação está em `docs/layout_v2/fontes_comparativo.png` e
**nenhuma fonte foi aplicada**, como foi pedido. A escala, a sombra e o tema já estão valendo com a fonte de hoje.
Quando ele escolher, falta só:
- copiar o `.ttf` (OFL) para `assets/fonts/`;
- pôr o caminho em `Tipo.FONTE_CORPO` (`scripts/ui/tipografia.gd`);
- refazer as capturas.

**Skills usadas:**
- `godot-ui-control` (Containers, tema, foco);
- `godot-gdscript`;
- `godot-gdscript-headless-testing`;
- `deep-iron-arte` (contrato, custo e piloto);
- `game-feel` (avisos que entram e saem, contador nos botões).

## Capturas

| O quê | Onde |
|---|---|
| ANTES (pasta nova; a `docs/layout_v2/antes/` do pedido não existia no repositório) | `docs/layout_v2/antes/` |
| DEPOIS, as mesmas telas | `docs/layout_v2/depois/` |
| Telas novas | `depois/v2_*.png` (lista, obras, avisos, CONSTRUIR a 90% e 125%, rótulo inteiro, balões) |
| Lado a lado | `docs/layout_v2/antes_depois.jpg` |

As capturas do ANTES e do DEPOIS são:
- `hud_jogo`;
- `hud_selecionado`;
- `construir_00` a `construir_10`, uma por aba, na ordem de `TAB_NAMES`.

Para refazer:

```
<Godot>.exe --path project.godot -s res://tests/capturas_bloco95.gd -- <pasta>
```

Precisa de janela e do APPDATA isolado. A comparação das fontes sai do `tests/capturas_fontes95.gd`.

## Parte A — o layout v2

| Item da seção 27 | Como ficou |
|---|---|
| 1. Força de trabalho | Uma **aba fina** de 40 px à esquerda, com os ícones Pessoas, Obras e Missões (esta em breve). A lista sai dela como gaveta: **Tab** abre e fecha, e passar o mouse no ícone também abre (fecha quando o mouse sai). A ordem é: **parados** primeiro, depois **com problema** (ferido, caído, com fome, zangado, sem cama), depois o resto. O ícone Pessoas mostra quantos estão parados ou com problema. |
| 2. Coluna de construções | Saiu. No lugar entrou a **coluna de ALERTAS**, cada um com ícone e número: invasão (às 21h aparece "22h"), feridos, sem comida (porções que faltam hoje), onda solar, greve, obra parada, parados, desarmados, sem casaco e sem cama. Cada alerta só aparece quando acontece; a dica conta o detalhe; **clicar leva a câmera ao lugar**, e clicar de novo leva ao próximo. As janelas dos prédios continuam abrindo **clicando no prédio** e pela tecla. As que não têm prédio (Diário, Pesquisa, Corte da mina…) e todas as outras ficam no menu **"Janelas"** da barra de cima, com a tecla do lado; o "•" marca onde há o que fazer. |
| 3. Barra de funções | Em **grupos**: PRODUÇÃO (minerador, lenhador, caçador, cozinheiro, fundidor, ferreiro, carpinteiro), SERVIÇO (engenheiro, médico, pesquisador, padre), DEFESA (guarda) e ORDENS (sem função, turno extra). Os botões têm 46 px, **só o ícone e o contador**; o nome e a tecla ficam na dica. **Só aparecem as funções liberadas**: o pesquisador com laboratório, o fundidor com fornalha, o ferreiro com a Oficina pronta ou um Arsenal, o padre com a vila no estágio dele e o carpinteiro com carpintaria. Se alguém já tem a função, o botão aparece. |
| 4. Cartão do selecionado | Fica **acima da barra, à esquerda**, com o retrato, o nome, a função (na cor dela), **o que está fazendo** e o ânimo. Com vários selecionados, mostra a lista dos nomes. Não cobre mais o Construir. |
| 5. Barra de cima | À esquerda os recursos. No meio, a **hora grande** (fonte pixel 32), com o dia da semana e "dia N · sem. N" do lado e a barrinha da fase embaixo. À direita a estação, a velocidade, "Janelas" e "?". **"Vender" e "auto" foram para a janela do Armazém**: o "Vender tudo" e a venda por item já estavam lá, e o "auto" entrou na linha dos créditos. A tecla V continua vendendo tudo. Em tela estreita (125% em 720p), a estação e a semana ficam só na dica. |
| 6. Rótulos no mapa | **Só o nome**, em letra menor (`Tipo.MAPA`) e com contorno. O texto inteiro ("60 / 120", o estágio, a obra) aparece **com o mouse em cima** ou com a janela do prédio aberta. É feito num lugar só, no espelho iso (`iso_billboard._rotulo_compacto`), para todo `NameLabel`/`StatusLabel`. |
| 7. Obras no mapa | Toda obra encomendada ganha a **barrinha de progresso + martelo**: colorido com gente trabalhando, **cinza esperando engenheiro** (ou ferreiro). Antes isso só valia para o canteiro, e com outro ícone. A linha "45% — esperando engenheiro" saiu do rótulo. A gaveta **Obras** da aba fina lista cada uma, com o mesmo martelo, a barrinha e o clique para ir até ela. |
| 8. Avisos | Viraram uma **pilha no canto de baixo à direita**, com ícone (pela palavra: invasão, comida, morte…). Ficam no máximo 4; o mais novo embaixo; somem sozinhos. `show_toast(texto, cor, alvo)` ganhou o `alvo`: com ele, **clicar leva até o lugar**. As faixas grandes (invasão, conquista, morte) continuam no alto, como eram. |
| 9. Escala | Nas configurações, **3 opções: 90 / 100 / 125%**. A área mínima das janelas passou a 1024x576, que é 1280x720 a 125%, então **125% cabe em 720p**. Um valor antigo do Bloco 54 (80–150%) vai para a opção mais perto. |
| 10. Missões | O **espaço reservado** (`scripts/ui/rastreador_missoes.gd`) fica no canto direito, acima da barra: 240x110, escondido. O sistema de missões só chama `mostra(capitulo, objetivos)` / `esconde()`. A pilha de avisos sobe quando ele aparece. |
| Balões de motivo | Um ícone num balão sobre quem está **parado**, explicando o porquê (detalhes abaixo). Liga e desliga em Configurações → Jogo → "Balões de motivo". |

**Teclas:**
- **Tab** abre a lista de pessoas (ação nova `pessoas`).
- O "próximo ipezinho", que era o Tab, foi para o **ponto (.)**.
- As duas são remapeáveis. Quem já tinha remapeado continua com a própria escolha.

### Balões de motivo

O motivo sai de `ipezinho.motivo_parado()`. Ele só **lê** o estado que a IA já decidiu, sem mudar a IA. O balão aparece
depois de **2 s parado pelo mesmo motivo**, para não piscar a cada troca de tarefa (`motivo_espera`, `@export`). Ele
usa o mesmo lugar do balão da conversa do Bloco 85, e os dois nunca aparecem juntos.

| Motivo | Quando | Ícone |
|---|---|---|
| sem trabalho | sem função, ou com função e nada pra fazer (sem obra, sem jazida, sem árvore…) | `sem_funcao` (a mão) |
| sem ferramenta | guarda com a arma quebrada e sem Arsenal; caçador com toca e sem arco; minerador que só tem jazida trancada por ferramenta | `sem_ferramenta` (novo) |
| armazém cheio | com a carga nas costas e sem armazém para entregar | `armazem_cheio` (novo) |
| caminho bloqueado | andando e preso no mesmo lugar (o anti-travamento do Bloco 31b já começou) | `caminho_bloqueado` (novo) |
| sem comida | com fome e a cozinha vazia | `al_falta_comida` |

**Atenção:** o armazém do jogo **não tem limite**, então "armazém cheio" no sentido literal nunca acontece. O balão
ficou ligado ao caso real de "não ter onde guardar". Se o armazém ganhar capacidade um dia, basta acrescentar a
condição em `motivo_parado()`.

**De quebra,** os dois balões (conversa e motivo) desceram para perto da cabeça (`BALAO_POS`). Com -66, eles ficavam
longe da arte nova.

## Parte B — a janela CONSTRUIR

1. **Tamanho e lugar fixos.** O retângulo é o mesmo em todas as abas, centrado entre a barra de cima e a de baixo.
   - Ele usa a altura que sobra até no máximo 872x560 (px lógicos).
   - Muda só com a escala da interface (ou a janela do jogo), nunca com a aba.
   - Não passa da aba fina nem da coluna de alertas.
2. **Grade:**
   - 4 colunas, todos os cartões com o mesmo tamanho (200 de largura; a altura é calculada pela fonte, ~295);
   - quebra em linhas e rola **só na vertical**;
   - abas com poucos cartões ficam centradas.
3. **Estrutura fixa do cartão**, de cima para baixo:
   - a **imagem** numa área de 180x70, com o fundo escuro e o aro de ferro iguais em todos;
   - o nome (1 linha);
   - a etiqueta (1 linha);
   - a descrição, com **até 3 linhas** (o texto inteiro vai na dica do cartão);
   - o **custo** numa linha, com o ícone de créditos (o inteiro na dica);
   - o **requisito/bloqueio** noutra linha, com cadeado ou "!" e o motivo;
   - o **botão no rodapé**, no mesmo lugar em todos.
4. **Abas** com a mesma largura, em duas linhas (6 + 5):
   - "Defesa e equipamento" vira "Defesa e equip.", com o nome inteiro na dica;
   - a ativa fica clara, com a letra âmbar;
   - o X fica na linha do título, longe das abas.
5. **Cabeçalho** com uma linha curta ("Escolha o prédio e o lugar; o engenheiro (tecla 4) ergue.") e o botão **"?"** com o
   resto.
6. **Estados do cartão:**
   - **construível**;
   - **bloqueado** por estágio, pesquisa ou obra: cartão escuro, **imagem escurecida com cadeado**, o motivo legível ao
     lado do cadeado;
   - **sem recursos**: imagem normal, o que falta com o ícone "!" e a cor palha (não depende só do vermelho).

   Os cartões bloqueados continuam visíveis.
7. **Teclas:**
   - **Esc** fecha;
   - **←/→** trocam de aba (com o menu aberto, a câmera não usa as setas; o WASD continua);
   - a **última aba fica lembrada** em `[hud] construir_aba`, nas configurações e não no save.

## Parte C — legibilidade e tipografia

- **A escala única** fica em `scripts/ui/tipografia.gd`:

  | Tipo | Tamanho (px lógicos) |
  |---|---|
  | `TITULO_JANELA` | 20 |
  | `TITULO` | 15 |
  | `CORPO` | 13 |
  | `DETALHE` | 12 |
  | `DICA` | 12 |
  | `FAIXA` | 26 |
  | `TELA` | 34 |

  Há ainda os nativos da fonte pixel (16/32/64) e os do mapa (10/8/14).
- **Nada da interface fica abaixo de 12 px.** Os 11 e 10 de antes subiram.
- **Sem número solto no código.** Saíram 277 tamanhos soltos em 43 arquivos, mais os `draw_string` do corte e das
  áreas, todos trocados pelos nomes da escala. O `b95` varre `scripts/` e falha se aparecer um.
- **O tema chega no HUD.** O tema da janela raiz **não atravessava os `CanvasLayer`** (HUD, corte, pausa, eventos,
  vitória…). Por isso cada controle sem estilo próprio ficava com a fonte e o tamanho padrão do Godot.
  `UiSkin.tema_na_camada(camada)` põe o tema em cada controle de cima da camada, agora e quando entra um novo.
- **Contraste:** sombra fina (1 px, preta a 85%) em todo `Label` pelo tema, e contorno escuro nos rótulos do mapa.
  Custo e requisito têm ícone, então não dependem só do vermelho ou laranja.
- **Fontes candidatas:** a comparação está em `docs/layout_v2/fontes_comparativo.png` (a fonte de hoje, à esquerda,
  e as 3 candidatas). As três são OFL, do repositório oficial do Google Fonts, e têm os acentos do português.

  | Fonte | Como ficou |
  |---|---|
  | Pixelify Sans | Pixel; só fica nítida no tamanho nativo (≥16). A 12–13 px ela quebra. Seria boa para títulos, não para o corpo. |
  | Barlow Semi Condensed | Industrial e condensada. Cabe mais texto, mas a 12–13 px a letra fica pequena. |
  | Chakra Petch | Quadrada, "placa de máquina", e a mais legível a 12–13 px. **Minha recomendação** para o corpo, com o título de sempre (`deep_iron_titulo`). |

  **Esperando a escolha do Marco.** Os arquivos ficaram fora do repositório.

## Parte D — imagem em todo cartão

**Auditoria** (todas as abas, pelo `build_menu.gd`). Estes cartões estavam **sem imagem**:

| Aba | Cartão | Solução |
|---|---|---|
| Moradia | Escola (em breve) | **nova** (PixelLab) |
| Coleta automática | Trilho e vagonete | reaproveitada: o vagonete cheio do jogo |
| Coleta automática | Ferrovia de carga | **nova** (estação com cavalete) |
| Coleta automática | Coletor de minério (tinha o desenho antigo, fora do padrão) | reaproveitada: o prédio pronto, reduzido como os outros |
| Decoração | Tocha, Lampião, Banco, Mesa, Cerca, Canteiro de flores, Bandeira | reaproveitadas: o sprite iso de cada peça |
| Decoração | Remover decoração | **nova** (pé de cabra arrancando a estaca) |
| Vila | Caminho: terra batida / cascalho / pedra | **novas** (3 amostras de chão) |
| Vila | Apagar caminhos | **nova** (pá) |
| Vila | Desbravar o leste | **nova** (mapa velho com a seta) |
| Vila | Trilhas batidas | **nova** (bota na trilha) |

O **"Expandir a vila" já tinha imagem** (o Centro da Vila). Na captura do ANTES ele só aparecia cortado na borda.

- **Campo `img` em cada item** do `_defs` (no lugar de `tex`/`frames`):
  - `_predio(nome)` = o prédio pronto reduzido (`assets/game/ui/icones/predios/`);
  - `_cartao(nome)` = a ilustração própria (`assets/game/ui/icones/cartoes/`).

  As duas têm 96x64, entram 1:1 e centradas.
- **Sem imagem:** o cartão mostra "? sem imagem" em laranja, e o `b95b` lista e falha.
- **Regra nova no `CLAUDE.md`:** todo cartão novo do Construir precisa de imagem.

**A arte nova** (regra 11 e contrato de arte):
- **Ferramenta:** `create_image_pro`, com a casa ou o coletor de minério do jogo como estilo, mais o sufixo de
  estilo de sempre (`gen.ESTILO`: contorno de 1 px escuro, paleta suja, luz de cima à esquerda). Os ícones usam o
  engenheiro e o cozinheiro como referência, como no Bloco 92.
- **Piloto antes do lote:**
  - **Caminhos:** a amostra com os três num pedido só saiu com a terra parecendo tábua. Virou 3 pedidos separados.
  - **"Sem ferramenta":** nenhum dos 64 candidatos veio quebrado. O escolhido foi partido à mão
    (`ui95/quebra_picareta.py`), sem gerar de novo.
- **Escolhidos:**

  | Peça | Candidato |
  |---|---|
  | escola | c03 (sino e lousa) |
  | ferrovia | c01 |
  | terra | c03 |
  | cascalho | c00 |
  | pedra | c00 |
  | pá | c02 |
  | mapa | c01 |
  | bota | c02 |
  | pé de cabra | c01 |
  | caixote | c00 |
  | pedras com X | c12 |
  | capacetes | c03 |
  | pergaminho | c13 |

- **Gasto:** 15 pedidos de 20 = **300 gerações**. O plano estimava ~200: o piloto dos caminhos foi refeito em 3, e
  os ícones custam 20 cada, e não 4. **Saldo: 7.237 → 6.937** (renova em 2026-11-02).
- **Candidatos não escolhidos:** ficam fora do repositório (`ui95/_cand/` tem `.gitignore`); os ids estão em
  `ui95/ui95_jobs.json`.
- **A Escola é só a ilustração do cartão.** A obra 1-2-3-pronto dela vem quando ela for construível (Bloco 65,
  crianças).

## Código

| Arquivo | O quê |
|---|---|
| `scripts/ui/tipografia.gd` (novo) | a escala, a fonte do corpo (pendente), a sombra e o contorno do mapa |
| `scripts/ui/alertas.gd` (novo) | a coluna de alertas |
| `scripts/ui/avisos.gd` (novo) | a pilha de avisos |
| `scripts/ui/rastreador_missoes.gd` (novo) | o espaço das missões |
| `scripts/core/hud.gd` | barra de cima, aba fina + gavetas, menu Janelas, alertas, barra agrupada, cartão do selecionado, avisos, `_reposiciona` |
| `scripts/core/build_menu.gd` | janela fixa, grade, cartão fixo, estados, teclas, `img`, `diagnostico()` |
| `scripts/ui/ui_skin.gd` | escala no tema; `tema_na_camada` (chamado no HUD, corte, pausa, evento, carregando, debug, vitória e fim de jogo) |
| `scripts/iso/iso_billboard.gd` + `iso_view.gd` | rótulo compacto, `hover`/`foco`, barrinha + martelo em toda obra |
| `scripts/workers/ipezinho.gd` | `motivo_parado()`, balão de motivo, `BALAO_POS` |
| `scripts/core/window_manager.gd` + `ui/settings_panel.gd` | escala 90/100/125; o liga/desliga dos balões |
| `scripts/core/armazem_panel.gd` | o "auto" |
| `scripts/core/teclas.gd` + `main.gd` | Tab = pessoas; "." = próximo |
| `scripts/core/camera_controller.gd` | as setas ficam com o CONSTRUIR aberto |
| 43 arquivos | os tamanhos de letra pela escala |

**Save:** nada entra no `savegame`. As escolhas novas (`[video] ui_scale` em opções, `[hud] baloes_motivo`,
`[hud] construir_aba`) ficam no `settings.cfg`, e o save antigo carrega igual.

**Balanceamento:** os `@export` novos estão no `docs/BALANCEAMENTO.md`, regenerado. São eles:
- a janela e o cartão do CONSTRUIR;
- o tempo e o intervalo do balão;
- os avisos (máximo e duração);
- o tamanho das missões e dos alertas.

## Testes

Todos rodaram com o APPDATA isolado, **um por vez, em primeiro plano**.

- **Novos:**
  - **`b95_layout_v2`: 0 falhas.** Confere a barra de cima, Tab/aba fina/ordem da lista, os alertas e o clique, a barra
    agrupada e as funções liberadas, o cartão do selecionado, o rótulo compacto e o inteiro, a gaveta de obras com o
    martelo cinza, a pilha de avisos, a escala, as missões, o tema no HUD, a falta de número solto e os balões.
  - **`b95b_construir_abas`: 0 falhas.** Abre as 11 abas nas 3 escalas, nas áreas lógicas de verdade (1280x720,
    1422x800 e 1024x576): mesmo retângulo, nenhum cartão cortado, sem rolagem horizontal, cartões do mesmo tamanho com o
    botão no mesmo lugar, abas iguais com folga pro X, ←/→, Esc, última aba, auditoria das imagens e estados.
- **Ajustados:**

  | Teste | O que mudou |
  |---|---|
  | `hud_frostpunk` | a coluna da direita agora é a de alertas |
  | `b28` | a seção "CONSTRUÇÕES" virou a gaveta "OBRAS" |
  | `p20` | o cadeado é do bloqueado; o sem recurso mostra o que falta |
  | `b54` | escala em 3 opções; a tecla livre do teste passou do ponto para a barra |
  | `b83` | a hora e o dia da semana em rótulos separados |

- **A bateria inteira**, depois das mudanças:
  - os **79 de `tests/blocos`**, um por vez, com 0 falhas, incluindo o b51 (351 s);
  - os GUT `test_iso` (6/6), `test_iso_arte` (3/3) e `test_iso_pele` (3/3).

  **Duas instabilidades por sorteio, sem relação com o bloco:**
  - o **b84** falhou uma vez (um ipezinho se machucou na mina no meio da "volta") e passou nas duas rodadas
    seguintes;
  - o **b85** falhou uma vez ("pares conversando na mesma roda") e passou nas duas seguintes.
- **Não conferido em teste automático:**
  - **a fonte escolhida**, que ainda não foi aplicada;
  - **o visual.** Foi conferido pelas capturas com janela, em 1280x720. Não foi conferido em tela cheia de 1080p ou
    1440p.

## O que precisa do Marco

1. **Escolher a fonte** do corpo: 1, 2, 3 ou ficar com a de hoje.
2. Ver as capturas e dizer se:
   - o tamanho da hora agrada;
   - o cartão do selecionado está bom;
   - o menu "Janelas" está no lugar certo.
3. O **"armazém cheio"** ficou como "sem armazém para entregar", porque o armazém não tem limite. Ele quer que o
   armazém ganhe capacidade?
4. **Push** só com o OK dele.
