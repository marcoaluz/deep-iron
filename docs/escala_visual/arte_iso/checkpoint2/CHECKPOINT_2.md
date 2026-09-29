# Arte isométrica — CHECKPOINT 2: casa em escala real + obra + variações

Data: 2026-09-29. **Parado aqui esperando a aprovação do Marco.** Nada foi integrado ao jogo.
A arte está em `project.godot/prototipos/camera/arte_iso/casa/`.

Além da casa pedida, entraram os dois pedidos do Marco no meio do caminho:
- **as 4 variações de casa da Fase 1**, agora em isométrico;
- **a obra** (a casa aparece em estágios enquanto o engenheiro constrói).

## Custo

| Item | Gerações |
|---|---|
| Casa v0 (a base) | 25 |
| Obra: 3 estágios | 75 |
| Variações v1, v2, v3 | 75 |
| **Total do checkpoint** | **175** (saldo 1.656 → **1.481**) |
| Imagem-guia da caixa (desenhada no PixelLab, no `pixelart_workbench`) | 0 (grátis) |

## Como foi feito

1. **Declarei a caixa antes de gerar** (regra 2): pegada 130 × 100, altura 160, porta de ~80
   na parede da frente-esquerda.
2. **Desenhei essa caixa em 2:1 exato** como imagem-guia, dentro do próprio PixelLab (a
   ferramenta gratuita de desenho), pra usar por link.
   - Transcrever imagem em texto falhou duas vezes (a imagem chega corrompida). **Por link
     é seguro.**
3. `create_image_pro` 240×288 com a guia + o minerador isométrico (escala e estilo). **Saiu
   bom de primeira:** isométrica de verdade, porta da altura do minerador, estilo igual.
4. Obra e variações: a **casa pronta como referência de estrutura**. Os 6 desenhos saíram
   alinhados no mesmo lugar do quadro (`casas_com_caixa_guia.png`: todos dentro da mesma
   guia).

## O contrato

| Regra | Resultado |
|---|---|
| 1. Ângulo 2:1 | ✅ Aqui **bateu**: com a guia desenhada em 2:1, o chão da casa segue o losango exato. Pro prédio a guia resolve o desvio que o personagem teve |
| 2. Cabe na caixa | ✅ Cada desenho tem a **sua** caixa (`contrato_casa.json`), no máximo 4 px fora (ver abaixo) |
| 3. Âncora | ✅ A mesma nos 7: ponto (120, 222) do quadro 240×288 = centro da pegada no chão. **Obra e casa trocam no mesmo lugar** |
| 4. Personagem | — |
| 5. Ferramenta | — |
| 6. Relevo | — |
| 7. Luz e peças | ⚠️ Janelas com luz âmbar e o lampião da v2 estão no desenho. O ponto de cada luz ainda não foi anotado (é só medir, na integração) |

**Caixas declaradas** (pegada relativa à âncora, no chão; o fundo é fixo na parede de trás):

| Desenho | Pegada | Altura | Pixels fora |
|---|---|---|---|
| casa v0 (chapa furada, caixote) | 133 × 114 | 201 | 4 |
| casa v1 (roda, corda, persianas abertas) | 133 × 120 | 203 | 0 |
| casa v2 (lampião, barril, 2 chapas) | 133 × 114 | 201 | 4 |
| casa v3 (lona, cano de fogão, lenha, roda) | 139 × 114 | 203 | 0 |
| obra 1 — fundação | 146 × 102 | 97 | 2 |
| obra 2 — estrutura | 133 × 150 | 180 | 3 |
| obra 3 — paredes e telhado | 163 × 138 | 203 | 0 |

- **A caixa muda com o estado** (a obra tem tábuas no chão, a pronta não), e isso é só
  dado. Uma caixa única pros 7 teria 160 × 148 de pegada, grande demais.
- **Achado:** no isométrico, "cabe na caixa" tem mais de uma resposta. Empurrar a pegada pra
  trás cobre na tela a mesma área que aumentar a altura. Por isso **o fundo da caixa é fixo
  na parede de trás** e só a frente, os lados e a altura crescem. Isso vira regra do
  verificador.

**Ordem de desenho** (cena de estresse com as 7 casas e obras e 14 mineradores novos, 60 s):
- ordem incremental: **0 erros em 16.157 sobreposições**;
- ingênua: 1,3% de erros.

Ver `vila_com_mineradores.gif`.

**Bug achado e corrigido pelo teste:** a ordem incremental tinha um limite de 6 mineradores
por "vaga" entre prédios. Com mineradores grandes e poucos prédios, o 7º empatava. Isso teria
aparecido no jogo com muita gente junta. Agora não tem limite.

## A obra

`obra_vira_casa.gif`: fundação → estrutura → paredes/telhado → pronta, no mesmo lugar.
Sugestão pro jogo: trocar o desenho do canteiro pelo **progresso da obra** (0–33%, 33–66%,
66–100%). Hoje o canteiro é um "fantasma" que vai ficando nítido.

⚠️ **A fundação da obra 1 saiu um pouco maior que a base de pedra da casa.** Na troca obra 1
→ obra 2, a base "mexe" um pouco. Dá pra refazer só a obra 1 (25 gerações) pedindo a
fundação exatamente do tamanho da base, ou aceitar.

## Pra aprovar

1. A casa e as 3 variações (`casas_e_obras.png`).
2. Os 3 estágios de obra e a troca pelo progresso (`obra_vira_casa.gif`).
3. A fundação da obra 1: refazer (25) ou aceitar.
4. Com o OK, sigo pro item 5 do plano, **na ordem que você preferir**:
   - elenco completo: 9 funções × gêneros/tons de pele;
   - tiles de terreno com relevo;
   - prédios restantes;
   - objetos.

   Estimativa pelo que já gastei:
   - cada **prédio** pronto ≈ 25, **+75 com os 3 estágios de obra**;
   - cada **personagem** ≈ 27 (base + 8 direções + caminhada);
   - cada **animação extra** por personagem (minerar, cortar, carregar…) ≈ 1 a 25, dependendo
     da técnica.
