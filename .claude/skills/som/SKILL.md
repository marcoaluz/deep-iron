---
name: som
description: Convenções de som do DEEP IRON (efeitos, ambiência, música, interface e voz) e como ligar um som novo no jogo. Use ao criar, trocar ou ligar qualquer som ou música, ao mexer em volume, zoom ou variações, ao rodar a ferramenta do ElevenLabs (tools/elevenlabs) ou ao conferir por que algo toca (ou não toca). Cobre nome de arquivo, formato, slots, dB, classes de zoom, camadas de música e os testes de áudio.
---

# Som (DEEP IRON)

Tudo é **slot** (`project.godot/data/audio/slots.json`) e **sem arquivo = mudo ou o som de antes** (a `reserva`). O código nunca carrega arquivo por caminho: chama `Audio.som(id, pos)`, `Audio.som_global(id)`, `Audio.ui(nome)`, `Audio.stinger(nome)`, `Audio.tema(nome)`... O `audio_manager.gd` é o autoload; os testes carregam scripts antes dos autoloads, então fora do `audio_manager` chame o Audio por `get_node_or_null("/root/Audio")`.

## Arquivos

- Pasta: `project.godot/assets/audio/<id>.wav` (ou `.ogg`/`.mp3`; o jogo procura nessa ordem). Variações: `<id>_0`, `<id>_1`... (sorteadas, com `pitch` do slot). `ffmpeg` não está instalado: tudo em **WAV** (o Godot importa como QOA, `compress/mode=2`: **`stream.data` não são amostras**; teste que mede nível lê o ARQUIVO `.wav`).
- Formato: efeitos posicionais **mono 44,1 kHz**; ambiência, UI, stingers e globais **estéreo**; loops de ambiência 24 kHz. Música 44,1 kHz estéreo.
- Volume: efeitos curtos com pico **-3 dBFS**; UI -5; loops com RMS **-20** e pico <= -2; música RMS **-18**, pico <= -1,5. A normalização **só sobe** (a ferramenta faz). Ajuste fino é o `db` do slot, nunca refazer o arquivo.
- Loop: o jogo força o loop por código; o arquivo precisa **emendar** (crossfade no fim; razão de estalo < 6).
- Git LFS cobre wav/ogg/mp3. A chave do ElevenLabs só no `.env` (ignorado).

## O slot (campos de `slots.json`)

`id` (`pasta/nome`), `tipo` (`loop`, `loop_predio`, `tiro`, `pontual`, `tema`), `bus` (Master/Music/Ambience/SFX/UI), `db`, `variacoes`, `pitch`, `ctx` (onde vale), `intervalo` (pontual), `raio`, `grupo` + `ativo` (loop de prédio), `duck` (abaixa a música), `reserva` (`prop:<variável>` ou `novo:<chave>`), `zoom` (opcional), `duracao`, `prompt` (inglês, para o ElevenLabs), `quando` (onde toca). Som novo = uma linha aqui + a chamada no jogo + rodar `python tools/elevenlabs/docs_audio.py`.

## Zoom (Bloco 118, modelo Frostpunk)

O mundo só faz barulho com a câmera perto. Classe por slot (`audio_slots.gd zoom_de`): **perto** (passos, voz, ferramentas, bichos, loops de prédio), **medio** (criatura, portão, máquina, trovão), **global** (interface, stinger, alarme, sino, vitória, ambiência, música). `Audio.fator_zoom(classe)` (0 a 1) pela medida `cam.art_pixel_screen` (0,5 longe / 1 de sempre / 2-3 perto); limiares em `@export zoom_*`. Clicar num prédio põe o som dele em destaque por 4 s (`Audio.selecionar_predio`). Em headless o zoom é 99 (tudo se ouve).

## Música (Blocos 117, 120, 121)

- `musica/jogo` e `musica/perigo` (as de antes) são o **fallback**; `musica/abertura` e `musica/intro` são temas do `Audio.tema()`.
- **Camadas por estação** (`data/audio/musica.json`, `musicas_dinamica`): `<estacao>_noite` = pad/drone, `_dia` = melodia, `_perigo` = percussão, **mesmo BPM (80) e mesmo tom (ré menor), 120 s = 40 compassos**; mais `tema_menu`, `tema_vitoria`, `tema_derrota`. `musica_dinamica.gd` toca cada estação como `AudioStreamSynchronized` (volume por camada) e troca clipes num `AudioStreamInteractive`; os WAV não têm BPM, então a classe conta o compasso (3 s) e `fade_beats` = segundos. Sem arquivos / desligada / headless: as 2 músicas de antes.
- Gerar: `python tools/elevenlabs/gerar_musica.py --confere | --lista | --so estacao:<nome> --dry-run | --sim | --sincronia <estacao>` (precisa de numpy). **Licença Eleven Music**: indie game (< US$ 500 mil de receita do jogo e < US$ 1 mi do desenvolvedor) pode; "Studio Game" não; guarde uma cópia do termo.

## Efeitos (ElevenLabs sound-generation)

`python tools/elevenlabs/gerar_sons.py --saldo | --lista | --dry-run --so <id ou pasta> | --so <id> --sim | --candidatos 3 | --aprovar <nome> <n> | --reprocessa`. Cache por hash do prompt (mesmo pedido nunca paga duas vezes), teto de chamadas e confirmação de custo (`--sim`). Custo medido: efeitos ~10,5 créditos/s; música ~13,7/s. A API devolve PCM **estéreo** mesmo quando a doc diz MP3. Depois: `godot --headless --path project.godot --import` e `docs_audio.py`.

## Onde ligar

- Evento do jogo → função do `audio_manager.gd` (`som("sfx/...", pos)`), chamada no script do sistema (no estilo `Audio.som(...)`).
- Interface: `Audio.ui("clique"|"erro"|"abrir_janela"...)` (bus UI, slider "Interface").
- Ambiência por andar: `CTX_SLOT` (floresta dia/noite, mina, s2 a s5) + camadas (chuva, vento do inverno, onda solar); eco do S5 = reverb no bus Ambience.
- Ducking: `Audio.duck("alarme"|"sino"|"aviso")`.
- Voz curta: `Audio.voz(pos, emocao, genero)` (desligável nas Configurações).

## Testes de áudio (um por vez, APPDATA isolado)

`b55_audio`, `b114_audio_sistemas`, `b115_sons_do_jogo`, `b116_audio_carga` (os 191+ arquivos carregam e não estão inaudíveis), `b117_musica`, `b118_audio_zoom`, `b120_musica_ferramenta`, `b121_musica_dinamica`. Nunca afirme que um som "ficou bom": ninguém ouviu; diga que só os números foram conferidos.
