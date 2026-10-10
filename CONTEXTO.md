# Contexto do projeto (pra retomar em outra sessão/conta)

Atualizado em 2026-10-10. Branch `isometrico`. Tudo até o Bloco 104 **foi enviado** pro GitHub (push com o OK do Marco); os Blocos 105 a 111 estão só no commit local. Push só com o OK dele.
Ele disse "pode executar todos os prompts que depois eu valido". No meio do 105 ele mandou o prompt URGENTE do balanceamento
da coleta (Bloco 106) dizendo "após terminar tudo aplicar ... se achar algo que deixe melhor pode aplicar e depois so me
documenta".

## AGORA (2026-10-10): Bloco 111 — famílias (feito; commit local). FIM DO PACOTE 8 → R → F: o Marco valida 108–111

Prompt F. Relatório `docs/BLOCO111_FAMILIAS.md`; simulação de 3 anos `docs/telemetria/bloco111/` (`tests/sim_familias.gd`,
modelo dia a dia que lê os @export); fotos `docs/arte/bloco111/`.
- `familias.gd` (gravidez, parto, fases bebê/criança/aprendiz/adulto, herança, mentor, política de Família) + `props/escola.gd`
  (obra do Centro) + as fases no ipezinho (`fase`, `idade_s`, `pais`, `filhos`…). Família não namora (`relacoes.parentes`); a
  cama do bebê a caminho fica prometida; criança fora dos alertas de parado.
- Arte: menino e menina (todas as animações + retratos), escola (obra 1–3 + pronto), ícone do bebê: 151 gerações, saldo 5.562.
- Simulado: sem casa nova, 4 bebês e para (a cama é o freio); com 1 casa a cada 14 dias, 12 → 42 adultos em 3 anos; adulto aos
  56 dá fome no 3º ano (por isso 28).
- Cuidado no commit: os 161 retratos " M" (aviso do LFS) são idênticos ao HEAD — commitar por caminho explícito.
- Teste: o b85 agora mede o máximo da hora social (a foto de um instante falhava quando todos trocavam de roda).

## Bloco 110 — relacionamentos (feito; commit local)

Prompt R. Relatório `docs/BLOCO110_RELACOES.md`; medição `docs/telemetria/bloco110/` (`tests/bench_relacoes.gd`); fotos
`docs/arte/bloco110/`.
- `relacoes.gd` (traços, pares, níveis, casal, casamento na missa, luto pessoal, diário) + `ficha_panel.gd` (botão "Ficha" no
  cartão) + habilidade por função no ipezinho. Os traços modulam as Políticas (`politicas._reacao`).
- Arte: ícones coracao e coracao_partido (10 gerações, saldo 5.713).
- Medido: 1º casal no dia ~14 (2º domingo); a habilidade em ~77% no dia 14. A queda de ânimo do dia 8 no banco é fome.
- Pro Prompt F: `relacoes.adulto()` já pergunta `w.e_crianca()`; `sorteia_tracos()` pronto pra herança; casais em `parceiro_de`.

## Bloco 109 — IA (feito; commit local)

Prompt 8. Relatório `docs/BLOCO109_IA.md`; medição `docs/telemetria/bloco109/` (`tests/bench_ia.gd`); fotos `docs/arte/bloco109/`.
- Estação por PONTUAÇÃO (`_custo_estacao`: distância, fila, quanto tem, o que falta no armazém, perigo). FUNÇÃO SECUNDÁRIA
  (padrão por função, botão no cartão; só no expediente e só sem NADA a fazer — não em "esperando espaço" nem esperando entrega;
  veste a roupa da secundária). Perigo: recolhe no AVISO da invasão, foge de criatura, ABRIGO mais perto na onda solar (sem cama
  nunca mais fica exposto). Carona sem carregador (material de obra).
- Achado e corrigido: o prato preso do Bloco 84 (sem lugar no comedouro, parado em "comendo" pra sempre: matava a vila de fome).
- Testes antigos de tempo de resposta (b105, b86, b94) ligam `ipezinho.secundaria_desligada = true`.
- Medido: ociosos 3,67 -> 2,14 (dias 1-2: 3,4/2,7 -> 0,0/1,6), minério +86%, expostos na onda 2 -> 0.

## Bloco 108 — Políticas da Vila (feito; commit local)

Prompt L. Plano `docs/BLOCO108_PLANO.md` (aprovado com: sem "Farta", F6, espera 1 dia, Vilarejo). Relatório
`docs/BLOCO108_POLITICAS.md`; medição `docs/telemetria/bloco108/` (`tests/bench_politicas.gd`); fotos `docs/arte/bloco108/`.
- `politicas.gd` (jornada, ração, segurança, migração; espera; fraqueza; vigilância paga ao anoitecer; treino até 125%; a greve
  derruba as opções que tiram ânimo) + `politicas_panel.gd` (F6) + `modificadores.gd` (o ponto único dos multiplicadores: a
  Dificuldade do Prompt 5 só entra no grupo "modificadores"). Ânimo num ponto só: `fatores_animo` / `_reacao` (pros traços).
- Achado: ~40% da comida servida vai pro lixo (o prato sai inteiro e quem enche larga o resto). NÃO mexido (anularia a ração
  reduzida e mudaria o balanceamento do 101); proposta no relatório.
- O Marco disse (2026-10-10) "pode aplicar" os Prompts 8, R e F em seguida, com as decisões: secundária por ipezinho com padrão
  por função; combinar viagens só sem carregador; só o balão de coração (sem animação de abraço); casal muda de casa sozinho;
  adulto aos 28 dias (@export; simular também 56); escola SEM função nova ("já temos muitas"); arte das crianças e da escola
  COMPLETA (sem parar no piloto); a política de Família no cartão reservado da janela de Políticas. "Sempre usar skill"; "se ver
  algo estranho pode alterar e depois só me fala".

## Bloco 107 — agricultor, estufa, carvoaria, curtume e cardápio (feito; commit local)

Prompt W2. Plano `docs/BLOCO107_PLANO.md` (aprovado). Relatório `docs/BLOCO107_AGRICULTOR_OFICINAS.md`; fotos `docs/arte/bloco107/`.
- Horta e estufa são construção DENTRO da vila (a horta da clareira sai na partida nova; save antigo mantém). Agricultor (tecla
  `-`): colhe; com ele o caçador só caça (sem ele, o caçador colhe). Estufa de VIDRO (estágio 2): rende mais no inverno.
- Carvoaria (lenhador) e Curtume (caçador): oficinas de ordens (herdam da Fornalha), um operador por vez; carvão vegetal vale
  como o mineral (vegetal primeiro); com curtume, botas/mochila/trajes pedem couro curtido.
- Cozinha (clique): prato da semana (comum/ensopado) e ORDEM de ração (item `racao`; a expedição gasta a pronta primeiro).
- ARTE feita e integrada (o Marco aprovou o piloto do agricultor): agricultor/agricultora, estufa/carvoaria/curtume (obra 1-2-3-
  pronto), animações carvoejar e curtir, ícones e a RUÍNA do vagonete (Bloco 106). Pendência pequena: o "curtir" do casaco do caçador
  ainda mostra uma ferramenta curva grande (refazer ~16).
- Provisório: o cartão e o desenho da horta (o que já existia).

### Orçamento do PixelLab (Bloco 107)
| | Gerações | Tipo |
|---|---|---|
| Saldo inicial | 6.063 | confirmado |
| Gasto (tudo o que o bloco precisou) | 332 | real |
| Saldo restante | 5.723 | confirmado (depois da refação do "curtir" dos casacos: 8) |
| Previsto no plano | ~570 | estimado (as estruturas saíram bem mais baratas) |

