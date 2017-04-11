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
```c
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
```c
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
```c
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

We need to know how `dubmfork` works first.
```c
envid_t
dumbfork(void)
{
	envid_t envid;
	uint8_t *addr;
	int r;
	extern unsigned char end[];

	envid = sys_exofork();
	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.

	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
		duppage(envid, addr);

	// Also copy the stack we are currently running on.
	duppage(envid, ROUNDDOWN(&addr, PGSIZE));

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);

	return envid;
}
```

When we call dumbfork in umain
```
	who = dumbfork();
```
dumbfork call `sys_exofork` to allocate a new child enviroment. The kernel will initialize it with a copy of our register state, which means the child enviroment's return address is exaclty the same as the parent enviroment. But its status is not runnable. After `sys_exofork` returns with the child enviroment's envid, we're the parent. The parent set the child's status to `ENV_RUNNABLE` and copy the their entire address space into the child. The parent then return to `umain` and print `0: I am the parent!`. After this, it call `sys_yield` to schedule round-robin to run the child enviroment. During `env_run` the kernel call `env_pop_tf` to pop the register value to register, and we return to `envid = sys_exofork();` at `dumbfork`. Right now, we expect the envid to be 0, which is the value of `eax`. To realize this, we should add this in `sys_exofork` before we return!
```
	e->env_tf.tf_regs.reg_eax = 0;
```
Now we are the child, and we return to `umain`. This is how fork realize `call once, return twice`.


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

#### Setting the Page Fault Handler

**Exercise 8**
---
> Implement the `sys_env_set_pgfault_upcall` system call.

```c
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
		return r;

	e->env_pgfault_upcall = func;
	return 0;
}
```
#### Normal and Exception Stacks in User Environments


The JOS user exception stack is also one page in size, and its top is defined to be at virtual address UXSTACKTOP, so the valid bytes of the user exception stack are from UXSTACKTOP-PGSIZE through UXSTACKTOP-1 inclusive. While running on this exception stack, the user-level page fault handler can use JOS's regular system calls to map new pages or adjust mappings so as to fix whatever problem originally caused the page fault. Then the user-level page fault handler returns, via an assembly language stub, to the faulting code on the original stack.

#### Invoking the User Page Fault Handler

**Exercise 9** 
---
> Implement the code in `page_fault_handler` in kern/trap.c required to dispatch page faults to the user-mode handler. 

We need to understand how all of this works first. When there is a page fault from user mode, the processor switches to the kernel stack and pushes old SS, ESP, ESP, EFLAGS, CS and EIP. Then it sets CS:EIP to point to the handler function described by the entry which is set by IDT. Then we push other registers value into the stack to form a Trapframe. After this, we call `trap` in `kern/trap.c` 

In the function `trap`, we dispatch based on what type of trap occurred by `trap_dispatch`. Then we find that it is a `T_PGFLT` trap, so we go to `page_fault_handler`.

In the function `page_fault_handler`, we find that the page fault happenred in user mode. Up to now, the state of the user enviroment at the time of the fault, i.e. `trap-time` state is stored in the `tf` parament of `page_fault_handler`. We need to set up a trap frame on the exception stack that looks like a struct `UTrapframe` from inc/trap.h:

```
                    <-- UXSTACKTOP
trap-time esp
trap-time eflags
trap-time eip
trap-time eax       start of struct PushRegs
trap-time ecx
trap-time edx
trap-time ebx
trap-time esp
trap-time ebp
trap-time esi
trap-time edi       end of struct PushRegs
tf_err (error code)
fault_va            <-- %esp when handler is run
```
How to do this? we need to get the address of the UTrapframe, and then set the correct value to it.
Here is the code
```c
struct UTrapframe *utf = (struct UTrapframe *)utf_addr;

utf->utf_fault_va = fault_va;
utf->utf_err = tf->tf_err;
utf->utf_regs = tf->tf_regs;
utf->utf_eip = tf->tf_eip;
utf->utf_eflags = tf->tf_eflags;
utf->utf_esp = tf->tf_esp;

```

The question is how to get the `utf_addr`. If it the first time we face user level page fault, `utf_addr` is just `UTrapframe` size below `UXSTACKTOP`. However, The page fault upcall might cause another page fault, in which case we branch to the page fault upcall recursively, pushing another page fault stack frame on top of the user exception stack.  That means If the user environment is already running on the user exception stack when an exception occurs, then the page fault handler itself has faulted. In this case, you should start the new stack frame just under the current tf->tf_esp rather than at UXSTACKTOP. You should first push an empty 32-bit word, then a struct UTrapframe.

To test whether tf->tf_esp is already on the user exception stack, check whether it is in the range between UXSTACKTOP-PGSIZE and UXSTACKTOP-1, inclusive.

Here is the code
```c
uintptr_t utf_addr;
if(UXSTACKTOP-PGSIZE <= tf->tf_esp && tf->tf_esp <= UXSTACKTOP-1)
	utf_addr = tf->tf_esp - sizeof(struct UTrapframe) - 4;
