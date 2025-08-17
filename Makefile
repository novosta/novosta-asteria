# ===== Novosta Asteria Makefile (Linux + CI) =====

# Paths / names
BUILD        := build
ISO_DIR      := $(BUILD)/iso
KERNEL_ELF   := $(BUILD)/novosta.elf
ISO          := novosta.iso
LINKER       := linker.ld

# Limine (built into build/limine to avoid stale dirs)
LIMINE_DIR   := $(BUILD)/limine
LIMINE_CFG   := boot/limine.cfg
LIMINE_FILES := $(LIMINE_DIR)/limine.sys \
                $(LIMINE_DIR)/limine-cd.bin \
                $(LIMINE_DIR)/limine-eltorito-efi.bin
LIMINE_STAMP := $(LIMINE_DIR)/.built

# Tools
CC      := clang
LD      := ld.lld
CFLAGS  := -target x86_64-elf -ffreestanding -fno-pic -O2 -Wall -Wextra -Ikernel/include
LDFLAGS := -nostdlib -static -T $(LINKER)

# Sources
C_SRCS := $(shell find kernel -name '*.c')
S_SRCS := $(shell find kernel -name '*.s')   # GAS/AT&T assembled with clang
OBJ_C  := $(patsubst kernel/%.c,$(BUILD)/kernel/%.o,$(C_SRCS))
OBJ_S  := $(patsubst kernel/%.s,$(BUILD)/kernel/%.o,$(S_SRCS))
OBJS   := $(OBJ_S) $(OBJ_C)

.PHONY: all iso run clean distclean limine

all: iso

# --- Compile C files ---
$(BUILD)/kernel/%.o: kernel/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# --- Assemble GAS .s files with clang ---
$(BUILD)/kernel/%.o: kernel/%.s
	@mkdir -p $(dir $@)
	$(CC) -target x86_64-elf -c $< -o $@

# --- Link kernel ---
$(KERNEL_ELF): $(OBJS) $(LINKER)
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

# --- Fetch & build Limine into build/limine ---
$(LIMINE_STAMP):
	@echo "==> Cloning & building Limine into $(LIMINE_DIR)"
	@rm -rf $(LIMINE_DIR)
	@git clone --depth=1 https://github.com/limine-bootloader/limine.git $(LIMINE_DIR)
	@$(MAKE) -C $(LIMINE_DIR)
	@touch $(LIMINE_STAMP)

limine: $(LIMINE_STAMP)

# --- Build bootable ISO (outputs novosta.iso at repo root) ---
iso: $(KERNEL_ELF) limine $(LIMINE_CFG)
	@mkdir -p $(ISO_DIR)
	cp $(KERNEL_ELF) $(ISO_DIR)/kernel.elf
	cp $(LIMINE_CFG) $(ISO_DIR)/
	cp $(LIMINE_FILES) $(ISO_DIR)/
	$(LIMINE_DIR)/limine-install $(ISO_DIR)
	xorriso -as mkisofs \
		-b limine-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-eltorito-efi.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		-o $(ISO) $(ISO_DIR)

run: iso
	qemu-system-x86_64 -cdrom $(ISO) -m 512M -serial stdio

clean:
	rm -rf $(BUILD)

distclean: clean
	rm -f $(ISO)
