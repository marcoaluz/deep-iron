# Bloco 123 — Pedidos da vila e eventos com escolha (relatório)

Data: 2026-10-11. Branch `isometrico`. Pedido: Prompt 11 (seção 21 do guia): (1) **pedidos da vila** — desejos de ipezinhos com nome e retrato que aparecem no diário e dão ânimo ou recompensa; (2) **eventos com escolha**, estilo Frostpunk — cartão com uma das ilustrações existentes e 2 ou 3 opções com custo e consequência.
Teste: `tests/blocos/b123_pedidos_eventos.gd`, **0 falhas**, registrado no GUT. Nada foi jogado de verdade (só o teste).

## 1) Pedidos da vila (`pedidos.gd`, nó "Pedidos"; dados em `data/pedidos/pedidos.json`; janela **F7**)

Um desejo de um ipezinho **adulto, com nome e retrato**, com **prazo** (dias de jogo) e **recompensa**; no máximo `max_abertos` (3) ao mesmo tempo, um novo a cada 2 a 4 dias a partir do dia 3, sem repetir o tipo nem o autor entre os abertos.
O sorteio **só pede o que faz sentido naquele momento** (`_pode`). Pedido que vence só some (e fica no diário). Cumprir toca o aviso, registra uma página no diário e entrega a recompensa.

| Pedido | Só aparece quando... | Cumpre quando... | Recompensa |
|---|---|---|---|
| **Um banco perto de casa** | quem pede tem casa e não há banco por perto | um banco a até 110 px da casa dele | ânimo +15 só pra ele por 2 dias |
| **Ninguém passando fome** | há cozinha | 3 dias seguidos sem ninguém com fome braba (< 25% da fome) | o próximo festival sai **de graça** |
| **Casaco para todos antes do inverno** | verão ou outono e há Oficina | todos os adultos de casaco (vence quando o inverno começa) | o inverno deste ano **sem o -3 de ânimo** |
| **Enterrar com dignidade** | já morreu alguém e falta cemitério ou os Ritos | cemitério + pesquisa Ritos fúnebres | ânimo +6 pra vila por 3 dias |
| **3 guardas com 100% de treino** | campo de treino e 3 guardas | 3 guardas com habilidade >= 99% | uma **besta** de graça no cavalete |
| **Caminho de pedra até a mina** | a ferramenta dos caminhos e a vila | 25 trechos de pedra pintados | ânimo +8 dos **mineradores** por 3 dias |
| **Festival das Lanternas** | calendário e decoração | 5 lampiões a até 170 px da praça | o próximo festival **rende o dobro** |

A janela **Pedidos (F7)** mostra cada pedido aberto com o **retrato** (o da função e do tom dele), o nome, o texto, o andamento (2/3), o prazo e a recompensa, mais os últimos encerrados.
Tudo é `@export` do nó (`max_abertos`, `intervalo_dias_min/max`, `primeiro_dia`, `adultos_minimo`, `banco_raio`, `fome_braba`, `treino_cheio`, `lanternas_raio`, `inverno_ameno_cancela`).
O ânimo entra pelos pontos de sempre: `morale.village_factors()` (vila toda) e `relacoes.fatores_animo(w)` (uma pessoa ou uma função); o festival de graça/em dobro é lido pelo `morale.throw_festa`.

## 2) Eventos com escolha (`eventos.gd`, nó "Eventos"; dados em `data/eventos/eventos.json`; cartão `ui/evento_cartao.gd`)

O cartão **pausa o jogo**, mostra uma das 10 ilustrações que já existem, o texto e **2 ou 3 opções**, cada uma com **custo** (créditos, comida, madeira) e **consequência** escritos embaixo; a opção que a vila não paga fica desabilitada e diz o que falta; as teclas **1, 2 e 3** escolhem.
O jogador sempre decide (não dá pra fechar sem escolher). A escolha vira uma página no diário.

