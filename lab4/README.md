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

**Question: How LAPIC works ?**
---
 

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


**Exercise 6**
> Implement round-robin scheduling in sched_yield() as described above

Note that curenv may not always valid.
```c
void
sched_yield(void)
{
	struct Env *idle;
	int i, index = 0;
	if (curenv)
		index = ENVX(curenv->env_id);
	else
		index = 0;

	for(i = index; i != index + NENV ; i++) {
		if (envs[i%NENV].env_status == ENV_RUNNABLE)
			env_run(&envs[i%NENV]);
	}
	if(curenv && curenv->env_status == ENV_RUNNING) {
		env_run(curenv);
	}

	// sched_halt never returns
	sched_halt();
}
```
Run `make qemu`
```
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
Hello, I am environment 00001000.
Hello, I am environment 00001001.
Hello, I am environment 00001002.
Back in environment 00001000, iteration 0.
Back in environment 00001001, iteration 0.
Back in environment 00001002, iteration 0.
Back in environment 00001000, iteration 1.
Back in environment 00001001, iteration 1.
Back in environment 00001002, iteration 1.
Back in environment 00001000, iteration 2.
Back in environment 00001001, iteration 2.
Back in environment 00001002, iteration 2.
Back in environment 00001000, iteration 3.
Back in environment 00001001, iteration 3.
Back in environment 00001002, iteration 3.
Back in environment 00001000, iteration 4.
All done in environment 00001000.
[00001000] exiting gracefully
[00001000] free env 00001000
Back in environment 00001001, iteration 4.
All done in environment 00001001.
[00001001] exiting gracefully
[00001001] free env 00001001
Back in environment 00001002, iteration 4.
All done in environment 00001002.
[00001002] exiting gracefully
[00001002] free env 00001002
No runnable environments in the system!
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
K> 
```

Run `make qemu CPUS=2`
```
SMP: CPU 0 found 2 CPU(s)
enabled interrupts: 1 2
SMP: CPU 1 starting
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
Hello, I am environment 00001000.
Hello, I am environment 00001001.
Back in environment 00001000, iteration 0.
Hello, I am environment 00001002.
Back in environment 00001001, iteration 0.
Back in environment 00001000, iteration 1.
Back in environment 00001002, iteration 0.
Back in environment 00001001, iteration 1.
Back in environment 00001000, iteration 2.
Back in environment 00001002, iteration 1.
Back in environment 00001001, iteration 2.
Back in environment 00001000, iteration 3.
Back in environment 00001002, iteration 2.
Back in environment 00001001, iteration 3.
Back in environment 00001000, iteration 4.
All done in environment 00001000.
Back in environment 00001002, iteration 3.
[00001000] exiting gracefully
[00001000] free env 00001000
Back in environment 00001001, iteration 4.
Back in environment 00001002, iteration 4.
All done in environment 00001001.
All done in environment 00001002.
[00001001] exiting gracefully
[00001001] free env 00001001
[00001002] exiting gracefully
[00001002] free env 00001002
No runnable environments in the system!
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
K> 
```
However, when I run `make qemu CPUS=2` again, this result in a general protection or kernel page fault once there are no more runnable environments due to unhandled timer interrupts.
```
SMP: CPU 0 found 2 CPU(s)
enabled interrupts: 1 2
SMP: CPU 1 starting
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
Hello, I am environment 00001000.
Hello, I am environment 00001001.
Back in environment 00001000, iteration 0.
Hello, I am environment 00001002.
Back in environment 00001001, iteration 0.
Back in environment 00001000, iteration 1.
Back in environment 00001001, iteration 1.
Back in environment 00001002, iteration 0.
Back in environment 00001000, iteration 2.
Back in environment 00001001, iteration 2.
Back in environment 00001002, iteration 1.
Back in environment 00001000, iteration 3.
Back in environment 00001001, iteration 3.
Back in environment 00001002, iteration 2.
Back in environment 00001000, iteration 4.
Back in environment 00001001, iteration 4.
All done in environment 00001000.
All done in environment 00001001.
[00001000] exiting gracefully
[00001000] free env 00001000
[00001001] exiting gracefully
[00001001] free env 00001001
Back in environment 00001002, iteration 3.
TRAP frame at 0xf023bfbc from CPU 1
  edi  0xf028f0c0
  esi  0x00000000
  ebp  0x00000000
  oesp 0xf023bfdc
  ebx  0xf028f000
  edx  0xf022b094
  ecx  0x00000002
  eax  0xf023c000
  es   0x----0010
  ds   0x----0010
  trap 0x00000020 Hardware Interrupt
  err  0x00000000
  eip  0xf01040d0
  cs   0x----0008
  flag 0x00000206
kernel panic on CPU 1 at kern/trap.c:230: unhandled trap in kernel
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
K> 
```

