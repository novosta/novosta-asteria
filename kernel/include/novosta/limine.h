#pragma once
#include <stdint.h>

#define LIMINE_FRAMEBUFFER_REQUEST 0x3E7E279702BEA000

struct limine_framebuffer_request {
    uint64_t id;
    uint64_t revision;
    void* response;
};
