
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 00 19 10 f0       	push   $0xf0101900
f0100050:	e8 69 09 00 00       	call   f01009be <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 e5 06 00 00       	call   f0100760 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 1c 19 10 f0       	push   $0xf010191c
f0100087:	e8 32 09 00 00       	call   f01009be <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 b6 13 00 00       	call   f0101467 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 37 19 10 f0       	push   $0xf0101937
f01000c3:	e8 f6 08 00 00       	call   f01009be <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 5d 07 00 00       	call   f010083e <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 52 19 10 f0       	push   $0xf0101952
f0100110:	e8 a9 08 00 00       	call   f01009be <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 79 08 00 00       	call   f0100998 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 8e 19 10 f0 	movl   $0xf010198e,(%esp)
f0100126:	e8 93 08 00 00       	call   f01009be <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 06 07 00 00       	call   f010083e <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 6a 19 10 f0       	push   $0xf010196a
f0100152:	e8 67 08 00 00       	call   f01009be <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 35 08 00 00       	call   f0100998 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 8e 19 10 f0 	movl   $0xf010198e,(%esp)
f010016a:	e8 4f 08 00 00       	call   f01009be <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 e0 1a 10 f0 	movzbl -0xfefe520(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 e0 1a 10 f0 	movzbl -0xfefe520(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a e0 19 10 f0 	movzbl -0xfefe620(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d c0 19 10 f0 	mov    -0xfefe640(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 84 19 10 f0       	push   $0xf0101984
f01002c0:	e8 f9 06 00 00       	call   f01009be <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100367:	89 fa                	mov    %edi,%edx
f0100369:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036f:	89 f8                	mov    %edi,%eax
f0100371:	80 cc 07             	or     $0x7,%ah
f0100374:	85 d2                	test   %edx,%edx
f0100376:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 74                	je     f01003f7 <cons_putc+0x113>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xae>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xbd>
f010038d:	e9 99 00 00 00       	jmp    f010042b <cons_putc+0x147>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 3a                	je     f01003d1 <cons_putc+0xed>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3d                	je     f01003d9 <cons_putc+0xf5>
f010039c:	e9 8a 00 00 00       	jmp    f010042b <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003a1:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d8:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003f5:	eb 52                	jmp    f0100449 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c5 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 bb fe ff ff       	call   f01002e4 <cons_putc>
f0100429:	eb 1e                	jmp    f0100449 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010042b:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 46 10 00 00       	call   f01014b4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ac:	8d 71 01             	lea    0x1(%ecx),%esi
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	66 c1 e8 08          	shr    $0x8,%ax
f01004b5:	89 f2                	mov    %esi,%edx
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bd:	89 ca                	mov    %ecx,%edx
f01004bf:	ee                   	out    %al,(%dx)
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	89 f2                	mov    %esi,%edx
f01004c4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c8:	5b                   	pop    %ebx
f01004c9:	5e                   	pop    %esi
f01004ca:	5f                   	pop    %edi
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004cd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004d4:	74 11                	je     f01004e7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004dc:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004e1:	e8 b0 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	f3 c3                	repz ret 

f01004e9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ef:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004f4:	e8 9d fc ff ff       	call   f0100196 <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100501:	e8 c7 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100506:	e8 de ff ff ff       	call   f01004e9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050b:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100510:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100521:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100528:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100530:	75 11                	jne    f0100543 <cons_getc+0x48>
			cons.rpos = 0;
f0100532:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100539:	00 00 00 
f010053c:	eb 05                	jmp    f0100543 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	57                   	push   %edi
f0100549:	56                   	push   %esi
f010054a:	53                   	push   %ebx
f010054b:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100555:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055c:	5a a5 
	if (*cp != 0xA55A) {
f010055e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010056b:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100572:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010058a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100592:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a0:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a3:	89 da                	mov    %ebx,%edx
f01005a5:	ec                   	in     (%dx),%al
f01005a6:	0f b6 c8             	movzbl %al,%ecx
f01005a9:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b1:	89 fa                	mov    %edi,%edx
f01005b3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b4:	89 da                	mov    %ebx,%edx
f01005b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b7:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 f2                	mov    %esi,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005da:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 03 00 00 00       	mov    $0x3,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100619:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061e:	ec                   	in     (%dx),%al
f010061f:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010062a:	89 f2                	mov    %esi,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 f9 ff             	cmp    $0xff,%cl
f0100633:	75 10                	jne    f0100645 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100635:	83 ec 0c             	sub    $0xc,%esp
f0100638:	68 90 19 10 f0       	push   $0xf0101990
f010063d:	e8 7c 03 00 00       	call   f01009be <cprintf>
f0100642:	83 c4 10             	add    $0x10,%esp
}
f0100645:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 89 fc ff ff       	call   f01002e4 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 93 fe ff ff       	call   f01004fb <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    

f0100678 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 e0 1b 10 f0       	push   $0xf0101be0
f0100683:	68 fe 1b 10 f0       	push   $0xf0101bfe
f0100688:	68 03 1c 10 f0       	push   $0xf0101c03
f010068d:	e8 2c 03 00 00       	call   f01009be <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 b0 1c 10 f0       	push   $0xf0101cb0
f010069a:	68 0c 1c 10 f0       	push   $0xf0101c0c
f010069f:	68 03 1c 10 f0       	push   $0xf0101c03
f01006a4:	e8 15 03 00 00       	call   f01009be <cprintf>
	return 0;
}
f01006a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ae:	c9                   	leave  
f01006af:	c3                   	ret    

f01006b0 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b6:	68 15 1c 10 f0       	push   $0xf0101c15
f01006bb:	e8 fe 02 00 00       	call   f01009be <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c0:	83 c4 08             	add    $0x8,%esp
f01006c3:	68 0c 00 10 00       	push   $0x10000c
f01006c8:	68 d8 1c 10 f0       	push   $0xf0101cd8
f01006cd:	e8 ec 02 00 00       	call   f01009be <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d2:	83 c4 0c             	add    $0xc,%esp
f01006d5:	68 0c 00 10 00       	push   $0x10000c
f01006da:	68 0c 00 10 f0       	push   $0xf010000c
f01006df:	68 00 1d 10 f0       	push   $0xf0101d00
f01006e4:	e8 d5 02 00 00       	call   f01009be <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 f1 18 10 00       	push   $0x1018f1
f01006f1:	68 f1 18 10 f0       	push   $0xf01018f1
f01006f6:	68 24 1d 10 f0       	push   $0xf0101d24
f01006fb:	e8 be 02 00 00       	call   f01009be <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 00 23 11 00       	push   $0x112300
f0100708:	68 00 23 11 f0       	push   $0xf0112300
f010070d:	68 48 1d 10 f0       	push   $0xf0101d48
f0100712:	e8 a7 02 00 00       	call   f01009be <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 44 29 11 00       	push   $0x112944
f010071f:	68 44 29 11 f0       	push   $0xf0112944
f0100724:	68 6c 1d 10 f0       	push   $0xf0101d6c
f0100729:	e8 90 02 00 00       	call   f01009be <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010072e:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100733:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100738:	83 c4 08             	add    $0x8,%esp
f010073b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100740:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100746:	85 c0                	test   %eax,%eax
f0100748:	0f 48 c2             	cmovs  %edx,%eax
f010074b:	c1 f8 0a             	sar    $0xa,%eax
f010074e:	50                   	push   %eax
f010074f:	68 90 1d 10 f0       	push   $0xf0101d90
f0100754:	e8 65 02 00 00       	call   f01009be <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100759:	b8 00 00 00 00       	mov    $0x0,%eax
f010075e:	c9                   	leave  
f010075f:	c3                   	ret    

f0100760 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100760:	55                   	push   %ebp
f0100761:	89 e5                	mov    %esp,%ebp
f0100763:	57                   	push   %edi
f0100764:	56                   	push   %esi
f0100765:	53                   	push   %ebx
f0100766:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100769:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	int *ebp = (int *)read_ebp();

	cprintf("Stack backtrace:\n");
f010076b:	68 2e 1c 10 f0       	push   $0xf0101c2e
f0100770:	e8 49 02 00 00       	call   f01009be <cprintf>
	
	while((int)ebp != 0x0) {
f0100775:	83 c4 10             	add    $0x10,%esp
		cprintf(" %08x", *(ebp+5));
		cprintf(" %08x\n", *(ebp+6));
		
		int eip = *(ebp+1);
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100778:	8d 7d d0             	lea    -0x30(%ebp),%edi
	// Your code here.
	int *ebp = (int *)read_ebp();

	cprintf("Stack backtrace:\n");
	
	while((int)ebp != 0x0) {
f010077b:	e9 a9 00 00 00       	jmp    f0100829 <mon_backtrace+0xc9>
		cprintf(" ebp %08x", (int)ebp);
f0100780:	83 ec 08             	sub    $0x8,%esp
f0100783:	53                   	push   %ebx
f0100784:	68 40 1c 10 f0       	push   $0xf0101c40
f0100789:	e8 30 02 00 00       	call   f01009be <cprintf>
		cprintf(" eip %08x", *(ebp+1));
f010078e:	83 c4 08             	add    $0x8,%esp
f0100791:	ff 73 04             	pushl  0x4(%ebx)
f0100794:	68 4a 1c 10 f0       	push   $0xf0101c4a
f0100799:	e8 20 02 00 00       	call   f01009be <cprintf>
		cprintf(" args");
f010079e:	c7 04 24 54 1c 10 f0 	movl   $0xf0101c54,(%esp)
f01007a5:	e8 14 02 00 00       	call   f01009be <cprintf>
		cprintf(" %08x", *(ebp+2));
f01007aa:	83 c4 08             	add    $0x8,%esp
f01007ad:	ff 73 08             	pushl  0x8(%ebx)
f01007b0:	68 44 1c 10 f0       	push   $0xf0101c44
f01007b5:	e8 04 02 00 00       	call   f01009be <cprintf>
		cprintf(" %08x", *(ebp+3));
f01007ba:	83 c4 08             	add    $0x8,%esp
f01007bd:	ff 73 0c             	pushl  0xc(%ebx)
f01007c0:	68 44 1c 10 f0       	push   $0xf0101c44
f01007c5:	e8 f4 01 00 00       	call   f01009be <cprintf>
		cprintf(" %08x", *(ebp+4));
f01007ca:	83 c4 08             	add    $0x8,%esp
f01007cd:	ff 73 10             	pushl  0x10(%ebx)
f01007d0:	68 44 1c 10 f0       	push   $0xf0101c44
f01007d5:	e8 e4 01 00 00       	call   f01009be <cprintf>
		cprintf(" %08x", *(ebp+5));
f01007da:	83 c4 08             	add    $0x8,%esp
f01007dd:	ff 73 14             	pushl  0x14(%ebx)
f01007e0:	68 44 1c 10 f0       	push   $0xf0101c44
f01007e5:	e8 d4 01 00 00       	call   f01009be <cprintf>
		cprintf(" %08x\n", *(ebp+6));
f01007ea:	83 c4 08             	add    $0x8,%esp
f01007ed:	ff 73 18             	pushl  0x18(%ebx)
f01007f0:	68 5a 1c 10 f0       	push   $0xf0101c5a
f01007f5:	e8 c4 01 00 00       	call   f01009be <cprintf>
		
		int eip = *(ebp+1);
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01007fa:	8b 73 04             	mov    0x4(%ebx),%esi
f01007fd:	83 c4 08             	add    $0x8,%esp
f0100800:	57                   	push   %edi
f0100801:	56                   	push   %esi
f0100802:	e8 c1 02 00 00       	call   f0100ac8 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n", 
f0100807:	83 c4 08             	add    $0x8,%esp
f010080a:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010080d:	56                   	push   %esi
f010080e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100811:	ff 75 dc             	pushl  -0x24(%ebp)
f0100814:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100817:	ff 75 d0             	pushl  -0x30(%ebp)
f010081a:	68 61 1c 10 f0       	push   $0xf0101c61
f010081f:	e8 9a 01 00 00       	call   f01009be <cprintf>
			info.eip_file, info.eip_line,
			info.eip_fn_namelen, info.eip_fn_name,
			eip - info.eip_fn_addr);

		ebp = (int *)(*ebp);
f0100824:	8b 1b                	mov    (%ebx),%ebx
f0100826:	83 c4 20             	add    $0x20,%esp
	// Your code here.
	int *ebp = (int *)read_ebp();

	cprintf("Stack backtrace:\n");
	
	while((int)ebp != 0x0) {
f0100829:	85 db                	test   %ebx,%ebx
f010082b:	0f 85 4f ff ff ff    	jne    f0100780 <mon_backtrace+0x20>
			eip - info.eip_fn_addr);

		ebp = (int *)(*ebp);
	}
	return 0;
}
f0100831:	b8 00 00 00 00       	mov    $0x0,%eax
f0100836:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100839:	5b                   	pop    %ebx
f010083a:	5e                   	pop    %esi
f010083b:	5f                   	pop    %edi
f010083c:	5d                   	pop    %ebp
f010083d:	c3                   	ret    

f010083e <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010083e:	55                   	push   %ebp
f010083f:	89 e5                	mov    %esp,%ebp
f0100841:	57                   	push   %edi
f0100842:	56                   	push   %esi
f0100843:	53                   	push   %ebx
f0100844:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100847:	68 bc 1d 10 f0       	push   $0xf0101dbc
f010084c:	e8 6d 01 00 00       	call   f01009be <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100851:	c7 04 24 e0 1d 10 f0 	movl   $0xf0101de0,(%esp)
f0100858:	e8 61 01 00 00       	call   f01009be <cprintf>
f010085d:	83 c4 10             	add    $0x10,%esp

//  unsigned int i = 0x00646c72;
//  cprintf("H%x Wo%s\n", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100860:	83 ec 0c             	sub    $0xc,%esp
f0100863:	68 72 1c 10 f0       	push   $0xf0101c72
f0100868:	e8 a3 09 00 00       	call   f0101210 <readline>
f010086d:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010086f:	83 c4 10             	add    $0x10,%esp
f0100872:	85 c0                	test   %eax,%eax
f0100874:	74 ea                	je     f0100860 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100876:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010087d:	be 00 00 00 00       	mov    $0x0,%esi
f0100882:	eb 0a                	jmp    f010088e <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100884:	c6 03 00             	movb   $0x0,(%ebx)
f0100887:	89 f7                	mov    %esi,%edi
f0100889:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010088c:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010088e:	0f b6 03             	movzbl (%ebx),%eax
f0100891:	84 c0                	test   %al,%al
f0100893:	74 63                	je     f01008f8 <monitor+0xba>
f0100895:	83 ec 08             	sub    $0x8,%esp
f0100898:	0f be c0             	movsbl %al,%eax
f010089b:	50                   	push   %eax
f010089c:	68 76 1c 10 f0       	push   $0xf0101c76
f01008a1:	e8 84 0b 00 00       	call   f010142a <strchr>
f01008a6:	83 c4 10             	add    $0x10,%esp
f01008a9:	85 c0                	test   %eax,%eax
f01008ab:	75 d7                	jne    f0100884 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01008ad:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008b0:	74 46                	je     f01008f8 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008b2:	83 fe 0f             	cmp    $0xf,%esi
f01008b5:	75 14                	jne    f01008cb <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008b7:	83 ec 08             	sub    $0x8,%esp
f01008ba:	6a 10                	push   $0x10
f01008bc:	68 7b 1c 10 f0       	push   $0xf0101c7b
f01008c1:	e8 f8 00 00 00       	call   f01009be <cprintf>
f01008c6:	83 c4 10             	add    $0x10,%esp
f01008c9:	eb 95                	jmp    f0100860 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008cb:	8d 7e 01             	lea    0x1(%esi),%edi
f01008ce:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008d2:	eb 03                	jmp    f01008d7 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008d4:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d7:	0f b6 03             	movzbl (%ebx),%eax
f01008da:	84 c0                	test   %al,%al
f01008dc:	74 ae                	je     f010088c <monitor+0x4e>
f01008de:	83 ec 08             	sub    $0x8,%esp
f01008e1:	0f be c0             	movsbl %al,%eax
f01008e4:	50                   	push   %eax
f01008e5:	68 76 1c 10 f0       	push   $0xf0101c76
f01008ea:	e8 3b 0b 00 00       	call   f010142a <strchr>
f01008ef:	83 c4 10             	add    $0x10,%esp
f01008f2:	85 c0                	test   %eax,%eax
f01008f4:	74 de                	je     f01008d4 <monitor+0x96>
f01008f6:	eb 94                	jmp    f010088c <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008f8:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008ff:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100900:	85 f6                	test   %esi,%esi
f0100902:	0f 84 58 ff ff ff    	je     f0100860 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100908:	83 ec 08             	sub    $0x8,%esp
f010090b:	68 fe 1b 10 f0       	push   $0xf0101bfe
f0100910:	ff 75 a8             	pushl  -0x58(%ebp)
f0100913:	e8 b4 0a 00 00       	call   f01013cc <strcmp>
f0100918:	83 c4 10             	add    $0x10,%esp
f010091b:	85 c0                	test   %eax,%eax
f010091d:	74 1e                	je     f010093d <monitor+0xff>
f010091f:	83 ec 08             	sub    $0x8,%esp
f0100922:	68 0c 1c 10 f0       	push   $0xf0101c0c
f0100927:	ff 75 a8             	pushl  -0x58(%ebp)
f010092a:	e8 9d 0a 00 00       	call   f01013cc <strcmp>
f010092f:	83 c4 10             	add    $0x10,%esp
f0100932:	85 c0                	test   %eax,%eax
f0100934:	75 2f                	jne    f0100965 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100936:	b8 01 00 00 00       	mov    $0x1,%eax
f010093b:	eb 05                	jmp    f0100942 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010093d:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100942:	83 ec 04             	sub    $0x4,%esp
f0100945:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100948:	01 d0                	add    %edx,%eax
f010094a:	ff 75 08             	pushl  0x8(%ebp)
f010094d:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100950:	51                   	push   %ecx
f0100951:	56                   	push   %esi
f0100952:	ff 14 85 10 1e 10 f0 	call   *-0xfefe1f0(,%eax,4)
//  cprintf("H%x Wo%s\n", 57616, &i);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100959:	83 c4 10             	add    $0x10,%esp
f010095c:	85 c0                	test   %eax,%eax
f010095e:	78 1d                	js     f010097d <monitor+0x13f>
f0100960:	e9 fb fe ff ff       	jmp    f0100860 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100965:	83 ec 08             	sub    $0x8,%esp
f0100968:	ff 75 a8             	pushl  -0x58(%ebp)
f010096b:	68 98 1c 10 f0       	push   $0xf0101c98
f0100970:	e8 49 00 00 00       	call   f01009be <cprintf>
f0100975:	83 c4 10             	add    $0x10,%esp
f0100978:	e9 e3 fe ff ff       	jmp    f0100860 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010097d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100980:	5b                   	pop    %ebx
f0100981:	5e                   	pop    %esi
f0100982:	5f                   	pop    %edi
f0100983:	5d                   	pop    %ebp
f0100984:	c3                   	ret    

f0100985 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100985:	55                   	push   %ebp
f0100986:	89 e5                	mov    %esp,%ebp
f0100988:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010098b:	ff 75 08             	pushl  0x8(%ebp)
f010098e:	e8 ba fc ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f0100993:	83 c4 10             	add    $0x10,%esp
f0100996:	c9                   	leave  
f0100997:	c3                   	ret    

f0100998 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100998:	55                   	push   %ebp
f0100999:	89 e5                	mov    %esp,%ebp
f010099b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010099e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009a5:	ff 75 0c             	pushl  0xc(%ebp)
f01009a8:	ff 75 08             	pushl  0x8(%ebp)
f01009ab:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009ae:	50                   	push   %eax
f01009af:	68 85 09 10 f0       	push   $0xf0100985
f01009b4:	e8 42 04 00 00       	call   f0100dfb <vprintfmt>
	return cnt;
}
f01009b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009bc:	c9                   	leave  
f01009bd:	c3                   	ret    

f01009be <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009be:	55                   	push   %ebp
f01009bf:	89 e5                	mov    %esp,%ebp
f01009c1:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009c4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009c7:	50                   	push   %eax
f01009c8:	ff 75 08             	pushl  0x8(%ebp)
f01009cb:	e8 c8 ff ff ff       	call   f0100998 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009d0:	c9                   	leave  
f01009d1:	c3                   	ret    

f01009d2 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009d2:	55                   	push   %ebp
f01009d3:	89 e5                	mov    %esp,%ebp
f01009d5:	57                   	push   %edi
f01009d6:	56                   	push   %esi
f01009d7:	53                   	push   %ebx
f01009d8:	83 ec 14             	sub    $0x14,%esp
f01009db:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009de:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009e1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009e4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009e7:	8b 1a                	mov    (%edx),%ebx
f01009e9:	8b 01                	mov    (%ecx),%eax
f01009eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009ee:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009f5:	eb 7f                	jmp    f0100a76 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009fa:	01 d8                	add    %ebx,%eax
f01009fc:	89 c6                	mov    %eax,%esi
f01009fe:	c1 ee 1f             	shr    $0x1f,%esi
f0100a01:	01 c6                	add    %eax,%esi
f0100a03:	d1 fe                	sar    %esi
f0100a05:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a08:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a0b:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100a0e:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a10:	eb 03                	jmp    f0100a15 <stab_binsearch+0x43>
			m--;
f0100a12:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a15:	39 c3                	cmp    %eax,%ebx
f0100a17:	7f 0d                	jg     f0100a26 <stab_binsearch+0x54>
f0100a19:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a1d:	83 ea 0c             	sub    $0xc,%edx
f0100a20:	39 f9                	cmp    %edi,%ecx
f0100a22:	75 ee                	jne    f0100a12 <stab_binsearch+0x40>
f0100a24:	eb 05                	jmp    f0100a2b <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a26:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a29:	eb 4b                	jmp    f0100a76 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a2b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a2e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a31:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a35:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a38:	76 11                	jbe    f0100a4b <stab_binsearch+0x79>
			*region_left = m;
f0100a3a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a3d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a3f:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a42:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a49:	eb 2b                	jmp    f0100a76 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a4b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a4e:	73 14                	jae    f0100a64 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a50:	83 e8 01             	sub    $0x1,%eax
f0100a53:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a56:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a59:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a5b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a62:	eb 12                	jmp    f0100a76 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a64:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a67:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a69:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a6d:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a6f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a76:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a79:	0f 8e 78 ff ff ff    	jle    f01009f7 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a7f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a83:	75 0f                	jne    f0100a94 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a85:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a88:	8b 00                	mov    (%eax),%eax
f0100a8a:	83 e8 01             	sub    $0x1,%eax
f0100a8d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a90:	89 06                	mov    %eax,(%esi)
f0100a92:	eb 2c                	jmp    f0100ac0 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a94:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a97:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a99:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a9c:	8b 0e                	mov    (%esi),%ecx
f0100a9e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100aa1:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100aa4:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aa7:	eb 03                	jmp    f0100aac <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100aa9:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aac:	39 c8                	cmp    %ecx,%eax
f0100aae:	7e 0b                	jle    f0100abb <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100ab0:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100ab4:	83 ea 0c             	sub    $0xc,%edx
f0100ab7:	39 df                	cmp    %ebx,%edi
f0100ab9:	75 ee                	jne    f0100aa9 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100abb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100abe:	89 06                	mov    %eax,(%esi)
	}
}
f0100ac0:	83 c4 14             	add    $0x14,%esp
f0100ac3:	5b                   	pop    %ebx
f0100ac4:	5e                   	pop    %esi
f0100ac5:	5f                   	pop    %edi
f0100ac6:	5d                   	pop    %ebp
f0100ac7:	c3                   	ret    