## Bloco 106 — coleta, armazém por compartimento e ociosidade (feito; commit local; o Marco revisa)

Prompt URGENTE (balanceamento da coleta). O Marco autorizou fazer as etapas A e B seguidas ("pode aplicar e depois so me
documenta"). Relatório `docs/BLOCO106_COLETA_ARMAZEM.md`; telemetria `docs/telemetria/bloco106/` (antes/depois, medida com
`tests/bench_coleta.gd` numa partida nova de verdade); fotos `docs/arte/bloco106/` (`tests/capturas_bloco106.gd`).
- Causa: mineiro ~30 minério/h de jogo (6x o lenhador) + um limite só de 400 de tudo junto -> cheio em 2,4-3,7 h de jogo
  (~1 min real; 30-40 s em 2x). O vagonete operava sem área (o "mina desativada" do Bloco 77 só valia com área), mas não era
  a causa. Ociosidade = estado "storing" preso na porta (não animação). Perda: escavadeira/coletor de minério sumiam o
  minério com o armazém cheio.
- Feito: `Economy.ritmo_mineracao` 0,045; `taxa_dentro` 3,5; `level_ore_required` 0/200/650/1600/3200; compartimentos
  (alimentos 150, madeira 350, minérios 400, manufaturados 100 no nível 1; x2,5 e x5); estado `esperando_espaco`; máquinas
  param antes de produzir; alerta/janela por compartimento; o vagonete da BOCA em RUÍNA (3 etapas, só com mecânico,
  `vagonete_panel.gd`; save antigo = funcionando).
- Depois (medido): abertura -> 1º compartimento (madeira) cheio a h38, minério 258/400 em 2 dias; 3 casas + cozinha em 12,5 h.
- PENDENTE com o Marco: o ritmo novo vale pro jogo todo (os custos em minério dos prédios não mudaram); arte da ruína do
  vagonete não foi gerada; "Pedra" não existe como recurso separado.

## Bloco 105 — carregador e mecânico (feito; commit local; ESPERANDO o Marco: telemetria e arte)

Prompt W1. Plano `docs/BLOCO105_PLANO.md` (com a aprovação). Relatório `docs/BLOCO105_CARREGADOR_MECANICO.md`.
- Carregador (tecla física BracketRight = "[" no ABNT2): `logistica.gd` (obra, insumo "a caminho" da Fornalha/Carpintaria,
  barras, estoque da cozinha), fallback de 30 s. A forja não mudou.
- Mecânico (tecla física BackSlash = "]" no ABNT2): `manutencao.gd` + `desgaste.gd` + `props/conserto_maquina.gd`; desgaste
  gradual (100% até 40%, cai até 50%, quebra em 0) na escavadeira, coletores, ventiladores (aviso a 25%), robô; cabine e
  trilho com a curva. Conserto só com o material todo e quem conserte; preventiva só tempo; sem mecânico o engenheiro
  conserta só a quebra. Desiste de máquina sem caminho (60 s) — achado na telemetria.
- PENDENTE com o Marco: (1) a TELEMETRIA do desgaste (seção 4 do relatório; `docs/telemetria/bloco105/`) — o
  balanceamento do `Manutencao` está PROVISÓRIO; (2) o PILOTO da arte (o carregador: `docs/arte/bloco105/`) — só depois da
  aprovação: carregadora, mecânico, mecânica, os ícones e a integração (`integra.py bonecos carregador ...`); defeito
  apontado: o "carregar" de frente perde a armação (refaz ~16); (3) apertar `[` e `]` no teclado real.
- Ícones provisórios: barra (it_mochila / it_ferragem), alerta da máquina (al_reator), balão sem material (al_obra_parada);
  o mecânico veste o engenheiro (`iso_bonecos.PROVISORIO`).

### Orçamento do PixelLab (Bloco 105)
| | Gerações | Tipo |
|---|---|---|
| Saldo inicial do bloco | 6.141 | confirmado (`get_balance`) |
| Gasto neste bloco (o carregador completo) | 78 | real |
| Saldo restante | 6.063 | confirmado (`get_balance`) |
| Próximos personagens (carregadora, mecânico, mecânica) | ~78 cada = ~234 | estimado (custo real do piloto) |
| Ícones (carregador, mecânico, sem material, alerta da máquina) | ~40–60 | estimado |
| Refazer o "carregar" de frente (opcional) | ~16 | estimado |
| Total previsto pro resto | ~290–310 (saldo ~5.750) | estimado |

## Bloco 104 — robô antigo, batedor e expedições (feito; enviado ao GitHub com o OK do Marco)

Prompt E. Plano `docs/BLOCO104_PLANO.md` (decisões: Antena improvisada sem rádio; batedor obrigatório; a fábrica atrás da
radiação do S2 — análise no relatório; Posto de expedição; arte; teclas K e ;). Relatório `docs/BLOCO104_EXPEDICOES.md`.
- Cadeia do robô (expedicoes.gd): Ferrugento estudado -> sinal (Rádio/Antena, de noite) -> 3 escutas (pistas do catálogo)
  -> "A fábrica soterrada" -> a expedição acha o robô. Partida nova sem sorte; save antigo sem robô mantém a sorte.
- Batedor (K, h/m, arte completa PixelLab): bate o mato (avista x3, toca rastreada x1,5) e lidera as expedições.
- Expedições (janela ;, mapa da região novo): equipe 2-4, ração/kit, risco com partes, sai do mundo (sai_do_mundo), 1-2
  decisões, relatório; 8 regiões em data/expedicoes/. Posto de expedição (Centro, estágio 3) = 2 ao mesmo tempo.
- PixelLab: 201 gerações (saldo 6.141).

## Bloco 103 — corpos de criatura, bestiário e reconhecimento dos andares (feito; enviado ao GitHub com o OK do Marco em 2026-10-08)

Prompt S2 + acréscimo. Plano `docs/BLOCO103_PLANO.md` (com as decisões). Relatório `docs/BLOCO103_BESTIARIO.md`; fotos
`docs/arte/bloco103/`.
- Corpo da criatura abatida (`props/corpo_criatura.gd`): o último quadro da morte, até o amanhecer seguinte + 8 h; o drop
  fica no corpo (colhido no estudo; no prazo vai pro armazém); corpo na vila: -1,5 de ânimo (até 4,5).
- A pesquisadora estuda a espécie NO CORPO (portão fechado: não vai lá fora). Ficha (comportamento, fraqueza, deixa,
  perigo 1-5, POR QUE VEIO + dica, história) do `textos.txt`; cartão (banner) + diário; ela ganha xp (+10% de ritmo por
  descoberta, até 50%) e ânimo, com balão.
- Gosma e Magmante MORAM no S2/S3 (de dia e de noite, não sobem; `nivel_mina.moradores`); saíram das invasões. Guardas
  descem caçar (`defense.patrulhas`, janela da Defesa). A Gosma corrói a arma (implementado). Os textos da barricada saíram.
- Andar novo não reconhecido: a IA não desce; ordem/área/patrulha pedem confirmação (`hud.pergunta_descida`) e aí
  acidentes x2 até o reconhecimento (com risco de ferimento; revela perigos, criaturas, equipamento).
- Defesa: a previsão da próxima onda, "???" pra espécie não estudada, o banner da invasão também.
- Sinais `criatura_estudada` / `andar_reconhecido`; objetivos `criatura` / `reconhecer`.

## Bloco 102 — catálogo, minérios e animais (feito; enviado ao GitHub com o OK do Marco em 2026-10-08)

