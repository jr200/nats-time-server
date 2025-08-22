include .env.local
define RUN_WITH_ENV
/bin/sh -lc 'set -euo pipefail; set -a; . $(1); set +a; $(2)'
endef

DOCKER_IMAGE := ghcr.io/jr200/nats-time-server
DOCKER_TAG := local
POETRY_VERSION := 2.1.4

K8S_NAMESPACE ?= nats-time-server
CHART_INSTANCE ?= my-nats-time-server

all:
	$(call RUN_WITH_ENV, .env.local, start_api)


local-creds:
	@mkdir -p secrets
	nats context select ${NATS_SYSTEM_CONTEXT}
	$(call RUN_WITH_ENV, .env.local, curl -fsSL https://raw.githubusercontent.com/jr200/nats-infra/main/scripts/nats-create-account.sh | /bin/bash -s -- > secrets/sa-nats-time-server.creds)

check:
	ruff check --fix
	ruff format
	mypy .

shell:
	docker run -it --env-file .env.local --rm --entrypoint /bin/bash ${DOCKER_IMAGE}:${DOCKER_TAG}

build:
	docker build \
		-f docker/Dockerfile \
		-t ${DOCKER_IMAGE}:${DOCKER_TAG} \
		.

up:
	docker compose --env-file .env.local -f compose-nats-s3-monitor.yaml -p ${TEAM_NAME} up -d

down:
	docker compose --env-file .env.local -f compose-nats-s3-monitor.yaml -p ${TEAM_NAME} down || echo "No running containers"


chart-deps:
	kubectl create namespace ${K8S_NAMESPACE} || echo "OK"
	
	kubectl create secret generic -n ${K8S_NAMESPACE} nats-time-server-env \
	--from-env-file=.env.local.k8s || echo "OK"

	kubectl create secret generic -n ${K8S_NAMESPACE} nats-user-credentials \
	--from-file=app.creds=secrets/sa-nats-time-server.creds || echo "OK"


chart-install: chart-deps
	kubectl create namespace ${K8S_NAMESPACE} || echo "OK"
	helm upgrade --install -n ${K8S_NAMESPACE} ${CHART_INSTANCE} -f charts/values.yaml stakater/application

chart-template:
	helm template --debug -n ${K8S_NAMESPACE} ${CHART_INSTANCE} -f charts/values.yaml stakater/application > charts/zz_rendered.yaml

chart-uninstall:
	helm uninstall -n ${K8S_NAMESPACE} ${CHART_INSTANCE} || echo "OK"
	kubectl delete secret -n ${K8S_NAMESPACE} nats-time-server-env || echo "OK"
	kubectl delete secret -n ${K8S_NAMESPACE} nats-user-credentials || echo "OK"
	kubectl delete configmap -n ${K8S_NAMESPACE} nats-time-server-config || echo "OK"
