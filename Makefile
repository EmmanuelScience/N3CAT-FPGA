RISCV_PREFIX = /opt/Xilinx/Vitis/2023.2/gnu/riscv/lin/riscv64-unknown-elf/bin/riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
OBJCOPY = $(RISCV_PREFIX)objcopy
OBJDUMP = $(RISCV_PREFIX)objdump

CFLAGS = -march=rv64gc -mabi=lp64d -nostdlib -nostartfiles -T linker.ld

TARGET = simple_test
SOURCES = simple_test.S

all: $(TARGET).bin

$(TARGET).elf: $(SOURCES) linker.ld
	$(CC) $(CFLAGS) -o $@ $(SOURCES)

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -d $< > $@

clean:
	rm -f $(TARGET).elf $(TARGET).bin $(TARGET).dump

disasm: $(TARGET).dump
	cat $(TARGET).dump

.PHONY: all clean disasm