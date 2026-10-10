# Pedido de sons (Bloco 116)

Gerado por `python tools/elevenlabs/docs_audio.py` a partir de `project.godot/data/audio/slots.json`. **Não edite à mão.** Os prompts estão em `docs/audio/PROMPTS_ELEVENLABS.md` e a lista de escuta em `docs/audio/LISTA_DE_ESCUTA.md`.

O jogo roda **sem** os arquivos: o slot sem arquivo fica mudo (ou toca o som sintetizado de antes), sem erro. Arquivo novo é só pôr em `project.godot/assets/audio/<nome>.ogg|wav|mp3` com o nome exato e rodar `godot --headless --path project.godot --import`.

**Resumo:** 128 slots, 193 arquivos esperados, **191 prontos, 2 faltam**.

## O que falta

| Arquivo | Duração | Loop | Descrição | Termos de busca |
|---|---|---|---|---|
| `musica/abertura` | Música (fora desta lista de efeitos) | sim | A ABERTURA do jogo: toca na tela inicial (o menu). Loop de 1 a 2 minutos, tema principal do DEEP IRON (sol, ruína, esperança). | A ABERTURA do jogo: toca na tela inicial . Loop de 1 a 2 minutos, tema principal do DEEP I; game music loop |
| `musica/intro` | Música (fora desta lista de efeitos) | não | A INTRODUÇÃO (3 quadros ilustrados + 4 no mapa, uns 60 s): uma peça só, crescendo da explosão até a fogueira e o título. Não repete. | A INTRODUÇÃO : uma peça só, crescendo da explosão até a fogueira e o título. Não repete; game music loop |

A **música** (abertura e introdução) não é gerada pela ferramenta de efeitos: os slots estão no catálogo e o jogo toca quando o arquivo existir.


## Ambiência (loops por andar, clima e onda solar)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `ambiencia/mina` | loop 40 s | sim | Ambience | 0.0 | Vila, pedreira e túneis do S1 (a câmera na área da mina). Loop contínuo, sem pico alto. | deep underground quarry and mine ambience, low steady cave air tone; ambience loop | o som de antes | pronto |
| `ambiencia/floresta_dia` | loop 40 s | sim | Ambience | -4.0 | Floresta e clareira de dia: pássaros, folhas, vento leve. | peaceful boreal forest clearing in daytime, several small birds singing and calling at dif; ambience loop | o som de antes | pronto |
| `ambiencia/floresta_noite` | loop 40 s | sim | Ambience | -5.0 | Floresta e clareira de noite: grilos e uma coruja distante. | forest clearing at night, many crickets chirping steadily; ambience loop | o som de antes | pronto |
| `ambiencia/vento_inverno` | loop 30 s | sim | Ambience | -8.0 | CAMADA por cima da floresta e da vila no inverno: vento frio e constante, sem pássaros. | cold winter wind blowing steadily across an open snowy landscape, soft whistling through b; ambience loop | mudo | pronto |
| `ambiencia/chuva` | loop 30 s | sim | Ambience | -6.0 | CAMADA por cima da clareira quando está chovendo. | steady rain falling on dirt ground, wooden roofs and leaves; ambience loop | o som de antes | pronto |
| `ambiencia/s2_acido` | loop 40 s | sim | Ambience | -1.0 | S2 (ácido e gás): bolhas de ácido borbulhando e gotejar. | underground cave filled with toxic acid pools, slow viscous bubbling and popping; ambience loop | o som de antes | pronto |
| `ambiencia/s3_lava` | loop 40 s | sim | Ambience | -1.0 | S3 (lava): lava borbulhando e ronco grave de fundo. | cavern beside a lava lake, thick bubbling and gurgling magma; ambience loop | o som de antes | pronto |
| `ambiencia/s4_cachoeira` | loop 40 s | sim | Ambience | -1.0 | S4 (cachoeira e lava): queda d'água constante ao longe. | huge underground waterfall crashing into a pool inside a big cave, constant roaring water ; ambience loop | o som de antes | pronto |
| `ambiencia/s5_lago` | loop 40 s | sim | Ambience | -1.0 | S5 (lago azul): gotas e água parada, o jogo põe o eco (reverb) sozinho. *(eco 0.35)* | calm underground lake in a huge cavern, gentle water lapping; ambience loop | o som de antes | pronto |
| `ambiencia/onda_solar` | loop 30 s | sim | Ambience | -4.0 | CAMADA durante a onda solar, na superfície: calor, rugido e estática. | scorching solar flare disaster over the surface, a deep rising roar like a distant furnace; ambience loop | mudo | pronto |

