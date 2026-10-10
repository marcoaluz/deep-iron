# DEEP IRON — Inventário de arte (isométrico)

Varredura de 2026-09-29 em `scripts/`, `scenes/`, `assets/game/`, nos dados de
pesquisa/itens/eventos (`research.gd`, `equipment.gd`, `finds.gd`, `build_menu.gd`) e nos
estados visuais de cada prédio (`hframes` e `.frame`). **Todo prompt de arte atualiza este
arquivo.**

**Status:** falta · piloto · gerado · aprovado · integrado.

**Gerações:** estimativa a partir dos custos reais já medidos (ver CONTRATO §2.7). Nos itens
prontos, é o gasto de fato.

**Prompt:** a numeração do pacote do Marco (`docs/Prompt/deep_iron_prompts_arte_completa.md`,
prompts 0–31).

**Arte em:** `project.godot/prototipos/camera/arte_iso/<categoria>/`.

---

## 1. Personagens (elenco humano)

| Item | Prompt | Status | Variações | Direções | Animações | Gerações |
|---|---|---|---|---|---|---|
| Minerador (homem) + picareta nas costas | 1 | **integrado** (Prompt 29 parte 3) | 3 tons por paleta | 8 paradas, 4 andando | caminhada, minerar | 27 + 6 (feito) |
| Elenco: mineradora, guarda (h/m), médico (h/m), engenheiro (h/m), caçador (h/m), pesquisador (h/m), lenhador (h/m), sem função (h/m), cozinheiro (h/m) = 17 | 1 | **integrado** (Prompt 29 parte 3) | 3 tons por paleta; corpo forte/magro/gordinho/cheinho; mulheres 3–4 px mais baixas (corte de linhas) | 8 paradas, 4 andando | caminhada + 1 de trabalho por função (sem função: nenhuma) | 515 + 91 (feito) |
| Caçadora "com arco" (referência pro visual com arco) | 1 | gerado (guardada em `cacadora/com_arco_ref/`) | — | 8 | caminhada | incluído |
| Animações de trabalho (1 por função, h/m): minerar, construir/martelar, atacar com porrete, atender ajoelhado, cozinhar (tigela no braço), caçar com arco (só com a Oficina), cortar lenha, pesquisar na bancada | 1 | **integrado** | 16 | SE+NE +espelho (4) | 8 quadros cada | ~97 (feito) |
| Colher fruta (caçador sem arco), treinar no campo | 2 | **integrado** (pendência feita junto do Prompt 26) | h/m | SE+NE +espelho | colher, treinar | ~20 (feito) |
| Animações comuns (18): comer, ferido (tala), deitar (morte sóbria / dormir na rua), mancar (sad-walk) | 2 | **integrado** | 18 | SE+NE +espelho | 4 × 18 | ~345 (feito) |
| Carregar (caminhada + saco em sobreposição, `itens/saco_costas.png`) | 2 | **integrado** | 18 + 6 trajes | 4 | caminhada | 0 |
| Festa (pulinho), respiração, curativo | 2 | código | — | — | — | 0 |
| Dormindo / na taverna / na enfermaria (dentro do prédio) | 2 | não precisa | — | — | some dentro | 0 |
| Greve: placa na mão | 2 | **integrado** (Prompt 18: a placa erguida na mão, por cima do boneco) | — | 4 | qualquer | 1 (feito) |
| Crianças (reservado: "Escola — pra quando a vila tiver crianças") | 31 | falta | menino/menina, 3 tons | 8/4 | caminhada | ~100 |

## 2. Trajes e acessórios

| Item | Prompt | Status | Variações | Direções | Animações | Gerações |
|---|---|---|---|---|---|---|
| Casaco de inverno por função (`equipment.gd`) | 3 | **integrado** (andar e trabalho) | 18 | 8 paradas, 4 andando | andar, trabalho da função | ~600 (feito) |
| Trajes de perigo: gás (amarelo), calor (prata), radiação (oliva), h/m | 3 | **integrado** (andar e minerar) | 6 | 8 paradas, 4 andando | andar, minerar, carregar (saco) | ~220 (feito) |
| Desgaste das peças (novo/gasto/rasgado) | 3 | só ícone na UI (sem arte) | — | — | — | 0 |
| Ícones de vestiário (3 trajes + casaco), recortados da arte | 3 | **gerado** | 4 | — | — | 0 |
| Chapéu de cozinheiro solto (`cook_hat.png`, ícone) | 21 | não precisa (o ícone do cozinheiro é a panela) | — | — | — | 0 |
| Acessórios antigos (bota, lenço, detalhe: `acc_*.png`) | 3 | **substituído** | a variedade agora vem das roupas por função + tons + corpos | — | — | 0 |

