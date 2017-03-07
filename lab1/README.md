# Report for lab1, Houmin Wei
---

## Environment Configuration

```
Hardware Environment:
Memory:         8GB
Processor:      Intel® Core™ i5-3230M CPU @ 2.60GHz × 4
Graphics:       Intel® Ivybridge Mobile
OS Type:        64 bit
Disk:           750GB

Software Environment:
OS:             Ubuntu 16.04 LTS(x86_64)
Gcc:            Gcc 5.4.0
Make:           GNU Make 4.1
Gdb:            GNU gdb 7.11.1

```

### Test Compiler Toolchain
```shell
$ objdump -i   # the 5th line say elf32-i386
$ gcc -m32 -print-libgcc-file-name
/usr/lib/gcc/x86_64-linux-gnu/5/32/libgcc.a
```

### QEMU Emulator
```shell
 # Clone the IAP 6.828 QEMU git repository
 $ git clone https://github.com/geofft/qemu.git -b 6.828-1.7.0
 $ cd qemu
 $ ./configure --disable-kvm --target-list="i386-softmmu x86_64-softmmu"
 $ make
 $ sudo make install
```

## PC Bootstrap

### Simulating the x86
```shell
houmin@cosmos:~/lab$ make
+ as kern/entry.S
+ cc kern/entrypgdir.c
+ cc kern/init.c
+ cc kern/console.c
+ cc kern/monitor.c
+ cc kern/printf.c
+ cc kern/kdebug.c
+ cc lib/printfmt.c
+ cc lib/readline.c
+ cc lib/string.c
+ ld obj/kern/kernel
+ as boot/boot.S
+ cc -Os boot/main.c
+ ld boot/boot
boot block is 390 bytes (max 510)
+ mk obj/kern/kernel.img
```
After compiling, we now have our boot loader(obj/boot/boot) and out kernel(obj/kern/kernel), So where is the disk?
Actually the `kernel.img` is the disk image, which is acting as the virtual disk here. From kern/Makefrag we can see that
both our boot loader and kernel have been written to the image(using the `dd` command).

Now we can running the QEMU like running a real PC.
```shell
houmin@cosmos:~/lab$ make qemu
sed "s/localhost:1234/localhost:26000/" < .gdbinit.tmpl > .gdbinit
qemu -hda obj/kern/kernel.img -serial mon:stdio -gdb tcp::26000 -D qemu.log
WARNING: Image format was not specified for 'obj/kern/kernel.img' and probing guessed raw.
         Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.
         Specify the 'raw' format explicitly to remove the restrictions.
6828 decimal is XXX octal!
entering test_backtrace 5
entering test_backtrace 4
entering test_backtrace 3
entering test_backtrace 2
entering test_backtrace 1
entering test_backtrace 0
leaving test_backtrace 0
leaving test_backtrace 1
leaving test_backtrace 2
leaving test_backtrace 3
leaving test_backtrace 4
leaving test_backtrace 5
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
K>
```

### The PC's Physical Address Space

```
                    +------------------+  <- 0xFFFFFFFF (4GB)
                    |      32-bit      |
                    |  memory mapped   |
                    |     devices      |
                    |                  |
                    /\/\/\/\/\/\/\/\/\/\

                    /\/\/\/\/\/\/\/\/\/\
                    |                  |
                    |      Unused      |
                    |                  |
                    +------------------+  <- depends on amount of RAM
                    |                  |
                    |                  |
                    | Extended Memory  |
                    |                  |
                    |                  |
                    +------------------+  <- 0x00100000 (1MB)
                    |     BIOS ROM     |
                    +------------------+  <- 0x000F0000 (960KB)
                    |  16-bit devices, |
                    |  expansion ROMs  |
                    +------------------+  <- 0x000C0000 (768KB)
                    |   VGA Display    |
                    +------------------+  <- 0x000A0000 (640KB)
                    |                  |
                    |    Low Memory    |
                    |                  |
                    +------------------+  <- 0x00000000
```

### The ROM BIOS

## The Boot Loader

## The Kernel
