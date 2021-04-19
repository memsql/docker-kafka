# Kafka and Zookeeper
ARG BASE_IMAGE=memsql/kafka_base:latest
FROM $BASE_IMAGE

ARG SCALA_VERSION_ARG=2.12
ENV SCALA_VERSION=$SCALA_VERSION_ARG
ARG KAFKA_VERSION_ARG=2.7.0
ENV KAFKA_VERSION=$KAFKA_VERSION_ARG
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"

RUN /scripts/install-kafka.sh

ADD config/log4j.properties "$KAFKA_HOME"/config/

ADD supervisor/kafka.conf /etc/supervisor/conf.d/

# 2122 is ssh, 2181 is zookeeper, 9092 is kafka, 8081 is the schema registry
EXPOSE 2122 2181 9092 8081

CMD ["/scripts/start.sh"]
