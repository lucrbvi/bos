const console = @import("console.zig");

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

export fn _start() noreturn {
    main();
    while (true) {}
}

pub fn main() void {
    console.setColors(.White, .Cyan);
    console.clear();
    console.putString("Hello, World");
    console.setForegroundColor(.LightRed);
    console.putString("!");
}