Prompt S1. Plano `docs/BLOCO102_PLANO.md` (decisões: conhecimento inicial do plano; pesquisas travadas por estudo como na
tabela; criaturas pela amostra do abate; locais S2-S5 + Leste "de momento"; tecla R). Relatório `docs/BLOCO102_CATALOGO.md`;
fotos `docs/arte/bloco102/`.
- `catalogo.gd` (nó Catalogo, grupo "catalogo") + `catalogo_panel.gd` (tecla R); dados `data/catalogo/entradas.json` +
  `textos.txt`. Desconhecido -> Avistado -> Estudado.
- A pesquisadora sem pesquisa sai pra catalogar (estado `catalogando`, `nota_campo` no save); 40 s anotando com a animação
  `pesquisar`; +8 pontos (guardados se não há pesquisa: `research.pontos_guardados`).
- Pedra desconhecida -> "minério desconhecido" (tipo novo do ores.gd, 1 cr); estudar troca no armazém. Toca não estudada
  some pro caçador. Fornalha/Oficina sem o nome. Pesquisas: explosivos/carvão, trajes/S2, ventilação/cristal verde,
  bombas/S3, escudo/solarita. Plano B: o laboratório sozinho (0,15 pt/s). Amostra no abate da criatura.
- Testes antigos que mineram cobre/carvão, caçam ou pesquisam: `catalogo.gd tudo_estudado = true` no _initialize.
- O export passou a levar `data/catalogo/*` e `data/missoes/*.txt` (os textos das missões do Bloco 100 ficavam de fora).

## Bloco 101 — migrantes e população inicial (feito; enviado ao GitHub com o OK do Marco em 2026-10-08)

Prompt M. Plano `docs/BLOCO101_PLANO.md` (decisões: os itens 1-6 ok; casas iniciais NÃO prontas — só o recurso pra
construir, como já era; comida inicial 240 / cozinha 300; sem a dica de cozinheiro/caçadores; o satélite chama
migrantes). Relatório `docs/BLOCO101_MIGRANTES.md`; fotos `docs/arte/bloco101/`; medição `tests/bench_comida.gd`.
- Acabou o "Recrutar" (tecla R, botões, custo, ajuda). Partida nova: a Fundação completa 10 (5 e 5, sem função).
- Capacidade = camas livres. Migrantes (`migrantes.gd`): grupo de 1-3 no portão, cartão Aceitar/Recusar/Esperar, prazo de 1
  dia, ataque à noite, frequência pela atratividade (1,5 a 4 dias), rede de segurança (< 4 ipezinhos). O "refugiados" do
  Prompt 11 é este sistema.
- Comida com 10: com 1 cozinheiro + 2 caçadores segura (fome ~80); o gargalo é o cozinheiro (~230/dia), não a horta.

## Bloco 100 — sistema de missões e Capítulo 1 "Cinzas" (feito, enviado ao GitHub com o OK do Marco em 2026-10-08)

Prompt 3 / seção 21 do guia. Relatório `docs/BLOCO100_MISSOES.md`; fotos `docs/arte/bloco100/`.
- `missao.gd` (recurso) + `data/missoes/cap1_cinzas.tres`; textos em `data/missoes/capitulo_1.txt` (um arquivo por capítulo,
  formato `chave = valor`); gerenciador `missoes.gd` (nó Missoes, grupo "missoes"); janela `missoes_panel.gd` (tecla vírgula);
  rastreador do canto (o espaço do layout v2) ligado.
- Capítulo 1: fundar a vila, 3 casas, cozinha, 100 de minério, 1ª invasão -> 150 cr + página do diário + libera o cap. 2
  (ainda não escrito: a janela diz "em breve"). Sinal novo `centro_vila.obra_pronta(tipo)` (só avisa).
- Save "missoes"; save antigo começa no capítulo certo (refaz os contadores e entrega o que já estava cumprido).
- Capítulos 2 a 6 da seção 21.1 do guia ficam pros próximos pedidos (é só um .tres por missão + o arquivo de texto).

## Bloco 99 — entrada da mina, elevador, escadas e vagonete (feito, enviado ao GitHub com o OK do Marco em 2026-10-08)

Plano `docs/BLOCO99_PLANO.md` (aprovado: em paralelo, espiral sempre, escadas como achar melhor, rendimento igual,
100/240/60 s, arte ~440). Relatório `docs/BLOCO99_MINA_ELEVADOR.md`; fotos `docs/arte/bloco99/` (auditoria e depois).
- Elevador do S2: ruína → 3 etapas (obra com material) em paralelo com a escavadeira; a cabine (`cabine.gd`) faz fila,
  embarca 4, anda pelo poço (desenho a cada quadro em `iso_view._sync_cabines`), desembarca; o cabo arrebenta em 60
  viagens e o conserto é pedido sozinho. O mesmo nas plataformas S3–S5.
- Escada em espiral (`espiral.gd`): ligação lenta (20 s por andar) sempre aberta com o andar; o caminho prefere o elevador.
- Mina: o mineiro da área de mina entra pela boca principal e trabalha dentro (21/h, sai na agenda); o vagonete leva 100,
  guarda 240, espera 60 s; desgaste por minério. Saíram as escadas de mão do paredão e a do S1.
- Arte PixelLab: torre obra_1/obra_2, cabine vazia/cheia, vagonete com carga grande, lampião da boca (205 gerações).
- Medição: renda parecida (galerias ~90–100/h com 5 lá dentro; antes ~105). Telemetria com o minério por dia.

## Bloco 98 — portão da paliçada (abre/fecha) e tochas (feito, enviado ao GitHub com o OK do Marco em 2026-10-08)

Relatório `docs/BLOCO98_PORTAO_TOCHAS.md`; fotos `docs/arte/bloco98/antes|depois/`.
- Causa: a navegação já passava só pelo vão, mas o vão da cerca desenhada (99 px) não batia com o lógico (80) nem com o
  portão (68), o caminho roçava a ponta do vão e o desenho era sempre um portão fechado. O nível 3 estava espelhado.
- Agora: `gate_half_width` 34 (= o desenho), a paliçada sai do portão pra fora, a malha leva a paliçada inteira e o portão
  passa por 3 faixas (`NavigationLink2D`). Abre de dia e fecha às 18:30 (abre 05:00), com nivel_N/meio_N/aberto_N
  (PixelLab, 340 gerações). Quem está fora espera encostado no portão; um guarda abre (3 s); sem guarda, 20 s; criatura
  perto não abre. Derrubado ou sem muro: aberto.
- Tochas: um desenho só (a chama), muda só a luz.
- Testes: b98 passa; ajustados p29_predios e p29_natureza. Intermitentes: p29_predios (o vagonete contra a montanha) e
  b58 (timeout no passo 3, passou ao repetir).

## Bloco 97 — armazém com limite e níveis até 3 (feito, enviado ao GitHub com o OK do Marco em 2026-10-08)

**O pedido:** "sim e o armazem pode ser upado ate nivel 3". Plano em `docs/BLOCO97_PLANO.md`; relatório em
`docs/BLOCO97_ARMAZEM_NIVEIS.md`; arte de conferência em `docs/arte/bloco97/armazem_niveis.png`.

**Decisões do Marco:**
- 400 / 1.000 / 2.000 ("muito bom");
- 10 por viagem continua;
- armazém novo é construção nova, libera no estágio 2 e o jogador escolhe o lugar;
- a arte pode ser feita já;
- os saves dele "pode deletar": **NÃO apaguei** (save antigo = nível 1 com o que tem; apagar fica com ele).

**Como funciona:**
- `armazem.gd`: `capacidade()` / `usado()` / `espaco()` / `cheio()`. O depósito só entra até caber.
- Cheio: `accepts_worker` recusa quem vem entregar (ele vai pra outro armazém ou espera com o balão
  "armazem_cheio"). Os coletores, a broca e o vagonete param (`Economy.armazem_com_espaco`). Devolução e prêmio
  entram mesmo cheio.
