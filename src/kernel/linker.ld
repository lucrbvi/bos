ENTRY(_boot)

SECTIONS {
    . = 1M;

    .multiboot ALIGN(4) : {
      KEEP(*(.multiboot))
    }
    .rodata : ALIGN(16) {
      *(.rodata .rodata.*)
    }
    .text : {
      *(.text .text.*)
    }
    .data : ALIGN(16) {
      *(.data .data.*)
    }
    .bss : ALIGN(16) {
      *(COMMON)
      *(.bss .bss.*)
      . = ALIGN(16);
      . += 6384;
      stack_top = .;
    }
}
