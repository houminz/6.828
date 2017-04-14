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

# This is defined in `inc/fs.h`
```c
// Bytes per file system block - same as page size
#define BLKSIZE		PGSIZE
#define BLKBITSIZE	(BLKSIZE * 8)
```

And we also define this in `fs/fs.h`
```c
#define SECTSIZE	512			// bytes per disk sector
#define BLKSECTS	(BLKSIZE / SECTSIZE)	// sectors per block
```

### Superblocks

Our file system will have exactly one block, which is always be at block 1 on the disk. We define struct `Super` in `inc/fs.h`
```c
// File system super-block (both in-memory and on-disk)

#define FS_MAGIC	0x4A0530AE	// related vaguely to 'J\0S!'

struct Super {
	uint32_t s_magic;		// Magic number: FS_MAGIC
	uint32_t s_nblocks;		// Total number of blocks on disk
	struct File s_root;		// Root directory node
};
```
And we define the variable in `fs/fs.h`
```c
struct Super *super;		// superblock
uint32_t *bitmap;		// bitmap blocks mapped in memory
```
### File Meta-data

The layout of the meta-data describing a file in our file system is described by struct `File` in `inc/fs.h`. This meta-data includes the file's name, size, type (regular file or directory), and pointers to the blocks comprising the file. 

```c
// Maximum size of a filename (a single path component), including null
// Must be a multiple of 4
#define MAXNAMELEN	128

// Maximum size of a complete pathname, including null
#define MAXPATHLEN	1024

// Number of block pointers in a File descriptor
#define NDIRECT		10
// Number of direct block pointers in an indirect block
#define NINDIRECT	(BLKSIZE / 4)

#define MAXFILESIZE	((NDIRECT + NINDIRECT) * BLKSIZE)

struct File {
	char f_name[MAXNAMELEN];	// filename
	off_t f_size;			// file size in bytes
	uint32_t f_type;		// file type

	// Block pointers.
	// A block is allocated iff its value is != 0.
	uint32_t f_direct[NDIRECT];	// direct blocks
	uint32_t f_indirect;		// indirect block

	// Pad out to 256 bytes; must do arithmetic in case we're compiling
	// fsformat on a 64-bit machine.
	uint8_t f_pad[256 - MAXNAMELEN - 8 - 4*NDIRECT - 4];
} __attribute__((packed));	// required only on some 64-bit machines
```

### Directories versus Regular Files

The file system manages regular files and directory-files in exactly the same way, except that it does not interpret the contents of the data blocks associated with regular files at all, whereas the file system interprets the contents of a directory-file as a series of File structures describing the files and subdirectories within the directory.
```c
// File types
#define FTYPE_REG	0	// Regular file
#define FTYPE_DIR	1	// Directory
```
## The File System

### Disk Access

In `monolithic` operating system like Linux, they add an IDE disk driver to the kernel along with the necessary system calls to allow the file system to access the disk. But in jos, we instead implement the IDE driver as part of the user-level file system enviroment.

To implement disk access in user space, we rely on `polling`, `programmed I/O`-based disk access and do not use disk interrupt.

All the IDE disk registers we need to access are located in the x86's I/O space rather than memory-mapped. In otder to allow the file system to access these registers, we need to giving `I/O privilege` to the file system enviroment. To do this, we just need to enable the `IOPL` bits when create the file system enviroment.


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

We can have a look at how the file system works now. As we have said, our file system is an user-level enviroment. in init.c, we create the enviroment by 
`ENV_CREATE(fs_fs, ENV_TYPE_FS);`
here is the main function for it(in fs/serv.c)
```c
void
umain(int argc, char **argv)
{
	static_assert(sizeof(struct File) == 256);
	binaryname = "fs";
	cprintf("FS is running\n");

	// Check that we are able to do I/O
	outw(0x8A00, 0x8A00);
	cprintf("FS can do I/O\n");

	serve_init();
	fs_init();
        fs_test();
	serve();
}
```
After `exercise 1`, we pass `FS can do I/O`. 

