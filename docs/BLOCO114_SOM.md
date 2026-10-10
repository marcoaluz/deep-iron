# Bloco 114 — Sistemas de som (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido: "Prompt 6", som, ambiência e sons dos prédios. O plano foi APROVADO pelo Marco ("pode") com:
- bus novo **UI**, sem bus separado só pra voz (a voz sai no SFX e uma caixa liga e desliga);
- voz **ligada** por padrão (sem arquivo, não toca nada);
- os nomes dos arquivos são os da lista `docs/audio/PEDIDO_DE_SONS.md`; **o Marco gera os sons no ElevenLabs** (plano Creator) e põe nas pastas.

E um pedido a mais: a **música da introdução e da abertura** do jogo, que estava pendente. Como este bloco **não cria áudio** (regra do prompt e
"sem criar som agora"), ela entrou como **dois slots prontos** (`musica/abertura` no menu, `musica/intro` na introdução) + o sistema de temas.
O arquivo de cada um é só gerar e pôr na pasta.

- Teste: `tests/blocos/b114_audio_sistemas.gd`, 116 verificações, **0 falhas** (rodado duas vezes, mais o GUT). Registrado (`test_b114_audio_sistemas`).
- **Nenhum áudio foi criado nem ouvido.** Os testes usam sons falsos (silêncio) criados na memória. Nada disso foi conferido de ouvido.

## 1) A ideia: o catálogo de slots

Cada som é um **slot com nome fixo** em `data/audio/slots.json` (55 slots, 73 arquivos esperados). O jogo procura
`assets/audio/<id>.ogg|wav|mp3` (e `<id>_0`, `<id>_1`... nos slots com variações). **Sem arquivo o slot fica mudo** (sem erro) ou, onde já havia
um som, toca o de antes (a *reserva*): assim nada do jogo atual muda até os arquivos novos chegarem. O loop é forçado por código (o import não
precisa marcar). A lista completa, com onde cada um toca, a duração esperada, o bus e o dB, é `docs/audio/PEDIDO_DE_SONS.md`
(gerada por `python tools/elevenlabs/docs_audio.py`; mostra também quais já existem). `.ogg` e `.mp3` já estão no Git LFS.

## 2) O que entrou

| Pedido | Como ficou | Onde |
|---|---|---|
| **1) Ambiência por andar** | A câmera decide pelo andar (`env.level_at`): S2 ácido, S3 lava, S4 cachoeira, S5 lago, cada um com o loop dele; floresta de dia (pássaros) e de noite (grilos); mina (a de sempre). Por cima, **camadas**: chuva e o **vento do inverno** (floresta e vila). O **S5 ganha eco**: um reverb no bus Ambience que sobe só lá. Troca suave de 2 s (como antes). | `audio_manager.gd` (`_update_context`, `set_ambience`, `_camada`, `_setup_eco`) |
| **2) Sons de prédios** | `SonsPredios` (filho do `Audio`): um loop posicional por prédio, **só perto da câmera** (raio por slot), **só com o prédio em atividade** (`som_ativo()`), no máximo 6 juntos (os mais perto). Fornalha (herdada por carpintaria, carvoaria e curtume), taverna (com gente dentro), cemitério (sempre), vagonete (andando), coletor de madeira e de minério. **Sino da igreja** na missa e no funeral (posicional, só na subida). | `sons_predios.gd`, `som_ativo()` nos prédios, `calendario.gd _sinos/_toca_sinos` |
| **3) Stingers** | `Audio.stinger(nome)`: amanhecer (o dia virou), onda solar (o aviso), estágio novo, pesquisa pronta, morte, vitória, derrota, missão cumprida. Sem arquivo vale a fanfarra, o sino ou o alarme de antes; o amanhecer não tem reserva (mudo). | `audio_manager.gd`, ligados em `sun.gd`, `centro_vila.gd`, `research.gd`, `ipezinho.gd`, `morale.gd`, `missoes.gd` |
| **4) Bus UI** | Bus novo **UI** (4 vozes, slider "Interface" nas Configurações): abrir e fechar janela, confirmar, erro, clique, notícia boa e má. A notícia sai do `show_toast` pela cor (verde = boa, vermelho = ruim; aviso de outra cor fica mudo), com intervalo mínimo. | `default_bus_layout.tres`, `audio_manager.gd`, `hud.gd`, `settings_panel.gd` |
| **5) Passos e voz** | O passo depende do chão (`Audio.chao_de`): caminho pintado (terra, cascalho, pedra), poça = água, perto de plataforma, escada ou elevador = madeira; senão pelo lugar (andares fundos = pedra, pedreira = cascalho, resto = terra). **Voz curta** (homem e mulher): ordem do jogador, dor, alegria na taverna, cansaço ao ir dormir; intervalo mínimo de 1,2 s; caixa **"Voz dos ipezinhos"** nas Configurações (liga e desliga, salva). | `audio_manager.gd`, `ipezinho.gd`, `taverna.gd`, `main.gd`, `settings_panel.gd` |
| **6) Ducking** | A música abaixa **9 dB no alarme, 7 dB no sino e 6 dB no aviso** (banner), em 0,2 s, segura 2,5 s e volta em 1,2 s (tudo `@export`). É um efeito Amplify no bus Music: o slider de música não é mexido. Dois ao mesmo tempo: vale o mais fundo. O sino só abaixa se deu pra ouvir. | `audio_manager.gd` (`duck`, `_duck_tick`), `hud.gd show_banner` |
| **Música: abertura e intro** | `Audio.tema("abertura")` no menu, `tema("intro")` na introdução (segue tocando nos quadros no mapa), `tema("")` quando começa a partida ou a intro acaba. A música do jogo desce e volta com troca suave; o perigo espera enquanto o tema toca. **Sem arquivo, nada muda** (a música de sempre segue). | `audio_manager.gd tema()`, `start_menu.gd`, `intro.gd`, `intro_cinema.gd`, `main.gd` |
| **Sons da intro** | Os sete sons do Bloco 112 (`explosao`, `vento`, `caravana`, `pedreira`, `mina`, `fogo`, `titulo`) agora são slots (`intro/<nome>`) e entram na lista. | `audio_manager.gd intro()` |