f0100ac8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ac8:	55                   	push   %ebp
f0100ac9:	89 e5                	mov    %esp,%ebp
f0100acb:	57                   	push   %edi
f0100acc:	56                   	push   %esi
f0100acd:	53                   	push   %ebx
f0100ace:	83 ec 3c             	sub    $0x3c,%esp
f0100ad1:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ad4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ad7:	c7 03 20 1e 10 f0    	movl   $0xf0101e20,(%ebx)
	info->eip_line = 0;
f0100add:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ae4:	c7 43 08 20 1e 10 f0 	movl   $0xf0101e20,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100aeb:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100af2:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100af5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100afc:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b02:	76 11                	jbe    f0100b15 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b04:	b8 7e 73 10 f0       	mov    $0xf010737e,%eax
f0100b09:	3d 55 5a 10 f0       	cmp    $0xf0105a55,%eax
f0100b0e:	77 19                	ja     f0100b29 <debuginfo_eip+0x61>
f0100b10:	e9 a1 01 00 00       	jmp    f0100cb6 <debuginfo_eip+0x1ee>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b15:	83 ec 04             	sub    $0x4,%esp
f0100b18:	68 2a 1e 10 f0       	push   $0xf0101e2a
f0100b1d:	6a 7f                	push   $0x7f
f0100b1f:	68 37 1e 10 f0       	push   $0xf0101e37
f0100b24:	e8 bd f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b29:	80 3d 7d 73 10 f0 00 	cmpb   $0x0,0xf010737d
f0100b30:	0f 85 87 01 00 00    	jne    f0100cbd <debuginfo_eip+0x1f5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b36:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b3d:	b8 54 5a 10 f0       	mov    $0xf0105a54,%eax
f0100b42:	2d 70 20 10 f0       	sub    $0xf0102070,%eax
f0100b47:	c1 f8 02             	sar    $0x2,%eax
f0100b4a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b50:	83 e8 01             	sub    $0x1,%eax
f0100b53:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b56:	83 ec 08             	sub    $0x8,%esp
f0100b59:	56                   	push   %esi
f0100b5a:	6a 64                	push   $0x64
f0100b5c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b5f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b62:	b8 70 20 10 f0       	mov    $0xf0102070,%eax
f0100b67:	e8 66 fe ff ff       	call   f01009d2 <stab_binsearch>
	if (lfile == 0)
