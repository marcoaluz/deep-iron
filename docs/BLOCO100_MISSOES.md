# Bloco 100 — Sistema de missões e Capítulo 1 "Cinzas"

Data: 2026-10-08. Branch `isometrico`. Teste: `b100_missoes`.

**O pedido:** o "Prompt 3": o sistema de missões da seção 21 do guia e o Capítulo 1. Era o b97 do roteiro antigo; virou o
próximo número livre, o **b100**.

**Skills usadas:** `godot-gdscript`, `godot-gdscript-headless-testing`, `save-systems` (a chave "missoes" e a migração do save
antigo) e `godot-ui-control` (a janela e o rastreador).

## Como ficou

### Os dados (um recurso por missão, no padrão dos níveis da mina)
- `scripts/core/missao.gd`: o recurso, com `id`, `titulo`, `texto`, `capitulo`, `ordem`, `objetivos` ([tipo, alvo,
  quantidade]), `recompensa` e `prerequisitos`.
- `data/missoes/cap1_cinzas.tres`: a missão do Capítulo 1. **Missão nova = um `.tres` novo** em `data/missoes/`.
- **Os tipos de objetivo** que o gerenciador sabe medir (`missoes.gd` `valor_do_objetivo`, um `match`):

  | Tipo | O que mede |
  |---|---|
  | `fundar_vila` | a vila foi fundada |
  | `casas` | casas construídas |
  | `construcao` | prédios de um grupo do jogo (alvo = grupo; "comedouros" = a cozinha) |
  | `minerio_armazem` | minério guardado nos armazéns (alvo vazio = qualquer) |
  | `item` | itens processados no armazém |
  | `invasoes` | invasões que acabaram |
  | `estagio` | o estágio da vila |
  | `pesquisa` | uma pesquisa pronta |
  | `vendido` | minério vendido, no total |
  | `obras` | obras prontas de um tipo |
  | `mortes` | mortes na vila |

  Os 11 tipos cobrem os capítulos 2 a 6 da tabela 21.1 do guia; só o Capítulo 1 foi escrito agora.
- **Recompensa:** créditos, página do diário, itens e "libera o capítulo N". A página do diário nova e o texto dela vêm do
  arquivo do capítulo (o `diary.gd` ganhou `registra()` e `entrada()` pra páginas de fora do código).

### Os textos: um arquivo por capítulo, fácil de editar
`data/missoes/capitulo_1.txt`. O formato é simples e está explicado no cabeçalho do arquivo:
- `[secao]` abre uma seção (o nome é o id da missão);
- `chave = valor`, com as linhas seguintes (sem "chave =") continuando o texto;
- `#` é comentário;
- `{n}` no texto de um objetivo vira a quantidade ("Construir {n} casas" → "Construir 3 casas");
- quando precisa de mais de 1, o jogo acrescenta sozinho o "(tem/precisa)".

Lá estão o título, o subtítulo ("Acampamento") e a introdução do capítulo, o texto da missão, o texto de cada objetivo, a
recompensa e a página do diário. **Mudar uma frase no arquivo muda o jogo**, sem tocar em código nem no `.tres`. Se o
arquivo faltar, valem os textos do `.tres`.

### O gerenciador (`missoes.gd`, nó "Missoes" na cena, grupo "missoes")
- **Escuta os sinais que o jogo já tem:**
  - minério vendido (`economy.ore_sold`);
  - pesquisa pronta (`research.researched`);
  - fim de invasão (`defense.invasion_ended`);
  - morte (`ipezinho.died`, ligado em cada ipezinho que nasce);
  - estágio novo (`centro_vila.level_changed`).
- **Sinal novo, que só avisa:** `centro_vila.obra_pronta(tipo)`, emitido quando um canteiro termina e quando uma casa fica
  pronta. Ele não muda o comportamento de ninguém.
- **Confere os contadores a cada segundo** (`confere_a_cada`, `@export`). Objetivo cumprido **fica cumprido**: vender o minério
  depois não desfaz.
