# 2020 David DiPaola
# Licensed under CC0

SRC = main.c
OBJ = $(SRC:.c=.o)
ELF = flash.elf

TARGET_PREFIX ?= arm-none-eabi-
TARGET_GCC ?= $(TARGET_PREFIX)gcc
TARGET_GDB ?= gdb-multiarch
TARGET_OBJDUMP ?= $(TARGET_PREFIX)objdump

OPENOCD ?= openocd
OPENOCD_INTERFACE ?= interface/stlink-v2.cfg
OPENOCD_TARGET ?= target/stm32f4x.cfg
OPENOCD_FLAGS ?= \
	--file $(OPENOCD_INTERFACE) \
	--file $(OPENOCD_TARGET)

TARGET_SFLAGS = \
	-Os -g3 \
	--static -nostartfiles \
	-fno-common -ffunction-sections -fdata-sections \
	-I./lib/opencm3/include
TARGET_CFLAGS = \
	-std=c99 \
	-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16\
	-DSTM32F4 \
	$(TARGET_SFLAGS)
TARGET_LFLAGS = \
	-Wl,--start-group \
		-nostdlib -lc -lgcc -lnosys \
		-T./layout.ld -L./lib/opencm3/lib/ \
	-Wl,--end-group
TARGET_GDBFLAGS = \
	-tui -quiet 

.PHONY: all
all: $(ELF)

.PHONY: flash
flash: $(ELF)
	$(OPENOCD) $(OPENOCD_FLAGS) --command "program $< verify reset exit"

.PHONY: run-debug-server
run-debug-server:
	$(OPENOCD) $(OPENOCD_FLAGS)

.PHONY: run-debug-client
run-debug-client: gdbinit $(ELF)
	$(TARGET_GDB) $(TARGET_GDBFLAGS) -x gdbinit $(ELF)

.PHONY: clean
clean:
	rm -fr $(OBJ)
	rm -fr $(ELF)

.PHONY: realclean
realclean: clean
	$(MAKE) -C lib/opencm3 clean

.PHONY: disassemble
disassemble: $(ELF)
	$(TARGET_OBJDUMP) --disassemble-all $(ELF)

.PHONY: libopencm3
libopencm3:
	$(MAKE) -C lib/opencm3 PREFIX="$(TARGET_PREFIX)" TARGETS=stm32/f4

%.o: %.c libopencm3
	$(TARGET_GCC) $(TARGET_CFLAGS) -c $< -o $@

$(ELF): $(OBJ) libopencm3 
	$(TARGET_GCC) $(TARGET_LFLAGS) $(OBJ) lib/opencm3/lib/libopencm3_stm32f4.a -o $@
