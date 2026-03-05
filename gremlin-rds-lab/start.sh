#!/usr/bin/env bash
set -euo pipefail

# If set to 1, run DB seed automatically on container startup
SEED_ON_START="${SEED_ON_START:-1}"

# seed_rds.sh uses PGPASSWORD for auth, so mirror DB_PASSWORD into it (without storing on disk)
export PGPASSWORD="${PGPASSWORD:-${DB_PASSWORD:-}}"

if [[ "$SEED_ON_START" == "1" ]]; then
  echo "[start] Seeding database..."
  ./seed_rds.sh
fi

echo "[start] Launching API..."
exec uvicorn app:app --host 0.0.0.0 --port 8080
