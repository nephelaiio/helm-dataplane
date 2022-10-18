FROM confluentinc/cp-kafka-connect:7.2.2 as cp
RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:1.9.6
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-avro-converter:7.2.2
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.6.0

FROM quay.io/strimzi/kafka:latest-kafka-3.2.3
ENV KAFKA_CONNECT_PLUGIN_PATH=/home/kafka/connect-plugins
RUN mkdir -p $KAFKA_CONNECT_PLUGIN_PATH
COPY --from=cp /usr/share/confluent-hub-components/debezium-debezium-connector-postgresql/lib ${KAFKA_CONNECT_PLUGIN_PATH}/postgresql/
COPY --from=cp /usr/share/confluent-hub-components/confluentinc-kafka-connect-avro-converter/lib ${KAFKA_CONNECT_PLUGIN_PATH}/avro/
COPY --from=cp /usr/share/confluent-hub-components/confluentinc-kafka-connect-jdbc/lib ${KAFKA_CONNECT_PLUGIN_PATH}/jdbc/
