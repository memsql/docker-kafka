#!/bin/bash
# This script installs the apt libraries

# Update jessie-backports
echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50

# Install Kafka, Zookeeper, python dependencies and other needed things
apt-get -o Acquire::Check-Valid-Until=false update --fix-missing && \
    apt-get install -y python3 python3-pip dnsutils git supervisor wget zookeeper build-essential libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev&& \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean 

apt-get -y -o Acquire::Check-Valid-Until=false update
