# Bloco 102 — Catálogo, minérios e animais

Data: 2026-10-08. Branch `isometrico`. Teste: `b102_catalogo`. Plano: `docs/BLOCO102_PLANO.md`.

**O pedido:** o "Prompt S1", o pesquisador como naturalista: um sistema de DESCOBERTAS.

**As decisões do Marco:**
1. O conhecimento inicial do plano: "sim muito bom assim".
2. As pesquisas que pedem estudo: "fica assim".
3. As criaturas estudadas pela amostra do abate: "pode sim".
4. Os locais S2 a S5 e o Leste: "ok de momento".
5. A tecla R pro Catálogo: "sim".

A pergunta da pedra desconhecida que pede ferramenta ficou sem resposta. Valeu a proposta do plano: sem a ferramenta
não minera, como hoje.

**Skills usadas:**
- `godot-gdscript`;
- `godot-gdscript-headless-testing`;
- `ai-behavior-trees-utility-ai` (a tarefa de campo);
- `save-systems` (a chave nova e o save antigo);
- `godot-ui-control` (a janela);
- `survival-crafting` (a escada da descoberta: estudar → nome → receita → pesquisa).

## Como ficou

### 1) O catálogo (`catalogo.gd`, nó "Catalogo" na cena, grupo "catalogo")
- **As entradas:** 20, por dados.
  - `data/catalogo/entradas.json` tem id, categoria, alvo, estado inicial, pontos do plano B, o que libera, a página do
    diário, o ícone e o ponto/andar dos locais.
  - `data/catalogo/textos.txt` tem o nome, o texto, "para que serve" e a ficha dos bichos. É o formato dos capítulos das
    missões e pode ser editado à vontade.
  - **Mudança em relação ao plano:** um JSON só, em vez de um `.tres` por entrada. É mais fácil de editar à mão e o
    pedido aceitava ".tres/.json".
- **As categorias:**
  - Minerais: os 8 minérios;
  - Animais: coelho e javali;
  - Criaturas: lumívoro, ferrugento, gosma, magmante e matriarca;
  - Locais: S2, S3, S4, S5 e o Leste.
- **Os estados:** Desconhecido → Avistado → Estudado. Nunca volta atrás.
- **O avistar:**
  - um morador a até 160 px da jazida ou da toca (`alcance_avistar`);
  - o andar que abre (local);
  - a criatura que aparece.
  - O aviso: "Pedra desconhecida avistada: falta estudar (Catálogo, R)".
- **Os sinais:** `entrada_avistada(id)` e `entrada_estudada(id, categoria)`.
- **As missões:** o objetivo novo `estudar` aceita um id (estudada ou não), uma categoria ou "" (quantas no total).

### 2) A pesquisadora naturalista (`ipezinho.gd`, estado `catalogando`)
- **Com pesquisa ativa no laboratório:** fica lá, como antes.
- **Sem pesquisa (ou sem laboratório):** sai pra catalogar.
  - **A escolha:** o alvo avistado pela prioridade (minério > local > animal > criatura), depois pela distância.
  - **A reserva:** fica no catálogo, então duas pesquisadoras nunca pegam a mesma entrada (nem a que outra já anotou).
  - **O que ela pula:** zona de perigo e poça sem o traje, andar trancado, galeria lacrada e o leste fechado.
  - **O estudo:** ela anda até o alvo ("Hmm, o que é isso?") e anota por 40 s de jogo (`segundos_estudo`, no ritmo
    dela), com a animação `pesquisar` do elenco, que já existia.
  - **A entrega:** ela volta pro laboratório (ou pro Centro) e entrega. Vêm o balão "Estudou: Carvão!", o aviso no
    canto, o som de achado e a página no diário.
- **Só de dia:** a agenda manda pra casa. Na invasão e na onda solar, as regras de emergência tiram ela do campo. A
  anotação já feita fica com ela (vai no save) e ela entrega depois.
- **Sem nada pra catalogar:** minera, como antes.
- **Trocou de função com a anotação na mão:** entrega na hora.
- **Minério na mão:** guarda antes de sair.

### 3) Minérios
- **No mapa:**
  - a jazida de um tipo não estudado é **pedra desconhecida**: a placa diz "Pedra desconhecida N", e sem a ferramenta
    "Pedra desconhecida: dura demais (estude)";
  - a vista iso desenha a pedra cinza com brilho pálido.
