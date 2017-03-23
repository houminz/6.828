# Report for lab2, Houmin Wei
---


## Part 1: Physical Page Management


**Exercise 1**
---
>Q: You'll now write the physical page allocator. It keeps track of which pages are free with a linked list of struct PageInfo objects.

The operating system must keep track of which parts of physical RAM are free and which are currently in use. Considering what we have done now:

![roadmap](assets/roadmap.png)

After the boot loader loading the kernel to physical address 0x00100000(1M, Extended Memory), the kernel began to take control. First of all, the kernel enable paging to use virtual memory and work around position dependence. During this period, we just do this using the hand-written, statically-initialized page directory and page table in `kern/entrypgdir.c`. Up to now we just map the first 4M of physical memory.
- virtual addresses 0xf0000000 through 0xf0400000 to physical addresses 0x00000000 through 0x00400000
- virtual addresses 0x00000000 through 0x00400000 to physical addresses 0x00000000 through 0x00400000

After the kernel initializing its stack, we entered `i386_init` to do some initialization work. After completing the ELF loading process, we use the `cons_init` function to realize formatted printing to the console and other works related. Finally, we enter the `mem_init` function, and this is what lab2 deal with.

It's not difficult to find that the `mem_init` in `kern/pmap.c`. In mem_init, we need to find out available base & extended memory using CMOS calls to measure(`i386_detect_memory`).
```
Physical memory: 66556K available, base = 640K, extended = 65532K
npages is 16639, npages_basemem is 160, npages_extmem is 16383
```
Since we have got physical memory information, we now can set up virtual memory and this is our virtual memory map.
```
/*
* Virtual memory map:                                Permissions
*                                                    kernel/user
*
*    4 Gig -------->  +------------------------------+
*                     |                              | RW/--
*                     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*                     :              .               :
*                     :              .               :
*                     :              .               :
*                     |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~| RW/--
*                     |                              | RW/--
*                     |   Remapped Physical Memory   | RW/--
*                     |                              | RW/--
*    KERNBASE, ---->  +------------------------------+ 0xf0000000      --+
*    KSTACKTOP        |     CPU0's Kernel Stack      | RW/--  KSTKSIZE   |
*                     | - - - - - - - - - - - - - - -|                   |
*                     |      Invalid Memory (*)      | --/--  KSTKGAP    |
*                     +------------------------------+                   |
*                     |     CPU1's Kernel Stack      | RW/--  KSTKSIZE   |
*                     | - - - - - - - - - - - - - - -|                 PTSIZE
*                     |      Invalid Memory (*)      | --/--  KSTKGAP    |
*                     +------------------------------+                   |
*                     :              .               :                   |
*                     :              .               :                   |
*    MMIOLIM ------>  +------------------------------+ 0xefc00000      --+
*                     |       Memory-mapped I/O      | RW/--  PTSIZE
* ULIM, MMIOBASE -->  +------------------------------+ 0xef800000
*                     |  Cur. Page Table (User R-)   | R-/R-  PTSIZE
*    UVPT      ---->  +------------------------------+ 0xef400000
*                     |          RO PAGES            | R-/R-  PTSIZE
*    UPAGES    ---->  +------------------------------+ 0xef000000
*                     |           RO ENVS            | R-/R-  PTSIZE
* UTOP,UENVS ------>  +------------------------------+ 0xeec00000
* UXSTACKTOP -/       |     User Exception Stack     | RW/RW  PGSIZE
*                     +------------------------------+ 0xeebff000
*                     |       Empty Memory (*)       | --/--  PGSIZE
*    USTACKTOP  --->  +------------------------------+ 0xeebfe000
*                     |      Normal User Stack       | RW/RW  PGSIZE
*                     +------------------------------+ 0xeebfd000
*                     |                              |
*                     |                              |
*                     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*                     .                              .
*                     .                              .
*                     .                              .
*                     |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
*                     |     Program Data & Heap      |
*    UTEXT -------->  +------------------------------+ 0x00800000
*    PFTEMP ------->  |       Empty Memory (*)       |        PTSIZE
*                     |                              |
*    UTEMP -------->  +------------------------------+ 0x00400000      --+
*                     |       Empty Memory (*)       |                   |
*                     | - - - - - - - - - - - - - - -|                   |
*                     |  User STAB Data (optional)   |                 PTSIZE
*    USTABDATA ---->  +------------------------------+ 0x00200000        |
*                     |       Empty Memory (*)       |                   |
*    0 ------------>  +------------------------------+                 --+
*
* (*) Note: The kernel ensures that "Invalid Memory" is *never* mapped.
*     "Empty Memory" is normally unmapped, but user programs may map pages
*     there if desired.  JOS user programs map pages temporarily at UTEMP.
*/
```

