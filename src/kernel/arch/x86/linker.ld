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
