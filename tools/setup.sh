#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
version="$($GODOT_BIN --version)"
case "$version" in 4.6.3.stable*) ;; *) echo "É necessário Godot 4.6.3 estável; encontrado: $version" >&2; exit 1 ;; esac
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --editor --import --quit
bash "$PROJECT_DIR/tools/check.sh"
