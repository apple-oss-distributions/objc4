.macro NOP16
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
.endmacro

.macro NOP256
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
	NOP16
.endmacro

.text
	.globl _main

#if __x86_64__
	// Only request 4kB alignment on Intel. It doesn't support any greater
	// alignment anyway, and the linker complains if we ask. rdar://119847439
	.align 12
#else
	.align 14
#endif

_main:
	// at least 1024 instruction bytes on all architectures
	NOP256
	NOP256
	NOP256
	NOP256
