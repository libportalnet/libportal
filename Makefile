ZIG = /usr/bin/env zig
ZIGMOD = /usr/bin/env zigmod

install:
	$(ZIGMOD) fetch --no-update

build:
	$(ZIG) build

run:
	$(ZIG) build run

test:
	$(ZIG) build test
