# Arquivos de som que o jogo espera (Bloco 114/115)

Gerado por `python tools/lista_audio.py` a partir de `project.godot/data/audio/slots.json`. **Não edite à mão.** Os **prompts** de cada som estão em `docs/AUDIO_PROMPTS_ELEVENLABS.md`.

Os sons NÃO são criados pelo jogo nem pelo código: são gerados fora (ElevenLabs; a música à parte) e postos em `project.godot/assets/audio/` **com o nome exato abaixo**. O jogo procura `<nome>.ogg`, `<nome>.wav` ou `<nome>.mp3` (nessa ordem). Sem arquivo o som fica mudo (ou toca o som sintetizado de antes, a *reserva*), sem erro. Arquivo novo substitui o sintetizado.

## Regras dos arquivos

- **Formato:** `.ogg` pros loops e músicas (menor), `.wav` ou `.ogg` pros curtos. Depois de pôr arquivos novos: `godot --headless --path project.godot --import`.
- **Loops** (ambiência, prédios): o começo e o fim têm que emendar sem corte; o jogo força a repetição por código (não precisa marcar loop no import). 20 a 40 s.
- **Posicionais** (prédios, efeitos, passos, voz, sons soltos): **mono**. Os de interface e stingers podem ser estéreo.
- **Variações** (`_0`, `_1`...): arquivos diferentes do mesmo som; o jogo sorteia sem repetir seguido.
- **Volume:** normalizar em torno de −16 LUFS, pico abaixo de −1 dB. O jogo ajusta o volume de cada slot (coluna dB) e tem limitador no Master.
- **Ducking:** os slots marcados abaixam a música (alarme −9 dB, sino −7 dB, aviso −6 dB).

**Resumo:** 128 slots, 193 arquivos esperados, 0 já existem.


## Ambiência (loops por andar, clima e onda solar)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `ambiencia/mina` | loop | Ambience | 0.0 | Vila, pedreira e túneis do S1 (a câmera na área da mina). Loop contínuo, sem pico alto. | o som de antes | falta |
| `ambiencia/floresta_dia` | loop | Ambience | -4.0 | Floresta e clareira de dia: pássaros, folhas, vento leve. | o som de antes | falta |
| `ambiencia/floresta_noite` | loop | Ambience | -5.0 | Floresta e clareira de noite: grilos e uma coruja distante. | o som de antes | falta |
| `ambiencia/vento_inverno` | loop | Ambience | -8.0 | CAMADA por cima da floresta e da vila no inverno: vento frio e constante, sem pássaros. | mudo | falta |
| `ambiencia/chuva` | loop | Ambience | -6.0 | CAMADA por cima da clareira quando está chovendo. | o som de antes | falta |
| `ambiencia/s2_acido` | loop | Ambience | -1.0 | S2 (ácido e gás): bolhas de ácido borbulhando e gotejar. | o som de antes | falta |
| `ambiencia/s3_lava` | loop | Ambience | -1.0 | S3 (lava): lava borbulhando e ronco grave de fundo. | o som de antes | falta |
| `ambiencia/s4_cachoeira` | loop | Ambience | -1.0 | S4 (cachoeira e lava): queda d'água constante ao longe. | o som de antes | falta |
| `ambiencia/s5_lago` | loop | Ambience | -1.0 | S5 (lago azul): gotas e água parada, o jogo põe o eco (reverb) sozinho. *(eco 0.35)* | o som de antes | falta |
| `ambiencia/onda_solar` | loop | Ambience | -4.0 | CAMADA durante a onda solar, na superfície: calor, rugido e estática. | mudo | falta |

