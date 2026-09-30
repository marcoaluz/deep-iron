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
| Minerador (homem) + picareta nas costas | 1 | **aprovado** (caminhada) · **gerado** (minerar) | 3 tons por paleta | 8 paradas, 4 andando | caminhada, minerar | 27 + 6 (feito) |
| Elenco: mineradora, guarda (h/m), médico (h/m), engenheiro (h/m), caçador (h/m), pesquisador (h/m), lenhador (h/m), sem função (h/m), cozinheiro (h/m) = 17 | 1 | **gerado** (Prompt 1 completo) | 3 tons por paleta; corpo forte/magro/gordinho/cheinho; mulheres 3–4 px mais baixas (corte de linhas) | 8 paradas, 4 andando | caminhada + 1 de trabalho por função (sem função: nenhuma) | 515 + 91 (feito) |
| Caçadora "com arco" (referência pro visual com arco) | 1 | gerado (guardada em `cacadora/com_arco_ref/`) | — | 8 | caminhada | incluído |
| Animações de trabalho (1 por função, h/m): minerar, construir/martelar, atacar com porrete, atender ajoelhado, cozinhar (tigela no braço), caçar com arco (só com a Oficina), cortar lenha, pesquisar na bancada | 1 | **gerado** | 16 | SE+NE +espelho (4) | 8 quadros cada | ~97 (feito) |
| Colher fruta (caçador sem arco), treinar no campo | 2 | falta | h/m | SE+NE +espelho | — | ~30 |
| Animações comuns (18): comer, ferido (tala), deitar (morte sóbria / dormir na rua), mancar (sad-walk) | 2 | **gerado** | 18 | SE+NE +espelho | 4 × 18 | ~345 (feito) |
| Carregar (caminhada + saco em sobreposição, `itens/saco_costas.png`) | 2 | **gerado** | 18 + 6 trajes | 4 | caminhada | 0 |
| Festa (pulinho), respiração, curativo | 2 | código | — | — | — | 0 |
| Dormindo / na taverna / na enfermaria (dentro do prédio) | 2 | não precisa | — | — | some dentro | 0 |
| Greve: placa na mão | 2 | falta | — | 2 + espelho | parado + placa | incluído |
| Crianças (reservado: "Escola — pra quando a vila tiver crianças") | 31 | falta | menino/menina, 3 tons | 8/4 | caminhada | ~100 |

## 2. Trajes e acessórios

| Item | Prompt | Status | Variações | Direções | Animações | Gerações |
|---|---|---|---|---|---|---|
| Casaco de inverno por função (`equipment.gd`) | 3 | **gerado** (os 18) | 18 | 8 paradas, 4 andando | andar, trabalho da função | ~600 (feito) |
| Trajes de perigo: gás (amarelo), calor (prata), radiação (oliva), h/m | 3 | **gerado** | 6 | 8 paradas, 4 andando | andar, minerar, carregar (saco) | ~220 (feito) |
| Desgaste das peças (novo/gasto/rasgado) | 3 | só ícone na UI (sem arte) | — | — | — | 0 |
| Ícones de vestiário (3 trajes + casaco), recortados da arte | 3 | **gerado** | 4 | — | — | 0 |
| Chapéu de cozinheiro solto (`cook_hat.png`, ícone) | 21 | falta | — | — | — | incluído |
| Acessórios antigos (bota, lenço, detalhe: `acc_*.png`) | 3 | **substituído** | a variedade agora vem das roupas por função + tons + corpos | — | — | 0 |

## 3. Ferramentas e armas (Prompt 4, feito)

| Item | Prompt | Status | Versões | Gerações |
|---|---|---|---|---|
| Picareta, picareta de aço, machado, martelo, broca manual, lampião, arco (+aljava) | 4 | **gerado** | base, gasta, quebrada, no chão, ícone; nas costas (regra da picareta) | 40 |
| Porrete, lança de ferro, besta de cobre, lança de prata, arma quebrada | 4 | **gerado** | idem | 20 |
| Arma trocada na mão no ataque (lança/besta no lugar do porrete) | 29 | falta | posição da mão por quadro (integração) ou animação por arma (~8 cada) | 0–48 |
| Cesto de coleta, placa de greve (sobreposição) | 14 | falta | — | ~20 |

## 4. Criaturas, robô e animais

