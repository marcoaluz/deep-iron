# Bloco 116 — Ferramenta de geração de sons (ElevenLabs), candidatos, cache e teste de carga (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido: "construa uma ferramenta que gera os sons do pedido pela API de efeitos da ElevenLabs", com `--dry-run`, `--so`,
`--candidatos`, `--aprovar`, cache por hash, limites de custo, pós-processamento, lista de escuta e teste de carga.

**Boa parte disso já existia** (Blocos 114 e 115, e a geração dos 191 sons que o Marco aprovou: "ficou muito bom agora"): a ferramenta de geração, o manifesto
(`slots.json`), a chave no `.env` fora do git, a normalização, o loop e os testes. Este bloco **só fez o que faltava** e reorganizou nos caminhos pedidos.

- Teste: `tests/blocos/b116_audio_carga.gd`, 21 verificações, **0 falhas** (e o GUT); mais o teste offline da ferramenta (`tools/elevenlabs/testa_ferramenta.py`), 0 falhas.
- **Nenhum crédito foi gasto neste bloco** (nenhuma chamada nova à API; o teste da ferramenta usa um som sintético).

## 1) A documentação oficial (conferida antes de codar)

`POST https://api.elevenlabs.io/v1/sound-generation`, header `xi-api-key`; corpo: `text` (obrigatório), `duration_seconds` (0,5 a 30; sem ele a API adivinha),
`prompt_influence` (0 a 1, padrão 0,3), `loop` (só no modelo v2), `model_id` (o único valor aceito é `eleven_text_to_sound_v2`); query `output_format`. Bate com o que a ferramenta usa.

Duas diferenças entre a documentação e o que a API faz **na prática** (conferidas nos arquivos gerados): a documentação diz que a resposta é MP3, mas pedindo `pcm_*` ela devolve
PCM de 16 bits **estéreo**; e diz que PCM de 44,1 kHz exige o plano Pro, mas funcionou no plano Creator do Marco. A ferramenta trata o estéreo (e faz a média pra mono nos sons posicionais).

## 2) O que mudou

| Pedido | Como ficou | Onde |
|---|---|---|
| Caminhos | `tools/elevenlabs/gerar_sons.py`, `posprocessa.py`, `docs_audio.py`; `docs/audio/PEDIDO_DE_SONS.md`, `PROMPTS_ELEVENLABS.md`, `LISTA_DE_ESCUTA.md`. O manifesto continua `data/audio/slots.json` (o jogo e os testes dependem dele; ele já tem id, arquivo, prompt em inglês, duração, loop, categoria e dB). Todas as referências foram atualizadas. | `tools/elevenlabs/`, `docs/audio/` |
| Chave | De `ELEVENLABS_API_KEY` ou do `.env` na raiz. O `.env` está no `.gitignore` (e `.env.*`, menos o `.env.example`, que ficou sem chave). A chave nunca é impressa: erros da API passam por uma máscara; `--confere-segredos` varre os 45 mil arquivos do git e a chave não aparece em nenhum. | `gerar_sons.py` |
| `--dry-run` | Lista o que seria gerado, a contagem, quantos já estão em cache, os segundos e o custo estimado, sem gastar nada. | `gerar_sons.py` |
| `--so <id ou pasta>` | Só esses slots (id exato ou a pasta). Sem `--so`/`--tudo` não gera nada. A ordem é a de prioridade (ambiência por andar, fornalha, sinos, stingers, interface, depois o resto). | `gerar_sons.py` |
| `--candidatos N` e `--aprovar` | Gera N versões em `audio_candidatos/<nome>/<n>.wav` (**fora do git**) e `--aprovar <nome> <n>` copia a escolhida pro destino e marca como aprovada. | `gerar_sons.py` |
| Cache e custo | Cada chamada fica guardada (`audio_candidatos/_cache/`) pela chave hash(prompt+parâmetros)+nome+n: o mesmo pedido **nunca gasta crédito duas vezes** (apagar o arquivo e gerar de novo vem do cache). `--force` ignora o cache de propósito. `data/audio/gerados.json` guarda o hash do pedido de cada arquivo: mudou o prompt, o arquivo aparece como **desatualizado** (`--desatualizados`, `--atualiza`). Teto de chamadas por execução (`--max-geracoes`, padrão 40) e confirmação acima de X créditos (`--confirma-acima`, padrão 1.500; sem terminal exige `--sim`). Estimativa: 10,5 créditos por segundo (medido no lote real). | `gerar_sons.py`, `gerados.json` |
| Pós-processamento | **Sem ffmpeg** (não está instalado; a ferramenta avisa): em Python puro corta o silêncio dos curtos, normaliza **só subindo** o volume (loops: RMS −20 dBFS; curtos: pico −3; interface: pico −5; teto de +36 dB) e emenda o loop com um crossfade quando há estalo. Com o ffmpeg a conversão pra OGG fica disponível (`converte_ogg`); sem ele fica em WAV, que é o que o jogo já usa. | `posprocessa.py` |
| Loops sem estalo | 5 loops tinham um salto no ponto da emenda (mina, lava, onda solar, cemitério, ventilador; razão 14 a 31 vezes a diferença típica): receberam crossfade de 400 ms (agora 0,3 a 1,6). O jogo marca o loop por código. | `gerar_sons.py --reprocessa` |
| LFS | O `.gitattributes` já manda wav, ogg e mp3 pro Git LFS (conferido no teste). | `.gitattributes` |
| `PEDIDO_DE_SONS.md` | Cada som: arquivo, duração, loop sim/não, descrição, **termos de busca em inglês** (pra procurar num banco de sons) e o estado; o que falta vem primeiro. | `docs_audio.py` |
| Lista de escuta | `docs/audio/LISTA_DE_ESCUTA.md`: os 191 arquivos em ordem de prioridade, com caixa pra marcar, o que ouvir em cada um e como trocar. Todos já vêm marcados como aprovados (o Marco ouviu o lote e aprovou). | `docs_audio.py` |
| Teste de carga | O jogo rodando com os arquivos, sem eles e sem a pasta (ver abaixo). | `b116_audio_carga.gd` |

