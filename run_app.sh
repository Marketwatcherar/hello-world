#!/usr/bin/env bash
set -euo pipefail

if [[ -x "./scripts/run_app.sh" ]]; then
  exec ./scripts/run_app.sh "$@"
fi

echo "❌ Could not find ./scripts/run_app.sh"
echo "You are probably not in the repository root."
echo "Try:"
echo "  cd /workspace/hello-world"
echo "  ls -la scripts"
echo "  ./scripts/run_app.sh"
exit 1
