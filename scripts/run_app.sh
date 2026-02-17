#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8080}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ ! -f "${REPO_ROOT}/Cats/index.html" ]]; then
  echo "Could not find ${REPO_ROOT}/Cats/index.html"
  echo "Make sure you're running inside the repository."
  exit 1
fi

echo "Serving repo root: ${REPO_ROOT}"
echo "Open: http://localhost:${PORT}/Cats/"
python3 -m http.server "${PORT}" --directory "${REPO_ROOT}"
