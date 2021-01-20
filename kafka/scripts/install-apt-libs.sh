#!/bin/bash
# This script installs the apt libraries and kafka

if [[ -z "${KAFKA_VERSION}" ]]; then
  echo "ERROR: KAFKA_VERSION is undefined"
fi

if [[ -z "${SCALA_VERSION}" ]]; then
  echo "ERROR: KAFKA_VERSION is undefined"
fi

# Update jessie-backports
echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50

# Install Kafka, Zookeeper, python dependencies and other needed things
apt-get -o Acquire::Check-Valid-Until=false update --fix-missing && \
    apt-get install -y dnsutils git supervisor wget zookeeper build-essential libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev&& \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean 

wget http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

if [ $? -ne 0 ]; then
    exit 1
fi

apt-get -y -o Acquire::Check-Valid-Until=false update