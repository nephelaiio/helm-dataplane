##
# nephelaiio.k8s Ansible role
#
# @file
# @version 0.0.1

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

SAGILA_DB := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_sagila_db' molecule/default/molecule.yml -r)
SAGILA_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_sagila_namespace' molecule/default/molecule.yml -r)
SAGILA_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_sagila_team' molecule/default/molecule.yml -r)
SAGILA_USER := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_sagila_user' molecule/default/molecule.yml -r)
SAGILA_PASS := $$(make --no-print-directory kubectl get secret $(SAGILA_USER)-$(SAGILA_TEAM)-$(SAGILA_DB) -- -n $(SAGILA_NS) -o json | jq '.data.password' -r | base64 -d )
SAGILA_HOST := $$(make --no-print-directory kubectl get service -- -n $(SAGILA_NS) -o json | jq ".items | map(select(.metadata.name == \"$(SAGILA_TEAM)-$(SAGILA_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

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
WAREHOUSE_PASS := $$(make --no-print-directory kubectl get secret $(WAREHOUSE_USER)-$(WAREHOUSE_TEAM)-$(WAREHOUSE_DB)-db -- -n $(WAREHOUSE_NS) -o json | jq '.data.password' -r | base64 -d )
WAREHOUSE_HOST := $$(make --no-print-directory kubectl get service -- -n $(WAREHOUSE_NS) -o json | jq ".items | map(select(.metadata.name == \"$(WAREHOUSE_TEAM)-$(WAREHOUSE_DB)-db\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

DOCKER_REGISTRY ?= localhost:5000/
DOCKER_USER ?= nephelaiio
DATAPLANE_RELEASE ?= latest
KAFKA_RELEASE := $$(yq eval '.strimzi.kafka.version' ../charts/dataplane/values.yaml -r)

TARGETS = poetry clean molecule run helm kubectl psql docker dataplane dataplane-init dataplane-connect images strimzi strimzi-topics

.PHONY: $(TARGETS)

clean:
	find /home/teddyphreak/.cache/ansible-compat/ -mindepth 2 -maxdepth 2 -type d -name "roles" | xargs -r rm -rf

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
	PGPASSWORD=$(PAGILA_PASS) psql -h $(PAGILA_HOST) -U $(PAGILA_USER) $(PAGILA_DB)

sagila:
	PGPASSWORD=$(SAGILA_PASS) psql -h $(SAGILA_HOST) -U $(SAGILA_USER) $(SAGILA_DB)

metabase:
	PGPASSWORD=$(METABASE_PASS) psql -h $(METABASE_HOST) -U $(METABASE_USER) $(METABASE_DB)

warehouse:
	PGPASSWORD=$(WAREHOUSE_PASS) psql -h $(WAREHOUSE_HOST) -U $(WAREHOUSE_USER) $(WAREHOUSE_DB)

images: dataplane-init dataplane-connect
	docker image prune --force; \
	curl -s http://localhost:5000/v2/_catalog | jq

dataplane-init:
	docker build \
		--rm \
		--tag "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		. ; \
	docker image push "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)"

dataplane-connect:
	cd connect ; \
	KAFKA_RELEASE=$(KAFKA_RELEASE) docker build \
		--rm \
		--tag "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)" \
		. ; \
	docker image push "$(DOCKER_REGISTRY)$(DOCKER_USER)/$@:$(DATAPLANE_RELEASE)"

strimzi: strimzi-topics

strimzi-topics:
	make --no-print-directory kubectl exec -- -it pod/dataplane-strimzi-kafka-0 -n dataplane -- "/opt/kafka/bin/kafka-topics.sh --bootstrap-server dataplane-strimzi-kafka-bootstrap:9092 --list"

dataplane:
	@:

%:
	@:

# end
