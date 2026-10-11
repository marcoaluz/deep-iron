---
name: balanceamento
description: Regras pra mexer em números do jogo DEEP IRON (economia, defesa, fome, produção, dificuldade, eventos, preços). Use ao criar um valor novo, ao ajustar um existente, ao pedir "balanceia isso", ao ler telemetria ou ao mexer nos perfis de dificuldade e nas Políticas. Diz onde ficam os dados, a regra de que balanceamento é @export com comentário, como medir pela telemetria e o que nunca mudar sem o Marco.
---

# Balanceamento (DEEP IRON)

## Regras

1. **Todo número de balanceamento é `@export` com comentário** (o que é e a unidade) — nunca número mágico no meio da lógica. Agrupe com `@export_group`.
2. **Mudar um valor existente é decisão do Marco.** Valor novo entra com um padrão conservador, documentado. Explique no relatório do bloco o que mudou e por quê.
3. **O Normal não muda sem dados.** O perfil `data/dificuldade/normal.tres` tem que bater com os `@export` (o `b113_dificuldade` confere); mudou o balanceamento de lá, mude o `normal.tres` junto. Tranquilo/Ferro/Criativo são multiplicadores sobre o Normal.
4. **Efeito de regra entra pelo `Modificadores`** (`Modificadores.mult(get_tree(), "producao", ipezinho)`: chaves `producao`, `acidente`, `porcao`, `fome_refeicao`, `migracao_intervalo`, `treino`, `roubo`, `preco_venda`, `fome`) — um nó no grupo "modificadores" com `mult(chave, quem)`. Política, dificuldade, evento e traço entram aí, sempre multiplicando.
5. **Ânimo**: um fator de ânimo entra por `morale.village_factors()` / `relacoes.fatores_animo(w)` (com o teto da penalidade nas Políticas), não somando direto no `happiness`.
6. **Dinheiro e itens**: `Economy.spend/paga_metal/paga_itens`, `ganha_creditos`, `add_item/take_item`; nunca mexer em `credits` à mão fora de teste. Nada compra, vende ou produz sozinho: tudo por ação do jogador (produção só por ordem).
7. **Injustiça**: nada que mata sem aviso nem sem defesa possível. Criatura nova tem regra de aparição própria, defesa possível e vem com telemetria; evento tem opção de custo zero e a pior consequência não mata direto (machuca; o jogador tem tempo de reagir).

## Onde ficam os dados

- `@export` nos scripts de `scripts/core`, `scripts/props`, `scripts/workers`, `scripts/creatures`; a cena (`scenes/game/main.tscn`, cenas dos prédios) pode trocar o padrão (vale o da cena).
- **A lista de tudo**: `python tools/lista_balanceamento.py` → `docs/BALANCEAMENTO.md` (valor, padrão, onde a cena troca). Rode depois de criar valores.
- Dados em arquivo: `data/dificuldade/*.tres`, `data/niveis/*.tres`, `data/missoes/*.tres`, `data/expedicoes/regioes.json`, `data/eventos/eventos.json`, `data/pedidos/pedidos.json`, `data/catalogo/entradas.json`, `data/audio/slots.json`.

## Como medir

- **Telemetria**: o jogo grava CSV em `user://telemetria/` (`telemetria.gd`); `python tools/resumo_telemetria.py <csv ou pasta>` mostra curva de créditos e minério, dias sem lucro, picos de morte, ânimo, invasões e greves. Os resumos dos blocos ficam em `docs/telemetria/blocoNN/` — **leia antes de mexer**.
- **F3** (build de editor): "Pular dia", "Dar", "Andares: abrir todos", "Criaturas: invasão com todos os tipos", "Vila: evento agora / pedido novo", "Liberar pesquisas".
- Teste do bloco com o estado posto à mão (créditos, camas, mineradores) e a conferência do número exato (`is_equal_approx`), no padrão dos `bNN_*.gd`.
- Simulação longa não existe pronta: se um prompt pedir "balancear pelos dados", cite a telemetria usada e diga **o que não foi simulado**.

## Ao entregar

Relatório do bloco com: os valores novos e o padrão, a lista do que foi medido (e como), o que ficou como palpite e como o Marco ajusta (nome do `@export`). Atualize `docs/BALANCEAMENTO.md`.
