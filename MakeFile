CFLAGS=-std=gnu11 -ffreestanding -O2 -Wall -Wextra
LDFLAGS=-nostdlib -static

KERNEL_ELF=build/novosta.elf
ISO_DIR=build/iso
ISO_FILE=novosta.iso

SRC=$(shell find kernel -name '*.c')
OBJ=$(SRC:.c=.o)

all: $(ISO_FILE)

$(KERNEL_ELF): $(OBJ) kernel/arch/x86_64/boot.o linker.ld
	ld -n -T linker.ld -o $@ $^

%.o: %.c
	mkdir -p $(@D)
	x86_64-elf-gcc $(CFLAGS) -c $< -o $@

%.o: %.s
	mkdir -p $(@D)
	x86_64-elf-as $< -o $@

$(ISO_FILE): $(KERNEL_ELF)
	cp $(KERNEL_ELF) $(ISO_DIR)/kernel.elf
	limine-install $(ISO_DIR)
	xorriso -as mkisofs -b limine-cd.bin \
		--no-emul-boot -boot-load-size 4 -boot-info-table \
		-o $(ISO_FILE) $(ISO_DIR)

clean:
	rm -rf build *.iso
