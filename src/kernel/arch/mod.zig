//! Architecture-specific modules

const builtin = @import("builtin");
const std = @import("std");

pub const boot = switch (builtin.cpu.arch) {
    .x86 => @import("x86/boot.zig"),
    .aarch64 => @import("aarch64/boot.zig"),
    else => @compileError(std.fmt.comptimePrint("Unsupported architecture. Add src/kernel/arch/{}/boot.zig support.", .{builtin.cpu.arch})),
};

pub const io = switch (builtin.cpu.arch) {
    .x86 => @import("x86/io.zig"),
    .aarch64 => @import("aarch64/io.zig"),
    else => @compileError(std.fmt.comptimePrint("Unsupported architecture. Add src/kernel/arch/{}/io.zig support.", .{builtin.cpu.arch})),
};
