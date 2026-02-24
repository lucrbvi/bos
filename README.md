## Basic Operating System

*This is not a serious project, just a hobby one to learn some basic operating system concepts.*

The kernel can boot with GNU GRUB on x86 systems (aarch64 soon).

### Why does this project exists ?
1. I like Zig
2. I like to learn hard things
3. Kernels are cool

## How to Build It

1. Check if you have Zig (0.15+), GNU GRUB utilities, and QEMU installed.
2. Run `zig build -Doptimize=ReleaseFast`.
3. Run the kernel in QEMU with `qemu-system-i386 -cdrom kernel.iso -m 20M -serial stdio`
4. Enjoy!
5. (I recommend running `zig build -Doptimize=ReleaseFast && qemu-system-i386 -cdrom kernel-x86.iso -m 20M -serial stdio` when doing small changes/tweaking)
6. (I recommend using `zig build -Darch=aarch64 -Doptimize=ReleaseFast && qemu-system-aarch64 -M virt -cpu cortex-a57 -m 128M -display none -serial stdio -kernel zig-out/bin/kernel-aarch64.elf` to debug aarch64)

## How to Debug It

1. Build the kernel.
2. Run `qemu-system-i386 -cdrom kernel.iso -m 20M -serial stdio -s -S`
3. In parallel, run `gdb zig-out/bin/kernel-x86.elf`
4. You should enter `target remote localhost:1234`
5. Then you can debug!

## How to Develop It

1. Read `RESSOURCES.md`