else
	utf_addr = UXSTACKTOP - sizeof(struct UTrapframe);
user_mem_assert(curenv, (void *)utf_addr, 1, PTE_W);
```

The kernel then arranges for the user environment to resume execution with the page fault handler running on the exception stack with this stack frame. 

How to do this? 

From the hint we know `env_run` is useful. Since we are still in kernel mode now, we can call env_run to drop into user mode and resume execution. But we need to execute the page fault handler, not the environment itself. On the other hand, the stack is not `USTACKTOP` now, we are in the exception stack now. We need to pass the `UTrapframe` pointer as function argument. With the `iret` instruction, we set eip to the page fault handler and change the stack pointer to the UTrapframe.

Here is the code
```
curenv->env_tf.tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
curenv->env_tf.tf_esp = utf_addr;
env_run(curenv);
```

#### User-mode Page Fault Entrypoint
Next, you need to implement the assembly routine that will take care of calling the C page fault handler and resume execution at the original faulting instruction. This assembly routine is the handler that will be registered with the kernel using `sys_env_set_pgfault_upcall()`.

**Exercise 10**
---
> Implement the `_pgfault_upcall` routine in lib/pfentry.S. The interesting part is returning to the original point in the user code that caused the page fault. You'll return directly there, without going back through the kernel. The hard part is simultaneously switching stacks and re-loading the EIP.

As we have known, we call `env_run` to run `curenv->env_pgfault_upcall` which is set using `sys_env_set_pgfault_upcall`. Actually rather than register C page fault handler directly with the kernel as the page fault handler, we register the assembly language wrapper in pfentry.S, which is `_pgfault_upcall`

At first, we enter `_pgfault_upcall` and call `_pgfault_handler`, this deal with the page fault. 
```asm
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
	movl _pgfault_handler, %eax
	call *%eax
	addl $4, %esp			// pop function argument
