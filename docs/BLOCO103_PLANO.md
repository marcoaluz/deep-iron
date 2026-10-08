# Bloco 103 — Criaturas (corpos e bestiário) e reconhecimento dos andares (plano)

Data: 2026-10-08. Branch `isometrico`. Pedido: "Prompt S2" + o acréscimo ("por que veio", história, dica, o
pesquisador realizado). Teste: `b103_bestiario`. **Esperando a aprovação do Marco.**

## O que existe hoje (auditoria)

- **A morte** (`creature.die`):
  - toca a animação "morrer" (6 quadros, todas as criaturas e variantes já têm), fica 1,4 s no chão, some e é apagada
    (`queue_free`);
  - os drops caem direto no armazém: Ferrugento 35% de 1 peça rara; Gosma 35% de 2 cristais verdes; Magmante 50% de 3
    cristais rubros. A Matriarca dá 40 solarita + 2 peças + pontos de pesquisa (`defense._on_boss_died`);
  - Bloco 102: o abate guarda uma **amostra** pro catálogo.
- **As páginas do diário das criaturas** abrem quando a criatura **nasce** (`defense._spawn` e `_spawn_boss`). Com o
  bestiário elas passam a abrir no **estudo**.
- **A janela da Defesa** fala dos tipos pelo nome ("Ferrugentos também"). A composição da onda é calculada dentro do
  `start_invasion`: dá pra extrair numa função e prever a próxima sem mudar nada.
- **Os andares:** `nivel_mina.gd` tem perigo, traje, criaturas e minérios por andar. As regras duras são as zonas de
  perigo (`hazard_zone`: só entra com traje), as poças (ácido e lava queimam sem traje) e os ventiladores. O catálogo
  do Bloco 102 já tem os "locais" S2–S5, avistados quando o andar abre, e o reconhecimento do S2 já trava os Trajes.
- **O portão** (Bloco 98) fecha às 18:30 e abre às 05:00. Quem tem destino do outro lado espera encostado.
- **O "corpo" de gente** (`corpo.gd`) é outra coisa (a mortalha, o padre). Não é reaproveitado aqui.

### Regras que os textos citam e o código NÃO faz (o acréscimo pede para listar)

1. **"A Gosma corrói as armas dos guardas"** está no cabeçalho do `creature.gd`, no diário e no texto do catálogo do
   Bloco 102, mas não existe: só a Matriarca corrói (`weapon_corrode`).
   - **Proposta: implementar.** O golpe da Gosma num guarda armado gasta durabilidade a mais
     (`corrosao_gosma`, `@export`, 1 golpe a mais por golpe), com o mesmo código da Matriarca.
2. **"O Magmante/a Gosma derretem a barricada"**: o `barricade_mult` existe, mas os dois saem da boca do poço, que não
   tem barricada. Na prática nunca encostam nela.
   - **Proposta: corrigir os textos** (diário e catálogo) pra o que é verdade: "sai do poço, sem muro; no armazém come
     o carvão / dissolve o minério de ferro e cobre". Fazer eles chegarem no portão mudaria o equilíbrio das invasões.

## O plano

### 1) Corpos de criatura (`props/corpo_criatura.gd`, grupo "corpos_criatura")
- Quando a criatura morre (abatida, não a que foge), nasce um **corpo** no lugar, e a criatura em si some como hoje.
  Assim nada que procura criatura viva acha o corpo.
- **O desenho:** o **último quadro da animação "morrer"** da própria criatura (variante forte e Matriarca incluídas),
  pela mesma função da vista iso (`criatura_pose`). É arte que já existe; **0 gerações**.
- **O prazo:** o corpo fica até o **amanhecer seguinte + `horas_corpo` horas** (`@export`, 8 h: até umas 13:00) ou até
  ser estudado. Passou o prazo, ele some.
- **O desconforto:** corpo dentro da paliçada ou a até 120 px do portão tira **1,5 de ânimo da vila** por corpo, até
  4,5 (`desconforto_corpo` e `desconforto_max`, `@export`). Entra nos motivos do ânimo: "corpos de criatura na vila".
- **Não vai pro save** (o pedido permite). No save antigo e no carregado, nenhum corpo.

### 2) Estudar o corpo: o BESTIÁRIO
- **A pesquisadora no campo:** o corpo de uma espécie ainda não estudada vira alvo, no lugar da amostra no laboratório
  do Bloco 102.
  - Ela só vai de dia: a agenda já manda.
  - Corpo do lado de fora da paliçada só com o **portão aberto**; fechado, ela não escolhe.
  - Chegando, ela anota (os 40 s de sempre) e entrega no laboratório.
  - Cada espécie é estudada uma vez, e várias pesquisadoras pegam corpos de espécies diferentes.
