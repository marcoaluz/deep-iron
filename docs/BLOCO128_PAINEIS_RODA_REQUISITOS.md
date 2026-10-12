# Bloco 128 — Janelas por prédio, roda do mouse e requisitos da função

Três correções de interface, pedidas pelo Marco. Teste: `b128_paineis_roda_requisitos` (115+ verificações). Nada foi jogado nem
visto na tela: tudo foi conferido por teste headless e leitura de código. Os `@export` novos são dois, só do cartão de requisitos.

## 1) Cada prédio abre a SUA janela

**Antes:** o Arsenal e o Campo de treino abriam a janela da Defesa (`panel_id = "defesa"`), a Taverna abria a de Bem-estar
(`"moral"`), e quase toda janela de prédio tinha um botão "Construir… escolher lugar".

**Agora:** `panel_id` do Arsenal = `arsenal`, do Campo = `campo`, da Taverna = `taverna`. A janela da Defesa (G) é só a visão
geral. Construir prédio novo é só no menu CONSTRUIR (Espaço); as janelas apontam pra ele (botão "Abrir o CONSTRUIR" na aba certa,
`hud.botao_construir` / `hud.abre_construir`). Melhorar o próprio prédio (ampliar taverna/enfermaria/armazém/casa, melhorias do
Centro, muro/portão) fica na janela, e o CONSTRUIR também lista.

### Auditoria dos `*_panel.gd`

| Janela (arquivo) | Quem abre | O que mostrava | O que mostra agora |
|---|---|---|---|
| **Defesa** `defense_panel.gd` | G, portão (barricada) | Invasão/previsão, tier, bestiário, patrulhas, muro (ampliar/consertar), guardas, **botão Construir campo, Arsenal inteiro (cavalete, forja, armas, forjar/consertar, botão Construir Arsenal)** | **Visão geral**: invasão, previsão, tier + dificuldade, bestiário, patrulhas do fundo, muro/portão (estado e "melhorias"), **postos** (cada guarda: arma e onde está), atalhos pro Arsenal e pro campo |
| **Arsenal** `arsenal_panel.gd` (NOVA) | clique no Arsenal | (dentro da Defesa) | Forja (fila e barra), cavalete, desarmados, forjar/consertar cada arma; "1 de N" com vários |
| **Campo de treino** `campo_panel.gd` (NOVA) | clique no campo | (dentro da Defesa: só uma linha) | Guardas, % de treino de cada, quem treina agora, ritmo e tempo até o teto |
| **Taverna** `taverna_panel.gd` (NOVA) | clique na taverna | (dentro de Bem-estar) | Frequentadores (e ânimo de cada), lugares ocupados, diversão por segundo, bônus de ânimo da vila, "Melhorias": ampliar |
| **Bem-estar** `moral_panel.gd` | B, parque | Ânimo, causas, greve, festa, **taverna (ampliar, construir outra), parque (construir)** | Ânimo, causas, greve, festa, resumo da taverna + atalho pra janela dela, resumo dos parques, apontamento pro CONSTRUIR (Lazer) |
| **Centro da Vila** `hub_panel.gd` | clique, U | Estágio, expandir, **construir casa inicial / cozinha / coletor (escolher lugar)**, melhorias (incl. "Construir casa" de Moradias) | Estágio, expandir, onde as casas podem ficar, apontamento pro CONSTRUIR, melhorias (Enfermaria, Trilhas, Posto; a casa saiu) |
| **Enfermaria** `enfermaria_panel.gd` | clique, I | Leitos, pacientes, ampliar, **construir outra** | Leitos, pacientes, memorial, ampliar ("Melhorias"), apontamento pro CONSTRUIR (Saúde) |
| **Laboratório** `lab_panel.gd` | clique, Q | Árvore de pesquisa, **construir laboratório (escolher lugar)** | Árvore de pesquisa; apontamento pro CONSTRUIR (Pesquisa) |
| **Oficina** `oficina_panel.gd` | clique na Oficina/Vestiário, O | Ferramentas, equipamento, encomendas, **construir Oficina e Vestiário (escolher lugar)** | Ferramentas, equipamento, encomendas; sem Oficina/Vestiário só aponta pro CONSTRUIR (Defesa e equipamento) |
| **Fornalha / Carpintaria / Carvoaria / Curtume** `fornalha_panel.gd` (+3) | clique | Receitas, quantidade, fila, **construir outra (escolher lugar)** | Receitas, quantidade, fila; apontamento pro CONSTRUIR (Produção) |
| **Coletor de madeira** `coletor_panel.gd` | clique | Operador, etapas da ruína, **construir outro** | Operador, etapas da ruína; apontamento pro CONSTRUIR (Coleta automática) quando a ruína foi restaurada |
| **Coletor de minério** `coletor_minerio_panel.gd` | clique | Operador, jazida, **construir outro** | Operador, jazida; apontamento pro CONSTRUIR (Coleta automática) |
| **Calendário** `calendario_panel.gd` | clique na Igreja, domingo | Eventos, escolha do domingo, padre, **construir Igreja** | Eventos, escolha do domingo, padre; sem Igreja aponta pro CONSTRUIR (Culto) |
| **Sol** `sun_panel.gd` | Y, gerador | Estação, previsão, **marcar o lugar do gerador (escolher lugar)**, etapas do escudo | Estação, previsão, etapas do escudo; sem gerador aponta pro CONSTRUIR (Vila) |
| Escavadeira `escavadeira_panel.gd` | clique, E | Peças, fabricação, reatores (construir/instalar) | igual: "Construir" do reator é fabricar peça da própria máquina, não escolhe lugar |
| Armazém `armazem_panel.gd` | clique | Estoque por categoria, vender, ampliar | igual (ampliar é "melhoria"; o CONSTRUIR também lista) |
| Casa `casa_panel.gd` | clique | Camas, moradores, ampliar, camas de tábua | igual (ampliar é melhoria; o CONSTRUIR lista "Casa nível 2 e 3") |
| Cozinha `cozinha_panel.gd` | clique | Cardápio, ração | igual |
| Elevador / Abismo / Vagonete (`elevador_panel`, `abyss_panel`, `vagonete_panel`) | clique | Restauração por etapas, cabine | igual (restaurar não escolhe lugar) |
| Robô, Galeria `robo_panel.gd`, `galeria_panel.gd` | clique | Robô antigo; dinamite | igual |
| Caravana `caravana_panel.gd` | clique no posto | Compra/venda, encomendas | igual |
| Trabalho `work_panel.gd` | botão | Áreas de trabalho (`area_placer`: marca área, não prédio) | igual |
| Missões, Catálogo, Expedições, Políticas, Pedidos, Migrantes, Ficha, Diário | teclas/menu | (sem prédio) | igual |
| Configurações, Nova partida, Debug | menu | (sem prédio) | igual |

