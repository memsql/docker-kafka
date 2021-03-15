#!/bin/bash
# This script installs the kafka

if [[ -z "${KAFKA_VERSION}" ]]; then
  echo "ERROR: KAFKA_VERSION is undefined"
fi

if [[ -z "${SCALA_VERSION}" ]]; then
  echo "ERROR: KAFKA_VERSION is undefined"
fi


wget https://archive.apache.org/dist/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

if [ $? -ne 0 ]; then
    exit 1
fi