## Prédios e lugares (loops posicionais e sinos)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `predios/fornalha` | loop 25 s | sim | SFX | -12.0 | Fornalha acesa (só enquanto o fundidor funde): fogo e foles. *(só perto da câmera (600 px), com o prédio em atividade)* | blast furnace burning, roaring fire with bellows breathing in and out slowly; loop machinery ambience | mudo | pronto |
| `predios/carpintaria` | loop 25 s | sim | SFX | -12.0 | Carpintaria com ordem em andamento: serra e martelo. *(só perto da câmera (600 px), com o prédio em atividade)* | busy carpentry workshop, rhythmic hand saw cutting wood; loop machinery ambience | mudo | pronto |
| `predios/taverna` | loop 30 s | sim | SFX | -12.0 | Taverna com gente dentro: murmúrio, canecas, riso. *(só perto da câmera (600 px), com o prédio em atividade)* | small tavern interior, low murmur of a few people chatting; loop machinery ambience | mudo | pronto |
| `predios/cemiterio` | loop 30 s | sim | SFX | -14.0 | Cemitério (sempre): vento baixo e um corvo distante. *(só perto da câmera (600 px), com o prédio em atividade)* | quiet graveyard at dusk, low soft wind; loop machinery ambience | mudo | pronto |
| `predios/vagonete` | loop 20 s | sim | SFX | -10.0 | Vagonete andando no trilho: rodas de ferro. *(só perto da câmera (600 px), com o prédio em atividade)* | heavy iron mine cart rolling on rails, rhythmic wheel clacks at the rail joints and a low ; loop machinery ambience | mudo | pronto |
| `predios/coletor_madeira` | loop 25 s | sim | SFX | -12.0 | Coletor de madeira funcionando: engrenagem e serra mecânica. *(só perto da câmera (600 px), com o prédio em atividade)* | small steam-powered wood-collecting machine working, rhythmic clanking gears; loop machinery ambience | mudo | pronto |
| `predios/coletor_minerio` | loop 25 s | sim | SFX | -12.0 | Coletor de minério funcionando: motor e broca. *(só perto da câmera (600 px), com o prédio em atividade)* | automatic ore-drilling machine working, powerful rotary drill grinding rock; loop machinery ambience | mudo | pronto |
| `predios/sino_missa` | 8 s | não | SFX | -5.0 | Sino da igreja quando a missa de domingo começa (posicional, na igreja). *(abaixa a música (sino))* | A single large church bell tolling slowly three times in a village, warm resonant bronze t; loop machinery ambience | o som de antes | pronto |
| `predios/sino_funeral` | 12 s | não | SFX | -5.0 | Sino da igreja (ou do cemitério) quando o funeral começa: mais lento e grave. *(abaixa a música (sino))* | A slow low funeral bell, five deep tolls spaced far apart; loop machinery ambience | o som de antes | pronto |
| `predios/poca_perigo` | loop 20 s | sim | SFX | -16.0 | Perto de uma poça de ácido ou lava (sempre): borbulhar baixo e chiado. *(só perto da câmera (400 px), com o prédio em atividade)* | a small pool of toxic acid, slow bubbling and soft hissing with faint gas escaping; loop machinery ambience | mudo | pronto |
| `predios/ventilador` | loop 20 s | sim | SFX | -14.0 | Perto de um ventilador da mina (sempre): zumbido de ar. *(só perto da câmera (500 px), com o prédio em atividade)* | a large industrial mine ventilation fan spinning, steady whooshing air and a soft metallic; loop machinery ambience | mudo | pronto |
| `predios/tocha` | loop 20 s | sim | SFX | -8.0 | Perto de uma tocha acesa (sempre): fogo crepitando. *(só perto da câmera (350 px), com o prédio em atividade)* | a wall torch burning, soft crackling fire with gentle flame flutter; loop machinery ambience | mudo | pronto |
| `predios/conversa` | loop 30 s | sim | SFX | -14.0 | Num ponto social (refeitório, praça, parque, igreja...) com gente reunida: o murmúrio da conversa. *(só perto da câmera (500 px), com o prédio em atividade)* | a small crowd of villagers chatting quietly, indistinct overlapping murmur with no intelli; loop machinery ambience | mudo | pronto |
| `predios/oficina` | loop 25 s | sim | SFX | -12.0 | Oficina com o ferreiro trabalhando: martelo na bigorna. *(só perto da câmera (600 px), com o prédio em atividade)* | a blacksmith workshop, rhythmic hammer on anvil with ringing metal; loop machinery ambience | mudo | pronto |
| `predios/arsenal` | loop 25 s | sim | SFX | -12.0 | Arsenal com o ferreiro trabalhando: metal batido e armas. *(só perto da câmera (600 px), com o prédio em atividade)* | an armory forge, metal being hammered and filed; loop machinery ambience | mudo | pronto |
| `predios/laboratorio` | loop 25 s | sim | SFX | -14.0 | Laboratório com a pesquisadora trabalhando: líquidos borbulhando. *(só perto da câmera (600 px), com o prédio em atividade)* | an old-fashioned laboratory, liquids bubbling in glass flasks; loop machinery ambience | mudo | pronto |
| `predios/escavadeira` | loop 25 s | sim | SFX | -10.0 | Escavadeira gigante funcionando: motor e broca. *(só perto da câmera (700 px), com o prédio em atividade)* | a giant steam excavator drilling machine running, deep engine chugging; loop machinery ambience | mudo | pronto |
| `predios/escola` | loop 30 s | sim | SFX | -14.0 | Escola com gente dentro: crianças ao longe e giz. *(só perto da câmera (600 px), com o prédio em atividade)* | a small village schoolroom, children murmuring and giggling softly in the distance; loop machinery ambience | mudo | pronto |
| `predios/cozinha` | loop 25 s | sim | SFX | -9.0 | Cozinha com o cozinheiro trabalhando: panela e fogão. *(só perto da câmera (600 px), com o prédio em atividade)* | a communal kitchen, a big pot of stew simmering; loop machinery ambience | mudo | pronto |

