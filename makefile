FW_NAME ?= cv180x-forth

CROSS_COMPILE ?= riscv64-elf-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OD = $(CROSS_COMPILE)objdump
OC = $(CROSS_COMPILE)objcopy
SZ = $(CROSS_COMPILE)size
NM = $(CROSS_COMPILE)nm

LINK_SCRIPT ?= link.ld

CFLAGS += \
	-march=rv64g_zifencei_zicsr_xtheadcmo \
	-mabi=lp64 -nostdlib  -x assembler-with-cpp -ggdb \
	-T $(LINK_SCRIPT)

LDFLAGS += \
	-b elf64-littleriscv \
	--print-memory-usage \
	-T $(LINK_SCRIPT)



all: rebuild flash

rebuild: clean genfip dis


clean:
	rm -f *.out *.o $(FW_NAME).dis $(FW_NAME).elf \
		$(FW_NAME).bin \
		8051.rel 8051.ihx 8051.hex 8051.lst 8051.sym 8051.bin \
		chip_conf.bin blcp.bin fip.bin \

8051:
	sdas8051 -los 8051.asm
	sdld -i 8051.rel
	packihx 8051.ihx > 8051.hex
	sdobjcopy -I ihex -O binary 8051.ihx 8051.bin
	$(OC) -I binary -O elf64-littleriscv 8051.bin dw8051.o

bin: elf
	$(OC) -O binary $(FW_NAME).elf $(FW_NAME).bin

elf: 8051
	$(CC) $(CFLAGS) riscv.s -c -o riscv.o
	$(LD) $(LDFLAGS) riscv.o dw8051.o -o $(FW_NAME).elf

dis: elf
	$(OD) -d -s $(FW_NAME).elf > $(FW_NAME).dis

chip_conf:
	python3 ./fsbl/plat/cv180x/chip_conf.py chip_conf.bin

blcp:
	touch blcp.bin

genfip: bin chip_conf blcp
	python3 ./fsbl/plat/cv180x/fiptool.py -v genfip \
		--CHIP_CONF=chip_conf.bin \
		--BL2=$(FW_NAME).bin \
		--BLCP_IMG_RUNADDR=0x05200200 \
		--BLCP_PARAM_LOADADDR=0 \
		--BLCP=blcp.bin \
		fip.bin

flash: genfip
	cp -fv fip.bin ./build/tools/cv180x/usb_dl/
	cd ./build/tools/cv180x/usb_dl/ && sudo python3 cv181x_dl.py --serial
