const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    kernel.setLinkerScript(b.path("src/kernel/linker.ld"));
    kernel.entry = .{ .symbol_name = "_start" };

    b.installArtifact(kernel);

    const copy_kernel = b.addSystemCommand(&[_][]const u8{
        "cp", "zig-out/bin/kernel.elf", "iso_dir/boot/kernel.elf",
    });
    copy_kernel.step.dependOn(&kernel.step);

    const make_iso = b.addSystemCommand(&[_][]const u8{
        "grub-mkrescue", "-o", "kernel.iso", "iso_dir",
    });
    make_iso.step.dependOn(&copy_kernel.step);

    b.getInstallStep().dependOn(&make_iso.step);
}
