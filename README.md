# nephelaiio.dataplane

[![Build Status](https://github.com/nephelaiio/helm-dataplane/workflows/molecule/badge.svg)](https://github.com/nephelaiio/helm-dataplane/actions)

A helm chart to deploy a CDC replication stack integrating the following components
* Strimzi Kafka Broker
* Zalando PostgreSQL Data Warehouse
* Metabase Data Reporting
* Strimzi Kafka Connect cluster
* Strimzi Kafka Schema Registry
* Strimzi Kafka Connect PostgreSQL sink
* Strimzi Kafka Connect PostgreSQL sources

## TODO
In order of priority
* Add support for MySQL sources
* Add config options for warehouse backups
* Add monitoring for Kafka topics
* Add Apache Flink deployment
* Add table exclude support for cdc connectors

## Dependencies
Chart depends on the following cluster levels components being deployed in the target cluster

* Strimzi Kafka controller
* Zalando Postgres controller
* Nginx Ingress controller
* Storage class with ReclaimPolicy=Retain 

Cluster dependencies are provisioned with role [nephelaiio.k8s](https://github.com/nephelaiio/ansible-role-k8s) in testing environment

## Testing
Testing is performed using molecule against a local single-node kind cluster using Github Actions and can be replicated locally for the latest supported cluster version using the following commands:

``` sh
./bin/test
```
