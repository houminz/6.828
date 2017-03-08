
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
f010004b:	68 60 18 10 f0       	push   $0xf0101860
f0100050:	e8 ac 08 00 00       	call   f0100901 <cprintf>
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
f0100076:	e8 d1 06 00 00       	call   f010074c <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 7c 18 10 f0       	push   $0xf010187c
f0100087:	e8 75 08 00 00       	call   f0100901 <cprintf>
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
f01000ac:	e8 00 13 00 00       	call   f01013b1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 7b 04 00 00       	call   f0100531 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 97 18 10 f0       	push   $0xf0101897
f01000c3:	e8 39 08 00 00       	call   f0100901 <cprintf>

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
f01000dc:	e8 75 06 00 00       	call   f0100756 <monitor>
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
f010010b:	68 b2 18 10 f0       	push   $0xf01018b2
f0100110:	e8 ec 07 00 00       	call   f0100901 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 bc 07 00 00       	call   f01008db <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ee 18 10 f0 	movl   $0xf01018ee,(%esp)
f0100126:	e8 d6 07 00 00       	call   f0100901 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 1e 06 00 00       	call   f0100756 <monitor>
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
f010014d:	68 ca 18 10 f0       	push   $0xf01018ca
f0100152:	e8 aa 07 00 00       	call   f0100901 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 78 07 00 00       	call   f01008db <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ee 18 10 f0 	movl   $0xf01018ee,(%esp)
f010016a:	e8 92 07 00 00       	call   f0100901 <cprintf>
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
f0100221:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
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
f010025d:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a 40 19 10 f0 	movzbl -0xfefe6c0(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d 20 19 10 f0 	mov    -0xfefe6e0(,%ecx,4),%ecx
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
f01002bb:	68 e4 18 10 f0       	push   $0xf01018e4
f01002c0:	e8 3c 06 00 00       	call   f0100901 <cprintf>
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
f0100455:	e8 a4 0f 00 00       	call   f01013fe <memmove>
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
f0100624:	68 f0 18 10 f0       	push   $0xf01018f0
f0100629:	e8 d3 02 00 00       	call   f0100901 <cprintf>
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
f010066a:	68 40 1b 10 f0       	push   $0xf0101b40
f010066f:	68 5e 1b 10 f0       	push   $0xf0101b5e
f0100674:	68 63 1b 10 f0       	push   $0xf0101b63
f0100679:	e8 83 02 00 00       	call   f0100901 <cprintf>
f010067e:	83 c4 0c             	add    $0xc,%esp
f0100681:	68 ec 1b 10 f0       	push   $0xf0101bec
f0100686:	68 6c 1b 10 f0       	push   $0xf0101b6c
f010068b:	68 63 1b 10 f0       	push   $0xf0101b63
f0100690:	e8 6c 02 00 00       	call   f0100901 <cprintf>
	return 0;
}
f0100695:	b8 00 00 00 00       	mov    $0x0,%eax
f010069a:	c9                   	leave  
f010069b:	c3                   	ret    

f010069c <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010069c:	55                   	push   %ebp
f010069d:	89 e5                	mov    %esp,%ebp
f010069f:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a2:	68 75 1b 10 f0       	push   $0xf0101b75
f01006a7:	e8 55 02 00 00       	call   f0100901 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006ac:	83 c4 08             	add    $0x8,%esp
f01006af:	68 0c 00 10 00       	push   $0x10000c
f01006b4:	68 14 1c 10 f0       	push   $0xf0101c14
f01006b9:	e8 43 02 00 00       	call   f0100901 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006be:	83 c4 0c             	add    $0xc,%esp
f01006c1:	68 0c 00 10 00       	push   $0x10000c
f01006c6:	68 0c 00 10 f0       	push   $0xf010000c
f01006cb:	68 3c 1c 10 f0       	push   $0xf0101c3c
f01006d0:	e8 2c 02 00 00       	call   f0100901 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d5:	83 c4 0c             	add    $0xc,%esp
f01006d8:	68 41 18 10 00       	push   $0x101841
f01006dd:	68 41 18 10 f0       	push   $0xf0101841
f01006e2:	68 60 1c 10 f0       	push   $0xf0101c60
f01006e7:	e8 15 02 00 00       	call   f0100901 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ec:	83 c4 0c             	add    $0xc,%esp
f01006ef:	68 00 23 11 00       	push   $0x112300
f01006f4:	68 00 23 11 f0       	push   $0xf0112300
f01006f9:	68 84 1c 10 f0       	push   $0xf0101c84
f01006fe:	e8 fe 01 00 00       	call   f0100901 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100703:	83 c4 0c             	add    $0xc,%esp
f0100706:	68 48 29 11 00       	push   $0x112948
f010070b:	68 48 29 11 f0       	push   $0xf0112948
f0100710:	68 a8 1c 10 f0       	push   $0xf0101ca8
f0100715:	e8 e7 01 00 00       	call   f0100901 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010071a:	b8 47 2d 11 f0       	mov    $0xf0112d47,%eax
f010071f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100724:	83 c4 08             	add    $0x8,%esp
f0100727:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010072c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100732:	85 c0                	test   %eax,%eax
f0100734:	0f 48 c2             	cmovs  %edx,%eax
f0100737:	c1 f8 0a             	sar    $0xa,%eax
f010073a:	50                   	push   %eax
f010073b:	68 cc 1c 10 f0       	push   $0xf0101ccc
f0100740:	e8 bc 01 00 00       	call   f0100901 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100745:	b8 00 00 00 00       	mov    $0x0,%eax
f010074a:	c9                   	leave  
f010074b:	c3                   	ret    

f010074c <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010074c:	55                   	push   %ebp
f010074d:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010074f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100754:	5d                   	pop    %ebp
f0100755:	c3                   	ret    

f0100756 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100756:	55                   	push   %ebp
f0100757:	89 e5                	mov    %esp,%ebp
f0100759:	57                   	push   %edi
f010075a:	56                   	push   %esi
f010075b:	53                   	push   %ebx
f010075c:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010075f:	68 f8 1c 10 f0       	push   $0xf0101cf8
f0100764:	e8 98 01 00 00       	call   f0100901 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100769:	c7 04 24 1c 1d 10 f0 	movl   $0xf0101d1c,(%esp)
f0100770:	e8 8c 01 00 00       	call   f0100901 <cprintf>
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");
f0100775:	83 c4 0c             	add    $0xc,%esp
f0100778:	68 8e 1b 10 f0       	push   $0xf0101b8e
f010077d:	68 00 04 00 00       	push   $0x400
f0100782:	68 92 1b 10 f0       	push   $0xf0101b92
f0100787:	68 00 02 00 00       	push   $0x200
f010078c:	68 98 1b 10 f0       	push   $0xf0101b98
f0100791:	68 00 01 00 00       	push   $0x100
f0100796:	68 9d 1b 10 f0       	push   $0xf0101b9d
f010079b:	e8 61 01 00 00       	call   f0100901 <cprintf>
f01007a0:	83 c4 20             	add    $0x20,%esp

	while (1) {
		buf = readline("K> ");
f01007a3:	83 ec 0c             	sub    $0xc,%esp
f01007a6:	68 ad 1b 10 f0       	push   $0xf0101bad
f01007ab:	e8 aa 09 00 00       	call   f010115a <readline>
f01007b0:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007b2:	83 c4 10             	add    $0x10,%esp
f01007b5:	85 c0                	test   %eax,%eax
f01007b7:	74 ea                	je     f01007a3 <monitor+0x4d>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007b9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007c0:	be 00 00 00 00       	mov    $0x0,%esi
f01007c5:	eb 0a                	jmp    f01007d1 <monitor+0x7b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007c7:	c6 03 00             	movb   $0x0,(%ebx)
f01007ca:	89 f7                	mov    %esi,%edi
f01007cc:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007cf:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007d1:	0f b6 03             	movzbl (%ebx),%eax
f01007d4:	84 c0                	test   %al,%al
f01007d6:	74 63                	je     f010083b <monitor+0xe5>
f01007d8:	83 ec 08             	sub    $0x8,%esp
f01007db:	0f be c0             	movsbl %al,%eax
f01007de:	50                   	push   %eax
f01007df:	68 b1 1b 10 f0       	push   $0xf0101bb1
f01007e4:	e8 8b 0b 00 00       	call   f0101374 <strchr>
f01007e9:	83 c4 10             	add    $0x10,%esp
f01007ec:	85 c0                	test   %eax,%eax
f01007ee:	75 d7                	jne    f01007c7 <monitor+0x71>
			*buf++ = 0;
		if (*buf == 0)
f01007f0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007f3:	74 46                	je     f010083b <monitor+0xe5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007f5:	83 fe 0f             	cmp    $0xf,%esi
f01007f8:	75 14                	jne    f010080e <monitor+0xb8>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007fa:	83 ec 08             	sub    $0x8,%esp
f01007fd:	6a 10                	push   $0x10
f01007ff:	68 b6 1b 10 f0       	push   $0xf0101bb6
f0100804:	e8 f8 00 00 00       	call   f0100901 <cprintf>
f0100809:	83 c4 10             	add    $0x10,%esp
f010080c:	eb 95                	jmp    f01007a3 <monitor+0x4d>
			return 0;
		}
		argv[argc++] = buf;
f010080e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100811:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100815:	eb 03                	jmp    f010081a <monitor+0xc4>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100817:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010081a:	0f b6 03             	movzbl (%ebx),%eax
f010081d:	84 c0                	test   %al,%al
f010081f:	74 ae                	je     f01007cf <monitor+0x79>
f0100821:	83 ec 08             	sub    $0x8,%esp
f0100824:	0f be c0             	movsbl %al,%eax
f0100827:	50                   	push   %eax
f0100828:	68 b1 1b 10 f0       	push   $0xf0101bb1
f010082d:	e8 42 0b 00 00       	call   f0101374 <strchr>
f0100832:	83 c4 10             	add    $0x10,%esp
f0100835:	85 c0                	test   %eax,%eax
f0100837:	74 de                	je     f0100817 <monitor+0xc1>
f0100839:	eb 94                	jmp    f01007cf <monitor+0x79>
			buf++;
	}
	argv[argc] = 0;
