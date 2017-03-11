
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 74 49 11 f0       	mov    $0xf0114974,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 cf 20 00 00       	call   f010212c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 74 04 00 00       	call   f01004d6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 25 10 f0       	push   $0xf01025c0
f010006f:	e8 c9 15 00 00       	call   f010163d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 20 0e 00 00       	call   f0100e99 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 30 07 00 00       	call   f01007b6 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 49 11 f0 00 	cmpl   $0x0,0xf0114960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 49 11 f0    	mov    %esi,0xf0114960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 db 25 10 f0       	push   $0xf01025db
f01000b5:	e8 83 15 00 00       	call   f010163d <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 53 15 00 00       	call   f0101617 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 17 26 10 f0 	movl   $0xf0102617,(%esp)
f01000cb:	e8 6d 15 00 00       	call   f010163d <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 d9 06 00 00       	call   f01007b6 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 f3 25 10 f0       	push   $0xf01025f3
f01000f7:	e8 41 15 00 00       	call   f010163d <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 0f 15 00 00       	call   f0101617 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 17 26 10 f0 	movl   $0xf0102617,(%esp)
f010010f:	e8 29 15 00 00       	call   f010163d <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 60 27 10 f0 	movzbl -0xfefd8a0(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 60 27 10 f0 	movzbl -0xfefd8a0(%edx),%eax
f0100209:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f010020f:	0f b6 8a 60 26 10 f0 	movzbl -0xfefd9a0(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 40 26 10 f0 	mov    -0xfefd9c0(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 0d 26 10 f0       	push   $0xf010260d
f0100265:	e8 d3 13 00 00       	call   f010163d <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 0c             	sub    $0xc,%esp
f0100292:	89 c6                	mov    %eax,%esi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 fa                	mov    %edi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002bd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c2:	89 f0                	mov    %esi,%eax
f01002c4:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c5:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ca:	bf 79 03 00 00       	mov    $0x379,%edi
f01002cf:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d4:	eb 09                	jmp    f01002df <cons_putc+0x56>
f01002d6:	89 ca                	mov    %ecx,%edx
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	ec                   	in     (%dx),%al
f01002da:	ec                   	in     (%dx),%al
f01002db:	ec                   	in     (%dx),%al
f01002dc:	83 c3 01             	add    $0x1,%ebx
f01002df:	89 fa                	mov    %edi,%edx
f01002e1:	ec                   	in     (%dx),%al
f01002e2:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002e8:	7f 04                	jg     f01002ee <cons_putc+0x65>
f01002ea:	84 c0                	test   %al,%al
f01002ec:	79 e8                	jns    f01002d6 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f3:	89 f0                	mov    %esi,%eax
f01002f5:	ee                   	out    %al,(%dx)
f01002f6:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01002fb:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100300:	ee                   	out    %al,(%dx)
f0100301:	b8 08 00 00 00       	mov    $0x8,%eax
f0100306:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c |= textcolor;
f0100307:	0b 35 64 49 11 f0    	or     0xf0114964,%esi
f010030d:	89 f2                	mov    %esi,%edx

//	if (!(c & ~0xFF))
//		c |= 0x0700;

	switch (c & 0xff) {
f010030f:	0f b6 c2             	movzbl %dl,%eax
f0100312:	83 f8 09             	cmp    $0x9,%eax
f0100315:	74 71                	je     f0100388 <cons_putc+0xff>
f0100317:	83 f8 09             	cmp    $0x9,%eax
f010031a:	7f 0a                	jg     f0100326 <cons_putc+0x9d>
f010031c:	83 f8 08             	cmp    $0x8,%eax
f010031f:	74 14                	je     f0100335 <cons_putc+0xac>
f0100321:	e9 96 00 00 00       	jmp    f01003bc <cons_putc+0x133>
f0100326:	83 f8 0a             	cmp    $0xa,%eax
f0100329:	74 37                	je     f0100362 <cons_putc+0xd9>
f010032b:	83 f8 0d             	cmp    $0xd,%eax
f010032e:	74 3a                	je     f010036a <cons_putc+0xe1>
f0100330:	e9 87 00 00 00       	jmp    f01003bc <cons_putc+0x133>
	case '\b':
		if (crt_pos > 0) {
f0100335:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010033c:	66 85 c0             	test   %ax,%ax
f010033f:	0f 84 e3 00 00 00    	je     f0100428 <cons_putc+0x19f>
			crt_pos--;
f0100345:	83 e8 01             	sub    $0x1,%eax
f0100348:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010034e:	0f b7 c0             	movzwl %ax,%eax
f0100351:	b2 00                	mov    $0x0,%dl
f0100353:	83 ca 20             	or     $0x20,%edx
f0100356:	8b 0d 2c 45 11 f0    	mov    0xf011452c,%ecx
f010035c:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100360:	eb 78                	jmp    f01003da <cons_putc+0x151>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100362:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f0100369:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010036a:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100371:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100377:	c1 e8 16             	shr    $0x16,%eax
f010037a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010037d:	c1 e0 04             	shl    $0x4,%eax
f0100380:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
f0100386:	eb 52                	jmp    f01003da <cons_putc+0x151>
		break;
	case '\t':
		cons_putc(' ');
f0100388:	b8 20 00 00 00       	mov    $0x20,%eax
f010038d:	e8 f7 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f0100392:	b8 20 00 00 00       	mov    $0x20,%eax
f0100397:	e8 ed fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
f01003ba:	eb 1e                	jmp    f01003da <cons_putc+0x151>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003bc:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003c3:	8d 48 01             	lea    0x1(%eax),%ecx
f01003c6:	66 89 0d 28 45 11 f0 	mov    %cx,0xf0114528
f01003cd:	0f b7 c0             	movzwl %ax,%eax
f01003d0:	8b 0d 2c 45 11 f0    	mov    0xf011452c,%ecx
f01003d6:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003da:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f01003e1:	cf 07 
f01003e3:	76 43                	jbe    f0100428 <cons_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003e5:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f01003ea:	83 ec 04             	sub    $0x4,%esp
f01003ed:	68 00 0f 00 00       	push   $0xf00
f01003f2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01003f8:	52                   	push   %edx
f01003f9:	50                   	push   %eax
f01003fa:	e8 7a 1d 00 00       	call   f0102179 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01003ff:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f0100405:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010040b:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100411:	83 c4 10             	add    $0x10,%esp
f0100414:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100419:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010041c:	39 d0                	cmp    %edx,%eax
f010041e:	75 f4                	jne    f0100414 <cons_putc+0x18b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100420:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f0100427:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100428:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f010042e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100433:	89 ca                	mov    %ecx,%edx
f0100435:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100436:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
f010043d:	8d 71 01             	lea    0x1(%ecx),%esi
f0100440:	89 d8                	mov    %ebx,%eax
f0100442:	66 c1 e8 08          	shr    $0x8,%ax
f0100446:	89 f2                	mov    %esi,%edx
f0100448:	ee                   	out    %al,(%dx)
f0100449:	b8 0f 00 00 00       	mov    $0xf,%eax
f010044e:	89 ca                	mov    %ecx,%edx
f0100450:	ee                   	out    %al,(%dx)
f0100451:	89 d8                	mov    %ebx,%eax
f0100453:	89 f2                	mov    %esi,%edx
f0100455:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100456:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100459:	5b                   	pop    %ebx
f010045a:	5e                   	pop    %esi
f010045b:	5f                   	pop    %edi
f010045c:	5d                   	pop    %ebp
f010045d:	c3                   	ret    

f010045e <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f010045e:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
f0100465:	74 11                	je     f0100478 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100467:	55                   	push   %ebp
f0100468:	89 e5                	mov    %esp,%ebp
f010046a:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010046d:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100472:	e8 c4 fc ff ff       	call   f010013b <cons_intr>
}
f0100477:	c9                   	leave  
f0100478:	f3 c3                	repz ret 

f010047a <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010047a:	55                   	push   %ebp
f010047b:	89 e5                	mov    %esp,%ebp
f010047d:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100480:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100485:	e8 b1 fc ff ff       	call   f010013b <cons_intr>
}
f010048a:	c9                   	leave  
f010048b:	c3                   	ret    

f010048c <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010048c:	55                   	push   %ebp
f010048d:	89 e5                	mov    %esp,%ebp
f010048f:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100492:	e8 c7 ff ff ff       	call   f010045e <serial_intr>
	kbd_intr();
f0100497:	e8 de ff ff ff       	call   f010047a <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010049c:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004a1:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004a7:	74 26                	je     f01004cf <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004a9:	8d 50 01             	lea    0x1(%eax),%edx
f01004ac:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004b2:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004b9:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004bb:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004c1:	75 11                	jne    f01004d4 <cons_getc+0x48>
			cons.rpos = 0;
f01004c3:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
f01004ca:	00 00 00 
f01004cd:	eb 05                	jmp    f01004d4 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004cf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004d4:	c9                   	leave  
f01004d5:	c3                   	ret    

f01004d6 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	57                   	push   %edi
f01004da:	56                   	push   %esi
f01004db:	53                   	push   %ebx
f01004dc:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004df:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004e6:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01004ed:	5a a5 
	if (*cp != 0xA55A) {
f01004ef:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01004f6:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01004fa:	74 11                	je     f010050d <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01004fc:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
f0100503:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100506:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010050b:	eb 16                	jmp    f0100523 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010050d:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100514:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
f010051b:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010051e:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100523:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
f0100529:	b8 0e 00 00 00       	mov    $0xe,%eax
f010052e:	89 fa                	mov    %edi,%edx
f0100530:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100531:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100534:	89 da                	mov    %ebx,%edx
f0100536:	ec                   	in     (%dx),%al
f0100537:	0f b6 c8             	movzbl %al,%ecx
f010053a:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010053d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100545:	89 da                	mov    %ebx,%edx
f0100547:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100548:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f010054e:	0f b6 c0             	movzbl %al,%eax
f0100551:	09 c8                	or     %ecx,%eax
f0100553:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100559:	be fa 03 00 00       	mov    $0x3fa,%esi
f010055e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100563:	89 f2                	mov    %esi,%edx
f0100565:	ee                   	out    %al,(%dx)
f0100566:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010056b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100570:	ee                   	out    %al,(%dx)
f0100571:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100576:	b8 0c 00 00 00       	mov    $0xc,%eax
f010057b:	89 da                	mov    %ebx,%edx
f010057d:	ee                   	out    %al,(%dx)
f010057e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100583:	b8 00 00 00 00       	mov    $0x0,%eax
f0100588:	ee                   	out    %al,(%dx)
f0100589:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100593:	ee                   	out    %al,(%dx)
f0100594:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100599:	b8 00 00 00 00       	mov    $0x0,%eax
f010059e:	ee                   	out    %al,(%dx)
f010059f:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a4:	b8 01 00 00 00       	mov    $0x1,%eax
f01005a9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005aa:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005af:	ec                   	in     (%dx),%al
f01005b0:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005b2:	3c ff                	cmp    $0xff,%al
f01005b4:	0f 95 05 34 45 11 f0 	setne  0xf0114534
f01005bb:	89 f2                	mov    %esi,%edx
f01005bd:	ec                   	in     (%dx),%al
f01005be:	89 da                	mov    %ebx,%edx
f01005c0:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005c1:	80 f9 ff             	cmp    $0xff,%cl
f01005c4:	75 10                	jne    f01005d6 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005c6:	83 ec 0c             	sub    $0xc,%esp
f01005c9:	68 19 26 10 f0       	push   $0xf0102619
f01005ce:	e8 6a 10 00 00       	call   f010163d <cprintf>
f01005d3:	83 c4 10             	add    $0x10,%esp
}
f01005d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005d9:	5b                   	pop    %ebx
f01005da:	5e                   	pop    %esi
f01005db:	5f                   	pop    %edi
f01005dc:	5d                   	pop    %ebp
f01005dd:	c3                   	ret    

f01005de <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005de:	55                   	push   %ebp
f01005df:	89 e5                	mov    %esp,%ebp
f01005e1:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01005e7:	e8 9d fc ff ff       	call   f0100289 <cons_putc>
}
f01005ec:	c9                   	leave  
f01005ed:	c3                   	ret    

f01005ee <getchar>:

int
getchar(void)
{
f01005ee:	55                   	push   %ebp
f01005ef:	89 e5                	mov    %esp,%ebp
f01005f1:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005f4:	e8 93 fe ff ff       	call   f010048c <cons_getc>
f01005f9:	85 c0                	test   %eax,%eax
f01005fb:	74 f7                	je     f01005f4 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01005fd:	c9                   	leave  
f01005fe:	c3                   	ret    

f01005ff <iscons>:

int
iscons(int fdnum)
{
f01005ff:	55                   	push   %ebp
f0100600:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100602:	b8 01 00 00 00       	mov    $0x1,%eax
f0100607:	5d                   	pop    %ebp
f0100608:	c3                   	ret    

f0100609 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100609:	55                   	push   %ebp
f010060a:	89 e5                	mov    %esp,%ebp
f010060c:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010060f:	68 60 28 10 f0       	push   $0xf0102860
f0100614:	68 7e 28 10 f0       	push   $0xf010287e
f0100619:	68 83 28 10 f0       	push   $0xf0102883
f010061e:	e8 1a 10 00 00       	call   f010163d <cprintf>
f0100623:	83 c4 0c             	add    $0xc,%esp
f0100626:	68 54 29 10 f0       	push   $0xf0102954
f010062b:	68 8c 28 10 f0       	push   $0xf010288c
f0100630:	68 83 28 10 f0       	push   $0xf0102883
f0100635:	e8 03 10 00 00       	call   f010163d <cprintf>
f010063a:	83 c4 0c             	add    $0xc,%esp
f010063d:	68 7c 29 10 f0       	push   $0xf010297c
f0100642:	68 95 28 10 f0       	push   $0xf0102895
f0100647:	68 83 28 10 f0       	push   $0xf0102883
f010064c:	e8 ec 0f 00 00       	call   f010163d <cprintf>
	return 0;
}
f0100651:	b8 00 00 00 00       	mov    $0x0,%eax
f0100656:	c9                   	leave  
f0100657:	c3                   	ret    

f0100658 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100658:	55                   	push   %ebp
f0100659:	89 e5                	mov    %esp,%ebp
f010065b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010065e:	68 9f 28 10 f0       	push   $0xf010289f
f0100663:	e8 d5 0f 00 00       	call   f010163d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100668:	83 c4 08             	add    $0x8,%esp
f010066b:	68 0c 00 10 00       	push   $0x10000c
f0100670:	68 e4 29 10 f0       	push   $0xf01029e4
f0100675:	e8 c3 0f 00 00       	call   f010163d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010067a:	83 c4 0c             	add    $0xc,%esp
f010067d:	68 0c 00 10 00       	push   $0x10000c
f0100682:	68 0c 00 10 f0       	push   $0xf010000c
f0100687:	68 0c 2a 10 f0       	push   $0xf0102a0c
f010068c:	e8 ac 0f 00 00       	call   f010163d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100691:	83 c4 0c             	add    $0xc,%esp
f0100694:	68 b1 25 10 00       	push   $0x1025b1
f0100699:	68 b1 25 10 f0       	push   $0xf01025b1
f010069e:	68 30 2a 10 f0       	push   $0xf0102a30
f01006a3:	e8 95 0f 00 00       	call   f010163d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a8:	83 c4 0c             	add    $0xc,%esp
f01006ab:	68 00 43 11 00       	push   $0x114300
f01006b0:	68 00 43 11 f0       	push   $0xf0114300
f01006b5:	68 54 2a 10 f0       	push   $0xf0102a54
f01006ba:	e8 7e 0f 00 00       	call   f010163d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bf:	83 c4 0c             	add    $0xc,%esp
f01006c2:	68 74 49 11 00       	push   $0x114974
f01006c7:	68 74 49 11 f0       	push   $0xf0114974
f01006cc:	68 78 2a 10 f0       	push   $0xf0102a78
f01006d1:	e8 67 0f 00 00       	call   f010163d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d6:	b8 73 4d 11 f0       	mov    $0xf0114d73,%eax
f01006db:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006e0:	83 c4 08             	add    $0x8,%esp
f01006e3:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006e8:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006ee:	85 c0                	test   %eax,%eax
f01006f0:	0f 48 c2             	cmovs  %edx,%eax
f01006f3:	c1 f8 0a             	sar    $0xa,%eax
f01006f6:	50                   	push   %eax
f01006f7:	68 9c 2a 10 f0       	push   $0xf0102a9c
f01006fc:	e8 3c 0f 00 00       	call   f010163d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100701:	b8 00 00 00 00       	mov    $0x0,%eax
f0100706:	c9                   	leave  
f0100707:	c3                   	ret    

f0100708 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100708:	55                   	push   %ebp
f0100709:	89 e5                	mov    %esp,%ebp
f010070b:	57                   	push   %edi
f010070c:	56                   	push   %esi
f010070d:	53                   	push   %ebx
f010070e:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100711:	89 ee                	mov    %ebp,%esi
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");
f0100713:	68 b8 28 10 f0       	push   $0xf01028b8
f0100718:	e8 20 0f 00 00       	call   f010163d <cprintf>

	while(ebp) {
f010071d:	83 c4 10             	add    $0x10,%esp
f0100720:	eb 7f                	jmp    f01007a1 <mon_backtrace+0x99>
		cprintf("ebp %08x ", ebp);
f0100722:	83 ec 08             	sub    $0x8,%esp
f0100725:	56                   	push   %esi
f0100726:	68 ca 28 10 f0       	push   $0xf01028ca
f010072b:	e8 0d 0f 00 00       	call   f010163d <cprintf>
		cprintf("eip %08x args", ebp[1]);
f0100730:	83 c4 08             	add    $0x8,%esp
f0100733:	ff 76 04             	pushl  0x4(%esi)
f0100736:	68 d4 28 10 f0       	push   $0xf01028d4
f010073b:	e8 fd 0e 00 00       	call   f010163d <cprintf>
f0100740:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100743:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100746:	83 c4 10             	add    $0x10,%esp
		for(int i = 2; i <= 6; i++)
			cprintf(" %08x", ebp[i]);
f0100749:	83 ec 08             	sub    $0x8,%esp
f010074c:	ff 33                	pushl  (%ebx)
f010074e:	68 e2 28 10 f0       	push   $0xf01028e2
f0100753:	e8 e5 0e 00 00       	call   f010163d <cprintf>
f0100758:	83 c3 04             	add    $0x4,%ebx
	cprintf("Stack backtrace:\n");

	while(ebp) {
		cprintf("ebp %08x ", ebp);
		cprintf("eip %08x args", ebp[1]);
		for(int i = 2; i <= 6; i++)
f010075b:	83 c4 10             	add    $0x10,%esp
f010075e:	39 fb                	cmp    %edi,%ebx
f0100760:	75 e7                	jne    f0100749 <mon_backtrace+0x41>
			cprintf(" %08x", ebp[i]);
		cprintf("\n");
f0100762:	83 ec 0c             	sub    $0xc,%esp
f0100765:	68 17 26 10 f0       	push   $0xf0102617
f010076a:	e8 ce 0e 00 00       	call   f010163d <cprintf>

		unsigned int eip = ebp[1];
f010076f:	8b 5e 04             	mov    0x4(%esi),%ebx
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100772:	83 c4 08             	add    $0x8,%esp
f0100775:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100778:	50                   	push   %eax
f0100779:	53                   	push   %ebx
f010077a:	e8 c8 0f 00 00       	call   f0101747 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f010077f:	83 c4 08             	add    $0x8,%esp
f0100782:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f0100785:	53                   	push   %ebx
f0100786:	ff 75 d8             	pushl  -0x28(%ebp)
f0100789:	ff 75 dc             	pushl  -0x24(%ebp)
f010078c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010078f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100792:	68 e8 28 10 f0       	push   $0xf01028e8
f0100797:	e8 a1 0e 00 00       	call   f010163d <cprintf>
		info.eip_file, info.eip_line,
		info.eip_fn_namelen, info.eip_fn_name,
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
f010079c:	8b 36                	mov    (%esi),%esi
f010079e:	83 c4 20             	add    $0x20,%esp
{
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");

	while(ebp) {
f01007a1:	85 f6                	test   %esi,%esi
f01007a3:	0f 85 79 ff ff ff    	jne    f0100722 <mon_backtrace+0x1a>
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
	}
	return 0;
}
f01007a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007b1:	5b                   	pop    %ebx
f01007b2:	5e                   	pop    %esi
f01007b3:	5f                   	pop    %edi
f01007b4:	5d                   	pop    %ebp
f01007b5:	c3                   	ret    

f01007b6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007b6:	55                   	push   %ebp
f01007b7:	89 e5                	mov    %esp,%ebp
f01007b9:	57                   	push   %edi
f01007ba:	56                   	push   %esi
f01007bb:	53                   	push   %ebx
f01007bc:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007bf:	68 c8 2a 10 f0       	push   $0xf0102ac8
f01007c4:	e8 74 0e 00 00       	call   f010163d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007c9:	c7 04 24 ec 2a 10 f0 	movl   $0xf0102aec,(%esp)
f01007d0:	e8 68 0e 00 00       	call   f010163d <cprintf>
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");
f01007d5:	83 c4 0c             	add    $0xc,%esp
f01007d8:	68 f9 28 10 f0       	push   $0xf01028f9
f01007dd:	68 00 04 00 00       	push   $0x400
f01007e2:	68 fd 28 10 f0       	push   $0xf01028fd
f01007e7:	68 00 02 00 00       	push   $0x200
f01007ec:	68 03 29 10 f0       	push   $0xf0102903
f01007f1:	68 00 01 00 00       	push   $0x100
f01007f6:	68 08 29 10 f0       	push   $0xf0102908
f01007fb:	e8 3d 0e 00 00       	call   f010163d <cprintf>
f0100800:	83 c4 20             	add    $0x20,%esp

	while (1) {
		buf = readline("K> ");
f0100803:	83 ec 0c             	sub    $0xc,%esp
f0100806:	68 18 29 10 f0       	push   $0xf0102918
f010080b:	e8 c5 16 00 00       	call   f0101ed5 <readline>
f0100810:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100812:	83 c4 10             	add    $0x10,%esp
f0100815:	85 c0                	test   %eax,%eax
f0100817:	74 ea                	je     f0100803 <monitor+0x4d>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100819:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100820:	be 00 00 00 00       	mov    $0x0,%esi
f0100825:	eb 0a                	jmp    f0100831 <monitor+0x7b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100827:	c6 03 00             	movb   $0x0,(%ebx)
f010082a:	89 f7                	mov    %esi,%edi
f010082c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010082f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100831:	0f b6 03             	movzbl (%ebx),%eax
f0100834:	84 c0                	test   %al,%al
f0100836:	74 63                	je     f010089b <monitor+0xe5>
f0100838:	83 ec 08             	sub    $0x8,%esp
f010083b:	0f be c0             	movsbl %al,%eax
f010083e:	50                   	push   %eax
f010083f:	68 1c 29 10 f0       	push   $0xf010291c
f0100844:	e8 a6 18 00 00       	call   f01020ef <strchr>
f0100849:	83 c4 10             	add    $0x10,%esp
f010084c:	85 c0                	test   %eax,%eax
f010084e:	75 d7                	jne    f0100827 <monitor+0x71>
			*buf++ = 0;
		if (*buf == 0)
f0100850:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100853:	74 46                	je     f010089b <monitor+0xe5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100855:	83 fe 0f             	cmp    $0xf,%esi
f0100858:	75 14                	jne    f010086e <monitor+0xb8>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010085a:	83 ec 08             	sub    $0x8,%esp
f010085d:	6a 10                	push   $0x10
f010085f:	68 21 29 10 f0       	push   $0xf0102921
f0100864:	e8 d4 0d 00 00       	call   f010163d <cprintf>
f0100869:	83 c4 10             	add    $0x10,%esp
f010086c:	eb 95                	jmp    f0100803 <monitor+0x4d>
			return 0;
		}
		argv[argc++] = buf;
f010086e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100871:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100875:	eb 03                	jmp    f010087a <monitor+0xc4>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100877:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010087a:	0f b6 03             	movzbl (%ebx),%eax
f010087d:	84 c0                	test   %al,%al
f010087f:	74 ae                	je     f010082f <monitor+0x79>
f0100881:	83 ec 08             	sub    $0x8,%esp
f0100884:	0f be c0             	movsbl %al,%eax
f0100887:	50                   	push   %eax
f0100888:	68 1c 29 10 f0       	push   $0xf010291c
f010088d:	e8 5d 18 00 00       	call   f01020ef <strchr>
f0100892:	83 c4 10             	add    $0x10,%esp
f0100895:	85 c0                	test   %eax,%eax
f0100897:	74 de                	je     f0100877 <monitor+0xc1>
f0100899:	eb 94                	jmp    f010082f <monitor+0x79>
			buf++;
	}
	argv[argc] = 0;
f010089b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008a2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008a3:	85 f6                	test   %esi,%esi
f01008a5:	0f 84 58 ff ff ff    	je     f0100803 <monitor+0x4d>
f01008ab:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b0:	83 ec 08             	sub    $0x8,%esp
f01008b3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008b6:	ff 34 85 20 2b 10 f0 	pushl  -0xfefd4e0(,%eax,4)
f01008bd:	ff 75 a8             	pushl  -0x58(%ebp)
f01008c0:	e8 cc 17 00 00       	call   f0102091 <strcmp>
f01008c5:	83 c4 10             	add    $0x10,%esp
f01008c8:	85 c0                	test   %eax,%eax
f01008ca:	75 21                	jne    f01008ed <monitor+0x137>
			return commands[i].func(argc, argv, tf);
f01008cc:	83 ec 04             	sub    $0x4,%esp
f01008cf:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008d2:	ff 75 08             	pushl  0x8(%ebp)
f01008d5:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008d8:	52                   	push   %edx
f01008d9:	56                   	push   %esi
f01008da:	ff 14 85 28 2b 10 f0 	call   *-0xfefd4d8(,%eax,4)
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008e1:	83 c4 10             	add    $0x10,%esp
f01008e4:	85 c0                	test   %eax,%eax
f01008e6:	78 25                	js     f010090d <monitor+0x157>
f01008e8:	e9 16 ff ff ff       	jmp    f0100803 <monitor+0x4d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008ed:	83 c3 01             	add    $0x1,%ebx
f01008f0:	83 fb 03             	cmp    $0x3,%ebx
f01008f3:	75 bb                	jne    f01008b0 <monitor+0xfa>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008f5:	83 ec 08             	sub    $0x8,%esp
f01008f8:	ff 75 a8             	pushl  -0x58(%ebp)
f01008fb:	68 3e 29 10 f0       	push   $0xf010293e
f0100900:	e8 38 0d 00 00       	call   f010163d <cprintf>
f0100905:	83 c4 10             	add    $0x10,%esp
f0100908:	e9 f6 fe ff ff       	jmp    f0100803 <monitor+0x4d>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010090d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100910:	5b                   	pop    %ebx
f0100911:	5e                   	pop    %esi
f0100912:	5f                   	pop    %edi
f0100913:	5d                   	pop    %ebp
f0100914:	c3                   	ret    

f0100915 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100915:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f010091c:	75 60                	jne    f010097e <boot_alloc+0x69>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010091e:	ba 73 59 11 f0       	mov    $0xf0115973,%edx
f0100923:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100929:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0) {
f010092f:	85 c0                	test   %eax,%eax
f0100931:	74 42                	je     f0100975 <boot_alloc+0x60>
		result = nextfree;
f0100933:	8b 0d 38 45 11 f0    	mov    0xf0114538,%ecx
		nextfree = ROUNDUP((char*)(nextfree+n), PGSIZE);
f0100939:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100940:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100946:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
		if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
f010094c:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100952:	a1 68 49 11 f0       	mov    0xf0114968,%eax
f0100957:	c1 e0 0c             	shl    $0xc,%eax
f010095a:	39 c2                	cmp    %eax,%edx
f010095c:	76 1d                	jbe    f010097b <boot_alloc+0x66>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010095e:	55                   	push   %ebp
f010095f:	89 e5                	mov    %esp,%ebp
f0100961:	83 ec 0c             	sub    $0xc,%esp
	// LAB 2: Your code here.
	if(n > 0) {
		result = nextfree;
		nextfree = ROUNDUP((char*)(nextfree+n), PGSIZE);
		if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
			panic("Out Of Memory!\n");
f0100964:	68 44 2b 10 f0       	push   $0xf0102b44
f0100969:	6a 6a                	push   $0x6a
f010096b:	68 54 2b 10 f0       	push   $0xf0102b54
f0100970:	e8 16 f7 ff ff       	call   f010008b <_panic>
//		cprintf("allocate %d bytes, update nextfree to %x\n", n, nextfree);
		return result;
	}
	else if(n == 0)
		return nextfree;
f0100975:	a1 38 45 11 f0       	mov    0xf0114538,%eax
f010097a:	c3                   	ret    
		result = nextfree;
		nextfree = ROUNDUP((char*)(nextfree+n), PGSIZE);
		if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
			panic("Out Of Memory!\n");
//		cprintf("allocate %d bytes, update nextfree to %x\n", n, nextfree);
		return result;
f010097b:	89 c8                	mov    %ecx,%eax
f010097d:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0) {
f010097e:	85 c0                	test   %eax,%eax
f0100980:	75 b1                	jne    f0100933 <boot_alloc+0x1e>
f0100982:	eb f1                	jmp    f0100975 <boot_alloc+0x60>

f0100984 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100984:	89 d1                	mov    %edx,%ecx
f0100986:	c1 e9 16             	shr    $0x16,%ecx
f0100989:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010098c:	a8 01                	test   $0x1,%al
f010098e:	74 52                	je     f01009e2 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100990:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100995:	89 c1                	mov    %eax,%ecx
f0100997:	c1 e9 0c             	shr    $0xc,%ecx
f010099a:	3b 0d 68 49 11 f0    	cmp    0xf0114968,%ecx
f01009a0:	72 1b                	jb     f01009bd <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009a2:	55                   	push   %ebp
f01009a3:	89 e5                	mov    %esp,%ebp
f01009a5:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009a8:	50                   	push   %eax
f01009a9:	68 8c 2d 10 f0       	push   $0xf0102d8c
f01009ae:	68 b7 02 00 00       	push   $0x2b7
f01009b3:	68 54 2b 10 f0       	push   $0xf0102b54
f01009b8:	e8 ce f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009bd:	c1 ea 0c             	shr    $0xc,%edx
f01009c0:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009c6:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009cd:	89 c2                	mov    %eax,%edx
f01009cf:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009d2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009d7:	85 d2                	test   %edx,%edx
f01009d9:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009de:	0f 44 c2             	cmove  %edx,%eax
f01009e1:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009e7:	c3                   	ret    

f01009e8 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009e8:	55                   	push   %ebp
f01009e9:	89 e5                	mov    %esp,%ebp
f01009eb:	57                   	push   %edi
f01009ec:	56                   	push   %esi
f01009ed:	53                   	push   %ebx
f01009ee:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009f1:	84 c0                	test   %al,%al
f01009f3:	0f 85 c3 02 00 00    	jne    f0100cbc <check_page_free_list+0x2d4>
f01009f9:	e9 d0 02 00 00       	jmp    f0100cce <check_page_free_list+0x2e6>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;
//	cprintf("we now enter check_page_free_list, pdx_limit is %u, NPDENTRIES is %d\n", pdx_limit, NPDENTRIES);

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009fe:	83 ec 04             	sub    $0x4,%esp
f0100a01:	68 b0 2d 10 f0       	push   $0xf0102db0
f0100a06:	68 ec 01 00 00       	push   $0x1ec
f0100a0b:	68 54 2b 10 f0       	push   $0xf0102b54
f0100a10:	e8 76 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		cprintf("before hanling low memory question, page_free_list is %x now\n", page_free_list);
f0100a15:	83 ec 08             	sub    $0x8,%esp
f0100a18:	50                   	push   %eax
f0100a19:	68 d4 2d 10 f0       	push   $0xf0102dd4
f0100a1e:	e8 1a 0c 00 00       	call   f010163d <cprintf>
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a23:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100a26:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100a29:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100a2c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a2f:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100a34:	83 c4 10             	add    $0x10,%esp
f0100a37:	eb 20                	jmp    f0100a59 <check_page_free_list+0x71>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a39:	89 c2                	mov    %eax,%edx
f0100a3b:	2b 15 70 49 11 f0    	sub    0xf0114970,%edx
f0100a41:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a47:	0f 95 c2             	setne  %dl
f0100a4a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a4d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a51:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a53:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		cprintf("before hanling low memory question, page_free_list is %x now\n", page_free_list);
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a57:	8b 00                	mov    (%eax),%eax
f0100a59:	85 c0                	test   %eax,%eax
f0100a5b:	75 dc                	jne    f0100a39 <check_page_free_list+0x51>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a5d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a60:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a66:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a69:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a6c:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a6e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a71:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a76:	be 01 00 00 00       	mov    $0x1,%esi
		*tp[1] = 0;
		*tp[0] = pp2;
		page_free_list = pp1;
	}

	cprintf("after hanling low memory question, page_free_list is %x now\n", page_free_list);
f0100a7b:	83 ec 08             	sub    $0x8,%esp
f0100a7e:	ff 35 3c 45 11 f0    	pushl  0xf011453c
f0100a84:	68 14 2e 10 f0       	push   $0xf0102e14
f0100a89:	e8 af 0b 00 00       	call   f010163d <cprintf>
	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a8e:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100a94:	83 c4 10             	add    $0x10,%esp
f0100a97:	eb 53                	jmp    f0100aec <check_page_free_list+0x104>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a99:	89 d8                	mov    %ebx,%eax
f0100a9b:	2b 05 70 49 11 f0    	sub    0xf0114970,%eax
f0100aa1:	c1 f8 03             	sar    $0x3,%eax
f0100aa4:	c1 e0 0c             	shl    $0xc,%eax
	{
//		cprintf("we entered! CAUSES TROUBLE!!\n");
		if (PDX(page2pa(pp)) < pdx_limit)
f0100aa7:	89 c2                	mov    %eax,%edx
f0100aa9:	c1 ea 16             	shr    $0x16,%edx
f0100aac:	39 f2                	cmp    %esi,%edx
f0100aae:	73 3a                	jae    f0100aea <check_page_free_list+0x102>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ab0:	89 c2                	mov    %eax,%edx
f0100ab2:	c1 ea 0c             	shr    $0xc,%edx
f0100ab5:	3b 15 68 49 11 f0    	cmp    0xf0114968,%edx
f0100abb:	72 12                	jb     f0100acf <check_page_free_list+0xe7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100abd:	50                   	push   %eax
f0100abe:	68 8c 2d 10 f0       	push   $0xf0102d8c
f0100ac3:	6a 52                	push   $0x52
f0100ac5:	68 60 2b 10 f0       	push   $0xf0102b60
f0100aca:	e8 bc f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100acf:	83 ec 04             	sub    $0x4,%esp
f0100ad2:	68 80 00 00 00       	push   $0x80
f0100ad7:	68 97 00 00 00       	push   $0x97
f0100adc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ae1:	50                   	push   %eax
f0100ae2:	e8 45 16 00 00       	call   f010212c <memset>
f0100ae7:	83 c4 10             	add    $0x10,%esp
	}

	cprintf("after hanling low memory question, page_free_list is %x now\n", page_free_list);
	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aea:	8b 1b                	mov    (%ebx),%ebx
f0100aec:	85 db                	test   %ebx,%ebx
f0100aee:	75 a9                	jne    f0100a99 <check_page_free_list+0xb1>
//		cprintf("we entered! CAUSES TROUBLE!!\n");
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);
	}

	first_free_page = (char *) boot_alloc(0);
f0100af0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100af5:	e8 1b fe ff ff       	call   f0100915 <boot_alloc>
f0100afa:	89 45 cc             	mov    %eax,-0x34(%ebp)
	cprintf("first_free_page is %x\n", first_free_page);
f0100afd:	83 ec 08             	sub    $0x8,%esp
f0100b00:	50                   	push   %eax
f0100b01:	68 6e 2b 10 f0       	push   $0xf0102b6e
f0100b06:	e8 32 0b 00 00       	call   f010163d <cprintf>
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b0b:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b11:	8b 0d 70 49 11 f0    	mov    0xf0114970,%ecx
		assert(pp < pages + npages);
f0100b17:	a1 68 49 11 f0       	mov    0xf0114968,%eax
f0100b1c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b1f:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b22:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			memset(page2kva(pp), 0x97, 128);
	}

	first_free_page = (char *) boot_alloc(0);
	cprintf("first_free_page is %x\n", first_free_page);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b25:	83 c4 10             	add    $0x10,%esp
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b28:	be 00 00 00 00       	mov    $0x0,%esi
f0100b2d:	89 5d d0             	mov    %ebx,-0x30(%ebp)
			memset(page2kva(pp), 0x97, 128);
	}

	first_free_page = (char *) boot_alloc(0);
	cprintf("first_free_page is %x\n", first_free_page);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b30:	e9 30 01 00 00       	jmp    f0100c65 <check_page_free_list+0x27d>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b35:	39 ca                	cmp    %ecx,%edx
