# DEEP IRON — Análise do projeto + prompts de melhorias (Blocos 49–66)

Data: 2026-10-02. Complementa `deep-iron-prompts-arte-completa.md` (prompts de arte 0–31). Estes são prompts de **código/jogo** para o Claude Code local, no formato: Contexto → Passo 0 → Implementar → Fora de escopo → Checklist.

## 1. Diagnóstico (o que falta e o que melhorar)

**Saúde do repositório (urgente).** Histórico de 1 commit só ("daa"); `.gitignore` só com padrões do Godot; `.gitattributes` só `* text=auto` (sem LFS); addons pesados e sem uso (LimboAI ~93 MB, GodotSteam ~97 MB) e plugins habilitados sem uso (dialogue_manager, godot_state_charts, godotsteam); sem `export_presets.cfg`; sem CI/script único de testes. Risco: perder trabalho, clone gigante, impossível voltar a um bloco anterior.

**Engenharia/qualidade.** Arquivos grandes (hud.gd ~1200 linhas, defense.gd ~825, save_manager.gd ~754, environment.gd ~690, morale.gd ~625); bug pendente do engenheiro preso após carregar save; sem painel de debug/telemetria para balanceamento; sem passe de performance; sem menu de configurações (só tela cheia); sem i18n; áudio todo procedural (~40 wavs), sem mixer.

**Gameplay pendente.** Casas nível 2/3; Coletor de minério; Oficina construível; trilho + vagonete; pesquisas de explosivos/rádio; fauna com gameplay (javali, coelho, tocas); chefes/tiers de invasores; tela lógica "Corte da mina"; escola/crianças (em espera até a Rota A); tutorial (adiado).

**Arte/integração.** Pipeline PixelLab (prompts 1–27) em chat separado; 28–30 integram; créditos de geração: ~1.439 hoje, +5.000 em 2026-10-30, faltam ~4.650 + ~420 → só o elenco, prédios principais e terreno cabem antes de 30/10.

**Crítica de escopo (honesta).** O redesenho isométrico completo + 18 blocos de gameplay novos é mais do que um dev solo entrega rápido. Recomendação: congelar gameplay novo depois do Bloco 58, fechar a Rota A (arte + integração 28–30), e só então fazer 59–66 conforme a vontade. Tutorial e escola ficam por último.

## 2. Ordem recomendada

| Fase | Blocos | Por quê |
|---|---|---|
| A. Fundação | 49, 50, 51 | Proteger o trabalho, build rodando, bug conhecido |
| B. Ferramentas | 52, 53, 54, 55 | Balancear, performar, configurar, áudio |
| C. Gameplay | 56, 57, 58 | Backlog já combinado |
| D. Spike | 59 | Testar motor isométrico sem arte, em branch |
| E. Gameplay extra | 60–64 | Só depois da Rota A |
| F. Fecho | 65, 66 | Tutorial e QA |

Protocolo entre chats: **um commit por bloco** (`bloco-NN: resumo`), branch própria para 59 e para a integração 28–30, e o chat de gameplay avisado de que o chat de arte gera em paralelo em `prototipos/camera/arte_iso/`.

---

## Bloco 49 — Saúde do repositório

### Contexto
Repositório com 1 commit, sem LFS, com addons gigantes e sem uso. Antes de qualquer outro bloco, deixar o repo seguro e leve.

### Passo 0 — Revisão
- Listar tamanho de cada pasta de `addons/` e dizer quais são realmente usados (grep de uso no código/cenas). Confirmar LimboAI, GodotSteam, dialogue_manager, godot_state_charts, phantom_camera, gut.
- Listar quais plugins estão habilitados em `project.godot` e quais autoloads dependem deles.
- Medir tamanho do `.git` e dos maiores arquivos binários (PNG/GIF/WAV/OGG).
- **Não apagar nada antes de reportar a lista.** Fazer commit de checkpoint antes de mexer.

