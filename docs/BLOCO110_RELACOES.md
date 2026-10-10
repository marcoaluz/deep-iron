# Bloco 110 — Relacionamentos, traços e habilidades (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido: "Prompt R" (substitui o Prompt 9). O Marco autorizou executar sem esperar o plano
e decidiu: **só o balão de coração** (sem animação de abraço) e **o casal muda de casa sozinho** (se couber). Teste:
`tests/blocos/b110_relacoes.gd` (40 verificações). Medição: `tests/bench_relacoes.gd` (`docs/telemetria/bloco110/`). Fotos:
`docs/arte/bloco110/` (`tests/capturas_bloco110.gd`).

## 1) O que entrou

| Item | Como ficou | Onde |
|---|---|---|
| **Traços** | 1 ou 2 por pessoa, sorteados na primeira vez que alguém pergunta (ipezinho novo, migrante, **save antigo**), sem os que se contradizem: valente (não foge de criatura; o medo pesa menos), guloso (fome ×1,15; ração reduzida chateia mais), devoto (missa ×1,5; amizade na igreja), preguiçoso (produção ×0,92; a jornada estendida pesa ×1,5, a reduzida alegra ×1,5), trabalhador (×1,08; a estendida pesa ×0,5), cuidadoso (acidente ×0,7), sociável (pontos ×1,3), reservado (pontos ×0,7; +2 "gosta do sossego"). | `relacoes.gd TRACOS`, `ipezinho.tracos_de()` |
| **Habilidade por função** | Sobe trabalhando na função (a principal ou a secundária do Bloco 109), até 100%, e rende até +15% nela. A ficha mostra aprendiz/bom/mestre. O combate do guarda continua sendo o `combat_skill` (não duplica). | `ipezinho.habilidade`, `_pratica`, `_mult_pessoal` |
| **Relações** | Um par = uma entrada com pontos. Os pontos vêm da **conversa na roda da hora social** (×2 com festa ou festival, ×1,5 na igreja, ×1,5 mais com devoto) e de **trabalhar lado a lado**, e a **afinidade dos traços** multiplica (o mesmo traço ×1,2; opostos ×0,7). Níveis: conhecido (5) → amigo (30) → próximo (60) → interesse (80) → casal (100). **Interesse e casal só entre um homem e uma mulher adultos, os dois sem parceiro, um por vez** (dois homens ou duas mulheres param em "próximo"). | `relacoes.gd` |
| **Efeitos** | Amigos animam (+1 cada, até 4) e a conversa com amigo anima ×1,5; namorar/casado +3 e perto do parceiro +3; a roda do parceiro e dos amigos puxa na hora social (sentam juntos); o casal **muda pra mesma casa** sozinho (a cama livre mais perto da do parceiro; tenta de novo quando abrir cama). | `fatores_animo`, `ipezinho._nota_social`, `muda_pra_casa` |
| **Luto** | A morte de um amigo pesa −10 e a do parceiro −25 em quem ficou (some em ~15 min); o parceiro fica viúvo (sem namoro novo por 7 dias) e mostra o balão de **coração partido**. | `relacoes.morreu` |
| **Casamento** | Num domingo, na missa, com igreja e padre, o casal junto há 3 dias casa: a vila ganha +3 por um dia, os noivos +8 (some devagar), o diário ganha a página; se a tarde for de Festival, ele vira "Festa do casamento de A e B" (o sistema do Bloco 88). Sem igreja ou padre o casal existe sem casamento. | `_confere_casamento`, `calendario.nome_festival_hoje` |
| **Controle indireto** | O jogador não escolhe nada disso: influencia pelo ambiente (bancos, praças, festas, igreja, ânimo). | — |
| **Ficha do ipezinho** | Botão "Ficha" no cartão do selecionado: traços (com o que fazem), habilidades, amigos (com o nível) e parceiro (namorando/casados). | `ficha_panel.gd` |
| **Diário** | "O primeiro casal" e cada casamento. | `relacoes.marcos` (vão no save e são registrados de novo no diário) |
| **Políticas (Bloco 108)** | O `_reacao` das Políticas agora chama os traços: o mesmo efeito pesa diferente em cada um. | `politicas._reacao` → `relacoes.reacao_politica` |

