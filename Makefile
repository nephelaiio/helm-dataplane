.PHONY: all ${MAKECMDGOALS}

GIT_COMMIT := $$(date +%Y%m%d%H%M%S)

KIND_RELEASE := $$(yq eval '.jobs.molecule.strategy.matrix.include[0].release ' .github/workflows/molecule.yml)
KIND_IMAGE := $$(yq eval '.jobs.molecule.strategy.matrix.include[0].image' .github/workflows/molecule.yml)
ROLE_NAME := $$(pwd | xargs basename)
SCENARIO ?= default
EPHEMERAL_DIR := $$HOME/.cache/molecule/$(ROLE_NAME)/$(SCENARIO)

PAGILA_DB := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_db' molecule/default/molecule.yml -r)
PAGILA_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_namespace' molecule/default/molecule.yml -r)
PAGILA_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_team' molecule/default/molecule.yml -r)
PAGILA_USER := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_user' molecule/default/molecule.yml -r)
PAGILA_PASS := $$(make --no-print-directory kubectl get secret $(PAGILA_USER)-$(PAGILA_TEAM)-$(PAGILA_DB) -- -n $(PAGILA_NS) -o json | jq '.data.password' -r | base64 -d )
PAGILA_HOST := $$(make --no-print-directory kubectl get service -- -n $(PAGILA_NS) -o json | jq ".items | map(select(.metadata.name == \"$(PAGILA_TEAM)-$(PAGILA_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

DATAPLANE_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_namespace' molecule/default/molecule.yml -r)
DATAPLANE_CHART := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_chart' molecule/default/molecule.yml -r)

METABASE_DB := metabase
METABASE_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_chart' molecule/default/molecule.yml -r)
METABASE_USER := metabase
METABASE_PASS := $$(make --no-print-directory kubectl get secret $(METABASE_USER)-$(METABASE_TEAM)-$(METABASE_DB) -- -n $(DATAPLANE_NS) -o json | jq '.data.password' -r | base64 -d )
METABASE_HOST := $$(make --no-print-directory kubectl get service -- -n $(DATAPLANE_NS) -o json | jq ".items | map(select(.metadata.name == \"$(METABASE_TEAM)-$(METABASE_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

WAREHOUSE_DB := warehouse
WAREHOUSE_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_namespace' molecule/default/molecule.yml -r)
WAREHOUSE_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_chart' molecule/default/molecule.yml -r)
WAREHOUSE_USER := warehouse_reader_user
WAREHOUSE_PASS := $$(make --no-print-directory kubectl get secret warehouse-reader-user-$(WAREHOUSE_TEAM)-$(WAREHOUSE_DB) -- -n $(WAREHOUSE_NS) -o json | jq '.data.password' -r | base64 -d )
WAREHOUSE_HOST := $$(make --no-print-directory kubectl get service -- -n $(WAREHOUSE_NS) -o json | jq ".items | map(select(.metadata.name == \"$(WAREHOUSE_TEAM)-$(WAREHOUSE_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

DOCKER_REGISTRY_PORT := $$(yq eval '.provisioner.inventory.hosts.all.vars.kind_registry_port' molecule/default/molecule.yml -r)
DOCKER_REGISTRY ?= localhost:$$(yq eval '.provisioner.inventory.hosts.all.vars.kind_registry_port' ../molecule/default/molecule.yml -r)/
DOCKER_USER ?= nephelaiio
DATAPLANE_RELEASE ?= latest

test:
	./bin/test

dependency create prepare converge idempotence side-effect verify destroy cleanup reset list:
	KIND_RELEASE=$(KIND_RELEASE) \
	KIND_IMAGE=$(KIND_IMAGE) \
	poetry run molecule $@ -s $(SCENARIO)

purge:
	@echo cleaning ansible cache
	if [ -d $(HOME)/.cache/ansible-compat/ ]; then \
		find $(HOME)/.cache/ansible-compat/ -mindepth 2 -maxdepth 2 -type d -name "roles" | xargs -r rm -rf; \
	fi ;

clean: destroy reset purge
	@poetry env remove $$(which python) >/dev/null 2>&1 || exit 0

ifeq (run,$(firstword $(MAKECMDGOALS)))
    RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(subst $(space),,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))):;@:)
endif

run:
	$(EPHEMERAL_DIR)/bwrap ${RUN_ARGS}

ifeq (helm,$(firstword $(MAKECMDGOALS)))
    HELM_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(subst $(space),,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))):;@:)
endif

helm:
	KUBECONFIG=$(EPHEMERAL_DIR)/config helm ${HELM_ARGS}

ifeq (kubectl,$(firstword $(MAKECMDGOALS)))
    KUBECTL_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(subst $(space),,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))):;@:)
