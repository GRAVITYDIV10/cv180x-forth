OUTPUT_FORMAT("elf64-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
	VC_SRAM(rwx):  ORIGIN = 0x3BC00000, LENGTH = 0x19000
	TPU_SRAM(rwx): ORIGIN = 0x3C000000, LENGTH = 0x10000
	RTC_SRAM(rwx): ORIGIN = 0x05200000, LENGTH = 0x2000
}

SECTIONS
{
	. = ORIGIN(VC_SRAM);
	.init : {
		. = ALIGN(8);
		*(.init)
		*(.init*)
		. = ALIGN(8);
	} > VC_SRAM

	.text : {
		. = ALIGN(8);
		*(.text)
		*(.text*)
		*(.rodata)
		*(.rodata*)
		. = ALIGN(8);
	} > VC_SRAM

	.data : {
		. = ALIGN(8);
		*(.data)
		*(.data*)
		. = ALIGN(8);
	} > VC_SRAM

	.bss (NOLOAD) : {
		. = ALIGN(8);
		*(.bss)
		*(.sbss)
		. = ALIGN(8);
	} > VC_SRAM
}
