
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

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
f0100046:	b8 74 79 11 f0       	mov    $0xf0117974,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 39 33 00 00       	call   f0103396 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 74 04 00 00       	call   f01004d6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 38 10 f0       	push   $0xf0103840
f010006f:	e8 33 28 00 00       	call   f01028a7 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 ae 10 00 00       	call   f0101127 <mem_init>
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
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

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
f01000b0:	68 5b 38 10 f0       	push   $0xf010385b
f01000b5:	e8 ed 27 00 00       	call   f01028a7 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 bd 27 00 00       	call   f0102881 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 ed 40 10 f0 	movl   $0xf01040ed,(%esp)
f01000cb:	e8 d7 27 00 00       	call   f01028a7 <cprintf>
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
f01000f2:	68 73 38 10 f0       	push   $0xf0103873
f01000f7:	e8 ab 27 00 00       	call   f01028a7 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 79 27 00 00       	call   f0102881 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 ed 40 10 f0 	movl   $0xf01040ed,(%esp)
f010010f:	e8 93 27 00 00       	call   f01028a7 <cprintf>
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
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
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
f0100198:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
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
f01001b0:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 e0 39 10 f0 	movzbl -0xfefc620(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 e0 39 10 f0 	movzbl -0xfefc620(%edx),%eax
f0100209:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f010020f:	0f b6 8a e0 38 10 f0 	movzbl -0xfefc720(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d c0 38 10 f0 	mov    -0xfefc740(,%ecx,4),%ecx
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
f0100260:	68 8d 38 10 f0       	push   $0xf010388d
f0100265:	e8 3d 26 00 00       	call   f01028a7 <cprintf>
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
f0100307:	0b 35 64 79 11 f0    	or     0xf0117964,%esi
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
f0100335:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010033c:	66 85 c0             	test   %ax,%ax
f010033f:	0f 84 e3 00 00 00    	je     f0100428 <cons_putc+0x19f>
			crt_pos--;
f0100345:	83 e8 01             	sub    $0x1,%eax
f0100348:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010034e:	0f b7 c0             	movzwl %ax,%eax
f0100351:	b2 00                	mov    $0x0,%dl
f0100353:	83 ca 20             	or     $0x20,%edx
f0100356:	8b 0d 2c 75 11 f0    	mov    0xf011752c,%ecx
f010035c:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100360:	eb 78                	jmp    f01003da <cons_putc+0x151>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100362:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f0100369:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010036a:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100371:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100377:	c1 e8 16             	shr    $0x16,%eax
f010037a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010037d:	c1 e0 04             	shl    $0x4,%eax
f0100380:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f01003bc:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003c3:	8d 48 01             	lea    0x1(%eax),%ecx
f01003c6:	66 89 0d 28 75 11 f0 	mov    %cx,0xf0117528
f01003cd:	0f b7 c0             	movzwl %ax,%eax
f01003d0:	8b 0d 2c 75 11 f0    	mov    0xf011752c,%ecx
f01003d6:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003da:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f01003e1:	cf 07 
f01003e3:	76 43                	jbe    f0100428 <cons_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003e5:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f01003ea:	83 ec 04             	sub    $0x4,%esp
f01003ed:	68 00 0f 00 00       	push   $0xf00
f01003f2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01003f8:	52                   	push   %edx
f01003f9:	50                   	push   %eax
f01003fa:	e8 e4 2f 00 00       	call   f01033e3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01003ff:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
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
f0100420:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100427:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100428:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f010042e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100433:	89 ca                	mov    %ecx,%edx
f0100435:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100436:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
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
f010045e:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
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
f010049c:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004a1:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004a7:	74 26                	je     f01004cf <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004a9:	8d 50 01             	lea    0x1(%eax),%edx
f01004ac:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004b2:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
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
f01004c3:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
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
f01004fc:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
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
f0100514:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
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
f0100523:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
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
f0100548:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f010054e:	0f b6 c0             	movzbl %al,%eax
f0100551:	09 c8                	or     %ecx,%eax
f0100553:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f01005b4:	0f 95 05 34 75 11 f0 	setne  0xf0117534
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
f01005c9:	68 99 38 10 f0       	push   $0xf0103899
f01005ce:	e8 d4 22 00 00       	call   f01028a7 <cprintf>
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
f010060f:	68 e0 3a 10 f0       	push   $0xf0103ae0
f0100614:	68 fe 3a 10 f0       	push   $0xf0103afe
f0100619:	68 03 3b 10 f0       	push   $0xf0103b03
f010061e:	e8 84 22 00 00       	call   f01028a7 <cprintf>
f0100623:	83 c4 0c             	add    $0xc,%esp
f0100626:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010062b:	68 0c 3b 10 f0       	push   $0xf0103b0c
f0100630:	68 03 3b 10 f0       	push   $0xf0103b03
f0100635:	e8 6d 22 00 00       	call   f01028a7 <cprintf>
f010063a:	83 c4 0c             	add    $0xc,%esp
f010063d:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0100642:	68 15 3b 10 f0       	push   $0xf0103b15
f0100647:	68 03 3b 10 f0       	push   $0xf0103b03
f010064c:	e8 56 22 00 00       	call   f01028a7 <cprintf>
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
f010065e:	68 1f 3b 10 f0       	push   $0xf0103b1f
f0100663:	e8 3f 22 00 00       	call   f01028a7 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100668:	83 c4 08             	add    $0x8,%esp
f010066b:	68 0c 00 10 00       	push   $0x10000c
f0100670:	68 64 3c 10 f0       	push   $0xf0103c64
f0100675:	e8 2d 22 00 00       	call   f01028a7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010067a:	83 c4 0c             	add    $0xc,%esp
f010067d:	68 0c 00 10 00       	push   $0x10000c
f0100682:	68 0c 00 10 f0       	push   $0xf010000c
f0100687:	68 8c 3c 10 f0       	push   $0xf0103c8c
f010068c:	e8 16 22 00 00       	call   f01028a7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100691:	83 c4 0c             	add    $0xc,%esp
f0100694:	68 21 38 10 00       	push   $0x103821
f0100699:	68 21 38 10 f0       	push   $0xf0103821
f010069e:	68 b0 3c 10 f0       	push   $0xf0103cb0
f01006a3:	e8 ff 21 00 00       	call   f01028a7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a8:	83 c4 0c             	add    $0xc,%esp
f01006ab:	68 00 73 11 00       	push   $0x117300
f01006b0:	68 00 73 11 f0       	push   $0xf0117300
f01006b5:	68 d4 3c 10 f0       	push   $0xf0103cd4
f01006ba:	e8 e8 21 00 00       	call   f01028a7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bf:	83 c4 0c             	add    $0xc,%esp
f01006c2:	68 74 79 11 00       	push   $0x117974
f01006c7:	68 74 79 11 f0       	push   $0xf0117974
f01006cc:	68 f8 3c 10 f0       	push   $0xf0103cf8
f01006d1:	e8 d1 21 00 00       	call   f01028a7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d6:	b8 73 7d 11 f0       	mov    $0xf0117d73,%eax
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
f01006f7:	68 1c 3d 10 f0       	push   $0xf0103d1c
f01006fc:	e8 a6 21 00 00       	call   f01028a7 <cprintf>
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
f0100713:	68 38 3b 10 f0       	push   $0xf0103b38
f0100718:	e8 8a 21 00 00       	call   f01028a7 <cprintf>

	while(ebp) {
f010071d:	83 c4 10             	add    $0x10,%esp
f0100720:	eb 7f                	jmp    f01007a1 <mon_backtrace+0x99>
		cprintf("ebp %08x ", ebp);
f0100722:	83 ec 08             	sub    $0x8,%esp
f0100725:	56                   	push   %esi
f0100726:	68 4a 3b 10 f0       	push   $0xf0103b4a
f010072b:	e8 77 21 00 00       	call   f01028a7 <cprintf>
		cprintf("eip %08x args", ebp[1]);
f0100730:	83 c4 08             	add    $0x8,%esp
f0100733:	ff 76 04             	pushl  0x4(%esi)
f0100736:	68 54 3b 10 f0       	push   $0xf0103b54
f010073b:	e8 67 21 00 00       	call   f01028a7 <cprintf>
f0100740:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100743:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100746:	83 c4 10             	add    $0x10,%esp
		for(int i = 2; i <= 6; i++)
			cprintf(" %08x", ebp[i]);
f0100749:	83 ec 08             	sub    $0x8,%esp
f010074c:	ff 33                	pushl  (%ebx)
f010074e:	68 62 3b 10 f0       	push   $0xf0103b62
f0100753:	e8 4f 21 00 00       	call   f01028a7 <cprintf>
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
f0100765:	68 ed 40 10 f0       	push   $0xf01040ed
f010076a:	e8 38 21 00 00       	call   f01028a7 <cprintf>

		unsigned int eip = ebp[1];
f010076f:	8b 5e 04             	mov    0x4(%esi),%ebx
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100772:	83 c4 08             	add    $0x8,%esp
f0100775:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100778:	50                   	push   %eax
f0100779:	53                   	push   %ebx
f010077a:	e8 32 22 00 00       	call   f01029b1 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f010077f:	83 c4 08             	add    $0x8,%esp
f0100782:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f0100785:	53                   	push   %ebx
f0100786:	ff 75 d8             	pushl  -0x28(%ebp)
f0100789:	ff 75 dc             	pushl  -0x24(%ebp)
f010078c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010078f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100792:	68 68 3b 10 f0       	push   $0xf0103b68
f0100797:	e8 0b 21 00 00       	call   f01028a7 <cprintf>
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
f01007bf:	68 48 3d 10 f0       	push   $0xf0103d48
f01007c4:	e8 de 20 00 00       	call   f01028a7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007c9:	c7 04 24 6c 3d 10 f0 	movl   $0xf0103d6c,(%esp)
f01007d0:	e8 d2 20 00 00       	call   f01028a7 <cprintf>
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");
f01007d5:	83 c4 0c             	add    $0xc,%esp
f01007d8:	68 79 3b 10 f0       	push   $0xf0103b79
f01007dd:	68 00 04 00 00       	push   $0x400
f01007e2:	68 7d 3b 10 f0       	push   $0xf0103b7d
f01007e7:	68 00 02 00 00       	push   $0x200
f01007ec:	68 83 3b 10 f0       	push   $0xf0103b83
f01007f1:	68 00 01 00 00       	push   $0x100
f01007f6:	68 88 3b 10 f0       	push   $0xf0103b88
f01007fb:	e8 a7 20 00 00       	call   f01028a7 <cprintf>
f0100800:	83 c4 20             	add    $0x20,%esp

	while (1) {
		buf = readline("K> ");
f0100803:	83 ec 0c             	sub    $0xc,%esp
f0100806:	68 98 3b 10 f0       	push   $0xf0103b98
f010080b:	e8 2f 29 00 00       	call   f010313f <readline>
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
f010083f:	68 9c 3b 10 f0       	push   $0xf0103b9c
f0100844:	e8 10 2b 00 00       	call   f0103359 <strchr>
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
f010085f:	68 a1 3b 10 f0       	push   $0xf0103ba1
f0100864:	e8 3e 20 00 00       	call   f01028a7 <cprintf>
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
f0100888:	68 9c 3b 10 f0       	push   $0xf0103b9c
f010088d:	e8 c7 2a 00 00       	call   f0103359 <strchr>
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
f01008b6:	ff 34 85 a0 3d 10 f0 	pushl  -0xfefc260(,%eax,4)
f01008bd:	ff 75 a8             	pushl  -0x58(%ebp)
f01008c0:	e8 36 2a 00 00       	call   f01032fb <strcmp>
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
f01008da:	ff 14 85 a8 3d 10 f0 	call   *-0xfefc258(,%eax,4)
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
f01008fb:	68 be 3b 10 f0       	push   $0xf0103bbe
f0100900:	e8 a2 1f 00 00       	call   f01028a7 <cprintf>
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
f0100915:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f010091c:	75 60                	jne    f010097e <boot_alloc+0x69>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010091e:	ba 73 89 11 f0       	mov    $0xf0118973,%edx
f0100923:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100929:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0) {
f010092f:	85 c0                	test   %eax,%eax
f0100931:	74 42                	je     f0100975 <boot_alloc+0x60>
		result = nextfree;
f0100933:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
		nextfree = ROUNDUP((char*)(nextfree+n), PGSIZE);
f0100939:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100940:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100946:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
		if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
f010094c:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100952:	a1 68 79 11 f0       	mov    0xf0117968,%eax
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
f0100964:	68 c4 3d 10 f0       	push   $0xf0103dc4
f0100969:	6a 6a                	push   $0x6a
f010096b:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100970:	e8 16 f7 ff ff       	call   f010008b <_panic>
//		cprintf("allocate %d bytes, update nextfree to %x\n", n, nextfree);
		return result;
	}
	else if(n == 0)
		return nextfree;
f0100975:	a1 38 75 11 f0       	mov    0xf0117538,%eax
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
f010099a:	3b 0d 68 79 11 f0    	cmp    0xf0117968,%ecx
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
f01009a9:	68 28 41 10 f0       	push   $0xf0104128
f01009ae:	68 ef 02 00 00       	push   $0x2ef
f01009b3:	68 d4 3d 10 f0       	push   $0xf0103dd4
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
f0100a01:	68 4c 41 10 f0       	push   $0xf010414c
f0100a06:	68 24 02 00 00       	push   $0x224
f0100a0b:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100a10:	e8 76 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		cprintf("before hanling low memory question, page_free_list is %x now\n", page_free_list);
f0100a15:	83 ec 08             	sub    $0x8,%esp
f0100a18:	50                   	push   %eax
f0100a19:	68 70 41 10 f0       	push   $0xf0104170
f0100a1e:	e8 84 1e 00 00       	call   f01028a7 <cprintf>
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a23:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100a26:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100a29:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100a2c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a2f:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100a34:	83 c4 10             	add    $0x10,%esp
f0100a37:	eb 20                	jmp    f0100a59 <check_page_free_list+0x71>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a39:	89 c2                	mov    %eax,%edx
f0100a3b:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
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
f0100a71:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
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
f0100a7e:	ff 35 3c 75 11 f0    	pushl  0xf011753c
f0100a84:	68 b0 41 10 f0       	push   $0xf01041b0
f0100a89:	e8 19 1e 00 00       	call   f01028a7 <cprintf>
	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a8e:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a94:	83 c4 10             	add    $0x10,%esp
f0100a97:	eb 53                	jmp    f0100aec <check_page_free_list+0x104>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a99:	89 d8                	mov    %ebx,%eax
f0100a9b:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
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
f0100ab5:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100abb:	72 12                	jb     f0100acf <check_page_free_list+0xe7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100abd:	50                   	push   %eax
f0100abe:	68 28 41 10 f0       	push   $0xf0104128
f0100ac3:	6a 52                	push   $0x52
f0100ac5:	68 e0 3d 10 f0       	push   $0xf0103de0
f0100aca:	e8 bc f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100acf:	83 ec 04             	sub    $0x4,%esp
f0100ad2:	68 80 00 00 00       	push   $0x80
f0100ad7:	68 97 00 00 00       	push   $0x97
f0100adc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ae1:	50                   	push   %eax
f0100ae2:	e8 af 28 00 00       	call   f0103396 <memset>
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
f0100b01:	68 ee 3d 10 f0       	push   $0xf0103dee
f0100b06:	e8 9c 1d 00 00       	call   f01028a7 <cprintf>
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b0b:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b11:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
		assert(pp < pages + npages);
f0100b17:	a1 68 79 11 f0       	mov    0xf0117968,%eax
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
f0100b39:	68 05 3e 10 f0       	push   $0xf0103e05
f0100b3e:	68 11 3e 10 f0       	push   $0xf0103e11
f0100b43:	68 44 02 00 00       	push   $0x244
f0100b48:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100b4d:	e8 39 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b52:	39 fa                	cmp    %edi,%edx
f0100b54:	72 19                	jb     f0100b6f <check_page_free_list+0x187>
f0100b56:	68 26 3e 10 f0       	push   $0xf0103e26
f0100b5b:	68 11 3e 10 f0       	push   $0xf0103e11
f0100b60:	68 45 02 00 00       	push   $0x245
f0100b65:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100b6a:	e8 1c f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b6f:	89 d0                	mov    %edx,%eax
f0100b71:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b74:	a8 07                	test   $0x7,%al
f0100b76:	74 19                	je     f0100b91 <check_page_free_list+0x1a9>
f0100b78:	68 f0 41 10 f0       	push   $0xf01041f0
f0100b7d:	68 11 3e 10 f0       	push   $0xf0103e11
f0100b82:	68 46 02 00 00       	push   $0x246
f0100b87:	68 d4 3d 10 f0       	push   $0xf0103dd4
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
f0100b9b:	68 3a 3e 10 f0       	push   $0xf0103e3a
f0100ba0:	68 11 3e 10 f0       	push   $0xf0103e11
f0100ba5:	68 49 02 00 00       	push   $0x249
f0100baa:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100baf:	e8 d7 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bb4:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bb9:	75 19                	jne    f0100bd4 <check_page_free_list+0x1ec>
f0100bbb:	68 4b 3e 10 f0       	push   $0xf0103e4b
f0100bc0:	68 11 3e 10 f0       	push   $0xf0103e11
f0100bc5:	68 4a 02 00 00       	push   $0x24a
f0100bca:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100bcf:	e8 b7 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bd4:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bd9:	75 19                	jne    f0100bf4 <check_page_free_list+0x20c>
f0100bdb:	68 24 42 10 f0       	push   $0xf0104224
f0100be0:	68 11 3e 10 f0       	push   $0xf0103e11
f0100be5:	68 4b 02 00 00       	push   $0x24b
f0100bea:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100bef:	e8 97 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bf4:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bf9:	75 19                	jne    f0100c14 <check_page_free_list+0x22c>
f0100bfb:	68 64 3e 10 f0       	push   $0xf0103e64
f0100c00:	68 11 3e 10 f0       	push   $0xf0103e11
f0100c05:	68 4c 02 00 00       	push   $0x24c
f0100c0a:	68 d4 3d 10 f0       	push   $0xf0103dd4
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
f0100c26:	68 28 41 10 f0       	push   $0xf0104128
f0100c2b:	6a 52                	push   $0x52
f0100c2d:	68 e0 3d 10 f0       	push   $0xf0103de0
f0100c32:	e8 54 f4 ff ff       	call   f010008b <_panic>
f0100c37:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c3c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c3f:	76 1e                	jbe    f0100c5f <check_page_free_list+0x277>
f0100c41:	68 48 42 10 f0       	push   $0xf0104248
f0100c46:	68 11 3e 10 f0       	push   $0xf0103e11
f0100c4b:	68 4d 02 00 00       	push   $0x24d
f0100c50:	68 d4 3d 10 f0       	push   $0xf0103dd4
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
f0100c75:	68 90 42 10 f0       	push   $0xf0104290
f0100c7a:	e8 28 1c 00 00       	call   f01028a7 <cprintf>

	assert(nfree_basemem > 0);
f0100c7f:	83 c4 10             	add    $0x10,%esp
f0100c82:	85 f6                	test   %esi,%esi
f0100c84:	7f 19                	jg     f0100c9f <check_page_free_list+0x2b7>
f0100c86:	68 7e 3e 10 f0       	push   $0xf0103e7e
f0100c8b:	68 11 3e 10 f0       	push   $0xf0103e11
f0100c90:	68 56 02 00 00       	push   $0x256
f0100c95:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100c9a:	e8 ec f3 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c9f:	85 db                	test   %ebx,%ebx
f0100ca1:	7f 42                	jg     f0100ce5 <check_page_free_list+0x2fd>
f0100ca3:	68 90 3e 10 f0       	push   $0xf0103e90
f0100ca8:	68 11 3e 10 f0       	push   $0xf0103e11
f0100cad:	68 57 02 00 00       	push   $0x257
f0100cb2:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100cb7:	e8 cf f3 ff ff       	call   f010008b <_panic>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;
//	cprintf("we now enter check_page_free_list, pdx_limit is %u, NPDENTRIES is %d\n", pdx_limit, NPDENTRIES);

	if (!page_free_list)
f0100cbc:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100cc1:	85 c0                	test   %eax,%eax
f0100cc3:	0f 85 4c fd ff ff    	jne    f0100a15 <check_page_free_list+0x2d>
f0100cc9:	e9 30 fd ff ff       	jmp    f01009fe <check_page_free_list+0x16>
f0100cce:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
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
f0100cf6:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
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
f0100d12:	8b 15 70 79 11 f0    	mov    0xf0117970,%edx
f0100d18:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	for(i = 1; i < npages_basemem; i++)
f0100d1e:	8b 35 40 75 11 f0    	mov    0xf0117540,%esi
f0100d24:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d29:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d2e:	ba 01 00 00 00       	mov    $0x1,%edx
f0100d33:	eb 27                	jmp    f0100d5c <page_init+0x6f>
	{
		pages[i].pp_ref = 0;
f0100d35:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100d3c:	89 cb                	mov    %ecx,%ebx
f0100d3e:	03 1d 70 79 11 f0    	add    0xf0117970,%ebx
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
f0100d51:	03 3d 70 79 11 f0    	add    0xf0117970,%edi
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
f0100d64:	89 3d 3c 75 11 f0    	mov    %edi,0xf011753c
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
		pages[i].pp_ref = 1;
f0100d6a:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
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
f0100d86:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d8c:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100d93:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d98:	eb 23                	jmp    f0100dbd <page_init+0xd0>
		pages[i].pp_ref = 1;
	for(; i < npages; i++)
	{
		pages[i].pp_ref = 0;
f0100d9a:	89 c1                	mov    %eax,%ecx
f0100d9c:	03 0d 70 79 11 f0    	add    0xf0117970,%ecx
f0100da2:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100da8:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100daa:	89 c3                	mov    %eax,%ebx
f0100dac:	03 1d 70 79 11 f0    	add    0xf0117970,%ebx
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
		pages[i].pp_ref = 1;
	for(; i < npages; i++)
f0100db2:	83 c2 01             	add    $0x1,%edx
f0100db5:	83 c0 08             	add    $0x8,%eax
f0100db8:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100dbd:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100dc3:	72 d5                	jb     f0100d9a <page_init+0xad>
f0100dc5:	84 c9                	test   %cl,%cl
f0100dc7:	74 06                	je     f0100dcf <page_init+0xe2>
f0100dc9:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
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
f0100dde:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
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
f0100df0:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100df6:	c1 f8 03             	sar    $0x3,%eax
f0100df9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dfc:	89 c2                	mov    %eax,%edx
f0100dfe:	c1 ea 0c             	shr    $0xc,%edx
f0100e01:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100e07:	72 12                	jb     f0100e1b <page_alloc+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e09:	50                   	push   %eax
f0100e0a:	68 28 41 10 f0       	push   $0xf0104128
f0100e0f:	6a 52                	push   $0x52
f0100e11:	68 e0 3d 10 f0       	push   $0xf0103de0
f0100e16:	e8 70 f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(pp), 0, PGSIZE);
f0100e1b:	83 ec 04             	sub    $0x4,%esp
f0100e1e:	68 00 10 00 00       	push   $0x1000
f0100e23:	6a 00                	push   $0x0
f0100e25:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e2a:	50                   	push   %eax
f0100e2b:	e8 66 25 00 00       	call   f0103396 <memset>
f0100e30:	83 c4 10             	add    $0x10,%esp
	}
	page_free_list = pp->pp_link;
f0100e33:	8b 03                	mov    (%ebx),%eax
f0100e35:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	pp->pp_link = 0;
f0100e3a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
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
f0100e5a:	68 a1 3e 10 f0       	push   $0xf0103ea1
f0100e5f:	68 4a 01 00 00       	push   $0x14a
f0100e64:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100e69:	e8 1d f2 ff ff       	call   f010008b <_panic>
	if(pp->pp_link)
f0100e6e:	83 38 00             	cmpl   $0x0,(%eax)
f0100e71:	74 17                	je     f0100e8a <page_free+0x43>
		panic("pp->pp_link is not NULL\n");
f0100e73:	83 ec 04             	sub    $0x4,%esp
f0100e76:	68 b8 3e 10 f0       	push   $0xf0103eb8
f0100e7b:	68 4c 01 00 00       	push   $0x14c
f0100e80:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100e85:	e8 01 f2 ff ff       	call   f010008b <_panic>

	pp->pp_link = page_free_list;
f0100e8a:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e90:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e92:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e97:	c9                   	leave  
f0100e98:	c3                   	ret    

f0100e99 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e99:	55                   	push   %ebp
f0100e9a:	89 e5                	mov    %esp,%ebp
f0100e9c:	83 ec 08             	sub    $0x8,%esp
f0100e9f:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100ea2:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100ea6:	83 e8 01             	sub    $0x1,%eax
f0100ea9:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100ead:	66 85 c0             	test   %ax,%ax
f0100eb0:	75 0c                	jne    f0100ebe <page_decref+0x25>
		page_free(pp);
f0100eb2:	83 ec 0c             	sub    $0xc,%esp
f0100eb5:	52                   	push   %edx
f0100eb6:	e8 8c ff ff ff       	call   f0100e47 <page_free>
f0100ebb:	83 c4 10             	add    $0x10,%esp
}
f0100ebe:	c9                   	leave  
f0100ebf:	c3                   	ret    

f0100ec0 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ec0:	55                   	push   %ebp
f0100ec1:	89 e5                	mov    %esp,%ebp
f0100ec3:	56                   	push   %esi
f0100ec4:	53                   	push   %ebx
f0100ec5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pde_t pde = pgdir[PDX(va)];
f0100ec8:	89 de                	mov    %ebx,%esi
f0100eca:	c1 ee 16             	shr    $0x16,%esi
f0100ecd:	c1 e6 02             	shl    $0x2,%esi
f0100ed0:	03 75 08             	add    0x8(%ebp),%esi
f0100ed3:	8b 06                	mov    (%esi),%eax
	pte_t * result;
	if(pde & PTE_P)
f0100ed5:	a8 01                	test   $0x1,%al
f0100ed7:	74 39                	je     f0100f12 <pgdir_walk+0x52>
	{
		pte_t * pg_table_p = KADDR(PTE_ADDR(pde));
f0100ed9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ede:	89 c2                	mov    %eax,%edx
f0100ee0:	c1 ea 0c             	shr    $0xc,%edx
f0100ee3:	39 15 68 79 11 f0    	cmp    %edx,0xf0117968
f0100ee9:	77 15                	ja     f0100f00 <pgdir_walk+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eeb:	50                   	push   %eax
f0100eec:	68 28 41 10 f0       	push   $0xf0104128
f0100ef1:	68 7b 01 00 00       	push   $0x17b
f0100ef6:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100efb:	e8 8b f1 ff ff       	call   f010008b <_panic>
		result = pg_table_p + PTX(va);
f0100f00:	c1 eb 0a             	shr    $0xa,%ebx
f0100f03:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
		return result;
f0100f09:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100f10:	eb 7b                	jmp    f0100f8d <pgdir_walk+0xcd>
	}
	else if(!create)
f0100f12:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f16:	74 69                	je     f0100f81 <pgdir_walk+0xc1>
		return NULL;
	else
	{
		struct PageInfo *pp = page_alloc(1);
f0100f18:	83 ec 0c             	sub    $0xc,%esp
f0100f1b:	6a 01                	push   $0x1
f0100f1d:	e8 b5 fe ff ff       	call   f0100dd7 <page_alloc>
		if(!pp)
f0100f22:	83 c4 10             	add    $0x10,%esp
f0100f25:	85 c0                	test   %eax,%eax
f0100f27:	74 5f                	je     f0100f88 <pgdir_walk+0xc8>
			return NULL;
		else
		{
			pp->pp_ref++;
f0100f29:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W;
f0100f2e:	89 c2                	mov    %eax,%edx
f0100f30:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0100f36:	c1 fa 03             	sar    $0x3,%edx
f0100f39:	c1 e2 0c             	shl    $0xc,%edx
f0100f3c:	83 ca 03             	or     $0x3,%edx
f0100f3f:	89 16                	mov    %edx,(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f41:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100f47:	c1 f8 03             	sar    $0x3,%eax
f0100f4a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f4d:	89 c2                	mov    %eax,%edx
f0100f4f:	c1 ea 0c             	shr    $0xc,%edx
f0100f52:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100f58:	72 15                	jb     f0100f6f <pgdir_walk+0xaf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f5a:	50                   	push   %eax
f0100f5b:	68 28 41 10 f0       	push   $0xf0104128
f0100f60:	68 8a 01 00 00       	push   $0x18a
f0100f65:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100f6a:	e8 1c f1 ff ff       	call   f010008b <_panic>
			pte_t * pg_table_p = KADDR(page2pa(pp));
			result = pg_table_p + PTX(va);
f0100f6f:	c1 eb 0a             	shr    $0xa,%ebx
f0100f72:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
			return result;
f0100f78:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100f7f:	eb 0c                	jmp    f0100f8d <pgdir_walk+0xcd>
		pte_t * pg_table_p = KADDR(PTE_ADDR(pde));
		result = pg_table_p + PTX(va);
		return result;
	}
	else if(!create)
		return NULL;
f0100f81:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f86:	eb 05                	jmp    f0100f8d <pgdir_walk+0xcd>
	else
	{
		struct PageInfo *pp = page_alloc(1);
		if(!pp)
			return NULL;
f0100f88:	b8 00 00 00 00       	mov    $0x0,%eax
			pte_t * pg_table_p = KADDR(page2pa(pp));
			result = pg_table_p + PTX(va);
			return result;
		}
	}
}
f0100f8d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f90:	5b                   	pop    %ebx
f0100f91:	5e                   	pop    %esi
f0100f92:	5d                   	pop    %ebp
f0100f93:	c3                   	ret    

f0100f94 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f94:	55                   	push   %ebp
f0100f95:	89 e5                	mov    %esp,%ebp
f0100f97:	57                   	push   %edi
f0100f98:	56                   	push   %esi
f0100f99:	53                   	push   %ebx
f0100f9a:	83 ec 1c             	sub    $0x1c,%esp
f0100f9d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fa0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fa3:	c1 e9 0c             	shr    $0xc,%ecx
f0100fa6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100fa9:	89 c3                	mov    %eax,%ebx
f0100fab:	be 00 00 00 00       	mov    $0x0,%esi
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
f0100fb0:	89 d7                	mov    %edx,%edi
f0100fb2:	29 c7                	sub    %eax,%edi
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
f0100fb4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fb7:	83 c8 01             	or     $0x1,%eax
f0100fba:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100fbd:	eb 3f                	jmp    f0100ffe <boot_map_region+0x6a>
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
f0100fbf:	83 ec 04             	sub    $0x4,%esp
f0100fc2:	6a 01                	push   $0x1
f0100fc4:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100fc7:	50                   	push   %eax
f0100fc8:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fcb:	e8 f0 fe ff ff       	call   f0100ec0 <pgdir_walk>
        if (!pte) panic("boot_map_region panic, out of memory");
f0100fd0:	83 c4 10             	add    $0x10,%esp
f0100fd3:	85 c0                	test   %eax,%eax
f0100fd5:	75 17                	jne    f0100fee <boot_map_region+0x5a>
f0100fd7:	83 ec 04             	sub    $0x4,%esp
f0100fda:	68 bc 42 10 f0       	push   $0xf01042bc
f0100fdf:	68 a1 01 00 00       	push   $0x1a1
f0100fe4:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100fe9:	e8 9d f0 ff ff       	call   f010008b <_panic>
        *pte = pa | perm | PTE_P;
f0100fee:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ff1:	09 da                	or     %ebx,%edx
f0100ff3:	89 10                	mov    %edx,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
    int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100ff5:	83 c6 01             	add    $0x1,%esi
f0100ff8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100ffe:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101001:	75 bc                	jne    f0100fbf <boot_map_region+0x2b>
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
    }
}
f0101003:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101006:	5b                   	pop    %ebx
f0101007:	5e                   	pop    %esi
f0101008:	5f                   	pop    %edi
f0101009:	5d                   	pop    %ebp
f010100a:	c3                   	ret    