## Stingers (eventos do jogo)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `stingers/amanhecer` | 3 s | não | SFX | -8.0 | Começa um novo dia (05:00): curto, claro, 2 a 3 s. | Short gentle sunrise sting: a soft rising chime with a warm low string swell and a few bir; stinger jingle | mudo | pronto |
| `stingers/onda_solar` | 4 s | não | SFX | -4.0 | O aviso 'ONDA SOLAR CHEGANDO' (tensão crescente, 3 a 4 s). *(abaixa a música (alarme))* | Ominous warning sting: a rising low metallic drone with a deep pulsing alarm swell and ele; stinger jingle | o som de antes | pronto |
| `stingers/estagio_novo` | 4 s | não | SFX | -4.0 | A vila sobe de estágio: fanfarra de conquista, 3 a 4 s. | Triumphant achievement sting: bright brass fanfare with a rolling drum hit and ascending a; stinger jingle | o som de antes | pronto |
| `stingers/pesquisa_pronta` | 2.5 s | não | SFX | -4.0 | Uma pesquisa termina: brilho curto, 2 s. | Short discovery sting: a sparkling bell chime run upward with a soft magical shimmer, curi; stinger jingle | o som de antes | pronto |
| `stingers/morte` | 4 s | não | SFX | -5.0 | Um ipezinho morre: sino fúnebre curto e triste. *(abaixa a música (sino))* | Mournful sting: one slow low funeral bell toll with a faint sad cello note fading away; stinger jingle | o som de antes | pronto |
| `stingers/vitoria` | 7 s | não | SFX | -3.0 | Vitória (o escudo solar fica pronto): triunfo, 5 a 8 s. | Epic victory sting: a big triumphant brass and drum swell resolving into a held major chor; stinger jingle | o som de antes | pronto |
| `stingers/derrota` | 5 s | não | SFX | -3.0 | Derrota (os ipezinhos expulsam o jogador): grave e vazio, 4 a 6 s. *(abaixa a música (sino))* | Defeat sting: a heavy low drone collapsing downward with a dull distant gong and fading wi; stinger jingle | o som de antes | pronto |
| `stingers/missao_cumprida` | 3 s | não | SFX | -4.0 | Uma missão é cumprida: fanfarra curta de recompensa, 2 a 3 s. | Short reward sting: a cheerful ascending three-note chime with a soft drum accent and a sp; stinger jingle | o som de antes | pronto |

## Interface (bus UI)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `ui/abrir_janela` | 0.3 s | não | UI | -14.0 | Abrir uma janela: whoosh/papel curto, menos de 0,3 s. | Soft game UI sound: a wooden panel sliding open with a light paper rustle, very short; ui sound game | o som de antes | pronto |
| `ui/fechar_janela` | 0.3 s | não | UI | -14.0 | Fechar uma janela: o oposto do abrir, menos de 0,3 s. | Soft game UI sound: a wooden panel sliding closed with a light paper rustle, very short; ui sound game | o som de antes | pronto |
| `ui/confirmar` | 0.5 s | não | UI | -8.0 | Confirmar (pôr um prédio, marcar uma área, comprar): toque firme e satisfatório. | Satisfying UI confirm sound: a firm wooden stamp thud with a tiny metallic ring; ui sound game | o som de antes | pronto |
| `ui/erro` | 0.4 s | não | UI | -6.0 | Ação negada (sem recurso, lugar inválido): buzz curto e seco. | Negative UI sound: a short dull low buzzer thunk; ui sound game | o som de antes | pronto |
| `ui/clique` | 0.15 s | não | UI | -12.0 | Clique de botão: tec curto e suave. | Subtle UI button click: a small wooden tick, extremely short; ui sound game | o som de antes | pronto |
| `ui/noticia_boa` | 0.6 s | não | UI | -8.0 | Aviso bom (aviso verde): dois toques ascendentes, 0,5 s. | Positive notification: two ascending soft bell notes; ui sound game | mudo | pronto |
| `ui/noticia_ruim` | 0.6 s | não | UI | -8.0 | Aviso ruim (aviso vermelho): dois toques descendentes, 0,5 s. | Negative notification: two descending dull bell notes; ui sound game | mudo | pronto |

