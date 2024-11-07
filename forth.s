	.section .init
	.global _start
_start:
	.option norvc;
	j reset
	.word 0 // resvered
	.word 0 // BL2 MSID
	.word 0 // BL2 version
	.word 0 //
	.word 0
	.word 0
	.word 0
	.option rvc;


#define wp t0
#define xp t1
#define yp t2
#define zp t3

	.section .text
reset:
	# dw 8250 uart controller sucks
	# TODO: change uart baudrate
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

	li wp, UART0_BASE

	li wp, 0x20
1:
	call early_putc
	addi wp, wp, 1
	li xp, 0x7F
	bne xp, wp, 1b

1:
	call early_getc
	call early_putc
	j 1b

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