f010100b <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010100b:	55                   	push   %ebp
f010100c:	89 e5                	mov    %esp,%ebp
f010100e:	53                   	push   %ebx
f010100f:	83 ec 08             	sub    $0x8,%esp
f0101012:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 0);
f0101015:	6a 00                	push   $0x0
f0101017:	ff 75 0c             	pushl  0xc(%ebp)
f010101a:	ff 75 08             	pushl  0x8(%ebp)
f010101d:	e8 9e fe ff ff       	call   f0100ec0 <pgdir_walk>
	if(ptep && ((*ptep) & PTE_P)) {
f0101022:	83 c4 10             	add    $0x10,%esp
f0101025:	85 c0                	test   %eax,%eax
f0101027:	74 38                	je     f0101061 <page_lookup+0x56>
f0101029:	89 c1                	mov    %eax,%ecx
f010102b:	8b 10                	mov    (%eax),%edx
f010102d:	f6 c2 01             	test   $0x1,%dl
f0101030:	74 36                	je     f0101068 <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101032:	c1 ea 0c             	shr    $0xc,%edx
f0101035:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f010103b:	72 14                	jb     f0101051 <page_lookup+0x46>
		panic("pa2page called with invalid pa");
f010103d:	83 ec 04             	sub    $0x4,%esp
f0101040:	68 e4 42 10 f0       	push   $0xf01042e4
f0101045:	6a 4b                	push   $0x4b
f0101047:	68 e0 3d 10 f0       	push   $0xf0103de0
f010104c:	e8 3a f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0101051:	a1 70 79 11 f0       	mov    0xf0117970,%eax
f0101056:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		physaddr_t pa = PTE_ADDR(*ptep);
		struct PageInfo * result = pa2page(pa);
		if(pte_store)
f0101059:	85 db                	test   %ebx,%ebx
f010105b:	74 10                	je     f010106d <page_lookup+0x62>
			*pte_store = ptep;
f010105d:	89 0b                	mov    %ecx,(%ebx)
f010105f:	eb 0c                	jmp    f010106d <page_lookup+0x62>
		return result;
	}
	return NULL;
f0101061:	b8 00 00 00 00       	mov    $0x0,%eax
f0101066:	eb 05                	jmp    f010106d <page_lookup+0x62>
f0101068:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010106d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101070:	c9                   	leave  
f0101071:	c3                   	ret    

f0101072 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101072:	55                   	push   %ebp
f0101073:	89 e5                	mov    %esp,%ebp
f0101075:	53                   	push   %ebx
f0101076:	83 ec 18             	sub    $0x18,%esp
f0101079:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t * ptep;
	struct PageInfo *pp = page_lookup(pgdir, va, &ptep);
f010107c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010107f:	50                   	push   %eax
f0101080:	53                   	push   %ebx
f0101081:	ff 75 08             	pushl  0x8(%ebp)
f0101084:	e8 82 ff ff ff       	call   f010100b <page_lookup>
	if(!pp || !(*ptep & PTE_P))
f0101089:	83 c4 10             	add    $0x10,%esp
f010108c:	85 c0                	test   %eax,%eax
f010108e:	74 20                	je     f01010b0 <page_remove+0x3e>
f0101090:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101093:	f6 02 01             	testb  $0x1,(%edx)
f0101096:	74 18                	je     f01010b0 <page_remove+0x3e>
		return;
	page_decref(pp);		// the ref count of the physical page should decrement
f0101098:	83 ec 0c             	sub    $0xc,%esp
f010109b:	50                   	push   %eax
f010109c:	e8 f8 fd ff ff       	call   f0100e99 <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010a1:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);	// the TLB must be invalidated if you remove an entry from the page table
	*ptep = 0;
f01010a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010a7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01010ad:	83 c4 10             	add    $0x10,%esp
}
f01010b0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010b3:	c9                   	leave  
f01010b4:	c3                   	ret    

f01010b5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01010b5:	55                   	push   %ebp
f01010b6:	89 e5                	mov    %esp,%ebp
f01010b8:	57                   	push   %edi
f01010b9:	56                   	push   %esi
f01010ba:	53                   	push   %ebx
f01010bb:	83 ec 10             	sub    $0x10,%esp
f01010be:	8b 75 08             	mov    0x8(%ebp),%esi
f01010c1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 1);
f01010c4:	6a 01                	push   $0x1
f01010c6:	ff 75 10             	pushl  0x10(%ebp)
f01010c9:	56                   	push   %esi
f01010ca:	e8 f1 fd ff ff       	call   f0100ec0 <pgdir_walk>
	if(ptep == NULL)
f01010cf:	83 c4 10             	add    $0x10,%esp
f01010d2:	85 c0                	test   %eax,%eax
f01010d4:	74 44                	je     f010111a <page_insert+0x65>
f01010d6:	89 c7                	mov    %eax,%edi
		return -E_NO_MEM;

	pp->pp_ref++;
f01010d8:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*ptep) & PTE_P)
f01010dd:	f6 00 01             	testb  $0x1,(%eax)
f01010e0:	74 0f                	je     f01010f1 <page_insert+0x3c>
		page_remove(pgdir, va);
f01010e2:	83 ec 08             	sub    $0x8,%esp
f01010e5:	ff 75 10             	pushl  0x10(%ebp)
f01010e8:	56                   	push   %esi
f01010e9:	e8 84 ff ff ff       	call   f0101072 <page_remove>
f01010ee:	83 c4 10             	add    $0x10,%esp

	*ptep  = page2pa(pp) | PTE_P | perm;
f01010f1:	2b 1d 70 79 11 f0    	sub    0xf0117970,%ebx
f01010f7:	c1 fb 03             	sar    $0x3,%ebx
f01010fa:	c1 e3 0c             	shl    $0xc,%ebx
f01010fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0101100:	83 c8 01             	or     $0x1,%eax
f0101103:	09 c3                	or     %eax,%ebx
f0101105:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;
f0101107:	8b 45 10             	mov    0x10(%ebp),%eax
f010110a:	c1 e8 16             	shr    $0x16,%eax
f010110d:	8b 55 14             	mov    0x14(%ebp),%edx
f0101110:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f0101113:	b8 00 00 00 00       	mov    $0x0,%eax
f0101118:	eb 05                	jmp    f010111f <page_insert+0x6a>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 1);
	if(ptep == NULL)
		return -E_NO_MEM;
f010111a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);

	*ptep  = page2pa(pp) | PTE_P | perm;
	pgdir[PDX(va)] |= perm;
	return 0;
}
f010111f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101122:	5b                   	pop    %ebx
f0101123:	5e                   	pop    %esi
f0101124:	5f                   	pop    %edi
f0101125:	5d                   	pop    %ebp
f0101126:	c3                   	ret    

f0101127 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101127:	55                   	push   %ebp
f0101128:	89 e5                	mov    %esp,%ebp
f010112a:	57                   	push   %edi
f010112b:	56                   	push   %esi
f010112c:	53                   	push   %ebx
f010112d:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101130:	6a 15                	push   $0x15
f0101132:	e8 09 17 00 00       	call   f0102840 <mc146818_read>
f0101137:	89 c3                	mov    %eax,%ebx
f0101139:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101140:	e8 fb 16 00 00       	call   f0102840 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101145:	c1 e0 08             	shl    $0x8,%eax
f0101148:	09 d8                	or     %ebx,%eax
f010114a:	c1 e0 0a             	shl    $0xa,%eax
f010114d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101153:	85 c0                	test   %eax,%eax
f0101155:	0f 48 c2             	cmovs  %edx,%eax
f0101158:	c1 f8 0c             	sar    $0xc,%eax
f010115b:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101160:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101167:	e8 d4 16 00 00       	call   f0102840 <mc146818_read>
f010116c:	89 c3                	mov    %eax,%ebx
f010116e:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101175:	e8 c6 16 00 00       	call   f0102840 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010117a:	c1 e0 08             	shl    $0x8,%eax
f010117d:	09 d8                	or     %ebx,%eax
f010117f:	c1 e0 0a             	shl    $0xa,%eax
f0101182:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101188:	83 c4 10             	add    $0x10,%esp
f010118b:	85 c0                	test   %eax,%eax
f010118d:	0f 49 d8             	cmovns %eax,%ebx
f0101190:	c1 fb 0c             	sar    $0xc,%ebx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101193:	85 db                	test   %ebx,%ebx
f0101195:	74 0d                	je     f01011a4 <mem_init+0x7d>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101197:	8d 83 00 01 00 00    	lea    0x100(%ebx),%eax
f010119d:	a3 68 79 11 f0       	mov    %eax,0xf0117968
f01011a2:	eb 0a                	jmp    f01011ae <mem_init+0x87>
	else
		npages = npages_basemem;
f01011a4:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f01011a9:	a3 68 79 11 f0       	mov    %eax,0xf0117968

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01011ae:	89 d8                	mov    %ebx,%eax
f01011b0:	c1 e0 0c             	shl    $0xc,%eax
f01011b3:	c1 e8 0a             	shr    $0xa,%eax
f01011b6:	50                   	push   %eax
f01011b7:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f01011bc:	c1 e0 0c             	shl    $0xc,%eax
f01011bf:	c1 e8 0a             	shr    $0xa,%eax
f01011c2:	50                   	push   %eax
f01011c3:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01011c8:	c1 e0 0c             	shl    $0xc,%eax
f01011cb:	c1 e8 0a             	shr    $0xa,%eax
f01011ce:	50                   	push   %eax
f01011cf:	68 04 43 10 f0       	push   $0xf0104304
f01011d4:	e8 ce 16 00 00       	call   f01028a7 <cprintf>
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
	cprintf("npages is %u, npages_basemem is %u, npages_extmem is %u\n", npages, npages_basemem, npages_extmem);
f01011d9:	53                   	push   %ebx
f01011da:	ff 35 40 75 11 f0    	pushl  0xf0117540
f01011e0:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01011e6:	68 40 43 10 f0       	push   $0xf0104340
f01011eb:	e8 b7 16 00 00       	call   f01028a7 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01011f0:	83 c4 20             	add    $0x20,%esp
f01011f3:	b8 00 10 00 00       	mov    $0x1000,%eax
f01011f8:	e8 18 f7 ff ff       	call   f0100915 <boot_alloc>
f01011fd:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(kern_pgdir, 0, PGSIZE);
f0101202:	83 ec 04             	sub    $0x4,%esp
f0101205:	68 00 10 00 00       	push   $0x1000
f010120a:	6a 00                	push   $0x0
f010120c:	50                   	push   %eax
f010120d:	e8 84 21 00 00       	call   f0103396 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101212:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101217:	83 c4 10             	add    $0x10,%esp
f010121a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010121f:	77 15                	ja     f0101236 <mem_init+0x10f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101221:	50                   	push   %eax
f0101222:	68 7c 43 10 f0       	push   $0xf010437c
f0101227:	68 94 00 00 00       	push   $0x94
f010122c:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101231:	e8 55 ee ff ff       	call   f010008b <_panic>
f0101236:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010123c:	83 ca 05             	or     $0x5,%edx
f010123f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101245:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010124a:	c1 e0 03             	shl    $0x3,%eax
f010124d:	e8 c3 f6 ff ff       	call   f0100915 <boot_alloc>
f0101252:	a3 70 79 11 f0       	mov    %eax,0xf0117970
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101257:	83 ec 04             	sub    $0x4,%esp
f010125a:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101260:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101267:	52                   	push   %edx
f0101268:	6a 00                	push   $0x0
f010126a:	50                   	push   %eax
f010126b:	e8 26 21 00 00       	call   f0103396 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101270:	e8 78 fa ff ff       	call   f0100ced <page_init>

	check_page_free_list(1);
f0101275:	b8 01 00 00 00       	mov    $0x1,%eax
f010127a:	e8 69 f7 ff ff       	call   f01009e8 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010127f:	83 c4 10             	add    $0x10,%esp
f0101282:	83 3d 70 79 11 f0 00 	cmpl   $0x0,0xf0117970
f0101289:	75 17                	jne    f01012a2 <mem_init+0x17b>
		panic("'pages' is a null pointer!");
f010128b:	83 ec 04             	sub    $0x4,%esp
f010128e:	68 d1 3e 10 f0       	push   $0xf0103ed1
f0101293:	68 69 02 00 00       	push   $0x269
f0101298:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010129d:	e8 e9 ed ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012a2:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01012a7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01012ac:	eb 05                	jmp    f01012b3 <mem_init+0x18c>
		++nfree;
f01012ae:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012b1:	8b 00                	mov    (%eax),%eax
f01012b3:	85 c0                	test   %eax,%eax
f01012b5:	75 f7                	jne    f01012ae <mem_init+0x187>
		++nfree;

	cprintf("should be able to allocate three pages\n");
f01012b7:	83 ec 0c             	sub    $0xc,%esp
f01012ba:	68 a0 43 10 f0       	push   $0xf01043a0
f01012bf:	e8 e3 15 00 00       	call   f01028a7 <cprintf>
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012cb:	e8 07 fb ff ff       	call   f0100dd7 <page_alloc>
f01012d0:	89 c7                	mov    %eax,%edi
f01012d2:	83 c4 10             	add    $0x10,%esp
f01012d5:	85 c0                	test   %eax,%eax
f01012d7:	75 19                	jne    f01012f2 <mem_init+0x1cb>
f01012d9:	68 ec 3e 10 f0       	push   $0xf0103eec
f01012de:	68 11 3e 10 f0       	push   $0xf0103e11
f01012e3:	68 72 02 00 00       	push   $0x272
f01012e8:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01012ed:	e8 99 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01012f2:	83 ec 0c             	sub    $0xc,%esp
f01012f5:	6a 00                	push   $0x0
f01012f7:	e8 db fa ff ff       	call   f0100dd7 <page_alloc>
f01012fc:	89 c6                	mov    %eax,%esi
f01012fe:	83 c4 10             	add    $0x10,%esp
f0101301:	85 c0                	test   %eax,%eax
f0101303:	75 19                	jne    f010131e <mem_init+0x1f7>
f0101305:	68 02 3f 10 f0       	push   $0xf0103f02
f010130a:	68 11 3e 10 f0       	push   $0xf0103e11
f010130f:	68 73 02 00 00       	push   $0x273
f0101314:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101319:	e8 6d ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010131e:	83 ec 0c             	sub    $0xc,%esp
f0101321:	6a 00                	push   $0x0
f0101323:	e8 af fa ff ff       	call   f0100dd7 <page_alloc>
f0101328:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010132b:	83 c4 10             	add    $0x10,%esp
f010132e:	85 c0                	test   %eax,%eax
f0101330:	75 19                	jne    f010134b <mem_init+0x224>
f0101332:	68 18 3f 10 f0       	push   $0xf0103f18
f0101337:	68 11 3e 10 f0       	push   $0xf0103e11
f010133c:	68 74 02 00 00       	push   $0x274
f0101341:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101346:	e8 40 ed ff ff       	call   f010008b <_panic>

//	cprintf("pp0 is %x, pp0->pp_ref is %d, pp0->pp_link is %x\n", pp0, pp0->pp_ref, pp0->pp_link);
//	cprintf("pp1 is %x, pp1->pp_ref is %d, pp1->pp_link is %x\n", pp1, pp1->pp_ref, pp1->pp_link);
//  cprintf("pp2 is %x, pp2->pp_ref is %d, pp2->pp_link is %x\n", pp2, pp2->pp_ref, pp2->pp_link);
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010134b:	39 f7                	cmp    %esi,%edi
f010134d:	75 19                	jne    f0101368 <mem_init+0x241>
f010134f:	68 2e 3f 10 f0       	push   $0xf0103f2e
f0101354:	68 11 3e 10 f0       	push   $0xf0103e11
f0101359:	68 7a 02 00 00       	push   $0x27a
f010135e:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101363:	e8 23 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101368:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010136b:	39 c6                	cmp    %eax,%esi
f010136d:	74 04                	je     f0101373 <mem_init+0x24c>
f010136f:	39 c7                	cmp    %eax,%edi
f0101371:	75 19                	jne    f010138c <mem_init+0x265>
f0101373:	68 c8 43 10 f0       	push   $0xf01043c8
f0101378:	68 11 3e 10 f0       	push   $0xf0103e11
f010137d:	68 7b 02 00 00       	push   $0x27b
f0101382:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101387:	e8 ff ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010138c:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101392:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101398:	c1 e2 0c             	shl    $0xc,%edx
f010139b:	89 f8                	mov    %edi,%eax
f010139d:	29 c8                	sub    %ecx,%eax
f010139f:	c1 f8 03             	sar    $0x3,%eax
f01013a2:	c1 e0 0c             	shl    $0xc,%eax
f01013a5:	39 d0                	cmp    %edx,%eax
f01013a7:	72 19                	jb     f01013c2 <mem_init+0x29b>
f01013a9:	68 40 3f 10 f0       	push   $0xf0103f40
f01013ae:	68 11 3e 10 f0       	push   $0xf0103e11
f01013b3:	68 7c 02 00 00       	push   $0x27c
f01013b8:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01013bd:	e8 c9 ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01013c2:	89 f0                	mov    %esi,%eax
f01013c4:	29 c8                	sub    %ecx,%eax
f01013c6:	c1 f8 03             	sar    $0x3,%eax
f01013c9:	c1 e0 0c             	shl    $0xc,%eax
f01013cc:	39 c2                	cmp    %eax,%edx
f01013ce:	77 19                	ja     f01013e9 <mem_init+0x2c2>
f01013d0:	68 5d 3f 10 f0       	push   $0xf0103f5d
f01013d5:	68 11 3e 10 f0       	push   $0xf0103e11
f01013da:	68 7d 02 00 00       	push   $0x27d
f01013df:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01013e4:	e8 a2 ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013ec:	29 c8                	sub    %ecx,%eax
f01013ee:	c1 f8 03             	sar    $0x3,%eax
f01013f1:	c1 e0 0c             	shl    $0xc,%eax
f01013f4:	39 c2                	cmp    %eax,%edx
f01013f6:	77 19                	ja     f0101411 <mem_init+0x2ea>
f01013f8:	68 7a 3f 10 f0       	push   $0xf0103f7a
f01013fd:	68 11 3e 10 f0       	push   $0xf0103e11
f0101402:	68 7e 02 00 00       	push   $0x27e
f0101407:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010140c:	e8 7a ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101411:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101416:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101419:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101420:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101423:	83 ec 0c             	sub    $0xc,%esp
f0101426:	6a 00                	push   $0x0
f0101428:	e8 aa f9 ff ff       	call   f0100dd7 <page_alloc>
f010142d:	83 c4 10             	add    $0x10,%esp
f0101430:	85 c0                	test   %eax,%eax
f0101432:	74 19                	je     f010144d <mem_init+0x326>
f0101434:	68 97 3f 10 f0       	push   $0xf0103f97
f0101439:	68 11 3e 10 f0       	push   $0xf0103e11
f010143e:	68 85 02 00 00       	push   $0x285
f0101443:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101448:	e8 3e ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010144d:	83 ec 0c             	sub    $0xc,%esp
f0101450:	57                   	push   %edi
f0101451:	e8 f1 f9 ff ff       	call   f0100e47 <page_free>
	page_free(pp1);