- **O plano B continua:** o laboratório sozinho estuda uma espécie se tiver amostra do abate.
- **A ficha da espécie** (texto em `data/catalogo/textos.txt`, editável; os números lidos do jogo):
  - nome e descrição;
  - **comportamento**;
  - **fraqueza**;
  - **o que deixa**;
  - **nível de perigo** (1 a 5, calculado da vida e do dano da cena);
  - **POR QUE VEIO**, com a **dica acionável**;
  - uma **pequena história**.
- **Por que veio / dica**, só com as regras que o código faz:

  | Criatura | Por que veio (a regra real) | Dica |
  |---|---|---|
  | Lumívoro | Atraído pela LUZ: gente acordada lá fora (a lanterna do capacete), casas com gente dentro, enfermaria e taverna ocupadas; uma tocha/lampião da decoração atrai como uma casa duas vezes mais perto (`atracao_luz`). Vem da floresta, pelo portão. | "Tire as tochas da decoração do caminho entre o portão e as casas, ou ponha perto do posto dos guardas: elas puxam os Lumívoros." |
  | Ferrugento | Sai da boca do poço do elevador (desde que o S2 abriu); o poço não tem muro. Vai atrás de quem está perto ou do minério do armazém. | "Ponha um guarda no posto do poço; a lança de prata bate 60% mais forte neles." |
  | Gosma | Sobe do S2 pelo poço; no armazém dissolve o MINÉRIO de ferro e cobre. | "Funda o minério em barra antes da noite (a Fornalha): a Gosma não dissolve barras." |
  | Magmante | Sobe do S3 pelo poço (com o abismo aberto); no armazém come o carvão. Lento e duro. | "Gaste o carvão na Fornalha antes da invasão, e use os guardas mais fortes no poço." |
  | Matriarca | Vem uma vez por estação junto da invasão; só GRITA (chama mais Lumívoros) depois de entrar na vila. | "Derrube-a no portão, antes de entrar: lá fora ela não chama ninguém." |

- **A fraqueza** só onde existe:
  - **Lumívoro:** os Holofotes (−30% de velocidade, +30% no golpe dos guardas);
  - **Ferrugento:** a lança de prata;
  - **Gosma:** pouca vida, cai rápido;
  - **Magmante:** lento: os guardas alcançam;
  - **Matriarca:** os Holofotes.
- **A descoberta** aparece como um **cartão narrativo curto** (o banner da tela: "DESCOBERTA: O LUMÍVORO" + a história
  em duas linhas + a dica). A página vai pro diário com a história, o porquê e a dica.
- **A pesquisadora realizada:**
  - **ânimo** +`animo_descoberta` (`@export`, 12, que vai sumindo como a hora social);
  - **experiência:** `xp_pesquisa` +1 por descoberta (qualquer entrada do catálogo). Cada ponto deixa o estudo de campo
    10% mais rápido, até 50% (`@export`). Fica no save e aparece no cartão dela;
  - o **balão de comemoração**: o balão de sempre com o ícone do que ela descobriu e o "Descobri!".

### 3) Os drops colhidos no estudo (mostrando antes, como o pedido manda)
- **A proposta: o drop fica NO CORPO** (sorteado na morte com as mesmas chances e quantidades de hoje).
  - **Corpo estudado:** a pesquisadora colhe e leva pro armazém.
  - **Corpo que passou do prazo**, ou de espécie já estudada: o drop vai pro armazém do mesmo jeito.
  - **O total é igual ao de hoje** (mesmas chances, nada se perde); muda só o caminho e a hora.
- **A alternativa:** deixar como está (o drop cai na hora no armazém).
- A Matriarca continua dando o prêmio na hora (o banner dela).

### 4) A janela da Defesa
- **Seção nova "Criaturas":**
  - cada espécie que já apareceu: "???" + silhueta se não estudada; estudada mostra a ficha curta (perigo, fraqueza,
    o que deixa, a dica);
  - a **PREVISÃO DA PRÓXIMA INVASÃO**, com os tipos e as quantidades da onda que vem (a composição sai do
    `start_invasion` pra `composicao(onda)`, sem mudar a conta). Espécie não estudada aparece como "??? × N";
  - a Matriarca prevista: "a rainha deles vem nesta estação".
- **O banner da invasão** usa o nome só das espécies estudadas ("4 Lumívoros e 2 ???").

### 5) Reconhecimento dos andares (S2 a S5)
- **Quando o andar abre**, ele fica **"não reconhecido"** (Avistado no catálogo). A pesquisadora vai lá fazer o
  reconhecimento, no ponto seguro do andar (o do Bloco 102).
  - **Com risco real:** o caminho tem as poças e as zonas de sempre (sem o traje, ela não entra na zona e a poça
    queima), e no fim do reconhecimento há uma chance de ferimento (`risco_reconhecimento`, `@export`, 15%; um
    quarto disso com o traje do andar no vestiário).
