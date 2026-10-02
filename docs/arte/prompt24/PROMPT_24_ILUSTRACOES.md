# Prompt 24: ilustrações de eventos e achados

Data: 2026-10-02. Branch `isometrico`. Geração: **200** (10 cartões pro de 256×144, 20 cada).

## 1. Eventos no código que mostram (ou deviam mostrar) imagem

Levantamento das faixas de aviso e telas (`show_banner`, vitória, fim de jogo):

| Evento | Onde | Ilustração |
|---|---|---|
| Robô antigo achado | `finds.gd` | `robo_achado` |
| Item de reator achado (cristal, solar, bobina) | `finds.gd` | `reator_achado` |
| Acidente na mina | `ipezinho.gd` (**faixa nova**, só no machucado grave) | `acidente_mina` |
| Invasão chegando / começando / roubo pela brecha | `defense.gd` | `invasao` |
| Greve | `morale.gd` | `greve` |
| Festa | `morale.gd` | `festa` |
| Onda solar chegando | `sun.gd` | `onda_solar` |
| O abismo abriu | `abyss_shaft.gd` | `abismo` |
| Escudo ativado (vitória) | `victory.gd` | `escudo_vitoria` |
| Colônia colapsando (derrota: expulso pela greve) | `game_over.gd` | `expulso_derrota` |
| Expedição | **não existe no jogo** | não gerada (fica pro Prompt 31) |

## 2. As ilustrações

`galeria_ilustracoes.png`. Mesmo estilo e paleta do mapa (as referências foram fotos do próprio
jogo), sem gore. No jogo:

- **faixas de aviso** mostram a cena em cima do título (`faixa_com_ilustracao.png`);
- **vitória** e **derrota** com a cena em 2x (`vitoria.png`);
- a **janela de evento** do Prompt 20 também aceita a imagem.

## 3. Segunda imagem pro resultado?

Não vale agora: nenhum evento do jogo tem escolha com resultado bom/ruim (são avisos). Quando entrar
expedição ou decisão, a janela de evento já tem os botões e a imagem.

## Arquivos

`prototipos/camera/arte_iso/ilustracoes/`, `assets/game/ui/ilustracoes/`, `scripts/ui/icones.gd`
(`ilustracao()`), `scripts/core/hud.gd` (faixa com imagem), `scripts/ui/victory.gd`,
`scripts/ui/game_over.gd`, `scripts/workers/ipezinho.gd` (faixa do acidente grave).
