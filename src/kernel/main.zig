const arch = @import("arch/mod.zig");
const console = @import("vga_console.zig");
const std = @import("std");
const io = arch.io;
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

export fn _start() noreturn {
    if (!ser.init()) {
        ioserinit = false;
    }

    if (!ser.canTransmit()) {
        ioser = false;
    }

    if (ioserinit and ioser) {
        klog(&ser, "I/O Serial COM: OK\n", .{});
    }

    klog(&ser, "Start of main()\n", .{});

    kmain() catch |err| {
        kpanic(&ser, tmode, err, "kmain()");
    };

    klog(&ser, "End of main()\n", .{});

    loop();
}

pub fn kmain() !void {
    if (builtin.cpu.arch == .x86) {
        tmode = kutils.IoMode.VGA;

        console.setColors(.White, .Cyan);
        console.clear();

        if (!ioserinit) {
            console.setForegroundColor(.Black);
            console.printf("I/O Serial init: ERROR\n", .{});
        }

        if (!ioser) {
            console.setForegroundColor(.Black);
            console.printf("I/O Serial COM: ERROR\n", .{});
        }

        console.setForegroundColor(.White);
        console.printf("This is Basic Operating System. {s}.\n\n", .{"Welcome"});
    }

    _ = ioser;
    _ = ioserinit;

    klog(&ser, "This is Basic Operating System. {s}.\n", .{"Welcome"});
}