## 3. Ferramentas e armas (Prompt 4, feito)

| Item | Prompt | Status | Versões | Gerações |
|---|---|---|---|---|
| Picareta, picareta de aço, machado, martelo, broca manual, lampião, arco (+aljava) | 4 | **integrado** (nas costas; broca e lampião ainda não) | base, gasta, quebrada, no chão, ícone; nas costas (regra da picareta) | 40 |
| Porrete, lança de ferro, besta de cobre, lança de prata, arma quebrada | 4 | **integrado** (nas costas; arma quebrada ainda não) | idem | 20 |
| Arma trocada na mão no ataque (lança/besta no lugar do porrete) | 29 | **integrado** (animação de ataque com lança e com besta, h/m; a lança de prata usa a da lança) | 4 | ~24 (feito) |
| Cesto de coleta, placa de greve (sobreposição) | 14 | **integrado** (Prompt 18: na mão do caçador sem arco / do grevista) | — | 2 (feito) |

## 4. Criaturas, robô e animais

| Item | Prompt | Status | Variações | Direções | Animações | Gerações |
|---|---|---|---|---|---|---|
| Lumívoro (invasor) | 16–17 | **integrado** (linha A, mutado da radiação) | forma forte: **bruto** | 4 (SE/NE + espelho) | parado, andar, atacar, dano, cair (poeira) | ~70 (feito) |
| Ferrugento (invasor) | 16–17 | **integrado** (linha B, máquina de antes) | forma forte: **carregador**; caçamba cheia ao roubar | 4 | parado, andar, atacar, dano, cair/desligar | ~70 (feito) |
| **Criaturas mais fortes + criatura mestre (chefe)** (pedido do Marco) | 16–17 | fortes **integradas** (onda 4+, 1 a cada 3); chefe (matriarca/colosso) **só conceito** (o jogo não tem chefe) | — | — | — | 18 conceito (feito) |
| Robô antigo GIGANTE (218 px, ~80% da casa): achado + arrastado + 3 estágios de conserto (deitado, mesma âncora) + ativo; fluxo em prompt05/FLUXO_ROBO.md | 5 | **integrado** (estados + andar/atacar/desligar; dano ainda não) | 4 estados parados + retrato + ícone | 8 paradas, 4 andando | andar, atacar, dano, desligar/derrubado | ~425 (feito) |
| Coelho + toca (coelho fora / só orelhas / toca vazia) | 15 | toca **integrada**; o coelho andando não existe no jogo | 8 dir. + andar, fugir, abatido; 3 estados da toca | ~40 (feito) |
| **Javali** + toca | 15 | **gerado** | 8 dir. + andar, fugir, abatido | ~25 (feito) |
| **Gosma ácida** (S2) e **Magmante** (S3) — Bloco 70 | — | **integrado** (personagem pro no estilo do Lumívoro; Gosma escurecida na exportação 0,56 → 0,31) | — | 4 (SE/NE + espelho) | parado, andar, atacar, dano, morrer | ~90 (feito) |

## 5. Prédios (cada construível: obra_1 · obra_2 · obra_3 · pronto; upgrade com obra entre níveis)

