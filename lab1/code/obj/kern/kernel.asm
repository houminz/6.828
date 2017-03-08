
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
f010004b:	68 40 19 10 f0       	push   $0xf0101940
f0100050:	e8 54 09 00 00       	call   f01009a9 <cprintf>
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
f0100076:	e8 e8 06 00 00       	call   f0100763 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 5c 19 10 f0       	push   $0xf010195c
f0100087:	e8 1d 09 00 00       	call   f01009a9 <cprintf>
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
f010009a:	b8 48 29 11 f0       	mov    $0xf0112948,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 e7 13 00 00       	call   f0101498 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 7b 04 00 00       	call   f0100531 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 77 19 10 f0       	push   $0xf0101977
f01000c3:	e8 e1 08 00 00       	call   f01009a9 <cprintf>

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
f01000dc:	e8 30 07 00 00       	call   f0100811 <monitor>
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
f010010b:	68 92 19 10 f0       	push   $0xf0101992
f0100110:	e8 94 08 00 00       	call   f01009a9 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 64 08 00 00       	call   f0100983 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f0100126:	e8 7e 08 00 00       	call   f01009a9 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 d9 06 00 00       	call   f0100811 <monitor>
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
f010014d:	68 aa 19 10 f0       	push   $0xf01019aa
f0100152:	e8 52 08 00 00       	call   f01009a9 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 20 08 00 00       	call   f0100983 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f010016a:	e8 3a 08 00 00       	call   f01009a9 <cprintf>
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
f0100221:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
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
f010025d:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d 00 1a 10 f0 	mov    -0xfefe600(,%ecx,4),%ecx
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
f01002bb:	68 c4 19 10 f0       	push   $0xf01019c4
f01002c0:	e8 e4 06 00 00       	call   f01009a9 <cprintf>
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
f01002ea:	83 ec 0c             	sub    $0xc,%esp
f01002ed:	89 c6                	mov    %eax,%esi
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
f01002f4:	bf fd 03 00 00       	mov    $0x3fd,%edi
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
f0100309:	89 fa                	mov    %edi,%edx
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
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100318:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010031d:	89 f0                	mov    %esi,%eax
f010031f:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100320:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100325:	bf 79 03 00 00       	mov    $0x379,%edi
f010032a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010032f:	eb 09                	jmp    f010033a <cons_putc+0x56>
f0100331:	89 ca                	mov    %ecx,%edx
f0100333:	ec                   	in     (%dx),%al
f0100334:	ec                   	in     (%dx),%al
f0100335:	ec                   	in     (%dx),%al
f0100336:	ec                   	in     (%dx),%al
f0100337:	83 c3 01             	add    $0x1,%ebx
f010033a:	89 fa                	mov    %edi,%edx
f010033c:	ec                   	in     (%dx),%al
f010033d:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100343:	7f 04                	jg     f0100349 <cons_putc+0x65>
f0100345:	84 c0                	test   %al,%al
f0100347:	79 e8                	jns    f0100331 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100349:	ba 78 03 00 00       	mov    $0x378,%edx
f010034e:	89 f0                	mov    %esi,%eax
f0100350:	ee                   	out    %al,(%dx)
f0100351:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100356:	b8 0d 00 00 00       	mov    $0xd,%eax
f010035b:	ee                   	out    %al,(%dx)
f010035c:	b8 08 00 00 00       	mov    $0x8,%eax
f0100361:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c |= textcolor;
f0100362:	0b 35 44 29 11 f0    	or     0xf0112944,%esi
f0100368:	89 f2                	mov    %esi,%edx

//	if (!(c & ~0xFF))
//		c |= 0x0700;

	switch (c & 0xff) {
f010036a:	0f b6 c2             	movzbl %dl,%eax
f010036d:	83 f8 09             	cmp    $0x9,%eax
f0100370:	74 71                	je     f01003e3 <cons_putc+0xff>
f0100372:	83 f8 09             	cmp    $0x9,%eax
f0100375:	7f 0a                	jg     f0100381 <cons_putc+0x9d>
f0100377:	83 f8 08             	cmp    $0x8,%eax
f010037a:	74 14                	je     f0100390 <cons_putc+0xac>
f010037c:	e9 96 00 00 00       	jmp    f0100417 <cons_putc+0x133>
f0100381:	83 f8 0a             	cmp    $0xa,%eax
f0100384:	74 37                	je     f01003bd <cons_putc+0xd9>
f0100386:	83 f8 0d             	cmp    $0xd,%eax
f0100389:	74 3a                	je     f01003c5 <cons_putc+0xe1>
f010038b:	e9 87 00 00 00       	jmp    f0100417 <cons_putc+0x133>
	case '\b':
		if (crt_pos > 0) {
f0100390:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100397:	66 85 c0             	test   %ax,%ax
f010039a:	0f 84 e3 00 00 00    	je     f0100483 <cons_putc+0x19f>
			crt_pos--;
f01003a0:	83 e8 01             	sub    $0x1,%eax
f01003a3:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a9:	0f b7 c0             	movzwl %ax,%eax
f01003ac:	b2 00                	mov    $0x0,%dl
f01003ae:	83 ca 20             	or     $0x20,%edx
f01003b1:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003b7:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01003bb:	eb 78                	jmp    f0100435 <cons_putc+0x151>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003bd:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003c4:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003c5:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003cc:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003d2:	c1 e8 16             	shr    $0x16,%eax
f01003d5:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003d8:	c1 e0 04             	shl    $0x4,%eax
f01003db:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003e1:	eb 52                	jmp    f0100435 <cons_putc+0x151>
		break;
	case '\t':
		cons_putc(' ');
f01003e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e8:	e8 f7 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f01003ed:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f2:	e8 ed fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
f0100415:	eb 1e                	jmp    f0100435 <cons_putc+0x151>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100417:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010041e:	8d 48 01             	lea    0x1(%eax),%ecx
f0100421:	66 89 0d 28 25 11 f0 	mov    %cx,0xf0112528
f0100428:	0f b7 c0             	movzwl %ax,%eax
f010042b:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f0100431:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100435:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010043c:	cf 07 
f010043e:	76 43                	jbe    f0100483 <cons_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100440:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100445:	83 ec 04             	sub    $0x4,%esp
f0100448:	68 00 0f 00 00       	push   $0xf00
f010044d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100453:	52                   	push   %edx
f0100454:	50                   	push   %eax
f0100455:	e8 8b 10 00 00       	call   f01014e5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100466:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010046c:	83 c4 10             	add    $0x10,%esp
f010046f:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100474:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100477:	39 d0                	cmp    %edx,%eax
f0100479:	75 f4                	jne    f010046f <cons_putc+0x18b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010047b:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100482:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100483:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f0100489:	b8 0e 00 00 00       	mov    $0xe,%eax
f010048e:	89 ca                	mov    %ecx,%edx
f0100490:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100491:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f0100498:	8d 71 01             	lea    0x1(%ecx),%esi
f010049b:	89 d8                	mov    %ebx,%eax
f010049d:	66 c1 e8 08          	shr    $0x8,%ax
f01004a1:	89 f2                	mov    %esi,%edx
f01004a3:	ee                   	out    %al,(%dx)
f01004a4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004a9:	89 ca                	mov    %ecx,%edx
f01004ab:	ee                   	out    %al,(%dx)
f01004ac:	89 d8                	mov    %ebx,%eax
f01004ae:	89 f2                	mov    %esi,%edx
f01004b0:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004b4:	5b                   	pop    %ebx
f01004b5:	5e                   	pop    %esi
f01004b6:	5f                   	pop    %edi
f01004b7:	5d                   	pop    %ebp
f01004b8:	c3                   	ret    

f01004b9 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004b9:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004c0:	74 11                	je     f01004d3 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004c2:	55                   	push   %ebp
f01004c3:	89 e5                	mov    %esp,%ebp
f01004c5:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004c8:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004cd:	e8 c4 fc ff ff       	call   f0100196 <cons_intr>
}
f01004d2:	c9                   	leave  
f01004d3:	f3 c3                	repz ret 

f01004d5 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004d5:	55                   	push   %ebp
f01004d6:	89 e5                	mov    %esp,%ebp
f01004d8:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004db:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004e0:	e8 b1 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e5:	c9                   	leave  
f01004e6:	c3                   	ret    

f01004e7 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e7:	55                   	push   %ebp
f01004e8:	89 e5                	mov    %esp,%ebp
f01004ea:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004ed:	e8 c7 ff ff ff       	call   f01004b9 <serial_intr>
	kbd_intr();
f01004f2:	e8 de ff ff ff       	call   f01004d5 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f7:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f01004fc:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100502:	74 26                	je     f010052a <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100504:	8d 50 01             	lea    0x1(%eax),%edx
f0100507:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010050d:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100514:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100516:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010051c:	75 11                	jne    f010052f <cons_getc+0x48>
			cons.rpos = 0;
f010051e:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100525:	00 00 00 
f0100528:	eb 05                	jmp    f010052f <cons_getc+0x48>
		return c;
	}
	return 0;
f010052a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010052f:	c9                   	leave  
f0100530:	c3                   	ret    

f0100531 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100531:	55                   	push   %ebp
f0100532:	89 e5                	mov    %esp,%ebp
f0100534:	57                   	push   %edi
f0100535:	56                   	push   %esi
f0100536:	53                   	push   %ebx
f0100537:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010053a:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100541:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100548:	5a a5 
	if (*cp != 0xA55A) {
f010054a:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100551:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100555:	74 11                	je     f0100568 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100557:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010055e:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100561:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100566:	eb 16                	jmp    f010057e <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100568:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010056f:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100576:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100579:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010057e:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100584:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100589:	89 fa                	mov    %edi,%edx
f010058b:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010058c:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ec                   	in     (%dx),%al
f0100592:	0f b6 c8             	movzbl %al,%ecx
f0100595:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100598:	b8 0f 00 00 00       	mov    $0xf,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a0:	89 da                	mov    %ebx,%edx
f01005a2:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005a3:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005a9:	0f b6 c0             	movzbl %al,%eax
f01005ac:	09 c8                	or     %ecx,%eax
f01005ae:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b4:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01005be:	89 f2                	mov    %esi,%edx
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c6:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005cb:	ee                   	out    %al,(%dx)
f01005cc:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005d1:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005d6:	89 da                	mov    %ebx,%edx
f01005d8:	ee                   	out    %al,(%dx)
f01005d9:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005de:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e3:	ee                   	out    %al,(%dx)
f01005e4:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e9:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ee:	ee                   	out    %al,(%dx)
f01005ef:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f9:	ee                   	out    %al,(%dx)
f01005fa:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ff:	b8 01 00 00 00       	mov    $0x1,%eax
f0100604:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100605:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010060a:	ec                   	in     (%dx),%al
f010060b:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010060d:	3c ff                	cmp    $0xff,%al
f010060f:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100616:	89 f2                	mov    %esi,%edx
f0100618:	ec                   	in     (%dx),%al
f0100619:	89 da                	mov    %ebx,%edx
f010061b:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010061c:	80 f9 ff             	cmp    $0xff,%cl
f010061f:	75 10                	jne    f0100631 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100621:	83 ec 0c             	sub    $0xc,%esp
f0100624:	68 d0 19 10 f0       	push   $0xf01019d0
f0100629:	e8 7b 03 00 00       	call   f01009a9 <cprintf>
f010062e:	83 c4 10             	add    $0x10,%esp
}
f0100631:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100634:	5b                   	pop    %ebx
f0100635:	5e                   	pop    %esi
f0100636:	5f                   	pop    %edi
f0100637:	5d                   	pop    %ebp
f0100638:	c3                   	ret    

f0100639 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100639:	55                   	push   %ebp
f010063a:	89 e5                	mov    %esp,%ebp
f010063c:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010063f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100642:	e8 9d fc ff ff       	call   f01002e4 <cons_putc>
}
f0100647:	c9                   	leave  
f0100648:	c3                   	ret    

f0100649 <getchar>:

