##
# nephelaiio.k8s Ansible role
#
# @file
# @version 0.0.6

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
METABASE_USER := postgres
METABASE_PASS := $$(make --no-print-directory kubectl get secret $(METABASE_USER)-$(METABASE_TEAM)-$(METABASE_DB) -- -n $(DATAPLANE_NS) -o json | jq '.data.password' -r | base64 -d )
METABASE_HOST := $$(make --no-print-directory kubectl get service -- -n $(DATAPLANE_NS) -o json | jq ".items | map(select(.metadata.name == \"$(METABASE_TEAM)-$(METABASE_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

WAREHOUSE_DB := warehouse
WAREHOUSE_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_namespace' molecule/default/molecule.yml -r)
WAREHOUSE_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_chart' molecule/default/molecule.yml -r)
WAREHOUSE_USER := postgres
WAREHOUSE_PASS := $$(make --no-print-directory kubectl get secret $(WAREHOUSE_USER)-$(WAREHOUSE_TEAM)-$(WAREHOUSE_DB) -- -n $(WAREHOUSE_NS) -o json | jq '.data.password' -r | base64 -d )
WAREHOUSE_HOST := $$(make --no-print-directory kubectl get service -- -n $(WAREHOUSE_NS) -o json | jq ".items | map(select(.metadata.name == \"$(WAREHOUSE_TEAM)-$(WAREHOUSE_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

DOCKER_REGISTRY_PORT := $$(yq eval '.provisioner.inventory.hosts.all.vars.kind_registry_port' molecule/default/molecule.yml -r)
DOCKER_REGISTRY ?= localhost:$$(yq eval '.provisioner.inventory.hosts.all.vars.kind_registry_port' ../molecule/default/molecule.yml -r)/
DOCKER_USER ?= nephelaiio
DATAPLANE_RELEASE ?= latest

TARGETS = test poetry clean molecule run helm kubectl psql docker dataplane dataplane-connect images wait strimzi strimzi-topics strimzi-connectors strimzi-connector-status strimzi-connector-trace strimzi-connector-restart

.PHONY: $(TARGETS)

test:
	./bin/test

clean:
	@echo cleaning ansible cache
	if [ -d $(HOME)/.cache/ansible-compat/ ]; then \
		find $(HOME)/.cache/ansible-compat/ -mindepth 2 -maxdepth 2 -type d -name "roles" | xargs -r rm -rf; \
	fi ;

molecule: clean poetry
	KIND_RELEASE=$(KIND_RELEASE) KIND_IMAGE=$(KIND_IMAGE) poetry run molecule $(filter-out $(TARGETS),$(MAKECMDGOALS)) -s $(SCENARIO)

run:
	$(EPHEMERAL_DIR)/bwrap $(filter-out $@,$(MAKECMDGOALS))

helm:
	KUBECONFIG=$(EPHEMERAL_DIR)/config helm $(filter-out $@,$(MAKECMDGOALS))

kubectl:
	@KUBECONFIG=$(EPHEMERAL_DIR)/config kubectl $(filter-out $@,$(MAKECMDGOALS))

poetry:
	@poetry install --only dev --no-root

pagila:
	@PGPASSWORD=$(PAGILA_PASS) psql -h $(PAGILA_HOST) -U $(PAGILA_USER) -d $(PAGILA_DB) $(filter-out $@,$(MAKECMDGOALS))

metabase:
	@PGPASSWORD=$(METABASE_PASS) psql -h $(METABASE_HOST) -U $(METABASE_USER) -d $(METABASE_DB) $(filter-out $@,$(MAKECMDGOALS))

warehouse:
	@PGPASSWORD=$(WAREHOUSE_PASS) psql -h $(WAREHOUSE_HOST) -U $(WAREHOUSE_USER) -d $(WAREHOUSE_DB) $(filter-out $@,$(MAKECMDGOALS))

images: dataplane-connect dataplane-util
	docker image prune --force; \
	curl -s http://localhost:$(DOCKER_REGISTRY_PORT)/v2/_catalog | jq

dataplane-init:
	cd init ; \
	docker build \
		--rm \
		--tag "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		. ; \
	docker image push "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)"

dataplane-connect:
	cd connect ; \
	docker build \
		--rm \
		--tag "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		. ; \
	docker image push "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)"

