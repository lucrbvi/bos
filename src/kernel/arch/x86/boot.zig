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
const MB2_ARCH_X86: u32 = 0;
const MB2_HEADER_LENGTH: u32 = 16 + 8;

export var multiboot align(8) linksection(".multiboot") =
    MultibootFull{
        .header = .{
            .magic = MB2_MAGIC,
            .arch = MB2_ARCH_X86,
            .header_length = MB2_HEADER_LENGTH,
            .checksum = -%(MB2_MAGIC +% MB2_ARCH_X86 +% MB2_HEADER_LENGTH),
        },
        .end_tag = .{
            .type = 0,
            .flags = 0,
            .size = 8,
        },
    };

export fn _boot() callconv(.naked) noreturn {
    asm volatile (
        \\movl $stack_top, %esp
        \\andl $-16, %esp
        \\subl $12, %esp
        \\call _start
        \\hlt
    );
}
