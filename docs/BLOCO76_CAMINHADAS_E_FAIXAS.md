# Bloco 76 — todos andando de verdade + as faixas da maquete (rio de lava, cachoeira, tons)

Pedido do Marco: "verificar a movimentação dos personagens todos, se precisar usar o blender para
refazer as movimentações fique a vontade. e continua o desenvolvimento do layout do jogo com base a
maquete montada no blender".

## 1. Movimento de todos

O Bloco 73 já tinha posto o pé da gente no chão. Aqui o resto do elenco entrou na mesma regra: **a
perna segue a distância andada**, não um relógio.

| Quem | Antes | Agora |
|---|---|---|
| Gente (42 personagens: 18 base, 18 de casaco, 6 trajes) | Caminhada de **4 quadros**, dura | Caminhada de **8 quadros**. O quadro sai da distância dividida pela passada medida da própria tira (`ciclo` no `bonecos.json`). |
| Criaturas (lumívoro, ferrugento, magmante, gosma, matriarca…) | Relógio fixo: patinavam | Distância dividida pelo `ciclo` medido da tira (`integra.py pes`). |
| Robô | Relógio fixo | Idem, pela distância. |
| Coelho e javali (`animal.gd`) | Relógio | `_andado` pela distância, com a passada de cada bicho (`CICLO`). |

**A caminhada de 8 quadros é do PixelLab, modelo `walking-8-frames` no modo `skeleton-v3`.** O piloto no
minerador comparou os dois modos (`docs/arte/bloco76/piloto_modelo_x_esqueleto.png`):

- O modo comum (1 geração por direção) **redesenha cada quadro**, e o colete do mineiro trocava no meio
  do ciclo.
- O `skeleton-v3` (2–4 gerações por direção) **põe o esqueleto do modelo no desenho do personagem**:
  roupa e rosto ficam iguais nos 8 quadros.

O Blender não foi preciso. Ele seria o caminho (um esqueleto posado no Blender passado pro
`animate_with_skeleton_v3`) se o PixelLab não segurasse a identidade.

Ferramentas:

- `prototipos/camera/arte_iso/caminhadas8.py`:
  - `pede` gera em levas de 10 (o PixelLab roda 20 jobs juntos) e espera quando falta vaga;
  - `baixa` baixa SE e NE e espelha SO e NO;
  - `troca` guarda a de 4 quadros em `caminhada4/` como reserva, grava a âncora no `anim.json` e refaz
    a picareta nas costas do minerador quadro a quadro.
- `integra.py caminhadas <pastas>` refaz só essas tiras (com os tons de pele e o pé no chão).

Conferência: `docs/arte/bloco76/elenco_8quadros_*.png` mostra o elenco inteiro, SE e NE, os 8 quadros.
Os GIFs `andando_*.gif` mostram os bonecos no jogo.

## 2. As faixas da maquete (`coluna_v3.png`)

- **S3: rio de lava.** Ele corre a faixa inteira ao pé da parede de trás. As 2 fileiras de rocha logo
  atrás do chão viram lava, e ninguém anda nelas. Fios de lava serpenteiam a partir de fendas acesas na
  parede até o rio. A beira do chão é rocha rachada com brasa.
- **S4: cachoeira.** Uma cortina reta desce a parede atrás do `fx:cachoeira` até a poça. Ela é pintada
  pela coluna da tela, por isso passa reta por todos os degraus da parede.
- **Tom da rocha por andar**, como na maquete: S2 musgo, S3 barro queimado, S4 cinza molhado, S5 cinza
  azulado. A coluna se lê faixa por faixa de longe.
- `andares.py`:
  - a semente dos enfeites não usa mais `hash()` de string, que mudava a cada execução e regerava os PNGs
    sem motivo;
  - o gerador agora é determinístico.

Fotos: `docs/arte/bloco76/s3_rio_de_lava.jpg`, `s4_cachoeira.jpg` e `coluna_tons_por_andar.jpg`.

## 3. Melhorias depois da aprovação ("aprovado, pode aplicar as melhorias")