### Implementar
- Commit de checkpoint do estado atual; depois um commit por mudança.
- `.gitignore`: `.godot/`, `*.import` não (manter os `.import`), `__pycache__/`, `*.pyc`, `.mono/`, builds (`build/`, `export/`), saves locais, `*.tmp`.
- `.gitattributes`: manter `text=auto`; adicionar Git LFS para `*.png`, `*.gif`, `*.wav`, `*.ogg`, `*.mp3`, `*.psd`, `*.aseprite` (e migrar o histórico atual só se for seguro; senão, só dali pra frente).
- Remover do projeto os addons sem uso (LimboAI, GodotSteam) e desabilitar/remover plugins sem uso (dialogue_manager, godot_state_charts) **somente se** o Passo 0 confirmar zero referência. Autoload `DialogueManager` só sai se nada o usa.
- Remover pastas demo/example de addons mantidos.
- Adicionar `README.md` curto (como abrir, como rodar testes, estrutura de pastas) e `docs/PROCESSO.md` (um commit por bloco, branches de integração, onde ficam as ferramentas).
- Rodar toda a suíte GUT depois de cada remoção.

### Fora de escopo
Reescrever histórico antigo, mudar código de jogo, mexer em arte.

### Checklist
- [ ] Relatório do Passo 0 (tamanhos, usados × não usados).
- [ ] Jogo abre e roda; GUT 100% igual ao de antes.
- [ ] Tamanho do repo caiu e o relatório mostra quanto.
- [ ] LFS configurado; novo PNG adicionado vira ponteiro LFS.
- [ ] README e PROCESSO.md existem.

---

## Bloco 50 — Export, build e script único de testes

### Contexto
Não há `export_presets.cfg` nem forma simples de gerar um executável ou rodar tudo de uma vez.

### Passo 0
Confirmar versão exata do Godot e se há templates de exportação instalados; revisar `TESTING.md` e `tests/test_blocos.gd` (cada bloco roda em processo isolado).

### Implementar
- `export_presets.cfg` para Windows desktop (`build/windows/DeepIron.exe`), sem embutir `tests/` nem `tools/` nem `docs/` (filtro de exclusão).
- Script `tools/run_tests.(ps1|sh)` que roda a suíte GUT headless e sai com código ≠0 se falhar; documentar em `TESTING.md`.
- Script `tools/build_windows.(ps1|sh)` que exporta e roda um teste de fumaça (abre, carrega menu, fecha).
- Workflow opcional do GitHub Actions (`.github/workflows/tests.yml`) que roda GUT em container Godot 4.7.x; marcar como opcional se o runner não tiver o binário.
- Verificar que o build não escreve no save real e que `SAVE_VERSION` aparece no log.

### Fora de escopo
Steam, assinatura de código, instalador, outras plataformas.

### Checklist
- [ ] `run_tests` passa localmente.
- [ ] Exe gerado abre, mostra menu, inicia partida, salva e carrega.
- [ ] Build não contém `tests/`.
- [ ] (Se feito) CI verde.

---

## Bloco 51 — Bug: engenheiro preso após carregar + teste de estresse

### Contexto
Pendência do Bloco 37: após carregar um save, o engenheiro pode ficar preso (visto 2 de 15 vezes).

### Passo 0
Revisar estado do engenheiro (fila de obras, alvo, estado de movimento, ordem de carga no `SaveManager`) e o que é restaurado antes/depois dos prédios/obras. Listar hipóteses (referência a obra ainda não instanciada, alvo salvo como nó, race na mesma frame).

### Implementar
- Teste de estresse automatizado: N ciclos (≥50) de salvar/carregar com obras em vários estágios, engenheiro em cada estado (parado, indo, construindo, voltando) e verificar que ele retoma ou reassume a próxima obra em X segundos.
- Corrigir a causa raiz (salvar alvo por id/posição e resolver depois do mundo carregado) e adicionar *watchdog*: se parado com obra pendente por >`@export` segundos, reatribuir.
- Log de depuração quando o watchdog age.

### Fora de escopo
Reescrever o save inteiro, aumentar `SAVE_VERSION` sem necessidade (se subir, manter leitura tolerante de v4).

### Checklist
- [ ] Reproduz o bug (ou explica por que não reproduz) e o teste de estresse passa 50/50.
- [ ] Save antigo (v4) ainda carrega.
- [ ] Watchdog só age em caso real, sem falsos positivos em jogo normal.

---

## Bloco 52 — Painel de debug e telemetria para balanceamento

### Contexto
Marco vai fazer uma passada de balanceamento; hoje não há como acelerar o tempo, injetar recursos ou ver métricas.