int
getchar(void)
{
f0100649:	55                   	push   %ebp
f010064a:	89 e5                	mov    %esp,%ebp
f010064c:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010064f:	e8 93 fe ff ff       	call   f01004e7 <cons_getc>
f0100654:	85 c0                	test   %eax,%eax
f0100656:	74 f7                	je     f010064f <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100658:	c9                   	leave  
f0100659:	c3                   	ret    

f010065a <iscons>:

int
iscons(int fdnum)
{
f010065a:	55                   	push   %ebp
f010065b:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100662:	5d                   	pop    %ebp
f0100663:	c3                   	ret    

f0100664 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100664:	55                   	push   %ebp
f0100665:	89 e5                	mov    %esp,%ebp
f0100667:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010066a:	68 20 1c 10 f0       	push   $0xf0101c20
f010066f:	68 3e 1c 10 f0       	push   $0xf0101c3e
f0100674:	68 43 1c 10 f0       	push   $0xf0101c43
f0100679:	e8 2b 03 00 00       	call   f01009a9 <cprintf>
f010067e:	83 c4 0c             	add    $0xc,%esp
f0100681:	68 14 1d 10 f0       	push   $0xf0101d14
f0100686:	68 4c 1c 10 f0       	push   $0xf0101c4c
f010068b:	68 43 1c 10 f0       	push   $0xf0101c43
f0100690:	e8 14 03 00 00       	call   f01009a9 <cprintf>
f0100695:	83 c4 0c             	add    $0xc,%esp
f0100698:	68 3c 1d 10 f0       	push   $0xf0101d3c
f010069d:	68 55 1c 10 f0       	push   $0xf0101c55
f01006a2:	68 43 1c 10 f0       	push   $0xf0101c43
f01006a7:	e8 fd 02 00 00       	call   f01009a9 <cprintf>
	return 0;
}
f01006ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01006b1:	c9                   	leave  
f01006b2:	c3                   	ret    

f01006b3 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b3:	55                   	push   %ebp
f01006b4:	89 e5                	mov    %esp,%ebp
f01006b6:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b9:	68 5f 1c 10 f0       	push   $0xf0101c5f
f01006be:	e8 e6 02 00 00       	call   f01009a9 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c3:	83 c4 08             	add    $0x8,%esp
f01006c6:	68 0c 00 10 00       	push   $0x10000c
f01006cb:	68 a4 1d 10 f0       	push   $0xf0101da4
f01006d0:	e8 d4 02 00 00       	call   f01009a9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d5:	83 c4 0c             	add    $0xc,%esp
f01006d8:	68 0c 00 10 00       	push   $0x10000c
f01006dd:	68 0c 00 10 f0       	push   $0xf010000c
f01006e2:	68 cc 1d 10 f0       	push   $0xf0101dcc
f01006e7:	e8 bd 02 00 00       	call   f01009a9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ec:	83 c4 0c             	add    $0xc,%esp
f01006ef:	68 21 19 10 00       	push   $0x101921
f01006f4:	68 21 19 10 f0       	push   $0xf0101921
f01006f9:	68 f0 1d 10 f0       	push   $0xf0101df0
f01006fe:	e8 a6 02 00 00       	call   f01009a9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100703:	83 c4 0c             	add    $0xc,%esp
f0100706:	68 00 23 11 00       	push   $0x112300
f010070b:	68 00 23 11 f0       	push   $0xf0112300
f0100710:	68 14 1e 10 f0       	push   $0xf0101e14
f0100715:	e8 8f 02 00 00       	call   f01009a9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010071a:	83 c4 0c             	add    $0xc,%esp
f010071d:	68 48 29 11 00       	push   $0x112948
f0100722:	68 48 29 11 f0       	push   $0xf0112948
f0100727:	68 38 1e 10 f0       	push   $0xf0101e38
f010072c:	e8 78 02 00 00       	call   f01009a9 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100731:	b8 47 2d 11 f0       	mov    $0xf0112d47,%eax
f0100736:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010073b:	83 c4 08             	add    $0x8,%esp
f010073e:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100743:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100749:	85 c0                	test   %eax,%eax
f010074b:	0f 48 c2             	cmovs  %edx,%eax
f010074e:	c1 f8 0a             	sar    $0xa,%eax
f0100751:	50                   	push   %eax
f0100752:	68 5c 1e 10 f0       	push   $0xf0101e5c
f0100757:	e8 4d 02 00 00       	call   f01009a9 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010075c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100761:	c9                   	leave  
f0100762:	c3                   	ret    

f0100763 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100763:	55                   	push   %ebp
f0100764:	89 e5                	mov    %esp,%ebp
f0100766:	57                   	push   %edi
f0100767:	56                   	push   %esi
f0100768:	53                   	push   %ebx
f0100769:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010076c:	89 ee                	mov    %ebp,%esi
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");
f010076e:	68 78 1c 10 f0       	push   $0xf0101c78
f0100773:	e8 31 02 00 00       	call   f01009a9 <cprintf>

	while(ebp) {
f0100778:	83 c4 10             	add    $0x10,%esp
f010077b:	eb 7f                	jmp    f01007fc <mon_backtrace+0x99>
		cprintf("ebp %08x ", ebp);
f010077d:	83 ec 08             	sub    $0x8,%esp
f0100780:	56                   	push   %esi
f0100781:	68 8a 1c 10 f0       	push   $0xf0101c8a
f0100786:	e8 1e 02 00 00       	call   f01009a9 <cprintf>
		cprintf("eip %08x args", ebp[1]);
f010078b:	83 c4 08             	add    $0x8,%esp
f010078e:	ff 76 04             	pushl  0x4(%esi)
f0100791:	68 94 1c 10 f0       	push   $0xf0101c94
f0100796:	e8 0e 02 00 00       	call   f01009a9 <cprintf>
f010079b:	8d 5e 08             	lea    0x8(%esi),%ebx
f010079e:	8d 7e 1c             	lea    0x1c(%esi),%edi
f01007a1:	83 c4 10             	add    $0x10,%esp
		for(int i = 2; i <= 6; i++)
			cprintf(" %08x", ebp[i]);
f01007a4:	83 ec 08             	sub    $0x8,%esp
f01007a7:	ff 33                	pushl  (%ebx)
f01007a9:	68 a2 1c 10 f0       	push   $0xf0101ca2
f01007ae:	e8 f6 01 00 00       	call   f01009a9 <cprintf>
f01007b3:	83 c3 04             	add    $0x4,%ebx
	cprintf("Stack backtrace:\n");

	while(ebp) {
		cprintf("ebp %08x ", ebp);
		cprintf("eip %08x args", ebp[1]);
		for(int i = 2; i <= 6; i++)
f01007b6:	83 c4 10             	add    $0x10,%esp
f01007b9:	39 fb                	cmp    %edi,%ebx
f01007bb:	75 e7                	jne    f01007a4 <mon_backtrace+0x41>
			cprintf(" %08x", ebp[i]);
		cprintf("\n");
f01007bd:	83 ec 0c             	sub    $0xc,%esp
f01007c0:	68 ce 19 10 f0       	push   $0xf01019ce
f01007c5:	e8 df 01 00 00       	call   f01009a9 <cprintf>

		unsigned int eip = ebp[1];
f01007ca:	8b 5e 04             	mov    0x4(%esi),%ebx
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01007cd:	83 c4 08             	add    $0x8,%esp
f01007d0:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007d3:	50                   	push   %eax
f01007d4:	53                   	push   %ebx
f01007d5:	e8 d9 02 00 00       	call   f0100ab3 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f01007da:	83 c4 08             	add    $0x8,%esp
f01007dd:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f01007e0:	53                   	push   %ebx
f01007e1:	ff 75 d8             	pushl  -0x28(%ebp)
f01007e4:	ff 75 dc             	pushl  -0x24(%ebp)
f01007e7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007ea:	ff 75 d0             	pushl  -0x30(%ebp)
f01007ed:	68 a8 1c 10 f0       	push   $0xf0101ca8
f01007f2:	e8 b2 01 00 00       	call   f01009a9 <cprintf>
		info.eip_file, info.eip_line,
		info.eip_fn_namelen, info.eip_fn_name,
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
f01007f7:	8b 36                	mov    (%esi),%esi
f01007f9:	83 c4 20             	add    $0x20,%esp
{
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");

	while(ebp) {
f01007fc:	85 f6                	test   %esi,%esi
f01007fe:	0f 85 79 ff ff ff    	jne    f010077d <mon_backtrace+0x1a>
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
	}
	return 0;
}
f0100804:	b8 00 00 00 00       	mov    $0x0,%eax
f0100809:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010080c:	5b                   	pop    %ebx
f010080d:	5e                   	pop    %esi
f010080e:	5f                   	pop    %edi
f010080f:	5d                   	pop    %ebp
f0100810:	c3                   	ret    

f0100811 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100811:	55                   	push   %ebp
f0100812:	89 e5                	mov    %esp,%ebp
f0100814:	57                   	push   %edi
f0100815:	56                   	push   %esi
f0100816:	53                   	push   %ebx
f0100817:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010081a:	68 88 1e 10 f0       	push   $0xf0101e88
f010081f:	e8 85 01 00 00       	call   f01009a9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100824:	c7 04 24 ac 1e 10 f0 	movl   $0xf0101eac,(%esp)
f010082b:	e8 79 01 00 00       	call   f01009a9 <cprintf>
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");
f0100830:	83 c4 0c             	add    $0xc,%esp
f0100833:	68 b9 1c 10 f0       	push   $0xf0101cb9
f0100838:	68 00 04 00 00       	push   $0x400
f010083d:	68 bd 1c 10 f0       	push   $0xf0101cbd
f0100842:	68 00 02 00 00       	push   $0x200
f0100847:	68 c3 1c 10 f0       	push   $0xf0101cc3
f010084c:	68 00 01 00 00       	push   $0x100
f0100851:	68 c8 1c 10 f0       	push   $0xf0101cc8
f0100856:	e8 4e 01 00 00       	call   f01009a9 <cprintf>
f010085b:	83 c4 20             	add    $0x20,%esp

	while (1) {
		buf = readline("K> ");
f010085e:	83 ec 0c             	sub    $0xc,%esp
f0100861:	68 d8 1c 10 f0       	push   $0xf0101cd8
f0100866:	e8 d6 09 00 00       	call   f0101241 <readline>
f010086b:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010086d:	83 c4 10             	add    $0x10,%esp
f0100870:	85 c0                	test   %eax,%eax
f0100872:	74 ea                	je     f010085e <monitor+0x4d>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100874:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010087b:	be 00 00 00 00       	mov    $0x0,%esi
f0100880:	eb 0a                	jmp    f010088c <monitor+0x7b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100882:	c6 03 00             	movb   $0x0,(%ebx)
f0100885:	89 f7                	mov    %esi,%edi
f0100887:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010088a:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010088c:	0f b6 03             	movzbl (%ebx),%eax
f010088f:	84 c0                	test   %al,%al
f0100891:	74 63                	je     f01008f6 <monitor+0xe5>
f0100893:	83 ec 08             	sub    $0x8,%esp
f0100896:	0f be c0             	movsbl %al,%eax
f0100899:	50                   	push   %eax
f010089a:	68 dc 1c 10 f0       	push   $0xf0101cdc
f010089f:	e8 b7 0b 00 00       	call   f010145b <strchr>
f01008a4:	83 c4 10             	add    $0x10,%esp
f01008a7:	85 c0                	test   %eax,%eax
f01008a9:	75 d7                	jne    f0100882 <monitor+0x71>
			*buf++ = 0;
		if (*buf == 0)
f01008ab:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008ae:	74 46                	je     f01008f6 <monitor+0xe5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008b0:	83 fe 0f             	cmp    $0xf,%esi
f01008b3:	75 14                	jne    f01008c9 <monitor+0xb8>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008b5:	83 ec 08             	sub    $0x8,%esp
f01008b8:	6a 10                	push   $0x10
f01008ba:	68 e1 1c 10 f0       	push   $0xf0101ce1
f01008bf:	e8 e5 00 00 00       	call   f01009a9 <cprintf>
f01008c4:	83 c4 10             	add    $0x10,%esp
f01008c7:	eb 95                	jmp    f010085e <monitor+0x4d>
			return 0;
		}
		argv[argc++] = buf;
f01008c9:	8d 7e 01             	lea    0x1(%esi),%edi
f01008cc:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008d0:	eb 03                	jmp    f01008d5 <monitor+0xc4>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008d2:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d5:	0f b6 03             	movzbl (%ebx),%eax
f01008d8:	84 c0                	test   %al,%al
f01008da:	74 ae                	je     f010088a <monitor+0x79>
f01008dc:	83 ec 08             	sub    $0x8,%esp
f01008df:	0f be c0             	movsbl %al,%eax
f01008e2:	50                   	push   %eax
f01008e3:	68 dc 1c 10 f0       	push   $0xf0101cdc
f01008e8:	e8 6e 0b 00 00       	call   f010145b <strchr>
f01008ed:	83 c4 10             	add    $0x10,%esp
f01008f0:	85 c0                	test   %eax,%eax
f01008f2:	74 de                	je     f01008d2 <monitor+0xc1>
f01008f4:	eb 94                	jmp    f010088a <monitor+0x79>
			buf++;
	}
	argv[argc] = 0;
f01008f6:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008fd:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008fe:	85 f6                	test   %esi,%esi
f0100900:	0f 84 58 ff ff ff    	je     f010085e <monitor+0x4d>
f0100906:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010090b:	83 ec 08             	sub    $0x8,%esp
f010090e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100911:	ff 34 85 e0 1e 10 f0 	pushl  -0xfefe120(,%eax,4)
f0100918:	ff 75 a8             	pushl  -0x58(%ebp)
f010091b:	e8 dd 0a 00 00       	call   f01013fd <strcmp>
f0100920:	83 c4 10             	add    $0x10,%esp
f0100923:	85 c0                	test   %eax,%eax
f0100925:	75 21                	jne    f0100948 <monitor+0x137>
			return commands[i].func(argc, argv, tf);
f0100927:	83 ec 04             	sub    $0x4,%esp
f010092a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010092d:	ff 75 08             	pushl  0x8(%ebp)
f0100930:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100933:	52                   	push   %edx
f0100934:	56                   	push   %esi
f0100935:	ff 14 85 e8 1e 10 f0 	call   *-0xfefe118(,%eax,4)
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010093c:	83 c4 10             	add    $0x10,%esp
f010093f:	85 c0                	test   %eax,%eax
f0100941:	78 25                	js     f0100968 <monitor+0x157>
f0100943:	e9 16 ff ff ff       	jmp    f010085e <monitor+0x4d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100948:	83 c3 01             	add    $0x1,%ebx
f010094b:	83 fb 03             	cmp    $0x3,%ebx
f010094e:	75 bb                	jne    f010090b <monitor+0xfa>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100950:	83 ec 08             	sub    $0x8,%esp
f0100953:	ff 75 a8             	pushl  -0x58(%ebp)
f0100956:	68 fe 1c 10 f0       	push   $0xf0101cfe
f010095b:	e8 49 00 00 00       	call   f01009a9 <cprintf>
f0100960:	83 c4 10             	add    $0x10,%esp
f0100963:	e9 f6 fe ff ff       	jmp    f010085e <monitor+0x4d>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100968:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010096b:	5b                   	pop    %ebx
f010096c:	5e                   	pop    %esi
f010096d:	5f                   	pop    %edi
f010096e:	5d                   	pop    %ebp
f010096f:	c3                   	ret    

f0100970 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100970:	55                   	push   %ebp
f0100971:	89 e5                	mov    %esp,%ebp
f0100973:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100976:	ff 75 08             	pushl  0x8(%ebp)
f0100979:	e8 bb fc ff ff       	call   f0100639 <cputchar>
	*cnt++;
}
f010097e:	83 c4 10             	add    $0x10,%esp
f0100981:	c9                   	leave  
f0100982:	c3                   	ret    

f0100983 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100989:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100990:	ff 75 0c             	pushl  0xc(%ebp)
f0100993:	ff 75 08             	pushl  0x8(%ebp)
f0100996:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100999:	50                   	push   %eax
f010099a:	68 70 09 10 f0       	push   $0xf0100970
f010099f:	e8 42 04 00 00       	call   f0100de6 <vprintfmt>
	return cnt;
}
f01009a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009a7:	c9                   	leave  
f01009a8:	c3                   	ret    