## Prédios e lugares (loops posicionais e sinos)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `predios/fornalha` | loop posicional | SFX | -12.0 | Fornalha acesa (só enquanto o fundidor funde): fogo e foles. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/carpintaria` | loop posicional | SFX | -12.0 | Carpintaria com ordem em andamento: serra e martelo. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/taverna` | loop posicional | SFX | -12.0 | Taverna com gente dentro: murmúrio, canecas, riso. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/cemiterio` | loop posicional | SFX | -14.0 | Cemitério (sempre): vento baixo e um corvo distante. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/vagonete` | loop posicional | SFX | -10.0 | Vagonete andando no trilho: rodas de ferro. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/coletor_madeira` | loop posicional | SFX | -12.0 | Coletor de madeira funcionando: engrenagem e serra mecânica. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/coletor_minerio` | loop posicional | SFX | -12.0 | Coletor de minério funcionando: motor e broca. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/sino_missa` | toca uma vez | SFX | -5.0 | Sino da igreja quando a missa de domingo começa (posicional, na igreja). *(abaixa a música (sino))* | o som de antes | falta |
| `predios/sino_funeral` | toca uma vez | SFX | -5.0 | Sino da igreja (ou do cemitério) quando o funeral começa: mais lento e grave. *(abaixa a música (sino))* | o som de antes | falta |
| `predios/poca_perigo` | loop posicional | SFX | -16.0 | Perto de uma poça de ácido ou lava (sempre): borbulhar baixo e chiado. *(só perto da câmera (400 px), com o prédio em atividade)* | mudo | falta |
| `predios/ventilador` | loop posicional | SFX | -14.0 | Perto de um ventilador da mina (sempre): zumbido de ar. *(só perto da câmera (500 px), com o prédio em atividade)* | mudo | falta |
| `predios/tocha` | loop posicional | SFX | -16.0 | Perto de uma tocha acesa (sempre): fogo crepitando. *(só perto da câmera (350 px), com o prédio em atividade)* | mudo | falta |
| `predios/conversa` | loop posicional | SFX | -14.0 | Num ponto social (refeitório, praça, parque, igreja...) com gente reunida: o murmúrio da conversa. *(só perto da câmera (500 px), com o prédio em atividade)* | mudo | falta |
| `predios/oficina` | loop posicional | SFX | -12.0 | Oficina com o ferreiro trabalhando: martelo na bigorna. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/arsenal` | loop posicional | SFX | -12.0 | Arsenal com o ferreiro trabalhando: metal batido e armas. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/laboratorio` | loop posicional | SFX | -14.0 | Laboratório com a pesquisadora trabalhando: líquidos borbulhando. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/escavadeira` | loop posicional | SFX | -10.0 | Escavadeira gigante funcionando: motor e broca. *(só perto da câmera (700 px), com o prédio em atividade)* | mudo | falta |
| `predios/escola` | loop posicional | SFX | -14.0 | Escola com gente dentro: crianças ao longe e giz. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/cozinha` | loop posicional | SFX | -14.0 | Cozinha com o cozinheiro trabalhando: panela e fogão. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |

## Stingers (eventos do jogo)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `stingers/amanhecer` | toca uma vez | SFX | -8.0 | Começa um novo dia (05:00): curto, claro, 2 a 3 s. | mudo | falta |
| `stingers/onda_solar` | toca uma vez | SFX | -4.0 | O aviso 'ONDA SOLAR CHEGANDO' (tensão crescente, 3 a 4 s). *(abaixa a música (alarme))* | o som de antes | falta |
| `stingers/estagio_novo` | toca uma vez | SFX | -4.0 | A vila sobe de estágio: fanfarra de conquista, 3 a 4 s. | o som de antes | falta |
| `stingers/pesquisa_pronta` | toca uma vez | SFX | -4.0 | Uma pesquisa termina: brilho curto, 2 s. | o som de antes | falta |
| `stingers/morte` | toca uma vez | SFX | -5.0 | Um ipezinho morre: sino fúnebre curto e triste. *(abaixa a música (sino))* | o som de antes | falta |
| `stingers/vitoria` | toca uma vez | SFX | -3.0 | Vitória (o escudo solar fica pronto): triunfo, 5 a 8 s. | o som de antes | falta |
| `stingers/derrota` | toca uma vez | SFX | -3.0 | Derrota (os ipezinhos expulsam o jogador): grave e vazio, 4 a 6 s. *(abaixa a música (sino))* | o som de antes | falta |
| `stingers/missao_cumprida` | toca uma vez | SFX | -4.0 | Uma missão é cumprida: fanfarra curta de recompensa, 2 a 3 s. | o som de antes | falta |

