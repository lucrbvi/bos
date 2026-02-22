const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel/main.zig"),
            .target = target,
            .optimize = .Debug,
        }),
    });

    kernel.setLinkerScript(b.path("linker.ld"));
    kernel.entry = .{ .symbol_name = "_start" };

    b.installArtifact(kernel);
}