**Why ?**
---

**Question**
---
> Why can the pointer e be dereferenced both before and after the addressing switch?

Because the kernel part of vm of all environments are identical.


> Whenever the kernel switches from one environment to another, it must ensure the old environment's registers are saved so they can be restored properly later. Why? Where does this happen?

In trap.c
```
// Copy trap frame (which is currently on the stack)
// into 'curenv->env_tf', so that running the environment
// will restart at the trap point.
curenv->env_tf = *tf;
```
### System Calls for Enviroment Creation

The new system calls you will write for JOS are as follows:
- **sys_exofork**
- **sys_env_set_status**
- **sys_page_alloc**
- **sys_page_map**
- **sys_page_unmap**

**Exercise 7**

>  Implement the system calls described above in `kern/syscall.c`. 

Here is the code I wrote for `sys_exofork`. It Create the new environment with `env_alloc()`, from kern/env.c. It should be left as env_alloc created it, except that status is set to `ENV_NOT_RUNNABLE`, and the register set is copied from the current environment.

```c
static envid_t
sys_exofork(void)
{
	int r;
	struct Env *e;
	if ((r = env_alloc(&e, curenv->env_id)) < 0)
		return r;
	e->env_status = ENV_NOT_RUNNABLE;
	e->env_tf = curenv->env_tf;
	return e->env_id;
}
```
And with other functions written, run `make qemu`, it turns out `page fault` ! What's wrong ?

```
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
[00001000] new env 00001001
0: I am the parent!
[00001001] user panic in <unknown> at user/dumbfork.c:32: sys_page_alloc: bad environment
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
TRAP frame at 0xf029007c from CPU 0
  edi  0x00000000
  esi  0x008011ad
  ebp  0xeebfdf60
  oesp 0xf0234fdc
  ebx  0xeebfdf74
  edx  0xeebfde18
  ecx  0x00000001
  eax  0x00000001
  es   0x----0023
  ds   0x----0023
  trap 0x00000003 Breakpoint
  err  0x00000000
  eip  0x00800277
  cs   0x----001b
  flag 0x00000082
  esp  0xeebfdf58
  ss   0x----0023
K> 
```

**Great Bug!!!**
---

You should add 
```
	e->env_tf.tf_regs.reg_eax = 0;
```
in `sys_exofork` before you return!

And This finish part A of lab4.
```
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
[00001000] new env 00001001
0: I am the parent!
0: I am the child!
1: I am the parent!
1: I am the child!
2: I am the parent!
2: I am the child!
3: I am the parent!
3: I am the child!
4: I am the parent!
4: I am the child!
5: I am the parent!
5: I am the child!
6: I am the parent!
6: I am the child!
7: I am the parent!
7: I am the child!
8: I am the parent!
8: I am the child!
9: I am the parent!
9: I am the child!
[00001000] exiting gracefully
[00001000] free env 00001000
10: I am the child!
11: I am the child!
12: I am the child!
13: I am the child!
14: I am the child!
15: I am the child!
16: I am the child!
17: I am the child!
18: I am the child!
19: I am the child!
[00001001] exiting gracefully
[00001001] free env 00001001
No runnable environments in the system!
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
K> 
```

## Part B: Copy-on-Write Fork


### User-level page fault handling

### Implementing Copy-on-Write Fork

## Part C: Preemptive Multitasking and Inter-Process Communication(IPC)

### Clock Interrupts and Preemption

### Inter-Process Communication(IPC)


