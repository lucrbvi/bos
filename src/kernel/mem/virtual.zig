//! Track allocated memory slices per PID

const std = @import("std");
const kutils = @import("../kutils.zig");
const physical = @import("physical.zig");

const Region = std.ArrayList([]u8);
var map: std.AutoHashMap(u32, Region) = undefined;
var gpa: std.mem.Allocator = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    gpa = allocator;
    map = .init(allocator);
    kutils.klog("mem.virtual.init(0): OK\n", .{});
}

pub fn track(pid: u32, slice: []u8) !void {
    const result = try map.getOrPut(pid);
    if (!result.found_existing) {
        result.value_ptr.* = .empty;
    }
    try result.value_ptr.*.append(gpa, slice);
}

pub fn freePid(pid: u32) void {
    if (map.fetchRemove(pid)) |entry| {
        var region = entry.value;
        for (region.items) |slice| {
            physical.freePages(slice);
        }
        region.deinit(gpa);
    }
}
