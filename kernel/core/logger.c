#include <novosta/logger.h>
#include <stdint.h>
#include <stddef.h>

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY ((uint16_t*)0xB8000)

static size_t cursor = 0;

static void advance_cursor(void) {
    if (cursor >= VGA_WIDTH * VGA_HEIGHT) {
        cursor = 0; // wrap to top-left if we overflow the buffer
    }
}

static void print(const char* prefix, const char* msg) {
    const char* p = prefix;
    while (*p) {
        VGA_MEMORY[cursor++] = (*p++ | 0x0700);
        advance_cursor();
    }
    p = msg;
    while (*p) {
        VGA_MEMORY[cursor++] = (*p++ | 0x0700);
        advance_cursor();
    }
    VGA_MEMORY[cursor++] = ('\n' | 0x0700); // crude newline
    advance_cursor();
}

void log_info(const char* msg)  { print("[INFO] ", msg); }
void log_debug(const char* msg) { print("[DEBUG] ", msg); }
__attribute__((noreturn))
void log_panic(const char* msg) {
    print("[PANIC] ", msg);
    for (;;) {
        __asm__ volatile ("hlt");
    }
}
