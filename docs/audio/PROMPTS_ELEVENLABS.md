# Prompts do ElevenLabs — todos os sons do jogo, menos a música

Gerado por `python tools/elevenlabs/docs_audio.py` a partir de `project.godot/data/audio/slots.json` (campos `prompt` e `duracao`). **Não edite à mão: mude o prompt no `slots.json` e rode a ferramenta.**

**126 sons (191 arquivos)**. A música da abertura e da introdução fica de fora (lista no fim).

## Como usar

1. A ferramenta `tools/elevenlabs/gerar_sons.py` já usa estes prompts pela API (`--dry-run` mostra o custo antes). Pra gerar à mão, no ElevenLabs **Sound Effects**: cole o prompt, ponha a **duração** indicada e ligue **loop** nos sons de loop.
2. Prompts em inglês: *dark, dusty, industrial*; *isolated sound, no music, no speech*; *close microphone, dry* nos curtos; *seamless loop* nos loops.
3. **Variações** (`_0`, `_1`...): o mesmo prompt gerado várias vezes; o jogo sorteia entre elas. `--candidatos N` gera N pra você escolher.
4. Os **stingers** são frases curtas de música/efeito: se o gerador de efeitos não fizer bem, gere na ferramenta de música e salve com o mesmo nome.
5. As **vozes curtas** (`voz/`) podem sair do Text to Speech em português se preferir fala de verdade (as frases sugeridas estão entre parênteses).


## Ambiência (loops por andar, clima e onda solar)

### 1. `ambiencia/mina`

- **Arquivo(s):** `ambiencia/mina`
- **Duração:** loop 40 s  •  **Tipo:** loop
- **Onde toca:** Vila, pedreira e túneis do S1 (a câmera na área da mina). Loop contínuo, sem pico alto.

> Seamless loop, deep underground quarry and mine ambience, low steady cave air tone, distant water dripping, faint far-off metal creaks and stone settling, wide stereo, no music, no voices, no sudden loud events.

### 2. `ambiencia/floresta_dia`

- **Arquivo(s):** `ambiencia/floresta_dia`
- **Duração:** loop 40 s  •  **Tipo:** loop
- **Onde toca:** Floresta e clareira de dia: pássaros, folhas, vento leve.

> Seamless loop, peaceful boreal forest clearing in daytime, several small birds singing and calling at different distances, leaves rustling in a light breeze, no voices, no music.

### 3. `ambiencia/floresta_noite`

- **Arquivo(s):** `ambiencia/floresta_noite`
- **Duração:** loop 40 s  •  **Tipo:** loop
- **Onde toca:** Floresta e clareira de noite: grilos e uma coruja distante.

> Seamless loop, forest clearing at night, many crickets chirping steadily, a very light breeze through trees, calm and slightly eerie, no music, no voices.

### 4. `ambiencia/vento_inverno`

- **Arquivo(s):** `ambiencia/vento_inverno`
- **Duração:** loop 30 s  •  **Tipo:** loop
- **Onde toca:** CAMADA por cima da floresta e da vila no inverno: vento frio e constante, sem pássaros.

> Seamless loop, cold winter wind blowing steadily across an open snowy landscape, soft whistling through bare branches and wooden walls, no birds, no music.

### 5. `ambiencia/chuva`

- **Arquivo(s):** `ambiencia/chuva`
- **Duração:** loop 30 s  •  **Tipo:** loop
- **Onde toca:** CAMADA por cima da clareira quando está chovendo.

> Seamless loop, steady rain falling on dirt ground, wooden roofs and leaves, medium intensity, soft constant patter, no thunder, no music.

### 6. `ambiencia/s2_acido`

- **Arquivo(s):** `ambiencia/s2_acido`
- **Duração:** loop 40 s  •  **Tipo:** loop
- **Onde toca:** S2 (ácido e gás): bolhas de ácido borbulhando e gotejar.

> Seamless loop, underground cave filled with toxic acid pools, slow viscous bubbling and popping, hissing gas vents, occasional single water drips echoing in a stone cavern, ominous, no music.

### 7. `ambiencia/s3_lava`

- **Arquivo(s):** `ambiencia/s3_lava`
- **Duração:** loop 40 s  •  **Tipo:** loop
- **Onde toca:** S3 (lava): lava borbulhando e ronco grave de fundo.

> Seamless loop, cavern beside a lava lake, thick bubbling and gurgling magma, deep low rumble, occasional crackle of cooling rock and hiss of steam, hot oppressive atmosphere, no music.

### 8. `ambiencia/s4_cachoeira`

- **Arquivo(s):** `ambiencia/s4_cachoeira`
- **Duração:** loop 40 s  •  **Tipo:** loop
- **Onde toca:** S4 (cachoeira e lava): queda d'água constante ao longe.

> Seamless loop, huge underground waterfall crashing into a pool inside a big cave, constant roaring water with spray, deep echoing reverb, no music.

### 9. `ambiencia/s5_lago`

- **Arquivo(s):** `ambiencia/s5_lago`
- **Duração:** loop 40 s  •  **Tipo:** loop  •  eco 0.35
- **Onde toca:** S5 (lago azul): gotas e água parada, o jogo põe o eco (reverb) sozinho.

> Seamless loop, calm underground lake in a huge cavern, gentle water lapping, sparse droplets falling into water, very quiet airy tone, dry (the game adds the echo), no music.

### 10. `ambiencia/onda_solar`

- **Arquivo(s):** `ambiencia/onda_solar`
- **Duração:** loop 30 s  •  **Tipo:** loop
- **Onde toca:** CAMADA durante a onda solar, na superfície: calor, rugido e estática.

> Seamless loop, scorching solar flare disaster over the surface, a deep rising roar like a distant furnace and heat shimmer, crackling electrical static and low rumbling, tense, no voices, no music.