f0100b6c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b6f:	83 c4 10             	add    $0x10,%esp
f0100b72:	85 c0                	test   %eax,%eax
f0100b74:	0f 84 4a 01 00 00    	je     f0100cc4 <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b7a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b7d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b80:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b83:	83 ec 08             	sub    $0x8,%esp
f0100b86:	56                   	push   %esi
f0100b87:	6a 24                	push   $0x24
f0100b89:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b8c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b8f:	b8 70 20 10 f0       	mov    $0xf0102070,%eax
f0100b94:	e8 39 fe ff ff       	call   f01009d2 <stab_binsearch>

	if (lfun <= rfun) {
f0100b99:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b9c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b9f:	83 c4 10             	add    $0x10,%esp
f0100ba2:	39 d0                	cmp    %edx,%eax
f0100ba4:	7f 40                	jg     f0100be6 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ba6:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100ba9:	c1 e1 02             	shl    $0x2,%ecx
f0100bac:	8d b9 70 20 10 f0    	lea    -0xfefdf90(%ecx),%edi
f0100bb2:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bb5:	8b b9 70 20 10 f0    	mov    -0xfefdf90(%ecx),%edi
f0100bbb:	b9 7e 73 10 f0       	mov    $0xf010737e,%ecx
f0100bc0:	81 e9 55 5a 10 f0    	sub    $0xf0105a55,%ecx
f0100bc6:	39 cf                	cmp    %ecx,%edi
f0100bc8:	73 09                	jae    f0100bd3 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bca:	81 c7 55 5a 10 f0    	add    $0xf0105a55,%edi
f0100bd0:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bd3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bd6:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bd9:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bdc:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bde:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100be1:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100be4:	eb 0f                	jmp    f0100bf5 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100be6:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100be9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bf2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bf5:	83 ec 08             	sub    $0x8,%esp
f0100bf8:	6a 3a                	push   $0x3a
f0100bfa:	ff 73 08             	pushl  0x8(%ebx)
f0100bfd:	e8 49 08 00 00       	call   f010144b <strfind>
f0100c02:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c05:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c08:	83 c4 08             	add    $0x8,%esp
f0100c0b:	56                   	push   %esi
f0100c0c:	6a 44                	push   $0x44
f0100c0e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c11:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c14:	b8 70 20 10 f0       	mov    $0xf0102070,%eax
f0100c19:	e8 b4 fd ff ff       	call   f01009d2 <stab_binsearch>
    info->eip_line = stabs[lline].n_desc;
f0100c1e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100c21:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c24:	8d 04 85 70 20 10 f0 	lea    -0xfefdf90(,%eax,4),%eax
f0100c2b:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0100c2f:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c32:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c35:	83 c4 10             	add    $0x10,%esp
f0100c38:	eb 06                	jmp    f0100c40 <debuginfo_eip+0x178>
f0100c3a:	83 ea 01             	sub    $0x1,%edx
f0100c3d:	83 e8 0c             	sub    $0xc,%eax
f0100c40:	39 d6                	cmp    %edx,%esi
f0100c42:	7f 34                	jg     f0100c78 <debuginfo_eip+0x1b0>
	       && stabs[lline].n_type != N_SOL
f0100c44:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c48:	80 f9 84             	cmp    $0x84,%cl
f0100c4b:	74 0b                	je     f0100c58 <debuginfo_eip+0x190>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c4d:	80 f9 64             	cmp    $0x64,%cl
f0100c50:	75 e8                	jne    f0100c3a <debuginfo_eip+0x172>
f0100c52:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c56:	74 e2                	je     f0100c3a <debuginfo_eip+0x172>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c58:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c5b:	8b 14 85 70 20 10 f0 	mov    -0xfefdf90(,%eax,4),%edx
f0100c62:	b8 7e 73 10 f0       	mov    $0xf010737e,%eax
f0100c67:	2d 55 5a 10 f0       	sub    $0xf0105a55,%eax
f0100c6c:	39 c2                	cmp    %eax,%edx
f0100c6e:	73 08                	jae    f0100c78 <debuginfo_eip+0x1b0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c70:	81 c2 55 5a 10 f0    	add    $0xf0105a55,%edx
f0100c76:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c78:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c7b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c7e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c83:	39 f2                	cmp    %esi,%edx
f0100c85:	7d 49                	jge    f0100cd0 <debuginfo_eip+0x208>
		for (lline = lfun + 1;
f0100c87:	83 c2 01             	add    $0x1,%edx
f0100c8a:	89 d0                	mov    %edx,%eax
f0100c8c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c8f:	8d 14 95 70 20 10 f0 	lea    -0xfefdf90(,%edx,4),%edx
f0100c96:	eb 04                	jmp    f0100c9c <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c98:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c9c:	39 c6                	cmp    %eax,%esi
f0100c9e:	7e 2b                	jle    f0100ccb <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100ca0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100ca4:	83 c0 01             	add    $0x1,%eax
f0100ca7:	83 c2 0c             	add    $0xc,%edx
f0100caa:	80 f9 a0             	cmp    $0xa0,%cl
f0100cad:	74 e9                	je     f0100c98 <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100caf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb4:	eb 1a                	jmp    f0100cd0 <debuginfo_eip+0x208>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cb6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cbb:	eb 13                	jmp    f0100cd0 <debuginfo_eip+0x208>
f0100cbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cc2:	eb 0c                	jmp    f0100cd0 <debuginfo_eip+0x208>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100cc4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cc9:	eb 05                	jmp    f0100cd0 <debuginfo_eip+0x208>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ccb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cd0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cd3:	5b                   	pop    %ebx
f0100cd4:	5e                   	pop    %esi
f0100cd5:	5f                   	pop    %edi
f0100cd6:	5d                   	pop    %ebp
f0100cd7:	c3                   	ret    

f0100cd8 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cd8:	55                   	push   %ebp
f0100cd9:	89 e5                	mov    %esp,%ebp
f0100cdb:	57                   	push   %edi
f0100cdc:	56                   	push   %esi
f0100cdd:	53                   	push   %ebx
f0100cde:	83 ec 1c             	sub    $0x1c,%esp
f0100ce1:	89 c7                	mov    %eax,%edi
f0100ce3:	89 d6                	mov    %edx,%esi
f0100ce5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ce8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ceb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cee:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cf1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cf4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cf9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cfc:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100cff:	39 d3                	cmp    %edx,%ebx
f0100d01:	72 05                	jb     f0100d08 <printnum+0x30>
f0100d03:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100d06:	77 45                	ja     f0100d4d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d08:	83 ec 0c             	sub    $0xc,%esp
f0100d0b:	ff 75 18             	pushl  0x18(%ebp)
f0100d0e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d11:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100d14:	53                   	push   %ebx
f0100d15:	ff 75 10             	pushl  0x10(%ebp)
f0100d18:	83 ec 08             	sub    $0x8,%esp
f0100d1b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d1e:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d21:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d24:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d27:	e8 44 09 00 00       	call   f0101670 <__udivdi3>
f0100d2c:	83 c4 18             	add    $0x18,%esp
f0100d2f:	52                   	push   %edx
f0100d30:	50                   	push   %eax
f0100d31:	89 f2                	mov    %esi,%edx
f0100d33:	89 f8                	mov    %edi,%eax
f0100d35:	e8 9e ff ff ff       	call   f0100cd8 <printnum>
f0100d3a:	83 c4 20             	add    $0x20,%esp
f0100d3d:	eb 18                	jmp    f0100d57 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d3f:	83 ec 08             	sub    $0x8,%esp
f0100d42:	56                   	push   %esi
f0100d43:	ff 75 18             	pushl  0x18(%ebp)
f0100d46:	ff d7                	call   *%edi
f0100d48:	83 c4 10             	add    $0x10,%esp
f0100d4b:	eb 03                	jmp    f0100d50 <printnum+0x78>
f0100d4d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d50:	83 eb 01             	sub    $0x1,%ebx
f0100d53:	85 db                	test   %ebx,%ebx
f0100d55:	7f e8                	jg     f0100d3f <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d57:	83 ec 08             	sub    $0x8,%esp
f0100d5a:	56                   	push   %esi
f0100d5b:	83 ec 04             	sub    $0x4,%esp
f0100d5e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d61:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d64:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d67:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d6a:	e8 31 0a 00 00       	call   f01017a0 <__umoddi3>
f0100d6f:	83 c4 14             	add    $0x14,%esp
f0100d72:	0f be 80 45 1e 10 f0 	movsbl -0xfefe1bb(%eax),%eax
f0100d79:	50                   	push   %eax
f0100d7a:	ff d7                	call   *%edi
}
f0100d7c:	83 c4 10             	add    $0x10,%esp
f0100d7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d82:	5b                   	pop    %ebx
f0100d83:	5e                   	pop    %esi
f0100d84:	5f                   	pop    %edi
f0100d85:	5d                   	pop    %ebp
f0100d86:	c3                   	ret    

f0100d87 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d87:	55                   	push   %ebp
f0100d88:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d8a:	83 fa 01             	cmp    $0x1,%edx
f0100d8d:	7e 0e                	jle    f0100d9d <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d8f:	8b 10                	mov    (%eax),%edx
f0100d91:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d94:	89 08                	mov    %ecx,(%eax)
f0100d96:	8b 02                	mov    (%edx),%eax
f0100d98:	8b 52 04             	mov    0x4(%edx),%edx
f0100d9b:	eb 22                	jmp    f0100dbf <getuint+0x38>
	else if (lflag)
f0100d9d:	85 d2                	test   %edx,%edx
f0100d9f:	74 10                	je     f0100db1 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100da1:	8b 10                	mov    (%eax),%edx
f0100da3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100da6:	89 08                	mov    %ecx,(%eax)
f0100da8:	8b 02                	mov    (%edx),%eax
f0100daa:	ba 00 00 00 00       	mov    $0x0,%edx
f0100daf:	eb 0e                	jmp    f0100dbf <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100db1:	8b 10                	mov    (%eax),%edx
f0100db3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100db6:	89 08                	mov    %ecx,(%eax)
f0100db8:	8b 02                	mov    (%edx),%eax
f0100dba:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100dbf:	5d                   	pop    %ebp
f0100dc0:	c3                   	ret    

f0100dc1 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100dc1:	55                   	push   %ebp
f0100dc2:	89 e5                	mov    %esp,%ebp
f0100dc4:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100dc7:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100dcb:	8b 10                	mov    (%eax),%edx
f0100dcd:	3b 50 04             	cmp    0x4(%eax),%edx
f0100dd0:	73 0a                	jae    f0100ddc <sprintputch+0x1b>
		*b->buf++ = ch;
f0100dd2:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dd5:	89 08                	mov    %ecx,(%eax)
f0100dd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dda:	88 02                	mov    %al,(%edx)
}
f0100ddc:	5d                   	pop    %ebp
f0100ddd:	c3                   	ret    