- Fora do expediente, com todos os armazéns cheios, `_entrega_pendente` não prende: ele fica com a carga e vai pro
  festival, o funeral ou a cama (o b88 achou).
- `ampliar()` é obra com material (Bloco 96): o nível 2 pede o estágio 2, e o nível 3 pede o estágio 3.
- O armazém novo: `centro_vila.build_armazem` → `Canteiro` "armazem" → `spawn_armazem` (`construido = true`), salvo
  em `armazens_novos`.
- Arte: `assets/game/iso/predios/armazem/nivel_2|3.png` (80 gerações; os candidatos estão em `_cand97/`, fora do
  git) e o cartão `armazem_ampliar.png`.

**Testes:**
- b97 passa;
- os 81 testes de bloco e os GUT iso passaram, um por vez;
- os testes que enchem o armazém pra outro assunto (b45, b57, b58, b64, b79, b94) usam
  `armazem.gd limite_desligado = true`;
- intermitentes: b92 e p29_predios (passam ao repetir).


## Bloco 96 — obras com material levado pelo engenheiro (feito, enviado ao GitHub com o OK do Marco)

**O pedido:** o Prompt O (`Claude outputs/deep-iron-prompts-O-P-Q-M-S1-S2.md`). Plano e tabela em `docs/BLOCO96_PLANO.md`;
relatório em `docs/BLOCO96_OBRAS_MATERIAL.md`.

**Decisões do Marco:** 10 por viagem; cancelar devolve também os créditos e vale pra todas; os consertos grandes
(barricada, plataforma do abismo, robô) viram obra com material.

**Como funciona:** a Economy anota o RECIBO dos pagamentos do quadro e o `ObraSite.start()` da obra que nasce pega:
o material volta pro armazém como RESERVA (`Economy.livre`). O engenheiro busca no armazém mais perto, até 10 por
viagem, e a obra só anda até o entregue. Tem pilha ao lado, carga no corpo, "levando N/M" e o Cancelar na gaveta
Obras. Save antigo = tudo entregue.

**Medida** (`tests/bench_obras.gd`): as obras ficaram 1,5x a 2,7x mais demoradas; a escavadeira, ~15–20 min com 1
engenheiro. As propostas (carga 15, carrinho de mão, carga maior pra escavadeira/escudo) estão no relatório, **NÃO
aplicadas**: decisão do Marco.

**Testes:** o b96 passa; a bateria dos 80 blocos e os GUT iso passaram um por vez. Foram ajustados b41, b44, b45,
b56, b71, b81, b86, b87 e b94 (conferem o livre).

**Seguinte:** o armazém com limite virou o Bloco 97 (acima).

## Bloco 95 — layout v2 da interface (feito, fonte Chakra Petch aplicada, enviado ao GitHub)

**O pedido:** a seção 27 do guia (`docs/DEEP_IRON_Guia_completo_e_Analise.docx`) mais a janela CONSTRUIR
padronizada, a tipografia e uma imagem em todo cartão (partes A, B, C e D). O plano e o ANTES estão em
`docs/layout_v2/PLANO_BLOCO95.md`. O Marco aprovou: "pode continuar, aprovado".

**Relatório:** `docs/BLOCO95_LAYOUT_V2.md`. Capturas em `docs/layout_v2/antes|depois/` e `antes_depois.jpg`.

**O que foi feito:**
- **HUD v2:**
  - aba fina à esquerda: Tab abre a lista (o "próximo ipezinho" foi pro ".");
  - alertas à direita, com clique que leva ao lugar;
  - barra de funções agrupada, só com as liberadas;
  - cartão do selecionado acima da barra;
  - hora grande no meio;
  - Vender e auto no Armazém;
  - menu "Janelas";
  - pilha de avisos;
  - espaço do rastreador de missões;
  - balões de motivo, com liga/desliga.
- **CONSTRUIR:** janela de tamanho fixo, grade vertical e cartão de estrutura fixa, com o campo `img`.
- **Escala tipográfica:** `scripts/ui/tipografia.gd`, sem número solto, e o tema chegando nos `CanvasLayer`.
- **Escala da interface:** 90/100/125%; 125% cabe em 720p.
- **Rótulos do mapa:** só o nome, com o texto inteiro ao passar o mouse; toda obra ganhou barrinha e martelo cinza.
- **Arte (PixelLab):** 9 ilustrações de cartão e 5 ícones, **300 gerações**. **Saldo 6.937** (renova em 2026-11-02).
  Os 8 cartões da decoração e do vagonete reaproveitam o sprite do jogo.
- **Regra 12 nova no CLAUDE.md:** todo cartão novo do CONSTRUIR precisa de imagem.

**Decisões do Marco (2026-10-07):** fonte = Chakra Petch (aplicada); o armazém ganha LIMITE e sobe até o nível 3
(vira o Bloco 97); push liberado.

**Testes:** a bateria inteira foi conferida um por vez em 2026-10-07: os 79 de `tests/blocos` com 0 falhas e os GUT
iso. O b84 e o b85 têm falha rara por sorteio e passaram ao repetir. Os ajustados: hud_frostpunk, b28, p20, b54
e b83. Push só com o OK do Marco.

**Roteiro do guia (seção 28) andou um número:** o b96 é a tela de dificuldade e o b97 as missões (que usam o
`rastreador_missoes.gd`).

## Antes (2026-10-07): Bloco 94 — a cadeia de produção fechada

**O pedido:** dar uso ao que se fabrica e só servia para vender.

**O que foi feito:**
- **Carpintaria** (obra 1-2-3-pronto do PixelLab) e a função **carpinteiro/carpinteira** (tecla 9), com a receita
  completa do elenco.
- **Tábuas e camas de tábua**, só por ordem. A cama vai pra casa pela janela da casa; o carpinteiro monta e quem
  dorme nela ganha +3 de ânimo.
- **Pregos e ferragens** na casa 3, na barricada 3 e na ferrovia.
- **Aço** na Picareta de aço nova, na lança de prata e nas bobinas.
- **Couro** nas botas (a neve atrasa quem anda sem) e na mochila (+4 de carga do minerador).

**Aprovação:** o Marco aprovou a tabela de custos antes (e depois aceitou a mochila sem os 40 cr: 3 couro + 2 pregos), a lentidão na neve ("pode criar") e a picareta:
- a de antes virou "Picareta temperada" (o id `picareta_aco` ficou);
- a "Picareta de aço" é nova, no estágio 3.

**Detalhes:**
- Tabela e relatório: `docs/BLOCO94_CARPINTARIA_CADEIA.md`.
- PixelLab: 485 gerações. Saldo 7.237.
- Testes: b54, b56 e b82 foram ajustados. O b94 dependia do sorteio do gênero (sem homem no começo, 4 falhas):
  corrigido em `5bd05115`. **Bateria inteira conferida em 2026-10-07, um teste por vez:** os 77 de `tests/blocos`
  (inclusive o b51, 353 s) com 0 falhas, e os GUT `test_iso` (6/6), `test_iso_arte` (3/3) e `test_iso_pele` (3/3).
  Cuidado: `gut_cmdln -gtest=...` sozinho varre `tests/` inteiro por causa do `.gutconfig.json`; use `-gconfig=`.
- Enviado pro GitHub em 2026-10-07.

## Antes (2026-10-06): os ajustes do Marco depois dos Blocos 81–91

O Marco viu o resumo dos Blocos 81–91 e pediu:
1. vender a quantidade que quiser no armazém;
2. a arte dos 86/87/88/90 **no PixelLab, no nível do jogo** (nada de provisório);
3. fundidor e padre como funções (padre só homem, um só; ferreiro homem e mulher);
4. o cemitério.

