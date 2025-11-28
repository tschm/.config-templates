#!/bin/bash
# This file is part of the tschm/.config-templates repository
# (https://github.com/tschm/.config-templates).
#
# Optional hook script for installing extra dependencies needed for book building
#
# Purpose: This script is called by the book workflow before building documentation.
#          Use it to install additional system packages or dependencies that your
#          project needs for documentation generation (e.g., graphviz for diagrams).
#
# Usage: This script is automatically executed if it exists in your repository.
#        Make sure it's executable: chmod +x .github/scripts/book-extras.sh
#
# Note: If you customize this file in your repository, add it to the exclude list
#       in action.yml to prevent it from being overwritten by template updates:
#       exclude: |
#         .github/scripts/book-extras.sh
#

set -euo pipefail

echo "Running book-extras.sh..."

# Add your custom installation commands here
# Example: Install graphviz
# sudo apt-get update
# sudo apt-get install -y graphviz

echo "Book extras setup complete."
