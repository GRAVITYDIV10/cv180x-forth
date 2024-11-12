	.section .init
	.global _start
_start:
	.option norvc;
	j init
	.word 0 // resvered
version:
	.word 0 // BL2 MSID
	.word 0 // BL2 version
	.word 0 //
	.word 0
	.word 0
	.word 0
	#.option rvc;

#define wp t0
#define xp t1
#define yp t2
#define zp t3

#define ap t4
#define bp t5

#define psp s0
#define psb s1
#define rsp s2

	.equ STKSIZE, 128
	.equ TIBSIZE, 0X100

	.section .text
init:
	la wp, reset
	jr wp

	.equ UART0_BASE, 0x04140000
	.equ UART_THR, 0x00
	.equ UART_RBR, 0x00
	.equ UART_DLL, 0x00
	.equ UART_DLH, 0x04
	.equ UART_IIR, 0x08
	.equ UART_FCR, 0x08
	.equ UART_LCR, 0x0C
	.equ UART_LSR, 0x14
	.equ UART_USR, 0x7C

	.equ UART_DR, (1 << 0)
	.equ UART_THRE, (1 << 5)
	.equ UART_TC, (1 << 6)

	.equ UART_FIFO_EN, (1 << 0)
	.equ UART_FIFO_RXCLR, (1 << 1)
	.equ UART_FIFO_TXCLR, (1 << 2)

	.equ UART_DLAB, (1 << 7)
	.equ UART_BUSY, (1 << 0)
early_putc:
	li xp, UART0_BASE
1:
	lw yp, UART_LSR(xp)
	andi yp, yp, UART_THRE
	beqz yp, 1b

	sw wp, UART_THR(xp)
	ret

early_puts:
	mv zp, wp
	li xp, UART0_BASE
2:
1:
	lw yp, UART_LSR(xp)
	andi yp, yp, UART_THRE
	beqz yp, 1b

	lbu yp, 0(zp)
	addi zp, zp, 1
	bnez yp, 1f
	ret
1:
	sw yp, UART_THR(xp)
	j 2b

early_getc:
	li wp, UART0_BASE
1:
	lw xp, UART_LSR(wp)
	andi xp, xp, UART_DR
	beqz xp, 1b
	lw wp, UART_RBR(wp)
	ret

early_puthex:
	li xp, 64
3:
	addi xp, xp, -4
	srl yp, wp, xp
	andi yp, yp, 0xF

	li zp, 0x9
	bgt yp, zp, 1f
	addi yp, yp, '0'
	j 2f
1:
	addi yp, yp, 'A' - 0xA
2:

	li zp, UART0_BASE
	lw zp, UART_LSR(zp)
	andi zp, zp, UART_THRE
	beqz zp, 2b

	li zp, UART0_BASE
	sw yp, UART_THR(zp)

	bnez xp, 3b
	ret

	.equ RSTN_BASE, 0x03003000
	.equ RSTN_SOFT_CPU, 0x24
	.equ RSTN_C906L, (1 << 6)

c906l_enter_reset:
	li wp, RSTN_BASE
	lw xp, RSTN_SOFT_CPU(wp)
	li yp, RSTN_C906L
	xori yp, yp, -1
	and xp, xp, yp
	sw xp, RSTN_SOFT_CPU(wp)
	ret

c906l_leave_reset:
	li wp, RSTN_BASE
        lw xp, RSTN_SOFT_CPU(wp)
        ori xp, xp, RSTN_C906L
        sw xp, RSTN_SOFT_CPU(wp)
        ret

	.equ SEC_SYS_BASE, 0x020B0000
	.equ SEC_SYS_C906L_ENTRY_LOW, 0x20
	.equ SEC_SYS_C906L_ENTRY_HIGH, 0x24
c906l_set_entry:
	li xp, SEC_SYS_BASE

	# no doc
	lw yp, 0x4(xp)
	li zp, (1 << 13)
	or yp, yp, zp
	sw yp, 0x4(xp)

	sw wp, SEC_SYS_C906L_ENTRY_LOW(xp)
	sw zero, SEC_SYS_C906L_ENTRY_HIGH(xp)
	ret



	.equ RTC_SRAM_BASE, 0x05200000
dw8051_copy_fw:
	la wp, _binary_8051_bin_start
	la xp, _binary_8051_bin_size
	la yp, RTC_SRAM_BASE
