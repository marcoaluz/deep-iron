# Bloco 102 — Catálogo, minérios e animais (plano)

Data: 2026-10-08. Branch `isometrico`. Pedido: "Prompt S1" (o pesquisador como naturalista; sistema de DESCOBERTAS).
Teste: `b102_catalogo`. **Esperando a aprovação do Marco.**

## O que existe hoje (auditoria)

- **Pesquisa** (`research.gd`): uma pesquisa por vez, com pontos que só o pesquisador gera no laboratório (1 ponto/s cada).
  Sem pesquisa ativa, o pesquisador **volta a minerar** ("como antes").
- **Pesquisador** (`ipezinho.gd`): estado `research` no laboratório; a animação `pesquisar` já existe no elenco
  (pesquisador e pesquisadora, 4 direções, 3 peles). **Dá pra usar ela como o "anotar"; não precisa de arte nova pro boneco.**
- **Minérios** (`ores.gd` e `mineral_node.gd`): 8 tipos, todos com nome desde o começo.
  - Ferramenta da Oficina: cobre (picareta temperada), carvão (lampião), prata e cristal verde (broca), solarita e
    cristal rubro (traje de chumbo).
  - A jazida também trava pela descida e pela galeria lacrada.
  - O minério sai de três lugares: a picareta (`mine`), o coletor (`extract`) e a galeria de dentro do vagonete
    (`extract`, Bloco 99).
- **Tocas** (`hunt_spot.gd`): coelho (clareira, perto da horta) e javali (no norte, longe). Só caça quem tem arco.
- **Diário** (`diary.gd`): já tem páginas de criaturas, cristais, solarita, S4 e S5, abertas por eventos soltos.
- **Fornalha** (Bloco 86): as receitas usam os ids reais (ferro, cobre, prata, solarita).
- **Achados** (`finds.gd`): peças e itens de reator. Não entram no catálogo (já têm a janela da Escavadeira).
- **Teclas:** o **R** ficou livre no Bloco 101 (era recrutar). Proposta: **R = Catálogo**.

## O plano

### 1) O catálogo (`catalogo.gd`, nó "Catalogo" na main.tscn, grupo "catalogo")
- **Entradas por dados:** um `.tres` por entrada em `data/catalogo/` (recurso `entrada_catalogo.gd`). Cada uma tem:
  - id, categoria (`minerio`/`animal`/`criatura`/`local`), ícone e o **alvo** (o tipo de minério, o bicho, a criatura
    ou o andar);
  - os pontos do estudo no laboratório (plano B);
  - **o que libera** (`libera`: pesquisas e a página do diário).
- **Os textos** ficam num arquivo só, `data/catalogo/textos.txt`, no formato do capítulo das missões (`chave = valor`):
  nome, texto, "para que serve" e a ficha.
- **Os estados:** Desconhecido → Avistado → Estudado. Nunca volta atrás.
- **O avistar:**
  - a cada 1 s, uma entrada desconhecida vira Avistada quando algum morador chega a até `alcance_avistar` px dela
    (`@export`, 160);
  - um andar fica Avistado quando abre;
  - uma criatura fica Avistada quando aparece pela primeira vez.
- **Os sinais:** `entrada_avistada(id)` e `entrada_estudada(id, categoria)`. As missões ganham o tipo de objetivo
  `estudar` (um `match` em `valor_do_objetivo`).

### 2) O pesquisador naturalista (a tarefa de campo)
- **Com pesquisa ativa no laboratório:** fica lá, como hoje.
- **Sem pesquisa (ou sem laboratório):** sai pra **CATALOGAR**, no estado novo `catalogando`.
  - **A escolha do alvo:** entre os Avistados que dá pra alcançar, pela prioridade da categoria (minério > local >
    animal) e depois pela distância.
  - **A reserva:** o alvo fica reservado, então duas pesquisadoras nunca estudam o mesmo.
  - **O que ele pula:**
    - zona de gás sem a máscara;
    - poço de lava sem o traje;
    - andar trancado;
    - galeria lacrada.
  - **O estudo:** ele anda até o alvo, estuda `segundos_estudo` (`@export`, 40 s de jogo, com a animação `pesquisar`)
    e **volta pro laboratório** (ou pro Centro, se não tem laboratório) pra entregar.
  - **A entrega:** o balão "Estudou: Cobre!", o aviso no canto, o som de achado e a página do diário.
- **Só de dia.** A agenda já manda pra casa e pras refeições. Na invasão e na onda solar, as regras de emergência que
  já existem tiram ele do campo (a reserva solta).
