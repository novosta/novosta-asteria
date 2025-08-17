# === Build Settings ===
KERNEL := novosta.elf
ISO := novosta.iso
BUILD := build
ISO_DIR := $(BUILD)/iso

SRC := $(shell find kernel -name '*.c')
OBJ := $(patsubst kernel/%.c, $(BUILD)/%.o, $(SRC))
ASM := $(BUILD)/boot.o

# === Tools ===
CC := clang
LD := ld.lld
AS := nasm
CFLAGS := -target x86_64-elf -ffreestanding -O2 -Wall -Wextra -nostdlib -fno-pic
LDFLAGS := -nostdlib -static -T linker.ld

# === Rules ===
all: $(ISO)

$(BUILD)/%.o: kernel/%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(ASM): kernel/arch/x86_64/boot.s
	mkdir -p $(dir $@)
	$(AS) -f elf64 $< -o $@

$(BUILD)/$(KERNEL): $(OBJ) $(ASM)
	$(LD) $(LDFLAGS) -o $@ $(ASM) $(OBJ)

$(ISO): $(BUILD)/$(KERNEL)
	mkdir -p $(ISO_DIR)
	cp $< $(ISO_DIR)/kernel.elf
	cp limine.cfg $(ISO_DIR)/
	limine-install $(ISO_DIR)
	xorriso -as mkisofs \
		-b limine-cd.bin \
		--no-emul-boot -boot-load-size 4 -boot-info-table \
		-o $@ $(ISO_DIR)

clean:
	rm -rf build *.iso

.PHONY: all clean