f0100b37:	73 19                	jae    f0100b52 <check_page_free_list+0x16a>
f0100b39:	68 85 2b 10 f0       	push   $0xf0102b85
f0100b3e:	68 91 2b 10 f0       	push   $0xf0102b91
f0100b43:	68 0c 02 00 00       	push   $0x20c
f0100b48:	68 54 2b 10 f0       	push   $0xf0102b54
f0100b4d:	e8 39 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b52:	39 fa                	cmp    %edi,%edx
f0100b54:	72 19                	jb     f0100b6f <check_page_free_list+0x187>
f0100b56:	68 a6 2b 10 f0       	push   $0xf0102ba6
f0100b5b:	68 91 2b 10 f0       	push   $0xf0102b91
f0100b60:	68 0d 02 00 00       	push   $0x20d
f0100b65:	68 54 2b 10 f0       	push   $0xf0102b54
f0100b6a:	e8 1c f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b6f:	89 d0                	mov    %edx,%eax
f0100b71:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b74:	a8 07                	test   $0x7,%al
f0100b76:	74 19                	je     f0100b91 <check_page_free_list+0x1a9>
f0100b78:	68 54 2e 10 f0       	push   $0xf0102e54
f0100b7d:	68 91 2b 10 f0       	push   $0xf0102b91
f0100b82:	68 0e 02 00 00       	push   $0x20e
f0100b87:	68 54 2b 10 f0       	push   $0xf0102b54
f0100b8c:	e8 fa f4 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b91:	c1 f8 03             	sar    $0x3,%eax
f0100b94:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b97:	85 c0                	test   %eax,%eax
f0100b99:	75 19                	jne    f0100bb4 <check_page_free_list+0x1cc>
f0100b9b:	68 ba 2b 10 f0       	push   $0xf0102bba
f0100ba0:	68 91 2b 10 f0       	push   $0xf0102b91
f0100ba5:	68 11 02 00 00       	push   $0x211
f0100baa:	68 54 2b 10 f0       	push   $0xf0102b54
f0100baf:	e8 d7 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bb4:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bb9:	75 19                	jne    f0100bd4 <check_page_free_list+0x1ec>
f0100bbb:	68 cb 2b 10 f0       	push   $0xf0102bcb
f0100bc0:	68 91 2b 10 f0       	push   $0xf0102b91
f0100bc5:	68 12 02 00 00       	push   $0x212
f0100bca:	68 54 2b 10 f0       	push   $0xf0102b54
f0100bcf:	e8 b7 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bd4:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bd9:	75 19                	jne    f0100bf4 <check_page_free_list+0x20c>
f0100bdb:	68 88 2e 10 f0       	push   $0xf0102e88
f0100be0:	68 91 2b 10 f0       	push   $0xf0102b91
f0100be5:	68 13 02 00 00       	push   $0x213
f0100bea:	68 54 2b 10 f0       	push   $0xf0102b54
f0100bef:	e8 97 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bf4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bf9:	75 19                	jne    f0100c14 <check_page_free_list+0x22c>
f0100bfb:	68 e4 2b 10 f0       	push   $0xf0102be4
f0100c00:	68 91 2b 10 f0       	push   $0xf0102b91
f0100c05:	68 14 02 00 00       	push   $0x214
f0100c0a:	68 54 2b 10 f0       	push   $0xf0102b54
f0100c0f:	e8 77 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c14:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c19:	76 3f                	jbe    f0100c5a <check_page_free_list+0x272>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c1b:	89 c3                	mov    %eax,%ebx
f0100c1d:	c1 eb 0c             	shr    $0xc,%ebx
f0100c20:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c23:	77 12                	ja     f0100c37 <check_page_free_list+0x24f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c25:	50                   	push   %eax
f0100c26:	68 8c 2d 10 f0       	push   $0xf0102d8c
f0100c2b:	6a 52                	push   $0x52
f0100c2d:	68 60 2b 10 f0       	push   $0xf0102b60
f0100c32:	e8 54 f4 ff ff       	call   f010008b <_panic>
f0100c37:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c3c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c3f:	76 1e                	jbe    f0100c5f <check_page_free_list+0x277>
f0100c41:	68 ac 2e 10 f0       	push   $0xf0102eac
f0100c46:	68 91 2b 10 f0       	push   $0xf0102b91
f0100c4b:	68 15 02 00 00       	push   $0x215
f0100c50:	68 54 2b 10 f0       	push   $0xf0102b54
f0100c55:	e8 31 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c5a:	83 c6 01             	add    $0x1,%esi
f0100c5d:	eb 04                	jmp    f0100c63 <check_page_free_list+0x27b>
		else
			++nfree_extmem;
