# Áudio (Bloco 55)

Tudo sintetizado do zero (`tools/gen_audio.py` = os sons antigos; `tools/gen_audio_novos.py` = os do
Bloco 55, cada um com a sua seed: rodar um não muda os do outro). WAV mono 16-bit 22050 Hz em
`project.godot/assets/audio/`. Autoload `Audio` (`scripts/core/audio_manager.gd`).

## Mixer

| bus | o quê | slider (Configurações) |
|---|---|---|
| Master | tudo; **limitador** (`AudioEffectHardLimiter`, teto −0,5 dB) | Volume geral |
| Music | música calma + música de perigo | Música (+ "Música ligada", tecla M) |
| Ambience | mina / superfície dia / noite / fundo + chuva por cima | Ambiente da caverna |
| SFX | efeitos (24 vozes 2D) + interface (4 vozes) | Efeitos |

- **Variação:** cada efeito toca com tom aleatório leve (`pitch_variation` 8%; alguns menos) e nunca a
  mesma variação duas vezes seguidas.
- **Limite de vozes:** 24 no total; **no máximo 4 do mesmo som** ao mesmo tempo (`max_same_voice`);
  passos limitados a 8/s. Som longe da câmera (> 900 px) nem toca.
- Medido no teste: 15 ipezinhos trabalhando, pico do Master −11 dB (o limitador nem precisa agir).

## Música e ambiência

- **Música:** calma (`music_loop`) e **perigo** (`music_danger`, tambores e metais graves). Invasão
  começou → troca suave (2,5 s) pra de perigo; acabou → volta.
- **Ambiência pelo lugar da câmera** (o ponto do chão que ela olha), troca suave de 2 s:
  - mina (`cave_ambience`): a vila, os túneis;
  - clareira de dia (`surface_day_loop`: vento, corvos) / de noite (`surface_night_loop`: grilos, coruja);
  - chuva por cima na clareira quando está chovendo (`rain_loop`);
  - fundo — nível 2 e abismo (`deep_loop`: ronco grave, lava borbulhando, vapor).

## Evento → som

| evento | som | onde |
|---|---|---|
| picareta na pedra | `pick_0..2` | ipezinho (golpe) |
| martelo na obra | `build_hit_0..2` *(novo)* | ipezinho engenheiro (golpe) |
| obra pronta | `build_done` *(novo)* | ipezinho engenheiro |
| marcar canteiro / construir | `place` *(novo)* | posicionador |
| passos | `step_0..3` | ipezinho |
| entregar no armazém | `deposit_0..2` | armazém |
| comer | `eat_0..2` | ipezinho |
| machadada | `chop_0..2` | lenhador / coletor de madeira |
| galho quebrando (árvore cai) | `branch` | árvore |
| colher na horta | `harvest_0..2` *(novo)* | horta |
| pegar casaco/traje/arma | `equip` *(novo)* | vestiário |
| forja (peça, ferramenta, arma) | `forge` | oficina, arsenal, escavadeira |
| broca do coletor de minério | `drill` *(novo)* | coletor de minério (Bloco 57) |
| elevador | `elevator` | elevador |
| machucado / curado | `hurt` / `heal` | ipezinho / enfermaria |
| morte | `toll` | enfermaria (memorial) |
| achado na mina | `find` | achados |
| robô ligando | `robot` | robô |
| pane do reator | `boom` | escavadeira |
| brinde na taverna | `cheers` | taverna |
| **festa na vila** | `party` *(novo; antes era a fanfarra)* | bem-estar |
| greve | `protest` | bem-estar |
| alarme de invasão | `alarm` | defesa |
| lumívoro / ferrugento | `screech` / `clank` | criaturas |
| golpe | `hit` | guarda / criatura |
| criatura derrubada | `creature_down` *(novo)* | criatura |
| barricada quebrando | `gate_break` | portão |
| onda solar | `solar` | sol |
| conquista (escavadeira, escudo, vila) | `fanfare` | vários |
| vender / recrutar | `sell` / `recruit` | economia |
| clique / erro | `click` / `error` | interface |
| abrir / fechar janela | `ui_open` / `ui_close` *(novo)* | HUD |
| clima | `rain_loop` (ambiência) | clareira |

Sem lacuna: todo evento da lista tem som (o teste `b55_audio` confere que cada um carrega).
