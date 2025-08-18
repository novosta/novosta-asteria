# ===== Novosta Asteria Makefile (portable, CI-friendly) =====

# Paths / names
BUILD        := build
ISO_DIR      := $(BUILD)/iso
KERNEL_ELF   := $(BUILD)/novosta.elf
ISO          := novosta.iso
LINKER       := linker.ld

# Limine (fetch to build/limine; binary branch ships boot files)
LIMINE_DIR    := $(BUILD)/limine
LIMINE_BRANCH := v9.x-binary
LIMINE_CFG    := boot/limine.cfg
LIMINE_STAMP  := $(LIMINE_DIR)/.ready

# Tools
CC      := clang
LD      := ld.lld
CFLAGS  := -target x86_64-elf -ffreestanding -fno-pic -O2 -Wall -Wextra -Ikernel/include
LDFLAGS := -nostdlib -static -T $(LINKER)

# Sources (C + GAS .s assembled by clang)
C_SRCS := $(shell find kernel -name '*.c')
S_SRCS := $(shell find kernel -name '*.s')
OBJ_C  := $(patsubst kernel/%.c,$(BUILD)/kernel/%.o,$(C_SRCS))
OBJ_S  := $(patsubst kernel/%.s,$(BUILD)/kernel/%.o,$(S_SRCS))
OBJS   := $(OBJ_S) $(OBJ_C)

.PHONY: all iso run clean distclean limine

all: iso

# --- Compile C ---
$(BUILD)/kernel/%.o: kernel/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# --- Assemble GAS .s with clang ---
$(BUILD)/kernel/%.o: kernel/%.s
	@mkdir -p $(dir $@)
	$(CC) -target x86_64-elf -c $< -o $@

# --- Link kernel ---
$(KERNEL_ELF): $(OBJS) $(LINKER)
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

# --- Fetch Limine binary branch into build/limine ---
$(LIMINE_STAMP):
	@echo "==> Fetching Limine ($(LIMINE_BRANCH)) into $(LIMINE_DIR)"
	@rm -rf $(LIMINE_DIR)
	@git clone --depth=1 --branch=$(LIMINE_BRANCH) https://github.com/limine-bootloader/limine.git $(LIMINE_DIR)
	@# Build tools if present (harmless if there's no Makefile)
	@$(MAKE) -C $(LIMINE_DIR) || true
	@touch $(LIMINE_STAMP)

limine: $(LIMINE_STAMP)

# --- Build bootable ISO (no limine-install; El Torito via xorriso) ---
iso: $(KERNEL_ELF) limine $(LIMINE_CFG)
	@mkdir -p $(ISO_DIR)
	cp $(KERNEL_ELF) $(ISO_DIR)/kernel.elf
	cp $(LIMINE_CFG) $(ISO_DIR)/

	@set -e; \
	found_cd=; found_efi=; \
	for f in limine-cd.bin; do \
	  for base in "$(LIMINE_DIR)" "$(LIMINE_DIR)/bin"; do \
	    if [ -f "$${base}/$${f}" ]; then cp "$${base}/$${f}" "$(ISO_DIR)/"; found_cd=1; break; fi; \
	  done; \
	done; \
	for f in limine-eltorito-efi.bin limine-cd-efi.bin; do \
	  for base in "$(LIMINE_DIR)" "$(LIMINE_DIR)/bin"; do \
	    if [ -f "$${base}/$${f}" ]; then cp "$${base}/$${f}" "$(ISO_DIR)/"; found_efi="$${f}"; break; fi; \
	  done; \
	  [ -n "$${found_efi}" ] && break; \
	done; \
	if [ -z "$${found_cd}" ]; then echo "ERROR: limine-cd.bin not found in $(LIMINE_DIR){,/bin}"; exit 1; fi; \
	if [ -z "$${found_efi}" ]; then echo "ERROR: EFI boot image not found (looked for limine-eltorito-efi.bin or limine-cd-efi.bin)"; exit 1; fi; \
	echo "==> Using EFI image: $${found_efi}"; \
	xorriso -as mkisofs \
	  -b limine-cd.bin \
	  -no-emul-boot -boot-load-size 4 -boot-info-table \
	  --efi-boot "$${found_efi}" \
	  -efi-boot-part --efi-boot-image --protective-msdos-label \
	  -o "$(ISO)" "$(ISO_DIR)"

run: iso
	qemu-system-x86_64 -cdrom $(ISO) -m 512M -serial stdio

clean:
	rm -rf $(BUILD)

distclean: clean
	rm -f $(ISO)