f010083b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100842:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100843:	85 f6                	test   %esi,%esi
f0100845:	0f 84 58 ff ff ff    	je     f01007a3 <monitor+0x4d>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010084b:	83 ec 08             	sub    $0x8,%esp
f010084e:	68 5e 1b 10 f0       	push   $0xf0101b5e
f0100853:	ff 75 a8             	pushl  -0x58(%ebp)
f0100856:	e8 bb 0a 00 00       	call   f0101316 <strcmp>
f010085b:	83 c4 10             	add    $0x10,%esp
f010085e:	85 c0                	test   %eax,%eax
f0100860:	74 1e                	je     f0100880 <monitor+0x12a>
f0100862:	83 ec 08             	sub    $0x8,%esp
f0100865:	68 6c 1b 10 f0       	push   $0xf0101b6c
f010086a:	ff 75 a8             	pushl  -0x58(%ebp)
f010086d:	e8 a4 0a 00 00       	call   f0101316 <strcmp>
f0100872:	83 c4 10             	add    $0x10,%esp
f0100875:	85 c0                	test   %eax,%eax
f0100877:	75 2f                	jne    f01008a8 <monitor+0x152>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100879:	b8 01 00 00 00       	mov    $0x1,%eax
f010087e:	eb 05                	jmp    f0100885 <monitor+0x12f>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100880:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100885:	83 ec 04             	sub    $0x4,%esp
f0100888:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010088b:	01 d0                	add    %edx,%eax
f010088d:	ff 75 08             	pushl  0x8(%ebp)
f0100890:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100893:	51                   	push   %ecx
f0100894:	56                   	push   %esi
f0100895:	ff 14 85 4c 1d 10 f0 	call   *-0xfefe2b4(,%eax,4)
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010089c:	83 c4 10             	add    $0x10,%esp
f010089f:	85 c0                	test   %eax,%eax
f01008a1:	78 1d                	js     f01008c0 <monitor+0x16a>
f01008a3:	e9 fb fe ff ff       	jmp    f01007a3 <monitor+0x4d>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008a8:	83 ec 08             	sub    $0x8,%esp
f01008ab:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ae:	68 d3 1b 10 f0       	push   $0xf0101bd3
f01008b3:	e8 49 00 00 00       	call   f0100901 <cprintf>
f01008b8:	83 c4 10             	add    $0x10,%esp
f01008bb:	e9 e3 fe ff ff       	jmp    f01007a3 <monitor+0x4d>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008c0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008c3:	5b                   	pop    %ebx
f01008c4:	5e                   	pop    %esi
f01008c5:	5f                   	pop    %edi
f01008c6:	5d                   	pop    %ebp
f01008c7:	c3                   	ret    

f01008c8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008c8:	55                   	push   %ebp
f01008c9:	89 e5                	mov    %esp,%ebp
f01008cb:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008ce:	ff 75 08             	pushl  0x8(%ebp)
f01008d1:	e8 63 fd ff ff       	call   f0100639 <cputchar>
	*cnt++;
}
f01008d6:	83 c4 10             	add    $0x10,%esp
f01008d9:	c9                   	leave  
f01008da:	c3                   	ret    

f01008db <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008db:	55                   	push   %ebp
f01008dc:	89 e5                	mov    %esp,%ebp
f01008de:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01008e1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008e8:	ff 75 0c             	pushl  0xc(%ebp)
f01008eb:	ff 75 08             	pushl  0x8(%ebp)
f01008ee:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008f1:	50                   	push   %eax
f01008f2:	68 c8 08 10 f0       	push   $0xf01008c8
f01008f7:	e8 03 04 00 00       	call   f0100cff <vprintfmt>
	return cnt;
}
f01008fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008ff:	c9                   	leave  
f0100900:	c3                   	ret    

f0100901 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100901:	55                   	push   %ebp
f0100902:	89 e5                	mov    %esp,%ebp
f0100904:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100907:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010090a:	50                   	push   %eax
f010090b:	ff 75 08             	pushl  0x8(%ebp)
f010090e:	e8 c8 ff ff ff       	call   f01008db <vcprintf>
	va_end(ap);

	return cnt;
}
f0100913:	c9                   	leave  
f0100914:	c3                   	ret    

f0100915 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100915:	55                   	push   %ebp
f0100916:	89 e5                	mov    %esp,%ebp
f0100918:	57                   	push   %edi
f0100919:	56                   	push   %esi
f010091a:	53                   	push   %ebx
f010091b:	83 ec 14             	sub    $0x14,%esp
f010091e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100921:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100924:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100927:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010092a:	8b 1a                	mov    (%edx),%ebx
f010092c:	8b 01                	mov    (%ecx),%eax
f010092e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100931:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100938:	eb 7f                	jmp    f01009b9 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010093a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010093d:	01 d8                	add    %ebx,%eax
f010093f:	89 c6                	mov    %eax,%esi
f0100941:	c1 ee 1f             	shr    $0x1f,%esi
f0100944:	01 c6                	add    %eax,%esi
f0100946:	d1 fe                	sar    %esi
f0100948:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010094b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010094e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100951:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100953:	eb 03                	jmp    f0100958 <stab_binsearch+0x43>
			m--;
f0100955:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100958:	39 c3                	cmp    %eax,%ebx
f010095a:	7f 0d                	jg     f0100969 <stab_binsearch+0x54>
f010095c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100960:	83 ea 0c             	sub    $0xc,%edx
f0100963:	39 f9                	cmp    %edi,%ecx
f0100965:	75 ee                	jne    f0100955 <stab_binsearch+0x40>
f0100967:	eb 05                	jmp    f010096e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100969:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010096c:	eb 4b                	jmp    f01009b9 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010096e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100971:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100974:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100978:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010097b:	76 11                	jbe    f010098e <stab_binsearch+0x79>
			*region_left = m;
f010097d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100980:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100982:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100985:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010098c:	eb 2b                	jmp    f01009b9 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010098e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100991:	73 14                	jae    f01009a7 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100993:	83 e8 01             	sub    $0x1,%eax
f0100996:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100999:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010099c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010099e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009a5:	eb 12                	jmp    f01009b9 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009a7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009aa:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01009ac:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01009b0:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009b2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009b9:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009bc:	0f 8e 78 ff ff ff    	jle    f010093a <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009c2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009c6:	75 0f                	jne    f01009d7 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01009c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009cb:	8b 00                	mov    (%eax),%eax
f01009cd:	83 e8 01             	sub    $0x1,%eax
f01009d0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009d3:	89 06                	mov    %eax,(%esi)
f01009d5:	eb 2c                	jmp    f0100a03 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009d7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009da:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009dc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009df:	8b 0e                	mov    (%esi),%ecx
f01009e1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009e4:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01009e7:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ea:	eb 03                	jmp    f01009ef <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009ec:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009ef:	39 c8                	cmp    %ecx,%eax
f01009f1:	7e 0b                	jle    f01009fe <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01009f3:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01009f7:	83 ea 0c             	sub    $0xc,%edx
f01009fa:	39 df                	cmp    %ebx,%edi
f01009fc:	75 ee                	jne    f01009ec <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009fe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a01:	89 06                	mov    %eax,(%esi)
	}
}
f0100a03:	83 c4 14             	add    $0x14,%esp
f0100a06:	5b                   	pop    %ebx
f0100a07:	5e                   	pop    %esi
f0100a08:	5f                   	pop    %edi
f0100a09:	5d                   	pop    %ebp
f0100a0a:	c3                   	ret    

f0100a0b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a0b:	55                   	push   %ebp
f0100a0c:	89 e5                	mov    %esp,%ebp
f0100a0e:	57                   	push   %edi
f0100a0f:	56                   	push   %esi
f0100a10:	53                   	push   %ebx
f0100a11:	83 ec 1c             	sub    $0x1c,%esp
f0100a14:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100a17:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a1a:	c7 06 5c 1d 10 f0    	movl   $0xf0101d5c,(%esi)
	info->eip_line = 0;
f0100a20:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a27:	c7 46 08 5c 1d 10 f0 	movl   $0xf0101d5c,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a2e:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a35:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a38:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a3f:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a45:	76 11                	jbe    f0100a58 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a47:	b8 c1 71 10 f0       	mov    $0xf01071c1,%eax
f0100a4c:	3d bd 58 10 f0       	cmp    $0xf01058bd,%eax
f0100a51:	77 19                	ja     f0100a6c <debuginfo_eip+0x61>
f0100a53:	e9 62 01 00 00       	jmp    f0100bba <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a58:	83 ec 04             	sub    $0x4,%esp
f0100a5b:	68 66 1d 10 f0       	push   $0xf0101d66
f0100a60:	6a 7f                	push   $0x7f
f0100a62:	68 73 1d 10 f0       	push   $0xf0101d73
f0100a67:	e8 7a f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a6c:	80 3d c0 71 10 f0 00 	cmpb   $0x0,0xf01071c0
f0100a73:	0f 85 48 01 00 00    	jne    f0100bc1 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a79:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a80:	b8 bc 58 10 f0       	mov    $0xf01058bc,%eax
f0100a85:	2d b0 1f 10 f0       	sub    $0xf0101fb0,%eax
f0100a8a:	c1 f8 02             	sar    $0x2,%eax
f0100a8d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a93:	83 e8 01             	sub    $0x1,%eax
f0100a96:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a99:	83 ec 08             	sub    $0x8,%esp
f0100a9c:	57                   	push   %edi
f0100a9d:	6a 64                	push   $0x64
f0100a9f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100aa2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100aa5:	b8 b0 1f 10 f0       	mov    $0xf0101fb0,%eax
f0100aaa:	e8 66 fe ff ff       	call   f0100915 <stab_binsearch>
	if (lfile == 0)
