#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Wait for venv to be ready
MAX_WAIT=30
count=0
while [ ! -f .venv/bin/marimo ] && [ $count -lt $MAX_WAIT ]; do
    echo "Waiting for marimo to be installed..."
    sleep 1
    count=$((count + 1))
done

if [ ! -f .venv/bin/marimo ]; then
    echo "Error: Marimo not found in .venv/bin/marimo"
    exit 1
fi

# Start Marimo server in the background
echo "Starting Marimo server on port 8080..."
nohup .venv/bin/marimo edit book/marimo --host 0.0.0.0 --port 8080 --headless > /tmp/marimo.log 2>&1 &

echo "Marimo server started. Check /tmp/marimo.log for output."
echo "Access the server at http://localhost:8080"