### The Block Cache

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
  *                     +-----------------------------------+ FILEDATA
  *                     |               32                  | 32 x PGSIZE
  *                     |           struct Fd *             |
  * DISKMAP + DISKSIZE  +-----------------------------------+ 0xd0000000 / FDTABLE
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

Our file system will be limited to handling disks of size 3GB or less. We reserve a large, fixed 3GB region of the file system environment's address space, from 0x10000000 (DISKMAP) up to 0xD0000000 (DISKMAP+DISKMAX), as a "memory mapped" version of the disk. This is defined in `fs/fs.h`
```c
/* Disk block n, when in memory, is mapped into the file system
 * server's address space at DISKMAP + (n*BLKSIZE). */
#define DISKMAP		0x10000000

/* Maximum disk size we can handle (3GB) */
#define DISKSIZE	0xC0000000
```

By this `buffer cache` strategy, we'll implement a form of `demand paging`. We don't need to read the entire disk into memory, but only allocate pages in the disk map region and read the corresponding block from the disk in response to a page fault in this region.

**Exercise 2**
---
> Implement the `bc_pgfault` and `flush_block` functions in fs/bc.c

Notice that the first argument of ide_read is LBA, i.e. Logic Block Address, which equals `blockno*BLKSECTS`, or the sector number `secno`. The second argument `dst` is the location where the data is read to. The third argument `nsecs` is the total number of sectors we want to read, here is `BLKSECTS`
```c
static void
bc_pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;
	int r;

	// Check that the fault was within the block cache region
	if (addr < (void*)DISKMAP || addr >= (void*)(DISKMAP + DISKSIZE))
		panic("page fault in FS: eip %08x, va %08x, err %04x",
		      utf->utf_eip, addr, utf->utf_err);

	// Sanity check the block number.
	if (super && blockno >= super->s_nblocks)
		panic("reading non-existent block %08x\n", blockno);

	// Allocate a page in the disk map region, read the contents
	// of the block from the disk into that page.
	// Hint: first round addr to page boundary. fs/ide.c has code to read
	// the disk.
	//
	// LAB 5: you code here:
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

	// Clear the dirty bit for the disk block page since we just read the
	// block from disk
	if ((r = sys_page_map(0, addr, 0, addr, uvpt[PGNUM(addr)] & PTE_SYSCALL)) < 0)
		panic("in bc_pgfault, sys_page_map: %e", r);

	// Check that the block we read was allocated.
	if (bitmap && block_is_free(blockno))
		panic("reading free block %08x\n", blockno);
}
```
Note that after we read the block from disk, we need to clear the dirty bit for the disk block page since we just read the block from disk. Actually we use the VM hardware to keep track of whether a disk block has been modified since it was last read from or written to disk. To see whether a block needs writing, we can just look to see if the `PTE_D` dirty bit is set in the uvpt entry. (Note that the `PTE_D` bit is set by the processor in response to a write to that page.)
```c
// Flush the contents of the block containing VA out to disk if
// necessary, then clear the PTE_D bit using sys_page_map.
// If the block is not in the block cache or is not dirty, does
// nothing.
void
flush_block(void *addr)
{
	uint32_t blockno = ((uint32_t)addr - DISKMAP) / BLKSIZE;

	if (addr < (void*)DISKMAP || addr >= (void*)(DISKMAP + DISKSIZE))
		panic("flush_block of bad va %08x", addr);

	// LAB 5: Your code here.
	int r;
	if (!va_is_mapped(addr) || !va_is_dirty(addr))
		return ;
	addr = (void *)ROUNDDOWN(addr, PGSIZE);
	if (ide_write(blockno*BLKSECTS, addr, BLKSECTS) < 0)
		panic("flush_block: ide_write error\n");

	// Clear the dirty bit for the disk block page since we just read the
	// block from disk
	if ((r = sys_page_map(0, addr, 0, addr, uvpt[PGNUM(addr)] & PTE_SYSCALL)) < 0)
		panic("in bc_pgfault, sys_page_map: %e", r);

}
```
Now we can check what we do in `fs_init`
```c
// Initialize the file system
void
fs_init(void)
{
	static_assert(sizeof(struct File) == 256);

    // Find a JOS disk.  Use the second IDE disk (number 1) if availabl
    if (ide_probe_disk1())
           ide_set_disk(1);
    else
           ide_set_disk(0);
    bc_init();
    
    // Set "super" to point to the super block.
    super = diskaddr(1);
    check_super();
    
    // Set "bitmap" to the beginning of the first bitmap block.
    bitmap = diskaddr(2);
    check_bitmap();

}
```
First we have a strcut `File` for each file to store the meta data of a file, it should be 256 bytes. Then we set check whether disk 1 exist. To understand this, we should know that the `GNUmakefile` file in this lab sets up QEMU to use the file `obj/kern/kernel.img` as the image for `disk 0` (typically "Drive C" under DOS/Windows) as before, and to use the (new) file `obj/fs/fs.img` as the image for `disk 1` ("Drive D"). In this lab our file system should only ever touch disk 1; disk 0 is used only to boot the kernel. 
```Makefile
QEMUOPTS = -hda $(OBJDIR)/kern/kernel.img -serial mon:stdio -gdb tcp::$(GDBPORT)
QEMUOPTS += $(shell if $(QEMU) -nographic -help | grep -q '^-D '; then echo '-D qemu.log'; fi)
IMAGES = $(OBJDIR)/kern/kernel.img
QEMUOPTS += -smp $(CPUS)
QEMUOPTS += -hdb $(OBJDIR)/fs/fs.img
IMAGES += $(OBJDIR)/fs/fs.img
```
We can see that `obj/kern/kernel.img` is hda and `obj/fs/fs.img` is hdb.

