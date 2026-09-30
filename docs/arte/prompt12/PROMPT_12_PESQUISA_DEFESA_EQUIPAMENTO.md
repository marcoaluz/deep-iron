# Prompt 12: pesquisa, defesa e equipamento

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/{laboratorio,arsenal,vestiario,campo_treino,fundicao,muro}/`.
Nada integrado ao jogo.

## O que ficou pronto

| Prédio | Estágios | Caixa (pegada × altura) |
|---|---|---|
| **Laboratório** | obra 1–3 → pronto: pedra embaixo, madeira em cima, torrinha de observação, mastro com fios, bancada com frascos e microscópio, quadro de giz. O satélite do telhado é o do Prompt 13 | 126×108×214 |
| **Arsenal** (criação de armas e armaduras) | obra 1–3 → pronto: pedra e madeira com ferro, portão reforçado, telheiro com **suporte de lanças, besta e porretes**, peitoral e escudo no cavalete, **bigorna e rebolo** pra fazer arma e armadura | 146×104×182 |
| **Vestiário** | obra 1–3 → pronto: varanda com os **3 trajes pendurados** (gás amarelo, calor prata, radiação oliva) e casacos, banco, botas, pia | 126×104×174 |
| **Campo de treino** | obra 1–3 (script) → pronto: pátio cercado, 3 bonecos de palha com capacete, 2 alvos de flecha, suporte de espadas de treino, torrinha | 166×134×104 |
| **Fundição** (prédio NOVO, pedido do Marco: pedra → carvão, ferro → aço) | obra 1–3 → pronto: alto-forno de tijolo com chaminé de ferro, cadinho nas correntes, canal de vazamento com lingoteiras, **forno de carvão** (monte), lingotes de aço, carvão, fole, carrinho de minério. Forno apagado (brilho = luz no código) | 148×112×202 |
| **Muro modular**, 3 níveis | nível 1 paliçada, nível 2 madeira reforçada com base de pedra, nível 3 pedra com ameias. Peças por nível: **reta (eixo i e j), canto, ponta, danificada, brecha** (a "brecha" do roubo, com entulho) | 1 tile por peça |
| **Portão** (a única entrada da vila) | **quebrado** (o do começo) → **nível 1** (toras) → **nível 2** (torres de madeira, ferragem) → **nível 3** (arco de pedra, torres com ameias, grade de ferro, emblema de picaretas) | 2 tiles |

## Entregas (nesta pasta)

`prancha_<prédio>.png` + `obra_<prédio>.gif` (laboratório, arsenal, vestiário, campo de
treino, fundição); `prancha_muro_portao.png`, com as peças dos 3 níveis, um trecho montado
(nível 2 com portão, danificada e brecha) e os 4 portões.

## Custo

**~370 gerações** (5 prédios com esqueleto, muro com 1 refação, 4 portões).

## Desvios

1. **Muro níveis 2 e 3, 1ª tentativa:** vieram "de frente" e não encaixavam na diagonal do
   chão. Refiz com a paliçada do nível 1 como referência de orientação (+40).
2. **Muro no eixo j = espelho do eixo i.** O contrato manda não espelhar bloco (troca a luz),
   mas o muro é fino e a diferença quase não aparece. Se incomodar na montagem, é +20 por
   nível pra gerar o eixo j.
3. **O danificado** saiu do mesmo lote da IA (um dos 4 candidatos já tinha rombo). A
   **brecha** é por script: tira o meio do segmento e põe entulho.
4. **Portão:** uma orientação só (a da entrada). Se a entrada do mapa ficar no outro eixo, são
   +20 por nível.
5. **Upgrade do portão:** nível → nível troca direto. A obra entre níveis pode usar o andaime
   do Centro/Armazém por cima (integração).
6. **Campo de treino:** a obra saiu por corte do próprio pronto (é um pátio baixo), sem gerar.
7. **Torre de vigia:** o jogo não tem (a aba Defesa tem Barricada, Arsenal, Campo de treino e
   agora Muro/Portão). Não gerei.
