# Report for lab5, Houmin Wei

**Great Bug from lab4**

To get started, we need to run `pingpong`, `primes`, and `forktree` test case from lab4 again after merging in the new lab 5 code. However when I run `pingpong` it did not pass. What is wrong ?

Here is the problem. In `sys_ipc_recv` we call `sched_yield` to run another enviroment, But we need to return 0 on success. How can we do that? Add `return 0` after `sched_yield` ? No! we will not come back to here any more after we call `sched_yield`. The original enviroment will start after `r	int r = sys_ipc_recv(pg);` in ipc.c 

To resume the code execution, we need to ensure the `eax` of the enviroment have been ready, which is 0. Thus, we need to add this line in `sys_try_to_send`

```c
	e->env_tf.tf_regs.reg_eax = 0;
```
## On-Disk File System Structure

### Sectors and Blocks

Most disks cannot perform reads and writes at byte granularity and instead perform reads and writes in units of sectors, which today are almost universally 512 bytes each. File systems actually allocate and use disk storage in units of blocks Be wary of the distinction between the two terms: sector size is a property of the disk hardware, whereas block size is an aspect of the operating system using the disk. A file system's block size must be a multiple of the sector size of the underlying disk.

The file system of Jos use a block size of 4096 bytes, conveniently matching the processor's page size.

### Superblocks

Our file system will have exactly one block, which is always be at block 1 on the disk.

### File Meta-data

The layout of the meta-data describing a file in our file system is described by struct File in inc/fs.h. This meta-data includes the file's name, size, type (regular file or directory), and pointers to the blocks comprising the file. 

### Directories versus Regular Files

The file system manages regular files and directory-files in exactly the same way, except that it does not interpret the contents of the data blocks associated with regular files at all, whereas the file system interprets the contents of a directory-file as a series of File structures describing the files and subdirectories within the directory.

## The File System

### Disk Access

**Exercise 1**
---
> Modify `env_create` in env.c, so that it gives the file system environment I/O privilege, but never gives that privilege to any other environment.

Just add these lines
```c
if(type == ENV_TYPE_FS)
	env->env_tf.tf_eflags |= FL_IOPL_3;
```
**Question**
---
> Do you have to do anything else to ensure that this I/O privilege setting is saved and restored properly when you subsequently switch from one environment to another? Why?

No, since the file system server works as a user-level enviroment, each time when we switch from one enviroment to another, we will push `EFLAGS` into the enviroment's trapframe stack by hardware. And it is restored by `iret` in `env_pop_tf`

### The Block Cache

**Exercise 2**
---
> Implement the `bc_pgfault` and `flush_block` functions in fs/bc.c

Notice that the first argument of ide_read is LBA, i.e. Logic Block Address, which equals `blockno*BLKSECTS`, or the sector number `secno`. The second argument `dst` is the location where the data is read to. The third argument `nsecs` is the total number of sectors we want to read, here is `BLKSECTS`
```c
addr = (void *)ROUNDDOWN(addr, PGSIZE);
r = sys_page_alloc(0, addr, PTE_U | PTE_W | PTE_P);
if (r < 0 )
	panic("bc_pgfault: sys_page_alloc fail\n");
r = ide_read(blockno*BLKSECTS, addr, BLKSECTS);
if (r < 0)
	panic("bc_pgfault: ide_read error\n");
```
And in `flush_block`
```c
int r;
if (!va_is_mapped(addr) || !va_is_dirty(addr))
	return ;
addr = (void *)ROUNDDOWN(addr, PGSIZE);
if (ide_write(blockno*BLKSECTS, addr, BLKSECTS) < 0)
	panic("flush_block: ide_write error\n");
```

### The Block Bitmap

**Exercise 3**
---
> Use `free_block` as a model to implement `alloc_block`, which should find a free disk block in the bitmap, mark it used, and return the number of that block. 

```c
int
alloc_block(void)
{
	int bitmap_block_size = super->s_nblocks / BLKBITSIZE;
	if (super->s_nblocks % BLKBITSIZE)
		bitmap_block_size++;
	for (int blockno = 2 + bitmap_block_size; blockno < super->s_nblocks; blockno++) {
		if (block_is_free(blockno)) {
			bitmap[blockno/32] &= ~(1<<(blockno%32));
			flush_block(bitmap);
			return blockno;
		}
	}
	return -E_NO_DISK;
}
```
### File Operations

**Exercise 4**
---
> Implement `file_block_walk` and `file_get_block`

What `file_block_walk` do? It find the disk block number slot  for the `filebno'th` block in the file `f`. First it will check if filebno is lager than NDIRECT. If not, just set `*ppdiskbno` point to that slot. Note that `f->f_direct[filebno]` is the block number of that block, thus `*ppdiskbno` should be the address of the block number, i.e. `*ppdiskbno = f->f_direct + filebno;`

If filebno is larger than NDIRECT, we should check if `f->f_indirect` is allocated yet, just check whether `f->f_indirect` is 0. If not, we should allocate an indirect block. Don't forget to clear any block you allocate and flush it back to disk.

