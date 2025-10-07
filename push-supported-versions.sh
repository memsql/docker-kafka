set -e

build_version=""
if [[ -n $1 ]]; then
    if [ "$1" = "-h" ]; then
        echo "This script pushes the docker images for the supported kafka versions"
        echo "The optional first positional argument specifies the subverion of the docker image to push"
        echo "Example: './push-supported-versions.sh 111' will aws-psyduck-production-ecr-em-proxy.internal.memcompute.com/psyduck/switchman-images/schema_kafka:2.7.0.111"
        echo ""
        exit
    fi
    build_version="$1"
else
    echo "please set the build version"
    exit 1
fi

push_image () {
    image_version="${1}.${build_version}"
    docker push "aws-psyduck-production-ecr-em-proxy.internal.memcompute.com/psyduck/switchman-images/schema_kafka:$image_version"

    if [[ "$*" == *"aio"* ]]; then
        docker push "aws-psyduck-production-ecr-em-proxy.internal.memcompute.com/psyduck/switchman-images/schema_kafka-aio:$image_version"
    fi

    if [[ "$*" == *"oauth"* ]]; then
        docker push "aws-psyduck-production-ecr-em-proxy.internal.memcompute.com/psyduck/switchman-images/schema_kafka-oauth:$image_version"
    fi
}

push_image 0.8.2.1
push_image 0.10.2.1 aio
push_image 0.11.0.2 aio
push_image 1.0.1 aio
push_image 1.1.0 aio
push_image 2.0.0 aio
push_image 2.7.0 aio
push_image 3.3.1 oauth