### Passo 0
Revisar onde ficam recursos, relógio, moral, defesa, pesquisa; se existe alguma ferramenta de debug já.

### Implementar
- Painel de debug (tecla `F3`, só em build de editor/debug): acelerar tempo (x1/x4/x16), adicionar créditos/minério/madeira, pular dia/estação, disparar invasão, curar tudo, liberar pesquisa.
- Telemetria leve: a cada dia do jogo, registrar em CSV (`user://telemetria/`) créditos, minério por tipo, população, moral, mortes, invasões, pesquisas feitas, tempo de jogo real.
- Relatório resumido `tools/resumo_telemetria.py`: curva de recursos, dias sem lucro, picos de morte.
- Tudo `@export`/constantes de balanceamento reunidas em um único recurso (`Balance.tres`) **se** o Passo 0 mostrar valores espalhados; senão apenas listar onde estão em `docs/BALANCEAMENTO.md`.

### Fora de escopo
Mudar valores de balanceamento (isso é com Marco), analytics online.

### Checklist
- [ ] Painel não aparece em build de release.
- [ ] CSV gerado corretamente numa partida de 10 dias.
- [ ] `docs/BALANCEAMENTO.md` lista onde mexer em cada valor.

---

## Bloco 53 — Passe de performance

### Contexto
Muitos ipezinhos, luzes, clima, partículas e zoom. Hoje não há medição.

### Passo 0
Medir FPS, tempo de frame, nº de nós e draw calls em 3 cenários (início, vila média 15 ipezinhos, vila cheia + invasão + chuva + noite). Reportar top 5 custos (Profiler).

### Implementar
- Corrigir apenas os 3–5 piores gargalos achados (ex.: `_process` em tudo → timers/sinais, buscas por grupo todo frame, luzes 2D, partículas, `queue_redraw` excessivo).
- Meta: 60 FPS estáveis na vila cheia em máquina média (reportar a máquina).
- Adicionar teste/benchmark simples (`tools/bench_cena.gd`) reproduzível.

### Fora de escopo
Otimizar arte, trocar de renderer, multithread.

### Checklist
- [ ] Tabela antes × depois nos 3 cenários.
- [ ] Nenhum comportamento mudou (GUT igual).
- [ ] Benchmark documentado.

---

## Bloco 54 — Configurações, acessibilidade e base de idioma

### Contexto
Só existe tela cheia (F11/Alt+Enter). Faltam volume, escala de UI, remapeamento e base para tradução (pt-BR e en).

### Passo 0
Ver como o `Audio` autoload controla volumes/buses, como a HUD define tamanhos de fonte, onde está o `settings.cfg` do Bloco 48 e quantas strings de UI estão hardcoded.

### Implementar
- Tela **Configurações** (do menu inicial e pause): volume mestre/música/efeitos, tela cheia, escala da UI (80–150%), velocidade de pan/zoom, remapeamento das teclas principais, opção de reduzir efeitos (clima/tremor).
- Persistir em `settings.cfg`, aplicar ao abrir.
- Base de i18n: mover strings da UI/HUD e dos principais painéis para `translations/*.csv` (pt_BR padrão, en como segunda); trocar de idioma em Configurações. Não precisa traduzir 100% de cara — marcar o que falta.
- Fontes: garantir acentos corretos.

### Fora de escopo
Traduzir diálogos/eventos longos, gamepad, outros idiomas.

### Checklist
- [ ] Todas as opções persistem e se aplicam ao reabrir.
- [ ] Trocar idioma atualiza a UI sem reiniciar (ou avisa se precisar).
- [ ] Remapear uma tecla funciona e restaurar padrão também.
- [ ] Escala de UI não corta painéis em 1280×720.

---

## Bloco 55 — Passe de áudio

### Contexto
~40 sons procedurais + `music_loop` + `cave_ambience`, sem mixer nem variedade.

### Passo 0
Mapear cada evento do jogo → som atual; listar eventos sem som (obra, colheita, festa, greve, alarme de invasão, equipamentos, clima, UI) e se existem buses (Master/Música/SFX/Ambiente).

