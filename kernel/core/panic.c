#include <novosta/panic.h>
#include <novosta/logger.h>

__attribute__((noreturn))
void panic(const char* msg) {
    log_panic(msg);
    for (;;) {
        __asm__ volatile ("hlt");
    }
}
