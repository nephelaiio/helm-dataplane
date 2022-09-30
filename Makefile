##
# nephelaiio.k8s Ansible role
#
# @file
# @version 0.0.1

GIT_COMMIT := $$(date +%Y%m%d%H%M%S)

KIND_RELEASE := $$(yq eval '.jobs.molecule.strategy.matrix.include[0].release ' .github/workflows/molecule.yml)
K8S_RELEASE := $$(yq eval '.jobs.molecule.strategy.matrix.include[0].image' .github/workflows/molecule.yml)
ROLE_NAME := $$(pwd | xargs basename)
SCENARIO ?= default
EPHEMERAL_DIR := $$HOME/.cache/molecule/$(ROLE_NAME)/$(SCENARIO)

PAGILA_DB := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_db' molecule/default/molecule.yml -r)
PAGILA_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_namespace' molecule/default/molecule.yml -r)
PAGILA_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_team' molecule/default/molecule.yml -r)
PAGILA_USER := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_user' molecule/default/molecule.yml -r)
PAGILA_PASS := $$(make --no-print-directory kubectl get secret $(PAGILA_USER)-$(PAGILA_TEAM)-$(PAGILA_DB) -- -n $(PAGILA_NS) -o json | jq '.data.password' -r | base64 -d )
PAGILA_HOST := $$(make --no-print-directory kubectl get service -- -n $(PAGILA_NS) -o json | jq ".items | map(select(.metadata.name == \"$(PAGILA_TEAM)-$(PAGILA_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

METABASE_DB := metabase
METABASE_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_namespace' molecule/default/molecule.yml -r)
METABASE_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_chart' molecule/default/molecule.yml -r)
METABASE_USER := metabase
METABASE_PASS := $$(make --no-print-directory kubectl get secret $(METABASE_USER)-$(METABASE_TEAM)-$(METABASE_DB) -- -n $(METABASE_NS) -o json | jq '.data.password' -r | base64 -d )
METABASE_HOST := $$(make --no-print-directory kubectl get service -- -n $(METABASE_NS) -o json | jq ".items | map(select(.metadata.name == \"$(METABASE_TEAM)-$(METABASE_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

WAREHOUSE_DB := warehouse
WAREHOUSE_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_namespace' molecule/default/molecule.yml -r)
WAREHOUSE_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_chart' molecule/default/molecule.yml -r)
WAREHOUSE_USER := strimzi
WAREHOUSE_PASS := $$(make --no-print-directory kubectl get secret $(WAREHOUSE_USER)-$(WAREHOUSE_TEAM)-$(WAREHOUSE_DB) -- -n $(WAREHOUSE_NS) -o json | jq '.data.password' -r | base64 -d )
WAREHOUSE_HOST := $$(make --no-print-directory kubectl get service -- -n $(WAREHOUSE_NS) -o json | jq ".items | map(select(.metadata.name == \"$(WAREHOUSE_TEAM)-$(WAREHOUSE_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

DOCKER_REGISTRY := localhost:5000/
DOCKER_USER := nephelaiio
DATAPLANE_RELEASE := latest

TARGETS = poetry clean molecule run helm kubectl psql docker dataplane images connect

.PHONY: $(TARGETS)

clean:
	find /home/teddyphreak/.cache/ansible-compat/ -mindepth 2 -maxdepth 2 -type d -name "roles" | xargs -r rm -rf

molecule: clean poetry
	KIND_RELEASE=$(KIND_RELEASE) K8S_RELEASE=$(K8S_RELEASE) poetry run molecule $(filter-out $(TARGETS),$(MAKECMDGOALS)) -s $(SCENARIO)

run:
	$(EPHEMERAL_DIR)/bwrap $(filter-out $@,$(MAKECMDGOALS))

helm:
	KUBECONFIG=$(EPHEMERAL_DIR)/config helm $(filter-out $@,$(MAKECMDGOALS))

kubectl:
	@KUBECONFIG=$(EPHEMERAL_DIR)/config kubectl $(filter-out $@,$(MAKECMDGOALS))

poetry:
	@poetry install --no-root

pagila:
	PGPASSWORD=$(PAGILA_PASS) psql -h $(PAGILA_HOST) -U $(PAGILA_USER) $(PAGILA_DB)

metabase:
	PGPASSWORD=$(METABASE_PASS) psql -h $(METABASE_HOST) -U $(METABASE_USER) $(METABASE_DB)

warehouse:
	PGPASSWORD=$(WAREHOUSE_PASS) psql -h $(WAREHOUSE_HOST) -U $(WAREHOUSE_USER) $(WAREHOUSE_DB)

images: metabase-init kafka-connect

metabase-init:
	docker build \
		--rm \
		--tag "$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		. ; \
	docker image push $(DOCKER_REGISTRY)$(DOCKER_USER)/metabase-init:$(METABASE_RELEASE)

kafka-connect:
	cd connect && \
	docker build \
		--rm \
		--tag "$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		--build-arg KAFKA_RELEASE=$$(yq eval '.strimzi.kafka.version' ../charts/dataplane/values.yaml -r) \
		. ; \
	docker image push $(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(METABASE_RELEASE)

dataplane:
	@:

%:
	@:

# end