### Implementar
- Buses e mixer ligados às Configurações do Bloco 54.
- Preencher os eventos sem som usando `tools/gen_audio.py` (ou variações dos existentes), com pitch aleatório leve para não repetir.
- Ambiência por contexto: superfície dia/noite/chuva, mina, nível 2/abismo; música com pelo menos 2 faixas e *crossfade* (calma × perigo na invasão).
- Limite de vozes simultâneas para não saturar.

### Fora de escopo
Compor música original, dublagem.

### Checklist
- [ ] Tabela evento→som sem lacunas.
- [ ] Música muda para perigo na invasão e volta.
- [ ] Sliders do mixer funcionam.
- [ ] Sem estouro/clipping com 15 ipezinhos trabalhando.

---

## Bloco 56 — Casas nível 2 e 3

### Contexto
Casas são colocáveis e abrigam ipezinhos; Marco quer evolução.

### Passo 0
Revisar o script/cena da casa, capacidade de camas, custo, moral/conforto e como o menu de construção e o engenheiro tratam upgrades (se existe padrão de melhoria, como no Centro da Vila).

### Implementar
- Upgrade da casa para N2 e N3: capacidade de camas (`@export`), conforto/moral (bônus), custo crescente em créditos+minério+madeira, tempo de obra pelo engenheiro, pré-requisito de pesquisa (ex.: ramo Vila).
- Arte provisória por tinta/variação (a definitiva vem do prompt de arte de prédios); pontos de ancoragem e área de clique preservados.
- Persistir nível no save (leitura tolerante: ausente = 1).
- Atualizar o menu/tooltip com o próximo nível e custo.

### Fora de escopo
Casas diferentes por tipo, famílias/crianças.

### Checklist
- [ ] Upgrade consome recursos e usa o engenheiro.
- [ ] Capacidade e moral mudam como configurado.
- [ ] Save/load preserva nível; save antigo carrega como nível 1.
- [ ] Sem pesquisa, o upgrade fica bloqueado com motivo visível.

---

## Bloco 57 — Coletor de minério

### Contexto
Estrutura análoga ao Coletor de madeira (Bloco 45), mas para minério de superfície/afloramentos; **a Escavadeira não tem operador** — o padrão de operador vem de Campo de treino/Taverna/Arsenal.

### Passo 0
Rever Coletor de madeira, Escavadeira e como minério avulso é coletado; decidir onde pode ser posto (próximo de jazidas/afloramentos) e se os ipezinhos mineradores manuais continuam úteis.

### Implementar
- Prédio construível (engenheiro), múltiplas unidades, custo crescente `@export`.
- Opera com um minerador alocado; produz minério do tipo da jazida mais próxima/escolhida, com taxa `@export`, parando se não há operador ou jazida.
- Desgaste/manutenção opcional só se já existir padrão; senão fora.
- Persistência de posição, operador e acumulado.

### Fora de escopo
Substituir mineração manual, trilho/vagonete.

### Checklist
- [ ] Constrói, aloca, produz e para ao remover o operador.
- [ ] Jazida esgotada → para sem erro.
- [ ] Save/load preserva tudo; menu mostra "pode ter vários" e custo atual.

---

## Bloco 58 — Oficina construível

### Contexto
A Oficina hoje está fixa na cena e é única. Marco quer poder construí-la.

### Passo 0
Ver o que a Oficina faz hoje (reparo de equipamento/armas?), quais sistemas a referenciam e se ela deve continuar única ou ter várias (decidir e justificar).

### Implementar
- Oficina vira prédio construível pelo engenheiro (fundação + custo + menu), mantendo todas as funções atuais.
- Saves antigos com a Oficina fixa migram sem perder estado (a instância fixa passa a ser "já construída" na mesma posição).
- Arte provisória; ancoragem preservada.

### Fora de escopo
Novas funções da Oficina, fabricação de itens novos.

### Checklist
- [ ] Novo jogo: Oficina só aparece depois de construída.
- [ ] Save antigo mantém Oficina funcionando.
- [ ] Funções de reparo seguem iguais.

---

## Bloco 59 — Spike do motor isométrico (sem trocar a arte) — **em branch**

### Contexto
Prompt 28 do pacote de arte é o maior risco do projeto. Este spike testa a Rota A com arte provisória antes de gastar créditos de geração.

### Passo 0
Revisar `docs/escala_visual/ISOMETRICO_viabilidade.md`, `CONTRATO_ARTE.md`, como posições, y_sort, cliques, câmera e `Camera`/PhantomCamera trabalham hoje. **Branch `rota-a-spike`; não tocar na `main`.**