## Prédios e lugares (loops posicionais e sinos)

### 11. `predios/fornalha`

- **Arquivo(s):** `predios/fornalha`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Fornalha acesa (só enquanto o fundidor funde): fogo e foles.

> Seamless loop, blast furnace burning, roaring fire with bellows breathing in and out slowly, crackling coals, occasional metal creak, close-up industrial, no voices.

### 12. `predios/carpintaria`

- **Arquivo(s):** `predios/carpintaria`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Carpintaria com ordem em andamento: serra e martelo.

> Seamless loop, busy carpentry workshop, rhythmic hand saw cutting wood, occasional hammer taps on nails, steady and cozy, no voices, no music.

### 13. `predios/taverna`

- **Arquivo(s):** `predios/taverna`
- **Duração:** loop 30 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Taverna com gente dentro: murmúrio, canecas, riso.

> Seamless loop, small tavern interior, low murmur of a few people chatting (unintelligible, no clear words), wooden mugs clinking, soft laughter now and then, warm, no music.

### 14. `predios/cemiterio`

- **Arquivo(s):** `predios/cemiterio`
- **Duração:** loop 30 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Cemitério (sempre): vento baixo e um corvo distante.

> Seamless loop, quiet graveyard at dusk, low soft wind, faint creak of an old wooden fence, melancholic, no music, no voices.

### 15. `predios/vagonete`

- **Arquivo(s):** `predios/vagonete`
- **Duração:** loop 20 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Vagonete andando no trilho: rodas de ferro.

> Seamless loop, heavy iron mine cart rolling on rails, rhythmic wheel clacks at the rail joints and a low metal rumble, steady speed, no voices.

### 16. `predios/coletor_madeira`

- **Arquivo(s):** `predios/coletor_madeira`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Coletor de madeira funcionando: engrenagem e serra mecânica.

> Seamless loop, small steam-powered wood-collecting machine working, rhythmic clanking gears, wooden logs knocking, hissing steam puffs, no voices.

### 17. `predios/coletor_minerio`

- **Arquivo(s):** `predios/coletor_minerio`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Coletor de minério funcionando: motor e broca.

> Seamless loop, automatic ore-drilling machine working, powerful rotary drill grinding rock, motor chugging, small stones clattering into a bin, no voices.

### 18. `predios/sino_missa`

- **Arquivo(s):** `predios/sino_missa`
- **Duração:** 8 s  •  **Tipo:** toca uma vez  •  abaixa a música (sino)
- **Onde toca:** Sino da igreja quando a missa de domingo começa (posicional, na igreja).

> A single large church bell tolling slowly three times in a village, warm resonant bronze tone with natural decay and a little distant reverb, nothing else.

### 19. `predios/sino_funeral`

- **Arquivo(s):** `predios/sino_funeral`
- **Duração:** 12 s  •  **Tipo:** toca uma vez  •  abaixa a música (sino)
- **Onde toca:** Sino da igreja (ou do cemitério) quando o funeral começa: mais lento e grave.

> A slow low funeral bell, five deep tolls spaced far apart, solemn bronze tone with long decay and echo, sad, nothing else.

### 20. `predios/poca_perigo`

- **Arquivo(s):** `predios/poca_perigo`
- **Duração:** loop 20 s  •  **Tipo:** loop posicional  •  só perto da câmera (400 px), com o prédio em atividade
- **Onde toca:** Perto de uma poça de ácido ou lava (sempre): borbulhar baixo e chiado.

> Seamless loop, a small pool of toxic acid, slow bubbling and soft hissing with faint gas escaping, close, no music.

### 21. `predios/ventilador`

- **Arquivo(s):** `predios/ventilador`
- **Duração:** loop 20 s  •  **Tipo:** loop posicional  •  só perto da câmera (500 px), com o prédio em atividade
- **Onde toca:** Perto de um ventilador da mina (sempre): zumbido de ar.

> Seamless loop, a large industrial mine ventilation fan spinning, steady whooshing air and a soft metallic whirr, low hum, no voices.

### 22. `predios/tocha`

- **Arquivo(s):** `predios/tocha`
- **Duração:** loop 20 s  •  **Tipo:** loop posicional  •  só perto da câmera (350 px), com o prédio em atividade
- **Onde toca:** Perto de uma tocha acesa (sempre): fogo crepitando.

> Seamless loop, a wall torch burning, soft crackling fire with gentle flame flutter, close, no music.

### 23. `predios/conversa`

- **Arquivo(s):** `predios/conversa`
- **Duração:** loop 30 s  •  **Tipo:** loop posicional  •  só perto da câmera (500 px), com o prédio em atividade
- **Onde toca:** Num ponto social (refeitório, praça, parque, igreja...) com gente reunida: o murmúrio da conversa.

> Seamless loop, a small crowd of villagers chatting quietly, indistinct overlapping murmur with no intelligible words, cups and cutlery occasionally, warm ambience, no music.

### 24. `predios/oficina`

- **Arquivo(s):** `predios/oficina`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Oficina com o ferreiro trabalhando: martelo na bigorna.

> Seamless loop, a blacksmith workshop, rhythmic hammer on anvil with ringing metal, fire crackle between the strikes, an occasional hiss of quenching, no voices.

### 25. `predios/arsenal`

- **Arquivo(s):** `predios/arsenal`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Arsenal com o ferreiro trabalhando: metal batido e armas.

> Seamless loop, an armory forge, metal being hammered and filed, weapons clanking on racks, fire crackle, no voices.

### 26. `predios/laboratorio`

- **Arquivo(s):** `predios/laboratorio`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Laboratório com a pesquisadora trabalhando: líquidos borbulhando.

> Seamless loop, an old-fashioned laboratory, liquids bubbling in glass flasks, a soft electrical hum, an occasional glass clink, curious, no voices, no music.