## 3) Mudanças de comportamento que valem saber

- Os cliques, o erro, abrir/fechar janela e o "pôr prédio" saíram do bus SFX para o **UI**. Sem arquivos novos soam igual (a reserva é o som de antes), mas
  agora têm slider próprio. A fanfarra, o sino, o alarme e a solar seguem nas vozes globais do SFX.
- A ambiência dos andares fundos deixou de ser uma só ("fundo"): são `s2` a `s5` (o b55 foi ajustado).
- O amanhecer passa a ser detectado pelo `Audio` (o dia virou); o primeiro dia que o jogo vê, e voltar ao menu, não tocam.
- `play_at` agora devolve se tocou (quem chama ignorava; o sino usa pra decidir se abaixa a música).

## 4) Pra pôr os arquivos (pro Marco)

1. Gere cada som no ElevenLabs e salve com o **nome exato** de `docs/audio/PEDIDO_DE_SONS.md`, em `project.godot/assets/audio/<pasta>/` (`ambiencia/`, `predios/`, `stingers/`, `ui/`, `passos/`, `voz/`, `musica/`, `intro/`).
2. Rode `godot --headless --path project.godot --import` (ou abra o editor uma vez).
3. `python tools/elevenlabs/docs_audio.py` atualiza a lista com o que já tem.
4. Loops: o começo e o fim têm que emendar. Posicionais (prédios, passos, voz): mono. Normalizar em torno de −16 LUFS, pico abaixo de −1 dB.

## 5) Testes rodados (um por vez, em primeiro plano, APPDATA isolado; o save real conferido por md5)

| Teste | Resultado |
|---|---|
| `b114_audio_sistemas` (duas vezes, e pelo GUT) | 0 falhas (116 OK) |
| `b55_audio` | 0 falhas (ajustado: ambiência "s2" no nível 2 e o clique no bus UI) |
| `b112_intro_primeiro_dia`, `b54_configuracoes`, `hud_frostpunk`, `b88_padre_igreja`, `b64_vagonete`, `b86_fornalha`, `b113_dificuldade`, `b100_missoes`, `b95_layout_v2`, `p28_save` | 0 falhas |

`godot --import` rodou limpo. **Não conferidos:** o resto da bateria (seguindo a nota de memória, não rodei tudo).

## 6) O que NÃO foi verificado

- **Nada de ouvido.** Não há arquivo de som novo; só conferi números (volumes, bus, quem toca quando, queda de 6 a 10 dB do ducking). Como soa, o equilíbrio
  entre ambiência, música e efeitos, e se as emendas dos loops ficam limpas só dá pra saber com os arquivos.
- O eco do S5 é um reverb sobre a ambiência (0,35 de mistura, sala 0,85): vale ouvir com o arquivo do lago e ajustar `eco` no `slots.json` e `eco_sala`.
- Os ganchos de **onda solar, estágio, pesquisa, morte, derrota, vitória e missão** foram conferidos como ligados no código, não disparados um a um no jogo.

## 7) Pendências

- Gerar os 73 arquivos (e a música da abertura e da intro) no ElevenLabs.
- Se o Marco quiser, escrevo os **prompts prontos** pra colar no ElevenLabs a partir da coluna "Quando toca".
