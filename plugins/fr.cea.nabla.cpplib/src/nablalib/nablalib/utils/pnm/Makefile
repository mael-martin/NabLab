CC  ?= clang
EXEC = pnm.out
SRC  = $(wildcard *.c)
OBJ  = ${SRC:%.c=%.o}

CFLAGS  = -Wall -Werror -Wextra -Wpedantic -I../../../ -g
LDFLAGS = -static

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) $< -c

clean:
	rm $(EXEC) $(OBJ)

.PHONY: clean
