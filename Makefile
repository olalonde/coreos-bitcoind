.PHONY: build run test

build:
	docker build -t olalond3/coreos-bitcoind .
run:
	docker run --rm -it olalond3/coreos-bitcoind /bin/bash

fleet-submit:
	-fleetctl destroy bitcoind@livenet
	-fleetctl destroy bitcoind-ebs@livenet
	fleetctl submit bitcoind@livenet
	fleetctl submit bitcoind-ebs@livenet

fleet-load:
	fleetctl load bitcoind@livenet
	fleetctl load bitcoind-ebs@livenet

fleet-start:
	fleetctl start bitcoind-ebs@livenet
	fleetctl start bitcoind@livenet

fleet-stop:
	fleetctl stop bitcoind@livenet

test: fleet-submit fleet-load fleet-start
