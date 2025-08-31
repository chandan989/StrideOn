# syntax=docker/dockerfile:1.7

# ---------- Base image ----------
FROM python:3.11-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -ms /bin/bash appuser
WORKDIR /app

# ---------- Dependencies layer ----------
FROM base AS deps
COPY requirements.txt /tmp/requirements.txt
RUN python -m pip install --upgrade pip \
 && pip wheel --wheel-dir /wheels -r /tmp/requirements.txt

# ---------- Runtime image ----------
FROM base AS runtime

# Copy wheels and install
COPY --from=deps /wheels /wheels
RUN pip install --no-index --find-links=/wheels /wheels/*

# Copy app code
COPY . /app

# Expose port
EXPOSE 8000

# Healthcheck hits /health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8000/health || exit 1

# Drop privileges
USER appuser

# Default command: run uvicorn
ENV HOST=0.0.0.0 PORT=8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
