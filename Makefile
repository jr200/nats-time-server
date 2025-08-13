include .env.local
ENV := $(shell cat .env.local)

DOCKER_IMAGE := ghcr.io/jr200/nats-time-server
DOCKER_TAG := local
POETRY_VERSION := 2.1.4

all:
	/bin/sh -lc '\
	  set -euo pipefail; \
	  set -a; \
	  . .env.local; \
	  set +a; \
	  start_api \
	'

install:
	pip uninstall -y pyapi_service_kit
	rm -rf poetry.lock
	poetry install
	poetry update

local-creds:
	@mkdir -p secrets
	$(shell /bin/bash -c "$(ENV) $$(curl -fsSL https://raw.githubusercontent.com/jr200/nats-infra/main/scripts/nats-create-account.sh) > secrets/app.creds")

check:
	ruff check --fix
	ruff format
	mypy .

build:
	podman build \
		-f Dockerfile \
		-t ${DOCKER_IMAGE}:${DOCKER_TAG} \
		--build-arg POETRY_VERSION=${POETRY_VERSION} \
		--layers=true \
		.

shell:
	podman run --env-file .env.local -it --rm \
		--volume ./secrets/app.creds:/secrets/app.creds:ro \
		--volume ./charts/nats-time-server/files/config.yaml:/config.yaml:ro \
		--entrypoint /bin/bash \
		${DOCKER_IMAGE}:${DOCKER_TAG}

up:
	podman compose --env-file .env.local -f compose-time-server.yaml -p ${TEAM_NAME} up -d

down:
	podman compose --env-file .env.local -f compose-time-server.yaml -p ${TEAM_NAME} down || echo "No running containers"