| Item | Prompt | Status | Estágios / estados | Gerações |
|---|---|---|---|---|
| Casa | 10 | **integrado** | obra 1–3 + pronto + 3 variações (v1–v3) | 175 (feito) |
| Casa nível 2 e 3 | 10 | **gerado** (`casa/nivel_2.png`, `nivel_3.png`; no jogo não há nível de casa: guardadas em `assets/game/iso/predios/casa/`) | upgrade por cima da casa aprovada | 80 (feito) |
| Armazém | 10 | **integrado** (lotação: sobreposição ainda não feita) | obra 1–3 + pronto; lotação vazio/médio/cheio (sobreposição) | 100 (feito) |
| Oficina (forja; hoje vem com a vila) | 10 | **integrado** | obra 1–3 + pronto; forja acesa = luz no código | 100 (feito) |
| Arsenal (criação de armas e armaduras) | 12 | **integrado** | obra 1–3 + pronto | ~50 (feito) |
| Taverna + ampliação | 11 | **integrado** | obra 1–3 + pronto + ampliada (2º andar) | ~90 (feito) |
| Enfermaria + ampliação | 11 | **integrado** | obra 1–3 + pronto + ampliada | ~90 (feito) |
| Laboratório (+ satélite no telhado) | 12 | **integrado** (o satélite ainda não) | obra 1–3 + pronto; satélite (Prompt 13) | ~50 (feito) |
| **Cozinha** (antes "Comedouro"; renomear no jogo na integração) | 11 | **integrado** (o nome no jogo ainda é "Comedouro") | obra 1–3 + pronto; vazia / com comida | ~50 (feito) |
| Horta (+ hidroponia, pesquisa) | 9/11 | **gerado** (canteiros no Prompt 9; cerca, galpão, espantalho, estufa no 11) | 6 estágios + estruturas | ~40 (feito) |
| Parque | 11 | **integrado** (o coreto) | obra 1–3 + coreto (resto montado com o Prompt 9) | ~40 (feito) |
| Campo de treino | 12 | **integrado** | obra 1–3 (script) + pronto | ~25 (feito) |
| Vestiário | 12 | **integrado** | obra 1–3 + pronto (3 trajes pendurados) | ~50 (feito) |
| Coletor de madeira = **máquina grande de cortar árvores** | 13 | **integrado** (pronto; obra pelo corte) | quebrada → consertada | ~50 (feito) |
| Barricada / Muro modular | 12 | **gerado** (`muro/final/`) | 3 níveis × reta i/j, canto, ponta, danificada, brecha | ~100 (feito) |
| **Portão da vila** (única entrada) | 12 / 29 | **integrado** (refeito no eixo da paliçada no Prompt 29: `muro/final/portao_i_*.png`) | quebrado + níveis 1, 2, 3 | ~80 (feito) |
| **Fundição** (pedra → carvão, ferro → aço) | 12 | **gerado** (`fundicao/`) | obra 1–3 + pronto | ~50 (feito) |
| Centro da Vila | 10 | **integrado** | 5 estágios + 4 obras entre estágios; caixas ≤ 4 px fora | ~280 (feito) |
| Escavadeira (plataforma de perfuração) + 5 reatores | 13 | **integrado** (peças como camadas; animação perfurando ainda não) | 5 etapas (peças) + animação perfurando + 5 reatores | ~105 (feito) |
| Elevador (ruína → pronto) + gaiola separada | 13 | **integrado** | ruína, pronto, gaiola | ~50 (feito) |
| Elevador do abismo | 13 | **integrado** | ruína, pronto | 0 |
| Escudo solar | 13 | **integrado** (as 4 etapas) | 4 etapas do jogo (fundação, bobinas, núcleo, emissor); cúpula = efeito (Prompt 18) | ~80 (feito) |
| Holofotes + satélite (4 ângulos, girando) | 13 | **gerado** | — | ~25 (feito) |
| Coletor de minério (reservado, "em breve") | 13 | **gerado** (pronto) | pronto | 25 (feito) |
| Escola (reservado, "em breve") | 31 | falta | obra 1–3 + pronto | ~100 |

## 6. Terreno (superfície e mina, por nível)

| Item | Prompt | Status | Peças | Gerações |
|---|---|---|---|---|
| Relevo da colônia (terra batida): chão ×4, bloco ×2 (+ sem borda), escada N/O | 6 | **integrado** (terreno do mapa novo, Prompt 29 p1) | platô, 2 degraus, escada | 40 (feito) |
| Clareira (grama), nível 2 (ardósia), abismo (basalto), rocha da caverna (parede) | 6–7 | **integrado** (floresta no mapa novo; chão e blocos das lajes do nível 2 e do abismo, Prompt 29 p1) | chão, bloco, sem borda; rocha com 4 blocos | 80 (feito) |
| Buraco/galeria, transição entre chãos, parede da caverna | 6–7 | **integrado** (transição entre chãos no terreno assado; parede da caverna não se usa: a vila é a céu aberto) | — | 0 |
| Galeria na parede de rocha: lacrada → abrindo → aberta (também serve de túnel entre áreas) | 7 | **integrado** em parte: lacrada (com entulho, Prompt 29 p4); abrindo/aberta ainda não aparecem | 3 estágios, mesma âncora | 75 (feito) |
| Pisos das zonas de perigo: gás, calor, radiação (5 variações cada) | 7 | **integrado** (lajes dos andares, parte 1) | — | 60 (feito) |
| Trilhos: reto, curva, cruzamento, fim de linha (script, encaixe exato) | 7 | **integrado** (trilho da boca da mina ao armazém, no fundo da pedreira) | 11 peças | 60 (feito; a IA só deu a cor) |
| Escora de madeira (pesquisa "Escoramento") | 7 | **integrado** | — | 20 (feito) |
| Poço do elevador / da escavadeira | 7 | **código** (buraco fundo do relevo) | — | 0 |
| Variante por estação do chão/árvore | 6 | **não precisa hoje** (o jogo só usa estação no clima) | — | 0 |
| Pisos da superfície: grama alta (5), trilha (5), cascalho (4), lama (1+espelho), laje (4), canteiro (2+espelho) | 6 | **integrado** (terreno do mapa novo) | — | 120 (feito) |
| Escada de pedra, rampa (+ espelho) | 6 | **integrado** (5 subidas entre os terraços) | — | 40 (feito) |
| Boca de mina no paredão (vigas de madeira, 3 degraus, 2×1 tiles) | 6 | **integrado** (4 bocas, uma por galeria) | — | 75 (feito) |
| **Pisos do S4 (rocha molhada), S5 (rocha azulada) e água rasa do lago** + lajes `andar_s4/s5` — Bloco 71 | — | **integrado** | 4 + 4 + 4 ladrilhos | 60 (feito) |
| **Cachoeira** (efeito animado, 6 quadros por script) — Bloco 71 | — | **integrado** | 1 | 25 (feito) |
| **Rocha com ácido** (em volta das poças do S2) e **borda do lago** (seixos, S5) | — | **integrado** | 4 + 4 ladrilhos | 40 (feito) |