### Implementar
- Camada de projeção: lógica cartesiana → tela `(x−y, (x+y)/2)`; inversa para mouse; ordenação por caixas (footprint + altura).
- Rodar o mundo atual com sprites quadrados como *placeholder* em losangos, só para provar: clique, seleção, construção, caminhada, ordenação e câmera.
- Medir custo/risco e listar tudo que quebra (colisão, áreas de clique, UI flutuante, partículas, luz).
- Relatório: viável/inviável, lista de arquivos a mudar, estimativa de blocos.

### Fora de escopo
Qualquer arte nova, merge na main, migração de saves.

### Checklist
- [ ] Mundo roda em projeção isométrica com placeholders.
- [ ] Clique, construção e caminhada funcionam.
- [ ] Relatório de quebras com lista priorizada.
- [ ] `main` intocada.

---

## Bloco 60 — Pesquisas: explosivos e rádio

### Contexto
Itens do inventário (explosivos, antena) sem gameplay.

### Passo 0
Rever árvore de pesquisa (Mina/Vila/Sol), usos de minério pesado, galerias lacradas e o satélite.

### Implementar
- Pesquisa **Explosivos**: dinamite para abrir galerias lacradas/rochas duras, consumível, risco `@export` de acidente sem treino.
- Pesquisa **Rádio/Antena**: aviso antecipado de invasão (segundos `@export`) e bônus para o satélite.
- Custos/tempos `@export`; persistência no save.

### Fora de escopo
Novas áreas de mapa, balanceamento fino.

### Checklist
- [ ] Pesquisas aparecem no ramo correto e bloqueiam/liberam corretamente.
- [ ] Dinamite abre galeria lacrada e é consumida.
- [ ] Aviso de rádio dispara antes da invasão.
- [ ] Save/load preserva estado.

---

## Bloco 61 — Fauna com gameplay

### Contexto
Javali, coelho e tocas existem só como ideia/arte.

### Passo 0
Ver como caçador, comedouros e cozinheiro consomem carne hoje e como animais já aparecem (se aparecem).

### Implementar
- Coelhos (caça fácil, pouca carne) e javalis (perigosos, mais carne, podem ferir caçador sem equipamento); tocas como pontos de reaparecimento com taxa `@export` e limite de população.
- Sazonalidade (menos caça no inverno) ligada ao sistema de estações.
- Persistência de animais/tocas.

### Fora de escopo
Domesticação, criação em currais.

### Checklist
- [ ] Animais surgem, vagam e podem ser caçados.
- [ ] Javali ferir caçador despreparado aciona o médico.
- [ ] Limite populacional respeitado; save/load ok.

---

## Bloco 62 — Invasores: tiers e chefe

### Contexto
Lumívoros e Ferrugentos existem; falta curva de dificuldade e clímax.

### Passo 0
Revisar defense.gd, spawn, desgaste de armas, guarda caído, roubo pela brecha; ler o conceito de criaturas no pacote de arte (prompts 16–17).

### Implementar
- Tiers de onda por dia/pesquisa (`@export`), nova criatura de elite e **chefe** (uma vez por estação avançada) com mecânica própria simples (ex.: corrói armadura, atrai Ferrugentos).
- Recompensa do chefe (minério raro/pesquisa).
- Telemetria (Bloco 52) registra resultado das ondas.

### Fora de escopo
Arte final (placeholder até o prompt 17), campanha/narrativa.

### Checklist
- [ ] Ondas escalam; chefe aparece e pode ser derrotado.
- [ ] Derrota/vitória do chefe persiste no save.
- [ ] Sem softlock se todos os guardas caem.

---

## Bloco 63 — "Corte da mina" (lógica da tela)

### Contexto
Tela de corte lateral da mina (checkpoint de arte 25). Independente do motor isométrico.

### Passo 0
Rever como níveis, galerias, reatores, abismo e Escavadeira são representados em dados.

### Implementar
- Tela/painel lateral que mostra níveis, galerias abertas/lacradas, reatores, escavadeira, ipezinhos por nível e perigos (gás/radiação/calor), clicável para focar a câmera.
- Dados lidos do estado do jogo; arte provisória.

