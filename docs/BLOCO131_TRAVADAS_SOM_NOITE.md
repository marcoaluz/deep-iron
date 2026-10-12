# Bloco 131 — TRAVADAS e o SOM CHATO À NOITE

Pedido do Marco (a numeração dele dizia "Teste b130"; o 130 já existia, então virou o **131**, com o teste
`b131_travadas_som`).

## 1. Travadas

O tranco forte era o **bake síncrono da malha de navegação**: ~1,27 s dentro do quadro a cada obra pronta (na vila cheia,
i3-8100). A subida de estágio em si custava pouco; o pico dela (~140 ms) vinha do **Padre** chegando no mesmo quadro.

| Cenário | ANTES (maior quadro) | DEPOIS (maior quadro) |
|---|---|---|
| Obra pronta | **1306 ms** na chamada + 143–149 ms no quadro seguinte | chamada 3 ms; 32–51 ms |
| Subida de estágio | 130–140 ms | 38–56 ms |
| O padre chega | (somado à subida) | 27–52 ms |
| Vila cheia à noite (méd / p99) | 22,4 / 26,0 | 22,1 / 24,1 – 22,7 / 26,5 |
| Hora social (méd / p99) | 21,1 / 24,4 – 21,2 / 29,3 | 20,9 / 22,5 – 20,7 / 22,3 |

**Meta:** p99 ≤ 33 ms na vila cheia e nenhum quadro acima de 100 ms num evento (alvo ≤ 60 ms): cumprida nas rodadas medidas.
Tabela completa, método e o que mudou em `docs/DESEMPENHO.md` (seção Bloco 131). Ferramenta nova: `tools/bench_picos.ps1`.

O que mudou:
- `environment.gd`: bake **assíncrono** (`bake_from_source_geometry_data_async`) com os pedidos agrupados (vários no mesmo
  quadro ou durante um bake = um bake só), a malha antiga valendo até a nova (`navigation_rebuilt`). Carregar save e fundar a
  vila continuam síncronos (`rebuild_navigation(true)`). Geometria dos obstáculos em cache. `clear_decor_under_extras`
  agrupada e sem varrer de novo área já limpa.
- `iso_core.gd`: `topo_order` acha os pares por uma grade da tela (137 → 27,5 ms, ordem idêntica à de antes).
- `calendario.gd`: `@export padre_atraso` (3 s) — o padre chega depois do tranco da subida, com as animações já carregando.
- `iso_art.gd`: `aquece(kind)` carrega em segundo plano o desenho do prédio pronto enquanto ele é obra.

Achado durante o teste: na primeira versão da grade do `topo_order` o `PackedInt32Array` guardado no dicionário voltava como
CÓPIA e o `append` se perdia — a ordem de desenho saía só pela chave (errada). O teste (que compara com o algoritmo antigo)
pegou; agora é `Array`. Os números acima são da versão corrigida.

Efeito colateral conhecido: por ~2,5 s depois de uma obra pronta a malha ainda é a de antes; alguém pode cruzar o terreno do
prédio novo nesse tempo.

## 2. O som chato à noite

### Ferramenta: F3 > Som: "o que está tocando agora"

Janela ao vivo (`scripts/ui/sons_ativos_panel.gd`, atualiza 4 vezes por segundo): uma linha por slot tocando, com o **id do
slot**, o **bus**, o **volume em dB** (o do player + o do bus), a **distância** até o centro da câmera (ou "sem posição") e se é
**LOOP**, e o botão **Silenciar / Voltar**. Silenciar pausa o que já toca e impede o slot de tocar de novo (efeito, som solto,
loop de prédio, ambiência). Não vai pro save nem pras configurações. No `Audio`: `sons_ativos()`, `silenciar(id, mudo)`,
`silenciado(id)`, `silenciados`.

Como usar: à noite na floresta, abrir F3 > Som, e silenciar de cima pra baixo até o incômodo sumir.

### Configurações: controles separados

- **Ambiência (floresta, mina, chuva)** — o bus Ambience (o antigo "Ambiente da caverna").
- **Sons soltos (coruja, sapo, trovão...)** — bus novo **Soltos** (`Audio.soltos_volume`, 0,8; salvo em `audio/soltos_volume`).
  Antes os sons soltos saíam no bus da ambiência e não dava pra baixar um sem o outro.
- **Música** — como antes (e os 3 volumes das camadas do Bloco 121).

### Medição dos slots da noite

