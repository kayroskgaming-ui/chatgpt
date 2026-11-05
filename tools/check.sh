#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
check_log="$(mktemp "$XDG_CACHE_HOME/minhavida-tests.XXXXXX")"
trap 'rm -f "$check_log"' EXIT
for suite in run ui_run daily_life controller_run; do
  test_status=0
  "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "tests/$suite.gd" > "$check_log" 2>&1 || test_status=$?
  cat "$check_log"
  if [ "$test_status" -ne 0 ]; then exit "$test_status"; fi
  if rg -q 'SCRIPT ERROR|^ERROR:' "$check_log"; then
    echo "Erro de execução detectado em $suite." >&2
    exit 1
  fi
done
