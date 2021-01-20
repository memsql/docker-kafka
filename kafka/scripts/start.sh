#!/bin/bash

mkdir -p /var/private/ssl && \
    cd /var/private/ssl && \
    /scripts/gen-ssl-certs.sh ca ca-cert US && \
    /scripts/gen-ssl-certs.sh -k server ca-cert broker_host.example.com_ host.example.com && \
    /scripts/gen-ssl-certs.sh client ca-cert client_memsql_ memsql

if [ "$PRODUCE_TWITTER" != 1 ]; then
    rm /etc/supervisor/conf.d/producer.conf
fi

if [ -z "$ADVERTISED_HOST" ]; then
    export ADVERTISED_HOST=$(hostname -i)
fi

if [ ! -z "$LOG_RETENTION_HOURS" ]; then
    # Only keep around 12 hours of data
    export LOG_RETENTION_HOURS=12
fi
if [ ! -z "$NUM_PARTITIONS" ]; then
    export NUM_PARTITIONS=16
fi

PIDS=()
# Launch the schema registry in the background and tee the results to a log file
if [ ! -z "$LAUNCH_SCHEMA_REGISTRY" ]; then
    /etc/confluent/docker/run | tee /var/log/schema-registry.log &
    PIDS+=($!)
else
    echo "No schema registry launched" >> /var/log/schema-registry.log
fi

if [ -z "$DONT_LAUNCH_KAFKA" ]; then
    # Launch Kafka
    /usr/bin/supervisord -n &
    PIDS+=($!)
fi


if [ ! -z "$PIDS" ]; then
    success=true
    # wait a pid in PIDS to crash
    while [ "$success" == "true" ]
    do
        sleep 2
        for pid in "${PIDS[@]}"
        do
            kill -0 $pid
            if [ $? -ne 0 ]; then
                echo "PID $pid terminated, exiting."
                success=false
            fi
        done
    done
else
    # the container was launched without kafka or schema regisrty
    # simply sleep and let the user do what they want
    sleep infinity
fi