f0100c5f:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
			memset(page2kva(pp), 0x97, 128);
	}

	first_free_page = (char *) boot_alloc(0);
	cprintf("first_free_page is %x\n", first_free_page);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c63:	8b 12                	mov    (%edx),%edx
f0100c65:	85 d2                	test   %edx,%edx
f0100c67:	0f 85 c8 fe ff ff    	jne    f0100b35 <check_page_free_list+0x14d>
f0100c6d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
		else
			++nfree_extmem;
	}
	cprintf("nfree_basemem is %d, nfree_extmem is %d\n", nfree_basemem, nfree_extmem);
f0100c70:	83 ec 04             	sub    $0x4,%esp
f0100c73:	53                   	push   %ebx
f0100c74:	56                   	push   %esi
f0100c75:	68 f4 2e 10 f0       	push   $0xf0102ef4
f0100c7a:	e8 be 09 00 00       	call   f010163d <cprintf>

	assert(nfree_basemem > 0);
f0100c7f:	83 c4 10             	add    $0x10,%esp
f0100c82:	85 f6                	test   %esi,%esi
f0100c84:	7f 19                	jg     f0100c9f <check_page_free_list+0x2b7>
f0100c86:	68 fe 2b 10 f0       	push   $0xf0102bfe
f0100c8b:	68 91 2b 10 f0       	push   $0xf0102b91
f0100c90:	68 1e 02 00 00       	push   $0x21e
f0100c95:	68 54 2b 10 f0       	push   $0xf0102b54
f0100c9a:	e8 ec f3 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c9f:	85 db                	test   %ebx,%ebx
f0100ca1:	7f 42                	jg     f0100ce5 <check_page_free_list+0x2fd>
f0100ca3:	68 10 2c 10 f0       	push   $0xf0102c10
f0100ca8:	68 91 2b 10 f0       	push   $0xf0102b91
f0100cad:	68 1f 02 00 00       	push   $0x21f
f0100cb2:	68 54 2b 10 f0       	push   $0xf0102b54
f0100cb7:	e8 cf f3 ff ff       	call   f010008b <_panic>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;
//	cprintf("we now enter check_page_free_list, pdx_limit is %u, NPDENTRIES is %d\n", pdx_limit, NPDENTRIES);

	if (!page_free_list)
f0100cbc:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100cc1:	85 c0                	test   %eax,%eax
f0100cc3:	0f 85 4c fd ff ff    	jne    f0100a15 <check_page_free_list+0x2d>
f0100cc9:	e9 30 fd ff ff       	jmp    f01009fe <check_page_free_list+0x16>
f0100cce:	83 3d 3c 45 11 f0 00 	cmpl   $0x0,0xf011453c
f0100cd5:	0f 84 23 fd ff ff    	je     f01009fe <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cdb:	be 00 04 00 00       	mov    $0x400,%esi
f0100ce0:	e9 96 fd ff ff       	jmp    f0100a7b <check_page_free_list+0x93>
	cprintf("nfree_basemem is %d, nfree_extmem is %d\n", nfree_basemem, nfree_extmem);

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
//	cprintf("we now leave check_page_free_list!\n");
}
f0100ce5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ce8:	5b                   	pop    %ebx
f0100ce9:	5e                   	pop    %esi
f0100cea:	5f                   	pop    %edi
f0100ceb:	5d                   	pop    %ebp
f0100cec:	c3                   	ret    

f0100ced <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ced:	55                   	push   %ebp
f0100cee:	89 e5                	mov    %esp,%ebp
f0100cf0:	57                   	push   %edi
f0100cf1:	56                   	push   %esi
f0100cf2:	53                   	push   %ebx
f0100cf3:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f0100cf6:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0100cfd:	00 00 00 

	//num_alloc：在extmem区域已经被占用的页的个数
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
f0100d00:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d05:	e8 0b fc ff ff       	call   f0100915 <boot_alloc>
f0100d0a:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d0f:	c1 e8 0c             	shr    $0xc,%eax
	//num_iohole：在io hole区域占用的页数
	int num_iohole = 96;

	pages[0].pp_ref = 1;
f0100d12:	8b 15 70 49 11 f0    	mov    0xf0114970,%edx
f0100d18:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	for(i = 1; i < npages_basemem; i++)
f0100d1e:	8b 35 40 45 11 f0    	mov    0xf0114540,%esi
f0100d24:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d29:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d2e:	ba 01 00 00 00       	mov    $0x1,%edx
f0100d33:	eb 27                	jmp    f0100d5c <page_init+0x6f>
	{
		pages[i].pp_ref = 0;
f0100d35:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100d3c:	89 cb                	mov    %ecx,%ebx
f0100d3e:	03 1d 70 49 11 f0    	add    0xf0114970,%ebx
f0100d44:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0100d4a:	89 3b                	mov    %edi,(%ebx)
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	//num_iohole：在io hole区域占用的页数
	int num_iohole = 96;

	pages[0].pp_ref = 1;
	for(i = 1; i < npages_basemem; i++)
f0100d4c:	83 c2 01             	add    $0x1,%edx
	{
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100d4f:	89 cf                	mov    %ecx,%edi
f0100d51:	03 3d 70 49 11 f0    	add    0xf0114970,%edi
f0100d57:	b9 01 00 00 00       	mov    $0x1,%ecx
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	//num_iohole：在io hole区域占用的页数
	int num_iohole = 96;

	pages[0].pp_ref = 1;
	for(i = 1; i < npages_basemem; i++)
f0100d5c:	39 f2                	cmp    %esi,%edx
f0100d5e:	72 d5                	jb     f0100d35 <page_init+0x48>
f0100d60:	84 c9                	test   %cl,%cl
f0100d62:	74 06                	je     f0100d6a <page_init+0x7d>
f0100d64:	89 3d 3c 45 11 f0    	mov    %edi,0xf011453c
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
		pages[i].pp_ref = 1;
f0100d6a:	8b 0d 70 49 11 f0    	mov    0xf0114970,%ecx
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	//num_iohole：在io hole区域占用的页数
	int num_iohole = 96;

	pages[0].pp_ref = 1;
	for(i = 1; i < npages_basemem; i++)
f0100d70:	89 f2                	mov    %esi,%edx
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
f0100d72:	8d 44 30 60          	lea    0x60(%eax,%esi,1),%eax
f0100d76:	eb 0a                	jmp    f0100d82 <page_init+0x95>
		pages[i].pp_ref = 1;
f0100d78:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
f0100d7f:	83 c2 01             	add    $0x1,%edx
f0100d82:	39 c2                	cmp    %eax,%edx
f0100d84:	72 f2                	jb     f0100d78 <page_init+0x8b>
f0100d86:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100d8c:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100d93:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d98:	eb 23                	jmp    f0100dbd <page_init+0xd0>
		pages[i].pp_ref = 1;
	for(; i < npages; i++)
	{
		pages[i].pp_ref = 0;
f0100d9a:	89 c1                	mov    %eax,%ecx
f0100d9c:	03 0d 70 49 11 f0    	add    0xf0114970,%ecx
f0100da2:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100da8:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100daa:	89 c3                	mov    %eax,%ebx
f0100dac:	03 1d 70 49 11 f0    	add    0xf0114970,%ebx
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
		pages[i].pp_ref = 1;
	for(; i < npages; i++)
f0100db2:	83 c2 01             	add    $0x1,%edx
f0100db5:	83 c0 08             	add    $0x8,%eax
f0100db8:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100dbd:	3b 15 68 49 11 f0    	cmp    0xf0114968,%edx
f0100dc3:	72 d5                	jb     f0100d9a <page_init+0xad>
f0100dc5:	84 c9                	test   %cl,%cl
f0100dc7:	74 06                	je     f0100dcf <page_init+0xe2>
f0100dc9:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
	{
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100dcf:	83 c4 0c             	add    $0xc,%esp
f0100dd2:	5b                   	pop    %ebx
f0100dd3:	5e                   	pop    %esi
f0100dd4:	5f                   	pop    %edi
f0100dd5:	5d                   	pop    %ebp
f0100dd6:	c3                   	ret    

f0100dd7 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100dd7:	55                   	push   %ebp
f0100dd8:	89 e5                	mov    %esp,%ebp
f0100dda:	53                   	push   %ebx
f0100ddb:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(!page_free_list)
f0100dde:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100de4:	85 db                	test   %ebx,%ebx
f0100de6:	74 58                	je     f0100e40 <page_alloc+0x69>
		return NULL;
	struct PageInfo *pp = page_free_list;
	if(alloc_flags & ALLOC_ZERO) {
f0100de8:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100dec:	74 45                	je     f0100e33 <page_alloc+0x5c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dee:	89 d8                	mov    %ebx,%eax
f0100df0:	2b 05 70 49 11 f0    	sub    0xf0114970,%eax
f0100df6:	c1 f8 03             	sar    $0x3,%eax
f0100df9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dfc:	89 c2                	mov    %eax,%edx
f0100dfe:	c1 ea 0c             	shr    $0xc,%edx
f0100e01:	3b 15 68 49 11 f0    	cmp    0xf0114968,%edx
f0100e07:	72 12                	jb     f0100e1b <page_alloc+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e09:	50                   	push   %eax
f0100e0a:	68 8c 2d 10 f0       	push   $0xf0102d8c
f0100e0f:	6a 52                	push   $0x52
f0100e11:	68 60 2b 10 f0       	push   $0xf0102b60
f0100e16:	e8 70 f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(pp), 0, PGSIZE);
f0100e1b:	83 ec 04             	sub    $0x4,%esp
f0100e1e:	68 00 10 00 00       	push   $0x1000
f0100e23:	6a 00                	push   $0x0
f0100e25:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e2a:	50                   	push   %eax
f0100e2b:	e8 fc 12 00 00       	call   f010212c <memset>
f0100e30:	83 c4 10             	add    $0x10,%esp
	}
	page_free_list = pp->pp_link;
f0100e33:	8b 03                	mov    (%ebx),%eax
f0100e35:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	pp->pp_link = 0;
f0100e3a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
//	cprintf("pp is %x, page_free_list is %x\n", pp, page_free_list);
	return pp;
}
f0100e40:	89 d8                	mov    %ebx,%eax
f0100e42:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e45:	c9                   	leave  
f0100e46:	c3                   	ret    

f0100e47 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e47:	55                   	push   %ebp
f0100e48:	89 e5                	mov    %esp,%ebp
f0100e4a:	83 ec 08             	sub    $0x8,%esp
f0100e4d:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0)
f0100e50:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e55:	74 17                	je     f0100e6e <page_free+0x27>
		panic("pp->pp_ref is nonzero\n");
f0100e57:	83 ec 04             	sub    $0x4,%esp
f0100e5a:	68 21 2c 10 f0       	push   $0xf0102c21
f0100e5f:	68 46 01 00 00       	push   $0x146
f0100e64:	68 54 2b 10 f0       	push   $0xf0102b54
f0100e69:	e8 1d f2 ff ff       	call   f010008b <_panic>
	if(pp->pp_link)
f0100e6e:	83 38 00             	cmpl   $0x0,(%eax)
f0100e71:	74 17                	je     f0100e8a <page_free+0x43>
		panic("pp->pp_link is not NULL\n");
f0100e73:	83 ec 04             	sub    $0x4,%esp
f0100e76:	68 38 2c 10 f0       	push   $0xf0102c38
f0100e7b:	68 48 01 00 00       	push   $0x148
f0100e80:	68 54 2b 10 f0       	push   $0xf0102b54
f0100e85:	e8 01 f2 ff ff       	call   f010008b <_panic>

	pp->pp_link = page_free_list;
f0100e8a:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100e90:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e92:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
}
f0100e97:	c9                   	leave  
f0100e98:	c3                   	ret    

f0100e99 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100e99:	55                   	push   %ebp
f0100e9a:	89 e5                	mov    %esp,%ebp
f0100e9c:	57                   	push   %edi
f0100e9d:	56                   	push   %esi
f0100e9e:	53                   	push   %ebx
f0100e9f:	83 ec 28             	sub    $0x28,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ea2:	6a 15                	push   $0x15
f0100ea4:	e8 2d 07 00 00       	call   f01015d6 <mc146818_read>
f0100ea9:	89 c3                	mov    %eax,%ebx
f0100eab:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100eb2:	e8 1f 07 00 00       	call   f01015d6 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100eb7:	c1 e0 08             	shl    $0x8,%eax
f0100eba:	09 d8                	or     %ebx,%eax
f0100ebc:	c1 e0 0a             	shl    $0xa,%eax
f0100ebf:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100ec5:	85 c0                	test   %eax,%eax
f0100ec7:	0f 48 c2             	cmovs  %edx,%eax
f0100eca:	c1 f8 0c             	sar    $0xc,%eax
f0100ecd:	a3 40 45 11 f0       	mov    %eax,0xf0114540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ed2:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100ed9:	e8 f8 06 00 00       	call   f01015d6 <mc146818_read>
f0100ede:	89 c3                	mov    %eax,%ebx
f0100ee0:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100ee7:	e8 ea 06 00 00       	call   f01015d6 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100eec:	c1 e0 08             	shl    $0x8,%eax
f0100eef:	09 d8                	or     %ebx,%eax
f0100ef1:	c1 e0 0a             	shl    $0xa,%eax
f0100ef4:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0100efa:	83 c4 10             	add    $0x10,%esp
f0100efd:	85 c0                	test   %eax,%eax
f0100eff:	0f 49 d8             	cmovns %eax,%ebx
f0100f02:	c1 fb 0c             	sar    $0xc,%ebx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100f05:	85 db                	test   %ebx,%ebx
f0100f07:	74 0d                	je     f0100f16 <mem_init+0x7d>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100f09:	8d 83 00 01 00 00    	lea    0x100(%ebx),%eax
f0100f0f:	a3 68 49 11 f0       	mov    %eax,0xf0114968
f0100f14:	eb 0a                	jmp    f0100f20 <mem_init+0x87>
	else
		npages = npages_basemem;
f0100f16:	a1 40 45 11 f0       	mov    0xf0114540,%eax
f0100f1b:	a3 68 49 11 f0       	mov    %eax,0xf0114968

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100f20:	89 d8                	mov    %ebx,%eax
f0100f22:	c1 e0 0c             	shl    $0xc,%eax
f0100f25:	c1 e8 0a             	shr    $0xa,%eax
f0100f28:	50                   	push   %eax
f0100f29:	a1 40 45 11 f0       	mov    0xf0114540,%eax
f0100f2e:	c1 e0 0c             	shl    $0xc,%eax
f0100f31:	c1 e8 0a             	shr    $0xa,%eax
f0100f34:	50                   	push   %eax
f0100f35:	a1 68 49 11 f0       	mov    0xf0114968,%eax
f0100f3a:	c1 e0 0c             	shl    $0xc,%eax
f0100f3d:	c1 e8 0a             	shr    $0xa,%eax
f0100f40:	50                   	push   %eax
f0100f41:	68 20 2f 10 f0       	push   $0xf0102f20
f0100f46:	e8 f2 06 00 00       	call   f010163d <cprintf>
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
	cprintf("npages is %u, npages_basemem is %u, npages_extmem is %u\n", npages, npages_basemem, npages_extmem);
f0100f4b:	53                   	push   %ebx
f0100f4c:	ff 35 40 45 11 f0    	pushl  0xf0114540
f0100f52:	ff 35 68 49 11 f0    	pushl  0xf0114968
f0100f58:	68 5c 2f 10 f0       	push   $0xf0102f5c
f0100f5d:	e8 db 06 00 00       	call   f010163d <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100f62:	83 c4 20             	add    $0x20,%esp
f0100f65:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100f6a:	e8 a6 f9 ff ff       	call   f0100915 <boot_alloc>
f0100f6f:	a3 6c 49 11 f0       	mov    %eax,0xf011496c
	memset(kern_pgdir, 0, PGSIZE);
f0100f74:	83 ec 04             	sub    $0x4,%esp
f0100f77:	68 00 10 00 00       	push   $0x1000
f0100f7c:	6a 00                	push   $0x0
f0100f7e:	50                   	push   %eax
f0100f7f:	e8 a8 11 00 00       	call   f010212c <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100f84:	a1 6c 49 11 f0       	mov    0xf011496c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f89:	83 c4 10             	add    $0x10,%esp
f0100f8c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f91:	77 15                	ja     f0100fa8 <mem_init+0x10f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f93:	50                   	push   %eax
f0100f94:	68 98 2f 10 f0       	push   $0xf0102f98
f0100f99:	68 94 00 00 00       	push   $0x94
f0100f9e:	68 54 2b 10 f0       	push   $0xf0102b54
f0100fa3:	e8 e3 f0 ff ff       	call   f010008b <_panic>
f0100fa8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100fae:	83 ca 05             	or     $0x5,%edx
f0100fb1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100fb7:	a1 68 49 11 f0       	mov    0xf0114968,%eax
f0100fbc:	c1 e0 03             	shl    $0x3,%eax
f0100fbf:	e8 51 f9 ff ff       	call   f0100915 <boot_alloc>
f0100fc4:	a3 70 49 11 f0       	mov    %eax,0xf0114970
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100fc9:	83 ec 04             	sub    $0x4,%esp
f0100fcc:	8b 0d 68 49 11 f0    	mov    0xf0114968,%ecx
f0100fd2:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100fd9:	52                   	push   %edx
f0100fda:	6a 00                	push   $0x0
f0100fdc:	50                   	push   %eax
f0100fdd:	e8 4a 11 00 00       	call   f010212c <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100fe2:	e8 06 fd ff ff       	call   f0100ced <page_init>

	check_page_free_list(1);
f0100fe7:	b8 01 00 00 00       	mov    $0x1,%eax
f0100fec:	e8 f7 f9 ff ff       	call   f01009e8 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100ff1:	83 c4 10             	add    $0x10,%esp
f0100ff4:	83 3d 70 49 11 f0 00 	cmpl   $0x0,0xf0114970
f0100ffb:	75 17                	jne    f0101014 <mem_init+0x17b>
		panic("'pages' is a null pointer!");
f0100ffd:	83 ec 04             	sub    $0x4,%esp
f0101000:	68 51 2c 10 f0       	push   $0xf0102c51
f0101005:	68 31 02 00 00       	push   $0x231
f010100a:	68 54 2b 10 f0       	push   $0xf0102b54
f010100f:	e8 77 f0 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101014:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101019:	bb 00 00 00 00       	mov    $0x0,%ebx
f010101e:	eb 05                	jmp    f0101025 <mem_init+0x18c>
		++nfree;
f0101020:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101023:	8b 00                	mov    (%eax),%eax
f0101025:	85 c0                	test   %eax,%eax
f0101027:	75 f7                	jne    f0101020 <mem_init+0x187>
		++nfree;

	cprintf("should be able to allocate three pages\n");
