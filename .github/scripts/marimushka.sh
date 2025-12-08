#!/bin/sh
# Export Marimo notebooks in ${MARIMO_FOLDER} to HTML under _marimushka
# This replicates the previous Makefile logic for maintainability and reuse.

set -e

MARIMO_FOLDER=${MARIMO_FOLDER:-book/marimo}
UV_BIN=${UV_BIN:-./bin/uv}
UVX_BIN=${UVX_BIN:-./bin/uvx}

BLUE="\033[36m"
YELLOW="\033[33m"
RESET="\033[0m"

printf "%b[INFO] Exporting notebooks from %s...%b\n" "$BLUE" "$MARIMO_FOLDER" "$RESET"

if [ ! -d "$MARIMO_FOLDER" ]; then
  printf "%b[WARN] Directory '%s' does not exist. Skipping marimushka.%b\n" "$YELLOW" "$MARIMO_FOLDER" "$RESET"
  exit 0
fi

# Ensure output directory exists
mkdir -p _marimushka

# Discover .py files (top-level only) using globbing; handle no-match case
set -- "$MARIMO_FOLDER"/*.py
if [ "$1" = "$MARIMO_FOLDER/*.py" ]; then
  printf "%b[WARN] No Python files found in '%s'.%b\n" "$YELLOW" "$MARIMO_FOLDER" "$RESET"
  # Create a minimal index.html indicating no notebooks
  mkdir -p _marimushka
  printf '<html><head><title>Marimo Notebooks</title></head><body><h1>Marimo Notebooks</h1><p>No notebooks found.</p></body></html>' > _marimushka/index.html
  exit 0
fi

# Add src to PYTHONPATH so marimo can find the config package
if [ -d "src" ]; then
  export PYTHONPATH="${PYTHONPATH}:$(pwd)/src"
fi

# Run marimushka export
"$UVX_BIN" marimushka export --notebooks "$MARIMO_FOLDER" --output _marimushka

# Ensure GitHub Pages does not process with Jekyll
: > _marimushka/.nojekyll
