const std = @import("std");

const KernelArch = enum {
    x86,
    x86_64,
};

pub fn build(b: *std.Build) !void {
    const optimize = b.option(
        std.builtin.OptimizeMode,
        "optimize",
        "Optimize mode",
    ) orelse .Debug;

    const kernel_arch = b.option(
        KernelArch,
        "arch",
        "Kernel architecture target (x86, x86_64, or aarch64)",
    ) orelse .x86;

    const grub_modules_dir = b.option(
        []const u8,
        "grub-modules-dir",
        "Path to GRUB platform modules directory (required for bootable aarch64 ISO)",
    );

    const target = switch (kernel_arch) {
        .x86 => b.resolveTargetQuery(.{
            .cpu_arch = .x86,
            .os_tag = .freestanding,
            .abi = .none,
            .cpu_model = .{ .explicit = &std.Target.x86.cpu.i386 },
        }),
        .x86_64 => b.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .freestanding,
            .abi = .none,
            // .cpu_model = .{ .explicit = &std.Target.x86_64.cpu.x86_64 },
        }),
        // else => @compileError("Unsupported architecture"),
    };

    const kernel_name = switch (kernel_arch) {
        .x86 => "kernel-x86.elf",
        .x86_64 => "kernel-x86_64.elf",
    };

    const iso_name = switch (kernel_arch) {
        .x86 => "kernel-x86.iso",
        .x86_64 => "kernel-x86_64.iso",
    };

    const linker_script = switch (kernel_arch) {
        .x86 => "src/kernel/arch/x86/linker.ld",
        .x86_64 => "src/kernel/arch/x86/linker.ld",
    };

    const kernel = b.addExecutable(.{
        .name = kernel_name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel/kmain.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    kernel.setLinkerScript(b.path(linker_script));
    kernel.entry = .{ .symbol_name = "_boot" };

    b.installArtifact(kernel);

    const grub_cfg_template = switch (kernel_arch) {
        .x86 => "iso_dir/boot/grub/grub-x86.cfg",
        .x86_64 => "iso_dir/boot/grub/grub-x86_64.cfg",
    };

    const copy_grub_cfg = b.addSystemCommand(&[_][]const u8{
        "cp", grub_cfg_template, "iso_dir/boot/grub/grub.cfg",
    });

    const stage_kernel = switch (kernel_arch) {
        .x86 => b.addSystemCommand(&[_][]const u8{
            "cp", "zig-out/bin/kernel-x86.elf", "iso_dir/boot/kernel.elf",
        }),
        .x86_64 => b.addSystemCommand(&[_][]const u8{
            "cp", "zig-out/bin/kernel-x86_64.elf", "iso_dir/boot/kernel.elf",
        }),
    };
    stage_kernel.step.dependOn(&kernel.step);

    const make_iso = blk: {
        if (grub_modules_dir) |modules_dir| {
            break :blk b.addSystemCommand(&[_][]const u8{
                "grub-mkrescue", "--directory", modules_dir, "-o", iso_name, "iso_dir",
            });
        }

        break :blk b.addSystemCommand(&[_][]const u8{
            "grub-mkrescue", "-o", iso_name, "iso_dir",
        });
    };
    make_iso.step.dependOn(&copy_grub_cfg.step);
    make_iso.step.dependOn(&stage_kernel.step);

    b.getInstallStep().dependOn(&make_iso.step);
}