f0100aaf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ab2:	83 c4 10             	add    $0x10,%esp
f0100ab5:	85 c0                	test   %eax,%eax
f0100ab7:	0f 84 0b 01 00 00    	je     f0100bc8 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100abd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ac0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ac3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ac6:	83 ec 08             	sub    $0x8,%esp
f0100ac9:	57                   	push   %edi
f0100aca:	6a 24                	push   $0x24
f0100acc:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100acf:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ad2:	b8 b0 1f 10 f0       	mov    $0xf0101fb0,%eax
f0100ad7:	e8 39 fe ff ff       	call   f0100915 <stab_binsearch>

	if (lfun <= rfun) {
f0100adc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100adf:	83 c4 10             	add    $0x10,%esp
f0100ae2:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100ae5:	7f 31                	jg     f0100b18 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ae7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100aea:	c1 e0 02             	shl    $0x2,%eax
f0100aed:	8d 90 b0 1f 10 f0    	lea    -0xfefe050(%eax),%edx
f0100af3:	8b 88 b0 1f 10 f0    	mov    -0xfefe050(%eax),%ecx
f0100af9:	b8 c1 71 10 f0       	mov    $0xf01071c1,%eax
f0100afe:	2d bd 58 10 f0       	sub    $0xf01058bd,%eax
f0100b03:	39 c1                	cmp    %eax,%ecx
f0100b05:	73 09                	jae    f0100b10 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b07:	81 c1 bd 58 10 f0    	add    $0xf01058bd,%ecx
f0100b0d:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b10:	8b 42 08             	mov    0x8(%edx),%eax
f0100b13:	89 46 10             	mov    %eax,0x10(%esi)
f0100b16:	eb 06                	jmp    f0100b1e <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b18:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b1b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b1e:	83 ec 08             	sub    $0x8,%esp
f0100b21:	6a 3a                	push   $0x3a
f0100b23:	ff 76 08             	pushl  0x8(%esi)
f0100b26:	e8 6a 08 00 00       	call   f0101395 <strfind>
f0100b2b:	2b 46 08             	sub    0x8(%esi),%eax
f0100b2e:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b34:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b37:	8d 04 85 b0 1f 10 f0 	lea    -0xfefe050(,%eax,4),%eax
f0100b3e:	83 c4 10             	add    $0x10,%esp
f0100b41:	eb 06                	jmp    f0100b49 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b43:	83 eb 01             	sub    $0x1,%ebx
f0100b46:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b49:	39 fb                	cmp    %edi,%ebx
f0100b4b:	7c 34                	jl     f0100b81 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100b4d:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b51:	80 fa 84             	cmp    $0x84,%dl
f0100b54:	74 0b                	je     f0100b61 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b56:	80 fa 64             	cmp    $0x64,%dl
f0100b59:	75 e8                	jne    f0100b43 <debuginfo_eip+0x138>
f0100b5b:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b5f:	74 e2                	je     f0100b43 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b61:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b64:	8b 14 85 b0 1f 10 f0 	mov    -0xfefe050(,%eax,4),%edx
f0100b6b:	b8 c1 71 10 f0       	mov    $0xf01071c1,%eax
f0100b70:	2d bd 58 10 f0       	sub    $0xf01058bd,%eax
f0100b75:	39 c2                	cmp    %eax,%edx
f0100b77:	73 08                	jae    f0100b81 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b79:	81 c2 bd 58 10 f0    	add    $0xf01058bd,%edx
f0100b7f:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b81:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b84:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b87:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b8c:	39 cb                	cmp    %ecx,%ebx
f0100b8e:	7d 44                	jge    f0100bd4 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100b90:	8d 53 01             	lea    0x1(%ebx),%edx
f0100b93:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b96:	8d 04 85 b0 1f 10 f0 	lea    -0xfefe050(,%eax,4),%eax
f0100b9d:	eb 07                	jmp    f0100ba6 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100b9f:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100ba3:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100ba6:	39 ca                	cmp    %ecx,%edx
f0100ba8:	74 25                	je     f0100bcf <debuginfo_eip+0x1c4>
f0100baa:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bad:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bb1:	74 ec                	je     f0100b9f <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bb3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bb8:	eb 1a                	jmp    f0100bd4 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bbf:	eb 13                	jmp    f0100bd4 <debuginfo_eip+0x1c9>
f0100bc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bc6:	eb 0c                	jmp    f0100bd4 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bcd:	eb 05                	jmp    f0100bd4 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bcf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bd4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bd7:	5b                   	pop    %ebx
f0100bd8:	5e                   	pop    %esi
f0100bd9:	5f                   	pop    %edi
f0100bda:	5d                   	pop    %ebp
f0100bdb:	c3                   	ret    

f0100bdc <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bdc:	55                   	push   %ebp
f0100bdd:	89 e5                	mov    %esp,%ebp
f0100bdf:	57                   	push   %edi
f0100be0:	56                   	push   %esi
f0100be1:	53                   	push   %ebx
f0100be2:	83 ec 1c             	sub    $0x1c,%esp
f0100be5:	89 c7                	mov    %eax,%edi
f0100be7:	89 d6                	mov    %edx,%esi
f0100be9:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bec:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100bef:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100bf2:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100bf5:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100bf8:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100bfd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c00:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c03:	39 d3                	cmp    %edx,%ebx
f0100c05:	72 05                	jb     f0100c0c <printnum+0x30>
f0100c07:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100c0a:	77 45                	ja     f0100c51 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c0c:	83 ec 0c             	sub    $0xc,%esp
f0100c0f:	ff 75 18             	pushl  0x18(%ebp)
f0100c12:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c15:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c18:	53                   	push   %ebx
f0100c19:	ff 75 10             	pushl  0x10(%ebp)
f0100c1c:	83 ec 08             	sub    $0x8,%esp
f0100c1f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c22:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c25:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c28:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c2b:	e8 90 09 00 00       	call   f01015c0 <__udivdi3>
f0100c30:	83 c4 18             	add    $0x18,%esp
f0100c33:	52                   	push   %edx
f0100c34:	50                   	push   %eax
f0100c35:	89 f2                	mov    %esi,%edx
f0100c37:	89 f8                	mov    %edi,%eax
f0100c39:	e8 9e ff ff ff       	call   f0100bdc <printnum>
f0100c3e:	83 c4 20             	add    $0x20,%esp
f0100c41:	eb 18                	jmp    f0100c5b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c43:	83 ec 08             	sub    $0x8,%esp
f0100c46:	56                   	push   %esi
f0100c47:	ff 75 18             	pushl  0x18(%ebp)
f0100c4a:	ff d7                	call   *%edi
f0100c4c:	83 c4 10             	add    $0x10,%esp
f0100c4f:	eb 03                	jmp    f0100c54 <printnum+0x78>
f0100c51:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c54:	83 eb 01             	sub    $0x1,%ebx
f0100c57:	85 db                	test   %ebx,%ebx
f0100c59:	7f e8                	jg     f0100c43 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c5b:	83 ec 08             	sub    $0x8,%esp
f0100c5e:	56                   	push   %esi
f0100c5f:	83 ec 04             	sub    $0x4,%esp
f0100c62:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c65:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c68:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c6b:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c6e:	e8 7d 0a 00 00       	call   f01016f0 <__umoddi3>
f0100c73:	83 c4 14             	add    $0x14,%esp
f0100c76:	0f be 80 81 1d 10 f0 	movsbl -0xfefe27f(%eax),%eax
f0100c7d:	50                   	push   %eax
f0100c7e:	ff d7                	call   *%edi
}
f0100c80:	83 c4 10             	add    $0x10,%esp
f0100c83:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c86:	5b                   	pop    %ebx
f0100c87:	5e                   	pop    %esi
f0100c88:	5f                   	pop    %edi
f0100c89:	5d                   	pop    %ebp
f0100c8a:	c3                   	ret    

f0100c8b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100c8b:	55                   	push   %ebp
f0100c8c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100c8e:	83 fa 01             	cmp    $0x1,%edx
f0100c91:	7e 0e                	jle    f0100ca1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100c93:	8b 10                	mov    (%eax),%edx
f0100c95:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100c98:	89 08                	mov    %ecx,(%eax)
f0100c9a:	8b 02                	mov    (%edx),%eax
f0100c9c:	8b 52 04             	mov    0x4(%edx),%edx
f0100c9f:	eb 22                	jmp    f0100cc3 <getuint+0x38>
	else if (lflag)
f0100ca1:	85 d2                	test   %edx,%edx
f0100ca3:	74 10                	je     f0100cb5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ca5:	8b 10                	mov    (%eax),%edx
f0100ca7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100caa:	89 08                	mov    %ecx,(%eax)
f0100cac:	8b 02                	mov    (%edx),%eax
f0100cae:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cb3:	eb 0e                	jmp    f0100cc3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100cb5:	8b 10                	mov    (%eax),%edx
f0100cb7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100cba:	89 08                	mov    %ecx,(%eax)
f0100cbc:	8b 02                	mov    (%edx),%eax
f0100cbe:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100cc3:	5d                   	pop    %ebp
f0100cc4:	c3                   	ret    

f0100cc5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cc5:	55                   	push   %ebp
f0100cc6:	89 e5                	mov    %esp,%ebp
f0100cc8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ccb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ccf:	8b 10                	mov    (%eax),%edx
f0100cd1:	3b 50 04             	cmp    0x4(%eax),%edx
f0100cd4:	73 0a                	jae    f0100ce0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100cd6:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100cd9:	89 08                	mov    %ecx,(%eax)
f0100cdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cde:	88 02                	mov    %al,(%edx)
}
f0100ce0:	5d                   	pop    %ebp
f0100ce1:	c3                   	ret    

f0100ce2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ce2:	55                   	push   %ebp
f0100ce3:	89 e5                	mov    %esp,%ebp
f0100ce5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ce8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ceb:	50                   	push   %eax
f0100cec:	ff 75 10             	pushl  0x10(%ebp)
f0100cef:	ff 75 0c             	pushl  0xc(%ebp)
f0100cf2:	ff 75 08             	pushl  0x8(%ebp)
f0100cf5:	e8 05 00 00 00       	call   f0100cff <vprintfmt>
	va_end(ap);
}
f0100cfa:	83 c4 10             	add    $0x10,%esp
f0100cfd:	c9                   	leave  
f0100cfe:	c3                   	ret    

f0100cff <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100cff:	55                   	push   %ebp
f0100d00:	89 e5                	mov    %esp,%ebp
f0100d02:	57                   	push   %edi
f0100d03:	56                   	push   %esi
f0100d04:	53                   	push   %ebx
f0100d05:	83 ec 2c             	sub    $0x2c,%esp
f0100d08:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d0b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d0e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d11:	eb 1d                	jmp    f0100d30 <vprintfmt+0x31>
	
	//textcolor = 0x0700;		//black on write

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d13:	85 c0                	test   %eax,%eax
f0100d15:	75 0f                	jne    f0100d26 <vprintfmt+0x27>
			{
				textcolor = 0x0700;
f0100d17:	c7 05 44 29 11 f0 00 	movl   $0x700,0xf0112944
f0100d1e:	07 00 00 
				return;
f0100d21:	e9 c4 03 00 00       	jmp    f01010ea <vprintfmt+0x3eb>
			}
			putch(ch, putdat);
f0100d26:	83 ec 08             	sub    $0x8,%esp
f0100d29:	53                   	push   %ebx
f0100d2a:	50                   	push   %eax
f0100d2b:	ff d6                	call   *%esi
f0100d2d:	83 c4 10             	add    $0x10,%esp
	char padc;
	
	//textcolor = 0x0700;		//black on write

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d30:	83 c7 01             	add    $0x1,%edi
f0100d33:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d37:	83 f8 25             	cmp    $0x25,%eax
f0100d3a:	75 d7                	jne    f0100d13 <vprintfmt+0x14>
f0100d3c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d40:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100d47:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d4e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100d55:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d5a:	eb 07                	jmp    f0100d63 <vprintfmt+0x64>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d5c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d5f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d63:	8d 47 01             	lea    0x1(%edi),%eax
f0100d66:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d69:	0f b6 07             	movzbl (%edi),%eax
f0100d6c:	0f b6 c8             	movzbl %al,%ecx
f0100d6f:	83 e8 23             	sub    $0x23,%eax
f0100d72:	3c 55                	cmp    $0x55,%al
f0100d74:	0f 87 55 03 00 00    	ja     f01010cf <vprintfmt+0x3d0>
f0100d7a:	0f b6 c0             	movzbl %al,%eax
f0100d7d:	ff 24 85 20 1e 10 f0 	jmp    *-0xfefe1e0(,%eax,4)
f0100d84:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d87:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d8b:	eb d6                	jmp    f0100d63 <vprintfmt+0x64>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d95:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100d98:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d9b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100d9f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100da2:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100da5:	83 fa 09             	cmp    $0x9,%edx
f0100da8:	77 39                	ja     f0100de3 <vprintfmt+0xe4>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100daa:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100dad:	eb e9                	jmp    f0100d98 <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100daf:	8b 45 14             	mov    0x14(%ebp),%eax
f0100db2:	8d 48 04             	lea    0x4(%eax),%ecx
f0100db5:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100db8:	8b 00                	mov    (%eax),%eax
f0100dba:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dbd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100dc0:	eb 27                	jmp    f0100de9 <vprintfmt+0xea>
f0100dc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dc5:	85 c0                	test   %eax,%eax
f0100dc7:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100dcc:	0f 49 c8             	cmovns %eax,%ecx
f0100dcf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dd2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100dd5:	eb 8c                	jmp    f0100d63 <vprintfmt+0x64>
f0100dd7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100dda:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100de1:	eb 80                	jmp    f0100d63 <vprintfmt+0x64>
f0100de3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100de6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100de9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ded:	0f 89 70 ff ff ff    	jns    f0100d63 <vprintfmt+0x64>
				width = precision, precision = -1;