```
After this done, we need to resume excution of original enviroment, which means to start from where we trap. This can be done using `ret` instruction if we are now at trap-time stack and the top of the stack is the trap-time eip. To do this, we should first push trap-time eip to trap-time stack.
```asm
movl 0x28(%esp), %eax	// trap-time eip
movl 0x30(%esp), %ebx	// trap-time esp
subl $0x4, (%ebx)	
movl %eax, (%ebx)		
addl $0x8, %esp			// skip fault_va and error code
```
Then we need to restore the trap-time registers and eflags
```asm
popal
addl $4, %esp
popfl		
```

Finally we switch back to the adjusted trap-time stack and return to re-execute the instruction that faulted.
```asm
popl %esp
ret
```
**Exercise 11**
---
> Finish `set_pgfault_handler()` in lib/pgfault.c

```c
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
	int r;

	if (_pgfault_handler == 0) {
		// First time through!
		if((sys_page_alloc(curenv->env_id, (void *)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P) < 0)
			panic("set_pgfault_handler: sys_page_alloc error\n");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
	if((sys_env_set_pgfault_upcall(0, _pgfault_upcall)) < 0)
		panic("set_pgfault_handler: sys_env_set_pgfault_upcall error\n");
}
```
#### Testing

It is ok when we run `user/faultread` and `user/faultdie`, but when we run `user/faultalloc`, it did not turn out to be what we expect, but like this

```
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
fault deadbeef
this string was faulted in at deadbeef
fault cafebffe
fault cafec000
fault 69
TRAP frame at 0xf0290000 from CPU 0
  edi  0x008010ef
  esi  0x30b57cec
  ebp  0x00800360
  oesp 0xf0234fdc
  ebx  0xeebfff6c
  edx  0xcafec000
  ecx  0xcafec001
  eax  0x00000069
  es   0x----0023
  ds   0x----0023
  trap 0x0000000d General Protection
  err  0x00000000
  eip  0x00000072
  cs   0x----001b
  flag 0x00000803
  esp  0xeebfff10
  ss   0x----0023
[00001000] free env 00001000
```
**Great BUG!!!**
What is the problem? When I allocate a page at 0xcafec000 and 
```c
snprintf((char*) addr, 100, "this string was faulted in at %x", addr);
```
It is ok to return to `_pgfault_upcall` to re-execute the first page fault at 0xcafebffe. To return to the trap-time state we push trap-time eip to that trap-time stack. However, our code above have not change the stack pointer yet. We need to change code like this.
```asm
movl 0x28(%esp), %eax	// trap-time eip
subl $0x4, 0x30(%esp)	// we have to use subl now because we can't use after popfl
movl 0x30(%esp), %ebx   // trap-time esp-4
movl %eax, (%ebx)		// push trap-time eip to trap-time stack 
addl $0x8, %esp			// skip fault_va and error code
```

After this we get 50/80.

### Implementing Copy-on-Write Fork

**Exercise 12**
> Implement `fork`, `duppage` and `pgfault` in lib/fork.c

What will `fork` do?

- The parent installs `pgfault()` as the C-level page fault handler
```c
set_pgfault_handler(pgfault);
```
- The parent calls `sys_exofork()` to create a child enviroment
```c
envid = sys_exofork();
if (envid < 0)
	panic("sys_exofork: %e", envid);
if (envid == 0) {
	// We're the child.
	// The copied value of the global variable 'thisenv'
	// is no longer valid (it refers to the parent!).
	// Fix it and return 0.
	thisenv = &envs[ENVX(sys_getenvid())];
	return 0;
}
```
- for each writable or copy-on-write page in its address space below UTOP, the parent calls `duppage`, which should map the page copy-on-write into the address space for the child and then *remap* the page copy-on-write in its own address space. 
```c
for (addr = 0; addr < USTACKTOP; addr += PGSIZE)
	if((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_U))
		duppage(envid, PGNUM(addr));
```

Note, we need to check uvpd present first to avoid page fault in accessing uvpt.

- `duppage` sets both PTEs so that the page is not writable, and to contain PTE_COW in the `avail` field to distinguish copy-on-write pages from genuine read-only pages.

```c
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	void* addr = (void *)(pn * PGSIZE);
	if((uvpt[pn] & PTE_COW) || (uvpt[pn] & PTE_W))
	{
		r = sys_page_map(0, addr, envid, addr, PTE_COW | PTE_U | PTE_P);
		if(r < 0)
			panic("duppage: sys_page_map fail\n");
		r = sys_page_map(0, addr, 0, addr, PTE_COW | PTE_U | PTE_P);
		if(r < 0)
			panic("duppage: sys_page_map fail\n");
	}
	else
	{
		r = sys_page_map(0, addr, envid, addr, PTE_U | PTE_P);
		if(r < 0)
			panic("duppage: sys_page_map fail\n");
	}

	return 0;
}
```
- The exception stack is not remapped this way, however. Instead you need to allocate a fresh page in the child for the exception stack. Since the page fault handler will be doing the actual copying and the page fault handler runs on the exception stack, the exception stack cannot be made copy-on-write
```c
// allocate a new page for the child's user exception stack.
if((r = sys_page_alloc(envid, (void *)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P)) < 0)
	panic("sys_page_alloc: %e", r);
```
- The parent sets the user page fault entrypoint for the child to look like its own
```c
extern void _pgfault_upcall();
sys_env_set_pgfault_upcall(envid, _pgfault_upcall);
```
- The child is now ready to run, so the parent marks it runnable
```c
if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
	panic("sys_env_set_status: %e", r);
```

**Question: How UVPT/UVPD works ?**
---

Remember how the x86 translates virtual addresses into physical ones, CR3 points at the page directory. The PDX part of the address indexes into the page directory to give you a page table. The PTX part indexes into the page table to give you a page, and then you add the low bits in.

How page fault work to realize copy-on-write?
- The kernel propagates the page fault to _pgfault_upcall, which calls fork()'s pgfault() handler.

- pgfault() checks that the fault is a write (check for FEC_WR in the error code) and that the PTE for the page is marked PTE_COW. If not, panic.
```c
if (!((err & FEC_WR) && (uvpt[PGNUM(addr)] & PTE_COW) && (uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P)))
	panic("pgfault: not copy-on-write\n");
```
- pgfault() allocates a new page mapped at a temporary location and copies the contents of the faulting page into it. Then the fault handler maps the new page at the appropriate address with read/write permissions, in place of the old read-only mapping.
```c
r = sys_page_alloc(0, (void *)PFTEMP, PTE_U | PTE_W | PTE_P);
if (r < 0)
	panic("pgfault: sys_page_alloc fail\n");
memcpy(PFTEMP, ROUNDDOWN(addr, PGSIZE), PGSIZE);
r = sys_page_map(0, (void *)PFTEMP, 0, ROUNDDOWN(addr, PGSIZE), PTE_U | PTE_W | PTE_P);
if (r < 0)
	panic("pgfault: sys_page_map fail\n");
r = sys_page_unmap(0, (void *)PFTEMP);
if (r < 0)
	panic("pgfault: sys_page_unmap fail\n");