### 27. `predios/escavadeira`

- **Arquivo(s):** `predios/escavadeira`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (700 px), com o prédio em atividade
- **Onde toca:** Escavadeira gigante funcionando: motor e broca.

> Seamless loop, a giant steam excavator drilling machine running, deep engine chugging, a grinding drill and steam hissing, heavy industrial, no voices.

### 28. `predios/escola`

- **Arquivo(s):** `predios/escola`
- **Duração:** loop 30 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Escola com gente dentro: crianças ao longe e giz.

> Seamless loop, a small village schoolroom, children murmuring and giggling softly in the distance (no clear words), chalk scratching, a calm low teacher voice (unintelligible), no music.

### 29. `predios/cozinha`

- **Arquivo(s):** `predios/cozinha`
- **Duração:** loop 25 s  •  **Tipo:** loop posicional  •  só perto da câmera (600 px), com o prédio em atividade
- **Onde toca:** Cozinha com o cozinheiro trabalhando: panela e fogão.

> Seamless loop, a communal kitchen, a big pot of stew simmering, a ladle stirring, a knife chopping vegetables now and then, wood stove crackle, no voices.


## Stingers (eventos do jogo)

### 30. `stingers/amanhecer`

- **Arquivo(s):** `stingers/amanhecer`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** Começa um novo dia (05:00): curto, claro, 2 a 3 s.

> Short gentle sunrise sting: a soft rising chime with a warm low string swell and a few birds starting to chirp, hopeful, 3 seconds, ends cleanly.

### 31. `stingers/onda_solar`

- **Arquivo(s):** `stingers/onda_solar`
- **Duração:** 4 s  •  **Tipo:** toca uma vez  •  abaixa a música (alarme)
- **Onde toca:** O aviso 'ONDA SOLAR CHEGANDO' (tensão crescente, 3 a 4 s).

> Ominous warning sting: a rising low metallic drone with a deep pulsing alarm swell and electrical crackle, building tension, 4 seconds.

### 32. `stingers/estagio_novo`

- **Arquivo(s):** `stingers/estagio_novo`
- **Duração:** 4 s  •  **Tipo:** toca uma vez
- **Onde toca:** A vila sobe de estágio: fanfarra de conquista, 3 a 4 s.

> Triumphant achievement sting: bright brass fanfare with a rolling drum hit and ascending anvil strikes, proud, 4 seconds.

### 33. `stingers/pesquisa_pronta`

- **Arquivo(s):** `stingers/pesquisa_pronta`
- **Duração:** 2.5 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma pesquisa termina: brilho curto, 2 s.

> Short discovery sting: a sparkling bell chime run upward with a soft magical shimmer, curious and satisfying, 2 seconds.

### 34. `stingers/morte`

- **Arquivo(s):** `stingers/morte`
- **Duração:** 4 s  •  **Tipo:** toca uma vez  •  abaixa a música (sino)
- **Onde toca:** Um ipezinho morre: sino fúnebre curto e triste.

> Mournful sting: one slow low funeral bell toll with a faint sad cello note fading away, 4 seconds.

### 35. `stingers/vitoria`

- **Arquivo(s):** `stingers/vitoria`
- **Duração:** 7 s  •  **Tipo:** toca uma vez
- **Onde toca:** Vitória (o escudo solar fica pronto): triunfo, 5 a 8 s.

> Epic victory sting: a big triumphant brass and drum swell resolving into a held major chord with a cymbal crash, emotional and heroic, 7 seconds.

### 36. `stingers/derrota`

- **Arquivo(s):** `stingers/derrota`
- **Duração:** 5 s  •  **Tipo:** toca uma vez  •  abaixa a música (sino)
- **Onde toca:** Derrota (os ipezinhos expulsam o jogador): grave e vazio, 4 a 6 s.

> Defeat sting: a heavy low drone collapsing downward with a dull distant gong and fading wind, hopeless, 5 seconds.

### 37. `stingers/missao_cumprida`

- **Arquivo(s):** `stingers/missao_cumprida`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma missão é cumprida: fanfarra curta de recompensa, 2 a 3 s.

> Short reward sting: a cheerful ascending three-note chime with a soft drum accent and a sparkle, 2.5 seconds.


## Interface (bus UI)

### 38. `ui/abrir_janela`

- **Arquivo(s):** `ui/abrir_janela`
- **Duração:** 0.3 s  •  **Tipo:** toca uma vez
- **Onde toca:** Abrir uma janela: whoosh/papel curto, menos de 0,3 s.

> Soft game UI sound: a wooden panel sliding open with a light paper rustle, very short, 0.3 seconds.

### 39. `ui/fechar_janela`

- **Arquivo(s):** `ui/fechar_janela`
- **Duração:** 0.3 s  •  **Tipo:** toca uma vez
- **Onde toca:** Fechar uma janela: o oposto do abrir, menos de 0,3 s.

> Soft game UI sound: a wooden panel sliding closed with a light paper rustle, very short, 0.3 seconds.

### 40. `ui/confirmar`

- **Arquivo(s):** `ui/confirmar`
- **Duração:** 0.5 s  •  **Tipo:** toca uma vez
- **Onde toca:** Confirmar (pôr um prédio, marcar uma área, comprar): toque firme e satisfatório.

> Satisfying UI confirm sound: a firm wooden stamp thud with a tiny metallic ring, 0.4 seconds.

### 41. `ui/erro`

- **Arquivo(s):** `ui/erro`
- **Duração:** 0.4 s  •  **Tipo:** toca uma vez
- **Onde toca:** Ação negada (sem recurso, lugar inválido): buzz curto e seco.

> Negative UI sound: a short dull low buzzer thunk, dry, 0.4 seconds.

### 42. `ui/clique`

