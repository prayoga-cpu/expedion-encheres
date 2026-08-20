#!/usr/bin/env bash
#
# Starts everything a local Flutter run needs before starting Flutter itself:
# expeditoo-ship's Postgres cluster, then its `next dev` server, waiting for
# each to actually be ready rather than just "started". Without this,
# `flutter run` races expeditoo-ship's cold start — the first request to
# /api/expedion/quotes can land before Next has even bound the port, and
# "Mes devis" shows a dead-end error instead of data.
#
#   tools/dev.sh [flutter run args...]
#
# Idempotent — safe to run whether or not expeditoo-ship is already up.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHIP_DIR="$REPO_ROOT/../expeditoo-ship"
HEALTH_URL="http://localhost:3000/api/health"
LOG_FILE="/tmp/expeditoo-ship-dev.log"

if [ ! -d "$SHIP_DIR" ]; then
  echo "❌ expeditoo-ship not found at $SHIP_DIR — clone it as a sibling of this repo." >&2
  exit 1
fi

is_healthy() {
  [ "$(curl -s -o /dev/null -w '%{http_code}' "$HEALTH_URL" 2>/dev/null)" = "200" ]
}

if is_healthy; then
  echo "✅ expeditoo-ship already serving on localhost:3000"
else
  echo "▶️  Starting expeditoo-ship's local Postgres…"
  (cd "$SHIP_DIR" && pnpm db:start)

  echo "▶️  Starting expeditoo-ship (pnpm dev), logging to $LOG_FILE…"
  (cd "$SHIP_DIR" && nohup pnpm dev >"$LOG_FILE" 2>&1 &)

  echo -n "⏳ Waiting for localhost:3000"
  ready=false
  for _ in $(seq 1 60); do
    if is_healthy; then
      ready=true
      break
    fi
    echo -n "."
    sleep 1
  done
  echo ""

  if [ "$ready" != "true" ]; then
    echo "❌ expeditoo-ship did not become healthy within 60s — see $LOG_FILE" >&2
    exit 1
  fi
  echo "✅ expeditoo-ship is ready on localhost:3000"
fi

echo "▶️  Starting Flutter…"
cd "$REPO_ROOT"
exec flutter run "$@"