f0100dde <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dde:	55                   	push   %ebp
f0100ddf:	89 e5                	mov    %esp,%ebp
f0100de1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100de4:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100de7:	50                   	push   %eax
f0100de8:	ff 75 10             	pushl  0x10(%ebp)
f0100deb:	ff 75 0c             	pushl  0xc(%ebp)
f0100dee:	ff 75 08             	pushl  0x8(%ebp)
f0100df1:	e8 05 00 00 00       	call   f0100dfb <vprintfmt>
	va_end(ap);
}
f0100df6:	83 c4 10             	add    $0x10,%esp
f0100df9:	c9                   	leave  
f0100dfa:	c3                   	ret    

f0100dfb <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dfb:	55                   	push   %ebp
f0100dfc:	89 e5                	mov    %esp,%ebp
f0100dfe:	57                   	push   %edi
f0100dff:	56                   	push   %esi
f0100e00:	53                   	push   %ebx
f0100e01:	83 ec 2c             	sub    $0x2c,%esp
f0100e04:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e0a:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e0d:	eb 12                	jmp    f0100e21 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e0f:	85 c0                	test   %eax,%eax
f0100e11:	0f 84 89 03 00 00    	je     f01011a0 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100e17:	83 ec 08             	sub    $0x8,%esp
f0100e1a:	53                   	push   %ebx
f0100e1b:	50                   	push   %eax
f0100e1c:	ff d6                	call   *%esi
f0100e1e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e21:	83 c7 01             	add    $0x1,%edi
f0100e24:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e28:	83 f8 25             	cmp    $0x25,%eax
f0100e2b:	75 e2                	jne    f0100e0f <vprintfmt+0x14>
f0100e2d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e31:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e38:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e3f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e46:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e4b:	eb 07                	jmp    f0100e54 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e50:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e54:	8d 47 01             	lea    0x1(%edi),%eax
f0100e57:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e5a:	0f b6 07             	movzbl (%edi),%eax
f0100e5d:	0f b6 c8             	movzbl %al,%ecx
f0100e60:	83 e8 23             	sub    $0x23,%eax
f0100e63:	3c 55                	cmp    $0x55,%al
f0100e65:	0f 87 1a 03 00 00    	ja     f0101185 <vprintfmt+0x38a>
f0100e6b:	0f b6 c0             	movzbl %al,%eax
f0100e6e:	ff 24 85 e0 1e 10 f0 	jmp    *-0xfefe120(,%eax,4)
f0100e75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e78:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e7c:	eb d6                	jmp    f0100e54 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e81:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e86:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e89:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e8c:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e90:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e93:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e96:	83 fa 09             	cmp    $0x9,%edx
f0100e99:	77 39                	ja     f0100ed4 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e9b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e9e:	eb e9                	jmp    f0100e89 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ea0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ea3:	8d 48 04             	lea    0x4(%eax),%ecx
f0100ea6:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100ea9:	8b 00                	mov    (%eax),%eax
f0100eab:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100eb1:	eb 27                	jmp    f0100eda <vprintfmt+0xdf>
f0100eb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eb6:	85 c0                	test   %eax,%eax
f0100eb8:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ebd:	0f 49 c8             	cmovns %eax,%ecx
f0100ec0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ec6:	eb 8c                	jmp    f0100e54 <vprintfmt+0x59>
f0100ec8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ecb:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100ed2:	eb 80                	jmp    f0100e54 <vprintfmt+0x59>
f0100ed4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ed7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100eda:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ede:	0f 89 70 ff ff ff    	jns    f0100e54 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100ee4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ee7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100eea:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ef1:	e9 5e ff ff ff       	jmp    f0100e54 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ef6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100efc:	e9 53 ff ff ff       	jmp    f0100e54 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f01:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f04:	8d 50 04             	lea    0x4(%eax),%edx
f0100f07:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f0a:	83 ec 08             	sub    $0x8,%esp
f0100f0d:	53                   	push   %ebx
f0100f0e:	ff 30                	pushl  (%eax)
f0100f10:	ff d6                	call   *%esi
			break;
f0100f12:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f18:	e9 04 ff ff ff       	jmp    f0100e21 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f1d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f20:	8d 50 04             	lea    0x4(%eax),%edx
f0100f23:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f26:	8b 00                	mov    (%eax),%eax
f0100f28:	99                   	cltd   
f0100f29:	31 d0                	xor    %edx,%eax
f0100f2b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f2d:	83 f8 07             	cmp    $0x7,%eax
f0100f30:	7f 0b                	jg     f0100f3d <vprintfmt+0x142>
f0100f32:	8b 14 85 40 20 10 f0 	mov    -0xfefdfc0(,%eax,4),%edx
f0100f39:	85 d2                	test   %edx,%edx
f0100f3b:	75 18                	jne    f0100f55 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100f3d:	50                   	push   %eax
f0100f3e:	68 5d 1e 10 f0       	push   $0xf0101e5d
f0100f43:	53                   	push   %ebx
f0100f44:	56                   	push   %esi
f0100f45:	e8 94 fe ff ff       	call   f0100dde <printfmt>
f0100f4a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f50:	e9 cc fe ff ff       	jmp    f0100e21 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f55:	52                   	push   %edx
f0100f56:	68 66 1e 10 f0       	push   $0xf0101e66
f0100f5b:	53                   	push   %ebx
f0100f5c:	56                   	push   %esi
f0100f5d:	e8 7c fe ff ff       	call   f0100dde <printfmt>
f0100f62:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f68:	e9 b4 fe ff ff       	jmp    f0100e21 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f70:	8d 50 04             	lea    0x4(%eax),%edx
f0100f73:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f76:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f78:	85 ff                	test   %edi,%edi
f0100f7a:	b8 56 1e 10 f0       	mov    $0xf0101e56,%eax
f0100f7f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f82:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f86:	0f 8e 94 00 00 00    	jle    f0101020 <vprintfmt+0x225>
f0100f8c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f90:	0f 84 98 00 00 00    	je     f010102e <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f96:	83 ec 08             	sub    $0x8,%esp
f0100f99:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f9c:	57                   	push   %edi
f0100f9d:	e8 5f 03 00 00       	call   f0101301 <strnlen>
f0100fa2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100fa5:	29 c1                	sub    %eax,%ecx
f0100fa7:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100faa:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100fad:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100fb1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fb4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fb7:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fb9:	eb 0f                	jmp    f0100fca <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100fbb:	83 ec 08             	sub    $0x8,%esp
f0100fbe:	53                   	push   %ebx
f0100fbf:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fc2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fc4:	83 ef 01             	sub    $0x1,%edi
f0100fc7:	83 c4 10             	add    $0x10,%esp
f0100fca:	85 ff                	test   %edi,%edi
f0100fcc:	7f ed                	jg     f0100fbb <vprintfmt+0x1c0>
f0100fce:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fd1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fd4:	85 c9                	test   %ecx,%ecx
f0100fd6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fdb:	0f 49 c1             	cmovns %ecx,%eax
f0100fde:	29 c1                	sub    %eax,%ecx
f0100fe0:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fe3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fe6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fe9:	89 cb                	mov    %ecx,%ebx
f0100feb:	eb 4d                	jmp    f010103a <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100ff1:	74 1b                	je     f010100e <vprintfmt+0x213>
f0100ff3:	0f be c0             	movsbl %al,%eax
f0100ff6:	83 e8 20             	sub    $0x20,%eax
f0100ff9:	83 f8 5e             	cmp    $0x5e,%eax
f0100ffc:	76 10                	jbe    f010100e <vprintfmt+0x213>
					putch('?', putdat);
f0100ffe:	83 ec 08             	sub    $0x8,%esp
f0101001:	ff 75 0c             	pushl  0xc(%ebp)
f0101004:	6a 3f                	push   $0x3f
f0101006:	ff 55 08             	call   *0x8(%ebp)
f0101009:	83 c4 10             	add    $0x10,%esp
f010100c:	eb 0d                	jmp    f010101b <vprintfmt+0x220>
				else
					putch(ch, putdat);
