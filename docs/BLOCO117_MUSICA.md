# Bloco 117 — Música do jogo pela API do ElevenLabs (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido do Marco: "a música de loop do jogo vai ser alterada, correto? pode tentar fazer na API do ElevenLabs da mesma chave"
(a abertura e a intro estavam pendentes desde o Bloco 114). Também: "se houver necessidade de criar mais algum áudio me fala" (ver a seção 6).

- Teste: `tests/blocos/b117_musica.gd`, **0 falhas**, registrado no GUT (`test_b117_musica`). Vizinhos rodados: b116, b114, b115, b55, b112 (0 falhas).
- **Nada foi ouvido por mim.** Conferi números (duração, volume, emenda), não o gosto.

## 1) A API de música

`POST https://api.elevenlabs.io/v1/music` (documentação oficial conferida): `prompt`, `music_length_ms` (3 a 600 s), `model_id` (`music_v1`), `force_instrumental`, query `output_format`.
**Funciona no plano Creator.** Pedimos `pcm_44100`, que aqui vem em estéreo de verdade, 16 bits: dá para medir e corrigir volume e emendar o loop em Python.
Custo medido: as 4 músicas (315 s) gastaram cerca de **2.130 créditos** (~6,7 por segundo); sobram ~116.900. (O contador do plano não mostrou o custo dos dois testes de 10 s na hora; o custo aparece depois.)

## 2) As 4 músicas (`assets/audio/musica/`)

| Arquivo | Duração | Loop | Onde toca |
|---|---|---|---|
| `abertura.wav` | 72 s | sim | menu inicial (`Audio.tema("abertura")`) |
| `intro.wav` | 60 s | não (fade-out de 2,5 s) | introdução (`Audio.tema("intro")`) |
| `jogo.wav` | 117 s | sim | a partida normal (substitui `music_loop.wav`) |
| `perigo.wav` | 57 s | sim | durante a invasão (substitui `music_danger.wav`) |

Todas WAV estéreo de 44,1 kHz, **RMS -18 dBFS** (um pouco abaixo da música antiga, -16, para sobrar espaço ao ducking), pico até -1,5 dBFS. Os loops têm um **crossfade de 3 s** entre o fim e o começo
(razão de estalo 0,2 a 1,4; o limite de estalo é 6). Os prompts estão em `data/audio/slots.json` (campo `prompt` e `seg`). Registro do que foi gerado: `data/audio/musicas.json`.

## 3) A ferramenta `tools/elevenlabs/gerar_musica.py`

`--lista`, `--dry-run`, `--tudo`, `--so musica/jogo`, `--candidatos N` (em `audio_candidatos/musica/`, fora do git), `--aprovar musica/jogo N`, `--force`, teto de chamadas (`--max-geracoes 8`), cache por hash
(`audio_candidatos/_cache_musica/`: o mesmo pedido não gasta de novo) e a chave só do `.env` (mascarada). Precisa de **numpy** para gerar (`--lista` e `--dry-run` funcionam sem).
Prompt mudou → o arquivo aparece como desatualizado na `--lista`.

## 4) O que mudou no jogo (`audio_manager.gd`)

- A música do jogo e a de perigo agora vêm dos slots `musica/jogo` e `musica/perigo`. Sem arquivo vale o loop antigo (reserva), como nos outros slots.
- **A ambiência da mina também vem do slot.** (Commit 2845e217, já enviado.) Antes o som antigo da caverna começava no `_ready` e o arquivo novo nunca o trocava; era o "som antigo junto".

## 5) Achado importante: o b116 media bytes comprimidos

O WAV importado pelo Godot fica em **QOA** (`compress/mode=2`, `AudioStreamWAV.format == 3`): `stream.data` **não são amostras**. O b116 media volume e emenda nesses bytes, então essas duas checagens
não verificavam nada de verdade. Agora o b116 e o b117 leem o **arquivo .wav** (cabeçalho + amostras). Com a medida real, tudo passa, mas dois loops de prédio têm RMS baixo:
`predios/tocha` (RMS -37, pico 0 dBFS) e `predios/cozinha` (RMS -34). São fogo estalando (poucos picos altos), que o Marco já ouviu e aprovou; o critério de "inaudível" passou a ser RMS baixo **e** pico baixo.
Consequência a conhecer: o jogo toca o WAV em QOA (lossy, ~5x menor na memória); soa como WAV para efeitos, mas é compressão com perda.

## 6) Mais algum áudio a criar?

Pelo jogo, **falta pouco**, e nada impede de jogar:
- **Nada obrigatório.** Os 128 slots de efeitos + as 4 músicas têm arquivo.
- **Opcional, se você quiser mais música:** vitória/derrota longas (hoje são stingers curtos), uma música de **inverno** ou de **noite** (hoje a música do jogo é uma só), e temas por andar da mina. É só dizer e eu gero o mesmo jeito (`gerar_musica.py`).
- Os **WAV antigos** (`music_loop.wav`, `music_danger.wav`, `cave_ambience.wav`, `click.wav`...) seguem na pasta só como reserva; podem ser apagados quando você decidir que nunca mais voltam (os testes que checam a reserva teriam que mudar).

## 7) O que NÃO foi verificado

- Como as músicas **soam**: se a abertura repete sem emenda audível, se a do jogo cansa, se a de perigo combina com o alarme e o ducking. Se alguma não agradar: `python tools/elevenlabs/gerar_musica.py --so musica/jogo --candidatos 3 --sim` e `--aprovar musica/jogo N`.
- Os temas rodaram só em teste (stream certo, loop, `tema()`), não numa partida de verdade.
- Instalando o ffmpeg dá para converter para OGG e reduzir o tamanho no LFS (as 4 músicas pesam ~55 MB em WAV).
