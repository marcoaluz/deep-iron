import os
from doc_base import *  # noqa: F401,F403
from PIL import Image, ImageDraw, ImageFont

SP = os.path.dirname(os.path.abspath(__file__))


def _fonte(t):
    for f in ("C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, t)
    return ImageFont.load_default()


from doc_esboco import esboco_layout  # (o esboço do layout fica num arquivo à parte)


def parte2():
    H("PARTE 2 — ANÁLISE E SUGESTÕES", 1, nova_pagina=True)
    P("A partir daqui é a minha análise: o que o DEEP IRON já tem de forte, o que falta e um caminho para cada "
      "assunto que você pediu. No fim há um roteiro com a ordem que eu sugiro.", italico=True, cor=CINZA)

    # ------------------------------------------------------------------ 19
    H("19. O estilo do nosso jogo", 1)
    P("**Identidade.** DEEP IRON é um **gerenciador de colônia sombrio e aconchegante ao mesmo tempo**: o mundo é "
      "duro (sol que mata, criaturas à noite, inverno, acidentes), mas os ipezinhos são pequenos, têm nome, comem "
      "juntos, conversam na hora social, vão à missa e são enterrados com lápide. Esse contraste — **mundo hostil, "
      "gente que cuida um do outro** — é o coração do jogo e deve guiar cada decisão nova.")
    T(["Pilar", "Como já aparece", "Como reforçar"], [
        ["Sobreviver à noite", "Invasões a cada 2 noites, guardas, barricada, luzes que atraem Lumívoros", "Mais variedade de noite (eventos), som de tensão crescente"],
        ["Crescer para BAIXO", "Mina vertical S1–S5, cada andar com perigo, traje e criatura próprios", "Missões por andar, 'primeira descida' com cena curta"],
        ["Cuidar da gente", "Fome com 3 refeições, ânimo, zanga, ferimentos, luto, funeral, igreja", "Personalidade, amizades, pedidos dos ipezinhos"],
        ["Controle indireto", "Funções, áreas de trabalho, encomendas, agenda", "Prioridades secundárias e IA que explica o que está fazendo"],
        ["Rumo ao escudo", "Escavadeira → andares → pesquisa → escudo = vitória", "Capítulos com objetivos claros e epílogo"],
    ], [3.3, 7, 6.7])
    P("**Referências que combinam:** Frostpunk (pressão, escolhas morais, HUD de ferro), RimWorld (gente com "
      "necessidades e histórias), Banished/Timberborn (economia de cadeia), Dwarf Fortress (descer na terra), "
      "Against the Storm (ciclos de perigo). O DEEP IRON já tem um pouco de cada — o diferencial é a **vertical da "
      "mina com o sol como inimigo**.")
    P("**Ponto forte da arte:** o PixelLab deu um estilo coeso (contorno escuro de 1 px, paleta suja, luz de cima "
      "à esquerda). A regra 11 do projeto garante que tudo novo siga esse nível.")

    # ------------------------------------------------------------------ 20
    H("20. Diagnóstico: o que está bom e o que falta", 1)
    T(["Área", "Hoje", "Falta", "Prioridade"], [
        ["Sistemas", "Muito profundos (agenda, fome, ânimo, ferimentos, produção, pesquisa, mina, calendário)", "Ligar os sistemas a objetivos", "—"],
        ["Começo do jogo", "Fundação direta, sem explicação", "Cena inicial + primeiro dia guiado (tutorial, Bloco 66)", "ALTA"],
        ["Objetivos", "Só o escudo no fim; o diário mostra descobertas", "MISSÕES por capítulo + pedidos da vila", "ALTA"],
        ["Itens", "Pregos, ferragem e AÇO são feitos mas NÃO servem para nada (só vender)", "Dar uso (construções, ferramentas, casas)", "ALTA (barato)"],
        ["Dificuldade", "Uma só, sem opções de partida", "Tela de nova partida com níveis", "ALTA"],
        ["Interface", "Muita coisa aberta ao mesmo tempo; textos cortados; rótulos grandes no mapa", "Layout v2 (seção 27)", "ALTA"],
        ["Som", "Base técnica boa; só 2 músicas e 5 ambiências", "Música por camadas, ambiência por andar, sons dos prédios", "MÉDIA"],
        ["Ipezinhos", "Agem bem, mas são todos iguais", "Habilidades, traços, amizades, prioridades secundárias", "MÉDIA"],
        ["Conteúdo", "Escola 'em breve'; sem comércio; poucos eventos", "Crianças, caravana, eventos com escolha", "MÉDIA"],
        ["Fim de jogo", "Vitória ao terminar o escudo", "Epílogo, estatísticas da partida, modo infinito depois", "BAIXA"],
    ], [2.4, 5.2, 6.4, 3], tam=8.5)

    # ------------------------------------------------------------------ 21
    H("21. Missões: como montar", 1)
    P("Proposta em **três camadas**, todas usando sistemas que já existem:")
    B(["**Campanha em capítulos** — ligada aos estágios da vila e aos andares; dá a direção da partida.",
       "**Pedidos da vila** — pequenos desejos dos ipezinhos (com nome e retrato), que aparecem no diário e dão "
       "ânimo/recompensa quando cumpridos. Dão vida e ensinam sistemas.",
       "**Eventos com escolha** — cartões com ilustração (já existem 11 ilustrações de evento) e 2 ou 3 opções, "
       "cada uma com custo e consequência (estilo Frostpunk)."])
    H("21.1 A campanha (exemplo completo)", 2)
    T(["Capítulo", "Objetivos", "Recompensa"], [
        ["1. Cinzas (Acampamento)", "Fundar a vila • 3 casas e a cozinha • 100 de minério no armazém • sobreviver à 1ª invasão (dia 3)", "150 cr; página do diário; libera o capítulo 2"],
        ["2. Fogo e ferro (Vilarejo)", "Expandir para Vilarejo • fornalha + 10 barras de ferro • arsenal + 2 lanças • igreja e um padre", "Um colono; decoração 'lampião'"],
        ["3. O poço", "Laboratório • pesquisar Carrinhos • montar as 5 peças da escavadeira • abrir o S2 • 1 ventilador", "Peças raras; música nova do S2"],
        ["4. O abismo", "Pesquisar Trajes • consertar a plataforma • 50 de solarita • derrotar a Matriarca", "Lingotes solares; título 'Vila que não dorme'"],
        ["5. Água e fogo", "Bombas d'água • abrir S4 e S5 • 10 gemas azuis • Vila Mineira", "Monumento (decoração única)"],
        ["6. O escudo", "Estudo da explosão • Projeto do escudo • as 4 etapas", "VITÓRIA + epílogo + estatísticas"],
    ], [3.5, 9, 4.5])
    H("21.2 Pedidos da vila (exemplos)", 2)
    B(["'Quero um banco perto de casa' (Dora) → +ânimo para ela por 2 dias.",
       "'Ninguém passou fome por 3 dias' → festa de graça.",
       "'Casaco para todos antes do inverno' → inverno sem −3.",
       "'Enterrar com dignidade' → cemitério + Ritos fúnebres.",
       "'3 guardas com 100% de treino' → besta grátis.",
       "'Caminho de pedra da vila até a mina' → +ânimo dos mineradores.",
       "'Festival das Lanternas com 5 lampiões na praça' → festival rende o dobro.",
       "'Vender 20 barras para a caravana' (quando houver comércio)."])
    H("21.3 Como implementar (no padrão do projeto)", 2)
    B(["**Dados**: um recurso `missao.gd` (id, título, texto, capítulo, objetivos [tipo, alvo, quantidade], "
       "recompensa, pré-requisitos) e um arquivo `.tres` por missão em `data/missoes/` — igual aos níveis da mina.",
       "**Gerenciador** `missoes.gd` (nó na cena, grupo \"missoes\"): escuta os sinais que já existem (minério vendido, "
       "pesquisa pronta, obra pronta, morte, fim de invasão, estágio novo) e confere os contadores a cada segundo.",
       "**Interface**: janela 'Missões' (`hud._add_panel`, tecla própria) + um **rastreador** pequeno no canto "
       "direito com o capítulo atual e 3 caixinhas de objetivo.",
       "**Save**: chave \"missoes\" no save_manager (progresso de cada uma); save antigo começa no capítulo certo "
       "conferindo o que já foi feito.",
       "**Teste**: um Bloco com teste próprio para cada etapa (sistema + capítulo 1; depois os outros)."])

    # ------------------------------------------------------------------ 22
    H("22. Cena inicial: como montar", 1)
    H("22.1 Roteiro sugerido (cerca de 60 segundos, dá para pular)", 2)
    T(["#", "Quadro", "Texto na tela / som"], [
        ["1", "Céu alaranjado; o sol pulsa e explode em luz branca", "'No ano em que o sol gritou...' — zumbido crescendo"],
        ["2", "Cidade coberta de cinza, fios caídos, rádio chiando", "'...as cidades se calaram.' — rádio: '...alguém na escuta...'"],
        ["3", "Uma pequena caravana de ipezinhos com carroça na floresta morta", "Passos, rodas, vento"],
        ["4", "A pedreira abandonada: o coletor em ruína, a capela velha, a boca da mina", "'Debaixo da terra o sol não alcança.'"],
        ["5", "A câmera desce pelas camadas da mina (o mapa do mundo, F2)", "Ecos, gotejar, um ronco de lava lá no fundo"],
        ["6", "A primeira fogueira; todos olhando a mina. Título DEEP IRON", "Tema principal (violão + percussão de metal)"],
        ["7", "Corte para o jogo: a fundação (escolher o Centro da Vila)", "A voz do capataz começa o tutorial"],
    ], [0.8, 8.2, 8])
    H("22.2 Duas formas de fazer", 2)
    T(["", "A) Ilustrações (estilo 'história em quadros')", "B) No próprio motor (câmera roteirizada)"], [
        ["Como", "7 ilustrações 640x360 no PixelLab (mesmo estilo dos cartões de evento) + movimento lento de câmera e fades", "O mapa de verdade: a câmera passa pela floresta, pela vila e desce pelo corte da mina, com Tweens"],
        ["Prós", "Mais cinematográfico; conta o que aconteceu ANTES do jogo", "Barato; mostra a arte real; serve também de 'apresentação' do mapa"],
        ["Contras", "Custo de arte (~7 imagens + variações)", "Não mostra a explosão nem a cidade"],
        ["Godot", "Cena `scenes/ui/intro.tscn` entre o menu e a partida: TextureRect + AnimationPlayer + Label com texto letra a letra + AudioStreamPlayer; Esc/Espaço pula; 'ver de novo' no menu; flag 'intro vista' nas configurações", "Um script de câmera com uma lista de pontos e tempos (Tween) rodando na main.tscn antes da fundação; mesmos controles de pular"],
    ], [1.8, 7.6, 7.6], tam=8.5)
    P("**Minha sugestão:** juntar as duas — quadros 1 a 3 com ilustração (o passado) e 4 a 7 no motor (o presente) — "
      "e emendar direto no **primeiro dia guiado**: o capataz pede, em ordem, para fundar o Centro, dar funções, "
      "erguer as casas e se preparar para a primeira noite. Esse tutorial vira o **Capítulo 1** das missões.")

    # ------------------------------------------------------------------ 23
    H("23. Som e música", 1)
    H("23.1 O que existe hoje", 2)
    B(["Barramentos **Master / Música / Ambiente / Efeitos**, com limitador no Master e volumes nas configurações.",
       "**2 músicas**: a calma e a de perigo (troca suave de 2,5 s quando começa a invasão).",
       "**5 ambiências**: superfície de dia, superfície à noite, caverna, fundo da mina e chuva.",
       "**~45 efeitos** (picareta, passos, machado, forja, alarme, sino, multidão...), com variação de tom (±8%) e "
       "limite de vozes iguais (15 mineradores não viram um muro de som)."])
    P("A base técnica é boa. O que falta é **conteúdo** e **reação ao jogo**.")
    H("23.2 O que melhorar (em ordem)", 2)
    T(["#", "Melhoria", "Detalhe"], [
        ["1", "Ambiência por andar", "S2: bolhas de ácido e gotejar • S3: lava borbulhando e ronco grave • S4: cachoeira forte • S5: lago calmo com eco • floresta: pássaros de dia e grilos à noite • vento no inverno"],
        ["2", "Sons dos prédios (em loop, no lugar)", "Fornalha (fogo e fole), taverna (conversa e viola), igreja (sino na missa e no funeral), cemitério (vento, corvo), vagonete (rodas no trilho), coletor (serra)"],
        ["3", "Momentos marcantes ('stingers')", "Amanhecer, onda solar chegando, estágio novo, pesquisa pronta, morte, vitória, derrota, missão cumprida"],
        ["4", "Música em camadas", "Base + percussão que entra com o perigo + melodia de dia + 'pad' à noite; variação por estação; tema do menu, da vitória e da derrota"],
        ["5", "Voz dos ipezinhos", "Murmúrios curtos ('Opa!', 'Ai!', resmungo, risada) ao receber ordem, se machucar, protestar, festejar; conversa baixinha na hora social"],
        ["6", "Passos por chão", "Terra, cascalho e pedra (os caminhos), madeira (passarelas), água (S4)"],
        ["7", "Interface", "Barramento UI separado; sons próprios para abrir janela, confirmar, erro, notícia boa e ruim"],
        ["8", "Mixagem", "Abaixar a música 6 a 10 dB quando tocam alarme, sino ou aviso (ducking); volume alvo por volta de −16 LUFS; ouvir em fone e em caixa"],
    ], [0.7, 4, 12.3], tam=8.5)
    B(["**Godot 4.7 já tem o que precisa**: `AudioStreamSynchronized` (camadas que tocam juntas, para a música por "
       "intensidade) e `AudioStreamInteractive` (troca de trechos no tempo certo).",
       "**Onde arrumar os sons**: bibliotecas gratuitas (Freesound CC0, o pacote anual de sons da GDC/Sonniss), gravar "
       "(metal, madeira, passos), ou gerar música com IA (Suno/Udio — conferir a licença de uso comercial).",
       "**Estilo musical sugerido**: folk sombrio + industrial — violão de aço, sanfona, percussão de metal (bigorna, "
       "correntes), drones graves; no fundo da mina, mais drone e menos melodia."])

    # ------------------------------------------------------------------ 24
    H("24. Novas estruturas e personagens", 1)
    H("24.1 Primeiro: dar uso ao que já se fabrica (barato e importante)", 2)
    B(["**Pregos e ferragem** → uma **Carpintaria** (carpinteiro: madeira + pregos = tábuas e móveis); casa nível 3, "
       "barricada nível 3 e a ferrovia pedem ferragem.",
       "**Aço** → picareta de aço de verdade (hoje usa cobre), lança de prata pede aço, as bobinas do escudo pedem aço.",
       "**Couro** → além do casaco: botas (andar na neve), mochila (+carga)."])
    H("24.2 Estruturas novas", 2)
    T(["Estrutura", "Para quê", "Mecânica nova"], [
        ["Escola + crianças", "A vila cresce sozinha; aprendizes", "Nascimento, infância, aprender uma função (Bloco 65)"],
        ["Posto de troca + caravana", "Comprar o que falta, vender gemas e barras", "Comércio com preços que variam; caravana a cada 2 semanas"],
        ["Torre de vigia", "Ver a invasão chegando; besteiro no alto", "Defesa em altura; aviso mais cedo"],
        ["Despensa / defumadouro", "Guardar comida; carne defumada dura mais", "Comida que estraga no verão"],
        ["Estufa", "Comida no inverno", "Horta coberta (o inverno corta a horta pela metade)"],
        ["Abrigo solar", "Proteger na onda forte", "Ondas fortes no fim do jogo pedem abrigo perto do trabalho"],
        ["Poço d'água", "Água para cozinha e hidroponia", "Nova cadeia simples (sem virar mais uma barra de fome)"],
        ["Biblioteca", "Pesquisa mais rápida; histórias no diário", "Lazer intelectual"],
        ["Estábulo de mulas", "Carga entre andares", "Animal de trabalho"],
        ["Monumento / memorial", "Lembrar os mortos; ânimo duradouro", "Recompensa de capítulo"],
    ], [3.6, 5.6, 7.8], tam=8.5)
    H("24.3 Personagens / funções novas", 2)
    T(["Personagem", "O que faz"], [
        ["Carpinteiro(a)", "Carpintaria: tábuas, móveis, camas melhores (usa pregos e ferragem)"],
        ["Agricultor(a)", "Cuida da horta e da estufa (hoje quem colhe é o cozinheiro/caçador)"],
        ["Carregador(a)", "Leva carga entre armazéns e andares (alivia os mineradores)"],
        ["Batedor(a)", "Explora o leste e as ruínas: acha peças raras, mapas, sobreviventes"],
        ["Mecânico(a)", "Conserta robôs, a escavadeira e o trilho"],
        ["Bardo / músico", "Toca na taverna e nos festivais (+ânimo, e som de verdade no jogo)"],
        ["Comerciante (visitante)", "Chega com a caravana; tem retrato e falas"],
        ["Criança / aprendiz", "Cresce na vila; aprende a função de quem acompanha"],
    ], [4, 13])
    H("24.4 Criaturas e eventos novos", 2)
    B(["**Rato-de-cinza**: invasão pequena que rouba COMIDA do armazém (pressão na cadeia de comida).",
       "**Morcego de brasa** (S3): apaga lampiões e tochas da mina.",
       "**Sombra solar**: só nas ondas fortes do fim do jogo.",
       "**Eventos**: refugiados pedindo abrigo (aceitar = mais gente e mais bocas), tempestade de poeira, desabamento "
       "numa galeria, febre na vila, casamento (festa), achado de um mapa antigo."])

    # ------------------------------------------------------------------ 25
    H("25. Dificuldade", 1)
    P("**Hoje** há uma dificuldade só. A pressão vem de: 3 refeições por dia, invasão a cada 2 noites desde o "
      "dia 3, onda solar 50% no verão, greve com expulsão em 300 s. Para quem está aprendendo, a primeira invasão no "
      "dia 3 (≈ 18 minutos de jogo) chega cedo; para quem já domina, o meio do jogo fica fácil.")
    T(["Ajuste", "Tranquilo", "Normal (hoje)", "Ferro", "Valor no jogo"], [
        ["1ª invasão", "dia 5", "dia 3", "dia 2", "first_invasion_day"],
        ["Invasão a cada", "3 dias", "2 dias", "2 dias", "invasion_every"],
        ["Vida das criaturas por onda", "+8%", "+15%", "+22%", "hp_growth"],
        ["Fome", "x0,8", "x1,0", "x1,2", "hunger_decay"],
        ["Onda solar (verão)", "30%", "50%", "65%", "season_wave_chance"],
        ["Ultimato da greve", "480 s", "300 s", "200 s", "strike_ultimatum"],
        ["Comida inicial", "100", "60", "40", "start_food"],
        ["Preço de venda", "x1,2", "x1,0", "x0,85", "ore_price..."],
    ], [4, 2.5, 2.8, 2.3, 5.4], tam=8.5)
    B(["**Tela de nova partida** com Tranquilo / Normal / Ferro / Personalizado e um **modo criativo** (sem invasão, "
       "recursos à vontade) para quem só quer construir.",
       "**Diretor adaptativo** (opcional): se a vila perdeu gente na última invasão, a próxima vem mais leve; se "
       "passou sem arranhão, um pouco mais forte.",
       "**Comunicar a pressão**: o tier das criaturas sobe também com as PESQUISAS feitas — vale mostrar isso na "
       "janela da Defesa, senão parece injusto.",
       "**Implementação**: um recurso `dificuldade.tres` com os multiplicadores, escolhido na nova partida e salvo no "
       "save (save antigo = Normal). Medir com a telemetria (tempo até cada estágio, mortes por causa, fome média, greves)."])

    # ------------------------------------------------------------------ 26
    H("26. A inteligência dos ipezinhos", 1)
    H("26.1 Como funciona hoje", 2)
    B(["Uma máquina de estados com **prioridades fixas**: emergência → agenda → necessidades → função.",
       "Cada um reavalia **a cada 1 segundo** (com sorteio para não decidirem todos juntos).",
       "Estações com **vagas reservadas** (ninguém disputa a mesma jazida), filtradas por área de trabalho e por "
       "andar trancado; navegação com desvio entre eles.",
       "Termina a entrega antes de mudar de estado; o engenheiro tem um 'vigia' que procura outro caminho se emperra.",
       "**Agenda** dá muita vida: café, almoço, hora social com conversa, missa, dormir."])
    P("**Avaliação:** a IA é **previsível e robusta** (bem testada), o que é ótimo para um jogo de gerenciamento. "
      "O que falta é **personalidade e esperteza nas escolhas**.")
    H("26.2 O que melhorar", 2)
    T(["Problema", "Sugestão", "Ganho"], [
        ["Escolhe a estação mais perto/livre", "Pontuar as opções (distância + quanto tem + fila + o que está FALTANDO no armazém + perigo)", "Mineram o que a vila precisa"],
        ["Função sem trabalho = parado", "Funções SECUNDÁRIAS por ipezinho (ex.: engenheiro sem obra vira lenhador)", "Menos ociosos, menos micro"],
        ["Todos iguais", "Habilidade que sobe com a prática + 1 ou 2 traços (valente, guloso, devoto, preguiçoso...)", "Histórias e decisões ('quem eu mando pro abismo?')"],
        ["Hora social sem memória", "Amizades: quem conversa vira amigo; conversar com amigo anima mais; luto maior pelo amigo", "Laços e drama"],
        ["Logística simples", "Combinar viagens (quem volta vazio leva algo), função Carregador", "Menos idas e vindas"],
        ["Perigo", "Na invasão, quem está fora corre para casa mais cedo e evita criaturas; na onda, o abrigo mais perto", "Menos mortes 'bobas'"],
        ["Não explica o que faz", "Ícone/balão com o motivo: 'sem trabalho', 'sem ferramenta', 'armazém cheio', 'caminho bloqueado'", "O jogador entende e corrige"],
    ], [4.2, 8.3, 4.5], tam=8.5)

    # ------------------------------------------------------------------ 27
    H("27. Layout e interface: sugestões", 1)
    P("Olhando as telas do jogo hoje, a interface **mostra tudo ao mesmo tempo** e sobra pouco espaço para o mapa — "
      "que é a parte mais bonita do jogo.")
    IMG(r"bloco92\barra_padre.png", 15.5, "A tela hoje: lista à esquerda, coluna de construções à direita, barra de funções embaixo.")
    T(["#", "Onde", "Problema", "Sugestão"], [
        ["1", "Força de trabalho (esquerda)", "Ocupa ~25% da largura o tempo todo", "Vira uma aba fina com ícones; a lista abre com Tab ou ao passar o mouse; mostra primeiro os OCIOSOS e os COM PROBLEMA"],
        ["2", "Construções (direita)", "15 botões de texto, muitos cortados ('Coletor (ruína): etapa 0 ...'); repete o menu Construir", "Trocar por uma coluna de ALERTAS com ícone e número (sem comida, obra parada, ferido, invasão às 21h); os prédios abrem clicando no mapa"],
        ["3", "Barra de funções", "14 botões; o cartão do selecionado cobre o 'Construir'", "Agrupar: Produção | Serviço | Defesa; botões só com ícone + contador (o nome na dica); mostrar só as funções já liberadas"],
        ["4", "Cartão do selecionado", "Cobre a barra", "Acima da barra, à esquerda, com retrato e o que está fazendo"],
        ["5", "Barra de cima", "Muito cheia; 'Vender' e 'auto' no meio dos recursos", "Levar 'Vender' e 'auto' para a janela do Armazém; hora grande no centro"],
        ["6", "Rótulos no mapa", "'Centro da Vila / Acampamento' e 'Cozinha 60/120' grandes, cobrindo a arte", "Só o nome, menor; detalhes ao passar o mouse ou selecionar"],
        ["7", "Obras no mapa", "'45% — esperando engenheiro' em texto grande", "Barrinha de progresso + ícone (martelo cinza = esperando engenheiro)"],
        ["8", "Avisos", "Faixas e toasts no meio da tela", "Pilha de avisos num canto, com ícone; clicar leva até o lugar"],
        ["9", "Escala", "Tudo fixo para 1280x720", "Escala da interface nas configurações (90% / 100% / 125%)"],
        ["10", "Missões", "Não existe", "Rastreador pequeno no canto direito (capítulo + 3 objetivos)"],
    ], [0.7, 3.2, 5.8, 7.3], tam=8.5)
    IMG(esboco_layout(), 15.5, "Esboço: a tela de hoje (em cima) x a proposta (embaixo) — mais mapa, menos texto fixo.")

    # ------------------------------------------------------------------ 28
    H("28. Roteiro sugerido (próximos Blocos)", 1)
    T(["Bloco", "O quê", "Por quê"], [
        ["b94", "Dar uso a pregos, ferragem, aço e couro (+ Carpintaria e carpinteiro)", "Fecha a cadeia de produção que já existe"],
        ["b95", "Tela de nova partida: dificuldade (Tranquilo/Normal/Ferro/Personalizado/Criativo)", "Abre o jogo para mais gente"],
        ["b96", "Sistema de missões + Capítulo 1", "Dá direção e ensina"],
        ["b97", "Cena inicial + primeiro dia guiado (tutorial, Bloco 66)", "Primeira impressão"],
        ["b98", "Layout v2 (painéis recolhíveis, alertas, barra agrupada, rótulos menores)", "Mais mapa, menos texto"],
        ["b99", "Som: ambiência por andar, sons dos prédios, sinos, stingers", "Imersão"],
        ["b100", "Música em camadas + temas (menu, vitória, derrota)", "Emoção"],
        ["b101", "IA: funções secundárias + escolha por pontuação + balões com o motivo", "Menos micro, mais clareza"],
        ["b102", "Habilidades, traços e amizades", "Histórias"],
        ["b103", "Capítulos 2 a 6 + pedidos da vila + eventos com escolha", "Partida completa"],
        ["b104", "Caravana e posto de troca", "Economia viva"],
        ["b105", "Crianças e escola (Bloco 65)", "A vila cresce sozinha"],
    ], [1.6, 9.4, 6])
    P("Cada Bloco seguindo as regras do projeto: teste próprio, save compatível, arte do PixelLab no nível do jogo "
      "e a evolução da obra em toda estrutura nova.", italico=True, cor=CINZA)