f010100e:	83 ec 08             	sub    $0x8,%esp
f0101011:	ff 75 0c             	pushl  0xc(%ebp)
f0101014:	52                   	push   %edx
f0101015:	ff 55 08             	call   *0x8(%ebp)
f0101018:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010101b:	83 eb 01             	sub    $0x1,%ebx
f010101e:	eb 1a                	jmp    f010103a <vprintfmt+0x23f>
f0101020:	89 75 08             	mov    %esi,0x8(%ebp)
f0101023:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101026:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101029:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010102c:	eb 0c                	jmp    f010103a <vprintfmt+0x23f>
f010102e:	89 75 08             	mov    %esi,0x8(%ebp)
f0101031:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101034:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101037:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010103a:	83 c7 01             	add    $0x1,%edi
f010103d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101041:	0f be d0             	movsbl %al,%edx
f0101044:	85 d2                	test   %edx,%edx
f0101046:	74 23                	je     f010106b <vprintfmt+0x270>
f0101048:	85 f6                	test   %esi,%esi
f010104a:	78 a1                	js     f0100fed <vprintfmt+0x1f2>
f010104c:	83 ee 01             	sub    $0x1,%esi
f010104f:	79 9c                	jns    f0100fed <vprintfmt+0x1f2>
f0101051:	89 df                	mov    %ebx,%edi
f0101053:	8b 75 08             	mov    0x8(%ebp),%esi
f0101056:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101059:	eb 18                	jmp    f0101073 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010105b:	83 ec 08             	sub    $0x8,%esp
f010105e:	53                   	push   %ebx
f010105f:	6a 20                	push   $0x20
f0101061:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101063:	83 ef 01             	sub    $0x1,%edi
f0101066:	83 c4 10             	add    $0x10,%esp
f0101069:	eb 08                	jmp    f0101073 <vprintfmt+0x278>
f010106b:	89 df                	mov    %ebx,%edi
f010106d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101070:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101073:	85 ff                	test   %edi,%edi
f0101075:	7f e4                	jg     f010105b <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101077:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010107a:	e9 a2 fd ff ff       	jmp    f0100e21 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010107f:	83 fa 01             	cmp    $0x1,%edx
f0101082:	7e 16                	jle    f010109a <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101084:	8b 45 14             	mov    0x14(%ebp),%eax
f0101087:	8d 50 08             	lea    0x8(%eax),%edx
f010108a:	89 55 14             	mov    %edx,0x14(%ebp)
f010108d:	8b 50 04             	mov    0x4(%eax),%edx
f0101090:	8b 00                	mov    (%eax),%eax
f0101092:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101095:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101098:	eb 32                	jmp    f01010cc <vprintfmt+0x2d1>
	else if (lflag)
f010109a:	85 d2                	test   %edx,%edx
f010109c:	74 18                	je     f01010b6 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f010109e:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a1:	8d 50 04             	lea    0x4(%eax),%edx
f01010a4:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a7:	8b 00                	mov    (%eax),%eax
f01010a9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010ac:	89 c1                	mov    %eax,%ecx
f01010ae:	c1 f9 1f             	sar    $0x1f,%ecx
f01010b1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010b4:	eb 16                	jmp    f01010cc <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f01010b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b9:	8d 50 04             	lea    0x4(%eax),%edx
f01010bc:	89 55 14             	mov    %edx,0x14(%ebp)
f01010bf:	8b 00                	mov    (%eax),%eax
f01010c1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010c4:	89 c1                	mov    %eax,%ecx
f01010c6:	c1 f9 1f             	sar    $0x1f,%ecx
f01010c9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010cc:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010cf:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010d2:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010d7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010db:	79 74                	jns    f0101151 <vprintfmt+0x356>
				putch('-', putdat);
f01010dd:	83 ec 08             	sub    $0x8,%esp
f01010e0:	53                   	push   %ebx
f01010e1:	6a 2d                	push   $0x2d
f01010e3:	ff d6                	call   *%esi
				num = -(long long) num;
f01010e5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010e8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010eb:	f7 d8                	neg    %eax
f01010ed:	83 d2 00             	adc    $0x0,%edx
f01010f0:	f7 da                	neg    %edx
f01010f2:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010f5:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010fa:	eb 55                	jmp    f0101151 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010fc:	8d 45 14             	lea    0x14(%ebp),%eax
f01010ff:	e8 83 fc ff ff       	call   f0100d87 <getuint>
			base = 10;
f0101104:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101109:	eb 46                	jmp    f0101151 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010110b:	8d 45 14             	lea    0x14(%ebp),%eax
f010110e:	e8 74 fc ff ff       	call   f0100d87 <getuint>
			base = 8;
f0101113:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101118:	eb 37                	jmp    f0101151 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010111a:	83 ec 08             	sub    $0x8,%esp
f010111d:	53                   	push   %ebx
f010111e:	6a 30                	push   $0x30
f0101120:	ff d6                	call   *%esi
			putch('x', putdat);
f0101122:	83 c4 08             	add    $0x8,%esp
f0101125:	53                   	push   %ebx
f0101126:	6a 78                	push   $0x78
f0101128:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010112a:	8b 45 14             	mov    0x14(%ebp),%eax
f010112d:	8d 50 04             	lea    0x4(%eax),%edx
f0101130:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101133:	8b 00                	mov    (%eax),%eax
f0101135:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010113a:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010113d:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101142:	eb 0d                	jmp    f0101151 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101144:	8d 45 14             	lea    0x14(%ebp),%eax
f0101147:	e8 3b fc ff ff       	call   f0100d87 <getuint>
			base = 16;
f010114c:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101151:	83 ec 0c             	sub    $0xc,%esp
f0101154:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101158:	57                   	push   %edi
f0101159:	ff 75 e0             	pushl  -0x20(%ebp)
f010115c:	51                   	push   %ecx
f010115d:	52                   	push   %edx
f010115e:	50                   	push   %eax
f010115f:	89 da                	mov    %ebx,%edx
f0101161:	89 f0                	mov    %esi,%eax
f0101163:	e8 70 fb ff ff       	call   f0100cd8 <printnum>
			break;
f0101168:	83 c4 20             	add    $0x20,%esp
f010116b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010116e:	e9 ae fc ff ff       	jmp    f0100e21 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101173:	83 ec 08             	sub    $0x8,%esp
f0101176:	53                   	push   %ebx
f0101177:	51                   	push   %ecx
f0101178:	ff d6                	call   *%esi
			break;
f010117a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010117d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101180:	e9 9c fc ff ff       	jmp    f0100e21 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101185:	83 ec 08             	sub    $0x8,%esp
f0101188:	53                   	push   %ebx
f0101189:	6a 25                	push   $0x25
f010118b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010118d:	83 c4 10             	add    $0x10,%esp
f0101190:	eb 03                	jmp    f0101195 <vprintfmt+0x39a>
f0101192:	83 ef 01             	sub    $0x1,%edi
f0101195:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101199:	75 f7                	jne    f0101192 <vprintfmt+0x397>
f010119b:	e9 81 fc ff ff       	jmp    f0100e21 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01011a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a3:	5b                   	pop    %ebx
f01011a4:	5e                   	pop    %esi
f01011a5:	5f                   	pop    %edi
f01011a6:	5d                   	pop    %ebp
f01011a7:	c3                   	ret    

f01011a8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011a8:	55                   	push   %ebp
f01011a9:	89 e5                	mov    %esp,%ebp
f01011ab:	83 ec 18             	sub    $0x18,%esp
f01011ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011b4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011b7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011bb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011be:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011c5:	85 c0                	test   %eax,%eax
f01011c7:	74 26                	je     f01011ef <vsnprintf+0x47>
f01011c9:	85 d2                	test   %edx,%edx
f01011cb:	7e 22                	jle    f01011ef <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011cd:	ff 75 14             	pushl  0x14(%ebp)
f01011d0:	ff 75 10             	pushl  0x10(%ebp)
f01011d3:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011d6:	50                   	push   %eax
f01011d7:	68 c1 0d 10 f0       	push   $0xf0100dc1
f01011dc:	e8 1a fc ff ff       	call   f0100dfb <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011e4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ea:	83 c4 10             	add    $0x10,%esp
f01011ed:	eb 05                	jmp    f01011f4 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011ef:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011f4:	c9                   	leave  
f01011f5:	c3                   	ret    

f01011f6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011f6:	55                   	push   %ebp
f01011f7:	89 e5                	mov    %esp,%ebp
f01011f9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011fc:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011ff:	50                   	push   %eax
f0101200:	ff 75 10             	pushl  0x10(%ebp)
f0101203:	ff 75 0c             	pushl  0xc(%ebp)
f0101206:	ff 75 08             	pushl  0x8(%ebp)
f0101209:	e8 9a ff ff ff       	call   f01011a8 <vsnprintf>
	va_end(ap);

	return rc;
}
f010120e:	c9                   	leave  
f010120f:	c3                   	ret    

f0101210 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101210:	55                   	push   %ebp
f0101211:	89 e5                	mov    %esp,%ebp
f0101213:	57                   	push   %edi
f0101214:	56                   	push   %esi
f0101215:	53                   	push   %ebx
f0101216:	83 ec 0c             	sub    $0xc,%esp
f0101219:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010121c:	85 c0                	test   %eax,%eax
f010121e:	74 11                	je     f0101231 <readline+0x21>
		cprintf("%s", prompt);
f0101220:	83 ec 08             	sub    $0x8,%esp
f0101223:	50                   	push   %eax
f0101224:	68 66 1e 10 f0       	push   $0xf0101e66
f0101229:	e8 90 f7 ff ff       	call   f01009be <cprintf>
f010122e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101231:	83 ec 0c             	sub    $0xc,%esp
f0101234:	6a 00                	push   $0x0
f0101236:	e8 33 f4 ff ff       	call   f010066e <iscons>
f010123b:	89 c7                	mov    %eax,%edi
f010123d:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101240:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101245:	e8 13 f4 ff ff       	call   f010065d <getchar>
f010124a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010124c:	85 c0                	test   %eax,%eax
f010124e:	79 18                	jns    f0101268 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101250:	83 ec 08             	sub    $0x8,%esp
f0101253:	50                   	push   %eax
f0101254:	68 60 20 10 f0       	push   $0xf0102060
f0101259:	e8 60 f7 ff ff       	call   f01009be <cprintf>
			return NULL;
f010125e:	83 c4 10             	add    $0x10,%esp
f0101261:	b8 00 00 00 00       	mov    $0x0,%eax
f0101266:	eb 79                	jmp    f01012e1 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101268:	83 f8 08             	cmp    $0x8,%eax
f010126b:	0f 94 c2             	sete   %dl
f010126e:	83 f8 7f             	cmp    $0x7f,%eax
f0101271:	0f 94 c0             	sete   %al
f0101274:	08 c2                	or     %al,%dl
f0101276:	74 1a                	je     f0101292 <readline+0x82>
f0101278:	85 f6                	test   %esi,%esi
f010127a:	7e 16                	jle    f0101292 <readline+0x82>
			if (echoing)
f010127c:	85 ff                	test   %edi,%edi
f010127e:	74 0d                	je     f010128d <readline+0x7d>
				cputchar('\b');
f0101280:	83 ec 0c             	sub    $0xc,%esp
f0101283:	6a 08                	push   $0x8
f0101285:	e8 c3 f3 ff ff       	call   f010064d <cputchar>
f010128a:	83 c4 10             	add    $0x10,%esp
			i--;
f010128d:	83 ee 01             	sub    $0x1,%esi
f0101290:	eb b3                	jmp    f0101245 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101292:	83 fb 1f             	cmp    $0x1f,%ebx
f0101295:	7e 23                	jle    f01012ba <readline+0xaa>
f0101297:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010129d:	7f 1b                	jg     f01012ba <readline+0xaa>
			if (echoing)
f010129f:	85 ff                	test   %edi,%edi
f01012a1:	74 0c                	je     f01012af <readline+0x9f>
				cputchar(c);
f01012a3:	83 ec 0c             	sub    $0xc,%esp
f01012a6:	53                   	push   %ebx
f01012a7:	e8 a1 f3 ff ff       	call   f010064d <cputchar>
f01012ac:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012af:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012b5:	8d 76 01             	lea    0x1(%esi),%esi
f01012b8:	eb 8b                	jmp    f0101245 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012ba:	83 fb 0a             	cmp    $0xa,%ebx
f01012bd:	74 05                	je     f01012c4 <readline+0xb4>
f01012bf:	83 fb 0d             	cmp    $0xd,%ebx
f01012c2:	75 81                	jne    f0101245 <readline+0x35>
			if (echoing)
f01012c4:	85 ff                	test   %edi,%edi
f01012c6:	74 0d                	je     f01012d5 <readline+0xc5>
				cputchar('\n');