E duas regras para sempre, gravadas na memória (`feedback_receita_arte_nova.md`) e no CLAUDE.md (regra 11):
- **personagem novo:** a receita inteira do elenco, com as 5 expressões do retrato e a caminhada ajustada;
- **estrutura nova:** a evolução da obra até ficar pronta.

| Commit | O quê | Relatório |
|---|---|---|
| `0584027a` bloco-82 | vender a quantidade escolhida: "Vender…" seleciona o item e a barra de venda tem −10/−1/+1/+10/Tudo e "Vender N"; `Economy.sell(item, quantidade)` | `docs/BLOCO82_ITENS_ARMAZEM.md` (fim) |
| `cd1efdcf` bloco-92 | arte do PixelLab: fundidor/a, ferreiro/a e padre com a receita do elenco (fundir/forjar/pregar, casaco, retrato com 5 expressões, ícone da barra); fornalha = a Fundição do Prompt 12; igreja nova (obra 1-2-3-pronto); decoração pelo desenho do PixelLab (lampião, cerca, canteiro e bandeira novos; a tocha acende/apaga). **Padre = função [8]**: só homem, um por vila, pode trocar de função, prega na missa | `docs/BLOCO92_ARTE_OFICIOS_PIXELLAB.md` |
| `ec4efdf4` bloco-93 | **cemitério** do tamanho que o jogador arrasta; começa vazio; a obra aparece em etapas (estacas, postes, cerca, pronto com portão); quem morre deixa o corpo; o padre busca, leva nos ombros e enterra (cruz ou lápide com nome e dia); pesquisa **Ritos fúnebres**: funeral no cemitério, o luto cai e o ânimo sobe ("funeral digno") | `docs/BLOCO93_CEMITERIO.md` |

**Detalhes que importam:**
- **Casaco no trabalho:** o trabalho de casaco do fundidor e do ferreiro saiu ruim no PixelLab (picareta, fogo).
  Na fornalha e na forja eles trabalham **sem o casaco** (o jogo cai sozinho na animação da base); o padre prega
  de casaco.
- **Funeral (mudou o Bloco 88):** agora precisa da pesquisa "Ritos fúnebres". Com cemitério, é lá depois do
  enterro; sem cemitério, na igreja.
- **Barra de funções:** são 14 botões com o Padre; cada um foi de 90 para 82 px.
- **PixelLab:** saldo de 8.669 → 7.917 depois do 92; o 93 gastou mais ~195 (cemitério, peças, cerca, ícone): saldo 7.722.
  Os candidatos não escolhidos ficaram fora do repositório (os ids estão nos `*_jobs.json`).
- **Testes:**
  - b92 passa;
  - b93: passa (0 falhas); depois do 93 também passaram b88, b77 e b36;
  - depois das mudanças, passaram b82, b39, b86, b87, b88, b90, p29_bonecos, p29_predios, hud_frostpunk e b54.
- A **bateria inteira** não rodou (memória: um teste por vez).

## Antes (2026-10-06): Blocos 81–91 — feitos, esperando o Marco validar

**De onde veio:** os pedidos estão em `docs/Prompt/Ultimo_84.txt` (numerados lá como Blocos 50–59 com testes
b51–b59). Esses números já existiam no histórico, então cada um virou **o próximo livre**, com o teste do mesmo
número, explicado em cada relatório.

**O pedido final do Marco:** "no final atualizar os arquivos CLAUDE.md e Contexto" (feito).

| Bloco | Commit | O quê | Relatório |
|---|---|---|---|
| 81 | `0b84c11b` | Coletor de madeira nasce em RUÍNA na floresta (-420, 260) e é restaurado por etapas pagas pelo jogador e feitas pelo engenheiro; extras só depois dele | `docs/BLOCO81_COLETOR_RUINA.md` |
| 82 | `ebfcb099` | Catálogo de itens `items.gd` (barras, aço, lingote, prego...), dicionário `itens` no armazém (fora do `stock`), janela do armazém em grade por categoria | `docs/BLOCO82_ITENS_ARMAZEM.md` |
| 83 | `86bf485c` | Relógio de 24 h (9 min reais, 1 h = 22,5 s; marcos 05:00/18:00/18:30/21:30), semana (7º = domingo), estações de 2 semanas, invasão às 22:00 (aviso 21:00), velocidade pausa/1x/2x/4x e "Pular dia" | `docs/BLOCO83_RELOGIO_24H.md` |
| 84 | `67fe6be0` | AGENDA (`Schedule`): emergência > agenda > necessidades; café/almoço/jantar (uma porção cada), voltar 18:00, social 18:30, dormir 21:30; médico de plantão, vigília em rodízio, cozinheiro cedo; HUD "porções (hoje N)" | `docs/BLOCO84_AGENDA.md` |
| 85 | `6967a11d` | Hora social: pontos sociais (`social_spot.gd`: refeitório, praça, taverna, parque), rodas de conversa com balão, passeios com waypoint, chuva → cobertos | `docs/BLOCO85_HORA_SOCIAL.md` |
| 86 | `43f18076` | `production_queue.gd` (só por ordem, quantidade, pausa sem insumo, cancelar devolve) + Fornalha (aba Produção) + função **fundidor** (tecla 6) | `docs/BLOCO86_FORNALHA.md` |
| 87 | `e6195b3d` | Função **ferreiro** (tecla 7): Oficina e Arsenal são dele (o engenheiro só constrói); pregos e ferragens; custos migrados pra **barras** a partir do estágio da fornalha (1 barra = 2 minérios, `Economy.metal()`) | `docs/BLOCO87_FERREIRO_BARRAS.md` (com a tabela) |
| 88 | `695e92e0` | Padre (chega no estágio 2), Igreja (aba Culto), missa de domingo, funeral (alivia o luto), aconselhamento, escolha de domingo à tarde (Festival / Dia livre / Trabalhar), festivais por estação, nó `Calendario` | `docs/BLOCO88_PADRE_IGREJA.md` |
| 89 | `d082e87f` | Caminhos pintados (terra / cascalho / pedra) com bônus de velocidade; Trilhas aumenta o bônus; o passeio segue os caminhos; não mexem na navegação | `docs/BLOCO89_CAMINHOS.md` |
| 90 | `ee354d09` | Decoração do jogador (`decor.gd` + `decoracoes.gd`): 7 peças, aba Decoração, várias em sequência, remover com reembolso, luz à noite (o Lumívoro é atraído e apaga), banco/mesa = ponto social, beleza perto de casa, rebuild de navegação agrupado | `docs/BLOCO90_DECORACAO.md` |
| 91 | `f512fff7` | Criaturas do PixelLab (Lumívoro, Matriarca, Gosma, Magmante): já estavam integradas (Blocos 62/70); conferidas no jogo, teste de carga e **F3 → "invasão com todos os tipos"** | `docs/BLOCO91_CRIATURAS_PIXELLAB.md` |

**Arte provisória** (geradores em `prototipos/camera/arte_iso/`):
- ruína do coletor: `coletor_ruina.py`;
- ícones dos itens: `ui/icones_itens.py`;
- fornalha: `fornalha_provisoria.py`;
- igreja: `igreja_provisoria.py`;
- decoração: `decor_provisoria.py`;
- balão de fala;
- fundidor, ferreiro e padre com a roupa de outro ofício e um tom de cor (`FUNDIDOR_TOM`, `FERREIRO_TOM`,
  `PADRE_TOM` no `ipezinho.gd`).

O PixelLab não foi usado nestes blocos (a não ser pra listar as criaturas no 91).