f0101029:	83 ec 0c             	sub    $0xc,%esp
f010102c:	68 bc 2f 10 f0       	push   $0xf0102fbc
f0101031:	e8 07 06 00 00       	call   f010163d <cprintf>
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101036:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010103d:	e8 95 fd ff ff       	call   f0100dd7 <page_alloc>
f0101042:	89 c7                	mov    %eax,%edi
f0101044:	83 c4 10             	add    $0x10,%esp
f0101047:	85 c0                	test   %eax,%eax
f0101049:	75 19                	jne    f0101064 <mem_init+0x1cb>
f010104b:	68 6c 2c 10 f0       	push   $0xf0102c6c
f0101050:	68 91 2b 10 f0       	push   $0xf0102b91
f0101055:	68 3a 02 00 00       	push   $0x23a
f010105a:	68 54 2b 10 f0       	push   $0xf0102b54
f010105f:	e8 27 f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101064:	83 ec 0c             	sub    $0xc,%esp
f0101067:	6a 00                	push   $0x0
f0101069:	e8 69 fd ff ff       	call   f0100dd7 <page_alloc>
f010106e:	89 c6                	mov    %eax,%esi
f0101070:	83 c4 10             	add    $0x10,%esp
f0101073:	85 c0                	test   %eax,%eax
f0101075:	75 19                	jne    f0101090 <mem_init+0x1f7>
f0101077:	68 82 2c 10 f0       	push   $0xf0102c82
f010107c:	68 91 2b 10 f0       	push   $0xf0102b91
f0101081:	68 3b 02 00 00       	push   $0x23b
f0101086:	68 54 2b 10 f0       	push   $0xf0102b54
f010108b:	e8 fb ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101090:	83 ec 0c             	sub    $0xc,%esp
f0101093:	6a 00                	push   $0x0
f0101095:	e8 3d fd ff ff       	call   f0100dd7 <page_alloc>
f010109a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010109d:	83 c4 10             	add    $0x10,%esp
f01010a0:	85 c0                	test   %eax,%eax
f01010a2:	75 19                	jne    f01010bd <mem_init+0x224>
f01010a4:	68 98 2c 10 f0       	push   $0xf0102c98
f01010a9:	68 91 2b 10 f0       	push   $0xf0102b91
f01010ae:	68 3c 02 00 00       	push   $0x23c
f01010b3:	68 54 2b 10 f0       	push   $0xf0102b54
f01010b8:	e8 ce ef ff ff       	call   f010008b <_panic>

//	cprintf("pp0 is %x, pp0->pp_ref is %d, pp0->pp_link is %x\n", pp0, pp0->pp_ref, pp0->pp_link);
//	cprintf("pp1 is %x, pp1->pp_ref is %d, pp1->pp_link is %x\n", pp1, pp1->pp_ref, pp1->pp_link);
//  cprintf("pp2 is %x, pp2->pp_ref is %d, pp2->pp_link is %x\n", pp2, pp2->pp_ref, pp2->pp_link);
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01010bd:	39 f7                	cmp    %esi,%edi
f01010bf:	75 19                	jne    f01010da <mem_init+0x241>
f01010c1:	68 ae 2c 10 f0       	push   $0xf0102cae
f01010c6:	68 91 2b 10 f0       	push   $0xf0102b91
f01010cb:	68 42 02 00 00       	push   $0x242
f01010d0:	68 54 2b 10 f0       	push   $0xf0102b54
f01010d5:	e8 b1 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01010da:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010dd:	39 c7                	cmp    %eax,%edi
f01010df:	74 04                	je     f01010e5 <mem_init+0x24c>
f01010e1:	39 c6                	cmp    %eax,%esi
f01010e3:	75 19                	jne    f01010fe <mem_init+0x265>
f01010e5:	68 e4 2f 10 f0       	push   $0xf0102fe4
f01010ea:	68 91 2b 10 f0       	push   $0xf0102b91
f01010ef:	68 43 02 00 00       	push   $0x243
f01010f4:	68 54 2b 10 f0       	push   $0xf0102b54
f01010f9:	e8 8d ef ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010fe:	8b 0d 70 49 11 f0    	mov    0xf0114970,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101104:	8b 15 68 49 11 f0    	mov    0xf0114968,%edx
f010110a:	c1 e2 0c             	shl    $0xc,%edx
f010110d:	89 f8                	mov    %edi,%eax
f010110f:	29 c8                	sub    %ecx,%eax
f0101111:	c1 f8 03             	sar    $0x3,%eax
f0101114:	c1 e0 0c             	shl    $0xc,%eax
f0101117:	39 d0                	cmp    %edx,%eax
f0101119:	72 19                	jb     f0101134 <mem_init+0x29b>
f010111b:	68 c0 2c 10 f0       	push   $0xf0102cc0
f0101120:	68 91 2b 10 f0       	push   $0xf0102b91
f0101125:	68 44 02 00 00       	push   $0x244
f010112a:	68 54 2b 10 f0       	push   $0xf0102b54
f010112f:	e8 57 ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101134:	89 f0                	mov    %esi,%eax
f0101136:	29 c8                	sub    %ecx,%eax
f0101138:	c1 f8 03             	sar    $0x3,%eax
f010113b:	c1 e0 0c             	shl    $0xc,%eax
f010113e:	39 c2                	cmp    %eax,%edx
f0101140:	77 19                	ja     f010115b <mem_init+0x2c2>
f0101142:	68 dd 2c 10 f0       	push   $0xf0102cdd
f0101147:	68 91 2b 10 f0       	push   $0xf0102b91
f010114c:	68 45 02 00 00       	push   $0x245
f0101151:	68 54 2b 10 f0       	push   $0xf0102b54
f0101156:	e8 30 ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010115b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010115e:	29 c8                	sub    %ecx,%eax
f0101160:	c1 f8 03             	sar    $0x3,%eax
f0101163:	c1 e0 0c             	shl    $0xc,%eax
f0101166:	39 c2                	cmp    %eax,%edx
f0101168:	77 19                	ja     f0101183 <mem_init+0x2ea>
f010116a:	68 fa 2c 10 f0       	push   $0xf0102cfa
f010116f:	68 91 2b 10 f0       	push   $0xf0102b91
f0101174:	68 46 02 00 00       	push   $0x246
f0101179:	68 54 2b 10 f0       	push   $0xf0102b54
f010117e:	e8 08 ef ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101183:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101188:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f010118b:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0101192:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101195:	83 ec 0c             	sub    $0xc,%esp
f0101198:	6a 00                	push   $0x0
f010119a:	e8 38 fc ff ff       	call   f0100dd7 <page_alloc>
f010119f:	83 c4 10             	add    $0x10,%esp
f01011a2:	85 c0                	test   %eax,%eax
f01011a4:	74 19                	je     f01011bf <mem_init+0x326>
f01011a6:	68 17 2d 10 f0       	push   $0xf0102d17
f01011ab:	68 91 2b 10 f0       	push   $0xf0102b91
f01011b0:	68 4d 02 00 00       	push   $0x24d
f01011b5:	68 54 2b 10 f0       	push   $0xf0102b54
f01011ba:	e8 cc ee ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01011bf:	83 ec 0c             	sub    $0xc,%esp
f01011c2:	57                   	push   %edi
f01011c3:	e8 7f fc ff ff       	call   f0100e47 <page_free>
	page_free(pp1);
f01011c8:	89 34 24             	mov    %esi,(%esp)
f01011cb:	e8 77 fc ff ff       	call   f0100e47 <page_free>
	page_free(pp2);
f01011d0:	83 c4 04             	add    $0x4,%esp
f01011d3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01011d6:	e8 6c fc ff ff       	call   f0100e47 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011db:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01011e2:	e8 f0 fb ff ff       	call   f0100dd7 <page_alloc>
f01011e7:	89 c6                	mov    %eax,%esi
f01011e9:	83 c4 10             	add    $0x10,%esp
f01011ec:	85 c0                	test   %eax,%eax
f01011ee:	75 19                	jne    f0101209 <mem_init+0x370>
f01011f0:	68 6c 2c 10 f0       	push   $0xf0102c6c
f01011f5:	68 91 2b 10 f0       	push   $0xf0102b91
f01011fa:	68 54 02 00 00       	push   $0x254
f01011ff:	68 54 2b 10 f0       	push   $0xf0102b54
f0101204:	e8 82 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101209:	83 ec 0c             	sub    $0xc,%esp
f010120c:	6a 00                	push   $0x0
f010120e:	e8 c4 fb ff ff       	call   f0100dd7 <page_alloc>
f0101213:	89 c7                	mov    %eax,%edi
f0101215:	83 c4 10             	add    $0x10,%esp
f0101218:	85 c0                	test   %eax,%eax
f010121a:	75 19                	jne    f0101235 <mem_init+0x39c>
f010121c:	68 82 2c 10 f0       	push   $0xf0102c82
f0101221:	68 91 2b 10 f0       	push   $0xf0102b91
f0101226:	68 55 02 00 00       	push   $0x255
f010122b:	68 54 2b 10 f0       	push   $0xf0102b54
f0101230:	e8 56 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101235:	83 ec 0c             	sub    $0xc,%esp
f0101238:	6a 00                	push   $0x0
f010123a:	e8 98 fb ff ff       	call   f0100dd7 <page_alloc>
f010123f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101242:	83 c4 10             	add    $0x10,%esp
f0101245:	85 c0                	test   %eax,%eax
f0101247:	75 19                	jne    f0101262 <mem_init+0x3c9>
f0101249:	68 98 2c 10 f0       	push   $0xf0102c98
f010124e:	68 91 2b 10 f0       	push   $0xf0102b91
f0101253:	68 56 02 00 00       	push   $0x256
f0101258:	68 54 2b 10 f0       	push   $0xf0102b54
f010125d:	e8 29 ee ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101262:	39 fe                	cmp    %edi,%esi
f0101264:	75 19                	jne    f010127f <mem_init+0x3e6>
f0101266:	68 ae 2c 10 f0       	push   $0xf0102cae
f010126b:	68 91 2b 10 f0       	push   $0xf0102b91
f0101270:	68 58 02 00 00       	push   $0x258
f0101275:	68 54 2b 10 f0       	push   $0xf0102b54
f010127a:	e8 0c ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010127f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101282:	39 c6                	cmp    %eax,%esi
f0101284:	74 04                	je     f010128a <mem_init+0x3f1>
f0101286:	39 c7                	cmp    %eax,%edi
f0101288:	75 19                	jne    f01012a3 <mem_init+0x40a>
f010128a:	68 e4 2f 10 f0       	push   $0xf0102fe4
f010128f:	68 91 2b 10 f0       	push   $0xf0102b91
f0101294:	68 59 02 00 00       	push   $0x259
f0101299:	68 54 2b 10 f0       	push   $0xf0102b54
f010129e:	e8 e8 ed ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01012a3:	83 ec 0c             	sub    $0xc,%esp
f01012a6:	6a 00                	push   $0x0
f01012a8:	e8 2a fb ff ff       	call   f0100dd7 <page_alloc>
f01012ad:	83 c4 10             	add    $0x10,%esp
f01012b0:	85 c0                	test   %eax,%eax
f01012b2:	74 19                	je     f01012cd <mem_init+0x434>
f01012b4:	68 17 2d 10 f0       	push   $0xf0102d17
f01012b9:	68 91 2b 10 f0       	push   $0xf0102b91
f01012be:	68 5a 02 00 00       	push   $0x25a
f01012c3:	68 54 2b 10 f0       	push   $0xf0102b54
f01012c8:	e8 be ed ff ff       	call   f010008b <_panic>

	cprintf("test flags\n");
f01012cd:	83 ec 0c             	sub    $0xc,%esp
f01012d0:	68 26 2d 10 f0       	push   $0xf0102d26
f01012d5:	e8 63 03 00 00       	call   f010163d <cprintf>
f01012da:	89 f0                	mov    %esi,%eax
f01012dc:	2b 05 70 49 11 f0    	sub    0xf0114970,%eax
f01012e2:	c1 f8 03             	sar    $0x3,%eax
f01012e5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012e8:	89 c2                	mov    %eax,%edx
f01012ea:	c1 ea 0c             	shr    $0xc,%edx
f01012ed:	83 c4 10             	add    $0x10,%esp
f01012f0:	3b 15 68 49 11 f0    	cmp    0xf0114968,%edx
f01012f6:	72 12                	jb     f010130a <mem_init+0x471>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012f8:	50                   	push   %eax
f01012f9:	68 8c 2d 10 f0       	push   $0xf0102d8c
f01012fe:	6a 52                	push   $0x52
f0101300:	68 60 2b 10 f0       	push   $0xf0102b60
f0101305:	e8 81 ed ff ff       	call   f010008b <_panic>
	// test flags
	cprintf("page2kva(pp0) is %x\n", page2kva(pp0));
f010130a:	83 ec 08             	sub    $0x8,%esp
f010130d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101312:	50                   	push   %eax
f0101313:	68 32 2d 10 f0       	push   $0xf0102d32
f0101318:	e8 20 03 00 00       	call   f010163d <cprintf>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010131d:	89 f0                	mov    %esi,%eax
f010131f:	2b 05 70 49 11 f0    	sub    0xf0114970,%eax
f0101325:	c1 f8 03             	sar    $0x3,%eax
f0101328:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010132b:	89 c2                	mov    %eax,%edx
f010132d:	c1 ea 0c             	shr    $0xc,%edx
f0101330:	83 c4 10             	add    $0x10,%esp
f0101333:	3b 15 68 49 11 f0    	cmp    0xf0114968,%edx
f0101339:	72 12                	jb     f010134d <mem_init+0x4b4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010133b:	50                   	push   %eax
f010133c:	68 8c 2d 10 f0       	push   $0xf0102d8c
f0101341:	6a 52                	push   $0x52
f0101343:	68 60 2b 10 f0       	push   $0xf0102b60
f0101348:	e8 3e ed ff ff       	call   f010008b <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f010134d:	83 ec 04             	sub    $0x4,%esp
f0101350:	68 00 10 00 00       	push   $0x1000
f0101355:	6a 01                	push   $0x1
f0101357:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010135c:	50                   	push   %eax
f010135d:	e8 ca 0d 00 00       	call   f010212c <memset>
	page_free(pp0);
f0101362:	89 34 24             	mov    %esi,(%esp)
f0101365:	e8 dd fa ff ff       	call   f0100e47 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010136a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101371:	e8 61 fa ff ff       	call   f0100dd7 <page_alloc>
f0101376:	83 c4 10             	add    $0x10,%esp
f0101379:	85 c0                	test   %eax,%eax
f010137b:	75 19                	jne    f0101396 <mem_init+0x4fd>
f010137d:	68 47 2d 10 f0       	push   $0xf0102d47
f0101382:	68 91 2b 10 f0       	push   $0xf0102b91
f0101387:	68 61 02 00 00       	push   $0x261
f010138c:	68 54 2b 10 f0       	push   $0xf0102b54
f0101391:	e8 f5 ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101396:	39 c6                	cmp    %eax,%esi
f0101398:	74 19                	je     f01013b3 <mem_init+0x51a>
f010139a:	68 65 2d 10 f0       	push   $0xf0102d65
f010139f:	68 91 2b 10 f0       	push   $0xf0102b91
f01013a4:	68 62 02 00 00       	push   $0x262
f01013a9:	68 54 2b 10 f0       	push   $0xf0102b54
f01013ae:	e8 d8 ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013b3:	89 f0                	mov    %esi,%eax
f01013b5:	2b 05 70 49 11 f0    	sub    0xf0114970,%eax
f01013bb:	c1 f8 03             	sar    $0x3,%eax
f01013be:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013c1:	89 c2                	mov    %eax,%edx
f01013c3:	c1 ea 0c             	shr    $0xc,%edx
f01013c6:	3b 15 68 49 11 f0    	cmp    0xf0114968,%edx
f01013cc:	72 12                	jb     f01013e0 <mem_init+0x547>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013ce:	50                   	push   %eax
f01013cf:	68 8c 2d 10 f0       	push   $0xf0102d8c
f01013d4:	6a 52                	push   $0x52
f01013d6:	68 60 2b 10 f0       	push   $0xf0102b60
f01013db:	e8 ab ec ff ff       	call   f010008b <_panic>
f01013e0:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01013e6:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01013ec:	80 38 00             	cmpb   $0x0,(%eax)
f01013ef:	74 19                	je     f010140a <mem_init+0x571>
f01013f1:	68 75 2d 10 f0       	push   $0xf0102d75
f01013f6:	68 91 2b 10 f0       	push   $0xf0102b91
f01013fb:	68 65 02 00 00       	push   $0x265
f0101400:	68 54 2b 10 f0       	push   $0xf0102b54
f0101405:	e8 81 ec ff ff       	call   f010008b <_panic>
f010140a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010140d:	39 d0                	cmp    %edx,%eax
f010140f:	75 db                	jne    f01013ec <mem_init+0x553>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101411:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101414:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f0101419:	83 ec 0c             	sub    $0xc,%esp
f010141c:	56                   	push   %esi
f010141d:	e8 25 fa ff ff       	call   f0100e47 <page_free>
	page_free(pp1);
f0101422:	89 3c 24             	mov    %edi,(%esp)
f0101425:	e8 1d fa ff ff       	call   f0100e47 <page_free>
	page_free(pp2);
f010142a:	83 c4 04             	add    $0x4,%esp
f010142d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101430:	e8 12 fa ff ff       	call   f0100e47 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101435:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f010143a:	83 c4 10             	add    $0x10,%esp
f010143d:	eb 05                	jmp    f0101444 <mem_init+0x5ab>
		--nfree;
f010143f:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101442:	8b 00                	mov    (%eax),%eax
f0101444:	85 c0                	test   %eax,%eax
f0101446:	75 f7                	jne    f010143f <mem_init+0x5a6>
		--nfree;
	assert(nfree == 0);
f0101448:	85 db                	test   %ebx,%ebx
f010144a:	74 19                	je     f0101465 <mem_init+0x5cc>
f010144c:	68 7f 2d 10 f0       	push   $0xf0102d7f
f0101451:	68 91 2b 10 f0       	push   $0xf0102b91
f0101456:	68 72 02 00 00       	push   $0x272
f010145b:	68 54 2b 10 f0       	push   $0xf0102b54
f0101460:	e8 26 ec ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101465:	83 ec 0c             	sub    $0xc,%esp
f0101468:	68 04 30 10 f0       	push   $0xf0103004
f010146d:	e8 cb 01 00 00       	call   f010163d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101472:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101479:	e8 59 f9 ff ff       	call   f0100dd7 <page_alloc>
f010147e:	89 c6                	mov    %eax,%esi
f0101480:	83 c4 10             	add    $0x10,%esp
f0101483:	85 c0                	test   %eax,%eax
f0101485:	75 19                	jne    f01014a0 <mem_init+0x607>
f0101487:	68 6c 2c 10 f0       	push   $0xf0102c6c
f010148c:	68 91 2b 10 f0       	push   $0xf0102b91
f0101491:	68 cb 02 00 00       	push   $0x2cb
f0101496:	68 54 2b 10 f0       	push   $0xf0102b54
f010149b:	e8 eb eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01014a0:	83 ec 0c             	sub    $0xc,%esp
f01014a3:	6a 00                	push   $0x0
f01014a5:	e8 2d f9 ff ff       	call   f0100dd7 <page_alloc>
f01014aa:	89 c3                	mov    %eax,%ebx
f01014ac:	83 c4 10             	add    $0x10,%esp
f01014af:	85 c0                	test   %eax,%eax
f01014b1:	75 19                	jne    f01014cc <mem_init+0x633>
f01014b3:	68 82 2c 10 f0       	push   $0xf0102c82
f01014b8:	68 91 2b 10 f0       	push   $0xf0102b91
f01014bd:	68 cc 02 00 00       	push   $0x2cc
f01014c2:	68 54 2b 10 f0       	push   $0xf0102b54
f01014c7:	e8 bf eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01014cc:	83 ec 0c             	sub    $0xc,%esp
f01014cf:	6a 00                	push   $0x0
f01014d1:	e8 01 f9 ff ff       	call   f0100dd7 <page_alloc>
f01014d6:	83 c4 10             	add    $0x10,%esp
f01014d9:	85 c0                	test   %eax,%eax
f01014db:	75 19                	jne    f01014f6 <mem_init+0x65d>
f01014dd:	68 98 2c 10 f0       	push   $0xf0102c98
f01014e2:	68 91 2b 10 f0       	push   $0xf0102b91
f01014e7:	68 cd 02 00 00       	push   $0x2cd
f01014ec:	68 54 2b 10 f0       	push   $0xf0102b54
f01014f1:	e8 95 eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014f6:	39 de                	cmp    %ebx,%esi
f01014f8:	75 19                	jne    f0101513 <mem_init+0x67a>
f01014fa:	68 ae 2c 10 f0       	push   $0xf0102cae
f01014ff:	68 91 2b 10 f0       	push   $0xf0102b91
f0101504:	68 d0 02 00 00       	push   $0x2d0
f0101509:	68 54 2b 10 f0       	push   $0xf0102b54
f010150e:	e8 78 eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101513:	39 c6                	cmp    %eax,%esi
f0101515:	74 04                	je     f010151b <mem_init+0x682>
f0101517:	39 c3                	cmp    %eax,%ebx
f0101519:	75 19                	jne    f0101534 <mem_init+0x69b>
f010151b:	68 e4 2f 10 f0       	push   $0xf0102fe4
f0101520:	68 91 2b 10 f0       	push   $0xf0102b91
f0101525:	68 d1 02 00 00       	push   $0x2d1
f010152a:	68 54 2b 10 f0       	push   $0xf0102b54
f010152f:	e8 57 eb ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101534:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f010153b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010153e:	83 ec 0c             	sub    $0xc,%esp
f0101541:	6a 00                	push   $0x0
f0101543:	e8 8f f8 ff ff       	call   f0100dd7 <page_alloc>
f0101548:	83 c4 10             	add    $0x10,%esp
f010154b:	85 c0                	test   %eax,%eax
f010154d:	74 19                	je     f0101568 <mem_init+0x6cf>
f010154f:	68 17 2d 10 f0       	push   $0xf0102d17
f0101554:	68 91 2b 10 f0       	push   $0xf0102b91
f0101559:	68 d8 02 00 00       	push   $0x2d8
f010155e:	68 54 2b 10 f0       	push   $0xf0102b54
f0101563:	e8 23 eb ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101568:	68 24 30 10 f0       	push   $0xf0103024
f010156d:	68 91 2b 10 f0       	push   $0xf0102b91
f0101572:	68 de 02 00 00       	push   $0x2de
f0101577:	68 54 2b 10 f0       	push   $0xf0102b54
f010157c:	e8 0a eb ff ff       	call   f010008b <_panic>

