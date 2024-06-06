# Variables
CC := $(CROSS_COMPILE)gcc

writer: writer.c
	gcc writer.c -o writer

.PHONY: clean
clean:
	rm -f writer  $(wildcard *.o)