f0101456:	89 34 24             	mov    %esi,(%esp)
f0101459:	e8 e9 f9 ff ff       	call   f0100e47 <page_free>
	page_free(pp2);
f010145e:	83 c4 04             	add    $0x4,%esp
f0101461:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101464:	e8 de f9 ff ff       	call   f0100e47 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101469:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101470:	e8 62 f9 ff ff       	call   f0100dd7 <page_alloc>
f0101475:	89 c6                	mov    %eax,%esi
f0101477:	83 c4 10             	add    $0x10,%esp
f010147a:	85 c0                	test   %eax,%eax
f010147c:	75 19                	jne    f0101497 <mem_init+0x370>
f010147e:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101483:	68 11 3e 10 f0       	push   $0xf0103e11
f0101488:	68 8c 02 00 00       	push   $0x28c
f010148d:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101492:	e8 f4 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101497:	83 ec 0c             	sub    $0xc,%esp
f010149a:	6a 00                	push   $0x0
f010149c:	e8 36 f9 ff ff       	call   f0100dd7 <page_alloc>
f01014a1:	89 c7                	mov    %eax,%edi
f01014a3:	83 c4 10             	add    $0x10,%esp
f01014a6:	85 c0                	test   %eax,%eax
f01014a8:	75 19                	jne    f01014c3 <mem_init+0x39c>
f01014aa:	68 02 3f 10 f0       	push   $0xf0103f02
f01014af:	68 11 3e 10 f0       	push   $0xf0103e11
f01014b4:	68 8d 02 00 00       	push   $0x28d
f01014b9:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01014be:	e8 c8 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01014c3:	83 ec 0c             	sub    $0xc,%esp
f01014c6:	6a 00                	push   $0x0
f01014c8:	e8 0a f9 ff ff       	call   f0100dd7 <page_alloc>
f01014cd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014d0:	83 c4 10             	add    $0x10,%esp
f01014d3:	85 c0                	test   %eax,%eax
f01014d5:	75 19                	jne    f01014f0 <mem_init+0x3c9>
f01014d7:	68 18 3f 10 f0       	push   $0xf0103f18
f01014dc:	68 11 3e 10 f0       	push   $0xf0103e11
f01014e1:	68 8e 02 00 00       	push   $0x28e
f01014e6:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01014eb:	e8 9b eb ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014f0:	39 fe                	cmp    %edi,%esi
f01014f2:	75 19                	jne    f010150d <mem_init+0x3e6>
f01014f4:	68 2e 3f 10 f0       	push   $0xf0103f2e
f01014f9:	68 11 3e 10 f0       	push   $0xf0103e11
f01014fe:	68 90 02 00 00       	push   $0x290
f0101503:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101508:	e8 7e eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010150d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101510:	39 c6                	cmp    %eax,%esi
f0101512:	74 04                	je     f0101518 <mem_init+0x3f1>
f0101514:	39 c7                	cmp    %eax,%edi
f0101516:	75 19                	jne    f0101531 <mem_init+0x40a>
f0101518:	68 c8 43 10 f0       	push   $0xf01043c8
f010151d:	68 11 3e 10 f0       	push   $0xf0103e11
f0101522:	68 91 02 00 00       	push   $0x291
f0101527:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010152c:	e8 5a eb ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101531:	83 ec 0c             	sub    $0xc,%esp
f0101534:	6a 00                	push   $0x0
f0101536:	e8 9c f8 ff ff       	call   f0100dd7 <page_alloc>
f010153b:	83 c4 10             	add    $0x10,%esp
f010153e:	85 c0                	test   %eax,%eax
f0101540:	74 19                	je     f010155b <mem_init+0x434>
f0101542:	68 97 3f 10 f0       	push   $0xf0103f97
f0101547:	68 11 3e 10 f0       	push   $0xf0103e11
f010154c:	68 92 02 00 00       	push   $0x292
f0101551:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101556:	e8 30 eb ff ff       	call   f010008b <_panic>

	cprintf("test flags\n");
f010155b:	83 ec 0c             	sub    $0xc,%esp
f010155e:	68 a6 3f 10 f0       	push   $0xf0103fa6
f0101563:	e8 3f 13 00 00       	call   f01028a7 <cprintf>
f0101568:	89 f0                	mov    %esi,%eax
f010156a:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101570:	c1 f8 03             	sar    $0x3,%eax
f0101573:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101576:	89 c2                	mov    %eax,%edx
f0101578:	c1 ea 0c             	shr    $0xc,%edx
f010157b:	83 c4 10             	add    $0x10,%esp
f010157e:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0101584:	72 12                	jb     f0101598 <mem_init+0x471>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101586:	50                   	push   %eax
f0101587:	68 28 41 10 f0       	push   $0xf0104128
f010158c:	6a 52                	push   $0x52
f010158e:	68 e0 3d 10 f0       	push   $0xf0103de0
f0101593:	e8 f3 ea ff ff       	call   f010008b <_panic>
	// test flags
	cprintf("page2kva(pp0) is %x\n", page2kva(pp0));
f0101598:	83 ec 08             	sub    $0x8,%esp
f010159b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015a0:	50                   	push   %eax
f01015a1:	68 b2 3f 10 f0       	push   $0xf0103fb2
f01015a6:	e8 fc 12 00 00       	call   f01028a7 <cprintf>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015ab:	89 f0                	mov    %esi,%eax
f01015ad:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01015b3:	c1 f8 03             	sar    $0x3,%eax
f01015b6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015b9:	89 c2                	mov    %eax,%edx
f01015bb:	c1 ea 0c             	shr    $0xc,%edx
f01015be:	83 c4 10             	add    $0x10,%esp
f01015c1:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f01015c7:	72 12                	jb     f01015db <mem_init+0x4b4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015c9:	50                   	push   %eax
f01015ca:	68 28 41 10 f0       	push   $0xf0104128
f01015cf:	6a 52                	push   $0x52
f01015d1:	68 e0 3d 10 f0       	push   $0xf0103de0
f01015d6:	e8 b0 ea ff ff       	call   f010008b <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f01015db:	83 ec 04             	sub    $0x4,%esp
f01015de:	68 00 10 00 00       	push   $0x1000
f01015e3:	6a 01                	push   $0x1
f01015e5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015ea:	50                   	push   %eax
f01015eb:	e8 a6 1d 00 00       	call   f0103396 <memset>
	page_free(pp0);
f01015f0:	89 34 24             	mov    %esi,(%esp)
f01015f3:	e8 4f f8 ff ff       	call   f0100e47 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015f8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015ff:	e8 d3 f7 ff ff       	call   f0100dd7 <page_alloc>
f0101604:	83 c4 10             	add    $0x10,%esp
f0101607:	85 c0                	test   %eax,%eax
f0101609:	75 19                	jne    f0101624 <mem_init+0x4fd>
f010160b:	68 c7 3f 10 f0       	push   $0xf0103fc7
f0101610:	68 11 3e 10 f0       	push   $0xf0103e11
f0101615:	68 99 02 00 00       	push   $0x299
f010161a:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010161f:	e8 67 ea ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101624:	39 c6                	cmp    %eax,%esi
f0101626:	74 19                	je     f0101641 <mem_init+0x51a>
f0101628:	68 e5 3f 10 f0       	push   $0xf0103fe5
f010162d:	68 11 3e 10 f0       	push   $0xf0103e11
f0101632:	68 9a 02 00 00       	push   $0x29a
f0101637:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010163c:	e8 4a ea ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101641:	89 f0                	mov    %esi,%eax
f0101643:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101649:	c1 f8 03             	sar    $0x3,%eax
f010164c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010164f:	89 c2                	mov    %eax,%edx
f0101651:	c1 ea 0c             	shr    $0xc,%edx
f0101654:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f010165a:	72 12                	jb     f010166e <mem_init+0x547>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010165c:	50                   	push   %eax
f010165d:	68 28 41 10 f0       	push   $0xf0104128
f0101662:	6a 52                	push   $0x52
f0101664:	68 e0 3d 10 f0       	push   $0xf0103de0
f0101669:	e8 1d ea ff ff       	call   f010008b <_panic>
f010166e:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101674:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010167a:	80 38 00             	cmpb   $0x0,(%eax)
f010167d:	74 19                	je     f0101698 <mem_init+0x571>
f010167f:	68 f5 3f 10 f0       	push   $0xf0103ff5
f0101684:	68 11 3e 10 f0       	push   $0xf0103e11
f0101689:	68 9d 02 00 00       	push   $0x29d
f010168e:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101693:	e8 f3 e9 ff ff       	call   f010008b <_panic>
f0101698:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010169b:	39 d0                	cmp    %edx,%eax
f010169d:	75 db                	jne    f010167a <mem_init+0x553>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010169f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016a2:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01016a7:	83 ec 0c             	sub    $0xc,%esp
f01016aa:	56                   	push   %esi
f01016ab:	e8 97 f7 ff ff       	call   f0100e47 <page_free>
	page_free(pp1);
f01016b0:	89 3c 24             	mov    %edi,(%esp)
f01016b3:	e8 8f f7 ff ff       	call   f0100e47 <page_free>
	page_free(pp2);
f01016b8:	83 c4 04             	add    $0x4,%esp
f01016bb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016be:	e8 84 f7 ff ff       	call   f0100e47 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016c3:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01016c8:	83 c4 10             	add    $0x10,%esp
f01016cb:	eb 05                	jmp    f01016d2 <mem_init+0x5ab>
		--nfree;
f01016cd:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016d0:	8b 00                	mov    (%eax),%eax
f01016d2:	85 c0                	test   %eax,%eax
f01016d4:	75 f7                	jne    f01016cd <mem_init+0x5a6>
		--nfree;
	assert(nfree == 0);
