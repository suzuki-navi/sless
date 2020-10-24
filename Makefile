build: bin/sless

bin/sless: etc/sznpack.sh src/*
	mkdir -p bin
	bash ./etc/sznpack.sh -o bin/sless

etc/sznpack.sh: etc/download-sznpack.sh
	bash etc/download-sznpack.sh > etc/sznpack.sh

test: bin/sless FORCE
	cd test; bash ./test.sh

FORCE:

