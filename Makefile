CONTAINER_NAME = memsql_kafka


.PHONY: build
build: build-kafka build-kafka-with-saml build-kafka-with-saml-aio

build-kafka:
	docker build -t memsql/kafka ./kafka

build-kafka-with-saml:
	docker build -t memsql/kafka_saml -f ./kafka/Dockerfile.saml ./kafka

build-kafka-with-saml-aio:
	docker build -t memsql/kafka_saml_aio -f ./kafka/Dockerfile.saml.aio ./kafka

.PHONY: rm
rm: rm-kafka rm-kafka-with-saml rm-kafka-with-saml-aio

.PHONY: rm-kafka
rm-kafka:
	docker rm -f ${CONTAINER_NAME}; true

.PHONY: rm-kafka-with-saml
rm-kafka-with-saml:
	docker rm -f ${CONTAINER_NAME}_saml; true

.PHONY: rm-kafka-with-saml-aio
rm-kafka-with-saml-aio:
	docker rm -f ${CONTAINER_NAME}_saml_aio; true

.PHONY: rmimages
rmimages: rmi-kafka-saml rmi-kafka rmi-kafka-saml-aio

.PHONY: rmi-kafka
rmi-kafka: 
	docker rmi -f memsql/kafka; true

.PHONY: rmi-kafka-saml
rmi-kafka-saml: 
	docker rmi -f memsql/kafka_saml:latest; true

.PHONY: rmi-kafka-saml-aio
rmi-kafka-saml-aio: 
	docker rmi -f memsql/kafka_saml_aio:latest; true

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