2:
	beqz xp, 1f
	lbu zp, 0(wp)
	sb zp, 0(xp)
	addi wp, wp, 1
	addi xp, xp, -1
	addi yp, yp, 1
	j 2b
1:
	ret

	.equ TOP_MISC_BASE, 0x03000000
	.equ RTC_CTRL_BASE, 0x05025000
	.equ RTC_RST_CTRL,    0x18
	.equ RTC_RST_MCU, (1 << 1)
	.equ RTC_MCU51_CTLR0, 0x20
	.equ RTC_MCU51_ADDRMASK, 0xFFFFF000
dw8051_enter_reset:
	li wp, RTC_CTRL_BASE
	lw xp, RTC_RST_CTRL(wp)
	li yp, RTC_RST_MCU
	xori yp, yp, -1
	and xp, xp, yp
	sw xp, RTC_RST_CTRL(wp)
	ret

dw8051_leave_reset:
	li wp, TOP_MISC_BASE

	# no doc
	li xp, 0x1
	sw xp, 0x248(wp)

	li wp, RTC_CTRL_BASE
	li xp, RTC_SRAM_BASE
	li yp, RTC_MCU51_ADDRMASK
	and xp, xp, yp
	ori xp, xp, 0x8C
	sw xp, RTC_MCU51_CTLR0(wp)

	lw xp, RTC_RST_CTRL(wp)
	li yp, RTC_RST_MCU
	ori xp, xp, RTC_RST_MCU
	sw xp, RTC_RST_CTRL(wp)

	ret

	.p2align 2, 0x0
reset:
	# dw 8250 uart controller sucks
	# TODO: change uart baudrate
	la psp, dstk_c906m
	mv psb, psp
	la rsp, rstk_c906m

	.section .rodata
msg_c906m_boot:
	.asciz "\n\rC906M START"
msg_c906m_pc:
	.asciz "\n\rC906M PC: "
msg_version:
	.asciz "\n\rVERSION: "
	.p2align 2, 0x0
	.section .text

	la wp, msg_version
	call early_puts
	la xp, version
	ld wp, 0(xp)
	call early_puthex

	la wp, msg_c906m_boot
	call early_puts

	la wp, msg_c906m_pc
	call early_puts
	auipc wp, 0x0
	call early_puthex


	call c906l_enter_reset
	la wp, c906l_reset
	call c906l_set_entry
	call c906l_leave_reset

1:
	j 1b

	.section .bss
	.p2align 8, 0x0
rstk_c906m:
	.fill STKSIZE, 8, 0
dstk_c906m:
	.fill STKSIZE, 8, 0
	.section .text

	.p2align 2, 0x0
c906l_start:
	.option norvc;
	j c906l_reset
	#.option rvc;

c906l_reset:
	.equ mhcr, 0x7C1
	.equ mcor, 0x7C2

	# invalid I-cache
	li x3, 0x33
	csrc mcor, x3
	li x3, 0x11
	csrs mcor, x3
	# enable I-cache
	li x3, 0x1
	csrs mhcr, x3
	# invalid D-cache
	li x3, 0x33
	csrc mcor, x3
	li x3, 0x12
	csrs mcor, x3
	# enable D-cache
	li x3, 0x2
	csrs mhcr, x3

	.section .rodata
msg_c906l_boot:
	.asciz "\n\rC906L START"
msg_c906l_pc:
	.asciz "\n\rC906L PC: "
	.p2align 2, 0x0
	.section .text
	la psp, dstk_c906l
	mv psb, psp
	la rsp, rstk_c906l

	la wp, msg_c906l_boot
	call early_puts

	la wp, msg_c906l_pc
	call early_puts
	auipc wp, 0x0
	call early_puthex

	call dw8051_enter_reset
	call dw8051_copy_fw
	call dw8051_leave_reset

	la wp, forth
	jr wp

	.macro rpush reg
		sd \reg, 0(rsp)
		addi rsp, rsp, 8
	.endm

	.macro rpop reg
		addi rsp, rsp, -8
		ld \reg, 0(rsp)
	.endm

	.set lastword, 0
	.macro defword label, name, attr
	name_\label:
		.ascii "\name"
		.set nlen_\label, . - name_\label
		.p2align 2, 0
		.set prev_\label, lastword
	attr_\label:
		.4byte nlen_\label + \attr
	link_\label:
		.4byte prev_\label
	w_\label:
		.set lastword, w_\label
		rpush ra
	.endm

	.macro next
		rpop ra
		ret
	.endm

	defword DUMMY, "DUMMY", 0

	defword HALT, "HALT", 0
	.section .rodata
