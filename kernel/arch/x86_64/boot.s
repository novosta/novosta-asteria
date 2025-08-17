.global _start
.section .text
_start:
    call kernel_main
    cli
    hlt
