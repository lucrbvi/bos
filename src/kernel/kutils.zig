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
        else => {
            if (serial_ctx) |ser| {
                ser.write("Kernel panic in ");
                ser.write(src);
                ser.write(": ");
                ser.write(@errorName(err));
                ser.write("\n");
            }
        },
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

const Range = struct {
    start: usize,
    end: usize,
};

const KMemChief = struct {
    arena: std.heap.ArenaAllocator,
    map: std.AutoHashMap(u32, Range),

    pub fn init(self: *KMemChief, backing: std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(backing);
        self.map = std.AutoHashMap(u32, Range).init(self.arena.allocator());
    }

    pub fn deinit(self: *KMemChief) void {
        self.map.deinit();
        self.arena.deinit();
    }

    pub fn add(self: *KMemChief, pid: u32, range: Range) void {
        self.map.put(pid, range) catch |err| {
            klog("kmemchief.add(3) failed: {s}\n", .{@errorName(err)});
        };
    }

    pub fn bytesUntilKernelOom(_: *const KMemChief) usize {
        return kheap.len - kheap_offset;
    }
};

pub var kmemchief: ?KMemChief = null;
var kmemchief_buf: [64 * 1024]u8 = undefined;
var kmemchief_fba = std.heap.FixedBufferAllocator.init(&kmemchief_buf);

pub fn kmemchiefInit() void {
    kmemchief = .{
        .arena = undefined,
        .map = undefined,
    };
    if (kmemchief) |*kc| {
        kc.init(kmemchief_fba.allocator());
    }
}

/// Allocate memory
pub fn kalloc(size: usize) []u8 {
    const alignment: usize = 16;
    const aligned_size = std.mem.alignForward(usize, size, alignment);

    const next = std.math.add(usize, kheap_offset, aligned_size) catch {
        kpanic(error.OutOfMemory, "kalloc");
    };

    if (next > kheap.len) {
        kpanic(error.OutOfMemory, "kalloc");
    }

    const start = kheap_offset;
    kheap_offset = next;
    const out = kheap[start .. start + size];
    const begin_addr = @intFromPtr(out.ptr);

    const end_addr_excl = std.math.add(usize, begin_addr, size) catch {
        kpanic(error.OutOfMemory, "kalloc addr overflow");
    };

    if (kmemchief) |*kc| {
        kc.add(0, .{ .start = begin_addr, .end = end_addr_excl });
    }
    return out;
}

const kheap_size = 1024 * 1024;
var kheap: [kheap_size]u8 align(16) = undefined;
var kheap_offset: usize = 0;
