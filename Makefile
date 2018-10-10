all:

install: bin/guardian
	cp bin/guardian ../../bin/

bin/guardian:
	shards build --release guardian
