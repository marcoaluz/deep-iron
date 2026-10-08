# Bloco 98 — Portão da paliçada (abre e fecha) e tochas

Data: 2026-10-07. Branch `isometrico`. Teste: `b98_portao_tochas`.

**O pedido:** o "Prompt P" (portão e tochas). Duas correções:
1. O portão parecia fora da cerca e o pessoal andava ao lado da cerca em vez de passar pelo portão. Ele agora tem de abrir de
   dia e fechar ao anoitecer, com animação.
2. A tocha mudava de desenho entre dia e noite. Tem de ser o mesmo desenho sempre.

**Pedido extra do Marco, durante o trabalho:** o portão de **nível 3** aparecia de lado no jogo, diferente dos níveis 1 e 2.
Corrigido (abaixo).

**Skills usadas:** `godot-gdscript`, `godot-gdscript-headless-testing`, `ai-behavior-trees-utility-ai` (quem espera o portão),
`deep-iron-arte` (as folhas abertas).

## A causa (medida antes de corrigir)

Capturas em `docs/arte/bloco98/antes/` (com a marcação do vão lógico em vermelho e da linha da paliçada em amarelo).

| O que medi | Antes |
|---|---|
| Vão lógico (navegação) | y de -80 a 0 (80 px) |
| Vão da cerca desenhada | y de -94 a +5 (99 px, centro em -44,5): as peças saíam de uma grade que não sabia onde o portão acabava |
| Caixa do desenho do portão | y de -72 a -4 (68 px, centro em -38) |
| Desenho do portão | **sempre fechado** (nivel_1/2/3) ou uma **ruína que cobre o vão inteiro** (nível 0 / derrubado): nunca mostrava uma passagem |
| Caminhos de 300 pontos aleatórios | 277 chegam, **todos pelo vão**, mas cruzando em y = -73 ou -7, as pontas do vão, **colados na ponta da cerca** |

O que isso explica:
1. **A navegação estava certa.** A paliçada já bloqueava a extensão toda; o vão era o único caminho.
2. **O vão desenhado não batia com nada.** Havia 14 px de fresta à esquerda do portão, 5 à direita, e o desenho do portão era
   mais estreito que o vão lógico. O portão parecia solto da cerca.
3. **O caminho mais curto roça a ponta do vão** (o funil da malha), então o pessoal passava rente à cerca, ao lado do desenho
   do portão, que parecia um muro fechado.
4. **Nível 3: a arte estava espelhada.** `nivel_3.png` foi desenhado correndo no sentido contrário ao dos níveis 1 e 2. O espelho
   que o jogo aplica (a paliçada corre de norte a sul) deixava o arco de pedra atravessado na cerca. Era um erro de antes do
   Bloco 98, que passou a aparecer agora porque as folhas abertas deram um desenho novo pra olhar.

## O que foi feito

### (a) O desenho alinhado ao vão e à paliçada
- `gate_half_width` passou de 40 para **34**: é a meia largura do desenho do portão. Agora o vão lógico, a caixa do desenho e
  o espaço da cerca são a mesma largura (68 px).
- A paliçada de norte a sul é montada **a partir do portão pra fora** (`iso_view.gd` `_build_palisade`), contando da borda da
  caixa da peça que encosta nele. Medido: a cerca termina em -74,0 e começa em -6,0, e o portão acaba em -74 e -6.
  A peça "danificada" nunca fica colada no portão.
- **Nível 3:** os desenhos `nivel_3`, `meio_3` e `aberto_3` foram espelhados (assets e a origem `muro/final/portao_i_nivel_3.png`)
  e a caixa no `predios.json` ajustada. O teste confere que os 3 níveis, nas 3 posições da folha, correm no mesmo sentido.

### (b) A paliçada inteira bloqueia
A malha agora leva **a paliçada inteira, sem vão** (`environment.gd` `_iso_blockers`, `portao_por_faixas()`); sem a barricada
na cena (cenas de teste) o vão continua aberto como antes.

### (c) O único caminho é o portão, pelas faixas
O portão tem **3 faixas de passagem** (`NavigationLink2D`, `barricada.gd`), de 14 em 14 px, no centro do vão. Os caminhos
cruzam sempre por elas, no meio, e não mais pelas pontas.

O teste usa 120 caminhos aleatórios floresta → vila e 36 de volta: todos cruzam em `gate_y ± gate_half_width` (na prática
em ±14). Pontos colados na cerca, longe do portão, vão até ele e passam.

### Abrir e fechar
Todos os valores são `@export` com comentário no `barricada.gd` (grupo "Abrir e fechar").

| Regra | Padrão |
|---|---|
| Fecha | **18:30** (`hora_fecha`; o expediente acaba às 18:00 e "voltar" dura até 18:30) |
| Abre | **05:00** (`hora_abre`, o amanhecer) |
| Animação | 1,2 s: `nivel_N` (fechado) → `meio_N` → `aberto_N` |
| Fechado | desliga as 3 faixas: **sem refazer a malha** |
| Derrubado, sem muro (nível 0), ou brecha (guarda caído) | **sempre aberto**; a vida, o dano, o conserto e a ampliação seguem iguais |
| Não fecha em cima de quem está passando | espera sair do vão |
| Carregou o save de noite | já nasce fechado, sem animar |

### Quem está fora na hora de fechar (a regra proposta)
- O portão só fecha **depois da hora de voltar** (18:30). Quem ficou fora **espera encostado no portão**, do lado dele (e
  não ao longo da cerca, que seria o ponto mais perto do destino).