`python tools/elevenlabs/analisa_noite.py` → `docs/audio/DIAGNOSTICO_NOITE.md`: todos os slots que podem tocar à noite
(ambiências, camadas, sons soltos sem "dia", loops de prédio, radiação, música da noite e de perigo), com duração, LUFS
(BS.1770), pico, fração da energia acima de 4 kHz e de 8 kHz, se é contínua, se é tonal (planura 3–9 kHz), o estalo da emenda
dos loops e quantas vezes por minuto cada som solto toca.

**O principal suspeito: `ambiencia/floresta_noite`** — a ambiência da superfície à noite.
- quase toda a energia acima de 4 kHz, concentrada em **7,0–7,8 kHz**, **constante** (o envelope não tem ritmo nenhum) e
  **tonal** (planura 0,05): um chiado/grilo afinado que não para;
- **-11,8 LUFS** com o slot em -5 dB: ~10 LU mais alta que a ambiência da mina (-22,2) e da chuva (-26,4);
- o prompt dela pede "many crickets chirping steadily".

Outros sinalizados (menos prováveis à noite na vila):
- `ambiencia/s2_acido`: o mesmo padrão (97% acima de 4 kHz, contínuo) — só no S2;
- loops de prédio agudos e contínuos: `coletor_madeira`, `coletor_minerio`, `arsenal`, `poca_perigo`, `oficina` (só perto da
  câmera e com o prédio ativo);
- sons soltos que repetem muito: `vento_rajada` (3,4/min, só com vento), `gotejar`, `gota_eco`, `acido_borbulha`,
  `lava_estalo` (4–6/min, nos andares).
- Nenhuma emenda de loop passou do limite de estalo; coruja (2,4/min), sapo (2,9/min) e lobo (0,9/min) ficaram abaixo dos
  limiares.

### Proposta (NÃO aplicada: precisa do OK do Marco)

1. Confirmar ouvindo com o F3 > Som (silenciar `ambiencia/floresta_noite`).
2. Regerar a `floresta_noite` com um prompt sem grilo contínuo, por exemplo:
   *"Seamless loop, quiet forest clearing at night, soft low wind through leaves, distant sparse insects far away and quiet,
   occasional leaf rustle, calm and dark, no high-pitched constant tones, no music, no voices."*
   - 3 candidatas: `python tools/elevenlabs/gerar_sons.py --so ambiencia/floresta_noite --candidatos 3` —
     **~945 créditos** (dry-run: 3 chamadas de 30 s); com o S2 junto, `--so ambiencia/floresta_noite ambiencia/s2_acido`
     = 6 chamadas, **~1890 créditos**.
   - Depois de ouvir: `--aprovar ambiencia/floresta_noite <n>` e o `--import`.
3. Enquanto isso (sem regerar): baixar o `db` do slot `ambiencia/floresta_noite` de -5 para ~-12 dB (iguala a sonoridade às
   outras ambiências). Também é mudança de valor existente: fica pra ele decidir.

## Teste

`tests/blocos/b131_travadas_som.gd` (35 OK): malha em segundo plano (3 pedidos = 1 bake, a chamada não espera, malha antiga
até `navigation_rebuilt`, pedido durante o bake = mais um bake, imediato síncrono), decoração agrupada, padre com atraso,
`topo_order` igual ao antigo em 6 conjuntos sorteados (até 190 caixas), desenho aquecido = load direto, bus Soltos e o slider,
lista ao vivo (slot, bus, dB, distância, loop), silenciar/voltar e a janela do F3.

Regressão rodada (um por vez, pasta isolada, save real intocado): b47, b48, b54, b55, b88 (ajustado: `padre_atraso = 0`),
b89, b114, b115 (ajustado: os sons soltos agora no bus **Soltos**), b118, b121, b129, b130 e os GUT `test_iso`,
`test_iso_arte`, `test_iso_pele` — todos verdes. O b121 caiu uma vez com segfault na SAÍDA da Godot depois de `FALHAS: 0`;
não se repetiu em 2 rodadas seguidas (anotado, não investigado). A bateria completa não foi rodada neste bloco.

## Não verificado

- Nada jogado na tela: a janela do F3 e o slider foram conferidos pelo teste headless; o som não foi ouvido (headless não
  toca áudio). Achar o culpado de ouvido é com o Marco.
- O profiler do editor do Godot não foi usado (o tempo de cada parte foi cronometrado no benchmark).
