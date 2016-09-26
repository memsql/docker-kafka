CONTAINER_NAME = memsql_kafka


.PHONY: build
build:
	docker build -t memsql/kafka ./kafka

.PHONY: rm
rm:
	docker rm -f ${CONTAINER_NAME}; true

.PHONY: run
run: build rm
	docker run --rm --name ${CONTAINER_NAME} \
		-p 2181:2181 -p 9092:9092 \
		memsql/kafka

.PHONY: run-with-twitter
run-with-twitter: build rm
	. secrets.env && \
		docker run --rm --name ${CONTAINER_NAME} \
		-p 2181:2181 -p 9092:9092 \
		-e PRODUCE_TWITTER=1 \
		-e TWITTER_CONSUMER_KEY \
		-e TWITTER_CONSUMER_SECRET \
		-e TWITTER_ACCESS_TOKEN \
		-e TWITTER_ACCESS_SECRET \
		memsql/kafka
