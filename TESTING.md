# Testes do DEEP IRON

Os testes ficam em `project.godot/tests/` e rodam pelo **GUT** (já instalado em
`addons/gut`), pelo painel do editor ou pela linha de comando.

## Como funciona

- `tests/blocos/*.gd` — um teste por bloco. Cada um abre a partida inteira
  (`main.tscn`), mexe nela (ordens, save/load, obras…) e imprime `OK` / `FALHOU` e no
  fim `FALHAS: N`. São scripts `SceneTree`, não testes GUT.
- `tests/test_blocos.gd` — o teste **GUT**: um `test_…` por bloco. Cada um roda o
  script do bloco num **Godot headless separado** e confere a saída.
- `.gutconfig.json` (na raiz do projeto) — aponta o GUT pra `res://tests/`.

**O save de verdade nunca é tocado:** o Godot de cada bloco roda com a pasta de
usuário trocada por uma temporária (`%TEMP%/deep_iron_testes/fake_appdata`), e os
próprios testes abortam (`ABORTADO`) se não estiverem nela.

**Leva tempo:** cada bloco joga um pedaço da partida (≈ 1 a 4 min). A bateria
inteira leva uns **15 minutos**. Pra conferir só um bloco, rode só o teste dele.

## Pelo painel do GUT (editor)

1. Abra o painel **GUT** (aba embaixo do editor).
2. Na primeira vez: em **Settings → Directories**, adicione `res://tests`
   (o painel guarda isso por usuário, fora do Git).
3. **Run All** roda todos. Pra um só, abra `tests/test_blocos.gd` e rode o teste
   (ex.: `test_b35_arsenal_desgaste`).
4. Se algum falhar, o painel mostra as linhas `FALHOU` e o fim da saída do bloco.

## Script único (Bloco 50)

Da raiz do repositório, roda a suíte inteira com a pasta de usuário isolada e confere o md5 do save
real antes/depois; sai com **0** se tudo passou, **1** se algum teste falhou, **2** se o save real
mudou, **3** se não achou o Godot:

```
powershell -ExecutionPolicy Bypass -File tools
un_tests.ps1 [-Filtro b35] [-Godot <caminho>]
bash tools/run_tests.sh [b35]          (GODOT_BIN = caminho do Godot)
```

Build do Windows + teste de fumaça (abre, começa partida, salva, carrega, fecha; pasta isolada):

```
powershell -ExecutionPolicy Bypass -File toolsuild_windows.ps1     -> build/windows/DeepIron.exe
```

Precisa dos templates de exportação do 4.7.2 (`%APPDATA%\Godot\export_templates.7.2.stable\`).
O pacote não leva `tests/`, `prototipos/` nem `addons/gut/`. O workflow `.github/workflows/tests.yml`
roda a suíte no GitHub (manual ou em push na `main`; opcional, leva ~1 h).

## Balanceamento (Bloco 52)

- **F3** no jogo (editor ou build de debug): painel com tempo x1/x4/x16, +créditos/minério/madeira/comida,
  pular fase/dia/estação, invasão agora, curar todos, liberar pesquisas. No executável de release
  não existe (o teste de fumaça do build confere).
- **Telemetria:** a cada dia novo, uma linha em `user://telemetria/partida_<data>.csv` (build de debug,
  ou `[debug] telemetria=true` no `settings.cfg`). Resumo: `python tools/resumo_telemetria.py <pasta>`.
- **Onde mexer em cada valor:** `docs/BALANCEAMENTO.md` (gerado por `python tools/lista_balanceamento.py`).

## Desempenho (Bloco 53)

`powershell -ExecutionPolicy Bypass -File toolsench_cena.ps1 [-Rapido]` abre uma janela 1920×1080 sem
vsync e mede 3 cenários (início, vila média, vila cheia + invasão + chuva + noite), o detalhe da HUD e
da vista iso e o custo por script. Resultado em `docs/bench/`; método e antes × depois em
`docs/DESEMPENHO.md`. Não é teste do GUT (precisa de janela e de PC parado).