msg_halt:
	.asciz "FORTH HALT"
	.p2align 2, 0
	.section .text
	la wp, msg_halt
	call early_puts
1:
	j 1b

	defword PANIC, "PANIC", 0
	.section .rodata
msg_panic:
	.asciz "FORTH PANIC"
	.p2align 2, 0
	.section .text
	la wp, msg_panic
	call early_puts
1:
	j 1b

	.macro dpush reg
		sd \reg, 0(psp)
		addi psp, psp, 8
	.endm

	.macro dpop reg
		addi psp, psp, -8
		ld \reg, 0(psp)
	.endm

	defword EMIT, "EMIT", 0
	dpop wp
	call early_putc
	next

	defword LLIT, "LLIT", 0
	rpop ra
	lwu wp, 0(ra)
	dpush wp
	addi ra, ra, 4
	ret

	defword XLIT, "XLIT", 0
	rpop ra
	lwu wp, 0(ra)
	lwu xp, 4(ra)
	slli xp, xp, 32
	or wp, wp, xp
	dpush wp
	addi ra, ra, 8
	ret

	defword DOT, ".", 0
	dpop wp
	call early_puthex
	next

	defword DZCHK, "DZCHK", 0
	bne psp, psb, w_PANIC
	next

	defword NEPANIC, "<>PANIC", 0
	dpop wp
	dpop xp
	bne wp, xp, w_PANIC
	next

	defword TRUE, "TRUE", 0
	li wp, -1
	dpush wp
	next

	defword FALSE, "FALSE", 0
	dpush zero
	next

	defword EQ, "=", 0
	dpop wp
	dpop xp
	li yp, -1
	beq wp, xp, 1f
	li yp, 0
1:
	dpush yp
	next

	defword 0X0, "0X0", 0
	dpush zero
	next

	defword 0X1, "0X1", 0
	li wp, 0x1
	dpush wp
	next
	
	defword 0X2, "0X2", 0
	li wp, 0x2
	dpush wp
	next
	
	defword 0X3, "0X3", 0
	li wp, 0x3
	dpush wp
	next

	defword 0X4, "0X4", 0
	li wp, 0x4
	dpush wp
	next

	defword 0X5, "0X5", 0
	li wp, 0x5
	dpush wp
	next

	defword 0X6, "0X6", 0
	li wp, 0x6
	dpush wp
	next

	defword 0X7, "0X7", 0
	li wp, 0x7
	dpush wp
	next

	defword 0X8, "0X8", 0
	li wp, 0x8
	dpush wp
	next

	defword 0X9, "0X9", 0
	li wp, 0x9
	dpush wp
	next

	defword 0XA, "0XA", 0
	li wp, 0xA
	dpush wp
	next

	defword 0XB, "0XB", 0
	li wp, 0xB
	dpush wp
	next

	defword 0XC, "0XC", 0
	li wp, 0xC
	dpush wp
	next

	defword 0XD, "0XD", 0
	li wp, 0xD
	dpush wp
	next

	defword 0XE, "0XE", 0
	li wp, 0xE
	dpush wp
	next

	defword 0XF, "0XF", 0
	li wp, 0xF
	dpush wp
	next

	defword DEPTH, "DEPTH", 0
	sub wp, psp, psb
	srli wp, wp, 3
	dpush wp
	next

	defword DROP, "DROP", 0
	dpop wp
	next

	defword DUP, "DUP", 0
	dpop wp
	dpush wp
	dpush wp
	next

	defword SWAP, "SWAP", 0
	dpop wp
	dpop xp
	dpush wp
	dpush xp
	next

	defword KEY, "KEY", 0
	call early_getc
	dpush wp
	next

	defword LBRANCH, "LBRANCH", 0
	rpop ra
	lw wp, 0(ra)
	jr wp

	defword 0LBRANCH, "0LBRANCH", 0
	rpop ra
	lw wp, 0(ra)
	addi ra, ra, 4
	dpop xp
	bnez xp, 1f
	jr wp
