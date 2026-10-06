from doc_base import *  # noqa: F401,F403


def parte1():
    # ------------------------------------------------------------------ capa
    for _ in range(6):
        doc.add_paragraph()
    P("DEEP IRON", cor=FERRUGEM, tam=40, alinhar="centro")
    P("Guia completo do jogo e análise de design", cor=CARVAO, tam=18, alinhar="centro")
    doc.add_paragraph()
    P("Todas as mecânicas, funções e construções, com os números de verdade do jogo — "
      "e uma análise do que já está bom, do que falta e de como melhorar.", italico=True, cor=CINZA, tam=11, alinhar="centro")
    for _ in range(8):
        doc.add_paragraph()
    P("Versão do jogo: branch isometrico, até o Bloco 93 (cemitério)  •  6 de outubro de 2026", cor=CINZA, tam=9, alinhar="centro")
    P("Os números saem do próprio código (os valores de balanceamento, docs/BALANCEAMENTO.md). "
      "Quando um valor mudar no jogo, este documento pode ser gerado de novo.", cor=CINZA, tam=9, alinhar="centro")
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
    H("Sumário", 1)
    SUMARIO()

    # ================================================================== PARTE 1
    H("PARTE 1 — O JOGO, PEÇA POR PEÇA", 1, nova_pagina=True)
    P("Esta parte explica cada mecânica como ela está hoje no jogo. Os tempos estão em **horas do relógio do "
      "jogo** e, quando ajuda, em **segundos reais**.")

    # ------------------------------------------------------------------ 1
    H("1. Visão geral", 1)
    P("**DEEP IRON** é um jogo de colônia de mineração depois de uma **explosão solar**. O jogador cuida de uma "
      "pequena vila de mineiros — os **ipezinhos** — numa pedreira: eles cavam, erguem a vila, descem pelos "
      "andares da mina e aguentam as noites de **invasão de criaturas** e as **ondas solares**, até construir o "
      "**escudo solar**, que protege a vila para sempre e encerra a partida com vitória.")
    T(["", "Como é"], [
        ["Gênero", "Colônia / gerenciamento com controle INDIRETO (estilo Frostpunk + RimWorld + Banished)"],
        ["Visão", "Isométrica, pixel art escura e suja (arte do PixelLab), interface de placas de ferro com rebites"],
        ["Controle", "O jogador NÃO anda com ninguém: ele dá a FUNÇÃO de cada ipezinho, marca ÁREAS de trabalho, "
                     "encomenda obras e produção. A IA de cada um decide o resto, seguindo a agenda do dia."],
        ["Vitória", "Terminar as 4 etapas do Escudo solar (vila no estágio 4 ou mais)."],
        ["Derrota", "Ser EXPULSO: greve que dura o ultimato inteiro (300 s) sem o ânimo voltar."],
        ["Mapa", "Superfície (floresta | paliçada | vila | mina com a montanha) e os andares S1 a S5, um embaixo do outro."],
    ], [3.5, 13.5])

    H("1.1 A tela e os controles", 2)
    T(["Tecla", "O quê"], [
        ["Espaço", "Menu CONSTRUIR (cartões por aba)"],
        ["1 / 2 / 3 / 4", "Função: Minerador / Caçador / Médico / Engenheiro"],
        ["C / L / X / Z", "Função: Cozinheiro / Lenhador / Guarda / Pesquisador"],
        ["6 / 7 / 8", "Função: Fundidor / Ferreiro / Padre (só um, só homem)"],
        ["0", "Tirar a função (fica 'sem função')"],
        ["T", "Turno extra (trabalha à noite; dá zanga)"],
        ["5", "Trabalhadores: marcar ÁREAS de trabalho"],
        ["V / R", "Vender minério / Recrutar ipezinho"],
        ["U E O I B G J Q Y", "Janelas: Centro da Vila, Escavadeira, Oficina, Enfermaria, Bem-estar, Defesa, Diário, Laboratório, O Sol"],
        ["Tab / F / P / H / M", "Próximo ipezinho / câmera segue / pausa / atalhos / música"],
        ["F2 / F11 / F5 / F9", "Corte da mina (mapa do mundo) / tela cheia / salvar / carregar"],
        ["WASD, setas, roda", "Câmera"],
        ["Botão direito", "Ordem manual: mover / minerar a jazida clicada"],
    ], [4, 13])
    P("As teclas podem ser trocadas em Configurações > Teclas. A velocidade do jogo tem pausa, 1x, 2x, 4x e "
      "**Pular dia** (avança até o próximo amanhecer, parando sozinho em emergência).")

    # ------------------------------------------------------------------ 2
    H("2. O tempo: dia, noite, semana e estações", 1)
    P("O relógio do jogo tem **24 horas**. Um dia inteiro dura **9 minutos reais** — então **1 hora de jogo = "
      "22,5 segundos**. O dia do jogo vira às 05:00.")
    T(["Hora", "Marco", "O que acontece"], [
        ["04:00", "Cozinheiro acorda", "Começa a preparar o café"],
        ["05:00", "AMANHECER", "Todos acordam; café até 07:00. Criaturas fogem / desligam"],
        ["07:00 – 12:00", "Trabalho", "Cada um na sua função"],
        ["08:00 – 16:00", "Janela das ondas solares", "Se houver onda no dia, ela cai numa hora sorteada aqui"],
        ["12:00 – 13:00", "Almoço", "Uma porção para cada um (se estiver com fome)"],
        ["13:00 – 18:00", "Trabalho", "O cozinheiro, a partir das 16:00, prepara o jantar"],
        ["18:00", "Fim do expediente", "'Voltar': quem tem carga termina a entrega"],
        ["18:30", "ANOITECER", "Jantar e HORA SOCIAL (rodas de conversa) até 21:30"],
        ["21:00", "Aviso de invasão", "Só nas noites de invasão (o rádio adianta o aviso)"],
        ["21:30", "Dormir", "Cada um vai para a sua cama"],
        ["22:00 – 05:00", "INVASÃO", "Nas noites de invasão: as criaturas chegam e lutam até o amanhecer"],
    ], [3, 4, 10])
    B(["**Expediente:** 05:00–18:00 = 13 horas = cerca de 4 min 52 s reais.",
       "**Noite:** 18:30–05:00 = 10,5 horas = cerca de 3 min 56 s reais.",
       "**Semana:** 7 dias; o 7º dia é **domingo** (missa de manhã e escolha da tarde).",
       "**Estações:** primavera, verão, outono e inverno, cada uma com **2 semanas (14 dias)**. Um ano = 56 dias "
       "= cerca de 8 horas e meia de jogo real.",
       "A luz muda com a hora e com a estação (verão quente, outono dourado, inverno azulado e noites mais escuras). "
       "As tochas acendem sozinhas ao escurecer."])
    H("2.1 Clima por estação", 2)
    T(["Estação", "Chuva (chance por dia)", "Horta rende", "Fome", "Onda solar (chance por dia)", "Outros"], [
        ["Primavera", "50%", "x1,3", "normal", "25%", "Flores; chove muito"],
        ["Verão", "10%", "x1,0", "normal", "50% (a pior)", "Pólen no ar"],
        ["Outono", "35%", "x0,8", "normal", "25%", "Folhas caindo"],
        ["Inverno", "0%", "x0,5", "x1,25 (mais fome)", "12%", "Neve, geada; −3 de ânimo; sem casaco o trabalho rende 45% menos"],
    ], [2.4, 2.8, 2, 2.3, 3, 4.5])

    # ------------------------------------------------------------------ 3
    H("3. A agenda do ipezinho", 1)
    P("Cada ipezinho decide o que fazer a cada segundo, nesta ordem de prioridade:")
    B(["**1. Emergência** — caído, ferido, sendo resgatado, onda solar, invasão, greve.",
       "**2. Agenda do dia** — café, almoço, voltar, hora social, dormir, missa de domingo.",
       "**3. Necessidades** — comer com fome braba (fora de hora), ir à taverna quando está triste.",
       "**4. Função** — o trabalho dele (minerar, cozinhar, construir...)."], numerada=False)
    T(["Quem", "Exceção na agenda"], [
        ["Cozinheiro", "Começa às 04:00 (prepara o café) e das 16:00 ao anoitecer prepara o jantar (não tem o 'voltar')."],
        ["Médico", "Fica de PLANTÃO o tempo todo; come em turnos de meia hora (o 2º médico come depois do 1º)."],
        ["Guarda", "Noite comum: metade dos guardas fica de vigia (gira todo dia, pelo menos 1). Noite de invasão: TODOS."],
        ["Padre", "Fica na igreja (aconselhando); busca os mortos e enterra no cemitério; prega na missa e no funeral."],
        ["Turno extra (T)", "Trabalha também à noite — mas ganha ZANGA (ver seção 6)."],
    ], [3, 14])

    # ------------------------------------------------------------------ 4
    H("4. Fome e comida", 1)
    P("A fome vai de **0 a 100** (100 = satisfeito). Ela cai **0,2 por segundo real** = **4,5 por hora de jogo**. "
      "Dormindo, cai só 20% disso. No inverno, 25% mais rápido.")
    T(["Regra", "Valor", "O que significa"], [
        ["Refeições por dia", "3 (café, almoço, jantar)", "Cada uma gasta UMA porção do comedouro"],
        ["Porção", "8 de comida", "Tirada do comedouro (a cozinha)"],
        ["Cada refeição repõe", "45 de fome", ""],
        ["Pula a refeição se", "fome acima de 90", "Sem fome: não conta como refeição perdida"],
        ["Fome braba", "abaixo de 30", "Come FORA de hora (uma porção)"],
        ["Refeição perdida", "−12% de trabalho cada", "Até 3 seguidas (−36%). Some quando ele come"],
        ["Fome zero", "anda na metade da velocidade", ""],
        ["Gasto por dia (acordado + dormindo)", "≈ 81 de fome", "No inverno ≈ 101"],
    ], [5, 4, 8])
    H("4.1 De onde vem a comida (a cadeia)", 2)
    B(["**Horta** (clareira): 150 de comida cheia, volta a crescer 0,35/s (≈ 189 por dia). O cozinheiro colhe 3/s. "
       "Murcha 30% em cada onda solar. A Hidroponia dobra a horta.",
       "**Caçador**: fruta (1 de matéria-prima por unidade) ou, com ARCO, caça nas tocas — coelho (4 de carne) e "
       "javali (12 de carne, pode ferir o caçador novato). Cada unidade de caça vale 2,5 de matéria-prima e dá "
       "0,5 de couro. Os bichos nascem menos no inverno.",
       "**Armazém**: a matéria-prima (comida crua) é guardada lá.",
       "**Cozinheiro**: leva 12 de matéria-prima por viagem para a cozinha, prepara 0,8 s por unidade e "
       "**cada unidade vira 1,25 de comida** (cozinhar rende).",
       "**Cozinha (comedouro)**: guarda até 120 de comida (+60 com Hidroponia); começa com 60."])
    CAIXA("Conta de cabeça", [
        "1 ipezinho come até 3 porções x 8 = **24 de comida por dia** ≈ 19 de matéria-prima.",
        "8 ipezinhos ≈ **190 de comida por dia** — mais que uma cozinha cheia (120). Por isso o cozinheiro "
        "não pode parar e uma 2ª cozinha ajuda quando a vila cresce.",
        "O HUD mostra a comida como 'N (hoje M)': o que tem e quantas refeições ainda faltam hoje."])

    # ------------------------------------------------------------------ 5
    H("5. Sono, casas e recrutamento", 1)
    B(["Cada ipezinho dorme numa **cama**. Casa nível 1 = 4 camas, nível 2 = 6, nível 3 = 8. O nível dá "
       "**conforto** (ânimo de quem mora): 0 / +4 / +8.",
       "Ampliar a casa: nível 2 = 220 cr + 40 ferro + 40 madeira (estágio 2); nível 3 = 420 cr + 90 ferro + 70 madeira "
       "(estágio 3 + pesquisa Medicina).",
       "**Recrutar** custa 150 créditos e fica 50% mais caro a cada recruta; **precisa de cama livre**.",
       "Limite de ipezinhos: 8 no começo; a melhoria **Moradias** do Centro da Vila soma 4 por nível.",
       "Partida nova: **Fundação** — o jogador escolhe onde fica o Centro da Vila; entra um pacote (400 cr, 90 "
       "ferro, 80 madeira) que dá para 3 casas iniciais e uma cozinha."])

    # ------------------------------------------------------------------ 6
    H("6. Ânimo, zanga, greve e luto", 1)
    P("Cada ipezinho tem **ânimo** (felicidade, 0 a 100). Ele anda devagar (0,25/s) em direção a um **alvo**: "
      "60 + a soma dos motivos (a janela do ipezinho mostra a lista).")
    T(["Motivo", "Efeito no alvo"], [
        ["Vila crescendo", "+3 por estágio acima do 1"],
        ["Casa / conforto", "+0, +4, +8 pelo nível da casa; casa enfeitada (decoração perto) até +6"],
        ["Taverna", "+5 (nível 1) / +8 (nível 2); quem está lá dentro ganha 3 a 4,5 por segundo"],
        ["Festa", "+20 na hora para todos e +10 por 240 s (custa 150 cr + 30 de comida)"],
        ["Hora social", "Conversar na roda: até +8 ('conversou com os amigos'), some devagar"],
        ["Missa", "+6 'foi à missa'"],
        ["Funeral digno (pesquisa Ritos fúnebres)", "+5 para a vila por 240 s"],
        ["Rádio da vila (pesquisa)", "+6 o dia todo"],
        ["Parque", "+0,5 por segundo para quem está perto, ao ar livre"],
        ["Robô guarda ativo", "+5"],
        ["Lago azul (S5)", "acalma quem trabalha lá"],
        ["Luto", "−20 por morte (até −40), some em 300 s"],
        ["Inverno", "−3"],
        ["Motor a diesel da escavadeira", "−4 enquanto liga"],
        ["Criaturas dentro da vila", "−10"],
        ["Fome, zanga, sem cama", "pesam no alvo"],
    ], [6, 11])
    T(["Faixa", "Ânimo", "Trabalho rende"], [
        ["Feliz", "75 ou mais", "x1,1"], ["Normal", "40 a 75", "x1,0"],
        ["Triste", "abaixo de 40 (vai à taverna)", "x0,8"], ["Revoltado", "abaixo de 25", "x0,6"]], [4, 6, 7])
    H("6.1 Zanga (turno extra)", 2)
    B(["Trabalhar à noite (turno extra) dá **+0,8 de zanga por segundo** (≈ +48 por noite). Dormindo, ela cai 1,5/s.",
       "**Irritado** (40+): acidentes x2, trabalho x0,8, anda um pouco mais devagar.",
       "**Furioso** (75+): acidentes x4, trabalho x0,55, anda 15% mais devagar.",
       "Na igreja (missa, funeral, hora social) a zanga cai — mais rápido com o padre lá."])
    H("6.2 Greve e expulsão", 2)
    B(["Ânimo médio da vila abaixo de **40**: aviso de insatisfação.",
       "Abaixo de **30 por 60 s**: **GREVE** — param de trabalhar e protestam (batucada).",
       "A greve só acaba quando a média sobe para **45**.",
       "Se a greve durar **300 s** (o ultimato), o jogador é **EXPULSO** — fim de jogo. Aviso final aos 60 s."])

    # ------------------------------------------------------------------ 7
    H("7. Ferimentos, enfermaria e morte", 1)
    T(["Situação", "Regra"], [
        ["Acidente na mina", "4% a cada carga minerada (16 de minério); 20% de ser grave (+30% no S2, +20% no abismo)"],
        ["Queda de galho (lenhador)", "5% a cada carga de madeira (8); x2 à noite; 40% de ser grave"],
        ["Machucado leve sem leito", "vira GRAVE em 150 s"],
        ["Machucado grave sem leito", "MORRE em 75 s (aviso no HUD aos 25 s finais)"],
        ["Enfermaria", "2 leitos (+1 por nível da melhoria); cura no leito: leve 20 s, grave 45 s"],
        ["Médico", "Cada médico lá dentro acelera a cura em +150% (até 2 médicos). Quem espera leito piora na metade da velocidade"],
        ["Guarda caído na luta", "Fica no chão, grave; morre em 150 s sem resgate. O médico vai buscar e carrega"],
        ["Mancando", "anda a 73% da velocidade"],
        ["Pesquisa Medicina", "cura 30% mais rápida; sem leito aguenta 50% mais tempo"],
    ], [5, 12])
    H("7.1 Morte, cemitério e funeral (Bloco 93)", 2)
    B(["Morte: sino fúnebre, **luto** na vila e o nome entra no **memorial** (diário).",
       "**Sem cemitério**: a cruz aparece do lado da enfermaria.",
       "**Com cemitério** (o jogador arrasta o tamanho): o corpo fica onde caiu, envolto na mortalha; o **padre** "
       "vai buscar, leva nos ombros e **enterra** — aparece uma cruz ou lápide com **'Nome · † dia N'**. O "
       "cemitério começa vazio e vai enchendo do fundo para a frente.",
       "**Funeral** (só com a pesquisa **Ritos fúnebres**): na hora social depois do enterro, a vila se junta no "
       "portão do cemitério (ou na igreja, se não houver cemitério), o padre prega, o **luto cai 12** e a vila "
       "ganha **'funeral digno' (+5 por 240 s)**."])

    # ------------------------------------------------------------------ 8
    H("8. As funções", 1)
    P("A função é dada selecionando os ipezinhos e apertando o botão (ou a tecla) na barra de baixo.")
    T(["Função (tecla)", "O que faz", "Onde / precisa de"], [
        ["Minerador (1)", "Minera nas jazidas e leva o minério ao armazém (16 por viagem; 3 por segundo na jazida)", "Jazidas; cobre pede picareta de aço, carvão pede lampião, prata pede broca"],
        ["Caçador (2)", "Colhe fruta na horta ou caça nas tocas (com arco); leva matéria-prima e couro ao armazém", "Clareira (floresta)"],
        ["Médico (3)", "Plantão na enfermaria (cura +150%); resgata guarda caído", "Enfermaria"],
        ["Engenheiro (4)", "Constrói TODAS as obras encomendadas (prédios, casas, melhorias, peças, consertos)", "Sem engenheiro, nenhuma obra anda"],
        ["Cozinheiro (C)", "Busca matéria-prima no armazém e cozinha na cozinha (rende 1,25)", "Cozinha"],
        ["Lenhador (L)", "Corta árvores (1,5/s; 8 por viagem) e leva madeira ao armazém", "Floresta"],
        ["Guarda (X)", "Treina de dia no campo; à noite fica nos postos e luta nas invasões", "Arma do Arsenal; campo de treino"],
        ["Pesquisador (Z)", "Gera 1 ponto de pesquisa por segundo no laboratório (de dia)", "Laboratório"],
        ["Fundidor (6)", "Opera a FORNALHA: busca minério e carvão, funde as barras encomendadas", "Fornalha; só com ordem do jogador"],
        ["Ferreiro (7)", "Opera a OFICINA e o ARSENAL: ferramentas, armas, equipamentos, pregos e ferragens encomendados", "Homem ou mulher"],
        ["Padre (8)", "Igreja: missa, funeral, aconselhamento; busca e enterra os mortos", "UM só, só homem; estágio 2"],
        ["Sem função (0)", "Espera no Centro da Vila", ""],
        ["Turno extra (T)", "Liga/desliga o trabalho noturno (zanga)", ""],
    ], [3.3, 8.2, 5.5])
    P("**Áreas de trabalho (tecla 5):** em vez de deixar a IA escolher, o jogador marca um retângulo no mapa "
      "(madeira, alimentos, mina) e diz quantos trabalham lá (até 5 postos por área).")

    # ------------------------------------------------------------------ 9
    H("9. Recursos e itens", 1)
    T(["Recurso", "Tipo", "Venda (cr/un.)", "De onde vem"], [
        ["Ferro", "minério", "2", "S1 (a pedra de base; também serve de 'pedra' nas obras)"],
        ["Carvão", "minério", "3", "S1 (pede lampião); combustível da fornalha e da caldeira"],
        ["Cobre", "minério", "4", "S1 (pede picareta de aço), S2"],
        ["Prata", "minério", "8", "S2, S3 (pede broca)"],
        ["Cristal verde", "minério", "10", "S2; Gosma ácida às vezes deixa"],
        ["Solarita", "minério", "14", "S3, S4 (abismo; pede traje)"],
        ["Cristal rubro", "minério", "18", "S3, S4; o Magmante às vezes deixa"],
        ["Gema azul", "minério", "30", "S5 (lago azul)"],
        ["Barras (ferro, cobre, prata), lingote solar, aço", "metal", "por item", "Fornalha"],
        ["Pregos, ferragem", "peças", "por item", "Ferreiro (Oficina)"],
        ["Madeira", "madeira", "não vende", "Lenhador, coletor de madeira"],
        ["Comida crua", "comida", "não vende", "Caçador (fruta, caça), horta"],
        ["Couro", "peças", "não vende", "Caça (0,5 por unidade)"],
        ["Peças raras", "peças", "não vende", "Achados na mina; chefe"],
    ], [4.5, 2, 2.5, 8])
    B(["A janela do **Armazém** mostra tudo em grade por categoria; dá para vender **a quantidade escolhida** "
       "(−10/−1/+1/+10/Tudo) ou a categoria inteira.",
       "A partir do estágio 2 (quando a fornalha libera), os custos de metal (armas, peças da escavadeira, "
       "reatores, laboratório, coletores, ampliação das barricadas) pedem **barras**: 1 barra vale 2 minérios.",
       "Recrutar: 150 cr (+50% a cada um). Prédio repetido (laboratório, arsenal, taverna...) custa +50% a cada novo."])

    # ------------------------------------------------------------------ 10
    H("10. A vila: estágios e melhorias", 1)
    T(["Estágio", "Nome", "Minério coletado no total", "Custo para expandir", "Obra"], [
        ["1", "Acampamento", "—", "—", "—"],
        ["2", "Vilarejo", "375", "190 cr", "60 s"],
        ["3", "Vila", "1.250", "625 cr", "90 s"],
        ["4", "Vila Mineira", "3.100", "1.500 cr", "120 s"],
        ["5", "Cidade Mineira", "6.250", "3.100 cr", "150 s"],
    ], [2, 3.5, 4.5, 3.5, 2])
    P("Cada estágio libera construções e dá **+3 de ânimo** para todos. Melhorias do Centro da Vila:")
    T(["Melhoria", "Níveis", "O que faz"], [
        ["Moradias", "4 (190 cr+40 ferro → 1.250 cr+310 ferro)", "+4 vagas de ipezinho por nível; casas novas"],
        ["Enfermaria", "3 (125 cr → 625 cr)", "−20% do tempo de cura por nível; +1 leito"],
        ["Trilhas batidas", "3 (150 cr → 810 cr)", "+50% do bônus de velocidade dos CAMINHOS pintados, por nível"],
    ], [3.5, 6, 7.5])

    # ------------------------------------------------------------------ 11
    H("11. Construções", 1)
    P("Tudo é encomendado no menu **CONSTRUIR (Espaço)**, por abas. Toda obra é **paga na hora** e depois "
      "**precisa de engenheiro** para sair do lugar. Os prédios aparecem por etapas (obra 1 → 2 → 3 → pronto).")
    T(["Aba / construção", "Custo", "Estágio", "Para quê"], [
        ["**Moradia** — Casa", "por nível de Moradias (ferro + madeira)", "1", "Camas (4/6/8) e conforto"],
        ["**Alimentação** — Cozinha", "100 cr + 20 ferro + 25 madeira", "1", "Guarda e serve a comida (120)"],
        ["**Saúde** — Enfermaria extra", "200 cr + 40 ferro + 60 madeira", "1", "Mais leitos (a da vila é de graça)"],
        ["**Lazer** — Taverna", "120 cr + 40 madeira (ampliar: 350 cr)", "1", "+5/+8 de ânimo; ponto social"],
        ["**Lazer** — Parque", "100 cr + 20 ferro + 40 madeira", "1", "Ânimo para quem está perto"],
        ["**Pesquisa** — Laboratório", "300 cr + 80 ferro + 60 madeira", "2", "Pesquisa (pesquisadores)"],
        ["**Defesa** — Arsenal", "150 cr + 40 ferro + 60 madeira", "1", "Forja de armas (ferreiro)"],
        ["**Defesa** — Campo de treino", "120 cr + 50 madeira", "1", "Guardas treinam (≈110 s para ficar pronto)"],
        ["**Defesa** — Vestiário", "120 cr + 30 ferro + 50 madeira", "1", "Guarda casacos e trajes"],
        ["**Defesa** — Oficina (forja)", "200 cr + 40 ferro + 60 madeira", "1", "Ferramentas, casacos, trajes, pregos (ferreiro)"],
        ["**Defesa** — Ventilador (S2)", "400 cr + 60 prata + 40 madeira", "pesquisa", "Corta o gás/ácido do S2 pela metade"],
        ["**Produção** — Fornalha", "180 cr + 50 ferro", "2", "Barras e aço (fundidor)"],
        ["**Produção** — Coletor de madeira", "a ruína da floresta: 4 etapas; extras 250 cr + 60 ferro", "1", "0,6 madeira/s com operador"],
        ["**Produção** — Coletor de minério", "280 cr + 40 ferro + 60 madeira", "1", "0,5 minério/s de uma jazida perto"],
        ["**Produção** — Trilho e vagonete", "260 cr + 80 ferro + 80 madeira", "1", "Leva minério da boca da mina ao armazém sozinho"],
        ["**Produção** — Ferrovia de carga", "300 cr + 60 ferro + 100 madeira (+150 cr por andar)", "S2 aberto", "Estação em cada andar; a carga sobe sozinha"],
        ["**Culto** — Igreja", "220 cr + 40 ferro + 80 madeira", "2", "Missa, funeral, aconselhamento (uma só)"],
        ["**Culto** — Cemitério", "pelo tamanho (40 cr + 6/vaga; ferro e madeira por trecho)", "2", "Enterros com lápide; funeral"],
        ["**Decoração** — tocha, lampião, banco, mesa, cerca, canteiro, bandeira", "baratas (sem engenheiro)", "1", "Beleza perto das casas; luz; banco/mesa viram ponto social"],
        ["**Vila** — Expandir a vila", "ver estágios", "—", "Próximo estágio"],
        ["**Vila** — Caminhos (terra, cascalho, pedra)", "por célula pintada", "1", "Andar mais rápido (+12% / +20% / +30%)"],
        ["**Vila** — Desbravar o leste", "900 cr + 120 ferro + 160 madeira", "2", "Abre a área leste do mapa"],
        ["**Vila** — Escudo solar", "4 etapas (ver seção 15)", "4", "A VITÓRIA"],
        ["Escola", "em breve", "—", "Para quando houver crianças"],
    ], [5.3, 5, 1.6, 5.1], tam=8.5)
    IMG(r"bloco92\predios_e_oficios.png", 15.5, "Fornalha (a Fundição) e a Igreja, com fundidores, ferreiros e o padre.")

    # ------------------------------------------------------------------ 12
    H("12. Produção (só por ordem do jogador)", 1)
    P("Nada é produzido sozinho: o jogador **encomenda a quantidade** e o trabalhador certo faz. Os insumos saem do "
      "armazém quando cada unidade começa; cancelar devolve.")
    T(["Onde", "Quem", "Receita"], [
        ["Fornalha", "Fundidor", "Barra de ferro = 2 ferro + 1 carvão (10 s)  •  Barra de cobre = 2 cobre + 1 carvão (12 s)  •  "
                                 "Barra de prata = 2 prata (14 s)  •  Lingote solar = 2 solarita (18 s)  •  Aço = 1 barra de ferro + 1 carvão (20 s, estágio 3)"],
        ["Oficina", "Ferreiro", "Ferramentas: picareta de aço (cobre), lampião de segurança (carvão), broca manual (prata), traje de chumbo (abismo), arco (caça)"],
        ["Oficina", "Ferreiro", "Pregos (6) = 1 barra de ferro (8 s)  •  Ferragem = 2 barras de ferro + 4 pregos (12 s)"],
        ["Oficina", "Ferreiro", "Casaco de inverno (30 cr + 3 couro + 6 madeira, 3 por vez)  •  Trajes: gás, calor, radiação (pesquisa Trajes)"],
        ["Arsenal", "Ferreiro", "Armas (ver seção 13)"],
        ["Escavadeira", "Engenheiro", "5 peças (estrutura, motor, hidráulico, cabine, broca) e 5 reatores"],
    ], [2.5, 2.5, 12])

    # ------------------------------------------------------------------ 13
    H("13. A noite e as invasões", 1)
    CAIXA("Quando vem invasão?", [
        "A **primeira invasão é no dia 3**, e depois **a cada 2 dias** (dias 3, 5, 7, 9...).",
        "**21:00** toca o berrante (aviso). Com o **rádio** o aviso vem 60 s antes.",
        "**22:00** as criaturas começam a chegar (espalhadas ao longo de 20 s) e a luta vai até o **amanhecer (05:00)** — "
        "cerca de 2 min 37 s reais. Ao amanhecer o Lumívoro foge da luz e o Ferrugento desliga.",
        "Antes da invasão todo mundo já está em casa; os guardas vão aos postos."])
    H("13.1 As criaturas", 2)
    T(["Criatura", "Vida", "Vel.", "Dano", "De onde / quando", "O que faz"], [
        ["Lumívoro", "18", "72", "4", "Floresta (portão); sempre", "Come luz: ataca quem está fora, assusta quem está nas casas acesas (−ânimo). É atraído por tochas e lampiões e os apaga"],
        ["Ferrugento (robô)", "42", "44", "7", "Poço do elevador; com o S2 aberto", "Ataca quem está perto e ROUBA minério do armazém. Lança de prata x1,6 contra ele"],
        ["Gosma ácida", "24", "62", "5", "Poço; S2 aberto, a partir da onda 2", "Corrói a arma do guarda; no armazém dissolve ferro e cobre; derrete barricada x1,5; às vezes deixa cristal verde"],
        ["Magmante", "70", "34", "10", "Poço; S3 aberto, a partir da onda 3", "Lento e duro; no armazém come carvão; derrete barricada x2; às vezes deixa cristal rubro"],
        ["Matriarca (chefe)", "x10", "—", "x2", "1ª invasão de cada estação, a partir do verão", "Grita e chama mais Lumívoros; gasta a arma do guarda. Recompensa: 40 solarita + 2 peças raras + 80 pontos de pesquisa"],
    ], [2.6, 1.1, 1.1, 1.1, 4, 7.1], tam=8.5)
    T(["Onda", "Quantas criaturas", "Mais forte"], [
        ["Toda onda", "Lumívoros: 2 + 1 por onda (máx. 10); Ferrugentos: 1 por onda (máx. 6)", "Vida +15% por onda"],
        ["A partir da onda 2/3", "Gosmas (máx. 4) e Magmantes (máx. 3), se o andar deles estiver aberto", ""],
        ["A partir da onda 4", "1 em cada 3 vem FORTE (Lumívoro bruto, Ferrugento carregador): vida x1,6, dano x1,3", ""],
        ["Tier 3+", "Os fortes viram ELITE: vida x1,35, dano x1,2 a mais", "Tier sobe com as ondas e com as pesquisas feitas"],
    ], [3, 9, 5])
    H("13.2 A defesa", 2)
    T(["Arma", "Custo", "Forja", "Dano", "Alcance", "Aguenta"], [
        ["Porrete", "grátis", "—", "3", "corpo a corpo", "30 golpes"],
        ["Lança", "150 cr + 40 ferro + 20 madeira", "40 s", "6", "corpo a corpo", "45"],
        ["Besta", "350 cr + 40 cobre + 40 madeira", "60 s", "7", "110 (distância)", "55"],
        ["Lança de prata", "600 cr + 60 prata + 20 madeira", "80 s", "11 (x1,6 no Ferrugento)", "corpo a corpo", "70"],
    ], [2.6, 5, 1.4, 2.6, 2.6, 2])
    B(["**Guarda**: vida 30 + 20 x habilidade (treino de 0 a 100%). Sem treino bate com metade da força. "
       "Arma quebrada: luta no soco (1,5). Conserto = 40% do custo, 50% do tempo.",
       "**Barricada (portão da floresta)**: vida 120 / 260 / 450 por nível (80 cr + 60 madeira → 500 cr + 200 ferro). "
       "Consertar gasta madeira.",
       "**Brecha**: se o guarda do portão CAI, o primeiro invasor que chega ao armazém leva **12% do minério e dos créditos**.",
       "**Robô antigo** (achado na mina, conserto 400 cr + 60 minério + 6 peças raras): patrulha e luta; +5 de ânimo.",
       "**Holofotes** (pesquisa): Lumívoros 30% mais lentos e guardas 30% mais fortes.",
       "**Luz da decoração**: tochas e lampiões atraem os Lumívoros (iscas para longe das casas)."])

    # ------------------------------------------------------------------ 14
    H("14. Ondas solares", 1)
    B(["Começam no **dia 2**. Chance por dia: primavera 25%, **verão 50%**, outono 25%, inverno 12%.",
       "Chegam numa hora sorteada entre **08:00 e 16:00** e duram 35 s. A intensidade cresce 8% por dia.",
       "Aviso: 10 s antes — ou **60 s** com a pesquisa Estudo da explosão solar.",
       "Quem fica exposto acumula radiação (1/s x intensidade); com 10, se machuca (25% grave). Abrigo: dentro "
       "dos prédios e na mina.",
       "A horta murcha 30% em cada onda."])

    # ------------------------------------------------------------------ 15
    H("15. A mina, os andares e o objetivo final", 1)
    T(["Andar", "Perigo", "Traje", "Minérios", "Criaturas", "Como abrir"], [
        ["Superfície", "—", "—", "—", "Lumívoro", "—"],
        ["S1 — Mina e vila", "poeira", "—", "ferro, cobre, carvão", "Lumívoro", "Desde o começo (galerias lacradas abrem com o estágio)"],
        ["S2 — Ácido e gás", "gás, poças de ácido", "máscara de gás", "prata, cobre, cristal verde", "Ferrugento, Gosma", "ESCAVADEIRA pronta (5 peças)"],
        ["S3 — Lava (abismo)", "calor, poços de lava", "traje térmico", "solarita, prata, cristal rubro", "Ferrugento, Magmante", "Pesquisa Trajes + conserto da plataforma (1.500 cr + 12 peças raras + 150 prata, estágio 4)"],
        ["S4 — Cachoeira", "calor, água", "traje térmico", "cristais, solarita", "Magmante", "Pesquisa Bombas d'água + conserto"],
        ["S5 — Lago azul", "—", "—", "gema azul", "—", "Conserto da ligação; o lago acalma"],
    ], [2.8, 2.5, 2.2, 3.1, 2.7, 3.7], tam=8.5)
    B(["**Jazida**: 200 de minério, volta 0,45/s depois de 20 s esgotada. Cada uma tem até 3 vagas.",
       "**Achados** na mineração (5% na superfície, 12% no fundo): peças raras, cristal, painel solar, bobina e o **robô**.",
       "**Dinamite** (pesquisa Explosivos): abre galeria lacrada antes da hora (40 cr + 15 carvão cada).",
       "**Elevadores e plataformas**: 4 pessoas por viagem, 1,6 s.",
       "**Escavadeira**: 5 peças → abre o S2; a broca manda minério ao armazém sozinha com um **reator**: "
       "caldeira a vapor (gasta carvão), diesel (barulho: −ânimo), cristal (dobra os achados), núcleo solar "
       "(mais acidentes), fusão (o mais forte, às vezes explode)."])
    T(["Escudo solar (vitória)", "Custo", "Obra"], [
        ["1. Fundação", "600 cr + 200 ferro + 100 madeira", "60 s"],
        ["2. Bobinas", "900 cr + 150 cobre + 80 prata", "80 s"],
        ["3. Núcleo", "1.200 cr + 150 solarita + 15 peças raras", "100 s"],
        ["4. Emissor", "2.000 cr + 100 prata + 100 solarita", "120 s"],
    ], [5, 9, 3])
    P("Precisa da vila no **estágio 4** e da pesquisa **Projeto do escudo solar**.")

    # ------------------------------------------------------------------ 16
    H("16. Pesquisa (Laboratório)", 1)
    P("O laboratório custa 300 cr + 80 ferro + 60 madeira (estágio 2). Cada **pesquisador** gera 1 ponto por "
      "segundo, de dia. Três ramos; algumas são **escolhas** (pesquisar uma tranca a outra para sempre).")
    T(["Pesquisa", "Ramo", "Precisa de", "Pontos", "Custo", "Efeito"], [
        ["Carrinhos de mina", "Mina", "—", "80", "150 cr + 100 ferro", "+25% de carga por viagem"],
        ["Explosivos", "Mina", "Carrinhos (tranca Escoramento)", "140", "300 cr + 60 carvão", "+30% mineração, +25% acidentes, dinamite"],
        ["Escoramento", "Mina", "Carrinhos (tranca Explosivos)", "140", "250 cr + 100 madeira", "−40% acidentes na mina"],
        ["Trajes de proteção", "Mina", "Carrinhos", "120", "250 cr + 40 cobre", "Máscara de gás, traje térmico, antirradiação; abre o S3"],
        ["Ventilação", "Mina", "Trajes", "120", "300 cr + 40 prata", "Ventiladores no S2"],
        ["Bombas d'água", "Mina", "Ventilação", "160", "600 cr + 60 solarita", "Conserto da ligação para o S4"],
        ["Medicina de campo", "Vila", "—", "80", "200 cr + 40 cobre", "Cura 30% mais rápida; sem leito aguenta 50% mais"],
        ["Rádio da vila", "Vila", "Medicina (tranca Hidroponia)", "120", "300 cr + 40 cobre", "+6 ânimo; aviso de invasão mais cedo"],
        ["Hidroponia", "Vila", "Medicina (tranca Rádio)", "120", "250 cr + 60 madeira", "Horta x2; cozinha +60"],
        ["Ritos fúnebres", "Vila", "Medicina", "90", "150 cr + 40 madeira", "O padre faz o funeral: −luto, +ânimo"],
        ["Estudo da explosão solar", "Sol", "—", "150", "300 cr + 30 prata", "Aviso das ondas com 60 s"],
        ["Satélite", "Sol", "Estudo (tranca Holofotes)", "200", "600 cr + 60 prata", "Um colono a cada 2 dias"],
        ["Holofotes", "Sol", "Estudo (tranca Satélite)", "200", "500 cr + 80 cobre", "Lumívoros −30% velocidade; guardas +30% dano"],
        ["Projeto do escudo solar", "Sol", "Estudo", "300", "800 cr + 40 solarita", "Libera o Escudo"],
    ], [3.3, 1.3, 3.4, 1.3, 3.1, 4.6], tam=8.5)

    # ------------------------------------------------------------------ 17
    H("17. Calendário, igreja e vida social", 1)
    B(["**Hora social (18:30–21:30)**: depois do jantar cada ipezinho vai a um ponto social — refeitório, praça, "
       "taverna, parque, igreja, bancos e mesas da decoração — e conversa em rodas (balões de fala). Com chuva, só "
       "lugares cobertos.",
       "**Missa de domingo (09:00–11:00)**: com padre e igreja, todos vão (menos o médico de plantão): +6 de ânimo.",
       "**Domingo à tarde**: o jogador escolhe — **Festival** (a festa, todos na praça), **Dia livre** (passeiam) "
       "ou **Trabalhar** (hora extra com zanga).",
       "**Festivais**: um por estação, no último domingo — Festa das Flores, do Sol, da Colheita e das Lanternas "
       "(o festival desse dia anima 50% mais).",
       "**Diário (J)**: páginas que abrem conforme a vila descobre o mundo, e o memorial de quem morreu."])
    IMG(r"bloco93\com_tumulos.png", 14.5, "O cemitério com as lápides ('Nome · † dia N').")

    # ------------------------------------------------------------------ 18
    H("18. Save", 1)
    B(["Save automático a cada 3 minutos e ao fechar; F5 salva, F9 carrega.",
       "Começar partida nova não apaga o save: ele vira um **backup** com data (até 5), na tela inicial.",
       "Saves antigos continuam carregando depois das atualizações."])
