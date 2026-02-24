ENTRY(_boot)

SECTIONS {
    . = 0x40000000;

    .multiboot ALIGN(8) : {
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
        . += 65536;
        stack_top = .;
    }
}
