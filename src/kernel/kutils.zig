//! Kernel Utilities

const std = @import("std");
const arch = @import("arch/mod.zig");
const io = arch.io;

const Framebuffer = @import("framebuffer.zig").Framebuffer;

var serial_ctx: ?*io.Serial = null;
var framebuffer_ctx: ?*Framebuffer = null;
var io_mode_ctx: IoMode = .None;

pub const IoMode = enum(u4) {
    None = 0,
    Framebuffer = 1,
};

pub fn loop() noreturn {
    while (true) {}
}

pub fn setSerial(ser: *io.Serial) void {
    serial_ctx = ser;
}

pub fn setFramebuffer(fb: *Framebuffer) void {
    framebuffer_ctx = fb;
}

pub fn setIoMode(mode: IoMode) void {
    io_mode_ctx = mode;
}

pub fn kpanic(err: anyerror, comptime src: []const u8) noreturn {
    switch (io_mode_ctx) {
        IoMode.Framebuffer => {
            if (framebuffer_ctx) |fb| {
                fb.clear(0x000000);
                fb.printf("Kernel panic in {s}: {}\n", .{ src, err });
            }
        },
        else => {},
    }
    klog("Kernel panic in {s}: {}\n", .{ src, err });
    loop();
}

// FIXME: Does not work on aarch64 due to `std.fmt.bufPrint`
pub fn klog(comptime msg: []const u8, args: anytype) void {
    const ser = serial_ctx orelse return;

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
