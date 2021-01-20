# Kafka and Zookeeper

FROM java:openjdk-8-jre
FROM psy3.memcompute.com/confluentinc/cp-schema-registry:5.5.1

ENV DEBIAN_FRONTEND noninteractive
ENV SCALA_VERSION 2.12
ARG KAFKA_VERSION_ARG=2.7.0
ENV KAFKA_VERSION=$KAFKA_VERSION_ARG
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV NUM_PARTITIONS 16

ADD scripts /scripts

RUN /scripts/install-apt-libs.sh
RUN /scripts/install-python3.5.sh

RUN pip3 install git+git://github.com/bear/python-twitter.git@3f99eaf06a6a9862cd6957e33072165f7ab50c86
RUN pip3 install git+git://github.com/dpkp/kafka-python.git

# setup ssh
RUN mkdir /var/run/sshd

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

# Use a known SSH key - the one we use for psyduck containers
COPY authorized_keys /root/.ssh/authorized_keys

RUN apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y ssh openssh-server && \
    apt-get clean && \
    sed -r -i "s/^(Port )22/\1 2122/g" /etc/ssh/sshd_config

# Supervisor config
ADD supervisor/kafka.conf /etc/supervisor/conf.d/
ADD supervisor/producer.conf /etc/supervisor/conf.d/
ADD supervisor/zookeeper.conf /etc/supervisor/conf.d/
ADD supervisor/sshd.conf /etc/supervisor/conf.d/

# make image compatible with old way of starting kafka
RUN ln -s /scripts/start.sh /startup.sh

# 2122 is ssh, 2181 is zookeeper, 9092 is kafka, 8081 is the schema registry
EXPOSE 2122 2181 9092 8081

CMD ["/scripts/start.sh"]
