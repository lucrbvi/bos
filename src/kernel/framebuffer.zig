//! Framebuffer text console
//!
//! Designed to be cross-platform

pub const glyphs: [256][16]u8 = @import("font8x16_data.zig").data;

pub const Framebuffer = struct {
    addr: u64,
    pitch: u32,
    width: u32,
    height: u32,
    bpp: u8,

    cursor_x: u32 = 0,
    cursor_y: u32 = 0,

    const CHAR_W = 8;
    const CHAR_H = 16;

    pub fn putPixel(self: *Framebuffer, x: u32, y: u32, color: u32) void {
        if (x >= self.width or y >= self.height) return;
        const bytes_per_pixel = self.bpp / 8;
        const offset = y * self.pitch + x * bytes_per_pixel;
        const ptr: *volatile u32 = @ptrFromInt(
            @as(usize, @intCast(self.addr)) + offset,
        );
        ptr.* = color;
    }

    pub fn clear(self: *Framebuffer, color: u32) void {
        var y: u32 = 0;
        while (y < self.height) : (y += 1) {
            var x: u32 = 0;
            while (x < self.width) : (x += 1) {
                self.putPixel(x, y, color);
            }
        }
    }

    pub fn drawChar(
        self: *Framebuffer,
        ch: u8,
        col: u32,
        row: u32,
        fg: u32,
        bg: u32,
    ) void {
        const glyph = glyphs[ch];
        var gy: u32 = 0;
        while (gy < CHAR_H) : (gy += 1) {
            const line = glyph[gy];
            var gx: u32 = 0;
            while (gx < CHAR_W) : (gx += 1) {
                const bit = (line >> @intCast(7 - gx)) & 1;
                const color = if (bit != 0) fg else bg;
                self.putPixel(col * CHAR_W + gx, row * CHAR_H + gy, color);
            }
        }
    }

    pub fn putChar(self: *Framebuffer, ch: u8) void {
        const cols = self.width / CHAR_W;
        const rows = self.height / CHAR_H;

        if (ch == '\n') {
            self.cursor_x = 0;
            self.cursor_y += 1;
        } else {
            self.drawChar(ch, self.cursor_x, self.cursor_y, 0xFFFFFF, 0x000000);
            self.cursor_x += 1;
            if (self.cursor_x >= cols) {
                self.cursor_x = 0;
                self.cursor_y += 1;
            }
        }

        // TODO: add true scroll - need to listen to keyboard
        if (self.cursor_y >= rows) {
            self.cursor_y = 0;
            self.cursor_x = 0;
        }
    }

    pub fn write(self: *Framebuffer, s: []const u8) void {
        for (s) |c| self.putChar(c);
    }
};
