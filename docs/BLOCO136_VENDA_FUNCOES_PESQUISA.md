# Bloco 136 — Três janelas novas: vender no armazém, a janela da função e o pesquisador

Pedido do Marco: três janelas, com a regra de construção só no CONSTRUIR (Bloco 128) e o gerente de janelas do Bloco 135.
Teste `tests/blocos/b136_venda_funcoes_pesquisa.gd` (51 OK). As capturas ficam em `docs/arte/bloco136/`
(`tests/capturas_bloco136.gd`).

## 1. Vender no armazém: a caixa de venda

O "Vender…" de um item e o botão da categoria ("Vender tudo", "Vender metal"…) abrem a CAIXA DE VENDA
(`ui/caixa_venda.gd`). **Nada vende sem confirmar.**

- **Item:**
  - "Você está vendendo: [ícone] Gema azul — tem 200, 30 cr cada";
  - a quantidade: −10 / −1 / um campo de digitar (com as setinhas) / +1 / +10 / máx, com o valor em créditos ("200 × 30 cr =
    6000 cr");
  - "Vender tudo (200 = +6000 cr)", Confirmar e Cancelar.
- **Categoria:** o resumo (o que vai e quanto rende) e Confirmar/Cancelar.
- **Fechar:** Cancelar, o X e o **Esc** fecham sem vender. O Esc fecha a caixa antes de qualquer janela (grupo
  `fecha_com_esc` em `hud.fecha_janela_de_cima`). A janela do armazém fica aberta.
- **O que se vende:** só o que a Economia deixa (`pode_vender`). Madeira, comida etc. continuam sem botão, e a caixa nem
  abre pra elas.
- **"Vender sozinho (auto)" ligado:** a caixa avisa que o minério que chegar vai ser vendido sozinho.
- **Na tela:** véu escuro, centrada, numa camada por cima do HUD e do capataz. É modal pra roda do mouse (sem zoom no
  mapa).
- **O que saiu:** a barra de venda de antes, embaixo da grade. Os nomes `seleciona`, `vender_selecionado`, `_sel_id`,
  `_sel_qtd` e `_sel_tudo` seguem existindo, agora ligados à caixa.

Captura: `1_caixa_venda.png`.

## 2. A janela da função

**Clicar num botão de função da barra sem ninguém selecionado** abre a janela daquela função (`core/funcoes_panel.gd`,
`hud.abre_funcao`). Antes, isso só dava o aviso "Selecione ipezinhos". Com alguém selecionado, o botão segue dando a
função, como antes. A dica do botão explica as duas coisas.

- **No topo:** o nome, a descrição e os requisitos ✓/✗ da função (Bloco 128), e um seletor pra ver outra função sem fechar.
- **As listas:** "COM A FUNÇÃO" e "SEM ESTA FUNÇÃO". Na segunda, quem está sem função vem primeiro.
- **Cada linha:** retrato, nome (com a função atual, quando é outra), ânimo e o que está fazendo, mais dois botões:
  - **Dar: <Função>** / **Tirar**;
  - **Trocar ▾**: o menu de todas as funções liberadas com ✓ (tem trabalho pra ele agora) ou ✗ e o que falta. É avaliado
    pra aquela pessoa só na hora de abrir o menu: nada roda a cada segundo, pra não repetir a travada do Bloco 135.
- **A contagem do botão da barra** muda na hora (`_refresh_order_bar` logo depois).
- **Regras de sempre:**
  - o padre: só homem e um só; o item fica desligado no menu, com o motivo;
  - criança não aparece.

Capturas: `2_funcao_minerador.png` e `2b_trocar_menu.png`.

## 3. O pesquisador: a ficha com a pesquisa

**Mudança de regra:** a pesquisadora NÃO sai mais sozinha pra catalogar (Bloco 102). Só o jogador manda, como as ordens
de produção.

- **A ficha do pesquisador** ganhou a seção PESQUISA (`ui/estudos_lista.gd`, dentro do `ficha_panel.gd`). O botão do
  cartão do selecionado vira "Ficha e pesquisa".
  - **Agora:** o que ele faz (no laboratório: a pesquisa, a % e o tempo que falta em horas de jogo; no campo: o que está
    estudando). Tem a barra de progresso.
  - **FILA:** a pesquisa de agora, as pesquisas encomendadas e os estudos de campo, cada um com Cancelar.
  - **PARA ESTUDAR — CATÁLOGO:** o que a vila avistou e não estudou (minerais, animais, criaturas, lugares), com a
    situação e o tempo. O corpo da criatura abatida aparece como "Lumívoro (criaturas) — pronta para estudar: o corpo
    some em 32 h • leva ~2 h de anotação". Criatura sem corpo: "precisa de um corpo (abata um)".
  - **PESQUISAS DO LABORATÓRIO:** a árvore, com custo, pontos e tempo pelo número de pesquisadores. Pesquisar fica
    desligado com o motivo na dica.
- **O catálogo (`catalogo.gd`):**
  - `fila_estudo` (`pede_estudo`, `cancela_estudo`, `motivo_estudo`, `situacao`, `tempo_texto`);
  - a pesquisadora só escolhe alvos da fila, na ordem;
  - ao concluir, sai da fila; o cartão da criatura agora traz "Por que veio: …" e "A ficha está no Catálogo (R)".
- **O laboratório (`research.gd`):** a FILA DE PESQUISA.
  - `pede(id)`: começa já, se o laboratório estiver livre; senão, entra na fila. Pode entrar na fila a que precisa da de
    agora. O caminho que a fila já escolheu fecha o outro.
  - Quando a de agora acaba, a próxima começa sozinha e paga o custo nessa hora. Sem o custo, espera e tenta de novo a
    cada `intervalo_fila` (2 s, novo `@export`).
  - `cancela(id)`: tira da fila; a de agora para e **devolve o custo** (o progresso se perde). A que dependia dela sai da
    fila.
  - `tempo_restante()`, `ritmo()`, `motivo_fila()`.
- **Save:** `research.fila` e `catalogo.fila_estudo`. Save antigo, sem as chaves: filas vazias. O teste confere os dois
  casos.

Captura: `3_ficha_pesquisador.png`.

## Testes

- **Do bloco:** `b136_venda_funcoes_pesquisa` (51 OK).
- **Ajustados:**
  - b82: a categoria agora pede confirmação, e a caixa fecha depois de vender;
  - b102, b103 e b104: `catalogo.gd estudo_sozinho = true`, porque esperam a pesquisadora sair sozinha;
  - b47: o cartão do Vestiário pronto é "✔ Construído" + Abrir desde o Bloco 135. A conferência antiga ("um por vila")
    falhava desde então e eu não tinha pego.
  - b113: falhava desde o Bloco 129 (fazia `preload` de um painel que usa o autoload `SaveManager`). Agora usa `load` em
    tempo de execução.
- **Regressão, um por vez, verde:** b39, b47, b52, b60, b62, b68, b82, b100, b101, b102, b103, b104, b109, b110, b112, b113,
  b122, b128 e b135.

## Não verificado

- **Toque:** nada jogado com mouse e teclado. Os cliques foram simulados no teste.
- **Coisas que valem conferir jogando:**
  - a caixa de venda com teclado (Enter no campo aplica o número; o foco fica no Confirmar);
  - o menu "Trocar ▾" com muitas funções em telas pequenas.
- **Decisão minha:** com uma pesquisa no laboratório, os pesquisadores vão pro laboratório primeiro. Os estudos de campo
  da fila andam quando não há pesquisa ou com pesquisador sobrando (vagas do laboratório), como já era a prioridade.
