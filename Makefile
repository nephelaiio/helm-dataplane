##
# nephelaiio.k8s Ansible role
#
# @file
# @version 0.0.1

KIND_RELEASE := $$(yq eval '.jobs.molecule.strategy.matrix.release| sort | reverse | .[0]' .github/workflows/main.yml)
KIND_IMAGE := $$(yq eval '.jobs.molecule.strategy.matrix.image | sort | reverse | .[0]' .github/workflows/main.yml)
ROLE_NAME := $$(pwd | xargs basename)
SCENARIO_NAME := default
EPHEMERAL_DIR := $$HOME/.cache/molecule/$(ROLE_NAME)/$(SCENARIO_NAME)

PAGILA_SRC_DB := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_db' molecule/default/molecule.yml -r)
PAGILA_SRC_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_namespace' molecule/default/molecule.yml -r)
PAGILA_SRC_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_team' molecule/default/molecule.yml -r)
PAGILA_SRC_USER := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_pagila_user' molecule/default/molecule.yml -r)
PAGILA_SRC_PASS := $$(make --no-print-directory kubectl get secret $(PAGILA_SRC_USER)-$(PAGILA_SRC_TEAM)-$(PAGILA_SRC_DB) -- -n $(PAGILA_SRC_NS) -o json | jq '.data.password' -r | base64 -d )
PAGILA_SRC_HOST := $$(make --no-print-directory kubectl get service -- -n $(PAGILA_SRC_NS) -o json | jq ".items | map(select(.metadata.name == \"$(PAGILA_SRC_TEAM)-$(PAGILA_SRC_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

.PHONY: poetry run helm kubectl psql test create prepare converge verify destroy cleanup clean

clean:
	rm -rf /home/teddyphreak/.cache/ansible-compat/*

test create prepare converge verify destroy cleanup: poetry clean
	KIND_RELEASE=$(KIND_RELEASE) KIND_IMAGE=$(KIND_IMAGE) poetry run molecule $@

run:
	$(EPHEMERAL_DIR)/bwrap $(filter-out $@,$(MAKECMDGOALS))

helm:
	KUBECONFIG=$(EPHEMERAL_DIR)/config helm $(filter-out $@,$(MAKECMDGOALS))

kubectl:
	@KUBECONFIG=$(EPHEMERAL_DIR)/config kubectl $(filter-out $@,$(MAKECMDGOALS))

poetry:
	@poetry install

pagila:
	PGPASSWORD=$(PAGILA_SRC_PASS) psql -h $(PAGILA_SRC_HOST) -U $(PAGILA_SRC_USER) $(PAGILA_SRC_DB)

molecule:
	PGPASSWORD=$(PAGILA_SRC_PASS) psql -h $(PAGILA_SRC_HOST) -U $(PAGILA_SRC_USER) $(PAGILA_SRC_DB)

--verbose -v:
	KIND_RELEASE=$(KIND_RELEASE) KIND_IMAGE=$(KIND_IMAGE) poetry run -vvv molecule $(filter-out $@,$(MAKECMDGOALS))

%:
	@:

# end
