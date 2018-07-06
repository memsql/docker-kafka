#!/bin/sh

set -ex pipefail

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic
# * SECURITY_PROTOCOL_MAP: mapping from the listener names to security protocol

echo "set SASL mechanism"
if grep -r -q "^#\?sasl.enabled.mechanisms" ${KAFKA_HOME}/config/server.properties; then
    sed -r -i "s/#?(sasl.enabled.mechanisms)=(.*)/\1=GSSAPI,PLAIN/g" ${KAFKA_HOME}/config/server.properties
else
    echo "sasl.enabled.mechanisms=GSSAPI,PLAIN" >> ${KAFKA_HOME}/config/server.properties
fi

echo "set Kerberos service name for kafka"
if grep -r -q "^#\?sasl.kerberos.service.name" ${KAFKA_HOME}/config/server.properties; then
    sed -r -i "s/#?(sasl.kerberos.service.name)=(.*)/\1=memsql/g" ${KAFKA_HOME}/config/server.properties
else
    echo "sasl.kerberos.service.name=memsql" >> ${KAFKA_HOME}/config/server.properties
fi

HOSTNAME=`hostname -i`
LISTENERS="PLAINTEXT:\/\/${HOSTNAME}:9092,SSL:\/\/${HOSTNAME}:9093,SASL_PLAINTEXT:\/\/${HOSTNAME}:9094,SASL_SSL:\/\/${HOSTNAME}:9095"
ADVERTISED_LISTENERS="PLAINTEXT:\/\/host.example.com:9092,SSL:\/\/host.example.com:9093,SASL_PLAINTEXT:\/\/host.example.com:9094,SASL_SSL:\/\/host.example.com:9095"
echo "set listener ports for: PLAINTEXT,SSL,SASL_PLAINTEXT,SASL_SSL"
if grep -r -q "^#\?listeners=" ${KAFKA_HOME}/config/server.properties; then
    sed -r -i "s/#?(listeners)=(.*)/\1=${ADVERTISED_LISTENERS}/g" ${KAFKA_HOME}/config/server.properties
else
    echo "listeners=${ADVERTISED_LISTENERS}" >> ${KAFKA_HOME}/config/server.properties
fi

if grep -r -q "^#\?advertised.listeners=" ${KAFKA_HOME}/config/server.properties; then
    sed -r -i "s/#?(advertised.listeners)=(.*)/\1=${ADVERTISED_LISTENERS}/g" ${KAFKA_HOME}/config/server.properties
else
    echo "advertised.listeners=${ADVERTISED_LISTENERS}" >> ${KAFKA_HOME}/config/server.properties
fi

echo "${HOSTNAME} host.example.com" >> /etc/hosts

echo "set SSL options"
if grep -r -q "^#\?ssl.client.auth=" ${KAFKA_HOME}/config/server.properties; then
    echo "Not setting ssl options"
else
    echo "ssl.client.auth=required" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.protocol=TLS" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.enabled.protocols=TLSv1.2,TLSv1.1,TLSv1" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.client.auth = required" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.truststore.location=/var/private/ssl/broker_host.example.com_server.truststore.jks" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.truststore.password=abcdefgh" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.keystore.location=/var/private/ssl/broker_host.example.com_server.keystore.jks" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.keystore.password=abcdefgh" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.key.password=abcdefgh" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.keystore.type = JKS" >> ${KAFKA_HOME}/config/server.properties
    echo "ssl.truststore.type = JKS" >> ${KAFKA_HOME}/config/server.properties
fi

echo "create jaas config based on template"
sed "s/HOSTNAME/$(hostname -f)/g" ${KAFKA_HOME}/config/kafka.jaas.tmpl > ${KAFKA_HOME}/config/kafka.jaas

export KAFKA_OPTS="-Djava.security.auth.login.config=${KAFKA_HOME}/config/kafka.jaas -Djava.security.krb5.conf=/etc/krb5.conf -Dzookeeper.authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider -Dsun.security.krb5.debug=true"

# Configure advertised host/port if we run in helios
if [ ! -z "$HELIOS_PORT_kafka" ]; then
    ADVERTISED_HOST=`echo $HELIOS_PORT_kafka | cut -d':' -f 1 | xargs -n 1 dig +short | tail -n 1`
    ADVERTISED_PORT=`echo $HELIOS_PORT_kafka | cut -d':' -f 2`
fi

# Set the external host and port
if [ ! -z "$ADVERTISED_HOST" ]; then
    echo "advertised host: $ADVERTISED_HOST"
    if grep -r -q "^#\?advertised.host.name=" ${KAFKA_HOME}/config/server.properties; then
        sed -r -i "s/#?(advertised.host.name=)=(.*)/\1=${ADVERTISED_HOST}/g" ${KAFKA_HOME}/config/server.properties
    else
        echo "advertised.host.name=$ADVERTISED_HOST" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set the zookeeper chroot
if [ ! -z "$ZK_CHROOT" ]; then
    # wait for zookeeper to start up
    until /usr/share/zookeeper/bin/zkServer.sh status; do
      sleep 2
    done

    # create the chroot node
    echo "create /$ZK_CHROOT \"\"" | /usr/share/zookeeper/bin/zkCli.sh || {
        echo "can't create chroot in zookeeper, exit"
        exit 1
    }

    # configure kafka
    sed -r -i "s/(zookeeper.connect)=(.*)/\1=localhost:2181\/$ZK_CHROOT/g" $KAFKA_HOME/config/server.properties
fi

# Allow specification of log retention policies
if [ ! -z "$LOG_RETENTION_HOURS" ]; then
    echo "log retention hours: $LOG_RETENTION_HOURS"
    sed -r -i "s/(log.retention.hours)=(.*)/\1=$LOG_RETENTION_HOURS/g" $KAFKA_HOME/config/server.properties
fi
if [ ! -z "$LOG_RETENTION_BYTES" ]; then
    echo "log retention bytes: $LOG_RETENTION_BYTES"
    sed -r -i "s/#(log.retention.bytes)=(.*)/\1=$LOG_RETENTION_BYTES/g" $KAFKA_HOME/config/server.properties
fi

# Configure the default number of log partitions per topic
if [ ! -z "$NUM_PARTITIONS" ]; then
    echo "default number of partition: $NUM_PARTITIONS"
    sed -r -i "s/(num.partitions)=(.*)/\1=$NUM_PARTITIONS/g" $KAFKA_HOME/config/server.properties
fi

# Stop Kafka first
$KAFKA_HOME/bin/kafka-server-stop.sh $KAFKA_HOME/config/server.properties || true
sleep 2

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties

# If we want to use the included Twitter producer, create the topics that it
# will use
if [ "$PRODUCE_TWITTER" == 1 ]; then
    sleep 5

    CREATE_TOPIC="$KAFKA_HOME/bin/kafka-topics.sh --create \
        --zookeeper $ADVERTISED_HOST:2181 --replication-factor 1 --topic"

    $CREATE_TOPIC tweets-json
    $CREATE_TOPIC tweets-csv
fi
