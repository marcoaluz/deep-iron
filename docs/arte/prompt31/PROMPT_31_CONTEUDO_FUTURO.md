# Prompt 31: conteúdo futuro (verificação) + prompts que ficaram sem fazer

Data: 2026-10-01. Branch `isometrico`. **Sem geração** (saldo **1.359**, recarga de +5.000 em
2026-10-30).

O Prompt 31 manda: *"Usar só quando o sistema de gameplay correspondente existir (ou for
começar), pra não gerar arte que ninguém usa."* Então o trabalho foi conferir cada item do
backlog contra o jogo de hoje.

## Backlog do Prompt 31 × jogo de hoje

| Item | Gameplay hoje | Arte | Decisão | Quando aplicar |
|---|---|---|---|---|
| **Escola** (com obra) | só o cartão **"em breve"** no menu de construção ("Pra quando a vila tiver crianças.") | não existe | **não gerar** | quando a escola/crianças entrarem no gameplay. ~100 gerações (obra 1–3 + pronto) |
| **Crianças** (menino/menina, 3 peles, 4 direções, andar, brincar, estudar) | não existem | não existe | **não gerar** | junto com a escola. ~100 (base + rotações + 3 animações; peles por paleta, sem custo) |
| **Casa nível 2/3** | cartão "em breve" (a casa não tem nível) | **já gerada** (`casa/nivel_2.png`, `nivel_3.png`, guardada em `assets/game/iso/predios/casa/`) | nada a fazer | quando houver nível de casa: falta a **obra entre os níveis** (andaime sobre a casa, regra do contrato), ~25 por nível |
| **Coletor de minério** | cartão "em breve" | **já gerado** (só o pronto) | nada a fazer | quando entrar no jogo: faltam **obra 1–3** (~25, obra barata do Prompt 11) |
| **Oficina construível** | fixa na cena (não se constrói) | a arte já tem obra 1–3 + pronto | nada a fazer | se sair do fixo: só integrar (os desenhos de obra existem) |
| Reatores de nível mais alto | o jogo tem 5 (vapor, diesel, cristal, solar, fusão) | os 5 existem | nada a fazer | quando houver reator novo |
| Picaretas/armas de nível mais alto | picareta, picareta de aço; porrete, lança, besta, lança de prata | todas existem (Prompt 4) | nada a fazer | quando houver arma/ferramenta nova |
| Trajes novos | gás, calor, radiação (vestiário); o "traje de chumbo" da Oficina é um desbloqueio, não roupa vestida | os 3 existem | nada a fazer | quando houver traje novo vestido |
| Criaturas das fases mais fundas | o jogo tem lumívoro e ferrugento | **nem esses têm arte nova** (Prompts 16–17) | primeiro os Prompts 16–17 | criaturas novas só com gameplay novo |
| Eventos e ilustrações novas | os eventos de hoje (achado, onda solar, invasão, greve, morte, marco da vila) | sem ilustração (Prompt 24) | é o Prompt 24 | — |

**Mapa:** a análise do Prompt 29 (cabem 31 casas a mais; o jogo pede no máximo 7) continua
valendo. Se a escola entrar, rodar `tests/analise_capacidade.gd` de novo com ela.

**Resultado do Prompt 31 hoje: nada a gerar.** Nenhum item do backlog tem gameplay; os que já
tinham arte (casa nível 2/3, coletor de minério) estão guardados.

## Prompts que ficaram sem fazer

Feitos: 0–15, 27, 28, 29 (partes 1–6), 30 e este 31 (verificação). **Sem fazer: 16 a 26.**

| Prompt | O quê | Checkpoint teu? | Dá pra adiantar sem gerar? | Gerações (estimativa do inventário) |
|---|---|---|---|---|
| 16 | Criaturas: **conceito** (lumívoro, ferrugento, mais fortes, criatura mestre) | **sim** (mostrar propostas antes de gerar personagem) | as propostas/roteiro | ~0–20 (rascunhos) |
| 17 | Criaturas: produção (4 direções, andar, atacar, morrer sóbrio) | não | — | ~190 |
| 18 | Efeitos e clima (poeira de obra, faíscas, fumaça, explosão, brilho da onda solar; partículas de clima novas) | não | o clima já aparece na vista iso (partículas antigas, Prompt 30) | ~30–40 |
| 19 | Luz e noite (ponto de luz por prédio, janelas acesas a partir da arte) | não | **quase todo: é código** (as luzes hoje vão pra proporção do desenho novo, não pro ponto certo da janela/forja/cabine) | ~0 |
| 20 | Interface: sistema visual (painel 9-slice, botões, chips, abas, cursor, menus) | **sim** (mockup antes de gerar o resto) | o mockup | ~50 |
| 21 | Ícones (recursos, status, pesquisa, itens; chapéu de cozinheiro) | não | parte sai da arte já gerada, reduzida | ~100 (menos com reaproveitamento) |
| 22 | Fonte pixel | **sim** (amostra antes de trocar) | — | ~30 |
| 23 | Retratos do elenco (18, 3 peles) + criaturas | não | — | ~200 |
| 24 | Ilustrações de eventos e achados | não | — | ~200 |
| 25 | Tela "Corte da mina" | **sim** (layout antes da arte) | o passo 1 (layout, sem arte) | a estimar no passo 1 |
| 26 | Título, logo, splash, loading, vitória/derrota | **sim** (2–3 propostas de key art) | — | ~160 |

**Pendências pequenas dentro de prompts já feitos** (status "falta" no inventário):

| Prompt | Item | Gerações |
|---|---|---|
| 2 | Colher fruta (caçador sem arco), treinar no campo, placa de greve na mão | ~30 |
| 14 | Cesto de coleta, placa de greve (sobreposição); cova; explosivos e antena do rádio (pesquisa) | ~80 |
| 29 | Arma trocada na mão no ataque (hoje o guarda ataca com o porrete do desenho, qualquer que seja a arma) | 0–48 |

**Soma:** ~1.100–1.200 gerações pros Prompts 16–26 + as pendências. Cabe no saldo de 1.359 com
pouca folga pra refazer; com a recarga de 30/10 (+5.000) fica tranquilo.

## Ordem sugerida

1. **Sem gastar geração, já:** Prompt 19 (luz por código), os passos de rascunho dos checkpoints
   16 (conceito), 20 (mockup) e 25 (layout).
2. **Com o saldo de agora:** 16→17 (criaturas: é o que mais destoa no jogo, ainda com o desenho
   antigo) e 18 (efeitos).
3. **Depois da recarga de 30/10:** 20–22 (interface, ícones, fonte), 23–24 (retratos,
   ilustrações), 25–26 (telas) e as pendências pequenas.
4. **Prompt 31 de novo** quando a escola/crianças (ou outro item do backlog) entrar no gameplay.

## Mudanças

- `docs/arte/prompt31/PROMPT_31_CONTEUDO_FUTURO.md` (este), `docs/arte/INVENTARIO.md`
  (atualização), `CONTEXTO.md`.
- Nenhum código mudou; nenhum teste a rodar.