**How `fs.img` is created?**
---

```Makefile

OBJDIRS += fs

FSOFILES := 		$(OBJDIR)/fs/ide.o \
			$(OBJDIR)/fs/bc.o \
			$(OBJDIR)/fs/fs.o \
			$(OBJDIR)/fs/serv.o \
			$(OBJDIR)/fs/test.o \

USERAPPS := 		$(OBJDIR)/user/init

FSIMGTXTFILES :=	fs/newmotd \
			fs/motd


USERAPPS :=		$(USERAPPS) \
			$(OBJDIR)/user/cat \
			$(OBJDIR)/user/echo \
			$(OBJDIR)/user/init \
			$(OBJDIR)/user/ls \
			$(OBJDIR)/user/lsfd \
			$(OBJDIR)/user/num \
			$(OBJDIR)/user/forktree \
			$(OBJDIR)/user/primes \
			$(OBJDIR)/user/primespipe \
			$(OBJDIR)/user/sh \
			$(OBJDIR)/user/testfdsharing \
			$(OBJDIR)/user/testkbd \
			$(OBJDIR)/user/testpipe \
			$(OBJDIR)/user/testpteshare \
			$(OBJDIR)/user/testshell \
			$(OBJDIR)/user/hello \

FSIMGTXTFILES :=	$(FSIMGTXTFILES) \
			fs/lorem \
			fs/script \
			fs/testshell.key \
			fs/testshell.sh


FSIMGFILES := $(FSIMGTXTFILES) $(USERAPPS)

$(OBJDIR)/fs/%.o: fs/%.c fs/fs.h inc/lib.h $(OBJDIR)/.vars.USER_CFLAGS
	@echo + cc[USER] $<
	@mkdir -p $(@D)
	$(V)$(CC) -nostdinc $(USER_CFLAGS) -c -o $@ $<

$(OBJDIR)/fs/fs: $(FSOFILES) $(OBJDIR)/lib/entry.o $(OBJDIR)/lib/libjos.a user/user.ld
	@echo + ld $@
	$(V)mkdir -p $(@D)
	$(V)$(LD) -o $@ $(ULDFLAGS) $(LDFLAGS) -nostdlib \
		$(OBJDIR)/lib/entry.o $(FSOFILES) \
		-L$(OBJDIR)/lib -ljos $(GCC_LIB)
	$(V)$(OBJDUMP) -S $@ >$@.asm

# How to build the file system image
$(OBJDIR)/fs/fsformat: fs/fsformat.c
	@echo + mk $(OBJDIR)/fs/fsformat
	$(V)mkdir -p $(@D)
	$(V)$(NCC) $(NATIVE_CFLAGS) -o $(OBJDIR)/fs/fsformat fs/fsformat.c

$(OBJDIR)/fs/clean-fs.img: $(OBJDIR)/fs/fsformat $(FSIMGFILES)
	@echo + mk $(OBJDIR)/fs/clean-fs.img
	$(V)mkdir -p $(@D)
	$(V)$(OBJDIR)/fs/fsformat $(OBJDIR)/fs/clean-fs.img 1024 $(FSIMGFILES)

$(OBJDIR)/fs/fs.img: $(OBJDIR)/fs/clean-fs.img
	@echo + cp $(OBJDIR)/fs/clean-fs.img $@
	$(V)cp $(OBJDIR)/fs/clean-fs.img $@

all: $(OBJDIR)/fs/fs.img

#all: $(addsuffix .sym, $(USERAPPS))

#all: $(addsuffix .asm, $(USERAPPS))

```