1:
	ret

	defword EXECUTE, "EXECUTE", 0
	dpop wp
	jalr ra, wp, 0
	next

	defword PLUS, "+", 0
	dpop wp
	dpop xp
	addw wp, wp, xp
	dpush wp
	next

	defword 1PLUS, "1+", 0
	dpop wp
	addiw wp, wp, 1
	dpush wp
	next

	defword MINUS, "-", 0
	dpop wp
	dpop xp
	subw xp, xp, wp
	dpush xp
	next

	defword 1MINUS, "1-", 0
	dpop wp
	addiw wp, wp, -1
	dpush wp
	next

	defword CLOAD, "C@", 0
	dpop wp
	lbu xp, 0(wp)
	dpush xp
	next

	defword WLOAD, "W@", 0
	dpop wp
	lhu xp, 0(wp)
	dpush xp
	next

	defword LLOAD, "L@", 0
	dpop wp
	lwu xp, 0(wp)
	dpush xp
	next

	defword XLOAD, "X@", 0
	dpop wp
	ld xp, 0(wp)
	dpush xp
	next

	defword LOAD, "@", 0
	call w_XLOAD
	next

	defword CSTORE, "C!", 0
	dpop wp
	dpop xp
	sb xp, 0(wp)
	next

	defword WSTORE, "W!", 0
	dpop wp
	dpop xp
	sh xp, 0(wp)
	next

	defword LSTORE, "L!", 0
	dpop wp
	dpop xp
	sw xp, 0(wp)
	next

	defword XSTORE, "X!", 0
	dpop wp
	dpop xp
	sd xp, 0(wp)
	next

	defword STORE, "!", 0
	call w_XSTORE
	next

	defword TOR, ">R", 0
	rpop ra
	dpop wp
	rpush wp
	ret

	defword FROMR, "R>", 0
	rpop ra
	rpop wp
	dpush wp
	ret

	defword TOA, ">A", 0
	dpop ap
	next

	defword FROMA, "A>", 0
	dpush ap
	next

	defword ACLOAD, "AC@", 0
	lbu wp, 0(ap)
	dpush wp
	next

	defword ACSTORE, "AC!", 0
	dpop wp
	sb wp, 0(ap)
	next

	defword ACLOADPLUS, "AC@+", 0
	call w_ACLOAD
	addiw ap, ap, 1
	next

	defword ACLOADMINUS, "AC@-", 0
	call w_ACLOAD
	addiw ap, ap, -1
	next

	defword ACSTOREPLUS, "AC!+", 0
	call w_ACSTORE
	addiw ap, ap, 1
	next

	defword ACSTOREMINUS, "AC!-", 0
	call w_ACSTORE
	addiw ap, ap, -1
	next

	defword AXLOAD, "AX@", 0
	ld wp, 0(ap)
	dpush wp
	next

	defword AXSTORE, "AX!", 0
	dpop wp
	sd wp, 0(ap)
	next

	defword AXLOADPLUS, "AX@+", 0
	call w_AXLOAD
	addiw ap, ap, 8
	next

	defword AXLOADMINUS, "AX@-", 0
	call w_AXLOAD
	addiw ap, ap, -8
	next

	defword AXSTOREPLUS, "AX!+", 0
	call w_AXSTORE
	addiw ap, ap, 8
	next

	defword AXSTOREMINUS, "AX!-", 0
	call w_AXSTORE
	addiw ap, ap, -8
	next

	defword SPACE, "SPACE", 0
	li wp, ' '
	dpush wp
	call w_EMIT
	next

	defword TOB, ">B", 0
	dpop bp
	next

	defword FROMB, "B>", 0
	dpush bp
	next

	defword BCLOAD, "BC@", 0
        lbu wp, 0(bp)
        dpush wp
        next

        defword BCSTORE, "BC!", 0
        dpop wp
        sb wp, 0(bp)
        next

        defword BCLOADPLUS, "BC@+", 0
        call w_BCLOAD
        addiw bp, bp, 1
        next

        defword BCLOADMINUS, "BC@-", 0
        call w_BCLOAD
        addiw bp, bp, -1
        next

        defword BCSTOREPLUS, "BC!+", 0
        call w_BCSTORE
        addiw bp, bp, 1
        next

        defword BCSTOREMINUS, "BC!-", 0
        call w_BCSTORE
        addiw bp, bp, -1
        next

	defword ROT, "ROT", 0
	dpop wp
	dpop xp
	dpop yp
	dpush xp
	dpush wp
	dpush yp
	next

	defword MIN, "MIN", 0
	dpop wp
	dpop xp
	blt wp, xp, 1f
	dpush xp
	next
