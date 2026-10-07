---
name: deep-iron-arte
description: Regras de arte do jogo DEEP IRON (Godot 4, pixel art isométrico Rota A, geração via PixelLab MCP). Use SEMPRE que for gerar, revisar, animar, exportar ou integrar qualquer asset visual do Deep Iron - personagens, elenco, prédios, estágios de obra, tilesets, objetos, criaturas, ícones, UI, efeitos - mesmo que o pedido seja curto como "gera a taverna" ou "faz a animação de andar". Também use ao estimar custo de gerações, montar prancha/GIF de entrega ou atualizar o INVENTARIO.md. Não use para código de gameplay sem relação com arte.
---

# DEEP IRON — Skill de arte

Esta skill é a versão compacta do contrato de arte. Se existirem `docs/arte/CONTRATO_ARTE.md` e `docs/arte/INVENTARIO.md` no repositório, leia os dois primeiro: eles têm prioridade sobre esta skill em caso de conflito. Reporte o conflito, não resolva sozinho.

## Antes de gerar qualquer coisa

1. Ler o contrato e o inventário (se existirem).
2. Estimar o custo em gerações. Se passar do saldo, gerar só o que cabe, pela prioridade do inventário, e parar reportando o que faltou.
3. Declarar a **caixa** (pegada + altura) do objeto ou personagem.
4. Desenhar a **imagem-guia 2:1** dentro do PixelLab (sem custo) ANTES de pedir a arte.
5. Usar o minerador isométrico aprovado (ou outro asset já aprovado) como referência de escala e estilo.
6. Gerar **1 peça-piloto** de cada tipo novo e validar antes de gerar em lote.

## Estilo (vale para toda geração)

- Texto obrigatório no prompt: `Crisp 1px near-black outline`.
- Tom dark/sujo: paleta terrosa, brilho médio ~0,22-0,23, desgaste, fuligem, remendos.
- Escala: o minerador é a régua. Porta de prédio = altura do minerador.
- Sem gore. Ferimento, morte e combate sempre sóbrios, sem sangue.
- Canvas de personagem: 48x84 (48x80 corta a cabeça).

## Técnica isométrica

- Ângulo 2:1 exato, sempre pela imagem-guia.
- No máximo 4 px de sprite fora da caixa.
- **Fundo da caixa fixo** (encostado na parede de trás). Só frente, lados e altura crescem. Empurrar a caixa para trás "cobre" na tela o mesmo que aumentar a altura.
- Prédio com arte inteira, sem fatiamento manual. Ordenação por caixas, não por fatias.
- **Âncora** anotada na exportação. A mesma âncora em todas as variações e estágios de um objeto.
- Tileset: paredes externas de buraco não são desenhadas; borda da frente tão grossa quanto o buraco é fundo; peças para os 4 lados + cantos.

## Personagens e criaturas

- 4 direções de losango: 2 desenhos + espelho por animação. As 8 poses paradas que o PixelLab entrega ficam guardadas.
- Animação: skeleton-v3 primeiro; interpolação v3 entre estados quando precisar; v3 com texto só se as outras falharem.
- Fluxo de movimento: gerar quadro-chave, aprovar, só então interpolar. Sempre olhar o GIF em loop antes de seguir (ciclo de andar fecha sem pulo?).
- **Diversidade**: todo humano cobre homens e mulheres e pele branca, parda e negra. Arte neutra + troca de paleta por código (`paletas_pele.json`). Mostrar prancha com as 3 peles lado a lado.
- Variar cabelo e rosto entre as funções.
- Picareta híbrida: overlay nas costas (atrás do corpo quando de frente para a câmera, na frente quando de costas); embutida na animação de golpe. Vale para qualquer ferramenta guardada nas costas ou no cinto.
- Machucado: ícone de curativo/tala sobreposto + pose parada com respiração por código.

## Estágios de obra (regra de conteúdo)

Toda estrutura construível tem: `obra_1` (fundação e material solto) → `obra_2` (esqueleto/andaime) → `obra_3` (paredes e telhado incompletos) → `pronto`. Upgrade de nível (1→2→3) também tem obra, feita por cima do prédio existente. No jogo o desenho troca por progresso do engenheiro (0-33 / 33-66 / 66-100%). Nunca o prédio aparecendo pronto do nada, nunca o "fantasma que fica nítido".

## Estações e luz

- O que é natural (chão, árvores, vegetação, telhados) tem variante por estação quando o jogo usar estação naquele elemento.
- Cada peça com luz traz 1 ponto de luz anotado.

## Verificação de cada entrega

Rodar `references/checklist-qa.md`. Resumo: cabe na caixa, âncora igual, paleta e contorno consistentes, ordenação correta na cena de estresse, 3 peles ok, GIF em loop sem pulo, legível em 1x.

## Entrega padrão

Prancha lado a lado, GIF das animações, custo em gerações, desvios do contrato (listados, nunca contornados em silêncio) e `INVENTARIO.md` atualizado. Tudo isolado em `prototipos/camera/arte_iso/<categoria>/` até os prompts de integração.

## Checkpoints com Marco (parar e mostrar)

Conceito de criaturas, sistema visual de UI, fonte, tela "Corte da mina", título/logo/splash, layout do mapa. Nesses pontos, não seguir sem aprovação.

## Erros já aprendidos

- Gerar sem imagem-guia deixa o ângulo iso incerto (foi o caso do minerador).
- Fundação da obra_1 maior que a base da casa causa "pulo" na troca de estágio; checar na piloto.
- Case-sensitivity de pastas quebra export Windows→Linux: usar `assets/game/` em minúsculas.