| Item | Prompt | Status | Variações | Direções | Animações | Gerações |
|---|---|---|---|---|---|---|
| Lumívoro (invasor) | 16–17 | falta | — | 4 | andar, atacar, morrer (sóbrio) | ~35 |
| Ferrugento (invasor) | 16–17 | falta | — | 4 | andar, atacar, morrer | ~35 |
| **Criaturas mais fortes + criatura mestre (chefe)** (pedido do Marco) | 16–17 | falta (conceito com checkpoint) | — | 4 | andar, atacar, morrer | ~120 |
| Robô antigo GIGANTE (218 px, ~80% da casa): achado + arrastado + 3 estágios de conserto (deitado, mesma âncora) + ativo; fluxo em prompt05/FLUXO_ROBO.md | 5 | **gerado** | 4 estados parados + retrato + ícone | 8 paradas, 4 andando | andar, atacar, dano, desligar/derrubado | ~425 (feito) |
| Coelho + toca (coelho fora / só orelhas / toca vazia) | 15 | falta | 3 estados | — | — | ~45 |
| **Javalizinho** + toca (visão do mapa, `MAPA_VISAO.md`) | 15 | falta | — | 4 | andar, fugir | ~35 |

## 5. Prédios (cada construível: obra_1 · obra_2 · obra_3 · pronto; upgrade com obra entre níveis)

| Item | Prompt | Status | Estágios / estados | Gerações |
|---|---|---|---|---|
| Casa | 10 | **aprovado** | obra 1–3 + pronto + 3 variações (v1–v3) | 175 (feito) |
| Casa nível 2 e 3 | 10 | **gerado** (`casa/nivel_2.png`, `nivel_3.png`) | upgrade por cima da casa aprovada | 80 (feito) |
| Armazém | 10 | **gerado** (`armazem/`) | obra 1–3 + pronto; lotação vazio/médio/cheio (sobreposição) | 100 (feito) |
| Oficina (forja; hoje vem com a vila) | 10 | **gerado** (`oficina/`) | obra 1–3 + pronto; forja acesa = luz no código | 100 (feito) |
| Arsenal (criação de armas e armaduras) | 12 | **gerado** (`arsenal/`) | obra 1–3 + pronto | ~50 (feito) |
| Taverna + ampliação | 11 | **gerado** (`taverna/`) | obra 1–3 + pronto + ampliada (2º andar) | ~90 (feito) |
| Enfermaria + ampliação | 11 | **gerado** (`enfermaria/`) | obra 1–3 + pronto + ampliada | ~90 (feito) |
| Laboratório (+ satélite no telhado) | 12 | **gerado** (`laboratorio/`) | obra 1–3 + pronto; satélite (Prompt 13) | ~50 (feito) |
| **Cozinha** (antes "Comedouro"; renomear no jogo na integração) | 11 | **gerado** (`cozinha/`) | obra 1–3 + pronto; vazia / com comida | ~50 (feito) |
| Horta (+ hidroponia, pesquisa) | 9/11 | **gerado** (canteiros no Prompt 9; cerca, galpão, espantalho, estufa no 11) | 6 estágios + estruturas | ~40 (feito) |
| Parque | 11 | **gerado** (`parque/`) | obra 1–3 + coreto (resto montado com o Prompt 9) | ~40 (feito) |
| Campo de treino | 12 | **gerado** (`campo_treino/`) | obra 1–3 (script) + pronto | ~25 (feito) |
| Vestiário | 12 | **gerado** (`vestiario/`) | obra 1–3 + pronto (3 trajes pendurados) | ~50 (feito) |
| Coletor de madeira = **máquina grande de cortar árvores** | 13 | **gerado** | quebrada → consertada | ~50 (feito) |
| Barricada / Muro modular | 12 | **gerado** (`muro/final/`) | 3 níveis × reta i/j, canto, ponta, danificada, brecha | ~100 (feito) |
| **Portão da vila** (única entrada) | 12 | **gerado** (`muro/final/`) | quebrado + níveis 1, 2, 3 | ~80 (feito) |
| **Fundição** (pedra → carvão, ferro → aço) | 12 | **gerado** (`fundicao/`) | obra 1–3 + pronto | ~50 (feito) |
| Centro da Vila | 10 | **gerado** (`centro/`) | 5 estágios + 4 obras entre estágios; caixas ≤ 4 px fora | ~280 (feito) |
| Escavadeira (plataforma de perfuração) + 5 reatores | 13 | **gerado** (`final_maquinas/`) | 5 etapas (peças) + animação perfurando + 5 reatores | ~105 (feito) |
| Elevador (ruína → pronto) + gaiola separada | 13 | **gerado** | ruína, pronto, gaiola | ~50 (feito) |
| Elevador do abismo | 13 | **gerado** (o elevador escurecido) | ruína, pronto | 0 |
| Escudo solar | 13 | **gerado** | 4 etapas do jogo (fundação, bobinas, núcleo, emissor); cúpula = efeito (Prompt 18) | ~80 (feito) |
| Holofotes + satélite (4 ângulos, girando) | 13 | **gerado** | — | ~25 (feito) |
| Coletor de minério (reservado, "em breve") | 13 | **gerado** (pronto) | pronto | 25 (feito) |
| Escola (reservado, "em breve") | 31 | falta | obra 1–3 + pronto | ~100 |

