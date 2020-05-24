FROM centos:7
MAINTAINER Plutarco Guerrero, plutarcog@gmail.com

ENV GOSU_VERSION=1.12
RUN set -eux; \
  gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
  curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64"; \
  curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc"; \
  gpg --batch --verify /usr/local/bin/gosu.asc; \
  rm /usr/local/bin/gosu.asc; \
  rm -r /root/.gnupg; \
  chmod +x /usr/local/bin/gosu; \
# Verify that the binary works
  gosu nobody true

# Agregar repo Rabbitmq
COPY bintray-rabbitmq-server.repo /etc/yum.repos.d/

# Agregar repo Erlang
COPY bintray-rabbitmq-erlang.repo /etc/yum.repos.d/

RUN set -eux; \
  yum update -y; \
# Install Erlang
  yum install -y erlang

# Install RabbitMQ
RUN set -eux; \
  yum install -y rabbitmq-server; \
# Ensure RabbitMQ was installed correctly by running a few commands that do not depend on a running server, as the rabbitmq user
# If they all succeed, it's safe to assume that things have been set up correctly
	gosu rabbitmq rabbitmqctl help; \
	gosu rabbitmq rabbitmqctl list_ciphers

ENV RABBITMQ_DATA_DIR=/var/lib/rabbitmq
# Fix permissions & allow root user to connect to the RabbitMQ Erlang VM
RUN set -eux; \
	mkdir -p /tmp/rabbitmq-ssl; \
	chown -fR rabbitmq:rabbitmq /tmp/rabbitmq-ssl; \
	chmod 777 /tmp/rabbitmq-ssl; \
        chmod g+w /etc/rabbitmq

# set home so that any `--user` knows where to put the erlang cookie
ENV HOME $RABBITMQ_DATA_DIR
# Hint that the data (a.k.a. home dir) dir should be separate volume
VOLUME $RABBITMQ_DATA_DIR

# warning: the VM is running with native name encoding of latin1 which may cause Elixir to malfunction as it expects utf8. Please ensure your locale is set to UTF-8 (which can be verified by running "locale" in your shell)
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

COPY docker-entrypoint.sh /usr/local/bin/
RUN set -eux; \
   chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 4369 5671 5672 25672
CMD ["rabbitmq-server"]
