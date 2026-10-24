#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-.}"
cd "$repo_root"

fd -t f \
  -e kt -e kts -e rs -e dart -e skir \
  . \
  services backend panel skir-src \
  --exclude build \
  --exclude .dart_tool \
  --exclude skirout \
  --exclude generated \
  --exclude '*.generated.dart' \
  --exclude '*.g.dart' \
  --exclude '*.freezed.dart' \
  | rg -v '(^|/)(test|tests|testkit|widgetbook|docs/adapters)/' \
  | sort
