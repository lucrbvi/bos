const arch = @import("arch/mod.zig");
const Framebuffer = @import("framebuffer.zig").Framebuffer;
const std = @import("std");
const io = arch.io;
const mbi = @import("mbi.zig");
const kutils = @import("kutils.zig");
const builtin = @import("builtin");

comptime {
    _ = arch.boot;
}

const klog = kutils.klog;
const kpanic = kutils.kpanic;
const loop = kutils.loop;

const Allocator = std.mem.Allocator;

var tmode = kutils.IoMode.None;
var ser = io.Serial{};
var ioserinit: bool = true;
var ioser: bool = true;
var fb: ?Framebuffer = null;

export fn _start(mbi_addr: usize) noreturn {
    if (!ser.init()) {
        ioserinit = false;
    }

    if (!ser.canTransmit()) {
        ioser = false;
    }

    if (ioserinit and ioser) {
        klog(&ser, "I/O Serial COM: OK\n", .{});
    }

    if (mbi.findFramebuffer(mbi_addr)) |info| {
        klog(&ser, "k: framebuffer addr=0x{X} pitch={} width={} height={} bpp={}\n", .{ info.addr, info.pitch, info.width, info.height, info.bpp });

        fb = Framebuffer{
            .addr = info.addr,
            .pitch = info.pitch,
            .width = info.width,
            .height = info.height,
            .bpp = info.bpp,
        };
        fb.?.clear(0x1E1E2E);
    } else {
        ser.write("k: no framebuffer found in MBI\n");
    }

    klog(&ser, "Start of main()\n", .{});

    kmain() catch |err| {
        kpanic(&ser, tmode, err, "kmain()");
    };

    klog(&ser, "End of main()\n", .{});

    loop();
}

pub fn kmain() !void {
    _ = ioser;
    _ = ioserinit;

    if (fb) |*f| {
        f.write("This is Basic Operating System. Welcome.\n");
    }
}
