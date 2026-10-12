# Bloco 137 — O som da noite, a chegada do padre e as refeições do padre e dos guardas

Pedido do Marco: três partes, com teste, telemetria e capturas. Teste `tests/blocos/b137_noite_padre_refeicoes.gd`
(32 OK). As capturas ficam em `docs/arte/bloco137/` (`tests/capturas_bloco137.gd`) e a telemetria em
`docs/telemetria/bloco137/` (`tests/telemetria_bloco137.gd`).

## 1. O som da noite

O Marco confirmou pelo F3 que o som chato é o `ambiencia/floresta_noite`. Não repeti o prompt do Bloco 133; mudei a
abordagem.

**(a) O loop virou quase silêncio:**
- Um tom de ar muito baixo e grave, sem agudos.
- O slot desceu pra −14 dB. O prompt novo pede "almost complete silence… long pauses of near silence, no hiss, no static,
  no white noise, no continuous insects, no crickets, no high frequencies".
- A atmosfera vem dos SONS PONTUAIS espaçados. São 3 slots novos, com 2 variações cada:
  - `pontuais/vento_distante` (de 25 a 60 s);
  - `pontuais/galho_estala` (de 30 a 70 s);
  - `pontuais/grilo_isolado`: um grilo, três cricrís e silêncio, de 35 a 80 s, nunca contínuo.
- Eles se somam à coruja, ao sapo e ao lobo de antes e à tocha/fogueira perto da câmera (`predios/tocha`).

**(b) As candidatas:**
- Geradas com `gerar_sons.py --candidatos 3 --so ambiencia/floresta_noite`. O custo foi mostrado antes (`--dry-run`) e o
  Marco já tinha liberado ("pode gastar").
- Medi o espectro das 3:

  | Candidata | Abaixo de 200 Hz | Acima de 8 kHz (relativo) | Veredito |
  |---|---|---|---|
  | #0 | quase toda a energia | −39 dB | tom grave limpo |
  | #1 | quase toda a energia | −31 dB | grave, um pouco mais de ar |
  | #2 | −35 dB | quase toda a energia | **chiado**: descartada |

- **No jogo agora:** a #0 (`--aprovar`) mais um passa-baixa de 1,5 kHz (`passa_baixa.py`). No arquivo, os agudos acima de
  8 kHz ficaram em −70 dB; a emenda do loop não tem estalo (`estalos.py`).
- **O Marco escolhe no F3 > Som:** o painel "Som: o que está tocando agora" ganhou a seção CANDIDATAS.
  - "Ouvir" troca o loop da noite pela candidata (`Audio.prova_ambiencia`); "Voltar ao do jogo" desfaz.
  - O painel mostra o comando pra aprovar outra.

**(c) O som do amanhecer saiu:** `Audio.stinger_amanhecer = false` (novo `@export`; true volta). O aviso da troca de
estação ficou (o aviso "Começou o…" do `sun.gd`).

**Custo do ElevenLabs** (saldo antes: 89.254 restantes):

| Pedido | Créditos |
|---|---|
| 3 candidatas de 30 s | ~990 |
| 6 pontuais | ~189 |
| 2 ventos refeitos (a 1ª versão do `vento_distante_1` saiu baixa demais pro teste do Bloco 116: pico −22 dBFS) | ~105 |
| **Total** | **~1.280** |

O painel da conta mostrava 88.066 restantes depois da última geração.

**Ninguém ouviu ainda.** Só os números foram conferidos (espectro, nível, emenda).

## 2. A chegada do padre

`calendario.chega_padre()` virou uma pequena cena:

- **Onde aparece:** do lado de FORA do portão, a `padre_chegada_dist` (220 px). Ele entra cambaleando (anda mancando, com o
  curativo).
- **Ferido de leve:** `hurt("fuga", "leve")`. O balão diz "Uma criatura... na estrada... graças a Deus, um portão!". Ele
  não piora no caminho, mesmo se o portão estiver fechado.
- **A história:** o banner ("…entrou cambaleando pelo portão, a batina rasgada: fugiu de uma criatura na estrada da
  floresta. Vai direto pra enfermaria…") e a página do diário, reescrita com a fuga.
- **O tratamento:** ele vai direto pra enfermaria e fica pelo menos `padre_tratamento_s` (90 s) no leito antes de assumir
  a função. Sem enfermaria, descansa o mesmo tempo.
- **Um padre só:** se alguém já tem a função, ele chega sem função.
- **Save:** nada novo. O ferimento e o relógio já iam no save do ipezinho.

## 3. As refeições do padre e dos guardas

- **O padre:**
  - Com a igreja pronta, fica DENTRO dela (some do mapa, como o médico na enfermaria; criatura não pega quem está lá
    dentro).
  - Sai pra pregar (missa, funeral), buscar um corpo, comer nas refeições e ir pra hora social (`ipezinho._entra_igreja`
    / `_sai_igreja`).
  - Antes ele ficava na igreja até na hora social. Agora janta e vai pras rodas, menos com funeral pra rezar ou um corpo
    nas costas.
- **Os guardas de vigia** (`schedule._periodo_guarda_vigia`):
  - Metade janta e vai pras rodas na 1ª parte da hora social (`guarda_turno_fracao`, 0,5), a outra metade na 2ª, e eles
    trocam.
  - Com a invasão ativa ou avisada, ninguém sai do posto.
  - Um só de vigia janta rápido se tiver fome e volta, como antes.
  - Os de folga fazem a noite normal.

**Telemetria** (uma noite, 6 guardas, vigília de 50%, o padre com a igreja pronta; `noite_guardas.csv`, `resumo.txt`):

- Depois que a vigia assumiu, o posto nunca ficou vazio na hora social: o mínimo foi 1, e 2 na maior parte.
- Numa das rodadas, o primeiro instante da hora social (18:30) pegou os 3 de vigia ainda chegando do trabalho do dia.
  Isso já acontecia antes, no "voltar".
- O padre esteve na janta ou nas rodas em 33 de 33 amostras da hora social, e dentro da igreja no expediente.

## Testes

- **Do bloco:** `b137_noite_padre_refeicoes` (32 OK).
- **Ajustado:** b114. O amanhecer não toca; religado, toca.
- **Regressão, um por vez, verde:** b84, b85, b88, b93, b108, b114, b115, b116, b127 e b131.
  - O b84 falhou uma vez ("voltar: lenhador leva a madeira…") e passou nas 2 rodadas seguintes. Parece intermitente
    (corrida de tempo); não mexi nele.
- **Documentação do áudio** regerada (`docs_audio.py`: PEDIDO_DE_SONS, PROMPTS_ELEVENLABS, LISTA_DE_ESCUTA).
