all:

install: ../../bin/paladin

../../bin/paladin: bin/paladin ../../bin
	cp bin/paladin ../../bin/

../../bin:
	mkdir -p ../../bin

bin/paladin:
	shards build --release paladin
