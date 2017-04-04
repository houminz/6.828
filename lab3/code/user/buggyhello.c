// buggy hello world -- unmapped pointer passed to kernel
// kernel should destroy user environment in response

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	cprintf("thisenv->env_tf.tf_cs: %08x\n", thisenv->env_tf.tf_cs);
	sys_cputs((char*)1, 1);
}