### Fora de escopo
Arte final, edição do mapa por essa tela.

### Checklist
- [ ] Reflete o estado real e atualiza em tempo real.
- [ ] Clique foca o ponto no mapa.
- [ ] Sem custo de frame perceptível (Bloco 53).

---

## Bloco 64 — Trilho e vagonete

### Contexto
Transporte de minério por trilho (item do inventário).

### Passo 0
Rever como o minério chega ao armazém hoje e o custo de caminhada dos carregadores.

### Implementar
- Trilhos construíveis entre pontos da mina e o armazém; vagonete automático com capacidade/velocidade `@export`; manutenção mínima.
- Reduz viagens manuais; persistência de trilhos e carga.

### Fora de escopo
Rotas complexas/ramificadas, sinais.

### Checklist
- [ ] Liga A→B e transporta minério sem ipezinho.
- [ ] Trilho quebrado/incompleto não trava a logística.
- [ ] Save/load ok.

---

## Bloco 65 — Escola e crianças (**só depois da Rota A integrada**)

### Contexto
Em espera. Não iniciar antes das prompts 28–30.

### Passo 0
Decidir com Marco: crianças nascem? crescem? só visual? Reportar opções e custo antes de codar.

### Implementar (após decisão)
- Escola, crianças como população futura que vira trabalhador, impacto em moral e custo de alimento.

### Fora de escopo
Tudo antes da decisão.

### Checklist
- [ ] Decisão registrada no dev log antes do código.

---

## Bloco 66 — Tutorial e onboarding (**adiado**)

Usar o arquivo `prompt_bloco41_tutorial_onboarding.md` já escrito; só executar quando mecânicas estabilizarem (depois de 56–58 e da Rota A).

---

## 3. Arte: sequência com orçamento de créditos

- Agora (≈1.439): terreno superfície (6), elenco base (1) e Centro da Vila/Armazém/Casas (10).
- A partir de 30/10 (+5.000): demais prédios, máquinas, jazidas, vegetação, animais, efeitos, UI.
- Checkpoints de aprovação visual de Marco obrigatórios nos prompts 16, 20, 22, 25, 26, 27.
- Integração 28→29→30 só com a arte principal pronta; fazer **antes** o Bloco 59.

# DEEP IRON — Mapa ampliado e níveis temáticos (referência "World Map" em camadas)

Referência: imagem de mapa isométrico com superfície (vila, floresta, encosta) + 5 subsolos temáticos (mina comum, ácido, lava+escavadeira, cachoeira+lava, lago azul), rampa em espiral central, kit de assets, vista explodida em 5 camadas e composição A→D.

## Leitura honesta da referência
- É **arte conceitual**: serve de norte visual e de planta vertical, não de especificação pixel a pixel. "Ficar igual" depende da Rota A (arte isométrica, prompts 1–30 do pacote de arte). Isso não muda.
- O que dá para fazer **agora, sem arte nova**: aumentar o mundo, estruturar os níveis temáticos, sistema de camadas/atmosfera por nível e a rampa/elevador entre níveis. A arte entra depois por troca.
- Hoje o jogo tem superfície + mina nível 1 + nível 2 + abismo. A referência pede 5 subsolos. Proposta de mapeamento: S1 mina comum, S2 ácido (gás → traje de gás), S3 lava (calor → traje de calor, escavadeira/reatores), S4 cachoeira + lava (mistura), S5 lago/cristais azuis (radiação/fim de jogo). Isso reaproveita os trajes e perigos já existentes. **Corte de escopo recomendado:** entregar S1–S3 primeiro; S4–S5 só depois da Rota A.
- Pontes de corda, igreja, torre do relógio, guindaste de ponte: arte/decoração, não gameplay. Ficam nos prompts de arte.

## Ordem
1. Bloco 67 — Ampliar a área da superfície e da mina (código, agora)
2. Bloco 68 — Sistema de níveis temáticos + rampa/elevador (código, agora)
3. Bloco 69 — Camadas de render e atmosfera por nível (código, agora)
4. Bloco 70 — Conteúdo dos níveis S2–S3 (depois de 67–69)
5. Bloco 71 — Conteúdo S4–S5 (só depois da Rota A)
6. Itens de arte novos (ver fim) para o chat do PixelLab

---

