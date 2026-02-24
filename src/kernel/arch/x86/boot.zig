const MB2_MAGIC: u32 = 0xe85250d6;
const MB2_ARCH_X86: u32 = 0;
const MB2_HEADER_LENGTH: u32 = 16 + 16 + 20 + 8; // header(16) + info_req(12+4=16) + fb_tag(20) + end(8) = 60

const MultibootHeader = extern struct {
    magic: u32,
    arch: u32,
    header_length: u32,
    checksum: u32,
};

const MultibootInfoReqTag = extern struct {
    type: u16 = 1,
    flags: u16 = 0,
    size: u32 = 12,
    mbi_tag_type: u32 = 8, // framebuffer info
};

const MultibootFramebufferTag = extern struct {
    type: u16 = 5, // graphic mode
    flags: u16 = 0,
    size: u32 = 20,
    width: u32 = 1024,
    height: u32 = 768,
    depth: u32 = 32,
};

const MultibootTagEnd = extern struct {
    type: u32 = 0,
    flags: u32 = 0,
    size: u32 = 8,
};

const MultibootFull = extern struct {
    header: MultibootHeader,
    info_req: MultibootInfoReqTag,
    _pad: u32 = 0,
    fb_tag: MultibootFramebufferTag,
    end_tag: MultibootTagEnd,
};

export var multiboot align(8) linksection(".multiboot") =
    MultibootFull{
        .header = .{
            .magic = MB2_MAGIC,
            .arch = MB2_ARCH_X86,
            .header_length = MB2_HEADER_LENGTH,
            .checksum = -%(MB2_MAGIC +% MB2_ARCH_X86 +% MB2_HEADER_LENGTH),
        },
        .info_req = .{},
        .fb_tag = .{},
        .end_tag = .{},
    };

export fn _boot() callconv(.naked) noreturn {
    asm volatile (
        \\movl $stack_top, %esp
        \\andl $-16, %esp
        \\subl $12, %esp
        // EBX has MultiBoot2Info
        \\pushl %ebx
        \\call _start
        \\hlt
    );
}
