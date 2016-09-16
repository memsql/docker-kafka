#!/bin/sh

export ADVERTISED_HOST=$(hostname -i)
exec /usr/bin/supervisord -n