| Evento | Ilustração | Opções (custo -> consequência) |
|---|---|---|
| **Refugiados no portão** (vem com >= 2 camas livres) | expulso_derrota | abrigar 4 (30 comida: entram os que couberem, ânimo +3) · abrigar 2 (10 comida) · fechar o portão (ânimo -4 por 2 dias) |
| **Tempestade de poeira** | onda_solar | parar tudo (produção x0,4 por 1 dia) · lonas (120 cr + 20 madeira: x0,8) · trabalhar assim (acidentes x2 e 1 machucado) |
| **Desabamento numa galeria** (>= 3 mineradores) | acidente_mina | resgate com tudo (150 cr + 30 madeira: 1 machucado leve) · resgate rápido (2 machucados graves) · selar (3 graves e ânimo -6 por 3 dias) |
| **Febre na vila** (>= 8 pessoas) | greve | tratar todos (180 cr) · isolar (60 cr + 20 comida: 2 de cama, produção x0,9 por 2 dias) · esperar (5 de cama, ânimo -6) |
| **Casamento pedido** (um casal + igreja + padre) | festa | festa (80 cr + 30 comida: casa + ânimo +10 por 2 dias) · cerimônia simples (casa, ânimo +3) · esperar o domingo (ânimo -2) |
| **Mapa antigo** (região escondida e estágio 2) | reator_achado | marcar o lugar (100 cr: revela a região) · vender (+120 cr) · guardar no diário (ânimo +3) |

**Frequência e peso nos `@export`:** `primeiro_dia` (4), `intervalo_dias_min/max` (3 a 7), `cooldown_dias` (8), `pesos` por evento, `ligado`, `pausa_no_cartao` e as condições (`refugiados_camas_min`, `desabamento_mineradores_min`, `febre_populacao_min`, `mapa_estagio_min`).
**Nunca o mesmo evento em sequência** (e cooldown por evento). Não abre cartão com invasão em andamento, onda solar, greve ou vitória. Efeitos que duram (produção/acidente e ânimo) valem por dias de jogo: o nó está no grupo "modificadores" (`mult`) e dá `fatores_animo()` ao moral.
Nenhuma opção mata direto: o pior resultado machuca (o jogador tem a enfermaria e tempo de reagir).

## 3) Save, F3 e testes

- **Save:** `pedidos` {abertos, histórico, próximo dia, dias sem fome, festival guardado, inverno ameno, efeitos} e `eventos` {próximo dia, último, histórico, efeitos que duram}; save antigo carrega vazio; chave ruim é ignorada (cabeçalho do `save_manager.gd`). As páginas do diário voltam do histórico.
- **F3:** nova linha "Vila:" com **evento agora** (o próximo que faz sentido, ou qualquer um forçado) e **pedido novo**.
- **Teste (`b123_pedidos_eventos`):** os dados e os `@export`; cada pedido (condição, andamento e recompensa: festival de graça que não gasta nada, ânimo só pra quem pediu, inverno ameno, besta no cavalete, ânimo dos mineradores, festival em dobro); limite de abertos, sem repetir tipo nem autor, prazo e vencimento; o cartão (pausa, 3 opções, não abre outro por cima, opção sem dinheiro desabilitada);
  os 6 eventos com custo e consequência conferidos; produção/acidente pelo `Modificadores`; o fator de ânimo no `village_factors`; sem repetir em sequência e o intervalo (30 sorteios); a janela F7; o save. Vizinhos (um por vez): b103, b108, b110, b111, b47, b93, b88, p28_save, hud_frostpunk, b95, b54 — 0 falhas; save real conferido por md5.

## 4) O que NÃO foi verificado

- **Nada foi jogado**: o equilíbrio das recompensas e dos custos é palpite (todos nos dados e `@export`: ajuste depois de ver a telemetria de partidas com eventos). Nenhum balanceamento por telemetria nova: não havia dado de eventos.
- O cartão e a janela F7 foram testados por código, não vistos na tela (a fonte e o layout usam o tema do jogo; a ilustração fica a 2x como na vitória).
- A ilustração da **febre** é a da greve (as 10 que existem não têm uma de doença); se quiser, gero uma nova no PixelLab. A do **mapa antigo** é a do reator achado.
- O pedido **"Vender 20 barras para a caravana"** do guia fica pro bloco da caravana (Prompt 13).
