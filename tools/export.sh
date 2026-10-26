#!/usr/bin/env bash
# Exporta o jogo para Web, Linux, Windows e Android e gera em build/ um .zip de
# cada versão de PC e o .apk do Android.
# A versão web vai embutida (web/site.zip) nas builds de PC e Android: quem
# hospeda a serve para os navegadores da rede (autoload/web_host.gd).
# Uso: tools/export.sh [caminho/do/godot]
# Requer os modelos de exportação do Godot 4.7.2 instalados
# (Editor > Gerenciar modelos de exportação) e, para o Android, o JDK 17 e o
# Android SDK configurados nas configurações do editor (veja o README).
#
# O APK é assinado com a chave de depuração do Godot, a menos que estas
# variáveis apontem para uma chave de release:
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH, GODOT_ANDROID_KEYSTORE_RELEASE_USER,
#   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT="${1:-../Godot_v4.7.2-stable_linux.x86_64}"
VERSION="$(grep -m1 '^config/version=' project.godot | cut -d'"' -f2)"

if [[ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ]]; then
	DEBUG_KEYSTORE="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$HOME/.local/share/godot/keystores/debug.keystore}"
	if [[ ! -f "$DEBUG_KEYSTORE" ]]; then
		echo "Chave de depuração não encontrada em $DEBUG_KEYSTORE (veja o README)." >&2
		exit 1
	fi
	echo "APK assinado com a chave de depuração ($DEBUG_KEYSTORE)."
	export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$DEBUG_KEYSTORE"
	export GODOT_ANDROID_KEYSTORE_RELEASE_USER="androiddebugkey"
	export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="android"
else
	echo "APK assinado com a chave de release ($GODOT_ANDROID_KEYSTORE_RELEASE_PATH)."
fi

mkdir -p build/linux build/windows build/android build/web
touch build/.gdignore

rm -rf build/web/*
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
[[ -s build/web/index.wasm ]] || { echo "Falha ao exportar a versão web." >&2; exit 1; }
rm -f web/site.zip
(cd build/web && zip -q -r ../../web/site.zip .)

"$GODOT" --headless --path . --export-release "Linux" build/linux/PiqueProp.x86_64
"$GODOT" --headless --path . --export-release "Windows" build/windows/PiqueProp.exe
rm -f build/android/PiqueProp.apk
"$GODOT" --headless --path . --export-release "Android" build/android/PiqueProp.apk
# O Godot pode terminar com código 0 mesmo quando a exportação falha.
[[ -s build/android/PiqueProp.apk ]] || { echo "Falha ao exportar o APK." >&2; exit 1; }

rm -f build/PiqueProp-*.zip build/PiqueProp-*.apk
(cd build/linux && zip -q "../PiqueProp-${VERSION}-linux.zip" PiqueProp.x86_64)
(cd build/windows && zip -q "../PiqueProp-${VERSION}-windows.zip" PiqueProp.exe)
cp build/android/PiqueProp.apk "build/PiqueProp-${VERSION}-android.apk"
ls -lh build/*.zip build/*.apk