- **O reconhecimento revela**, na ficha do local e no corte da mina (F2):
  - os perigos (gás, calor, radiação, ácido, lava, água: lidos das zonas e poças do andar);
  - as criaturas do andar;
  - o equipamento exigido (o traje do andar e as ferramentas dos minérios de lá).
- **Antes do reconhecimento** (a decisão 1 abaixo):
  - na interface, o andar aparece como **"não reconhecido"** (corte da mina, janela do elevador, catálogo);
  - a IA não manda ninguém trabalhar lá sozinha (as jazidas e as áreas de trabalho do andar não chamam ninguém); a
    pesquisadora é a exceção;
  - **descer mesmo assim:** a ordem à mão pra um ponto do andar, ou uma área de trabalho nele, **pede confirmação**
    ("Descer sem reconhecimento? Acidentes 2× mais comuns lá até o reconhecimento"). Confirmado, o andar fica liberado
    e o acidente na mina lá dentro é ×`acidente_sem_reconhecimento` (`@export`, 2,0) até ser reconhecido.
- **As regras duras continuam iguais** (traje de gás, de chumbo, ventilador). O reconhecimento só **mostra** elas.

### 6) Catálogo, pesquisas, diário e missões
- **Reaproveita o catálogo** (as entradas de criatura e de local ganham os campos novos da ficha), as pesquisas
  travadas pelo estudo (Trajes/S2 e Bombas/S3 continuam) e o diário.
- **Os sinais novos:** `criatura_estudada(id)` e `andar_reconhecido(id)` no catálogo, além do `entrada_estudada`.
  As missões ganham os objetivos `criatura` e `reconhecer`.

### 7) Save
- **O que entra:**
  - **ipezinho:** `xp_pesquisa` e `animo_descoberta`;
  - **catálogo:** `descida_liberada` (os andares que o jogador mandou descer sem reconhecimento).
- **Os corpos:** não entram.
- **Save antigo:**
  - andar que já estava aberto = reconhecido (é a migração do Bloco 102: local aberto = estudado);
  - criatura com página no diário = estudada (idem);
  - xp 0.

### 8) Teste `b103_bestiario`
Confere:
- o corpo (nasce com o drop, a pose de morte, o prazo, o desconforto);
- o estudo pelo corpo (a ficha, o cartão, o diário, a xp, o ânimo, o balão, o drop colhido);
- o portão fechado (não vai);
- a Defesa com "???" e a previsão;
- a Gosma corroendo a arma;
- o andar não reconhecido (a IA não desce, a confirmação, o acidente 2×, o reconhecimento com risco revelando);
- os sinais;
- o save e o save antigo.

## Decisões para o Marco

1. **Antes do reconhecimento:** proposta: a IA não desce sozinha, e a ordem à mão ou a área de trabalho pede
   confirmação (depois de confirmar, acidente 2× até o reconhecimento). A alternativa mais leve: todos descem como
   hoje, só com o acidente 2× e um aviso.
2. **Os drops:** no corpo, colhidos no estudo (o total igual ao de hoje), ou deixar como está?
3. **A Gosma corrói a arma:** implementar (proposta), ou tirar dos textos?
4. **O "derrete a barricada"** do Magmante e da Gosma: corrigir os textos (proposta), ou fazer eles subirem pelo
   portão?
5. **O desconforto dos corpos:** 1,5 por corpo, até 4,5, ok? (O pedido diz opcional.)

## As decisões do Marco (2026-10-08)

1. **Antes do reconhecimento:** "concordo". A IA não desce sozinha; a ordem à mão, a área de trabalho e a patrulha
   pedem confirmação; confirmado, o acidente fica 2× até o reconhecimento.
2. **Os drops:** "faça o que fizer mais sentido". Ficam **no corpo**, colhidos no estudo; o corpo não estudado (ou de
   espécie já conhecida) manda pro armazém. O total não muda.
3. **A Gosma corrói a arma:** "podemos implementar".
4. **A barricada:** "estas novas criaturas só ficam na sessão deles, não sobe". Ele escolheu: **o andar deles, de dia e
   de noite**.
   - **Moradores do fundo:** a Gosma mora no S2 e o Magmante no S3 (nos dados do andar: `moradores`).
     - Uns poucos vagam pelo andar o tempo todo, a partir de quando ele abre.
     - Atacam quem está no MESMO andar (o mineiro, a pesquisadora no reconhecimento, o guarda) e nunca saem dele.
     - Repõem devagar (um por dia, até o número do andar).
   - **Saem das invasões da superfície:** a onda passa a ser os Lumívoros, os Ferrugentos e a Matriarca.
   - **Os guardas descem pra caçar:** a ordem "caçar no S2" (quantos), na janela da Defesa. De dia, esses guardas vão
     pro andar e lutam com o combate de sempre; de noite voltam pros postos. O corpo fica no andar.
   - Os textos da barricada e do armazém saem; entram os de verdade.
5. **O desconforto:** "pode ser" (1,5 por corpo, até 4,5).
