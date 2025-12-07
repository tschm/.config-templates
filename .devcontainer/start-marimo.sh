#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Configuration
MARIMO_BIN=".venv/bin/marimo"
MARIMO_FOLDER="book/marimo"
MARIMO_LOG="/tmp/marimo.log"
MARIMO_PORT=8080

# Maximum time to wait for marimo to be installed (in seconds)
# This should be enough for the onCreateCommand to complete
MAX_WAIT=30

# Wait for venv to be ready
count=0
while [ ! -f "$MARIMO_BIN" ] && [ $count -lt $MAX_WAIT ]; do
    echo "Waiting for marimo to be installed..."
    sleep 1
    count=$((count + 1))
done

if [ ! -f "$MARIMO_BIN" ]; then
    echo "Error: Marimo not found at $MARIMO_BIN after ${MAX_WAIT}s timeout"
    exit 1
fi

# Start Marimo server in the background
echo "Starting Marimo server on port $MARIMO_PORT..."
nohup "$MARIMO_BIN" edit "$MARIMO_FOLDER" --host 0.0.0.0 --port "$MARIMO_PORT" --headless > "$MARIMO_LOG" 2>&1 &

echo "Marimo server started. Check $MARIMO_LOG for output."
echo "Access the server at http://localhost:$MARIMO_PORT"
