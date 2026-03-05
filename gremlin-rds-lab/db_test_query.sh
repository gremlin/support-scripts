#!/usr/bin/env bash
set -uo pipefail

API_BASE_URL="${API_BASE_URL:-http://localhost:8080}"
ENDPOINT="${ENDPOINT:-/fruits}"
SLEEP_SECONDS="${SLEEP_SECONDS:-3}"
LOG_FILE="${LOG_FILE:-fruits_latency.log}"

# Stop curl from hanging forever during blackhole tests
CURL_TIMEOUT_SECONDS="${CURL_TIMEOUT_SECONDS:-5}"

# Require jq (you already have it in your container image)
command -v jq >/dev/null 2>&1 || {
  echo "ERROR: jq is required."
  exit 1
}

while true; do
  echo "----- $(date) -----" | tee -a "$LOG_FILE"

  # Capture body + status without letting a single failure kill the loop
  resp="$(curl -sS --max-time "$CURL_TIMEOUT_SECONDS" \
    -w '\n__HTTP_CODE__=%{http_code}\n' \
    "${API_BASE_URL}${ENDPOINT}" 2>&1)"
  rc=$?

  if [[ $rc -ne 0 ]]; then
    echo "curl_failed rc=$rc timeout=${CURL_TIMEOUT_SECONDS}s url=${API_BASE_URL}${ENDPOINT}" | tee -a "$LOG_FILE"
    echo "curl_output: $resp" | tee -a "$LOG_FILE"
    echo | tee -a "$LOG_FILE"
    sleep "$SLEEP_SECONDS"
    continue
  fi

  # Split response from HTTP code marker
  body="${resp%$'\n__HTTP_CODE__='*}"
  code="${resp##*$'\n__HTTP_CODE__='}"

  if [[ "$code" != "200" ]]; then
    echo "http_status=$code url=${API_BASE_URL}${ENDPOINT}" | tee -a "$LOG_FILE"
    echo "$body" | head -c 500 | tee -a "$LOG_FILE"
    echo | tee -a "$LOG_FILE"
    sleep "$SLEEP_SECONDS"
    continue
  fi

  # Print only timings_ms (and tolerate bad JSON)
  echo "$body" | jq '.timings_ms' 2>/dev/null | tee -a "$LOG_FILE" || {
    echo "json_parse_failed (showing first 500 chars):" | tee -a "$LOG_FILE"
    echo "$body" | head -c 500 | tee -a "$LOG_FILE"
    echo | tee -a "$LOG_FILE"
  }

  sleep "$SLEEP_SECONDS"
done
