# nephelaiio.dataplane

[![Build Status](https://github.com/nephelaiio/helm-dataplane/workflows/molecule/badge.svg)](https://github.com/nephelaiio/helm-dataplane/actions)

A helm chart to deploy a CDC replication stack integrating the following components
* Strimzi Kafka Broker
* Zalando PostgreSQL Data Warehouse
* Metabase Data Reporting
* Strimzi Kafka Connect cluster
* Strimzi Kafka Schema Registry
* Strimzi Kafka Connect sources/sinks

## TODO
In order of priority
* Add initContainer for Metabase initialization
* Add data quality tests
* Add Apache Flink deployment

## Dependencies
Chart depends on the following cluster levels components being deployed in the target cluster

* Strimzi
* Zalando
* Ingress controller

Cluster dependencies are provisioned with role [nephelaiio.k8s](https://github.com/nephelaiio/ansible-role-k8s) in testing environment

## Testing
Testing is performed using molecule against a local single-node kind cluster using Github Actions and can be replicated locally for the latest supported cluster version using the following commands:

``` sh
make molecule converge
make molecule verify
```

Or as a single command

``` sh
make molecule test
```

