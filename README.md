# coreos-bitcoind

coreos-bitcoind is an [automatically built Docker image for
bitcoind](https://hub.docker.com/r/olalond3/coreos-bitcoind/).

It can be used as a [standalone](#standalone-usage) container or as a
[CoreOS service](#coreos-usage).

The image is based on [Alpine
Linux](https://github.com/gliderlabs/docker-alpine) resulting in a
smallish image of only 46 MB (the [smallest such
image](https://hub.docker.com/search/?q=bitcoind&page=1&isAutomated=0&isOfficial=0&pullCount=0&starCount=1)
to my knowledge).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [coreos-bitcoind](#coreos-bitcoind)
  - [Standalone usage](#standalone-usage)
    - [Configuration](#configuration)
    - [Data persistence](#data-persistence)
  - [CoreOS usage](#coreos-usage)
    - [Configuration](#configuration-1)
    - [Data persistence](#data-persistence-1)
    - [EBS](#ebs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Standalone usage

```bash
docker run \
  -d \
  --name=bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  olalond3/coreos-bitcoind

# view debug.log logs in real time
docker logs --follow bitcoind
```

Or with docker-compose (the [docker-compose.yml](./docker-compose.yml)
must be present in your current directory):

```bash
docker-compose up
```

For playing with bitcoind inside an ephemeral container:

```bash
docker run --rm -it olalond3/coreos-bitcoind /bin/bash
bash-4.3# bitcoind --help
```

Or with docker-compose:

```
docker-compose run bitcoind /bin/bash
```

### Configuration

The container is entirely configurable through environment variables
that follow this pattern `BITCOIND_CONF_ARG=value`, where `ARG` is one
of the bitcoind configuration flags.

See `docker run --rm -t olalond3/coreos-bitcoind bitcoind --help` for a list.

The following example starts bitcoind in testnet mode with rpc enabled
(if the rpcuser and/or rpcpassword are not specified, they will be
generated automatically):

```bash
docker run \
  -d \
  --name=bitcoind \
  -p 18333:18333 \
  -p 18332:18332 \
  -e BITCOIND_CONF_SERVER=1 \
  -e BITCOIND_CONF_TESTNET=1 \
  -e BITCOIND_CONF_RPCUSER=someuser \
  olalond3/coreos-bitcoind

# view automatically generated rpcpassword or user
docker logs bitcoind | grep ^rpc
```

### Data persistence

Data can be persisted through a data container:

```bash
docker run --name=bitcoind-data -v /bitcoin alpine:3.2 true
docker run \
  --volumes-from=bitcoind-data \
  -d \
  --name=bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  olalond3/coreos-bitcoind
```

Or by mounting a directory from the host:

```bash
docker run \
  -v ~/.bitcoin:/bitcoin
  -d \
  --name=bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  olalond3/coreos-bitcoind
```

Inside the container, the data folder is `/bitcoin/` and the
configuration file is `/etc/bitcoind.conf`.

## CoreOS usage

Important: in both unit files, set the MachineID directive to the ID of
the machine you want your services to be scheduled on. TODO: use BindsTo
and Before directives instead.

```
fleetctl start bitcoind@<instance>
```

For example:

```bash
fleetctl start bitcoind@livenet
```

Additional bitcoind services can be launched by choosing a different
name following the `@` (referred to as instance name).

`bitcoind@testnet` is handled specially by automatically defaulting to
`testnet=1` in the configuration.

The service opens ports on the host, so when running multiple instances
on a same host, you must ensure that ports (e.g. `rpcport` and `port` do
not conflict).

### Configuration

Configuration is entirely done through
[etcd](https://github.com/coreos/etcd). Internally,
[confd](https://github.com/kelseyhightower/confd) is used for
automatically restarting bitcoind when etcd configuration values change.

The configuration directory for a given service is
`/bitcoin/<instance>/conf` where `<instance>` is the instance name used
when launching the service (e.g.  bitcoind@livenet's directory would be
`/bitcoin/livenet/conf`.

All bitcoind configuration keys are supported.

See `docker run --rm -t olalond3/coreos-bitcoind bitcoind --help` for a list.

Example:

```bash
etcdctl set /bitcoin/livenet/conf/rpcuser someuser
etcdctl set /bitcoin/livenet/conf/rpcpassword somepassword
```

If the `rcpuser` and `rpcpassword` keys are not set at first launch, the
service will generate some automatically. To see those values, use
the follow commands:

```bash
etcdctl get /bitcoin/livenet/conf/rpcuser
etcdctl get /bitcoin/livenet/conf/rpcpassword
```

### Data persistence

By default, the bitcoind service will mount the
`/data/bitcoin/<instance>` directory from the host if it exists and use
it as its data directory. If the directory does not exist, at every
restart, bitcoind will lose its wallet and need to download the whole
blockchain from scratch.

### Data persistence using AWS EBS volume

If you are running your CoreOS cluster on AWS, you can use the
bitcoind-ebs@<instance> service which will attach an EBS volume on the
host and mount it at `/data/bitcoin/<instance>`.

The EBS volume must be created and formatted manually. It must
be in the same AWS region as the EC2 machine the service is scheduled on
(todo: automate this or replace with flocker).

Create a new 70+ GB SSD EBS volume in AWS EC2 web interface. Attach the
volume to a temporary Linux EC2 and format the disk with mkfs:

```bash
mkfs -t ext4 /dev/xvdg
```

Set the following configuration keys:

```bash
etcdctl set /aws/key <aws key id>
etcdctl set /aws/secret <aws key secret>
etcdctl set /aws/region <aws region of ebs volume is>
etcdctl set /bitcoin/<instance>/ebs/volume_id <ebs volume id>
```

bitcoind-ebs must be launched **before** bitcoind and must be scheduled
on the same machine. TODO: use BindTo and Before directives so that this
is handled automatically (instead of MachineID).

```
fleetctl start bitcoind-ebs@livenet
# wait for EBS volume to be mounted
# fleetctl journal -f bitcoind-ebs@livenet
fleetctl start bitcoind@livenet
```