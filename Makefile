CC=gcc
CFLAGS=-Wall -O2 -std=c99
TARGET=hostpress

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -o $(TARGET) $(TARGET).c

clean:
	rm -f $(TARGET)
