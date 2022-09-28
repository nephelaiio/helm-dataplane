# nephelaiio.dataplane

[![Build Status](https://github.com/nephelaiio/helm-dataplane/workflows/Molecule/badge.svg)](https://github.com/nephelaiio/helm-dataplane/actions)

A helm chart to deploy a CDC replication stack integrating the following components
* Strimzi Kafka Broker
* Zalando PostgreSQL Data Warehouse
* Metabase Data Reporting
* Strimzi Kafka Schema Registry [In Progress]
* Strimzi Kafka Connect [In Progress]
* Apache Flink [Planned]

## TODO
In order of priority
* Add source Kafka connector manifests
* Add sink Kafka connector manifests
* Add initContainer for Metabase initialization
* Add initContainer for Metabase Data Warehouse registration
* Add data quality tests
* Add Apache Flink deployment

## Dependencies
Chart depends on the following cluster levels components being deployed in the target cluster

* Strimzi
* Zalando
* Ingress controller

Dependencies are provisioned with 

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

