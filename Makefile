all:

install: ../../bin/guardian

../../bin/guardian: bin/guardian
	cp bin/guardian ../../bin/

bin/guardian:
	shards build --release guardian
