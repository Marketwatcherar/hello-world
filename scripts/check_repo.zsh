#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Checking repository at: ${REPO_ROOT}"

if [[ ! -d "${REPO_ROOT}/.git" ]]; then
  echo "❌ .git directory not found in ${REPO_ROOT}"
  exit 1
fi

required_paths=(
  "${REPO_ROOT}/Cats"
  "${REPO_ROOT}/Cats/index.html"
  "${REPO_ROOT}/scripts"
  "${REPO_ROOT}/scripts/run_app.sh"
  "${REPO_ROOT}/scripts/test_app.sh"
  "${REPO_ROOT}/README.md"
  "${REPO_ROOT}/IMPLEMENTATION_PACKAGE.md"
)

for p in "${required_paths[@]}"; do
  if [[ -e "$p" ]]; then
    echo "✅ Found: $p"
  else
    echo "❌ Missing: $p"
    exit 1
  fi
done

echo "✅ Repository structure looks correct."
