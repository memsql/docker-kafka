# Kafka and Zookeeper

FROM java:openjdk-8-jre

ENV DEBIAN_FRONTEND noninteractive
ENV SCALA_VERSION 2.11
ENV KAFKA_VERSION 0.10.2.1
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV NUM_PARTITIONS 16

# Install Kafka, Zookeeper and other needed things
RUN apt-get update --fix-missing && \
    apt-get install -y dnsutils git python3 python3-pip supervisor wget zookeeper && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    wget -q http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

# Install Python packages for the producer script.
RUN pip3 install git+git://github.com/bear/python-twitter.git@3f99eaf06a6a9862cd6957e33072165f7ab50c86
RUN pip3 install git+git://github.com/dpkp/kafka-python.git

# setup ssh
RUN mkdir /var/run/sshd

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

# Use a known SSH key - the one we use for psyduck containers
COPY authorized_keys /root/.ssh/authorized_keys

RUN apt-get update && \
    apt-get install -y ssh openssh-server && \
    apt-get clean && \
    sed -r -i "s/^(Port )22/\1 2122/g" /etc/ssh/sshd_config


ADD scripts /scripts

# Supervisor config
ADD supervisor/kafka.conf /etc/supervisor/conf.d/
ADD supervisor/producer.conf /etc/supervisor/conf.d/
ADD supervisor/zookeeper.conf /etc/supervisor/conf.d/
ADD supervisor/sshd.conf /etc/supervisor/conf.d/

# make image compatible with old way of starting kafka
RUN ln -s /scripts/start.sh /startup.sh

# 2122 is ssh, 2181 is zookeeper, 9092 is kafka
EXPOSE 2122 2181 9092

CMD ["/scripts/start.sh"]
