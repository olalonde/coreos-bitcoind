FROM alpine:3.2
MAINTAINER Olivier Lalonde <olalonde@gmail.com>

ENV BITCOIN_VERSION 0.11.1

# install common packages
RUN apk add --update-cache \
  bash \
  curl \
  sudo \
  boost \
  openssl \
  protobuf \
  boost-program_options \
  db \
  db-c++ \
  && rm -rf /var/cache/apk/*

# install confd
RUN curl -sSL -o "/usr/local/bin/confd" "https://github.com/kelseyhightower/confd/releases/download/v0.9.0/confd-0.9.0-linux-amd64" \
  && chmod +x /usr/local/bin/confd

# install etcdctl
RUN curl -sSL -o "etcd.tar.gz" \
  "https://github.com/coreos/etcd/releases/download/v2.2.1/etcd-v2.2.1-linux-amd64.tar.gz" \
  && tar xzvf etcd.tar.gz \
  && mv ./etcd-v2.2.1-linux-amd64/etcdctl /usr/local/bin/etcdctl \
  && chmod +x /usr/local/bin/etcdctl \
  && rm ./etcd.tar.gz \
  && rm -rf ./etcd-v2.2.1-linux-amd64

COPY rootfs /

# compile bitcoind from source
RUN build
ENV PATH /opt/bitcoin/bin:$PATH

# create bitcoin user/group
#RUN addgroup -S bitcoin 2> /dev/null
#RUN adduser -S -H -h /bitcoin -g bitcoin -G bitcoin -D -s /sbin/nologin bitcoin 2> /dev/null
# create bitcoin datadir
RUN mkdir -p /bitcoin
#RUN chown bitcoin:bitcoin /bitcoin
#RUN chmod 0700 /bitcoin

# create /etc/bitcoin.conf
RUN touch /etc/bitcoin.conf
#RUN chown bitcoin:bitcoin /etc/bitcoin.conf
#RUN chmod 0600 /etc/bitcoin.conf

ENV NETWORK livenet

CMD ["boot"]