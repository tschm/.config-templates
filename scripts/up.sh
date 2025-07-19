#!/bin/bash
# Script: up.sh
# Description: Safely updates config files from GitHub without branch switching
# Author: Thomas Schmelzer

set -euo pipefail

REPO_URL="https://github.com/tschm/.config-templates"
TEMP_DIR="$(mktemp -d)"

main() {
  curl -sSL -o templates.zip "$REPO_URL/archive/refs/heads/main.zip"
  unzip -q templates.zip -d "$TEMP_DIR"
  rm -f templates.zip

  EXTRACTED_DIR="${TEMP_DIR}/.config-templates-main"
  # don't copy the script itself into the repo
  rm "${TEMP_DIR}/.config-templates-main/scripts/up.sh"
  cp -Rf $EXTRACTED_DIR/. .

  git status
}
trap 'rm -rf "$TEMP_DIR"' EXIT
main "$@"
