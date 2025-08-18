#include <novosta/logger.h>

__attribute__((noreturn))
void kernel_main(void) {
    log_info("Novosta OS (Asteria) booting...");
    log_debug("Logger initialized.");

    // Demonstrate cursor wrapping by printing more than 25 lines
    for (int i = 0; i < 30; ++i) {
        log_debug("Testing VGA logger wraparound.");
    }

    for (;;) {
        __asm__ volatile ("hlt");
    }
}
