#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8080}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BASE_URL="http://127.0.0.1:${PORT}/Cats/"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [[ ! -f "${REPO_ROOT}/Cats/index.html" ]]; then
  echo "Missing ${REPO_ROOT}/Cats/index.html"
  exit 1
fi

echo "[1/4] Starting local web server on port ${PORT} from ${REPO_ROOT}..."
python3 -m http.server "$PORT" --directory "${REPO_ROOT}" >/tmp/edu_app_server.log 2>&1 &
SERVER_PID=$!
sleep 1

echo "[2/4] Checking app URL responds..."
HTTP_STATUS=$(curl -s -o /tmp/edu_app_index.html -w "%{http_code}" "$BASE_URL")
if [[ "$HTTP_STATUS" != "200" ]]; then
  echo "Expected HTTP 200 from ${BASE_URL}, got ${HTTP_STATUS}"
  echo "Tip: open http://127.0.0.1:${PORT}/Cats/index.html directly to confirm path."
  exit 1
fi

echo "[3/4] Checking key UI sections in HTML..."
for token in "Attendance" "Grades" "Behavior" "Family Feedback" "Sync Status"; do
  if ! grep -q "$token" /tmp/edu_app_index.html; then
    echo "Missing expected UI section: $token"
    exit 1
  fi
done

echo "[4/4] Smoke test passed ✅"
echo "You can now open ${BASE_URL} in your browser."