f01016d6:	85 db                	test   %ebx,%ebx
f01016d8:	74 19                	je     f01016f3 <mem_init+0x5cc>
f01016da:	68 ff 3f 10 f0       	push   $0xf0103fff
f01016df:	68 11 3e 10 f0       	push   $0xf0103e11
f01016e4:	68 aa 02 00 00       	push   $0x2aa
f01016e9:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01016ee:	e8 98 e9 ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01016f3:	83 ec 0c             	sub    $0xc,%esp
f01016f6:	68 e8 43 10 f0       	push   $0xf01043e8
f01016fb:	e8 a7 11 00 00       	call   f01028a7 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101700:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101707:	e8 cb f6 ff ff       	call   f0100dd7 <page_alloc>
f010170c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010170f:	83 c4 10             	add    $0x10,%esp
f0101712:	85 c0                	test   %eax,%eax
f0101714:	75 19                	jne    f010172f <mem_init+0x608>
f0101716:	68 ec 3e 10 f0       	push   $0xf0103eec
f010171b:	68 11 3e 10 f0       	push   $0xf0103e11
f0101720:	68 03 03 00 00       	push   $0x303
f0101725:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010172a:	e8 5c e9 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010172f:	83 ec 0c             	sub    $0xc,%esp
f0101732:	6a 00                	push   $0x0
f0101734:	e8 9e f6 ff ff       	call   f0100dd7 <page_alloc>
f0101739:	89 c3                	mov    %eax,%ebx
f010173b:	83 c4 10             	add    $0x10,%esp
f010173e:	85 c0                	test   %eax,%eax
f0101740:	75 19                	jne    f010175b <mem_init+0x634>
f0101742:	68 02 3f 10 f0       	push   $0xf0103f02
f0101747:	68 11 3e 10 f0       	push   $0xf0103e11
f010174c:	68 04 03 00 00       	push   $0x304
f0101751:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101756:	e8 30 e9 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010175b:	83 ec 0c             	sub    $0xc,%esp
f010175e:	6a 00                	push   $0x0
f0101760:	e8 72 f6 ff ff       	call   f0100dd7 <page_alloc>
f0101765:	89 c6                	mov    %eax,%esi
f0101767:	83 c4 10             	add    $0x10,%esp
f010176a:	85 c0                	test   %eax,%eax
f010176c:	75 19                	jne    f0101787 <mem_init+0x660>
f010176e:	68 18 3f 10 f0       	push   $0xf0103f18
f0101773:	68 11 3e 10 f0       	push   $0xf0103e11
f0101778:	68 05 03 00 00       	push   $0x305
f010177d:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101782:	e8 04 e9 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101787:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010178a:	75 19                	jne    f01017a5 <mem_init+0x67e>
f010178c:	68 2e 3f 10 f0       	push   $0xf0103f2e
f0101791:	68 11 3e 10 f0       	push   $0xf0103e11
f0101796:	68 08 03 00 00       	push   $0x308
f010179b:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01017a0:	e8 e6 e8 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017a5:	39 c3                	cmp    %eax,%ebx
f01017a7:	74 05                	je     f01017ae <mem_init+0x687>
f01017a9:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01017ac:	75 19                	jne    f01017c7 <mem_init+0x6a0>
f01017ae:	68 c8 43 10 f0       	push   $0xf01043c8
f01017b3:	68 11 3e 10 f0       	push   $0xf0103e11
f01017b8:	68 09 03 00 00       	push   $0x309
f01017bd:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01017c2:	e8 c4 e8 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017c7:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01017cc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01017cf:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01017d6:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01017d9:	83 ec 0c             	sub    $0xc,%esp
f01017dc:	6a 00                	push   $0x0
f01017de:	e8 f4 f5 ff ff       	call   f0100dd7 <page_alloc>
f01017e3:	83 c4 10             	add    $0x10,%esp
f01017e6:	85 c0                	test   %eax,%eax
f01017e8:	74 19                	je     f0101803 <mem_init+0x6dc>
f01017ea:	68 97 3f 10 f0       	push   $0xf0103f97
f01017ef:	68 11 3e 10 f0       	push   $0xf0103e11
f01017f4:	68 10 03 00 00       	push   $0x310
f01017f9:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01017fe:	e8 88 e8 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101803:	83 ec 04             	sub    $0x4,%esp
f0101806:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101809:	50                   	push   %eax
f010180a:	6a 00                	push   $0x0
f010180c:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101812:	e8 f4 f7 ff ff       	call   f010100b <page_lookup>
f0101817:	83 c4 10             	add    $0x10,%esp
f010181a:	85 c0                	test   %eax,%eax
f010181c:	74 19                	je     f0101837 <mem_init+0x710>
f010181e:	68 08 44 10 f0       	push   $0xf0104408
f0101823:	68 11 3e 10 f0       	push   $0xf0103e11
f0101828:	68 13 03 00 00       	push   $0x313
f010182d:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101832:	e8 54 e8 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101837:	6a 02                	push   $0x2
f0101839:	6a 00                	push   $0x0
f010183b:	53                   	push   %ebx
f010183c:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101842:	e8 6e f8 ff ff       	call   f01010b5 <page_insert>
f0101847:	83 c4 10             	add    $0x10,%esp
f010184a:	85 c0                	test   %eax,%eax
f010184c:	78 19                	js     f0101867 <mem_init+0x740>
f010184e:	68 40 44 10 f0       	push   $0xf0104440
f0101853:	68 11 3e 10 f0       	push   $0xf0103e11
f0101858:	68 16 03 00 00       	push   $0x316
f010185d:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101862:	e8 24 e8 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101867:	83 ec 0c             	sub    $0xc,%esp
f010186a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010186d:	e8 d5 f5 ff ff       	call   f0100e47 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101872:	6a 02                	push   $0x2
f0101874:	6a 00                	push   $0x0
f0101876:	53                   	push   %ebx
f0101877:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f010187d:	e8 33 f8 ff ff       	call   f01010b5 <page_insert>
f0101882:	83 c4 20             	add    $0x20,%esp
f0101885:	85 c0                	test   %eax,%eax
f0101887:	74 19                	je     f01018a2 <mem_init+0x77b>
f0101889:	68 70 44 10 f0       	push   $0xf0104470
f010188e:	68 11 3e 10 f0       	push   $0xf0103e11
f0101893:	68 1a 03 00 00       	push   $0x31a
f0101898:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010189d:	e8 e9 e7 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01018a2:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018a8:	a1 70 79 11 f0       	mov    0xf0117970,%eax
f01018ad:	89 c1                	mov    %eax,%ecx
f01018af:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01018b2:	8b 17                	mov    (%edi),%edx
f01018b4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01018ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018bd:	29 c8                	sub    %ecx,%eax
f01018bf:	c1 f8 03             	sar    $0x3,%eax
f01018c2:	c1 e0 0c             	shl    $0xc,%eax
f01018c5:	39 c2                	cmp    %eax,%edx
f01018c7:	74 19                	je     f01018e2 <mem_init+0x7bb>
f01018c9:	68 a0 44 10 f0       	push   $0xf01044a0
f01018ce:	68 11 3e 10 f0       	push   $0xf0103e11
f01018d3:	68 1b 03 00 00       	push   $0x31b
f01018d8:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01018dd:	e8 a9 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01018e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01018e7:	89 f8                	mov    %edi,%eax
f01018e9:	e8 96 f0 ff ff       	call   f0100984 <check_va2pa>
f01018ee:	89 da                	mov    %ebx,%edx
f01018f0:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01018f3:	c1 fa 03             	sar    $0x3,%edx
f01018f6:	c1 e2 0c             	shl    $0xc,%edx
f01018f9:	39 d0                	cmp    %edx,%eax
f01018fb:	74 19                	je     f0101916 <mem_init+0x7ef>
f01018fd:	68 c8 44 10 f0       	push   $0xf01044c8
f0101902:	68 11 3e 10 f0       	push   $0xf0103e11
f0101907:	68 1c 03 00 00       	push   $0x31c
f010190c:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101911:	e8 75 e7 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101916:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010191b:	74 19                	je     f0101936 <mem_init+0x80f>
f010191d:	68 0a 40 10 f0       	push   $0xf010400a
f0101922:	68 11 3e 10 f0       	push   $0xf0103e11
f0101927:	68 1d 03 00 00       	push   $0x31d
f010192c:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101931:	e8 55 e7 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101936:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101939:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010193e:	74 19                	je     f0101959 <mem_init+0x832>
f0101940:	68 1b 40 10 f0       	push   $0xf010401b
f0101945:	68 11 3e 10 f0       	push   $0xf0103e11
f010194a:	68 1e 03 00 00       	push   $0x31e
f010194f:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101954:	e8 32 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101959:	6a 02                	push   $0x2
f010195b:	68 00 10 00 00       	push   $0x1000
f0101960:	56                   	push   %esi
f0101961:	57                   	push   %edi
f0101962:	e8 4e f7 ff ff       	call   f01010b5 <page_insert>
f0101967:	83 c4 10             	add    $0x10,%esp
f010196a:	85 c0                	test   %eax,%eax
f010196c:	74 19                	je     f0101987 <mem_init+0x860>
f010196e:	68 f8 44 10 f0       	push   $0xf01044f8
f0101973:	68 11 3e 10 f0       	push   $0xf0103e11
f0101978:	68 21 03 00 00       	push   $0x321
f010197d:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101982:	e8 04 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101987:	ba 00 10 00 00       	mov    $0x1000,%edx
f010198c:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101991:	e8 ee ef ff ff       	call   f0100984 <check_va2pa>
f0101996:	89 f2                	mov    %esi,%edx
f0101998:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f010199e:	c1 fa 03             	sar    $0x3,%edx
f01019a1:	c1 e2 0c             	shl    $0xc,%edx
f01019a4:	39 d0                	cmp    %edx,%eax
f01019a6:	74 19                	je     f01019c1 <mem_init+0x89a>
f01019a8:	68 34 45 10 f0       	push   $0xf0104534
f01019ad:	68 11 3e 10 f0       	push   $0xf0103e11
f01019b2:	68 22 03 00 00       	push   $0x322
f01019b7:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01019bc:	e8 ca e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019c1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019c6:	74 19                	je     f01019e1 <mem_init+0x8ba>
f01019c8:	68 2c 40 10 f0       	push   $0xf010402c
f01019cd:	68 11 3e 10 f0       	push   $0xf0103e11
f01019d2:	68 23 03 00 00       	push   $0x323
f01019d7:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01019dc:	e8 aa e6 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01019e1:	83 ec 0c             	sub    $0xc,%esp
f01019e4:	6a 00                	push   $0x0
f01019e6:	e8 ec f3 ff ff       	call   f0100dd7 <page_alloc>
f01019eb:	83 c4 10             	add    $0x10,%esp
f01019ee:	85 c0                	test   %eax,%eax
f01019f0:	74 19                	je     f0101a0b <mem_init+0x8e4>
f01019f2:	68 97 3f 10 f0       	push   $0xf0103f97
f01019f7:	68 11 3e 10 f0       	push   $0xf0103e11
f01019fc:	68 26 03 00 00       	push   $0x326
f0101a01:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101a06:	e8 80 e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a0b:	6a 02                	push   $0x2
f0101a0d:	68 00 10 00 00       	push   $0x1000
f0101a12:	56                   	push   %esi
f0101a13:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101a19:	e8 97 f6 ff ff       	call   f01010b5 <page_insert>
f0101a1e:	83 c4 10             	add    $0x10,%esp
f0101a21:	85 c0                	test   %eax,%eax
f0101a23:	74 19                	je     f0101a3e <mem_init+0x917>
f0101a25:	68 f8 44 10 f0       	push   $0xf01044f8
f0101a2a:	68 11 3e 10 f0       	push   $0xf0103e11
f0101a2f:	68 29 03 00 00       	push   $0x329
f0101a34:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101a39:	e8 4d e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a3e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a43:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101a48:	e8 37 ef ff ff       	call   f0100984 <check_va2pa>
f0101a4d:	89 f2                	mov    %esi,%edx
f0101a4f:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101a55:	c1 fa 03             	sar    $0x3,%edx
f0101a58:	c1 e2 0c             	shl    $0xc,%edx
f0101a5b:	39 d0                	cmp    %edx,%eax
f0101a5d:	74 19                	je     f0101a78 <mem_init+0x951>
f0101a5f:	68 34 45 10 f0       	push   $0xf0104534
f0101a64:	68 11 3e 10 f0       	push   $0xf0103e11
f0101a69:	68 2a 03 00 00       	push   $0x32a
f0101a6e:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101a73:	e8 13 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a78:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a7d:	74 19                	je     f0101a98 <mem_init+0x971>
f0101a7f:	68 2c 40 10 f0       	push   $0xf010402c
f0101a84:	68 11 3e 10 f0       	push   $0xf0103e11
f0101a89:	68 2b 03 00 00       	push   $0x32b
f0101a8e:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101a93:	e8 f3 e5 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a98:	83 ec 0c             	sub    $0xc,%esp
f0101a9b:	6a 00                	push   $0x0
f0101a9d:	e8 35 f3 ff ff       	call   f0100dd7 <page_alloc>
f0101aa2:	83 c4 10             	add    $0x10,%esp
f0101aa5:	85 c0                	test   %eax,%eax
f0101aa7:	74 19                	je     f0101ac2 <mem_init+0x99b>
f0101aa9:	68 97 3f 10 f0       	push   $0xf0103f97
f0101aae:	68 11 3e 10 f0       	push   $0xf0103e11
f0101ab3:	68 2f 03 00 00       	push   $0x32f
f0101ab8:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101abd:	e8 c9 e5 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ac2:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0101ac8:	8b 02                	mov    (%edx),%eax
f0101aca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101acf:	89 c1                	mov    %eax,%ecx
f0101ad1:	c1 e9 0c             	shr    $0xc,%ecx
f0101ad4:	3b 0d 68 79 11 f0    	cmp    0xf0117968,%ecx
f0101ada:	72 15                	jb     f0101af1 <mem_init+0x9ca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101adc:	50                   	push   %eax
f0101add:	68 28 41 10 f0       	push   $0xf0104128
f0101ae2:	68 32 03 00 00       	push   $0x332
f0101ae7:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101aec:	e8 9a e5 ff ff       	call   f010008b <_panic>
f0101af1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101af6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101af9:	83 ec 04             	sub    $0x4,%esp
f0101afc:	6a 00                	push   $0x0
f0101afe:	68 00 10 00 00       	push   $0x1000
f0101b03:	52                   	push   %edx
f0101b04:	e8 b7 f3 ff ff       	call   f0100ec0 <pgdir_walk>
f0101b09:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b0c:	8d 51 04             	lea    0x4(%ecx),%edx
f0101b0f:	83 c4 10             	add    $0x10,%esp
f0101b12:	39 d0                	cmp    %edx,%eax
f0101b14:	74 19                	je     f0101b2f <mem_init+0xa08>
f0101b16:	68 64 45 10 f0       	push   $0xf0104564
f0101b1b:	68 11 3e 10 f0       	push   $0xf0103e11
f0101b20:	68 33 03 00 00       	push   $0x333
f0101b25:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101b2a:	e8 5c e5 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b2f:	6a 06                	push   $0x6
f0101b31:	68 00 10 00 00       	push   $0x1000
f0101b36:	56                   	push   %esi
f0101b37:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101b3d:	e8 73 f5 ff ff       	call   f01010b5 <page_insert>
f0101b42:	83 c4 10             	add    $0x10,%esp
f0101b45:	85 c0                	test   %eax,%eax
f0101b47:	74 19                	je     f0101b62 <mem_init+0xa3b>
f0101b49:	68 a4 45 10 f0       	push   $0xf01045a4
f0101b4e:	68 11 3e 10 f0       	push   $0xf0103e11
f0101b53:	68 36 03 00 00       	push   $0x336
f0101b58:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101b5d:	e8 29 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b62:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0101b68:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b6d:	89 f8                	mov    %edi,%eax
f0101b6f:	e8 10 ee ff ff       	call   f0100984 <check_va2pa>
f0101b74:	89 f2                	mov    %esi,%edx
f0101b76:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101b7c:	c1 fa 03             	sar    $0x3,%edx
f0101b7f:	c1 e2 0c             	shl    $0xc,%edx
f0101b82:	39 d0                	cmp    %edx,%eax
f0101b84:	74 19                	je     f0101b9f <mem_init+0xa78>
f0101b86:	68 34 45 10 f0       	push   $0xf0104534
f0101b8b:	68 11 3e 10 f0       	push   $0xf0103e11
f0101b90:	68 37 03 00 00       	push   $0x337
f0101b95:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101b9a:	e8 ec e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101b9f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ba4:	74 19                	je     f0101bbf <mem_init+0xa98>
f0101ba6:	68 2c 40 10 f0       	push   $0xf010402c
f0101bab:	68 11 3e 10 f0       	push   $0xf0103e11
f0101bb0:	68 38 03 00 00       	push   $0x338
f0101bb5:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101bba:	e8 cc e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bbf:	83 ec 04             	sub    $0x4,%esp
f0101bc2:	6a 00                	push   $0x0
f0101bc4:	68 00 10 00 00       	push   $0x1000
f0101bc9:	57                   	push   %edi
f0101bca:	e8 f1 f2 ff ff       	call   f0100ec0 <pgdir_walk>
f0101bcf:	83 c4 10             	add    $0x10,%esp
f0101bd2:	f6 00 04             	testb  $0x4,(%eax)
f0101bd5:	75 19                	jne    f0101bf0 <mem_init+0xac9>
f0101bd7:	68 e4 45 10 f0       	push   $0xf01045e4
f0101bdc:	68 11 3e 10 f0       	push   $0xf0103e11
f0101be1:	68 39 03 00 00       	push   $0x339
f0101be6:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101beb:	e8 9b e4 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101bf0:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101bf5:	f6 00 04             	testb  $0x4,(%eax)
f0101bf8:	75 19                	jne    f0101c13 <mem_init+0xaec>
f0101bfa:	68 3d 40 10 f0       	push   $0xf010403d
f0101bff:	68 11 3e 10 f0       	push   $0xf0103e11
f0101c04:	68 3a 03 00 00       	push   $0x33a
f0101c09:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101c0e:	e8 78 e4 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c13:	6a 02                	push   $0x2
f0101c15:	68 00 10 00 00       	push   $0x1000
f0101c1a:	56                   	push   %esi
f0101c1b:	50                   	push   %eax
f0101c1c:	e8 94 f4 ff ff       	call   f01010b5 <page_insert>
f0101c21:	83 c4 10             	add    $0x10,%esp
f0101c24:	85 c0                	test   %eax,%eax
f0101c26:	74 19                	je     f0101c41 <mem_init+0xb1a>
f0101c28:	68 f8 44 10 f0       	push   $0xf01044f8
f0101c2d:	68 11 3e 10 f0       	push   $0xf0103e11
f0101c32:	68 3d 03 00 00       	push   $0x33d
f0101c37:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101c3c:	e8 4a e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c41:	83 ec 04             	sub    $0x4,%esp
f0101c44:	6a 00                	push   $0x0
f0101c46:	68 00 10 00 00       	push   $0x1000
f0101c4b:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101c51:	e8 6a f2 ff ff       	call   f0100ec0 <pgdir_walk>
f0101c56:	83 c4 10             	add    $0x10,%esp
f0101c59:	f6 00 02             	testb  $0x2,(%eax)
f0101c5c:	75 19                	jne    f0101c77 <mem_init+0xb50>
f0101c5e:	68 18 46 10 f0       	push   $0xf0104618
f0101c63:	68 11 3e 10 f0       	push   $0xf0103e11
f0101c68:	68 3e 03 00 00       	push   $0x33e
f0101c6d:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101c72:	e8 14 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c77:	83 ec 04             	sub    $0x4,%esp
f0101c7a:	6a 00                	push   $0x0
f0101c7c:	68 00 10 00 00       	push   $0x1000
f0101c81:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101c87:	e8 34 f2 ff ff       	call   f0100ec0 <pgdir_walk>
f0101c8c:	83 c4 10             	add    $0x10,%esp
f0101c8f:	f6 00 04             	testb  $0x4,(%eax)
f0101c92:	74 19                	je     f0101cad <mem_init+0xb86>
f0101c94:	68 4c 46 10 f0       	push   $0xf010464c
f0101c99:	68 11 3e 10 f0       	push   $0xf0103e11
f0101c9e:	68 3f 03 00 00       	push   $0x33f
f0101ca3:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101ca8:	e8 de e3 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101cad:	6a 02                	push   $0x2
f0101caf:	68 00 00 40 00       	push   $0x400000
f0101cb4:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101cb7:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101cbd:	e8 f3 f3 ff ff       	call   f01010b5 <page_insert>
f0101cc2:	83 c4 10             	add    $0x10,%esp
f0101cc5:	85 c0                	test   %eax,%eax
f0101cc7:	78 19                	js     f0101ce2 <mem_init+0xbbb>
f0101cc9:	68 84 46 10 f0       	push   $0xf0104684
f0101cce:	68 11 3e 10 f0       	push   $0xf0103e11
f0101cd3:	68 42 03 00 00       	push   $0x342
f0101cd8:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101cdd:	e8 a9 e3 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ce2:	6a 02                	push   $0x2
f0101ce4:	68 00 10 00 00       	push   $0x1000
f0101ce9:	53                   	push   %ebx
f0101cea:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101cf0:	e8 c0 f3 ff ff       	call   f01010b5 <page_insert>
f0101cf5:	83 c4 10             	add    $0x10,%esp
f0101cf8:	85 c0                	test   %eax,%eax
f0101cfa:	74 19                	je     f0101d15 <mem_init+0xbee>
f0101cfc:	68 bc 46 10 f0       	push   $0xf01046bc
f0101d01:	68 11 3e 10 f0       	push   $0xf0103e11
f0101d06:	68 45 03 00 00       	push   $0x345
f0101d0b:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101d10:	e8 76 e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d15:	83 ec 04             	sub    $0x4,%esp
f0101d18:	6a 00                	push   $0x0
f0101d1a:	68 00 10 00 00       	push   $0x1000
f0101d1f:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101d25:	e8 96 f1 ff ff       	call   f0100ec0 <pgdir_walk>
f0101d2a:	83 c4 10             	add    $0x10,%esp
f0101d2d:	f6 00 04             	testb  $0x4,(%eax)
f0101d30:	74 19                	je     f0101d4b <mem_init+0xc24>
f0101d32:	68 4c 46 10 f0       	push   $0xf010464c
f0101d37:	68 11 3e 10 f0       	push   $0xf0103e11
f0101d3c:	68 46 03 00 00       	push   $0x346
f0101d41:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101d46:	e8 40 e3 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d4b:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0101d51:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d56:	89 f8                	mov    %edi,%eax
f0101d58:	e8 27 ec ff ff       	call   f0100984 <check_va2pa>
f0101d5d:	89 c1                	mov    %eax,%ecx
f0101d5f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d62:	89 d8                	mov    %ebx,%eax
f0101d64:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101d6a:	c1 f8 03             	sar    $0x3,%eax
f0101d6d:	c1 e0 0c             	shl    $0xc,%eax
f0101d70:	39 c1                	cmp    %eax,%ecx
f0101d72:	74 19                	je     f0101d8d <mem_init+0xc66>
f0101d74:	68 f8 46 10 f0       	push   $0xf01046f8
f0101d79:	68 11 3e 10 f0       	push   $0xf0103e11
f0101d7e:	68 49 03 00 00       	push   $0x349
f0101d83:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101d88:	e8 fe e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d8d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d92:	89 f8                	mov    %edi,%eax
f0101d94:	e8 eb eb ff ff       	call   f0100984 <check_va2pa>
f0101d99:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d9c:	74 19                	je     f0101db7 <mem_init+0xc90>
f0101d9e:	68 24 47 10 f0       	push   $0xf0104724
f0101da3:	68 11 3e 10 f0       	push   $0xf0103e11
f0101da8:	68 4a 03 00 00       	push   $0x34a
f0101dad:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101db2:	e8 d4 e2 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101db7:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101dbc:	74 19                	je     f0101dd7 <mem_init+0xcb0>
f0101dbe:	68 53 40 10 f0       	push   $0xf0104053
f0101dc3:	68 11 3e 10 f0       	push   $0xf0103e11
f0101dc8:	68 4c 03 00 00       	push   $0x34c
f0101dcd:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101dd2:	e8 b4 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101dd7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ddc:	74 19                	je     f0101df7 <mem_init+0xcd0>
f0101dde:	68 64 40 10 f0       	push   $0xf0104064
f0101de3:	68 11 3e 10 f0       	push   $0xf0103e11
f0101de8:	68 4d 03 00 00       	push   $0x34d
f0101ded:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101df2:	e8 94 e2 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101df7:	83 ec 0c             	sub    $0xc,%esp
f0101dfa:	6a 00                	push   $0x0
f0101dfc:	e8 d6 ef ff ff       	call   f0100dd7 <page_alloc>
f0101e01:	83 c4 10             	add    $0x10,%esp
f0101e04:	39 c6                	cmp    %eax,%esi
f0101e06:	75 04                	jne    f0101e0c <mem_init+0xce5>
f0101e08:	85 c0                	test   %eax,%eax
f0101e0a:	75 19                	jne    f0101e25 <mem_init+0xcfe>
f0101e0c:	68 54 47 10 f0       	push   $0xf0104754
f0101e11:	68 11 3e 10 f0       	push   $0xf0103e11
f0101e16:	68 50 03 00 00       	push   $0x350
f0101e1b:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101e20:	e8 66 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e25:	83 ec 08             	sub    $0x8,%esp
f0101e28:	6a 00                	push   $0x0
f0101e2a:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101e30:	e8 3d f2 ff ff       	call   f0101072 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e35:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0101e3b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e40:	89 f8                	mov    %edi,%eax
f0101e42:	e8 3d eb ff ff       	call   f0100984 <check_va2pa>
f0101e47:	83 c4 10             	add    $0x10,%esp
f0101e4a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e4d:	74 19                	je     f0101e68 <mem_init+0xd41>
f0101e4f:	68 78 47 10 f0       	push   $0xf0104778
f0101e54:	68 11 3e 10 f0       	push   $0xf0103e11
f0101e59:	68 54 03 00 00       	push   $0x354
f0101e5e:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101e63:	e8 23 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e68:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e6d:	89 f8                	mov    %edi,%eax
f0101e6f:	e8 10 eb ff ff       	call   f0100984 <check_va2pa>
f0101e74:	89 da                	mov    %ebx,%edx
f0101e76:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101e7c:	c1 fa 03             	sar    $0x3,%edx
f0101e7f:	c1 e2 0c             	shl    $0xc,%edx
f0101e82:	39 d0                	cmp    %edx,%eax
f0101e84:	74 19                	je     f0101e9f <mem_init+0xd78>
f0101e86:	68 24 47 10 f0       	push   $0xf0104724
f0101e8b:	68 11 3e 10 f0       	push   $0xf0103e11
f0101e90:	68 55 03 00 00       	push   $0x355
f0101e95:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101e9a:	e8 ec e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101e9f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ea4:	74 19                	je     f0101ebf <mem_init+0xd98>
f0101ea6:	68 0a 40 10 f0       	push   $0xf010400a
f0101eab:	68 11 3e 10 f0       	push   $0xf0103e11
f0101eb0:	68 56 03 00 00       	push   $0x356
f0101eb5:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101eba:	e8 cc e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ebf:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ec4:	74 19                	je     f0101edf <mem_init+0xdb8>
f0101ec6:	68 64 40 10 f0       	push   $0xf0104064
f0101ecb:	68 11 3e 10 f0       	push   $0xf0103e11
f0101ed0:	68 57 03 00 00       	push   $0x357
f0101ed5:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101eda:	e8 ac e1 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101edf:	6a 00                	push   $0x0
f0101ee1:	68 00 10 00 00       	push   $0x1000
f0101ee6:	53                   	push   %ebx
f0101ee7:	57                   	push   %edi
f0101ee8:	e8 c8 f1 ff ff       	call   f01010b5 <page_insert>
f0101eed:	83 c4 10             	add    $0x10,%esp
f0101ef0:	85 c0                	test   %eax,%eax
f0101ef2:	74 19                	je     f0101f0d <mem_init+0xde6>
f0101ef4:	68 9c 47 10 f0       	push   $0xf010479c
f0101ef9:	68 11 3e 10 f0       	push   $0xf0103e11
f0101efe:	68 5a 03 00 00       	push   $0x35a
f0101f03:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101f08:	e8 7e e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101f0d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f12:	75 19                	jne    f0101f2d <mem_init+0xe06>
f0101f14:	68 75 40 10 f0       	push   $0xf0104075
f0101f19:	68 11 3e 10 f0       	push   $0xf0103e11
f0101f1e:	68 5b 03 00 00       	push   $0x35b
f0101f23:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101f28:	e8 5e e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101f2d:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f30:	74 19                	je     f0101f4b <mem_init+0xe24>
f0101f32:	68 81 40 10 f0       	push   $0xf0104081
f0101f37:	68 11 3e 10 f0       	push   $0xf0103e11
f0101f3c:	68 5c 03 00 00       	push   $0x35c
f0101f41:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101f46:	e8 40 e1 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f4b:	83 ec 08             	sub    $0x8,%esp
f0101f4e:	68 00 10 00 00       	push   $0x1000
f0101f53:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101f59:	e8 14 f1 ff ff       	call   f0101072 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f5e:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0101f64:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f69:	89 f8                	mov    %edi,%eax
f0101f6b:	e8 14 ea ff ff       	call   f0100984 <check_va2pa>
f0101f70:	83 c4 10             	add    $0x10,%esp
f0101f73:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f76:	74 19                	je     f0101f91 <mem_init+0xe6a>
f0101f78:	68 78 47 10 f0       	push   $0xf0104778
f0101f7d:	68 11 3e 10 f0       	push   $0xf0103e11
f0101f82:	68 60 03 00 00       	push   $0x360
f0101f87:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101f8c:	e8 fa e0 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f91:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f96:	89 f8                	mov    %edi,%eax
f0101f98:	e8 e7 e9 ff ff       	call   f0100984 <check_va2pa>
f0101f9d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fa0:	74 19                	je     f0101fbb <mem_init+0xe94>
f0101fa2:	68 d4 47 10 f0       	push   $0xf01047d4
f0101fa7:	68 11 3e 10 f0       	push   $0xf0103e11
f0101fac:	68 61 03 00 00       	push   $0x361
f0101fb1:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101fb6:	e8 d0 e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101fbb:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fc0:	74 19                	je     f0101fdb <mem_init+0xeb4>
f0101fc2:	68 96 40 10 f0       	push   $0xf0104096
f0101fc7:	68 11 3e 10 f0       	push   $0xf0103e11
f0101fcc:	68 62 03 00 00       	push   $0x362
f0101fd1:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101fd6:	e8 b0 e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101fdb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fe0:	74 19                	je     f0101ffb <mem_init+0xed4>
f0101fe2:	68 64 40 10 f0       	push   $0xf0104064
f0101fe7:	68 11 3e 10 f0       	push   $0xf0103e11
f0101fec:	68 63 03 00 00       	push   $0x363
f0101ff1:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0101ff6:	e8 90 e0 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ffb:	83 ec 0c             	sub    $0xc,%esp
f0101ffe:	6a 00                	push   $0x0
f0102000:	e8 d2 ed ff ff       	call   f0100dd7 <page_alloc>
f0102005:	83 c4 10             	add    $0x10,%esp
f0102008:	85 c0                	test   %eax,%eax
f010200a:	74 04                	je     f0102010 <mem_init+0xee9>
f010200c:	39 c3                	cmp    %eax,%ebx
f010200e:	74 19                	je     f0102029 <mem_init+0xf02>
f0102010:	68 fc 47 10 f0       	push   $0xf01047fc
f0102015:	68 11 3e 10 f0       	push   $0xf0103e11
f010201a:	68 66 03 00 00       	push   $0x366
f010201f:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102024:	e8 62 e0 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102029:	83 ec 0c             	sub    $0xc,%esp
f010202c:	6a 00                	push   $0x0
f010202e:	e8 a4 ed ff ff       	call   f0100dd7 <page_alloc>
f0102033:	83 c4 10             	add    $0x10,%esp
f0102036:	85 c0                	test   %eax,%eax
f0102038:	74 19                	je     f0102053 <mem_init+0xf2c>
f010203a:	68 97 3f 10 f0       	push   $0xf0103f97
f010203f:	68 11 3e 10 f0       	push   $0xf0103e11
f0102044:	68 69 03 00 00       	push   $0x369
f0102049:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010204e:	e8 38 e0 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102053:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0102059:	8b 11                	mov    (%ecx),%edx
f010205b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102061:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102064:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f010206a:	c1 f8 03             	sar    $0x3,%eax
f010206d:	c1 e0 0c             	shl    $0xc,%eax
f0102070:	39 c2                	cmp    %eax,%edx
f0102072:	74 19                	je     f010208d <mem_init+0xf66>
f0102074:	68 a0 44 10 f0       	push   $0xf01044a0
f0102079:	68 11 3e 10 f0       	push   $0xf0103e11
f010207e:	68 6c 03 00 00       	push   $0x36c
f0102083:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102088:	e8 fe df ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010208d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102093:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102096:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010209b:	74 19                	je     f01020b6 <mem_init+0xf8f>
f010209d:	68 1b 40 10 f0       	push   $0xf010401b
f01020a2:	68 11 3e 10 f0       	push   $0xf0103e11
f01020a7:	68 6e 03 00 00       	push   $0x36e
f01020ac:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01020b1:	e8 d5 df ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01020b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020bf:	83 ec 0c             	sub    $0xc,%esp
f01020c2:	50                   	push   %eax
f01020c3:	e8 7f ed ff ff       	call   f0100e47 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020c8:	83 c4 0c             	add    $0xc,%esp
f01020cb:	6a 01                	push   $0x1
f01020cd:	68 00 10 40 00       	push   $0x401000
f01020d2:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01020d8:	e8 e3 ed ff ff       	call   f0100ec0 <pgdir_walk>
f01020dd:	89 c7                	mov    %eax,%edi
f01020df:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020e2:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01020e7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020ea:	8b 40 04             	mov    0x4(%eax),%eax
f01020ed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020f2:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f01020f8:	89 c2                	mov    %eax,%edx
f01020fa:	c1 ea 0c             	shr    $0xc,%edx
f01020fd:	83 c4 10             	add    $0x10,%esp
f0102100:	39 ca                	cmp    %ecx,%edx
f0102102:	72 15                	jb     f0102119 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102104:	50                   	push   %eax
f0102105:	68 28 41 10 f0       	push   $0xf0104128
f010210a:	68 75 03 00 00       	push   $0x375
f010210f:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102114:	e8 72 df ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102119:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010211e:	39 c7                	cmp    %eax,%edi
f0102120:	74 19                	je     f010213b <mem_init+0x1014>
f0102122:	68 a7 40 10 f0       	push   $0xf01040a7
f0102127:	68 11 3e 10 f0       	push   $0xf0103e11
f010212c:	68 76 03 00 00       	push   $0x376
f0102131:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102136:	e8 50 df ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f010213b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010213e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102145:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102148:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010214e:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0102154:	c1 f8 03             	sar    $0x3,%eax
f0102157:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010215a:	89 c2                	mov    %eax,%edx
f010215c:	c1 ea 0c             	shr    $0xc,%edx
f010215f:	39 d1                	cmp    %edx,%ecx
f0102161:	77 12                	ja     f0102175 <mem_init+0x104e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102163:	50                   	push   %eax
f0102164:	68 28 41 10 f0       	push   $0xf0104128
f0102169:	6a 52                	push   $0x52
f010216b:	68 e0 3d 10 f0       	push   $0xf0103de0
f0102170:	e8 16 df ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102175:	83 ec 04             	sub    $0x4,%esp
f0102178:	68 00 10 00 00       	push   $0x1000
f010217d:	68 ff 00 00 00       	push   $0xff
f0102182:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102187:	50                   	push   %eax
f0102188:	e8 09 12 00 00       	call   f0103396 <memset>
	page_free(pp0);
f010218d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102190:	89 3c 24             	mov    %edi,(%esp)
f0102193:	e8 af ec ff ff       	call   f0100e47 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102198:	83 c4 0c             	add    $0xc,%esp
f010219b:	6a 01                	push   $0x1
f010219d:	6a 00                	push   $0x0
f010219f:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01021a5:	e8 16 ed ff ff       	call   f0100ec0 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021aa:	89 fa                	mov    %edi,%edx
f01021ac:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f01021b2:	c1 fa 03             	sar    $0x3,%edx
f01021b5:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021b8:	89 d0                	mov    %edx,%eax
f01021ba:	c1 e8 0c             	shr    $0xc,%eax
f01021bd:	83 c4 10             	add    $0x10,%esp
f01021c0:	3b 05 68 79 11 f0    	cmp    0xf0117968,%eax
f01021c6:	72 12                	jb     f01021da <mem_init+0x10b3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021c8:	52                   	push   %edx
f01021c9:	68 28 41 10 f0       	push   $0xf0104128
f01021ce:	6a 52                	push   $0x52
f01021d0:	68 e0 3d 10 f0       	push   $0xf0103de0
f01021d5:	e8 b1 de ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01021da:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01021e0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021e3:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021e9:	f6 00 01             	testb  $0x1,(%eax)
f01021ec:	74 19                	je     f0102207 <mem_init+0x10e0>
f01021ee:	68 bf 40 10 f0       	push   $0xf01040bf
f01021f3:	68 11 3e 10 f0       	push   $0xf0103e11
f01021f8:	68 80 03 00 00       	push   $0x380
f01021fd:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102202:	e8 84 de ff ff       	call   f010008b <_panic>
f0102207:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010220a:	39 d0                	cmp    %edx,%eax
f010220c:	75 db                	jne    f01021e9 <mem_init+0x10c2>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010220e:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102213:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102219:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010221c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102222:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102225:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010222b:	83 ec 0c             	sub    $0xc,%esp
f010222e:	50                   	push   %eax
f010222f:	e8 13 ec ff ff       	call   f0100e47 <page_free>
	page_free(pp1);