- Um **guarda abre** pra quem da vila espera: 3 s depois de alguém chegar. A janela fica 10 s.
- **Sem guarda** vivo na vila, alguém ouve a batida e abre depois de **20 s**.
- **Criatura a menos de 150 px do portão: não abre pra ninguém.** Migrantes (Prompt M) não existem ainda: quando
  existirem, é só não contá-los como "da vila".
- Turno extra, caçador e lenhador atrasados entram nessa mesma regra (esperam, o guarda abre). Quem quer SAIR de noite
  também espera.
- Aviso: "Um guarda abriu o portão pra Fulano." (toast).

Como funciona por dentro: o `ipezinho._go_to` desvia o destino pro ponto de espera quando o portão está fechado e o destino é
do outro lado, e o Barricada avisa todo mundo (`portao_mudou`) quando abre ou fecha.

## Arte (PixelLab)

- `portao98/portao98.py`: as folhas **abertas** (`aberto_1/2/3`), **a meio caminho** (`meio_1/2/3`) e a **ruína com o vão aberto**
  (`quebrado_aberto`, nível 0 ou derrubado), a partir do portão fechado aprovado de cada nível (`create_image_pro` com o
  desenho como referência e como estilo, quadro 126×198, mesma âncora).
- **Custo: 340 gerações** (17 pedidos de 20; escolhi 7, o resto foram refações do nível 1 e da ruína). Saldo: 6.887 → **6.547**.
- Escolhidos: `aberto_1d`, `meio_1c`, `aberto_2`, `meio_2`, `aberto_3`, `meio_3`, `quebrado_abertob`. Os outros ficam fora
  do repositório (`_cand/`).
- O desenho antigo `quebrado` continua no repositório, sem uso.
- Conferência: `docs/arte/bloco98/portao_estados.png` e as fotos em `docs/arte/bloco98/depois/`.

## (2) Tochas: um desenho só

**Onde a troca acontecia:**
1. `iso_art.gd` (tocha sorteada do mapa): chama animada se a chama desenhada estava visível, senão `tocha_apagada`.
2. `decoracao.gd` `iso_prop_nome()` (tocha do jogador): `tocha_apagada` quando a luz estava desligada (de dia, ou comida por
   um Lumívoro).
3. `environment.gd`: a chama desenhada da tocha do mapa apagava junto com a luz (`flame.modulate.a`), e era isso que o
   item 1 lia.

**Agora:** só a chama animada (`tocha_chao`), de dia, de noite e mesmo com a luz comida pelo Lumívoro. Só a **luz**
(`PointLight2D`, pelo `torch_level` do DayNight) liga à noite e desliga de dia. Vale para as sorteadas, as do jogador e os
dois lampiões do batente da boca da mina (que são tochas do mapa). O lampião do jogador (`decor_lampiao`) e o de cristal já
tinham um desenho só.

**Outros props que mudam com dia e noite** (listados, nenhum mexido):
- **Janelas acesas das casas e prédios:** é uma camada por cima (`IsoLuz.cor_janela`), não troca o desenho.
- **Fogueira e forja:** o fogo mexe e a luz acompanha, o desenho é o mesmo.
- **Fogos de artifício do festival** (`iso_fx.gd`): só de noite, é efeito.
- **Robô antigo:** muda o *comportamento* (vigia de dia, patrulha à noite), não o desenho.
- **Luz do cristal e do fóssil do S3:** só a luz.

Não achei outro prop que troque de desenho entre dia e noite.

## Testes

- **`b98_portao_tochas`** (novo, **0 falhas**). Confere:
  - o encaixe da cerca (±4 px) e a orientação dos 3 níveis;
  - 120 + 36 caminhos aleatórios, o colado na cerca e o de frente ao portão;
  - abre às 5:06 e fecha às 18:42, os quadros `nivel_N` / `meio_N` / `aberto_N`, e que ninguém atravessa fechado;
  - derrubado, consertado, sem muro e a vida da barricada;
  - quem espera encostado, o guarda, a abertura sem guarda e a criatura que impede;
  - carregar de noite;
  - as tochas (mapa, jogador, lampião e luz comida): o mesmo desenho de dia e de noite.
- **Testes ajustados de propósito:**
  - `p29_predios`: o portão agora desenha `aberto_N` de dia, `nivel_N` fechado e `quebrado_aberto` derrubado;
  - `p29_natureza` e `b92_arte_oficios`: a tocha tem um desenho só, e o Lumívoro apaga só a luz.
- **A caixa do `meio_1`** ficou mais funda (`peg [-48, -14, 44, 4]`): as folhas a meio caminho saem pros lados. Sem isso, o
  GUT `test_iso_arte` acusava 13 px fora da caixa.
- **Bateria completa**, um por vez, em primeiro plano, com a pasta `fake_appdata`:
  - passaram todos os testes de bloco, b25 → b98 (b51 incluído, 387 s), e `hud_frostpunk`, `manut_backups`, `p17`–`p20`,
    `p28_iso`, `p28_save`, `p29_*` e `p2_pendencias`;
  - passaram os GUT `test_iso` (6), `test_iso_arte` (3) e `test_iso_pele` (3).
- **Intermitente:** `b58_oficina_construivel` deu timeout no passo 3 uma vez e passou ao repetir.
- **Intermitente que já existia:** `p29_predios` falha às vezes, 1 par na ordem de desenho, sempre o vagonete da mina contra
  um bloco da montanha. Não tem a ver com o portão.
