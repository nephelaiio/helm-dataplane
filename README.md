# nephelaiio.dataplane

A helm chart to deploy a set of CDC replication connectors to create a data lake from a set of distributed databases

Deployment integrates the following components
* Metabase Data Reporting
* Strimzi Kafka Broker
* Zalando PostgreSQL Data Warehouse
* Strimzi Kafka Connect cluster
* Strimzi Kafka Schema Registry
* Strimzi Kafka Connect PostgreSQL sink
* Strimzi Kafka Connect PostgreSQL sources

## Installation

``` sh
helm repo add dataplane https://nephelaiio.github.io/helm-dataplane/
helm repo update
helm install dataplane/dataplane
```

## Values

This is an example values definition for replicating pagila db:

```
metabase:
  admin:
      email: metabase@nephelai.io
      password: dataplane
  ingress:
      enabled: true
      className: nginx-private
      hostName: metabase.nephelai.io
cdc:
  postgres:
    - hostname: pagilahost
      port: 5432
      id: pagila
      dbname: pagila
      signaling: True
strimzi:
  connect:
    secret: "metabase-pagila-db"
  kafka:
    storage:
      class: standard
  zookeeper:
    storage:
      class: standard
zalando:
  metabase:
    class: standard
```

## Roadmap
In order of priority
* Create python package for maintenance operations
* Create and publish Topic Reroute transform
* Add support for MySQL sources
* Add monitoring for Kafka topics
* Add Opendistro deployment

## Dependencies
Chart depends on the following cluster levels components being deployed in the target cluster

* Strimzi Kafka controller
* Zalando Postgres controller
* Nginx Ingress controller
* Storage class with ReclaimPolicy=Retain 

Cluster dependencies are provisioned with role [nephelaiio.k8s](https://github.com/nephelaiio/ansible-role-k8s) in testing environment

## Testing
Testing is performed using molecule against a local cluster using Github Actions and can be replicated locally for the latest supported cluster version using the following commands:

``` sh
./bin/test
```
