#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --script tests/run.gd
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --script tests/ui_run.gd