f0101581 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101581:	55                   	push   %ebp
f0101582:	89 e5                	mov    %esp,%ebp
f0101584:	83 ec 08             	sub    $0x8,%esp
f0101587:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010158a:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010158e:	83 e8 01             	sub    $0x1,%eax
f0101591:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101595:	66 85 c0             	test   %ax,%ax
f0101598:	75 0c                	jne    f01015a6 <page_decref+0x25>
		page_free(pp);
f010159a:	83 ec 0c             	sub    $0xc,%esp
f010159d:	52                   	push   %edx
f010159e:	e8 a4 f8 ff ff       	call   f0100e47 <page_free>
f01015a3:	83 c4 10             	add    $0x10,%esp
}
f01015a6:	c9                   	leave  
f01015a7:	c3                   	ret    

f01015a8 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01015a8:	55                   	push   %ebp
f01015a9:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01015ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01015b0:	5d                   	pop    %ebp
f01015b1:	c3                   	ret    

f01015b2 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01015b2:	55                   	push   %ebp
f01015b3:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01015b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01015ba:	5d                   	pop    %ebp
f01015bb:	c3                   	ret    

f01015bc <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01015bc:	55                   	push   %ebp
f01015bd:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01015bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01015c4:	5d                   	pop    %ebp
f01015c5:	c3                   	ret    

f01015c6 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01015c6:	55                   	push   %ebp
f01015c7:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01015c9:	5d                   	pop    %ebp
f01015ca:	c3                   	ret    

f01015cb <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01015cb:	55                   	push   %ebp
f01015cc:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01015ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015d1:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01015d4:	5d                   	pop    %ebp
f01015d5:	c3                   	ret    

f01015d6 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01015d6:	55                   	push   %ebp
f01015d7:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01015d9:	ba 70 00 00 00       	mov    $0x70,%edx
f01015de:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01015e2:	ba 71 00 00 00       	mov    $0x71,%edx
f01015e7:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01015e8:	0f b6 c0             	movzbl %al,%eax
}
f01015eb:	5d                   	pop    %ebp
f01015ec:	c3                   	ret    

f01015ed <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01015ed:	55                   	push   %ebp
f01015ee:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01015f0:	ba 70 00 00 00       	mov    $0x70,%edx
f01015f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f8:	ee                   	out    %al,(%dx)
f01015f9:	ba 71 00 00 00       	mov    $0x71,%edx
f01015fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101601:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0101602:	5d                   	pop    %ebp
f0101603:	c3                   	ret    

f0101604 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101604:	55                   	push   %ebp
f0101605:	89 e5                	mov    %esp,%ebp
f0101607:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010160a:	ff 75 08             	pushl  0x8(%ebp)
f010160d:	e8 cc ef ff ff       	call   f01005de <cputchar>
	*cnt++;
}
f0101612:	83 c4 10             	add    $0x10,%esp
f0101615:	c9                   	leave  
f0101616:	c3                   	ret    

f0101617 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101617:	55                   	push   %ebp
f0101618:	89 e5                	mov    %esp,%ebp
f010161a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010161d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101624:	ff 75 0c             	pushl  0xc(%ebp)
f0101627:	ff 75 08             	pushl  0x8(%ebp)
f010162a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010162d:	50                   	push   %eax
f010162e:	68 04 16 10 f0       	push   $0xf0101604
f0101633:	e8 42 04 00 00       	call   f0101a7a <vprintfmt>
	return cnt;
}
f0101638:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010163b:	c9                   	leave  
f010163c:	c3                   	ret    

f010163d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010163d:	55                   	push   %ebp
f010163e:	89 e5                	mov    %esp,%ebp
f0101640:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101643:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101646:	50                   	push   %eax
f0101647:	ff 75 08             	pushl  0x8(%ebp)
f010164a:	e8 c8 ff ff ff       	call   f0101617 <vcprintf>
	va_end(ap);

	return cnt;
}
f010164f:	c9                   	leave  
f0101650:	c3                   	ret    

f0101651 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101651:	55                   	push   %ebp
f0101652:	89 e5                	mov    %esp,%ebp
f0101654:	57                   	push   %edi
f0101655:	56                   	push   %esi
f0101656:	53                   	push   %ebx
f0101657:	83 ec 14             	sub    $0x14,%esp
f010165a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010165d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101660:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101663:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101666:	8b 1a                	mov    (%edx),%ebx
f0101668:	8b 01                	mov    (%ecx),%eax
f010166a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010166d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101674:	eb 7f                	jmp    f01016f5 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101676:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101679:	01 d8                	add    %ebx,%eax
f010167b:	89 c6                	mov    %eax,%esi
f010167d:	c1 ee 1f             	shr    $0x1f,%esi
f0101680:	01 c6                	add    %eax,%esi
f0101682:	d1 fe                	sar    %esi
f0101684:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101687:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010168a:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010168d:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010168f:	eb 03                	jmp    f0101694 <stab_binsearch+0x43>
			m--;
f0101691:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101694:	39 c3                	cmp    %eax,%ebx
f0101696:	7f 0d                	jg     f01016a5 <stab_binsearch+0x54>
f0101698:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010169c:	83 ea 0c             	sub    $0xc,%edx
f010169f:	39 f9                	cmp    %edi,%ecx
f01016a1:	75 ee                	jne    f0101691 <stab_binsearch+0x40>
f01016a3:	eb 05                	jmp    f01016aa <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01016a5:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01016a8:	eb 4b                	jmp    f01016f5 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01016aa:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01016ad:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01016b0:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01016b4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01016b7:	76 11                	jbe    f01016ca <stab_binsearch+0x79>
			*region_left = m;
f01016b9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01016bc:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01016be:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01016c1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01016c8:	eb 2b                	jmp    f01016f5 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01016ca:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01016cd:	73 14                	jae    f01016e3 <stab_binsearch+0x92>
			*region_right = m - 1;
f01016cf:	83 e8 01             	sub    $0x1,%eax
f01016d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01016d5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01016d8:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01016da:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01016e1:	eb 12                	jmp    f01016f5 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01016e3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01016e6:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01016e8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01016ec:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01016ee:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01016f5:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01016f8:	0f 8e 78 ff ff ff    	jle    f0101676 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01016fe:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101702:	75 0f                	jne    f0101713 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0101704:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101707:	8b 00                	mov    (%eax),%eax
f0101709:	83 e8 01             	sub    $0x1,%eax
f010170c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010170f:	89 06                	mov    %eax,(%esi)
f0101711:	eb 2c                	jmp    f010173f <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101713:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101716:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101718:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010171b:	8b 0e                	mov    (%esi),%ecx
f010171d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101720:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101723:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101726:	eb 03                	jmp    f010172b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101728:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010172b:	39 c8                	cmp    %ecx,%eax
f010172d:	7e 0b                	jle    f010173a <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010172f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101733:	83 ea 0c             	sub    $0xc,%edx
f0101736:	39 df                	cmp    %ebx,%edi
f0101738:	75 ee                	jne    f0101728 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010173a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010173d:	89 06                	mov    %eax,(%esi)
	}
}
f010173f:	83 c4 14             	add    $0x14,%esp
f0101742:	5b                   	pop    %ebx
f0101743:	5e                   	pop    %esi
f0101744:	5f                   	pop    %edi
f0101745:	5d                   	pop    %ebp
f0101746:	c3                   	ret    

f0101747 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101747:	55                   	push   %ebp
f0101748:	89 e5                	mov    %esp,%ebp
f010174a:	57                   	push   %edi
f010174b:	56                   	push   %esi
f010174c:	53                   	push   %ebx
f010174d:	83 ec 3c             	sub    $0x3c,%esp
f0101750:	8b 75 08             	mov    0x8(%ebp),%esi
f0101753:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101756:	c7 03 54 30 10 f0    	movl   $0xf0103054,(%ebx)
	info->eip_line = 0;
f010175c:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101763:	c7 43 08 54 30 10 f0 	movl   $0xf0103054,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010176a:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0101771:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101774:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010177b:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101781:	76 11                	jbe    f0101794 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101783:	b8 63 9c 10 f0       	mov    $0xf0109c63,%eax
f0101788:	3d 49 7f 10 f0       	cmp    $0xf0107f49,%eax
f010178d:	77 19                	ja     f01017a8 <debuginfo_eip+0x61>
f010178f:	e9 a1 01 00 00       	jmp    f0101935 <debuginfo_eip+0x1ee>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101794:	83 ec 04             	sub    $0x4,%esp
f0101797:	68 5e 30 10 f0       	push   $0xf010305e
f010179c:	6a 7f                	push   $0x7f
f010179e:	68 6b 30 10 f0       	push   $0xf010306b
f01017a3:	e8 e3 e8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01017a8:	80 3d 62 9c 10 f0 00 	cmpb   $0x0,0xf0109c62
f01017af:	0f 85 87 01 00 00    	jne    f010193c <debuginfo_eip+0x1f5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01017b5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01017bc:	b8 48 7f 10 f0       	mov    $0xf0107f48,%eax
f01017c1:	2d b0 32 10 f0       	sub    $0xf01032b0,%eax
f01017c6:	c1 f8 02             	sar    $0x2,%eax
f01017c9:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01017cf:	83 e8 01             	sub    $0x1,%eax
f01017d2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01017d5:	83 ec 08             	sub    $0x8,%esp
f01017d8:	56                   	push   %esi
f01017d9:	6a 64                	push   $0x64
f01017db:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01017de:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01017e1:	b8 b0 32 10 f0       	mov    $0xf01032b0,%eax
f01017e6:	e8 66 fe ff ff       	call   f0101651 <stab_binsearch>
	if (lfile == 0)
f01017eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01017ee:	83 c4 10             	add    $0x10,%esp
f01017f1:	85 c0                	test   %eax,%eax
f01017f3:	0f 84 4a 01 00 00    	je     f0101943 <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01017f9:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01017fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01017ff:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101802:	83 ec 08             	sub    $0x8,%esp
f0101805:	56                   	push   %esi
f0101806:	6a 24                	push   $0x24
f0101808:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010180b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010180e:	b8 b0 32 10 f0       	mov    $0xf01032b0,%eax
f0101813:	e8 39 fe ff ff       	call   f0101651 <stab_binsearch>

	if (lfun <= rfun) {
f0101818:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010181b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010181e:	83 c4 10             	add    $0x10,%esp
f0101821:	39 d0                	cmp    %edx,%eax
f0101823:	7f 40                	jg     f0101865 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101825:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0101828:	c1 e1 02             	shl    $0x2,%ecx
f010182b:	8d b9 b0 32 10 f0    	lea    -0xfefcd50(%ecx),%edi
f0101831:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0101834:	8b b9 b0 32 10 f0    	mov    -0xfefcd50(%ecx),%edi
f010183a:	b9 63 9c 10 f0       	mov    $0xf0109c63,%ecx
f010183f:	81 e9 49 7f 10 f0    	sub    $0xf0107f49,%ecx
f0101845:	39 cf                	cmp    %ecx,%edi
f0101847:	73 09                	jae    f0101852 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101849:	81 c7 49 7f 10 f0    	add    $0xf0107f49,%edi
f010184f:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101852:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101855:	8b 4f 08             	mov    0x8(%edi),%ecx
f0101858:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010185b:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010185d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101860:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101863:	eb 0f                	jmp    f0101874 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101865:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101868:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010186b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010186e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101871:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101874:	83 ec 08             	sub    $0x8,%esp
f0101877:	6a 3a                	push   $0x3a
f0101879:	ff 73 08             	pushl  0x8(%ebx)
f010187c:	e8 8f 08 00 00       	call   f0102110 <strfind>
f0101881:	2b 43 08             	sub    0x8(%ebx),%eax
f0101884:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101887:	83 c4 08             	add    $0x8,%esp
f010188a:	56                   	push   %esi
f010188b:	6a 44                	push   $0x44
f010188d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101890:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101893:	b8 b0 32 10 f0       	mov    $0xf01032b0,%eax
f0101898:	e8 b4 fd ff ff       	call   f0101651 <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f010189d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01018a0:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01018a3:	8d 04 85 b0 32 10 f0 	lea    -0xfefcd50(,%eax,4),%eax
f01018aa:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f01018ae:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01018b1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01018b4:	83 c4 10             	add    $0x10,%esp
f01018b7:	eb 06                	jmp    f01018bf <debuginfo_eip+0x178>
f01018b9:	83 ea 01             	sub    $0x1,%edx
f01018bc:	83 e8 0c             	sub    $0xc,%eax
f01018bf:	39 d6                	cmp    %edx,%esi
f01018c1:	7f 34                	jg     f01018f7 <debuginfo_eip+0x1b0>
	       && stabs[lline].n_type != N_SOL
f01018c3:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01018c7:	80 f9 84             	cmp    $0x84,%cl
f01018ca:	74 0b                	je     f01018d7 <debuginfo_eip+0x190>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01018cc:	80 f9 64             	cmp    $0x64,%cl
f01018cf:	75 e8                	jne    f01018b9 <debuginfo_eip+0x172>
f01018d1:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01018d5:	74 e2                	je     f01018b9 <debuginfo_eip+0x172>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01018d7:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01018da:	8b 14 85 b0 32 10 f0 	mov    -0xfefcd50(,%eax,4),%edx
f01018e1:	b8 63 9c 10 f0       	mov    $0xf0109c63,%eax
f01018e6:	2d 49 7f 10 f0       	sub    $0xf0107f49,%eax
f01018eb:	39 c2                	cmp    %eax,%edx
f01018ed:	73 08                	jae    f01018f7 <debuginfo_eip+0x1b0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01018ef:	81 c2 49 7f 10 f0    	add    $0xf0107f49,%edx
f01018f5:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01018f7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01018fa:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01018fd:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101902:	39 f2                	cmp    %esi,%edx
f0101904:	7d 49                	jge    f010194f <debuginfo_eip+0x208>
		for (lline = lfun + 1;
f0101906:	83 c2 01             	add    $0x1,%edx
f0101909:	89 d0                	mov    %edx,%eax
f010190b:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010190e:	8d 14 95 b0 32 10 f0 	lea    -0xfefcd50(,%edx,4),%edx
f0101915:	eb 04                	jmp    f010191b <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101917:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010191b:	39 c6                	cmp    %eax,%esi
f010191d:	7e 2b                	jle    f010194a <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010191f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101923:	83 c0 01             	add    $0x1,%eax
f0101926:	83 c2 0c             	add    $0xc,%edx
f0101929:	80 f9 a0             	cmp    $0xa0,%cl
f010192c:	74 e9                	je     f0101917 <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010192e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101933:	eb 1a                	jmp    f010194f <debuginfo_eip+0x208>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101935:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010193a:	eb 13                	jmp    f010194f <debuginfo_eip+0x208>
f010193c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101941:	eb 0c                	jmp    f010194f <debuginfo_eip+0x208>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101943:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101948:	eb 05                	jmp    f010194f <debuginfo_eip+0x208>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010194a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010194f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101952:	5b                   	pop    %ebx
f0101953:	5e                   	pop    %esi
f0101954:	5f                   	pop    %edi
f0101955:	5d                   	pop    %ebp
f0101956:	c3                   	ret    

f0101957 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101957:	55                   	push   %ebp
f0101958:	89 e5                	mov    %esp,%ebp
f010195a:	57                   	push   %edi
f010195b:	56                   	push   %esi
f010195c:	53                   	push   %ebx
f010195d:	83 ec 1c             	sub    $0x1c,%esp
f0101960:	89 c7                	mov    %eax,%edi
f0101962:	89 d6                	mov    %edx,%esi
f0101964:	8b 45 08             	mov    0x8(%ebp),%eax
f0101967:	8b 55 0c             	mov    0xc(%ebp),%edx
f010196a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010196d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101970:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101973:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101978:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010197b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010197e:	39 d3                	cmp    %edx,%ebx
f0101980:	72 05                	jb     f0101987 <printnum+0x30>
f0101982:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101985:	77 45                	ja     f01019cc <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101987:	83 ec 0c             	sub    $0xc,%esp
f010198a:	ff 75 18             	pushl  0x18(%ebp)
f010198d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101990:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101993:	53                   	push   %ebx
f0101994:	ff 75 10             	pushl  0x10(%ebp)
f0101997:	83 ec 08             	sub    $0x8,%esp
f010199a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010199d:	ff 75 e0             	pushl  -0x20(%ebp)
f01019a0:	ff 75 dc             	pushl  -0x24(%ebp)
f01019a3:	ff 75 d8             	pushl  -0x28(%ebp)
f01019a6:	e8 85 09 00 00       	call   f0102330 <__udivdi3>
f01019ab:	83 c4 18             	add    $0x18,%esp
f01019ae:	52                   	push   %edx
f01019af:	50                   	push   %eax
f01019b0:	89 f2                	mov    %esi,%edx
f01019b2:	89 f8                	mov    %edi,%eax
f01019b4:	e8 9e ff ff ff       	call   f0101957 <printnum>
f01019b9:	83 c4 20             	add    $0x20,%esp
f01019bc:	eb 18                	jmp    f01019d6 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01019be:	83 ec 08             	sub    $0x8,%esp
f01019c1:	56                   	push   %esi
f01019c2:	ff 75 18             	pushl  0x18(%ebp)
f01019c5:	ff d7                	call   *%edi
f01019c7:	83 c4 10             	add    $0x10,%esp
f01019ca:	eb 03                	jmp    f01019cf <printnum+0x78>
f01019cc:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01019cf:	83 eb 01             	sub    $0x1,%ebx
f01019d2:	85 db                	test   %ebx,%ebx
f01019d4:	7f e8                	jg     f01019be <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01019d6:	83 ec 08             	sub    $0x8,%esp
f01019d9:	56                   	push   %esi
f01019da:	83 ec 04             	sub    $0x4,%esp
f01019dd:	ff 75 e4             	pushl  -0x1c(%ebp)
f01019e0:	ff 75 e0             	pushl  -0x20(%ebp)
f01019e3:	ff 75 dc             	pushl  -0x24(%ebp)
f01019e6:	ff 75 d8             	pushl  -0x28(%ebp)
f01019e9:	e8 72 0a 00 00       	call   f0102460 <__umoddi3>
f01019ee:	83 c4 14             	add    $0x14,%esp
f01019f1:	0f be 80 79 30 10 f0 	movsbl -0xfefcf87(%eax),%eax
f01019f8:	50                   	push   %eax
f01019f9:	ff d7                	call   *%edi
}
f01019fb:	83 c4 10             	add    $0x10,%esp
f01019fe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101a01:	5b                   	pop    %ebx
f0101a02:	5e                   	pop    %esi
f0101a03:	5f                   	pop    %edi
f0101a04:	5d                   	pop    %ebp
f0101a05:	c3                   	ret    

f0101a06 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101a06:	55                   	push   %ebp
f0101a07:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101a09:	83 fa 01             	cmp    $0x1,%edx
f0101a0c:	7e 0e                	jle    f0101a1c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101a0e:	8b 10                	mov    (%eax),%edx
f0101a10:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101a13:	89 08                	mov    %ecx,(%eax)
f0101a15:	8b 02                	mov    (%edx),%eax
f0101a17:	8b 52 04             	mov    0x4(%edx),%edx
f0101a1a:	eb 22                	jmp    f0101a3e <getuint+0x38>
	else if (lflag)
f0101a1c:	85 d2                	test   %edx,%edx
f0101a1e:	74 10                	je     f0101a30 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101a20:	8b 10                	mov    (%eax),%edx
f0101a22:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101a25:	89 08                	mov    %ecx,(%eax)
f0101a27:	8b 02                	mov    (%edx),%eax
f0101a29:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a2e:	eb 0e                	jmp    f0101a3e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101a30:	8b 10                	mov    (%eax),%edx
f0101a32:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101a35:	89 08                	mov    %ecx,(%eax)
f0101a37:	8b 02                	mov    (%edx),%eax
f0101a39:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101a3e:	5d                   	pop    %ebp
f0101a3f:	c3                   	ret    

f0101a40 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101a40:	55                   	push   %ebp
f0101a41:	89 e5                	mov    %esp,%ebp
f0101a43:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101a46:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101a4a:	8b 10                	mov    (%eax),%edx
f0101a4c:	3b 50 04             	cmp    0x4(%eax),%edx
f0101a4f:	73 0a                	jae    f0101a5b <sprintputch+0x1b>
		*b->buf++ = ch;
f0101a51:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101a54:	89 08                	mov    %ecx,(%eax)
f0101a56:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a59:	88 02                	mov    %al,(%edx)
}
f0101a5b:	5d                   	pop    %ebp
f0101a5c:	c3                   	ret    