1:
	dpush wp
	next

	defword MAX, "MAX", 0
	dpop wp
	dpop xp
	bgt wp, xp, 1f
	dpush xp
	next
1:
	dpush wp
	next

	defword EQZ, "0=", 0
	dpop wp
	li yp, -1
	beqz wp, 1f
	li yp, 0
1:
	dpush yp
	next

	defword NIP, "NIP", 0
	dpop wp
	dpop xp
	dpush wp
	next

	defword NEZ, "0<>", 0
	dpop wp
	li yp, -1
	bnez wp, 1f
	li yp, 0
1:
	dpush yp
	next

	defword 2DROP, "2DROP", 0
	dpop wp
	dpop wp
	next

	defword OVER, "OVER", 0
	dpop wp
	dpop xp
	dpush xp
	dpush wp
	dpush xp
	next

	defword 2DUP, "2DUP", 0
	call w_OVER
	call w_OVER
	next

	defword CR, "CR", 0
	li wp, '\n'
	dpush wp
	li wp, '\r'
	dpush wp
	call w_EMIT
	call w_EMIT
	next

	defword COMPARE, "COMPARE", 0
	call w_ROT
	call w_MIN
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 1f
	call w_NIP
	call w_NIP
	next
1:
	call w_FROMA
	call w_TOR
	call w_FROMB
	call w_TOR

	call w_ROT
	call w_TOA
	call w_SWAP
	call w_TOB

2:
	call w_ACLOADPLUS
	call w_BCLOADPLUS
	call w_MINUS
	call w_DUP
	call w_NEZ
	call w_0LBRANCH
	.4byte 1f
	call w_FROMR
	call w_TOB
	call w_FROMR
	call w_TOA
	call w_NIP
	next
1:
	call w_DROP
	call w_1MINUS
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 2b
	call w_FROMR
	call w_TOB
	call w_FROMR
	call w_TOA
	next

	.equ XT_OFFSET_LINK, -4
	defword XT_OFFSET_LINK, "XT-OFFSET-LINK", 0
	li wp, XT_OFFSET_LINK
	dpush wp
	next

	defword XTLINK, "XTLINK", 0
	dpop wp
	addiw wp, wp, XT_OFFSET_LINK
	dpush wp
	next

	defword XTLINKLOAD, "XTLINK@", 0
	call w_XTLINK
	call w_LLOAD
	next

	defword XTLINKSTORE, "XTLINK!", 0
	call w_XTLINK
	call w_LSTORE
	next

	defword LATEST, "LATEST", 0
	la wp, latest
	ld xp, 0(wp)
	dpush xp
	next

	defword WORDCOUNTS, "WORDCOUNTS", 0
	call w_0X0
	call w_LATEST

1:
	call w_SWAP
	call w_1PLUS
	call w_SWAP
	call w_XTLINKLOAD
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 1b
	call w_DROP
	next

	.equ XT_OFFSET_NLEN, -8
	defword XT_OFFSET_NLEN, "XT-OFFSET-NLEN", 0
	li wp, XT_OFFSET_NLEN
	dpush wp
	next

	defword XTNLEN, "XTNLEN", 0
	dpop wp
	addiw wp, wp, XT_OFFSET_NLEN
	dpush wp
	next

	defword XTNLENLOAD, "XTNLEN@", 0
	call w_XTNLEN
	call w_CLOAD
	next

	defword XTNLENSTORE, "XTNLEN!", 0
	call w_XTNLEN
	call w_CSTORE
	next

	defword LALIGNED, "LALIGNED", 0
	dpop wp
	addiw wp, wp, 3
	andi wp, wp, -4
	dpush wp
	next

	defword NEGATE, "NEGATE", 0
	dpop wp
	xori wp, wp, -1
	addiw wp, wp, 1
	dpush wp
	next

	defword XTNAME, "XTNAME", 0
	call w_DUP
	call w_XTNLEN
	call w_SWAP
	call w_XTNLENLOAD
	call w_LALIGNED
	call w_NEGATE
	call w_PLUS
	next

	defword TYPE, "TYPE", 0
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 1f
	call w_2DROP
	next
1:
	call w_FROMA
	call w_TOR
	call w_SWAP
	call w_TOA

1:
	call w_ACLOADPLUS
	call w_EMIT
	call w_1MINUS
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 1b
	call w_DROP
	call w_FROMR
	call w_TOA
	next

	defword WORDS, "WORDS", 0
	call w_LATEST
