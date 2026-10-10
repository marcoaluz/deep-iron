# Lista de escuta (Bloco 116)

Gerado por `python tools/elevenlabs/docs_audio.py`. A ordem é a de prioridade (ambiência por andar, fornalha, igreja, stingers, interface, depois o resto). **Marque `[x]` o que você ouviu e aprovou.** O estado de aprovação gravado pela ferramenta está em `project.godot/data/audio/gerados.json`.

**Resumo:** 191 arquivos de efeitos, 191 marcados como aprovados.

## Como ouvir e trocar um som

- **Ouvir no jogo:** o F3 tem "Ir para…" (andares) e "Pular dia"; os prédios tocam perto da câmera; os sons soltos tocam sozinhos de tempos em tempos.
- **Ouvir o arquivo:** `project.godot/assets/audio/<nome>.wav`.
- **Não gostou?** `python tools/elevenlabs/gerar_sons.py --so <id> --candidatos 3` gera 3 versões em `audio_candidatos/` (fora do git); ouça e escolha com `--aprovar <nome> <n>`. Antes, `--dry-run` mostra o custo.
- **Muito baixo ou alto?** Mude o `db` do slot em `data/audio/slots.json` (não precisa refazer o arquivo).


## Ambiência (loops por andar, clima e onda solar)

- [x] `ambiencia/chuva` — loop 30 s — CAMADA por cima da clareira quando está chovendo.
  - arquivo: `assets/audio/ambiencia/chuva.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/floresta_dia` — loop 40 s — Floresta e clareira de dia: pássaros, folhas, vento leve.
  - arquivo: `assets/audio/ambiencia/floresta_dia.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/floresta_noite` — loop 40 s — Floresta e clareira de noite: grilos e uma coruja distante.
  - arquivo: `assets/audio/ambiencia/floresta_noite.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/mina` — loop 40 s — Vila, pedreira e túneis do S1 (a câmera na área da mina). Loop contínuo, sem pico alto.
  - arquivo: `assets/audio/ambiencia/mina.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/onda_solar` — loop 30 s — CAMADA durante a onda solar, na superfície: calor, rugido e estática.
  - arquivo: `assets/audio/ambiencia/onda_solar.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/s2_acido` — loop 40 s — S2 (ácido e gás): bolhas de ácido borbulhando e gotejar.
  - arquivo: `assets/audio/ambiencia/s2_acido.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/s3_lava` — loop 40 s — S3 (lava): lava borbulhando e ronco grave de fundo.
  - arquivo: `assets/audio/ambiencia/s3_lava.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/s4_cachoeira` — loop 40 s — S4 (cachoeira e lava): queda d'água constante ao longe.
  - arquivo: `assets/audio/ambiencia/s4_cachoeira.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/s5_lago` — loop 40 s — S5 (lago azul): gotas e água parada, o jogo põe o eco (reverb) sozinho. *(eco 0.35)*
  - arquivo: `assets/audio/ambiencia/s5_lago.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `ambiencia/vento_inverno` — loop 30 s — CAMADA por cima da floresta e da vila no inverno: vento frio e constante, sem pássaros.
  - arquivo: `assets/audio/ambiencia/vento_inverno.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa

## Prédios e lugares (loops posicionais e sinos)