## Efeitos do jogo (trabalho, combate, obras, avisos)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `sfx/picareta_0`<br>`sfx/picareta_1`<br>`sfx/picareta_2` | 0.5 s cada | não | SFX | -7.0 | O ipezinho dá um golpe de picareta na pedra. | A pickaxe striking hard rock, one sharp metallic clink with small stone chips flying; sound effect | o som de antes | pronto |
| `sfx/deposito_0`<br>`sfx/deposito_1`<br>`sfx/deposito_2` | 0.7 s cada | não | SFX | -9.0 | Entrega o minério (ou a madeira) no armazém. | Dropping a handful of ore chunks into a wooden storage bin, rocks clattering; sound effect | o som de antes | pronto |
| `sfx/comer_0`<br>`sfx/comer_1`<br>`sfx/comer_2` | 1 s cada | não | SFX | -11.0 | Um ipezinho come no refeitório. | A person eating stew with a wooden spoon, a couple of quick chews and a small satisfied gu; sound effect | o som de antes | pronto |
| `sfx/ferido` | 0.6 s | não | SFX | -4.0 | Um ipezinho se machuca (acidente, criatura, radiação). | The impact of a worker getting hurt followed by a short pained grunt, no words; sound effect | o som de antes | pronto |
| `sfx/curar` | 1 s | não | SFX | -8.0 | A enfermaria cura um paciente. | A soft healing sound: a gentle bandage rustle with a warm reassuring chime; sound effect | o som de antes | pronto |
| `sfx/forja` | 0.8 s | não | SFX | -10.0 | A oficina, o arsenal ou a escavadeira forjam uma peça. | A hammer strike on hot iron on an anvil with ringing metal and a spark hiss; sound effect | o som de antes | pronto |
| `sfx/machadada_0`<br>`sfx/machadada_1`<br>`sfx/machadada_2` | 0.6 s cada | não | SFX | -9.0 | O lenhador dá uma machadada na árvore. | An axe chopping into a tree trunk, a heavy wooden thock with wood chips; sound effect | o som de antes | pronto |
| `sfx/elevador` | 3 s | não | SFX | -8.0 | O elevador sobe ou desce. | A mine elevator cage starting to move: heavy chain rattle, a winch rattling and a metal cl; sound effect | o som de antes | pronto |
| `sfx/galho` | 2 s | não | SFX | -5.0 | Uma árvore cai. | A tree branch snapping and a trunk creaking as it begins to fall; sound effect | o som de antes | pronto |
| `sfx/fanfarra` | 3 s | não | SFX | -4.0 | Uma conquista (a Matriarca cai, a escavadeira fica pronta, o abismo abre, o fim da greve). *(sem posição (na tela toda))* | A short triumphant brass fanfare; sound effect | o som de antes | pronto |
| `sfx/sino_funebre` | 4 s | não | SFX | -5.0 | O último aviso da greve e o som antigo do funeral. *(sem posição (na tela toda); abaixa a música (sino))* | A single low funeral bell toll with a long decay; sound effect | o som de antes | pronto |
| `sfx/alarme_invasao` | 3 s | não | SFX | -4.0 | Começa uma invasão de criaturas (e o aviso da onda solar, sem o stinger). *(sem posição (na tela toda); abaixa a música (alarme))* | A loud war horn blast followed by a second lower blast, an urgent alarm; sound effect | o som de antes | pronto |
| `sfx/solar` | 3 s | não | SFX | -3.0 | A onda solar chega. *(sem posição (na tela toda))* | A huge solar blast hitting: a deep sizzling whoosh with electric crackle and a heat roar; sound effect | o som de antes | pronto |
| `sfx/brinde` | 1.5 s | não | SFX | -12.0 | Um brinde na taverna. | A group of people raising wooden mugs: clinking and a cheer, an unintelligible shout; sound effect | o som de antes | pronto |
| `sfx/greve` | 3 s | não | SFX | -9.0 | A vila em greve bate panelas e ferramentas na praça. | An angry crowd banging tools and pots rhythmically in protest, tools hitting metal; sound effect | o som de antes | pronto |
| `sfx/achado` | 1 s | não | SFX | -8.0 | Um achado na escavação. | A discovery chime: a bright glint sound with a small stone clink, treasure found; sound effect | o som de antes | pronto |
| `sfx/robo` | 3 s | não | SFX | -6.0 | O robô antigo é ligado. | An ancient robot powering on: servo whirr, relay clicks and a deep electronic hum rising; sound effect | o som de antes | pronto |
| `sfx/explosao` | 3 s | não | SFX | -2.0 | Dinamite no entulho (e a pane do reator). | A dynamite blast in a mine: a deep boom with rock debris falling and an echo; sound effect | o som de antes | pronto |
| `sfx/lumivoro_grito_0`<br>`sfx/lumivoro_grito_1` | 0.8 s cada | não | SFX | -12.0 | O Lumívoro ataca. | A high-pitched screech of a glowing cave creature, shrill and alien; sound effect | o som de antes | pronto |
| `sfx/ferrugento_golpe_0`<br>`sfx/ferrugento_golpe_1` | 0.6 s cada | não | SFX | -10.0 | O Ferrugento ataca (garra de ferro). | A heavy metal creature striking: a clanking iron claw hit with scraping; sound effect | o som de antes | pronto |
| `sfx/golpe_0`<br>`sfx/golpe_1` | 0.4 s cada | não | SFX | -9.0 | Um golpe de arma acerta. | A weapon hitting a body in leather armor, a dull thump impact; sound effect | o som de antes | pronto |
| `sfx/portao_quebra` | 2 s | não | SFX | -4.0 | Uma barricada ou máquina quebra. | A wooden palisade gate smashing and splintering under attack, a heavy crack and timbers fa; sound effect | o som de antes | pronto |
| `sfx/criatura_cai` | 1 s | não | SFX | -8.0 | Uma criatura é derrubada. | A monster creature collapsing dead: a wet thud with a dying hiss; sound effect | o som de antes | pronto |
| `sfx/martelo_0`<br>`sfx/martelo_1`<br>`sfx/martelo_2` | 0.4 s cada | não | SFX | -12.0 | O engenheiro bate o martelo numa obra. | A hammer hitting a nail into a wooden beam, a short sharp knock; sound effect | o som de antes | pronto |
| `sfx/obra_pronta` | 1.2 s | não | SFX | -6.0 | Uma obra fica pronta. | Construction complete: a final hammer knock followed by a cheerful short wooden chime; sound effect | o som de antes | pronto |
| `sfx/colher_0`<br>`sfx/colher_1`<br>`sfx/colher_2` | 0.6 s cada | não | SFX | -12.0 | Colher na horta. | Picking a vegetable from soil: a soft root pull and leafy rustle; sound effect | o som de antes | pronto |
| `sfx/equipar` | 0.7 s | não | SFX | -10.0 | Pegar casaco, traje ou arma no vestiário. | Putting on a heavy coat and tool belt: leather and buckle rustle; sound effect | o som de antes | pronto |
| `sfx/festa` | 3 s | não | SFX | -8.0 | Uma festa começa na vila. *(sem posição (na tela toda))* | A village party burst: a cheering crowd, rhythmic clapping and a whoop; sound effect | o som de antes | pronto |
| `sfx/broca` | 1 s | não | SFX | -14.0 | O coletor de minério fura a rocha. | A short burst of an industrial rock drill biting into stone; sound effect | o som de antes | pronto |
| `sfx/vender` | 1 s | não | SFX | -6.0 | Vender no armazém. *(sem posição (na tela toda))* | Coins counted: several coins dropping and chinking into a leather purse; sound effect | o som de antes | pronto |
| `sfx/boas_vindas` | 1 s | não | SFX | -6.0 | Gente nova na vila e melhorias compradas. *(sem posição (na tela toda))* | A warm welcome chime: two soft bright bell notes with a gentle cheer; sound effect | o som de antes | pronto |
| `sfx/migrantes_chegando` | 4 s | não | SFX | -6.0 | Um grupo de migrantes chega no portão. | A small group of travelers arriving at a wooden gate: footsteps, a cart creak; sound effect | mudo | pronto |
| `sfx/portao_abre` | 3 s | não | SFX | -10.0 | O portão da paliçada abre. | A big wooden palisade gate opening: heavy creaking hinges and wood scraping with a final t; sound effect | o som de antes | pronto |
| `sfx/portao_fecha` | 3 s | não | SFX | -10.0 | O portão da paliçada fecha ao anoitecer. | A big wooden palisade gate closing: creaking hinges, wood scraping and a heavy wooden bar ; sound effect | o som de antes | pronto |
| `sfx/minerio_esgotado` | 2 s | não | SFX | -8.0 | Uma jazida esgota. | A rich ore vein finally collapsing: rocks crumbling and sliding with a dusty settle; sound effect | mudo | pronto |