## Escala da interface em 1280×720 (Bloco 54)

`tests/capturas_escala.gd` (com janela): abre cada janela, o menu de construção, as configurações e
a página de teclas em 80%, 100% e na maior escala que cabe, confere que nada sai da tela e tira fotos
(`<pasta>/escala.txt` + PNGs). Rodar com APPDATA isolado:
`<Godot>.exe --path project.godot -s res://tests/capturas_escala.gd -- <pasta>`.

Fotos da clareira com os bichos (Bloco 61): `tests/capturas_fauna.gd` (com janela, APPDATA isolado).

Fotos da Matriarca e do trilho com o vagonete (Blocos 62/64): `tests/capturas_chefe_trilho.gd`.

Fotos do mapa ampliado (Bloco 67): `tests/capturas_leste.gd`.

## Pela linha de comando

Da pasta `project.godot/` (troque o caminho do Godot pelo seu):

```
# todos
<Godot>.exe --headless --path . -s addons/gut/gut_cmdln.gd

# só um bloco (filtra pelo nome do teste)
<Godot>.exe --headless --path . -s addons/gut/gut_cmdln.gd -gunit_test_name=b35

# um bloco direto, sem GUT (mostra toda a saída do teste)
<Godot>.exe --headless --path . -s res://tests/blocos/b35_arsenal_desgaste.gd
```

> No último jeito (direto, sem GUT), a trava de segurança exige a pasta isolada: rode
> com `APPDATA` apontando pra uma pasta que tenha `fake_appdata` no caminho, senão o
> teste só imprime `ABORTADO` e sai (de propósito).

## Regressão dos sprites

`tools/sprite_regress.py` confere que o gerador de sprites (`tools/gen_sprites.py`,
determinístico) só mudou o que o bloco pretendia — instruções no topo do arquivo.

## O que tem teste versionado

