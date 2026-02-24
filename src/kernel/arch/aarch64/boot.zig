// Linux ARM64 Image Header - https://docs.kernel.org/arch/arm64/booting.html
const Arm64ImageHeader = extern struct {
    code0: u32, // Executable code
    code1: u32, // Executable code
    text_offset: u64, // Image load offset, little endian
    image_size: u64, // Effective Image size, little endian
    flags: u64, // kernel flags, little endian
    res2: u64 = 0, // reserved
    res3: u64 = 0, // reserved
    res4: u64 = 0, // reserved
    magic: u32, // Magic number, little endian, "ARM\x64"
    res5: u32 = 0, // reserved (used for PE COFF offset)
};

const ARM64_IMAGE_MAGIC: u32 = 0x644d5241;

export var multiboot align(8) linksection(".multiboot") = Arm64ImageHeader{
    .code0 = 0x91000000, // MZ magic (add x0, x0, #0 - encode "MZ")
    .code1 = 0xD503201F, // NOOP
    .text_offset = 0x80000,
    .image_size = 0,
    .flags = 0b1010, // LE, 4K pages
    .magic = ARM64_IMAGE_MAGIC,
};

export fn _boot() callconv(.naked) noreturn {
    asm volatile (
    // --- EL detection ---
        \\mrs  x1, CurrentEL
        \\and  x1, x1, #0xC

        // EL3 ?
        \\cmp  x1, #0xC
        \\b.ne 10f
        \\mrs  x2, cptr_el3
        \\bic  x2, x2, #(1 << 10)
        \\msr  cptr_el3, x2
        \\isb

        // EL2 ?
        \\10:
        \\cmp  x1, #0x8
        \\b.ne 20f
        \\mrs  x2, cptr_el2
        \\bic  x2, x2, #(1 << 10)
        \\msr  cptr_el2, x2
        \\isb

        // EL1 toujours
        \\20:
        \\mrs  x2, cpacr_el1
        \\orr  x2, x2, #(3 << 20)
        \\msr  cpacr_el1, x2
        \\isb

        // Stack + jump
        \\adrp x0, stack_top
        \\add  x0, x0, :lo12:stack_top
        \\mov  sp, x0
        \\bl   _start

        // Halt loop
        \\99:
        \\wfi
        \\b 99b
    );
}
