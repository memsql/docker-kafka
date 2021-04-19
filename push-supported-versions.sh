set -e

build_version=""
if [[ -n $1 ]]; then
    if [ "$1" = "-h" ]; then
        echo "This script pushes the docker images for the supported kafka versions"
        echo "The optional first positional argument specifies the subverion of the docker image to push"
        echo "Example: './push-supported-versions.sh 111' will build psy3.memcompute.com/schema_kafka:2.7.0.111"
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
    docker push "psy3.memcompute.com/schema_kafka:$image_version"
    
    if [ -z "${dont_push_aio+set}" ]; then
        docker push "psy3.memcompute.com/schema_kafka-aio:$image_version"
    fi
}

dont_push_aio=1
push_image 0.8.2.1
unset dont_push_aio

push_image 0.10.2.1
push_image 0.11.0.2
push_image 1.0.1
push_image 1.1.0
push_image 2.0.0
push_image 2.7.0