f01012c8:	83 ec 0c             	sub    $0xc,%esp
f01012cb:	6a 0a                	push   $0xa
f01012cd:	e8 7b f3 ff ff       	call   f010064d <cputchar>
f01012d2:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012d5:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012dc:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012e4:	5b                   	pop    %ebx
f01012e5:	5e                   	pop    %esi
f01012e6:	5f                   	pop    %edi
f01012e7:	5d                   	pop    %ebp
f01012e8:	c3                   	ret    

f01012e9 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012e9:	55                   	push   %ebp
f01012ea:	89 e5                	mov    %esp,%ebp
f01012ec:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01012f4:	eb 03                	jmp    f01012f9 <strlen+0x10>
		n++;
f01012f6:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012f9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012fd:	75 f7                	jne    f01012f6 <strlen+0xd>
		n++;
	return n;
}
f01012ff:	5d                   	pop    %ebp
f0101300:	c3                   	ret    

f0101301 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101301:	55                   	push   %ebp
f0101302:	89 e5                	mov    %esp,%ebp
f0101304:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101307:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010130a:	ba 00 00 00 00       	mov    $0x0,%edx
f010130f:	eb 03                	jmp    f0101314 <strnlen+0x13>
		n++;
f0101311:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101314:	39 c2                	cmp    %eax,%edx
f0101316:	74 08                	je     f0101320 <strnlen+0x1f>
f0101318:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010131c:	75 f3                	jne    f0101311 <strnlen+0x10>
f010131e:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101320:	5d                   	pop    %ebp
f0101321:	c3                   	ret    

f0101322 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101322:	55                   	push   %ebp
f0101323:	89 e5                	mov    %esp,%ebp
f0101325:	53                   	push   %ebx
f0101326:	8b 45 08             	mov    0x8(%ebp),%eax
f0101329:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010132c:	89 c2                	mov    %eax,%edx
f010132e:	83 c2 01             	add    $0x1,%edx
f0101331:	83 c1 01             	add    $0x1,%ecx
f0101334:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101338:	88 5a ff             	mov    %bl,-0x1(%edx)
f010133b:	84 db                	test   %bl,%bl
f010133d:	75 ef                	jne    f010132e <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010133f:	5b                   	pop    %ebx
f0101340:	5d                   	pop    %ebp
f0101341:	c3                   	ret    

f0101342 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101342:	55                   	push   %ebp
f0101343:	89 e5                	mov    %esp,%ebp
f0101345:	53                   	push   %ebx
f0101346:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101349:	53                   	push   %ebx
f010134a:	e8 9a ff ff ff       	call   f01012e9 <strlen>
f010134f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101352:	ff 75 0c             	pushl  0xc(%ebp)
f0101355:	01 d8                	add    %ebx,%eax
f0101357:	50                   	push   %eax
f0101358:	e8 c5 ff ff ff       	call   f0101322 <strcpy>
	return dst;
}
f010135d:	89 d8                	mov    %ebx,%eax
f010135f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101362:	c9                   	leave  
f0101363:	c3                   	ret    

f0101364 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101364:	55                   	push   %ebp
f0101365:	89 e5                	mov    %esp,%ebp
f0101367:	56                   	push   %esi
f0101368:	53                   	push   %ebx
f0101369:	8b 75 08             	mov    0x8(%ebp),%esi
f010136c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010136f:	89 f3                	mov    %esi,%ebx
f0101371:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101374:	89 f2                	mov    %esi,%edx
f0101376:	eb 0f                	jmp    f0101387 <strncpy+0x23>
		*dst++ = *src;
f0101378:	83 c2 01             	add    $0x1,%edx
f010137b:	0f b6 01             	movzbl (%ecx),%eax
f010137e:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101381:	80 39 01             	cmpb   $0x1,(%ecx)
f0101384:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101387:	39 da                	cmp    %ebx,%edx
f0101389:	75 ed                	jne    f0101378 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010138b:	89 f0                	mov    %esi,%eax
f010138d:	5b                   	pop    %ebx
f010138e:	5e                   	pop    %esi
f010138f:	5d                   	pop    %ebp
f0101390:	c3                   	ret    

f0101391 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101391:	55                   	push   %ebp
f0101392:	89 e5                	mov    %esp,%ebp
f0101394:	56                   	push   %esi
f0101395:	53                   	push   %ebx
f0101396:	8b 75 08             	mov    0x8(%ebp),%esi
f0101399:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010139c:	8b 55 10             	mov    0x10(%ebp),%edx
f010139f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013a1:	85 d2                	test   %edx,%edx
f01013a3:	74 21                	je     f01013c6 <strlcpy+0x35>
f01013a5:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013a9:	89 f2                	mov    %esi,%edx
f01013ab:	eb 09                	jmp    f01013b6 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013ad:	83 c2 01             	add    $0x1,%edx
f01013b0:	83 c1 01             	add    $0x1,%ecx
f01013b3:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013b6:	39 c2                	cmp    %eax,%edx
f01013b8:	74 09                	je     f01013c3 <strlcpy+0x32>
f01013ba:	0f b6 19             	movzbl (%ecx),%ebx
f01013bd:	84 db                	test   %bl,%bl
f01013bf:	75 ec                	jne    f01013ad <strlcpy+0x1c>
f01013c1:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013c3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013c6:	29 f0                	sub    %esi,%eax
}
f01013c8:	5b                   	pop    %ebx
f01013c9:	5e                   	pop    %esi
f01013ca:	5d                   	pop    %ebp
f01013cb:	c3                   	ret    

f01013cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013cc:	55                   	push   %ebp
f01013cd:	89 e5                	mov    %esp,%ebp
f01013cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013d5:	eb 06                	jmp    f01013dd <strcmp+0x11>
		p++, q++;
f01013d7:	83 c1 01             	add    $0x1,%ecx
f01013da:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013dd:	0f b6 01             	movzbl (%ecx),%eax
f01013e0:	84 c0                	test   %al,%al
f01013e2:	74 04                	je     f01013e8 <strcmp+0x1c>
f01013e4:	3a 02                	cmp    (%edx),%al
f01013e6:	74 ef                	je     f01013d7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013e8:	0f b6 c0             	movzbl %al,%eax
f01013eb:	0f b6 12             	movzbl (%edx),%edx
f01013ee:	29 d0                	sub    %edx,%eax
}
f01013f0:	5d                   	pop    %ebp
f01013f1:	c3                   	ret    

f01013f2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013f2:	55                   	push   %ebp
f01013f3:	89 e5                	mov    %esp,%ebp
f01013f5:	53                   	push   %ebx
f01013f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013fc:	89 c3                	mov    %eax,%ebx
f01013fe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101401:	eb 06                	jmp    f0101409 <strncmp+0x17>
		n--, p++, q++;
f0101403:	83 c0 01             	add    $0x1,%eax
f0101406:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101409:	39 d8                	cmp    %ebx,%eax
f010140b:	74 15                	je     f0101422 <strncmp+0x30>
f010140d:	0f b6 08             	movzbl (%eax),%ecx
f0101410:	84 c9                	test   %cl,%cl
f0101412:	74 04                	je     f0101418 <strncmp+0x26>
f0101414:	3a 0a                	cmp    (%edx),%cl
f0101416:	74 eb                	je     f0101403 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101418:	0f b6 00             	movzbl (%eax),%eax
f010141b:	0f b6 12             	movzbl (%edx),%edx
f010141e:	29 d0                	sub    %edx,%eax
f0101420:	eb 05                	jmp    f0101427 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101422:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101427:	5b                   	pop    %ebx
f0101428:	5d                   	pop    %ebp
f0101429:	c3                   	ret    

f010142a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010142a:	55                   	push   %ebp
f010142b:	89 e5                	mov    %esp,%ebp
f010142d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101430:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101434:	eb 07                	jmp    f010143d <strchr+0x13>
		if (*s == c)
f0101436:	38 ca                	cmp    %cl,%dl
f0101438:	74 0f                	je     f0101449 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010143a:	83 c0 01             	add    $0x1,%eax
f010143d:	0f b6 10             	movzbl (%eax),%edx
f0101440:	84 d2                	test   %dl,%dl
f0101442:	75 f2                	jne    f0101436 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101444:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101449:	5d                   	pop    %ebp
f010144a:	c3                   	ret    

f010144b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010144b:	55                   	push   %ebp
f010144c:	89 e5                	mov    %esp,%ebp
f010144e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101451:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101455:	eb 03                	jmp    f010145a <strfind+0xf>
f0101457:	83 c0 01             	add    $0x1,%eax
f010145a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010145d:	38 ca                	cmp    %cl,%dl
f010145f:	74 04                	je     f0101465 <strfind+0x1a>
f0101461:	84 d2                	test   %dl,%dl
f0101463:	75 f2                	jne    f0101457 <strfind+0xc>
			break;
	return (char *) s;
}
f0101465:	5d                   	pop    %ebp
f0101466:	c3                   	ret    

f0101467 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101467:	55                   	push   %ebp
f0101468:	89 e5                	mov    %esp,%ebp
f010146a:	57                   	push   %edi
f010146b:	56                   	push   %esi
f010146c:	53                   	push   %ebx
f010146d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101470:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101473:	85 c9                	test   %ecx,%ecx
f0101475:	74 36                	je     f01014ad <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101477:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010147d:	75 28                	jne    f01014a7 <memset+0x40>
f010147f:	f6 c1 03             	test   $0x3,%cl
f0101482:	75 23                	jne    f01014a7 <memset+0x40>
		c &= 0xFF;
f0101484:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101488:	89 d3                	mov    %edx,%ebx
f010148a:	c1 e3 08             	shl    $0x8,%ebx
f010148d:	89 d6                	mov    %edx,%esi
f010148f:	c1 e6 18             	shl    $0x18,%esi
f0101492:	89 d0                	mov    %edx,%eax
f0101494:	c1 e0 10             	shl    $0x10,%eax
f0101497:	09 f0                	or     %esi,%eax
f0101499:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010149b:	89 d8                	mov    %ebx,%eax
f010149d:	09 d0                	or     %edx,%eax
f010149f:	c1 e9 02             	shr    $0x2,%ecx
f01014a2:	fc                   	cld    
f01014a3:	f3 ab                	rep stos %eax,%es:(%edi)
f01014a5:	eb 06                	jmp    f01014ad <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014aa:	fc                   	cld    
f01014ab:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014ad:	89 f8                	mov    %edi,%eax
f01014af:	5b                   	pop    %ebx
f01014b0:	5e                   	pop    %esi
f01014b1:	5f                   	pop    %edi
f01014b2:	5d                   	pop    %ebp
f01014b3:	c3                   	ret    

f01014b4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014b4:	55                   	push   %ebp
f01014b5:	89 e5                	mov    %esp,%ebp
f01014b7:	57                   	push   %edi
f01014b8:	56                   	push   %esi
f01014b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014bc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014bf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014c2:	39 c6                	cmp    %eax,%esi
f01014c4:	73 35                	jae    f01014fb <memmove+0x47>
f01014c6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014c9:	39 d0                	cmp    %edx,%eax
f01014cb:	73 2e                	jae    f01014fb <memmove+0x47>
		s += n;
		d += n;
