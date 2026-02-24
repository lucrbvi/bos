const MultibootHeader = extern struct {
    magic: u32,
    arch: u32,
    header_length: u32,
    checksum: u32,
};

const MultibootTagEnd = extern struct {
    type: u32,
    flags: u32,
    size: u32,
};

const MultibootFull = extern struct {
    header: MultibootHeader,
    end_tag: MultibootTagEnd,
};

const MB2_MAGIC: u32 = 0xe85250d6;
const MB2_ARCH_I386: u32 = 0;
const MB2_HEADER_LENGTH: u32 = 16 + 8;

export var multiboot align(8) linksection(".multiboot") =
    MultibootFull{
        .header = .{
            .magic = MB2_MAGIC,
            .arch = MB2_ARCH_I386,
            .header_length = MB2_HEADER_LENGTH,
            .checksum = -%(MB2_MAGIC +% MB2_ARCH_I386 +% MB2_HEADER_LENGTH),
        },
        .end_tag = .{
            .type = 0,
            .flags = 0,
            .size = 8,
        },
    };

export fn _boot() callconv(.naked) noreturn {
    asm volatile (
        \\adrp x10, stack_top
        \\add  x10, x10, :lo12:stack_top
        \\mov  sp, x10

        // Multiboot2: x0 = magic, x1 = mbi
        // QEMU -kernel: x0 = dtb, x1 = 0
        \\mov  w11, #0x6289
        \\movk w11, #0x36d7, lsl #16   // w11 = 0x36d76289
        \\cmp  w0, w11
        \\b.ne 1f
        \\mov  x0, x1                 // arg0 = mbi_addr
        \\b 2f
        \\1:
        \\mov  x0, xzr                // arg0 = 0 => no MBI
        \\2:
        \\bl   _start

        // Halt
        \\99:
        \\wfi
        \\b 99b
    );
}
