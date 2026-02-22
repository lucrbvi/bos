
const VGA_BUFFER: *volatile [80 * 25]u16 = @ptrFromInt(0xB8000);

const VGAColor = enum(u4) {
    Black = 0,
    White = 15,
};

fn vgaEntry(char: u8, color: VGAColor) u16 {
    return @as(u16, char) | (@as(u16, @intFromEnum(color)) << 8);
}

fn print(str: []const u8) void {
    for (str, 0..) |char, i| {
        VGA_BUFFER[i] = vgaEntry(char, .White);
    }
}

export fn _start() noreturn {
    print("Hello BOS");

    while (true) {
        asm volatile ("hlt");
    }
}
