AS      = nasm
ASFLAGS = -f elf64 -F dwarf

LD      = ld
LDFLAGS = -m elf_x86_64

SOURCES     = $(wildcard *.asm)
OBJECTS     = $(SOURCES:.asm=.o)
EXECUTABLE  = program


all: $(EXECUTABLE)


$(EXECUTABLE): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@


$(OBJECTS): %.o : %.asm
	$(AS) $(ASFLAGS) $< -o $@


.PHONY: clean
clean:
	rm -rf $(OBJECTS) $(EXECUTABLE)
