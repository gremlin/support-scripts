#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:?DB_HOST is required}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:?DB_USER is required}"
DB_NAME="${DB_NAME:-postgres}"

# Prefer PGPASSWORD; allow DB_PASSWORD for consistency with container env vars
export PGPASSWORD="${PGPASSWORD:-${DB_PASSWORD:-}}"
if [[ -z "${PGPASSWORD:-}" ]] && [[ ! -f "$HOME/.pgpass" ]]; then
  echo "ERROR: Set PGPASSWORD (or DB_PASSWORD) or configure ~/.pgpass before running."
  echo "Example:"
  echo "  export DB_HOST='...'; export DB_USER='...'; export DB_NAME='...'; export PGPASSWORD='...'"
  exit 1
fi

exec psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
