# Prompt 26: título, logo, key art, carregamento, vitória e derrota

Data: 2026-10-02. Branch `isometrico`. Geração: **até 80** (2 propostas de key art pro de 428×240; junto com as animações das pendências
deu 82). O logo, o fundo animado e as telas de carregamento são por script, com a arte que já existe.
Checkpoint (escolher a key art) dispensado: escolhi a **A**.

## Como testar

- **Abra o jogo:** o menu inicial tem a **key art** cobrindo a tela (vila no platô, a pedreira
  cavada no penhasco, a escavadeira furando, o sol ameaçador num céu de fogo), com movimento leve: o
  céu pulsando, fumaça das chaminés, faíscas da broca e brasas subindo. O **logo DEEP IRON** em
  cima e os botões numa moldura de ferro (`menu_inicial.png`, `menu_animado.gif`);
- **Continuar / Novo jogo / carregar backup:** a **tela de carregamento** com uma cena (a key art B
  ou uma das ilustrações), o logo e uma **dica** do jogo (10 dicas) (`carregando.png`);
- **vitória** (escudo ativado) e **derrota** (expulso pela greve): com a ilustração (Prompt 24).

## O que foi feito

| Pedido | Feito |
|---|---|
| Logo "DEEP IRON" (metal pesado, ferrugem, brilho quente) com a fonte de título | `titulo/logo.py`: a fonte de título do Prompt 22 em 3x, ferro em faixas com luz em cima, ferrugem, contorno escuro e o brilho do fogo embaixo (`logo.png`) |
| Key art: a grande ilustração pintada | 2 propostas (`proposta_keyart_a.png`, `proposta_keyart_b.png`); a A é o fundo do título, a B entra no carregamento |
| Fundo animado do menu (camadas, fumaça, luz) | `scripts/ui/menu_fundo.gd`: key art + céu pulsando + fumaça + faíscas + brasas (partículas com as texturas do Prompt 18) |
| 2–3 telas de loading com dicas | `scripts/ui/carregando.gd`: 5 cenas possíveis × 10 dicas, aparece em toda troca de cena do SaveManager e some quando a partida abre |
| Tela de vitória e de derrota (fome, invasão, insatisfação) | vitória e derrota por insatisfação com a cena; **derrota por fome ou invasão não existe no jogo** (só a expulsão pela greve), então não gerei |

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `scripts/ui/start_menu.gd` | fundo animado, logo, moldura nos botões (backups e configurações dentro da mesma moldura) |
| `scripts/ui/menu_fundo.gd`, `scripts/ui/carregando.gd` (novos) | o fundo e a tela de carregamento |
| `scripts/core/save_manager.gd` | mostra a tela de carregamento antes de trocar de cena |
| `prototipos/camera/arte_iso/titulo/` | key arts e `logo.py` |
| `assets/game/ui/titulo/` | logo e key arts (com as bordas brancas do gerador cortadas) |
| `tests/capturas_titulo.gd` | fotos/GIF |