Up to now, we only mapped 4M at KERNBASE manually using `entry_pgdir` and `entry_pgtable`. From now on, we begin to remap the entire memory. First, we create initial page directory `kern_pgdir` using the `boot_alloc` function. The `boot_alloc(uint32_t n)` here behaving as a simple physical memory allocator is used only while JOS is setting up its memory system.
```c
// nextfree here is virtual address of next byte of free memory
// it is initialize to points to next free page address after the end of the kernel's bss segment:
...
if(n > 0) {
  result = nextfree;
  nextfree = ROUNDUP((char*)(nextfree+n), PGSIZE);
  if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
    panic("Out Of Memory!\n");
//		cprintf("allocate %d bytes, update nextfree to %x\n", n, nextfree);
  return result;
}
else if(n == 0)
  return nextfree;
return NULL;
```

Next, Allocate an array of npages `struct PageInfo`s and store it in `pages`. The kernel uses this array to keep track of physical pages.
```c
//in mem_init
pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
memset(pages, 0, npages * sizeof(struct PageInfo));
```
we can check `struct PageInfo` in `memlayout.h`. Each PageInfo can be mapped to physical address with `page2pa()` one-to-one.
```
struct PageInfo {
	// Next page on the free list.
	struct PageInfo *pp_link;

	// pp_ref is the count of pointers (usually in page table entries)
	// to this page, for pages allocated using page_alloc.
	// Pages allocated at boot time using pmap.c's
	// boot_alloc do not have valid reference count fields.

	uint16_t pp_ref;
};

```

Now that we've allocated the initial kernel data structures, we set up the list of free physical pages. The work is done in `page_init` function. This is the initial code.
```c
size_t i;
for (i = 0; i < npages; i++) {
  pages[i].pp_ref = 0;
  pages[i].pp_link = page_free_list;
  page_free_list = &pages[i];
}
```
What we have done here is to mark all physical pages as free and realize a link list like this
![page-free-list0](assets/page-free-list0.png)
However, this is not truly the case, since not all memory are free.

- Mark physical page 0 as in use. This way we preserve the real-mode IDT and BIOS structures in case we ever need them.
- The rest of base memory, [PGSIZE, npages_basemem * PGSIZE) is free.
- Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must never be allocated.
- Then extended memory [EXTPHYSMEM, ...). Some of it is in use, some is free. Where is the kernel  in physical memory?  Which pages are already in use for page tables and other data structures?

```c
size_t i;
page_free_list = NULL;

//num_alloc：在extmem区域已经被占用的页的个数
int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
//num_iohole：在io hole区域占用的页数
int num_iohole = 96;

pages[0].pp_ref = 1;
for(i = 1; i < npages_basemem; i++)
{
  pages[i].pp_ref = 0;
  pages[i].pp_link = page_free_list;
  page_free_list = &pages[i];
}

for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
  pages[i].pp_ref = 1;
for(; i < npages; i++)
{
  pages[i].pp_ref = 0;
  pages[i].pp_link = page_free_list;
  page_free_list = &pages[i];
}
```

Then, we entered `check_page_free_list`，Check that the pages on the page_free_list are reasonable.
**Here is the code I don't quiet understand**
```c
if (only_low_memory) {
  // Move pages with lower addresses first in the free
  // list, since entry_pgdir does not map all pages.
  cprintf("before hanling low memory question, page_free_list is %x now\n", page_free_list);
  struct PageInfo *pp1, *pp2;
  struct PageInfo **tp[2] = { &pp1, &pp2 };
  for (pp = page_free_list; pp; pp = pp->pp_link) {
    int pagetype = PDX(page2pa(pp)) >= pdx_limit;
    *tp[pagetype] = pp;
    tp[pagetype] = &pp->pp_link;
  }
  *tp[1] = 0;
  *tp[0] = pp2;
  page_free_list = pp1;
}

```
As we can see, the code here is to move pages with lower address first in free list. This is because the free page list originally begins from the big-number pages. However, jos now use entry_pgdir, and have not mapped for the big-number pages. So we can only operate on small-number pages. For this reason, we need to move pages before 4M first in the free page list.

