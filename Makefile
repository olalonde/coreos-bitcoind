.PHONY: build run unit units

build:
	docker build -t olalond3/coreos-bitcoind .
run:
	docker run --rm -it olalond3/coreos-bitcoind /bin/bash

unit: bitcoind.service.tmpl
	@sed -e "s/__NETWORK__/${NETWORK}/g" \
		./bitcoind.service.tmpl > "./units/bitcoind-${NETWORK}.service"

fleet: units
	fleetctl stop units/bitcoind-livenet.service
	-fleetctl destroy units/bitcoind-livenet.service
	fleetctl start units/bitcoind-livenet.service
	fleetctl journal -f bitcoind-livenet

units:
	NETWORK=livenet make unit
	NETWORK=testnet make unit