| Arquivo | Bloco |
|---|---|
| `manut_backups.gd` | Backups rotativos do save |
| `b25_funcoes.gd`, `b25_troca_funcao.gd` | 25 — função única por ipezinho |
| `b26_outfits.gd` | 26 — roupa por função |
| `b27_cacador_cozinheiro.gd` | 27 — caçador e cozinheiro que prepara |
| `b28_cacador_outfit.gd` | 28 — roupa do caçador, HUD, fallback de caça |
| `hud_frostpunk.gd` | HUD estilo Frostpunk |
| `b29_30_item_mao_medico.gd` | 29 e 30 — item na mão, médico |
| `b31_obras_engenheiro.gd`, `b31b_obras_restantes.gd` | 31 e 31b — engenheiro e obras |
| `b32_…` a `b42_…` | 32 a 42 (um arquivo por bloco) |
| `b44_vestiario.gd` | 44 — Vestiário como prédio físico |
| `p28_iso.gd` | Prompt 28 — vista isométrica no jogo (F3): espelhos, ordem por caixas, clique pelo raio, construir/demolir, prédio em "L", fantasma, câmera/save, desligar |
| `p28_save.gd` | Prompt 28 — save de antes do Prompt 28 carrega igual nas duas vistas (md5 do arquivo, ipezinhos, posições, créditos); com `DEEP_IRON_SAVE_FIXTURE=<cópia de um save antigo>` usa a cópia, sem ela faz o próprio save |
| `p29_mapa.gd` | Prompt 29 — mapa novo: alturas dos terraços e rampa da escada, navegação (escada e portão), construir só em chão plano, ordem com os terraços, andares de baixo empilhados (clique volta pro andar), céu e luz por hora, migração do save |
| `p29_predios.gd` | Prompt 29 parte 2 — prédios com a arte nova: desenho por estado (variação, obra 1/2/3 pelo progresso, estágio do Centro, peças da escavadeira, nível do portão), caixa do desenho, pegada de navegação = desenho ÷ 1,5, camas/slots fora da parede e alcançáveis, posicionador e fantasma novos, migração de prédios sobrepostos, paliçada, ordem sem erro |
| `p19_luz.gd` | Prompt 19 — luz e noite: texturas por tipo, ponto de luz do desenho, janelas acesas só à noite e com o prédio aceso, alcance de z das luzes, tocha/cristal/lanterna, lava, tom por estação |
| `p29_bonecos.gd` | Prompt 29 parte 3 — bonecos com a arte nova: pasta por função × gênero, animação pelo estado, direção, pele por paleta, casaco/traje, picareta e saco nas costas, corpo antigo escondido |
| `p29_natureza.gd` | Prompt 29 partes 4–5 — natureza/objetos pelo desenho antigo (árvores, toco, tocas, horta, jazidas pela quantidade, galeria lacrada, rochas, cristais, tocha), elevadores (gaiola no andar de baixo) e robô |
| `p17_criaturas.gd` | Prompt 17 — invasores com a arte nova: 5 animações × 4 direções, animação pelo estado (parado, andar, atacar, dano, cair e ficar no chão, desligar), forma forte (bruto/carregador) e a Defesa mandando 1 forte a cada 3 na onda 4+, carga do roubo, desenho antigo escondido |
| `p18_efeitos.gd` | Prompt 18 — efeitos: texturas por papel nas partículas copiadas (serragem, fumaça, gás), tamanho em pixel inteiro, festa (bandeirinhas, fogos à noite), greve (barril, placas, placa na mão), satélite (antena), explosivos, onda solar, clima com textura, neblina, ar tremendo no calor, cova, cesto na mão, domo do escudo, tudo recolhido no fim |
| `p2_pendencias.gd` | Pendências dos Prompts 2 e 29 — colher fruta, treinar e ataque com lança/besta nas 4 direções; escolha pelo estado (porrete, lança, lança de prata, besta) |
| `b51_engenheiro_estresse.gd` | 51 — 50 ciclos de salvar/carregar com obras longas e 3 engenheiros em estados diferentes (parado, indo, construindo): todo engenheiro retoma em até 25 s de jogo; o vigia age quando força "sem avançar" e não age enquanto ele se aproxima (~10 min) |
| `b52_debug_telemetria.gd` | 52 — painel de debug (F3, só em build de debug): tempo, recursos, pular dia, curar, pesquisas, invasão; telemetria: 10 dias = 10 linhas no CSV com as 21 colunas |
| `b54_configuracoes.gd` | 54 — escala da interface (persistida, limitada pra caber; janelas com rolagem), velocidade de câmera/zoom, reduzir efeitos, teclas (trocar, trocar entre duas, reservadas, valer no jogo, reabrir, restaurar), idioma (inglês na hora e volta), fonte com acentos, tela de configurações e página de teclas |
| `b55_audio.gd` | 55 — buses e limitador no Master, sliders nos buses, todo evento com som, música de perigo na invasão (e volta), ambiência pelo lugar da câmera (mina, clareira dia/noite, chuva, fundo), máximo de vozes do mesmo som, 15 ipezinhos trabalhando abaixo do teto |
| `b56_casas.gd` | 56 — casa nível 2 e 3: bloqueio com motivo (estágio, recursos, pesquisa Medicina), clique abre a janela da casa, ampliação cobra e é obra do engenheiro (casa segue habitada), camas e conforto do nível no ânimo, desenho do nível e andaime, cartão do menu, save/load (com a obra em andamento) e save antigo = nível 1 |
| `b57_coletor_minerio.gd` | 57 — coletor de minério: só perto de jazida, canteiro do engenheiro, designar minerador (lenhador não), produz o minério da jazida pro armazém, para sem operador, jazida esgotada para sem erro, o segundo custa mais, cartão do menu, save/load (posição, total, jazida escolhida, operador volta) |
| `b58_oficina_construivel.gd` | 58 — Oficina construível: jogo novo = não construída (invisível, sem clique/obra, não bloqueia caminho, ferramentas seguem trancando minérios, equipamento pede Oficina), janela e cartão de construir, canteiro do engenheiro, pronta no lugar escolhido e forjando, save com ela por construir, save antigo = construída no lugar da cena |
| `b60_dinamite_radio.gd` | 60 — dinamite (pesquisa Explosivos): bloqueio com motivo, fazer gasta cr + carvão, clique no entulho abre a janela, minerador leva e explode, galeria abre e a dinamite é gasta, acidente pelo risco; rádio adianta o aviso de invasão e acelera o satélite; save/load |
| `b61_fauna.gd` | 61 — tocas de coelho e de javali com bichos (nascem cheias, vagam perto da toca, aparecem na vista iso), caçador abate um bicho e leva a carne, javali fere caçador novato (experiente não), limite de população e inverno menor, save/load dos bichos e save antigo |
| `b62_tiers_chefe.gd` | 62 — tier sobe com a onda e com as pesquisas, elite, a Matriarca (uma por estação a partir da configurada): grito chama Lumívoros, golpe corrói a arma, derrubada dá recompensa, foge ao amanhecer, sem softlock com os guardas caídos, telemetria (tier/chefe) e save |
| `b63_corte_mina.gd` | 63 — corte da mina: todas as jazidas (abertas/lacradas/trancadas), ipezinhos por andar, redesenho ~20x/s, estado novo no próximo desenho, clique na galeria leva a câmera |
| `b64_vagonete.gd` | 64 — trilho e vagonete: lugar perto das jazidas e longe do armazém, canteiro, trilho até o armazém, minerador perto entrega no ponto de carga, vagonete leva sozinho, trilho quebra (ponto cheio não aceita: mineradores vão pro armazém), engenheiro conserta, save/load |
| `b67_mapa_leste.gd` | 67 — mapa ampliado pro leste (~2,9x a área): trancado (sem caminho, ninguém escolhe estação de lá, não constrói), conteúdo com nome fixo, câmera cobre o leste, desbravar (estágio, custo, obra do engenheiro), depois caminho e construção lá, save/load (aberto + jazida nova pelo nome) e save antigo trancado |
| `b68_niveis.gd` | 68 — níveis por dados (data/niveis/*.tres): leitura e ordem, nível de cada ponto (S0–S3), liberação com motivo (ligação, pesquisa, em breve), Trajes trava o S3, gaiola com tempo e lotação, corte da mina lê os dados |
| `b69_atmosfera.gd` | 69 — camadas e atmosfera por nível (docs/arte/CAMADAS.md): um nó de atmosfera por nível jogável na camada 4 (acima de toda fixa), névoa/partículas/tom da laje vindos do .tres, luz pulsando nas zonas de perigo (no corte de luzes), intensidade 50%/0% e reduzir efeitos, decoração por dados nas lajes (cada prop = linha do .tres, com arte iso), save/load sem duplicar |
| `b70_fundo.gd` | 70 — conteúdo do S2 (ácido) e S3 (lava): poças e jazidas de cristal vindas do .tres (nomes fixos), poça sem traje atrasa e queima (ácido leve em 5 s, lava em 2,5 s), com máscara no vestiário veste e nada acontece, cristal verde/rubro vendável no HUD e no armazém e liberado pela broca/traje de chumbo, ventilador (pesquisa Ventilação + S2 aberto, só no chão do nível 2) poupa metade da máscara, alivia o ácido e afina a névoa, Gosma e Magmante nas ondas certas (corrosão, metal/carvão do armazém, cristal ao cair), escavadeira acha cristal e rende mais com o S3, telemetria, save/load |
| `b71_s4_s5.gd` | 71 — S4 (cachoeira e lava) e S5 (lago azul) por dados: área, nível e perigo de cada ponto, plataformas montadas dos .tres com conserto em cadeia (abismo → S4 com Bombas d'água → S5 com cristal rubro), jazidas trancadas/abertas, caminho da vila até o S5, água que molha (lava queima menos), o lago não anda, ânimo do nível, gema azul, lajes/poças/cachoeira na vista iso, corte com 6 andares, save/load |
| `b73_andar.gd` | 73 — bonecos andando no chão: em toda animação de andar o pé de cada quadro encosta na linha da âncora depois do ajuste (`aj` no bonecos.json, `integra.py pes`) e a cabeça da caminhada fica na mesma vertical, a pose aplica o ajuste (âncora, topo, altura), o quadro vem da distância andada, sem sair do lugar fica parado, pulo de lugar não conta passo, posição entre dois passos da física |
| `b74_superficie.gd` | 74 — a superfície da maquete v3: floresta (oeste) \| paliçada de norte a sul com o único portão \| vila plana sem jazida \| mina; o que fica em cada área, carvão à esquerda e cobre à direita da boca, o caminho da floresta pra vila pelo portão, a montanha em degraus (6/12/18) com as escadas até as 4 galerias, o vagonete fixo da boca até a porta do armazém (leva a carga), portão de lado com os guardas do lado da vila, lumívoro nascendo na floresta, clima na superfície toda, construir (floresta e montanha não), save do mapa antigo (casa na floresta vai pra vila) |
| `b75_faixas.gd` | 75 — a coluna da maquete: os 4 andares em faixas (larga e rasa, menor em área que o andar antigo, longe dos retângulos antigos), 22 degraus entre andares, as galerias de madeira entre a superfície e o S2, cada chão aparecendo inteiro na tela, gaiolas na vertical do poço, conteúdo dentro da faixa e da caverna, caminho da gaiola até cada jazida, save de antes das faixas (posição relativa) |
| `b76_faixas_lotes.gd` | 76 — o resto da maquete e o andar de todos: 4 lotes livres na vila (lugar de casa válido, fora da praça e das ruas, chão limpo, o posicionador encaixa no meio, com prédio dentro deixa de ser livre), a boca da escada em espiral em cima da espiral da coluna, a arte das faixas (rio e fios de lava no S3, cortina da cachoeira no S4, raízes debaixo da floresta no S2), a gente toda com caminhada de 8 quadros e passada medida, criaturas/robô/bichos pela distância |
| `b78_marcos.gd` | 78 — os marcos de cada andar (maquete v4): fóssil gigante no S3 (luz, bloqueia a passagem), 3 bicas da fonte termal no S4 (vapor na vista), torre e 4 lampiões de cristal acesos na cidade do S5, mais cristais e poças d'água no S2, cabanas de mineiro na faixa das galerias; cada marco no andar certo, dentro da caverna, longe das jazidas, e o caminho da gaiola até cada jazida do S3/S4/S5 aberto |
| `b77_areas.gd` | 77 — áreas de trabalho (Frostpunk): marcar área de madeira/alimentos/mina arrastando (área minúscula ou em cima de outra do mesmo tipo não vale), até 5 por área e nunca mais que os disponíveis, disponível (sem função) → alocado (ganha a função, sai dos disponíveis) → disponível, quem está na área só usa árvore/horta/jazida de dentro e quem não está não usa a da área, trocar a função à mão tira da área, a mina (desligada / sem mineiro / operando; o carrinho só anda operando), produção de verdade (5 rende mais que 2, rodando), save/load (áreas, quem está em cada uma, mina ligada, total) |
| `p20_interface.gd` | Prompts 20–25 — pele (tema da raiz, botão/painel/cartão/aba 9-slice, cadeado, cursores), ícones (barra de cima, funções, prédios do menu), fontes (acentos, cabeçalho), velocidade, retrato (expressão pelo estado, cartão do selecionado), faixa com ilustração, janela de evento, corte da mina (4 andares, um boneco por ipezinho, clique seleciona) |
| `../test_iso.gd` (GUT, rápido) | Prompt 28 — núcleo: projeção, verdade 3D, ordem incremental, raio da câmera, direção de losango |
| `../test_iso_arte.gd` (GUT, rápido) | Prompt 28 — verificador "o sprite cabe na caixa" contra a arte dos prédios; Prompt 29 — toda a arte integrada (`assets/game/iso/predios/predios.json`) |
| `../test_iso_pele.gd` (GUT, rápido) | Prompt 28 — paletas de pele por código (igual ao `tons_de_pele.py`; dados em `tests/data/pele/`) |

**Prompt 29 parte 2 mudou de propósito** `b41_parque`: o lugar do 2º parque sai do posicionador
do parque aberto (pegada do desenho novo), não de uma pegada/bloqueios que tinham sobrado.

(Bloco 44 mudou de propósito o `b42_equipamento`: ele ergue um Vestiário pronto no começo,
porque desde o 44 o equipamento só funciona com o prédio.)

**Sem teste versionado:** os blocos **1 a 24** (os testes daquela época não foram
guardados — sobraram só sondas de depuração, que não dão OK/FALHOU e ficaram de fora)
e o próprio **Bloco 43**. Não foram recriados.

## Manutenção feita no Bloco 43

Os testes vieram do jeito que estavam, com três ajustes mecânicos pra rodar hoje
(trava do save isolado onde faltava; partida sem a fundação do Bloco 37; troca de cena
de verdade no load) e **checagens atualizadas** onde um bloco posterior mudou o
comportamento de propósito (cada troca está comentada com `(Bloco 43)` no arquivo):

- `b25_funcoes` — aceita "já entregou" além de "indo entregar" (o teste pegava o
  ipezinho já no armazém; a regra em si é coberta por `b25_troca_funcao`).
- `b26_outfits` — guarda e pesquisador com roupa própria (Bloco 28); cozinheiro com a
  cesta, guarda com a arma, pesquisador sem picareta fora da mina (Bloco 29).
- `b27_cacador_cozinheiro` — arco na mão só caçando (Bloco 29).
- `b28_cacador_outfit` e `b29_30_item_mao_medico` — HUD novo (seções e contagem por
  função na barra de funções); guarda novo começa com porrete (Bloco 35); o médico
  "some do mapa" confere `_inside` (o desenho some um quadro depois).
- `b27_cacador_cozinheiro` — depois do load confere a matéria-prima TOTAL (armazém +
  mochilas): o jogo segue rodando e o cozinheiro pode pegar um pouco antes da conferência.
- `b36_guarda_caido` — posição do caído com tolerância de 2 px (o save guarda 1 casa
  decimal; comparar arredondado dava diferença de 1 px à toa).
- `test_blocos.gd` — cada bloco começa com a pasta de usuário temporária **limpa**
  (sem save, backup ou `settings.cfg` deixado pelo bloco anterior).

## Rodar tudo com a vista isométrica ligada (Prompt 28)

`DEEP_IRON_ISO=1` faz toda partida começar com a vista iso ligada (o `main.gd` liga no
início). A lógica não pode mudar com a vista, então a bateria inteira tem que passar igual:

```
DEEP_IRON_ISO=1 <Godot>.exe --headless --path . -s addons/gut/gut_cmdln.gd
```

Os Godot filhos de cada bloco herdam a variável.

**Prompt 28 mudou de propósito** `b32_escavadeira_visual` e `b38_centro_por_estagio`: o
"fantasma que fica nítido" saiu e a obra aparece por **estágios** (0–33 / 33–66 / 66–100%,
`scripts/core/obra_estagio.gd`). As checagens de nitidez (alfa) viraram checagens de
estágio.

**Prompt 29 (partes 2–6) mudou de propósito:** `b37_fundacao_raio` (sem o raio do Centro: casa em
qualquer lugar da pedreira, a floresta recusa), `b41_parque` (lugar do parque pelo posicionador aberto,
sem raio), `b48_janela_zoom` (paradas com a densidade da arte nova + a parada "longe"), `p28_iso`
(o F3 saiu: liga/desliga direto e confere que o F3 não troca mais), `b46_menu_construcao` (cartão
"Cozinha").

**Prompt 19 mudou de propósito** `p29_predios`: a camada de janelas acesas não conta como desenho
do prédio. Fotos/GIF do ciclo dia/noite: `tests/ciclo_luz.gd` (com janela, pasta isolada).

## Análise de capacidade (Prompt 29)

`tests/analise_capacidade.gd` (headless, pasta isolada) encaixa casas na pedreira com o
posicionador de verdade até não caber mais e imprime quantas cabem por terraço.

## Capturas pros relatórios (Prompt 29)

`tests/capturas_iso.gd` não é teste: abre a partida, ergue os prédios no layout aprovado, põe
obras em estágios diferentes e salva PNGs. Precisa de JANELA (renderizar) e da pasta isolada:

```
<Godot>.exe --path . -s res://tests/capturas_iso.gd -- <pasta de saída>
```

(com `APPDATA` apontando pra uma pasta com `fake_appdata` no caminho; não rode ao mesmo tempo
que a bateria usando a MESMA pasta: ele apaga o save de lá ao começar.)

## Capturas dos Prompts 17 a 26

Também não são testes; JANELA + pasta isolada:

- `tests/capturas_fx.gd -- <pasta>`: criaturas, festa, greve, onda solar, chuva/neblina, mina
  (gotas, calor), forja, acidente, cemitério, escudo (quadros pros GIFs);
- `tests/capturas_ui.gd -- <pasta>`: HUD, menu de construção, janela de evento, painel de prédio;
- `tests/capturas_interface.gd -- <pasta>`: retrato + faixa com ilustração, corte da mina, vitória,
  derrota. Se houver `save_copia.json` na pasta de usuário isolada (uma **cópia** do save), carrega
  ele (foi assim que o corte foi fotografado com o save real; o original não é tocado);
- `tests/capturas_titulo.gd -- <pasta>`: menu inicial animado e tela de carregamento.

## Revisão visual e desempenho (Prompt 30)

Não são testes (não dão OK/FALHOU); precisam de JANELA e da pasta isolada, como as capturas:

- `tests/qa_prompt30.gd -- <pasta>`: vila cheia, as 4 estações, noite, onda solar, invasão,
  obras, nível 2, abismo e o mapa de longe; uma foto de cada e, em `ordem.txt`, quantos pares
  saíram na ordem errada (tem que ser 0);
- `tests/desempenho_iso.gd -- <pasta>`: fps em 1920×1080 em 5 situações (até o mapa cheio).

Da raiz do repositório (Python):

- `python tools/qa_arte.py <saida.json>`: brilho, saturação e contorno de cada desenho, por
  categoria, e o que destoa;
- `python tools/contorno.py`: contorno de 1 px nos desenhos da lista (rodar de novo não muda nada).

**Disco:** em 2026-10-01 o C: encheu (0 GB). Dá pra pôr a pasta isolada e os temporários no D:
(`APPDATA`, `XDG_DATA_HOME`, `TEMP` e `TMP` apontando pra uma pasta no D: com `fake_appdata` no
caminho); o `test_blocos.gd` cria as pastas dos blocos dentro do `TEMP`.

## Conhecido

- `b45_coletor_madeira` às vezes falha em "lenhador manual trabalha em paralelo": o lenhador
  sorteou um acidente cortando árvore e está internado na hora da conferência (visto 1 vez
  em 4 rodadas no Prompt 28; sozinho passou 2 de 2). É o sorteio do jogo, não a regra.
- ~~`b31b_obras_restantes` às vezes falha com "engenheiro preso a caminho de uma obra"~~
  (Bloco 51): a obra não vai no save (o engenheiro escolhe de novo, pelo grupo "obras", depois
  do mundo carregado), então não é referência velha. O que sobrava era o caminho: com a malha
  refeita no load, o ponto da obra podia ficar sem caminho de onde ele estava, o anti-travamento
  desistia e a IA mandava andar pro MESMO ponto. Agora tem o VIGIA (`obra_watchdog_time`, 12 s
  sem chegar 16 px mais perto): escolhe outro ponto de acesso em volta da obra que o caminho
  alcança, ou (sem nenhum) puxa pro chão andável mais perto; loga `[vigia]`. O estresse de 50
  ciclos não reproduziu o preso (0 de 50, com e sem o vigia agir).
