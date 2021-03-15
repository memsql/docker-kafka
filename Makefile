CONTAINER_NAME = memsql_kafka

# Consume KAFKA_VERSION from the make environment.
#
ifeq ($(KAFKA_VERSION),)
DOCKERARGS := 
else
DOCKERARGS := --build-arg KAFKA_VERSION_ARG=${KAFKA_VERSION}
endif

ifneq ($(SCALA_VERSION),)
DOCKERARGS := ${DOCKERARGS} --build-arg SCALA_VERSION_ARG=${SCALA_VERSION}
endif

.PHONY: build
build: build-kafka build-kafka-with-saml build-kafka-with-saml-aio

build-kafka:
	docker build ${DOCKERARGS} -t memsql/kafka ./kafka

build-kafka-with-saml:
	docker build ${DOCKERARGS} -t memsql/kafka_saml -f ./kafka/Dockerfile.saml ./kafka

build-kafka-with-saml-aio:
	docker build ${DOCKERARGS} -t memsql/kafka_saml_aio -f ./kafka/Dockerfile.saml.aio ./kafka

.PHONY: build-kafka-aio
build-kafka-aio:
	docker build ${DOCKERARGS} -t memsql/kafka_aio -f ./kafka/Dockerfile.aio ./kafka

.PHONY: build-kafka-no-auto-create
build-kafka-no-auto-create: build-kafka-aio
	docker build ${DOCKERARGS} -t memsql/kafka_aio_no_auto_create -f ./kafka/Dockerfile.aio.no.auto ./kafka

.PHONY: rm
rm: rm-kafka rm-kafka-with-saml rm-kafka-with-saml-aio rm-kafka-aio

.PHONY: rm-kafka
rm-kafka:
	docker rm -f ${CONTAINER_NAME}; true

.PHONY: rm-kafka-with-saml
rm-kafka-with-saml:
	docker rm -f ${CONTAINER_NAME}_saml; true

.PHONY: rm-kafka-with-saml-aio
rm-kafka-with-saml-aio:
	docker rm -f ${CONTAINER_NAME}_saml_aio; true

.PHONY: rm-kafka-aio
rm-kafka-aio:
	docker rm -f ${CONTAINER_NAME}_aio; true

.PHONY: rm-kafka-no-auto-create
rm-kafka-no-auto-create:
	docker rm -f ${CONTAINER_NAME}_aio_no_auto_create; true

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

.PHONY: rmi-kafka-aio
rmi-kafka-aio:
	docker rmi -f memsql/kafka_aio:latest; true

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