f0100df3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100df6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100df9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e00:	e9 5e ff ff ff       	jmp    f0100d63 <vprintfmt+0x64>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e05:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e0b:	e9 53 ff ff ff       	jmp    f0100d63 <vprintfmt+0x64>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100e10:	83 fa 01             	cmp    $0x1,%edx
f0100e13:	7e 0d                	jle    f0100e22 <vprintfmt+0x123>
		return va_arg(*ap, long long);
f0100e15:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e18:	8d 50 08             	lea    0x8(%eax),%edx
f0100e1b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e1e:	8b 00                	mov    (%eax),%eax
f0100e20:	eb 1c                	jmp    f0100e3e <vprintfmt+0x13f>
	else if (lflag)
f0100e22:	85 d2                	test   %edx,%edx
f0100e24:	74 0d                	je     f0100e33 <vprintfmt+0x134>
		return va_arg(*ap, long);
f0100e26:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e29:	8d 50 04             	lea    0x4(%eax),%edx
f0100e2c:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e2f:	8b 00                	mov    (%eax),%eax
f0100e31:	eb 0b                	jmp    f0100e3e <vprintfmt+0x13f>
	else
		return va_arg(*ap, int);
f0100e33:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e36:	8d 50 04             	lea    0x4(%eax),%edx
f0100e39:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e3c:	8b 00                	mov    (%eax),%eax
			goto reswitch;

		// text color
		case 'm':
			num = getint(&ap, lflag);
			textcolor = num;
f0100e3e:	a3 44 29 11 f0       	mov    %eax,0xf0112944
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e43:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// text color
		case 'm':
			num = getint(&ap, lflag);
			textcolor = num;
			break;
f0100e46:	e9 e5 fe ff ff       	jmp    f0100d30 <vprintfmt+0x31>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e4e:	8d 50 04             	lea    0x4(%eax),%edx
f0100e51:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e54:	83 ec 08             	sub    $0x8,%esp
f0100e57:	53                   	push   %ebx
f0100e58:	ff 30                	pushl  (%eax)
f0100e5a:	ff d6                	call   *%esi
			break;
f0100e5c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e62:	e9 c9 fe ff ff       	jmp    f0100d30 <vprintfmt+0x31>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e67:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e6a:	8d 50 04             	lea    0x4(%eax),%edx
f0100e6d:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e70:	8b 00                	mov    (%eax),%eax
f0100e72:	99                   	cltd   
f0100e73:	31 d0                	xor    %edx,%eax
f0100e75:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e77:	83 f8 07             	cmp    $0x7,%eax
f0100e7a:	7f 0b                	jg     f0100e87 <vprintfmt+0x188>
f0100e7c:	8b 14 85 80 1f 10 f0 	mov    -0xfefe080(,%eax,4),%edx
f0100e83:	85 d2                	test   %edx,%edx
f0100e85:	75 18                	jne    f0100e9f <vprintfmt+0x1a0>
				printfmt(putch, putdat, "error %d", err);
f0100e87:	50                   	push   %eax
f0100e88:	68 99 1d 10 f0       	push   $0xf0101d99
f0100e8d:	53                   	push   %ebx
f0100e8e:	56                   	push   %esi
f0100e8f:	e8 4e fe ff ff       	call   f0100ce2 <printfmt>
f0100e94:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e9a:	e9 91 fe ff ff       	jmp    f0100d30 <vprintfmt+0x31>
			else
				printfmt(putch, putdat, "%s", p);
f0100e9f:	52                   	push   %edx
f0100ea0:	68 a2 1d 10 f0       	push   $0xf0101da2
f0100ea5:	53                   	push   %ebx
f0100ea6:	56                   	push   %esi
f0100ea7:	e8 36 fe ff ff       	call   f0100ce2 <printfmt>
f0100eac:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eaf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eb2:	e9 79 fe ff ff       	jmp    f0100d30 <vprintfmt+0x31>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100eb7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eba:	8d 50 04             	lea    0x4(%eax),%edx
f0100ebd:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec0:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100ec2:	85 ff                	test   %edi,%edi
f0100ec4:	b8 92 1d 10 f0       	mov    $0xf0101d92,%eax
f0100ec9:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100ecc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ed0:	0f 8e 94 00 00 00    	jle    f0100f6a <vprintfmt+0x26b>
f0100ed6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100eda:	0f 84 98 00 00 00    	je     f0100f78 <vprintfmt+0x279>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ee0:	83 ec 08             	sub    $0x8,%esp
f0100ee3:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ee6:	57                   	push   %edi
f0100ee7:	e8 5f 03 00 00       	call   f010124b <strnlen>
f0100eec:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100eef:	29 c1                	sub    %eax,%ecx
f0100ef1:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100ef4:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100ef7:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100efb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100efe:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f01:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f03:	eb 0f                	jmp    f0100f14 <vprintfmt+0x215>
					putch(padc, putdat);
f0100f05:	83 ec 08             	sub    $0x8,%esp
f0100f08:	53                   	push   %ebx
f0100f09:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f0c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f0e:	83 ef 01             	sub    $0x1,%edi
f0100f11:	83 c4 10             	add    $0x10,%esp
f0100f14:	85 ff                	test   %edi,%edi
f0100f16:	7f ed                	jg     f0100f05 <vprintfmt+0x206>
f0100f18:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f1b:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f1e:	85 c9                	test   %ecx,%ecx
f0100f20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f25:	0f 49 c1             	cmovns %ecx,%eax
f0100f28:	29 c1                	sub    %eax,%ecx
f0100f2a:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f2d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f30:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f33:	89 cb                	mov    %ecx,%ebx
f0100f35:	eb 4d                	jmp    f0100f84 <vprintfmt+0x285>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f37:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f3b:	74 1b                	je     f0100f58 <vprintfmt+0x259>
f0100f3d:	0f be c0             	movsbl %al,%eax
f0100f40:	83 e8 20             	sub    $0x20,%eax
f0100f43:	83 f8 5e             	cmp    $0x5e,%eax
f0100f46:	76 10                	jbe    f0100f58 <vprintfmt+0x259>
					putch('?', putdat);
f0100f48:	83 ec 08             	sub    $0x8,%esp
f0100f4b:	ff 75 0c             	pushl  0xc(%ebp)
f0100f4e:	6a 3f                	push   $0x3f
f0100f50:	ff 55 08             	call   *0x8(%ebp)
f0100f53:	83 c4 10             	add    $0x10,%esp
f0100f56:	eb 0d                	jmp    f0100f65 <vprintfmt+0x266>
				else
					putch(ch, putdat);
f0100f58:	83 ec 08             	sub    $0x8,%esp
f0100f5b:	ff 75 0c             	pushl  0xc(%ebp)
f0100f5e:	52                   	push   %edx
f0100f5f:	ff 55 08             	call   *0x8(%ebp)
f0100f62:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f65:	83 eb 01             	sub    $0x1,%ebx
f0100f68:	eb 1a                	jmp    f0100f84 <vprintfmt+0x285>
f0100f6a:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f6d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f70:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f73:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f76:	eb 0c                	jmp    f0100f84 <vprintfmt+0x285>
f0100f78:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f7b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f7e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f81:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f84:	83 c7 01             	add    $0x1,%edi
f0100f87:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100f8b:	0f be d0             	movsbl %al,%edx
f0100f8e:	85 d2                	test   %edx,%edx
f0100f90:	74 23                	je     f0100fb5 <vprintfmt+0x2b6>
f0100f92:	85 f6                	test   %esi,%esi
f0100f94:	78 a1                	js     f0100f37 <vprintfmt+0x238>
f0100f96:	83 ee 01             	sub    $0x1,%esi
f0100f99:	79 9c                	jns    f0100f37 <vprintfmt+0x238>
f0100f9b:	89 df                	mov    %ebx,%edi
f0100f9d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fa0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fa3:	eb 18                	jmp    f0100fbd <vprintfmt+0x2be>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100fa5:	83 ec 08             	sub    $0x8,%esp
f0100fa8:	53                   	push   %ebx
f0100fa9:	6a 20                	push   $0x20
f0100fab:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fad:	83 ef 01             	sub    $0x1,%edi
f0100fb0:	83 c4 10             	add    $0x10,%esp
f0100fb3:	eb 08                	jmp    f0100fbd <vprintfmt+0x2be>
f0100fb5:	89 df                	mov    %ebx,%edi
f0100fb7:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fbd:	85 ff                	test   %edi,%edi
f0100fbf:	7f e4                	jg     f0100fa5 <vprintfmt+0x2a6>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fc4:	e9 67 fd ff ff       	jmp    f0100d30 <vprintfmt+0x31>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fc9:	83 fa 01             	cmp    $0x1,%edx
f0100fcc:	7e 16                	jle    f0100fe4 <vprintfmt+0x2e5>
		return va_arg(*ap, long long);
f0100fce:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd1:	8d 50 08             	lea    0x8(%eax),%edx
f0100fd4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fd7:	8b 50 04             	mov    0x4(%eax),%edx
f0100fda:	8b 00                	mov    (%eax),%eax
f0100fdc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fdf:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100fe2:	eb 32                	jmp    f0101016 <vprintfmt+0x317>
	else if (lflag)
f0100fe4:	85 d2                	test   %edx,%edx
f0100fe6:	74 18                	je     f0101000 <vprintfmt+0x301>
		return va_arg(*ap, long);
f0100fe8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100feb:	8d 50 04             	lea    0x4(%eax),%edx
f0100fee:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ff1:	8b 00                	mov    (%eax),%eax
f0100ff3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ff6:	89 c1                	mov    %eax,%ecx
f0100ff8:	c1 f9 1f             	sar    $0x1f,%ecx
f0100ffb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100ffe:	eb 16                	jmp    f0101016 <vprintfmt+0x317>
	else
		return va_arg(*ap, int);
f0101000:	8b 45 14             	mov    0x14(%ebp),%eax
f0101003:	8d 50 04             	lea    0x4(%eax),%edx
f0101006:	89 55 14             	mov    %edx,0x14(%ebp)
f0101009:	8b 00                	mov    (%eax),%eax
f010100b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010100e:	89 c1                	mov    %eax,%ecx
f0101010:	c1 f9 1f             	sar    $0x1f,%ecx
f0101013:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101016:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101019:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010101c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101021:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101025:	79 74                	jns    f010109b <vprintfmt+0x39c>
				putch('-', putdat);
f0101027:	83 ec 08             	sub    $0x8,%esp
f010102a:	53                   	push   %ebx
f010102b:	6a 2d                	push   $0x2d
f010102d:	ff d6                	call   *%esi
				num = -(long long) num;