```

This finishs partB.

## Part C: Preemptive Multitasking and Inter-Process Communication(IPC)

### Clock Interrupts and Preemption
In order to allow the kernel to preempt a running environment, forcefully retaking control of the CPU from it, we must extend the JOS kernel to support external hardware interrupts from the clock hardware.

#### Interrupt discipline


**Exercise 13** 
--- 
> Modify kern/trapentry.S and kern/trap.c to initialize the appropriate entries in the IDT and provide handlers for IRQs 0 through 15

This has been done in lab3

> Then modify the code in env_alloc() in kern/env.c to ensure that user environments are always run with interrupts enabled.

Just add this line 
```c
// Enable interrupts while in user mode.
// LAB 4: Your code here.
e->env_tf.tf_eflags |= FL_IF;
```

#### Handling Clock Interrupts

**Exercise 14**
---
> Modify the kernel's `trap_dispatch()` function so that it calls sched_yield() to find and run a different environment whenever a clock interrupt takes place.

Follew the guide
```c
// Handle clock interrupts. Don't forget to acknowledge the
// interrupt using lapic_eoi() before calling the scheduler!
case IRQ_OFFSET + IRQ_TIMER:
	lapic_eoi();
	sched_yield();
	return ;
```

Till now we get 65/80.

### Inter-Process Communication(IPC)

#### IPC in JOS

The "messages" that user environments can send to each other using JOS's IPC mechanism consist of two components: a single 32-bit value, and optionally a single page mapping. Allowing environments to pass page mappings in messages provides an efficient way to transfer more data than will fit into a single 32-bit integer, and also allows environments to set up shared memory arrangements easily.

#### Sending and Receiving Messages

#### Transferring Pages

#### Implementing IPC

**Exercise 15**
---
> Implement `sys_ipc_recv` and `sys_ipc_try_send` in kern/syscall.c

```c
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
	// LAB 4: Your code here.
	int r;
	struct Env *e;
	struct PageInfo *pp;
	pte_t *ptep;

	if ((r = envid2env(envid, &e, 0)) < 0)
		return r;

	if (e->env_ipc_recving == 0)
		return -E_IPC_NOT_RECV;

	pp = page_lookup(curenv->env_pgdir, srcva, &ptep);

	if (((uint32_t)srcva < UTOP) && (((uint32_t)srcva & 0xFFF) != 0))
		return -E_INVAL;

	if (((uint32_t)srcva < UTOP) && ((perm | PTE_SYSCALL) != PTE_SYSCALL))
		return -E_INVAL;

	if (((uint32_t)srcva < UTOP) && (pp == NULL))
		return -E_INVAL;


	if (!((*ptep) & PTE_W) && (perm & PTE_W))
		return -E_INVAL;

	e->env_ipc_perm = 0;
	if (((uint32_t)srcva < UTOP) && ((uint32_t)e->env_ipc_dstva < UTOP))
	{
		if ((r = page_insert(e->env_pgdir, pp, e->env_ipc_dstva, perm)) < 0)
			return r;
		e->env_ipc_perm = perm;

	}
	e->env_ipc_recving = 0;
	e->env_ipc_value = value;
	e->env_ipc_from = curenv->env_id;
	e->env_status = ENV_RUNNABLE;
	return 0;
}
```

```c
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
	if (((uint32_t)dstva < UTOP) && (((uint32_t)dstva & 0xFFF) != 0))
		return -E_INVAL;

	curenv->env_ipc_recving = 1;
	curenv->env_ipc_dstva = dstva;
	curenv->env_status = ENV_NOT_RUNNABLE;
	sched_yield();

	return 0;
}
```
Notice that when we call `sys_ip_recv`, the enviroment we now running is blocked until a value. Thus we call `sched_yield` to the sending enviroment to send the value. When the receiving enviroment get scheduled again, the value is ready and the system call will eventually return 0 on success.

```c
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
	// LAB 4: Your code here.
	int r;
	if (pg == NULL)
		pg = (void *)UTOP;
	while(1) {
		r = sys_ipc_try_send(to_env, val, pg, perm);
		if (r == 0)
			break;
		if(r < 0 && r != -E_IPC_NOT_RECV)
			panic("ipc_send: send fail, %e\n", r);
		sys_yield();
	}
}
```
Notice that if `E_IPC_NOT_RECV`, we can use `sys_yield` to schedule to the receive enviroment to be CPU-friendly.

```c
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
	// LAB 4: Your code here.
	if (pg == NULL)
		pg = (void *)UTOP;
	int r = sys_ipc_recv(pg);
	if (r < 0) {
		if (from_env_store != NULL)
			*from_env_store = 0;
		if (perm_store != NULL)
			*perm_store = 0;
		return r;
	}
	if (from_env_store != NULL)
		*from_env_store = thisenv->env_ipc_from;
	if (perm_store != NULL)
		*perm_store = thisenv->env_ipc_perm;
	return thisenv->env_ipc_value;
}
```

## This ends part C
