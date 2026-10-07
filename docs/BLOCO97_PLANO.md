# Bloco 97 — Armazém com limite e níveis até 3 (PLANO, esperando aprovação do Marco)

Pedido do Marco (resposta sobre o balão "armazém cheio" do Bloco 95): **"sim e o armazém pode ser upado até nível 3"**.

## Hoje

- O armazém **não tem limite**: guarda minério, madeira, matéria-prima, couro e itens (barras, tábuas, pregos…) sem
  fim.
- O jogo já aceita **vários armazéns** (grupo `armazens`; cada um guarda o seu, e a vila soma). Mas não existe cartão
  para construir outro: a partida tem um só.
- **Entram coisas no armazém por ~12 caminhos:**
  - quem entrega no lugar: minerador, lenhador, caçador, cozinheiro, fundidor, carpinteiro;
  - as máquinas: coletor de madeira, coletor de minério, broca da escavadeira, vagonete e ferrovia;
  - a Oficina;
  - as devoluções: cancelar, decoração removida;
  - prêmios (o chefe, o cristal da criatura), a fundação e o painel F3.

## Proposta

1. **Capacidade = total de unidades guardadas** (tudo junto: minério + madeira + matéria-prima + couro + itens).
   `@export` por nível:

   | Nível | Capacidade | Como sobe | Custo (obra de engenheiro, com material — Bloco 96) | Pede |
   |---|---|---|---|---|
   | 1 | **400** | começo | — | — |
   | 2 | **1.000** | "Ampliar armazém" | 250 cr + 60 ferro + 100 madeira, 45 s | vila no estágio 2 |
   | 3 | **2.000** | "Ampliar armazém" | 600 cr + 50 barras de ferro + 150 madeira + 20 pregos, 70 s | estágio 3 (fornalha) |

   Referências: a fundação dá 170; a peça mais cara da escavadeira pede 625 minério (estágio 4: cabe no nível 2); a
   etapa mais cara do escudo pede ~300.
2. **Cheio:**
   - **Quem entrega** (minerador, lenhador, caçador, fundidor, carpinteiro, cozinheiro guardando) espera no armazém
     com a carga: balão **"armazém cheio"** (o ícone do Bloco 95) e alerta novo na coluna da direita. Volta a
     trabalhar quando abrir espaço: vender, gastar ou ampliar.
   - **As máquinas** (coletores, broca, vagonete, ferrovia) param de mandar: "armazém cheio" no rótulo.
   - **Nunca some nada do jogador:** devolução de cancelar, reembolso de decoração, prêmio e fundação **entram mesmo
     cheio** (passam do limite). O "auto" de vender continua ajudando.
3. **A janela do Armazém:** a barra "usado / capacidade", o botão "Ampliar (nível N)" com o custo e o motivo, e o
   cartão "Ampliar armazém" no CONSTRUIR (aba Vila), **com imagem** (regra 12).
4. **Arte (regra 11):** o armazém nos níveis 2 e 3, prontos, no PixelLab. A obra da ampliação usa o andaime (obra_3)
   por cima do prédio atual, como a ampliação da casa já faz.
   - Os dois pedidos e o piloto: **~100 gerações** (saldo 6.937).
   - A imagem do cartão sai do nível 2 reduzido (sem gasto a mais).
   - Os prompts vão antes de gastar, como sempre.
5. **Save:** o armazém ganha `"nivel"`. Save antigo = nível 1, mas **um armazém que já passou de 400 continua com o
   que tem** (só não recebe mais até ter espaço). Se for melhor, pode começar no nível que caiba o que já tem.
6. **Teste `b97_armazem_nivel`:**
   - a capacidade por nível;
   - cheio, o minerador espera com o balão e o alerta;
   - o coletor para;
   - a devolução de cancelar entra mesmo cheio;
   - a ampliação vira obra com material e a capacidade sobe;
   - o save antigo.

## Decisões do Marco

1. Os números: capacidade **400 / 1.000 / 2.000** e os custos da ampliação. Ou prefere contar só minério e madeira?
2. Save antigo com mais de 400: **fica como está** (não recebe até ter espaço) ou **começa no nível que cabe**?
3. Quer também um cartão **"Armazém novo"** (construir outro armazém, perto da vila)? Encurta as viagens do
   engenheiro do Bloco 96.
4. Pode gastar **~100 gerações** na arte dos níveis 2 e 3 (prompts antes)?
