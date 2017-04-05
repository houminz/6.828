# Report for lab4, Houmin Wei

## Part A: Multiprocessor Support and Cooperative Multitasking

### Multiprocessor Support
---

In an SMP system, each CPU has an accompanying local `APIC` (LAPIC) unit. The `LAPIC` units are responsible for delivering interrupts throughout the system. The LAPIC also provides its connected CPU with a unique identifier. In this lab, we make use of the following basic functionality of the LAPIC unit (in kern/lapic.c):
- Reading the LAPIC identifier `APIC ID` to tell which CPU our code is currently running on
- Sending the `STARTUP` interprocessor interrupt `IPI` from BSP to the APs to bring up other CPUs
- In part C, we program LAPIC's built-in timer to trigger clock interrupts to support preemptive multitasking.

**Exercise 1**
> Implement `mmio_map_region` in kern/pmap.c.

We should not simply `ROUNDUP(size, PGSIZE)` but `size+pa` instead.
```
void *
mmio_map_region(physaddr_t pa, size_t size)
{
	static uintptr_t base = MMIOBASE;
	size = (size_t)ROUNDUP(pa + size, PGSIZE);
	pa = (physaddr_t)ROUNDDOWN(pa, PGSIZE);
	size = size - pa;
	if(base + size >= MMIOLIM)
		panic("mmio_map_region: not enough space\n");
	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD | PTE_PWT | PTE_W);
	base += size;
	return (void *)(base - size);
}
```

#### Application Processor Bootstrap
---


Before booting up APs, the BSP should first collect information about the multiprocessor system, such as the total number of CPUs, their APIC IDs and the MMIO address of the LAPIC unit. The `mp_init()` function in kern/mpconfig.c retrieves this information by reading the MP configuration table that resides in the BIOS's region of memory.

**Exercise 2**
---
>  modify your implementation of `page_init()` in kern/pmap.c to avoid adding the page at MPENTRY_PADDR to the free list

Just change the upper boundary.
```
	for(i = 1; i < MPENTRY_PADDR/PGSIZE; i++)
	{
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
```
**Question**
---
> Compare kern/mpentry.S side by side with boot/boot.S. what is the purpose of macro `MPBOOTPHYS` ?

Because `mpentry.S` is loaded by bootloader as a part of kernel, we should mv it to `0x7000` in `boot_aps` function by bootstrap CPU.
```
// Write entry code to unused memory at MPENTRY_PADDR
code = KADDR(MPENTRY_PADDR);
memmove(code, mpentry_start, mpentry_end - mpentry_start);
```
It uses MPBOOTPHYS to calculate absolute addresses of its symbols, rather than relying on the linker to fill them. In this ways, the code would execute at where we want it to.


> Because this code sets DS to zero, it must run from an address in the low 2^16 bytes of physical memory. Where sets? Why should in low memory?


#### Per-CPU state and Initialization
---

**Exercise 3**
---
> Modify `mem_init_mp()` (in kern/pmap.c) to map per-CPU stacks starting at KSTACKTOP, as shown in inc/memlayout.h

The first idea I came up with like this
```
static void
mem_init_mp(void)
{
	uint32_t kstacktop_i;
	for(int i = 1; i < NCPU; i++) {
		kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
	}
}
```
But it did not pass the check. I had thought now that we have a KSTKSIZE `bootstack`, we don't need to map percpu_kstacks[0] now. However there will be `KSTKSIZE` waste of memory. When I changed i to start from 0, it worked. This means we will not use `bootstack` any more.

**Exercise 4**
---

> The code in `trap_init_percpu()` (kern/trap.c) initializes the TSS and TSS descriptor for the BSP. It worked in Lab 3, but is incorrect when running on other CPUs. Change the code so that it can work on all CPUs.

we should change the original code to adapt to different cpu.
```
void
trap_init_percpu(void)
{
	uint8_t i = thiscpu->cpu_id;
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[i] + KSTKSIZE);
	thiscpu->cpu_ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (i << 3));

	// Load the IDT
	lidt(&idt_pd);
}
```

After this, we can see using `make qemu CPUS=4`
```
Physical memory: 66556K available, base = 640K, extended = 65532K
check_page_alloc() succeeded!
check_page() succeeded!
check_kern_pgdir() succeeded!
check_page_installed_pgdir() succeeded!
SMP: CPU 0 found 4 CPU(s)
enabled interrupts: 1 2
SMP: CPU 1 starting
SMP: CPU 2 starting
SMP: CPU 3 starting
```
#### Locking

**Question**
---

> It seems that using the big kernel lock guarantees that only one CPU can run the kernel code at a time. Why do we still need separate kernel stacks for each CPU?

When an interrupt occurs, the hardware automatically pushes
- uint32_t tf_err
- uint32_t tf_eip
- uint16_t tf_cs
- uint16_t tf_padding3
- uint32_t tf_eflags
to kernel stack before checking the lock. So it will just mess up.


### Round-Robin Scheduling


### System Calls for Enviroment Creation

## Part B: Copy-on-Write Fork

### User-level page fault handling

### Implementing Copy-on-Write Fork

## Part C: Preemptive Multitasking and Inter-Process Communication(IPC)

### Clock Interrupts and Preemption

### Inter-Process Communication(IPC)
