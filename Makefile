all:

install: ../../bin/guardian

../../bin/guardian: bin/guardian ../../bin
	cp bin/guardian ../../bin/

../../bin:
	mkdir -p ../../bin

bin/guardian:
	shards build --release guardian
