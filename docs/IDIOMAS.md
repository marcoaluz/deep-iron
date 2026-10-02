# Idiomas (Bloco 54)

**pt_BR** é o padrão (o jogo é escrito em português); **en** é a segunda língua, PARCIAL.
Troca em Configurações > Idioma, na hora (sem reiniciar); a escolha fica em `settings.cfg`
(`[geral] idioma`). Sem escolha, o jogo abre em inglês só se o sistema estiver em inglês.

## Como funciona

- `project.godot/translations/ui.csv`: uma linha por texto (`keys`, `pt_BR`, `en`). A chave é o
  próprio texto em português, do jeito que está no código. O Godot importa o CSV (gera
  `ui.pt_BR.translation` e `ui.en.translation`, registradas em `project.godot` >
  `internationalization/locale/translations`).
- Todo `Label`/`Button` traduz sozinho o texto que for **exatamente** igual a uma chave (e retraduz
  quando o idioma muda). Por isso entram os textos fixos: títulos de janela, botões, abas, menus,
  faixas ("GREVE!", "VILA FUNDADA!"), configurações.
- Pra traduzir um texto novo: acrescentar a linha no CSV (o editor reimporta sozinho).

## O que está traduzido (186 textos)

Títulos e botões fixos da HUD (barra de cima, força de trabalho, coluna de prédios, ajuda), das
janelas (Centro da Vila, armazém, escavadeira, oficina, enfermaria, bem-estar, defesa, laboratório,
sol, diário, corte da mina, casa, coletor), do menu de construção (abas e nomes dos prédios), do menu
inicial, da pausa, das configurações, das faixas de evento e da vitória/derrota.

## O que falta (marcado pra depois)

- **Textos montados com números/nomes** (`"Vender +%d"`, `"DIA %d"`, `"falta 30 ferro"`, estados dos
  ipezinhos "indo pra obra: Casa (40%)", custos, dicas dos cartões): seguem em português. Pra traduzir
  precisam virar `tr("Vender +%d") % valor` no código, um por um.
- **Diálogos e textos longos** (eventos, diário, descrições dos cartões e das pesquisas, notas das
  estações): fora do escopo do Bloco 54.
- **Nomes próprios** (ipezinhos, Ferrugento) não se traduzem.
- Outros idiomas: é só acrescentar uma coluna no CSV (ex.: `es`) e uma linha em
  `WindowManager.IDIOMAS`.

## Fontes

As fontes da pele (Prompt 22) têm os acentos do português (á à â ã é ê í ó ô õ ú ç, maiúsculas
também); o teste `b54_configuracoes` confere.
