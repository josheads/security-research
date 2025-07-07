CFLAGS=-std=gnu2x -Og -ggdb3 $(shell pkg-config --cflags $(PKGDEPS))
CPPFLAGS=-Wall -W -D_GNU_SOURCE -DZENTOOL_VERSION=\"$(VERSION)\"
LDLIBS=$(shell pkg-config --libs $(PKGDEPS))
LDFLAGS=
VERSION=0.01

UNAME_S := $(shell uname -s)
LOADER_O = loader.o

ifeq ($(UNAME_S),Linux)
	LDFLAGS += -Wl,-z,noexecstack
	CFLAGS += -mavx -march=znver2
	CPPFLAGS += -mavx -march=znver2
endif
ifeq ($(UNAME_S),Darwin)
	LOADER_O =
endif

# List of all required dependencies in pkg-config format.
PKGDEPS=openssl,gmp,json-c

.PHONY: clean distclean sync check template.bin test_ksy

ifeq ($(UNAME_S),Linux)
all: check zentool mcop mcas opcodes mtalk dumper
endif
ifeq ($(UNAME_S),Darwin)
all: check zentool mcop mcas
endif




# build debug versions of all binaries
debug:	CFLAGS+=-fsanitize=address -O0
debug: clean all

# This is just to check all required packages are installed
check:
	@pkg-config $(PKGDEPS) || (echo "missing dependencies, try:" && echo "    Debian: apt install pkg-config libssl-dev libgmp-dev libjson-c-dev nasm" && echo "    Fedora: dnf install pkg-config gmp-devel json-c-devel openssl-devel libasan nasm" && echo "    macOS: brew install pkg-config gmp json-c openssl nasm" && exit 1)
	@nasm --version > /dev/null || (echo "missing dependency, try:" && echo "   Debian: apt install nasm" && echo "   Fedora: dnf install nasm" && echo "   macOS: brew install nasm" && exit 1)

sync: HOST=amdbench.cpu
sync:
	rsync --delete -azF . $(HOST):zentool/

ifeq ($(UNAME_S),Linux)
%.o: %.asm
	nasm -f elf64 -o $@ $^
opcodes: CFLAGS=-fno-sanitize=address
opcodes: corechk.o
mtalk: LDFLAGS+=-O0
endif
ifeq ($(UNAME_S),Darwin)
%.o: %.asm
	nasm -f macho64 -o $@ $^
opcodes:
	@echo "opcodes target is not supported on macOS"
mtalk:
	@echo "mtalk target is not supported on macOS"
dumper:
	@echo "dumper target is not supported on macOS"
endif

fields.o disas.o: RegOp_fields.h LdStOp_fields.h SpecOp_fields.h BrOp_fields.h SRegOp_fields.h

zentool: ucode.o risc86.o preimage.o fixup.o $(LOADER_O) dump.o options.o edit.o verify.o disas.o xxtea.o encrypt.o util.o parse.o cpuid.o data.o symbols.o fields.o factor.o

mcas: disas.o options.o ucode.o parse.o ucode.o \
      risc86.o preimage.o options.o util.o cpuid.o factor.o dump.o data.o
mcop: ucode.o risc86.o disas.o util.o fields.o options.o \
      cpuid.o preimage.o factor.o dump.o data.o
mtalk: util.o options.o
dumper: dumper.o

# The automated tests use this file
.PHONY: template.bin
template.bin:
	@echo "template.bin is not supported on macOS"

clean:
	rm -f *.o zentool mcas mcop mtalk opcodes dumper template.bin
	rm -f zentool-$(VERSION).tar.gz

distclean: clean
	rm -f *_fields.h

dist: distclean
	@tmpfile=$(mktemp)
	@tar	--directory=..                            \
		--exclude-vcs                                 \
		--exclude-vcs-ignores                         \
		--exclude-tag-all=.nobackup                   \
		--numeric-owner                               \
		--owner=:1000                                 \
		--group=:1000                                 \
		--gzip                                        \
		--create                                      \
		--transform="s#^zentool#zentool-$(VERSION)#"  \
		--file=${tmpfile}                            \
		$(notdir $(abspath .))
	@mv ${tmpfile} zentool-$(VERSION).tar.gz
	@ls -l zentool-$(VERSION).tar.gz