f010102f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101032:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101035:	f7 d8                	neg    %eax
f0101037:	83 d2 00             	adc    $0x0,%edx
f010103a:	f7 da                	neg    %edx
f010103c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010103f:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101044:	eb 55                	jmp    f010109b <vprintfmt+0x39c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101046:	8d 45 14             	lea    0x14(%ebp),%eax
f0101049:	e8 3d fc ff ff       	call   f0100c8b <getuint>
			base = 10;
f010104e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101053:	eb 46                	jmp    f010109b <vprintfmt+0x39c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101055:	8d 45 14             	lea    0x14(%ebp),%eax
f0101058:	e8 2e fc ff ff       	call   f0100c8b <getuint>
			base = 8;
f010105d:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101062:	eb 37                	jmp    f010109b <vprintfmt+0x39c>

		// pointer
		case 'p':
			putch('0', putdat);
f0101064:	83 ec 08             	sub    $0x8,%esp
f0101067:	53                   	push   %ebx
f0101068:	6a 30                	push   $0x30
f010106a:	ff d6                	call   *%esi
			putch('x', putdat);
f010106c:	83 c4 08             	add    $0x8,%esp
f010106f:	53                   	push   %ebx
f0101070:	6a 78                	push   $0x78
f0101072:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101074:	8b 45 14             	mov    0x14(%ebp),%eax
f0101077:	8d 50 04             	lea    0x4(%eax),%edx
f010107a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010107d:	8b 00                	mov    (%eax),%eax
f010107f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101084:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101087:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010108c:	eb 0d                	jmp    f010109b <vprintfmt+0x39c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010108e:	8d 45 14             	lea    0x14(%ebp),%eax
f0101091:	e8 f5 fb ff ff       	call   f0100c8b <getuint>
			base = 16;
f0101096:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010109b:	83 ec 0c             	sub    $0xc,%esp
f010109e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01010a2:	57                   	push   %edi
f01010a3:	ff 75 e0             	pushl  -0x20(%ebp)
f01010a6:	51                   	push   %ecx
f01010a7:	52                   	push   %edx
f01010a8:	50                   	push   %eax
f01010a9:	89 da                	mov    %ebx,%edx
f01010ab:	89 f0                	mov    %esi,%eax
f01010ad:	e8 2a fb ff ff       	call   f0100bdc <printnum>
			break;
f01010b2:	83 c4 20             	add    $0x20,%esp
f01010b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010b8:	e9 73 fc ff ff       	jmp    f0100d30 <vprintfmt+0x31>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01010bd:	83 ec 08             	sub    $0x8,%esp
f01010c0:	53                   	push   %ebx
f01010c1:	51                   	push   %ecx
f01010c2:	ff d6                	call   *%esi
			break;
f01010c4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01010ca:	e9 61 fc ff ff       	jmp    f0100d30 <vprintfmt+0x31>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01010cf:	83 ec 08             	sub    $0x8,%esp
f01010d2:	53                   	push   %ebx
f01010d3:	6a 25                	push   $0x25
f01010d5:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01010d7:	83 c4 10             	add    $0x10,%esp
f01010da:	eb 03                	jmp    f01010df <vprintfmt+0x3e0>
f01010dc:	83 ef 01             	sub    $0x1,%edi
f01010df:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01010e3:	75 f7                	jne    f01010dc <vprintfmt+0x3dd>
f01010e5:	e9 46 fc ff ff       	jmp    f0100d30 <vprintfmt+0x31>
				/* do nothing */;
			break;
		}
	}
}
f01010ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010ed:	5b                   	pop    %ebx
f01010ee:	5e                   	pop    %esi
f01010ef:	5f                   	pop    %edi
f01010f0:	5d                   	pop    %ebp
f01010f1:	c3                   	ret    

f01010f2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01010f2:	55                   	push   %ebp
f01010f3:	89 e5                	mov    %esp,%ebp
f01010f5:	83 ec 18             	sub    $0x18,%esp
f01010f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01010fb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01010fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101101:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101105:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101108:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010110f:	85 c0                	test   %eax,%eax
f0101111:	74 26                	je     f0101139 <vsnprintf+0x47>
f0101113:	85 d2                	test   %edx,%edx
f0101115:	7e 22                	jle    f0101139 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101117:	ff 75 14             	pushl  0x14(%ebp)
f010111a:	ff 75 10             	pushl  0x10(%ebp)
f010111d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101120:	50                   	push   %eax
f0101121:	68 c5 0c 10 f0       	push   $0xf0100cc5
f0101126:	e8 d4 fb ff ff       	call   f0100cff <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010112b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010112e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101131:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101134:	83 c4 10             	add    $0x10,%esp
f0101137:	eb 05                	jmp    f010113e <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101139:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010113e:	c9                   	leave  
f010113f:	c3                   	ret    

f0101140 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101140:	55                   	push   %ebp
f0101141:	89 e5                	mov    %esp,%ebp
f0101143:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101146:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101149:	50                   	push   %eax
f010114a:	ff 75 10             	pushl  0x10(%ebp)
f010114d:	ff 75 0c             	pushl  0xc(%ebp)
f0101150:	ff 75 08             	pushl  0x8(%ebp)
f0101153:	e8 9a ff ff ff       	call   f01010f2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101158:	c9                   	leave  
f0101159:	c3                   	ret    

f010115a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010115a:	55                   	push   %ebp
f010115b:	89 e5                	mov    %esp,%ebp
f010115d:	57                   	push   %edi
f010115e:	56                   	push   %esi
f010115f:	53                   	push   %ebx
f0101160:	83 ec 0c             	sub    $0xc,%esp
f0101163:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101166:	85 c0                	test   %eax,%eax
f0101168:	74 11                	je     f010117b <readline+0x21>
		cprintf("%s", prompt);
f010116a:	83 ec 08             	sub    $0x8,%esp
f010116d:	50                   	push   %eax
f010116e:	68 a2 1d 10 f0       	push   $0xf0101da2
f0101173:	e8 89 f7 ff ff       	call   f0100901 <cprintf>
f0101178:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010117b:	83 ec 0c             	sub    $0xc,%esp
f010117e:	6a 00                	push   $0x0
f0101180:	e8 d5 f4 ff ff       	call   f010065a <iscons>
f0101185:	89 c7                	mov    %eax,%edi
f0101187:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010118a:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010118f:	e8 b5 f4 ff ff       	call   f0100649 <getchar>
f0101194:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101196:	85 c0                	test   %eax,%eax
f0101198:	79 18                	jns    f01011b2 <readline+0x58>
			cprintf("read error: %e\n", c);
f010119a:	83 ec 08             	sub    $0x8,%esp
f010119d:	50                   	push   %eax
f010119e:	68 a0 1f 10 f0       	push   $0xf0101fa0
f01011a3:	e8 59 f7 ff ff       	call   f0100901 <cprintf>
			return NULL;
f01011a8:	83 c4 10             	add    $0x10,%esp
f01011ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b0:	eb 79                	jmp    f010122b <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01011b2:	83 f8 08             	cmp    $0x8,%eax
f01011b5:	0f 94 c2             	sete   %dl
f01011b8:	83 f8 7f             	cmp    $0x7f,%eax
f01011bb:	0f 94 c0             	sete   %al
f01011be:	08 c2                	or     %al,%dl
f01011c0:	74 1a                	je     f01011dc <readline+0x82>
f01011c2:	85 f6                	test   %esi,%esi
f01011c4:	7e 16                	jle    f01011dc <readline+0x82>
			if (echoing)
f01011c6:	85 ff                	test   %edi,%edi
f01011c8:	74 0d                	je     f01011d7 <readline+0x7d>
				cputchar('\b');
f01011ca:	83 ec 0c             	sub    $0xc,%esp
f01011cd:	6a 08                	push   $0x8
f01011cf:	e8 65 f4 ff ff       	call   f0100639 <cputchar>
f01011d4:	83 c4 10             	add    $0x10,%esp
			i--;
f01011d7:	83 ee 01             	sub    $0x1,%esi
f01011da:	eb b3                	jmp    f010118f <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01011dc:	83 fb 1f             	cmp    $0x1f,%ebx
f01011df:	7e 23                	jle    f0101204 <readline+0xaa>
f01011e1:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01011e7:	7f 1b                	jg     f0101204 <readline+0xaa>
			if (echoing)
f01011e9:	85 ff                	test   %edi,%edi
f01011eb:	74 0c                	je     f01011f9 <readline+0x9f>
				cputchar(c);
f01011ed:	83 ec 0c             	sub    $0xc,%esp
f01011f0:	53                   	push   %ebx
f01011f1:	e8 43 f4 ff ff       	call   f0100639 <cputchar>
f01011f6:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01011f9:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01011ff:	8d 76 01             	lea    0x1(%esi),%esi
f0101202:	eb 8b                	jmp    f010118f <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101204:	83 fb 0a             	cmp    $0xa,%ebx
f0101207:	74 05                	je     f010120e <readline+0xb4>
f0101209:	83 fb 0d             	cmp    $0xd,%ebx
f010120c:	75 81                	jne    f010118f <readline+0x35>
			if (echoing)
f010120e:	85 ff                	test   %edi,%edi
f0101210:	74 0d                	je     f010121f <readline+0xc5>
				cputchar('\n');
f0101212:	83 ec 0c             	sub    $0xc,%esp
f0101215:	6a 0a                	push   $0xa
f0101217:	e8 1d f4 ff ff       	call   f0100639 <cputchar>
f010121c:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010121f:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101226:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f010122b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010122e:	5b                   	pop    %ebx
f010122f:	5e                   	pop    %esi
f0101230:	5f                   	pop    %edi
f0101231:	5d                   	pop    %ebp
f0101232:	c3                   	ret    

f0101233 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101233:	55                   	push   %ebp
f0101234:	89 e5                	mov    %esp,%ebp
f0101236:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101239:	b8 00 00 00 00       	mov    $0x0,%eax
f010123e:	eb 03                	jmp    f0101243 <strlen+0x10>
		n++;
f0101240:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101243:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101247:	75 f7                	jne    f0101240 <strlen+0xd>
		n++;
	return n;
}
f0101249:	5d                   	pop    %ebp
f010124a:	c3                   	ret    

f010124b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010124b:	55                   	push   %ebp
f010124c:	89 e5                	mov    %esp,%ebp
f010124e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101251:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101254:	ba 00 00 00 00       	mov    $0x0,%edx
f0101259:	eb 03                	jmp    f010125e <strnlen+0x13>
		n++;
f010125b:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010125e:	39 c2                	cmp    %eax,%edx
f0101260:	74 08                	je     f010126a <strnlen+0x1f>
f0101262:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101266:	75 f3                	jne    f010125b <strnlen+0x10>
f0101268:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010126a:	5d                   	pop    %ebp
f010126b:	c3                   	ret    

f010126c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010126c:	55                   	push   %ebp
f010126d:	89 e5                	mov    %esp,%ebp
f010126f:	53                   	push   %ebx
f0101270:	8b 45 08             	mov    0x8(%ebp),%eax
f0101273:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101276:	89 c2                	mov    %eax,%edx
f0101278:	83 c2 01             	add    $0x1,%edx
f010127b:	83 c1 01             	add    $0x1,%ecx
f010127e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101282:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101285:	84 db                	test   %bl,%bl
f0101287:	75 ef                	jne    f0101278 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101289:	5b                   	pop    %ebx
f010128a:	5d                   	pop    %ebp
f010128b:	c3                   	ret    