f01009a9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009a9:	55                   	push   %ebp
f01009aa:	89 e5                	mov    %esp,%ebp
f01009ac:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009af:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009b2:	50                   	push   %eax
f01009b3:	ff 75 08             	pushl  0x8(%ebp)
f01009b6:	e8 c8 ff ff ff       	call   f0100983 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009bb:	c9                   	leave  
f01009bc:	c3                   	ret    

f01009bd <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009bd:	55                   	push   %ebp
f01009be:	89 e5                	mov    %esp,%ebp
f01009c0:	57                   	push   %edi
f01009c1:	56                   	push   %esi
f01009c2:	53                   	push   %ebx
f01009c3:	83 ec 14             	sub    $0x14,%esp
f01009c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009c9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009cc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009cf:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009d2:	8b 1a                	mov    (%edx),%ebx
f01009d4:	8b 01                	mov    (%ecx),%eax
f01009d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009d9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009e0:	eb 7f                	jmp    f0100a61 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009e5:	01 d8                	add    %ebx,%eax
f01009e7:	89 c6                	mov    %eax,%esi
f01009e9:	c1 ee 1f             	shr    $0x1f,%esi
f01009ec:	01 c6                	add    %eax,%esi
f01009ee:	d1 fe                	sar    %esi
f01009f0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009f3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009f6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009f9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009fb:	eb 03                	jmp    f0100a00 <stab_binsearch+0x43>
			m--;
f01009fd:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a00:	39 c3                	cmp    %eax,%ebx
f0100a02:	7f 0d                	jg     f0100a11 <stab_binsearch+0x54>
f0100a04:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a08:	83 ea 0c             	sub    $0xc,%edx
f0100a0b:	39 f9                	cmp    %edi,%ecx
f0100a0d:	75 ee                	jne    f01009fd <stab_binsearch+0x40>
f0100a0f:	eb 05                	jmp    f0100a16 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a11:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a14:	eb 4b                	jmp    f0100a61 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a16:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a19:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a1c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a20:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a23:	76 11                	jbe    f0100a36 <stab_binsearch+0x79>
			*region_left = m;
f0100a25:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a28:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a2a:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a2d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a34:	eb 2b                	jmp    f0100a61 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a36:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a39:	73 14                	jae    f0100a4f <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a3b:	83 e8 01             	sub    $0x1,%eax
f0100a3e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a41:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a44:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a46:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a4d:	eb 12                	jmp    f0100a61 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a4f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a52:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a54:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a58:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a5a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a61:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a64:	0f 8e 78 ff ff ff    	jle    f01009e2 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a6a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a6e:	75 0f                	jne    f0100a7f <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a73:	8b 00                	mov    (%eax),%eax
f0100a75:	83 e8 01             	sub    $0x1,%eax
f0100a78:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a7b:	89 06                	mov    %eax,(%esi)
f0100a7d:	eb 2c                	jmp    f0100aab <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a82:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a84:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a87:	8b 0e                	mov    (%esi),%ecx
f0100a89:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a8c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a8f:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a92:	eb 03                	jmp    f0100a97 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a94:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a97:	39 c8                	cmp    %ecx,%eax
f0100a99:	7e 0b                	jle    f0100aa6 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a9b:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a9f:	83 ea 0c             	sub    $0xc,%edx
f0100aa2:	39 df                	cmp    %ebx,%edi
f0100aa4:	75 ee                	jne    f0100a94 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100aa6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100aa9:	89 06                	mov    %eax,(%esi)
	}
}
f0100aab:	83 c4 14             	add    $0x14,%esp
f0100aae:	5b                   	pop    %ebx
f0100aaf:	5e                   	pop    %esi
f0100ab0:	5f                   	pop    %edi
f0100ab1:	5d                   	pop    %ebp
f0100ab2:	c3                   	ret    

f0100ab3 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ab3:	55                   	push   %ebp
f0100ab4:	89 e5                	mov    %esp,%ebp
f0100ab6:	57                   	push   %edi
f0100ab7:	56                   	push   %esi
f0100ab8:	53                   	push   %ebx
f0100ab9:	83 ec 3c             	sub    $0x3c,%esp
f0100abc:	8b 75 08             	mov    0x8(%ebp),%esi
f0100abf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ac2:	c7 03 04 1f 10 f0    	movl   $0xf0101f04,(%ebx)
	info->eip_line = 0;
f0100ac8:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100acf:	c7 43 08 04 1f 10 f0 	movl   $0xf0101f04,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ad6:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100add:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ae0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ae7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100aed:	76 11                	jbe    f0100b00 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aef:	b8 da 74 10 f0       	mov    $0xf01074da,%eax
f0100af4:	3d 95 5b 10 f0       	cmp    $0xf0105b95,%eax
f0100af9:	77 19                	ja     f0100b14 <debuginfo_eip+0x61>
f0100afb:	e9 a1 01 00 00       	jmp    f0100ca1 <debuginfo_eip+0x1ee>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b00:	83 ec 04             	sub    $0x4,%esp
f0100b03:	68 0e 1f 10 f0       	push   $0xf0101f0e
f0100b08:	6a 7f                	push   $0x7f
f0100b0a:	68 1b 1f 10 f0       	push   $0xf0101f1b
f0100b0f:	e8 d2 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b14:	80 3d d9 74 10 f0 00 	cmpb   $0x0,0xf01074d9
f0100b1b:	0f 85 87 01 00 00    	jne    f0100ca8 <debuginfo_eip+0x1f5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b21:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b28:	b8 94 5b 10 f0       	mov    $0xf0105b94,%eax
f0100b2d:	2d 50 21 10 f0       	sub    $0xf0102150,%eax
f0100b32:	c1 f8 02             	sar    $0x2,%eax
f0100b35:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b3b:	83 e8 01             	sub    $0x1,%eax
f0100b3e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b41:	83 ec 08             	sub    $0x8,%esp
f0100b44:	56                   	push   %esi
f0100b45:	6a 64                	push   $0x64
f0100b47:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b4a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b4d:	b8 50 21 10 f0       	mov    $0xf0102150,%eax
f0100b52:	e8 66 fe ff ff       	call   f01009bd <stab_binsearch>
	if (lfile == 0)
