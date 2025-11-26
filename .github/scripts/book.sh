#!/bin/sh
# Assemble the combined documentation site into _book
# - Copies API docs (pdoc), coverage, test report, and marimushka exports
# - Generates a links.json consumed by minibook
#
# This script mirrors the logic previously embedded in the Makefile `book` target
# for maintainability and testability. It is POSIX-sh compatible.

set -e

BLUE="\033[36m"
YELLOW="\033[33m"
RESET="\033[0m"

printf "%b[INFO] Building combined documentation...%b\n" "$BLUE" "$RESET"
printf "%b[INFO] Ensuring jq is installed...%b\n" "$BLUE" "$RESET"

# Best-effort install of jq depending on the platform; non-fatal on failure
if ! command -v jq >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else SUDO=""; fi
    $SUDO apt-get update && $SUDO apt-get install -y jq || true
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache jq || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y jq || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq || true
  else
    printf "%b[WARN] Could not install jq automatically. Proceeding, but book task may have limited functionality.%b\n" "$YELLOW" "$RESET"
  fi
fi

printf "%b[INFO] Delete the _book folder...%b\n" "$BLUE" "$RESET"
rm -rf _book
printf "%b[INFO] Create empty _book folder...%b\n" "$BLUE" "$RESET"
mkdir -p _book
: > _book/links.json

printf "%b[INFO] Copy API docs...%b\n" "$BLUE" "$RESET"
if [ -f _pdoc/index.html ]; then
  mkdir -p _book/pdoc
  cp -r _pdoc/* _book/pdoc
  echo '{"API": "./pdoc/index.html"}' > _book/links.json
else
  echo '{}' > _book/links.json
fi

printf "%b[INFO] Copy coverage report...%b\n" "$BLUE" "$RESET"
if [ -f _tests/html-coverage/index.html ]; then
  mkdir -p _book/tests/html-coverage
  cp -r _tests/html-coverage/* _book/tests/html-coverage
  jq '. + {"Coverage": "./tests/html-coverage/index.html"}' _book/links.json > _book/tmp && mv _book/tmp _book/links.json
else
  printf "%b[WARN] No coverage report found or directory is empty%b\n" "$YELLOW" "$RESET"
fi

printf "%b[INFO] Copy test report...%b\n" "$BLUE" "$RESET"
if [ -f _tests/html-report/report.html ]; then
  mkdir -p _book/tests/html-report
  cp -r _tests/html-report/* _book/tests/html-report
  jq '. + {"Test Report": "./tests/html-report/report.html"}' _book/links.json > _book/tmp && mv _book/tmp _book/links.json
else
  printf "%b[WARN] No test report found or directory is empty%b\n" "$YELLOW" "$RESET"
fi

printf "%b[INFO] Copy notebooks...%b\n" "$BLUE" "$RESET"
if [ -f _marimushka/index.html ]; then
  mkdir -p _book/marimushka
  cp -r _marimushka/* _book/marimushka
  jq '. + {"Notebooks": "./marimushka/index.html"}' _book/links.json > _book/tmp && mv _book/tmp _book/links.json
  printf "%b[INFO] Copied notebooks into _book/marimushka%b\n" "$BLUE" "$RESET"
else
  printf "%b[WARN] No notebooks found or directory is empty%b\n" "$YELLOW" "$RESET"
fi

printf "%b[INFO] Generated links.json:%b\n" "$BLUE" "$RESET"
cat _book/links.json