f010128c <strcat>:

char *
strcat(char *dst, const char *src)
{
f010128c:	55                   	push   %ebp
f010128d:	89 e5                	mov    %esp,%ebp
f010128f:	53                   	push   %ebx
f0101290:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101293:	53                   	push   %ebx
f0101294:	e8 9a ff ff ff       	call   f0101233 <strlen>
f0101299:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010129c:	ff 75 0c             	pushl  0xc(%ebp)
f010129f:	01 d8                	add    %ebx,%eax
f01012a1:	50                   	push   %eax
f01012a2:	e8 c5 ff ff ff       	call   f010126c <strcpy>
	return dst;
}
f01012a7:	89 d8                	mov    %ebx,%eax
f01012a9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012ac:	c9                   	leave  
f01012ad:	c3                   	ret    

f01012ae <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01012ae:	55                   	push   %ebp
f01012af:	89 e5                	mov    %esp,%ebp
f01012b1:	56                   	push   %esi
f01012b2:	53                   	push   %ebx
f01012b3:	8b 75 08             	mov    0x8(%ebp),%esi
f01012b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012b9:	89 f3                	mov    %esi,%ebx
f01012bb:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012be:	89 f2                	mov    %esi,%edx
f01012c0:	eb 0f                	jmp    f01012d1 <strncpy+0x23>
		*dst++ = *src;
f01012c2:	83 c2 01             	add    $0x1,%edx
f01012c5:	0f b6 01             	movzbl (%ecx),%eax
f01012c8:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01012cb:	80 39 01             	cmpb   $0x1,(%ecx)
f01012ce:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012d1:	39 da                	cmp    %ebx,%edx
f01012d3:	75 ed                	jne    f01012c2 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01012d5:	89 f0                	mov    %esi,%eax
f01012d7:	5b                   	pop    %ebx
f01012d8:	5e                   	pop    %esi
f01012d9:	5d                   	pop    %ebp
f01012da:	c3                   	ret    

f01012db <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01012db:	55                   	push   %ebp
f01012dc:	89 e5                	mov    %esp,%ebp
f01012de:	56                   	push   %esi
f01012df:	53                   	push   %ebx
f01012e0:	8b 75 08             	mov    0x8(%ebp),%esi
f01012e3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012e6:	8b 55 10             	mov    0x10(%ebp),%edx
f01012e9:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01012eb:	85 d2                	test   %edx,%edx
f01012ed:	74 21                	je     f0101310 <strlcpy+0x35>
f01012ef:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01012f3:	89 f2                	mov    %esi,%edx
f01012f5:	eb 09                	jmp    f0101300 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01012f7:	83 c2 01             	add    $0x1,%edx
f01012fa:	83 c1 01             	add    $0x1,%ecx
f01012fd:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101300:	39 c2                	cmp    %eax,%edx
f0101302:	74 09                	je     f010130d <strlcpy+0x32>
f0101304:	0f b6 19             	movzbl (%ecx),%ebx
f0101307:	84 db                	test   %bl,%bl
f0101309:	75 ec                	jne    f01012f7 <strlcpy+0x1c>
f010130b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010130d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101310:	29 f0                	sub    %esi,%eax
}
f0101312:	5b                   	pop    %ebx
f0101313:	5e                   	pop    %esi
f0101314:	5d                   	pop    %ebp
f0101315:	c3                   	ret    

f0101316 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101316:	55                   	push   %ebp
f0101317:	89 e5                	mov    %esp,%ebp
f0101319:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010131c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010131f:	eb 06                	jmp    f0101327 <strcmp+0x11>
		p++, q++;
f0101321:	83 c1 01             	add    $0x1,%ecx
f0101324:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101327:	0f b6 01             	movzbl (%ecx),%eax
f010132a:	84 c0                	test   %al,%al
f010132c:	74 04                	je     f0101332 <strcmp+0x1c>
f010132e:	3a 02                	cmp    (%edx),%al
f0101330:	74 ef                	je     f0101321 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101332:	0f b6 c0             	movzbl %al,%eax
f0101335:	0f b6 12             	movzbl (%edx),%edx
f0101338:	29 d0                	sub    %edx,%eax
}
f010133a:	5d                   	pop    %ebp
f010133b:	c3                   	ret    

f010133c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010133c:	55                   	push   %ebp
f010133d:	89 e5                	mov    %esp,%ebp
f010133f:	53                   	push   %ebx
f0101340:	8b 45 08             	mov    0x8(%ebp),%eax
f0101343:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101346:	89 c3                	mov    %eax,%ebx
f0101348:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010134b:	eb 06                	jmp    f0101353 <strncmp+0x17>
		n--, p++, q++;
f010134d:	83 c0 01             	add    $0x1,%eax
f0101350:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101353:	39 d8                	cmp    %ebx,%eax
f0101355:	74 15                	je     f010136c <strncmp+0x30>
f0101357:	0f b6 08             	movzbl (%eax),%ecx
f010135a:	84 c9                	test   %cl,%cl
f010135c:	74 04                	je     f0101362 <strncmp+0x26>
f010135e:	3a 0a                	cmp    (%edx),%cl
f0101360:	74 eb                	je     f010134d <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101362:	0f b6 00             	movzbl (%eax),%eax
f0101365:	0f b6 12             	movzbl (%edx),%edx
f0101368:	29 d0                	sub    %edx,%eax
f010136a:	eb 05                	jmp    f0101371 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010136c:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101371:	5b                   	pop    %ebx
f0101372:	5d                   	pop    %ebp
f0101373:	c3                   	ret    

f0101374 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101374:	55                   	push   %ebp
f0101375:	89 e5                	mov    %esp,%ebp
f0101377:	8b 45 08             	mov    0x8(%ebp),%eax
f010137a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010137e:	eb 07                	jmp    f0101387 <strchr+0x13>
		if (*s == c)
f0101380:	38 ca                	cmp    %cl,%dl
f0101382:	74 0f                	je     f0101393 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101384:	83 c0 01             	add    $0x1,%eax
f0101387:	0f b6 10             	movzbl (%eax),%edx
f010138a:	84 d2                	test   %dl,%dl
f010138c:	75 f2                	jne    f0101380 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010138e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101393:	5d                   	pop    %ebp
f0101394:	c3                   	ret    

f0101395 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101395:	55                   	push   %ebp
f0101396:	89 e5                	mov    %esp,%ebp
f0101398:	8b 45 08             	mov    0x8(%ebp),%eax
f010139b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010139f:	eb 03                	jmp    f01013a4 <strfind+0xf>
f01013a1:	83 c0 01             	add    $0x1,%eax
f01013a4:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01013a7:	38 ca                	cmp    %cl,%dl
f01013a9:	74 04                	je     f01013af <strfind+0x1a>
f01013ab:	84 d2                	test   %dl,%dl
f01013ad:	75 f2                	jne    f01013a1 <strfind+0xc>
			break;
	return (char *) s;
}
f01013af:	5d                   	pop    %ebp
f01013b0:	c3                   	ret    

f01013b1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01013b1:	55                   	push   %ebp
f01013b2:	89 e5                	mov    %esp,%ebp
f01013b4:	57                   	push   %edi
f01013b5:	56                   	push   %esi
f01013b6:	53                   	push   %ebx
f01013b7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013ba:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01013bd:	85 c9                	test   %ecx,%ecx
f01013bf:	74 36                	je     f01013f7 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01013c1:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01013c7:	75 28                	jne    f01013f1 <memset+0x40>
f01013c9:	f6 c1 03             	test   $0x3,%cl
f01013cc:	75 23                	jne    f01013f1 <memset+0x40>
		c &= 0xFF;
f01013ce:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01013d2:	89 d3                	mov    %edx,%ebx
f01013d4:	c1 e3 08             	shl    $0x8,%ebx
f01013d7:	89 d6                	mov    %edx,%esi
f01013d9:	c1 e6 18             	shl    $0x18,%esi
f01013dc:	89 d0                	mov    %edx,%eax
f01013de:	c1 e0 10             	shl    $0x10,%eax
f01013e1:	09 f0                	or     %esi,%eax
f01013e3:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01013e5:	89 d8                	mov    %ebx,%eax
f01013e7:	09 d0                	or     %edx,%eax
f01013e9:	c1 e9 02             	shr    $0x2,%ecx
f01013ec:	fc                   	cld    
f01013ed:	f3 ab                	rep stos %eax,%es:(%edi)
f01013ef:	eb 06                	jmp    f01013f7 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01013f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013f4:	fc                   	cld    
f01013f5:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01013f7:	89 f8                	mov    %edi,%eax
f01013f9:	5b                   	pop    %ebx
f01013fa:	5e                   	pop    %esi
f01013fb:	5f                   	pop    %edi
f01013fc:	5d                   	pop    %ebp
f01013fd:	c3                   	ret    

f01013fe <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01013fe:	55                   	push   %ebp
f01013ff:	89 e5                	mov    %esp,%ebp
f0101401:	57                   	push   %edi
f0101402:	56                   	push   %esi
f0101403:	8b 45 08             	mov    0x8(%ebp),%eax
f0101406:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101409:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010140c:	39 c6                	cmp    %eax,%esi
f010140e:	73 35                	jae    f0101445 <memmove+0x47>
f0101410:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101413:	39 d0                	cmp    %edx,%eax
f0101415:	73 2e                	jae    f0101445 <memmove+0x47>
		s += n;
		d += n;
f0101417:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010141a:	89 d6                	mov    %edx,%esi
f010141c:	09 fe                	or     %edi,%esi
f010141e:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101424:	75 13                	jne    f0101439 <memmove+0x3b>
f0101426:	f6 c1 03             	test   $0x3,%cl
f0101429:	75 0e                	jne    f0101439 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010142b:	83 ef 04             	sub    $0x4,%edi
f010142e:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101431:	c1 e9 02             	shr    $0x2,%ecx
f0101434:	fd                   	std    
f0101435:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101437:	eb 09                	jmp    f0101442 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101439:	83 ef 01             	sub    $0x1,%edi
f010143c:	8d 72 ff             	lea    -0x1(%edx),%esi
f010143f:	fd                   	std    
f0101440:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101442:	fc                   	cld    
f0101443:	eb 1d                	jmp    f0101462 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101445:	89 f2                	mov    %esi,%edx
f0101447:	09 c2                	or     %eax,%edx
f0101449:	f6 c2 03             	test   $0x3,%dl
f010144c:	75 0f                	jne    f010145d <memmove+0x5f>
f010144e:	f6 c1 03             	test   $0x3,%cl
f0101451:	75 0a                	jne    f010145d <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101453:	c1 e9 02             	shr    $0x2,%ecx
f0101456:	89 c7                	mov    %eax,%edi
f0101458:	fc                   	cld    
f0101459:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010145b:	eb 05                	jmp    f0101462 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010145d:	89 c7                	mov    %eax,%edi
f010145f:	fc                   	cld    
f0101460:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101462:	5e                   	pop    %esi
f0101463:	5f                   	pop    %edi
f0101464:	5d                   	pop    %ebp
f0101465:	c3                   	ret    

