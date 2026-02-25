// Copyright Luc ROBERT--VILLANUEVA 2026
// Distributed under the Boost Software License, Version 1.0
// (See accompanying file LICENSE or copy at https://www.boost.org/LICENSE_1_0.txt)

const MB2_HEADER_MAGIC: u32 = 0xE85250D6;
const MB2_BOOTLOADER_MAGIC: u32 = 0x36D76289;
const MB2_ARCH_I386: u32 = 0;

const MB2_HEADER_TAG_END: u16 = 0;
const MB2_HEADER_TAG_FRAMEBUFFER: u16 = 5;
const MB2_HEADER_TAG_OPTIONAL: u16 = 1;

const MultibootHeader = extern struct {
    magic: u32,
    arch: u32,
    header_length: u32,
    checksum: u32,
};

const MultibootHeaderTag = extern struct {
    type: u16,
    flags: u16,
    size: u32,
};

const MultibootFramebufferTag = extern struct {
    tag: MultibootHeaderTag,
    width: u32,
    height: u32,
    depth: u32,
};

const AlignedFramebufferTag = extern struct {
    tag: MultibootFramebufferTag,
    pad_to_8: u32 = 0,
};

const MultibootFullHeader = extern struct {
    header: MultibootHeader,
    framebuffer: AlignedFramebufferTag,
    end: MultibootHeaderTag,
};

const MB2_HEADER_LENGTH: u32 = @sizeOf(MultibootFullHeader);

comptime {
    if ((@sizeOf(MultibootFullHeader) & 7) != 0) {
        @compileError("Multiboot2 header must be 8-byte aligned");
    }
}

export var multiboot align(8) linksection(".multiboot") = MultibootFullHeader{
    .header = .{
        .magic = MB2_HEADER_MAGIC,
        .arch = MB2_ARCH_I386,
        .header_length = MB2_HEADER_LENGTH,
        .checksum = -%(MB2_HEADER_MAGIC +% MB2_ARCH_I386 +% MB2_HEADER_LENGTH),
    },
    .framebuffer = .{
        .tag = .{
            .tag = .{
                .type = MB2_HEADER_TAG_FRAMEBUFFER,
                .flags = MB2_HEADER_TAG_OPTIONAL,
                .size = @sizeOf(MultibootFramebufferTag),
            },
            .width = 1082,
            .height = 512,
            .depth = 32,
        },
    },
    .end = .{
        .type = MB2_HEADER_TAG_END,
        .flags = 0,
        .size = @sizeOf(MultibootHeaderTag),
    },
};

export fn _boot() callconv(.naked) noreturn {
    // init stack and align on 16-byte boundary
    asm volatile (
        \\movl $stack_top, %esp
        \\andl $-8, %esp
        \\subl $12, %esp
    );

    // ecx to 0 + magic check (if fail we keep ecx at 0)
    asm volatile (
        \\xorl %ecx, %ecx
        \\cmpl $0x36D76289, %eax
        \\jne 1f
    );

    // init stack in ecx + push ecx
    asm volatile (
        \\movl %ebx, %ecx
        \\1:
        \\pushl %ecx
    );

    asm volatile (
        \\call _start
    );

    // security
    asm volatile (
        \\2:
        \\cli
        \\hlt
        \\jmp 2b
    );
}
