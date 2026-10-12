#!/usr/bin/env bash
# Tira um print da tela inteira e grava em <pasta-de-provas>/maquete-NN.png.
# Usado pela skill /prompt-logan (Passo 5). Numera sozinho e nunca sobrescreve.
#
# Uso: bash capturar-tela.sh <pasta-de-provas> [prefixo-do-arquivo]
#
# macOS: usa screencapture (vem com o sistema).
# Linux: usa o primeiro que achar entre grim (Wayland), gnome-screenshot,
#        import (ImageMagick) e scrot.
set -euo pipefail

pasta_de_provas="${1:?uso: capturar-tela.sh <pasta-de-provas> [prefixo-do-arquivo]}"
prefixo_do_arquivo="${2:-maquete}"

mkdir -p "$pasta_de_provas"

numero_do_print=1
while [ -e "$(printf '%s/%s-%02d.png' "$pasta_de_provas" "$prefixo_do_arquivo" "$numero_do_print")" ]; do
  numero_do_print=$((numero_do_print + 1))
done
caminho_do_print="$(printf '%s/%s-%02d.png' "$pasta_de_provas" "$prefixo_do_arquivo" "$numero_do_print")"

case "$(uname -s)" in
  Darwin)
    screencapture -x "$caminho_do_print"
    ;;
  Linux)
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
      # No Wayland, import e scrot gravam imagem preta sem dar erro.
      if command -v grim >/dev/null 2>&1; then
        grim "$caminho_do_print"
      elif command -v gnome-screenshot >/dev/null 2>&1; then
        gnome-screenshot -f "$caminho_do_print"
      else
        echo "Wayland sem grim nem gnome-screenshot: instale um dos dois." >&2
        exit 1
      fi
    elif command -v gnome-screenshot >/dev/null 2>&1; then
      gnome-screenshot -f "$caminho_do_print"
    elif command -v import >/dev/null 2>&1; then
      import -window root "$caminho_do_print"
    elif command -v scrot >/dev/null 2>&1; then
      scrot "$caminho_do_print"
    else
      echo "Nenhuma ferramenta de print encontrada (grim, gnome-screenshot, import ou scrot)." >&2
      exit 1
    fi
    ;;
  *)
    echo "Sistema nao suportado: $(uname -s). No Windows, use capturar-tela.ps1." >&2
    exit 1
    ;;
esac

# Algumas ferramentas saem com 0 mesmo quando o usuario cancela a captura.
if [ ! -s "$caminho_do_print" ]; then
  echo "O print nao foi gravado em $caminho_do_print." >&2
  exit 1
fi

echo "PRINT: $(cd "$(dirname "$caminho_do_print")" && pwd)/$(basename "$caminho_do_print")"
