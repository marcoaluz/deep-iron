# DEEP IRON: visão do mapa (Marco, 2026-09-30)

Base para a montagem do mapa (Prompt 27) e a integração (Prompts 28–29). Veio do texto que o
Marco usou pra gerar a imagem de referência (o corte com a vila no alto e os níveis
descendo). O mapa do jogo é **isométrico** (o corte lateral é a tela do Prompt 25).

## Da entrada ao fundo

1. **Floresta (começo do mapa).**
   - Árvores esparsas, com visibilidade aberta (floresta dispersa, não mata fechada).
   - **1–2 tocas de animais:** coelho e **javalizinho**.
   - Uma **máquina grande de cortar árvores, estragada**. O jogador conserta, e aí começa a
     colher e cortar as árvores.
2. **Portão quebrado.**
   - É a **única entrada** da vila, e é reconstruído depois.
   - À noite o robô gigante fica parado nele (`prompt05/FLUXO_ROBO.md`).
3. **Pedreira (onde fica a vila).** Uma sociedade dentro da pedreira, rodeada de rocha e de
   mina:
   - casas dos moradores;
   - Centro da Vila;
   - posto médico (Enfermaria);
   - Arsenal;
   - fornalha (Oficina/forja);
   - lugar de comer (Comedouro);
   - **tochas** iluminando.
4. **Entrada da mina** um pouco depois da pedreira, no paredão (`relevo/final/superficie/boca_mina.png`).
5. **Canto esquerdo: plataforma gigante de perfuração**, tipo plataforma de petróleo, que fura
   a terra pros mineiros descerem. É a **Escavadeira** (Prompt 13).
6. **Embaixo: a plataforma da mina, com elevador**, e mais adiante **outro elevador** que
   desce pro nível seguinte (nível 2 → abismo). Elevador e Elevador do abismo, Prompt 13.
7. **Visual:** mapa bonito, pixel art, bastante pedra espalhada.

## O que isso acrescenta ou muda na arte

| Item | Onde entra | Situação |
|---|---|---|
| **Javalizinho** (animal novo, além do coelho) + toca | Prompt 15 | **novo** no inventário |
| **Máquina grande de cortar árvores**, estragada → consertada (estágios como obra) | Prompt 13 (máquinas); no jogo, o **Coletor de madeira** | **novo**: o Coletor passa a ser essa máquina, não um prédio comum |
| **Portão** da vila: quebrado → em obra → pronto | Prompt 12 (defesa), junto da Barricada | **novo** |
| Chão da **pedreira**: terraços de rocha cortada, cascalho, blocos soltos | Relevo: bloco de rocha + cascalho (Prompt 6) e pedras soltas (Prompt 8) | coberto; a parede cortada da pedreira pode ganhar uma variação com marcas de corte (~20) |
| **Tochas** pela vila | Prompt 14 (tocha acesa/apagada) + luz no código (Prompt 19) | já previsto |
| Floresta dispersa + clareira | Prompt 9 (árvores) + clareira (Prompt 6) | já previsto |
| Plataforma de perfuração, elevadores | Prompt 13 | já previsto; a escavadeira segue a ideia de "plataforma de petróleo" |

## Sugestões: TODAS ACEITAS pelo Marco (2026-09-30)

- **Trilho da boca da mina até o Armazém da pedreira**, com vagonete. Liga visualmente a mina
  à vila. Os trilhos da mina já estão prontos e encaixam (`relevo/trilhos.py`).
- **Guindaste de madeira na pedreira**, ou um guincho de blocos: um prop grande que diz
  "pedreira" de longe (Prompt 14, ~25).
- **Cerca de estacas** marcando a borda entre a floresta e a pedreira, até o portão ser
  reconstruído (Prompt 14).
- **Terraços da pedreira em degraus** (2–3 platôs, com escada de pedra ou rampa entre eles),
  do mesmo jeito do mini-mapa da superfície. A vila fica em patamares, e o relevo aparece.

## Pedidos do Marco depois do Prompt 10 (2026-09-30)

- **Fundição** (prédio novo, não é a Oficina): refina o que vem da mina, **pedra → carvão**,
  **ferro → aço**. Serve pra upar e evoluir equipamento. Arte no **Prompt 12**; a mecânica é
  código (integração).
- **Arsenal** também faz **armas e armaduras** (criação), não só guarda. Arte no Prompt 12.
- **Laboratório de pesquisa**: o pesquisador fica lá pesquisando itens novos. Prompt 12.
- **Muro + portão bonito, com níveis 1, 2 e 3** (upgrade), além do portão quebrado do começo.
  Prompt 12.
- **Criaturas mais fortes e uma criatura mestre (chefe)**: Prompts 16–17.
- **"Comedouro" passa a se chamar "Cozinha"** (o nome antigo lembrava bicho). Na arte já é a
  cozinha comunitária (Prompt 11). No jogo, trocar o nome no menu, nos textos e na cena
  (`comedouro.gd`, `build_menu.gd`...) na integração.
