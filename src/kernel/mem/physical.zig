//! Manage the physical memory (pages)

const std = @import("std");
const kutils = @import("../kutils.zig");

pub const page_size: usize = 4096;
const membuf_size: usize = 1024 * 1024;
const page_count: usize = membuf_size / page_size;

var membuf: [membuf_size]u8 align(page_size) = undefined;
var bitmap = std.bit_set.StaticBitSet(page_count).initEmpty();

pub fn init() void {
    kutils.klog("mem.physical.init(0): OK\n", .{});
}

/// Contiguous memory allocator by pages
pub fn allocPages(n: usize) ?[]u8 {
    var start: usize = 0;
    while (start + n <= page_count) {
        var found = true;
        for (start..start + n) |i| {
            if (bitmap.isSet(i)) {
                start = i + 1;
                found = false;
                break;
            }
        }
        if (found) {
            for (start..start + n) |i| bitmap.set(i);
            const offset = start * page_size;
            return membuf[offset .. offset + n * page_size];
        }
    }
    return null;
}

/// Poison the slice and mark it as free
pub fn freePages(slice: []u8) void {
    @memset(slice, 0xCA);
    const offset = @intFromPtr(slice.ptr) - @intFromPtr(&membuf);
    const start = offset / page_size;
    const n = slice.len / page_size;
    for (start..start + n) |i| bitmap.unset(i);
}
