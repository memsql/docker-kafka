Kafka in Docker
===============

This repository provides everything you need to run Kafka in Docker, including
an optional Twitter producer script.

Why?
---

The main hurdle of running Kafka in Docker is that it depends on Zookeeper.
Compared to other Kafka docker images, this one runs both Zookeeper and Kafka
in the same container. This means:

* No dependency on an external Zookeeper host, or linking to another container
* Zookeeper and Kafka are configured to work together out of the box

When not to use this image
--------------------------

* Don't use this image for any production workload; this is for
  development and testing purposes only.
* If you want more than one Kafka broker, this image won't work very easily.

Run
---

```bash
docker run --rm --name memsql_kafka memsql/kafka
```

See `kafka/scripts/start-kafka.sh` for a list of optional environment variables.

To run the included Twitter producer:

```bash
docker run --rm --name memsql_kafka \
    -e PRODUCE_TWITTER=1 \
    -e TWITTER_CONSUMER_KEY \
    -e TWITTER_CONSUMER_SECRET \
    -e TWITTER_ACCESS_TOKEN \
    -e TWITTER_ACCESS_SECRET \
    memsql/kafka
```

Make sure that those Twitter secrets are in your environment.

The Twitter producer writes to two topics:
`tweets-json` and `tweets-tsv`. See `kafka/scripts/producer.py`.

To print records as they are inserted into a given topic:

```bash
docker exec -it memsql_kafka /bin/bash -c \
    '$KAFKA_HOME/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic <TOPIC>'
```

Networking FAQ
--------------

Docker networking doesn't always play nicely with Kafka since Kafka must know
which hostname it should advertise.  Depending on the scenario, you may need to
set the environment variable `ADVERTISED_HOST` when starting the container.  If
you are using the config included with this repo as-is, it will work with the
memsql-quickstart container out of the box.  Just make sure that in the
memsql-quickstart schema file, the CREATE PIPELINE statement uses the correct
IP.

Build from Source
-----------------

```bash
make build
make run
```

Or, use `make run-with-twitter`. See Makefile for how it pulls in Twitter
credentials.
