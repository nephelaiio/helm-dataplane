ARG KAFKA_RELEASE=3.2.0
FROM quay.io/strimzi/kafka:latest-kafka-${KAFKA_RELEASE}

ARG DEBEZIUM_RELEASE=1.9.4.Final
ENV KAFKA_CONNECT_PLUGIN_PATH=/home/kafka/connect-plugins

RUN mkdir $KAFKA_CONNECT_PLUGIN_PATH
RUN cd $KAFKA_CONNECT_PLUGIN_PATH
RUN curl -sfSL https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgre/${DEBEZIUM_RELEASE}/debezium-connector-postgre-${DEBEZIUM_RELEASE}-plugin.tar.gz | tar xz
RUN curl -sfSL https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/${DEBEZIUM_RELEASE}/debezium-connector-mysql-${DEBEZIUM_RELEASE}-plugin.tar.gz | tar xz
