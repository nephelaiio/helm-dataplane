FROM confluentinc/cp-kafka-connect:7.4.0 as cp
RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:2.2.1
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-avro-converter:7.4.0
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.7.3

FROM quay.io/strimzi/kafka:latest-kafka-3.4.1
ENV KAFKA_CONNECT_PLUGIN_PATH=/home/kafka/connect-plugins
RUN mkdir -p $KAFKA_CONNECT_PLUGIN_PATH
COPY --from=cp /usr/share/confluent-hub-components/debezium-debezium-connector-postgresql/lib ${KAFKA_CONNECT_PLUGIN_PATH}/postgresql/
COPY --from=cp /usr/share/confluent-hub-components/confluentinc-kafka-connect-avro-converter/lib ${KAFKA_CONNECT_PLUGIN_PATH}/avro/
COPY --from=cp /usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib ${KAFKA_CONNECT_PLUGIN_PATH}/jdbc/
