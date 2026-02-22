// GRUB multiboot
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

// Booting
export fn _boot() callconv(.naked) noreturn {
    asm volatile (
        \\movl $stack_top, %esp
        \\andl $-16, %esp
        \\subl $12, %esp
        \\call _start
        \\hlt
    );
    unreachable;
}

// True fun
const console = @import("vga_console.zig");
const std = @import("std");

const Allocator = std.mem.Allocator;

const IoMode = enum(u4) {
    None = 0,
    VGA = 1,
};

fn loop() noreturn {
    while (true) {}
}

var tmode = IoMode.None;

export fn _start() noreturn {
    tmode = IoMode.VGA;

    main() catch |err| {
        kpanic(err, "main()");
    };
    loop();
}

pub fn main() !void {
    console.setColors(.White, .Cyan);
    console.clear();
    console.printf("Hello, {s}!\n\n", .{"World"});
    console.printf("This is Basic Operating System. Welcome.\n", .{});
}

pub fn kpanic(err: anyerror, comptime src: []const u8) noreturn {
    switch (tmode) {
        IoMode.VGA => {
            console.setColors(.White, .Cyan);
            console.clear();
            console.setLocation(0, 0);
            console.setForegroundColor(.Black);
            console.printf("Kernel panic in {s}: {}", .{ src, err });
        },
        else => {},
    }
    loop();
}