- [x] `predios/fornalha` — loop 25 s — Fornalha acesa (só enquanto o fundidor funde): fogo e foles. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/fornalha.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/sino_funeral` — 12 s — Sino da igreja (ou do cemitério) quando o funeral começa: mais lento e grave. *(abaixa a música (sino))*
  - arquivo: `assets/audio/predios/sino_funeral.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `predios/sino_missa` — 8 s — Sino da igreja quando a missa de domingo começa (posicional, na igreja). *(abaixa a música (sino))*
  - arquivo: `assets/audio/predios/sino_missa.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Stingers (eventos do jogo)

- [x] `stingers/amanhecer` — 3 s — Começa um novo dia (05:00): curto, claro, 2 a 3 s.
  - arquivo: `assets/audio/stingers/amanhecer.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `stingers/derrota` — 5 s — Derrota (os ipezinhos expulsam o jogador): grave e vazio, 4 a 6 s. *(abaixa a música (sino))*
  - arquivo: `assets/audio/stingers/derrota.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `stingers/estagio_novo` — 4 s — A vila sobe de estágio: fanfarra de conquista, 3 a 4 s.
  - arquivo: `assets/audio/stingers/estagio_novo.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `stingers/missao_cumprida` — 3 s — Uma missão é cumprida: fanfarra curta de recompensa, 2 a 3 s.
  - arquivo: `assets/audio/stingers/missao_cumprida.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `stingers/morte` — 4 s — Um ipezinho morre: sino fúnebre curto e triste. *(abaixa a música (sino))*
  - arquivo: `assets/audio/stingers/morte.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `stingers/onda_solar` — 4 s — O aviso 'ONDA SOLAR CHEGANDO' (tensão crescente, 3 a 4 s). *(abaixa a música (alarme))*
  - arquivo: `assets/audio/stingers/onda_solar.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `stingers/pesquisa_pronta` — 2.5 s — Uma pesquisa termina: brilho curto, 2 s.
  - arquivo: `assets/audio/stingers/pesquisa_pronta.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `stingers/vitoria` — 7 s — Vitória (o escudo solar fica pronto): triunfo, 5 a 8 s.
  - arquivo: `assets/audio/stingers/vitoria.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Interface (bus UI)

- [x] `ui/abrir_janela` — 0.3 s — Abrir uma janela: whoosh/papel curto, menos de 0,3 s.
  - arquivo: `assets/audio/ui/abrir_janela.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `ui/clique` — 0.15 s — Clique de botão: tec curto e suave.
  - arquivo: `assets/audio/ui/clique.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `ui/confirmar` — 0.5 s — Confirmar (pôr um prédio, marcar uma área, comprar): toque firme e satisfatório.
  - arquivo: `assets/audio/ui/confirmar.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `ui/erro` — 0.4 s — Ação negada (sem recurso, lugar inválido): buzz curto e seco.
  - arquivo: `assets/audio/ui/erro.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `ui/fechar_janela` — 0.3 s — Fechar uma janela: o oposto do abrir, menos de 0,3 s.
  - arquivo: `assets/audio/ui/fechar_janela.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `ui/noticia_boa` — 0.6 s — Aviso bom (aviso verde): dois toques ascendentes, 0,5 s.
  - arquivo: `assets/audio/ui/noticia_boa.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `ui/noticia_ruim` — 0.6 s — Aviso ruim (aviso vermelho): dois toques descendentes, 0,5 s.
  - arquivo: `assets/audio/ui/noticia_ruim.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Prédios e lugares (loops posicionais e sinos)

