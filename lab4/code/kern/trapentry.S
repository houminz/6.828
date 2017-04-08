/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
    .data;  \
        .long name; \
    .text;  \
        .globl name;		/* define global symbol for 'name' */	\
    	.type name, @function;	/* symbol type is function */		\
    	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
        .if !(num == 8 || num == 17 || (num >= 10 && num <= 14));   \
        pushl $0;   \
        .endif;     \
    	pushl $(num);							\
    	jmp _alltraps


.data
    .globl  vectors

vectors:


/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
    TRAPHANDLER(vector0, 0)
    TRAPHANDLER(vector1, 1)
    TRAPHANDLER(vector2, 2)
    TRAPHANDLER(vector3, 3)
    TRAPHANDLER(vector4, 4)
    TRAPHANDLER(vector5, 5)
    TRAPHANDLER(vector6, 6)
    TRAPHANDLER(vector7, 7)
    TRAPHANDLER(vector8, 8)
    TRAPHANDLER(vector9, 9)
    TRAPHANDLER(vector10, 10)
    TRAPHANDLER(vector11, 11)
    TRAPHANDLER(vector12, 12)
    TRAPHANDLER(vector13, 13)
    TRAPHANDLER(vector14, 14)
    TRAPHANDLER(vector15, 15)
    TRAPHANDLER(vector16, 16)
    TRAPHANDLER(vector17, 17)
    TRAPHANDLER(vector18, 18)
    TRAPHANDLER(vector19, 19)
    TRAPHANDLER(vector20, 20)
    TRAPHANDLER(vector21, 21)
    TRAPHANDLER(vector22, 22)
    TRAPHANDLER(vector23, 23)
    TRAPHANDLER(vector24, 24)
    TRAPHANDLER(vector25, 25)
    TRAPHANDLER(vector26, 26)
    TRAPHANDLER(vector27, 27)
    TRAPHANDLER(vector28, 28)
    TRAPHANDLER(vector29, 29)
    TRAPHANDLER(vector30, 30)
    TRAPHANDLER(vector31, 31)
    TRAPHANDLER(vector32, 32)
    TRAPHANDLER(vector33, 33)
    TRAPHANDLER(vector34, 34)
    TRAPHANDLER(vector35, 35)
    TRAPHANDLER(vector36, 36)
    TRAPHANDLER(vector37, 37)
    TRAPHANDLER(vector38, 38)
    TRAPHANDLER(vector39, 39)
    TRAPHANDLER(vector40, 40)
    TRAPHANDLER(vector41, 41)
    TRAPHANDLER(vector42, 42)
    TRAPHANDLER(vector43, 43)
    TRAPHANDLER(vector44, 44)
    TRAPHANDLER(vector45, 45)
    TRAPHANDLER(vector46, 46)
    TRAPHANDLER(vector47, 47)
    TRAPHANDLER(vector48, 48)


/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
    pushl %ds;
    pushl %es;
    pushal;
    pushl $GD_KD;
    popl %ds;
    pushl $GD_KD;
    popl %es;
    pushl %esp;
    call trap;
