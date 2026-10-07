# Pendências dos Prompts 2, 14 e 29 (feitas junto dos Prompts 18 e 26)

Data: 2026-10-02. Branch `isometrico`.

## Como testar

- **Caçador sem arco colhendo fruta na horta:** agacha e colhe (antes: a animação de caçar com
  arco); andando, leva o **cesto** na mão.
- **Guarda no campo de treino:** golpes de treino (antes: o ataque com porrete).
- **Guarda atacando:** com **lança** (ou lança de prata) faz a estocada; com **besta** mira e
  atira; com porrete, o golpe de sempre.
- **Greve:** a **placa de greve** erguida na mão (antes: um ícone por cima da cabeça).
- **Cemitério:** a **cova** nova; **explosivos** pesquisados: caixote perto do poço; **satélite**
  pesquisado: a antena do lado do laboratório.

## O que foi feito

| Pendência | Prompt | Feito |
|---|---|---|
| Colher fruta (caçador sem arco), h/m | 2 | animação v3 (SE+NE, SO/NO espelhadas), passada pelo `trabalho.py` (limpeza, corte de altura das mulheres, âncora do pé) |
| Treinar no campo, h/m | 2 | idem (guarda e guarda mulher) |
| Greve: placa na mão | 2 | sobreposição na mão (Prompt 18) |
| Cesto de coleta | 14 | sobreposição na mão (Prompt 18) |
| Cova, explosivos, antena | 14 | peças geradas, no jogo pelo estado (Prompt 18) |
| Arma trocada na mão no ataque | 29 | animação de ataque com lança e com besta, h/m (a lança de prata usa a da lança) |

Prancha: `pendencias_2_29_animacoes.png` (as 8 animações, direção SE).

Teste: `tests/blocos/p2_pendencias.gd` (8 animações nas 4 direções e a escolha pelo estado: colher,
treinar, porrete, lança, lança de prata, besta).

## Limites

1. Na guarda mulher a besta saiu parecendo um arco (o gerador desenhou o arco curvo).
2. O caçador colhe sem cesto visível na animação (o cesto aparece quando ele anda).

Geração: as 8 animações e as 2 key arts do Prompt 26 somaram **82** (o saldo foi de 291 pra 209).
