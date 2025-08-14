FROM python:3.13 AS builder

ARG POETRY_VERSION=2.1.4

RUN useradd -d /app -m -s /bin/bash app_user
WORKDIR /app

ENV POETRY_VIRTUALENVS_CREATE=true \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_VIRTUALENVS_USE_POETRY_PYTHON=true \
    POETRY_NO_INTERACTION=1 \
    POETRY_REQUESTS_TIMEOUT=240 \
    POETRY_REQUESTS_MAX_RETRIES=3 \
    PIP_DEFAULT_TIMEOUT=240 \
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

RUN poetry install --only main --no-root -vvvv

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
COPY --chown=app_user:app_user ./docker/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT /docker-entrypoint.sh