## 7. Jazidas, minérios e pedras

| Item | Prompt | Status | Variações | Gerações |
|---|---|---|---|---|
| Jazidas: carvão, cobre, ferro, prata, solarita | 8 | **integrado** | 4 estados × 5 (cheia, meia, quase, esgotada) | ~25 (feito; recolor por minério) |
| Nó mineral comum (`mineral_node` / `ore_rock`) | 8 | **gerado** (= jazida) | 4 estados | incluído |
| Pedaços de minério soltos + pilhas (3 tamanhos) + lascas do golpe | 8 | **gerado** | 6 formas + 3 pilhas por minério | ~40 (feito) |
| Cristais (4 cores × 2), rochas (6 + 6 com musgo + 3 da mina), pedrinhas (8) | 8 | cristais e rochas **integrados**; pedrinhas não (o chão novo já tem) | — | ~80 (feito) |
| Achados (bobina, cristal, peça, painel solar) + entulho (4 tamanhos) | 8 | **integrado** (entulho médio) | — | ~40 (feito) |
| **Jazidas de cristal verde (S2) e rubro (S3)** — Bloco 70 | — | **integrado** | cheia, meia, quase (edit da jazida de prata, mesma âncora) | ~50 (feito) |
| **Poças de ácido e poços de lava** (decalque deitado na laje, `assets/game/iso/chao/`) — Bloco 70 | — | **integrado** | 2 de cada | ~100 (feito) |
| **Jazidas de gema azul (S5)** — Bloco 71 | — | **integrado** | cheia, meia, quase | ~25 (feito) |
| **Poças d'água (S4)** — Bloco 71 | — | **integrado** | 2 | 25 (feito) |

## 8. Vegetação

| Item | Prompt | Status | Variações | Gerações |
|---|---|---|---|---|
| Árvores: pinheiro, carvalho, bétula, seca; toco, tora caída, muda rebrotando | 9 | **integrado** (árvores e toco) | 8 árvores + ciclo por espécie | ~145 (feito) |
| Vegetação rasteira: arbusto, samambaia, moita, espinheiro, flores, capim alto, galho, tronco com musgo, cogumelos, raízes | 9 | **integrado** (Prompt 30: 90 peças espalhadas na floresta + arbustos da montagem; espinheiro, galho e raízes ainda não aparecem) | 3+ de cada | ~45 (feito) |
| Horta de cogumelos: vazio, preparado, plantado, crescendo, pronto, colhido | 9 | **integrado** (pronto, crescendo, colhido) | 6 estágios | 20 (feito) |
| Madeira: tora, toras P/M/G, lenha P/G, tábuas P/M/G + lascas do machado | 9 | **gerado** | 9 + efeito | 20 (feito) |

## 9. Objetos (mina e vila)

