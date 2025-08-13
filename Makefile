include .env.local
ENV := $(shell cat .env.local)

all:
	start_api

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
