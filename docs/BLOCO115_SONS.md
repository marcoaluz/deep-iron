# Bloco 115 — Todos os sons do jogo no catálogo + prompts do ElevenLabs (relatório)

Data: 2026-10-10. Branch `isometrico`. Continuação do Bloco 114. Pedido do Marco: escrever os **prompts do ElevenLabs**, com a observação de que
**todos os sons do jogo** serão criados lá, **só a música fica de fora** ("chuva, mineração, animais, pessoal falando, radiação, tudo").

Pra isso o catálogo do Bloco 114 (55 slots) não bastava: os sons antigos (picareta, forja, alarme...) tocavam direto de arquivos sintetizados e
vários eventos do jogo não tinham som nenhum (animais, radiação, poças, portão, conversa, nascimento...). Este bloco leva **tudo** pro catálogo.

- **128 slots, 193 arquivos** (126 slots / 191 arquivos pro ElevenLabs; os 2 de música ficam de fora).
- Teste: `tests/blocos/b115_sons_do_jogo.gd`, 39 verificações, **0 falhas** (e o GUT). O `b114` continua com 0 falhas.
- **Nenhum áudio foi criado nem ouvido** (os testes usam sons falsos na memória).

## 1) O que o Marco recebe

- **`docs/AUDIO_PROMPTS_ELEVENLABS.md`**: o prompt (em inglês), a duração, o nome do arquivo e onde toca, pra cada um dos 126 sons. Gerado do `slots.json`
  (`python tools/lista_audio.py`); pra mudar um prompt é só editar o campo `prompt` do slot.
- **`docs/AUDIO_ARQUIVOS.md`**: a lista de arquivos, com o que já existe.

## 2) O que entrou

| Grupo | Slots | Como |
|---|---|---|
| **Sons antigos → slots** | 32 (`sfx/…`: picareta, depósito, comer, ferido, curar, forja, machadada, elevador, galho, brinde, achado, robô, explosão, golpe, martelo, colher, equipar, broca, festa, vender, boas-vindas, fanfarra, sino fúnebre, alarme, solar, grito do Lumívoro, golpe do Ferrugento, portão quebrando, criatura caindo, migrantes, obra pronta, greve) | Cada função do `Audio` (`pick()`, `forge()`, `alarm()`...) passou a tocar pelo slot. **Sem arquivo vale o som sintetizado de antes** (a `reserva`): nada muda até o arquivo chegar. Com arquivo, o arquivo manda. O que nunca teve som (migrantes) fica mudo. |
| **Ambiência** | +1 (`onda_solar`) | Camada de calor, rugido e estática enquanto a onda solar passa, na superfície (nos andares fundos a rocha protege e ela não soa). |
| **Prédios e lugares (loops)** | +10 (poça de ácido/lava, ventilador, tocha, **conversa** nos pontos sociais, oficina, arsenal, laboratório, escavadeira, escola, cozinha) | Entram no `SonsPredios` do Bloco 114: só perto da câmera, só com o lugar em atividade (`som_ativo()`; a conversa precisa de 2 ou mais gente reunida). |
| **Sons soltos e aleatórios** | 12 (`pontuais/…`) | Novo tipo `pontual`: de vez em quando, num ponto aleatório perto da câmera, enquanto o contexto vale. Floresta de dia: pássaro e corvo. De noite: coruja, lobo, sapo. Chuva: trovão. Inverno: rajada de vento. Mina: pedra caindo e gota. S2: bolha de ácido. S3: estalo da lava. S5: gota no lago. Bus Ambience. |
| **Animais** | 4 | Coelho foge, javali grunhe, e cada um tem o som da morte. |
| **Radiação** | 1 (`perigo/geiger`, 4 variações) | O contador Geiger quando alguém é irradiado (no máximo uma rajada a cada 0,35 s na vila toda). |
| **Criaturas** | 3 | Gosma, Magmante e a Matriarca ganham o som de ataque deles (o Lumívoro e o Ferrugento já tinham). |
| **Máquinas** | 2 | Quebrou e foi consertada. |
| **Vida na vila** | 3 | O primeiro choro do bebê, o casamento e o enterro (a pá). |
| **Portão** | 2 | Abre e fecha (antes era o mesmo clangue). |
| **Outros** | 1 | Jazida esgotando (a veia desaba). |
| **Pessoal falando** | +2 (`voz/…_ola`) e a conversa | O "oi" ao selecionar um ipezinho (desligável com o resto da voz) e o murmúrio de conversa nos pontos sociais e na taverna. As vozes curtas do Bloco 114 (ordem, dor, alegria, cansaço) continuam, agora com sugestão de Text to Speech em português. |

## 3) Mudanças de comportamento que valem saber

- Sem arquivo novo, o jogo soa **igual** ao de antes. Única exceção: a barricada apanhando agora soa para qualquer espécie (antes só o Ferrugento fazia barulho; sem arquivo
  novo cada um usa o grito ou o clangue da espécie). Os sons que **nunca existiram** (Geiger, animais, máquinas, vida na vila, conversa, sons soltos) ficam mudos até os arquivos chegarem.
- O duck do alarme e do sino passou a vir do slot (`duck`), igual antes (−9 e −7 dB).
- O balanceamento de volume de cada som continua o mesmo: o `db` e a variação de tom (`pitch`) de cada slot foram copiados dos `@export` antigos.

## 4) Testes rodados (um por vez, em primeiro plano, APPDATA isolado; o save real conferido por md5)

| Teste | Resultado |
|---|---|
| `b115_sons_do_jogo` (e pelo GUT) | 0 falhas (39 OK) |
| `b114_audio_sistemas`, `b55_audio` | 0 falhas |
| `b61_fauna`, `b62_tiers_chefe`, `b98_portao_tochas`, `b105_carregador_mecanico`, `b110_relacoes`, `b111_familias`, `b93_cemiterio`, `b85_hora_social`, `b88_padre_igreja`, `b57_coletor_minerio` | 0 falhas |

`godot --import` rodou limpo. **Não conferidos:** o resto da bateria (seguindo a nota de memória, não rodei tudo).

## 5) O que NÃO foi verificado

- **Nada de ouvido** (não há arquivo novo). Volumes, equilíbrio entre loops e sons soltos e a frequência deles (intervalos no `slots.json`) só dá pra ajustar com os arquivos.
- Os prompts são sugestões escritas por mim, **não testadas no ElevenLabs**: o resultado pode pedir ajuste de palavras. O texto de cada um está no `slots.json`.
- Os ganchos de animais, criaturas, portão, máquinas, nascimento, casamento, enterro e jazida foram conferidos no código, não disparados um a um no jogo (a conversa dos loops, o Geiger, o "oi" e os sons soltos foram exercitados no teste).
- Não conferi o preço em créditos do ElevenLabs: são 193 arquivos, a maioria curta.

## 6) Pendências

- Gerar os 191 arquivos de som (e, à parte, a música da abertura e da introdução).
- Depois de ouvir: ajustar `db`, `intervalo` e `raio` no `data/audio/slots.json`.