f0101a5d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101a5d:	55                   	push   %ebp
f0101a5e:	89 e5                	mov    %esp,%ebp
f0101a60:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0101a63:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101a66:	50                   	push   %eax
f0101a67:	ff 75 10             	pushl  0x10(%ebp)
f0101a6a:	ff 75 0c             	pushl  0xc(%ebp)
f0101a6d:	ff 75 08             	pushl  0x8(%ebp)
f0101a70:	e8 05 00 00 00       	call   f0101a7a <vprintfmt>
	va_end(ap);
}
f0101a75:	83 c4 10             	add    $0x10,%esp
f0101a78:	c9                   	leave  
f0101a79:	c3                   	ret    

f0101a7a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101a7a:	55                   	push   %ebp
f0101a7b:	89 e5                	mov    %esp,%ebp
f0101a7d:	57                   	push   %edi
f0101a7e:	56                   	push   %esi
f0101a7f:	53                   	push   %ebx
f0101a80:	83 ec 2c             	sub    $0x2c,%esp
f0101a83:	8b 75 08             	mov    0x8(%ebp),%esi
f0101a86:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101a89:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101a8c:	eb 1d                	jmp    f0101aab <vprintfmt+0x31>
	
	//textcolor = 0x0700;		//black on write

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101a8e:	85 c0                	test   %eax,%eax
f0101a90:	75 0f                	jne    f0101aa1 <vprintfmt+0x27>
			{
				textcolor = 0x0700;
f0101a92:	c7 05 64 49 11 f0 00 	movl   $0x700,0xf0114964
f0101a99:	07 00 00 
				return;
f0101a9c:	e9 c4 03 00 00       	jmp    f0101e65 <vprintfmt+0x3eb>
			}
			putch(ch, putdat);
f0101aa1:	83 ec 08             	sub    $0x8,%esp
f0101aa4:	53                   	push   %ebx
f0101aa5:	50                   	push   %eax
f0101aa6:	ff d6                	call   *%esi
f0101aa8:	83 c4 10             	add    $0x10,%esp
	char padc;
	
	//textcolor = 0x0700;		//black on write

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101aab:	83 c7 01             	add    $0x1,%edi
f0101aae:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101ab2:	83 f8 25             	cmp    $0x25,%eax
f0101ab5:	75 d7                	jne    f0101a8e <vprintfmt+0x14>
f0101ab7:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0101abb:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101ac2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101ac9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0101ad0:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ad5:	eb 07                	jmp    f0101ade <vprintfmt+0x64>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ad7:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101ada:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ade:	8d 47 01             	lea    0x1(%edi),%eax
f0101ae1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101ae4:	0f b6 07             	movzbl (%edi),%eax
f0101ae7:	0f b6 c8             	movzbl %al,%ecx
f0101aea:	83 e8 23             	sub    $0x23,%eax
f0101aed:	3c 55                	cmp    $0x55,%al
f0101aef:	0f 87 55 03 00 00    	ja     f0101e4a <vprintfmt+0x3d0>
f0101af5:	0f b6 c0             	movzbl %al,%eax
f0101af8:	ff 24 85 20 31 10 f0 	jmp    *-0xfefcee0(,%eax,4)
f0101aff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101b02:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101b06:	eb d6                	jmp    f0101ade <vprintfmt+0x64>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101b0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b10:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101b13:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101b16:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101b1a:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0101b1d:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0101b20:	83 fa 09             	cmp    $0x9,%edx
f0101b23:	77 39                	ja     f0101b5e <vprintfmt+0xe4>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101b25:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101b28:	eb e9                	jmp    f0101b13 <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101b2a:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b2d:	8d 48 04             	lea    0x4(%eax),%ecx
f0101b30:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101b33:	8b 00                	mov    (%eax),%eax
f0101b35:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b38:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101b3b:	eb 27                	jmp    f0101b64 <vprintfmt+0xea>
f0101b3d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101b40:	85 c0                	test   %eax,%eax
f0101b42:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101b47:	0f 49 c8             	cmovns %eax,%ecx
f0101b4a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101b50:	eb 8c                	jmp    f0101ade <vprintfmt+0x64>
f0101b52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101b55:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101b5c:	eb 80                	jmp    f0101ade <vprintfmt+0x64>
f0101b5e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101b61:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0101b64:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101b68:	0f 89 70 ff ff ff    	jns    f0101ade <vprintfmt+0x64>
				width = precision, precision = -1;
f0101b6e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101b74:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101b7b:	e9 5e ff ff ff       	jmp    f0101ade <vprintfmt+0x64>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101b80:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101b86:	e9 53 ff ff ff       	jmp    f0101ade <vprintfmt+0x64>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101b8b:	83 fa 01             	cmp    $0x1,%edx
f0101b8e:	7e 0d                	jle    f0101b9d <vprintfmt+0x123>
		return va_arg(*ap, long long);
f0101b90:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b93:	8d 50 08             	lea    0x8(%eax),%edx
f0101b96:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b99:	8b 00                	mov    (%eax),%eax
f0101b9b:	eb 1c                	jmp    f0101bb9 <vprintfmt+0x13f>
	else if (lflag)
f0101b9d:	85 d2                	test   %edx,%edx
f0101b9f:	74 0d                	je     f0101bae <vprintfmt+0x134>
		return va_arg(*ap, long);
f0101ba1:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ba4:	8d 50 04             	lea    0x4(%eax),%edx
f0101ba7:	89 55 14             	mov    %edx,0x14(%ebp)
f0101baa:	8b 00                	mov    (%eax),%eax
f0101bac:	eb 0b                	jmp    f0101bb9 <vprintfmt+0x13f>
	else
		return va_arg(*ap, int);
f0101bae:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bb1:	8d 50 04             	lea    0x4(%eax),%edx
f0101bb4:	89 55 14             	mov    %edx,0x14(%ebp)
f0101bb7:	8b 00                	mov    (%eax),%eax
			goto reswitch;

		// text color
		case 'm':
			num = getint(&ap, lflag);
			textcolor = num;
f0101bb9:	a3 64 49 11 f0       	mov    %eax,0xf0114964
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101bbe:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// text color
		case 'm':
			num = getint(&ap, lflag);
			textcolor = num;
			break;
f0101bc1:	e9 e5 fe ff ff       	jmp    f0101aab <vprintfmt+0x31>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101bc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bc9:	8d 50 04             	lea    0x4(%eax),%edx
f0101bcc:	89 55 14             	mov    %edx,0x14(%ebp)
f0101bcf:	83 ec 08             	sub    $0x8,%esp
f0101bd2:	53                   	push   %ebx
f0101bd3:	ff 30                	pushl  (%eax)
f0101bd5:	ff d6                	call   *%esi
			break;
f0101bd7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101bda:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101bdd:	e9 c9 fe ff ff       	jmp    f0101aab <vprintfmt+0x31>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101be2:	8b 45 14             	mov    0x14(%ebp),%eax
f0101be5:	8d 50 04             	lea    0x4(%eax),%edx
f0101be8:	89 55 14             	mov    %edx,0x14(%ebp)
f0101beb:	8b 00                	mov    (%eax),%eax
f0101bed:	99                   	cltd   
f0101bee:	31 d0                	xor    %edx,%eax
f0101bf0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101bf2:	83 f8 07             	cmp    $0x7,%eax
f0101bf5:	7f 0b                	jg     f0101c02 <vprintfmt+0x188>
f0101bf7:	8b 14 85 80 32 10 f0 	mov    -0xfefcd80(,%eax,4),%edx
f0101bfe:	85 d2                	test   %edx,%edx
f0101c00:	75 18                	jne    f0101c1a <vprintfmt+0x1a0>
				printfmt(putch, putdat, "error %d", err);
f0101c02:	50                   	push   %eax
f0101c03:	68 91 30 10 f0       	push   $0xf0103091
f0101c08:	53                   	push   %ebx
f0101c09:	56                   	push   %esi
f0101c0a:	e8 4e fe ff ff       	call   f0101a5d <printfmt>
f0101c0f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101c15:	e9 91 fe ff ff       	jmp    f0101aab <vprintfmt+0x31>
			else
				printfmt(putch, putdat, "%s", p);
f0101c1a:	52                   	push   %edx
f0101c1b:	68 a3 2b 10 f0       	push   $0xf0102ba3
f0101c20:	53                   	push   %ebx
f0101c21:	56                   	push   %esi
f0101c22:	e8 36 fe ff ff       	call   f0101a5d <printfmt>
f0101c27:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101c2d:	e9 79 fe ff ff       	jmp    f0101aab <vprintfmt+0x31>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101c32:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c35:	8d 50 04             	lea    0x4(%eax),%edx
f0101c38:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c3b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101c3d:	85 ff                	test   %edi,%edi
f0101c3f:	b8 8a 30 10 f0       	mov    $0xf010308a,%eax
f0101c44:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101c47:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101c4b:	0f 8e 94 00 00 00    	jle    f0101ce5 <vprintfmt+0x26b>
f0101c51:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101c55:	0f 84 98 00 00 00    	je     f0101cf3 <vprintfmt+0x279>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101c5b:	83 ec 08             	sub    $0x8,%esp
f0101c5e:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c61:	57                   	push   %edi
f0101c62:	e8 5f 03 00 00       	call   f0101fc6 <strnlen>
f0101c67:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101c6a:	29 c1                	sub    %eax,%ecx
f0101c6c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101c6f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101c72:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101c76:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101c79:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101c7c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101c7e:	eb 0f                	jmp    f0101c8f <vprintfmt+0x215>
					putch(padc, putdat);
f0101c80:	83 ec 08             	sub    $0x8,%esp
f0101c83:	53                   	push   %ebx
f0101c84:	ff 75 e0             	pushl  -0x20(%ebp)
f0101c87:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101c89:	83 ef 01             	sub    $0x1,%edi
f0101c8c:	83 c4 10             	add    $0x10,%esp
f0101c8f:	85 ff                	test   %edi,%edi
f0101c91:	7f ed                	jg     f0101c80 <vprintfmt+0x206>
f0101c93:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101c96:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101c99:	85 c9                	test   %ecx,%ecx
f0101c9b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ca0:	0f 49 c1             	cmovns %ecx,%eax
f0101ca3:	29 c1                	sub    %eax,%ecx
f0101ca5:	89 75 08             	mov    %esi,0x8(%ebp)
f0101ca8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101cab:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101cae:	89 cb                	mov    %ecx,%ebx
f0101cb0:	eb 4d                	jmp    f0101cff <vprintfmt+0x285>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101cb2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101cb6:	74 1b                	je     f0101cd3 <vprintfmt+0x259>
f0101cb8:	0f be c0             	movsbl %al,%eax
f0101cbb:	83 e8 20             	sub    $0x20,%eax
f0101cbe:	83 f8 5e             	cmp    $0x5e,%eax
f0101cc1:	76 10                	jbe    f0101cd3 <vprintfmt+0x259>
					putch('?', putdat);
f0101cc3:	83 ec 08             	sub    $0x8,%esp
f0101cc6:	ff 75 0c             	pushl  0xc(%ebp)
f0101cc9:	6a 3f                	push   $0x3f
f0101ccb:	ff 55 08             	call   *0x8(%ebp)
f0101cce:	83 c4 10             	add    $0x10,%esp
f0101cd1:	eb 0d                	jmp    f0101ce0 <vprintfmt+0x266>
				else
					putch(ch, putdat);
f0101cd3:	83 ec 08             	sub    $0x8,%esp
f0101cd6:	ff 75 0c             	pushl  0xc(%ebp)
f0101cd9:	52                   	push   %edx
f0101cda:	ff 55 08             	call   *0x8(%ebp)
f0101cdd:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101ce0:	83 eb 01             	sub    $0x1,%ebx
f0101ce3:	eb 1a                	jmp    f0101cff <vprintfmt+0x285>
f0101ce5:	89 75 08             	mov    %esi,0x8(%ebp)
f0101ce8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101ceb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101cee:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101cf1:	eb 0c                	jmp    f0101cff <vprintfmt+0x285>
f0101cf3:	89 75 08             	mov    %esi,0x8(%ebp)
f0101cf6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101cf9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101cfc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101cff:	83 c7 01             	add    $0x1,%edi
f0101d02:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101d06:	0f be d0             	movsbl %al,%edx
f0101d09:	85 d2                	test   %edx,%edx
f0101d0b:	74 23                	je     f0101d30 <vprintfmt+0x2b6>
f0101d0d:	85 f6                	test   %esi,%esi
f0101d0f:	78 a1                	js     f0101cb2 <vprintfmt+0x238>
f0101d11:	83 ee 01             	sub    $0x1,%esi
f0101d14:	79 9c                	jns    f0101cb2 <vprintfmt+0x238>
f0101d16:	89 df                	mov    %ebx,%edi
f0101d18:	8b 75 08             	mov    0x8(%ebp),%esi
f0101d1b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101d1e:	eb 18                	jmp    f0101d38 <vprintfmt+0x2be>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101d20:	83 ec 08             	sub    $0x8,%esp
f0101d23:	53                   	push   %ebx
f0101d24:	6a 20                	push   $0x20
f0101d26:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101d28:	83 ef 01             	sub    $0x1,%edi
f0101d2b:	83 c4 10             	add    $0x10,%esp
f0101d2e:	eb 08                	jmp    f0101d38 <vprintfmt+0x2be>
f0101d30:	89 df                	mov    %ebx,%edi
f0101d32:	8b 75 08             	mov    0x8(%ebp),%esi
f0101d35:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101d38:	85 ff                	test   %edi,%edi
f0101d3a:	7f e4                	jg     f0101d20 <vprintfmt+0x2a6>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101d3c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101d3f:	e9 67 fd ff ff       	jmp    f0101aab <vprintfmt+0x31>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101d44:	83 fa 01             	cmp    $0x1,%edx
f0101d47:	7e 16                	jle    f0101d5f <vprintfmt+0x2e5>
		return va_arg(*ap, long long);
f0101d49:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d4c:	8d 50 08             	lea    0x8(%eax),%edx
f0101d4f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101d52:	8b 50 04             	mov    0x4(%eax),%edx
f0101d55:	8b 00                	mov    (%eax),%eax
f0101d57:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101d5a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101d5d:	eb 32                	jmp    f0101d91 <vprintfmt+0x317>
	else if (lflag)
f0101d5f:	85 d2                	test   %edx,%edx
f0101d61:	74 18                	je     f0101d7b <vprintfmt+0x301>
		return va_arg(*ap, long);
f0101d63:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d66:	8d 50 04             	lea    0x4(%eax),%edx
f0101d69:	89 55 14             	mov    %edx,0x14(%ebp)
f0101d6c:	8b 00                	mov    (%eax),%eax
f0101d6e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101d71:	89 c1                	mov    %eax,%ecx
f0101d73:	c1 f9 1f             	sar    $0x1f,%ecx
f0101d76:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101d79:	eb 16                	jmp    f0101d91 <vprintfmt+0x317>
	else
		return va_arg(*ap, int);
f0101d7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d7e:	8d 50 04             	lea    0x4(%eax),%edx
f0101d81:	89 55 14             	mov    %edx,0x14(%ebp)
f0101d84:	8b 00                	mov    (%eax),%eax
f0101d86:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101d89:	89 c1                	mov    %eax,%ecx
f0101d8b:	c1 f9 1f             	sar    $0x1f,%ecx
f0101d8e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101d91:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101d94:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101d97:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101d9c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101da0:	79 74                	jns    f0101e16 <vprintfmt+0x39c>
				putch('-', putdat);
f0101da2:	83 ec 08             	sub    $0x8,%esp
f0101da5:	53                   	push   %ebx
f0101da6:	6a 2d                	push   $0x2d
f0101da8:	ff d6                	call   *%esi
				num = -(long long) num;
f0101daa:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101dad:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101db0:	f7 d8                	neg    %eax
f0101db2:	83 d2 00             	adc    $0x0,%edx
f0101db5:	f7 da                	neg    %edx
f0101db7:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101dba:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101dbf:	eb 55                	jmp    f0101e16 <vprintfmt+0x39c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101dc1:	8d 45 14             	lea    0x14(%ebp),%eax
f0101dc4:	e8 3d fc ff ff       	call   f0101a06 <getuint>
			base = 10;
f0101dc9:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101dce:	eb 46                	jmp    f0101e16 <vprintfmt+0x39c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101dd0:	8d 45 14             	lea    0x14(%ebp),%eax
f0101dd3:	e8 2e fc ff ff       	call   f0101a06 <getuint>
			base = 8;
f0101dd8:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101ddd:	eb 37                	jmp    f0101e16 <vprintfmt+0x39c>

		// pointer
		case 'p':
			putch('0', putdat);
f0101ddf:	83 ec 08             	sub    $0x8,%esp
f0101de2:	53                   	push   %ebx
f0101de3:	6a 30                	push   $0x30
f0101de5:	ff d6                	call   *%esi
			putch('x', putdat);
f0101de7:	83 c4 08             	add    $0x8,%esp
f0101dea:	53                   	push   %ebx
f0101deb:	6a 78                	push   $0x78
f0101ded:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101def:	8b 45 14             	mov    0x14(%ebp),%eax
f0101df2:	8d 50 04             	lea    0x4(%eax),%edx
f0101df5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101df8:	8b 00                	mov    (%eax),%eax
f0101dfa:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101dff:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101e02:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101e07:	eb 0d                	jmp    f0101e16 <vprintfmt+0x39c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101e09:	8d 45 14             	lea    0x14(%ebp),%eax
f0101e0c:	e8 f5 fb ff ff       	call   f0101a06 <getuint>
			base = 16;
f0101e11:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101e16:	83 ec 0c             	sub    $0xc,%esp
f0101e19:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101e1d:	57                   	push   %edi
f0101e1e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101e21:	51                   	push   %ecx
f0101e22:	52                   	push   %edx
f0101e23:	50                   	push   %eax
f0101e24:	89 da                	mov    %ebx,%edx
f0101e26:	89 f0                	mov    %esi,%eax
f0101e28:	e8 2a fb ff ff       	call   f0101957 <printnum>
			break;
f0101e2d:	83 c4 20             	add    $0x20,%esp
f0101e30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101e33:	e9 73 fc ff ff       	jmp    f0101aab <vprintfmt+0x31>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101e38:	83 ec 08             	sub    $0x8,%esp
f0101e3b:	53                   	push   %ebx
f0101e3c:	51                   	push   %ecx
f0101e3d:	ff d6                	call   *%esi
			break;
f0101e3f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101e42:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101e45:	e9 61 fc ff ff       	jmp    f0101aab <vprintfmt+0x31>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101e4a:	83 ec 08             	sub    $0x8,%esp
f0101e4d:	53                   	push   %ebx
f0101e4e:	6a 25                	push   $0x25
f0101e50:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101e52:	83 c4 10             	add    $0x10,%esp
f0101e55:	eb 03                	jmp    f0101e5a <vprintfmt+0x3e0>
f0101e57:	83 ef 01             	sub    $0x1,%edi
f0101e5a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101e5e:	75 f7                	jne    f0101e57 <vprintfmt+0x3dd>
f0101e60:	e9 46 fc ff ff       	jmp    f0101aab <vprintfmt+0x31>
				/* do nothing */;
			break;
		}
	}
}
f0101e65:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e68:	5b                   	pop    %ebx
f0101e69:	5e                   	pop    %esi
f0101e6a:	5f                   	pop    %edi
f0101e6b:	5d                   	pop    %ebp
f0101e6c:	c3                   	ret    

