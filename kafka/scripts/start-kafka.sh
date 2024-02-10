#!/bin/sh

set -ex pipefail

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic

CONFIG_PATH="${KAFKA_HOME}/config/server.properties"

if [[ "${KAFKA_VERSION}" < "3.3" ]]; then
    # Configure advertised host/port if we run in helios
    if [ ! -z "$HELIOS_PORT_kafka" ]; then
        ADVERTISED_HOST=`echo $HELIOS_PORT_kafka | cut -d':' -f 1 | xargs -n 1 dig +short | tail -n 1`
        ADVERTISED_PORT=`echo $HELIOS_PORT_kafka | cut -d':' -f 2`
    fi


    # Set the external host and port
    if [ ! -z "${ADVERTISED_HOST}" ]; then
        echo "advertised host: ${ADVERTISED_HOST}"
        if grep -r -q "^#\?advertised.host.name=" ${CONFIG_PATH}; then
            sed -r -i "s/#?(advertised.host.name=)=(.*)/\1=${ADVERTISED_HOST}/g" ${CONFIG_PATH}
        else
            echo "advertised.host.name=${ADVERTISED_HOST}" >> ${CONFIG_PATH}
        fi
    fi
    if [ ! -z "$ADVERTISED_PORT" ]; then
        echo "advertised port: $ADVERTISED_PORT"
        if grep -r -q "^#\?advertised.port=" ${CONFIG_PATH}; then
            sed -r -i "s/#?(advertised.port=)=(.*)/\1=${ADVERTISED_PORT}/g" ${CONFIG_PATH}
        else
            echo "advertised.port=${ADVERTISED_PORT}" >> ${CONFIG_PATH}
        fi
    fi
fi

if [[ ! "${KAFKA_VERSION}" < "3.3" ]]; then
    # Kafka 3.3.1: The advertised.port and advertised.host.name configurations were removed. Please use advertised.listeners instead.
    HOSTNAME=`hostname -i`
    LISTENERS="PLAINTEXT:\/\/:9092"
    ADVERTISED_LISTENERS="PLAINTEXT:\/\/${HOSTNAME}:9092"

    echo "set listener ports for: PLAINTEXT"
    if grep -r -q "^#\?listeners=" ${CONFIG_PATH}; then
        sed -r -i "s/#?(listeners)=(.*)/\1=${LISTENERS}/g" ${CONFIG_PATH}
    else
        echo "listeners=${LISTENERS}" >> ${CONFIG_PATH}
    fi

    if grep -r -q "^#\?advertised.listeners=" ${CONFIG_PATH}; then
        sed -r -i "s/#?(advertised.listeners)=(.*)/\1=${ADVERTISED_LISTENERS}/g" ${CONFIG_PATH}
    else
        echo "advertised.listeners=${ADVERTISED_LISTENERS}" >> ${CONFIG_PATH}
    fi
fi


# Set the zookeeper chroot
if [ ! -z "$ZK_CHROOT" ]; then
    # wait for zookeeper to start up
    until /usr/share/zookeeper/bin/zkServer.sh status; do
      sleep 0.1
    done

    # create the chroot node
    echo "create /$ZK_CHROOT \"\"" | /usr/share/zookeeper/bin/zkCli.sh || {
        echo "can't create chroot in zookeeper, exit"
        exit 1
    }

    # configure kafka
    sed -r -i "s/(zookeeper.connect)=(.*)/\1=localhost:2181\/$ZK_CHROOT/g" ${CONFIG_PATH}
fi

# Allow specification of log retention policies
if [ ! -z "$LOG_RETENTION_HOURS" ]; then
    echo "log retention hours: $LOG_RETENTION_HOURS"
    sed -r -i "s/(log.retention.hours)=(.*)/\1=$LOG_RETENTION_HOURS/g" ${CONFIG_PATH}
fi
if [ ! -z "$LOG_RETENTION_BYTES" ]; then
    echo "log retention bytes: $LOG_RETENTION_BYTES"
    sed -r -i "s/#(log.retention.bytes)=(.*)/\1=$LOG_RETENTION_BYTES/g" ${CONFIG_PATH}
fi

# Configure the default number of log partitions per topic
if [ ! -z "$NUM_PARTITIONS" ]; then
    echo "default number of partition: $NUM_PARTITIONS"
    sed -r -i "s/(num.partitions)=(.*)/\1=$NUM_PARTITIONS/g" ${CONFIG_PATH}
fi

# Configure topic auto-creation
if [ ! -z "$AUTO_CREATE" ]; then
    echo "setting auto-create to: $AUTO_CREATE"
    if ! grep -q "^auto.create.topics.enable=" ${CONFIG_PATH}; then
        echo -e "\nauto.create.topics.enable=$AUTO_CREATE" >> ${CONFIG_PATH}
    else
        sed -r -i "s/(auto.create.topics.enable)=(.*)/\1=$AUTO_CREATE/g" ${CONFIG_PATH}
    fi
fi

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh ${CONFIG_PATH}

# If we want to use the included Twitter producer, create the topics that it
# will use
if [ "$PRODUCE_TWITTER" == 1 ]; then
    sleep 5

    CREATE_TOPIC="$KAFKA_HOME/bin/kafka-topics.sh --create \
        --zookeeper $ADVERTISED_HOST:2181 --replication-factor 1 --topic"

    $CREATE_TOPIC tweets-json
    $CREATE_TOPIC tweets-csv
fi
