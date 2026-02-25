// Copyright Luc ROBERT--VILLANUEVA 2026
// Distributed under the Boost Software License, Version 1.0
// (See accompanying file LICENSE or copy at https://www.boost.org/LICENSE_1_0.txt)

const arch = @import("arch/mod.zig");
const mbi = @import("mbi.zig");
const kutils = @import("kutils.zig");
const mem = @import("mem/mod.zig");
const std = @import("std");
const builtin = @import("builtin");

comptime {
    _ = arch.boot;
}

const klog = kutils.klog;
const kpanic = kutils.kpanic;
const loop = kutils.loop;
const io = arch.io;

const Framebuffer = @import("framebuffer.zig").Framebuffer;

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

    kutils.setSerial(&ser);

    if (ioserinit and ioser) {
        klog("I/O Serial COM: OK\n", .{});
    } else {
        klog("I/O Serial COM: FAIL\n", .{});
    }

    _ = ioser;
    _ = ioserinit;

    if (mbi.findFramebuffer(mbi_addr)) |info| {
        klog("framebuffer addr=0x{X} pitch={} width={} height={} bpp={}\n", .{ info.addr, info.pitch, info.width, info.height, info.bpp });

        fb = Framebuffer{
            .addr = info.addr,
            .pitch = info.pitch,
            .width = info.width,
            .height = info.height,
            .bpp = info.bpp,
        };
        fb.?.clear(0x000000);
        kutils.setFramebuffer(&fb.?);
        kutils.setIoMode(.Framebuffer);
    } else {
        ser.write("k: no framebuffer found in MBI\n");
    }

    klog("Start of kmain(0)\n", .{});

    kmain() catch |err| {
        kpanic(err, "kmain(0)");
    };

    klog("End of kmain(0)\n", .{});

    loop();
}

pub fn kmain() !void {
    var buffer: [1024 * 100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    mem.init(allocator);

    var data = try mem.kalloc(0, 10);
    data[0] = 70;
    data[9] = 69;

    if (fb) |*f| {
        f.printf("This is Basic Operating System version 0.0.1 on {s}; Welcome.\n\n", .{@tagName(builtin.cpu.arch)});
        mem.kfree(data[0..8]);
        // use after free - show the data poisonning when free
        f.printf("{} - {} = {}\n", .{ data[0], data[9], data[0] - data[9] });
    }
}