f0101e6d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101e6d:	55                   	push   %ebp
f0101e6e:	89 e5                	mov    %esp,%ebp
f0101e70:	83 ec 18             	sub    $0x18,%esp
f0101e73:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e76:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101e79:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101e7c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101e80:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101e83:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101e8a:	85 c0                	test   %eax,%eax
f0101e8c:	74 26                	je     f0101eb4 <vsnprintf+0x47>
f0101e8e:	85 d2                	test   %edx,%edx
f0101e90:	7e 22                	jle    f0101eb4 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101e92:	ff 75 14             	pushl  0x14(%ebp)
f0101e95:	ff 75 10             	pushl  0x10(%ebp)
f0101e98:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101e9b:	50                   	push   %eax
f0101e9c:	68 40 1a 10 f0       	push   $0xf0101a40
f0101ea1:	e8 d4 fb ff ff       	call   f0101a7a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101ea6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ea9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101eac:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101eaf:	83 c4 10             	add    $0x10,%esp
f0101eb2:	eb 05                	jmp    f0101eb9 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101eb4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101eb9:	c9                   	leave  
f0101eba:	c3                   	ret    

f0101ebb <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101ebb:	55                   	push   %ebp
f0101ebc:	89 e5                	mov    %esp,%ebp
f0101ebe:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101ec1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101ec4:	50                   	push   %eax
f0101ec5:	ff 75 10             	pushl  0x10(%ebp)
f0101ec8:	ff 75 0c             	pushl  0xc(%ebp)
f0101ecb:	ff 75 08             	pushl  0x8(%ebp)
f0101ece:	e8 9a ff ff ff       	call   f0101e6d <vsnprintf>
	va_end(ap);

	return rc;
}
f0101ed3:	c9                   	leave  
f0101ed4:	c3                   	ret    

f0101ed5 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101ed5:	55                   	push   %ebp
f0101ed6:	89 e5                	mov    %esp,%ebp
f0101ed8:	57                   	push   %edi
f0101ed9:	56                   	push   %esi
f0101eda:	53                   	push   %ebx
f0101edb:	83 ec 0c             	sub    $0xc,%esp
f0101ede:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101ee1:	85 c0                	test   %eax,%eax
f0101ee3:	74 11                	je     f0101ef6 <readline+0x21>
		cprintf("%s", prompt);
f0101ee5:	83 ec 08             	sub    $0x8,%esp
f0101ee8:	50                   	push   %eax
f0101ee9:	68 a3 2b 10 f0       	push   $0xf0102ba3
f0101eee:	e8 4a f7 ff ff       	call   f010163d <cprintf>
f0101ef3:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101ef6:	83 ec 0c             	sub    $0xc,%esp
f0101ef9:	6a 00                	push   $0x0
f0101efb:	e8 ff e6 ff ff       	call   f01005ff <iscons>
f0101f00:	89 c7                	mov    %eax,%edi
f0101f02:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101f05:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101f0a:	e8 df e6 ff ff       	call   f01005ee <getchar>
f0101f0f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101f11:	85 c0                	test   %eax,%eax
f0101f13:	79 18                	jns    f0101f2d <readline+0x58>
			cprintf("read error: %e\n", c);
f0101f15:	83 ec 08             	sub    $0x8,%esp
f0101f18:	50                   	push   %eax
f0101f19:	68 a0 32 10 f0       	push   $0xf01032a0
f0101f1e:	e8 1a f7 ff ff       	call   f010163d <cprintf>
			return NULL;
f0101f23:	83 c4 10             	add    $0x10,%esp
f0101f26:	b8 00 00 00 00       	mov    $0x0,%eax
f0101f2b:	eb 79                	jmp    f0101fa6 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101f2d:	83 f8 08             	cmp    $0x8,%eax
f0101f30:	0f 94 c2             	sete   %dl
f0101f33:	83 f8 7f             	cmp    $0x7f,%eax
f0101f36:	0f 94 c0             	sete   %al
f0101f39:	08 c2                	or     %al,%dl
f0101f3b:	74 1a                	je     f0101f57 <readline+0x82>
f0101f3d:	85 f6                	test   %esi,%esi
f0101f3f:	7e 16                	jle    f0101f57 <readline+0x82>
			if (echoing)
f0101f41:	85 ff                	test   %edi,%edi
f0101f43:	74 0d                	je     f0101f52 <readline+0x7d>
				cputchar('\b');
f0101f45:	83 ec 0c             	sub    $0xc,%esp
f0101f48:	6a 08                	push   $0x8
f0101f4a:	e8 8f e6 ff ff       	call   f01005de <cputchar>
f0101f4f:	83 c4 10             	add    $0x10,%esp
			i--;
f0101f52:	83 ee 01             	sub    $0x1,%esi
f0101f55:	eb b3                	jmp    f0101f0a <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101f57:	83 fb 1f             	cmp    $0x1f,%ebx
f0101f5a:	7e 23                	jle    f0101f7f <readline+0xaa>
f0101f5c:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101f62:	7f 1b                	jg     f0101f7f <readline+0xaa>
			if (echoing)
f0101f64:	85 ff                	test   %edi,%edi
f0101f66:	74 0c                	je     f0101f74 <readline+0x9f>
				cputchar(c);
f0101f68:	83 ec 0c             	sub    $0xc,%esp
f0101f6b:	53                   	push   %ebx
f0101f6c:	e8 6d e6 ff ff       	call   f01005de <cputchar>
f0101f71:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101f74:	88 9e 60 45 11 f0    	mov    %bl,-0xfeebaa0(%esi)
f0101f7a:	8d 76 01             	lea    0x1(%esi),%esi
f0101f7d:	eb 8b                	jmp    f0101f0a <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101f7f:	83 fb 0a             	cmp    $0xa,%ebx
f0101f82:	74 05                	je     f0101f89 <readline+0xb4>
f0101f84:	83 fb 0d             	cmp    $0xd,%ebx
f0101f87:	75 81                	jne    f0101f0a <readline+0x35>
			if (echoing)
f0101f89:	85 ff                	test   %edi,%edi
f0101f8b:	74 0d                	je     f0101f9a <readline+0xc5>
				cputchar('\n');
f0101f8d:	83 ec 0c             	sub    $0xc,%esp
f0101f90:	6a 0a                	push   $0xa
f0101f92:	e8 47 e6 ff ff       	call   f01005de <cputchar>
f0101f97:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101f9a:	c6 86 60 45 11 f0 00 	movb   $0x0,-0xfeebaa0(%esi)
			return buf;
f0101fa1:	b8 60 45 11 f0       	mov    $0xf0114560,%eax
		}
	}
}
f0101fa6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101fa9:	5b                   	pop    %ebx
f0101faa:	5e                   	pop    %esi
f0101fab:	5f                   	pop    %edi
f0101fac:	5d                   	pop    %ebp
f0101fad:	c3                   	ret    

f0101fae <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101fae:	55                   	push   %ebp
f0101faf:	89 e5                	mov    %esp,%ebp
f0101fb1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101fb4:	b8 00 00 00 00       	mov    $0x0,%eax
f0101fb9:	eb 03                	jmp    f0101fbe <strlen+0x10>
		n++;
f0101fbb:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101fbe:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101fc2:	75 f7                	jne    f0101fbb <strlen+0xd>
		n++;
	return n;
}
f0101fc4:	5d                   	pop    %ebp
f0101fc5:	c3                   	ret    

f0101fc6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101fc6:	55                   	push   %ebp
f0101fc7:	89 e5                	mov    %esp,%ebp
f0101fc9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101fcc:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101fcf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fd4:	eb 03                	jmp    f0101fd9 <strnlen+0x13>
		n++;
f0101fd6:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101fd9:	39 c2                	cmp    %eax,%edx
f0101fdb:	74 08                	je     f0101fe5 <strnlen+0x1f>
f0101fdd:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101fe1:	75 f3                	jne    f0101fd6 <strnlen+0x10>
f0101fe3:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101fe5:	5d                   	pop    %ebp
f0101fe6:	c3                   	ret    

f0101fe7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101fe7:	55                   	push   %ebp
f0101fe8:	89 e5                	mov    %esp,%ebp
f0101fea:	53                   	push   %ebx
f0101feb:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101ff1:	89 c2                	mov    %eax,%edx
f0101ff3:	83 c2 01             	add    $0x1,%edx
f0101ff6:	83 c1 01             	add    $0x1,%ecx
f0101ff9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101ffd:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102000:	84 db                	test   %bl,%bl
f0102002:	75 ef                	jne    f0101ff3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102004:	5b                   	pop    %ebx
f0102005:	5d                   	pop    %ebp
f0102006:	c3                   	ret    

f0102007 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102007:	55                   	push   %ebp
f0102008:	89 e5                	mov    %esp,%ebp
f010200a:	53                   	push   %ebx
f010200b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010200e:	53                   	push   %ebx
f010200f:	e8 9a ff ff ff       	call   f0101fae <strlen>
f0102014:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102017:	ff 75 0c             	pushl  0xc(%ebp)
f010201a:	01 d8                	add    %ebx,%eax
f010201c:	50                   	push   %eax
f010201d:	e8 c5 ff ff ff       	call   f0101fe7 <strcpy>
	return dst;
}
f0102022:	89 d8                	mov    %ebx,%eax
f0102024:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102027:	c9                   	leave  
f0102028:	c3                   	ret    

f0102029 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102029:	55                   	push   %ebp
f010202a:	89 e5                	mov    %esp,%ebp
f010202c:	56                   	push   %esi
f010202d:	53                   	push   %ebx
f010202e:	8b 75 08             	mov    0x8(%ebp),%esi
f0102031:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102034:	89 f3                	mov    %esi,%ebx
f0102036:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102039:	89 f2                	mov    %esi,%edx
f010203b:	eb 0f                	jmp    f010204c <strncpy+0x23>
		*dst++ = *src;
f010203d:	83 c2 01             	add    $0x1,%edx
f0102040:	0f b6 01             	movzbl (%ecx),%eax
f0102043:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102046:	80 39 01             	cmpb   $0x1,(%ecx)
f0102049:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010204c:	39 da                	cmp    %ebx,%edx
f010204e:	75 ed                	jne    f010203d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0102050:	89 f0                	mov    %esi,%eax
f0102052:	5b                   	pop    %ebx
f0102053:	5e                   	pop    %esi
f0102054:	5d                   	pop    %ebp
f0102055:	c3                   	ret    

f0102056 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102056:	55                   	push   %ebp
f0102057:	89 e5                	mov    %esp,%ebp
f0102059:	56                   	push   %esi
f010205a:	53                   	push   %ebx
f010205b:	8b 75 08             	mov    0x8(%ebp),%esi
f010205e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102061:	8b 55 10             	mov    0x10(%ebp),%edx
f0102064:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102066:	85 d2                	test   %edx,%edx
f0102068:	74 21                	je     f010208b <strlcpy+0x35>
f010206a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010206e:	89 f2                	mov    %esi,%edx
f0102070:	eb 09                	jmp    f010207b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102072:	83 c2 01             	add    $0x1,%edx
f0102075:	83 c1 01             	add    $0x1,%ecx
f0102078:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010207b:	39 c2                	cmp    %eax,%edx
f010207d:	74 09                	je     f0102088 <strlcpy+0x32>
f010207f:	0f b6 19             	movzbl (%ecx),%ebx
f0102082:	84 db                	test   %bl,%bl
f0102084:	75 ec                	jne    f0102072 <strlcpy+0x1c>
f0102086:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0102088:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010208b:	29 f0                	sub    %esi,%eax
}
f010208d:	5b                   	pop    %ebx
f010208e:	5e                   	pop    %esi
f010208f:	5d                   	pop    %ebp
f0102090:	c3                   	ret    

f0102091 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0102091:	55                   	push   %ebp
f0102092:	89 e5                	mov    %esp,%ebp
f0102094:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102097:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010209a:	eb 06                	jmp    f01020a2 <strcmp+0x11>
		p++, q++;
f010209c:	83 c1 01             	add    $0x1,%ecx
f010209f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01020a2:	0f b6 01             	movzbl (%ecx),%eax
f01020a5:	84 c0                	test   %al,%al
f01020a7:	74 04                	je     f01020ad <strcmp+0x1c>
f01020a9:	3a 02                	cmp    (%edx),%al
f01020ab:	74 ef                	je     f010209c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01020ad:	0f b6 c0             	movzbl %al,%eax
f01020b0:	0f b6 12             	movzbl (%edx),%edx
f01020b3:	29 d0                	sub    %edx,%eax
}
f01020b5:	5d                   	pop    %ebp
f01020b6:	c3                   	ret    

f01020b7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01020b7:	55                   	push   %ebp
f01020b8:	89 e5                	mov    %esp,%ebp
f01020ba:	53                   	push   %ebx
f01020bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01020be:	8b 55 0c             	mov    0xc(%ebp),%edx
f01020c1:	89 c3                	mov    %eax,%ebx
f01020c3:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01020c6:	eb 06                	jmp    f01020ce <strncmp+0x17>
		n--, p++, q++;
f01020c8:	83 c0 01             	add    $0x1,%eax
f01020cb:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01020ce:	39 d8                	cmp    %ebx,%eax
f01020d0:	74 15                	je     f01020e7 <strncmp+0x30>
f01020d2:	0f b6 08             	movzbl (%eax),%ecx
f01020d5:	84 c9                	test   %cl,%cl
f01020d7:	74 04                	je     f01020dd <strncmp+0x26>
f01020d9:	3a 0a                	cmp    (%edx),%cl
f01020db:	74 eb                	je     f01020c8 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01020dd:	0f b6 00             	movzbl (%eax),%eax
f01020e0:	0f b6 12             	movzbl (%edx),%edx
f01020e3:	29 d0                	sub    %edx,%eax
f01020e5:	eb 05                	jmp    f01020ec <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01020e7:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01020ec:	5b                   	pop    %ebx
f01020ed:	5d                   	pop    %ebp
f01020ee:	c3                   	ret    

f01020ef <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01020ef:	55                   	push   %ebp
f01020f0:	89 e5                	mov    %esp,%ebp
f01020f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01020f5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01020f9:	eb 07                	jmp    f0102102 <strchr+0x13>
		if (*s == c)
f01020fb:	38 ca                	cmp    %cl,%dl
f01020fd:	74 0f                	je     f010210e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01020ff:	83 c0 01             	add    $0x1,%eax
f0102102:	0f b6 10             	movzbl (%eax),%edx
f0102105:	84 d2                	test   %dl,%dl
f0102107:	75 f2                	jne    f01020fb <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0102109:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010210e:	5d                   	pop    %ebp
f010210f:	c3                   	ret    

f0102110 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0102110:	55                   	push   %ebp
f0102111:	89 e5                	mov    %esp,%ebp
f0102113:	8b 45 08             	mov    0x8(%ebp),%eax
f0102116:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010211a:	eb 03                	jmp    f010211f <strfind+0xf>
f010211c:	83 c0 01             	add    $0x1,%eax
f010211f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0102122:	38 ca                	cmp    %cl,%dl
f0102124:	74 04                	je     f010212a <strfind+0x1a>
f0102126:	84 d2                	test   %dl,%dl
f0102128:	75 f2                	jne    f010211c <strfind+0xc>
			break;
	return (char *) s;
}
f010212a:	5d                   	pop    %ebp
f010212b:	c3                   	ret    

f010212c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010212c:	55                   	push   %ebp
f010212d:	89 e5                	mov    %esp,%ebp
f010212f:	57                   	push   %edi
f0102130:	56                   	push   %esi
f0102131:	53                   	push   %ebx
f0102132:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102135:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0102138:	85 c9                	test   %ecx,%ecx
f010213a:	74 36                	je     f0102172 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010213c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0102142:	75 28                	jne    f010216c <memset+0x40>
f0102144:	f6 c1 03             	test   $0x3,%cl
f0102147:	75 23                	jne    f010216c <memset+0x40>
		c &= 0xFF;
f0102149:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010214d:	89 d3                	mov    %edx,%ebx
f010214f:	c1 e3 08             	shl    $0x8,%ebx
f0102152:	89 d6                	mov    %edx,%esi
f0102154:	c1 e6 18             	shl    $0x18,%esi
f0102157:	89 d0                	mov    %edx,%eax
f0102159:	c1 e0 10             	shl    $0x10,%eax
f010215c:	09 f0                	or     %esi,%eax
f010215e:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0102160:	89 d8                	mov    %ebx,%eax
f0102162:	09 d0                	or     %edx,%eax
f0102164:	c1 e9 02             	shr    $0x2,%ecx
f0102167:	fc                   	cld    
f0102168:	f3 ab                	rep stos %eax,%es:(%edi)
f010216a:	eb 06                	jmp    f0102172 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010216c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010216f:	fc                   	cld    
f0102170:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102172:	89 f8                	mov    %edi,%eax
f0102174:	5b                   	pop    %ebx
f0102175:	5e                   	pop    %esi
f0102176:	5f                   	pop    %edi
f0102177:	5d                   	pop    %ebp
f0102178:	c3                   	ret    

f0102179 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102179:	55                   	push   %ebp
f010217a:	89 e5                	mov    %esp,%ebp
f010217c:	57                   	push   %edi
f010217d:	56                   	push   %esi
f010217e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102181:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102184:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102187:	39 c6                	cmp    %eax,%esi
f0102189:	73 35                	jae    f01021c0 <memmove+0x47>
f010218b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010218e:	39 d0                	cmp    %edx,%eax
f0102190:	73 2e                	jae    f01021c0 <memmove+0x47>
		s += n;
		d += n;
f0102192:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102195:	89 d6                	mov    %edx,%esi
f0102197:	09 fe                	or     %edi,%esi
f0102199:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010219f:	75 13                	jne    f01021b4 <memmove+0x3b>
f01021a1:	f6 c1 03             	test   $0x3,%cl
f01021a4:	75 0e                	jne    f01021b4 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01021a6:	83 ef 04             	sub    $0x4,%edi
f01021a9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01021ac:	c1 e9 02             	shr    $0x2,%ecx
f01021af:	fd                   	std    
f01021b0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01021b2:	eb 09                	jmp    f01021bd <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01021b4:	83 ef 01             	sub    $0x1,%edi
f01021b7:	8d 72 ff             	lea    -0x1(%edx),%esi
f01021ba:	fd                   	std    
f01021bb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01021bd:	fc                   	cld    
f01021be:	eb 1d                	jmp    f01021dd <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01021c0:	89 f2                	mov    %esi,%edx
f01021c2:	09 c2                	or     %eax,%edx
f01021c4:	f6 c2 03             	test   $0x3,%dl
f01021c7:	75 0f                	jne    f01021d8 <memmove+0x5f>
f01021c9:	f6 c1 03             	test   $0x3,%cl
f01021cc:	75 0a                	jne    f01021d8 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01021ce:	c1 e9 02             	shr    $0x2,%ecx
f01021d1:	89 c7                	mov    %eax,%edi
f01021d3:	fc                   	cld    
f01021d4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01021d6:	eb 05                	jmp    f01021dd <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01021d8:	89 c7                	mov    %eax,%edi
f01021da:	fc                   	cld    
f01021db:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01021dd:	5e                   	pop    %esi
f01021de:	5f                   	pop    %edi
f01021df:	5d                   	pop    %ebp
f01021e0:	c3                   	ret    

f01021e1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01021e1:	55                   	push   %ebp
f01021e2:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01021e4:	ff 75 10             	pushl  0x10(%ebp)
f01021e7:	ff 75 0c             	pushl  0xc(%ebp)
f01021ea:	ff 75 08             	pushl  0x8(%ebp)
f01021ed:	e8 87 ff ff ff       	call   f0102179 <memmove>
}
f01021f2:	c9                   	leave  
f01021f3:	c3                   	ret    

f01021f4 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01021f4:	55                   	push   %ebp
f01021f5:	89 e5                	mov    %esp,%ebp
f01021f7:	56                   	push   %esi
f01021f8:	53                   	push   %ebx
f01021f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01021fc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01021ff:	89 c6                	mov    %eax,%esi
f0102201:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102204:	eb 1a                	jmp    f0102220 <memcmp+0x2c>
		if (*s1 != *s2)
f0102206:	0f b6 08             	movzbl (%eax),%ecx
f0102209:	0f b6 1a             	movzbl (%edx),%ebx
f010220c:	38 d9                	cmp    %bl,%cl
f010220e:	74 0a                	je     f010221a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0102210:	0f b6 c1             	movzbl %cl,%eax
f0102213:	0f b6 db             	movzbl %bl,%ebx
f0102216:	29 d8                	sub    %ebx,%eax
f0102218:	eb 0f                	jmp    f0102229 <memcmp+0x35>
		s1++, s2++;
