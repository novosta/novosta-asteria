# Top-level Makefile for building Novosta Asteria ISO on Linux

# === Directories ===
SRC_DIR      := kernel
BUILD_DIR    := build
ISO_DIR      := $(BUILD_DIR)/iso
LIMINE_DIR   := limine

# === Files ===
ELF_FILE     := $(BUILD_DIR)/novosta.elf
ISO_FILE     := $(BUILD_DIR)/novosta.iso
LINKER_SCRIPT := linker.ld

# === Compiler/Linker ===
CC           := clang
LD           := ld.lld
AS           := nasm
CFLAGS       := -target x86_64-elf -ffreestanding -O2 -Wall -Wextra -nostdlib -fno-pic -Ikernel/include
LDFLAGS      := -nostdlib -static -T $(LINKER_SCRIPT)
ASFLAGS      := -f elf64

# === Source files ===
C_SRC := \
	$(SRC_DIR)/core/logger.c \
	$(SRC_DIR)/core/main.c \
	$(SRC_DIR)/arch/x86_64/limine_handoff.c \
	$(SRC_DIR)/include/novosta/panic.c

ASM_SRC := $(SRC_DIR)/arch/x86_64/boot.s

OBJ := $(C_SRC:%.c=$(BUILD_DIR)/%.o) \
	$(ASM_SRC:%.s=$(BUILD_DIR)/%.o)

# === Targets ===
.PHONY: all clean iso

all: $(ISO_FILE)

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) $< -o $@

$(ELF_FILE): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $(OBJ)

$(ISO_FILE): $(ELF_FILE)
	@mkdir -p $(ISO_DIR)
	cp $(ELF_FILE) $(ISO_DIR)/kernel.elf
	cp boot/limine.cfg $(ISO_DIR)/
	cp $(LIMINE_DIR)/limine.sys \
	   $(LIMINE_DIR)/limine-cd.bin \
	   $(LIMINE_DIR)/limine-eltorito-efi.bin \
	   $(ISO_DIR)/
	$(LIMINE_DIR)/limine-install $(ISO_DIR)

clean:
	rm -rf $(BUILD_DIR)