- **Arquivo(s):** `ui/clique`
- **Duração:** 0.15 s  •  **Tipo:** toca uma vez
- **Onde toca:** Clique de botão: tec curto e suave.

> Subtle UI button click: a small wooden tick, extremely short, 0.1 seconds.

### 43. `ui/noticia_boa`

- **Arquivo(s):** `ui/noticia_boa`
- **Duração:** 0.6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Aviso bom (aviso verde): dois toques ascendentes, 0,5 s.

> Positive notification: two ascending soft bell notes, 0.6 seconds.

### 44. `ui/noticia_ruim`

- **Arquivo(s):** `ui/noticia_ruim`
- **Duração:** 0.6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Aviso ruim (aviso vermelho): dois toques descendentes, 0,5 s.

> Negative notification: two descending dull bell notes, 0.6 seconds.


## Efeitos do jogo (trabalho, combate, obras, avisos)

### 45. `sfx/picareta`

- **Arquivo(s):** `sfx/picareta_0`, `sfx/picareta_1`, `sfx/picareta_2`
- **Duração:** 0.5 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** O ipezinho dá um golpe de picareta na pedra.

> A pickaxe striking hard rock, one sharp metallic clink with small stone chips flying, dry close-up, 0.5 seconds, no other sounds.

### 46. `sfx/deposito`

- **Arquivo(s):** `sfx/deposito_0`, `sfx/deposito_1`, `sfx/deposito_2`
- **Duração:** 0.7 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Entrega o minério (ou a madeira) no armazém.

> Dropping a handful of ore chunks into a wooden storage bin, rocks clattering, 0.7 seconds, no voices.

### 47. `sfx/comer`

- **Arquivo(s):** `sfx/comer_0`, `sfx/comer_1`, `sfx/comer_2`
- **Duração:** 1 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Um ipezinho come no refeitório.

> A person eating stew with a wooden spoon, a couple of quick chews and a small satisfied gulp, close, 1 second, no words.

### 48. `sfx/ferido`

- **Arquivo(s):** `sfx/ferido`
- **Duração:** 0.6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Um ipezinho se machuca (acidente, criatura, radiação).

> The impact of a worker getting hurt followed by a short pained grunt, no words, 0.6 seconds.

### 49. `sfx/curar`

- **Arquivo(s):** `sfx/curar`
- **Duração:** 1 s  •  **Tipo:** toca uma vez
- **Onde toca:** A enfermaria cura um paciente.

> A soft healing sound: a gentle bandage rustle with a warm reassuring chime, 1 second.

### 50. `sfx/forja`

- **Arquivo(s):** `sfx/forja`
- **Duração:** 0.8 s  •  **Tipo:** toca uma vez
- **Onde toca:** A oficina, o arsenal ou a escavadeira forjam uma peça.

> A hammer strike on hot iron on an anvil with ringing metal and a spark hiss, 0.8 seconds.

### 51. `sfx/machadada`

- **Arquivo(s):** `sfx/machadada_0`, `sfx/machadada_1`, `sfx/machadada_2`
- **Duração:** 0.6 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** O lenhador dá uma machadada na árvore.

> An axe chopping into a tree trunk, a heavy wooden thock with wood chips, 0.6 seconds, no other sounds.

### 52. `sfx/elevador`

- **Arquivo(s):** `sfx/elevador`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** O elevador sobe ou desce.

> A mine elevator cage starting to move: heavy chain rattle, a winch rattling and a metal clunk, 3 seconds.

### 53. `sfx/galho`

- **Arquivo(s):** `sfx/galho`
- **Duração:** 2 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma árvore cai.

> A tree branch snapping and a trunk creaking as it begins to fall, 2 seconds.

### 54. `sfx/fanfarra`

- **Arquivo(s):** `sfx/fanfarra`
- **Duração:** 3 s  •  **Tipo:** toca uma vez  •  sem posição (na tela toda)
- **Onde toca:** Uma conquista (a Matriarca cai, a escavadeira fica pronta, o abismo abre, o fim da greve).

> A short triumphant brass fanfare, 3 seconds.

### 55. `sfx/sino_funebre`

- **Arquivo(s):** `sfx/sino_funebre`
- **Duração:** 4 s  •  **Tipo:** toca uma vez  •  sem posição (na tela toda); abaixa a música (sino)
- **Onde toca:** O último aviso da greve e o som antigo do funeral.

> A single low funeral bell toll with a long decay, 4 seconds.

### 56. `sfx/alarme_invasao`

- **Arquivo(s):** `sfx/alarme_invasao`
- **Duração:** 3 s  •  **Tipo:** toca uma vez  •  sem posição (na tela toda); abaixa a música (alarme)
- **Onde toca:** Começa uma invasão de criaturas (e o aviso da onda solar, sem o stinger).

> A loud war horn blast followed by a second lower blast, an urgent alarm, 3 seconds.

### 57. `sfx/solar`

- **Arquivo(s):** `sfx/solar`
- **Duração:** 3 s  •  **Tipo:** toca uma vez  •  sem posição (na tela toda)
- **Onde toca:** A onda solar chega.

> A huge solar blast hitting: a deep sizzling whoosh with electric crackle and a heat roar, 3 seconds.

### 58. `sfx/brinde`

- **Arquivo(s):** `sfx/brinde`
- **Duração:** 1.5 s  •  **Tipo:** toca uma vez
- **Onde toca:** Um brinde na taverna.

> A group of people raising wooden mugs: clinking and a cheer, an unintelligible shout, 1.5 seconds.

### 59. `sfx/greve`

- **Arquivo(s):** `sfx/greve`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** A vila em greve bate panelas e ferramentas na praça.

> An angry crowd banging tools and pots rhythmically in protest, tools hitting metal, muffled shouts with no words, 3 seconds.

