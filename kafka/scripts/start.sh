#!/bin/sh

if [ "$PRODUCE_TWITTER" != 1 ]; then
    rm /etc/supervisor/conf.d/producer.conf
fi

if [ -z "$ADVERTISED_HOST" ]; then
    export ADVERTISED_HOST=$(hostname -i)
fi

exec /usr/bin/supervisord -n