endif

kubectl:
	@KUBECONFIG=$(EPHEMERAL_DIR)/config kubectl ${KUBECTL_ARGS}

poetry:
	@poetry install --no-root

ifeq (pagila,$(firstword $(MAKECMDGOALS)))
    PAGILA_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(subst $(space),,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))):;@:)
endif

pagila:
	@PGPASSWORD=$(PAGILA_PASS) psql -h $(PAGILA_HOST) -U $(PAGILA_USER) -d $(PAGILA_DB) ${PAGILA_ARGS}

ifeq (metabase,$(firstword $(MAKECMDGOALS)))
    METABASE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(subst $(space),,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))):;@:)
endif

metabase:
	@PGPASSWORD=$(METABASE_PASS) psql -h $(METABASE_HOST) -U $(METABASE_USER) -d $(METABASE_DB) ${METABASE_ARGS}

ifeq (warehouse,$(firstword $(MAKECMDGOALS)))
    WAREHOUSE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(subst $(space),,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))):;@:)
endif

warehouse:
	@PGPASSWORD=$(WAREHOUSE_PASS) psql -h $(WAREHOUSE_HOST) -U $(WAREHOUSE_USER) -d $(WAREHOUSE_DB) ${WAREHOUSE_ARGS}

images: dataplane-connect dataplane-util
	docker image prune --force && \
	curl -s http://localhost:$(DOCKER_REGISTRY_PORT)/v2/_catalog | jq

dataplane-connect:
	cd connect && \
	docker build \
		--rm \
		--tag "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		. && \
	docker image push "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)"

dataplane-util:
	cd util ; \
	docker build \
		--rm \
		--tag "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		. ; \
	docker image push "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)"

wait:
	@export KUBECONFIG=$(EPHEMERAL_DIR)/config && \
	echo wait for service startup && \
	kubectl rollout status deployment/$(DATAPLANE_CHART)-registry -n $(DATAPLANE_NS) && \
	kubectl get pod -l "app.kubernetes.io/name=kafka-connect" -n $(DATAPLANE_NS) -o name | \
		xargs kubectl wait --for=jsonpath='{.status.phase}'=Running -n $(DATAPLANE_NS)

strimzi: strimzi-topics

strimzi-topics topics:
	@export KUBECONFIG=$(EPHEMERAL_DIR)/config && \
	kubectl get pod -n dataplane -o name -l "strimzi.io/component-type=kafka" -l "strimzi.io/broker-role=true" 2> /dev/null | \
		xargs -I{} kubectl exec -it {} -n $(DATAPLANE_NS) -- \
			/opt/kafka/bin/kafka-topics.sh --bootstrap-server $(DATAPLANE_CHART)-strimzi-kafka-bootstrap:9092 --list 2> /dev/null

strimzi-connector-logs connector-logs:
	@export KUBECONFIG=$(EPHEMERAL_DIR)/config && \
	kubectl get pod -n dataplane -o name -l "strimzi.io/component-type=kafka-connect" 2>/dev/null | \
		xargs -I{} kubectl logs {} -n $(DATAPLANE_NS)

strimzi-connectors connectors:
	@export KUBECONFIG=$(EPHEMERAL_DIR)/config && \
	export CONNECTORS=$$(kubectl get pod -n dataplane -o name -l "strimzi.io/component-type=kafka-connect" 2>/dev/null | \
		xargs -I{} kubectl exec -it {} -n $(DATAPLANE_NS) -- \
			curl -s http://localhost:8083/connectors | jq '.[]' -r) 2>/dev/null && \
	for connector in $$CONNECTORS; do \
		kubectl exec -it svc/$(DATAPLANE_CHART)-connect-api -n $(DATAPLANE_NS) -- \
			curl -s http://localhost:8083/connectors/$$connector 2>/dev/null | jq; \
	done

strimzi-connector-restart connector-restart: wait
	@export KUBECONFIG=$(EPHEMERAL_DIR)/config && \
	export CONNECTORS=$$(kubectl get kafkaconnector -n dataplane -o name && \
	for connector in $$CONNECTORS; do \
		kubectl annotate kafkaconnector $$connector -n $(DATAPLANE_NS) strimzi.io/restart=true
	done

strimzi-connector-task-restart connector-task-restart: wait
	@export KUBECONFIG=$(EPHEMERAL_DIR)/config && \
	export CONNECTORS=$$(kubectl get kafkaconnector -n dataplane -o name && \
	for connector in $$CONNECTORS; do \
		kubectl annotate kafkaconnector $$connector -n $(DATAPLANE_NS) strimzi.io/restart-task=0
	done

template:
	helm template $(PWD)/charts/dataplane --values values.minimal.yml --namespace $(DATAPLANE_NS) --debug
