#!/bin/bash
# Bloco 50: roda a suíte GUT inteira (headless) com a pasta de usuário ISOLADA e confere que o save
# de verdade não mudou. Sai com 0 se tudo passou; 1 se algum teste falhou; 2 se o save real mudou.
# Uso (da raiz do repositório): tools/run_tests.sh [filtro]     (GODOT_BIN = caminho do Godot)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT_BIN:-/d/DEV/Godot/Godot_v4.7.2-stable_win64.exe}"
[ -x "$GODOT" ] || [ -f "$GODOT" ] || { echo "Godot não encontrado: $GODOT (defina GODOT_BIN)"; exit 3; }
if [ -n "${APPDATA:-}" ]; then REAL="$APPDATA/Godot/app_userdata/project.godot/savegame.json"; else REAL="$HOME/.local/share/godot/app_userdata/project.godot/savegame.json"; fi
md5() { [ -f "$1" ] && md5sum "$1" | cut -d' ' -f1 || echo "-"; }
ANTES=$(md5 "$REAL")
TMPD="${TEMP:-/tmp}"
if command -v cygpath >/dev/null; then FAKE="$(cygpath -w "$TMPD")\\deep_iron_testes\\fake_appdata"; mkdir -p "$(cygpath -u "$FAKE")"; else FAKE="$TMPD/deep_iron_testes/fake_appdata"; mkdir -p "$FAKE"; fi
LOG="$TMPD/deep_iron_testes/gut_ultimo.log"
FILTRO=()
[ -n "${1:-}" ] && FILTRO=("-gunit_test_name=$1")
APPDATA="$FAKE" XDG_DATA_HOME="$FAKE" LOCALAPPDATA="$FAKE" "$GODOT" --headless --path "$RAIZ/project.godot" -s addons/gut/gut_cmdln.gd "${FILTRO[@]}" > "$LOG" 2>&1
grep -E "Passing Tests|Failing Tests|\[Failed\]|^Tests " "$LOG"
DEPOIS=$(md5 "$REAL")
echo "save real: md5 antes $ANTES / depois $DEPOIS   (log completo: $LOG)"
[ "$ANTES" != "$DEPOIS" ] && { echo "ATENÇÃO: o save real mudou durante os testes!"; exit 2; }
grep -qE "Failing Tests +[1-9]" "$LOG" && exit 1
grep -q "Passing Tests" "$LOG" || exit 1
exit 0