First at line 41, we can find files in the image include text files like `lorem` and executable files like `echo`. The text files are already under fs directory in the source code and the executable files are compiled from the user program under user directory in the source code.

```Makefile
FSIMGFILES := $(FSIMGTXTFILES) $(USERAPPS)
```

At line 48, we can see that the file system server is linked as `obj/fs/fs`
```Makefile
$(OBJDIR)/fs/fs: $(FSOFILES) $(OBJDIR)/lib/entry.o $(OBJDIR)/lib/libjos.a user/user.ld
```

At line 62, we generate `obj/fs/clean-fs.img` using the program `obj/fs/fsformat` and finally copy it to `obj/fs/fs.img`. this is the instruction
```Makefile
	$(V)$(OBJDIR)/fs/fsformat $(OBJDIR)/fs/clean-fs.img 1024 $(FSIMGFILES)
```

See how `fsformat` works
```c
int
main(int argc, char **argv)
{
	int i;
	char *s;
	struct Dir root;

	assert(BLKSIZE % sizeof(struct File) == 0);

	if (argc < 3)
		usage();

	nblocks = strtol(argv[2], &s, 0);
	if (*s || s == argv[2] || nblocks < 2 || nblocks > 1024)
		usage();

	opendisk(argv[1]);

	startdir(&super->s_root, &root);
	for (i = 3; i < argc; i++)
		writefile(&root, argv[i]);
	finishdir(&root);

	finishdisk();
	return 0;
}
```
We can see that it do the following things
- using `opendisk` to create a disk file and initialize the super block
- using `startdir` to create the root directory
- using `writefile` to write object files to disk image
- using `finishdir` to write root directory to disk image
- using `finishdisk` to mark all bitmap in-use and finish the disk-creating work.

Actually the fs.img is 1024*4k = 4M bytes as have said above.


### The Block Bitmap

**Exercise 3**
---
> Use `free_block` as a model to implement `alloc_block`, which should find a free disk block in the bitmap, mark it used, and return the number of that block. 

```c
int
alloc_block(void)
{
	int bitmap_block_size = (super->s_nblocks + BLKBITSIZE - 1)/ BLKBITSIZE; 
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

Up to now, we have understand how `fs/fs.c` realize functions like `file_open` and `file_read`. This is the base of the file system server. It's to dive into the `fs/serv.c`

After set `IOPL` bit, we should go to `serve_init` first. Then we initialize the file system using `fs_init` we have talk above. Actually the file system is already OK when we format the fs.img. We do in fs_init is to read it from disk to memory.

Here is the code of `serve_init`
```c
void
serve_init(void)
{
	int i;
	uintptr_t va = FILEVA;
	for (i = 0; i < MAXOPEN; i++) {
		opentab[i].o_fileid = i;
		opentab[i].o_fd = (struct Fd*) va;
		va += PGSIZE;
	}
}
```

Apparently, we just initialize the `opentab` here. What is it?

```c
struct OpenFile {
	uint32_t o_fileid;	// file id
	struct File *o_file;	// mapped descriptor for open file
	int o_mode;		// open mode
	struct Fd *o_fd;	// Fd page
};

