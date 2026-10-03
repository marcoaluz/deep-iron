# DEEP IRON — Bloco 72: Mapa do jogo × imagem de referência (auditoria + fechamento das diferenças)

## Contexto
Os Blocos 67–71 já ampliaram o mundo, criaram níveis temáticos (S1–S5), rampa, camadas/atmosfera e decoração (vila antiga a leste, passarelas, ponte de corda, rampa em espiral, etc.). Marco quer saber **o quanto o mapa do jogo já se parece com a imagem de referência** (`docs/arte/referencia_mapa_mundo.jpg` — Marco coloca o arquivo lá antes de rodar; é arte conceitual: superfície com vila/floresta/encosta + 5 subsolos temáticos + rampa em espiral + kit de peças + vista em camadas + composição A→D).

A referência é **norte visual, não especificação pixel a pixel**. O objetivo é chegar perto em estrutura, atmosfera, densidade de detalhe e leitura de cada andar.

## Passo 0 — Revisão (reportar antes de mudar qualquer coisa)
- Gerar capturas de tela (via ferramenta de captura/cena de teste que já exista; se não existir, criar uma cena/script de captura em `tools/`) de: superfície inteira ampliada, cada andar S1–S5 visto de cima/isométrico, a rampa em espiral, a tela Corte da mina (F2) e uma vista da vila cheia.
- Montar um quadro comparativo **referência × jogo**, por região: superfície/vila, encosta e entrada da mina, S1, S2, S3, S4, S5, rampa, atmosfera/luz. Para cada uma: o que já bate, o que falta, o que destoa.
- Avaliar três dimensões: (1) **estrutura** (andares, ligação vertical, proporção), (2) **densidade de detalhe** (props, vegetação, cristais, trilhos, passarelas por m²), (3) **atmosfera** (luz ambiente por nível, névoa, brilho de lava/ácido/água).
- Medir FPS e nº de nós/luzes antes de qualquer acréscimo, para não passar do orçamento (hoje vila cheia ~46 FPS; meta 60).
- Listar quais lacunas são só **dados/decoração** (barato), quais pedem **arte nova** (PixelLab) e quais pedem **código** (caro).

## O que implementar (depois do relatório, por ordem de custo-benefício)
1. **Densidade de decoração por dados:** aumentar props por nível/zona para chegar perto da referência (vegetação e rochas na superfície, cristais, trilhos, passarelas, ventiladores, placas, vagonetes nos andares), sem mexer em gameplay, respeitando o orçamento de luzes/partículas.
2. **Ajuste de atmosfera por andar:** cor/intensidade de luz, brilho de poças/lava/água, névoa/partículas e reflexos do lago até cada andar ter a leitura de cor da referência (verde S2, laranja S3, misto S4, azul S5).
3. **Rampa em espiral e ligação vertical:** garantir que a rampa leia como elemento central contínuo (peças modulares alinhadas, passarelas de cada andar conectando nela).
4. **Superfície:** encosta rochosa com trilhos e passarelas descendo para a mina, guindastes (perfuração/ponte) como decoração, vila antiga integrada, árvores em densidade variada.
5. **Arte faltante (só o que o relatório provar necessário):** gerar com PixelLab seguindo o CONTRATO_ARTE (imagem-guia 2:1, estilo "Crisp 1px near-black outline"). **Piloto antes de lote:** primeiro 1 tileset isométrico (rocha com lava) + 2–3 cristais (~60 gerações), mostrar a Marco, só então o resto. Registrar o gasto de gerações.
6. Atualizar a tela Corte da mina para refletir o mesmo visual (cores por andar, rampa, escavadeira, criaturas).

## Fora de escopo
- Mudar gameplay, balanceamento, preços ou criaturas.
- Bloco 65 (crianças).
- Reabrir a decisão da Rota A.
- Pontes de corda/igreja/torre além do que já foi feito, salvo se o relatório apontar como lacuna visual importante.

## Checklist de teste
- [ ] Relatório com capturas e quadro comparativo referência × jogo entregue **antes** das mudanças.
- [ ] FPS da vila cheia e de cada andar medido antes/depois (não cair abaixo do medido, ideal subir para perto de 60).
- [ ] Cada andar S1–S5 tem atmosfera visivelmente própria e reconhecível frente à referência.
- [ ] Rampa em espiral lê como eixo central; passarelas ligam nela.
- [ ] Saves antigos carregam; GUT sem regressão (rodar a suíte em partes se faltar memória).
- [ ] Piloto de tiles aprovado por Marco antes de qualquer lote de arte; gerações gastas reportadas.
- [ ] Commit por etapa no branch `isometrico`.
