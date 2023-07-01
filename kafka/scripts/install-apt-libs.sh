#!/bin/bash
# This script installs the apt libraries

source /etc/os-release

echo "Running on $PRETTY_NAME"
if [[ $VERSION == *"jessie"* ]]; then
    # jessie was deprecated and moved to archive repos
    # /etc/apt/sources.list contains snapshots, but fetching from those is slower than archive
    #
    sed -i '/deb http:\/\/\(deb\|security\).debian.org\/debian\(-security\)\? jessie\(-updates\|\/updates\)\? main/d' /etc/apt/sources.list
    echo "deb http://archive.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
    echo "deb http://archive.debian.org/debian jessie main" >> /etc/apt/sources.list
    echo "deb http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list
fi


# Install Kafka, Zookeeper, python dependencies and other needed things
apt-get update && \
apt-get -y --force-yes install python3 python3-pip dnsutils git \
supervisor wget zookeeper build-essential libreadline-gplv2-dev \
libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev && \
apt-get clean