- **Lotes livres na vila** (a maquete: terrenos cercados de corda).
  - São 4 lotes perto do Centro, em lugar de casa válido, fora da praça e das ruas: (128,−406),
    (−48,−470), (304,42) e (−208,−470).
  - Cada um tem o chão limpo de enfeite, estacas nos cantos e no meio dos lados, e uma corda caída entre
    elas. Quando o jogador está escolhendo onde construir, o chão do lote fica verde de leve.
  - Ao construir, o prédio **encaixa no meio do lote** quando passa perto, se couber lá.
  - Com um prédio dentro, o lote some. Isso é calculado (`environment.lotes_livres`), sem nada novo no
    save.
- **Boca da escada em espiral:** a casinha de madeira da maquete, com degraus descendo, lampião e placa.
  - Fica em cima da espiral da coluna, ao lado da torre do elevador.
  - A arte é do PixelLab, `create_image_pro` com o estilo dos prédios. Foram 4 candidatas e a escolhida
    foi a c03 (`prototipos/camera/arte_iso/fundo76/espiral.py`).
  - Entrou nas peças fixas com `integra.py props boca_espiral`. O `props <nomes>` é novo e processa só
    essas peças, sem regravar as outras.
- **Raízes:** debaixo da floresta (galerias e S2, a oeste da paliçada), raízes escuras descem do teto
  pelo paredão, ondulando e afinando.
- **Traje de gás (masculino):** a caminhada saiu duas vezes, nas duas direções, com colete marrom e calça
  cinza por cima do traje amarelo. Gerar de novo não resolveu. A correção foi `fundo76/traje_gas_cor.py`,
  que troca os marrons do tronco e os cinzas das pernas pelos tons do amarelo da pose parada da mesma
  direção. Capacete, máscara, luvas e botas ficam.

## 4. Itens na mão e navegação (verificação depois da aprovação)

- **Cassetete do guarda e machado do lenhador sumindo em alguns quadros.** A geração desenhava o item numa
  passada da caminhada e não na outra. O jogo já desenha a ferramenta ou a arma **nas costas**
  (`iso_bonecos._item`), então o certo é a mão vazia em todos os quadros.
  - A ferramenta é `fundo76/itens_mao.py`.
  - Cada quadro passou pelo `edit_image_pixen` com a instrução "tira o item da mão", e só a região do item
    volta para o quadro, nas cores do próprio original. Os 8 personagens (guardas e lenhadores, com e sem
    casaco, SE e NE) somaram 128 edições de 1 geração cada.
  - A escolha foi conferida quadro a quadro (`ESCOLHA`): o original, a composição que pega só o que sai do
    contorno, ou a que pega também por dentro.
  - Os originais e as edições ficam em `fundo76/itens_mao/antes/`. O comando `recompoe` refaz tudo sem
    gerar de novo.
- **Navegação:** o jogo avisava "Navigation region synchronization had 8 edge error(s)" sempre que a malha era
  refeita, desde o Bloco 75. A causa eram 12 triângulos de **área zero** (dois vértices no mesmo ponto) que o
  bake do Godot solta na beira das faixas, e uma fita de meio pixel entre dois enfeites na floresta. O
  `environment._sem_degenerados` tira esses triângulos depois do bake; os vizinhos se ligam direto. O aviso
  sumiu.
- **Saves do Marco** (cópias, com o código novo; `tests/verifica_save_marco.gd`): o atual, o das 09:50 e o
  de 02/10 carregam sem erro, com os lotes, a boca da espiral e a vista iso, e a área de trabalho funciona.
  - O das 09:50 entra em greve em 60 s, mas é a regra do jogo: fome 0, sem cozinha e sem casa.
  - **Ponto de balanceamento pro Marco:** numa partida nova, sem cozinha nos primeiros ~2 minutos, todo
    mundo zera a fome e entra em greve.

## Testes

- `b73_andar.gd`: a checagem do quadro pela fase usa o número de quadros e a passada da tira.
- `b76_faixas_lotes.gd` (novo): os lotes, a boca da espiral, a arte das faixas (lava, cachoeira, raízes)
  e o andar de todos.
- Passaram: b73, p29_bonecos, p28_iso, b26, b28, b42, b44, p20, p17_criaturas, b61_fauna e p18.
- A bateria inteira de blocos passou com o Bloco 77.

## Pendências

- Os itens na mão foram resolvidos (seção 4).
- Os itens da maquete que faltavam (espiral, lotes, raízes) entraram na seção 3.
