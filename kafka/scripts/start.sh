#!/bin/sh

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

exec /usr/bin/supervisord -n
