//! Kernel Utilities

const std = @import("std");
const arch = @import("arch/mod.zig");
const console = @import("vga_console.zig");
const io = arch.io;

pub const IoMode = enum(u4) {
    None = 0,
    VGA = 1,
};

pub fn loop() noreturn {
    while (true) {}
}

pub fn kpanic(ser: *io.Serial, mode: IoMode, err: anyerror, comptime src: []const u8) noreturn {
    switch (mode) {
        IoMode.VGA => {
            console.setColors(.White, .Cyan);
            console.clear();
            console.setLocation(0, 0);
            console.setForegroundColor(.Black);
            console.printf("Kernel panic in {s}: {}", .{ src, err });
            klog(ser, "Kernel panic in {s}: {}\n", .{ src, err });
        },
        else => {
            klog(ser, "Kernel panic in {s}: {}\n", .{ src, err });
        },
    }
    loop();
}

// FIXME: Does not work on aarch64 due to `std.fmt.bufPrint`
pub fn klog(ser: *io.Serial, comptime msg: []const u8, args: anytype) void {
    var buf: [500]u8 = undefined;
    const written = std.fmt.bufPrint(&buf, msg, args) catch {
        ser.write("[klog fmt error]\n");
        return;
    };
    ser.write("k: ");
    ser.write(written);
}
