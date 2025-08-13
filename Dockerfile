FROM python:3.13 AS builder

ARG POETRY_VERSION=2.1.4

RUN useradd -d /app -m -s /bin/bash app_user
WORKDIR /app

ENV POETRY_VIRTUALENVS_CREATE=true \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    XDG_CACHE_HOME=/app/.cache \
    PATH="/app/.venv/bin:/app/.local/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER app_user

RUN curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION}

COPY --chown=app_user:app_user pyproject.toml poetry.lock* ./
# Install only runtime deps (exclude dev group)
RUN poetry install --only main --no-root --no-ansi

COPY --chown=app_user:app_user ./src/nats_time_server /app/nats_time_server


FROM python:3.13-slim-bookworm

RUN useradd -d /app -m -s /bin/bash app_user
WORKDIR /app

ENV PATH="/app/.venv/bin:/app/.local/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER app_user

COPY --from=builder --chown=app_user:app_user /app/nats_time_server /app/nats_time_server
COPY --from=builder --chown=app_user:app_user /app/.venv /app/.venv

ENTRYPOINT ["python", "-m", "nats_time_server.start_api"]
