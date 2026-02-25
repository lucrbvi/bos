// Copyright Luc ROBERT--VILLANUEVA 2026
// Distributed under the Boost Software License, Version 1.0
// (See accompanying file LICENSE or copy at https://www.boost.org/LICENSE_1_0.txt)

pub inline fn outb(port: u16, value: u8) void {
    asm volatile (
        \\outb %[v], %[p]
        :
        : [v] "{al}" (value),
          [p] "{dx}" (port),
    );
}

pub inline fn inb(port: u16) u8 {
    var value: u8 = 0;
    asm volatile (
        \\inb %[p], %[v]
        : [v] "={al}" (value),
        : [p] "{dx}" (port),
    );
    return value;
}

pub const Serial = struct {
    base: u16 = 0x3F8,

    pub fn init(self: *Serial) bool {
        outb(self.base + 1, 0x00);
        outb(self.base + 3, 0x80);
        outb(self.base + 0, 0x03);
        outb(self.base + 1, 0x00);
        outb(self.base + 3, 0x03);
        outb(self.base + 2, 0xC7);
        outb(self.base + 4, 0x0B);
        outb(self.base + 4, 0x1E);
        outb(self.base + 0, 0xAE);

        if (inb(self.base + 0) != 0xAE) {
            return false;
        }

        outb(self.base + 4, 0x0F);
        return true;
    }

    pub fn canTransmit(self: *Serial) bool {
        return (inb(self.base + 5) & 0x20) != 0;
    }

    pub fn writeByte(self: *Serial, b: u8) void {
        while (!self.canTransmit()) {}
        outb(self.base + 0, b);
    }

    pub fn write(self: *Serial, s: []const u8) void {
        for (s) |c| self.writeByte(c);
    }

    pub fn received(self: *Serial) bool {
        return inb(self.base + 5) & 1;
    }

    pub fn read(self: *Serial) u8 {
        while (self.received()) {}
        return inb(self.base);
    }

    pub fn is_transmit_empty(self: *Serial) bool {
        return inb(self.base + 5) & 0x20;
    }
};
