//! Public kernel memory API

const std = @import("std");
const physical = @import("physical.zig");
const virtual = @import("virtual.zig");
const kutils = @import("../kutils.zig");

pub fn init(allocator: std.mem.Allocator) void {
    virtual.init(allocator);
    kutils.klog("mem.init(0): OK\n", .{});
}

fn pagePad(size: usize) usize {
    return (size + physical.page_size - 1) / physical.page_size;
}

/// Allocate memory
pub fn kalloc(pid: u32, size: usize) ![]u8 {
    const n = pagePad(size);
    const slice = physical.allocPages(n) orelse return error.OutOfMemory;
    try virtual.track(pid, slice);
    return slice;
}

/// Free a small amount of memory
pub fn kfree(slice: []u8) void {
    physical.freePages(slice);
}

/// Free all the memory allocated by a process
pub fn kfreePid(pid: u32) void {
    virtual.freePid(pid);
}