**Não mudou (anotado):** o Vestiário ainda abre a janela da Oficina (a seção Equipamento dela), o Cemitério abre o Calendário e a
Escola/Parque não têm janela própria (o parque abre Bem-estar). Ficam pra um próximo bloco se o Marco quiser.

### CONSTRUIR: o que ganhou cartão

Tudo que antes só se construía por janela já tinha cartão com imagem (Casa inicial, Casa/Moradias, Cozinha, Horta, Estufa, Nova
enfermaria, Taverna, Ampliar taverna, Parque, Laboratório, Arsenal, Campo de treino, Vestiário, Oficina, Fornalha, Carpintaria,
Carvoaria, Curtume, Coletor de madeira/minério, Igreja, Escudo solar, Armazém). Faltava um só: a **melhoria do muro e do portão**
(só estava na janela da Defesa). Ganhou o cartão **"Muro e portão"** (aba Defesa e equipamento) com a imagem reaproveitada do
sprite do portão (`assets/game/ui/icones/cartoes/portao_ampliar.png`, pelo `ui95.py`, nada do PixelLab).

## 2) Roda do mouse

`camera_controller.gd`: a roda não dá zoom quando o mouse está sobre a interface. O teste olha duas coisas:

- o controle sob o mouse (`gui_get_hovered_control`) — e, porque o "hover" do motor nem sempre acompanha, também a geometria: um
  controle da interface, visível, opaco (`MOUSE_FILTER_STOP`) ou lista (`ScrollContainer`) com o ponto dentro (`_sobre`);
- uma janela modal aberta (grupos `evento_cartao`, `pause_menu`, `victory_screen`, `game_over`, `janela_modal` — o corte da mina e
  a janela de evento entraram em `janela_modal`).