## Interface (bus UI)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `ui/abrir_janela` | toca uma vez | UI | -14.0 | Abrir uma janela: whoosh/papel curto, menos de 0,3 s. | o som de antes | falta |
| `ui/fechar_janela` | toca uma vez | UI | -14.0 | Fechar uma janela: o oposto do abrir, menos de 0,3 s. | o som de antes | falta |
| `ui/confirmar` | toca uma vez | UI | -8.0 | Confirmar (pôr um prédio, marcar uma área, comprar): toque firme e satisfatório. | o som de antes | falta |
| `ui/erro` | toca uma vez | UI | -6.0 | Ação negada (sem recurso, lugar inválido): buzz curto e seco. | o som de antes | falta |
| `ui/clique` | toca uma vez | UI | -12.0 | Clique de botão: tec curto e suave. | o som de antes | falta |
| `ui/noticia_boa` | toca uma vez | UI | -8.0 | Aviso bom (aviso verde): dois toques ascendentes, 0,5 s. | mudo | falta |
| `ui/noticia_ruim` | toca uma vez | UI | -8.0 | Aviso ruim (aviso vermelho): dois toques descendentes, 0,5 s. | mudo | falta |

## Efeitos do jogo (trabalho, combate, obras, avisos)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `sfx/picareta_0`<br>`sfx/picareta_1`<br>`sfx/picareta_2` | toca uma vez | SFX | -7.0 | O ipezinho dá um golpe de picareta na pedra. | o som de antes | falta |
| `sfx/deposito_0`<br>`sfx/deposito_1`<br>`sfx/deposito_2` | toca uma vez | SFX | -9.0 | Entrega o minério (ou a madeira) no armazém. | o som de antes | falta |
| `sfx/comer_0`<br>`sfx/comer_1`<br>`sfx/comer_2` | toca uma vez | SFX | -11.0 | Um ipezinho come no refeitório. | o som de antes | falta |
| `sfx/ferido` | toca uma vez | SFX | -4.0 | Um ipezinho se machuca (acidente, criatura, radiação). | o som de antes | falta |
| `sfx/curar` | toca uma vez | SFX | -8.0 | A enfermaria cura um paciente. | o som de antes | falta |
| `sfx/forja` | toca uma vez | SFX | -10.0 | A oficina, o arsenal ou a escavadeira forjam uma peça. | o som de antes | falta |
| `sfx/machadada_0`<br>`sfx/machadada_1`<br>`sfx/machadada_2` | toca uma vez | SFX | -9.0 | O lenhador dá uma machadada na árvore. | o som de antes | falta |
| `sfx/elevador` | toca uma vez | SFX | -8.0 | O elevador sobe ou desce. | o som de antes | falta |
| `sfx/galho` | toca uma vez | SFX | -5.0 | Uma árvore cai. | o som de antes | falta |
| `sfx/fanfarra` | toca uma vez | SFX | -4.0 | Uma conquista (a Matriarca cai, a escavadeira fica pronta, o abismo abre, o fim da greve). *(sem posição (na tela toda))* | o som de antes | falta |
| `sfx/sino_funebre` | toca uma vez | SFX | -5.0 | O último aviso da greve e o som antigo do funeral. *(sem posição (na tela toda); abaixa a música (sino))* | o som de antes | falta |
| `sfx/alarme_invasao` | toca uma vez | SFX | -4.0 | Começa uma invasão de criaturas (e o aviso da onda solar, sem o stinger). *(sem posição (na tela toda); abaixa a música (alarme))* | o som de antes | falta |
| `sfx/solar` | toca uma vez | SFX | -3.0 | A onda solar chega. *(sem posição (na tela toda))* | o som de antes | falta |
| `sfx/brinde` | toca uma vez | SFX | -12.0 | Um brinde na taverna. | o som de antes | falta |
| `sfx/greve` | toca uma vez | SFX | -9.0 | A vila em greve bate panelas e ferramentas na praça. | o som de antes | falta |
| `sfx/achado` | toca uma vez | SFX | -8.0 | Um achado na escavação. | o som de antes | falta |
| `sfx/robo` | toca uma vez | SFX | -6.0 | O robô antigo é ligado. | o som de antes | falta |
| `sfx/explosao` | toca uma vez | SFX | -2.0 | Dinamite no entulho (e a pane do reator). | o som de antes | falta |
| `sfx/lumivoro_grito_0`<br>`sfx/lumivoro_grito_1` | toca uma vez | SFX | -12.0 | O Lumívoro ataca. | o som de antes | falta |
| `sfx/ferrugento_golpe_0`<br>`sfx/ferrugento_golpe_1` | toca uma vez | SFX | -10.0 | O Ferrugento ataca (garra de ferro). | o som de antes | falta |
| `sfx/golpe_0`<br>`sfx/golpe_1` | toca uma vez | SFX | -9.0 | Um golpe de arma acerta. | o som de antes | falta |
| `sfx/portao_quebra` | toca uma vez | SFX | -4.0 | Uma barricada ou máquina quebra. | o som de antes | falta |
| `sfx/criatura_cai` | toca uma vez | SFX | -8.0 | Uma criatura é derrubada. | o som de antes | falta |
| `sfx/martelo_0`<br>`sfx/martelo_1`<br>`sfx/martelo_2` | toca uma vez | SFX | -12.0 | O engenheiro bate o martelo numa obra. | o som de antes | falta |
| `sfx/obra_pronta` | toca uma vez | SFX | -6.0 | Uma obra fica pronta. | o som de antes | falta |
| `sfx/colher_0`<br>`sfx/colher_1`<br>`sfx/colher_2` | toca uma vez | SFX | -12.0 | Colher na horta. | o som de antes | falta |
| `sfx/equipar` | toca uma vez | SFX | -10.0 | Pegar casaco, traje ou arma no vestiário. | o som de antes | falta |
| `sfx/festa` | toca uma vez | SFX | -8.0 | Uma festa começa na vila. *(sem posição (na tela toda))* | o som de antes | falta |
| `sfx/broca` | toca uma vez | SFX | -14.0 | O coletor de minério fura a rocha. | o som de antes | falta |
| `sfx/vender` | toca uma vez | SFX | -6.0 | Vender no armazém. *(sem posição (na tela toda))* | o som de antes | falta |
| `sfx/boas_vindas` | toca uma vez | SFX | -6.0 | Gente nova na vila e melhorias compradas. *(sem posição (na tela toda))* | o som de antes | falta |
| `sfx/migrantes_chegando` | toca uma vez | SFX | -6.0 | Um grupo de migrantes chega no portão. | mudo | falta |
| `sfx/portao_abre` | toca uma vez | SFX | -10.0 | O portão da paliçada abre. | o som de antes | falta |
| `sfx/portao_fecha` | toca uma vez | SFX | -10.0 | O portão da paliçada fecha ao anoitecer. | o som de antes | falta |
| `sfx/minerio_esgotado` | toca uma vez | SFX | -8.0 | Uma jazida esgota. | mudo | falta |

