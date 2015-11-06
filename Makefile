.PHONY: build run unit units

build:
	docker build -t olalond3/coreos-bitcoind .
run:
	docker run --rm -it olalond3/coreos-bitcoind /bin/bash

test:
	fleetctl stop bitcoind@livenet
	-fleetctl destroy bitcoind@.service
	fleetctl submit bitcoind@.service
	fleetctl start bitcoind@livenet
