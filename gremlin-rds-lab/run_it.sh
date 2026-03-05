export DB_NAME="$REPLACEME"     # or whatever you created
export DB_USER="$REPLACEME"
export DB_PASSWORD="$REPLACEME!"

uvicorn app:app --host 0.0.0.0 --port 8080