### 60. `sfx/achado`

- **Arquivo(s):** `sfx/achado`
- **Duração:** 1 s  •  **Tipo:** toca uma vez
- **Onde toca:** Um achado na escavação.

> A discovery chime: a bright glint sound with a small stone clink, treasure found, 1 second.

### 61. `sfx/robo`

- **Arquivo(s):** `sfx/robo`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** O robô antigo é ligado.

> An ancient robot powering on: servo whirr, relay clicks and a deep electronic hum rising, 3 seconds.

### 62. `sfx/explosao`

- **Arquivo(s):** `sfx/explosao`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** Dinamite no entulho (e a pane do reator).

> A dynamite blast in a mine: a deep boom with rock debris falling and an echo, 3 seconds.

### 63. `sfx/lumivoro_grito`

- **Arquivo(s):** `sfx/lumivoro_grito_0`, `sfx/lumivoro_grito_1`
- **Duração:** 0.8 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** O Lumívoro ataca.

> A high-pitched screech of a glowing cave creature, shrill and alien, 0.8 seconds.

### 64. `sfx/ferrugento_golpe`

- **Arquivo(s):** `sfx/ferrugento_golpe_0`, `sfx/ferrugento_golpe_1`
- **Duração:** 0.6 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** O Ferrugento ataca (garra de ferro).

> A heavy metal creature striking: a clanking iron claw hit with scraping, 0.6 seconds.

### 65. `sfx/golpe`

- **Arquivo(s):** `sfx/golpe_0`, `sfx/golpe_1`
- **Duração:** 0.4 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Um golpe de arma acerta.

> A weapon hitting a body in leather armor, a dull thump impact, 0.4 seconds.

### 66. `sfx/portao_quebra`

- **Arquivo(s):** `sfx/portao_quebra`
- **Duração:** 2 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma barricada ou máquina quebra.

> A wooden palisade gate smashing and splintering under attack, a heavy crack and timbers falling, 2 seconds.

### 67. `sfx/criatura_cai`

- **Arquivo(s):** `sfx/criatura_cai`
- **Duração:** 1 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma criatura é derrubada.

> A monster creature collapsing dead: a wet thud with a dying hiss, 1 second.

### 68. `sfx/martelo`

- **Arquivo(s):** `sfx/martelo_0`, `sfx/martelo_1`, `sfx/martelo_2`
- **Duração:** 0.4 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** O engenheiro bate o martelo numa obra.

> A hammer hitting a nail into a wooden beam, a short sharp knock, 0.4 seconds.

### 69. `sfx/obra_pronta`

- **Arquivo(s):** `sfx/obra_pronta`
- **Duração:** 1.2 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma obra fica pronta.

> Construction complete: a final hammer knock followed by a cheerful short wooden chime, 1.2 seconds.

### 70. `sfx/colher`

- **Arquivo(s):** `sfx/colher_0`, `sfx/colher_1`, `sfx/colher_2`
- **Duração:** 0.6 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Colher na horta.

> Picking a vegetable from soil: a soft root pull and leafy rustle, 0.6 seconds.

### 71. `sfx/equipar`

- **Arquivo(s):** `sfx/equipar`
- **Duração:** 0.7 s  •  **Tipo:** toca uma vez
- **Onde toca:** Pegar casaco, traje ou arma no vestiário.

> Putting on a heavy coat and tool belt: leather and buckle rustle, 0.7 seconds.

### 72. `sfx/festa`

- **Arquivo(s):** `sfx/festa`
- **Duração:** 3 s  •  **Tipo:** toca uma vez  •  sem posição (na tela toda)
- **Onde toca:** Uma festa começa na vila.

> A village party burst: a cheering crowd, rhythmic clapping and a whoop, 3 seconds.

### 73. `sfx/broca`

- **Arquivo(s):** `sfx/broca`
- **Duração:** 1 s  •  **Tipo:** toca uma vez
- **Onde toca:** O coletor de minério fura a rocha.

> A short burst of an industrial rock drill biting into stone, 1 second.

### 74. `sfx/vender`

- **Arquivo(s):** `sfx/vender`
- **Duração:** 1 s  •  **Tipo:** toca uma vez  •  sem posição (na tela toda)
- **Onde toca:** Vender no armazém.

> Coins counted: several coins dropping and chinking into a leather purse, 1 second.

### 75. `sfx/boas_vindas`

- **Arquivo(s):** `sfx/boas_vindas`
- **Duração:** 1 s  •  **Tipo:** toca uma vez  •  sem posição (na tela toda)
- **Onde toca:** Gente nova na vila e melhorias compradas.

> A warm welcome chime: two soft bright bell notes with a gentle cheer, 1 second.

### 76. `sfx/migrantes_chegando`

- **Arquivo(s):** `sfx/migrantes_chegando`
- **Duração:** 4 s  •  **Tipo:** toca uma vez
- **Onde toca:** Um grupo de migrantes chega no portão.

> A small group of travelers arriving at a wooden gate: footsteps, a cart creak, a knock and a distant greeting murmur with no words, 4 seconds.

### 77. `sfx/portao_abre`

- **Arquivo(s):** `sfx/portao_abre`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** O portão da paliçada abre.

> A big wooden palisade gate opening: heavy creaking hinges and wood scraping with a final thud, 3 seconds.

### 78. `sfx/portao_fecha`

- **Arquivo(s):** `sfx/portao_fecha`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** O portão da paliçada fecha ao anoitecer.

> A big wooden palisade gate closing: creaking hinges, wood scraping and a heavy wooden bar dropping into place with a thunk, 3 seconds.

### 79. `sfx/minerio_esgotado`

- **Arquivo(s):** `sfx/minerio_esgotado`
- **Duração:** 2 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma jazida esgota.