f0102234:	89 1c 24             	mov    %ebx,(%esp)
f0102237:	e8 0b ec ff ff       	call   f0100e47 <page_free>
	page_free(pp2);
f010223c:	89 34 24             	mov    %esi,(%esp)
f010223f:	e8 03 ec ff ff       	call   f0100e47 <page_free>

	cprintf("check_page() succeeded!\n");
f0102244:	c7 04 24 d6 40 10 f0 	movl   $0xf01040d6,(%esp)
f010224b:	e8 57 06 00 00       	call   f01028a7 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102250:	a1 70 79 11 f0       	mov    0xf0117970,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102255:	83 c4 10             	add    $0x10,%esp
f0102258:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010225d:	77 15                	ja     f0102274 <mem_init+0x114d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010225f:	50                   	push   %eax
f0102260:	68 7c 43 10 f0       	push   $0xf010437c
f0102265:	68 b6 00 00 00       	push   $0xb6
f010226a:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010226f:	e8 17 de ff ff       	call   f010008b <_panic>
f0102274:	83 ec 08             	sub    $0x8,%esp
f0102277:	6a 04                	push   $0x4
f0102279:	05 00 00 00 10       	add    $0x10000000,%eax
f010227e:	50                   	push   %eax
f010227f:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102284:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102289:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010228e:	e8 01 ed ff ff       	call   f0100f94 <boot_map_region>
	cprintf("pages\n");
f0102293:	c7 04 24 ef 40 10 f0 	movl   $0xf01040ef,(%esp)
f010229a:	e8 08 06 00 00       	call   f01028a7 <cprintf>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010229f:	83 c4 10             	add    $0x10,%esp
f01022a2:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01022a7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022ac:	77 15                	ja     f01022c3 <mem_init+0x119c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022ae:	50                   	push   %eax
f01022af:	68 7c 43 10 f0       	push   $0xf010437c
f01022b4:	68 c4 00 00 00       	push   $0xc4
f01022b9:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01022be:	e8 c8 dd ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01022c3:	83 ec 08             	sub    $0x8,%esp
f01022c6:	6a 02                	push   $0x2
f01022c8:	68 00 d0 10 00       	push   $0x10d000
f01022cd:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01022d2:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01022d7:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01022dc:	e8 b3 ec ff ff       	call   f0100f94 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
//	boot_map_region(kern_pgdir, KERNBASE, npages*PGSIZE, 0, PTE_W);
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f01022e1:	83 c4 08             	add    $0x8,%esp
f01022e4:	6a 02                	push   $0x2
f01022e6:	6a 00                	push   $0x0
f01022e8:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01022ed:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01022f2:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01022f7:	e8 98 ec ff ff       	call   f0100f94 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01022fc:	8b 35 6c 79 11 f0    	mov    0xf011796c,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102302:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102307:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010230a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102311:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102316:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102319:	8b 3d 70 79 11 f0    	mov    0xf0117970,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010231f:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102322:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102325:	bb 00 00 00 00       	mov    $0x0,%ebx
f010232a:	eb 55                	jmp    f0102381 <mem_init+0x125a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010232c:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102332:	89 f0                	mov    %esi,%eax
f0102334:	e8 4b e6 ff ff       	call   f0100984 <check_va2pa>
f0102339:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102340:	77 15                	ja     f0102357 <mem_init+0x1230>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102342:	57                   	push   %edi
f0102343:	68 7c 43 10 f0       	push   $0xf010437c
f0102348:	68 c2 02 00 00       	push   $0x2c2
f010234d:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102352:	e8 34 dd ff ff       	call   f010008b <_panic>
f0102357:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010235e:	39 c2                	cmp    %eax,%edx
f0102360:	74 19                	je     f010237b <mem_init+0x1254>
f0102362:	68 20 48 10 f0       	push   $0xf0104820
f0102367:	68 11 3e 10 f0       	push   $0xf0103e11
f010236c:	68 c2 02 00 00       	push   $0x2c2
f0102371:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102376:	e8 10 dd ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010237b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102381:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102384:	77 a6                	ja     f010232c <mem_init+0x1205>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102386:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102389:	c1 e7 0c             	shl    $0xc,%edi
f010238c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102391:	eb 30                	jmp    f01023c3 <mem_init+0x129c>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102393:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102399:	89 f0                	mov    %esi,%eax
f010239b:	e8 e4 e5 ff ff       	call   f0100984 <check_va2pa>
f01023a0:	39 c3                	cmp    %eax,%ebx
f01023a2:	74 19                	je     f01023bd <mem_init+0x1296>
f01023a4:	68 54 48 10 f0       	push   $0xf0104854
f01023a9:	68 11 3e 10 f0       	push   $0xf0103e11
f01023ae:	68 c7 02 00 00       	push   $0x2c7
f01023b3:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01023b8:	e8 ce dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01023bd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01023c3:	39 fb                	cmp    %edi,%ebx
f01023c5:	72 cc                	jb     f0102393 <mem_init+0x126c>
f01023c7:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01023cc:	89 da                	mov    %ebx,%edx
f01023ce:	89 f0                	mov    %esi,%eax
f01023d0:	e8 af e5 ff ff       	call   f0100984 <check_va2pa>
f01023d5:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01023db:	39 c2                	cmp    %eax,%edx
f01023dd:	74 19                	je     f01023f8 <mem_init+0x12d1>
f01023df:	68 7c 48 10 f0       	push   $0xf010487c
f01023e4:	68 11 3e 10 f0       	push   $0xf0103e11
f01023e9:	68 cb 02 00 00       	push   $0x2cb
f01023ee:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01023f3:	e8 93 dc ff ff       	call   f010008b <_panic>
f01023f8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023fe:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102404:	75 c6                	jne    f01023cc <mem_init+0x12a5>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102406:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010240b:	89 f0                	mov    %esi,%eax
f010240d:	e8 72 e5 ff ff       	call   f0100984 <check_va2pa>
f0102412:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102415:	74 51                	je     f0102468 <mem_init+0x1341>
f0102417:	68 c4 48 10 f0       	push   $0xf01048c4
f010241c:	68 11 3e 10 f0       	push   $0xf0103e11
f0102421:	68 cc 02 00 00       	push   $0x2cc
f0102426:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010242b:	e8 5b dc ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102430:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102435:	72 36                	jb     f010246d <mem_init+0x1346>
f0102437:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010243c:	76 07                	jbe    f0102445 <mem_init+0x131e>
f010243e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102443:	75 28                	jne    f010246d <mem_init+0x1346>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102445:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102449:	0f 85 83 00 00 00    	jne    f01024d2 <mem_init+0x13ab>
f010244f:	68 f6 40 10 f0       	push   $0xf01040f6
f0102454:	68 11 3e 10 f0       	push   $0xf0103e11
f0102459:	68 d4 02 00 00       	push   $0x2d4
f010245e:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102463:	e8 23 dc ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102468:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010246d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102472:	76 3f                	jbe    f01024b3 <mem_init+0x138c>
				assert(pgdir[i] & PTE_P);
f0102474:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102477:	f6 c2 01             	test   $0x1,%dl
f010247a:	75 19                	jne    f0102495 <mem_init+0x136e>
f010247c:	68 f6 40 10 f0       	push   $0xf01040f6
f0102481:	68 11 3e 10 f0       	push   $0xf0103e11
f0102486:	68 d8 02 00 00       	push   $0x2d8
f010248b:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102490:	e8 f6 db ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102495:	f6 c2 02             	test   $0x2,%dl
f0102498:	75 38                	jne    f01024d2 <mem_init+0x13ab>
f010249a:	68 07 41 10 f0       	push   $0xf0104107
f010249f:	68 11 3e 10 f0       	push   $0xf0103e11
f01024a4:	68 d9 02 00 00       	push   $0x2d9
f01024a9:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01024ae:	e8 d8 db ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f01024b3:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f01024b7:	74 19                	je     f01024d2 <mem_init+0x13ab>
f01024b9:	68 18 41 10 f0       	push   $0xf0104118
f01024be:	68 11 3e 10 f0       	push   $0xf0103e11
f01024c3:	68 db 02 00 00       	push   $0x2db
f01024c8:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01024cd:	e8 b9 db ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01024d2:	83 c0 01             	add    $0x1,%eax
f01024d5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024da:	0f 86 50 ff ff ff    	jbe    f0102430 <mem_init+0x1309>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024e0:	83 ec 0c             	sub    $0xc,%esp
f01024e3:	68 f4 48 10 f0       	push   $0xf01048f4
f01024e8:	e8 ba 03 00 00       	call   f01028a7 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024ed:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024f2:	83 c4 10             	add    $0x10,%esp
f01024f5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024fa:	77 15                	ja     f0102511 <mem_init+0x13ea>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024fc:	50                   	push   %eax
f01024fd:	68 7c 43 10 f0       	push   $0xf010437c
f0102502:	68 db 00 00 00       	push   $0xdb
f0102507:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010250c:	e8 7a db ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102511:	05 00 00 00 10       	add    $0x10000000,%eax
f0102516:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102519:	b8 00 00 00 00       	mov    $0x0,%eax
f010251e:	e8 c5 e4 ff ff       	call   f01009e8 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102523:	0f 20 c0             	mov    %cr0,%eax
f0102526:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102529:	0d 23 00 05 80       	or     $0x80050023,%eax
f010252e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102531:	83 ec 0c             	sub    $0xc,%esp
f0102534:	6a 00                	push   $0x0
f0102536:	e8 9c e8 ff ff       	call   f0100dd7 <page_alloc>
f010253b:	89 c3                	mov    %eax,%ebx
f010253d:	83 c4 10             	add    $0x10,%esp
f0102540:	85 c0                	test   %eax,%eax
f0102542:	75 19                	jne    f010255d <mem_init+0x1436>
f0102544:	68 ec 3e 10 f0       	push   $0xf0103eec
f0102549:	68 11 3e 10 f0       	push   $0xf0103e11
f010254e:	68 9b 03 00 00       	push   $0x39b
f0102553:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102558:	e8 2e db ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010255d:	83 ec 0c             	sub    $0xc,%esp
f0102560:	6a 00                	push   $0x0
f0102562:	e8 70 e8 ff ff       	call   f0100dd7 <page_alloc>
f0102567:	89 c7                	mov    %eax,%edi
f0102569:	83 c4 10             	add    $0x10,%esp
f010256c:	85 c0                	test   %eax,%eax
f010256e:	75 19                	jne    f0102589 <mem_init+0x1462>
f0102570:	68 02 3f 10 f0       	push   $0xf0103f02
f0102575:	68 11 3e 10 f0       	push   $0xf0103e11
f010257a:	68 9c 03 00 00       	push   $0x39c
f010257f:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102584:	e8 02 db ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102589:	83 ec 0c             	sub    $0xc,%esp
f010258c:	6a 00                	push   $0x0
f010258e:	e8 44 e8 ff ff       	call   f0100dd7 <page_alloc>
f0102593:	89 c6                	mov    %eax,%esi
f0102595:	83 c4 10             	add    $0x10,%esp
f0102598:	85 c0                	test   %eax,%eax
f010259a:	75 19                	jne    f01025b5 <mem_init+0x148e>
f010259c:	68 18 3f 10 f0       	push   $0xf0103f18
f01025a1:	68 11 3e 10 f0       	push   $0xf0103e11
f01025a6:	68 9d 03 00 00       	push   $0x39d
f01025ab:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01025b0:	e8 d6 da ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01025b5:	83 ec 0c             	sub    $0xc,%esp
f01025b8:	53                   	push   %ebx
f01025b9:	e8 89 e8 ff ff       	call   f0100e47 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025be:	89 f8                	mov    %edi,%eax
f01025c0:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01025c6:	c1 f8 03             	sar    $0x3,%eax
f01025c9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025cc:	89 c2                	mov    %eax,%edx
f01025ce:	c1 ea 0c             	shr    $0xc,%edx
f01025d1:	83 c4 10             	add    $0x10,%esp
f01025d4:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f01025da:	72 12                	jb     f01025ee <mem_init+0x14c7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025dc:	50                   	push   %eax
f01025dd:	68 28 41 10 f0       	push   $0xf0104128
f01025e2:	6a 52                	push   $0x52
f01025e4:	68 e0 3d 10 f0       	push   $0xf0103de0
f01025e9:	e8 9d da ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025ee:	83 ec 04             	sub    $0x4,%esp
f01025f1:	68 00 10 00 00       	push   $0x1000
f01025f6:	6a 01                	push   $0x1
f01025f8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025fd:	50                   	push   %eax
f01025fe:	e8 93 0d 00 00       	call   f0103396 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102603:	89 f0                	mov    %esi,%eax
f0102605:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f010260b:	c1 f8 03             	sar    $0x3,%eax
f010260e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102611:	89 c2                	mov    %eax,%edx
f0102613:	c1 ea 0c             	shr    $0xc,%edx
f0102616:	83 c4 10             	add    $0x10,%esp
f0102619:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f010261f:	72 12                	jb     f0102633 <mem_init+0x150c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102621:	50                   	push   %eax
f0102622:	68 28 41 10 f0       	push   $0xf0104128
f0102627:	6a 52                	push   $0x52
f0102629:	68 e0 3d 10 f0       	push   $0xf0103de0
f010262e:	e8 58 da ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102633:	83 ec 04             	sub    $0x4,%esp
f0102636:	68 00 10 00 00       	push   $0x1000
f010263b:	6a 02                	push   $0x2
f010263d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102642:	50                   	push   %eax
f0102643:	e8 4e 0d 00 00       	call   f0103396 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102648:	6a 02                	push   $0x2
f010264a:	68 00 10 00 00       	push   $0x1000
f010264f:	57                   	push   %edi
f0102650:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0102656:	e8 5a ea ff ff       	call   f01010b5 <page_insert>
	assert(pp1->pp_ref == 1);
f010265b:	83 c4 20             	add    $0x20,%esp
f010265e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102663:	74 19                	je     f010267e <mem_init+0x1557>
f0102665:	68 0a 40 10 f0       	push   $0xf010400a
f010266a:	68 11 3e 10 f0       	push   $0xf0103e11
f010266f:	68 a2 03 00 00       	push   $0x3a2
f0102674:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102679:	e8 0d da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010267e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102685:	01 01 01 
f0102688:	74 19                	je     f01026a3 <mem_init+0x157c>
f010268a:	68 14 49 10 f0       	push   $0xf0104914
f010268f:	68 11 3e 10 f0       	push   $0xf0103e11
f0102694:	68 a3 03 00 00       	push   $0x3a3
f0102699:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010269e:	e8 e8 d9 ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01026a3:	6a 02                	push   $0x2
f01026a5:	68 00 10 00 00       	push   $0x1000
f01026aa:	56                   	push   %esi
f01026ab:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01026b1:	e8 ff e9 ff ff       	call   f01010b5 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01026b6:	83 c4 10             	add    $0x10,%esp
f01026b9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01026c0:	02 02 02 
f01026c3:	74 19                	je     f01026de <mem_init+0x15b7>
f01026c5:	68 38 49 10 f0       	push   $0xf0104938
f01026ca:	68 11 3e 10 f0       	push   $0xf0103e11
f01026cf:	68 a5 03 00 00       	push   $0x3a5
f01026d4:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01026d9:	e8 ad d9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01026de:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01026e3:	74 19                	je     f01026fe <mem_init+0x15d7>
f01026e5:	68 2c 40 10 f0       	push   $0xf010402c
f01026ea:	68 11 3e 10 f0       	push   $0xf0103e11
f01026ef:	68 a6 03 00 00       	push   $0x3a6
f01026f4:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01026f9:	e8 8d d9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01026fe:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102703:	74 19                	je     f010271e <mem_init+0x15f7>
f0102705:	68 96 40 10 f0       	push   $0xf0104096
f010270a:	68 11 3e 10 f0       	push   $0xf0103e11
f010270f:	68 a7 03 00 00       	push   $0x3a7
f0102714:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102719:	e8 6d d9 ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010271e:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102725:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102728:	89 f0                	mov    %esi,%eax
f010272a:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0102730:	c1 f8 03             	sar    $0x3,%eax
f0102733:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102736:	89 c2                	mov    %eax,%edx
f0102738:	c1 ea 0c             	shr    $0xc,%edx
f010273b:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0102741:	72 12                	jb     f0102755 <mem_init+0x162e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102743:	50                   	push   %eax
f0102744:	68 28 41 10 f0       	push   $0xf0104128
f0102749:	6a 52                	push   $0x52
f010274b:	68 e0 3d 10 f0       	push   $0xf0103de0
f0102750:	e8 36 d9 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102755:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010275c:	03 03 03 
f010275f:	74 19                	je     f010277a <mem_init+0x1653>
f0102761:	68 5c 49 10 f0       	push   $0xf010495c
f0102766:	68 11 3e 10 f0       	push   $0xf0103e11
f010276b:	68 a9 03 00 00       	push   $0x3a9
f0102770:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0102775:	e8 11 d9 ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010277a:	83 ec 08             	sub    $0x8,%esp
f010277d:	68 00 10 00 00       	push   $0x1000
f0102782:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0102788:	e8 e5 e8 ff ff       	call   f0101072 <page_remove>
	assert(pp2->pp_ref == 0);
f010278d:	83 c4 10             	add    $0x10,%esp
f0102790:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102795:	74 19                	je     f01027b0 <mem_init+0x1689>
f0102797:	68 64 40 10 f0       	push   $0xf0104064
f010279c:	68 11 3e 10 f0       	push   $0xf0103e11
f01027a1:	68 ab 03 00 00       	push   $0x3ab
f01027a6:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01027ab:	e8 db d8 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027b0:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f01027b6:	8b 11                	mov    (%ecx),%edx
f01027b8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01027be:	89 d8                	mov    %ebx,%eax
f01027c0:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01027c6:	c1 f8 03             	sar    $0x3,%eax
f01027c9:	c1 e0 0c             	shl    $0xc,%eax
f01027cc:	39 c2                	cmp    %eax,%edx
f01027ce:	74 19                	je     f01027e9 <mem_init+0x16c2>
f01027d0:	68 a0 44 10 f0       	push   $0xf01044a0
f01027d5:	68 11 3e 10 f0       	push   $0xf0103e11
f01027da:	68 ae 03 00 00       	push   $0x3ae
f01027df:	68 d4 3d 10 f0       	push   $0xf0103dd4
f01027e4:	e8 a2 d8 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01027e9:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01027ef:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027f4:	74 19                	je     f010280f <mem_init+0x16e8>
f01027f6:	68 1b 40 10 f0       	push   $0xf010401b
f01027fb:	68 11 3e 10 f0       	push   $0xf0103e11
f0102800:	68 b0 03 00 00       	push   $0x3b0
f0102805:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010280a:	e8 7c d8 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010280f:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102815:	83 ec 0c             	sub    $0xc,%esp
f0102818:	53                   	push   %ebx
f0102819:	e8 29 e6 ff ff       	call   f0100e47 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010281e:	c7 04 24 88 49 10 f0 	movl   $0xf0104988,(%esp)
f0102825:	e8 7d 00 00 00       	call   f01028a7 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010282a:	83 c4 10             	add    $0x10,%esp
f010282d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102830:	5b                   	pop    %ebx
f0102831:	5e                   	pop    %esi
f0102832:	5f                   	pop    %edi
f0102833:	5d                   	pop    %ebp
f0102834:	c3                   	ret    

f0102835 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102835:	55                   	push   %ebp
f0102836:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102838:	8b 45 0c             	mov    0xc(%ebp),%eax
f010283b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010283e:	5d                   	pop    %ebp
f010283f:	c3                   	ret    

f0102840 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102840:	55                   	push   %ebp
f0102841:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102843:	ba 70 00 00 00       	mov    $0x70,%edx
f0102848:	8b 45 08             	mov    0x8(%ebp),%eax
f010284b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010284c:	ba 71 00 00 00       	mov    $0x71,%edx
f0102851:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102852:	0f b6 c0             	movzbl %al,%eax
}
f0102855:	5d                   	pop    %ebp
f0102856:	c3                   	ret    

f0102857 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102857:	55                   	push   %ebp
f0102858:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010285a:	ba 70 00 00 00       	mov    $0x70,%edx
f010285f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102862:	ee                   	out    %al,(%dx)
f0102863:	ba 71 00 00 00       	mov    $0x71,%edx
f0102868:	8b 45 0c             	mov    0xc(%ebp),%eax
f010286b:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010286c:	5d                   	pop    %ebp
f010286d:	c3                   	ret    

f010286e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010286e:	55                   	push   %ebp
f010286f:	89 e5                	mov    %esp,%ebp
f0102871:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102874:	ff 75 08             	pushl  0x8(%ebp)
f0102877:	e8 62 dd ff ff       	call   f01005de <cputchar>
	*cnt++;
}
f010287c:	83 c4 10             	add    $0x10,%esp
f010287f:	c9                   	leave  
f0102880:	c3                   	ret    

f0102881 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102881:	55                   	push   %ebp
f0102882:	89 e5                	mov    %esp,%ebp
f0102884:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102887:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010288e:	ff 75 0c             	pushl  0xc(%ebp)
f0102891:	ff 75 08             	pushl  0x8(%ebp)
f0102894:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102897:	50                   	push   %eax
f0102898:	68 6e 28 10 f0       	push   $0xf010286e
f010289d:	e8 42 04 00 00       	call   f0102ce4 <vprintfmt>
	return cnt;
}
f01028a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01028a5:	c9                   	leave  
f01028a6:	c3                   	ret    

f01028a7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01028a7:	55                   	push   %ebp
f01028a8:	89 e5                	mov    %esp,%ebp
f01028aa:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01028ad:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01028b0:	50                   	push   %eax
f01028b1:	ff 75 08             	pushl  0x8(%ebp)
f01028b4:	e8 c8 ff ff ff       	call   f0102881 <vcprintf>
	va_end(ap);

	return cnt;
}
f01028b9:	c9                   	leave  
f01028ba:	c3                   	ret    

f01028bb <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01028bb:	55                   	push   %ebp
f01028bc:	89 e5                	mov    %esp,%ebp
f01028be:	57                   	push   %edi
f01028bf:	56                   	push   %esi
f01028c0:	53                   	push   %ebx
f01028c1:	83 ec 14             	sub    $0x14,%esp
f01028c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01028c7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01028ca:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01028cd:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01028d0:	8b 1a                	mov    (%edx),%ebx
f01028d2:	8b 01                	mov    (%ecx),%eax
f01028d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01028d7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01028de:	eb 7f                	jmp    f010295f <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01028e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01028e3:	01 d8                	add    %ebx,%eax
f01028e5:	89 c6                	mov    %eax,%esi
f01028e7:	c1 ee 1f             	shr    $0x1f,%esi
f01028ea:	01 c6                	add    %eax,%esi
f01028ec:	d1 fe                	sar    %esi
f01028ee:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01028f1:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01028f4:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01028f7:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01028f9:	eb 03                	jmp    f01028fe <stab_binsearch+0x43>
			m--;
f01028fb:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01028fe:	39 c3                	cmp    %eax,%ebx
f0102900:	7f 0d                	jg     f010290f <stab_binsearch+0x54>
f0102902:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102906:	83 ea 0c             	sub    $0xc,%edx
f0102909:	39 f9                	cmp    %edi,%ecx
f010290b:	75 ee                	jne    f01028fb <stab_binsearch+0x40>
f010290d:	eb 05                	jmp    f0102914 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010290f:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102912:	eb 4b                	jmp    f010295f <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102914:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102917:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010291a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010291e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102921:	76 11                	jbe    f0102934 <stab_binsearch+0x79>
			*region_left = m;
f0102923:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102926:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102928:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010292b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102932:	eb 2b                	jmp    f010295f <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102934:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102937:	73 14                	jae    f010294d <stab_binsearch+0x92>
			*region_right = m - 1;
