# Prompt 11: alimentação, saúde e lazer

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/{taverna,enfermaria,cozinha,parque}/`
e `vegetacao/final/horta_*`. Nada integrado ao jogo.

## Conferido no menu de construção (abas Alimentação, Saúde, Lazer)

Cozinha (no jogo "Comedouro"), Taverna + Ampliar taverna, Enfermaria (nova) + Ampliar
Enfermaria, Parque. A horta é da clareira (Prompt 9).

## O que ficou pronto

| Prédio | Estágios | Caixa (pegada × altura) |
|---|---|---|
| **Taverna** | obra 1–3 → pronto (placa de caneca, mesas e bancos na frente, lampião, barris) → **ampliada**: 2º andar com varanda, telhado maior, jardim coberto do lado | 174×146×200 |
| **Enfermaria** | obra 1–3 → pronto (**cruz vermelha** bem legível, toldo com macas, barril, ervas) → **ampliada**: 2º andar (enfermaria em cima), outra cruz no oitão, anexo de tábua com mais macas | 134×100×166 |
| **Cozinha** (antes "Comedouro") | obra 1–3 → pronto (fogão de pedra, caldeirão, balcão, mesas compridas) + **vazia / com comida** (cestos de cogumelo e caixotes; sobreposição) | 136×112×154 |
| **Parque** | obra 1–3 → coreto de madeira no centro (degraus de pedra, telhado de ardósia, cata-vento), canteiro de flores, 2 bancos, lampião. O resto do parque se monta com as árvores e a vegetação do Prompt 9 | 100×90×144 |
| **Estruturas da horta** | cerca (reta, canto, portãozinho), espantalho, galpão de ferramentas, carrinho de mão, cocho, caixotes, regador, pá, mangueira, cesto de cogumelos, **estufa** (serve pra hidroponia) | — |

Todos cabem na caixa declarada (≤ 4 px fora).

## Técnica nova (economia)

**Só a obra 2 (esqueleto) vem da IA.** As obras 1 e 3 saem por script (`arte_iso/obras.py`):

- obra 1 = a faixa de baixo do esqueleto (fundação e primeira fiada) + o material que a IA pôs
  no chão;
- obra 3 = o pronto até ~62% da altura + o esqueleto por cima (telhado ainda em caibros).

A linha de corte acompanha a base 2:1 do prédio. Economia: ~50 gerações por prédio.

## Entregas (nesta pasta)

`prancha_<prédio>.png` + `obra_<prédio>.gif` (taverna, enfermaria, cozinha, parque),
`taverna_ampliacao.png`, `enfermaria_ampliacao.png`, `cozinha_estados.png`,
`horta_estruturas.png`.

## Custo

**~290 gerações.**

## Desvios

1. **Nome "Comedouro" → "Cozinha"** (pedido do Marco). Na arte já está trocado (pasta
   `cozinha/`). No jogo, trocar menu, textos e cena na integração.
2. **A obra das ampliações** (taverna e enfermaria nível 2) não tem estágios próprios. A
   sugestão pra integração é mostrar o andaime da obra 3 por cima do nível 1 enquanto amplia.
3. **Vazou uma linha laranja da guia** na borda do piso da cozinha. Troquei por marrom escuro
   por script.
4. **Obra 1 do script** às vezes deixa 1–2 pixels soltos de viga no alto; no jogo não
   aparecem.