f0100b57:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b5a:	83 c4 10             	add    $0x10,%esp
f0100b5d:	85 c0                	test   %eax,%eax
f0100b5f:	0f 84 4a 01 00 00    	je     f0100caf <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b65:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b68:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b6b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b6e:	83 ec 08             	sub    $0x8,%esp
f0100b71:	56                   	push   %esi
f0100b72:	6a 24                	push   $0x24
f0100b74:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b77:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b7a:	b8 50 21 10 f0       	mov    $0xf0102150,%eax
f0100b7f:	e8 39 fe ff ff       	call   f01009bd <stab_binsearch>

	if (lfun <= rfun) {
f0100b84:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b87:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b8a:	83 c4 10             	add    $0x10,%esp
f0100b8d:	39 d0                	cmp    %edx,%eax
f0100b8f:	7f 40                	jg     f0100bd1 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b91:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b94:	c1 e1 02             	shl    $0x2,%ecx
f0100b97:	8d b9 50 21 10 f0    	lea    -0xfefdeb0(%ecx),%edi
f0100b9d:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100ba0:	8b b9 50 21 10 f0    	mov    -0xfefdeb0(%ecx),%edi
f0100ba6:	b9 da 74 10 f0       	mov    $0xf01074da,%ecx
f0100bab:	81 e9 95 5b 10 f0    	sub    $0xf0105b95,%ecx
f0100bb1:	39 cf                	cmp    %ecx,%edi
f0100bb3:	73 09                	jae    f0100bbe <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bb5:	81 c7 95 5b 10 f0    	add    $0xf0105b95,%edi
f0100bbb:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bbe:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bc1:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bc4:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bc7:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bc9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bcc:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bcf:	eb 0f                	jmp    f0100be0 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bd1:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bd4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bd7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bda:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bdd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100be0:	83 ec 08             	sub    $0x8,%esp
f0100be3:	6a 3a                	push   $0x3a
f0100be5:	ff 73 08             	pushl  0x8(%ebx)
f0100be8:	e8 8f 08 00 00       	call   f010147c <strfind>
f0100bed:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bf0:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bf3:	83 c4 08             	add    $0x8,%esp
f0100bf6:	56                   	push   %esi
f0100bf7:	6a 44                	push   $0x44
f0100bf9:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bfc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bff:	b8 50 21 10 f0       	mov    $0xf0102150,%eax
f0100c04:	e8 b4 fd ff ff       	call   f01009bd <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f0100c09:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100c0c:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c0f:	8d 04 85 50 21 10 f0 	lea    -0xfefdeb0(,%eax,4),%eax
f0100c16:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0100c1a:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c1d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c20:	83 c4 10             	add    $0x10,%esp
f0100c23:	eb 06                	jmp    f0100c2b <debuginfo_eip+0x178>
f0100c25:	83 ea 01             	sub    $0x1,%edx
f0100c28:	83 e8 0c             	sub    $0xc,%eax
f0100c2b:	39 d6                	cmp    %edx,%esi
f0100c2d:	7f 34                	jg     f0100c63 <debuginfo_eip+0x1b0>
	       && stabs[lline].n_type != N_SOL
f0100c2f:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c33:	80 f9 84             	cmp    $0x84,%cl
f0100c36:	74 0b                	je     f0100c43 <debuginfo_eip+0x190>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c38:	80 f9 64             	cmp    $0x64,%cl
f0100c3b:	75 e8                	jne    f0100c25 <debuginfo_eip+0x172>
f0100c3d:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c41:	74 e2                	je     f0100c25 <debuginfo_eip+0x172>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c43:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c46:	8b 14 85 50 21 10 f0 	mov    -0xfefdeb0(,%eax,4),%edx
f0100c4d:	b8 da 74 10 f0       	mov    $0xf01074da,%eax
f0100c52:	2d 95 5b 10 f0       	sub    $0xf0105b95,%eax
f0100c57:	39 c2                	cmp    %eax,%edx
f0100c59:	73 08                	jae    f0100c63 <debuginfo_eip+0x1b0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c5b:	81 c2 95 5b 10 f0    	add    $0xf0105b95,%edx
f0100c61:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c63:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c66:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c69:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c6e:	39 f2                	cmp    %esi,%edx
f0100c70:	7d 49                	jge    f0100cbb <debuginfo_eip+0x208>
		for (lline = lfun + 1;
f0100c72:	83 c2 01             	add    $0x1,%edx
f0100c75:	89 d0                	mov    %edx,%eax
f0100c77:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c7a:	8d 14 95 50 21 10 f0 	lea    -0xfefdeb0(,%edx,4),%edx
f0100c81:	eb 04                	jmp    f0100c87 <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c83:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c87:	39 c6                	cmp    %eax,%esi
f0100c89:	7e 2b                	jle    f0100cb6 <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c8b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c8f:	83 c0 01             	add    $0x1,%eax
f0100c92:	83 c2 0c             	add    $0xc,%edx
f0100c95:	80 f9 a0             	cmp    $0xa0,%cl
f0100c98:	74 e9                	je     f0100c83 <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c9f:	eb 1a                	jmp    f0100cbb <debuginfo_eip+0x208>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ca1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca6:	eb 13                	jmp    f0100cbb <debuginfo_eip+0x208>
f0100ca8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cad:	eb 0c                	jmp    f0100cbb <debuginfo_eip+0x208>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100caf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cb4:	eb 05                	jmp    f0100cbb <debuginfo_eip+0x208>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cb6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cbb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cbe:	5b                   	pop    %ebx
f0100cbf:	5e                   	pop    %esi
f0100cc0:	5f                   	pop    %edi
f0100cc1:	5d                   	pop    %ebp
f0100cc2:	c3                   	ret    

f0100cc3 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cc3:	55                   	push   %ebp
f0100cc4:	89 e5                	mov    %esp,%ebp
f0100cc6:	57                   	push   %edi
f0100cc7:	56                   	push   %esi
f0100cc8:	53                   	push   %ebx
f0100cc9:	83 ec 1c             	sub    $0x1c,%esp
f0100ccc:	89 c7                	mov    %eax,%edi
f0100cce:	89 d6                	mov    %edx,%esi
f0100cd0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cd3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cd6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cd9:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cdc:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cdf:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ce4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ce7:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100cea:	39 d3                	cmp    %edx,%ebx
f0100cec:	72 05                	jb     f0100cf3 <printnum+0x30>
f0100cee:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cf1:	77 45                	ja     f0100d38 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cf3:	83 ec 0c             	sub    $0xc,%esp
f0100cf6:	ff 75 18             	pushl  0x18(%ebp)
f0100cf9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cfc:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cff:	53                   	push   %ebx
f0100d00:	ff 75 10             	pushl  0x10(%ebp)
f0100d03:	83 ec 08             	sub    $0x8,%esp
f0100d06:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d09:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d0c:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d0f:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d12:	e8 89 09 00 00       	call   f01016a0 <__udivdi3>
f0100d17:	83 c4 18             	add    $0x18,%esp
f0100d1a:	52                   	push   %edx
f0100d1b:	50                   	push   %eax
f0100d1c:	89 f2                	mov    %esi,%edx
f0100d1e:	89 f8                	mov    %edi,%eax
f0100d20:	e8 9e ff ff ff       	call   f0100cc3 <printnum>
f0100d25:	83 c4 20             	add    $0x20,%esp
f0100d28:	eb 18                	jmp    f0100d42 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d2a:	83 ec 08             	sub    $0x8,%esp
f0100d2d:	56                   	push   %esi
f0100d2e:	ff 75 18             	pushl  0x18(%ebp)
f0100d31:	ff d7                	call   *%edi
f0100d33:	83 c4 10             	add    $0x10,%esp
f0100d36:	eb 03                	jmp    f0100d3b <printnum+0x78>
f0100d38:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d3b:	83 eb 01             	sub    $0x1,%ebx
f0100d3e:	85 db                	test   %ebx,%ebx
f0100d40:	7f e8                	jg     f0100d2a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d42:	83 ec 08             	sub    $0x8,%esp
f0100d45:	56                   	push   %esi
f0100d46:	83 ec 04             	sub    $0x4,%esp
f0100d49:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d4c:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d4f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d52:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d55:	e8 76 0a 00 00       	call   f01017d0 <__umoddi3>
f0100d5a:	83 c4 14             	add    $0x14,%esp
f0100d5d:	0f be 80 29 1f 10 f0 	movsbl -0xfefe0d7(%eax),%eax
f0100d64:	50                   	push   %eax
f0100d65:	ff d7                	call   *%edi
}
f0100d67:	83 c4 10             	add    $0x10,%esp
f0100d6a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d6d:	5b                   	pop    %ebx
f0100d6e:	5e                   	pop    %esi
f0100d6f:	5f                   	pop    %edi
f0100d70:	5d                   	pop    %ebp
f0100d71:	c3                   	ret    

f0100d72 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d72:	55                   	push   %ebp
f0100d73:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d75:	83 fa 01             	cmp    $0x1,%edx
f0100d78:	7e 0e                	jle    f0100d88 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d7a:	8b 10                	mov    (%eax),%edx
f0100d7c:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d7f:	89 08                	mov    %ecx,(%eax)
f0100d81:	8b 02                	mov    (%edx),%eax
f0100d83:	8b 52 04             	mov    0x4(%edx),%edx
f0100d86:	eb 22                	jmp    f0100daa <getuint+0x38>
	else if (lflag)
f0100d88:	85 d2                	test   %edx,%edx
f0100d8a:	74 10                	je     f0100d9c <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d8c:	8b 10                	mov    (%eax),%edx
f0100d8e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d91:	89 08                	mov    %ecx,(%eax)
f0100d93:	8b 02                	mov    (%edx),%eax
f0100d95:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d9a:	eb 0e                	jmp    f0100daa <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d9c:	8b 10                	mov    (%eax),%edx
f0100d9e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100da1:	89 08                	mov    %ecx,(%eax)
f0100da3:	8b 02                	mov    (%edx),%eax
f0100da5:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100daa:	5d                   	pop    %ebp
f0100dab:	c3                   	ret    

f0100dac <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100dac:	55                   	push   %ebp
f0100dad:	89 e5                	mov    %esp,%ebp
f0100daf:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100db2:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100db6:	8b 10                	mov    (%eax),%edx
f0100db8:	3b 50 04             	cmp    0x4(%eax),%edx
f0100dbb:	73 0a                	jae    f0100dc7 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100dbd:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dc0:	89 08                	mov    %ecx,(%eax)
f0100dc2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dc5:	88 02                	mov    %al,(%edx)
}
f0100dc7:	5d                   	pop    %ebp
f0100dc8:	c3                   	ret    

f0100dc9 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dc9:	55                   	push   %ebp
f0100dca:	89 e5                	mov    %esp,%ebp
f0100dcc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dcf:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dd2:	50                   	push   %eax
f0100dd3:	ff 75 10             	pushl  0x10(%ebp)
f0100dd6:	ff 75 0c             	pushl  0xc(%ebp)
f0100dd9:	ff 75 08             	pushl  0x8(%ebp)
f0100ddc:	e8 05 00 00 00       	call   f0100de6 <vprintfmt>
	va_end(ap);
}
f0100de1:	83 c4 10             	add    $0x10,%esp
f0100de4:	c9                   	leave  
f0100de5:	c3                   	ret    

f0100de6 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100de6:	55                   	push   %ebp
f0100de7:	89 e5                	mov    %esp,%ebp
f0100de9:	57                   	push   %edi
f0100dea:	56                   	push   %esi
f0100deb:	53                   	push   %ebx
f0100dec:	83 ec 2c             	sub    $0x2c,%esp
f0100def:	8b 75 08             	mov    0x8(%ebp),%esi
f0100df2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100df5:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100df8:	eb 1d                	jmp    f0100e17 <vprintfmt+0x31>
	
	//textcolor = 0x0700;		//black on write

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100dfa:	85 c0                	test   %eax,%eax
f0100dfc:	75 0f                	jne    f0100e0d <vprintfmt+0x27>
			{
				textcolor = 0x0700;
f0100dfe:	c7 05 44 29 11 f0 00 	movl   $0x700,0xf0112944
f0100e05:	07 00 00 
				return;
f0100e08:	e9 c4 03 00 00       	jmp    f01011d1 <vprintfmt+0x3eb>
			}
			putch(ch, putdat);
f0100e0d:	83 ec 08             	sub    $0x8,%esp
f0100e10:	53                   	push   %ebx
f0100e11:	50                   	push   %eax
f0100e12:	ff d6                	call   *%esi
f0100e14:	83 c4 10             	add    $0x10,%esp
	char padc;
	
	//textcolor = 0x0700;		//black on write

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e17:	83 c7 01             	add    $0x1,%edi
f0100e1a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e1e:	83 f8 25             	cmp    $0x25,%eax
f0100e21:	75 d7                	jne    f0100dfa <vprintfmt+0x14>
f0100e23:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e27:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e2e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e35:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e3c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e41:	eb 07                	jmp    f0100e4a <vprintfmt+0x64>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e43:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e46:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4a:	8d 47 01             	lea    0x1(%edi),%eax
f0100e4d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e50:	0f b6 07             	movzbl (%edi),%eax
f0100e53:	0f b6 c8             	movzbl %al,%ecx
f0100e56:	83 e8 23             	sub    $0x23,%eax
f0100e59:	3c 55                	cmp    $0x55,%al
f0100e5b:	0f 87 55 03 00 00    	ja     f01011b6 <vprintfmt+0x3d0>
f0100e61:	0f b6 c0             	movzbl %al,%eax
f0100e64:	ff 24 85 c0 1f 10 f0 	jmp    *-0xfefe040(,%eax,4)
f0100e6b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e6e:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e72:	eb d6                	jmp    f0100e4a <vprintfmt+0x64>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e77:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e7c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e7f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e82:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e86:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e89:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e8c:	83 fa 09             	cmp    $0x9,%edx
f0100e8f:	77 39                	ja     f0100eca <vprintfmt+0xe4>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e91:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e94:	eb e9                	jmp    f0100e7f <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e96:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e99:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e9c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e9f:	8b 00                	mov    (%eax),%eax
f0100ea1:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ea7:	eb 27                	jmp    f0100ed0 <vprintfmt+0xea>
f0100ea9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eac:	85 c0                	test   %eax,%eax
f0100eae:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100eb3:	0f 49 c8             	cmovns %eax,%ecx
f0100eb6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ebc:	eb 8c                	jmp    f0100e4a <vprintfmt+0x64>
f0100ebe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ec1:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100ec8:	eb 80                	jmp    f0100e4a <vprintfmt+0x64>
f0100eca:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ecd:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100ed0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ed4:	0f 89 70 ff ff ff    	jns    f0100e4a <vprintfmt+0x64>
				width = precision, precision = -1;
f0100eda:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100edd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ee0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ee7:	e9 5e ff ff ff       	jmp    f0100e4a <vprintfmt+0x64>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eec:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ef2:	e9 53 ff ff ff       	jmp    f0100e4a <vprintfmt+0x64>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100ef7:	83 fa 01             	cmp    $0x1,%edx
f0100efa:	7e 0d                	jle    f0100f09 <vprintfmt+0x123>
		return va_arg(*ap, long long);
f0100efc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eff:	8d 50 08             	lea    0x8(%eax),%edx
f0100f02:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f05:	8b 00                	mov    (%eax),%eax
f0100f07:	eb 1c                	jmp    f0100f25 <vprintfmt+0x13f>
	else if (lflag)
f0100f09:	85 d2                	test   %edx,%edx
f0100f0b:	74 0d                	je     f0100f1a <vprintfmt+0x134>
		return va_arg(*ap, long);
f0100f0d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f10:	8d 50 04             	lea    0x4(%eax),%edx
f0100f13:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f16:	8b 00                	mov    (%eax),%eax
f0100f18:	eb 0b                	jmp    f0100f25 <vprintfmt+0x13f>
	else
		return va_arg(*ap, int);
f0100f1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1d:	8d 50 04             	lea    0x4(%eax),%edx
f0100f20:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f23:	8b 00                	mov    (%eax),%eax
			goto reswitch;

		// text color
		case 'm':
			num = getint(&ap, lflag);
			textcolor = num;
f0100f25:	a3 44 29 11 f0       	mov    %eax,0xf0112944
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// text color
		case 'm':
			num = getint(&ap, lflag);
			textcolor = num;
			break;
f0100f2d:	e9 e5 fe ff ff       	jmp    f0100e17 <vprintfmt+0x31>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f32:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f35:	8d 50 04             	lea    0x4(%eax),%edx
f0100f38:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f3b:	83 ec 08             	sub    $0x8,%esp
f0100f3e:	53                   	push   %ebx
f0100f3f:	ff 30                	pushl  (%eax)
f0100f41:	ff d6                	call   *%esi
			break;
f0100f43:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f49:	e9 c9 fe ff ff       	jmp    f0100e17 <vprintfmt+0x31>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f51:	8d 50 04             	lea    0x4(%eax),%edx
f0100f54:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f57:	8b 00                	mov    (%eax),%eax
f0100f59:	99                   	cltd   
f0100f5a:	31 d0                	xor    %edx,%eax
f0100f5c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f5e:	83 f8 07             	cmp    $0x7,%eax
f0100f61:	7f 0b                	jg     f0100f6e <vprintfmt+0x188>
f0100f63:	8b 14 85 20 21 10 f0 	mov    -0xfefdee0(,%eax,4),%edx
f0100f6a:	85 d2                	test   %edx,%edx
f0100f6c:	75 18                	jne    f0100f86 <vprintfmt+0x1a0>
				printfmt(putch, putdat, "error %d", err);