## Bloco 67 — Ampliar o mapa (superfície e mina)

### Contexto
Marco quer um mapa bem maior onde construir e explorar, no espírito da referência (vila grande, floresta, encosta, vários andares). Sem trocar arte e sem quebrar saves.

### Passo 0 — Revisão (reportar antes de codar)
- Tamanho atual do mundo (superfície, cada nível da mina), limites da câmera, área construível, onde o tamanho está hardcoded (câmera, posicionador de obras, nevoeiro/exploração, chão/textura, navegação/pathfinding, minimapa, spawn de invasões, clima, luz).
- Como o chão é desenhado (textura repetida? TileMap?) e custo por tamanho.
- Medir FPS e nº de nós no tamanho atual e estimar o custo de 2x, 3x e 4x a área.
- Como o save guarda posições (absolutas?) para garantir compatibilidade.

### Implementar
- Centralizar o tamanho do mundo em constantes/`@export` por nível (`world_size_surface`, `world_size_mine_N`), nada hardcoded.
- Ampliar a superfície (proposta: ~3x em área) mantendo a vila original no **mesmo lugar** (coordenadas antigas válidas); expandir com zonas: vila (centro), floresta, encosta rochosa, e área de entrada da mina.
- Ampliar o limite da câmera, a área em que o posicionador permite construir, a navegação, o chão e as bordas.
- Liberar a nova área por **exploração/nevoeiro ou por pesquisa/expansão paga** (`@export`), para não esvaziar a sensação de progressão; decidir no Passo 0 o que combina com o sistema de exploração existente.
- Spawn de invasões, clima, luz e comedouros/caça respeitando os novos limites.
- Se o tamanho exigir, dividir o chão em chunks/TileMapLayer só onde necessário.

### Fora de escopo
Nova arte, novos prédios, novos níveis de mina, motor isométrico.

### Checklist
- [ ] Relatório do Passo 0 e FPS antes/depois (vila cheia).
- [ ] Save antigo carrega com tudo no lugar certo.
- [ ] Construir na área nova funciona (obra, engenheiro, caminhada, clique).
- [ ] Câmera para nas bordas novas; sem buracos no chão.
- [ ] Invasões, clima e noite funcionam na área ampliada.
- [ ] GUT igual ao anterior.

---

## Bloco 68 — Níveis temáticos e rampa/elevador

### Contexto
A referência tem vários subsolos empilhados com identidade própria e uma rampa em espiral central ligando tudo. Hoje existe superfície + 2 níveis + abismo.

### Passo 0
Revisar como os níveis, galerias lacradas, reatores e abismo são representados (cena por nível? dados?), como ipezinhos trocam de nível, e onde ficam perigos/equipamentos (Bloco 42). Propor como adicionar níveis sem duplicar código.

### Implementar
- Definição de nível por dados (recurso `NivelMina`): id, nome, tamanho, perigo (nenhum / gás / calor / radiação / água), traje exigido, paleta/atmosfera, minérios que aparecem, criaturas, requisitos de pesquisa, profundidade.
- Níveis S1–S3 como dados (S1 existente, S2 ácido/gás, S3 lava/calor), S4–S5 declarados mas **bloqueados** como "em breve".
- Ligação entre níveis: **rampa/elevador central** (construível, custo `@export`, engenheiro), capacidade e tempo de viagem; ipezinhos usam sozinhos para trabalhar no nível.
- Desbloqueio de cada nível por pesquisa + traje (reaproveitar as zonas de perigo existentes).
- Persistir nível atual de cada ipezinho, estado das rampas e níveis liberados (leitura tolerante).
- Tela do "Corte da mina" (Bloco 63) lê essa definição.

### Fora de escopo
Conteúdo detalhado de cada nível (Bloco 70), arte final.

### Checklist
- [ ] Novo nível vira só um recurso de dados, sem copiar script.
- [ ] Rampa liga superfície↔S1↔S2↔S3 e ipezinhos a usam.
- [ ] Nível sem traje/pesquisa fica bloqueado com motivo visível.
- [ ] Save/load preserva tudo; save antigo carrega.

---

## Bloco 69 — Camadas de render e atmosfera por nível

