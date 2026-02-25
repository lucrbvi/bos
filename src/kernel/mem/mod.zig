//! Public kernel memory API

const std = @import("std");
const physical = @import("physical.zig");
const virtual = @import("virtual.zig");

pub fn init(allocator: std.mem.Allocator) void {
    physical.init();
    virtual.init(allocator);
}

fn pagePad(size: usize) usize {
    return (size + physical.page_size - 1) / physical.page_size;
}

pub fn kalloc(pid: u32, size: usize) ![]u8 {
    const n = pagePad(size);
    const slice = physical.allocPages(n) orelse return error.OutOfMemory;
    try virtual.track(pid, slice);
    return slice;
}

pub fn kfreePid(pid: u32) void {
    virtual.freePid(pid);
}
