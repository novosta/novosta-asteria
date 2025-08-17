#include <novosta/limine.h>

__attribute__((section(".limine_reqs")))
struct limine_framebuffer_request framebuffer_request = {
    .id = LIMINE_FRAMEBUFFER_REQUEST,
    .revision = 0
};
