# Novosta OS - Asteria

Asteria is a hobbyist 64‑bit x86 operating system experiment built as a learning
project. It currently boots with the [Limine](https://github.com/limine-bootloader/limine)
bootloader and draws text using the VGA text buffer.

## Features
- Limine-based boot chain
- Minimal kernel with VGA text logger
- Example build system using Clang and LLD

## Prerequisites
 - `clang` and `ld.lld`
 - `make`
 - `git-lfs` (for fetching Limine binaries)
 - `xorriso` (for ISO creation)
 - `qemu-system-x86_64` (to run the ISO)

## Building
```sh
make
```
This fetches Limine if necessary, builds the kernel and creates `novosta.iso`.

## Running
Run the ISO in QEMU:
```sh
make run
```
This boots the ISO and prints boot logs to the serial console.
