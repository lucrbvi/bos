## Basic Operating System

*This is not a serious project, just a hobby one to learn some basic operating system concepts.*

The kernel can boot with GNU GRUB on x86 and x86_64 systems.

### Why does this project exists ?
1. I like Zig
2. I like to learn hard things
3. Kernels are cool

## How to Build It

1. Check if you have Zig (0.15+), GNU GRUB utilities, and QEMU installed.
2. Run `zig build -Doptimize=ReleaseFast`.
3. Run the kernel in QEMU with `qemu-system-i386 -cdrom kernel-x86.iso -m 20M -serial stdio`
4. Enjoy!

## How to Debug It

1. Build the kernel.
2. Run `qemu-system-i386 -cdrom kernel.iso -m 20M -serial stdio -s -S`
3. In parallel, run `gdb zig-out/bin/kernel-x86.elf`
4. You should enter `target remote localhost:1234`
5. Then you can debug!

### Tips for Development

1. Read `RESSOURCES.md`
2. Run `zig build -Doptimize=ReleaseFast -Darch=x86_64 && qemu-system-x86_64 -cdrom kernel-x86_64.iso -m 40M -serial stdio` to test on x86_64.
3. Run `zig build -Doptimize=ReleaseFast && qemu-system-i386 -cdrom kernel-x86.iso -m 40M -serial stdio` to test on x86.