**Testes:**
- Cada bloco tem o seu teste (b81–b91), e todos passam.
- Também passaram depois das mudanças: b25, b26, b27, b28, b29_30, b31, b31b, b32, b33, b34, b35, b36, b37,
  b39, b40, b41, b42, b44, b45, b46, b47, b52, b55, b56, b57, b58, b60, b61, b62, b71, b77, b80, p17, p18,
  p19, p20, p28_save, p29_predios, hud_frostpunk.
- **Testes antigos ajustados:**
  - b45 e b47 (coletor em ruína);
  - b40, b60, p18 e p19 (relógio de 24 h);
  - b31, b31b, b32, b35, b42 e b47 (ferreiro, barras);
  - b46 (o cartão do coletor só aparece com a ruína restaurada);
  - b84 (a hora social do 85);
  - `tests/ciclo_luz.gd` (as fotos usam horas).
- **A bateria inteira não rodou.** O sistema derrubou a bateria em segundo plano por falta de memória: os
  editores do Marco ocupam ~1,8 GB e sobravam ~4,5 GB livres. Desde então, os testes rodam **um por vez, em
  primeiro plano**.
- **Não conferidos depois dos Blocos 81–91:** b37, b38, b48, b51 (longo), b54, b63, b64, b67, b68, b69, b70,
  b72, b73, b74, b75, b76, b78, b79, b81 (depois do 84), b82, p2, p28_iso, p29_bonecos, p29_mapa,
  p29_natureza, manut_backups. Rodar a bateria inteira quando a memória deixar (fechar o editor antes).

**Próximo:**
- o Marco valida os blocos;
- push com o OK dele;
- arte de verdade (PixelLab) pra fornalha, igreja, decoração, fundidor, ferreiro, padre e a ruína do coletor,
  se ele quiser.

**Pra ver as coisas novas rápido (F3):**
- "Andares: abrir todos" + "Ir para: …";
- "Criaturas: invasão com todos os tipos";
- "Pular dia" na barra de cima;
- o domingo é o dia 7: a missa às 09:00 precisa do padre (estágio 2) e da igreja.

## Antes (2026-10-05): Blocos 75, 76 e 77 — feitos, esperando o Marco conferir

Pedidos do Marco: (1) "fica na montanha e pode seguir" (ferro fica na montanha; seguir com a coluna da
maquete); (2) "verificar a movimentação dos personagens todos, se precisar usar o blender... e continua o
desenvolvimento do layout do jogo com base a maquete montada no blender"; (3) "após ajustar tudo isso
fazer esta parte aqui" = áreas de trabalho com postos estilo Frostpunk (texto inteiro em
`docs/BLOCO77_AREAS_DE_TRABALHO_PEDIDO.md`).

- **Bloco 75 (`8b94ce00`) — a coluna da maquete:** os 4 andares viraram FAIXAS largas e rasas debaixo da
  floresta e da vila (`andares.py`, retângulos novos longe dos antigos; save antigo migra pela posição
  relativa), galerias de madeira logo abaixo da superfície. `docs/BLOCO75_COLUNA_FAIXAS.md`, teste b75.
- **Bloco 76 (`4f7ca3c2`, `2d09e142`, `8b175d53` + o commit das caminhadas do elenco) — todos andando +
  faixas:** S3 com rio de lava ao pé da parede e fios de lava de fendas; S4 com a cachoeira em cortina até
  a poça; rocha de cada andar no tom do tema. Movimento: criaturas, robô e animais pela distância (passada
  medida, `ciclo`); a GENTE INTEIRA (42: base, casaco, trajes) com caminhada de 8 quadros do PixelLab
  (`walking-8-frames`, modo `skeleton-v3` — segura roupa e rosto; o modo comum trocava o colete).
  Ferramentas `caminhadas8.py` (pede/baixa/troca; a de 4 fica em `caminhada4/`) e `integra.py caminhadas`.
  Blender não foi preciso. `docs/BLOCO76_CAMINHADAS_E_FAIXAS.md` (pendência: traje_gas_m NE com colete).
- **Bloco 77 (`94b34071`) — áreas de trabalho (Frostpunk):** tecla 5 / janela TRABALHADORES; marca a área
  arrastando (madeira, alimentos, mina), [ - ] n/5 [ + ]; disponível = sem função; quem vai ganha a função
  e só trabalha dentro da área; mina nasce desligada, "Ligar o carrinho", estados Desativada / Sem mineiro
  / Sem recurso / Operando (o vagonete só anda operando); produção real (5 rende mais que 2); save.
  Código: `work_areas.gd` (WorkArea + TIPOS), `area_placer.gd`, `work_panel.gd`, filtro no `ipezinho.gd`.
  `docs/BLOCO77_AREAS_DE_TRABALHO.md` (com os 6 pontos que o Marco pediu no relatório), teste b77.
  A bateria inteira de blocos passou (o hud_frostpunk alternava por estado salvo do próprio teste: corrigido).
- **O Marco aprovou os Blocos 75–77 ("aprovado, pode aplicar as melhorias")** e as pendências foram
  aplicadas (Bloco 76, seção 3 do relatório): 4 LOTES LIVRES na vila (cerca de corda, o posicionador
  encaixa no meio, lote com prédio some — `environment.lotes()` / `lote_perto`), a BOCA DA ESPIRAL na
  superfície (prop `boca_espiral`, PixelLab c03, `fundo76/espiral.py`), RAÍZES debaixo da floresta
  (galerias e S2) e o traje de gás masculino corrigido (`fundo76/traje_gas_cor.py`). Teste `b76_faixas_lotes`.
  (Esse trabalho entrou no commit `336f0961` "commit", feito pelo Marco com o que estava no índice.)
- **Verificação geral (05/10, pedido do Marco):**
  - **Itens na mão:** guardas e lenhadores agora andam com a mão vazia em todos os quadros (a ferramenta
    já vai nas costas). A ferramenta é `fundo76/itens_mao.py`.
  - **Navegação:** os "8 edge errors" vinham de triângulos de área zero do bake (`environment._sem_degenerados`).
  - **Saves dele:** as cópias carregam bem (`tests/verifica_save_marco.gd`).
  - **Testes:** bateria inteira e GUT passaram. Detalhes no relatório do Bloco 76, seção 4.
- **NovoLayout (`docs/NovoLayout/`, pedido do Marco):**
  - A análise está em `ANALISE.md`; a maquete v4 em `maquete_v4_legenda.jpg` (script
    `blender/coluna_maquete_v4.py`).
  - Conclusão: manter a estrutura, que já é a do NewLayout, e aproveitar três coisas: os marcos por andar
    (fóssil no S3, fonte termal no S4, cidade no S5, cristais no S2, vila de mineração nas galerias), a
    ferrovia de carga (minha sugestão: virar jogabilidade, com uma estação por andar subindo o minério) e um
    monitor de perigos no HUD.
  - O Marco APROVOU a v4 e pediu: primeiro os marcos visuais, depois a ferrovia de carga.
- **Bloco 78 — marcos dos andares (feito):**
  - Os marcos: vila de mineração nas galerias, cristais e poças d'água no S2, o fóssil gigante no S3, a
    fonte termal (bicas com vapor) no S4 e a cidade (torre e lampiões de cristal) no S5.
  - Arte nova em `fundo78/marcos.py`; teste `b78_marcos`; relatório `docs/BLOCO78_MARCOS_DOS_ANDARES.md`.