dataplane-util:
	cd util ; \
	docker build \
		--rm \
		--tag "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		. ; \
	docker image push "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)"

wait:
	@echo wait for service startup ; \
	make --no-print-directory kubectl rollout status deployment/$(DATAPLANE_CHART)-registry -- -n $(DATAPLANE_NS) ; \
	make --no-print-directory kubectl rollout status deployment/$(DATAPLANE_CHART)-connect -- -n $(DATAPLANE_NS) ; \

strimzi: strimzi-topics

strimzi-topics:
	make --no-print-directory kubectl exec -- -it pod/$(DATAPLANE_CHART)-strimzi-kafka-0 -n $(DATAPLANE_NS) -- "/opt/kafka/bin/kafka-topics.sh --bootstrap-server $(DATAPLANE_CHART)-strimzi-kafka-bootstrap:9092 --list"

strimzi-connectors:
	@make --no-print-directory kubectl exec -- -it svc/$(DATAPLANE_CHART)-connect-api -n $(DATAPLANE_NS) -- \
		curl -s http://localhost:8083/connectors \
		| jq '.[]' -r \
		| xargs -I{} make --no-print-directory kubectl exec svc/$(DATAPLANE_CHART)-connect-api -- -it -n $(DATAPLANE_NS) -- \
		curl -s http://localhost:8083/connectors/\{\} 2>/dev/null

strimzi-connector-status:
	@make --no-print-directory kubectl exec -- -it svc/$(DATAPLANE_CHART)-connect-api -n $(DATAPLANE_NS) -- \
		curl -s http://localhost:8083/connectors \
		| jq '.[]' -r \
		| xargs -I{} make --no-print-directory kubectl exec svc/$(DATAPLANE_CHART)-connect-api -- -it -n $(DATAPLANE_NS) -- \
		curl -s http://localhost:8083/connectors/\{\}/status 2>/dev/null | jq '.tasks | map(.state) | .[]' -r

strimzi-connector-trace:
	@make --no-print-directory kubectl exec -- -it svc/$(DATAPLANE_CHART)-connect-api -n $(DATAPLANE_NS) -- \
		curl -s http://localhost:8083/connectors \
		| jq '.[]' -r \
		| xargs -I{} make --no-print-directory kubectl exec svc/$(DATAPLANE_CHART)-connect-api -- -it -n $(DATAPLANE_NS) -- \
		curl -s http://localhost:8083/connectors/\{\}/status 2>/dev/null | jq '.tasks | map(.trace) | .[]' -r

strimzi-connector-restart: wait
	@echo restart kafka connectors ; \
	make --no-print-directory kubectl exec -- -it svc/$(DATAPLANE_CHART)-connect-api -n $(DATAPLANE_NS) -- \
		curl -s http://localhost:8083/connectors \
		| jq '.[]' -r \
		| xargs -I{} make --no-print-directory kubectl exec svc/$(DATAPLANE_CHART)-connect-api -- -it -n $(DATAPLANE_NS) -- \
		curl -s -XPOST http://localhost:8083/connectors/\{\}/restart 2>/dev/null ; \
	make --no-print-directory kubectl exec -- -it svc/$(DATAPLANE_CHART)-connect-api -n $(DATAPLANE_NS) -- \
		curl -s http://localhost:8083/connectors \
		| jq '.[]' -r \
		| xargs -I{} make --no-print-directory kubectl exec svc/$(DATAPLANE_CHART)-connect-api -- -it -n $(DATAPLANE_NS) -- \
		curl -s -XPOST http://localhost:8083/connectors/\{\}/tasks/0/restart 2>/dev/null

dataplane:
	@:

%:
	@:

# end