## Animais

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `animais/coelho_foge_0`<br>`animais/coelho_foge_1`<br>`animais/coelho_foge_2` | 0.8 s cada | não | SFX | -10.0 | Um coelho foge de quem chega perto. | A small rabbit startled and bounding away: a quick leaf rustle and soft scurrying thumps w; animal sound | mudo | pronto |
| `animais/javali_grunhido_0`<br>`animais/javali_grunhido_1` | 1.2 s cada | não | SFX | -8.0 | Um javali percebe alguém perto. | A wild boar grunting and snorting aggressively, a deep wet snort; animal sound | mudo | pronto |
| `animais/coelho_morre` | 0.6 s | não | SFX | -10.0 | Um coelho é abatido. | A very short faint rabbit squeak and a soft thud; animal sound | mudo | pronto |
| `animais/javali_morre` | 1.5 s | não | SFX | -8.0 | Um javali é abatido. | A wild boar squeal followed by a heavy body falling; animal sound | mudo | pronto |

## Perigos (radiação)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `perigo/geiger_0`<br>`perigo/geiger_1`<br>`perigo/geiger_2`<br>`perigo/geiger_3` | 0.8 s cada | não | SFX | -12.0 | Alguém está sendo irradiado (onda solar, radiação do S2). | A Geiger counter crackling burst: rapid irregular clicks, a radiation warning; geiger counter | mudo | pronto |