| Item | Prompt | Status | Gerações |
|---|---|---|---|
| Tochas (parede, chão, apagada), lampiões, fogueira, braseiro, poste | 14 | tocha de chão (acesa animada/apagada) **integrada** | chama animada por script | ~20 (feito) |
| Escora de madeira (`support_beam`, pesquisa "Escoramento") | 7 | **integrado** | 0 |
| Placas com pictograma (caveira, raio, gás, perigo), postes, andaime, escada, varal, poço, banco, mesa, bigorna | 14 | placa de perigo **integrada** | — | ~25 (feito) |
| Cova (`grave`), entulho | 14/8 | entulho **gerado** (Prompt 8); cova **integrada** (Prompt 18, no cemitério da enfermaria) | — | 1 (feito) |
| Trilhos + vagonete (vazio/cheio), caixotes, barris, sacos, sucata, pneus, corrente, corda | 14 | **integrado** em parte (Prompt 30: vagonete, caixotes, barris, sacos, pedra, tijolo, poço, banco, placa, caixote, como na montagem aprovada) | — | ~40 (feito) |
| **Trilho com vagonete da boca da mina até o Armazém da pedreira** (aceito, `MAPA_VISAO.md`) | 14 / 27 | **integrado** (trilho no terreno; vagonete cheio em cima, Prompt 30) | incluído |
| **Guindaste de madeira da pedreira** (aceito) | 14 | **integrado** (Prompt 30, terraço do meio) | — | 20 (feito) |
| **Cerca de estacas** (aceito) | 12/11 | paliçada **integrada** (Prompt 29 parte 2); cerca da horta **gerada** | — | 0 |
| **Vila em 2–3 terraços de pedreira** com escadas entre eles (aceito) | 27 | **integrado** (Prompt 29 p1) | 0 |
| Explosivos (pesquisa), antena do satélite (pesquisa "Satélite") | 14 | **integrados** (Prompt 18: caixote perto do poço; antena ao lado do laboratório, com pulsos) | 2 (feito) |
| Pilhas de recurso P/M/G (pedra, tijolo, comida, couro, carvão, aço) + destroços pré-colapso e ossos | 14 | **gerado** | — | ~40 (feito) |
| Sombra | 19 | **código** (gerada da pegada, regra 7) | 0 |
| **Ventilador do nível 2** (prop + ícone do menu) — Bloco 70 | — | **integrado** | 25 (feito) |
| **Casinhas de pedra** da vila antiga do lago — Bloco 71 | — | **integrado** | 25 (feito) |
| **Vila antiga do leste: igreja, torre do relógio, 3 casas enxaimel** (itens de arte do documento de melhorias) | — | **integrado** (decoração ao desbravar) | 75 (feito) |
| **Passarelas de madeira (2), ponte de corda, peças da rampa em espiral (3)** | — | **integrado** (decoração do S3–S5) | 75 (feito) |
| **Carpintaria** (obra 1-2-3 + pronto, desenho do mapa antigo, cartão do CONSTRUIR) — Bloco 94 (`predios94.py`) | — | **integrado** | 40 (feito) |
| **Carpinteiro e carpinteira** (personagem v3, caminhada 8, comer/ferido/deitar/mancar, serrar, casaco, retrato 5 expressões, ícone da barra) — Bloco 94 (`oficios94.py`) | — | **integrado** | ~400 (feito, com refações do serrar e das expressões) |
| **Ícones de itens**: tábua, cama de tábua, mochila, botas, picareta de aço — Bloco 94 | — | **integrado** | ~45 (feito) |
| **Ícones de relação**: coração (balão do casal/interesse) e coração partido (luto pelo parceiro) — Bloco 110 (`oficios92.py icones coracao`; os dois saíram do MESMO pedido: c07 e c13) | — | **integrado** | 10 (feito) |
| **Cartões do CONSTRUIR sem desenho** (escola, estação da ferrovia de carga, caminho de terra/cascalho/pedra, pá de apagar caminho, mapa de desbravar, bota das trilhas, pé de cabra de remover decoração) + **ícones** (sem ferramenta, armazém cheio, caminho bloqueado, pessoas, missões) — Bloco 95 (`ui95/ui95.py`; os 8 cartões da decoração e do vagonete e o coletor de minério reaproveitam o sprite do jogo, sem gerar) | — | **integrado** | 300 (feito: 2 pilotos + 13 pedidos de 20; a picareta quebrada foi cortada à mão, `ui95/quebra_picareta.py`) |
| **Armazém nível 2 e 3** (pronto; a obra da ampliação usa o `obra_3` por cima; armazém novo sobe pelos `obra_1-2-3` que já existiam) + **cartão "Ampliar armazém"** (do nível 2 reduzido) — Bloco 97 (`armazem/niveis97.py`) | — | **integrado** | 80 (feito) |
| **Portão da paliçada aberto e a meio caminho** (aberto_1/2/3, meio_1/2/3) + **ruína com o vão aberto** (quebrado_aberto) — Bloco 98 (`portao98/portao98.py`); o nível 3 (nivel_3) foi espelhado pra correr como o 1 e o 2 | — | **integrado** | 340 (feito: 17 pedidos, 7 escolhidos) |
| **Entrada da mina** — torre do elevador obra_1/obra_2 (restauração por etapas), cabine vazia/cheia (anda pelo poço), vagonete com carga grande (SE/SO) e o lampião da boca — Bloco 99 (`mina99/mina99.py`) | — | **integrado** | 205 (feito: piloto + 1 lote) |