**Medido:** sem a trava, a roda vazava para o mapa sobre o **Armazém**, a **Oficina**, o **CONSTRUIR**, a **lista de pessoas** e uma
modal aberta (5 dos 15 casos). Com ela, nenhum. A garantia fica na câmera (um ponto só) em vez de em cada `ScrollContainer`: um
`gui_input` conectado ao scroll que aceitasse a roda também impediria o próprio scroll.

## 3) Requisitos da função

`data/funcoes/requisitos.json` (os requisitos e os caminhos) + `data/funcoes/textos.txt` (os textos) + os testes em
`scripts/core/requisitos_funcao.gd`. As 16 funções:

| Função | Requisitos (✓/✗) | Caminhos que bastam |
|---|---|---|
| Minerador | jazida livre; espaço no armazém | todos |
| Lenhador | árvore livre; espaço (madeira) | todos |
| **Caçador** | arco (Oficina); toca estudada; horta (e sem agricultor) | arco+toca **ou** horta |
| Agricultor | horta/estufa; espaço (comida) | todos |
| Cozinheiro | cozinha; matéria-prima no armazém | todos |
| Fundidor | Fornalha; ordem na fila (pausada = o que falta) | todos |
| Ferreiro | Oficina ou Arsenal; encomenda | todos |
| Carpinteiro | Carpintaria; ordem (ou cama pra montar) | todos |
| Engenheiro | obra esperando | todos |
| Carregador | entrega pra levar | todos |
| Mecânico | máquina gasta ou quebrada | todos |
| Médico | Enfermaria | todos |
| Pesquisador | Laboratório; pesquisa em andamento; algo pra catalogar | lab+pesquisa **ou** catálogo |
| Padre | Igreja; cemitério (informa) | Igreja |
| Batedor | toca a rastrear (informa) | sempre |
| Guarda | muro; Arsenal (informa); campo de treino | muro **ou** campo |

Onde aparece: o **cartão** ao dar a função (`✗ Falta o arco: a Oficina faz`, `✗ Nenhuma toca estudada: o pesquisador precisa
catalogar`, `✗ Construa a horta: CONSTRUIR > Alimentação`, e confere de novo a cada 0,5 s: o ✗ vira ✓); o **cartão do selecionado**;
a **dica do botão** da função (1 s); o **balão de motivo** (o ícone de sempre + o texto específico, com o ipezinho selecionado:
`motivo_texto()`); e a **fala do capataz** no Primeiro dia guiado (passos 3, 5 e 6: "Atenção, caçador sem trabalho. Falta o arco: a
Oficina faz.").

O caçador do relato tinha as três faltas ao mesmo tempo; agora o motivo é o primeiro do caminho principal (o arco).

## `@export` novos (`ui/requisitos_cartao.gd`)

| Nome | Padrão | O que é |
|---|---|---|
| `segundos_aberto` | 14 | segundos que o cartão fica aberto sozinho (0 = só fecha no clique) |
| `intervalo` | 0,5 | segundos entre as conferências dos requisitos |

## Testes

- Novo: `b128_paineis_roda_requisitos`.
- Ajustados (liam botões que saíram): `b41_parque`, `b44_vestiario`, `b45_coletor_madeira`, `b58_oficina_construivel`, `b81_coletor_ruina`.
- Regressão verde (0 falhas): b35, b36, b39, b41, b44, b45, b46, b54, b56, b57, b58*, b77, b81, b86, b88, b94, b95, b97, b99, b103,
  b105, b106, b112, b113, b123, b125, b126, b127. (*b58 estourou o tempo numa execução e passou na seguinte.)
- **Falha que já existia** e que este bloco não toca: `b47_varios_predios` ("load: 2 Arsenais e 2 campos": o Arsenal volta 8 px
  deslocado depois do load). Falha também no HEAD sem as mudanças deste bloco (conferido). Não investigada.

## O que não foi verificado

- Nada visto na tela: a posição do cartão de requisitos sobre a barra de funções, o texto do balão no mapa e as janelas novas.
- A roda do mouse foi testada em headless (eventos injetados, janela de 64 px esticada); no jogo real vale o hover do motor + a
  geometria, que dão a mesma resposta nos casos testados.
- Os requisitos de função cobrem o que a IA faz hoje; casos raros (andar não reconhecido, área de trabalho) usam a escolha de estação
  da própria IA (`_has_usable_station`) e estão aí.
- Vestiário, Cemitério, Escola e Parque seguem sem janela própria (ver acima).
