# Bloco 97 — Armazém com limite e níveis até 3

Data: 2026-10-07. Branch `isometrico`. Teste: `b97_armazem_nivel`.

**O pedido:** o Marco respondeu à pergunta sobre o balão "armazém cheio" (Bloco 95): "sim e o armazem pode ser upado
ate nivel 3". O plano está em `docs/BLOCO97_PLANO.md`.

**As decisões do Marco:**
- capacidade **400 / 1.000 / 2.000** e os custos da ampliação: "muito bom";
- obras continuam com **10 por viagem**;
- **armazém novo:** sim, mas "so desbloqueia nivel 2 da vila e proprio jogar define onde colocar, é uma construção
  nova";
- a arte pode ser feita já;
- save antigo: o Marco disse que os saves dele podem ser apagados. **Não apaguei nenhum save.** O jogo trata o save
  antigo sozinho (abaixo), e apagar os saves dele fica com ele.

**Skills usadas:**
- `save-systems` (nível, ampliação e armazéns novos no save; save antigo = nível 1);
- `godot-gdscript`;
- `godot-ui-control` (barra de espaço e botão na janela);
- `godot-gdscript-headless-testing`;
- `survival-crafting` (limite, espera e o que nunca some);
- `ai-behavior-trees-utility-ai` (quem espera e a agenda);
- `deep-iron-arte` (os níveis 2 e 3).

## Como ficou

1. **Capacidade.** É o total de unidades guardadas: minério, madeira, matéria-prima, couro e itens, tudo junto.
   - Nível 1 = **400**, nível 2 = **1.000**, nível 3 = **2.000**.
   - Fica em `@export capacidade_por_nivel` no `armazem.gd`.
   - Cada armazém tem o seu limite. `Economy.armazem_com_espaco(perto, n)` acha o mais perto com espaço, e
     `Economy.armazens_cheios()` diz se estão todos cheios.
2. **Cheio.**
   - **Quem vem entregar** (minerador, lenhador, caçador, fundidor, carpinteiro):
     - deposita até o limite e espera ao lado com o resto da carga;
     - aparece o balão **"armazém cheio"** (ícone do Bloco 95);
     - se outro armazém tem espaço, vai pra ele: o armazém cheio recusa quem vem entregar (`accepts_worker`).
   - **Alerta novo** na coluna da direita: "N armazém cheio — K esperando pra entregar. Venda, gaste ou amplie…".
     O clique leva ao armazém.
   - **As máquinas param.**
     - O coletor de madeira e o de minério ficam "parado — armazém cheio".
     - A broca da escavadeira só entrega onde cabe.
     - O vagonete espera carregado ("ARMAZÉM CHEIO") até caber a carga.
   - **Nada do jogador some.** Entram mesmo com o armazém cheio:
     - a devolução de cancelar;
     - o reembolso da decoração;
     - os prêmios;
     - a fundação.
   - **Fora do expediente a carga não prende.** Antes, quem tinha carga terminava a entrega antes de ir pra casa
     ou pra roda. Com todos os armazéns cheios, essa entrega nunca acabaria, e o ipezinho perderia o festival, o
     funeral e o sono. Agora ele fica com a carga, segue a agenda e entrega no expediente seguinte
     (`_entrega_pendente`). O teste do padre (b88) encontrou isso.
3. **Ampliar** (níveis 2 e 3).
   - Fica no botão **"Ampliar pro nível N"** da janela do Armazém e no cartão **"Ampliar armazém"** do CONSTRUIR
     (aba Vila). O cartão amplia o armazém de menor nível.
   - É **obra de engenheiro com material** (Bloco 96): os créditos saem na hora, o material fica reservado e o
     engenheiro leva.

   | Nível | Cabe | Custo | Segundos de engenheiro | Pede |
   |---|---|---|---|---|
   | 2 | 1.000 | 250 cr + 60 ferro + 100 madeira | 45 | vila no estágio 2 |
   | 3 | 2.000 | 600 cr + 100 ferro + 150 madeira + 20 pregos | 70 | vila no estágio 3 |

   - O ferro sai em barras a partir do estágio da fornalha (`Economy.custo_metal_texto`).
   - Durante a obra, o armazém continua no nível de antes e guarda normalmente; o andaime (`obra_3`) aparece por
     cima.
   - Cancelar devolve tudo.
4. **Armazém novo.** É uma construção nova: **libera no estágio 2 da vila**, e **o jogador escolhe o lugar**
   (`house_placer`).
   - Custa 300 cr + 80 ferro + 120 madeira e 50 s de engenheiro. O custo cresce a cada armazém construído, como as
     outras construções repetíveis.
   - Vira canteiro (`Canteiro` kind `"armazem"`) e sobe pelos desenhos de obra do armazém.
   - Começa no nível 1 e pode ser ampliado.
   - Quem trabalha perto entrega nele, e o engenheiro busca material nele.
