//! PL011 UART driver for aarch64 (QEMU virt machine)

const PL011_BASE: usize = 0x09000000;

// PL011 registers (offsets)
const UARTDR: usize = 0x000; // Data register
const UARTFR: usize = 0x018; // Flag register
const UARTIBRD: usize = 0x024; // Integer baud rate
const UARTFBRD: usize = 0x028; // Fractional baud rate
const UARTLCR_H: usize = 0x02C;
const UARTCR: usize = 0x030; // Control register
const UARTIMSC: usize = 0x038; // Interrupt mask

const FR_TXFF: u32 = 1 << 5; // TX FIFO full
const FR_RXFE: u32 = 1 << 4; // RX FIFO empty

inline fn mmio_write(offset: usize, value: u32) void {
    const ptr: *volatile u32 = @ptrFromInt(PL011_BASE + offset);
    ptr.* = value;
}

inline fn mmio_read(offset: usize) u32 {
    const ptr: *volatile u32 = @ptrFromInt(PL011_BASE + offset);
    return ptr.*;
}

pub const Serial = struct {
    base: u16 = 0, // unused on aarch64

    pub fn init(_: *Serial) bool {
        // Deactivate UART
        mmio_write(UARTCR, 0);

        // IBRD = 13, FBRD = 1
        mmio_write(UARTIBRD, 13);
        mmio_write(UARTFBRD, 1);

        // 8 bits, 1 stop bit, FIFO
        mmio_write(UARTLCR_H, 0x70);

        // Deactive interupts
        mmio_write(UARTIMSC, 0);

        // UART, TX, RX
        mmio_write(UARTCR, 0x301);

        return true;
    }

    pub fn canTransmit(_: *Serial) bool {
        return (mmio_read(UARTFR) & FR_TXFF) == 0;
    }

    pub fn writeByte(self: *Serial, b: u8) void {
        while (!self.canTransmit()) {}
        mmio_write(UARTDR, b);
    }

    pub fn write(self: *Serial, s: []const u8) void {
        for (s) |c| self.writeByte(c);
    }

    pub fn received(_: *Serial) bool {
        return (mmio_read(UARTFR) & FR_RXFE) == 0;
    }

    pub fn read(_: *Serial) u8 {
        while ((mmio_read(UARTFR) & FR_RXFE) != 0) {}
        return @truncate(mmio_read(UARTDR));
    }

    pub fn is_transmit_empty(self: *Serial) bool {
        return self.canTransmit();
    }
};