- **O minério desconhecido** é um tipo novo no `ores.gd` e no `items.gd`.
  - O que sai da pedra (pela picareta, pelo coletor e pela galeria de dentro do vagonete) é **minério desconhecido**:
    vale **1 cr** (`Economy.desconhecido_price`; o ferro vale 2);
  - não paga custo de "minério qualquer" e não entra em receita;
  - os mineiros preferem as jazidas conhecidas (vale menos).
- **Estudado o tipo:** o catálogo tinha anotado de que tipo era cada pedaço e **troca no armazém** esse tanto pelo
  minério de verdade. Se parte foi vendida, entra a parte proporcional. O aviso diz, por exemplo: "Estudou: Cobre — 30
  de minério desconhecido no armazém eram cobre".
- **Fornalha:** a receita de minério não estudado mostra "???" e não aceita ordem ("precisa estudar o minério").
- **Oficina:** a ferramenta diz "libera um minério desconhecido".
- **Tooltip do HUD:** não mostra o nome do que ninguém estudou.
- **A ficha** (na janela): para que serve, a ferramenta, a receita da fornalha, o preço e o que libera.

### 4) Animais
- **A toca de bicho não estudado** não aparece pro caçador: `is_usable` e `accepts_worker` dão falso. A placa diz
  "Toca ???". Os bichos andam do mesmo jeito.
- **Estudada,** libera a caça. A ficha mostra o que rende, o risco (o javali fere o novato) e a época (o inverno).

### 5) A janela Catálogo (tecla **R**, também no menu "Janelas")
- **As abas:** Minerais, Animais, Criaturas e Locais, com o contador ("Minerais 3/8").
- **As entradas:**
  - desconhecida: **silhueta** (o ícone em preto, por código) com "???" e uma dica ("Talvez mais fundo na mina");
  - avistada: o ícone apagado, "falta estudar", quem está estudando no campo, as amostras e o botão do **plano B**;
  - estudada: o ícone, o texto e a ficha.
- **No rodapé:** o estudo do laboratório em andamento e quantos pesquisadores a vila tem.

### 6) A descoberta libera pesquisa (nos dados: `"libera": ["pesquisa:<id>"]`)

| Pesquisa | Precisa estudar |
|---|---|
| Explosivos controlados | Carvão |
| Trajes de proteção | Reconhecimento do S2 |
| Ventilação | Cristal verde |
| Bombas d'água | Reconhecimento do S3 |
| Projeto do escudo solar | Solarita |

A janela do Laboratório mostra "precisa estudar: S2 — Galerias de ácido".

### 7) O plano B e os pontos
- **O plano B:** uma entrada avistada pode ser estudada **pelo laboratório sozinho**, a 0,15 ponto/s
  (`lab_pontos_sozinho`). Os pontos de cada entrada estão nos dados (30 a 120): uns 3 a 13 minutos de jogo.
  - Precisa de laboratório livre (sem pesquisa em andamento; com pesquisa, o estudo espera).
  - Um estudo por vez.
  - A criatura precisa de amostra.
- **As amostras:** cada criatura abatida guarda uma amostra (a matriarca, a dela). O primeiro abate avisa. O estudo
  gasta uma amostra.
- **Os pontos:** cada estudo de campo dá **8 pontos de pesquisa** (`pontos_por_estudo`). Vão pra pesquisa em andamento,
  ou ficam guardados (`research.pontos_guardados`) e entram na próxima que começar.

## Conhecimento inicial (partida nova)

| Entrada | Começa |
|---|---|
| Ferro | Estudado |
| Carvão, Cobre | Avistado (as veias da pedreira) |
| Coelho | Avistado (a toca da clareira) |
| Prata, Cristal verde, Solarita, Cristal rubro, Gema azul | Desconhecido |
| Javali | Desconhecido |
| Lumívoro, Ferrugento, Gosma, Magmante, Matriarca | Desconhecido |
| S2, S3, S4, S5, Leste | Desconhecido |

**O efeito no começo:**
- o coelho só é caçado depois do estudo, mas o caçador já precisava do arco da Oficina;
- o cobre e o carvão precisam da picareta e do lampião de qualquer jeito;
- o **lampião custa cobre**: sem estudar o cobre, o cobre sai como desconhecido e não paga o lampião. É a primeira
  escada da descoberta, e uma pesquisadora resolve em ~1 minuto.