f0100f6e:	50                   	push   %eax
f0100f6f:	68 41 1f 10 f0       	push   $0xf0101f41
f0100f74:	53                   	push   %ebx
f0100f75:	56                   	push   %esi
f0100f76:	e8 4e fe ff ff       	call   f0100dc9 <printfmt>
f0100f7b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f81:	e9 91 fe ff ff       	jmp    f0100e17 <vprintfmt+0x31>
			else
				printfmt(putch, putdat, "%s", p);
f0100f86:	52                   	push   %edx
f0100f87:	68 4a 1f 10 f0       	push   $0xf0101f4a
f0100f8c:	53                   	push   %ebx
f0100f8d:	56                   	push   %esi
f0100f8e:	e8 36 fe ff ff       	call   f0100dc9 <printfmt>
f0100f93:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f99:	e9 79 fe ff ff       	jmp    f0100e17 <vprintfmt+0x31>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa1:	8d 50 04             	lea    0x4(%eax),%edx
f0100fa4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fa7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100fa9:	85 ff                	test   %edi,%edi
f0100fab:	b8 3a 1f 10 f0       	mov    $0xf0101f3a,%eax
f0100fb0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100fb3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fb7:	0f 8e 94 00 00 00    	jle    f0101051 <vprintfmt+0x26b>
f0100fbd:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100fc1:	0f 84 98 00 00 00    	je     f010105f <vprintfmt+0x279>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fc7:	83 ec 08             	sub    $0x8,%esp
f0100fca:	ff 75 d0             	pushl  -0x30(%ebp)
f0100fcd:	57                   	push   %edi
f0100fce:	e8 5f 03 00 00       	call   f0101332 <strnlen>
f0100fd3:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100fd6:	29 c1                	sub    %eax,%ecx
f0100fd8:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100fdb:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100fde:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100fe2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fe5:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fe8:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fea:	eb 0f                	jmp    f0100ffb <vprintfmt+0x215>
					putch(padc, putdat);
f0100fec:	83 ec 08             	sub    $0x8,%esp
f0100fef:	53                   	push   %ebx
f0100ff0:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ff3:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ff5:	83 ef 01             	sub    $0x1,%edi
f0100ff8:	83 c4 10             	add    $0x10,%esp
f0100ffb:	85 ff                	test   %edi,%edi
f0100ffd:	7f ed                	jg     f0100fec <vprintfmt+0x206>
f0100fff:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101002:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101005:	85 c9                	test   %ecx,%ecx
f0101007:	b8 00 00 00 00       	mov    $0x0,%eax
f010100c:	0f 49 c1             	cmovns %ecx,%eax
f010100f:	29 c1                	sub    %eax,%ecx
f0101011:	89 75 08             	mov    %esi,0x8(%ebp)
f0101014:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101017:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010101a:	89 cb                	mov    %ecx,%ebx
f010101c:	eb 4d                	jmp    f010106b <vprintfmt+0x285>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010101e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101022:	74 1b                	je     f010103f <vprintfmt+0x259>
f0101024:	0f be c0             	movsbl %al,%eax
f0101027:	83 e8 20             	sub    $0x20,%eax
f010102a:	83 f8 5e             	cmp    $0x5e,%eax
f010102d:	76 10                	jbe    f010103f <vprintfmt+0x259>
					putch('?', putdat);
f010102f:	83 ec 08             	sub    $0x8,%esp
f0101032:	ff 75 0c             	pushl  0xc(%ebp)
f0101035:	6a 3f                	push   $0x3f
f0101037:	ff 55 08             	call   *0x8(%ebp)
f010103a:	83 c4 10             	add    $0x10,%esp
f010103d:	eb 0d                	jmp    f010104c <vprintfmt+0x266>
				else
					putch(ch, putdat);
f010103f:	83 ec 08             	sub    $0x8,%esp
f0101042:	ff 75 0c             	pushl  0xc(%ebp)
f0101045:	52                   	push   %edx
f0101046:	ff 55 08             	call   *0x8(%ebp)
f0101049:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010104c:	83 eb 01             	sub    $0x1,%ebx
f010104f:	eb 1a                	jmp    f010106b <vprintfmt+0x285>
f0101051:	89 75 08             	mov    %esi,0x8(%ebp)
f0101054:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101057:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010105a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010105d:	eb 0c                	jmp    f010106b <vprintfmt+0x285>
f010105f:	89 75 08             	mov    %esi,0x8(%ebp)
f0101062:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101065:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101068:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010106b:	83 c7 01             	add    $0x1,%edi
f010106e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101072:	0f be d0             	movsbl %al,%edx
f0101075:	85 d2                	test   %edx,%edx
f0101077:	74 23                	je     f010109c <vprintfmt+0x2b6>
f0101079:	85 f6                	test   %esi,%esi
f010107b:	78 a1                	js     f010101e <vprintfmt+0x238>
f010107d:	83 ee 01             	sub    $0x1,%esi
f0101080:	79 9c                	jns    f010101e <vprintfmt+0x238>
f0101082:	89 df                	mov    %ebx,%edi
f0101084:	8b 75 08             	mov    0x8(%ebp),%esi
f0101087:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010108a:	eb 18                	jmp    f01010a4 <vprintfmt+0x2be>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010108c:	83 ec 08             	sub    $0x8,%esp
f010108f:	53                   	push   %ebx
f0101090:	6a 20                	push   $0x20
f0101092:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101094:	83 ef 01             	sub    $0x1,%edi
f0101097:	83 c4 10             	add    $0x10,%esp
f010109a:	eb 08                	jmp    f01010a4 <vprintfmt+0x2be>
f010109c:	89 df                	mov    %ebx,%edi
f010109e:	8b 75 08             	mov    0x8(%ebp),%esi
f01010a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010a4:	85 ff                	test   %edi,%edi
f01010a6:	7f e4                	jg     f010108c <vprintfmt+0x2a6>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010ab:	e9 67 fd ff ff       	jmp    f0100e17 <vprintfmt+0x31>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010b0:	83 fa 01             	cmp    $0x1,%edx
f01010b3:	7e 16                	jle    f01010cb <vprintfmt+0x2e5>
		return va_arg(*ap, long long);
f01010b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b8:	8d 50 08             	lea    0x8(%eax),%edx
f01010bb:	89 55 14             	mov    %edx,0x14(%ebp)
f01010be:	8b 50 04             	mov    0x4(%eax),%edx
f01010c1:	8b 00                	mov    (%eax),%eax
f01010c3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010c6:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010c9:	eb 32                	jmp    f01010fd <vprintfmt+0x317>
	else if (lflag)
f01010cb:	85 d2                	test   %edx,%edx
f01010cd:	74 18                	je     f01010e7 <vprintfmt+0x301>
		return va_arg(*ap, long);
f01010cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d2:	8d 50 04             	lea    0x4(%eax),%edx
f01010d5:	89 55 14             	mov    %edx,0x14(%ebp)
f01010d8:	8b 00                	mov    (%eax),%eax
f01010da:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010dd:	89 c1                	mov    %eax,%ecx
f01010df:	c1 f9 1f             	sar    $0x1f,%ecx
f01010e2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010e5:	eb 16                	jmp    f01010fd <vprintfmt+0x317>
	else
		return va_arg(*ap, int);
f01010e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ea:	8d 50 04             	lea    0x4(%eax),%edx
f01010ed:	89 55 14             	mov    %edx,0x14(%ebp)
f01010f0:	8b 00                	mov    (%eax),%eax
f01010f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010f5:	89 c1                	mov    %eax,%ecx
f01010f7:	c1 f9 1f             	sar    $0x1f,%ecx
f01010fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010fd:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101100:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101103:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101108:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010110c:	79 74                	jns    f0101182 <vprintfmt+0x39c>
				putch('-', putdat);
f010110e:	83 ec 08             	sub    $0x8,%esp
f0101111:	53                   	push   %ebx
f0101112:	6a 2d                	push   $0x2d
f0101114:	ff d6                	call   *%esi
				num = -(long long) num;
f0101116:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101119:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010111c:	f7 d8                	neg    %eax
f010111e:	83 d2 00             	adc    $0x0,%edx
f0101121:	f7 da                	neg    %edx
f0101123:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101126:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010112b:	eb 55                	jmp    f0101182 <vprintfmt+0x39c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010112d:	8d 45 14             	lea    0x14(%ebp),%eax
f0101130:	e8 3d fc ff ff       	call   f0100d72 <getuint>
			base = 10;
f0101135:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010113a:	eb 46                	jmp    f0101182 <vprintfmt+0x39c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010113c:	8d 45 14             	lea    0x14(%ebp),%eax
f010113f:	e8 2e fc ff ff       	call   f0100d72 <getuint>
			base = 8;
f0101144:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101149:	eb 37                	jmp    f0101182 <vprintfmt+0x39c>

		// pointer
		case 'p':
			putch('0', putdat);
f010114b:	83 ec 08             	sub    $0x8,%esp
f010114e:	53                   	push   %ebx
f010114f:	6a 30                	push   $0x30
f0101151:	ff d6                	call   *%esi
			putch('x', putdat);
f0101153:	83 c4 08             	add    $0x8,%esp
f0101156:	53                   	push   %ebx
f0101157:	6a 78                	push   $0x78
f0101159:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010115b:	8b 45 14             	mov    0x14(%ebp),%eax
f010115e:	8d 50 04             	lea    0x4(%eax),%edx
f0101161:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101164:	8b 00                	mov    (%eax),%eax
f0101166:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010116b:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010116e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101173:	eb 0d                	jmp    f0101182 <vprintfmt+0x39c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101175:	8d 45 14             	lea    0x14(%ebp),%eax
f0101178:	e8 f5 fb ff ff       	call   f0100d72 <getuint>
			base = 16;
f010117d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101182:	83 ec 0c             	sub    $0xc,%esp
f0101185:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101189:	57                   	push   %edi
f010118a:	ff 75 e0             	pushl  -0x20(%ebp)
f010118d:	51                   	push   %ecx
f010118e:	52                   	push   %edx
f010118f:	50                   	push   %eax
f0101190:	89 da                	mov    %ebx,%edx
f0101192:	89 f0                	mov    %esi,%eax
f0101194:	e8 2a fb ff ff       	call   f0100cc3 <printnum>
			break;
f0101199:	83 c4 20             	add    $0x20,%esp
f010119c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010119f:	e9 73 fc ff ff       	jmp    f0100e17 <vprintfmt+0x31>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011a4:	83 ec 08             	sub    $0x8,%esp
f01011a7:	53                   	push   %ebx
f01011a8:	51                   	push   %ecx
f01011a9:	ff d6                	call   *%esi
			break;
f01011ab:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011b1:	e9 61 fc ff ff       	jmp    f0100e17 <vprintfmt+0x31>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011b6:	83 ec 08             	sub    $0x8,%esp
f01011b9:	53                   	push   %ebx
f01011ba:	6a 25                	push   $0x25
f01011bc:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011be:	83 c4 10             	add    $0x10,%esp
f01011c1:	eb 03                	jmp    f01011c6 <vprintfmt+0x3e0>
f01011c3:	83 ef 01             	sub    $0x1,%edi
f01011c6:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011ca:	75 f7                	jne    f01011c3 <vprintfmt+0x3dd>
f01011cc:	e9 46 fc ff ff       	jmp    f0100e17 <vprintfmt+0x31>
				/* do nothing */;
			break;
		}
	}
}
f01011d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011d4:	5b                   	pop    %ebx
f01011d5:	5e                   	pop    %esi
f01011d6:	5f                   	pop    %edi
f01011d7:	5d                   	pop    %ebp
f01011d8:	c3                   	ret    

f01011d9 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011d9:	55                   	push   %ebp
f01011da:	89 e5                	mov    %esp,%ebp
f01011dc:	83 ec 18             	sub    $0x18,%esp
f01011df:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e2:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011e5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011e8:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011ec:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011ef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011f6:	85 c0                	test   %eax,%eax
f01011f8:	74 26                	je     f0101220 <vsnprintf+0x47>
f01011fa:	85 d2                	test   %edx,%edx
f01011fc:	7e 22                	jle    f0101220 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011fe:	ff 75 14             	pushl  0x14(%ebp)
f0101201:	ff 75 10             	pushl  0x10(%ebp)
f0101204:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101207:	50                   	push   %eax
f0101208:	68 ac 0d 10 f0       	push   $0xf0100dac
f010120d:	e8 d4 fb ff ff       	call   f0100de6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101212:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101215:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101218:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010121b:	83 c4 10             	add    $0x10,%esp
f010121e:	eb 05                	jmp    f0101225 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101220:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101225:	c9                   	leave  
f0101226:	c3                   	ret    