Finally, we entered `check_page_alloc`, this function checks `page_alloc` and `page_free`
```c
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if(!page_free_list)
		return NULL;
	struct PageInfo *pp = page_free_list;
	if(alloc_flags & ALLOC_ZERO) {
		memset(page2kva(pp), 0, PGSIZE);
	}
	page_free_list = pp->pp_link;
	pp->pp_link = 0;
	return pp;
}

page_free(struct PageInfo *pp)
{
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0)
		panic("pp->pp_ref is nonzero\n");
	if(pp->pp_link)
		panic("pp->pp_link is not NULL\n");

	pp->pp_link = page_free_list;
	page_free_list = pp;
}

```
Till now, we have finished Part 1.
```
Physical memory: 66556K available, base = 640K, extended = 65532K
npages is 16639, npages_basemem is 160, npages_extmem is 16383
before hanling low memory question, page_free_list is f01367f0 now
after hanling low memory question, page_free_list is f0117ff8 now
first_free_page is f0137000
nfree_basemem is 159, nfree_extmem is 16072
should be able to allocate three pages
test flags
page2kva(pp0) is f03fd000
check_page_alloc() succeeded!
```

## Part 2: Virtual Memory

### Virtual, Liner, and Physical Address

```

           Selector  +--------------+         +-----------+
          ---------->|              |         |           |
                     | Segmentation |         |  Paging   |
Software             |              |-------->|           |---------->  RAM
            Offset   |  Mechanism   |         | Mechanism |
          ---------->|              |         |           |
                     +--------------+         +-----------+
            Virtual                   Linear                Physical

```
A C pointer is the "offset" component of the virtual address. In boot/boot.S, we installed a Global Descriptor Table (GDT) that effectively disabled segment translation by setting all segment base addresses to 0 and limits to 0xffffffff. Hence the "selector" has no effect and the linear address always equals the offset of the virtual address. In lab 3, we'll have to interact a little more with segmentation to set up privilege levels, but as for memory translation, we can ignore segmentation throughout the JOS labs and focus solely on page translation.

```
Question

Assuming that the following JOS kernel code is correct, what type should variable x have, uintptr_t or physaddr_t?
	mystery_t x;
	char* value = return_a_pointer();
	*value = 10;
	x = (mystery_t) value;
```
Answer: uintptr_t

### Reference Counting

We may remember that, in `page_init` we initialize the `pp_ref` field of all the page to 0 that can be used. And in `page_alloc` and `page_free`, we did not operate on this field. However, the same physical page may be mapped at multiple virtual addresses simultaneously.

Be careful when using `page_alloc`. The page it returns will always have a reference count of 0, so `pp_ref` should be incremented as soon as you've done something with the returned page (like inserting it into a page table). Sometimes this is handled by other functions (for example, page_insert) and sometimes the function calling page_alloc must do it directly.

In general, `pp_ref` should equal to the number of times the physical page appears `below UTOP`(the mapping above UTOP are mostly set up at boot time by the kernel and should never be freed, so there is no need to reference count them)

### Page Table Management

**Exercise 4**
---

>Q: Now you'll write a set of routines to manage page tables: to insert and remove linear-to-physical mappings, and to create page table pages when needed.

Here we need to Implement the following functions

- pgdir_walk()
```
// Given 'pgdir', a pointer to a page directory, pgdir_walk returns
// a pointer to the page table entry (PTE) for linear address 'va'.
// This requires walking the two-level page table structure.
//
// The relevant page table page might not exist yet.
// If this is true, and create == false, then pgdir_walk returns NULL.
// Otherwise, pgdir_walk allocates a new page table page with page_alloc.
//    - If the allocation fails, pgdir_walk returns NULL.
//    - Otherwise, the new page's reference count is incremented,
//	the page is cleared,
//	and pgdir_walk returns a pointer into the new page table page.
```
First we need to know that the 31-12bit of page directory and page table is physical address, not virtual address. To get page table entry, we need `KADDR` to map it to virtual address.

```c
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in
	pde_t pde = pgdir[PDX(va)];
	pte_t * result;
	if(pde & PTE_P)
	{
		pte_t * pg_table_p = KADDR(PTE_ADDR(pde));
		result = pg_table_p + PTX(va);
		return result;
	}
	else if(!create)
		return NULL;
	else
	{
		struct PageInfo *pp = page_alloc(1);
		if(!pp)
			return NULL;
		else
		{
			pp->pp_ref++;
			pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W;
			pte_t * pg_table_p = KADDR(page2pa(pp));
			result = pg_table_p + PTX(va);
			return result;
		}
	}
}
```

