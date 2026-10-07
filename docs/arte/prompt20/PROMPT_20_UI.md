# Prompt 20: interface (sistema visual)

Data: 2026-10-02. Branch `isometrico`. Geração: **45** (1 kit de interface do UI Template Pro do
PixelLab = 40; 5 cursores pixen). O checkpoint foi dispensado pelo Marco.

## Como testar

Abra o jogo: **toda a interface** está com a pele nova, sem mudar o que cada botão faz:

- **painéis/janelas** (força de trabalho, construções, todas as janelas de prédio, menu de pausa,
  fim de jogo, vitória): tábuas escuras com moldura de ferro e rebites nos cantos;
- **barra de recursos** (topo) e **barra de funções** (embaixo): viga de madeira com cintas de ferro;
- **botões**: tábua com borda de ferro (normal, passar o mouse, apertado, desabilitado); os botões de
  função são placas de ferro com rebites, e a função ativa fica com a **borda âmbar**;
- **menu de construção** (espaço): abas de couro (a escolhida fica clara), **cartões** com moldura
  (trancado: escuro + **cadeado**; "em breve": apagado);
- **dicas (tooltip)**, faixas de aviso: couro com borda de ferro;
- barras de progresso com aro de ferro, caixa de marcar e slider de ferro (configurações);
- **controle de velocidade** novo na barra de cima: pausa, 1x, 2x, 3x;
- **cursor do mouse**: seta de ferro; **martelo** ao construir (lugar válido) e **proibido** (lugar
  inválido); **espada** em cima de criatura; **luva apontando** em cima de ipezinho/robô;
- **janela de evento** nova (`scripts/ui/event_window.gd`): título na plaquinha, ilustração,
  texto e botões. É usada pelas ilustrações do Prompt 24.

## Mockup (no jogo de verdade)

`ui_jogo_hud.png` (jogo com HUD e um ipezinho selecionado), `ui_menu_construir.png` (menu de
construção aberto), `ui_janela_evento.png` (janela de evento) e `ui_painel_predio.png` (painel de
prédio). O kit gerado está em `kit_gerado.png`.

## O que o prompt pedia e o que foi feito

| Pedido | Feito |
|---|---|
| Moldura de painel grande e pequena, barra de título, separador | painel (9-slice), dica/faixa (painel pequeno), plaquinha de título (janela de evento); separadores continuam linhas finas |
| Botões: normal, hover, pressionado, desabilitado; de ícone; aba | os 4 estados (feitos da mesma arte: brilho/escuro/cinza), botão de ícone com o "aceso" âmbar, abas de couro |
| Barra inferior do HUD e barra de recursos | as duas vigas |
| Cartão do menu de construção (normal, bloqueado, "em breve") | os 3 + cadeado |
| Tooltip, janela de evento/decisão, caixa de confirmação | tooltip no tema; janela de evento nova (serve de confirmação com 2 botões) |
| Barras de progresso, slider, checkbox, lista/rolagem | barras com aro de ferro, slider, caixa de marcar, barra de rolagem e campo de lista no tema |
| Controles de velocidade (pausa, 1x, 2x, 3x) | **não existiam no jogo**: criados (barra de cima; `Engine.time_scale`; volta a 1x ao sair da partida) |
| Cursor: normal, construir, proibido, atacar, selecionar | os 5, trocando pelo que está embaixo do mouse |
| Painel de seleção de personagem e de prédio | os painéis de sempre com a pele nova; o retrato entra no Prompt 23 |

## Como funciona

- `prototipos/camera/arte_iso/ui/kit_a.png` (gerado, 600×448) → `ui/fatia.py` recorta cada peça,
  tira a plaquinha do título da janela (pra o 9-slice esticar sem deformar), monta a viga com ponta
  + meio liso + ponta e faz os estados → `assets/game/ui/` + `ui.json` (margens).
- `scripts/ui/ui_skin.gd`: os estilos 9-slice (StyleBoxTexture) e o **tema da janela raiz** (vale pra
  quem não tem estilo próprio: menus, dicas, caixas de marcar, sliders, rolagem).
- O HUD já montava a interface por funções centrais (`_button`, `_panel_style`, `_bar`): elas agora
  pedem a pele nova, então **todas as janelas de prédio** mudaram sem mexer em cada uma.

## Defeitos achados e corrigidos

| Defeito | Correção |
|---|---|
| O menu de construção crescia (texto quebrando no 1º quadro) e nunca encolhia: com a moldura nova ele saía da tela | volta pro tamanho do conteúdo ao abrir/trocar de aba (`build_menu.gd`, `_encolhe`) |
| O menu de construção ficava por baixo do painel da força de trabalho | vai pra frente ao abrir |

## Limites

1. A pele entra em pixel 1:1 na tela base (1280×720); em 1080p o projeto amplia tudo 1,5×
   (`canvas_items`), então alguns pixels da moldura ficam desiguais (igual ao resto do jogo).
2. O cursor é de 32 px (o do sistema não amplia junto com a tela).
3. A fonte continua a de antes até o Prompt 22.