5. **A janela do Armazém.**
   - Mostra "Este armazém (nível N): usado / capacidade — CHEIO", com a barra.
   - Com mais de um armazém, mostra também "todos (K): usado / capacidade".
   - Tem o botão Ampliar, com o custo ou o motivo de não dar.
   - Clicar num armazém no mapa mostra os números dele.
   - O rótulo do armazém no mapa mostra "usado/capacidade".

## Arte (PixelLab)

- O **armazém nos níveis 2 e 3**, prontos: `create_image_pro` com a imagem-guia 2:1, o armazém aprovado e o
  minerador como referência.
  - Foram 80 gerações; o saldo ficou em ~6.857.
  - Os candidatos ficam em `prototipos/camera/arte_iso/armazem/_cand97/` (fora do git), e o script é
    `armazem/niveis97.py` (`gera` / `escolhe`, que alinha a base com a do pronto).
- Integrados em `assets/game/iso/predios/armazem/nivel_2.png` e `nivel_3.png`. A âncora é a mesma do pronto (135,
  280), e o fundo da caixa ficou fixo; só a altura e a frente cresceram.
- **Obra da ampliação:** o andaime `obra_3` por cima, como na casa. **Armazém novo:** obra 1 → 2 → 3 → pronto, os
  desenhos de obra que o armazém já tinha.
- **Cartão "Ampliar armazém":** `assets/game/ui/icones/cartoes/armazem_ampliar.png`, feito do nível 2 reduzido (entrou
  no `ui95.py`, sem gasto a mais). O cartão "Armazém novo" usa o desenho do armazém.
- **Conferência:** `docs/arte/bloco97/armazem_niveis.png` (nível 1, 2 e 3 lado a lado).

![níveis](arte/bloco97/armazem_niveis.png)

## Save

Chaves novas, documentadas no cabeçalho do `save_manager.gd`:
- armazém: `nivel`, `ampliando`, `amp_total`, `amp_left` e `obra` (o material da ampliação);
- Centro da vila: `armazens_novos` ([{name, position}]).

Ao carregar, os armazéns construídos nascem de novo antes de o estoque de cada um ser aplicado, pelo nome.

**Save antigo:** o armazém fica no nível 1 e **com tudo que tem**, mesmo passando de 400. Ele só não recebe mais até
abrir espaço (vender, gastar ou ampliar).

## Comportamento que vale saber

- Um engenheiro com sobra de minério nas costas espera no armazém cheio antes de ir pra obra (é a espera de quem vem
  entregar). Ele sai assim que abre espaço.
- Com o armazém cheio, minerador e lenhador param de produzir. É o sinal de vender, gastar ou ampliar, e o alerta
  avisa.

## Testes

- **`b97_armazem_nivel`** (novo, **0 falhas**). Ele confere:
  - a capacidade por nível e o "usado" somando tudo;
  - cheio: o minerador fica com o resto da carga, com o balão e o alerta, e o armazém recusa quem vem entregar;
  - fora do expediente, a carga não prende ninguém;
  - o coletor não manda pro armazém cheio, e a devolução entra mesmo cheio;
  - o vagonete sabe esperar;
  - ampliar: estágio da vila, obra com material, créditos na hora, nível 2 = 1.000;
  - o armazém novo: estágio 2, lugar escolhido, canteiro com material, nasce no nível 1, cartões com imagem;
  - save e carregar com os 2 armazéns, o nível e o estoque;
  - save antigo = nível 1 com o que tem.
- **Testes ajustados:** `b45`, `b57`, `b58`, `b64`, `b79` e `b94` enchem o armazém além de 400 para outros
  assuntos. Eles ganharam a chave `armazem.gd limite_desligado = true` (estática, no `_initialize`), e o assunto deles
  não mudou.
- **Bateria completa**, um por vez, em primeiro plano, com a pasta `fake_appdata`:
  - passaram todos os testes de bloco, b25 → b97 (b51 incluído, 350 s), e `hud_frostpunk`, `manut_backups`,
    `p17`–`p20`, `p28_iso`, `p28_save`, `p29_*` e `p2_pendencias`;
  - passaram os GUT `test_iso` (6), `test_iso_arte` (3) e `test_iso_pele` (3).
- **Intermitentes** (passaram ao repetir; não parecem deste bloco):
  - `b92` falhou uma vez ("forjando de casaco");
  - `p29_predios` falhou 1 vez em 4, com 1 par na ordem de desenho. Na cena do teste o armazém está no nível 1, com o
    desenho de antes. Parece o lugar de um ipezinho andando.
- Depois da correção da agenda, passaram de novo `b64`, `b83`, `b84`, `b85`, `b86`, `b88` e `b97`.
