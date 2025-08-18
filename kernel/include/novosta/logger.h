#pragma once

void log_info(const char* msg);
void log_debug(const char* msg);
void log_panic(const char* msg) __attribute__((noreturn));
