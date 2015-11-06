build:
	docker build -t olalond3/coreos-bitcoind .
run:
	docker run --rm -it olalond3/coreos-bitcoind /bin/bash