Now we can go to the indirect block and find the address of the block number `(uint32_t*)diskaddr(f->f_indirect) + filebno - NDIRECT;`

Note that if the indirect block is allocated just now, all of its contents are 0, so the block bumber stored in the address `*ppdiskbno` might be 0.
```c
static int
file_block_walk(struct File *f, uint32_t filebno, uint32_t **ppdiskbno, bool alloc)
{
	// LAB 5: Your code here.
	int r;

	if (filebno >= NDIRECT + NINDIRECT)
		return -E_INVAL;

	if (filebno < NDIRECT) {
		if (ppdiskbno)
	 		*ppdiskbno = f->f_direct + filebno;
		return 0;
	}

	if (!f->f_indirect && !alloc)
		return -E_NOT_FOUND;

	if (!f->f_indirect) {
		if ((r = alloc_block()) < 0)
		  return -E_NO_DISK;
		f->f_indirect = r;
		memset(diskaddr(r), 0, BLKSIZE);
		flush_block(diskaddr(r));
	}

	if (ppdiskbno)
		*ppdiskbno = (uint32_t*)diskaddr(f->f_indirect) + filebno - NDIRECT;
	return 0;
}
```
In `file_get_block` we need to Set *blk to the address in memory where the `filebno'th` block of file 'f' would be mapped. First we should get the block number using `file_block_walk`

If the block number is 0, which means we haven't allocate a block for the `filebno`. 
```c
int
file_get_block(struct File *f, uint32_t filebno, char **blk)
{
	// LAB 5: Your code here.
	int r;
	uint32_t *pdiskno;

	if ((r = file_block_walk(f, filebno, &pdiskno, 1)) < 0)
	    return r;

	if (*pdiskno == 0) {
	    if ((r = alloc_block()) < 0)
	        return -E_NO_DISK;
	    *pdiskno = r;
		memset(diskaddr(r), 0, BLKSIZE);
		flush_block(diskaddr(r));
	}

	*blk = diskaddr(*pdiskno);
	return 0;
}
```
### The file system interface

```
/*
  *     4 Gig --------> +-----------------------------------+
  *                     :                .                  :
  *                     :                .                  :
  *                     :                .                  :
  *     USTACKTOP --->  +-----------------------------------+ 0xeebfe000
  *                     |           Normal User Stack       | RW/RW PGSIZE
  *                     +-----------------------------------+ 0xeebfd000
  *                     :                .                  :
  *                     :                .                  :
  *                     +-----------------------------------+ 
  *                     |               1024                | 1024 x PGSIZE
  *                     |           struct Fd *             |
  * DISKMAP + DISKSIZE  +-----------------------------------+ 0xd0000000
  *                     |                                   |
  *                     |                                   |
  *                     |       3GB IDE Disk Space          |
  *                     |                                   |
  *                     |                                   |
  *        DISKMAP ---> +-----------------------------------+ 0x10000000
  *                     |       union Fsipc *fsreq          | RW/RW PGSIZE
  *         fsreq  ---> +-----------------------------------+ 0x0ffff000
  *                     :                .                  :
  *                     :                .                  :
  *                     |-----------------------------------|
  *                     |       Program Data & Heap         |
27 *    UTEXT --------> +-----------------------------------+ 0x00800000
28 *    PFTEMP -------> |           Empty Memory (*)        | PTSIZE
29 *                    |                                   |
30 *    UTEMP --------> +-----------------------------------+ 0x00400000          --+
31 *                    |           Empty Memory (*)        |                       |
32 *                    |- - - - - - - - - - - - - - - - - -|                       |
33 *                    |       User STAB Data (optional)   |                     PTSIZE
34 *    USTABDATA ----> +-----------------------------------+ 0x00200000            |
35 *                    |           Empty Memory (*)        |                       |
36 *    0 ------------> +-----------------------------------+                     --+
37 *
38 */
```
```
      Regular env           FS env
   +---------------+   +---------------+
   |      read     |   |   file_read   |
   |   (lib/fd.c)  |   |   (fs/fs.c)   |
...|.......|.......|...|.......^.......|...............
   |       v       |   |       |       | RPC mechanism
   |  devfile_read |   |  serve_read   |
   |  (lib/file.c) |   |  (fs/serv.c)  |
   |       |       |   |       ^       |
   |       v       |   |       |       |
   |     fsipc     |   |     serve     |
   |  (lib/file.c) |   |  (fs/serv.c)  |
   |       |       |   |       ^       |
   |       v       |   |       |       |
   |   ipc_send    |   |   ipc_recv    |
   |       |       |   |       ^       |
   +-------|-------+   +-------|-------+
           |                   |
           +-------------------+
```
**Exercise 5**
---
> Implement `serve_read` in fs/serv.c

