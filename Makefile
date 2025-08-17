# Top-level Makefile for novosta-asteria

TARGET     := novosta.elf
ISO        := novosta.iso
LIMINE_CFG := limine.cfg

BUILD_DIR  := build
ISO_DIR    := $(BUILD_DIR)/iso

CC         := clang
LD         := ld.lld
CFLAGS     := -target x86_64-elf -ffreestanding -O2 -Wall -Wextra -nostdlib -fno-pic -Ikernel/include
LDFLAGS    := -nostdlib -static -T linker.ld

SRC_C      := \
    kernel/core/logger.c \
    kernel/core/main.c \
    kernel/include/novosta/panic.c \
    kernel/arch/x86_64/limine_handoff.c

SRC_S      := \
    kernel/arch/x86_64/boot.s

OBJ_C      := $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRC_C))
OBJ_S      := $(patsubst %.s,$(BUILD_DIR)/%.o,$(SRC_S))

OBJS       := $(OBJ_C) $(OBJ_S)

.PHONY: all clean run iso

all: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

iso: $(BUILD_DIR)/$(TARGET)
	@mkdir -p $(ISO_DIR)
	cp $(BUILD_DIR)/$(TARGET) $(ISO_DIR)/kernel.elf
	cp $(LIMINE_CFG) $(ISO_DIR)/
	limine-install $(ISO_DIR)

clean:
	rm -rf $(BUILD_DIR)

run: iso
	qemu-system-x86_64 -cdrom $(ISO_DIR)/$(ISO) -m 512M