- [x] `predios/arsenal` — loop 25 s — Arsenal com o ferreiro trabalhando: metal batido e armas. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/arsenal.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/carpintaria` — loop 25 s — Carpintaria com ordem em andamento: serra e martelo. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/carpintaria.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/cemiterio` — loop 30 s — Cemitério (sempre): vento baixo e um corvo distante. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/cemiterio.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/coletor_madeira` — loop 25 s — Coletor de madeira funcionando: engrenagem e serra mecânica. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/coletor_madeira.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/coletor_minerio` — loop 25 s — Coletor de minério funcionando: motor e broca. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/coletor_minerio.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/conversa` — loop 30 s — Num ponto social (refeitório, praça, parque, igreja...) com gente reunida: o murmúrio da conversa. *(só perto da câmera (500 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/conversa.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/cozinha` — loop 25 s — Cozinha com o cozinheiro trabalhando: panela e fogão. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/cozinha.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/escavadeira` — loop 25 s — Escavadeira gigante funcionando: motor e broca. *(só perto da câmera (700 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/escavadeira.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/escola` — loop 30 s — Escola com gente dentro: crianças ao longe e giz. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/escola.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/laboratorio` — loop 25 s — Laboratório com a pesquisadora trabalhando: líquidos borbulhando. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/laboratorio.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/oficina` — loop 25 s — Oficina com o ferreiro trabalhando: martelo na bigorna. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/oficina.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/poca_perigo` — loop 20 s — Perto de uma poça de ácido ou lava (sempre): borbulhar baixo e chiado. *(só perto da câmera (400 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/poca_perigo.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/taverna` — loop 30 s — Taverna com gente dentro: murmúrio, canecas, riso. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/taverna.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/tocha` — loop 20 s — Perto de uma tocha acesa (sempre): fogo crepitando. *(só perto da câmera (350 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/tocha.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/vagonete` — loop 20 s — Vagonete andando no trilho: rodas de ferro. *(só perto da câmera (600 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/vagonete.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa
- [x] `predios/ventilador` — loop 20 s — Perto de um ventilador da mina (sempre): zumbido de ar. *(só perto da câmera (500 px), com o prédio em atividade)*
  - arquivo: `assets/audio/predios/ventilador.wav`  •  ouça: a emenda do loop (sem estalo) e se não cansa

## Efeitos do jogo (trabalho, combate, obras, avisos)

- [x] `sfx/achado` — 1 s — Um achado na escavação.
  - arquivo: `assets/audio/sfx/achado.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/alarme_invasao` — 3 s — Começa uma invasão de criaturas (e o aviso da onda solar, sem o stinger). *(sem posição (na tela toda); abaixa a música (alarme))*
  - arquivo: `assets/audio/sfx/alarme_invasao.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/boas_vindas` — 1 s — Gente nova na vila e melhorias compradas. *(sem posição (na tela toda))*
  - arquivo: `assets/audio/sfx/boas_vindas.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/brinde` — 1.5 s — Um brinde na taverna.
  - arquivo: `assets/audio/sfx/brinde.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/broca` — 1 s — O coletor de minério fura a rocha.
  - arquivo: `assets/audio/sfx/broca.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/colher_0` — 0.6 s cada — Colher na horta.
  - arquivo: `assets/audio/sfx/colher_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/colher_1` — 0.6 s cada — Colher na horta.
  - arquivo: `assets/audio/sfx/colher_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/colher_2` — 0.6 s cada — Colher na horta.
  - arquivo: `assets/audio/sfx/colher_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/comer_0` — 1 s cada — Um ipezinho come no refeitório.
  - arquivo: `assets/audio/sfx/comer_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/comer_1` — 1 s cada — Um ipezinho come no refeitório.
  - arquivo: `assets/audio/sfx/comer_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/comer_2` — 1 s cada — Um ipezinho come no refeitório.
  - arquivo: `assets/audio/sfx/comer_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/criatura_cai` — 1 s — Uma criatura é derrubada.
  - arquivo: `assets/audio/sfx/criatura_cai.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/curar` — 1 s — A enfermaria cura um paciente.
  - arquivo: `assets/audio/sfx/curar.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/deposito_0` — 0.7 s cada — Entrega o minério (ou a madeira) no armazém.
  - arquivo: `assets/audio/sfx/deposito_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/deposito_1` — 0.7 s cada — Entrega o minério (ou a madeira) no armazém.
  - arquivo: `assets/audio/sfx/deposito_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/deposito_2` — 0.7 s cada — Entrega o minério (ou a madeira) no armazém.
  - arquivo: `assets/audio/sfx/deposito_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/elevador` — 3 s — O elevador sobe ou desce.
  - arquivo: `assets/audio/sfx/elevador.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/equipar` — 0.7 s — Pegar casaco, traje ou arma no vestiário.
  - arquivo: `assets/audio/sfx/equipar.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/explosao` — 3 s — Dinamite no entulho (e a pane do reator).
  - arquivo: `assets/audio/sfx/explosao.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/fanfarra` — 3 s — Uma conquista (a Matriarca cai, a escavadeira fica pronta, o abismo abre, o fim da greve). *(sem posição (na tela toda))*
  - arquivo: `assets/audio/sfx/fanfarra.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/ferido` — 0.6 s — Um ipezinho se machuca (acidente, criatura, radiação).
  - arquivo: `assets/audio/sfx/ferido.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/ferrugento_golpe_0` — 0.6 s cada — O Ferrugento ataca (garra de ferro).
  - arquivo: `assets/audio/sfx/ferrugento_golpe_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/ferrugento_golpe_1` — 0.6 s cada — O Ferrugento ataca (garra de ferro).
  - arquivo: `assets/audio/sfx/ferrugento_golpe_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/festa` — 3 s — Uma festa começa na vila. *(sem posição (na tela toda))*
  - arquivo: `assets/audio/sfx/festa.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/forja` — 0.8 s — A oficina, o arsenal ou a escavadeira forjam uma peça.
  - arquivo: `assets/audio/sfx/forja.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/galho` — 2 s — Uma árvore cai.
  - arquivo: `assets/audio/sfx/galho.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/golpe_0` — 0.4 s cada — Um golpe de arma acerta.
  - arquivo: `assets/audio/sfx/golpe_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/golpe_1` — 0.4 s cada — Um golpe de arma acerta.
  - arquivo: `assets/audio/sfx/golpe_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/greve` — 3 s — A vila em greve bate panelas e ferramentas na praça.
  - arquivo: `assets/audio/sfx/greve.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/lumivoro_grito_0` — 0.8 s cada — O Lumívoro ataca.
  - arquivo: `assets/audio/sfx/lumivoro_grito_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/lumivoro_grito_1` — 0.8 s cada — O Lumívoro ataca.
  - arquivo: `assets/audio/sfx/lumivoro_grito_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/machadada_0` — 0.6 s cada — O lenhador dá uma machadada na árvore.
  - arquivo: `assets/audio/sfx/machadada_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/machadada_1` — 0.6 s cada — O lenhador dá uma machadada na árvore.
  - arquivo: `assets/audio/sfx/machadada_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/machadada_2` — 0.6 s cada — O lenhador dá uma machadada na árvore.
  - arquivo: `assets/audio/sfx/machadada_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/martelo_0` — 0.4 s cada — O engenheiro bate o martelo numa obra.
  - arquivo: `assets/audio/sfx/martelo_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/martelo_1` — 0.4 s cada — O engenheiro bate o martelo numa obra.
  - arquivo: `assets/audio/sfx/martelo_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/martelo_2` — 0.4 s cada — O engenheiro bate o martelo numa obra.
  - arquivo: `assets/audio/sfx/martelo_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/migrantes_chegando` — 4 s — Um grupo de migrantes chega no portão.
  - arquivo: `assets/audio/sfx/migrantes_chegando.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/minerio_esgotado` — 2 s — Uma jazida esgota.
  - arquivo: `assets/audio/sfx/minerio_esgotado.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/obra_pronta` — 1.2 s — Uma obra fica pronta.
  - arquivo: `assets/audio/sfx/obra_pronta.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/picareta_0` — 0.5 s cada — O ipezinho dá um golpe de picareta na pedra.
  - arquivo: `assets/audio/sfx/picareta_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/picareta_1` — 0.5 s cada — O ipezinho dá um golpe de picareta na pedra.
  - arquivo: `assets/audio/sfx/picareta_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/picareta_2` — 0.5 s cada — O ipezinho dá um golpe de picareta na pedra.
  - arquivo: `assets/audio/sfx/picareta_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/portao_abre` — 3 s — O portão da paliçada abre.
  - arquivo: `assets/audio/sfx/portao_abre.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/portao_fecha` — 3 s — O portão da paliçada fecha ao anoitecer.
  - arquivo: `assets/audio/sfx/portao_fecha.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/portao_quebra` — 2 s — Uma barricada ou máquina quebra.
  - arquivo: `assets/audio/sfx/portao_quebra.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/robo` — 3 s — O robô antigo é ligado.
  - arquivo: `assets/audio/sfx/robo.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/sino_funebre` — 4 s — O último aviso da greve e o som antigo do funeral. *(sem posição (na tela toda); abaixa a música (sino))*
  - arquivo: `assets/audio/sfx/sino_funebre.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/solar` — 3 s — A onda solar chega. *(sem posição (na tela toda))*
  - arquivo: `assets/audio/sfx/solar.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `sfx/vender` — 1 s — Vender no armazém. *(sem posição (na tela toda))*
  - arquivo: `assets/audio/sfx/vender.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Passos por tipo de chão

- [x] `passos/agua_0` — 0.4 s cada — Passo na água (as poças do S2 e do S3).
  - arquivo: `assets/audio/passos/agua_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/agua_1` — 0.4 s cada — Passo na água (as poças do S2 e do S3).
  - arquivo: `assets/audio/passos/agua_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/agua_2` — 0.4 s cada — Passo na água (as poças do S2 e do S3).
  - arquivo: `assets/audio/passos/agua_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/cascalho_0` — 0.3 s cada — Passo no cascalho (a pedreira e o caminho de cascalho).
  - arquivo: `assets/audio/passos/cascalho_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/cascalho_1` — 0.3 s cada — Passo no cascalho (a pedreira e o caminho de cascalho).
  - arquivo: `assets/audio/passos/cascalho_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/cascalho_2` — 0.3 s cada — Passo no cascalho (a pedreira e o caminho de cascalho).
  - arquivo: `assets/audio/passos/cascalho_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/madeira_0` — 0.35 s cada — Passo na madeira (plataformas, elevadores e escadas).
  - arquivo: `assets/audio/passos/madeira_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/madeira_1` — 0.35 s cada — Passo na madeira (plataformas, elevadores e escadas).
  - arquivo: `assets/audio/passos/madeira_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/madeira_2` — 0.35 s cada — Passo na madeira (plataformas, elevadores e escadas).
  - arquivo: `assets/audio/passos/madeira_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/pedra_0` — 0.5 s cada — Passo na pedra (caminho de pedra e os andares fundos da mina).
  - arquivo: `assets/audio/passos/pedra_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/pedra_1` — 0.5 s cada — Passo na pedra (caminho de pedra e os andares fundos da mina).
  - arquivo: `assets/audio/passos/pedra_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/pedra_2` — 0.5 s cada — Passo na pedra (caminho de pedra e os andares fundos da mina).
  - arquivo: `assets/audio/passos/pedra_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/terra_0` — 0.3 s cada — Passo de ipezinho na terra (floresta, vila, caminho de terra batida).
  - arquivo: `assets/audio/passos/terra_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/terra_1` — 0.3 s cada — Passo de ipezinho na terra (floresta, vila, caminho de terra batida).
  - arquivo: `assets/audio/passos/terra_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `passos/terra_2` — 0.3 s cada — Passo de ipezinho na terra (floresta, vila, caminho de terra batida).
  - arquivo: `assets/audio/passos/terra_2.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Voz curta dos ipezinhos (desligável)

- [x] `voz/homem_alegria_0` — 0.8 s cada — Voz curta (homem) num brinde ou festa: riso e 'Eita!'. Menos de 1 s.
  - arquivo: `assets/audio/voz/homem_alegria_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_alegria_1` — 0.8 s cada — Voz curta (homem) num brinde ou festa: riso e 'Eita!'. Menos de 1 s.
  - arquivo: `assets/audio/voz/homem_alegria_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_cansaco_0` — 1.3 s cada — Voz curta (homem) cansado, indo dormir: suspiro e bocejo. Menos de 1,5 s.
  - arquivo: `assets/audio/voz/homem_cansaco_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_cansaco_1` — 1.3 s cada — Voz curta (homem) cansado, indo dormir: suspiro e bocejo. Menos de 1,5 s.
  - arquivo: `assets/audio/voz/homem_cansaco_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_dor_0` — 0.5 s cada — Voz curta (homem) ao se machucar: 'Ai!'. Menos de 1 s.
  - arquivo: `assets/audio/voz/homem_dor_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_dor_1` — 0.5 s cada — Voz curta (homem) ao se machucar: 'Ai!'. Menos de 1 s.
  - arquivo: `assets/audio/voz/homem_dor_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_ola_0` — 0.6 s cada — Voz curta (homem) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s.
  - arquivo: `assets/audio/voz/homem_ola_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_ola_1` — 0.6 s cada — Voz curta (homem) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s.
  - arquivo: `assets/audio/voz/homem_ola_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_ordem_0` — 0.7 s cada — Voz curta (homem) quando recebe uma ordem do jogador: 'Sim!', 'Pode deixar'. Menos de 1 s.
  - arquivo: `assets/audio/voz/homem_ordem_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/homem_ordem_1` — 0.7 s cada — Voz curta (homem) quando recebe uma ordem do jogador: 'Sim!', 'Pode deixar'. Menos de 1 s.
  - arquivo: `assets/audio/voz/homem_ordem_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_alegria_0` — 0.8 s cada — Voz curta (mulher) num brinde ou festa. Menos de 1 s.
  - arquivo: `assets/audio/voz/mulher_alegria_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_alegria_1` — 0.8 s cada — Voz curta (mulher) num brinde ou festa. Menos de 1 s.
  - arquivo: `assets/audio/voz/mulher_alegria_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_cansaco_0` — 1.3 s cada — Voz curta (mulher) cansada, indo dormir. Menos de 1,5 s.
  - arquivo: `assets/audio/voz/mulher_cansaco_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_cansaco_1` — 1.3 s cada — Voz curta (mulher) cansada, indo dormir. Menos de 1,5 s.
  - arquivo: `assets/audio/voz/mulher_cansaco_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_dor_0` — 0.5 s cada — Voz curta (mulher) ao se machucar. Menos de 1 s.
  - arquivo: `assets/audio/voz/mulher_dor_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_dor_1` — 0.5 s cada — Voz curta (mulher) ao se machucar. Menos de 1 s.
  - arquivo: `assets/audio/voz/mulher_dor_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_ola_0` — 0.6 s cada — Voz curta (mulher) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s.
  - arquivo: `assets/audio/voz/mulher_ola_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_ola_1` — 0.6 s cada — Voz curta (mulher) quando o jogador seleciona o ipezinho: um 'oi'. Menos de 1 s.
  - arquivo: `assets/audio/voz/mulher_ola_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_ordem_0` — 0.7 s cada — Voz curta (mulher) quando recebe uma ordem do jogador. Menos de 1 s.
  - arquivo: `assets/audio/voz/mulher_ordem_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `voz/mulher_ordem_1` — 0.7 s cada — Voz curta (mulher) quando recebe uma ordem do jogador. Menos de 1 s.
  - arquivo: `assets/audio/voz/mulher_ordem_1.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Animais

- [x] `animais/coelho_foge_0` — 0.8 s cada — Um coelho foge de quem chega perto.
  - arquivo: `assets/audio/animais/coelho_foge_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `animais/coelho_foge_1` — 0.8 s cada — Um coelho foge de quem chega perto.
  - arquivo: `assets/audio/animais/coelho_foge_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `animais/coelho_foge_2` — 0.8 s cada — Um coelho foge de quem chega perto.
  - arquivo: `assets/audio/animais/coelho_foge_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `animais/coelho_morre` — 0.6 s — Um coelho é abatido.
  - arquivo: `assets/audio/animais/coelho_morre.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `animais/javali_grunhido_0` — 1.2 s cada — Um javali percebe alguém perto.
  - arquivo: `assets/audio/animais/javali_grunhido_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `animais/javali_grunhido_1` — 1.2 s cada — Um javali percebe alguém perto.
  - arquivo: `assets/audio/animais/javali_grunhido_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `animais/javali_morre` — 1.5 s — Um javali é abatido.
  - arquivo: `assets/audio/animais/javali_morre.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Criaturas (um som de ataque por espécie)

- [x] `criaturas/gosma_ataque_0` — 0.8 s cada — A Gosma ataca.
  - arquivo: `assets/audio/criaturas/gosma_ataque_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `criaturas/gosma_ataque_1` — 0.8 s cada — A Gosma ataca.
  - arquivo: `assets/audio/criaturas/gosma_ataque_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `criaturas/magmante_ataque_0` — 1 s cada — O Magmante ataca.
  - arquivo: `assets/audio/criaturas/magmante_ataque_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `criaturas/magmante_ataque_1` — 1 s cada — O Magmante ataca.
  - arquivo: `assets/audio/criaturas/magmante_ataque_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `criaturas/matriarca_ataque_0` — 2 s cada — A Matriarca (a chefe) ataca.
  - arquivo: `assets/audio/criaturas/matriarca_ataque_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `criaturas/matriarca_ataque_1` — 2 s cada — A Matriarca (a chefe) ataca.
  - arquivo: `assets/audio/criaturas/matriarca_ataque_1.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Perigos (radiação)

- [x] `perigo/geiger_0` — 0.8 s cada — Alguém está sendo irradiado (onda solar, radiação do S2).
  - arquivo: `assets/audio/perigo/geiger_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `perigo/geiger_1` — 0.8 s cada — Alguém está sendo irradiado (onda solar, radiação do S2).
  - arquivo: `assets/audio/perigo/geiger_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `perigo/geiger_2` — 0.8 s cada — Alguém está sendo irradiado (onda solar, radiação do S2).
  - arquivo: `assets/audio/perigo/geiger_2.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `perigo/geiger_3` — 0.8 s cada — Alguém está sendo irradiado (onda solar, radiação do S2).
  - arquivo: `assets/audio/perigo/geiger_3.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Máquinas

- [x] `maquinas/consertada` — 3 s — Uma máquina é consertada e volta a funcionar.
  - arquivo: `assets/audio/maquinas/consertada.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `maquinas/quebrou` — 3 s — Uma máquina quebra.
  - arquivo: `assets/audio/maquinas/quebrou.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Vida na vila (nascimento, casamento, enterro)

- [x] `vida/bebe_nasce_0` — 2 s cada — Nasce um bebê.
  - arquivo: `assets/audio/vida/bebe_nasce_0.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `vida/bebe_nasce_1` — 2 s cada — Nasce um bebê.
  - arquivo: `assets/audio/vida/bebe_nasce_1.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `vida/casamento` — 4 s — Um casal se casa.
  - arquivo: `assets/audio/vida/casamento.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `vida/enterro` — 3 s — O padre enterra um morto no cemitério.
  - arquivo: `assets/audio/vida/enterro.wav`  •  ouça: se está claro e no volume certo, sem cortar

## Sons soltos pelo ambiente (aleatórios)

- [x] `pontuais/acido_borbulha_0` — 1.5 s cada — S2: uma bolha grande de ácido estoura. *(toca a cada 6 a 15 s enquanto vale: s2)*
  - arquivo: `assets/audio/pontuais/acido_borbulha_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/acido_borbulha_1` — 1.5 s cada — S2: uma bolha grande de ácido estoura. *(toca a cada 6 a 15 s enquanto vale: s2)*
  - arquivo: `assets/audio/pontuais/acido_borbulha_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/acido_borbulha_2` — 1.5 s cada — S2: uma bolha grande de ácido estoura. *(toca a cada 6 a 15 s enquanto vale: s2)*
  - arquivo: `assets/audio/pontuais/acido_borbulha_2.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/coruja_0` — 3 s cada — Floresta de noite: uma coruja. *(toca a cada 15 a 35 s enquanto vale: noite)*
  - arquivo: `assets/audio/pontuais/coruja_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/coruja_1` — 3 s cada — Floresta de noite: uma coruja. *(toca a cada 15 a 35 s enquanto vale: noite)*
  - arquivo: `assets/audio/pontuais/coruja_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/corvo_0` — 2 s cada — Floresta de dia: um corvo ao longe. *(toca a cada 20 a 45 s enquanto vale: dia)*
  - arquivo: `assets/audio/pontuais/corvo_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/corvo_1` — 2 s cada — Floresta de dia: um corvo ao longe. *(toca a cada 20 a 45 s enquanto vale: dia)*
  - arquivo: `assets/audio/pontuais/corvo_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/gota_eco_0` — 3 s cada — S5: uma gota cai no lago. *(toca a cada 7 a 18 s enquanto vale: s5)*
  - arquivo: `assets/audio/pontuais/gota_eco_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/gota_eco_1` — 3 s cada — S5: uma gota cai no lago. *(toca a cada 7 a 18 s enquanto vale: s5)*
  - arquivo: `assets/audio/pontuais/gota_eco_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/gota_eco_2` — 3 s cada — S5: uma gota cai no lago. *(toca a cada 7 a 18 s enquanto vale: s5)*
  - arquivo: `assets/audio/pontuais/gota_eco_2.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/gotejar_0` — 1.5 s cada — Na mina e no S2: uma gota cai. *(toca a cada 8 a 20 s enquanto vale: mina/s2)*
  - arquivo: `assets/audio/pontuais/gotejar_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/gotejar_1` — 1.5 s cada — Na mina e no S2: uma gota cai. *(toca a cada 8 a 20 s enquanto vale: mina/s2)*
  - arquivo: `assets/audio/pontuais/gotejar_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/gotejar_2` — 1.5 s cada — Na mina e no S2: uma gota cai. *(toca a cada 8 a 20 s enquanto vale: mina/s2)*
  - arquivo: `assets/audio/pontuais/gotejar_2.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/lava_estalo_0` — 1.5 s cada — S3: a rocha esfriando estala. *(toca a cada 5 a 14 s enquanto vale: s3)*
  - arquivo: `assets/audio/pontuais/lava_estalo_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/lava_estalo_1` — 1.5 s cada — S3: a rocha esfriando estala. *(toca a cada 5 a 14 s enquanto vale: s3)*
  - arquivo: `assets/audio/pontuais/lava_estalo_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/lava_estalo_2` — 1.5 s cada — S3: a rocha esfriando estala. *(toca a cada 5 a 14 s enquanto vale: s3)*
  - arquivo: `assets/audio/pontuais/lava_estalo_2.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/lobo_uivo_0` — 5 s cada — Floresta de noite: um lobo uiva ao longe. *(toca a cada 40 a 90 s enquanto vale: noite)*
  - arquivo: `assets/audio/pontuais/lobo_uivo_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/lobo_uivo_1` — 5 s cada — Floresta de noite: um lobo uiva ao longe. *(toca a cada 40 a 90 s enquanto vale: noite)*
  - arquivo: `assets/audio/pontuais/lobo_uivo_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/passaro_canto_0` — 3 s cada — Floresta de dia: um pássaro canta de vez em quando. *(toca a cada 5 a 12 s enquanto vale: dia)*
  - arquivo: `assets/audio/pontuais/passaro_canto_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/passaro_canto_1` — 3 s cada — Floresta de dia: um pássaro canta de vez em quando. *(toca a cada 5 a 12 s enquanto vale: dia)*
  - arquivo: `assets/audio/pontuais/passaro_canto_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/passaro_canto_2` — 3 s cada — Floresta de dia: um pássaro canta de vez em quando. *(toca a cada 5 a 12 s enquanto vale: dia)*
  - arquivo: `assets/audio/pontuais/passaro_canto_2.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/passaro_canto_3` — 3 s cada — Floresta de dia: um pássaro canta de vez em quando. *(toca a cada 5 a 12 s enquanto vale: dia)*
  - arquivo: `assets/audio/pontuais/passaro_canto_3.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/pedra_cai_0` — 2 s cada — Na mina: pedrinhas caem da parede. *(toca a cada 25 a 60 s enquanto vale: mina)*
  - arquivo: `assets/audio/pontuais/pedra_cai_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/pedra_cai_1` — 2 s cada — Na mina: pedrinhas caem da parede. *(toca a cada 25 a 60 s enquanto vale: mina)*
  - arquivo: `assets/audio/pontuais/pedra_cai_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/pedra_cai_2` — 2 s cada — Na mina: pedrinhas caem da parede. *(toca a cada 25 a 60 s enquanto vale: mina)*
  - arquivo: `assets/audio/pontuais/pedra_cai_2.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/sapo_0` — 3 s cada — Floresta de noite: sapos num brejo. *(toca a cada 12 a 30 s enquanto vale: noite)*
  - arquivo: `assets/audio/pontuais/sapo_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/sapo_1` — 3 s cada — Floresta de noite: sapos num brejo. *(toca a cada 12 a 30 s enquanto vale: noite)*
  - arquivo: `assets/audio/pontuais/sapo_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/trovao_0` — 6 s cada — Quando chove: um trovão. *(toca a cada 20 a 50 s enquanto vale: chuva)*
  - arquivo: `assets/audio/pontuais/trovao_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/trovao_1` — 6 s cada — Quando chove: um trovão. *(toca a cada 20 a 50 s enquanto vale: chuva)*
  - arquivo: `assets/audio/pontuais/trovao_1.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/trovao_2` — 6 s cada — Quando chove: um trovão. *(toca a cada 20 a 50 s enquanto vale: chuva)*
  - arquivo: `assets/audio/pontuais/trovao_2.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/vento_rajada_0` — 4 s cada — No inverno: uma rajada de vento. *(toca a cada 10 a 25 s enquanto vale: vento)*
  - arquivo: `assets/audio/pontuais/vento_rajada_0.wav`  •  ouça: se soa natural isolado
- [x] `pontuais/vento_rajada_1` — 4 s cada — No inverno: uma rajada de vento. *(toca a cada 10 a 25 s enquanto vale: vento)*
  - arquivo: `assets/audio/pontuais/vento_rajada_1.wav`  •  ouça: se soa natural isolado

## Sons da introdução

- [x] `intro/caravana` — 6 s — Quadro 3 da introdução: a caravana a caminho da pedreira (passos, carroça).
  - arquivo: `assets/audio/intro/caravana.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `intro/explosao` — 6 s — Quadro 1 da introdução: o sol explode sobre a cidade mineira.
  - arquivo: `assets/audio/intro/explosao.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `intro/fogo` — 6 s — Quadro 7 (no mapa): a fogueira acesa no meio da vila.
  - arquivo: `assets/audio/intro/fogo.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `intro/mina` — 6 s — Quadro 6 (no mapa): o corte da mina descendo andar por andar.
  - arquivo: `assets/audio/intro/mina.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `intro/pedreira` — 6 s — Quadro 4 (no mapa): a câmera atravessa a pedreira.
  - arquivo: `assets/audio/intro/pedreira.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `intro/titulo` — 3 s — O título DEEP IRON aparece: batida grave e curta.
  - arquivo: `assets/audio/intro/titulo.wav`  •  ouça: se está claro e no volume certo, sem cortar
- [x] `intro/vento` — 6 s — Quadro 2 da introdução: cidades em ruína, vento e silêncio.
  - arquivo: `assets/audio/intro/vento.wav`  •  ouça: se está claro e no volume certo, sem cortar