f0101227 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101227:	55                   	push   %ebp
f0101228:	89 e5                	mov    %esp,%ebp
f010122a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010122d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101230:	50                   	push   %eax
f0101231:	ff 75 10             	pushl  0x10(%ebp)
f0101234:	ff 75 0c             	pushl  0xc(%ebp)
f0101237:	ff 75 08             	pushl  0x8(%ebp)
f010123a:	e8 9a ff ff ff       	call   f01011d9 <vsnprintf>
	va_end(ap);

	return rc;
}
f010123f:	c9                   	leave  
f0101240:	c3                   	ret    

f0101241 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101241:	55                   	push   %ebp
f0101242:	89 e5                	mov    %esp,%ebp
f0101244:	57                   	push   %edi
f0101245:	56                   	push   %esi
f0101246:	53                   	push   %ebx
f0101247:	83 ec 0c             	sub    $0xc,%esp
f010124a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010124d:	85 c0                	test   %eax,%eax
f010124f:	74 11                	je     f0101262 <readline+0x21>
		cprintf("%s", prompt);
f0101251:	83 ec 08             	sub    $0x8,%esp
f0101254:	50                   	push   %eax
f0101255:	68 4a 1f 10 f0       	push   $0xf0101f4a
f010125a:	e8 4a f7 ff ff       	call   f01009a9 <cprintf>
f010125f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101262:	83 ec 0c             	sub    $0xc,%esp
f0101265:	6a 00                	push   $0x0
f0101267:	e8 ee f3 ff ff       	call   f010065a <iscons>
f010126c:	89 c7                	mov    %eax,%edi
f010126e:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101271:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101276:	e8 ce f3 ff ff       	call   f0100649 <getchar>
f010127b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010127d:	85 c0                	test   %eax,%eax
f010127f:	79 18                	jns    f0101299 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101281:	83 ec 08             	sub    $0x8,%esp
f0101284:	50                   	push   %eax
f0101285:	68 40 21 10 f0       	push   $0xf0102140
f010128a:	e8 1a f7 ff ff       	call   f01009a9 <cprintf>
			return NULL;
f010128f:	83 c4 10             	add    $0x10,%esp
f0101292:	b8 00 00 00 00       	mov    $0x0,%eax
f0101297:	eb 79                	jmp    f0101312 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101299:	83 f8 08             	cmp    $0x8,%eax
f010129c:	0f 94 c2             	sete   %dl
f010129f:	83 f8 7f             	cmp    $0x7f,%eax
f01012a2:	0f 94 c0             	sete   %al
f01012a5:	08 c2                	or     %al,%dl
f01012a7:	74 1a                	je     f01012c3 <readline+0x82>
f01012a9:	85 f6                	test   %esi,%esi
f01012ab:	7e 16                	jle    f01012c3 <readline+0x82>
			if (echoing)
f01012ad:	85 ff                	test   %edi,%edi
f01012af:	74 0d                	je     f01012be <readline+0x7d>
				cputchar('\b');
f01012b1:	83 ec 0c             	sub    $0xc,%esp
f01012b4:	6a 08                	push   $0x8
f01012b6:	e8 7e f3 ff ff       	call   f0100639 <cputchar>
f01012bb:	83 c4 10             	add    $0x10,%esp
			i--;
f01012be:	83 ee 01             	sub    $0x1,%esi
f01012c1:	eb b3                	jmp    f0101276 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012c3:	83 fb 1f             	cmp    $0x1f,%ebx
f01012c6:	7e 23                	jle    f01012eb <readline+0xaa>
f01012c8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012ce:	7f 1b                	jg     f01012eb <readline+0xaa>
			if (echoing)
f01012d0:	85 ff                	test   %edi,%edi
f01012d2:	74 0c                	je     f01012e0 <readline+0x9f>
				cputchar(c);
f01012d4:	83 ec 0c             	sub    $0xc,%esp
f01012d7:	53                   	push   %ebx
f01012d8:	e8 5c f3 ff ff       	call   f0100639 <cputchar>
f01012dd:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012e0:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012e6:	8d 76 01             	lea    0x1(%esi),%esi
f01012e9:	eb 8b                	jmp    f0101276 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012eb:	83 fb 0a             	cmp    $0xa,%ebx
f01012ee:	74 05                	je     f01012f5 <readline+0xb4>
f01012f0:	83 fb 0d             	cmp    $0xd,%ebx
f01012f3:	75 81                	jne    f0101276 <readline+0x35>
			if (echoing)
f01012f5:	85 ff                	test   %edi,%edi
f01012f7:	74 0d                	je     f0101306 <readline+0xc5>
				cputchar('\n');
f01012f9:	83 ec 0c             	sub    $0xc,%esp
f01012fc:	6a 0a                	push   $0xa
f01012fe:	e8 36 f3 ff ff       	call   f0100639 <cputchar>
f0101303:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101306:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010130d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101312:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101315:	5b                   	pop    %ebx
f0101316:	5e                   	pop    %esi
f0101317:	5f                   	pop    %edi
f0101318:	5d                   	pop    %ebp
f0101319:	c3                   	ret    

f010131a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010131a:	55                   	push   %ebp
f010131b:	89 e5                	mov    %esp,%ebp
f010131d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101320:	b8 00 00 00 00       	mov    $0x0,%eax
f0101325:	eb 03                	jmp    f010132a <strlen+0x10>
		n++;
f0101327:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010132a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010132e:	75 f7                	jne    f0101327 <strlen+0xd>
		n++;
	return n;
}
f0101330:	5d                   	pop    %ebp
f0101331:	c3                   	ret    

f0101332 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101332:	55                   	push   %ebp
f0101333:	89 e5                	mov    %esp,%ebp
f0101335:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101338:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010133b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101340:	eb 03                	jmp    f0101345 <strnlen+0x13>
		n++;
f0101342:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101345:	39 c2                	cmp    %eax,%edx
f0101347:	74 08                	je     f0101351 <strnlen+0x1f>
f0101349:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010134d:	75 f3                	jne    f0101342 <strnlen+0x10>
f010134f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101351:	5d                   	pop    %ebp
f0101352:	c3                   	ret    

f0101353 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101353:	55                   	push   %ebp
f0101354:	89 e5                	mov    %esp,%ebp
f0101356:	53                   	push   %ebx
f0101357:	8b 45 08             	mov    0x8(%ebp),%eax
f010135a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010135d:	89 c2                	mov    %eax,%edx
f010135f:	83 c2 01             	add    $0x1,%edx
f0101362:	83 c1 01             	add    $0x1,%ecx
f0101365:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101369:	88 5a ff             	mov    %bl,-0x1(%edx)
f010136c:	84 db                	test   %bl,%bl
f010136e:	75 ef                	jne    f010135f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101370:	5b                   	pop    %ebx
f0101371:	5d                   	pop    %ebp
f0101372:	c3                   	ret    

f0101373 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101373:	55                   	push   %ebp
f0101374:	89 e5                	mov    %esp,%ebp
f0101376:	53                   	push   %ebx
f0101377:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010137a:	53                   	push   %ebx
f010137b:	e8 9a ff ff ff       	call   f010131a <strlen>
f0101380:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101383:	ff 75 0c             	pushl  0xc(%ebp)
f0101386:	01 d8                	add    %ebx,%eax
f0101388:	50                   	push   %eax
f0101389:	e8 c5 ff ff ff       	call   f0101353 <strcpy>
	return dst;
}
f010138e:	89 d8                	mov    %ebx,%eax
f0101390:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101393:	c9                   	leave  
f0101394:	c3                   	ret    

f0101395 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101395:	55                   	push   %ebp
f0101396:	89 e5                	mov    %esp,%ebp
f0101398:	56                   	push   %esi
f0101399:	53                   	push   %ebx
f010139a:	8b 75 08             	mov    0x8(%ebp),%esi
f010139d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013a0:	89 f3                	mov    %esi,%ebx
f01013a2:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013a5:	89 f2                	mov    %esi,%edx
f01013a7:	eb 0f                	jmp    f01013b8 <strncpy+0x23>
		*dst++ = *src;
f01013a9:	83 c2 01             	add    $0x1,%edx
f01013ac:	0f b6 01             	movzbl (%ecx),%eax
f01013af:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013b2:	80 39 01             	cmpb   $0x1,(%ecx)
f01013b5:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013b8:	39 da                	cmp    %ebx,%edx
f01013ba:	75 ed                	jne    f01013a9 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013bc:	89 f0                	mov    %esi,%eax
f01013be:	5b                   	pop    %ebx
f01013bf:	5e                   	pop    %esi
f01013c0:	5d                   	pop    %ebp
f01013c1:	c3                   	ret    

f01013c2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013c2:	55                   	push   %ebp
f01013c3:	89 e5                	mov    %esp,%ebp
f01013c5:	56                   	push   %esi
f01013c6:	53                   	push   %ebx
f01013c7:	8b 75 08             	mov    0x8(%ebp),%esi
f01013ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013cd:	8b 55 10             	mov    0x10(%ebp),%edx
f01013d0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013d2:	85 d2                	test   %edx,%edx
f01013d4:	74 21                	je     f01013f7 <strlcpy+0x35>
f01013d6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013da:	89 f2                	mov    %esi,%edx
f01013dc:	eb 09                	jmp    f01013e7 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013de:	83 c2 01             	add    $0x1,%edx
f01013e1:	83 c1 01             	add    $0x1,%ecx
f01013e4:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013e7:	39 c2                	cmp    %eax,%edx
f01013e9:	74 09                	je     f01013f4 <strlcpy+0x32>
f01013eb:	0f b6 19             	movzbl (%ecx),%ebx
f01013ee:	84 db                	test   %bl,%bl
f01013f0:	75 ec                	jne    f01013de <strlcpy+0x1c>
f01013f2:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013f4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013f7:	29 f0                	sub    %esi,%eax
}
f01013f9:	5b                   	pop    %ebx
f01013fa:	5e                   	pop    %esi
f01013fb:	5d                   	pop    %ebp
f01013fc:	c3                   	ret    

f01013fd <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013fd:	55                   	push   %ebp
f01013fe:	89 e5                	mov    %esp,%ebp
f0101400:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101403:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101406:	eb 06                	jmp    f010140e <strcmp+0x11>
		p++, q++;
f0101408:	83 c1 01             	add    $0x1,%ecx
f010140b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010140e:	0f b6 01             	movzbl (%ecx),%eax
f0101411:	84 c0                	test   %al,%al
f0101413:	74 04                	je     f0101419 <strcmp+0x1c>
f0101415:	3a 02                	cmp    (%edx),%al
f0101417:	74 ef                	je     f0101408 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101419:	0f b6 c0             	movzbl %al,%eax
f010141c:	0f b6 12             	movzbl (%edx),%edx
f010141f:	29 d0                	sub    %edx,%eax
}
f0101421:	5d                   	pop    %ebp
f0101422:	c3                   	ret    

f0101423 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101423:	55                   	push   %ebp
f0101424:	89 e5                	mov    %esp,%ebp
f0101426:	53                   	push   %ebx
f0101427:	8b 45 08             	mov    0x8(%ebp),%eax
f010142a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010142d:	89 c3                	mov    %eax,%ebx
f010142f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101432:	eb 06                	jmp    f010143a <strncmp+0x17>
		n--, p++, q++;
f0101434:	83 c0 01             	add    $0x1,%eax
f0101437:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010143a:	39 d8                	cmp    %ebx,%eax
f010143c:	74 15                	je     f0101453 <strncmp+0x30>
f010143e:	0f b6 08             	movzbl (%eax),%ecx
f0101441:	84 c9                	test   %cl,%cl
f0101443:	74 04                	je     f0101449 <strncmp+0x26>
f0101445:	3a 0a                	cmp    (%edx),%cl
f0101447:	74 eb                	je     f0101434 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101449:	0f b6 00             	movzbl (%eax),%eax
f010144c:	0f b6 12             	movzbl (%edx),%edx
f010144f:	29 d0                	sub    %edx,%eax
f0101451:	eb 05                	jmp    f0101458 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101453:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101458:	5b                   	pop    %ebx
f0101459:	5d                   	pop    %ebp
f010145a:	c3                   	ret    

f010145b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010145b:	55                   	push   %ebp
f010145c:	89 e5                	mov    %esp,%ebp
f010145e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101461:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101465:	eb 07                	jmp    f010146e <strchr+0x13>
		if (*s == c)
f0101467:	38 ca                	cmp    %cl,%dl
f0101469:	74 0f                	je     f010147a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010146b:	83 c0 01             	add    $0x1,%eax
f010146e:	0f b6 10             	movzbl (%eax),%edx
f0101471:	84 d2                	test   %dl,%dl
f0101473:	75 f2                	jne    f0101467 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101475:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010147a:	5d                   	pop    %ebp
f010147b:	c3                   	ret    

