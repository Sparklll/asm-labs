CC      = gcc
CFLAGS  = -std=c99 -Wall

AS      = nasm
ASFLAGS = -f elf64 -F dwarf

LD      = ld
LDFLAGS = -m elf_x86_64 -lc --dynamic-linker=/lib64/ld-linux-x86-64.so.2

SOURCES        = $(wildcard *.asm)
OBJECTS        = $(SOURCES:.asm=.o)
EXTERN_SOURCES = $(wildcard *.c)
EXTERN_OBJECTS = $(EXTERN_SOURCES:.c=.o)


EXECUTABLE  = program


all: $(EXECUTABLE)


$(EXECUTABLE): $(OBJECTS) $(EXTERN_OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) $(EXTERN_OBJECTS) -o $@


$(OBJECTS): %.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@


$(EXTERN_OBJECTS): %.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@


.PHONY: clean
clean:
	rm -rf $(OBJECTS) $(EXTERN_OBJECTS) $(EXECUTABLE)
