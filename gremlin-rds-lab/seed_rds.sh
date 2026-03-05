#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:?DB_HOST is required}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:?DB_USER is required}"
DB_NAME="${DB_NAME:-gremlin_rds_test}"

# Optional: create the database if it doesn't exist (set to 1 to enable)
CREATE_DB_IF_MISSING="${CREATE_DB_IF_MISSING:-0}"

echo "Using:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  User: $DB_USER"
echo "  DB:   $DB_NAME"
echo

# Password handling:
# - Provide via env var:
#   export PGPASSWORD='YOUR_PASSWORD'
# - OR configure ~/.pgpass (chmod 600)
if [[ -z "${PGPASSWORD:-}" ]] && [[ ! -f "$HOME/.pgpass" ]]; then
  echo "ERROR: Set PGPASSWORD or configure ~/.pgpass before running."
  echo "Example: export PGPASSWORD='YOUR_PASSWORD'"
  exit 1
fi

if [[ "$CREATE_DB_IF_MISSING" == "1" ]]; then
  echo "Ensuring database '$DB_NAME' exists..."
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}') THEN
    CREATE DATABASE ${DB_NAME};
  END IF;
END
\$\$;
SQL
  echo "Database check complete."
  echo
fi

echo "Creating tables + inserting seed data..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 <<'SQL'
BEGIN;

CREATE TABLE IF NOT EXISTS fruit (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS vegetables (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

INSERT INTO fruit (name) VALUES
('Apple'),('Apricot'),('Avocado'),('Banana'),('Blackberry'),
('Blueberry'),('Cantaloupe'),('Cherry'),('Coconut'),('Cranberry'),
('Date'),('Dragonfruit'),('Fig'),('Grape'),('Grapefruit'),
('Guava'),('Kiwi'),('Lemon'),('Lime'),('Mango'),
('Nectarine'),('Orange'),('Papaya'),('Peach'),('Pineapple')
ON CONFLICT (name) DO NOTHING;

INSERT INTO vegetables (name) VALUES
('Artichoke'),('Arugula'),('Asparagus'),('Beet'),('Bell Pepper'),
('Broccoli'),('Brussels Sprout'),('Cabbage'),('Carrot'),('Cauliflower'),
('Celery'),('Chard'),('Collard Greens'),('Cucumber'),('Eggplant'),
('Garlic'),('Green Bean'),('Kale'),('Leek'),('Lettuce'),
('Mushroom'),('Okra'),('Onion'),('Parsnip'),('Potato')
ON CONFLICT (name) DO NOTHING;

COMMIT;

SELECT 'fruit' AS table, COUNT(*) AS rows FROM fruit
UNION ALL
SELECT 'vegetables' AS table, COUNT(*) AS rows FROM vegetables;
SQL

echo
echo "Done."