- **Bloco 79 — ferrovia de carga (feito):**
  - Uma estação por andar (S2 a S5, de cima pra baixo, só com o andar aberto, construída pelo engenheiro),
    usando o modo `ferrovia` da `estacao_vagonete.gd`.
  - O carrinho sobe pelo cavalete (desenhado na vista iso, à direita da espiral) até a plataforma na
    superfície e descarrega no armazém.
  - Teste `b79_ferrovia`; relatório `docs/BLOCO79_FERROVIA_DE_CARGA.md`.
- **CLAUDE.md** na raiz: visão geral, mapa das pastas e as regras fixas (Bloco numerado com teste, save
  compatível, @export, não mexer em addons/, padrões existentes, testes honestos, plano antes de refatoração
  grande, produção só por ordem, e **sempre usar as skills de .claude/skills**). Próximo Bloco: o número
  livre seguinte (os pedidos do Marco chamados "Bloco 49" etc. vêm de uma lista antiga: usar o próximo livre).
- **Bloco 80 (feito) — portão único + Ferrugento robô** (pedido "Bloco 49"): o portão do poço saiu (só o da
  floresta; o que sobe do fundo sai da boca do poço sem barricada; guardas fazem posto lá; brecha só no
  portão da floresta; save antigo com BarricadaPoco/downed_gate "poco" carrega). O Ferrugento virou robô
  enferrujado estilo exterminador, arte do PixelLab (`criaturas/ferrugento_robo.py`, personagem
  a48ac19b-…), desenhado por uma FOLHA DE QUADROS configurável (creature.gd `visual_*`). Teste `b80_…`;
  relatório `docs/BLOCO80_PORTAO_UNICO_FERRUGENTO.md`.
- **Pra ver os Blocos 78/79 no jogo logo no dia 1** (o Marco testou e "não viu": jogou 2 min na superfície; os
  marcos estão nos andares e a ferrovia só constrói com o S2 aberto): painel **F3** (build de editor) →
  "Andares: abrir todos" e "Ir para: vila / S2 / S3 / S4 / S5 / ferrovia".

## Antes (2026-10-04): Blocos 73 e 74 — feitos, esperando o Marco conferir

O Marco aprovou a `docs/arte/bloco72/maquete/superficie_v3_legenda.jpg` pra aplicar no jogo e pediu pra
melhorar o andar dos NPCs ("parece que eles flutuam um pouco").

- **Bloco 73 (`fa894421`) — bonecos andando:** os quadros da caminhada vinham cada um numa altura (pé até
  9 px acima do chão; robô 13). Ajuste por quadro `aj` no `bonecos.json` (`integra.py pes`, sem mexer nos
  PNGs); o quadro da caminhada vem da distância andada (`IsoBillboard.PASSO_CICLO`); sem sair do lugar
  fica parado; a posição desenhada fica entre dois passos da física. Relatório
  `docs/BLOCO73_BONECOS_ANDANDO.md`, GIF `docs/arte/bloco73/andar_antes_depois.gif`, teste `b73_andar`.
  Proposta em aberto: caminhadas de 8 quadros no PixelLab (Blender só como guia de pose, se precisar).
- **Bloco 74 (`df06d159`) — a superfície da maquete v3:** FLORESTA (oeste) | paliçada de norte a sul com o único
  portão | VILA plana (sem terraços, sem jazida) | MINA com a montanha de pedra em 3 degraus (6/12/18),
  5 bocas (a principal com o vagonete fixo até o armazém na frente; as 4 galerias nas outras), escadas,
  guindaste, casinha, pinheiros; o leste trancado (Bloco 67) começa depois da mina (x≈1245). Gerador:
  `prototipos/camera/arte_iso/mapa/monta.py` (constantes no topo) + `relevo/montanha.py`; jogo:
  `environment.gd` (palisade_x/gate_y, areas, open_sky_rect, surface_area, bocas_da_mina,
  _build_estacao_mina, MAP_DECOR_V3, migração de save antigo), `iso_view.gd` (paliçada de lado, trilho),
  `barricada.gd` (vertical), `founding.gd` (só o Centro: o armazém é o da mina), `main.tscn` (posições).
  Relatório `docs/BLOCO74_SUPERFICIE_V3.md`; teste `b74_superficie`; capturas `tests/capturas_bloco74.gd`.
  **Decisão pra confirmar com o Marco:** manter FERRO na montanha (é o minério de base; a informação de
  antes de que o começo era só cobre/carvão estava errada). Ponto de balanceamento: o lenhador anda ~1,7x
  (floresta no oeste, armazém único na mina). O save dele (cópia) carrega: a vila antiga vai pro lado de
  dentro da paliçada.
- Próximo (do plano do 72): as galerias de madeira logo abaixo da superfície e os andares como faixas
  (a coluna da maquete); lotes livres marcados e a boca da escada em espiral na superfície.

## Bloco 72 — o mapa do jogo igual à referência (histórico)

Prompt: `Claude outputs/prompt_bloco72_mapa_vs_referencia.md`. Referência:
`docs/arte/referencia_mapa_mundo.jpg`. Relatório: `docs/BLOCO72_MAPA_REFERENCIA.md`.

**O que o Marco quer (palavras dele, 2026-10-03):** o mapa do JOGO (não só uma imagem) com a mesma
estrutura da referência, em escala maior pra jogar: em cima a floresta e a pedreira/vila; a mina descendo
de verdade; cada nível UM EMBAIXO DO OUTRO, DEBAIXO DA VILA (não lá no canto do mapa); forma orgânica de
caverna (nada de quadrado/reto); escada em espiral + elevador + andaimes ligando os níveis. Ele rejeitou a
etapa 4 (lajes retangulares dentro de um bloco de terra reto, com a coluna na ponta leste do mapa).
**Decisões dele (perguntadas):** modelo = imagem B do PixelLab (`docs/arte/bloco72/mapa_pixellab/quadrado.png`);
fazer AS DUAS coisas (a imagem como mapa do mundo F2 + reconstruir os andares no jogo nesse formato);
andares mais compactos (~25% menores por lado), mantendo todas as jazidas. Memória:
`project_bloco72_coluna.md`.

**Commits do Bloco 72:**
- `1a90cd90` passo 0: auditoria, fotos em `docs/arte/bloco72/antes/`. `tests/capturas_bloco72.gd` tira
  fotos + medidas de 13 vistas (rodar COM janela e APPDATA isolado: `-- <pasta de saída>`).
- `e89b6e67` (1) densidade: 51 objetos do Prompt 14 registrados; `NivelMina.decoracao_sorteada`.
- `ac8178be` (2) atmosfera por andar. `172079ab` (3) desempenho (vila cheia ~50 FPS).
- `f3a19d64` (4) terra + paredes subindo + espiral. **Rejeitado na forma** pelo Marco: a ideia das paredes
  subindo e da espiral continua; mudam o lugar (debaixo da vila) e o formato (caverna orgânica).
- `e394ccdd` (5) piloto: faixas S4/S5 do corte + rio de lava (`NivelMina.decalques`). Ficou sem aprovação
  formal (o Marco passou direto pra estrutura).
- `9cb3b514` teste do PixelLab: 2 versões do mapa da referência no estilo do jogo (80 gerações).
- `515b5bfa` **mapa do mundo (F2) = a imagem B** (`assets/game/ui/corte/mapa_mundo.png`;
  `NivelMina.mapa_regiao` = região de cada nível na imagem; lista dos andares ao lado; b63/p20 passam).