1:
	call w_DUP
	call w_XTNAME
	call w_OVER
	call w_XTNLENLOAD
	call w_TYPE
	call w_SPACE
	call w_XTLINKLOAD
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 1b
	call w_DROP
	next

	defword 2SWAP, "2SWAP", 0
	dpop wp
	dpop xp
	dpop yp
	dpop zp
	dpush xp
	dpush wp
	dpush zp
	dpush yp
	next

	defword 2OVER, "2OVER", 0
	dpop wp
	dpop xp
	dpop yp
	dpop zp
	dpush zp
	dpush yp
	dpush xp
	dpush wp
	dpush zp
	dpush yp
	next

	defword FIND, "FIND", 0
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 1f
	call w_2DROP
	call w_FALSE
	next
1:
	call w_LATEST

2:
	call w_2DUP
	call w_XTNLENLOAD
	call w_EQ
	call w_0LBRANCH
	.4byte 1f
	call w_DUP
	call w_XTNAME
	call w_2OVER
	call w_SWAP
	call w_OVER
	call w_COMPARE
	call w_EQZ
	call w_0LBRANCH
	.4byte 1f
	call w_NIP
	call w_NIP
	next
1:
	call w_XTLINKLOAD
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 2b
	call w_NIP
	call w_NIP
	next

	defword PSBLOAD, "PSB@", 0
	dpush psb
	next

	defword DOTS, ".S", 0
	call w_DEPTH
	call w_LLIT
	.4byte '<'
	call w_EMIT
	call w_DOT
	call w_LLIT
	.4byte '>'
	call w_EMIT

	call w_DEPTH
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 1f
	call w_DROP
	next
1:
	call w_FROMA
	call w_TOR
	call w_PSBLOAD
	call w_TOA

1:
	call w_SPACE
	call w_AXLOADPLUS
	call w_DOT
	call w_1MINUS
	call w_DUP
	call w_EQZ
	call w_0LBRANCH
	.4byte 1b

	call w_DROP
	call w_FROMR
	call w_TOA
	next

	defword TIB, "TIB", 0
	la wp, tib
	dpush wp
	next

	defword TOIN, ">IN", 0
	la wp, toin
	dpush wp
	next

	defword TOINLOAD, ">IN@", 0
	call w_TOIN
	call w_XLOAD
	next

	defword TOINSTORE, ">IN!", 0
	call w_TOIN
	call w_XSTORE
	next

	defword TOINMAX, ">INMAX", 0
	li wp, (TIBSIZE - 1)
	dpush wp
	next

	defword WITHIN, "WITHIN", 0
	dpop wp # n3 max
	dpop xp # n2 min
	dpop yp # n1 val
	blt yp, wp, 1f
	dpush zero
	next
1:
	bge yp, xp, 1f
	dpush zero
	next
1:
	li zp, -1
	dpush zp
	next

	defword TOINCHK, ">INCHK", 0
	call w_TOINLOAD
	call w_0X0
	call w_TOINMAX
	call w_WITHIN
	next

	defword TOINRST, ">INRST", 0
	call w_0X0
	call w_TOINSTORE
	next

	defword TOIN1PLUS, ">IN1+", 0
	call w_TOINLOAD
	call w_1PLUS
	call w_TOINSTORE
	call w_TOINCHK
	call w_0LBRANCH
	.4byte 1f
	next
1:
	call w_TOINRST
	next

	defword TOIN1MINUS, ">IN1-", 0
	call w_TOINLOAD
	call w_1MINUS
	call w_TOINSTORE
	call w_TOINCHK
	call w_0LBRANCH
	.4byte 1f
	next
1:
	call w_TOINRST
	next

	defword TIBCSTOREPLUS, "TIBC!+", 0

	.8byte -1 # bad instruction
	.p2align 2, 0x0
forth:
	la wp, latest
	la xp, lastword
	sd xp, 0(wp)

	la wp, toin
	sd zero, 0(wp)

	call w_CR
	call w_WORDS
	call w_CR
	call w_WORDCOUNTS
	call w_DOT
	call w_CR
	call w_HALT
	call w_PANIC

        .section .bss
        .p2align 8, 0x0
rstk_c906l:
        .fill STKSIZE, 8, 0
dstk_c906l:
        .fill STKSIZE, 8, 0
latest:
	.8byte 0x0
tib:
	.fill TIBSIZE, 1, 0
	.p2align 8, 0x0
toin:
	.8byte 0x0