// Max number of open files in the file system at once
#define MAXOPEN		1024
#define FILEVA		0xD0000000

// initialize to force into data section
struct OpenFile opentab[MAXOPEN] = {
	{ 0, 0, 1, 0 }
};

// Virtual address at which to receive page mappings containing client requests.
union Fsipc *fsreq = (union Fsipc *)0x0ffff000;
```

The struct `OpenFile` maintain the open file information. And `opentab` is stored in the data section for the file system enviroment. Each opened real file `o_file` has a corresponding the user client discriptor `o_fd`. The struct Fd of each opened file are mapped to a page above `FILEVA`. The server and client all share this page. Client and Server use `o_fileid` to refer to the file to be operated on.

**How client side works?**
---
The user enviroment user `inc/lib.h` to access all the function to operate on file.
```c
// fd.c
int	close(int fd);
ssize_t	read(int fd, void *buf, size_t nbytes);
ssize_t	write(int fd, const void *buf, size_t nbytes);
int	seek(int fd, off_t offset);
void	close_all(void);
ssize_t	readn(int fd, void *buf, size_t nbytes);
int	dup(int oldfd, int newfd);
int	fstat(int fd, struct Stat *statbuf);
int	stat(const char *path, struct Stat *statbuf);

// file.c
int	open(const char *path, int mode);
int	ftruncate(int fd, off_t size);
int	remove(const char *path);
int	sync(void);
```
And these some important structs in `inc/fd.h`
```c
// Per-device-class file descriptor operations
struct Dev {
	int dev_id;
	const char *dev_name;
	ssize_t (*dev_read)(struct Fd *fd, void *buf, size_t len);
	ssize_t (*dev_write)(struct Fd *fd, const void *buf, size_t len);
	int (*dev_close)(struct Fd *fd);
	int (*dev_stat)(struct Fd *fd, struct Stat *stat);
	int (*dev_trunc)(struct Fd *fd, off_t length);
};

struct FdFile {
	int id;
};

struct Fd {
	int fd_dev_id;
	off_t fd_offset;
	int fd_omode;
	union {
		// File server files
		struct FdFile fd_file;
	};
};

struct Stat {
	char st_name[MAXNAMELEN];
	off_t st_size;
	int st_isdir;
	struct Dev *st_dev;
};
```
Taking `open` in file.c for an example.
```c
int
open(const char *path, int mode)
{
	int r;
	struct Fd *fd;

	if (strlen(path) >= MAXPATHLEN)
		return -E_BAD_PATH;

	if ((r = fd_alloc(&fd)) < 0)
		return r;

	strcpy(fsipcbuf.open.req_path, path);
	fsipcbuf.open.req_omode = mode;

	if ((r = fsipc(FSREQ_OPEN, fd)) < 0) {
		fd_close(fd, 0);
		return r;
	}

	return fd2num(fd);
}
```
First we find an unused file descriptor page using `fd_alloc`. Then send a file-open request to the file server. How can we send request ?
```c
union Fsipc fsipcbuf __attribute__((aligned(PGSIZE)));
```
fsipcbuf is a union and we store request like `path` and `mode` in it. See `Fsipc` in inc/fs.h
```c
union Fsipc {
	struct Fsreq_open {
		char req_path[MAXPATHLEN];
		int req_omode;
	} open;
	struct Fsreq_set_size {
		int req_fileid;
		off_t req_size;
	} set_size;
	struct Fsreq_read {
		int req_fileid;
		size_t req_n;
	} read;
	struct Fsret_read {
		char ret_buf[PGSIZE];
	} readRet;
	struct Fsreq_write {
		int req_fileid;
		size_t req_n;
		char req_buf[PGSIZE - (sizeof(int) + sizeof(size_t))];
	} write;
	struct Fsreq_stat {
		int req_fileid;
	} stat;
	struct Fsret_stat {
		char ret_name[MAXNAMELEN];
		off_t ret_size;
		int ret_isdir;
	} statRet;
	struct Fsreq_flush {
		int req_fileid;
	} flush;
	struct Fsreq_remove {
		char req_path[MAXPATHLEN];
	} remove;