## 10. Efeitos e luzes

| Item | Prompt | Status | Gerações |
|---|---|---|---|
| Clima: folha, pólen, chuva, neve (partícula por estação) + neblina | 18 | **integrado** (textura de pixel, pixel inteiro em qualquer zoom; neblina de manhã e na chuva) | ~4 (feito) |
| Poeira, lascas, serragem, faíscas, fumaça, gás, calor, radiação, gotas, pedras (acidente), fogo animado, onda solar, domo do escudo, festa (bandeirinhas, fogos, confete), greve (barril, placas), marcadores (seleção, destino, obra) | 18 | **integrado** (`iso_fx.gd`; relatório `prompt18/`) | ~37 (feito) |
| Luzes (janelas, forja, tochas, cabine, giroflex) | 19 | **integrado** (Prompt 19: ponto de luz por desenho, texturas por tipo, janelas acesas, lava, tom por estação) | 0 |

## 11. Interface

| Item | Prompt | Status | Gerações |
|---|---|---|---|
| Ícones de recurso: créditos, minério, madeira, comida, 5 minérios, camas, ânimo, saúde, estações | 21 | **integrado** (barra de cima) | ~20 (feito) |
| Ícones de necessidade/status: fome, frio, cansaço, ferido leve/grave, greve, zanga (+ 16 px sobre a cabeça), alertas (invasão, onda solar, falta de comida, obra parada, reator) | 21 | **integrado** | ~20 (feito) |
| Ícones de pesquisa (11: carrinhos, explosivos, escoramento, trajes, medicina, rádio, hidroponia, estudo solar, satélite, holofotes, escudo) | 21 | **integrado** (laboratório) | ~14 (feito) |
| Ícones de itens/armas/ferramentas e funções (9 + construir, sem função, turno extra) | 21 | **integrado** (ferramentas/armas/trajes reaproveitados dos Prompts 3–5; funções geradas) | ~12 (feito) |
| Cursores: normal, construir, proibido, atacar, selecionar | 20 | **integrado** (troca pelo que está embaixo do mouse) | 5 (feito) |
| Painel (moldura 9-slice), botões (4 estados), botão de ícone, abas, barras, dica, slider, caixa de marcar, controle de velocidade | 20 | **integrado** (kit do UI Template Pro; `ui_skin.gd` + tema da raiz) | 40 (feito) |
| Cartões do menu de construção (normal, trancado com cadeado, em breve; miniatura = render reduzido do prédio) | 20/21 | **integrado** | 0 |
| Fonte pixel: texto (com todos os acentos, números de largura fixa) e título (estêncil de ferro) | 22 | **integrado** em cabeçalhos, faixas e números do HUD (o texto corrido segue na padrão: ver `prompt22/`) | 50 (feito) |
| Menus: início (key art animada + logo), pausa, opções, fim de jogo, vitória | 20/26 | **integrado** (pele nova) | incluído |

## 12. Enfeite (depois que o jogo roda com a arte nova)

| Item | Prompt | Status | Gerações |
|---|---|---|---|
| Retratos do elenco (18) + criaturas, 5 expressões, 3 tons de pele | 23 | **integrado** (cartão do ipezinho selecionado) | ~498 (feito) |
| Imagens de evento (robô, reator, acidente, invasão, greve, festa, onda solar, abismo, vitória, derrota) | 24 | **integrado** (faixas de aviso, vitória, fim de jogo, janela de evento) | 200 (feito) |
| Telas: título (key art + logo, fundo animado), carregando (5 cenas × 10 dicas), vitória, derrota | 26 | **integrado** | 80 (feito) |
| Tela "Corte da mina" (vista lateral, F2) | 25 | **integrado** | 6 (feito) |

---

## Pendências

