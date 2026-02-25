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

export var pml4 align(4096) linksection(".bss") = [_]u64{0} ** 512;
export var pdpt align(4096) linksection(".bss") = [_]u64{0} ** 512;
export var pd_all align(4096) linksection(".bss") = [_]u64{0} ** 2048;

export fn _boot() callconv(.naked) noreturn {
    asm volatile (
        \\.code32
        \\cli
        \\xorl %esi, %esi
        \\cmpl $0x36D76289, %eax
        \\jne 1f
        \\movl %ebx, %esi
        \\1:
        \\movl $pdpt, %eax
        \\orl $0x3, %eax
        \\movl $pml4, %edi
        \\movl %eax, 0(%edi)
        \\movl $0, 4(%edi)
        \\movl $pd_all, %eax
        \\orl $0x3, %eax
        \\movl $pdpt, %edi
        \\movl %eax, 0(%edi)
        \\movl $0, 4(%edi)
        \\movl $pd_all + 0x1000, %eax
        \\orl $0x3, %eax
        \\movl %eax, 8(%edi)
        \\movl $0, 12(%edi)
        \\movl $pd_all + 0x2000, %eax
        \\orl $0x3, %eax
        \\movl %eax, 16(%edi)
        \\movl $0, 20(%edi)
        \\movl $pd_all + 0x3000, %eax
        \\orl $0x3, %eax
        \\movl %eax, 24(%edi)
        \\movl $0, 28(%edi)
        \\movl $pd_all, %edi
        \\xorl %ecx, %ecx
        \\2:
        \\movl %ecx, %eax
        \\shll $21, %eax
        \\orl $0x83, %eax
        \\movl %eax, 0(%edi, %ecx, 8)
        \\movl $0, 4(%edi, %ecx, 8)
        \\incl %ecx
        \\cmpl $2048, %ecx
        \\jne 2b
        \\movl $pml4, %eax
        \\movl %eax, %cr3
        \\movl %cr4, %eax
        \\orl $0x20, %eax
        \\movl %eax, %cr4
        \\movl $0xC0000080, %ecx
        \\rdmsr
        \\orl $0x00000100, %eax
        \\wrmsr
        \\movl %cr0, %eax
        \\orl $0x80000001, %eax
        \\movl %eax, %cr0
        \\lgdt gdt64_ptr
        \\ljmpl $0x08, $long_mode_entry
        \\.align 8
        \\gdt64:
        \\.quad 0x0000000000000000
        \\.quad 0x00209A0000000000
        \\.quad 0x0000920000000000
        \\gdt64_end:
        \\gdt64_ptr:
        \\.word gdt64_end - gdt64 - 1
        \\.long gdt64
        \\.code64
        \\long_mode_entry:
        \\movw $0x10, %ax
        \\movw %ax, %ds
        \\movw %ax, %es
        \\movw %ax, %ss
        \\movw %ax, %fs
        \\movw %ax, %gs
        \\movq %cr0, %rax
        \\andq $-5, %rax
        \\orq $0x2, %rax
        \\movq %rax, %cr0
        \\movq %cr4, %rax
        \\orq $0x600, %rax
        \\movq %rax, %cr4
        \\movq $stack_top, %rsp
        \\andq $-16, %rsp
        \\movl %esi, %edi
        \\call _start
        \\3:
        \\cli
        \\hlt
        \\jmp 3b
    );
}
