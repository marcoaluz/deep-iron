# Bloco 125 — Posto de troca e caravana (Prompt 13)

## O que entrou
- **Posto de troca** (`props/posto_troca.gd`, cena própria): obra do Centro (`OBRAS_107 "posto_troca"`, `troca_*` nos `@export`: 220 cr, 30 ferro, 100 madeira, 12 pregos, estágio 2, **um só por vila**), engenheiro ergue em 3 etapas. Arte do PixelLab: obra 1 → 2 → 3 → pronto (`assets/game/iso/predios/posto_troca/`), cartão do CONSTRUIR com imagem, desenho do posicionador. Clique abre a janela da caravana.
- **Caravana** (`caravana.gd`, nó "Caravana", `data/caravana/falas.txt` editável): a cada 14 dias (primeira a partir do dia 8) a comerciante **Cacilda** chega, fica 3 dias e parte. Sem posto pronto ela passa direto (avisa uma vez e tenta de novo no dia seguinte); a onda solar adia a chegada.
- **Comerciante visitante**: ipezinho `visitante` com `e_comerciante` (roupa/função própria "comerciante", só mulher), arte do PixelLab pela receita do elenco (caminhada, comer, ferido, deitar, mancar, **negociar** — toca ao negociar) e retrato com 5 expressões. Não é da vila (não come, não ocupa cama).
- **Negócio** (só por botão da janela — `caravana_panel.gd`): a vila COMPRA peças raras, pacotes de sementes (horta +50% por 10 dias, via `Modificadores "horta"` lido em `food_source.gd`) e carne defumada (+24 de comida crua); a caravana COMPRA barras e gemas, com teto de demanda por visita.
- **Preços**: base × margem (`margem_cobra` 1,3 / `margem_paga` 1,2) × estação (inverno encarece comida e sobe o metal) × situação do mercado sorteada na visita (escassez, carroça cheia, metal em alta, feira) × evento (`Modificadores "caravana_preco"`) × variação por item (±12%) × dificuldade (`preco_venda`: quem paga mais ao jogador cobra menos dele).
- **Encomendas**: 1 (2 a partir da 3ª visita) entram nos Pedidos da vila (F7) com o retrato dela: "vender N barras/gemas antes de eu partir"; cumprida = bônus em créditos; vence quando ela parte. Não contam pro teto de pedidos da vila.
- **Save**: chave `caravana` (documentada no cabeçalho do `save_manager.gd`), `postos_troca` no Centro, `item/vendido/bonus` nos pedidos. Save antigo = sem visita e sem posto.
- **Som** (ElevenLabs, 3 arquivos, ~52 créditos): `caravana/chegada`, `caravana/moedas` (2 variações).
- F3 → "caravana: chega/parte" (põe um posto se não houver).
- Teste `b125_caravana.gd` (A–I) com 0 falhas; `b123` ajustado (o tipo da encomenda não conta entre os 7 pedidos da vila).

## Arte (conferência em `docs/arte/bloco125/`)
Posto: guia + pronto (1 geração), obra 2 (1), obras 1/3 por corte. Comerciante: 16 candidatos (escolhido o c00), personagem v3, 7 animações em 2 direções, 5 retratos. A roupa/retrato usa o chapéu ocre e o casaco ferrugem; sem casaco de inverno próprio (ela só fica no posto).

## Não verificado / de fora
- Nada jogado nem ouvido: preços e frequência são palpite (tudo em `@export`); a margem de 1,2 sobre o preço normal de venda pode precisar de ajuste por telemetria.
- A comerciante anda até o posto pelo portão (usa o caminho dos migrantes); o portão fechado à noite não foi exercitado no teste.
- Casaco de inverno e ícone de função da comerciante não existem (ela não é função da barra).
- Ícones de sementes e carne reaproveitam `pq_hidroponia` e `comida`.
- `b111_familias` falha de vez em quando (escolhe uma mulher aleatória da vila de teste; independe deste bloco).