## Criaturas (um som de ataque por espécie)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `criaturas/gosma_ataque_0`<br>`criaturas/gosma_ataque_1` | 0.8 s cada | não | SFX | -10.0 | A Gosma ataca. | An acidic slime creature attack: a wet splat with a sizzling hiss; monster creature | o som de antes | pronto |
| `criaturas/magmante_ataque_0`<br>`criaturas/magmante_ataque_1` | 1 s cada | não | SFX | -10.0 | O Magmante ataca. | A molten magma creature strike: a heavy fiery thump with a lava hiss and a rock crack; monster creature | o som de antes | pronto |
| `criaturas/matriarca_ataque_0`<br>`criaturas/matriarca_ataque_1` | 2 s cada | não | SFX | -6.0 | A Matriarca (a chefe) ataca. | A huge boss monster roar and heavy claw slam: a deep guttural roar with metallic resonance; monster creature | o som de antes | pronto |

## Máquinas

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `maquinas/quebrou` | 3 s | não | SFX | -4.0 | Uma máquina quebra. | A heavy machine breaking down: a loud metallic snap, grinding gears seizing and a sad wind; machine | o som de antes | pronto |
| `maquinas/consertada` | 3 s | não | SFX | -6.0 | Uma máquina é consertada e volta a funcionar. | A machine repaired and restarting: a wrench ratchet, a spark and the motor coughing then h; machine | o som de antes | pronto |

## Vida na vila (nascimento, casamento, enterro)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `vida/bebe_nasce_0`<br>`vida/bebe_nasce_1` | 2 s cada | não | SFX | -8.0 | Nasce um bebê. | A newborn baby's first cry, small and fragile; village | mudo | pronto |
| `vida/casamento` | 4 s | não | SFX | -6.0 | Um casal se casa. | A village wedding celebration: a short cheerful bell ring with the crowd cheering and clap; village | mudo | pronto |
| `vida/enterro` | 3 s | não | SFX | -8.0 | O padre enterra um morto no cemitério. | Digging a grave: a shovel cutting into earth and soil dropping; village | mudo | pronto |

## Passos por tipo de chão

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `passos/terra_0`<br>`passos/terra_1`<br>`passos/terra_2` | 0.3 s cada | não | SFX | -22.0 | Passo de ipezinho na terra (floresta, vila, caminho de terra batida). | A single footstep of a heavy work boot on packed dirt, short soft thud with slight grit; footstep | o som de antes | pronto |
| `passos/cascalho_0`<br>`passos/cascalho_1`<br>`passos/cascalho_2` | 0.3 s cada | não | SFX | -22.0 | Passo no cascalho (a pedreira e o caminho de cascalho). | A single footstep of a work boot on loose gravel, crunchy stones shifting; footstep | o som de antes | pronto |
| `passos/pedra_0`<br>`passos/pedra_1`<br>`passos/pedra_2` | 0.5 s cada | não | SFX | -22.0 | Passo na pedra (caminho de pedra e os andares fundos da mina). | One footstep on a solid stone floor, hard shoe heel; footstep | o som de antes | pronto |
| `passos/madeira_0`<br>`passos/madeira_1`<br>`passos/madeira_2` | 0.35 s cada | não | SFX | -22.0 | Passo na madeira (plataformas, elevadores e escadas). | A single footstep on an old wooden plank platform, hollow thud with a slight creak; footstep | o som de antes | pronto |
| `passos/agua_0`<br>`passos/agua_1`<br>`passos/agua_2` | 0.4 s cada | não | SFX | -22.0 | Passo na água (as poças do S2 e do S3). | A single clear, loud footstep of a boot splashing into a shallow puddle; footstep | o som de antes | pronto |

