# Bloco 79 — a ferrovia de carga (maquete v4 aprovada)

O Marco pediu primeiro os marcos visuais (Bloco 78) e depois a ferrovia de carga. A ideia é que o minério do
fundo não precise subir nas costas do mineiro.

## Como joga

- No menu de construção (Coleta automática), o cartão **"Ferrovia de carga (S2)"** encomenda a estação do
  andar.
  - É um andar de cada vez, de cima pra baixo: S2, S3, S4, S5.
  - O andar precisa estar aberto. Com ele fechado, o cartão mostra o motivo ("S3 fechado: ...").
  - O custo cresce com a profundidade: base de 300 cr + 60 ferro + 100 madeira + 60 s de obra, e mais
    150 cr + 30 ferro + 20 madeira + 15 s por andar. O S2 sai por 600 cr.
  - Quem constrói é o engenheiro (tecla 4), que desce até o andar.
- A **estação** fica num lugar fixo: a ponta leste da faixa, perto do poço, no chão da caverna, longe da
  gaiola, das jazidas, das poças e dos marcos.
- **Os mineiros do andar entregam nela.** Eles já escolhem o ponto de carga mais perto que o armazém, então
  não sobem mais com o minério.
- **O carrinho:**
  - leva até 30 por viagem, e a estação guarda até 80;
  - sai pelo trilho curto no chão até a doca;
  - **sobe pelo cavalete** de madeira, em zigue-zague à direita da espiral, até a plataforma na superfície;
  - descarrega no armazém e volta.
  - A subida demora mais quanto mais fundo o andar.
- O trilho gasta: quebrado, vira obra do engenheiro, igual ao vagonete do Bloco 64.
- Uma **área de mina** (Bloco 77) em volta da estação liga e desliga ela junto com a mina.

## No visual

O cavalete é o da maquete v4: dois postes, travessas em X e as rampas em zigue-zague da doca mais funda até a
superfície. Ele só aparece com alguma estação construída. Cada estação tem a sua doca, do fim do trilho no chão
até o cavalete. Na superfície fica a plataforma de chegada e um trilho até a porta do armazém. O carrinho cheio
ou vazio anda pelo caminho de tela da estação dele. Fotos em `docs/arte/bloco79/`.

## Como foi feito (reaproveitando o Bloco 64)

- `estacao_vagonete.gd` ganhou o modo **`ferrovia`** (o id do andar).
  - O trilho de verdade é só o pedaço no chão até a doca. O comprimento da viagem soma a **subida**, que vale
    260 + 150 por andar de profundidade.
  - Enquanto o carrinho está na subida, ele some do chão (`progresso_subida()`) e a vista iso desenha ele no
    cavalete.
- `centro_vila.gd`:
  - `ferrovias()`, `ferrovia_proximo()`, `ferrovia_block_reason()`, `build_ferrovia()` e
    `spawn_ferrovia(id, pos)`;
  - o canteiro `"ferrovia"`;
  - o save, na chave `ferrovias`;
  - as estações não contam como "Trilho e vagonete" comum.
- `environment.ponto_ferrovia(n)`: o lugar da estação no andar.
- `iso_view.gd`, seção "ferrovia de carga":
  - `ferrovia_postes()`, `ferrovia_topo()`, `ferrovia_caminho(f)` e `ferrovia_carrinho(f)`;
  - o desenho fica atrás dos andares e por cima da espiral; a parte da superfície fica no chão, como os
    trilhos.
- `build_menu.gd`: o cartão.

## Testes

- `b79_ferrovia.gd` (novo): o lugar em cada andar, construir (fechado, pendente, pago), o canteiro virando a
  estação, o mineiro escolhendo ela, o carrinho subindo (na tela, entre os postes) e a carga chegando no
  armazém, o trilho gastando, a área de mina e o save/load.
- Passaram: b64, b74, b77, p28_iso, p28_save, b46, b57 e b78. A bateria inteira (62 testes) passou.
