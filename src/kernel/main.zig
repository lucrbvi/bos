// GRUB multiboot
const MultibootHeader = extern struct {
    magic: u32,
    arch: u32,
    header_length: u32,
    checksum: u32,
};

const MultibootTagEnd = extern struct {
    type: u32,
    flags: u32,
    size: u32,
};

const MultibootFull = extern struct {
    header: MultibootHeader,
    end_tag: MultibootTagEnd,
};

const MB2_MAGIC: u32 = 0xe85250d6;
const MB2_ARCH_X86: u32 = 0;
const MB2_HEADER_LENGTH: u32 = 16 + 8; // header + end tag

export var multiboot align(8) linksection(".multiboot") =
    MultibootFull{
        .header = .{
            .magic = MB2_MAGIC,
            .arch = MB2_ARCH_X86,
            .header_length = MB2_HEADER_LENGTH,
            .checksum = -%(MB2_MAGIC +% MB2_ARCH_X86 +% MB2_HEADER_LENGTH),
        },
        .end_tag = .{
            .type = 0,
            .flags = 0,
            .size = 8,
        },
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
    // unreachable;
}

// True fun
const console = @import("vga_console.zig");
const std = @import("std");
const io = @import("io.zig");

const Allocator = std.mem.Allocator;

const IoMode = enum(u4) {
    None = 0,
    VGA = 1,
};

fn loop() noreturn {
    while (true) {}
}

var tmode = IoMode.None;
var ser = io.Serial{};
var ioserinit: bool = true;
var ioser: bool = true;

export fn _start() noreturn {
    tmode = IoMode.VGA;

    if (!ser.init()) {
        ioserinit = false;
    }

    if (!ser.canTransmit()) {
        ioser = false;
    }

    klog("I/O Serial COM: OK", .{});

    main() catch |err| {
        kpanic(err, "main()");
    };
    loop();
}

pub fn main() !void {
    klog("Start of main()", .{});

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

    klog("End of main()", .{});
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

/// Log to Serial COM Port for another machine (or VM like QEMU)
pub fn klog(comptime msg: []const u8, args: anytype) void {
    var buf: [512]u8 = undefined;
    var buf2: [512]u8 = undefined;

    var w = std.Io.Writer.fixed(&buf);
    w.print(msg, args) catch {};
    const written = w.buffered();

    var z = std.Io.Writer.fixed(&buf2);
    z.print("k: {s}\n", .{written}) catch {};
    const zritten = z.buffered();

    ser.write(zritten);
}
