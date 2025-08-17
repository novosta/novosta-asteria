#include <novosta/logger.h>
#include <stdint.h>
#include <stddef.h>

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY ((uint16_t*)0xB8000)

static size_t cursor = 0;

static void print(const char* prefix, const char* msg) {
    const char* p = prefix;
    while (*p) VGA_MEMORY[cursor++] = (*p++ | 0x0700);
    p = msg;
    while (*p) VGA_MEMORY[cursor++] = (*p++ | 0x0700);
    VGA_MEMORY[cursor++] = ('\n' | 0x0700); // crude newline
}

void log_info(const char* msg)  { print("[INFO] ", msg); }
void log_debug(const char* msg) { print("[DEBUG] ", msg); }
void log_panic(const char* msg) { print("[PANIC] ", msg); while (1); }