f01014cd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014d0:	89 d6                	mov    %edx,%esi
f01014d2:	09 fe                	or     %edi,%esi
f01014d4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014da:	75 13                	jne    f01014ef <memmove+0x3b>
f01014dc:	f6 c1 03             	test   $0x3,%cl
f01014df:	75 0e                	jne    f01014ef <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014e1:	83 ef 04             	sub    $0x4,%edi
f01014e4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014e7:	c1 e9 02             	shr    $0x2,%ecx
f01014ea:	fd                   	std    
f01014eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014ed:	eb 09                	jmp    f01014f8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014ef:	83 ef 01             	sub    $0x1,%edi
f01014f2:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014f5:	fd                   	std    
f01014f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014f8:	fc                   	cld    
f01014f9:	eb 1d                	jmp    f0101518 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014fb:	89 f2                	mov    %esi,%edx
f01014fd:	09 c2                	or     %eax,%edx
f01014ff:	f6 c2 03             	test   $0x3,%dl
f0101502:	75 0f                	jne    f0101513 <memmove+0x5f>
f0101504:	f6 c1 03             	test   $0x3,%cl
f0101507:	75 0a                	jne    f0101513 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101509:	c1 e9 02             	shr    $0x2,%ecx
f010150c:	89 c7                	mov    %eax,%edi
f010150e:	fc                   	cld    
f010150f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101511:	eb 05                	jmp    f0101518 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101513:	89 c7                	mov    %eax,%edi
f0101515:	fc                   	cld    
f0101516:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101518:	5e                   	pop    %esi
f0101519:	5f                   	pop    %edi
f010151a:	5d                   	pop    %ebp
f010151b:	c3                   	ret    

f010151c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010151c:	55                   	push   %ebp
f010151d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010151f:	ff 75 10             	pushl  0x10(%ebp)
f0101522:	ff 75 0c             	pushl  0xc(%ebp)
f0101525:	ff 75 08             	pushl  0x8(%ebp)
f0101528:	e8 87 ff ff ff       	call   f01014b4 <memmove>
}
f010152d:	c9                   	leave  
f010152e:	c3                   	ret    

f010152f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010152f:	55                   	push   %ebp
f0101530:	89 e5                	mov    %esp,%ebp
f0101532:	56                   	push   %esi
f0101533:	53                   	push   %ebx
f0101534:	8b 45 08             	mov    0x8(%ebp),%eax
f0101537:	8b 55 0c             	mov    0xc(%ebp),%edx
f010153a:	89 c6                	mov    %eax,%esi
f010153c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010153f:	eb 1a                	jmp    f010155b <memcmp+0x2c>
		if (*s1 != *s2)
f0101541:	0f b6 08             	movzbl (%eax),%ecx
f0101544:	0f b6 1a             	movzbl (%edx),%ebx
f0101547:	38 d9                	cmp    %bl,%cl
f0101549:	74 0a                	je     f0101555 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010154b:	0f b6 c1             	movzbl %cl,%eax
f010154e:	0f b6 db             	movzbl %bl,%ebx
f0101551:	29 d8                	sub    %ebx,%eax
f0101553:	eb 0f                	jmp    f0101564 <memcmp+0x35>
		s1++, s2++;
f0101555:	83 c0 01             	add    $0x1,%eax
f0101558:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010155b:	39 f0                	cmp    %esi,%eax
f010155d:	75 e2                	jne    f0101541 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010155f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101564:	5b                   	pop    %ebx
f0101565:	5e                   	pop    %esi
f0101566:	5d                   	pop    %ebp
f0101567:	c3                   	ret    

f0101568 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101568:	55                   	push   %ebp
f0101569:	89 e5                	mov    %esp,%ebp
f010156b:	53                   	push   %ebx
f010156c:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010156f:	89 c1                	mov    %eax,%ecx
f0101571:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101574:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101578:	eb 0a                	jmp    f0101584 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010157a:	0f b6 10             	movzbl (%eax),%edx
f010157d:	39 da                	cmp    %ebx,%edx
f010157f:	74 07                	je     f0101588 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101581:	83 c0 01             	add    $0x1,%eax
f0101584:	39 c8                	cmp    %ecx,%eax
f0101586:	72 f2                	jb     f010157a <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101588:	5b                   	pop    %ebx
f0101589:	5d                   	pop    %ebp
f010158a:	c3                   	ret    

f010158b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010158b:	55                   	push   %ebp
f010158c:	89 e5                	mov    %esp,%ebp
f010158e:	57                   	push   %edi
f010158f:	56                   	push   %esi
f0101590:	53                   	push   %ebx
f0101591:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101594:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101597:	eb 03                	jmp    f010159c <strtol+0x11>
		s++;
f0101599:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010159c:	0f b6 01             	movzbl (%ecx),%eax
f010159f:	3c 20                	cmp    $0x20,%al
f01015a1:	74 f6                	je     f0101599 <strtol+0xe>
f01015a3:	3c 09                	cmp    $0x9,%al
f01015a5:	74 f2                	je     f0101599 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015a7:	3c 2b                	cmp    $0x2b,%al
f01015a9:	75 0a                	jne    f01015b5 <strtol+0x2a>
		s++;
f01015ab:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015ae:	bf 00 00 00 00       	mov    $0x0,%edi
f01015b3:	eb 11                	jmp    f01015c6 <strtol+0x3b>
f01015b5:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015ba:	3c 2d                	cmp    $0x2d,%al
f01015bc:	75 08                	jne    f01015c6 <strtol+0x3b>
		s++, neg = 1;
f01015be:	83 c1 01             	add    $0x1,%ecx
f01015c1:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015c6:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015cc:	75 15                	jne    f01015e3 <strtol+0x58>
f01015ce:	80 39 30             	cmpb   $0x30,(%ecx)
f01015d1:	75 10                	jne    f01015e3 <strtol+0x58>
f01015d3:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015d7:	75 7c                	jne    f0101655 <strtol+0xca>
		s += 2, base = 16;
f01015d9:	83 c1 02             	add    $0x2,%ecx
f01015dc:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015e1:	eb 16                	jmp    f01015f9 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01015e3:	85 db                	test   %ebx,%ebx
f01015e5:	75 12                	jne    f01015f9 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015e7:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015ec:	80 39 30             	cmpb   $0x30,(%ecx)
f01015ef:	75 08                	jne    f01015f9 <strtol+0x6e>
		s++, base = 8;
f01015f1:	83 c1 01             	add    $0x1,%ecx
f01015f4:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01015fe:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101601:	0f b6 11             	movzbl (%ecx),%edx
f0101604:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101607:	89 f3                	mov    %esi,%ebx
f0101609:	80 fb 09             	cmp    $0x9,%bl
f010160c:	77 08                	ja     f0101616 <strtol+0x8b>
			dig = *s - '0';
f010160e:	0f be d2             	movsbl %dl,%edx
f0101611:	83 ea 30             	sub    $0x30,%edx
f0101614:	eb 22                	jmp    f0101638 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101616:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101619:	89 f3                	mov    %esi,%ebx
f010161b:	80 fb 19             	cmp    $0x19,%bl
f010161e:	77 08                	ja     f0101628 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101620:	0f be d2             	movsbl %dl,%edx
f0101623:	83 ea 57             	sub    $0x57,%edx
f0101626:	eb 10                	jmp    f0101638 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101628:	8d 72 bf             	lea    -0x41(%edx),%esi
f010162b:	89 f3                	mov    %esi,%ebx
f010162d:	80 fb 19             	cmp    $0x19,%bl
f0101630:	77 16                	ja     f0101648 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101632:	0f be d2             	movsbl %dl,%edx
f0101635:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101638:	3b 55 10             	cmp    0x10(%ebp),%edx
f010163b:	7d 0b                	jge    f0101648 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010163d:	83 c1 01             	add    $0x1,%ecx
f0101640:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101644:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101646:	eb b9                	jmp    f0101601 <strtol+0x76>

	if (endptr)
f0101648:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010164c:	74 0d                	je     f010165b <strtol+0xd0>
		*endptr = (char *) s;
f010164e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101651:	89 0e                	mov    %ecx,(%esi)
f0101653:	eb 06                	jmp    f010165b <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101655:	85 db                	test   %ebx,%ebx
f0101657:	74 98                	je     f01015f1 <strtol+0x66>
f0101659:	eb 9e                	jmp    f01015f9 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010165b:	89 c2                	mov    %eax,%edx
f010165d:	f7 da                	neg    %edx
f010165f:	85 ff                	test   %edi,%edi
f0101661:	0f 45 c2             	cmovne %edx,%eax
}
f0101664:	5b                   	pop    %ebx
f0101665:	5e                   	pop    %esi
f0101666:	5f                   	pop    %edi
f0101667:	5d                   	pop    %ebp
f0101668:	c3                   	ret    
f0101669:	66 90                	xchg   %ax,%ax
f010166b:	66 90                	xchg   %ax,%ax
f010166d:	66 90                	xchg   %ax,%ax
f010166f:	90                   	nop