### Contexto
A referência organiza o desenho em Camadas 0–4 (fundo/atmosfera, terreno estático, detalhes, sprites dinâmicos, VFX/luz) e a composição A→D (base, detalhes, ativos, efeitos). Deixar o jogo organizado assim agora facilita a Rota A.

### Passo 0
Mapear a ordem de desenho atual (CanvasLayers, z_index, y_sort, luz, clima) e onde cada coisa vive hoje.

### Implementar
- Convenção de camadas documentada em `docs/arte/CAMADAS.md` e aplicada: 0 fundo/céu, 1 terreno, 2 detalhes (árvores, rochas, decoração), 3 dinâmicos (ipezinhos, criaturas, máquinas), 4 VFX/luz.
- **Atmosfera por nível** (dados do Bloco 68): cor de luz ambiente, brilho de poças/lava/cristais (luzes 2D piscando de leve), névoa/partículas (ácido verde, calor laranja, bolhas/água azul), intensidade configurável e desligável (Configurações, Bloco 54).
- Sistema de decoração por dados: lista de props por nível/zona (tipo, posição, camada) para montar o cenário sem editar cena na mão.
- Respeitar orçamento de luzes/partículas (medir com o Bloco 53).

### Fora de escopo
Trocar sprites, motor isométrico.

### Checklist
- [ ] Cada nível tem atmosfera própria visível mesmo com arte atual.
- [ ] Ordem de desenho segue a convenção; sem sobreposição estranha.
- [ ] Opção de reduzir efeitos funciona; FPS ok na vila cheia.
- [ ] Props de um nível carregam de dados.

---

## Bloco 70 — Conteúdo S2 (ácido) e S3 (lava)

### Contexto
Dar jogo aos dois níveis seguintes, usando perigos e trajes já existentes.

### Passo 0
Rever zonas de perigo, trajes, criaturas, minérios, Escavadeira/reatores, e quais recursos novos fazem sentido.

### Implementar
- S2: poças de ácido (dano/lentidão sem traje de gás), cristais verdes (minério novo ou variante, `@export`), ventiladores construíveis que reduzem o gás, criatura verde própria (placeholder).
- S3: poços de lava (zona de calor), cristais vermelhos, Escavadeira e reatores operando aqui, criatura de lava (placeholder), fumaça/calor.
- Minérios/valores, spawns e perigos por `@export`/dados; telemetria (Bloco 52).
- Integração com pesquisa, equipamento, médico e moral.

### Fora de escopo
S4–S5, arte final, balanceamento fino.

### Checklist
- [ ] Sem traje, os perigos causam dano coerente; com traje, não.
- [ ] Minério novo é vendável e aparece no armazém/HUD.
- [ ] Criaturas do nível aparecem e se encaixam na defesa.
- [ ] Save/load preserva estado dos níveis.

---

## Bloco 71 — S4 (cachoeira + lava) e S5 (lago azul) — só depois da Rota A

Mesma estrutura do 70: água/cachoeira (zona úmida, bônus ou risco), cristais de várias cores, lago subterrâneo como destino final, gemas azuis, casinhas de pedra. Só iniciar com a arte desses ambientes aprovada.

---

## Itens de arte novos (acrescentar ao pacote de arte)

Para o chat do PixelLab, além dos prompts 6–15 já previstos:
- Terrenos de nível: rocha comum, rocha com ácido, rocha com lava, rocha úmida, borda de lago (tileset 2:1).
- Poças de ácido, poços de lava (2 tamanhos), cachoeira, água do lago com reflexo (animado leve).
- Cristais: vermelho, azul, verde, roxo (pequeno/grande).
- Rampa em espiral central (peças modulares), escadas, escadas de mão, passarelas de madeira, pontes de corda, trilhos.
- Ventilador de ventilação, placas de sinalização.
- Igreja, torre do relógio, casas enxaimel (variações dos prédios 10–12).
- Criaturas: monstro de ácido verde e monstro de lava (já em 16–17).
- Orçamento: terrenos de nível e cristais cabem após 30/10 (+5.000 créditos). Cortar primeiro: pontes de corda, igreja e torre do relógio.

## Resumo de recomendação
Fazer 67 → 68 → 69 agora (entregam um mundo maior e níveis com identidade mesmo com a arte atual). 70 depois. 71 só com a Rota A pronta. Commit por bloco; 67 pode mexer em muita coisa, então branch própria.