f0102939:	83 e8 01             	sub    $0x1,%eax
f010293c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010293f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102942:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102944:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010294b:	eb 12                	jmp    f010295f <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010294d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102950:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102952:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102956:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102958:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010295f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102962:	0f 8e 78 ff ff ff    	jle    f01028e0 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102968:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010296c:	75 0f                	jne    f010297d <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010296e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102971:	8b 00                	mov    (%eax),%eax
f0102973:	83 e8 01             	sub    $0x1,%eax
f0102976:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102979:	89 06                	mov    %eax,(%esi)
f010297b:	eb 2c                	jmp    f01029a9 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010297d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102980:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102982:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102985:	8b 0e                	mov    (%esi),%ecx
f0102987:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010298a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010298d:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102990:	eb 03                	jmp    f0102995 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102992:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102995:	39 c8                	cmp    %ecx,%eax
f0102997:	7e 0b                	jle    f01029a4 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102999:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010299d:	83 ea 0c             	sub    $0xc,%edx
f01029a0:	39 df                	cmp    %ebx,%edi
f01029a2:	75 ee                	jne    f0102992 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01029a4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029a7:	89 06                	mov    %eax,(%esi)
	}
}
f01029a9:	83 c4 14             	add    $0x14,%esp
f01029ac:	5b                   	pop    %ebx
f01029ad:	5e                   	pop    %esi
f01029ae:	5f                   	pop    %edi
f01029af:	5d                   	pop    %ebp
f01029b0:	c3                   	ret    

f01029b1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01029b1:	55                   	push   %ebp
f01029b2:	89 e5                	mov    %esp,%ebp
f01029b4:	57                   	push   %edi
f01029b5:	56                   	push   %esi
f01029b6:	53                   	push   %ebx
f01029b7:	83 ec 3c             	sub    $0x3c,%esp
f01029ba:	8b 75 08             	mov    0x8(%ebp),%esi
f01029bd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01029c0:	c7 03 b4 49 10 f0    	movl   $0xf01049b4,(%ebx)
	info->eip_line = 0;
f01029c6:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01029cd:	c7 43 08 b4 49 10 f0 	movl   $0xf01049b4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01029d4:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01029db:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01029de:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01029e5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01029eb:	76 11                	jbe    f01029fe <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01029ed:	b8 9b c4 10 f0       	mov    $0xf010c49b,%eax
f01029f2:	3d dd a6 10 f0       	cmp    $0xf010a6dd,%eax
f01029f7:	77 19                	ja     f0102a12 <debuginfo_eip+0x61>
f01029f9:	e9 a1 01 00 00       	jmp    f0102b9f <debuginfo_eip+0x1ee>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01029fe:	83 ec 04             	sub    $0x4,%esp
f0102a01:	68 be 49 10 f0       	push   $0xf01049be
f0102a06:	6a 7f                	push   $0x7f
f0102a08:	68 cb 49 10 f0       	push   $0xf01049cb
f0102a0d:	e8 79 d6 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102a12:	80 3d 9a c4 10 f0 00 	cmpb   $0x0,0xf010c49a
f0102a19:	0f 85 87 01 00 00    	jne    f0102ba6 <debuginfo_eip+0x1f5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102a1f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102a26:	b8 dc a6 10 f0       	mov    $0xf010a6dc,%eax
f0102a2b:	2d 10 4c 10 f0       	sub    $0xf0104c10,%eax
f0102a30:	c1 f8 02             	sar    $0x2,%eax
f0102a33:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102a39:	83 e8 01             	sub    $0x1,%eax
f0102a3c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102a3f:	83 ec 08             	sub    $0x8,%esp
f0102a42:	56                   	push   %esi
f0102a43:	6a 64                	push   $0x64
f0102a45:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102a48:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102a4b:	b8 10 4c 10 f0       	mov    $0xf0104c10,%eax
f0102a50:	e8 66 fe ff ff       	call   f01028bb <stab_binsearch>
	if (lfile == 0)
f0102a55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a58:	83 c4 10             	add    $0x10,%esp
f0102a5b:	85 c0                	test   %eax,%eax
f0102a5d:	0f 84 4a 01 00 00    	je     f0102bad <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102a63:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102a66:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a69:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102a6c:	83 ec 08             	sub    $0x8,%esp
f0102a6f:	56                   	push   %esi
f0102a70:	6a 24                	push   $0x24
f0102a72:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102a75:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102a78:	b8 10 4c 10 f0       	mov    $0xf0104c10,%eax
f0102a7d:	e8 39 fe ff ff       	call   f01028bb <stab_binsearch>

	if (lfun <= rfun) {
f0102a82:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102a85:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102a88:	83 c4 10             	add    $0x10,%esp
f0102a8b:	39 d0                	cmp    %edx,%eax
f0102a8d:	7f 40                	jg     f0102acf <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102a8f:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102a92:	c1 e1 02             	shl    $0x2,%ecx
f0102a95:	8d b9 10 4c 10 f0    	lea    -0xfefb3f0(%ecx),%edi
f0102a9b:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102a9e:	8b b9 10 4c 10 f0    	mov    -0xfefb3f0(%ecx),%edi
f0102aa4:	b9 9b c4 10 f0       	mov    $0xf010c49b,%ecx
f0102aa9:	81 e9 dd a6 10 f0    	sub    $0xf010a6dd,%ecx
f0102aaf:	39 cf                	cmp    %ecx,%edi
f0102ab1:	73 09                	jae    f0102abc <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102ab3:	81 c7 dd a6 10 f0    	add    $0xf010a6dd,%edi
f0102ab9:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102abc:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102abf:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102ac2:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102ac5:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102ac7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102aca:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102acd:	eb 0f                	jmp    f0102ade <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102acf:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102ad2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ad5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102ad8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102adb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102ade:	83 ec 08             	sub    $0x8,%esp
f0102ae1:	6a 3a                	push   $0x3a
f0102ae3:	ff 73 08             	pushl  0x8(%ebx)
f0102ae6:	e8 8f 08 00 00       	call   f010337a <strfind>
f0102aeb:	2b 43 08             	sub    0x8(%ebx),%eax
f0102aee:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102af1:	83 c4 08             	add    $0x8,%esp
f0102af4:	56                   	push   %esi
f0102af5:	6a 44                	push   $0x44
f0102af7:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102afa:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102afd:	b8 10 4c 10 f0       	mov    $0xf0104c10,%eax
f0102b02:	e8 b4 fd ff ff       	call   f01028bb <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f0102b07:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102b0a:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102b0d:	8d 04 85 10 4c 10 f0 	lea    -0xfefb3f0(,%eax,4),%eax
f0102b14:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0102b18:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102b1b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102b1e:	83 c4 10             	add    $0x10,%esp
f0102b21:	eb 06                	jmp    f0102b29 <debuginfo_eip+0x178>
f0102b23:	83 ea 01             	sub    $0x1,%edx
f0102b26:	83 e8 0c             	sub    $0xc,%eax
f0102b29:	39 d6                	cmp    %edx,%esi
f0102b2b:	7f 34                	jg     f0102b61 <debuginfo_eip+0x1b0>
	       && stabs[lline].n_type != N_SOL
f0102b2d:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102b31:	80 f9 84             	cmp    $0x84,%cl
f0102b34:	74 0b                	je     f0102b41 <debuginfo_eip+0x190>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102b36:	80 f9 64             	cmp    $0x64,%cl
f0102b39:	75 e8                	jne    f0102b23 <debuginfo_eip+0x172>
f0102b3b:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102b3f:	74 e2                	je     f0102b23 <debuginfo_eip+0x172>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102b41:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102b44:	8b 14 85 10 4c 10 f0 	mov    -0xfefb3f0(,%eax,4),%edx
f0102b4b:	b8 9b c4 10 f0       	mov    $0xf010c49b,%eax
f0102b50:	2d dd a6 10 f0       	sub    $0xf010a6dd,%eax
f0102b55:	39 c2                	cmp    %eax,%edx
f0102b57:	73 08                	jae    f0102b61 <debuginfo_eip+0x1b0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102b59:	81 c2 dd a6 10 f0    	add    $0xf010a6dd,%edx
f0102b5f:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b61:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b64:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b67:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b6c:	39 f2                	cmp    %esi,%edx
f0102b6e:	7d 49                	jge    f0102bb9 <debuginfo_eip+0x208>
		for (lline = lfun + 1;
f0102b70:	83 c2 01             	add    $0x1,%edx
f0102b73:	89 d0                	mov    %edx,%eax
f0102b75:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102b78:	8d 14 95 10 4c 10 f0 	lea    -0xfefb3f0(,%edx,4),%edx
f0102b7f:	eb 04                	jmp    f0102b85 <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102b81:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102b85:	39 c6                	cmp    %eax,%esi
f0102b87:	7e 2b                	jle    f0102bb4 <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102b89:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102b8d:	83 c0 01             	add    $0x1,%eax
f0102b90:	83 c2 0c             	add    $0xc,%edx
f0102b93:	80 f9 a0             	cmp    $0xa0,%cl
f0102b96:	74 e9                	je     f0102b81 <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b98:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b9d:	eb 1a                	jmp    f0102bb9 <debuginfo_eip+0x208>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102b9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102ba4:	eb 13                	jmp    f0102bb9 <debuginfo_eip+0x208>
f0102ba6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102bab:	eb 0c                	jmp    f0102bb9 <debuginfo_eip+0x208>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102bad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102bb2:	eb 05                	jmp    f0102bb9 <debuginfo_eip+0x208>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102bb4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102bb9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bbc:	5b                   	pop    %ebx
f0102bbd:	5e                   	pop    %esi
f0102bbe:	5f                   	pop    %edi
f0102bbf:	5d                   	pop    %ebp
f0102bc0:	c3                   	ret    

f0102bc1 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102bc1:	55                   	push   %ebp
f0102bc2:	89 e5                	mov    %esp,%ebp
f0102bc4:	57                   	push   %edi
f0102bc5:	56                   	push   %esi
f0102bc6:	53                   	push   %ebx
f0102bc7:	83 ec 1c             	sub    $0x1c,%esp
f0102bca:	89 c7                	mov    %eax,%edi
f0102bcc:	89 d6                	mov    %edx,%esi
f0102bce:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bd1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102bd4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bd7:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102bda:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102bdd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102be2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102be5:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102be8:	39 d3                	cmp    %edx,%ebx
f0102bea:	72 05                	jb     f0102bf1 <printnum+0x30>
f0102bec:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102bef:	77 45                	ja     f0102c36 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102bf1:	83 ec 0c             	sub    $0xc,%esp
f0102bf4:	ff 75 18             	pushl  0x18(%ebp)
f0102bf7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bfa:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102bfd:	53                   	push   %ebx
f0102bfe:	ff 75 10             	pushl  0x10(%ebp)
f0102c01:	83 ec 08             	sub    $0x8,%esp
f0102c04:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c07:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c0a:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c0d:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c10:	e8 8b 09 00 00       	call   f01035a0 <__udivdi3>
f0102c15:	83 c4 18             	add    $0x18,%esp
f0102c18:	52                   	push   %edx
f0102c19:	50                   	push   %eax
f0102c1a:	89 f2                	mov    %esi,%edx
f0102c1c:	89 f8                	mov    %edi,%eax
f0102c1e:	e8 9e ff ff ff       	call   f0102bc1 <printnum>
f0102c23:	83 c4 20             	add    $0x20,%esp
f0102c26:	eb 18                	jmp    f0102c40 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102c28:	83 ec 08             	sub    $0x8,%esp
f0102c2b:	56                   	push   %esi
f0102c2c:	ff 75 18             	pushl  0x18(%ebp)
f0102c2f:	ff d7                	call   *%edi
f0102c31:	83 c4 10             	add    $0x10,%esp
f0102c34:	eb 03                	jmp    f0102c39 <printnum+0x78>
f0102c36:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102c39:	83 eb 01             	sub    $0x1,%ebx
f0102c3c:	85 db                	test   %ebx,%ebx
f0102c3e:	7f e8                	jg     f0102c28 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102c40:	83 ec 08             	sub    $0x8,%esp
f0102c43:	56                   	push   %esi
f0102c44:	83 ec 04             	sub    $0x4,%esp
f0102c47:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c4a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c4d:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c50:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c53:	e8 78 0a 00 00       	call   f01036d0 <__umoddi3>
f0102c58:	83 c4 14             	add    $0x14,%esp
f0102c5b:	0f be 80 d9 49 10 f0 	movsbl -0xfefb627(%eax),%eax
f0102c62:	50                   	push   %eax
f0102c63:	ff d7                	call   *%edi
}
f0102c65:	83 c4 10             	add    $0x10,%esp
f0102c68:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c6b:	5b                   	pop    %ebx
f0102c6c:	5e                   	pop    %esi
f0102c6d:	5f                   	pop    %edi
f0102c6e:	5d                   	pop    %ebp
f0102c6f:	c3                   	ret    

f0102c70 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102c70:	55                   	push   %ebp
f0102c71:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102c73:	83 fa 01             	cmp    $0x1,%edx
f0102c76:	7e 0e                	jle    f0102c86 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102c78:	8b 10                	mov    (%eax),%edx
f0102c7a:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102c7d:	89 08                	mov    %ecx,(%eax)
f0102c7f:	8b 02                	mov    (%edx),%eax
f0102c81:	8b 52 04             	mov    0x4(%edx),%edx
f0102c84:	eb 22                	jmp    f0102ca8 <getuint+0x38>
	else if (lflag)
f0102c86:	85 d2                	test   %edx,%edx
f0102c88:	74 10                	je     f0102c9a <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102c8a:	8b 10                	mov    (%eax),%edx
f0102c8c:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102c8f:	89 08                	mov    %ecx,(%eax)
f0102c91:	8b 02                	mov    (%edx),%eax
f0102c93:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c98:	eb 0e                	jmp    f0102ca8 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102c9a:	8b 10                	mov    (%eax),%edx
f0102c9c:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102c9f:	89 08                	mov    %ecx,(%eax)
f0102ca1:	8b 02                	mov    (%edx),%eax
f0102ca3:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102ca8:	5d                   	pop    %ebp
f0102ca9:	c3                   	ret    

f0102caa <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102caa:	55                   	push   %ebp
f0102cab:	89 e5                	mov    %esp,%ebp
f0102cad:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102cb0:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102cb4:	8b 10                	mov    (%eax),%edx
f0102cb6:	3b 50 04             	cmp    0x4(%eax),%edx
f0102cb9:	73 0a                	jae    f0102cc5 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102cbb:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102cbe:	89 08                	mov    %ecx,(%eax)
f0102cc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cc3:	88 02                	mov    %al,(%edx)
}
f0102cc5:	5d                   	pop    %ebp
f0102cc6:	c3                   	ret    

f0102cc7 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102cc7:	55                   	push   %ebp
f0102cc8:	89 e5                	mov    %esp,%ebp
f0102cca:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102ccd:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102cd0:	50                   	push   %eax
f0102cd1:	ff 75 10             	pushl  0x10(%ebp)
f0102cd4:	ff 75 0c             	pushl  0xc(%ebp)
f0102cd7:	ff 75 08             	pushl  0x8(%ebp)
f0102cda:	e8 05 00 00 00       	call   f0102ce4 <vprintfmt>
	va_end(ap);
}
f0102cdf:	83 c4 10             	add    $0x10,%esp
f0102ce2:	c9                   	leave  
f0102ce3:	c3                   	ret    

f0102ce4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102ce4:	55                   	push   %ebp
f0102ce5:	89 e5                	mov    %esp,%ebp
f0102ce7:	57                   	push   %edi
f0102ce8:	56                   	push   %esi
f0102ce9:	53                   	push   %ebx
f0102cea:	83 ec 2c             	sub    $0x2c,%esp
f0102ced:	8b 75 08             	mov    0x8(%ebp),%esi
f0102cf0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cf3:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102cf6:	eb 1d                	jmp    f0102d15 <vprintfmt+0x31>
	
	//textcolor = 0x0700;		//black on write

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102cf8:	85 c0                	test   %eax,%eax
f0102cfa:	75 0f                	jne    f0102d0b <vprintfmt+0x27>
			{
				textcolor = 0x0700;
f0102cfc:	c7 05 64 79 11 f0 00 	movl   $0x700,0xf0117964
f0102d03:	07 00 00 
				return;
f0102d06:	e9 c4 03 00 00       	jmp    f01030cf <vprintfmt+0x3eb>
			}
			putch(ch, putdat);
f0102d0b:	83 ec 08             	sub    $0x8,%esp
f0102d0e:	53                   	push   %ebx
f0102d0f:	50                   	push   %eax
f0102d10:	ff d6                	call   *%esi
f0102d12:	83 c4 10             	add    $0x10,%esp
	char padc;
	
	//textcolor = 0x0700;		//black on write

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102d15:	83 c7 01             	add    $0x1,%edi
f0102d18:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d1c:	83 f8 25             	cmp    $0x25,%eax
f0102d1f:	75 d7                	jne    f0102cf8 <vprintfmt+0x14>
f0102d21:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102d25:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102d2c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d33:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102d3a:	ba 00 00 00 00       	mov    $0x0,%edx
f0102d3f:	eb 07                	jmp    f0102d48 <vprintfmt+0x64>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d41:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102d44:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d48:	8d 47 01             	lea    0x1(%edi),%eax
f0102d4b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102d4e:	0f b6 07             	movzbl (%edi),%eax
f0102d51:	0f b6 c8             	movzbl %al,%ecx
f0102d54:	83 e8 23             	sub    $0x23,%eax
f0102d57:	3c 55                	cmp    $0x55,%al
f0102d59:	0f 87 55 03 00 00    	ja     f01030b4 <vprintfmt+0x3d0>
f0102d5f:	0f b6 c0             	movzbl %al,%eax
f0102d62:	ff 24 85 80 4a 10 f0 	jmp    *-0xfefb580(,%eax,4)
f0102d69:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102d6c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102d70:	eb d6                	jmp    f0102d48 <vprintfmt+0x64>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d75:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d7a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102d7d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102d80:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102d84:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102d87:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102d8a:	83 fa 09             	cmp    $0x9,%edx
f0102d8d:	77 39                	ja     f0102dc8 <vprintfmt+0xe4>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102d8f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102d92:	eb e9                	jmp    f0102d7d <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102d94:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d97:	8d 48 04             	lea    0x4(%eax),%ecx
f0102d9a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102d9d:	8b 00                	mov    (%eax),%eax
f0102d9f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102da2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102da5:	eb 27                	jmp    f0102dce <vprintfmt+0xea>
f0102da7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102daa:	85 c0                	test   %eax,%eax
f0102dac:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102db1:	0f 49 c8             	cmovns %eax,%ecx
f0102db4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102db7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dba:	eb 8c                	jmp    f0102d48 <vprintfmt+0x64>
f0102dbc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102dbf:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102dc6:	eb 80                	jmp    f0102d48 <vprintfmt+0x64>
f0102dc8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102dcb:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102dce:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102dd2:	0f 89 70 ff ff ff    	jns    f0102d48 <vprintfmt+0x64>
				width = precision, precision = -1;
f0102dd8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ddb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102dde:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102de5:	e9 5e ff ff ff       	jmp    f0102d48 <vprintfmt+0x64>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102dea:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ded:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102df0:	e9 53 ff ff ff       	jmp    f0102d48 <vprintfmt+0x64>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102df5:	83 fa 01             	cmp    $0x1,%edx
f0102df8:	7e 0d                	jle    f0102e07 <vprintfmt+0x123>
		return va_arg(*ap, long long);
f0102dfa:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dfd:	8d 50 08             	lea    0x8(%eax),%edx
f0102e00:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e03:	8b 00                	mov    (%eax),%eax
f0102e05:	eb 1c                	jmp    f0102e23 <vprintfmt+0x13f>
	else if (lflag)
f0102e07:	85 d2                	test   %edx,%edx
f0102e09:	74 0d                	je     f0102e18 <vprintfmt+0x134>
		return va_arg(*ap, long);
f0102e0b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e0e:	8d 50 04             	lea    0x4(%eax),%edx
f0102e11:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e14:	8b 00                	mov    (%eax),%eax
f0102e16:	eb 0b                	jmp    f0102e23 <vprintfmt+0x13f>
	else
		return va_arg(*ap, int);
f0102e18:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e1b:	8d 50 04             	lea    0x4(%eax),%edx
f0102e1e:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e21:	8b 00                	mov    (%eax),%eax
			goto reswitch;

		// text color
		case 'm':
			num = getint(&ap, lflag);
			textcolor = num;
f0102e23:	a3 64 79 11 f0       	mov    %eax,0xf0117964
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e28:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// text color
		case 'm':
			num = getint(&ap, lflag);
			textcolor = num;
			break;
f0102e2b:	e9 e5 fe ff ff       	jmp    f0102d15 <vprintfmt+0x31>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102e30:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e33:	8d 50 04             	lea    0x4(%eax),%edx
f0102e36:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e39:	83 ec 08             	sub    $0x8,%esp
f0102e3c:	53                   	push   %ebx
f0102e3d:	ff 30                	pushl  (%eax)
f0102e3f:	ff d6                	call   *%esi
			break;
f0102e41:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102e47:	e9 c9 fe ff ff       	jmp    f0102d15 <vprintfmt+0x31>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102e4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e4f:	8d 50 04             	lea    0x4(%eax),%edx
f0102e52:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e55:	8b 00                	mov    (%eax),%eax
f0102e57:	99                   	cltd   
f0102e58:	31 d0                	xor    %edx,%eax
f0102e5a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102e5c:	83 f8 07             	cmp    $0x7,%eax
f0102e5f:	7f 0b                	jg     f0102e6c <vprintfmt+0x188>
f0102e61:	8b 14 85 e0 4b 10 f0 	mov    -0xfefb420(,%eax,4),%edx
f0102e68:	85 d2                	test   %edx,%edx
f0102e6a:	75 18                	jne    f0102e84 <vprintfmt+0x1a0>
				printfmt(putch, putdat, "error %d", err);
f0102e6c:	50                   	push   %eax
f0102e6d:	68 f1 49 10 f0       	push   $0xf01049f1
f0102e72:	53                   	push   %ebx
f0102e73:	56                   	push   %esi
f0102e74:	e8 4e fe ff ff       	call   f0102cc7 <printfmt>
f0102e79:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102e7f:	e9 91 fe ff ff       	jmp    f0102d15 <vprintfmt+0x31>
			else
				printfmt(putch, putdat, "%s", p);
f0102e84:	52                   	push   %edx
f0102e85:	68 23 3e 10 f0       	push   $0xf0103e23
f0102e8a:	53                   	push   %ebx
f0102e8b:	56                   	push   %esi
f0102e8c:	e8 36 fe ff ff       	call   f0102cc7 <printfmt>
f0102e91:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e94:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e97:	e9 79 fe ff ff       	jmp    f0102d15 <vprintfmt+0x31>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102e9c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e9f:	8d 50 04             	lea    0x4(%eax),%edx
f0102ea2:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ea5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102ea7:	85 ff                	test   %edi,%edi
f0102ea9:	b8 ea 49 10 f0       	mov    $0xf01049ea,%eax
f0102eae:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102eb1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102eb5:	0f 8e 94 00 00 00    	jle    f0102f4f <vprintfmt+0x26b>
f0102ebb:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102ebf:	0f 84 98 00 00 00    	je     f0102f5d <vprintfmt+0x279>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ec5:	83 ec 08             	sub    $0x8,%esp
f0102ec8:	ff 75 d0             	pushl  -0x30(%ebp)
f0102ecb:	57                   	push   %edi
f0102ecc:	e8 5f 03 00 00       	call   f0103230 <strnlen>
f0102ed1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102ed4:	29 c1                	sub    %eax,%ecx
f0102ed6:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102ed9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102edc:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102ee0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ee3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102ee6:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ee8:	eb 0f                	jmp    f0102ef9 <vprintfmt+0x215>
					putch(padc, putdat);