- Nenhuma do Prompt 3: o casaco por função ficou completo (os 18, 2026-09-30).
- Prompts 16–26 e as pendências dos Prompts 2, 14 e 29: feitos em 2026-10-01/02 (ver o registro abaixo).

## Plano de crédito

**Atualização 2026-10-02 (noite, Bloco 70 — conteúdo do S2/S3):** PixelLab no tier 3 (10.000 no
ciclo, renova em 2026-11-02). Gasto no bloco ~260: jazidas de cristal (~50), ventilador (25), poças
(100), Gosma e Magmante (~90). Arte em `prototipos/camera/arte_iso/fundo70/` e `criaturas/fundo.py`;
relatório `docs/NIVEIS_S2_S3.md`.

**Atualização 2026-10-02 (noite, Bloco 71 — S4 e S5):** ~160 gerações: pisos de rocha molhada, rocha
azulada e água (60), cachoeira (25), casinhas de pedra (25), poças d'água (25), jazidas de gema azul (~25).
Arte em `relevo/fundo71.py`, `fundo71/` e `fundo70/jazidas.py`; relatório `docs/NIVEIS_S4_S5.md`.

**Atualização 2026-10-02 (Prompts 16 a 26 + pendências dos Prompts 2, 14 e 29), sem checkpoint
(o Marco liberou ir até o fim):** saldo 1.359 → **209** (1.150 gastas).

| Prompt | O quê | Gerações |
|---|---|---|
| 16 | conceito das criaturas (3 linhas × 3 tipos × 2): escolhidas A (mutados) e B (máquinas) | 18 |
| 17 | Lumívoro, Ferrugento e as formas fortes (bruto, carregador): 5 animações × 4 direções; carga do roubo | ~142 |
| 18 | partículas (por script + pixen), fogo animado, festa, greve, onda solar, domo, clima, neblina, marcadores; cova, explosivos, antena, cesto, placa de greve | ~37 |
| 19 | (já feito) luz e noite | 0 |
| 20 | kit de interface (9-slice), cursores, controle de velocidade, janela de evento | 45 |
| 21 | 76 ícones (55 gerados + 11 refeitos + reaproveitados) e 15 prédios reduzidos | 66 |
| 22 | 2 fontes pixel com acentos (montadas em .ttf por script) | 50 |
| 23 | 18 retratos + 2 criaturas, 5 expressões, 3 tons | ~498 |
| 24 | 10 ilustrações de evento | 200 |
| 25 | corte da mina (4 faixas, escavadeira, gaiola) | 6 |
| 26 + 2/29 | 2 key arts, logo por script, fundo animado, carregamento; colher fruta, treinar, ataque com lança e besta (h/m) | 82 (juntos) |

Relatórios: `docs/arte/prompt16/` a `prompt26/`.


**Atualização 2026-10-01 (Prompt 19, luz e noite):** feito sem geração. Texturas de luz por tipo
(`assets/game/iso/luz/`), janelas acesas em 10 desenhos, pontos de luz em 19, lava no abismo, tom
do ambiente por estação; corrigidos 5 defeitos de luz da vista iso (z da luz, tocha/cristal sem
luz, escala da luz, luzes do subsolo apagadas, luz por item no terreno grande). Relatório:
`docs/arte/prompt19/PROMPT_19_LUZ.md`.

**Atualização 2026-10-01 (Prompt 31, verificação):** nenhum item do backlog do Prompt 31 tem
gameplay hoje (escola, crianças, casa nível 2/3 e coletor de minério são cartões "em breve"; a
oficina é fixa; reatores, armas, ferramentas e trajes do jogo já têm arte). **Nada gerado.**
Prompts sem fazer: **16 a 26** (+ pendências pequenas dos Prompts 2, 14 e 29), ~1.100–1.200
gerações no total. Relatório: `docs/arte/prompt31/PROMPT_31_CONTEUDO_FUTURO.md`.

**Atualização 2026-10-01 (Prompt 30, revisão final):** decoração da montagem aprovada no jogo
(guindaste, vagonete, caixotes, vegetação rasteira); contorno de 1 px nos desenhos que vieram
sem ele; clima visível na vista iso; tiras dos bonecos carregando em segundo plano. Sem geração
(saldo **1.359**). O que ainda está "falta" é a arte dos Prompts 16–26 e o conteúdo futuro (31).
Relatório: `docs/arte/prompt30/PROMPT_30_REVISAO.md`.