## 2) Arte (PixelLab)

- **Coração** (balão do casal e do interesse) e **coração partido** (luto pelo parceiro): UM pedido `create_image_pro` 32×32 com
  os ícones do ânimo e do cozinheiro de referência (64 candidatos, **10 gerações**); escolhidos o c07 e o c13 do mesmo lote.
  Integrados pelo `oficios92.py icone_escolhe` (32 px + 24 px). Saldo: 5.723 → **5.713**.
- Sem animação de abraço (decisão do Marco).

## 3) Valores (`@export` em `relacoes.gd`, listados no `BALANCEAMENTO.md`)

Traços (chances e multiplicadores da seção 1), `habilidade_ganho` 0,0006/s e `habilidade_bonus` 0,15, `pontos_conversa` 1,5,
`mult_festa` 2, `mult_missa` 1,5, `pontos_trabalho` 0,3 a cada 5 s a até 70 px, `afinidade_igual` 1,2 / `afinidade_oposta` 0,7,
`limiares` 5/30/60/80/100, `puxa_parceiro/proximo/amigo` 25/8/4, `animo_por_amigo` 1 (até 4), `animo_casal` 3, `animo_juntos` 3,
`luto_amigo` 10, `luto_parceiro` 25, `luto_tempo` 900 s, `viuvez_dias` 7, `casamento_dias` 3, `casamento_animo` 3 por 540 s,
`casamento_noivos` 8.

## 4) Medição (telemetria)

Partida nova, 12 ipezinhos trabalhando, 8×, sem ondas nem invasão.

| | Dia 3 | Dia 7 | Dia 12 | Dia 14 | Maior habilidade |
|---|---|---|---|---|---|
| **1ª versão** (conversa 1,0; limiares 70/110/150) | 2 amizades | 13 | 27 amizades, **0 próximos** | — | 100% no dia 3 |
| **Ajustada** (conversa 1,5; 60/80/100; a roda puxa) | 3 amizades | 27 (2 próximos) | 48 (15 próximos, 6 interesses) | **52 amizades, 3 casais** | 77% no dia 14 |

- Os pontos se espalhavam por muitos pares (cada um troca de roda); por isso a roda passou a puxar quem tem gente querida nela:
  quem gosta se junta e o par forte acelera sozinho. O 1º casal sai **no 2º domingo** (dia 14) — a missa e o festival
  multiplicam. É o ritmo que o Prompt F (famílias) precisa.
- A habilidade chegava a 100% no 3º dia com 0,0015/s; com 0,0006 o melhor está em 77% no dia 14.
- O ânimo caiu do dia 8 em diante nas duas medições: era **fome** (2 caçadores pra 12), não as relações (o diagnóstico de cada
  dia está nos arquivos).
- Desempenho: o dia acelerado continua ~67 s reais. O ânimo (calculado a cada quadro) lê caches do parceiro e dos amigos —
  a 1ª versão percorria todos os pares a cada quadro (O(n²)) e foi trocada antes de medir.

## 5) Testes (um por vez, APPDATA isolado; o save real não mudou)

**Aprovados:** b110_relacoes (novo, 40/0), b84, b85, b88, b101, b103, b105, b106, b107, b108, b109, b86, b94, b36, b52, b95_layout_v2,
hud_frostpunk, p28_save.

**Ajustados (o assunto deles não é a personalidade):** b108 fixa traços neutros (os traços agora mudam a reação às políticas); o
b109 tinha uma conta frágil (o ipezinho sem função passeava entre duas medidas) e fixa a posição.

## 6) Pendências / pra o Marco validar

- Os números dos traços e o ritmo das relações (1º casal no dia ~14).
- Os traços de quem nascer (Prompt F) virão de um dos pais + 1 sorteado (o `sorteia_tracos` já fica pronto pra isso).
