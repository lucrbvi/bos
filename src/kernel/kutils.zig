//! Kernel Utilities

const std = @import("std");
const arch = @import("arch/mod.zig");
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
        else => {
            klog(ser, "Kernel panic in {s}: {}\n", .{ src, err });
        },
    }
    loop();
}

// FIXME: Does not work on aarch64 due to `std.fmt.bufPrint`
pub fn klog(ser: *io.Serial, comptime msg: []const u8, args: anytype) void {
    if (@import("builtin").cpu.arch == .aarch64) {
        ser.write("k: ");
        ser.write(msg);
        return;
    }

    var buf: [500]u8 = undefined;
    const written = std.fmt.bufPrint(&buf, msg, args) catch {
        ser.write("[klog fmt error]\n");
        return;
    };
    ser.write("k: ");
    ser.write(written);
}