**Atualização 2026-10-01 (Prompt 29, partes 3 a 6):** bonecos (elenco, animações, casacos, trajes,
ferramentas e saco nas costas, pele por paleta), natureza e objetos (árvores, jazidas, tocas, horta,
rochas, cristais, tocha, achados, escora, placa), robô e elevadores = **integrado**. Zoom com a
densidade da arte nova, F3 saiu, "Comedouro" → "Cozinha". Sem geração (saldo **1.359**). Relatório:
`docs/arte/prompt29/PROMPT_29_PARTES3A6.md`. O que ainda não tem arte (prompts 16–26) segue como
"falta".

**Atualização 2026-10-01 (Prompt 29, parte 2):** os **prédios** estão no jogo com a arte nova
(casa, armazém, oficina, arsenal, taverna, enfermaria, laboratório, cozinha/comedouro, parque,
campo de treino, vestiário, coletor de madeira, escudo, escavadeira, Centro nos 5 estágios, portão
e a paliçada), com obra por estágios e pegada de navegação do desenho. Status desses itens =
**integrado**. Geração: o portão refeito no eixo i (80; saldo **1.359**). Relatório: `docs/arte/prompt29/PROMPT_29_PARTE2_PREDIOS.md`.

**Atualização 2026-10-01 (Prompt 29, parte 1):** o mapa novo está no jogo (terreno do
Prompt 27 assado em imagens, céu do cenário, andares de baixo empilhados com os chãos do Prompt
7). Terreno, céu e chão do nível 2/abismo = **integrado**; o resto (personagens, prédios,
objetos...) segue nas próximas partes. Sem geração (saldo **1.439**). Relatório:
`docs/arte/prompt29/PROMPT_29_PARTE1_MAPA.md`.

**Atualização 2026-10-01 (Prompt 28, branch `isometrico`):** motor isométrico no jogo
principal (F3 liga/desliga), ainda com a arte de hoje; nada desta lista passou pra
"integrado" (isso é o Prompt 29). Já prontos pra receber a arte: verificador "cabe na caixa"
(`scripts/iso/iso_art_check.gd`), pele por paleta (`scripts/iso/skin_palette.gd`, lê
`paletas_pele.json`) e obra por estágios 0–33/33–66/66–100% (`scripts/core/obra_estagio.gd`).
Sem geração: saldo **1.439**. Relatório: `docs/arte/prompt28/PROMPT_28_MOTOR_ISO.md`.

**Atualização 2026-10-01 (fundo do mapa, Prompt 27):** céu + montanhas por hora do dia custou
**75**. Saldo **1.439** (conferido no PixelLab), recarga de +5.000 em 2026-10-30. Os Prompts
28–29 são código: não gastam geração.

**Atualização 2026-09-30 (fim do Prompt 15):** saldo do ciclo **1.514** (recarga de +5.000 em
2026-10-30). Casaco por função (~600), robô gigante (~425) terreno da superfície (~215) e da mina (~200), jazidas (~185), vegetação (~230), prédios da vila (~500) e prompts 11–13 (~990) já descontados. Com 1.758, dá pros prompts 14–15 (~450) e parte do 16–18; o resto espera a recarga de 30/10. O que falta dos
prompts 6–27 é estimado em ~4.000 (ver resposta de planejamento). Cabe no saldo, com pouca
folga pra refações; o Prompt 31 fica pra depois da recarga.

Atualizado depois dos Prompts 2 e 3 (2026-09-30).

| | Gerações |
|---|---|
| Já gasto na arte isométrica (até o Prompt 3) | ~1.530 |
| Saldo agora | **0** (ciclo esgotado; o Marco vai subir a assinatura: +5.000) |
| Decisão do Marco | gastar o saldo até acabar e então subir a assinatura (US$ 24) → **+5.000** |
| Estimativa do que falta (prompts 2–27, arte) | ~4.650 |
| Conteúdo futuro (prompt 31) | ~420 |

**Ordem** (a do pacote de prompts; cada prompt estima o custo e para no limite do saldo):

1. Prompts 2 e 3 feitos (~595). Sobram 162: o Prompt 4 (ferramentas e armas, ~220) começa
   com eles e termina depois do upgrade. O casaco por função (~630) fica pro upgrade.
2. Com os +5.000:
   - prompts 4–13 (ferramentas, robô, terreno, mina, jazidas, vegetação, prédios, máquinas):
     ~3.200;
   - depois prompts 14–27 (objetos, animais, criaturas, efeitos, luz, UI, ícones, fonte,
     retratos, eventos, telas, mapa): ~1.250.
3. Sobra estimada de ~800 pra refazer o que não passar e pro conteúdo futuro.
