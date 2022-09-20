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

PG_DB := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_src_db' molecule/default/molecule.yml -r)
PG_NS := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_src_namespace' molecule/default/molecule.yml -r)
PG_TEAM := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_src_team' molecule/default/molecule.yml -r)
PG_USER := $$(yq eval '.provisioner.inventory.hosts.all.vars.dataplane_src_user' molecule/default/molecule.yml -r)
PG_PASS := $$(make --no-print-directory kubectl get secret $(PG_USER)-$(PG_TEAM)-$(PG_DB) -- -n $(PG_NS) -o json | jq '.data.password' -r | base64 -d )
PG_HOST := $$(make --no-print-directory kubectl get service -- -n $(PG_NS) -o json | jq ".items | map(select(.metadata.name == \"$(PG_TEAM)-$(PG_DB)\"))[0] | .status.loadBalancer.ingress[0].ip" -r)

.PHONY: local aws poetry

test create prepare converge verify destroy cleanup: poetry
	KIND_RELEASE=$(KIND_RELEASE) KIND_IMAGE=$(KIND_IMAGE) poetry run molecule $@

run:
	$(EPHEMERAL_DIR)/bwrap $(filter-out $@,$(MAKECMDGOALS))

helm:
	KUBECONFIG=$(EPHEMERAL_DIR)/config helm $(filter-out $@,$(MAKECMDGOALS))

kubectl:
	@KUBECONFIG=$(EPHEMERAL_DIR)/config kubectl $(filter-out $@,$(MAKECMDGOALS))

poetry:
	@poetry install

psql:
	PGPASSWORD=$(POSTGRESQL_PASS) $(EPHEMERAL_DIR)/bwrap psql -h $(POSTGRESQL_HOST) -U $(POSTGRESQL_USER)

--verbose -v:
	KIND_RELEASE=$(KIND_RELEASE) KIND_IMAGE=$(KIND_IMAGE) poetry run -vvv molecule $(filter-out $@,$(MAKECMDGOALS))

%:
	@:

# end