f0101466 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101466:	55                   	push   %ebp
f0101467:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101469:	ff 75 10             	pushl  0x10(%ebp)
f010146c:	ff 75 0c             	pushl  0xc(%ebp)
f010146f:	ff 75 08             	pushl  0x8(%ebp)
f0101472:	e8 87 ff ff ff       	call   f01013fe <memmove>
}
f0101477:	c9                   	leave  
f0101478:	c3                   	ret    

f0101479 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101479:	55                   	push   %ebp
f010147a:	89 e5                	mov    %esp,%ebp
f010147c:	56                   	push   %esi
f010147d:	53                   	push   %ebx
f010147e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101481:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101484:	89 c6                	mov    %eax,%esi
f0101486:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101489:	eb 1a                	jmp    f01014a5 <memcmp+0x2c>
		if (*s1 != *s2)
f010148b:	0f b6 08             	movzbl (%eax),%ecx
f010148e:	0f b6 1a             	movzbl (%edx),%ebx
f0101491:	38 d9                	cmp    %bl,%cl
f0101493:	74 0a                	je     f010149f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101495:	0f b6 c1             	movzbl %cl,%eax
f0101498:	0f b6 db             	movzbl %bl,%ebx
f010149b:	29 d8                	sub    %ebx,%eax
f010149d:	eb 0f                	jmp    f01014ae <memcmp+0x35>
		s1++, s2++;
f010149f:	83 c0 01             	add    $0x1,%eax
f01014a2:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014a5:	39 f0                	cmp    %esi,%eax
f01014a7:	75 e2                	jne    f010148b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01014a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014ae:	5b                   	pop    %ebx
f01014af:	5e                   	pop    %esi
f01014b0:	5d                   	pop    %ebp
f01014b1:	c3                   	ret    

f01014b2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01014b2:	55                   	push   %ebp
f01014b3:	89 e5                	mov    %esp,%ebp
f01014b5:	53                   	push   %ebx
f01014b6:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01014b9:	89 c1                	mov    %eax,%ecx
f01014bb:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01014be:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014c2:	eb 0a                	jmp    f01014ce <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01014c4:	0f b6 10             	movzbl (%eax),%edx
f01014c7:	39 da                	cmp    %ebx,%edx
f01014c9:	74 07                	je     f01014d2 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014cb:	83 c0 01             	add    $0x1,%eax
f01014ce:	39 c8                	cmp    %ecx,%eax
f01014d0:	72 f2                	jb     f01014c4 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01014d2:	5b                   	pop    %ebx
f01014d3:	5d                   	pop    %ebp
f01014d4:	c3                   	ret    

f01014d5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01014d5:	55                   	push   %ebp
f01014d6:	89 e5                	mov    %esp,%ebp
f01014d8:	57                   	push   %edi
f01014d9:	56                   	push   %esi
f01014da:	53                   	push   %ebx
f01014db:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014de:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014e1:	eb 03                	jmp    f01014e6 <strtol+0x11>
		s++;
f01014e3:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014e6:	0f b6 01             	movzbl (%ecx),%eax
f01014e9:	3c 20                	cmp    $0x20,%al
f01014eb:	74 f6                	je     f01014e3 <strtol+0xe>
f01014ed:	3c 09                	cmp    $0x9,%al
f01014ef:	74 f2                	je     f01014e3 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01014f1:	3c 2b                	cmp    $0x2b,%al
f01014f3:	75 0a                	jne    f01014ff <strtol+0x2a>
		s++;
f01014f5:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01014f8:	bf 00 00 00 00       	mov    $0x0,%edi
f01014fd:	eb 11                	jmp    f0101510 <strtol+0x3b>
f01014ff:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101504:	3c 2d                	cmp    $0x2d,%al
f0101506:	75 08                	jne    f0101510 <strtol+0x3b>
		s++, neg = 1;
f0101508:	83 c1 01             	add    $0x1,%ecx
f010150b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101510:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101516:	75 15                	jne    f010152d <strtol+0x58>
f0101518:	80 39 30             	cmpb   $0x30,(%ecx)
f010151b:	75 10                	jne    f010152d <strtol+0x58>
f010151d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101521:	75 7c                	jne    f010159f <strtol+0xca>
		s += 2, base = 16;
f0101523:	83 c1 02             	add    $0x2,%ecx
f0101526:	bb 10 00 00 00       	mov    $0x10,%ebx
f010152b:	eb 16                	jmp    f0101543 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010152d:	85 db                	test   %ebx,%ebx
f010152f:	75 12                	jne    f0101543 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101531:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101536:	80 39 30             	cmpb   $0x30,(%ecx)
f0101539:	75 08                	jne    f0101543 <strtol+0x6e>
		s++, base = 8;
f010153b:	83 c1 01             	add    $0x1,%ecx
f010153e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101543:	b8 00 00 00 00       	mov    $0x0,%eax
f0101548:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010154b:	0f b6 11             	movzbl (%ecx),%edx
f010154e:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101551:	89 f3                	mov    %esi,%ebx
f0101553:	80 fb 09             	cmp    $0x9,%bl
f0101556:	77 08                	ja     f0101560 <strtol+0x8b>
			dig = *s - '0';
f0101558:	0f be d2             	movsbl %dl,%edx
f010155b:	83 ea 30             	sub    $0x30,%edx
f010155e:	eb 22                	jmp    f0101582 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101560:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101563:	89 f3                	mov    %esi,%ebx
f0101565:	80 fb 19             	cmp    $0x19,%bl
f0101568:	77 08                	ja     f0101572 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010156a:	0f be d2             	movsbl %dl,%edx
f010156d:	83 ea 57             	sub    $0x57,%edx
f0101570:	eb 10                	jmp    f0101582 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101572:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101575:	89 f3                	mov    %esi,%ebx
f0101577:	80 fb 19             	cmp    $0x19,%bl
f010157a:	77 16                	ja     f0101592 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010157c:	0f be d2             	movsbl %dl,%edx
f010157f:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101582:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101585:	7d 0b                	jge    f0101592 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101587:	83 c1 01             	add    $0x1,%ecx
f010158a:	0f af 45 10          	imul   0x10(%ebp),%eax
f010158e:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101590:	eb b9                	jmp    f010154b <strtol+0x76>

	if (endptr)
f0101592:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101596:	74 0d                	je     f01015a5 <strtol+0xd0>
		*endptr = (char *) s;
f0101598:	8b 75 0c             	mov    0xc(%ebp),%esi
f010159b:	89 0e                	mov    %ecx,(%esi)
f010159d:	eb 06                	jmp    f01015a5 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010159f:	85 db                	test   %ebx,%ebx
f01015a1:	74 98                	je     f010153b <strtol+0x66>
f01015a3:	eb 9e                	jmp    f0101543 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01015a5:	89 c2                	mov    %eax,%edx
f01015a7:	f7 da                	neg    %edx
f01015a9:	85 ff                	test   %edi,%edi
f01015ab:	0f 45 c2             	cmovne %edx,%eax
}
f01015ae:	5b                   	pop    %ebx
f01015af:	5e                   	pop    %esi
f01015b0:	5f                   	pop    %edi
f01015b1:	5d                   	pop    %ebp
f01015b2:	c3                   	ret    
f01015b3:	66 90                	xchg   %ax,%ax
f01015b5:	66 90                	xchg   %ax,%ax
f01015b7:	66 90                	xchg   %ax,%ax
f01015b9:	66 90                	xchg   %ax,%ax
f01015bb:	66 90                	xchg   %ax,%ax
f01015bd:	66 90                	xchg   %ax,%ax
f01015bf:	90                   	nop