	// Ensure Fsipc is one page
	char _pad[PGSIZE];
};
```
Then we call `fsipc` to send the request
```c
static int
fsipc(unsigned type, void *dstva)
{
	static envid_t fsenv;
	if (fsenv == 0)
		fsenv = ipc_find_env(ENV_TYPE_FS);

	static_assert(sizeof(fsipcbuf) == PGSIZE);

	if (debug)
		cprintf("[%08x] fsipc %d %08x\n", thisenv->env_id, type, *(uint32_t *)&fsipcbuf);

	ipc_send(fsenv, type, &fsipcbuf, PTE_P | PTE_W | PTE_U);
	return ipc_recv(NULL, dstva, NULL);
}
```
The request body should be in fsipcbuf, and parts of the response may be written back to fsipcbuf. Note that `dstva` is virtual address at which to receive reply page, 0 if none.

**How server side works**
---

```c
// Virtual address at which to receive page mappings containing client requests.
union Fsipc *fsreq = (union Fsipc *)0x0ffff000;
```

The server loop to wait for ipc request and deal with it. The request sent by client are mapped at `fsreq` and the server could resolve it directly from `fsreq` and request type `req`.
```c
void
serve(void)
{
	uint32_t req, whom;
	int perm, r;
	void *pg;

	while (1) {
		perm = 0;
		req = ipc_recv((int32_t *) &whom, fsreq, &perm);
		if (debug)
			cprintf("fs req %d from %08x [page %08x: %s]\n",
				req, whom, uvpt[PGNUM(fsreq)], fsreq);

		// All requests must contain an argument page
		if (!(perm & PTE_P)) {
			cprintf("Invalid request from %08x: no argument page\n",
				whom);
			continue; // just leave it hanging...
		}

		pg = NULL;
		if (req == FSREQ_OPEN) {
			r = serve_open(whom, (struct Fsreq_open*)fsreq, &pg, &perm);
		} else if (req < NHANDLERS && handlers[req]) {
			r = handlers[req](whom, fsreq);
		} else {
			cprintf("Invalid request code %d from %08x\n", req, whom);
			r = -E_INVAL;
		}
		ipc_send(whom, r, pg, perm);
		sys_page_unmap(0, fsreq);
	}
}
```

`FSREQ_OPEN` is dealt with `serve_open`, others are handlerd by handlers
```c
typedef int (*fshandler)(envid_t envid, union Fsipc *req);

fshandler handlers[] = {
	// Open is handled specially because it passes pages
	/* [FSREQ_OPEN] =	(fshandler)serve_open, */
	[FSREQ_READ] =		serve_read,
	[FSREQ_STAT] =		serve_stat,
	[FSREQ_FLUSH] =		(fshandler)serve_flush,
	[FSREQ_WRITE] =		(fshandler)serve_write,
	[FSREQ_SET_SIZE] =	(fshandler)serve_set_size,
	[FSREQ_SYNC] =		serve_sync
};
#define NHANDLERS (sizeof(handlers)/sizeof(handlers[0]))
```

As for `read` function in lib/fd.c, It is a little different but almost the same. We need to know the `Dev` struct
```c
struct Dev {
	int dev_id;
	const char *dev_name;
	ssize_t (*dev_read)(struct Fd *fd, void *buf, size_t len);
	ssize_t (*dev_write)(struct Fd *fd, const void *buf, size_t len);
	int (*dev_close)(struct Fd *fd);
	int (*dev_stat)(struct Fd *fd, struct Stat *stat);
	int (*dev_trunc)(struct Fd *fd, off_t length);
};
```
We difine 3 dev structs in lib/file.c, lib/pipe.c and lib/console.c
```c
struct Dev devfile =
{
	.dev_id =	'f',
	.dev_name =	"file",
	.dev_read =	devfile_read,
	.dev_close =	devfile_flush,
	.dev_stat =	devfile_stat,
	.dev_write =	devfile_write,
	.dev_trunc =	devfile_trunc
};

struct Dev devpipe =
{
	.dev_id =	'p',
	.dev_name =	"pipe",
	.dev_read =	devpipe_read,
	.dev_write =	devpipe_write,
	.dev_close =	devpipe_close,
	.dev_stat =	devpipe_stat,
};

