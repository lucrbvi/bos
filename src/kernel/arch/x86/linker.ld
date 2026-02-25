/*
Copyright Luc ROBERT--VILLANUEVA 2026
Distributed under the Boost Software License, Version 1.0
(See accompanying file LICENSE or copy at https://www.boost.org/LICENSE_1_0.txt)
*/

ENTRY(_boot)

SECTIONS {
    . = 1M;

    .multiboot ALIGN(8) : {
      KEEP(*(.multiboot))
    }

    .text : {
      *(.text .text.*)
    }

    .rodata : ALIGN(8) {
      *(.rodata .rodata.*)
    }

    .data : ALIGN(8) {
      *(.data .data.*)
    }

    .bss : ALIGN(8) {
      *(COMMON)
      *(.bss .bss.*)
      . = ALIGN(16);
      . += 16384;
      stack_top = .;
    }
}
