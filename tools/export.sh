#!/usr/bin/env bash
# Exporta o jogo para Linux e Windows e gera um .zip de cada um em build/.
# Uso: tools/export.sh [caminho/do/godot]
# Requer os modelos de exportação do Godot 4.7.2 instalados
# (Editor > Gerenciar modelos de exportação).
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT="${1:-../Godot_v4.7.2-stable_linux.x86_64}"
VERSION="$(grep -m1 '^config/version=' project.godot | cut -d'"' -f2)"

mkdir -p build/linux build/windows
touch build/.gdignore

"$GODOT" --headless --path . --export-release "Linux" build/linux/PiqueProp.x86_64
"$GODOT" --headless --path . --export-release "Windows" build/windows/PiqueProp.exe

rm -f build/PiqueProp-*.zip
(cd build/linux && zip -q "../PiqueProp-${VERSION}-linux.zip" PiqueProp.x86_64)
(cd build/windows && zip -q "../PiqueProp-${VERSION}-windows.zip" PiqueProp.exe)
ls -lh build/*.zip
