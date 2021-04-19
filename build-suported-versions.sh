#!/bin/bash
set -e

build_version=""
if [[ -n $1 ]]; then
    if [ "$1" = "-h" ]; then
        echo "This script builds the docker images for the supported kafka versions"
        echo "The optional first positional argument specifies the subverion of the docker image used to tag the image"
        echo "Example: './build-supported-versions.sh 111' will build psy3.memcompute.com/schema_kafka:2.7.0.111"
        echo ""
        exit
    fi
    build_version="$1"
    echo "build_version: $build_version"
fi

build_and_tag () {
    image_version="${KAFKA_VERSION}.${build_version}"
    make build-kafka
    docker tag memsql/kafka:latest "psy3.memcompute.com/schema_kafka:$image_version"
    
    if [ -z "${dont_build_aio+set}" ]; then
        make build-kafka-aio
        docker tag memsql/kafka_aio:latest "psy3.memcompute.com/schema_kafka-aio:$image_version"
    fi
}

export BASE_VERSION=$build_version
make build-kafka-base

# kafka 0.8 doesnt support saml and does not need an aio image
dont_build_aio=1
export KAFKA_VERSION=0.8.2.1
export SCALA_VERSION=2.10
build_and_tag
unset dont_build_aio

export KAFKA_VERSION=0.10.2.1
export SCALA_VERSION=2.10
build_and_tag

export KAFKA_VERSION=0.11.0.2
export SCALA_VERSION=2.11
build_and_tag

export KAFKA_VERSION=1.0.1
export SCALA_VERSION=2.11
build_and_tag

export KAFKA_VERSION=1.1.0
export SCALA_VERSION=2.11
build_and_tag

export KAFKA_VERSION=2.0.0
export SCALA_VERSION=2.11
build_and_tag

export KAFKA_VERSION=2.7.0
export SCALA_VERSION=2.12
build_and_tag
