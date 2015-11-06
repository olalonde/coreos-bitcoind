FROM alpine:3.2
MAINTAINER Olivier Lalonde <olalonde@gmail.com>

ENV BITCOIN_VERSION 0.11.1

# install common packages
RUN apk add --update-cache \
  bash \
  curl \
  sudo \
  && rm -rf /var/cache/apk/*

# install confd
RUN curl -sSL -o "/usr/local/bin/confd" "https://github.com/kelseyhightower/confd/releases/download/v0.9.0/confd-0.9.0-linux-amd64" \
  && chmod +x /usr/local/bin/confd

COPY rootfs /

# compile bitcoind from source
RUN build

ENV PATH /opt/bitcoin/bin:$PATH

CMD ["boot"]