f0101670 <__udivdi3>:
f0101670:	55                   	push   %ebp
f0101671:	57                   	push   %edi
f0101672:	56                   	push   %esi
f0101673:	53                   	push   %ebx
f0101674:	83 ec 1c             	sub    $0x1c,%esp
f0101677:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010167b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010167f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101683:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101687:	85 f6                	test   %esi,%esi
f0101689:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010168d:	89 ca                	mov    %ecx,%edx
f010168f:	89 f8                	mov    %edi,%eax
f0101691:	75 3d                	jne    f01016d0 <__udivdi3+0x60>
f0101693:	39 cf                	cmp    %ecx,%edi
f0101695:	0f 87 c5 00 00 00    	ja     f0101760 <__udivdi3+0xf0>
f010169b:	85 ff                	test   %edi,%edi
f010169d:	89 fd                	mov    %edi,%ebp
f010169f:	75 0b                	jne    f01016ac <__udivdi3+0x3c>
f01016a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016a6:	31 d2                	xor    %edx,%edx
f01016a8:	f7 f7                	div    %edi
f01016aa:	89 c5                	mov    %eax,%ebp
f01016ac:	89 c8                	mov    %ecx,%eax
f01016ae:	31 d2                	xor    %edx,%edx
f01016b0:	f7 f5                	div    %ebp
f01016b2:	89 c1                	mov    %eax,%ecx
f01016b4:	89 d8                	mov    %ebx,%eax
f01016b6:	89 cf                	mov    %ecx,%edi
f01016b8:	f7 f5                	div    %ebp
f01016ba:	89 c3                	mov    %eax,%ebx
f01016bc:	89 d8                	mov    %ebx,%eax
f01016be:	89 fa                	mov    %edi,%edx
f01016c0:	83 c4 1c             	add    $0x1c,%esp
f01016c3:	5b                   	pop    %ebx
f01016c4:	5e                   	pop    %esi
f01016c5:	5f                   	pop    %edi
f01016c6:	5d                   	pop    %ebp
f01016c7:	c3                   	ret    
f01016c8:	90                   	nop
f01016c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016d0:	39 ce                	cmp    %ecx,%esi
f01016d2:	77 74                	ja     f0101748 <__udivdi3+0xd8>
f01016d4:	0f bd fe             	bsr    %esi,%edi
f01016d7:	83 f7 1f             	xor    $0x1f,%edi
f01016da:	0f 84 98 00 00 00    	je     f0101778 <__udivdi3+0x108>
f01016e0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01016e5:	89 f9                	mov    %edi,%ecx
f01016e7:	89 c5                	mov    %eax,%ebp
f01016e9:	29 fb                	sub    %edi,%ebx
f01016eb:	d3 e6                	shl    %cl,%esi
f01016ed:	89 d9                	mov    %ebx,%ecx
f01016ef:	d3 ed                	shr    %cl,%ebp
f01016f1:	89 f9                	mov    %edi,%ecx
f01016f3:	d3 e0                	shl    %cl,%eax
f01016f5:	09 ee                	or     %ebp,%esi
f01016f7:	89 d9                	mov    %ebx,%ecx
f01016f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016fd:	89 d5                	mov    %edx,%ebp
f01016ff:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101703:	d3 ed                	shr    %cl,%ebp
f0101705:	89 f9                	mov    %edi,%ecx
f0101707:	d3 e2                	shl    %cl,%edx
f0101709:	89 d9                	mov    %ebx,%ecx
f010170b:	d3 e8                	shr    %cl,%eax
f010170d:	09 c2                	or     %eax,%edx
f010170f:	89 d0                	mov    %edx,%eax
f0101711:	89 ea                	mov    %ebp,%edx
f0101713:	f7 f6                	div    %esi
f0101715:	89 d5                	mov    %edx,%ebp
f0101717:	89 c3                	mov    %eax,%ebx
f0101719:	f7 64 24 0c          	mull   0xc(%esp)
f010171d:	39 d5                	cmp    %edx,%ebp
f010171f:	72 10                	jb     f0101731 <__udivdi3+0xc1>
f0101721:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101725:	89 f9                	mov    %edi,%ecx
f0101727:	d3 e6                	shl    %cl,%esi
f0101729:	39 c6                	cmp    %eax,%esi
f010172b:	73 07                	jae    f0101734 <__udivdi3+0xc4>
f010172d:	39 d5                	cmp    %edx,%ebp
f010172f:	75 03                	jne    f0101734 <__udivdi3+0xc4>
f0101731:	83 eb 01             	sub    $0x1,%ebx
f0101734:	31 ff                	xor    %edi,%edi
f0101736:	89 d8                	mov    %ebx,%eax
f0101738:	89 fa                	mov    %edi,%edx
f010173a:	83 c4 1c             	add    $0x1c,%esp
f010173d:	5b                   	pop    %ebx
f010173e:	5e                   	pop    %esi
f010173f:	5f                   	pop    %edi
f0101740:	5d                   	pop    %ebp
f0101741:	c3                   	ret    
f0101742:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101748:	31 ff                	xor    %edi,%edi
f010174a:	31 db                	xor    %ebx,%ebx
f010174c:	89 d8                	mov    %ebx,%eax
f010174e:	89 fa                	mov    %edi,%edx
f0101750:	83 c4 1c             	add    $0x1c,%esp
f0101753:	5b                   	pop    %ebx
f0101754:	5e                   	pop    %esi
f0101755:	5f                   	pop    %edi
f0101756:	5d                   	pop    %ebp
f0101757:	c3                   	ret    
f0101758:	90                   	nop
f0101759:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101760:	89 d8                	mov    %ebx,%eax
f0101762:	f7 f7                	div    %edi
f0101764:	31 ff                	xor    %edi,%edi
f0101766:	89 c3                	mov    %eax,%ebx
f0101768:	89 d8                	mov    %ebx,%eax
f010176a:	89 fa                	mov    %edi,%edx
f010176c:	83 c4 1c             	add    $0x1c,%esp
f010176f:	5b                   	pop    %ebx
f0101770:	5e                   	pop    %esi
f0101771:	5f                   	pop    %edi
f0101772:	5d                   	pop    %ebp
f0101773:	c3                   	ret    
f0101774:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101778:	39 ce                	cmp    %ecx,%esi
f010177a:	72 0c                	jb     f0101788 <__udivdi3+0x118>
f010177c:	31 db                	xor    %ebx,%ebx
f010177e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101782:	0f 87 34 ff ff ff    	ja     f01016bc <__udivdi3+0x4c>
f0101788:	bb 01 00 00 00       	mov    $0x1,%ebx
f010178d:	e9 2a ff ff ff       	jmp    f01016bc <__udivdi3+0x4c>
f0101792:	66 90                	xchg   %ax,%ax
f0101794:	66 90                	xchg   %ax,%ax
f0101796:	66 90                	xchg   %ax,%ax
f0101798:	66 90                	xchg   %ax,%ax
f010179a:	66 90                	xchg   %ax,%ax
f010179c:	66 90                	xchg   %ax,%ax
f010179e:	66 90                	xchg   %ax,%ax

f01017a0 <__umoddi3>:
f01017a0:	55                   	push   %ebp
f01017a1:	57                   	push   %edi
f01017a2:	56                   	push   %esi
f01017a3:	53                   	push   %ebx
f01017a4:	83 ec 1c             	sub    $0x1c,%esp
f01017a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017ab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017b7:	85 d2                	test   %edx,%edx
f01017b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017c1:	89 f3                	mov    %esi,%ebx
f01017c3:	89 3c 24             	mov    %edi,(%esp)
f01017c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017ca:	75 1c                	jne    f01017e8 <__umoddi3+0x48>
f01017cc:	39 f7                	cmp    %esi,%edi
f01017ce:	76 50                	jbe    f0101820 <__umoddi3+0x80>
f01017d0:	89 c8                	mov    %ecx,%eax
f01017d2:	89 f2                	mov    %esi,%edx
f01017d4:	f7 f7                	div    %edi
f01017d6:	89 d0                	mov    %edx,%eax
f01017d8:	31 d2                	xor    %edx,%edx
f01017da:	83 c4 1c             	add    $0x1c,%esp
f01017dd:	5b                   	pop    %ebx
f01017de:	5e                   	pop    %esi
f01017df:	5f                   	pop    %edi
f01017e0:	5d                   	pop    %ebp
f01017e1:	c3                   	ret    
f01017e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017e8:	39 f2                	cmp    %esi,%edx
f01017ea:	89 d0                	mov    %edx,%eax
f01017ec:	77 52                	ja     f0101840 <__umoddi3+0xa0>
f01017ee:	0f bd ea             	bsr    %edx,%ebp
f01017f1:	83 f5 1f             	xor    $0x1f,%ebp
f01017f4:	75 5a                	jne    f0101850 <__umoddi3+0xb0>
f01017f6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017fa:	0f 82 e0 00 00 00    	jb     f01018e0 <__umoddi3+0x140>
f0101800:	39 0c 24             	cmp    %ecx,(%esp)
f0101803:	0f 86 d7 00 00 00    	jbe    f01018e0 <__umoddi3+0x140>
f0101809:	8b 44 24 08          	mov    0x8(%esp),%eax
f010180d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101811:	83 c4 1c             	add    $0x1c,%esp
f0101814:	5b                   	pop    %ebx
f0101815:	5e                   	pop    %esi
f0101816:	5f                   	pop    %edi
f0101817:	5d                   	pop    %ebp
f0101818:	c3                   	ret    
f0101819:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101820:	85 ff                	test   %edi,%edi
f0101822:	89 fd                	mov    %edi,%ebp
f0101824:	75 0b                	jne    f0101831 <__umoddi3+0x91>
f0101826:	b8 01 00 00 00       	mov    $0x1,%eax
f010182b:	31 d2                	xor    %edx,%edx
f010182d:	f7 f7                	div    %edi
f010182f:	89 c5                	mov    %eax,%ebp
f0101831:	89 f0                	mov    %esi,%eax
f0101833:	31 d2                	xor    %edx,%edx
f0101835:	f7 f5                	div    %ebp
f0101837:	89 c8                	mov    %ecx,%eax
f0101839:	f7 f5                	div    %ebp
f010183b:	89 d0                	mov    %edx,%eax
f010183d:	eb 99                	jmp    f01017d8 <__umoddi3+0x38>
f010183f:	90                   	nop
f0101840:	89 c8                	mov    %ecx,%eax
f0101842:	89 f2                	mov    %esi,%edx
f0101844:	83 c4 1c             	add    $0x1c,%esp
f0101847:	5b                   	pop    %ebx
f0101848:	5e                   	pop    %esi
f0101849:	5f                   	pop    %edi
f010184a:	5d                   	pop    %ebp
f010184b:	c3                   	ret    
f010184c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101850:	8b 34 24             	mov    (%esp),%esi
f0101853:	bf 20 00 00 00       	mov    $0x20,%edi
f0101858:	89 e9                	mov    %ebp,%ecx
f010185a:	29 ef                	sub    %ebp,%edi
f010185c:	d3 e0                	shl    %cl,%eax
f010185e:	89 f9                	mov    %edi,%ecx
f0101860:	89 f2                	mov    %esi,%edx
f0101862:	d3 ea                	shr    %cl,%edx
f0101864:	89 e9                	mov    %ebp,%ecx
f0101866:	09 c2                	or     %eax,%edx
f0101868:	89 d8                	mov    %ebx,%eax
f010186a:	89 14 24             	mov    %edx,(%esp)
f010186d:	89 f2                	mov    %esi,%edx
f010186f:	d3 e2                	shl    %cl,%edx
f0101871:	89 f9                	mov    %edi,%ecx
f0101873:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101877:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010187b:	d3 e8                	shr    %cl,%eax
f010187d:	89 e9                	mov    %ebp,%ecx
f010187f:	89 c6                	mov    %eax,%esi
f0101881:	d3 e3                	shl    %cl,%ebx
f0101883:	89 f9                	mov    %edi,%ecx
f0101885:	89 d0                	mov    %edx,%eax
f0101887:	d3 e8                	shr    %cl,%eax
f0101889:	89 e9                	mov    %ebp,%ecx
f010188b:	09 d8                	or     %ebx,%eax
f010188d:	89 d3                	mov    %edx,%ebx
f010188f:	89 f2                	mov    %esi,%edx
f0101891:	f7 34 24             	divl   (%esp)
f0101894:	89 d6                	mov    %edx,%esi
f0101896:	d3 e3                	shl    %cl,%ebx
f0101898:	f7 64 24 04          	mull   0x4(%esp)
f010189c:	39 d6                	cmp    %edx,%esi
f010189e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018a2:	89 d1                	mov    %edx,%ecx
f01018a4:	89 c3                	mov    %eax,%ebx
f01018a6:	72 08                	jb     f01018b0 <__umoddi3+0x110>
f01018a8:	75 11                	jne    f01018bb <__umoddi3+0x11b>
f01018aa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018ae:	73 0b                	jae    f01018bb <__umoddi3+0x11b>
f01018b0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018b4:	1b 14 24             	sbb    (%esp),%edx
f01018b7:	89 d1                	mov    %edx,%ecx
f01018b9:	89 c3                	mov    %eax,%ebx
f01018bb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018bf:	29 da                	sub    %ebx,%edx
f01018c1:	19 ce                	sbb    %ecx,%esi
f01018c3:	89 f9                	mov    %edi,%ecx
f01018c5:	89 f0                	mov    %esi,%eax
f01018c7:	d3 e0                	shl    %cl,%eax
f01018c9:	89 e9                	mov    %ebp,%ecx
f01018cb:	d3 ea                	shr    %cl,%edx
f01018cd:	89 e9                	mov    %ebp,%ecx
f01018cf:	d3 ee                	shr    %cl,%esi
f01018d1:	09 d0                	or     %edx,%eax
f01018d3:	89 f2                	mov    %esi,%edx
f01018d5:	83 c4 1c             	add    $0x1c,%esp
f01018d8:	5b                   	pop    %ebx
f01018d9:	5e                   	pop    %esi
f01018da:	5f                   	pop    %edi
f01018db:	5d                   	pop    %ebp
f01018dc:	c3                   	ret    
f01018dd:	8d 76 00             	lea    0x0(%esi),%esi
f01018e0:	29 f9                	sub    %edi,%ecx
f01018e2:	19 d6                	sbb    %edx,%esi
f01018e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018ec:	e9 18 ff ff ff       	jmp    f0101809 <__umoddi3+0x69>