> A rich ore vein finally collapsing: rocks crumbling and sliding with a dusty settle, 2 seconds.


## Animais

### 80. `animais/coelho_foge`

- **Arquivo(s):** `animais/coelho_foge_0`, `animais/coelho_foge_1`, `animais/coelho_foge_2`
- **Duração:** 0.8 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Um coelho foge de quem chega perto.

> A small rabbit startled and bounding away: a quick leaf rustle and soft scurrying thumps with a tiny squeak, 0.8 seconds.

### 81. `animais/javali_grunhido`

- **Arquivo(s):** `animais/javali_grunhido_0`, `animais/javali_grunhido_1`
- **Duração:** 1.2 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Um javali percebe alguém perto.

> A wild boar grunting and snorting aggressively, a deep wet snort, 1.2 seconds.

### 82. `animais/coelho_morre`

- **Arquivo(s):** `animais/coelho_morre`
- **Duração:** 0.6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Um coelho é abatido.

> A very short faint rabbit squeak and a soft thud, 0.6 seconds.

### 83. `animais/javali_morre`

- **Arquivo(s):** `animais/javali_morre`
- **Duração:** 1.5 s  •  **Tipo:** toca uma vez
- **Onde toca:** Um javali é abatido.

> A wild boar squeal followed by a heavy body falling, 1.5 seconds.


## Perigos (radiação)

### 84. `perigo/geiger`

- **Arquivo(s):** `perigo/geiger_0`, `perigo/geiger_1`, `perigo/geiger_2`, `perigo/geiger_3`
- **Duração:** 0.8 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Alguém está sendo irradiado (onda solar, radiação do S2).

> A Geiger counter crackling burst: rapid irregular clicks, a radiation warning, 0.8 seconds, no voices.


## Criaturas (um som de ataque por espécie)

### 85. `criaturas/gosma_ataque`

- **Arquivo(s):** `criaturas/gosma_ataque_0`, `criaturas/gosma_ataque_1`
- **Duração:** 0.8 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** A Gosma ataca.

> An acidic slime creature attack: a wet splat with a sizzling hiss, 0.8 seconds.

### 86. `criaturas/magmante_ataque`

- **Arquivo(s):** `criaturas/magmante_ataque_0`, `criaturas/magmante_ataque_1`
- **Duração:** 1 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** O Magmante ataca.

> A molten magma creature strike: a heavy fiery thump with a lava hiss and a rock crack, 1 second.

### 87. `criaturas/matriarca_ataque`

- **Arquivo(s):** `criaturas/matriarca_ataque_0`, `criaturas/matriarca_ataque_1`
- **Duração:** 2 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** A Matriarca (a chefe) ataca.

> A huge boss monster roar and heavy claw slam: a deep guttural roar with metallic resonance, 2 seconds.


## Máquinas

### 88. `maquinas/quebrou`

- **Arquivo(s):** `maquinas/quebrou`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma máquina quebra.

> A heavy machine breaking down: a loud metallic snap, grinding gears seizing and a sad winding-down clunk with a steam hiss, 3 seconds.

### 89. `maquinas/consertada`

- **Arquivo(s):** `maquinas/consertada`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** Uma máquina é consertada e volta a funcionar.

> A machine repaired and restarting: a wrench ratchet, a spark and the motor coughing then humming back to life, 3 seconds.


## Vida na vila (nascimento, casamento, enterro)

### 90. `vida/bebe_nasce`

- **Arquivo(s):** `vida/bebe_nasce_0`, `vida/bebe_nasce_1`
- **Duração:** 2 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Nasce um bebê.

> A newborn baby's first cry, small and fragile, 2 seconds.

### 91. `vida/casamento`

- **Arquivo(s):** `vida/casamento`
- **Duração:** 4 s  •  **Tipo:** toca uma vez
- **Onde toca:** Um casal se casa.

> A village wedding celebration: a short cheerful bell ring with the crowd cheering and clapping, 4 seconds.

### 92. `vida/enterro`

- **Arquivo(s):** `vida/enterro`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** O padre enterra um morto no cemitério.

> Digging a grave: a shovel cutting into earth and soil dropping, 3 seconds, no voices.


## Passos por tipo de chão

### 93. `passos/terra`

- **Arquivo(s):** `passos/terra_0`, `passos/terra_1`, `passos/terra_2`
- **Duração:** 0.3 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Passo de ipezinho na terra (floresta, vila, caminho de terra batida).

> A single footstep of a heavy work boot on packed dirt, short soft thud with slight grit, close microphone, 0.3 seconds, no echo, no other sounds.

### 94. `passos/cascalho`

- **Arquivo(s):** `passos/cascalho_0`, `passos/cascalho_1`, `passos/cascalho_2`
- **Duração:** 0.3 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Passo no cascalho (a pedreira e o caminho de cascalho).

> A single footstep of a work boot on loose gravel, crunchy stones shifting, close microphone, 0.3 seconds, no other sounds.

### 95. `passos/pedra`

- **Arquivo(s):** `passos/pedra_0`, `passos/pedra_1`, `passos/pedra_2`
- **Duração:** 0.5 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Passo na pedra (caminho de pedra e os andares fundos da mina).

> One footstep on a solid stone floor, hard shoe heel, loud crisp click, echoing in a cave, close microphone, 0.5 seconds.

### 96. `passos/madeira`

- **Arquivo(s):** `passos/madeira_0`, `passos/madeira_1`, `passos/madeira_2`
- **Duração:** 0.35 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Passo na madeira (plataformas, elevadores e escadas).

> A single footstep on an old wooden plank platform, hollow thud with a slight creak, 0.3 seconds, no other sounds.

### 97. `passos/agua`

- **Arquivo(s):** `passos/agua_0`, `passos/agua_1`, `passos/agua_2`
- **Duração:** 0.4 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Passo na água (as poças do S2 e do S3).

