$(shell mkdir -p bin)

CFLAGS := -I . -I /usr/include/SDL2
UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
	CFLAGS += -I /Library/Frameworks/SDL2.framework/Headers -F /Library/Frameworks/ -framework SDL2
else
	LDFLAGS := -lSDL2
endif

all: bin/si78c

clean:
	rm -rf bin/si78c

bin/si78c: si78c.c si78c_proto.h
	gcc $(CFLAGS) $< -o $@ $(LDFLAGS)
