#!/usr/bin/env bash
set -euo pipefail

TARGET_ROOT="${1:-$HOME/workspace}"
REPO_NAME="hello-world"
TARGET_DIR="${TARGET_ROOT}/${REPO_NAME}"

mkdir -p "${TARGET_ROOT}"
echo "✅ Workspace folder ready: ${TARGET_ROOT}"

if [[ -d "${TARGET_DIR}/.git" ]]; then
  echo "✅ Repository already exists: ${TARGET_DIR}"
  exit 0
fi

echo "Repository not found at: ${TARGET_DIR}"
echo "Next step: clone your repo into that folder, e.g.:"
echo "  git clone https://github.com/<your-user>/<your-repo>.git ${TARGET_DIR}"
