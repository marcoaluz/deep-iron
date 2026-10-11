# Bloco 120 — Música em camadas pela Eleven Music: ferramenta, faixas e veredito de sincronia (relatório)

Data: 2026-10-11. Branch `isometrico`. Pedido: Prompt 7, parte da **ferramenta** ("estenda tools/elevenlabs/ para gerar música pela Eleven Music... tema do menu, vitória, derrota e a música do jogo por estação, cada uma com dia, noite e perigo...
me diga, depois de gerar, se as camadas ficaram sincronizadas o bastante para o AudioStreamSynchronized"). O **sistema** de música dinâmica no jogo (Synchronized / Interactive, configurações, fallback) é o Bloco 121.
Teste: `tests/blocos/b120_musica_ferramenta.gd`, **0 falhas**, registrado no GUT. **Nada foi ouvido por mim.**

## 1) A API (documentação lida, https://elevenlabs.io/docs/api-reference/music/compose)

`POST https://api.elevenlabs.io/v1/music`, header `xi-api-key`; corpo `prompt` (ou `composition_plan`, que não se mistura), `music_length_ms` (3.000 a 600.000), `model_id` (`music_v1` padrão; `music_v2` e `music_v2_5` existem), `force_instrumental`; query `output_format`
(pedimos `pcm_44100`: estéreo de verdade). `seed` não vale com `prompt`. A ferramenta usa só `prompt`, `music_length_ms`, `model_id` (`music_v1`), `force_instrumental` e `output_format`. Funciona no plano Creator do Marco.
O guia de prompts da Eleven Music diz que o modelo respeita BPM e tom pedidos o bastante para empilhar faixas: foi o que usamos.

## 2) As 15 faixas (`data/audio/musica.json`, `assets/audio/musica/`)

Folk sombrio + industrial (violão de aço, sanfona, percussão de metal e correntes, drones graves), instrumental, **80 BPM, 4/4, ré menor, 40 compassos = 120 s** (os loops saem com 117 s: crossfade de 3 s).

| Faixa | Papel | Loop |
|---|---|---|
| `tema_menu` | tema do menu (arranjo completo) | sim |
| `tema_vitoria` / `tema_derrota` | 60 s (20 compassos), terminam com fade-out | não |
| `primavera_`, `verao_`, `outono_`, `inverno_` + `dia` | camada de **melodia** (violão + sanfona sobre um drone suave) | sim |
| ... + `noite` | camada de **pad** (só drones, cordas graves, sem melodia, sem bateria) | sim |
| ... + `perigo` | camada de **percussão** (metal, bigornas, correntes, pulso grave, sem melodia) | sim |

Cada estação tem o clima dela no prompt (primavera = o degelo e uma esperança frágil; verão = calor seco e poeira; outono = melancolia e chuva chegando; inverno = gelo e vazio). "No fundo da mina: mais drone, menos melodia" é regra do **jogo**
(o Bloco 121 abaixa a melodia e sobe o pad lá), porque a camada de pad já é só drone.

## 3) A ferramenta `tools/elevenlabs/gerar_musica.py`

`--lista`, `--confere` (BPM, tom, compassos fechando com a duração, "no vocals", ids únicos), `--dry-run`, `--so estacao:<nome>|menu|vitoria|derrota|<id>`, `--tudo`, `--candidatos N`, `--aprovar`, `--force`, cache por hash (`audio_candidatos/_cache_musica/`),
`--max-geracoes` (8 por execução), `--max-creditos` (10.000: recusa antes de gastar), `--confirma-acima` (1.500 créditos: pede confirmação, ou `--sim`), custo estimado 13,7 créditos por segundo e `--sincronia <estação>`.
A chave vem só do `.env` (mascarada). Pós-processamento (numpy): RMS -18 dBFS, pico até -1,5, crossfade de 3 s nos loops, fade-out no que não repete; as camadas de uma estação saem com o mesmo tamanho.
`docs/audio/PEDIDO_DE_SONS.md` ganhou a seção "Música em camadas" (as faixas, como gerar, dicas e a licença); `docs_audio.py` a gera.

## 4) O VEREDITO: as camadas ficaram sincronizadas?

**Sim, nas 4 estações** (`python tools/elevenlabs/gerar_musica.py --sincronia <estação>`; tabelas em `docs/audio/SINCRONIA_MUSICA.md`). Como se mediu: o envelope de ataques (spectral flux) de cada camada, o tempo por autocorrelação, o atraso global entre os pares e, por janelas de 30 s,
o quanto esse atraso se mexe (a deriva), e o tom pelo cromagrama.

| Estação | Tempos (BPM) | Deriva dos ataques dia x perigo | Tons (estimados) |
|---|---|---|---|
| Primavera | 80,20 / 80,28 / 80,00 | 0 ms | D menor (melodia), A (pad e percussão) |
| Verão | 80,01 / 79,94 / 79,88 | 0 ms | A / D / D |
| Outono | 79,95 / 80,53 / 80,09 | 0 ms | D / D / A |
| Inverno | 79,62 / 79,69 / 80,21 | 0 ms | A / A / D |

- **Controle negativo:** uma faixa esticada só 0,1% já acusa 46 a 70 ms de deriva; as faixas reais dão 0 (resolução de 11,6 ms), então os tempos estão presos.
- O "tom" que o cromagrama acha às vezes é A em vez de D porque o pad e a percussão firmam na **quinta** (A) de ré menor: é compatível (o critério aceita a tônica ou a quinta).
- **Conclusão:** o jogo pode tocar as três camadas **juntas** com `AudioStreamSynchronized`. O plano B (trocar faixa inteira com crossfade, `AudioStreamInteractive`) segue disponível e será o caminho das trocas de estação.
- **Limite honesto:** o que não dá para medir por números é se a "batida 1" de uma camada cai na batida 1 das outras (alinhamento de compasso) e se as notas soam bem juntas. Isso só se descobre **ouvindo**; se alguma estação soar fora, `--so <id> --candidatos 3` gera outras versões.
- A medida inicial (janelas de 20 s com busca livre) dava deriva falsa de ~380 ms porque a batida se repete a cada 750 ms; a medida foi corrigida (atraso global + deriva fina) e validada com o controle acima.

## 5) Custo

Piloto da primavera (3 faixas, ~4.900 créditos) para medir antes do lote; depois verão, outono, inverno e os temas. Total ~23.000 créditos (1.680 s de música, 13,7 créditos por segundo). **Saldo da ElevenLabs: 92.172 de 131.000.**

## 6) LICENÇA (o Marco precisa conferir)

Termos da Eleven Music: **https://elevenlabs.io/eleven-music-model-specific-terms** (a página antiga `eleven-music-v1-terms` deu 404; "Last updated: 09 October 2026"). O que li:
- Nos planos Free, Starter, Creator, Pro, Scale (e Business e Enterprise Music Lite): uso comercial online e offline permitido **exceto cinema, TV, rádio e "Studio Games"**.
- Um **Indie Game** não é Studio Game: a receita do jogo (com todas as versões, edições e DLCs) abaixo de **US$ 500.000** desde o lançamento comercial **e** a receita de todos os jogos de quem desenvolve ou publica abaixo de **US$ 1.000.000** no último ano fiscal (líquidas de taxas da loja e reembolsos).
- Se o jogo deixar de ser Indie: **60 dias** para ter um plano que permita Studio Games ou parar de usar a música nele (cópias já distribuídas podem continuar). Quem decide se é Indie é o desenvolvedor.
- Uma busca achou um espelho antigo (ago/2025, v1) dizendo que "videogames comerciais" eram proibidos nos planos pagos sem aprovação escrita; **a versão atual não tem isso**. Mesmo assim, guarde uma cópia do termo vigente na data em que a música foi gerada.
- **Os termos dos efeitos sonoros (`sound-generation`) são outros e não foram lidos.** Vale conferir também.

## 7) O que NÃO foi verificado

- Nada foi ouvido (só números). O gosto, o alinhamento de compasso e se a melodia combina com o pad só se sabe ouvindo.
- Não testei `music_v2` / `music_v2_5` (só `music_v1`, o padrão): podem soar melhor ou piorar o travamento de tempo.
- A ferramenta só roda com o `numpy` instalado para gerar e medir (`--lista`, `--confere` e `--dry-run` funcionam sem).