f01015c0 <__udivdi3>:
f01015c0:	55                   	push   %ebp
f01015c1:	57                   	push   %edi
f01015c2:	56                   	push   %esi
f01015c3:	53                   	push   %ebx
f01015c4:	83 ec 1c             	sub    $0x1c,%esp
f01015c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01015cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01015cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01015d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01015d7:	85 f6                	test   %esi,%esi
f01015d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01015dd:	89 ca                	mov    %ecx,%edx
f01015df:	89 f8                	mov    %edi,%eax
f01015e1:	75 3d                	jne    f0101620 <__udivdi3+0x60>
f01015e3:	39 cf                	cmp    %ecx,%edi
f01015e5:	0f 87 c5 00 00 00    	ja     f01016b0 <__udivdi3+0xf0>
f01015eb:	85 ff                	test   %edi,%edi
f01015ed:	89 fd                	mov    %edi,%ebp
f01015ef:	75 0b                	jne    f01015fc <__udivdi3+0x3c>
f01015f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01015f6:	31 d2                	xor    %edx,%edx
f01015f8:	f7 f7                	div    %edi
f01015fa:	89 c5                	mov    %eax,%ebp
f01015fc:	89 c8                	mov    %ecx,%eax
f01015fe:	31 d2                	xor    %edx,%edx
f0101600:	f7 f5                	div    %ebp
f0101602:	89 c1                	mov    %eax,%ecx
f0101604:	89 d8                	mov    %ebx,%eax
f0101606:	89 cf                	mov    %ecx,%edi
f0101608:	f7 f5                	div    %ebp
f010160a:	89 c3                	mov    %eax,%ebx
f010160c:	89 d8                	mov    %ebx,%eax
f010160e:	89 fa                	mov    %edi,%edx
f0101610:	83 c4 1c             	add    $0x1c,%esp
f0101613:	5b                   	pop    %ebx
f0101614:	5e                   	pop    %esi
f0101615:	5f                   	pop    %edi
f0101616:	5d                   	pop    %ebp
f0101617:	c3                   	ret    
f0101618:	90                   	nop
f0101619:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101620:	39 ce                	cmp    %ecx,%esi
f0101622:	77 74                	ja     f0101698 <__udivdi3+0xd8>
f0101624:	0f bd fe             	bsr    %esi,%edi
f0101627:	83 f7 1f             	xor    $0x1f,%edi
f010162a:	0f 84 98 00 00 00    	je     f01016c8 <__udivdi3+0x108>
f0101630:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101635:	89 f9                	mov    %edi,%ecx
f0101637:	89 c5                	mov    %eax,%ebp
f0101639:	29 fb                	sub    %edi,%ebx
f010163b:	d3 e6                	shl    %cl,%esi
f010163d:	89 d9                	mov    %ebx,%ecx
f010163f:	d3 ed                	shr    %cl,%ebp
f0101641:	89 f9                	mov    %edi,%ecx
f0101643:	d3 e0                	shl    %cl,%eax
f0101645:	09 ee                	or     %ebp,%esi
f0101647:	89 d9                	mov    %ebx,%ecx
f0101649:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010164d:	89 d5                	mov    %edx,%ebp
f010164f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101653:	d3 ed                	shr    %cl,%ebp
f0101655:	89 f9                	mov    %edi,%ecx
f0101657:	d3 e2                	shl    %cl,%edx
f0101659:	89 d9                	mov    %ebx,%ecx
f010165b:	d3 e8                	shr    %cl,%eax
f010165d:	09 c2                	or     %eax,%edx
f010165f:	89 d0                	mov    %edx,%eax
f0101661:	89 ea                	mov    %ebp,%edx
f0101663:	f7 f6                	div    %esi
f0101665:	89 d5                	mov    %edx,%ebp
f0101667:	89 c3                	mov    %eax,%ebx
f0101669:	f7 64 24 0c          	mull   0xc(%esp)
f010166d:	39 d5                	cmp    %edx,%ebp
f010166f:	72 10                	jb     f0101681 <__udivdi3+0xc1>
f0101671:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101675:	89 f9                	mov    %edi,%ecx
f0101677:	d3 e6                	shl    %cl,%esi
f0101679:	39 c6                	cmp    %eax,%esi
f010167b:	73 07                	jae    f0101684 <__udivdi3+0xc4>
f010167d:	39 d5                	cmp    %edx,%ebp
f010167f:	75 03                	jne    f0101684 <__udivdi3+0xc4>
f0101681:	83 eb 01             	sub    $0x1,%ebx
f0101684:	31 ff                	xor    %edi,%edi
f0101686:	89 d8                	mov    %ebx,%eax
f0101688:	89 fa                	mov    %edi,%edx
f010168a:	83 c4 1c             	add    $0x1c,%esp
f010168d:	5b                   	pop    %ebx
f010168e:	5e                   	pop    %esi
f010168f:	5f                   	pop    %edi
f0101690:	5d                   	pop    %ebp
f0101691:	c3                   	ret    
f0101692:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101698:	31 ff                	xor    %edi,%edi
f010169a:	31 db                	xor    %ebx,%ebx
f010169c:	89 d8                	mov    %ebx,%eax
f010169e:	89 fa                	mov    %edi,%edx
f01016a0:	83 c4 1c             	add    $0x1c,%esp
f01016a3:	5b                   	pop    %ebx
f01016a4:	5e                   	pop    %esi
f01016a5:	5f                   	pop    %edi
f01016a6:	5d                   	pop    %ebp
f01016a7:	c3                   	ret    
f01016a8:	90                   	nop
f01016a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016b0:	89 d8                	mov    %ebx,%eax
f01016b2:	f7 f7                	div    %edi
f01016b4:	31 ff                	xor    %edi,%edi
f01016b6:	89 c3                	mov    %eax,%ebx
f01016b8:	89 d8                	mov    %ebx,%eax
f01016ba:	89 fa                	mov    %edi,%edx
f01016bc:	83 c4 1c             	add    $0x1c,%esp
f01016bf:	5b                   	pop    %ebx
f01016c0:	5e                   	pop    %esi
f01016c1:	5f                   	pop    %edi
f01016c2:	5d                   	pop    %ebp
f01016c3:	c3                   	ret    
f01016c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01016c8:	39 ce                	cmp    %ecx,%esi
f01016ca:	72 0c                	jb     f01016d8 <__udivdi3+0x118>
f01016cc:	31 db                	xor    %ebx,%ebx
f01016ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01016d2:	0f 87 34 ff ff ff    	ja     f010160c <__udivdi3+0x4c>
f01016d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01016dd:	e9 2a ff ff ff       	jmp    f010160c <__udivdi3+0x4c>
f01016e2:	66 90                	xchg   %ax,%ax
f01016e4:	66 90                	xchg   %ax,%ax
f01016e6:	66 90                	xchg   %ax,%ax
f01016e8:	66 90                	xchg   %ax,%ax
f01016ea:	66 90                	xchg   %ax,%ax
f01016ec:	66 90                	xchg   %ax,%ax
f01016ee:	66 90                	xchg   %ax,%ax

f01016f0 <__umoddi3>:
f01016f0:	55                   	push   %ebp
f01016f1:	57                   	push   %edi
f01016f2:	56                   	push   %esi
f01016f3:	53                   	push   %ebx
f01016f4:	83 ec 1c             	sub    $0x1c,%esp
f01016f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01016fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01016ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101703:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101707:	85 d2                	test   %edx,%edx
f0101709:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010170d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101711:	89 f3                	mov    %esi,%ebx
f0101713:	89 3c 24             	mov    %edi,(%esp)
f0101716:	89 74 24 04          	mov    %esi,0x4(%esp)
f010171a:	75 1c                	jne    f0101738 <__umoddi3+0x48>
f010171c:	39 f7                	cmp    %esi,%edi
f010171e:	76 50                	jbe    f0101770 <__umoddi3+0x80>
f0101720:	89 c8                	mov    %ecx,%eax
f0101722:	89 f2                	mov    %esi,%edx
f0101724:	f7 f7                	div    %edi
f0101726:	89 d0                	mov    %edx,%eax
f0101728:	31 d2                	xor    %edx,%edx
f010172a:	83 c4 1c             	add    $0x1c,%esp
f010172d:	5b                   	pop    %ebx
f010172e:	5e                   	pop    %esi
f010172f:	5f                   	pop    %edi
f0101730:	5d                   	pop    %ebp
f0101731:	c3                   	ret    
f0101732:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101738:	39 f2                	cmp    %esi,%edx
f010173a:	89 d0                	mov    %edx,%eax
f010173c:	77 52                	ja     f0101790 <__umoddi3+0xa0>
f010173e:	0f bd ea             	bsr    %edx,%ebp
f0101741:	83 f5 1f             	xor    $0x1f,%ebp
f0101744:	75 5a                	jne    f01017a0 <__umoddi3+0xb0>
f0101746:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010174a:	0f 82 e0 00 00 00    	jb     f0101830 <__umoddi3+0x140>
f0101750:	39 0c 24             	cmp    %ecx,(%esp)
f0101753:	0f 86 d7 00 00 00    	jbe    f0101830 <__umoddi3+0x140>
f0101759:	8b 44 24 08          	mov    0x8(%esp),%eax
f010175d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101761:	83 c4 1c             	add    $0x1c,%esp
f0101764:	5b                   	pop    %ebx
f0101765:	5e                   	pop    %esi
f0101766:	5f                   	pop    %edi
f0101767:	5d                   	pop    %ebp
f0101768:	c3                   	ret    
f0101769:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101770:	85 ff                	test   %edi,%edi
f0101772:	89 fd                	mov    %edi,%ebp
f0101774:	75 0b                	jne    f0101781 <__umoddi3+0x91>
f0101776:	b8 01 00 00 00       	mov    $0x1,%eax
f010177b:	31 d2                	xor    %edx,%edx
f010177d:	f7 f7                	div    %edi
f010177f:	89 c5                	mov    %eax,%ebp
f0101781:	89 f0                	mov    %esi,%eax
f0101783:	31 d2                	xor    %edx,%edx
f0101785:	f7 f5                	div    %ebp
f0101787:	89 c8                	mov    %ecx,%eax
f0101789:	f7 f5                	div    %ebp
f010178b:	89 d0                	mov    %edx,%eax
f010178d:	eb 99                	jmp    f0101728 <__umoddi3+0x38>
f010178f:	90                   	nop
f0101790:	89 c8                	mov    %ecx,%eax
f0101792:	89 f2                	mov    %esi,%edx
f0101794:	83 c4 1c             	add    $0x1c,%esp
f0101797:	5b                   	pop    %ebx
f0101798:	5e                   	pop    %esi
f0101799:	5f                   	pop    %edi
f010179a:	5d                   	pop    %ebp
f010179b:	c3                   	ret    
f010179c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017a0:	8b 34 24             	mov    (%esp),%esi
f01017a3:	bf 20 00 00 00       	mov    $0x20,%edi
f01017a8:	89 e9                	mov    %ebp,%ecx
f01017aa:	29 ef                	sub    %ebp,%edi
f01017ac:	d3 e0                	shl    %cl,%eax
f01017ae:	89 f9                	mov    %edi,%ecx
f01017b0:	89 f2                	mov    %esi,%edx
f01017b2:	d3 ea                	shr    %cl,%edx
f01017b4:	89 e9                	mov    %ebp,%ecx
f01017b6:	09 c2                	or     %eax,%edx
f01017b8:	89 d8                	mov    %ebx,%eax
f01017ba:	89 14 24             	mov    %edx,(%esp)
f01017bd:	89 f2                	mov    %esi,%edx
f01017bf:	d3 e2                	shl    %cl,%edx
f01017c1:	89 f9                	mov    %edi,%ecx
f01017c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01017c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01017cb:	d3 e8                	shr    %cl,%eax
f01017cd:	89 e9                	mov    %ebp,%ecx
f01017cf:	89 c6                	mov    %eax,%esi
f01017d1:	d3 e3                	shl    %cl,%ebx
f01017d3:	89 f9                	mov    %edi,%ecx
f01017d5:	89 d0                	mov    %edx,%eax
f01017d7:	d3 e8                	shr    %cl,%eax
f01017d9:	89 e9                	mov    %ebp,%ecx
f01017db:	09 d8                	or     %ebx,%eax
f01017dd:	89 d3                	mov    %edx,%ebx
f01017df:	89 f2                	mov    %esi,%edx
f01017e1:	f7 34 24             	divl   (%esp)
f01017e4:	89 d6                	mov    %edx,%esi
f01017e6:	d3 e3                	shl    %cl,%ebx
f01017e8:	f7 64 24 04          	mull   0x4(%esp)
f01017ec:	39 d6                	cmp    %edx,%esi
f01017ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01017f2:	89 d1                	mov    %edx,%ecx
f01017f4:	89 c3                	mov    %eax,%ebx
f01017f6:	72 08                	jb     f0101800 <__umoddi3+0x110>
f01017f8:	75 11                	jne    f010180b <__umoddi3+0x11b>
f01017fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01017fe:	73 0b                	jae    f010180b <__umoddi3+0x11b>
f0101800:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101804:	1b 14 24             	sbb    (%esp),%edx
f0101807:	89 d1                	mov    %edx,%ecx
f0101809:	89 c3                	mov    %eax,%ebx
f010180b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010180f:	29 da                	sub    %ebx,%edx
f0101811:	19 ce                	sbb    %ecx,%esi
f0101813:	89 f9                	mov    %edi,%ecx
f0101815:	89 f0                	mov    %esi,%eax
f0101817:	d3 e0                	shl    %cl,%eax
f0101819:	89 e9                	mov    %ebp,%ecx
f010181b:	d3 ea                	shr    %cl,%edx
f010181d:	89 e9                	mov    %ebp,%ecx
f010181f:	d3 ee                	shr    %cl,%esi
f0101821:	09 d0                	or     %edx,%eax
f0101823:	89 f2                	mov    %esi,%edx
f0101825:	83 c4 1c             	add    $0x1c,%esp
f0101828:	5b                   	pop    %ebx
f0101829:	5e                   	pop    %esi
f010182a:	5f                   	pop    %edi
f010182b:	5d                   	pop    %ebp
f010182c:	c3                   	ret    
f010182d:	8d 76 00             	lea    0x0(%esi),%esi
f0101830:	29 f9                	sub    %edi,%ecx
f0101832:	19 d6                	sbb    %edx,%esi
f0101834:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101838:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010183c:	e9 18 ff ff ff       	jmp    f0101759 <__umoddi3+0x69>