f0102eea:	83 ec 08             	sub    $0x8,%esp
f0102eed:	53                   	push   %ebx
f0102eee:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ef1:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ef3:	83 ef 01             	sub    $0x1,%edi
f0102ef6:	83 c4 10             	add    $0x10,%esp
f0102ef9:	85 ff                	test   %edi,%edi
f0102efb:	7f ed                	jg     f0102eea <vprintfmt+0x206>
f0102efd:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102f00:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102f03:	85 c9                	test   %ecx,%ecx
f0102f05:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f0a:	0f 49 c1             	cmovns %ecx,%eax
f0102f0d:	29 c1                	sub    %eax,%ecx
f0102f0f:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f12:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f15:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102f18:	89 cb                	mov    %ecx,%ebx
f0102f1a:	eb 4d                	jmp    f0102f69 <vprintfmt+0x285>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102f1c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102f20:	74 1b                	je     f0102f3d <vprintfmt+0x259>
f0102f22:	0f be c0             	movsbl %al,%eax
f0102f25:	83 e8 20             	sub    $0x20,%eax
f0102f28:	83 f8 5e             	cmp    $0x5e,%eax
f0102f2b:	76 10                	jbe    f0102f3d <vprintfmt+0x259>
					putch('?', putdat);
f0102f2d:	83 ec 08             	sub    $0x8,%esp
f0102f30:	ff 75 0c             	pushl  0xc(%ebp)
f0102f33:	6a 3f                	push   $0x3f
f0102f35:	ff 55 08             	call   *0x8(%ebp)
f0102f38:	83 c4 10             	add    $0x10,%esp
f0102f3b:	eb 0d                	jmp    f0102f4a <vprintfmt+0x266>
				else
					putch(ch, putdat);
f0102f3d:	83 ec 08             	sub    $0x8,%esp
f0102f40:	ff 75 0c             	pushl  0xc(%ebp)
f0102f43:	52                   	push   %edx
f0102f44:	ff 55 08             	call   *0x8(%ebp)
f0102f47:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102f4a:	83 eb 01             	sub    $0x1,%ebx
f0102f4d:	eb 1a                	jmp    f0102f69 <vprintfmt+0x285>
f0102f4f:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f52:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f55:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102f58:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102f5b:	eb 0c                	jmp    f0102f69 <vprintfmt+0x285>
f0102f5d:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f60:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f63:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102f66:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102f69:	83 c7 01             	add    $0x1,%edi
f0102f6c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102f70:	0f be d0             	movsbl %al,%edx
f0102f73:	85 d2                	test   %edx,%edx
f0102f75:	74 23                	je     f0102f9a <vprintfmt+0x2b6>
f0102f77:	85 f6                	test   %esi,%esi
f0102f79:	78 a1                	js     f0102f1c <vprintfmt+0x238>
f0102f7b:	83 ee 01             	sub    $0x1,%esi
f0102f7e:	79 9c                	jns    f0102f1c <vprintfmt+0x238>
f0102f80:	89 df                	mov    %ebx,%edi
f0102f82:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f85:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102f88:	eb 18                	jmp    f0102fa2 <vprintfmt+0x2be>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102f8a:	83 ec 08             	sub    $0x8,%esp
f0102f8d:	53                   	push   %ebx
f0102f8e:	6a 20                	push   $0x20
f0102f90:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102f92:	83 ef 01             	sub    $0x1,%edi
f0102f95:	83 c4 10             	add    $0x10,%esp
f0102f98:	eb 08                	jmp    f0102fa2 <vprintfmt+0x2be>
f0102f9a:	89 df                	mov    %ebx,%edi
f0102f9c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f9f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102fa2:	85 ff                	test   %edi,%edi
f0102fa4:	7f e4                	jg     f0102f8a <vprintfmt+0x2a6>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fa6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102fa9:	e9 67 fd ff ff       	jmp    f0102d15 <vprintfmt+0x31>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102fae:	83 fa 01             	cmp    $0x1,%edx
f0102fb1:	7e 16                	jle    f0102fc9 <vprintfmt+0x2e5>
		return va_arg(*ap, long long);
f0102fb3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fb6:	8d 50 08             	lea    0x8(%eax),%edx
f0102fb9:	89 55 14             	mov    %edx,0x14(%ebp)
f0102fbc:	8b 50 04             	mov    0x4(%eax),%edx
f0102fbf:	8b 00                	mov    (%eax),%eax
f0102fc1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102fc4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102fc7:	eb 32                	jmp    f0102ffb <vprintfmt+0x317>
	else if (lflag)
f0102fc9:	85 d2                	test   %edx,%edx
f0102fcb:	74 18                	je     f0102fe5 <vprintfmt+0x301>
		return va_arg(*ap, long);
f0102fcd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fd0:	8d 50 04             	lea    0x4(%eax),%edx
f0102fd3:	89 55 14             	mov    %edx,0x14(%ebp)
f0102fd6:	8b 00                	mov    (%eax),%eax
f0102fd8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102fdb:	89 c1                	mov    %eax,%ecx
f0102fdd:	c1 f9 1f             	sar    $0x1f,%ecx
f0102fe0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102fe3:	eb 16                	jmp    f0102ffb <vprintfmt+0x317>
	else
		return va_arg(*ap, int);
f0102fe5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fe8:	8d 50 04             	lea    0x4(%eax),%edx
f0102feb:	89 55 14             	mov    %edx,0x14(%ebp)
f0102fee:	8b 00                	mov    (%eax),%eax
f0102ff0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ff3:	89 c1                	mov    %eax,%ecx
f0102ff5:	c1 f9 1f             	sar    $0x1f,%ecx
f0102ff8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102ffb:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ffe:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103001:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103006:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010300a:	79 74                	jns    f0103080 <vprintfmt+0x39c>
				putch('-', putdat);
f010300c:	83 ec 08             	sub    $0x8,%esp
f010300f:	53                   	push   %ebx
f0103010:	6a 2d                	push   $0x2d
f0103012:	ff d6                	call   *%esi
				num = -(long long) num;
f0103014:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103017:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010301a:	f7 d8                	neg    %eax
f010301c:	83 d2 00             	adc    $0x0,%edx
f010301f:	f7 da                	neg    %edx
f0103021:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103024:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103029:	eb 55                	jmp    f0103080 <vprintfmt+0x39c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010302b:	8d 45 14             	lea    0x14(%ebp),%eax
f010302e:	e8 3d fc ff ff       	call   f0102c70 <getuint>
			base = 10;
f0103033:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103038:	eb 46                	jmp    f0103080 <vprintfmt+0x39c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010303a:	8d 45 14             	lea    0x14(%ebp),%eax
f010303d:	e8 2e fc ff ff       	call   f0102c70 <getuint>
			base = 8;
f0103042:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103047:	eb 37                	jmp    f0103080 <vprintfmt+0x39c>

		// pointer
		case 'p':
			putch('0', putdat);
f0103049:	83 ec 08             	sub    $0x8,%esp
f010304c:	53                   	push   %ebx
f010304d:	6a 30                	push   $0x30
f010304f:	ff d6                	call   *%esi
			putch('x', putdat);
f0103051:	83 c4 08             	add    $0x8,%esp
f0103054:	53                   	push   %ebx
f0103055:	6a 78                	push   $0x78
f0103057:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103059:	8b 45 14             	mov    0x14(%ebp),%eax
f010305c:	8d 50 04             	lea    0x4(%eax),%edx
f010305f:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103062:	8b 00                	mov    (%eax),%eax
f0103064:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103069:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010306c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103071:	eb 0d                	jmp    f0103080 <vprintfmt+0x39c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103073:	8d 45 14             	lea    0x14(%ebp),%eax
f0103076:	e8 f5 fb ff ff       	call   f0102c70 <getuint>
			base = 16;
f010307b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103080:	83 ec 0c             	sub    $0xc,%esp
f0103083:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103087:	57                   	push   %edi
f0103088:	ff 75 e0             	pushl  -0x20(%ebp)
f010308b:	51                   	push   %ecx
f010308c:	52                   	push   %edx
f010308d:	50                   	push   %eax
f010308e:	89 da                	mov    %ebx,%edx
f0103090:	89 f0                	mov    %esi,%eax
f0103092:	e8 2a fb ff ff       	call   f0102bc1 <printnum>
			break;
f0103097:	83 c4 20             	add    $0x20,%esp
f010309a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010309d:	e9 73 fc ff ff       	jmp    f0102d15 <vprintfmt+0x31>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01030a2:	83 ec 08             	sub    $0x8,%esp
f01030a5:	53                   	push   %ebx
f01030a6:	51                   	push   %ecx
f01030a7:	ff d6                	call   *%esi
			break;
f01030a9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01030ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01030af:	e9 61 fc ff ff       	jmp    f0102d15 <vprintfmt+0x31>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01030b4:	83 ec 08             	sub    $0x8,%esp
f01030b7:	53                   	push   %ebx
f01030b8:	6a 25                	push   $0x25
f01030ba:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01030bc:	83 c4 10             	add    $0x10,%esp
f01030bf:	eb 03                	jmp    f01030c4 <vprintfmt+0x3e0>
f01030c1:	83 ef 01             	sub    $0x1,%edi
f01030c4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01030c8:	75 f7                	jne    f01030c1 <vprintfmt+0x3dd>
f01030ca:	e9 46 fc ff ff       	jmp    f0102d15 <vprintfmt+0x31>
				/* do nothing */;
			break;
		}
	}
}
f01030cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030d2:	5b                   	pop    %ebx
f01030d3:	5e                   	pop    %esi
f01030d4:	5f                   	pop    %edi
f01030d5:	5d                   	pop    %ebp
f01030d6:	c3                   	ret    

f01030d7 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01030d7:	55                   	push   %ebp
f01030d8:	89 e5                	mov    %esp,%ebp
f01030da:	83 ec 18             	sub    $0x18,%esp
f01030dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01030e0:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01030e3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01030e6:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01030ea:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01030ed:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01030f4:	85 c0                	test   %eax,%eax
f01030f6:	74 26                	je     f010311e <vsnprintf+0x47>
f01030f8:	85 d2                	test   %edx,%edx
f01030fa:	7e 22                	jle    f010311e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01030fc:	ff 75 14             	pushl  0x14(%ebp)
f01030ff:	ff 75 10             	pushl  0x10(%ebp)
f0103102:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103105:	50                   	push   %eax
f0103106:	68 aa 2c 10 f0       	push   $0xf0102caa
f010310b:	e8 d4 fb ff ff       	call   f0102ce4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103110:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103113:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103116:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103119:	83 c4 10             	add    $0x10,%esp
f010311c:	eb 05                	jmp    f0103123 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010311e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103123:	c9                   	leave  
f0103124:	c3                   	ret    

f0103125 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103125:	55                   	push   %ebp
f0103126:	89 e5                	mov    %esp,%ebp
f0103128:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010312b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010312e:	50                   	push   %eax
f010312f:	ff 75 10             	pushl  0x10(%ebp)
f0103132:	ff 75 0c             	pushl  0xc(%ebp)
f0103135:	ff 75 08             	pushl  0x8(%ebp)
f0103138:	e8 9a ff ff ff       	call   f01030d7 <vsnprintf>
	va_end(ap);

	return rc;
}
f010313d:	c9                   	leave  
f010313e:	c3                   	ret    

f010313f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010313f:	55                   	push   %ebp
f0103140:	89 e5                	mov    %esp,%ebp
f0103142:	57                   	push   %edi
f0103143:	56                   	push   %esi
f0103144:	53                   	push   %ebx
f0103145:	83 ec 0c             	sub    $0xc,%esp
f0103148:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010314b:	85 c0                	test   %eax,%eax
f010314d:	74 11                	je     f0103160 <readline+0x21>
		cprintf("%s", prompt);
f010314f:	83 ec 08             	sub    $0x8,%esp
f0103152:	50                   	push   %eax
f0103153:	68 23 3e 10 f0       	push   $0xf0103e23
f0103158:	e8 4a f7 ff ff       	call   f01028a7 <cprintf>
f010315d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103160:	83 ec 0c             	sub    $0xc,%esp
f0103163:	6a 00                	push   $0x0
f0103165:	e8 95 d4 ff ff       	call   f01005ff <iscons>
f010316a:	89 c7                	mov    %eax,%edi
f010316c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010316f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103174:	e8 75 d4 ff ff       	call   f01005ee <getchar>
f0103179:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010317b:	85 c0                	test   %eax,%eax
f010317d:	79 18                	jns    f0103197 <readline+0x58>
			cprintf("read error: %e\n", c);
f010317f:	83 ec 08             	sub    $0x8,%esp
f0103182:	50                   	push   %eax
f0103183:	68 00 4c 10 f0       	push   $0xf0104c00
f0103188:	e8 1a f7 ff ff       	call   f01028a7 <cprintf>
			return NULL;
f010318d:	83 c4 10             	add    $0x10,%esp
f0103190:	b8 00 00 00 00       	mov    $0x0,%eax
f0103195:	eb 79                	jmp    f0103210 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103197:	83 f8 08             	cmp    $0x8,%eax
f010319a:	0f 94 c2             	sete   %dl
f010319d:	83 f8 7f             	cmp    $0x7f,%eax
f01031a0:	0f 94 c0             	sete   %al
f01031a3:	08 c2                	or     %al,%dl
f01031a5:	74 1a                	je     f01031c1 <readline+0x82>
f01031a7:	85 f6                	test   %esi,%esi
f01031a9:	7e 16                	jle    f01031c1 <readline+0x82>
			if (echoing)
f01031ab:	85 ff                	test   %edi,%edi
f01031ad:	74 0d                	je     f01031bc <readline+0x7d>
				cputchar('\b');
f01031af:	83 ec 0c             	sub    $0xc,%esp
f01031b2:	6a 08                	push   $0x8
f01031b4:	e8 25 d4 ff ff       	call   f01005de <cputchar>
f01031b9:	83 c4 10             	add    $0x10,%esp
			i--;
f01031bc:	83 ee 01             	sub    $0x1,%esi
f01031bf:	eb b3                	jmp    f0103174 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01031c1:	83 fb 1f             	cmp    $0x1f,%ebx
f01031c4:	7e 23                	jle    f01031e9 <readline+0xaa>
f01031c6:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01031cc:	7f 1b                	jg     f01031e9 <readline+0xaa>
			if (echoing)
f01031ce:	85 ff                	test   %edi,%edi
f01031d0:	74 0c                	je     f01031de <readline+0x9f>
				cputchar(c);
f01031d2:	83 ec 0c             	sub    $0xc,%esp
f01031d5:	53                   	push   %ebx
f01031d6:	e8 03 d4 ff ff       	call   f01005de <cputchar>
f01031db:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01031de:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01031e4:	8d 76 01             	lea    0x1(%esi),%esi
f01031e7:	eb 8b                	jmp    f0103174 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01031e9:	83 fb 0a             	cmp    $0xa,%ebx
f01031ec:	74 05                	je     f01031f3 <readline+0xb4>
f01031ee:	83 fb 0d             	cmp    $0xd,%ebx
f01031f1:	75 81                	jne    f0103174 <readline+0x35>
			if (echoing)
f01031f3:	85 ff                	test   %edi,%edi
f01031f5:	74 0d                	je     f0103204 <readline+0xc5>
				cputchar('\n');
f01031f7:	83 ec 0c             	sub    $0xc,%esp
f01031fa:	6a 0a                	push   $0xa
f01031fc:	e8 dd d3 ff ff       	call   f01005de <cputchar>
f0103201:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103204:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010320b:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103210:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103213:	5b                   	pop    %ebx
f0103214:	5e                   	pop    %esi
f0103215:	5f                   	pop    %edi
f0103216:	5d                   	pop    %ebp
f0103217:	c3                   	ret    

f0103218 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103218:	55                   	push   %ebp
f0103219:	89 e5                	mov    %esp,%ebp
f010321b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010321e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103223:	eb 03                	jmp    f0103228 <strlen+0x10>
		n++;
f0103225:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103228:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010322c:	75 f7                	jne    f0103225 <strlen+0xd>
		n++;
	return n;
}
f010322e:	5d                   	pop    %ebp
f010322f:	c3                   	ret    

f0103230 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103230:	55                   	push   %ebp
f0103231:	89 e5                	mov    %esp,%ebp
f0103233:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103236:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103239:	ba 00 00 00 00       	mov    $0x0,%edx
f010323e:	eb 03                	jmp    f0103243 <strnlen+0x13>
		n++;
f0103240:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103243:	39 c2                	cmp    %eax,%edx
f0103245:	74 08                	je     f010324f <strnlen+0x1f>
f0103247:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010324b:	75 f3                	jne    f0103240 <strnlen+0x10>
f010324d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010324f:	5d                   	pop    %ebp
f0103250:	c3                   	ret    

f0103251 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103251:	55                   	push   %ebp
f0103252:	89 e5                	mov    %esp,%ebp
f0103254:	53                   	push   %ebx
f0103255:	8b 45 08             	mov    0x8(%ebp),%eax
f0103258:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010325b:	89 c2                	mov    %eax,%edx
f010325d:	83 c2 01             	add    $0x1,%edx
f0103260:	83 c1 01             	add    $0x1,%ecx
f0103263:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103267:	88 5a ff             	mov    %bl,-0x1(%edx)
f010326a:	84 db                	test   %bl,%bl
f010326c:	75 ef                	jne    f010325d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010326e:	5b                   	pop    %ebx
f010326f:	5d                   	pop    %ebp
f0103270:	c3                   	ret    

f0103271 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103271:	55                   	push   %ebp
f0103272:	89 e5                	mov    %esp,%ebp
f0103274:	53                   	push   %ebx
f0103275:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103278:	53                   	push   %ebx
f0103279:	e8 9a ff ff ff       	call   f0103218 <strlen>
f010327e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103281:	ff 75 0c             	pushl  0xc(%ebp)
f0103284:	01 d8                	add    %ebx,%eax
f0103286:	50                   	push   %eax
f0103287:	e8 c5 ff ff ff       	call   f0103251 <strcpy>
	return dst;
}
f010328c:	89 d8                	mov    %ebx,%eax
f010328e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103291:	c9                   	leave  
f0103292:	c3                   	ret    

f0103293 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103293:	55                   	push   %ebp
f0103294:	89 e5                	mov    %esp,%ebp
f0103296:	56                   	push   %esi
f0103297:	53                   	push   %ebx
f0103298:	8b 75 08             	mov    0x8(%ebp),%esi
f010329b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010329e:	89 f3                	mov    %esi,%ebx
f01032a0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01032a3:	89 f2                	mov    %esi,%edx
f01032a5:	eb 0f                	jmp    f01032b6 <strncpy+0x23>
		*dst++ = *src;
f01032a7:	83 c2 01             	add    $0x1,%edx
f01032aa:	0f b6 01             	movzbl (%ecx),%eax
f01032ad:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01032b0:	80 39 01             	cmpb   $0x1,(%ecx)
f01032b3:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01032b6:	39 da                	cmp    %ebx,%edx
f01032b8:	75 ed                	jne    f01032a7 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01032ba:	89 f0                	mov    %esi,%eax
f01032bc:	5b                   	pop    %ebx
f01032bd:	5e                   	pop    %esi
f01032be:	5d                   	pop    %ebp
f01032bf:	c3                   	ret    

f01032c0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01032c0:	55                   	push   %ebp
f01032c1:	89 e5                	mov    %esp,%ebp
f01032c3:	56                   	push   %esi
f01032c4:	53                   	push   %ebx
f01032c5:	8b 75 08             	mov    0x8(%ebp),%esi
f01032c8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01032cb:	8b 55 10             	mov    0x10(%ebp),%edx
f01032ce:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01032d0:	85 d2                	test   %edx,%edx
f01032d2:	74 21                	je     f01032f5 <strlcpy+0x35>
f01032d4:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01032d8:	89 f2                	mov    %esi,%edx
f01032da:	eb 09                	jmp    f01032e5 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01032dc:	83 c2 01             	add    $0x1,%edx
f01032df:	83 c1 01             	add    $0x1,%ecx
f01032e2:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01032e5:	39 c2                	cmp    %eax,%edx
f01032e7:	74 09                	je     f01032f2 <strlcpy+0x32>
f01032e9:	0f b6 19             	movzbl (%ecx),%ebx
f01032ec:	84 db                	test   %bl,%bl
f01032ee:	75 ec                	jne    f01032dc <strlcpy+0x1c>
f01032f0:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01032f2:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01032f5:	29 f0                	sub    %esi,%eax
}
f01032f7:	5b                   	pop    %ebx
f01032f8:	5e                   	pop    %esi
f01032f9:	5d                   	pop    %ebp
f01032fa:	c3                   	ret    

f01032fb <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01032fb:	55                   	push   %ebp
f01032fc:	89 e5                	mov    %esp,%ebp
f01032fe:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103301:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103304:	eb 06                	jmp    f010330c <strcmp+0x11>
		p++, q++;
f0103306:	83 c1 01             	add    $0x1,%ecx
f0103309:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010330c:	0f b6 01             	movzbl (%ecx),%eax
f010330f:	84 c0                	test   %al,%al
f0103311:	74 04                	je     f0103317 <strcmp+0x1c>
f0103313:	3a 02                	cmp    (%edx),%al
f0103315:	74 ef                	je     f0103306 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103317:	0f b6 c0             	movzbl %al,%eax
f010331a:	0f b6 12             	movzbl (%edx),%edx
f010331d:	29 d0                	sub    %edx,%eax
}
f010331f:	5d                   	pop    %ebp
f0103320:	c3                   	ret    

f0103321 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103321:	55                   	push   %ebp
f0103322:	89 e5                	mov    %esp,%ebp
f0103324:	53                   	push   %ebx
f0103325:	8b 45 08             	mov    0x8(%ebp),%eax
f0103328:	8b 55 0c             	mov    0xc(%ebp),%edx
f010332b:	89 c3                	mov    %eax,%ebx
f010332d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103330:	eb 06                	jmp    f0103338 <strncmp+0x17>
		n--, p++, q++;
f0103332:	83 c0 01             	add    $0x1,%eax
f0103335:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103338:	39 d8                	cmp    %ebx,%eax
f010333a:	74 15                	je     f0103351 <strncmp+0x30>
f010333c:	0f b6 08             	movzbl (%eax),%ecx
f010333f:	84 c9                	test   %cl,%cl
f0103341:	74 04                	je     f0103347 <strncmp+0x26>
f0103343:	3a 0a                	cmp    (%edx),%cl
f0103345:	74 eb                	je     f0103332 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103347:	0f b6 00             	movzbl (%eax),%eax
f010334a:	0f b6 12             	movzbl (%edx),%edx
f010334d:	29 d0                	sub    %edx,%eax
f010334f:	eb 05                	jmp    f0103356 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103351:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103356:	5b                   	pop    %ebx
f0103357:	5d                   	pop    %ebp
f0103358:	c3                   	ret    

f0103359 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103359:	55                   	push   %ebp
f010335a:	89 e5                	mov    %esp,%ebp
f010335c:	8b 45 08             	mov    0x8(%ebp),%eax
f010335f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103363:	eb 07                	jmp    f010336c <strchr+0x13>
		if (*s == c)
f0103365:	38 ca                	cmp    %cl,%dl
f0103367:	74 0f                	je     f0103378 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103369:	83 c0 01             	add    $0x1,%eax
f010336c:	0f b6 10             	movzbl (%eax),%edx
f010336f:	84 d2                	test   %dl,%dl
f0103371:	75 f2                	jne    f0103365 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103373:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103378:	5d                   	pop    %ebp
f0103379:	c3                   	ret    

f010337a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010337a:	55                   	push   %ebp
f010337b:	89 e5                	mov    %esp,%ebp
f010337d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103380:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103384:	eb 03                	jmp    f0103389 <strfind+0xf>
f0103386:	83 c0 01             	add    $0x1,%eax
f0103389:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010338c:	38 ca                	cmp    %cl,%dl
f010338e:	74 04                	je     f0103394 <strfind+0x1a>
f0103390:	84 d2                	test   %dl,%dl
f0103392:	75 f2                	jne    f0103386 <strfind+0xc>
			break;
	return (char *) s;
}
f0103394:	5d                   	pop    %ebp
f0103395:	c3                   	ret    

f0103396 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103396:	55                   	push   %ebp
f0103397:	89 e5                	mov    %esp,%ebp
f0103399:	57                   	push   %edi
f010339a:	56                   	push   %esi
f010339b:	53                   	push   %ebx
f010339c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010339f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01033a2:	85 c9                	test   %ecx,%ecx
f01033a4:	74 36                	je     f01033dc <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01033a6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01033ac:	75 28                	jne    f01033d6 <memset+0x40>
f01033ae:	f6 c1 03             	test   $0x3,%cl
f01033b1:	75 23                	jne    f01033d6 <memset+0x40>
		c &= 0xFF;
