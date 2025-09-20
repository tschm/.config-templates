#!/bin/bash

# Set UV environment variables to avoid prompts and warnings
export UV_VENV_CLEAR=1
export UV_LINK_MODE=copy

# Make UV environment variables persistent for all sessions
echo "export UV_VENV_CLEAR=1" >> ~/.bashrc
echo "export UV_LINK_MODE=copy" >> ~/.bashrc

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create virtual environment and install all dependencies including dev and notebooks
uv venv
uv sync --all-extras

# Initialize pre-commit hooks (in background to not block startup)
nohup uv run pre-commit install > /dev/null 2>&1 &