> A single clear, loud footstep of a boot splashing into a shallow puddle, a distinct wet slap with a visible splash, close microphone, strong and clearly audible, 0.4 seconds, no other sounds.


## Voz curta dos ipezinhos (desligável)

### 98. `voz/homem_ordem`

- **Arquivo(s):** `voz/homem_ordem_0`, `voz/homem_ordem_1`
- **Duração:** 0.7 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (homem) quando recebe uma ordem do jogador: 'Sim!', 'Pode deixar'. Menos de 1 s.

> A short gruff male worker voice acknowledging an order, an energetic 'yes, sir!' style exclamation, dry, 0.7 seconds. (Alternativa: Text to Speech em português: 'Sim, senhor!' / 'Pode deixar!')

### 99. `voz/homem_dor`

- **Arquivo(s):** `voz/homem_dor_0`, `voz/homem_dor_1`
- **Duração:** 0.5 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (homem) ao se machucar: 'Ai!'. Menos de 1 s.

> A short male grunt of pain, 'ugh!', sharp and quick, no words, dry, 0.5 seconds.

### 100. `voz/homem_alegria`

- **Arquivo(s):** `voz/homem_alegria_0`, `voz/homem_alegria_1`
- **Duração:** 0.8 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (homem) num brinde ou festa: riso e 'Eita!'. Menos de 1 s.

> A short happy male laugh followed by a cheerful 'hey!', dry, 0.8 seconds.

### 101. `voz/homem_cansaco`

- **Arquivo(s):** `voz/homem_cansaco_0`, `voz/homem_cansaco_1`
- **Duração:** 1.3 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (homem) cansado, indo dormir: suspiro e bocejo. Menos de 1,5 s.

> A long tired male sigh followed by a small yawn, dry, 1.3 seconds.

### 102. `voz/mulher_ordem`

- **Arquivo(s):** `voz/mulher_ordem_0`, `voz/mulher_ordem_1`
- **Duração:** 0.7 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (mulher) quando recebe uma ordem do jogador. Menos de 1 s.

> A short determined female worker voice acknowledging an order, an energetic 'yes!' style exclamation, dry, 0.7 seconds. (Alternativa: Text to Speech em português: 'Pode deixar!' / 'Sim!')

### 103. `voz/mulher_dor`

- **Arquivo(s):** `voz/mulher_dor_0`, `voz/mulher_dor_1`
- **Duração:** 0.5 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (mulher) ao se machucar. Menos de 1 s.

> A short female gasp of pain, 'ah!', sharp and quick, no words, dry, 0.5 seconds.

### 104. `voz/mulher_alegria`

- **Arquivo(s):** `voz/mulher_alegria_0`, `voz/mulher_alegria_1`
- **Duração:** 0.8 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (mulher) num brinde ou festa. Menos de 1 s.

> A short happy female laugh followed by a cheerful 'oh!', dry, 0.8 seconds.

### 105. `voz/mulher_cansaco`

- **Arquivo(s):** `voz/mulher_cansaco_0`, `voz/mulher_cansaco_1`
- **Duração:** 1.3 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (mulher) cansada, indo dormir. Menos de 1,5 s.

> A long tired female sigh followed by a small yawn, dry, 1.3 seconds.

### 106. `voz/homem_ola`

- **Arquivo(s):** `voz/homem_ola_0`, `voz/homem_ola_1`
- **Duração:** 0.6 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (homem) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s.

> A short friendly male greeting, a casual 'hey there!', dry, 0.6 seconds. (Alternativa: Text to Speech em português: 'Oi!' / 'Pois não?')

### 107. `voz/mulher_ola`

- **Arquivo(s):** `voz/mulher_ola_0`, `voz/mulher_ola_1`
- **Duração:** 0.6 s cada  •  **Tipo:** toca uma vez
- **Onde toca:** Voz curta (mulher) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s.

> A short friendly female greeting, a casual 'hey there!', dry, 0.6 seconds. (Alternativa: Text to Speech em português: 'Oi!' / 'Pois não?')


## Sons soltos pelo ambiente (aleatórios)

### 108. `pontuais/passaro_canto`

- **Arquivo(s):** `pontuais/passaro_canto_0`, `pontuais/passaro_canto_1`, `pontuais/passaro_canto_2`, `pontuais/passaro_canto_3`
- **Duração:** 3 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 5 a 12 s enquanto vale: dia
- **Onde toca:** Floresta de dia: um pássaro canta de vez em quando.

> A single bird song phrase in a forest, clear and melodic, 3 seconds, no other sounds.

### 109. `pontuais/corvo`

- **Arquivo(s):** `pontuais/corvo_0`, `pontuais/corvo_1`
- **Duração:** 2 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 20 a 45 s enquanto vale: dia
- **Onde toca:** Floresta de dia: um corvo ao longe.

> A crow cawing one or two harsh caws, distant, 2 seconds.

### 110. `pontuais/coruja`

- **Arquivo(s):** `pontuais/coruja_0`, `pontuais/coruja_1`
- **Duração:** 3 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 15 a 35 s enquanto vale: noite
- **Onde toca:** Floresta de noite: uma coruja.

> An owl hooting, deep and soft, two hoots, night forest, 3 seconds.

### 111. `pontuais/lobo_uivo`

- **Arquivo(s):** `pontuais/lobo_uivo_0`, `pontuais/lobo_uivo_1`
- **Duração:** 5 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 40 a 90 s enquanto vale: noite
- **Onde toca:** Floresta de noite: um lobo uiva ao longe.

> A distant wolf howling at night, long and mournful, 5 seconds.

### 112. `pontuais/sapo`

- **Arquivo(s):** `pontuais/sapo_0`, `pontuais/sapo_1`
- **Duração:** 3 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 12 a 30 s enquanto vale: noite
- **Onde toca:** Floresta de noite: sapos num brejo.