f010221a:	83 c0 01             	add    $0x1,%eax
f010221d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102220:	39 f0                	cmp    %esi,%eax
f0102222:	75 e2                	jne    f0102206 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0102224:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102229:	5b                   	pop    %ebx
f010222a:	5e                   	pop    %esi
f010222b:	5d                   	pop    %ebp
f010222c:	c3                   	ret    

f010222d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010222d:	55                   	push   %ebp
f010222e:	89 e5                	mov    %esp,%ebp
f0102230:	53                   	push   %ebx
f0102231:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0102234:	89 c1                	mov    %eax,%ecx
f0102236:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0102239:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010223d:	eb 0a                	jmp    f0102249 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010223f:	0f b6 10             	movzbl (%eax),%edx
f0102242:	39 da                	cmp    %ebx,%edx
f0102244:	74 07                	je     f010224d <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0102246:	83 c0 01             	add    $0x1,%eax
f0102249:	39 c8                	cmp    %ecx,%eax
f010224b:	72 f2                	jb     f010223f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010224d:	5b                   	pop    %ebx
f010224e:	5d                   	pop    %ebp
f010224f:	c3                   	ret    

f0102250 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102250:	55                   	push   %ebp
f0102251:	89 e5                	mov    %esp,%ebp
f0102253:	57                   	push   %edi
f0102254:	56                   	push   %esi
f0102255:	53                   	push   %ebx
f0102256:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102259:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010225c:	eb 03                	jmp    f0102261 <strtol+0x11>
		s++;
f010225e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102261:	0f b6 01             	movzbl (%ecx),%eax
f0102264:	3c 20                	cmp    $0x20,%al
f0102266:	74 f6                	je     f010225e <strtol+0xe>
f0102268:	3c 09                	cmp    $0x9,%al
f010226a:	74 f2                	je     f010225e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010226c:	3c 2b                	cmp    $0x2b,%al
f010226e:	75 0a                	jne    f010227a <strtol+0x2a>
		s++;
f0102270:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102273:	bf 00 00 00 00       	mov    $0x0,%edi
f0102278:	eb 11                	jmp    f010228b <strtol+0x3b>
f010227a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010227f:	3c 2d                	cmp    $0x2d,%al
f0102281:	75 08                	jne    f010228b <strtol+0x3b>
		s++, neg = 1;
f0102283:	83 c1 01             	add    $0x1,%ecx
f0102286:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010228b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102291:	75 15                	jne    f01022a8 <strtol+0x58>
f0102293:	80 39 30             	cmpb   $0x30,(%ecx)
f0102296:	75 10                	jne    f01022a8 <strtol+0x58>
f0102298:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010229c:	75 7c                	jne    f010231a <strtol+0xca>
		s += 2, base = 16;
f010229e:	83 c1 02             	add    $0x2,%ecx
f01022a1:	bb 10 00 00 00       	mov    $0x10,%ebx
f01022a6:	eb 16                	jmp    f01022be <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01022a8:	85 db                	test   %ebx,%ebx
f01022aa:	75 12                	jne    f01022be <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01022ac:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01022b1:	80 39 30             	cmpb   $0x30,(%ecx)
f01022b4:	75 08                	jne    f01022be <strtol+0x6e>
		s++, base = 8;
f01022b6:	83 c1 01             	add    $0x1,%ecx
f01022b9:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01022be:	b8 00 00 00 00       	mov    $0x0,%eax
f01022c3:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01022c6:	0f b6 11             	movzbl (%ecx),%edx
f01022c9:	8d 72 d0             	lea    -0x30(%edx),%esi
f01022cc:	89 f3                	mov    %esi,%ebx
f01022ce:	80 fb 09             	cmp    $0x9,%bl
f01022d1:	77 08                	ja     f01022db <strtol+0x8b>
			dig = *s - '0';
f01022d3:	0f be d2             	movsbl %dl,%edx
f01022d6:	83 ea 30             	sub    $0x30,%edx
f01022d9:	eb 22                	jmp    f01022fd <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01022db:	8d 72 9f             	lea    -0x61(%edx),%esi
f01022de:	89 f3                	mov    %esi,%ebx
f01022e0:	80 fb 19             	cmp    $0x19,%bl
f01022e3:	77 08                	ja     f01022ed <strtol+0x9d>
			dig = *s - 'a' + 10;
f01022e5:	0f be d2             	movsbl %dl,%edx
f01022e8:	83 ea 57             	sub    $0x57,%edx
f01022eb:	eb 10                	jmp    f01022fd <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01022ed:	8d 72 bf             	lea    -0x41(%edx),%esi
f01022f0:	89 f3                	mov    %esi,%ebx
f01022f2:	80 fb 19             	cmp    $0x19,%bl
f01022f5:	77 16                	ja     f010230d <strtol+0xbd>
			dig = *s - 'A' + 10;
f01022f7:	0f be d2             	movsbl %dl,%edx
f01022fa:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01022fd:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102300:	7d 0b                	jge    f010230d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0102302:	83 c1 01             	add    $0x1,%ecx
f0102305:	0f af 45 10          	imul   0x10(%ebp),%eax
f0102309:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010230b:	eb b9                	jmp    f01022c6 <strtol+0x76>

	if (endptr)
f010230d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102311:	74 0d                	je     f0102320 <strtol+0xd0>
		*endptr = (char *) s;
f0102313:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102316:	89 0e                	mov    %ecx,(%esi)
f0102318:	eb 06                	jmp    f0102320 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010231a:	85 db                	test   %ebx,%ebx
f010231c:	74 98                	je     f01022b6 <strtol+0x66>
f010231e:	eb 9e                	jmp    f01022be <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0102320:	89 c2                	mov    %eax,%edx
f0102322:	f7 da                	neg    %edx
f0102324:	85 ff                	test   %edi,%edi
f0102326:	0f 45 c2             	cmovne %edx,%eax
}
f0102329:	5b                   	pop    %ebx
f010232a:	5e                   	pop    %esi
f010232b:	5f                   	pop    %edi
f010232c:	5d                   	pop    %ebp
f010232d:	c3                   	ret    
f010232e:	66 90                	xchg   %ax,%ax

f0102330 <__udivdi3>:
f0102330:	55                   	push   %ebp
f0102331:	57                   	push   %edi
f0102332:	56                   	push   %esi
f0102333:	53                   	push   %ebx
f0102334:	83 ec 1c             	sub    $0x1c,%esp
f0102337:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010233b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010233f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0102343:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102347:	85 f6                	test   %esi,%esi
f0102349:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010234d:	89 ca                	mov    %ecx,%edx
f010234f:	89 f8                	mov    %edi,%eax
f0102351:	75 3d                	jne    f0102390 <__udivdi3+0x60>
f0102353:	39 cf                	cmp    %ecx,%edi
f0102355:	0f 87 c5 00 00 00    	ja     f0102420 <__udivdi3+0xf0>
f010235b:	85 ff                	test   %edi,%edi
f010235d:	89 fd                	mov    %edi,%ebp
f010235f:	75 0b                	jne    f010236c <__udivdi3+0x3c>
f0102361:	b8 01 00 00 00       	mov    $0x1,%eax
f0102366:	31 d2                	xor    %edx,%edx
f0102368:	f7 f7                	div    %edi
f010236a:	89 c5                	mov    %eax,%ebp
f010236c:	89 c8                	mov    %ecx,%eax
f010236e:	31 d2                	xor    %edx,%edx
f0102370:	f7 f5                	div    %ebp
f0102372:	89 c1                	mov    %eax,%ecx
f0102374:	89 d8                	mov    %ebx,%eax
f0102376:	89 cf                	mov    %ecx,%edi
f0102378:	f7 f5                	div    %ebp
f010237a:	89 c3                	mov    %eax,%ebx
f010237c:	89 d8                	mov    %ebx,%eax
f010237e:	89 fa                	mov    %edi,%edx
f0102380:	83 c4 1c             	add    $0x1c,%esp
f0102383:	5b                   	pop    %ebx
f0102384:	5e                   	pop    %esi
f0102385:	5f                   	pop    %edi
f0102386:	5d                   	pop    %ebp
f0102387:	c3                   	ret    
f0102388:	90                   	nop
f0102389:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102390:	39 ce                	cmp    %ecx,%esi
f0102392:	77 74                	ja     f0102408 <__udivdi3+0xd8>
f0102394:	0f bd fe             	bsr    %esi,%edi
f0102397:	83 f7 1f             	xor    $0x1f,%edi
f010239a:	0f 84 98 00 00 00    	je     f0102438 <__udivdi3+0x108>
f01023a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01023a5:	89 f9                	mov    %edi,%ecx
f01023a7:	89 c5                	mov    %eax,%ebp
f01023a9:	29 fb                	sub    %edi,%ebx
f01023ab:	d3 e6                	shl    %cl,%esi
f01023ad:	89 d9                	mov    %ebx,%ecx
f01023af:	d3 ed                	shr    %cl,%ebp
f01023b1:	89 f9                	mov    %edi,%ecx
f01023b3:	d3 e0                	shl    %cl,%eax
f01023b5:	09 ee                	or     %ebp,%esi
f01023b7:	89 d9                	mov    %ebx,%ecx
f01023b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01023bd:	89 d5                	mov    %edx,%ebp
f01023bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01023c3:	d3 ed                	shr    %cl,%ebp
f01023c5:	89 f9                	mov    %edi,%ecx
f01023c7:	d3 e2                	shl    %cl,%edx
f01023c9:	89 d9                	mov    %ebx,%ecx
f01023cb:	d3 e8                	shr    %cl,%eax
f01023cd:	09 c2                	or     %eax,%edx
f01023cf:	89 d0                	mov    %edx,%eax
f01023d1:	89 ea                	mov    %ebp,%edx
f01023d3:	f7 f6                	div    %esi
f01023d5:	89 d5                	mov    %edx,%ebp
f01023d7:	89 c3                	mov    %eax,%ebx
f01023d9:	f7 64 24 0c          	mull   0xc(%esp)
f01023dd:	39 d5                	cmp    %edx,%ebp
f01023df:	72 10                	jb     f01023f1 <__udivdi3+0xc1>
f01023e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01023e5:	89 f9                	mov    %edi,%ecx
f01023e7:	d3 e6                	shl    %cl,%esi
f01023e9:	39 c6                	cmp    %eax,%esi
f01023eb:	73 07                	jae    f01023f4 <__udivdi3+0xc4>
f01023ed:	39 d5                	cmp    %edx,%ebp
f01023ef:	75 03                	jne    f01023f4 <__udivdi3+0xc4>
f01023f1:	83 eb 01             	sub    $0x1,%ebx
f01023f4:	31 ff                	xor    %edi,%edi
f01023f6:	89 d8                	mov    %ebx,%eax
f01023f8:	89 fa                	mov    %edi,%edx
f01023fa:	83 c4 1c             	add    $0x1c,%esp
f01023fd:	5b                   	pop    %ebx
f01023fe:	5e                   	pop    %esi
f01023ff:	5f                   	pop    %edi
f0102400:	5d                   	pop    %ebp
f0102401:	c3                   	ret    
f0102402:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102408:	31 ff                	xor    %edi,%edi
f010240a:	31 db                	xor    %ebx,%ebx
f010240c:	89 d8                	mov    %ebx,%eax
f010240e:	89 fa                	mov    %edi,%edx
f0102410:	83 c4 1c             	add    $0x1c,%esp
f0102413:	5b                   	pop    %ebx
f0102414:	5e                   	pop    %esi
f0102415:	5f                   	pop    %edi
f0102416:	5d                   	pop    %ebp
f0102417:	c3                   	ret    
f0102418:	90                   	nop
f0102419:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102420:	89 d8                	mov    %ebx,%eax
f0102422:	f7 f7                	div    %edi
f0102424:	31 ff                	xor    %edi,%edi
f0102426:	89 c3                	mov    %eax,%ebx
f0102428:	89 d8                	mov    %ebx,%eax
f010242a:	89 fa                	mov    %edi,%edx
f010242c:	83 c4 1c             	add    $0x1c,%esp
f010242f:	5b                   	pop    %ebx
f0102430:	5e                   	pop    %esi
f0102431:	5f                   	pop    %edi
f0102432:	5d                   	pop    %ebp
f0102433:	c3                   	ret    
f0102434:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102438:	39 ce                	cmp    %ecx,%esi
f010243a:	72 0c                	jb     f0102448 <__udivdi3+0x118>
f010243c:	31 db                	xor    %ebx,%ebx
f010243e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102442:	0f 87 34 ff ff ff    	ja     f010237c <__udivdi3+0x4c>
f0102448:	bb 01 00 00 00       	mov    $0x1,%ebx
f010244d:	e9 2a ff ff ff       	jmp    f010237c <__udivdi3+0x4c>
f0102452:	66 90                	xchg   %ax,%ax
f0102454:	66 90                	xchg   %ax,%ax
f0102456:	66 90                	xchg   %ax,%ax
f0102458:	66 90                	xchg   %ax,%ax
f010245a:	66 90                	xchg   %ax,%ax
f010245c:	66 90                	xchg   %ax,%ax
f010245e:	66 90                	xchg   %ax,%ax

f0102460 <__umoddi3>:
f0102460:	55                   	push   %ebp
f0102461:	57                   	push   %edi
f0102462:	56                   	push   %esi
f0102463:	53                   	push   %ebx
f0102464:	83 ec 1c             	sub    $0x1c,%esp
f0102467:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010246b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010246f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102473:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102477:	85 d2                	test   %edx,%edx
f0102479:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010247d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102481:	89 f3                	mov    %esi,%ebx
f0102483:	89 3c 24             	mov    %edi,(%esp)
f0102486:	89 74 24 04          	mov    %esi,0x4(%esp)
f010248a:	75 1c                	jne    f01024a8 <__umoddi3+0x48>
f010248c:	39 f7                	cmp    %esi,%edi
f010248e:	76 50                	jbe    f01024e0 <__umoddi3+0x80>
f0102490:	89 c8                	mov    %ecx,%eax
f0102492:	89 f2                	mov    %esi,%edx
f0102494:	f7 f7                	div    %edi
f0102496:	89 d0                	mov    %edx,%eax
f0102498:	31 d2                	xor    %edx,%edx
f010249a:	83 c4 1c             	add    $0x1c,%esp
f010249d:	5b                   	pop    %ebx
f010249e:	5e                   	pop    %esi
f010249f:	5f                   	pop    %edi
f01024a0:	5d                   	pop    %ebp
f01024a1:	c3                   	ret    
f01024a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01024a8:	39 f2                	cmp    %esi,%edx
f01024aa:	89 d0                	mov    %edx,%eax
f01024ac:	77 52                	ja     f0102500 <__umoddi3+0xa0>
f01024ae:	0f bd ea             	bsr    %edx,%ebp
f01024b1:	83 f5 1f             	xor    $0x1f,%ebp
f01024b4:	75 5a                	jne    f0102510 <__umoddi3+0xb0>
f01024b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01024ba:	0f 82 e0 00 00 00    	jb     f01025a0 <__umoddi3+0x140>
f01024c0:	39 0c 24             	cmp    %ecx,(%esp)
f01024c3:	0f 86 d7 00 00 00    	jbe    f01025a0 <__umoddi3+0x140>
f01024c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01024cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01024d1:	83 c4 1c             	add    $0x1c,%esp
f01024d4:	5b                   	pop    %ebx
f01024d5:	5e                   	pop    %esi
f01024d6:	5f                   	pop    %edi
f01024d7:	5d                   	pop    %ebp
f01024d8:	c3                   	ret    
f01024d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01024e0:	85 ff                	test   %edi,%edi
f01024e2:	89 fd                	mov    %edi,%ebp
f01024e4:	75 0b                	jne    f01024f1 <__umoddi3+0x91>
f01024e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01024eb:	31 d2                	xor    %edx,%edx
f01024ed:	f7 f7                	div    %edi
f01024ef:	89 c5                	mov    %eax,%ebp
f01024f1:	89 f0                	mov    %esi,%eax
f01024f3:	31 d2                	xor    %edx,%edx
f01024f5:	f7 f5                	div    %ebp
f01024f7:	89 c8                	mov    %ecx,%eax
f01024f9:	f7 f5                	div    %ebp
f01024fb:	89 d0                	mov    %edx,%eax
f01024fd:	eb 99                	jmp    f0102498 <__umoddi3+0x38>
f01024ff:	90                   	nop
f0102500:	89 c8                	mov    %ecx,%eax
f0102502:	89 f2                	mov    %esi,%edx
f0102504:	83 c4 1c             	add    $0x1c,%esp
f0102507:	5b                   	pop    %ebx
f0102508:	5e                   	pop    %esi
f0102509:	5f                   	pop    %edi
f010250a:	5d                   	pop    %ebp
f010250b:	c3                   	ret    
f010250c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102510:	8b 34 24             	mov    (%esp),%esi
f0102513:	bf 20 00 00 00       	mov    $0x20,%edi
f0102518:	89 e9                	mov    %ebp,%ecx
f010251a:	29 ef                	sub    %ebp,%edi
f010251c:	d3 e0                	shl    %cl,%eax
f010251e:	89 f9                	mov    %edi,%ecx
f0102520:	89 f2                	mov    %esi,%edx
f0102522:	d3 ea                	shr    %cl,%edx
f0102524:	89 e9                	mov    %ebp,%ecx
f0102526:	09 c2                	or     %eax,%edx
f0102528:	89 d8                	mov    %ebx,%eax
f010252a:	89 14 24             	mov    %edx,(%esp)
f010252d:	89 f2                	mov    %esi,%edx
f010252f:	d3 e2                	shl    %cl,%edx
f0102531:	89 f9                	mov    %edi,%ecx
f0102533:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102537:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010253b:	d3 e8                	shr    %cl,%eax
f010253d:	89 e9                	mov    %ebp,%ecx
f010253f:	89 c6                	mov    %eax,%esi
f0102541:	d3 e3                	shl    %cl,%ebx
f0102543:	89 f9                	mov    %edi,%ecx
f0102545:	89 d0                	mov    %edx,%eax
f0102547:	d3 e8                	shr    %cl,%eax
f0102549:	89 e9                	mov    %ebp,%ecx
f010254b:	09 d8                	or     %ebx,%eax
f010254d:	89 d3                	mov    %edx,%ebx
f010254f:	89 f2                	mov    %esi,%edx
f0102551:	f7 34 24             	divl   (%esp)
f0102554:	89 d6                	mov    %edx,%esi
f0102556:	d3 e3                	shl    %cl,%ebx
f0102558:	f7 64 24 04          	mull   0x4(%esp)
f010255c:	39 d6                	cmp    %edx,%esi
f010255e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102562:	89 d1                	mov    %edx,%ecx
f0102564:	89 c3                	mov    %eax,%ebx
f0102566:	72 08                	jb     f0102570 <__umoddi3+0x110>
f0102568:	75 11                	jne    f010257b <__umoddi3+0x11b>
f010256a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010256e:	73 0b                	jae    f010257b <__umoddi3+0x11b>
f0102570:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102574:	1b 14 24             	sbb    (%esp),%edx
f0102577:	89 d1                	mov    %edx,%ecx
f0102579:	89 c3                	mov    %eax,%ebx
f010257b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010257f:	29 da                	sub    %ebx,%edx
f0102581:	19 ce                	sbb    %ecx,%esi
f0102583:	89 f9                	mov    %edi,%ecx
f0102585:	89 f0                	mov    %esi,%eax
f0102587:	d3 e0                	shl    %cl,%eax
f0102589:	89 e9                	mov    %ebp,%ecx
f010258b:	d3 ea                	shr    %cl,%edx
f010258d:	89 e9                	mov    %ebp,%ecx
f010258f:	d3 ee                	shr    %cl,%esi
f0102591:	09 d0                	or     %edx,%eax
f0102593:	89 f2                	mov    %esi,%edx
f0102595:	83 c4 1c             	add    $0x1c,%esp
f0102598:	5b                   	pop    %ebx
f0102599:	5e                   	pop    %esi
f010259a:	5f                   	pop    %edi
f010259b:	5d                   	pop    %ebp
f010259c:	c3                   	ret    
f010259d:	8d 76 00             	lea    0x0(%esi),%esi
f01025a0:	29 f9                	sub    %edi,%ecx
f01025a2:	19 d6                	sbb    %edx,%esi
f01025a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01025a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01025ac:	e9 18 ff ff ff       	jmp    f01024c9 <__umoddi3+0x69>
