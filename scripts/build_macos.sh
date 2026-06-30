#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/stephen/Dev/envirioment/flutter/bin/flutter}"

cd "${PROJECT_ROOT}"

echo "== Flutter analyze =="
"${FLUTTER_BIN}" analyze

echo
echo "== Flutter tests =="
"${FLUTTER_BIN}" test

echo
echo "== Flutter macOS release build =="
"${FLUTTER_BIN}" build macos

echo
echo "Built app:"
echo "${PROJECT_ROOT}/build/macos/Build/Products/Release/archi_vision.app"

if [[ -n "${SKETCHUP_SDK_ROOT:-}" ]]; then
  echo
  echo "== Native skp_processor build =="
  cmake -S native/skp_processor -B native/skp_processor/build \
    -DCMAKE_BUILD_TYPE=Release \
    -DSKETCHUP_SDK_ROOT="${SKETCHUP_SDK_ROOT}"
  cmake --build native/skp_processor/build --config Release
else
  echo
  echo "Skipping skp_processor: SKETCHUP_SDK_ROOT is not set."
fi