f010147c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010147c:	55                   	push   %ebp
f010147d:	89 e5                	mov    %esp,%ebp
f010147f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101482:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101486:	eb 03                	jmp    f010148b <strfind+0xf>
f0101488:	83 c0 01             	add    $0x1,%eax
f010148b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010148e:	38 ca                	cmp    %cl,%dl
f0101490:	74 04                	je     f0101496 <strfind+0x1a>
f0101492:	84 d2                	test   %dl,%dl
f0101494:	75 f2                	jne    f0101488 <strfind+0xc>
			break;
	return (char *) s;
}
f0101496:	5d                   	pop    %ebp
f0101497:	c3                   	ret    

f0101498 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101498:	55                   	push   %ebp
f0101499:	89 e5                	mov    %esp,%ebp
f010149b:	57                   	push   %edi
f010149c:	56                   	push   %esi
f010149d:	53                   	push   %ebx
f010149e:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014a1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014a4:	85 c9                	test   %ecx,%ecx
f01014a6:	74 36                	je     f01014de <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014a8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014ae:	75 28                	jne    f01014d8 <memset+0x40>
f01014b0:	f6 c1 03             	test   $0x3,%cl
f01014b3:	75 23                	jne    f01014d8 <memset+0x40>
		c &= 0xFF;
f01014b5:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014b9:	89 d3                	mov    %edx,%ebx
f01014bb:	c1 e3 08             	shl    $0x8,%ebx
f01014be:	89 d6                	mov    %edx,%esi
f01014c0:	c1 e6 18             	shl    $0x18,%esi
f01014c3:	89 d0                	mov    %edx,%eax
f01014c5:	c1 e0 10             	shl    $0x10,%eax
f01014c8:	09 f0                	or     %esi,%eax
f01014ca:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01014cc:	89 d8                	mov    %ebx,%eax
f01014ce:	09 d0                	or     %edx,%eax
f01014d0:	c1 e9 02             	shr    $0x2,%ecx
f01014d3:	fc                   	cld    
f01014d4:	f3 ab                	rep stos %eax,%es:(%edi)
f01014d6:	eb 06                	jmp    f01014de <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014db:	fc                   	cld    
f01014dc:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014de:	89 f8                	mov    %edi,%eax
f01014e0:	5b                   	pop    %ebx
f01014e1:	5e                   	pop    %esi
f01014e2:	5f                   	pop    %edi
f01014e3:	5d                   	pop    %ebp
f01014e4:	c3                   	ret    

f01014e5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014e5:	55                   	push   %ebp
f01014e6:	89 e5                	mov    %esp,%ebp
f01014e8:	57                   	push   %edi
f01014e9:	56                   	push   %esi
f01014ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ed:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014f3:	39 c6                	cmp    %eax,%esi
f01014f5:	73 35                	jae    f010152c <memmove+0x47>
f01014f7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014fa:	39 d0                	cmp    %edx,%eax
f01014fc:	73 2e                	jae    f010152c <memmove+0x47>
		s += n;
		d += n;
f01014fe:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101501:	89 d6                	mov    %edx,%esi
f0101503:	09 fe                	or     %edi,%esi
f0101505:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010150b:	75 13                	jne    f0101520 <memmove+0x3b>
f010150d:	f6 c1 03             	test   $0x3,%cl
f0101510:	75 0e                	jne    f0101520 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101512:	83 ef 04             	sub    $0x4,%edi
f0101515:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101518:	c1 e9 02             	shr    $0x2,%ecx
f010151b:	fd                   	std    
f010151c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010151e:	eb 09                	jmp    f0101529 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101520:	83 ef 01             	sub    $0x1,%edi
f0101523:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101526:	fd                   	std    
f0101527:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101529:	fc                   	cld    
f010152a:	eb 1d                	jmp    f0101549 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010152c:	89 f2                	mov    %esi,%edx
f010152e:	09 c2                	or     %eax,%edx
f0101530:	f6 c2 03             	test   $0x3,%dl
f0101533:	75 0f                	jne    f0101544 <memmove+0x5f>
f0101535:	f6 c1 03             	test   $0x3,%cl
f0101538:	75 0a                	jne    f0101544 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010153a:	c1 e9 02             	shr    $0x2,%ecx
f010153d:	89 c7                	mov    %eax,%edi
f010153f:	fc                   	cld    
f0101540:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101542:	eb 05                	jmp    f0101549 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101544:	89 c7                	mov    %eax,%edi
f0101546:	fc                   	cld    
f0101547:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101549:	5e                   	pop    %esi
f010154a:	5f                   	pop    %edi
f010154b:	5d                   	pop    %ebp
f010154c:	c3                   	ret    

f010154d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010154d:	55                   	push   %ebp
f010154e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101550:	ff 75 10             	pushl  0x10(%ebp)
f0101553:	ff 75 0c             	pushl  0xc(%ebp)
f0101556:	ff 75 08             	pushl  0x8(%ebp)
f0101559:	e8 87 ff ff ff       	call   f01014e5 <memmove>
}
f010155e:	c9                   	leave  
f010155f:	c3                   	ret    

f0101560 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101560:	55                   	push   %ebp
f0101561:	89 e5                	mov    %esp,%ebp
f0101563:	56                   	push   %esi
f0101564:	53                   	push   %ebx
f0101565:	8b 45 08             	mov    0x8(%ebp),%eax
f0101568:	8b 55 0c             	mov    0xc(%ebp),%edx
f010156b:	89 c6                	mov    %eax,%esi
f010156d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101570:	eb 1a                	jmp    f010158c <memcmp+0x2c>
		if (*s1 != *s2)
f0101572:	0f b6 08             	movzbl (%eax),%ecx
f0101575:	0f b6 1a             	movzbl (%edx),%ebx
f0101578:	38 d9                	cmp    %bl,%cl
f010157a:	74 0a                	je     f0101586 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010157c:	0f b6 c1             	movzbl %cl,%eax
f010157f:	0f b6 db             	movzbl %bl,%ebx
f0101582:	29 d8                	sub    %ebx,%eax
f0101584:	eb 0f                	jmp    f0101595 <memcmp+0x35>
		s1++, s2++;
f0101586:	83 c0 01             	add    $0x1,%eax
f0101589:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010158c:	39 f0                	cmp    %esi,%eax
f010158e:	75 e2                	jne    f0101572 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101590:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101595:	5b                   	pop    %ebx
f0101596:	5e                   	pop    %esi
f0101597:	5d                   	pop    %ebp
f0101598:	c3                   	ret    

f0101599 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101599:	55                   	push   %ebp
f010159a:	89 e5                	mov    %esp,%ebp
f010159c:	53                   	push   %ebx
f010159d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01015a0:	89 c1                	mov    %eax,%ecx
f01015a2:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01015a5:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015a9:	eb 0a                	jmp    f01015b5 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015ab:	0f b6 10             	movzbl (%eax),%edx
f01015ae:	39 da                	cmp    %ebx,%edx
f01015b0:	74 07                	je     f01015b9 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015b2:	83 c0 01             	add    $0x1,%eax
f01015b5:	39 c8                	cmp    %ecx,%eax
f01015b7:	72 f2                	jb     f01015ab <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015b9:	5b                   	pop    %ebx
f01015ba:	5d                   	pop    %ebp
f01015bb:	c3                   	ret    

f01015bc <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015bc:	55                   	push   %ebp
f01015bd:	89 e5                	mov    %esp,%ebp
f01015bf:	57                   	push   %edi
f01015c0:	56                   	push   %esi
f01015c1:	53                   	push   %ebx
f01015c2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015c5:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015c8:	eb 03                	jmp    f01015cd <strtol+0x11>
		s++;
f01015ca:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015cd:	0f b6 01             	movzbl (%ecx),%eax
f01015d0:	3c 20                	cmp    $0x20,%al
f01015d2:	74 f6                	je     f01015ca <strtol+0xe>
f01015d4:	3c 09                	cmp    $0x9,%al
f01015d6:	74 f2                	je     f01015ca <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015d8:	3c 2b                	cmp    $0x2b,%al
f01015da:	75 0a                	jne    f01015e6 <strtol+0x2a>
		s++;
f01015dc:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015df:	bf 00 00 00 00       	mov    $0x0,%edi
f01015e4:	eb 11                	jmp    f01015f7 <strtol+0x3b>
f01015e6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015eb:	3c 2d                	cmp    $0x2d,%al
f01015ed:	75 08                	jne    f01015f7 <strtol+0x3b>
		s++, neg = 1;
f01015ef:	83 c1 01             	add    $0x1,%ecx
f01015f2:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015f7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015fd:	75 15                	jne    f0101614 <strtol+0x58>
f01015ff:	80 39 30             	cmpb   $0x30,(%ecx)
f0101602:	75 10                	jne    f0101614 <strtol+0x58>
f0101604:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101608:	75 7c                	jne    f0101686 <strtol+0xca>
		s += 2, base = 16;
f010160a:	83 c1 02             	add    $0x2,%ecx
f010160d:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101612:	eb 16                	jmp    f010162a <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101614:	85 db                	test   %ebx,%ebx
f0101616:	75 12                	jne    f010162a <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101618:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010161d:	80 39 30             	cmpb   $0x30,(%ecx)
f0101620:	75 08                	jne    f010162a <strtol+0x6e>
		s++, base = 8;
f0101622:	83 c1 01             	add    $0x1,%ecx
f0101625:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010162a:	b8 00 00 00 00       	mov    $0x0,%eax
f010162f:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101632:	0f b6 11             	movzbl (%ecx),%edx
f0101635:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101638:	89 f3                	mov    %esi,%ebx
f010163a:	80 fb 09             	cmp    $0x9,%bl
f010163d:	77 08                	ja     f0101647 <strtol+0x8b>
			dig = *s - '0';
f010163f:	0f be d2             	movsbl %dl,%edx
f0101642:	83 ea 30             	sub    $0x30,%edx
f0101645:	eb 22                	jmp    f0101669 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101647:	8d 72 9f             	lea    -0x61(%edx),%esi
f010164a:	89 f3                	mov    %esi,%ebx
f010164c:	80 fb 19             	cmp    $0x19,%bl
f010164f:	77 08                	ja     f0101659 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101651:	0f be d2             	movsbl %dl,%edx
f0101654:	83 ea 57             	sub    $0x57,%edx
f0101657:	eb 10                	jmp    f0101669 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101659:	8d 72 bf             	lea    -0x41(%edx),%esi
f010165c:	89 f3                	mov    %esi,%ebx
f010165e:	80 fb 19             	cmp    $0x19,%bl
f0101661:	77 16                	ja     f0101679 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101663:	0f be d2             	movsbl %dl,%edx
f0101666:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101669:	3b 55 10             	cmp    0x10(%ebp),%edx
f010166c:	7d 0b                	jge    f0101679 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010166e:	83 c1 01             	add    $0x1,%ecx
f0101671:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101675:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101677:	eb b9                	jmp    f0101632 <strtol+0x76>

	if (endptr)
f0101679:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010167d:	74 0d                	je     f010168c <strtol+0xd0>
		*endptr = (char *) s;
f010167f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101682:	89 0e                	mov    %ecx,(%esi)
f0101684:	eb 06                	jmp    f010168c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101686:	85 db                	test   %ebx,%ebx
f0101688:	74 98                	je     f0101622 <strtol+0x66>
f010168a:	eb 9e                	jmp    f010162a <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010168c:	89 c2                	mov    %eax,%edx
f010168e:	f7 da                	neg    %edx
f0101690:	85 ff                	test   %edi,%edi
f0101692:	0f 45 c2             	cmovne %edx,%eax
}
f0101695:	5b                   	pop    %ebx
f0101696:	5e                   	pop    %esi
f0101697:	5f                   	pop    %edi
f0101698:	5d                   	pop    %ebp
f0101699:	c3                   	ret    
f010169a:	66 90                	xchg   %ax,%ax
f010169c:	66 90                	xchg   %ax,%ax
f010169e:	66 90                	xchg   %ax,%ax

