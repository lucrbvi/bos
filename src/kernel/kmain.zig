const arch = @import("arch/mod.zig");
const io = arch.io;
const mbi = @import("mbi.zig");
const kutils = @import("kutils.zig");
const mem = @import("mem/mod.zig");
const std = @import("std");

comptime {
    _ = arch.boot;
}

const klog = kutils.klog;
const kpanic = kutils.kpanic;
const loop = kutils.loop;

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
        f.printf("This is Basic Operating System version 0.0.1; Welcome.\n\n", .{});
        mem.kfreePid(0);
        f.printf("{} - {} = {}\n", .{ data[0], data[9], data[0] - data[9] });
    }
}
