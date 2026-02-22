## Basic Operating System

*This is not a serious project, just a hobby one to learn some basic operating system concepts.*

### Why does this project exists ?
1. I like Zig
2. I like to learn hard things
3. Kernels are cool

The kernel can boot with GNU GRUB on x86 systems.

## How to Build It

1. Check if you have Zig (0.15+), GRUB, and QEMU installed.
2. Run `zig build -Doptimize=ReleaseFast`.
3. Run the kernel in QEMU with `qemu-system-x86_64 -cdrom kernel.iso -m 20M`
4. Enjoy!
