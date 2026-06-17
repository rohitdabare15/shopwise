# ── Stage 1: Builder ──────────────────────────────────────────
# Install dependencies in a separate stage so the final image
# doesn't include pip, build tools, or cached packages.
FROM python:3.12-slim AS builder

WORKDIR /build

# Copy only requirements first — Docker caches this layer.
# If requirements.txt doesn't change, pip install is skipped
# on subsequent builds. Huge time saver.
COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Runtime ──────────────────────────────────────────
# Start fresh from the same slim base — no build tools included.
FROM python:3.12-slim AS runtime

# Security: run as non-root user
# If a vulnerability is exploited, the attacker gets a restricted user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy only the installed packages from the builder stage
COPY --from=builder /install /usr/local

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose the port Gunicorn will listen on
EXPOSE 5000

# Health check — Docker and Kubernetes use this to monitor the container
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" \
    || exit 1

# Gunicorn is the production WSGI server
# --workers 2: 2 worker processes (tune to 2*CPU+1 in prod)
# --threads 2: 2 threads per worker
# --timeout 120: kill workers that take >120s
CMD ["gunicorn", \
     "--bind", "0.0.0.0:5000", \
     "--workers", "2", \
     "--threads", "2", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "wsgi:app"]