## 3) Teste de carga

- **Com os arquivos:** os 126 slots de efeitos têm todos os arquivos (191, 1.038 s), carregam como WAV, os loops repetem e emendam, nenhum está quase inaudível (loops com RMS acima de −34 dBFS;
  curtos com pico acima de −20: o problema do cemitério não volta), e o jogo toca 87 slots em sequência (ambiência de todos os andares, prédios, sons soltos, efeitos, interface, stingers, passos, voz, alarme, sino) sem erro.
- **Sem os arquivos:** o mesmo percurso; tocam só os 57 slots que têm o som de antes, o resto é silêncio sem erro.
- **Sem a pasta:** igual ao "sem arquivos"; a pasta volta e os arquivos voltam.
- **Git e ferramenta:** `.env` e `audio_candidatos/` no `.gitignore`, `.env.example` sem chave, LFS, `gerados.json` registrando os 191, os 3 docs citando todos os sons, e o teste offline da ferramenta.

## 4) O que ficou de fora

- **A música** (`musica/abertura` e `musica/intro`): não é efeito sonoro; os slots existem e o jogo toca quando o arquivo existir.
- **A conversão pra OGG:** o ffmpeg não está instalado. Os 191 WAV ocupam ~80 MB no LFS; instalando o ffmpeg dá pra converter os loops.
- Nada novo foi gerado (todos os 191 já existiam e foram aprovados).

## 5) O que NÃO foi verificado

- **Nada foi ouvido por mim.** O teste confere números (níveis, emendas, cobertura), não o gosto.
- A chamada **real** à API só foi exercitada nos Blocos 114/115 (lote de 191 + regerações); os novos modos (`--candidatos`, `--aprovar`, cache, teto, confirmação) foram testados offline, com um som sintético no lugar da API. Na primeira vez que o Marco usar `--candidatos` de verdade, vale conferir o primeiro resultado.
- Os termos de busca dos sons são derivados dos prompts automaticamente; podem pedir ajuste.

## 6) Como usar (resumo)

```
python tools/elevenlabs/gerar_sons.py --so sfx/picareta --candidatos 3 --dry-run   # quanto custaria
python tools/elevenlabs/gerar_sons.py --so sfx/picareta --candidatos 3 --sim       # gera 3 versões em audio_candidatos/
python tools/elevenlabs/gerar_sons.py --aprovar sfx/picareta_0 2                   # escolhe a 2
godot --headless --path project.godot --import
python tools/elevenlabs/gerar_sons.py --docs                                       # atualiza os docs
```
