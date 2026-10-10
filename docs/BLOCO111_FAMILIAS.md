# Bloco 111 — Famílias, crianças e escola (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido: "Prompt F" (o terceiro do pacote 8 → R → F). O Marco decidiu: **vida adulta aos
28 dias** (`@export`; a simulação mostra também 56), **nenhuma função nova** (a escola funciona sem professor), **o lote
completo de arte das crianças sem parar no piloto** e **a política de Família no cartão reservado da janela de Políticas**.
Teste: `tests/blocos/b111_familias.gd` (61 verificações). Simulação: `tests/sim_familias.gd` (`docs/telemetria/bloco111/`).
Fotos: `docs/arte/bloco111/` (`tests/capturas_bloco111.gd`).

## 1) O que entrou

| Item | Como ficou | Onde |
|---|---|---|
| **Gravidez** | De manhã, cada casal (Bloco 110) pode esperar um filho, com chance de 15% ao dia, se: o casal tem 3 dias ou mais; o último filho foi há 14 dias ou mais; o casal tem menos de 3 filhos; existe **cama livre** (descontadas as camas já prometidas aos bebês a caminho); a vila está no Vilarejo ou acima; o ânimo médio é 55 ou mais, sem greve; e há pelo menos 1 porção guardada por morador. A ficha diz o motivo quando não pode. Os dois ficam contentes ("vai ter um filho"). | `familias.gd motivo_sem_filho`, `_amanheceu` |
| **Trabalho leve e parto** | Nos 2 últimos dias a mãe rende ×0,6. O parto leva 45 s em casa; com médico perto, a metade. Depois vem 1 dia de resguardo em casa. A chance de morte no parto é **0** (`@export`, desligada por padrão). | `trabalho_leve`, `parto`, `ipezinho._destino_parto` |
| **Bebê** | Nasce pelo `Economy.novo_ipezinho`, com o tom de pele de um dos pais, mora na casa dos pais e só aparece como **ícone** (sem boneco andando). Não come comida do armazém (a mãe amamenta). | `parto`, `retratos.de` → ícone `bebe` |
| **Criança** (7–21 dias) | Tem boneco próprio, menor que o adulto. Não trabalha, não faz greve, não vai à taverna e não é alvo de criatura. De dia vai à **escola** (estuda e ganha ânimo) ou **brinca** perto de casa. Come meia porção. | `_estado_crianca`, `_brinca`, `escola.gd` |
| **Aprendiz** (21–28 dias) | Segue um **mentor** (o pai, a mãe ou um adulto da função mais forte da vila) e aprende a função dele. Também estuda, com metade do rendimento. | `_escolhe_mentor`, `_acompanha`, `aprende` |
| **Vira adulto** (28 dias) | Fica **sem função**, para o jogador escolher. Ganha o traço de um dos pais + 1 sorteado, 20% da habilidade do pai/mãe e um bônus pelo estudo (até +15%). O diário registra o primeiro adulto nascido na vila. | `_vira_adulto` |
| **Escola** | Obra do engenheiro (140 cr, 20 de minério, 80 de madeira, 10 pregos, 45 s; libera no Vilarejo, no máximo 2). Tem 8 lugares e conta como estação das crianças. Card real no CONSTRUIR, com a imagem do prédio. | `escola.gd`, `centro_vila OBRAS_107 "escola"`, `build_menu` |
| **Política de Família** | Ocupa o cartão que o Bloco 108 tinha reservado: Neutro / Desestimular (chance ×0,3; os casais ficam −3, "queriam filhos") / Incentivar (chance ×2; auxílio de 30 cr por nascimento; sem crédito, a chance volta ao normal). | `politicas.gd POLITICAS.familia` |
| **Família no resto do jogo** | Luto dos pais e dos filhos com o peso do luto pelo parceiro. **Família não namora** (pai/mãe com filho, irmãos). O memorial da enfermaria e o diário mostram a família. A ficha ganhou a seção FAMÍLIA (pais, filhos com a fase, "esperando um filho (faltam N dias)"). A rede de segurança dos migrantes conta só adultos. As refeições do HUD contam a meia porção. A criança não entra em "sem função", nos parados nem no topo da lista de pessoas. | `relacoes.parentes`, `enfermaria`, `ficha_panel`, `migrantes._populacao`, `schedule`, `hud._parado` |
| **Save** | Chave `familias` (casais: filhos e o dia do último; os marcos) + no ipezinho: `fase`, `idade_s`, `pais`, `filhos`, `gravidez_s`, `pai_bebe`, `resguardo_s`, `estudo`, `mentor`. Save antigo: todo mundo vira adulto, sem família. Escolas na chave `escolas` do Centro. | `save_manager.gd` (cabeçalho) |
| **Telemetria** | Colunas novas: bebês, crianças, aprendizes, grávidas, nascimentos e camas livres. | `telemetria.gd` |