> A few frogs croaking by a pond at night, 3 seconds.

### 113. `pontuais/trovao`

- **Arquivo(s):** `pontuais/trovao_0`, `pontuais/trovao_1`, `pontuais/trovao_2`
- **Duração:** 6 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 20 a 50 s enquanto vale: chuva
- **Onde toca:** Quando chove: um trovão.

> Rolling thunder, a distant to medium rumble that builds and fades, 6 seconds, no rain.

### 114. `pontuais/vento_rajada`

- **Arquivo(s):** `pontuais/vento_rajada_0`, `pontuais/vento_rajada_1`
- **Duração:** 4 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 10 a 25 s enquanto vale: vento
- **Onde toca:** No inverno: uma rajada de vento.

> A cold wind gust sweeping past, rising and fading, 4 seconds.

### 115. `pontuais/pedra_cai`

- **Arquivo(s):** `pontuais/pedra_cai_0`, `pontuais/pedra_cai_1`, `pontuais/pedra_cai_2`
- **Duração:** 2 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 25 a 60 s enquanto vale: mina
- **Onde toca:** Na mina: pedrinhas caem da parede.

> A few small stones falling and rattling down a mine wall with a dusty echo, 2 seconds.

### 116. `pontuais/gotejar`

- **Arquivo(s):** `pontuais/gotejar_0`, `pontuais/gotejar_1`, `pontuais/gotejar_2`
- **Duração:** 1.5 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 8 a 20 s enquanto vale: mina/s2
- **Onde toca:** Na mina e no S2: uma gota cai.

> A single clear, loud water drip falling into a pool in a cave, a distinct plink with a short echo, close microphone, strong and clearly audible, 1.5 seconds, no other sounds.

### 117. `pontuais/acido_borbulha`

- **Arquivo(s):** `pontuais/acido_borbulha_0`, `pontuais/acido_borbulha_1`, `pontuais/acido_borbulha_2`
- **Duração:** 1.5 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 6 a 15 s enquanto vale: s2
- **Onde toca:** S2: uma bolha grande de ácido estoura.

> A large acid bubble popping with a hiss in a cavern, 1.5 seconds.

### 118. `pontuais/lava_estalo`

- **Arquivo(s):** `pontuais/lava_estalo_0`, `pontuais/lava_estalo_1`, `pontuais/lava_estalo_2`
- **Duração:** 1.5 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 5 a 14 s enquanto vale: s3
- **Onde toca:** S3: a rocha esfriando estala.

> Cooling lava rock cracking loudly with an ember pop and a hiss, 1.5 seconds.

### 119. `pontuais/gota_eco`

- **Arquivo(s):** `pontuais/gota_eco_0`, `pontuais/gota_eco_1`, `pontuais/gota_eco_2`
- **Duração:** 3 s cada  •  **Tipo:** solto e aleatório  •  toca a cada 7 a 18 s enquanto vale: s5
- **Onde toca:** S5: uma gota cai no lago.

> A single water droplet falling into a still underground lake with a long dreamy echo, 3 seconds.


## Sons da introdução

### 120. `intro/explosao`

- **Arquivo(s):** `intro/explosao`
- **Duração:** 6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Quadro 1 da introdução: o sol explode sobre a cidade mineira.

> Cinematic massive solar flare explosion over a city: a huge deep boom with a rising roar and crackling fire, then debris falling, 6 seconds.

### 121. `intro/vento`

- **Arquivo(s):** `intro/vento`
- **Duração:** 6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Quadro 2 da introdução: cidades em ruína, vento e silêncio.

> Lonely wind through a ruined abandoned city, distant creaking metal and drifting dust, eerie and silent, 6 seconds.

### 122. `intro/caravana`

- **Arquivo(s):** `intro/caravana`
- **Duração:** 6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Quadro 3 da introdução: a caravana a caminho da pedreira (passos, carroça).

> A caravan of people and a wooden cart moving along a gravel road: footsteps, cart wheels creaking, a faint murmur (no words), 6 seconds.

### 123. `intro/pedreira`

- **Arquivo(s):** `intro/pedreira`
- **Duração:** 6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Quadro 4 (no mapa): a câmera atravessa a pedreira.

> Quarry atmosphere: distant hammering on stone, wind, the echo of a pickaxe and rocks shifting, 6 seconds.

### 124. `intro/mina`

- **Arquivo(s):** `intro/mina`
- **Duração:** 6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Quadro 6 (no mapa): o corte da mina descendo andar por andar.

> Cinematic descent into a deep mine: a low rumble that deepens, falling rocks and metal elevator cables creaking, 6 seconds.

### 125. `intro/fogo`

- **Arquivo(s):** `intro/fogo`
- **Duração:** 6 s  •  **Tipo:** toca uma vez
- **Onde toca:** Quadro 7 (no mapa): a fogueira acesa no meio da vila.

> A campfire crackling warmly with a few people murmuring around it (no words) and night insects, calm, 6 seconds.

### 126. `intro/titulo`

- **Arquivo(s):** `intro/titulo`
- **Duração:** 3 s  •  **Tipo:** toca uma vez
- **Onde toca:** O título DEEP IRON aparece: batida grave e curta.

> Deep cinematic title hit: a powerful low impact with metal resonance and a long tail, 3 seconds.


## Fora desta lista: música

- `musica/abertura` (loop): A ABERTURA do jogo: toca na tela inicial (o menu). Loop de 1 a 2 minutos, tema principal do DEEP IRON (sol, ruína, esperança).
- `musica/intro` (toca uma vez): A INTRODUÇÃO (3 quadros ilustrados + 4 no mapa, uns 60 s): uma peça só, crescendo da explosão até a fogueira e o título. Não repete.