Note to update offset.
```c
int
serve_read(envid_t envid, union Fsipc *ipc)
{
	struct Fsreq_read *req = &ipc->read;
	struct Fsret_read *ret = &ipc->readRet;

	if (debug)
		cprintf("serve_read %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

	// Lab 5: Your code here:
	// First, use openfile_lookup to find the relevant open file.
	// On failure, return the error code to the client with ipc_send.
	struct OpenFile *o;
	int r;
	if ((r = openfile_lookup(envid, req->req_fileid, &o)) < 0)
		return r;

	int req_n = req->req_n > PGSIZE ? PGSIZE : req->req_n;
	if ((r = file_read(o->o_file, ret->ret_buf, req_n, o->o_fd->fd_offset)) < 0)
		return r;
	o->o_fd->fd_offset += r;
	return r;
}
```

`serve_read` is easy, but I didn't pass the check. It panics at `ipc_send`. Why ? The problem is in `sys_ipc_try_send`. When the srcva is above UTOP, we won't try to send page currently mapped at srcva. It is only when srcva is below UTOP, we will try to to some check for that page. But my orinal code is not when we check permission about srcva. Changing the code like this will work.
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

	if (((uint32_t)srcva < UTOP)) {
		pp = page_lookup(curenv->env_pgdir, srcva, &ptep);

		if (((uint32_t)srcva & 0xFFF) != 0)
			return -E_INVAL;

		if ((perm | PTE_SYSCALL) != PTE_SYSCALL)
			return -E_INVAL;

		if (pp == NULL)
			return -E_INVAL;

		if (!((*ptep) & PTE_W) && (perm & PTE_W))
			return -E_INVAL;

		e->env_ipc_perm = 0;
		if ((uint32_t)e->env_ipc_dstva < UTOP)
		{
			if ((r = page_insert(e->env_pgdir, pp, e->env_ipc_dstva, perm)) < 0)
				return r;
			e->env_ipc_perm = perm;
		}
	}

	e->env_ipc_recving = 0;
	e->env_ipc_value = value;
	e->env_ipc_from = curenv->env_id;
	e->env_status = ENV_RUNNABLE;
	e->env_tf.tf_regs.reg_eax = 0;
	return 0;
}
```
**Exercise 6**
---
> Implement `serve_write` in fs/serv.c and `devfile_write` in lib/file.c.

```c
int
serve_write(envid_t envid, struct Fsreq_write *req)
{
	if (debug)
		cprintf("serve_write %08x %08x %08x\n", envid, req->req_fileid, req->req_n);

	// LAB 5: Your code here.
	struct OpenFile *o;
	int r;
	if ((r = openfile_lookup(envid, req->req_fileid, &o)) < 0)
		return r;

	int req_n = req->req_n > PGSIZE ? PGSIZE : req->req_n;
	if ((r = file_write(o->o_file, req->req_buf, req_n, o->o_fd->fd_offset)) < 0)
		return r;
	o->o_fd->fd_offset += r;
	return r;
```

```c
static ssize_t
devfile_write(struct Fd *fd, const void *buf, size_t n)
{
	// Make an FSREQ_WRITE request to the file system server.  Be
	// careful: fsipcbuf.write.req_buf is only so large, but
	// remember that write is always allowed to write *fewer*
	// bytes than requested.
	// LAB 5: Your code here
	int r;

	fsipcbuf.write.req_fileid = fd->fd_file.id;
	fsipcbuf.write.req_n = n;
	assert(n <= PGSIZE - (sizeof(int) + sizeof(size_t)));
	memcpy(fsipcbuf.write.req_buf, buf, n);
	if ((r = fsipc(FSREQ_WRITE, NULL)) < 0)
		return r;
	assert(r <= n);
	return r;
}
```
Till now we get 85/145.

## Spawning Processes

**Exercise 7**
---
> Implement `qsys_env_set_trapframeq` in kernel/syscall.c 

```c
static int
sys_env_set_trapframe(envid_t envid, struct Trapframe *tf)
{
	// LAB 5: Your code here.
	// Remember to check whether the user has supplied us with a good
	// address!
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
		return r;
	if (tf == NULL)
		panic("sys_env_set_trapframe: invalid Trapframe\n");

	// Make sure CPL = 3, interrupts enabled.
	user_mem_assert(e, tf, sizeof(struct Trapframe), PTE_U);
	e->env_tf.tf_cs |= 3;
	e->env_tf.tf_eip |= 3;
	e->env_tf.tf_eflags |= FL_IF;
	e->env_tf = *tf;
	return 0;
}
```
### Sharing library state across fork and spawn

**Exercise 8**
---
> Change `duppage` in lib/fork.c to follow the new convention

dd
> implement `copy_shared_pages` in lib/spawn.c


## The keyboard interface

**Exercise 9**
---
> In your kern/trap.c, call `kbd_intr` to handle trap `IRQ_OFFSET+IRQ_KBD` and `serial_intr` to handle trap `IRQ_OFFSET+IRQ_SERIAL`


## The Shell

**Exercise 10**
---
> Add I/O redirection for < to user/sh.c








