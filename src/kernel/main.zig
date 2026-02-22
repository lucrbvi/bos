const console = @import("vga_console.zig");
const std = @import("std");

const Allocator = std.mem.Allocator;

const MultibootHeader = extern struct {
    magic: u32,
    flags: u32,
    checksum: u32,
};

const MB1_MAGIC: u32 = 0x1BADB002;
const FLAGS: u32 = 0x00000000;

export var multiboot align(4) linksection(".multiboot") = MultibootHeader{
    .magic = MB1_MAGIC,
    .flags = FLAGS,
    .checksum = @truncate((-%@as(u32, MB1_MAGIC) -% FLAGS)),
};

const IoMode = enum(u4) {
    None = 0,
    VGA = 1,
};

fn loop() noreturn {
    while(true) {}
}

var err_buffer: [1000]u8 = undefined;
var err_fba = std.heap.FixedBufferAllocator.init(&err_buffer);

var tmode = IoMode.None;

export fn _start() noreturn {
    tmode = IoMode.VGA;

    main() catch |err| {
        kpanic(err, "main()");
    };
    loop();
}

pub fn kpanic(err: anyerror, comptime src: []const u8) void { 
    const alloc = err_fba.allocator();

    return switch(tmode) {
        IoMode.VGA => {
            console.setForegroundColor(.Black);
            console.printf(alloc, "Kernel panic: {} from {s}", .{err, src}) catch {};
            loop();
        },
        else => loop(),
    };
}

pub fn main() !void {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = fba.allocator();

    console.setColors(.White, .Cyan);
    console.clear();
    try console.printf(alloc, "Hello, {s}", .{"World"});
    console.setForegroundColor(.LightRed);
    console.putChar('!');
}
