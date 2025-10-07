#!/bin/bash

mkdir -p /var/private/ssl && \
    cd /var/private/ssl && \
    /scripts/gen-ssl-certs.sh

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
    if [ ! -z "$BASIC_AUTH" ]; then
        # Enable basic auth
        export SCHEMA_REGISTRY_AUTHENTICATION_METHOD="BASIC"
        export SCHEMA_REGISTRY_AUTHENTICATION_ROLES="admin"
        export SCHEMA_REGISTRY_AUTHENTICATION_REALM="SchemaRegistry-Props"

        echo "SchemaRegistry-Props {
  org.eclipse.jetty.jaas.spi.PropertyFileLoginModule required
  file=\"/etc/schema-registry/passwords\"
  debug=\"false\";
};" > /etc/schema-registry/jaas_config.conf

        export SCHEMA_REGISTRY_OPTS=-Djava.security.auth.login.config=/etc/schema-registry/jaas_config.conf /usr/bin/schema-registry-start /etc/schema-registry/schema-registry.properties

        # generated using 
        # bin/schema-registry-run-class org.eclipse.jetty.util.security.Password <username> <password>
        # see https://docs.confluent.io/platform/current/security/basic-auth.html#basic-auth-sr
        # for more details
        echo "billieJean: OBF:1q3a1vv11rvb1x1b1r531s9f1sbv1r2v1x1b1rxj1vu91q5k,admin" > /etc/schema-registry/passwords
    fi

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