## Voz curta dos ipezinhos (desligável)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `voz/homem_ordem_0`<br>`voz/homem_ordem_1` | 0.7 s cada | não | SFX | -14.0 | Voz curta (homem) quando recebe uma ordem do jogador: 'Sim!', 'Pode deixar'. Menos de 1 s. | A short gruff male worker voice acknowledging an order, an energetic 'yes; voice grunt | mudo | pronto |
| `voz/homem_dor_0`<br>`voz/homem_dor_1` | 0.5 s cada | não | SFX | -12.0 | Voz curta (homem) ao se machucar: 'Ai!'. Menos de 1 s. | A short male grunt of pain, 'ugh!'; voice grunt | mudo | pronto |
| `voz/homem_alegria_0`<br>`voz/homem_alegria_1` | 0.8 s cada | não | SFX | -14.0 | Voz curta (homem) num brinde ou festa: riso e 'Eita!'. Menos de 1 s. | A short happy male laugh followed by a cheerful 'hey!'; voice grunt | mudo | pronto |
| `voz/homem_cansaco_0`<br>`voz/homem_cansaco_1` | 1.3 s cada | não | SFX | -14.0 | Voz curta (homem) cansado, indo dormir: suspiro e bocejo. Menos de 1,5 s. | A long tired male sigh followed by a small yawn; voice grunt | mudo | pronto |
| `voz/mulher_ordem_0`<br>`voz/mulher_ordem_1` | 0.7 s cada | não | SFX | -14.0 | Voz curta (mulher) quando recebe uma ordem do jogador. Menos de 1 s. | A short determined female worker voice acknowledging an order, an energetic 'yes!' style e; voice grunt | mudo | pronto |
| `voz/mulher_dor_0`<br>`voz/mulher_dor_1` | 0.5 s cada | não | SFX | -12.0 | Voz curta (mulher) ao se machucar. Menos de 1 s. | A short female gasp of pain, 'ah!'; voice grunt | mudo | pronto |
| `voz/mulher_alegria_0`<br>`voz/mulher_alegria_1` | 0.8 s cada | não | SFX | -14.0 | Voz curta (mulher) num brinde ou festa. Menos de 1 s. | A short happy female laugh followed by a cheerful 'oh!'; voice grunt | mudo | pronto |
| `voz/mulher_cansaco_0`<br>`voz/mulher_cansaco_1` | 1.3 s cada | não | SFX | -14.0 | Voz curta (mulher) cansada, indo dormir. Menos de 1,5 s. | A long tired female sigh followed by a small yawn; voice grunt | mudo | pronto |
| `voz/homem_ola_0`<br>`voz/homem_ola_1` | 0.6 s cada | não | SFX | -14.0 | Voz curta (homem) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s. | A short friendly male greeting, a casual 'hey there!'; voice grunt | mudo | pronto |
| `voz/mulher_ola_0`<br>`voz/mulher_ola_1` | 0.6 s cada | não | SFX | -14.0 | Voz curta (mulher) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s. | A short friendly female greeting, a casual 'hey there!'; voice grunt | mudo | pronto |

## Sons soltos pelo ambiente (aleatórios)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `pontuais/passaro_canto_0`<br>`pontuais/passaro_canto_1`<br>`pontuais/passaro_canto_2`<br>`pontuais/passaro_canto_3` | 3 s cada | não | Ambience | -12.0 | Floresta de dia: um pássaro canta de vez em quando. *(toca a cada 5 a 12 s enquanto vale: dia)* | A single bird song phrase in a forest, clear and melodic; nature one shot | mudo | pronto |
| `pontuais/corvo_0`<br>`pontuais/corvo_1` | 2 s cada | não | Ambience | -14.0 | Floresta de dia: um corvo ao longe. *(toca a cada 20 a 45 s enquanto vale: dia)* | A crow cawing one or two harsh caws, distant; nature one shot | mudo | pronto |
| `pontuais/coruja_0`<br>`pontuais/coruja_1` | 3 s cada | não | Ambience | -14.0 | Floresta de noite: uma coruja. *(toca a cada 15 a 35 s enquanto vale: noite)* | An owl hooting, deep and soft; nature one shot | mudo | pronto |
| `pontuais/lobo_uivo_0`<br>`pontuais/lobo_uivo_1` | 5 s cada | não | Ambience | -16.0 | Floresta de noite: um lobo uiva ao longe. *(toca a cada 40 a 90 s enquanto vale: noite)* | A distant wolf howling at night, long and mournful; nature one shot | mudo | pronto |
| `pontuais/sapo_0`<br>`pontuais/sapo_1` | 3 s cada | não | Ambience | -14.0 | Floresta de noite: sapos num brejo. *(toca a cada 12 a 30 s enquanto vale: noite)* | A few frogs croaking by a pond at night; nature one shot | mudo | pronto |
| `pontuais/trovao_0`<br>`pontuais/trovao_1`<br>`pontuais/trovao_2` | 6 s cada | não | Ambience | -8.0 | Quando chove: um trovão. *(toca a cada 20 a 50 s enquanto vale: chuva)* | Rolling thunder, a distant to medium rumble that builds and fades; nature one shot | mudo | pronto |
| `pontuais/vento_rajada_0`<br>`pontuais/vento_rajada_1` | 4 s cada | não | Ambience | -12.0 | No inverno: uma rajada de vento. *(toca a cada 10 a 25 s enquanto vale: vento)* | A cold wind gust sweeping past, rising and fading; nature one shot | mudo | pronto |
| `pontuais/pedra_cai_0`<br>`pontuais/pedra_cai_1`<br>`pontuais/pedra_cai_2` | 2 s cada | não | Ambience | -14.0 | Na mina: pedrinhas caem da parede. *(toca a cada 25 a 60 s enquanto vale: mina)* | A few small stones falling and rattling down a mine wall with a dusty echo; nature one shot | mudo | pronto |
| `pontuais/gotejar_0`<br>`pontuais/gotejar_1`<br>`pontuais/gotejar_2` | 1.5 s cada | não | Ambience | -16.0 | Na mina e no S2: uma gota cai. *(toca a cada 8 a 20 s enquanto vale: mina/s2)* | A single clear, loud water drip falling into a pool in a cave; nature one shot | mudo | pronto |
| `pontuais/acido_borbulha_0`<br>`pontuais/acido_borbulha_1`<br>`pontuais/acido_borbulha_2` | 1.5 s cada | não | Ambience | -14.0 | S2: uma bolha grande de ácido estoura. *(toca a cada 6 a 15 s enquanto vale: s2)* | A large acid bubble popping with a hiss in a cavern; nature one shot | mudo | pronto |
| `pontuais/lava_estalo_0`<br>`pontuais/lava_estalo_1`<br>`pontuais/lava_estalo_2` | 1.5 s cada | não | Ambience | -14.0 | S3: a rocha esfriando estala. *(toca a cada 5 a 14 s enquanto vale: s3)* | Cooling lava rock cracking loudly with an ember pop and a hiss; nature one shot | mudo | pronto |
| `pontuais/gota_eco_0`<br>`pontuais/gota_eco_1`<br>`pontuais/gota_eco_2` | 3 s cada | não | Ambience | -16.0 | S5: uma gota cai no lago. *(toca a cada 7 a 18 s enquanto vale: s5)* | A single water droplet falling into a still underground lake with a long dreamy echo; nature one shot | mudo | pronto |