## Animais

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `animais/coelho_foge_0`<br>`animais/coelho_foge_1`<br>`animais/coelho_foge_2` | toca uma vez | SFX | -10.0 | Um coelho foge de quem chega perto. | mudo | falta |
| `animais/javali_grunhido_0`<br>`animais/javali_grunhido_1` | toca uma vez | SFX | -8.0 | Um javali percebe alguém perto. | mudo | falta |
| `animais/coelho_morre` | toca uma vez | SFX | -10.0 | Um coelho é abatido. | mudo | falta |
| `animais/javali_morre` | toca uma vez | SFX | -8.0 | Um javali é abatido. | mudo | falta |

## Perigos (radiação)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `perigo/geiger_0`<br>`perigo/geiger_1`<br>`perigo/geiger_2`<br>`perigo/geiger_3` | toca uma vez | SFX | -12.0 | Alguém está sendo irradiado (onda solar, radiação do S2). | mudo | falta |

## Criaturas (um som de ataque por espécie)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `criaturas/gosma_ataque_0`<br>`criaturas/gosma_ataque_1` | toca uma vez | SFX | -10.0 | A Gosma ataca. | o som de antes | falta |
| `criaturas/magmante_ataque_0`<br>`criaturas/magmante_ataque_1` | toca uma vez | SFX | -10.0 | O Magmante ataca. | o som de antes | falta |
| `criaturas/matriarca_ataque_0`<br>`criaturas/matriarca_ataque_1` | toca uma vez | SFX | -6.0 | A Matriarca (a chefe) ataca. | o som de antes | falta |

## Máquinas

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `maquinas/quebrou` | toca uma vez | SFX | -4.0 | Uma máquina quebra. | o som de antes | falta |
| `maquinas/consertada` | toca uma vez | SFX | -6.0 | Uma máquina é consertada e volta a funcionar. | o som de antes | falta |

## Vida na vila (nascimento, casamento, enterro)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `vida/bebe_nasce_0`<br>`vida/bebe_nasce_1` | toca uma vez | SFX | -8.0 | Nasce um bebê. | mudo | falta |
| `vida/casamento` | toca uma vez | SFX | -6.0 | Um casal se casa. | mudo | falta |
| `vida/enterro` | toca uma vez | SFX | -8.0 | O padre enterra um morto no cemitério. | mudo | falta |