f01033b3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01033b7:	89 d3                	mov    %edx,%ebx
f01033b9:	c1 e3 08             	shl    $0x8,%ebx
f01033bc:	89 d6                	mov    %edx,%esi
f01033be:	c1 e6 18             	shl    $0x18,%esi
f01033c1:	89 d0                	mov    %edx,%eax
f01033c3:	c1 e0 10             	shl    $0x10,%eax
f01033c6:	09 f0                	or     %esi,%eax
f01033c8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01033ca:	89 d8                	mov    %ebx,%eax
f01033cc:	09 d0                	or     %edx,%eax
f01033ce:	c1 e9 02             	shr    $0x2,%ecx
f01033d1:	fc                   	cld    
f01033d2:	f3 ab                	rep stos %eax,%es:(%edi)
f01033d4:	eb 06                	jmp    f01033dc <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01033d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033d9:	fc                   	cld    
f01033da:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01033dc:	89 f8                	mov    %edi,%eax
f01033de:	5b                   	pop    %ebx
f01033df:	5e                   	pop    %esi
f01033e0:	5f                   	pop    %edi
f01033e1:	5d                   	pop    %ebp
f01033e2:	c3                   	ret    

f01033e3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01033e3:	55                   	push   %ebp
f01033e4:	89 e5                	mov    %esp,%ebp
f01033e6:	57                   	push   %edi
f01033e7:	56                   	push   %esi
f01033e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01033eb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033ee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01033f1:	39 c6                	cmp    %eax,%esi
f01033f3:	73 35                	jae    f010342a <memmove+0x47>
f01033f5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01033f8:	39 d0                	cmp    %edx,%eax
f01033fa:	73 2e                	jae    f010342a <memmove+0x47>
		s += n;
		d += n;
f01033fc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01033ff:	89 d6                	mov    %edx,%esi
f0103401:	09 fe                	or     %edi,%esi
f0103403:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103409:	75 13                	jne    f010341e <memmove+0x3b>
f010340b:	f6 c1 03             	test   $0x3,%cl
f010340e:	75 0e                	jne    f010341e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103410:	83 ef 04             	sub    $0x4,%edi
f0103413:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103416:	c1 e9 02             	shr    $0x2,%ecx
f0103419:	fd                   	std    
f010341a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010341c:	eb 09                	jmp    f0103427 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010341e:	83 ef 01             	sub    $0x1,%edi
f0103421:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103424:	fd                   	std    
f0103425:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103427:	fc                   	cld    
f0103428:	eb 1d                	jmp    f0103447 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010342a:	89 f2                	mov    %esi,%edx
f010342c:	09 c2                	or     %eax,%edx
f010342e:	f6 c2 03             	test   $0x3,%dl
f0103431:	75 0f                	jne    f0103442 <memmove+0x5f>
f0103433:	f6 c1 03             	test   $0x3,%cl
f0103436:	75 0a                	jne    f0103442 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103438:	c1 e9 02             	shr    $0x2,%ecx
f010343b:	89 c7                	mov    %eax,%edi
f010343d:	fc                   	cld    
f010343e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103440:	eb 05                	jmp    f0103447 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103442:	89 c7                	mov    %eax,%edi
f0103444:	fc                   	cld    
f0103445:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103447:	5e                   	pop    %esi
f0103448:	5f                   	pop    %edi
f0103449:	5d                   	pop    %ebp
f010344a:	c3                   	ret    

f010344b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010344b:	55                   	push   %ebp
f010344c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010344e:	ff 75 10             	pushl  0x10(%ebp)
f0103451:	ff 75 0c             	pushl  0xc(%ebp)
f0103454:	ff 75 08             	pushl  0x8(%ebp)
f0103457:	e8 87 ff ff ff       	call   f01033e3 <memmove>
}
f010345c:	c9                   	leave  
f010345d:	c3                   	ret    

f010345e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010345e:	55                   	push   %ebp
f010345f:	89 e5                	mov    %esp,%ebp
f0103461:	56                   	push   %esi
f0103462:	53                   	push   %ebx
f0103463:	8b 45 08             	mov    0x8(%ebp),%eax
f0103466:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103469:	89 c6                	mov    %eax,%esi
f010346b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010346e:	eb 1a                	jmp    f010348a <memcmp+0x2c>
		if (*s1 != *s2)
f0103470:	0f b6 08             	movzbl (%eax),%ecx
f0103473:	0f b6 1a             	movzbl (%edx),%ebx
f0103476:	38 d9                	cmp    %bl,%cl
f0103478:	74 0a                	je     f0103484 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010347a:	0f b6 c1             	movzbl %cl,%eax
f010347d:	0f b6 db             	movzbl %bl,%ebx
f0103480:	29 d8                	sub    %ebx,%eax
f0103482:	eb 0f                	jmp    f0103493 <memcmp+0x35>
		s1++, s2++;
f0103484:	83 c0 01             	add    $0x1,%eax
f0103487:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010348a:	39 f0                	cmp    %esi,%eax
f010348c:	75 e2                	jne    f0103470 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010348e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103493:	5b                   	pop    %ebx
f0103494:	5e                   	pop    %esi
f0103495:	5d                   	pop    %ebp
f0103496:	c3                   	ret    

f0103497 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103497:	55                   	push   %ebp
f0103498:	89 e5                	mov    %esp,%ebp
f010349a:	53                   	push   %ebx
f010349b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010349e:	89 c1                	mov    %eax,%ecx
f01034a0:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01034a3:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01034a7:	eb 0a                	jmp    f01034b3 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01034a9:	0f b6 10             	movzbl (%eax),%edx
f01034ac:	39 da                	cmp    %ebx,%edx
f01034ae:	74 07                	je     f01034b7 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01034b0:	83 c0 01             	add    $0x1,%eax
f01034b3:	39 c8                	cmp    %ecx,%eax
f01034b5:	72 f2                	jb     f01034a9 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01034b7:	5b                   	pop    %ebx
f01034b8:	5d                   	pop    %ebp
f01034b9:	c3                   	ret    

f01034ba <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01034ba:	55                   	push   %ebp
f01034bb:	89 e5                	mov    %esp,%ebp
f01034bd:	57                   	push   %edi
f01034be:	56                   	push   %esi
f01034bf:	53                   	push   %ebx
f01034c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01034c3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01034c6:	eb 03                	jmp    f01034cb <strtol+0x11>
		s++;
f01034c8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01034cb:	0f b6 01             	movzbl (%ecx),%eax
f01034ce:	3c 20                	cmp    $0x20,%al
f01034d0:	74 f6                	je     f01034c8 <strtol+0xe>
f01034d2:	3c 09                	cmp    $0x9,%al
f01034d4:	74 f2                	je     f01034c8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01034d6:	3c 2b                	cmp    $0x2b,%al
f01034d8:	75 0a                	jne    f01034e4 <strtol+0x2a>
		s++;
f01034da:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01034dd:	bf 00 00 00 00       	mov    $0x0,%edi
f01034e2:	eb 11                	jmp    f01034f5 <strtol+0x3b>
f01034e4:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01034e9:	3c 2d                	cmp    $0x2d,%al
f01034eb:	75 08                	jne    f01034f5 <strtol+0x3b>
		s++, neg = 1;
f01034ed:	83 c1 01             	add    $0x1,%ecx
f01034f0:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01034f5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01034fb:	75 15                	jne    f0103512 <strtol+0x58>
f01034fd:	80 39 30             	cmpb   $0x30,(%ecx)
f0103500:	75 10                	jne    f0103512 <strtol+0x58>
f0103502:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103506:	75 7c                	jne    f0103584 <strtol+0xca>
		s += 2, base = 16;
f0103508:	83 c1 02             	add    $0x2,%ecx
f010350b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103510:	eb 16                	jmp    f0103528 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103512:	85 db                	test   %ebx,%ebx
f0103514:	75 12                	jne    f0103528 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103516:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010351b:	80 39 30             	cmpb   $0x30,(%ecx)
f010351e:	75 08                	jne    f0103528 <strtol+0x6e>
		s++, base = 8;
f0103520:	83 c1 01             	add    $0x1,%ecx
f0103523:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103528:	b8 00 00 00 00       	mov    $0x0,%eax
f010352d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103530:	0f b6 11             	movzbl (%ecx),%edx
f0103533:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103536:	89 f3                	mov    %esi,%ebx
f0103538:	80 fb 09             	cmp    $0x9,%bl
f010353b:	77 08                	ja     f0103545 <strtol+0x8b>
			dig = *s - '0';
f010353d:	0f be d2             	movsbl %dl,%edx
f0103540:	83 ea 30             	sub    $0x30,%edx
f0103543:	eb 22                	jmp    f0103567 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103545:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103548:	89 f3                	mov    %esi,%ebx
f010354a:	80 fb 19             	cmp    $0x19,%bl
f010354d:	77 08                	ja     f0103557 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010354f:	0f be d2             	movsbl %dl,%edx
f0103552:	83 ea 57             	sub    $0x57,%edx
f0103555:	eb 10                	jmp    f0103567 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103557:	8d 72 bf             	lea    -0x41(%edx),%esi
f010355a:	89 f3                	mov    %esi,%ebx
f010355c:	80 fb 19             	cmp    $0x19,%bl
f010355f:	77 16                	ja     f0103577 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103561:	0f be d2             	movsbl %dl,%edx
f0103564:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103567:	3b 55 10             	cmp    0x10(%ebp),%edx
f010356a:	7d 0b                	jge    f0103577 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010356c:	83 c1 01             	add    $0x1,%ecx
f010356f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103573:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103575:	eb b9                	jmp    f0103530 <strtol+0x76>

	if (endptr)
f0103577:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010357b:	74 0d                	je     f010358a <strtol+0xd0>
		*endptr = (char *) s;
f010357d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103580:	89 0e                	mov    %ecx,(%esi)
f0103582:	eb 06                	jmp    f010358a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103584:	85 db                	test   %ebx,%ebx
f0103586:	74 98                	je     f0103520 <strtol+0x66>
f0103588:	eb 9e                	jmp    f0103528 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010358a:	89 c2                	mov    %eax,%edx
f010358c:	f7 da                	neg    %edx
f010358e:	85 ff                	test   %edi,%edi
f0103590:	0f 45 c2             	cmovne %edx,%eax
}
f0103593:	5b                   	pop    %ebx
f0103594:	5e                   	pop    %esi
f0103595:	5f                   	pop    %edi
f0103596:	5d                   	pop    %ebp
f0103597:	c3                   	ret    
f0103598:	66 90                	xchg   %ax,%ax
f010359a:	66 90                	xchg   %ax,%ax
f010359c:	66 90                	xchg   %ax,%ax
f010359e:	66 90                	xchg   %ax,%ax

f01035a0 <__udivdi3>:
f01035a0:	55                   	push   %ebp
f01035a1:	57                   	push   %edi
f01035a2:	56                   	push   %esi
f01035a3:	53                   	push   %ebx
f01035a4:	83 ec 1c             	sub    $0x1c,%esp
f01035a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01035ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01035af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01035b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035b7:	85 f6                	test   %esi,%esi
f01035b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035bd:	89 ca                	mov    %ecx,%edx
f01035bf:	89 f8                	mov    %edi,%eax
f01035c1:	75 3d                	jne    f0103600 <__udivdi3+0x60>
f01035c3:	39 cf                	cmp    %ecx,%edi
f01035c5:	0f 87 c5 00 00 00    	ja     f0103690 <__udivdi3+0xf0>
f01035cb:	85 ff                	test   %edi,%edi
f01035cd:	89 fd                	mov    %edi,%ebp
f01035cf:	75 0b                	jne    f01035dc <__udivdi3+0x3c>
f01035d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01035d6:	31 d2                	xor    %edx,%edx
f01035d8:	f7 f7                	div    %edi
f01035da:	89 c5                	mov    %eax,%ebp
f01035dc:	89 c8                	mov    %ecx,%eax
f01035de:	31 d2                	xor    %edx,%edx
f01035e0:	f7 f5                	div    %ebp
f01035e2:	89 c1                	mov    %eax,%ecx
f01035e4:	89 d8                	mov    %ebx,%eax
f01035e6:	89 cf                	mov    %ecx,%edi
f01035e8:	f7 f5                	div    %ebp
f01035ea:	89 c3                	mov    %eax,%ebx
f01035ec:	89 d8                	mov    %ebx,%eax
f01035ee:	89 fa                	mov    %edi,%edx
f01035f0:	83 c4 1c             	add    $0x1c,%esp
f01035f3:	5b                   	pop    %ebx
f01035f4:	5e                   	pop    %esi
f01035f5:	5f                   	pop    %edi
f01035f6:	5d                   	pop    %ebp
f01035f7:	c3                   	ret    
f01035f8:	90                   	nop
f01035f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103600:	39 ce                	cmp    %ecx,%esi
f0103602:	77 74                	ja     f0103678 <__udivdi3+0xd8>
f0103604:	0f bd fe             	bsr    %esi,%edi
f0103607:	83 f7 1f             	xor    $0x1f,%edi
f010360a:	0f 84 98 00 00 00    	je     f01036a8 <__udivdi3+0x108>
f0103610:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103615:	89 f9                	mov    %edi,%ecx
f0103617:	89 c5                	mov    %eax,%ebp
f0103619:	29 fb                	sub    %edi,%ebx
f010361b:	d3 e6                	shl    %cl,%esi
f010361d:	89 d9                	mov    %ebx,%ecx
f010361f:	d3 ed                	shr    %cl,%ebp
f0103621:	89 f9                	mov    %edi,%ecx
f0103623:	d3 e0                	shl    %cl,%eax
f0103625:	09 ee                	or     %ebp,%esi
f0103627:	89 d9                	mov    %ebx,%ecx
f0103629:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010362d:	89 d5                	mov    %edx,%ebp
f010362f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103633:	d3 ed                	shr    %cl,%ebp
f0103635:	89 f9                	mov    %edi,%ecx
f0103637:	d3 e2                	shl    %cl,%edx
f0103639:	89 d9                	mov    %ebx,%ecx
f010363b:	d3 e8                	shr    %cl,%eax
f010363d:	09 c2                	or     %eax,%edx
f010363f:	89 d0                	mov    %edx,%eax
f0103641:	89 ea                	mov    %ebp,%edx
f0103643:	f7 f6                	div    %esi
f0103645:	89 d5                	mov    %edx,%ebp
f0103647:	89 c3                	mov    %eax,%ebx
f0103649:	f7 64 24 0c          	mull   0xc(%esp)
f010364d:	39 d5                	cmp    %edx,%ebp
f010364f:	72 10                	jb     f0103661 <__udivdi3+0xc1>
f0103651:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103655:	89 f9                	mov    %edi,%ecx
f0103657:	d3 e6                	shl    %cl,%esi
f0103659:	39 c6                	cmp    %eax,%esi
f010365b:	73 07                	jae    f0103664 <__udivdi3+0xc4>
f010365d:	39 d5                	cmp    %edx,%ebp
f010365f:	75 03                	jne    f0103664 <__udivdi3+0xc4>
f0103661:	83 eb 01             	sub    $0x1,%ebx
f0103664:	31 ff                	xor    %edi,%edi
f0103666:	89 d8                	mov    %ebx,%eax
f0103668:	89 fa                	mov    %edi,%edx
f010366a:	83 c4 1c             	add    $0x1c,%esp
f010366d:	5b                   	pop    %ebx
f010366e:	5e                   	pop    %esi
f010366f:	5f                   	pop    %edi
f0103670:	5d                   	pop    %ebp
f0103671:	c3                   	ret    
f0103672:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103678:	31 ff                	xor    %edi,%edi
f010367a:	31 db                	xor    %ebx,%ebx
f010367c:	89 d8                	mov    %ebx,%eax
f010367e:	89 fa                	mov    %edi,%edx
f0103680:	83 c4 1c             	add    $0x1c,%esp
f0103683:	5b                   	pop    %ebx
f0103684:	5e                   	pop    %esi
f0103685:	5f                   	pop    %edi
f0103686:	5d                   	pop    %ebp
f0103687:	c3                   	ret    
f0103688:	90                   	nop
f0103689:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103690:	89 d8                	mov    %ebx,%eax
f0103692:	f7 f7                	div    %edi
f0103694:	31 ff                	xor    %edi,%edi
f0103696:	89 c3                	mov    %eax,%ebx
f0103698:	89 d8                	mov    %ebx,%eax
f010369a:	89 fa                	mov    %edi,%edx
f010369c:	83 c4 1c             	add    $0x1c,%esp
f010369f:	5b                   	pop    %ebx
f01036a0:	5e                   	pop    %esi
f01036a1:	5f                   	pop    %edi
f01036a2:	5d                   	pop    %ebp
f01036a3:	c3                   	ret    
f01036a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01036a8:	39 ce                	cmp    %ecx,%esi
f01036aa:	72 0c                	jb     f01036b8 <__udivdi3+0x118>
f01036ac:	31 db                	xor    %ebx,%ebx
f01036ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01036b2:	0f 87 34 ff ff ff    	ja     f01035ec <__udivdi3+0x4c>
f01036b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01036bd:	e9 2a ff ff ff       	jmp    f01035ec <__udivdi3+0x4c>
f01036c2:	66 90                	xchg   %ax,%ax
f01036c4:	66 90                	xchg   %ax,%ax
f01036c6:	66 90                	xchg   %ax,%ax
f01036c8:	66 90                	xchg   %ax,%ax
f01036ca:	66 90                	xchg   %ax,%ax
f01036cc:	66 90                	xchg   %ax,%ax
f01036ce:	66 90                	xchg   %ax,%ax

f01036d0 <__umoddi3>:
f01036d0:	55                   	push   %ebp
f01036d1:	57                   	push   %edi
f01036d2:	56                   	push   %esi
f01036d3:	53                   	push   %ebx
f01036d4:	83 ec 1c             	sub    $0x1c,%esp
f01036d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01036db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01036df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01036e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01036e7:	85 d2                	test   %edx,%edx
f01036e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01036ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036f1:	89 f3                	mov    %esi,%ebx
f01036f3:	89 3c 24             	mov    %edi,(%esp)
f01036f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036fa:	75 1c                	jne    f0103718 <__umoddi3+0x48>
f01036fc:	39 f7                	cmp    %esi,%edi
f01036fe:	76 50                	jbe    f0103750 <__umoddi3+0x80>
f0103700:	89 c8                	mov    %ecx,%eax
f0103702:	89 f2                	mov    %esi,%edx
f0103704:	f7 f7                	div    %edi
f0103706:	89 d0                	mov    %edx,%eax
f0103708:	31 d2                	xor    %edx,%edx
f010370a:	83 c4 1c             	add    $0x1c,%esp
f010370d:	5b                   	pop    %ebx
f010370e:	5e                   	pop    %esi
f010370f:	5f                   	pop    %edi
f0103710:	5d                   	pop    %ebp
f0103711:	c3                   	ret    
f0103712:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103718:	39 f2                	cmp    %esi,%edx
f010371a:	89 d0                	mov    %edx,%eax
f010371c:	77 52                	ja     f0103770 <__umoddi3+0xa0>
f010371e:	0f bd ea             	bsr    %edx,%ebp
f0103721:	83 f5 1f             	xor    $0x1f,%ebp
f0103724:	75 5a                	jne    f0103780 <__umoddi3+0xb0>
f0103726:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010372a:	0f 82 e0 00 00 00    	jb     f0103810 <__umoddi3+0x140>
f0103730:	39 0c 24             	cmp    %ecx,(%esp)
f0103733:	0f 86 d7 00 00 00    	jbe    f0103810 <__umoddi3+0x140>
f0103739:	8b 44 24 08          	mov    0x8(%esp),%eax
f010373d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103741:	83 c4 1c             	add    $0x1c,%esp
f0103744:	5b                   	pop    %ebx
f0103745:	5e                   	pop    %esi
f0103746:	5f                   	pop    %edi
f0103747:	5d                   	pop    %ebp
f0103748:	c3                   	ret    
f0103749:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103750:	85 ff                	test   %edi,%edi
f0103752:	89 fd                	mov    %edi,%ebp
f0103754:	75 0b                	jne    f0103761 <__umoddi3+0x91>
f0103756:	b8 01 00 00 00       	mov    $0x1,%eax
f010375b:	31 d2                	xor    %edx,%edx
f010375d:	f7 f7                	div    %edi
f010375f:	89 c5                	mov    %eax,%ebp
f0103761:	89 f0                	mov    %esi,%eax
f0103763:	31 d2                	xor    %edx,%edx
f0103765:	f7 f5                	div    %ebp
f0103767:	89 c8                	mov    %ecx,%eax
f0103769:	f7 f5                	div    %ebp
f010376b:	89 d0                	mov    %edx,%eax
f010376d:	eb 99                	jmp    f0103708 <__umoddi3+0x38>
f010376f:	90                   	nop
f0103770:	89 c8                	mov    %ecx,%eax
f0103772:	89 f2                	mov    %esi,%edx
f0103774:	83 c4 1c             	add    $0x1c,%esp
f0103777:	5b                   	pop    %ebx
f0103778:	5e                   	pop    %esi
f0103779:	5f                   	pop    %edi
f010377a:	5d                   	pop    %ebp
f010377b:	c3                   	ret    
f010377c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103780:	8b 34 24             	mov    (%esp),%esi
f0103783:	bf 20 00 00 00       	mov    $0x20,%edi
f0103788:	89 e9                	mov    %ebp,%ecx
f010378a:	29 ef                	sub    %ebp,%edi
f010378c:	d3 e0                	shl    %cl,%eax
f010378e:	89 f9                	mov    %edi,%ecx
f0103790:	89 f2                	mov    %esi,%edx
f0103792:	d3 ea                	shr    %cl,%edx
f0103794:	89 e9                	mov    %ebp,%ecx
f0103796:	09 c2                	or     %eax,%edx
f0103798:	89 d8                	mov    %ebx,%eax
f010379a:	89 14 24             	mov    %edx,(%esp)
f010379d:	89 f2                	mov    %esi,%edx
f010379f:	d3 e2                	shl    %cl,%edx
f01037a1:	89 f9                	mov    %edi,%ecx
f01037a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01037ab:	d3 e8                	shr    %cl,%eax
f01037ad:	89 e9                	mov    %ebp,%ecx
f01037af:	89 c6                	mov    %eax,%esi
f01037b1:	d3 e3                	shl    %cl,%ebx
f01037b3:	89 f9                	mov    %edi,%ecx
f01037b5:	89 d0                	mov    %edx,%eax
f01037b7:	d3 e8                	shr    %cl,%eax
f01037b9:	89 e9                	mov    %ebp,%ecx
f01037bb:	09 d8                	or     %ebx,%eax
f01037bd:	89 d3                	mov    %edx,%ebx
f01037bf:	89 f2                	mov    %esi,%edx
f01037c1:	f7 34 24             	divl   (%esp)
f01037c4:	89 d6                	mov    %edx,%esi
f01037c6:	d3 e3                	shl    %cl,%ebx
f01037c8:	f7 64 24 04          	mull   0x4(%esp)
f01037cc:	39 d6                	cmp    %edx,%esi
f01037ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01037d2:	89 d1                	mov    %edx,%ecx
f01037d4:	89 c3                	mov    %eax,%ebx
f01037d6:	72 08                	jb     f01037e0 <__umoddi3+0x110>
f01037d8:	75 11                	jne    f01037eb <__umoddi3+0x11b>
f01037da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01037de:	73 0b                	jae    f01037eb <__umoddi3+0x11b>
f01037e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01037e4:	1b 14 24             	sbb    (%esp),%edx
f01037e7:	89 d1                	mov    %edx,%ecx
f01037e9:	89 c3                	mov    %eax,%ebx
f01037eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01037ef:	29 da                	sub    %ebx,%edx
f01037f1:	19 ce                	sbb    %ecx,%esi
f01037f3:	89 f9                	mov    %edi,%ecx
f01037f5:	89 f0                	mov    %esi,%eax
f01037f7:	d3 e0                	shl    %cl,%eax
f01037f9:	89 e9                	mov    %ebp,%ecx
f01037fb:	d3 ea                	shr    %cl,%edx
f01037fd:	89 e9                	mov    %ebp,%ecx
f01037ff:	d3 ee                	shr    %cl,%esi
f0103801:	09 d0                	or     %edx,%eax
f0103803:	89 f2                	mov    %esi,%edx
f0103805:	83 c4 1c             	add    $0x1c,%esp
f0103808:	5b                   	pop    %ebx
f0103809:	5e                   	pop    %esi
f010380a:	5f                   	pop    %edi
f010380b:	5d                   	pop    %ebp
f010380c:	c3                   	ret    
f010380d:	8d 76 00             	lea    0x0(%esi),%esi
f0103810:	29 f9                	sub    %edi,%ecx
f0103812:	19 d6                	sbb    %edx,%esi
f0103814:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103818:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010381c:	e9 18 ff ff ff       	jmp    f0103739 <__umoddi3+0x69>
