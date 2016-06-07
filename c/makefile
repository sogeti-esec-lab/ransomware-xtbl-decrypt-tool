CC=gcc
CFLAGS=-c -std=c11 -O3 -Werror
LDFLAGS=-s -shared
SOURCES=crypto_unlocker.c aes.c md5.c rc4.c
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=crypto_unlocker.dll

all: $(SOURCES) $(EXECUTABLE)
    
$(EXECUTABLE): $(OBJECTS) 
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.c.o:
	$(CC) $(CFLAGS) $< -o $@