## 6. Terreno (superfície e mina, por nível)

| Item | Prompt | Status | Peças | Gerações |
|---|---|---|---|---|
| Relevo da colônia (terra batida): chão ×4, bloco ×2 (+ sem borda), escada N/O | 6 | **aprovado** (checkpoint relevo 1) | platô, 2 degraus, escada | 40 (feito) |
| Clareira (grama), nível 2 (ardósia), abismo (basalto), rocha da caverna (parede) | 6–7 | **gerado** | chão, bloco, sem borda; rocha com 4 blocos | 80 (feito) |
| Buraco/galeria, transição entre chãos, parede da caverna | 6–7 | **gerado** (montagem por código) | — | 0 |
| Galeria na parede de rocha: lacrada → abrindo → aberta (também serve de túnel entre áreas) | 7 | **gerado** (`relevo/final/mina/`) | 3 estágios, mesma âncora | 75 (feito) |
| Pisos das zonas de perigo: gás, calor, radiação (5 variações cada) | 7 | **gerado** | — | 60 (feito) |
| Trilhos: reto, curva, cruzamento, fim de linha (script, encaixe exato) | 7 | **gerado** (`relevo/trilhos.py`) | 11 peças | 60 (feito; a IA só deu a cor) |
| Escora de madeira (pesquisa "Escoramento") | 7 | **gerado** | — | 20 (feito) |
| Poço do elevador / da escavadeira | 7 | **código** (buraco fundo do relevo) | — | 0 |
| Variante por estação do chão/árvore | 6 | **não precisa hoje** (o jogo só usa estação no clima) | — | 0 |
| Pisos da superfície: grama alta (5), trilha (5), cascalho (4), lama (1+espelho), laje (4), canteiro (2+espelho) | 6 | **gerado** (`relevo/final/superficie/`) | — | 120 (feito) |
| Escada de pedra, rampa (+ espelho) | 6 | **gerado** | — | 40 (feito) |
| Boca de mina no paredão (vigas de madeira, 3 degraus, 2×1 tiles) | 6 | **gerado** | — | 75 (feito) |

## 7. Jazidas, minérios e pedras

| Item | Prompt | Status | Variações | Gerações |
|---|---|---|---|---|
| Jazidas: carvão, cobre, ferro, prata, solarita | 8 | **gerado** (`jazidas/final/`) | 4 estados × 5 (cheia, meia, quase, esgotada) | ~25 (feito; recolor por minério) |
| Nó mineral comum (`mineral_node` / `ore_rock`) | 8 | **gerado** (= jazida) | 4 estados | incluído |
| Pedaços de minério soltos + pilhas (3 tamanhos) + lascas do golpe | 8 | **gerado** | 6 formas + 3 pilhas por minério | ~40 (feito) |
| Cristais (4 cores × 2), rochas (6 + 6 com musgo + 3 da mina), pedrinhas (8) | 8 | **gerado** | — | ~80 (feito) |
| Achados (bobina, cristal, peça, painel solar) + entulho (4 tamanhos) | 8 | **gerado** | — | ~40 (feito) |

## 8. Vegetação

| Item | Prompt | Status | Variações | Gerações |
|---|---|---|---|---|
| Árvores: pinheiro, carvalho, bétula, seca; toco, tora caída, muda rebrotando | 9 | **gerado** (`vegetacao/final/`) | 8 árvores + ciclo por espécie | ~145 (feito) |
| Vegetação rasteira: arbusto, samambaia, moita, espinheiro, flores, capim alto, galho, tronco com musgo, cogumelos, raízes | 9 | **gerado** | 3+ de cada | ~45 (feito) |
| Horta de cogumelos: vazio, preparado, plantado, crescendo, pronto, colhido | 9 | **gerado** | 6 estágios | 20 (feito) |
| Madeira: tora, toras P/M/G, lenha P/G, tábuas P/M/G + lascas do machado | 9 | **gerado** | 9 + efeito | 20 (feito) |