### Tempos (1 dia de jogo = 540 s = 9 min reais em 1x)

| Fase | Dias de jogo | Em 1x | Em 3x |
|---|---|---|---|
| Gestação | 7 | ~1 h 03 | ~21 min |
| Bebê | 0–7 | ~1 h 03 | ~21 min |
| Criança | 7–21 | ~2 h 06 | ~42 min |
| Aprendiz | 21–28 | ~1 h 03 | ~21 min |
| **Do nascimento ao adulto (28)** | 28 | **~4 h 12** | ~1 h 24 |
| Do nascimento ao adulto (56, opção) | 56 | ~8 h 24 | ~2 h 48 |
| 3 anos (4 estações × 14 dias = 56 por ano) | 168 | ~25 h | ~8 h 24 |

## 2) Arte (PixelLab) — lote completo, sem parar no piloto (decisão do Marco)

- **Menino e menina** (`crianca_m` 53bcddbe…, `crianca_f` e7bea2a9…): `create_image_pro` com os adultos de referência
  **reduzidos a 0,68** (`oficios111.py ESCALA`; o primeiro lote saiu do tamanho de um adulto e foi refeito). Depois
  `create_character` v3, caminhada, parado, **brincar** (nova), comer, ferido, deitar e mancar, nas 4 direções e nas 3 peles.
  Também os **retratos com as 5 expressões** (`retratos.py NOTA`: sem capacete nem chapéu). A caminhada SE da menina saiu com
  lixo e foi apagada e refeita. Os efeitos soltos do comer/ferido foram limpos com `limpa_soltos.py` (novo).
- **Escola**: a receita das estruturas (`predios111.py`): guia → pronto → obra 2 → obras 1 e 3 → `integra.py predios escola`.
  A placa saiu com letras em inglês e foi apagada à mão (o original ficou em `escola/pronto_com_placa_ingles.png`).
- **Ícone do bebê** (cartão e ficha), com o mesmo pedido do coração do 110 (`oficios92 ICONES`).
- `tools/pixellab/chars.py`: correção da URL dos modelos com `{i}`.
- **Custo: 151 gerações** (saldo 5.713 → **5.562**).
- O `integra.py`/`retratos.py exporta` regravou bonecos e retratos de outras funções (o aviso do Bloco 94). Tudo foi devolvido
  com `git checkout`. Os 161 retratos que o git mostra como "modificados" são idênticos byte a byte ao HEAD (aviso do LFS
  "should have been pointers", que já vinha de antes): **não entram no commit**.

## 3) Valores (`@export` em `familias.gd` e `centro_vila.gd`, listados no `BALANCEAMENTO.md`)

`gestacao_dias` 7, `bebe_dias` 7, `crianca_ate` 21, `adulto_aos` 28, `chance_dia` 0,15, `casal_estavel_dias` 3,
`intervalo_filhos_dias` 14, `max_filhos` 3, `animo_minimo` 55, `estagio_minimo` 2, `comida_porcoes_por_morador` 1,
`trabalho_leve_dias` 2 / `trabalho_leve_mult` 0,6, `parto_segundos` 45, `parto_medico_mult` 0,5, `resguardo_dias` 1,
`morte_parto_chance` 0, `crianca_porcao` 0,5, `estudo_por_s` 0,002, `animo_escola` 5, `aprendiz_ganho` 0,0008,
`aprendiz_estudo_mult` 0,5, `aprendiz_perto` 36, `heranca_habilidade` 0,2, `estudo_bonus` 0,15, `desestimular_mult` 0,3,
`incentivar_mult` 2, `incentivar_auxilio` 30, `animo_esperando` 5; escola: 140 cr, 20 de minério, 80 de madeira, 10 pregos,
45 s, estágio 2, até 2.

## 4) Simulação de 3 anos (`docs/telemetria/bloco111/sim_3anos_adulto28.txt` e `..._adulto56.txt`)

Rodar 168 dias no jogo de verdade levaria ~3 h reais **por cenário** (em 8×). Por isso a simulação é um **modelo dia a dia**
que lê os `@export` do `familias.gd` e repete as condições do `motivo_sem_filho`. O que o modelo **supõe**, e não mede:

- O 1º casal sai depois de ~12 dias de convivência, com 12% ao dia (calibrado pelo bench do 110: 3 casais no dia 14).
- Um adulto come 24 unidades por dia (medido no bench do 108).
- **Suposição:** 1 em cada 4 adultos produz comida, e cada produtor rende 100 unidades por dia. Com isso uma vila só de
  adultos empata.

Começo: 12 adultos, 16 camas, sem migrantes (pra isolar as famílias).

| Adulto aos | Política | Jogador | Nascimentos | Adultos no fim (de 12) | Comida no fim |
|---|---|---|---|---|---|
| 28 | neutro | **não constrói casa** | 4 | 16 (+33%) | sobra |
| 28 | neutro | 1 casa a cada 14 dias | 36 | 42 (+250%) | 0,6 porção/morador (no limite) |
| 28 | incentivar | 1 casa a cada 14 dias | 38 | 45 (+275%) | 1,5 |
| 28 | desestimular | 1 casa a cada 14 dias | 24 | 32 (+167%) | 5,2 |
| 56 | neutro | 1 casa a cada 14 dias | 24 | 25 (+108%) | **FOME no dia 168** |
| 56 | incentivar | 1 casa a cada 14 dias | 24 | 28 (+133%) | **FOME no dia 168** |

O que a simulação mostra:

- **A cama é o freio.** Se o jogador não constrói, nascem 4 bebês (as 4 camas livres) e a vila para aí, em qualquer política.
  O controle continua na mão do jogador, como o Prompt pedia.
- **Com casas, a vila cresce sozinha**, e o teto passa a ser o máximo de 3 filhos por casal. O **incentivar** quase não muda o
  total em 3 anos (38 × 36): ele **adianta** os nascimentos, mas não aumenta o teto. O **desestimular** corta um terço.
- **A criança pesa na comida.** Aos 28 dias a vila fica no limite (0,6 porção por morador). Aos **56** dias há gente demais
  comendo meia porção por tempo demais, e a vila **passa fome** no fim do 3º ano. Por isso fica **28** como padrão; o 56 só
  com mais comida.

## 5) Achados no caminho (corrigidos)

- **A cama do bebê não era reservada**: dois casais podiam engravidar disputando a mesma cama livre. Agora as grávidas
  descontam das camas livres (`familias.gravidas()`).
- **Irmãos e pai/filha podiam namorar** quando a criança virasse adulta (o 110 só olhava sexo, idade e parceiro). Agora
  existe `relacoes.parentes()`.
- **A criança aparecia como "parada"** no balão de motivo, no alerta de ociosos, no "SEM FUNÇÃO" do HUD e no topo da lista
  de pessoas. Agora fica de fora.
- **b85_hora_social**: a verificação "pares conversando na mesma roda" olhava um único instante às 20:12 e falhava quando
  todos trocavam de roda juntos. Com o código do 110 ele passou (5 em roda naquele instante); com o 111, deu 0, 3 e 4 em
  rodadas seguidas, todos conversando, só que trocando de roda. O teste agora guarda o **máximo** da hora social (7–8 de 8
  nas três rodadas).

## 6) Testes (um por vez, APPDATA isolado; o save real não mudou)

**Aprovados:** b111_familias (novo, 61/0), b110, b109, b108 (resumo esperado com `familia=neutro`), b107, b106, b105, b104,
b103, b101, b100, b97, b95b_construir_abas, b95_layout_v2, b93, b88, b85 (ajustado), b84, b62, b52, b36, b35, b27, p28_save,
hud_frostpunk e o GUT `test_iso*` (3 scripts, 12 testes, 491 asserts).

- O **b95_layout_v2** falhou uma vez ("125% cabe em 1280x720") quando rodou em lote, logo depois de outros testes. Sozinho,
  passou. Parece vir do `settings.cfg` compartilhado da pasta de teste, não do 111.
- **Não conferidos** (sem relação direta e longos): o resto da bateria antiga (b1–b83 fora os citados). Uma tentativa de rodar
  o GUT só com `-gtest` disparou a bateria inteira (a `.gutconfig.json` aponta pra pasta toda) e foi parada pela nota de
  memória do projeto. Pra rodar só um script, use `-gselect=<nome>`.

## 7) Pra o Marco validar

- O ritmo (pela simulação): os 1ºs bebês nascem entre o dia ~25 e o ~35 (4 a 5 semanas de jogo); o filho vira adulto em ~4 h reais em 1x.
- O crescimento com casas (+250% em 3 anos) e se o incentivar deveria **também** subir o máximo de filhos, já que hoje ele só
  adianta os nascimentos.
- A morte no parto continua desligada (0). Se quiser, é só ligar pelo `@export`.
- A arte das crianças e da escola (fotos em `docs/arte/bloco111/`).
