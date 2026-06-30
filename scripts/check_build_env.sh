#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/stephen/Dev/envirioment/flutter/bin/flutter}"

echo "== Flutter doctor =="
"${FLUTTER_BIN}" doctor -v

echo
echo "== Python backend =="
python3 -c "import ezdxf, matplotlib; print('Python deps ok: ezdxf + matplotlib')"

echo
echo "== ODA File Converter =="
ODA_BIN="/Applications/ODAFileConverter.app/Contents/MacOS/ODAFileConverter"
if [[ -x "${ODA_BIN}" ]]; then
  echo "ODA ok: ${ODA_BIN}"
else
  echo "Missing ODA: ${ODA_BIN}" >&2
  exit 1
fi

echo
echo "== CMake =="
cmake --version

echo
echo "== SketchUp C API SDK =="
if [[ -n "${SKETCHUP_SDK_ROOT:-}" && -f "${SKETCHUP_SDK_ROOT}/headers/SketchUpAPI/sketchup.h" ]]; then
  echo "SketchUp SDK ok: ${SKETCHUP_SDK_ROOT}"
else
  echo "SketchUp SDK not configured."
  echo "Download SketchUp Desktop SDK from https://developer.sketchup.com/"
  echo "Then run: export SKETCHUP_SDK_ROOT=/path/to/SketchUp-SDK"
fi

echo
echo "Project root: ${PROJECT_ROOT}"