- **Cumpriu tudo:** entrega a recompensa uma vez só, mostra o banner "MISSÃO CUMPRIDA" e libera o capítulo seguinte.
- **Avisos:** cada objetivo cumprido mostra um aviso curto, e a página do diário nova também.

### A interface
- **Janela "Missões"** (`missoes_panel.gd`), com **tecla própria: vírgula** (remapeável em Configurações) e o botão da aba fina
  da esquerda, que antes dizia "em breve" e agora funciona. Mostra o capítulo, a introdução, a missão com os objetivos
  (caixinha e andamento), a recompensa, as cumpridas e o que vem. O menu "Janelas" mostra o andamento ("Missões 4/5").
- **Rastreador do canto direito** (o espaço que o layout v2 reservou, `ui/rastreador_missoes.gd`): o capítulo e até 3
  objetivos, os que faltam primeiro. Sem missão valendo, ele some.
- Fotos: `docs/arte/bloco100/` (rastreador no jogo, janela com o andamento, missão cumprida e o aviso do Capítulo 2).

### Capítulo 1 "Cinzas"
| Objetivo | Como é medido |
|---|---|
| Fundar a vila | a vila foi fundada |
| Construir 3 casas | 3 casas prontas |
| Construir a cozinha | uma cozinha pronta |
| 100 de minério no armazém | 100 de minério guardado |
| Sobreviver à primeira invasão | o fim da primeira invasão |

**Recompensa:** 150 créditos, a página do diário "Cap. 1 — Cinzas" e a liberação do Capítulo 2. Como o Capítulo 2 ainda não
foi escrito, a janela mostra "Capítulo 2 — Fogo e ferro: em breve" (o texto está no mesmo arquivo).

Separei "3 casas e a cozinha" em dois objetivos pra cada um se marcar sozinho.

### Save
- Chave **`missoes`**: `capitulo_liberado`, `cumpridas`, `feitos` (os objetivos cumpridos de cada missão) e `contadores`
  (invasões, minério vendido, mortes, obras). Documentada no cabeçalho do `save_manager.gd`.
- **Save antigo (sem a chave) começa no capítulo certo, conferindo o que já foi feito:** refaz os contadores a partir do
  estado (as invasões que já passaram, as mortes do memorial) e confere tudo.
  - Vila que já tinha cumprido o capítulo 1: entrega a recompensa uma vez, libera o capítulo 2 e avisa numa linha só ("já
    estavam cumpridas").
  - Vila que tinha feito só uma parte: continua no capítulo 1, com o que já estava feito marcado.
- Chaves ruins ou de missão que não existe mais são ignoradas, sem erro.

## Testes

- **`b100_missoes`** (novo, **0 falhas**). Confere:
  - os dados e o formato do arquivo de texto (inclusive que mudar o texto no arquivo muda o jogo);
  - o nó, a janela, a tecla, o botão da aba e o rastreador com 3 objetivos;
  - o capítulo 1 objetivo por objetivo, com o andamento "(2/3)", o objetivo que continua cumprido depois de vender, a
    recompensa uma vez só e o capítulo 2 liberado;
  - os sinais de morte, venda e obra pronta;
  - o save (os dados, chaves ruins e pelo SaveManager de verdade);
  - o save antigo nos dois casos (já cumprido e só uma parte).
- **Testes antigos ajustados:** `b95_layout_v2` reservava o rastreador de missões "escondido" porque ainda não havia missões; agora
  ele confere que o espaço de 240 px existe e que só aparece com missão valendo.
- **Bateria completa**, um por vez, em primeiro plano, com a pasta `fake_appdata`:
  - passaram os 84 testes de bloco (b25 → b100, b51 incluído), `hud_frostpunk`, `manut_backups`, `p17`–`p20`, `p28_*`, `p29_*` e
    `p2_pendencias`;
  - passaram os GUT `test_iso` (6), `test_iso_arte` (3) e `test_iso_pele` (3).
- **Intermitentes** (falharam uma vez na bateria e passaram ao repetir): `b58_oficina_construivel` (timeout), `b85_hora_social`
  (as rodas de conversa) e `b25_funcoes` (um acidente aleatório do ipezinho do teste).