## Sons da introdução

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `intro/explosao` | 6 s | não | SFX | -6.0 | Quadro 1 da introdução: o sol explode sobre a cidade mineira. | Cinematic massive solar flare explosion over a city: a huge deep boom with a rising roar a; cinematic | mudo | pronto |
| `intro/vento` | 6 s | não | SFX | -6.0 | Quadro 2 da introdução: cidades em ruína, vento e silêncio. | Lonely wind through a ruined abandoned city, distant creaking metal and drifting dust; cinematic | mudo | pronto |
| `intro/caravana` | 6 s | não | SFX | -6.0 | Quadro 3 da introdução: a caravana a caminho da pedreira (passos, carroça). | A caravan of people and a wooden cart moving along a gravel road: footsteps, cart wheels c; cinematic | mudo | pronto |
| `intro/pedreira` | 6 s | não | SFX | -6.0 | Quadro 4 (no mapa): a câmera atravessa a pedreira. | Quarry atmosphere: distant hammering on stone, wind; cinematic | mudo | pronto |
| `intro/mina` | 6 s | não | SFX | -6.0 | Quadro 6 (no mapa): o corte da mina descendo andar por andar. | Cinematic descent into a deep mine: a low rumble that deepens, falling rocks and metal ele; cinematic | mudo | pronto |
| `intro/fogo` | 6 s | não | SFX | -6.0 | Quadro 7 (no mapa): a fogueira acesa no meio da vila. | A campfire crackling warmly with a few people murmuring around it and night insects, calm; cinematic | mudo | pronto |
| `intro/titulo` | 3 s | não | SFX | -6.0 | O título DEEP IRON aparece: batida grave e curta. | Deep cinematic title hit: a powerful low impact with metal resonance and a long tail; cinematic | mudo | pronto |

## Música (FORA do ElevenLabs de efeitos)

| Arquivo(s) em `assets/audio/` | Duração | Loop | Bus | dB | Descrição | Termos de busca | Sem arquivo | Estado |
|---|---|---|---|---|---|---|---|---|
| `musica/abertura` | Música (fora desta lista de efeitos) | sim | Music | 0.0 | A ABERTURA do jogo: toca na tela inicial (o menu). Loop de 1 a 2 minutos, tema principal do DEEP IRON (sol, ruína, esperança). | A ABERTURA do jogo: toca na tela inicial . Loop de 1 a 2 minutos, tema principal do DEEP I; game music loop | mudo | falta |
| `musica/intro` | Música (fora desta lista de efeitos) | não | Music | 0.0 | A INTRODUÇÃO (3 quadros ilustrados + 4 no mapa, uns 60 s): uma peça só, crescendo da explosão até a fogueira e o título. Não repete. | A INTRODUÇÃO : uma peça só, crescendo da explosão até a fogueira e o título. Não repete; game music loop | mudo | falta |