## Save
- **A chave `"catalogo"`:**
  - `estados` (só os não desconhecidos);
  - `bruto` (o minério desconhecido por tipo);
  - `amostras`;
  - `estudo_lab` (o plano B).
- **Também mudou:** `research` ganhou `guardados`; o ipezinho ganhou `nota_campo`; o armazém pode guardar `desconhecido`
  no `stock`. Tudo documentado no cabeçalho do `save_manager.gd`.
- **Save antigo (sem a chave):** o estado inicial, mais **Estudado** pra:
  - o minério que está no armazém ou tem jazida destravada;
  - as tocas visíveis (o caçador continua caçando);
  - os andares abertos e o leste desbravado;
  - as criaturas com página no diário (e o lumívoro, se já houve invasão);
  - o que as pesquisas já feitas pediam.
  - O resto começa como na partida nova. Ninguém perde nada.

## Arte
- **A pedra desconhecida** (cheia/meia/quase) e o **ícone do minério desconhecido** (interface, 32 e 24 px, e o pedaço
  carregado) foram **reaproveitados**, sem geração nova (regra 12: primeiro reaproveitar).
  - As jazidas do jogo saíram de um lote só do PixelLab, recolorido por minério (`jazidas/jazidas.py`). A de ferro
    guarda a rampa exata, e aqui ela vira a rampa da pedra desconhecida.
  - O script é `prototipos/camera/arte_iso/catalogo102/catalogo102.py`; a prancha está em
    `docs/arte/bloco102/pedra_desconhecida.png`.
- **O "anotar":** a animação `pesquisar` do elenco (pesquisador e pesquisadora, 3 peles).
- **Os ícones da janela:** os do jogo (minérios, a primeira pose dos bichos e das criaturas, as faixas do corte da mina
  pros andares, a igreja do leste).
- **Custo no PixelLab:** 0 gerações.
- **As fotos:** `docs/arte/bloco102/` (a pesquisadora na pedra desconhecida e a janela).

## Exportação
- O `export_presets.cfg` passou a incluir `data/catalogo/*.json`, `data/catalogo/*.txt` e `data/missoes/*.txt`.
- **O texto das missões do Bloco 100 não estava no filtro:** o jogo exportado ficaria sem os textos dos capítulos.
  Corrigido junto.

## Testes
- **`b102_catalogo`** (novo, **0 falhas**). Confere:
  - o conhecimento inicial;
  - a pedra desconhecida (placa e vista iso) e a toca escondida;
  - a Oficina sem o nome do minério;
  - o avistar e o sinal;
  - o minério desconhecido anotado e trocado no estudo;
  - a fornalha travada e liberada;
  - o diário;
  - duas pesquisadoras sem repetir o alvo, o minério primeiro;
  - a entrega com os pontos;
  - a pesquisadora no laboratório com pesquisa ativa;
  - Trajes/S2 e Explosivos/carvão;
  - o plano B;
  - a amostra do lumívoro;
  - o objetivo "estudar";
  - a janela (tecla R, abas, silhueta, "???", ficha, plano B);
  - o save e o save antigo.
- **A bateria completa:** os 85 testes de bloco, um por vez, com o APPDATA isolado.
  - **Falharam 7 na primeira volta:**
    - 4 de caça (b27, b28, b34, b61): o coelho começa avistado e o caçador não caça;
    - a Fornalha (b86): as receitas pedem carvão, que começa avistado;
    - p29_natureza: confere o desenho do minério de cada jazida, e as não estudadas agora são pedra desconhecida;
    - b85_hora_social: um intermitente conhecido.
  - **O ajuste:** os 6 primeiros são testes de antes do catálogo e ganharam `catalogo.gd tudo_estudado = true` no
    `_initialize` (como o `limite_desligado` do armazém). Rodados de novo, **os 7 passaram**.
  - **Um conserto no catálogo:** ele carregava a Fornalha com `preload`, e ela usa o autoload `Audio`. Isso quebrava os
    testes que carregam o script; agora usa `load` na hora.
  - **Os outros 78 passaram.** O b51_engenheiro_estresse passou de primeira desta vez.
- **GUT da vista iso** (`test_iso`, `test_iso_arte`, `test_iso_pele`): 12 testes, 439 asserts, todos passaram.