## 9. Objetos (mina e vila)

| Item | Prompt | Status | Gerações |
|---|---|---|---|
| Tocha acesa / apagada (`torch`, `torch_unlit`) | 14 | falta | ~20 |
| Escora de madeira (`support_beam`, pesquisa "Escoramento") | 7 | **gerado** (ver seção 6) | 0 |
| Placas de área de perigo: gás, calor, radiação (`placa_perigo`) | 14 | falta | ~20 |
| Cova (`grave`), entulho (`entulho`) | 14 | falta | ~40 |
| Trilhos + vagonete (pesquisa "Carrinhos de mina"), caixotes, barris | 14 | falta | ~60 |
| **Trilho com vagonete da boca da mina até o Armazém da pedreira** (aceito, `MAPA_VISAO.md`) | 14 / 27 | falta (trilho pronto; falta o vagonete) | incluído |
| **Guindaste de madeira da pedreira** (aceito) | 14 | falta | ~25 |
| **Cerca de estacas** até o portão ser reconstruído (aceito) | 14 | falta | ~20 |
| **Vila em 2–3 terraços de pedreira** com escadas entre eles (aceito) | 27 | montagem (relevo pronto) | 0 |
| Explosivos (pesquisa), antena do rádio (pesquisa "Rádio da vila") | 14 | falta | ~40 |
| Itens soltos/carregados: lenha, galho, pilha de minério, comida crua, cestos, moeda, bilhete, cadeado | 14 | falta | ~40 |
| Sombra | 19 | **código** (gerada da pegada, regra 7) | 0 |

## 10. Efeitos e luzes

| Item | Prompt | Status | Gerações |
|---|---|---|---|
| Clima: folha, pólen, chuva, neve (partícula por estação) | 18 | falta | ~0–10 (desenho no workbench, grátis) |
| Poeira de obra, faíscas (escavadeira/forja), fumaça de chaminé, explosão, brilho da onda solar | 18 | falta | ~30 |
| Luzes (janelas, forja, tochas, cabine, giroflex) | 19 | **código**: 1 ponto por arte, anotado na importação | 0 |

## 11. Interface

| Item | Prompt | Status | Gerações |
|---|---|---|---|
| Ícones de recurso: créditos, minério, madeira, comida, 5 minérios, pontos de pesquisa | 21 | falta | ~25 |
| Ícones de necessidade/status: fome, sono, ânimo, raiva, curativo, frio (sem casaco), greve, cozinheiro, bilhete, cadeado | 21 | falta | ~25 |
| Ícones de pesquisa (11: carrinhos, explosivos, escoramento, trajes, medicina, rádio, hidroponia, estudo solar, satélite, holofotes, escudo) | 21 | falta | ~25 |
| Ícones de itens/armas/ferramentas (~12) | 21 | falta | ~25 |
| Cursor(es) | 20 | falta | incluído |
| Painel (moldura 9-slice), botões, chips do HUD, abas; hoje tudo desenhado por código | 20 | falta | ~50 |
| Cartões do menu de construção (miniatura = a própria arte do prédio, reduzida) | 20 | falta | 0 (sai dos prédios) |
| Fonte pixel (hoje: a padrão do Godot) | 22 | falta | ~30 |
| Menus: início, pausa, opções (hoje só texto) | 20 | falta | incluído |

## 12. Enfeite (depois que o jogo roda com a arte nova)

| Item | Prompt | Status | Gerações |
|---|---|---|---|
| Retratos do elenco (18) + criaturas | 23 | falta | ~200 |
| Imagens de evento (achado, onda solar, invasão, greve, morte, marco da vila...) | 24 | falta | ~200 |
| Telas: título, carregando, vitória ("VITÓRIA"), derrota ("EXPULSO DA VILA") | 26 | falta | ~160 |

---

## Pendências

- Nenhuma do Prompt 3: o casaco por função ficou completo (os 18, 2026-09-30).

## Plano de crédito

**Atualização 2026-09-30 (fim do Prompt 13):** saldo do ciclo **1.758** (recarga de +5.000 em
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
