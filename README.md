Kafka in Docker
===

This repository provides everything you need to run Kafka in Docker, including
an optional Twitter producer script.

Why?
---
The main hurdle of running Kafka in Docker is that it depends on Zookeeper.
Compared to other Kafka docker images, this one runs both Zookeeper and Kafka
in the same container. This means:

* No dependency on an external Zookeeper host, or linking to another container
* Zookeeper and Kafka are configured to work together out of the box

Run
---

```bash
docker run --rm --name memsql_kafka \
    -p 2181:2181 -p 9092:9092 \
    memsql/kafka
```

See `kafka/scripts/start-kafka.sh` for a list of optional environment variables.

To run the included Twitter producer:

```bash
docker run --rm --name memsql_kafka \
    -p 2181:2181 -p 9092:9092 \
    -e PRODUCE_TWITTER=1 \
    -e TWITTER_CONSUMER_KEY \
    -e TWITTER_CONSUMER_SECRET \
    -e TWITTER_ACCESS_TOKEN \
    -e TWITTER_ACCESS_SECRET \
    memsql/kafka
```

Make sure that those Twitter secrets are in your environment.

The Twitter producer writes stripped-down Twitter data to two topics:
`tweets-json` and `tweets-tsv`. See `kafka/scripts/producer.py`.

Build from Source
-----------------

```bash
make build
make run
```

Or, use `make run-with-twitter`. See Makefile for how it pulls in Twitter
credentials.
