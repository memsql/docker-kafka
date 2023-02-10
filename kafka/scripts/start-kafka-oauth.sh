#!/bin/sh

set -ex pipefail

# ENV variables:
# * OAUTHBEARER_CONFIG: config with json keys - client_id, client_secret, token_url, jwks_url, audience
# Optional ENV variables:
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic


CONFIG_PATH="${KAFKA_HOME}/config/server.properties"
HOSTNAME=`hostname -i`

# Kafka 3.3.1: The advertised.port and advertised.host.name configurations were removed. Please use advertised.listeners instead.
LISTENERS="PLAINTEXT:\/\/:9092, SASL_PLAINTEXT:\/\/:9093, SASL_SSL:\/\/:9094"
ADVERTISED_LISTENERS="PLAINTEXT:\/\/${HOSTNAME}:9092, SASL_PLAINTEXT:\/\/${HOSTNAME}:9093, SASL_SSL:\/\/${HOSTNAME}:9094"

echo "set listener ports for: PLAINTEXT, SASL_PLAINTEXT, SASL_SSL"
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


if ! grep -r -q "sasl.enabled.mechanisms=OAUTHBEARER" ${CONFIG_PATH}; then
    CONFIG_JSON=$(echo "${OAUTHBEARER_CONFIG}" | base64 -d)
    echo "Setting OAUTHBEARER config settings ${CONFIG_JSON}"

    CLIENT_ID=$(echo "${CONFIG_JSON}" | jq -r '.client_id')
    CLIENT_SECRET=$(echo "${CONFIG_JSON}" | jq -r '.client_secret')


    cat << EOF >> ${CONFIG_PATH}

sasl.enabled.mechanisms=OAUTHBEARER
sasl.mechanism.inter.broker.protocol=OAUTHBEARER
security.inter.broker.protocol=PLAINTEXT

sasl.oauthbearer.token.endpoint.url=$(echo "${CONFIG_JSON}" | jq -r '.token_url')
sasl.oauthbearer.jwks.endpoint.url=$(echo "${CONFIG_JSON}" | jq -r '.jwks_url')
sasl.oauthbearer.expected.audience=$(echo "${CONFIG_JSON}" | jq -r '.audience')

listener.name.sasl_plaintext.oauthbearer.sasl.server.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerValidatorCallbackHandler
listener.name.sasl_plaintext.oauthbearer.sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerLoginCallbackHandler
listener.name.sasl_plaintext.oauthbearer.sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required clientId=${CLIENT_ID} clientSecret=${CLIENT_SECRET} unsecuredLoginStringClaim_sub='sub';

listener.name.sasl_ssl.oauthbearer.sasl.server.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerValidatorCallbackHandler
listener.name.sasl_ssl.oauthbearer.sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.secured.OAuthBearerLoginCallbackHandler
listener.name.sasl_ssl.oauthbearer.sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required clientId=${CLIENT_ID} clientSecret=${CLIENT_SECRET} unsecuredLoginStringClaim_sub='sub';
EOF
fi


if grep -r -q "^#\?ssl.client.auth=" ${CONFIG_PATH}; then
    echo "Not setting ssl options"
else
    echo "set SSL options"
    cat << EOF >> ${CONFIG_PATH}

ssl.client.auth=required
ssl.truststore.location=/var/private/ssl/broker_host.example.com_server.truststore.jks
ssl.truststore.password=abcdefgh
ssl.keystore.location=/var/private/ssl/broker_host.example.com_server.keystore.jks
ssl.keystore.password=abcdefgh
ssl.key.password=abcdefgh
EOF
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
    sed -r -i "s/(auto.create.topics.enable)=(.*)/\1=$AUTO_CREATE/g" ${CONFIG_PATH}
fi

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh ${CONFIG_PATH}