**Etapa 2 da revisão FEITA (`f8d6c4d1`):** os andares no jogo são cavernas uma embaixo da outra,
debaixo da vila, com o poço do elevador reto (4 gaiolas na vertical da torre) e a espiral ao lado; terra
em volta da coluna. Gerador: `prototipos/camera/arte_iso/mapa/andares.py` (escala K=0,75, contorno da
caverna no `andares.json`); `environment.gd` (`view_ground`, `logic_from_view`, `contorno_do_andar`,
`dentro_da_caverna`, navegação pelo contorno); `iso_view.gd` (`_build_terra` lê terra/poço/espiral do
json; névoa no formato da caverna). Teste `tests/blocos/b72_coluna.gd`. Comparação com a referência:
`docs/arte/bloco72/coluna/comparativo.jpg`. Os saves valem (a lógica dos andares não mudou).
**O Marco conferiu e disse que ainda está muito diferente** (2026-10-03, tarde) e pediu: como resolver
(pode usar Blender e PixelLab), o layout do jogo mais perto da referência, e MAIS ESPAÇO NA VILA pra
construir. Diagnóstico: a referência é um corte de frente (andares = faixas largas e rasas, parede alta
cheia de coisa atrás, empilhadas sem vão); o jogo mostra chão visto de cima (losango), com vão escuro
grande entre andares e paredes lisas. Maquete da proposta no Blender (`prototipos/camera/arte_iso/
blender/coluna_maquete.py`, Blender em `D:/Blender/blender.exe`, roda com `-b -P ... -- <saida.png>`):
`docs/arte/bloco72/maquete/coluna_blender.png` e `comparativo_maquete.jpg`. Plano proposto: andares
viram faixas (chão andável = polígono da faixa na lógica, conteúdo remapeado), arte de cada andar
renderizada no Blender na câmera do jogo + detalhe/pixelização no PixelLab; vila: juntar terraços e
recuar a paliçada.

**O Marco APROVOU a direção da maquete** ("aí sim o mapa tá ficando exatamente como a gente tá querendo")
e pediu a superfície em 3 áreas: floresta | vila (só construção, mais espaço, sem jazida dentro) | uma
área de MINA pequena: montanha com a boca da mina, os minérios iniciais nela; o mineiro muda de função e
põe o minério num vagonete que corre no trilho, sozinho, da boca da mina até o armazém (que fica logo na
frente). Os andares de baixo continuam como na maquete. **Maquete v2 feita** (`coluna_maquete.py`):
`docs/arte/bloco72/maquete/coluna_v2.png`, `superficie_v2_legenda.jpg` (com nomes), `comparativo_v2.jpg`.
Na v2 o poço do elevador foi pra X=34 e as salas acabam em X=31 (abre lugar pra mina à direita).
Minérios na montanha: carvão, cobre e ferro (hoje as jazidas iniciais do jogo são cobre e carvão; o
ferro está no leste) — confirmar com ele. **Esperando o ok do Marco na v2** pra começar a passar pro
jogo (ordem proposta: vila/mina na superfície + vagonete; piloto do S3 jogável; os outros andares).
O que ainda falta (lista em `docs/BLOCO72_MAPA_REFERENCIA.md`, fim):
andares mais juntos (~24 degraus em vez de 36), faixa de galerias de madeira abaixo da superfície,
detalhe nas paredes (lampiões, lava escorrendo, cachoeira descendo, cristais), coluna mais larga
(escala 0,85?).

## Antes do Bloco 72: o documento de melhorias (Blocos 49–71) está CONCLUÍDO
Feitos: 49–58, 60–64, 67–71 + itens de arte (59 já era feito; 65 crianças espera decisão do Marco, que
sugeriu deixar pra depois; 66 tutorial vem depois do balanceamento). Relatório final:
`docs/RELATORIO_MELHORIAS_49_71.md`. Fila sugerida pelo Marco depois do 72: balanceamento numa partida
longa simulada (F3 + telemetria), depois o tutorial (66).

## Ferramentas e cuidados
- PixelLab: tier 3, saldo ~9.200 antes do Bloco 76, que gastou umas 200–300 gerações nas caminhadas de 8 quadros (conferir o saldo; renova 2026-11-02). Esta conta chama o MCP HTTP pela config de
  `~/.claude.json` (`tools/pixellab/pl.py`, `gen.py` em lote, `chars.py` personagens). Arte nova em
  `prototipos/camera/arte_iso/` (fundo70, fundo71, fundo72, mapa_mundo, relevo/fundo71.py, criaturas/fundo.py).
- **`integra.py` regrava todos os PNGs** (pixels iguais, bytes diferentes). Depois de conferir, limpar com
  `git -c filter.lfs.process= -c filter.lfs.clean=cat -c filter.lfs.smudge=cat -c filter.lfs.required=false update-index --refresh`;
  os que já estão no LFS e continuam marcados: comparar os pixels e `git checkout --` neles.
- PNG/GIF/WAV/JPG vão pro Git LFS (`.gitattributes`). Imagem nova precisa de `--import` no Godot antes
  dos testes.
- Heredoc grande com aspas às vezes quebra no Bash desta máquina: gravar o script com a ferramenta de
  escrever arquivo e rodar com `python <arquivo>`.
- Testes: `tests/blocos/*.gd` (um por bloco, registrado em `tests/test_blocos.gd`, linha no TESTING.md);
  rodar sempre com APPDATA/XDG_DATA_HOME/LOCALAPPDATA em `%TEMP%\deep_iron_testes\fake_appdata`. O save
  real do Marco nunca pode mudar por teste. Ele JOGA pelo editor e o save muda junto (05/10: 00:31 manual,
  09:50 autosave/ao fechar), então não adianta fixar md5: se mudou, conferir em `%APPDATA%/Godot/app_userdata/
  project.godot/logs/godot.log` — "Embedded window only supports Windowed mode" = a janela de jogo do editor
  (ele); testes rodam headless ou por -s e SEMPRE em pasta com `fake_appdata` (abortam fora dela). Pra testar com ele: copiar pra uma
  pasta com `fake_appdata` no caminho e copiar pra `user://savegame.json` DEPOIS que a cena abre (abrir partida
  nova manda o save existente pros backups). Godot:
  `D:\DEV\Godot\Godot_v4.7.2-stable_win64.exe`. A tela lógica do jogo é 1280x720 (stretch canvas_items).
- Medidas: `tools/bench_cena.ps1 [-Rapido]` (vila cheia ~20 ms / 50 FPS em 2026-10-03).
- Skills do projeto: 21 em `.claude/skills/` (godot-*, game-feel, create-game-assets...).

Isso existe porque o Marco troca entre duas contas do Claude Code (`marco.luz1994@gmail.com` e
`marcoa.luz@hotmail.com`, essa via `claude-luz` com `CLAUDE_CONFIG_DIR` próprio) quando uma bate o limite.
A conversa não passa de uma pra outra: este arquivo é o resumo.

## Arte (pacote de prompts 0–31) — referência
- `docs/arte/CONTRATO_ARTE.md` (regras fixas de estilo), `docs/arte/INVENTARIO.md` (o que foi gerado e
  gasto), `docs/arte/MAPA_VISAO.md`, `docs/arte/promptNN/` (relatórios),
  `docs/Prompt/deep_iron_prompts_arte_completa.md`.
- Todos os prompts de arte 0–31 feitos. Como a arte entra no jogo: `prototipos/camera/arte_iso/integra.py`
  (`predios`, `bonecos`, `props`, `criaturas`, `fx`) → `assets/game/iso/...` com `.json`;
  `scripts/iso/iso_art.gd`, `iso_bonecos.gd` e `iso_billboard.gd` escolhem o desenho pelo estado do jogo.
- Andares de baixo na vista iso: `prototipos/camera/arte_iso/mapa/andares.py` (+ `espiral.py`) →
  `assets/game/iso/mapa/andar_*.png`, `espiral.png`, `andares.json`; lidos por `environment.gd`
  (`level_of`, `view_ground`, `logic_from_view`) e `iso_view.gd` (`_build_terrain`, `_build_terra`).
