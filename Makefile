CONTAINER_NAME = memsql_kafka


.PHONY: build
build:
	docker build -t memsql/kafka ./kafka

.PHONY: rm
rm:
	docker rm -f ${CONTAINER_NAME}; true

.PHONY: logs
logs:
	docker logs -f ${CONTAINER_NAME};

.PHONY: run
run: build rm
	docker run -d \
		--name ${CONTAINER_NAME} \
		-p 2181:2181 -p 9092:9092 \
		-e ADVERTISED_HOST \
		memsql/kafka

.PHONY: run-with-twitter
run-with-twitter: build rm
	docker run -d \
		--name ${CONTAINER_NAME} \
		-p 2181:2181 -p 9092:9092 \
		-e PRODUCE_TWITTER=1 \
		-e TWITTER_CONSUMER_KEY \
		-e TWITTER_CONSUMER_SECRET \
		-e TWITTER_ACCESS_TOKEN \
		-e TWITTER_ACCESS_SECRET \
		-e ADVERTISED_HOST \
		memsql/kafka
