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
3. Run the kernel in QEMU with `qemu-system-i386 -cdrom kernel.iso -m 20M`
4. Enjoy!
5. (I recommend running `zig build -Doptimize=ReleaseFast && qemu-system-i386 -cdrom kernel.iso -m 20M` when doing small changes/tweaking)

## How to Debug It

1. Build with `zig build` for debug
2. Run `qemu-system-i386 -cdrom kernel.iso -m 20M -s -S`
3. In parallel, run `gdb zig-out/bin/kernel.elf`
4. You should enter `target remote localhost:1234`
5. Then you can debug!