- **Sem nada pra catalogar:** volta a minerar, como hoje.
- **Criaturas:** não dá pra estudar uma criatura viva (de noite ele está em casa).
  - Cada **abate** deixa uma **amostra** guardada (um contador, sem desenho no mapa).
  - Com amostra e laboratório, o pesquisador estuda ela **no laboratório**, de dia, com o mesmo tempo.

### 3) Minérios
- **No mapa:** a jazida desconhecida aparece como **"pedra desconhecida"**, um desenho cinza novo (`jazida_desconhecida_
  cheia/meia/quase`), com a placa "Pedra desconhecida".
- **Dá pra minerar** (com a ferramenta, se ela pedir: ver a decisão 2). O que sai é **"Minério desconhecido"**:
  - um item novo, que vale **1 cr** (`@export`; o ferro vale 2) e não entra em receita nenhuma;
  - por trás, o catálogo anota quanto de cada tipo entrou;
  - quando o tipo é estudado, **esse tanto vira o minério de verdade** no armazém. O aviso diz, por exemplo:
    "Estudou: Cobre — 34 de minério desconhecido eram cobre".
  - Vale também pro coletor e pra galeria de dentro do vagonete.
- **Estudado,** a ficha mostra:
  - o nome e para que serve;
  - a **receita da fornalha** que ele libera (antes de estudar, a receita aparece "precisa estudar: ???");
  - a **ferramenta** pedida.
- **A Oficina:** antes do estudo, a ferramenta diz "libera um minério desconhecido".

### 4) Animais
- **A toca desconhecida** não aparece pro caçador: `is_usable` dá falso e ele não vai.
  - No mapa ela continua lá, com a placa "Toca ???". Os bichos andam do mesmo jeito.
  - Ela vira Avistada quando alguém passa perto, como os outros alvos.
- **A toca estudada** libera a caça e mostra a ficha:
  - o que rende (carne por bicho);
  - o risco (o javali fere o caçador novato);
  - a época (no inverno nascem menos e o limite cai pela metade).

### 5) A janela Catálogo (tecla R, no estilo do layout v2)
- **As abas:** Minerais, Animais, Criaturas e Locais, com um contador ("3/8 estudados").
- **As entradas:**
  - Desconhecida: em **silhueta** (o ícone em preto, feito por código) com "???";
  - Avistada: o ícone apagado, com "avistado: falta estudar" e o botão do **plano B**;
  - Estudada: o ícone, o texto, "para que serve" e o que liberou.
- **O diário:** a entrada estudada abre a página que ela já tem (lumívoros, cristais, solarita, S4, S5…). As outras
  ganham página nova, com o texto do arquivo.

### 6) A descoberta libera pesquisa
- **Nos dados da entrada** (`libera`), não no código: a pesquisa mostra "precisa estudar: Reconhecimento do S2".
- **A proposta:**

  | Pesquisa | Precisa estudar |
  |---|---|
  | Explosivos controlados | Carvão |
  | Trajes de proteção | Reconhecimento do S2 (o exemplo do pedido) |
  | Ventilação | Cristal verde |
  | Bombas d'água | Reconhecimento do S3 |
  | Projeto do escudo solar | Solarita |

### 7) O plano B (sem pesquisador) e os pontos do estudo
- **O plano B:** na janela, uma entrada Avistada pode ser estudada **pelo laboratório sozinho**.
  - Os instrumentos geram `lab_pontos_sozinho` (`@export`, 0,15 ponto/s; o pesquisador gera 1/s).
  - O estudo custa os pontos da entrada (por volta de 40: uns 4,5 min de jogo).
  - Precisa de laboratório e de laboratório livre (sem pesquisa ativa).
  - Um estudo por vez.
- **Os pontos do estudo:** cada estudo dá `pontos_por_estudo` (`@export`, 8) **pra próxima pesquisa**. Vai pra pesquisa
  ativa ou fica guardado; o guardado entra quando a próxima começar.

### 8) Save
- **A chave `"catalogo"`:** os estados (só os que não são Desconhecidos), o anotado do minério desconhecido, as
  amostras, os pontos guardados, o estudo do laboratório e as reservas soltas.
  - O pesquisador grava o alvo dele no save do ipezinho; se o alvo some, ele escolhe outro.