- page_lookup()
```c
//
// Return the page mapped at virtual address 'va'.
// If pte_store is not zero, then we store in it the address
// of the pte for this page.  This is used by page_remove and
// can be used to verify page permissions for syscall arguments,
// but should not be used by most callers.
//
// Return NULL if there is no page mapped at va.
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 0);
	if(ptep) {
		physaddr_t pa = PTE_ADDR(ptep);
		struct PageInfo * result = pa2page(pa);
		if(pte_store)
			pte_store = &ptep;
		return result;
	}
	return NULL;
}
```

- boot_map_region

```c
//
// Map [va, va+size) of virtual address space to physical [pa, pa+size)
// in the page table rooted at pgdir.  Size is a multiple of PGSIZE, and
// va and pa are both page-aligned.
// Use permission bits perm|PTE_P for the entries.
//
// This function is only intended to set up the ``static'' mappings
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
    }
}
```

- page_lookup

```c
//
// Return the page mapped at virtual address 'va'.
// If pte_store is not zero, then we store in it the address
// of the pte for this page.  This is used by page_remove and
// can be used to verify page permissions for syscall arguments,
// but should not be used by most callers.
//
// Return NULL if there is no page mapped at va.
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 0);
	if(ptep && ((*ptep) & PTE_P)) {
		physaddr_t pa = PTE_ADDR(*ptep);
		struct PageInfo * result = pa2page(pa);
		if(pte_store)
			*pte_store = ptep;
		return result;
	}
	return NULL;
}
```

- page_remove
```c
//
// Unmaps the physical page at virtual address 'va'.
// If there is no physical page at that address, silently does nothing.
//
// Details:
//   - The ref count on the physical page should decrement.
//   - The physical page should be freed if the refcount reaches 0.
//   - The pg table entry corresponding to 'va' should be set to 0.
//     (if such a PTE exists)
//   - The TLB must be invalidated if you remove an entry from
//     the page table.
//
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
	// Fill this function in
	pte_t * ptep;
	struct PageInfo *pp = page_lookup(pgdir, va, &ptep);
	if(!pp || !(*ptep & PTE_P))
		return;
	page_decref(pp);		// the ref count of the physical page should decrement
	tlb_invalidate(pgdir, va);	// the TLB must be invalidated if you remove an entry from the page table
	*ptep = 0;
}
```

- page_insert
```c
//
// Map the physical page 'pp' at virtual address 'va'.
// The permissions (the low 12 bits) of the page table entry
// should be set to 'perm|PTE_P'.
//
// Requirements
//   - If there is already a page mapped at 'va', it should be page_remove()d.
//   - If necessary, on demand, a page table should be allocated and inserted
//     into 'pgdir'.
//   - pp->pp_ref should be incremented if the insertion succeeds.
//   - The TLB must be invalidated if a page was formerly present at 'va'.
//
// Corner-case hint: Make sure to consider what happens when the same
// pp is re-inserted at the same virtual address in the same pgdir.
// However, try not to distinguish this case in your code, as this
// frequently leads to subtle bugs; there's an elegant way to handle
// everything in one code path.
//
// RETURNS:
//   0 on success
//   -E_NO_MEM, if page table couldn't be allocated
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 1);
	if(ptep == NULL)
		return -E_NO_MEM;

	pp->pp_ref++;
	if((*ptep) & PTE_P)
		page_remove(pgdir, va);

	*ptep  = page2pa(pp) | PTE_P | perm;
	pgdir[PDX(va)] |= perm;    //when permission of PTE changes, PDE should also change
	return 0;
}
```

**GREAT BUG**

in page_lookup
```
*pte_store = ptep;

//当写成pte_store = &ptep; 出现崩溃。
```

## Part 3: Kernel Address Space

why 256MB?

JOS divides the processor's 32-bit linear address space into two parts. User environments (processes), which we will begin loading and running in lab 3, will have control over the layout and contents of the lower part, while the kernel always maintains complete control over the upper part. The dividing line is defined somewhat arbitrarily by the symbol `ULIM` in inc/memlayout.h, reserving approximately 256MB of virtual address space for the kernel. This explains why we needed to give the kernel such a high link address in lab 1: otherwise there would not be enough room in the kernel's virtual address space to map in a user environment below it at the same time.


