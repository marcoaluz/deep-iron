# Arquivos de som que o jogo espera (Bloco 114)

Gerado por `python tools/lista_audio.py` a partir de `project.godot/data/audio/slots.json`. **Não edite à mão.**

Os sons NÃO são criados pelo jogo nem pelo código: são gerados fora (ElevenLabs) e postos em `project.godot/assets/audio/` **com o nome exato abaixo**. O jogo procura `<nome>.ogg`, `<nome>.wav` ou `<nome>.mp3` (nessa ordem). Sem arquivo o som fica mudo (ou toca o som sintetizado de antes, a *reserva*), sem erro.

## Regras dos arquivos

- **Formato:** `.ogg` pros loops e músicas (menor), `.wav` ou `.ogg` pros curtos. Depois de pôr arquivos novos: `godot --headless --path project.godot --import`.
- **Loops** (ambiência, prédios, música de abertura): o começo e o fim têm que emendar sem corte; o jogo força a repetição por código (não precisa marcar loop no import). 20 a 60 s.
- **Posicionais** (prédios, passos, voz, sinos): **mono**. Os de interface e stingers podem ser estéreo.
- **Variações** (`_0`, `_1`...): arquivos diferentes do mesmo som; o jogo sorteia sem repetir seguido.
- **Volume:** normalizar em torno de −16 LUFS, pico abaixo de −1 dB. O jogo ajusta o volume de cada slot (coluna dB) e tem limitador no Master.
- **Ducking:** os slots marcados com `duck` abaixam a música (alarme −9 dB, sino −7 dB, aviso −6 dB).

**Resumo:** 55 slots, 73 arquivos esperados, 0 já existem.


## Ambiência (loops por andar e por clima)

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

## Prédios (loops posicionais e sinos)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `predios/fornalha` | loop posicional | SFX | -12.0 | Fornalha acesa (só enquanto o fundidor funde): fogo e foles. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/carpintaria` | loop posicional | SFX | -12.0 | Carpintaria com ordem em andamento: serra e martelo. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/taverna` | loop posicional | SFX | -12.0 | Taverna com gente dentro: murmúrio, canecas, riso. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/cemiterio` | loop posicional | SFX | -14.0 | Cemitério (sempre): vento baixo e um corvo distante. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/vagonete` | loop posicional | SFX | -10.0 | Vagonete andando no trilho: rodas de ferro. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/coletor_madeira` | loop posicional | SFX | -12.0 | Coletor de madeira funcionando: engrenagem e serra mecânica. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/coletor_minerio` | loop posicional | SFX | -12.0 | Coletor de minério funcionando: motor e broca. *(só perto da câmera (600 px), com o prédio em atividade)* | mudo | falta |
| `predios/sino_missa` | toca uma vez | SFX | -5.0 | Sino da igreja quando a missa de domingo começa (posicional, na igreja). *(duck sino)* | o som de antes | falta |
| `predios/sino_funeral` | toca uma vez | SFX | -5.0 | Sino da igreja (ou do cemitério) quando o funeral começa: mais lento e grave. *(duck sino)* | o som de antes | falta |

## Stingers (eventos do jogo)

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `stingers/amanhecer` | toca uma vez | SFX | -8.0 | Começa um novo dia (05:00): curto, claro, 2 a 3 s. | mudo | falta |
| `stingers/onda_solar` | toca uma vez | SFX | -4.0 | O aviso 'ONDA SOLAR CHEGANDO' (tensão crescente, 3 a 4 s). *(duck alarme)* | o som de antes | falta |
| `stingers/estagio_novo` | toca uma vez | SFX | -4.0 | A vila sobe de estágio: fanfarra de conquista, 3 a 4 s. | o som de antes | falta |
| `stingers/pesquisa_pronta` | toca uma vez | SFX | -4.0 | Uma pesquisa termina: brilho curto, 2 s. | o som de antes | falta |
| `stingers/morte` | toca uma vez | SFX | -5.0 | Um ipezinho morre: sino fúnebre curto e triste. *(duck sino)* | o som de antes | falta |
| `stingers/vitoria` | toca uma vez | SFX | -3.0 | Vitória (o escudo solar fica pronto): triunfo, 5 a 8 s. | o som de antes | falta |
| `stingers/derrota` | toca uma vez | SFX | -3.0 | Derrota (os ipezinhos expulsam o jogador): grave e vazio, 4 a 6 s. *(duck sino)* | o som de antes | falta |
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

## Música: abertura e introdução

| Arquivo(s) em `assets/audio/` | Tipo | Bus | dB | Quando toca | Sem arquivo | Arquivo |
|---|---|---|---|---|---|---|
| `musica/abertura` | música | Music | 0.0 | A ABERTURA do jogo: toca na tela inicial (o menu). Loop de 1 a 2 minutos, tema principal do DEEP IRON (sol, ruína, esperança). | mudo | falta |
| `musica/intro` | música | Music | 0.0 | A INTRODUÇÃO (3 quadros ilustrados + 4 no mapa, uns 60 s): uma peça só, crescendo da explosão até a fogueira e o título. Não repete. | mudo | falta |

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
