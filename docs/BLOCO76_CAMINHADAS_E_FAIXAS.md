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

## Testes

- `b73_andar.gd`: a checagem do quadro pela fase usa o número de quadros e a passada da tira.
- Passaram: b73, p29_bonecos, p28_iso, b26, b28, b42, b44, p20, p17_criaturas, b61_fauna e p18.
- A bateria inteira de blocos passou com o Bloco 77.

## Pendências

- **traje_gas_m, direção NE:** do 2º quadro em diante aparece um colete marrom por cima do traje amarelo.
  A caminhada de 4 quadros já tinha o mesmo defeito, então nada piorou. Refazer exige apagar a animação
  no PixelLab, que não gera de novo o mesmo modelo, e pedir outra vez.
- **Itens na mão que somem em alguns quadros:** o cassetete de guarda e casaco_guarda NE, e o machado
  do lenhador. É pequeno.
- **Ainda falta da maquete:** a entrada da espiral na superfície, os lotes livres marcados e as raízes
  nas paredes.