### Permission and Fault Management

The user environment will have no permission to any of the memory above ULIM, while the kernel will be able to read and write this memory. For the address range [UTOP,ULIM), both the kernel and the user environment have the same permission: they can read but not write this address range. This range of address is used to expose certain kernel data structures read-only to the user environment. Lastly, the address space below UTOP is for the user environment to use; the user environment will set permissions for accessing this memory.


### Initializing the Kernel Address Space

Now you'll set up the address space above UTOP: the kernel part of the address space. inc/memlayout.h shows the layout you should use. You'll use the functions you just wrote to set up the appropriate linear to physical mappings.


**Exercise 5**

>Q: Fill in the missing code in mem_init() after the call to check_page().
Your code should now pass the check_kern_pgdir() and check_page_installed_pgdir() checks.

- Map 'pages' read-only by the user at linear address UPAGES

```c
// Permissions:
//    - the new image at UPAGES -- kernel R, user R
//      (ie. perm = PTE_U | PTE_P)
//    - pages itself -- kernel RW, user NONE
boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
```

What does this step mean? We already have a array of npages 'struct PageInfo'. It is first mapped to the virtual address after the kern_pgdir. Now we want map it to UPAGES.

- Use the physical memory that 'bootstack' refers to as the kernel stack.

from lab1 we know that the kernel stack is at 0xf0108000-0xf0110000, we now map it to [KSTACKTOP-KSTKSIZE, KSTACKTOP) where KSTKSIZE is 8 * PGSIZE, which is exactly 0x8000.

```c
boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
```

- Map all of physical memory at KERNBASE

the VA range [KERNBASE, 2^32) should map to the PA range [0, 2^32 - KERNBASE)

```c
boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
```

**Question 2**
---

> What entries (rows) in the page directory have been filled in at this point? What addresses do they map and where do they point? In other words, fill out this table as much as possible:

Until now, we have just filled some entries in page directory.

First, we recursively insert PD in itself as a page table, to form a virtual page table at virtual address UVPT.
```c
kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
```
This means we fill entry(0x3BD), its base virtual address is UVPT(0xef400000), points to `kern_pgdir`

Then we map 'pages' read-only by the user at linear address UPAGES        
This means we fill entry(0x3BC), its base virtual address is UPages(0xef000000), points to `pages`

Next we use the physical memory that 'bootstack' refers to as the kernel stack.       
This means we fill entry(0x3BF), its base virtual address is MMIOLIM(0xefc00000), points to `bootstack`

Finally we map all of physical memory at KERNBASE         
This means we fill entry(0x3C0-0x3FF), its base virtual address is MMIOLIM(0xefc00000), points to `kernel`

**Question 3**
---
>We have placed the kernel and user environment in the same address space. Why will user programs not be able to read or write the kernel's memory? What specific mechanisms protect the kernel memory?

Generally speaking, operating system uses 2 ways to realize protection of kernel space. One is segmentation, the other is paging. In JOS, we didn't enable segmentation yet, thus we use paging mechanism. When the PTE_U is not enabled, code in user space can not visit kernel's memory.

**Question 4**
---
>What is the maximum amount of physical memory that this operating system can support? Why?

Since JOS use 4MB UPAGES space to store all the PageInfo struct information, each struct is 8B, so we can store 512K PageInfo structs. The size of a page is 4KB, so we can have most `512K * 4KB = 2GB` physical memory.

**Question 5**
---
>How much space overhead is there for managing memory, if we actually had the maximum amount of physical memory? How is this overhead broken down?

We need 4MB `PageInfo` to manage memory, and 2MB for page table, 4KB for page directory if we have 2G physical memory.

**Question 6**
---
>Revisit the page table setup in kern/entry.S and kern/entrypgdir.c. Immediately after we turn on paging, EIP is still a low number (a little over 1MB). At what point do we transition to running at an EIP above KERNBASE? What makes it possible for us to continue executing at a low EIP between when we enable paging and when we begin running at an EIP above KERNBASE? Why is this transition necessary?

After `jmp *%eax` finished.It is possible because `entry_pgdir` also maps va[0-4M) to pa[0-4M), it is necessary because later a kern_pgdir will be loaded and va[0, 4M) will be abandoned.

### Address Space Layout Alternatives



## This completes the lab
