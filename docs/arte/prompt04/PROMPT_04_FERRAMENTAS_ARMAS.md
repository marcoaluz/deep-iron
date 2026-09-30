# Prompt 4: ferramentas e armas

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/itens/`. Nada integrado ao
jogo.

## O que o jogo usa (conferido no código)

| Grupo | Itens |
|---|---|
| Ferramentas | picareta, **picareta de aço temperado** (upgrade da Oficina), machado, martelo, **broca manual**, **lampião de segurança**, **arco e flecha** (só com a Oficina) |
| Armas do Arsenal (`defense.gd`) | porrete, lança de ferro, besta de cobre, lança de prata |
| Estado do jogo | arma quebrada (`arma_quebrada`, vai pra pilha de conserto) |

A maleta do médico já faz parte do corpo dele (Prompt 1). Os utensílios do cozinheiro
(tigela e colher) estão nas animações dele. O "traje de chumbo" antigo virou os trajes do
Prompt 3.

## O que ficou pronto (12 itens × 5 versões)

| Versão | Como foi feita |
|---|---|
| **Base** | gerada (1 item por candidato) e **reduzida** pro tamanho do jogo: picareta ~40 px, lança ~52 px, perto do minerador de 74 px |
| **Gasta** | por script: mais escura, dessaturada, pontos de ferrugem |
| **Quebrada** | por script: partida no meio, com vão |
| **No chão (largada)** | por script: achatada 1/2 na vertical, o que põe a diagonal de 45° exatamente no eixo 2:1 do chão, com sombra |
| **Ícone de UI** | o item em quadrado, no tamanho nativo; a escala fica com o Prompt 20/21 |

**Nas costas (regra da picareta, aplicada a todos os de cabo):**

- de frente pra câmera (SE/SO), o item fica **atrás** do corpo e só a ponta aparece por cima
  do ombro;
- de costas (NE/NO), fica **na frente**, cruzando as costas;
- o martelo do engenheiro vai no cinto.

Configurações em `itens.py → CONFIG`. Demonstração em `itens_nas_costas.gif`, na caminhada
real de 8 personagens.

**Na mão:** as ferramentas de trabalho já estão **desenhadas dentro das animações de
trabalho** (Prompt 1): picareta, machado, martelo, arco, porrete do guarda.

## Entregas (nesta pasta)

- `prancha_itens.png`: os 12 itens em base, gasta, quebrada, no chão e ícone.
- `itens_nas_costas.gif`: os itens nas costas na caminhada, SE e NE.

## Custo

**60 gerações** (saldo ~162 → ~102): 3 folhas × 20.

A técnica barateou tudo: pedi 4 itens numa imagem 128×128, e o modelo devolveu **1 item por
candidato** (4 candidatos = os 4 itens). Todo o resto é script.

## Desvios e o que fica pra integração

1. **Redução.** Os itens vieram grandes (~105 px). Em vez de gerar de novo em tamanho pequeno
   (~20 por item), reduzi por script: filtro, volta pra paleta do item, contorno refeito.
   Ficam nítidos, mas com um pouco menos de detalhe que um desenho feito já pequeno.
2. **Porrete.** Veio com uma mão segurando. Cortei a ponta do cabo.
3. **Arma quebrada.** A gerada perdeu a quebra ao reduzir. A genérica usa a lança partida do
   script.
4. **Arma trocada na mão durante o ataque** (lança, besta, lança de prata no lugar do porrete
   da animação do guarda): precisa da posição da mão quadro a quadro. É trabalho da
   integração (Prompt 29), ou outra animação de ataque por arma (~8 cada).
5. **Lampião.** É uma ferramenta global no jogo (libera minério pra todos). Ficou como item
   pequeno de gancho/cinto; a luz dele é do Prompt 19.
