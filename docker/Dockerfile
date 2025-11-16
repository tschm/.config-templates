# ================================
# Stage 1: Builder
# ================================
FROM ghcr.io/astral-sh/uv:0.9.9-python3.12-trixie-slim AS builder

ENV UV_SYSTEM_PYTHON=1
WORKDIR /app

# Create non-root user
RUN useradd -m app_user && chown app_user:app_user /app

# Copy dependency files
COPY uv.lock pyproject.toml README.md /app/

# Use non-root user
USER app_user

# Sync dependencies (no dev, no cache) into .venv
RUN uv sync --frozen --no-dev --no-cache

# Copy application code
COPY src /app

# Strip unnecessary files from .venv to save space
RUN find .venv -type d -name "__pycache__" -exec rm -rf {} + && \
    find .venv -type d -name "tests" -exec rm -rf {} + && \
    rm -rf .venv/share/man .venv/share/doc .venv/share/doc-base

# ================================
# Stage 2: Runtime
# ================================
FROM python:3.12-slim AS runtime

WORKDIR /app

# Install small system tools (pin versions and avoid recommends for smaller image)
RUN apt-get update && \
    apt-get install -y --no-install-recommends nano=8.* tree=2.* && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m app_user && chown app_user:app_user /app

# Copy stripped .venv and app from builder
COPY --from=builder --chown=app_user:app_user /app /app

# Set virtual environment PATH
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1

# Switch to non-root
USER app_user

