.PHONY: build
build:
	docker build -t memsql/kafka ./kafka

.PHONY: run
run: build
	. secrets.env && \
		docker run --rm --name memsql_kafka \
		-p 2181:2181 -p 9092:9092 \
		-e ADVERTISED_HOST=127.0.0.1 \
		-e TWITTER_CONSUMER_KEY \
		-e TWITTER_CONSUMER_SECRET \
		-e TWITTER_ACCESS_TOKEN \
		-e TWITTER_ACCESS_SECRET \
		memsql/kafka
