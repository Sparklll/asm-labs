AS      = nasm
ASFLAGS = -f elf64 -F dwarf

LD      = ld
LDFLAGS = -m elf_x86_64 -lc --dynamic-linker=/lib64/ld-linux-x86-64.so.2 

SOURCES        = $(wildcard *.asm)
OBJECTS        = $(SOURCES:.asm=.o)

EXECUTABLE  = game


all: $(EXECUTABLE)


$(EXECUTABLE): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@


$(OBJECTS): %.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@


.PHONY: clean
clean:
	rm -rf $(OBJECTS) $(EXTERN_OBJECTS) $(EXECUTABLE)