## Passos por tipo de chão

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `passos/terra_0`<br>`passos/terra_1`<br>`passos/terra_2` | toca uma vez | SFX | -22.0 | Passo de ipezinho na terra (floresta, vila, caminho de terra batida). | o som de antes | falta |
| `passos/cascalho_0`<br>`passos/cascalho_1`<br>`passos/cascalho_2` | toca uma vez | SFX | -22.0 | Passo no cascalho (a pedreira e o caminho de cascalho). | o som de antes | falta |
| `passos/pedra_0`<br>`passos/pedra_1`<br>`passos/pedra_2` | toca uma vez | SFX | -22.0 | Passo na pedra (caminho de pedra e os andares fundos da mina). | o som de antes | falta |
| `passos/madeira_0`<br>`passos/madeira_1`<br>`passos/madeira_2` | toca uma vez | SFX | -22.0 | Passo na madeira (plataformas, elevadores e escadas). | o som de antes | falta |
| `passos/agua_0`<br>`passos/agua_1`<br>`passos/agua_2` | toca uma vez | SFX | -22.0 | Passo na água (as poças do S2 e do S3). | o som de antes | falta |

## Voz curta dos ipezinhos (desligável)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `voz/homem_ordem_0`<br>`voz/homem_ordem_1` | toca uma vez | SFX | -14.0 | Voz curta (homem) quando recebe uma ordem do jogador: 'Sim!', 'Pode deixar'. Menos de 1 s. | mudo | falta |
| `voz/homem_dor_0`<br>`voz/homem_dor_1` | toca uma vez | SFX | -12.0 | Voz curta (homem) ao se machucar: 'Ai!'. Menos de 1 s. | mudo | falta |
| `voz/homem_alegria_0`<br>`voz/homem_alegria_1` | toca uma vez | SFX | -14.0 | Voz curta (homem) num brinde ou festa: riso e 'Eita!'. Menos de 1 s. | mudo | falta |
| `voz/homem_cansaco_0`<br>`voz/homem_cansaco_1` | toca uma vez | SFX | -14.0 | Voz curta (homem) cansado, indo dormir: suspiro e bocejo. Menos de 1,5 s. | mudo | falta |
| `voz/mulher_ordem_0`<br>`voz/mulher_ordem_1` | toca uma vez | SFX | -14.0 | Voz curta (mulher) quando recebe uma ordem do jogador. Menos de 1 s. | mudo | falta |
| `voz/mulher_dor_0`<br>`voz/mulher_dor_1` | toca uma vez | SFX | -12.0 | Voz curta (mulher) ao se machucar. Menos de 1 s. | mudo | falta |
| `voz/mulher_alegria_0`<br>`voz/mulher_alegria_1` | toca uma vez | SFX | -14.0 | Voz curta (mulher) num brinde ou festa. Menos de 1 s. | mudo | falta |
| `voz/mulher_cansaco_0`<br>`voz/mulher_cansaco_1` | toca uma vez | SFX | -14.0 | Voz curta (mulher) cansada, indo dormir. Menos de 1,5 s. | mudo | falta |
| `voz/homem_ola_0`<br>`voz/homem_ola_1` | toca uma vez | SFX | -14.0 | Voz curta (homem) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s. | mudo | falta |
| `voz/mulher_ola_0`<br>`voz/mulher_ola_1` | toca uma vez | SFX | -14.0 | Voz curta (mulher) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s. | mudo | falta |