struct Dev devcons =
{
	.dev_id =	'c',
	.dev_name =	"cons",
	.dev_read =	devcons_read,
	.dev_write =	devcons_write,
	.dev_close =	devcons_close,
	.dev_stat =	devcons_stat
};
```
And we have a device table in `lib/fd.c`
```c
static struct Dev *devtab[] =
{
	&devfile,
	&devpipe,
	&devcons,
	0
};
```

Actually lib/fd.c supply serials of functions like `read`, `write` as comman interface, it then call dev*_read corresponding to different device.
```c
ssize_t
read(int fdnum, void *buf, size_t n)
{
	int r;
	struct Dev *dev;
	struct Fd *fd;

	if ((r = fd_lookup(fdnum, &fd)) < 0
	    || (r = dev_lookup(fd->fd_dev_id, &dev)) < 0)
		return r;
	if ((fd->fd_omode & O_ACCMODE) == O_WRONLY) {
		cprintf("[%08x] read %d -- bad mode\n", thisenv->env_id, fdnum);
		return -E_INVAL;
	}
	if (!dev->dev_read)
		return -E_NOT_SUPP;
	return (*dev->dev_read)(fd, buf, n);
}
```
For example, in read, we find the `fd` and `dev` pointer corresponding to the `fdnum`, then we call `dev_read`. If the device is devfile, we call `devfile_read` which use ipc to send request to server.
```c
static ssize_t
devfile_read(struct Fd *fd, void *buf, size_t n)
{
	// Make an FSREQ_READ request to the file system server after
	// filling fsipcbuf.read with the request arguments.  The
	// bytes read will be written back to fsipcbuf by the file
	// system server.
	int r;

	fsipcbuf.read.req_fileid = fd->fd_file.id;
	fsipcbuf.read.req_n = n;
	if ((r = fsipc(FSREQ_READ, NULL)) < 0)
		return r;
	assert(r <= n);
	assert(r <= PGSIZE);
	memmove(buf, fsipcbuf.readRet.ret_buf, r);
	return r;
}
```

Till now, we finally understand how the C/S framework works!
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
> Implement `sys_env_set_trapframeq` in kernel/syscall.c 

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

```c
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	void* addr = (void *)(pn * PGSIZE);
	if (uvpt[pn] & PTE_SHARE)
	{
		r = sys_page_map(0, addr, envid, addr, uvpt[pn]&PTE_SYSCALL);
		if (r < 0)
			return r;
	}
	else if((uvpt[pn] & PTE_COW) || (uvpt[pn] & PTE_W))
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
> implement `copy_shared_pages` in lib/spawn.c

```c
static int
copy_shared_pages(envid_t child)
{
	// LAB 5: Your code here.
	uint32_t addr;
	int r;
	for (addr = 0; addr < USTACKTOP; addr += PGSIZE)
		if((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_SHARE))
			if ((r = sys_page_map(0, (void *)addr, child, (void *)addr, uvpt[PGNUM(addr)]&PTE_SYSCALL)) < 0)
				return r;
	return 0;
}
```

## The keyboard interface

**Exercise 9**
---
> In your kern/trap.c, call `kbd_intr` to handle trap `IRQ_OFFSET+IRQ_KBD` and `serial_intr` to handle trap `IRQ_OFFSET+IRQ_SERIAL`

It's simple to add lines in kern/trap.c
```c
	// Handle keyboard and serial interrupts.
	// LAB 5: Your code here.
	case IRQ_OFFSET + IRQ_KBD:
		lapic_eoi();
		kbd_intr();
		return;
	case IRQ_OFFSET + IRQ_SERIAL:
		lapic_eoi();
		serial_intr();
```
## The Shell

**Exercise 10**
---
> Add I/O redirection for < to user/sh.c

It's easy to add lines.
```c
	// LAB 5: Your code here.
	if ((fd = open(t, O_RDONLY)) < 0) {
		cprintf("open %s for read: %e", t, fd);
		exit();
	}
	if (fd != 0) {
		dup(fd, 0);
		close(fd);
	}
```

## This completes the lab






