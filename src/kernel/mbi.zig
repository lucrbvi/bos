//! Parser Multiboot2 Boot Information, partagé x86 + aarch64

pub const FramebufferInfo = struct {
    addr: u64,
    pitch: u32,
    width: u32,
    height: u32,
    bpp: u8,
};

const MBI_TAG_FRAMEBUFFER: u32 = 8;

pub fn findFramebuffer(mbi_addr: usize) ?FramebufferInfo {
    if (mbi_addr == 0) return null;
    var ptr: usize = mbi_addr + 8;

    while (true) {
        const tag_type = @as(*volatile u32, @ptrFromInt(ptr)).*;
        const tag_size = @as(*volatile u32, @ptrFromInt(ptr + 4)).*;

        if (tag_type == 0) break;

        if (tag_type == MBI_TAG_FRAMEBUFFER) {
            return FramebufferInfo{
                .addr = @as(*volatile u64, @ptrFromInt(ptr + 8)).*,
                .pitch = @as(*volatile u32, @ptrFromInt(ptr + 16)).*,
                .width = @as(*volatile u32, @ptrFromInt(ptr + 20)).*,
                .height = @as(*volatile u32, @ptrFromInt(ptr + 24)).*,
                .bpp = @as(*volatile u8, @ptrFromInt(ptr + 28)).*,
            };
        }

        ptr += (tag_size + 7) & ~@as(usize, 7);
    }

    return null;
}
