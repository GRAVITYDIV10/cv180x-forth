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
	-march=rv64gc_zifencei_zicsr -mabi=lp64 \
	-nostdlib  -x assembler-with-cpp -ggdb \
	-T $(LINK_SCRIPT)

all: rebuild flash

rebuild: clean genfip $(FW_NAME).dis

clean:
	rm -f *.out *.o $(FW_NAME).dis $(FW_NAME).elf \
		chip_conf.bin blcp.bin fip.bin \
		$(FW_NAME).bin

$(FW_NAME).bin: $(FW_NAME).elf
	$(OC) -O binary $(FW_NAME).elf $(FW_NAME).bin

$(FW_NAME).elf:
	$(CC) $(CFLAGS) forth.s -o $(FW_NAME).elf

$(FW_NAME).dis: $(FW_NAME).elf
	$(OD) -d -s $(FW_NAME).elf > $(FW_NAME).dis

chip_conf:
	python3 ./fsbl/plat/cv180x/chip_conf.py chip_conf.bin

blcp:
	touch blcp.bin

genfip: $(FW_NAME).bin chip_conf blcp
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