f01016a0 <__udivdi3>:
f01016a0:	55                   	push   %ebp
f01016a1:	57                   	push   %edi
f01016a2:	56                   	push   %esi
f01016a3:	53                   	push   %ebx
f01016a4:	83 ec 1c             	sub    $0x1c,%esp
f01016a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01016ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01016af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01016b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016b7:	85 f6                	test   %esi,%esi
f01016b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01016bd:	89 ca                	mov    %ecx,%edx
f01016bf:	89 f8                	mov    %edi,%eax
f01016c1:	75 3d                	jne    f0101700 <__udivdi3+0x60>
f01016c3:	39 cf                	cmp    %ecx,%edi
f01016c5:	0f 87 c5 00 00 00    	ja     f0101790 <__udivdi3+0xf0>
f01016cb:	85 ff                	test   %edi,%edi
f01016cd:	89 fd                	mov    %edi,%ebp
f01016cf:	75 0b                	jne    f01016dc <__udivdi3+0x3c>
f01016d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016d6:	31 d2                	xor    %edx,%edx
f01016d8:	f7 f7                	div    %edi
f01016da:	89 c5                	mov    %eax,%ebp
f01016dc:	89 c8                	mov    %ecx,%eax
f01016de:	31 d2                	xor    %edx,%edx
f01016e0:	f7 f5                	div    %ebp
f01016e2:	89 c1                	mov    %eax,%ecx
f01016e4:	89 d8                	mov    %ebx,%eax
f01016e6:	89 cf                	mov    %ecx,%edi
f01016e8:	f7 f5                	div    %ebp
f01016ea:	89 c3                	mov    %eax,%ebx
f01016ec:	89 d8                	mov    %ebx,%eax
f01016ee:	89 fa                	mov    %edi,%edx
f01016f0:	83 c4 1c             	add    $0x1c,%esp
f01016f3:	5b                   	pop    %ebx
f01016f4:	5e                   	pop    %esi
f01016f5:	5f                   	pop    %edi
f01016f6:	5d                   	pop    %ebp
f01016f7:	c3                   	ret    
f01016f8:	90                   	nop
f01016f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101700:	39 ce                	cmp    %ecx,%esi
f0101702:	77 74                	ja     f0101778 <__udivdi3+0xd8>
f0101704:	0f bd fe             	bsr    %esi,%edi
f0101707:	83 f7 1f             	xor    $0x1f,%edi
f010170a:	0f 84 98 00 00 00    	je     f01017a8 <__udivdi3+0x108>
f0101710:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101715:	89 f9                	mov    %edi,%ecx
f0101717:	89 c5                	mov    %eax,%ebp
f0101719:	29 fb                	sub    %edi,%ebx
f010171b:	d3 e6                	shl    %cl,%esi
f010171d:	89 d9                	mov    %ebx,%ecx
f010171f:	d3 ed                	shr    %cl,%ebp
f0101721:	89 f9                	mov    %edi,%ecx
f0101723:	d3 e0                	shl    %cl,%eax
f0101725:	09 ee                	or     %ebp,%esi
f0101727:	89 d9                	mov    %ebx,%ecx
f0101729:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010172d:	89 d5                	mov    %edx,%ebp
f010172f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101733:	d3 ed                	shr    %cl,%ebp
f0101735:	89 f9                	mov    %edi,%ecx
f0101737:	d3 e2                	shl    %cl,%edx
f0101739:	89 d9                	mov    %ebx,%ecx
f010173b:	d3 e8                	shr    %cl,%eax
f010173d:	09 c2                	or     %eax,%edx
f010173f:	89 d0                	mov    %edx,%eax
f0101741:	89 ea                	mov    %ebp,%edx
f0101743:	f7 f6                	div    %esi
f0101745:	89 d5                	mov    %edx,%ebp
f0101747:	89 c3                	mov    %eax,%ebx
f0101749:	f7 64 24 0c          	mull   0xc(%esp)
f010174d:	39 d5                	cmp    %edx,%ebp
f010174f:	72 10                	jb     f0101761 <__udivdi3+0xc1>
f0101751:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101755:	89 f9                	mov    %edi,%ecx
f0101757:	d3 e6                	shl    %cl,%esi
f0101759:	39 c6                	cmp    %eax,%esi
f010175b:	73 07                	jae    f0101764 <__udivdi3+0xc4>
f010175d:	39 d5                	cmp    %edx,%ebp
f010175f:	75 03                	jne    f0101764 <__udivdi3+0xc4>
f0101761:	83 eb 01             	sub    $0x1,%ebx
f0101764:	31 ff                	xor    %edi,%edi
f0101766:	89 d8                	mov    %ebx,%eax
f0101768:	89 fa                	mov    %edi,%edx
f010176a:	83 c4 1c             	add    $0x1c,%esp
f010176d:	5b                   	pop    %ebx
f010176e:	5e                   	pop    %esi
f010176f:	5f                   	pop    %edi
f0101770:	5d                   	pop    %ebp
f0101771:	c3                   	ret    
f0101772:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101778:	31 ff                	xor    %edi,%edi
f010177a:	31 db                	xor    %ebx,%ebx
f010177c:	89 d8                	mov    %ebx,%eax
f010177e:	89 fa                	mov    %edi,%edx
f0101780:	83 c4 1c             	add    $0x1c,%esp
f0101783:	5b                   	pop    %ebx
f0101784:	5e                   	pop    %esi
f0101785:	5f                   	pop    %edi
f0101786:	5d                   	pop    %ebp
f0101787:	c3                   	ret    
f0101788:	90                   	nop
f0101789:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101790:	89 d8                	mov    %ebx,%eax
f0101792:	f7 f7                	div    %edi
f0101794:	31 ff                	xor    %edi,%edi
f0101796:	89 c3                	mov    %eax,%ebx
f0101798:	89 d8                	mov    %ebx,%eax
f010179a:	89 fa                	mov    %edi,%edx
f010179c:	83 c4 1c             	add    $0x1c,%esp
f010179f:	5b                   	pop    %ebx
f01017a0:	5e                   	pop    %esi
f01017a1:	5f                   	pop    %edi
f01017a2:	5d                   	pop    %ebp
f01017a3:	c3                   	ret    
f01017a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	39 ce                	cmp    %ecx,%esi
f01017aa:	72 0c                	jb     f01017b8 <__udivdi3+0x118>
f01017ac:	31 db                	xor    %ebx,%ebx
f01017ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01017b2:	0f 87 34 ff ff ff    	ja     f01016ec <__udivdi3+0x4c>
f01017b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01017bd:	e9 2a ff ff ff       	jmp    f01016ec <__udivdi3+0x4c>
f01017c2:	66 90                	xchg   %ax,%ax
f01017c4:	66 90                	xchg   %ax,%ax
f01017c6:	66 90                	xchg   %ax,%ax
f01017c8:	66 90                	xchg   %ax,%ax
f01017ca:	66 90                	xchg   %ax,%ax
f01017cc:	66 90                	xchg   %ax,%ax
f01017ce:	66 90                	xchg   %ax,%ax

f01017d0 <__umoddi3>:
f01017d0:	55                   	push   %ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	53                   	push   %ebx
f01017d4:	83 ec 1c             	sub    $0x1c,%esp
f01017d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017e7:	85 d2                	test   %edx,%edx
f01017e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017f1:	89 f3                	mov    %esi,%ebx
f01017f3:	89 3c 24             	mov    %edi,(%esp)
f01017f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017fa:	75 1c                	jne    f0101818 <__umoddi3+0x48>
f01017fc:	39 f7                	cmp    %esi,%edi
f01017fe:	76 50                	jbe    f0101850 <__umoddi3+0x80>
f0101800:	89 c8                	mov    %ecx,%eax
f0101802:	89 f2                	mov    %esi,%edx
f0101804:	f7 f7                	div    %edi
f0101806:	89 d0                	mov    %edx,%eax
f0101808:	31 d2                	xor    %edx,%edx
f010180a:	83 c4 1c             	add    $0x1c,%esp
f010180d:	5b                   	pop    %ebx
f010180e:	5e                   	pop    %esi
f010180f:	5f                   	pop    %edi
f0101810:	5d                   	pop    %ebp
f0101811:	c3                   	ret    
f0101812:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101818:	39 f2                	cmp    %esi,%edx
f010181a:	89 d0                	mov    %edx,%eax
f010181c:	77 52                	ja     f0101870 <__umoddi3+0xa0>
f010181e:	0f bd ea             	bsr    %edx,%ebp
f0101821:	83 f5 1f             	xor    $0x1f,%ebp
f0101824:	75 5a                	jne    f0101880 <__umoddi3+0xb0>
f0101826:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010182a:	0f 82 e0 00 00 00    	jb     f0101910 <__umoddi3+0x140>
f0101830:	39 0c 24             	cmp    %ecx,(%esp)
f0101833:	0f 86 d7 00 00 00    	jbe    f0101910 <__umoddi3+0x140>
f0101839:	8b 44 24 08          	mov    0x8(%esp),%eax
f010183d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101841:	83 c4 1c             	add    $0x1c,%esp
f0101844:	5b                   	pop    %ebx
f0101845:	5e                   	pop    %esi
f0101846:	5f                   	pop    %edi
f0101847:	5d                   	pop    %ebp
f0101848:	c3                   	ret    
f0101849:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101850:	85 ff                	test   %edi,%edi
f0101852:	89 fd                	mov    %edi,%ebp
f0101854:	75 0b                	jne    f0101861 <__umoddi3+0x91>
f0101856:	b8 01 00 00 00       	mov    $0x1,%eax
f010185b:	31 d2                	xor    %edx,%edx
f010185d:	f7 f7                	div    %edi
f010185f:	89 c5                	mov    %eax,%ebp
f0101861:	89 f0                	mov    %esi,%eax
f0101863:	31 d2                	xor    %edx,%edx
f0101865:	f7 f5                	div    %ebp
f0101867:	89 c8                	mov    %ecx,%eax
f0101869:	f7 f5                	div    %ebp
f010186b:	89 d0                	mov    %edx,%eax
f010186d:	eb 99                	jmp    f0101808 <__umoddi3+0x38>
f010186f:	90                   	nop
f0101870:	89 c8                	mov    %ecx,%eax
f0101872:	89 f2                	mov    %esi,%edx
f0101874:	83 c4 1c             	add    $0x1c,%esp
f0101877:	5b                   	pop    %ebx
f0101878:	5e                   	pop    %esi
f0101879:	5f                   	pop    %edi
f010187a:	5d                   	pop    %ebp
f010187b:	c3                   	ret    
f010187c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101880:	8b 34 24             	mov    (%esp),%esi
f0101883:	bf 20 00 00 00       	mov    $0x20,%edi
f0101888:	89 e9                	mov    %ebp,%ecx
f010188a:	29 ef                	sub    %ebp,%edi
f010188c:	d3 e0                	shl    %cl,%eax
f010188e:	89 f9                	mov    %edi,%ecx
f0101890:	89 f2                	mov    %esi,%edx
f0101892:	d3 ea                	shr    %cl,%edx
f0101894:	89 e9                	mov    %ebp,%ecx
f0101896:	09 c2                	or     %eax,%edx
f0101898:	89 d8                	mov    %ebx,%eax
f010189a:	89 14 24             	mov    %edx,(%esp)
f010189d:	89 f2                	mov    %esi,%edx
f010189f:	d3 e2                	shl    %cl,%edx
f01018a1:	89 f9                	mov    %edi,%ecx
f01018a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01018a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018ab:	d3 e8                	shr    %cl,%eax
f01018ad:	89 e9                	mov    %ebp,%ecx
f01018af:	89 c6                	mov    %eax,%esi
f01018b1:	d3 e3                	shl    %cl,%ebx
f01018b3:	89 f9                	mov    %edi,%ecx
f01018b5:	89 d0                	mov    %edx,%eax
f01018b7:	d3 e8                	shr    %cl,%eax
f01018b9:	89 e9                	mov    %ebp,%ecx
f01018bb:	09 d8                	or     %ebx,%eax
f01018bd:	89 d3                	mov    %edx,%ebx
f01018bf:	89 f2                	mov    %esi,%edx
f01018c1:	f7 34 24             	divl   (%esp)
f01018c4:	89 d6                	mov    %edx,%esi
f01018c6:	d3 e3                	shl    %cl,%ebx
f01018c8:	f7 64 24 04          	mull   0x4(%esp)
f01018cc:	39 d6                	cmp    %edx,%esi
f01018ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018d2:	89 d1                	mov    %edx,%ecx
f01018d4:	89 c3                	mov    %eax,%ebx
f01018d6:	72 08                	jb     f01018e0 <__umoddi3+0x110>
f01018d8:	75 11                	jne    f01018eb <__umoddi3+0x11b>
f01018da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018de:	73 0b                	jae    f01018eb <__umoddi3+0x11b>
f01018e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018e4:	1b 14 24             	sbb    (%esp),%edx
f01018e7:	89 d1                	mov    %edx,%ecx
f01018e9:	89 c3                	mov    %eax,%ebx
f01018eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018ef:	29 da                	sub    %ebx,%edx
f01018f1:	19 ce                	sbb    %ecx,%esi
f01018f3:	89 f9                	mov    %edi,%ecx
f01018f5:	89 f0                	mov    %esi,%eax
f01018f7:	d3 e0                	shl    %cl,%eax
f01018f9:	89 e9                	mov    %ebp,%ecx
f01018fb:	d3 ea                	shr    %cl,%edx
f01018fd:	89 e9                	mov    %ebp,%ecx
f01018ff:	d3 ee                	shr    %cl,%esi
f0101901:	09 d0                	or     %edx,%eax
f0101903:	89 f2                	mov    %esi,%edx
f0101905:	83 c4 1c             	add    $0x1c,%esp
f0101908:	5b                   	pop    %ebx
f0101909:	5e                   	pop    %esi
f010190a:	5f                   	pop    %edi
f010190b:	5d                   	pop    %ebp
f010190c:	c3                   	ret    
f010190d:	8d 76 00             	lea    0x0(%esi),%esi
f0101910:	29 f9                	sub    %edi,%ecx
f0101912:	19 d6                	sbb    %edx,%esi
f0101914:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101918:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010191c:	e9 18 ff ff ff       	jmp    f0101839 <__umoddi3+0x69>