## Sons soltos pelo ambiente (aleatórios)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `pontuais/passaro_canto_0`<br>`pontuais/passaro_canto_1`<br>`pontuais/passaro_canto_2`<br>`pontuais/passaro_canto_3` | solto e aleatório | Ambience | -12.0 | Floresta de dia: um pássaro canta de vez em quando. *(toca a cada 5 a 12 s enquanto vale: dia)* | mudo | falta |
| `pontuais/corvo_0`<br>`pontuais/corvo_1` | solto e aleatório | Ambience | -14.0 | Floresta de dia: um corvo ao longe. *(toca a cada 20 a 45 s enquanto vale: dia)* | mudo | falta |
| `pontuais/coruja_0`<br>`pontuais/coruja_1` | solto e aleatório | Ambience | -14.0 | Floresta de noite: uma coruja. *(toca a cada 15 a 35 s enquanto vale: noite)* | mudo | falta |
| `pontuais/lobo_uivo_0`<br>`pontuais/lobo_uivo_1` | solto e aleatório | Ambience | -16.0 | Floresta de noite: um lobo uiva ao longe. *(toca a cada 40 a 90 s enquanto vale: noite)* | mudo | falta |
| `pontuais/sapo_0`<br>`pontuais/sapo_1` | solto e aleatório | Ambience | -14.0 | Floresta de noite: sapos num brejo. *(toca a cada 12 a 30 s enquanto vale: noite)* | mudo | falta |
| `pontuais/trovao_0`<br>`pontuais/trovao_1`<br>`pontuais/trovao_2` | solto e aleatório | Ambience | -8.0 | Quando chove: um trovão. *(toca a cada 20 a 50 s enquanto vale: chuva)* | mudo | falta |
| `pontuais/vento_rajada_0`<br>`pontuais/vento_rajada_1` | solto e aleatório | Ambience | -12.0 | No inverno: uma rajada de vento. *(toca a cada 10 a 25 s enquanto vale: vento)* | mudo | falta |
| `pontuais/pedra_cai_0`<br>`pontuais/pedra_cai_1`<br>`pontuais/pedra_cai_2` | solto e aleatório | Ambience | -14.0 | Na mina: pedrinhas caem da parede. *(toca a cada 25 a 60 s enquanto vale: mina)* | mudo | falta |
| `pontuais/gotejar_0`<br>`pontuais/gotejar_1`<br>`pontuais/gotejar_2` | solto e aleatório | Ambience | -16.0 | Na mina e no S2: uma gota cai. *(toca a cada 8 a 20 s enquanto vale: mina/s2)* | mudo | falta |
| `pontuais/acido_borbulha_0`<br>`pontuais/acido_borbulha_1`<br>`pontuais/acido_borbulha_2` | solto e aleatório | Ambience | -14.0 | S2: uma bolha grande de ácido estoura. *(toca a cada 6 a 15 s enquanto vale: s2)* | mudo | falta |
| `pontuais/lava_estalo_0`<br>`pontuais/lava_estalo_1`<br>`pontuais/lava_estalo_2` | solto e aleatório | Ambience | -14.0 | S3: a rocha esfriando estala. *(toca a cada 5 a 14 s enquanto vale: s3)* | mudo | falta |
| `pontuais/gota_eco_0`<br>`pontuais/gota_eco_1`<br>`pontuais/gota_eco_2` | solto e aleatório | Ambience | -16.0 | S5: uma gota cai no lago. *(toca a cada 7 a 18 s enquanto vale: s5)* | mudo | falta |

## Sons da introdução

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `intro/explosao` | toca uma vez | SFX | -6.0 | Quadro 1 da introdução: o sol explode sobre a cidade mineira. | mudo | falta |
| `intro/vento` | toca uma vez | SFX | -6.0 | Quadro 2 da introdução: cidades em ruína, vento e silêncio. | mudo | falta |
| `intro/caravana` | toca uma vez | SFX | -6.0 | Quadro 3 da introdução: a caravana a caminho da pedreira (passos, carroça). | mudo | falta |
| `intro/pedreira` | toca uma vez | SFX | -6.0 | Quadro 4 (no mapa): a câmera atravessa a pedreira. | mudo | falta |
| `intro/mina` | toca uma vez | SFX | -6.0 | Quadro 6 (no mapa): o corte da mina descendo andar por andar. | mudo | falta |
| `intro/fogo` | toca uma vez | SFX | -6.0 | Quadro 7 (no mapa): a fogueira acesa no meio da vila. | mudo | falta |
| `intro/titulo` | toca uma vez | SFX | -6.0 | O título DEEP IRON aparece: batida grave e curta. | mudo | falta |

## Música (FORA do ElevenLabs de efeitos)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `musica/abertura` | música | Music | 0.0 | A ABERTURA do jogo: toca na tela inicial (o menu). Loop de 1 a 2 minutos, tema principal do DEEP IRON (sol, ruína, esperança). | mudo | falta |
| `musica/intro` | música | Music | 0.0 | A INTRODUÇÃO (3 quadros ilustrados + 4 no mapa, uns 60 s): uma peça só, crescendo da explosão até a fogueira e o título. Não repete. | mudo | falta |