- **Save antigo (sem a chave):** entra como **Estudado** tudo que o jogo já liberou:
  - os minérios que estão no armazém, que já foram vendidos (`ore_sold`/estatística) ou que têm jazida destravada;
  - os andares abertos;
  - as tocas que já existem visíveis (o caçador continua caçando);
  - as criaturas com página no diário ou já vistas numa invasão;
  - o que as pesquisas já feitas pedem.
  - Ninguém perde nada; o resto começa Desconhecido.

### 9) Arte (PixelLab, regra 11)
- **Novo:**
  - a jazida "pedra desconhecida" em 3 estados (cheia/meia/quase), com uma piloto antes;
  - o ícone do "minério desconhecido" (item da interface e pedaço carregado na cabeça).
  - Custo estimado: **~40 a 60 gerações**.
- **Reaproveitado:**
  - os ícones dos minérios (`Icones`);
  - os bichos (`iso/animais`);
  - as criaturas (os sprites delas);
  - os locais (um recorte dos `iso/mapa/andar_*.png`);
  - a animação `pesquisar` como o "anotar".
  - As silhuetas são por código.

### 10) Teste `b102_catalogo`
Confere:
- a partida nova com o conhecimento inicial;
- o avistar;
- o pesquisador sai sem pesquisa e fica com pesquisa;
- duas pesquisadoras não repetem o alvo;
- a entrega com o aviso;
- o minério desconhecido virando cobre;
- a fornalha sem a receita;
- a toca escondida do caçador;
- a pesquisa travada pelo estudo;
- o plano B;
- os pontos;
- o sinal pras missões;
- a janela (as abas, a silhueta, o "???");
- o save e o save antigo (tudo liberado vira Estudado).

Os testes velhos que mineram cobre/carvão/prata ou caçam ganham `catalogo.estuda_tudo()` no começo, como o
`limite_desligado` do armazém.

## Conhecimento inicial (partida nova)

| Categoria | Entrada | Começa | Por quê |
|---|---|---|---|
| Minério | **Ferro** | **Estudado** | O começo não trava: casas, cozinha, Oficina, tudo é ferro. |
| Minério | Carvão | Avistado (pedreira do S1) | A primeira tarefa do pesquisador; as veias ficam à vista na pedreira. Precisa de lampião de qualquer jeito. |
| Minério | Cobre | Avistado (pedreira do S1) | Idem; precisa da picareta temperada. |
| Minério | Prata, cristal verde | Desconhecido | Ficam no S2 (e na galeria lacrada). |
| Minério | Solarita, cristal rubro | Desconhecido | S3 e S4. |
| Minério | Gema azul | Desconhecido | S5. |
| Animal | **Coelho** | **Avistado** | A toca é na clareira, do lado da horta (o caçador colhe fruta lá). |
| Animal | Javali | Desconhecido | A toca é longe, ao norte; alguém tem que passar perto. |
| Criatura | Lumívoro, Ferrugento, Gosma, Magmante, Matriarca | Desconhecido | Avistado na 1ª aparição; estudado com uma amostra. |
| Local | **Superfície e S1 (a vila)** | **Estudado** (não aparecem na lista) | É a casa da vila. |
| Local | S2, S3, S4, S5, o Leste | Desconhecido | Avistado quando abre ou desbrava; o pesquisador vai lá e faz o reconhecimento. |

**O que o jogador sente no começo:** só o ferro tem nome. Um pesquisador sem laboratório já sai pra estudar o carvão e
o cobre (uns 2 minutos pros dois). Sem pesquisador, o carvão e o cobre continuam mineráveis (com a ferramenta) e vão
pro armazém como minério desconhecido. Nada se perde: vira o minério certo quando for estudado.

## Decisões para o Marco

1. **O conhecimento inicial** da tabela: ferro estudado; carvão, cobre e coelho avistados; o resto desconhecido.
   Ok? (A opção mais segura é o carvão estudado também.)
2. **A pedra desconhecida que pede ferramenta** (cobre, carvão…), sem a ferramenta:
   - proposta: **não dá pra minerar**, com a placa "Pedra desconhecida: dura demais (estude)", como hoje;
   - com a ferramenta: minera como minério desconhecido.
3. **A tabela das pesquisas** que pedem estudo (explosivos/carvão, trajes/S2, ventilação/cristal verde, bombas/S3,
   escudo/solarita). Ok, ou só a dos Trajes?
4. **As criaturas** estudadas pela amostra do abate, no laboratório. Ok?
5. **Os locais:** S2 a S5 e o Leste. Ok?
6. **A tecla R** pro Catálogo. Ok?
