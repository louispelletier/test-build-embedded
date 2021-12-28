main: src/main.c
	cc src/main.c -o main

.PHONY: clean
clean:
	rm -f main

.PHONY: all
all: main