# =============================================================================
# OPTIMIZATION #
# =============================================================================
MAKEFLAGS += -j$(shell nproc 2>/dev/null || echo 1)

# =============================================================================
# PROJECT SETTINGS
# =============================================================================
OS := $(shell uname -s)

export PATH := $(PATH):$(shell pwd)/stm32cube/bin
export PATH := $(PATH):/opt/AppImages/ImageMagick

ifeq ($(OS),Darwin)
BASE_ARDUINO    = $(HOME)/Library/Arduino15
BASE_USER_LIBS  = $(HOME)/Projects/ArduinoLibs/libraries/
else
BASE_ARDUINO    = $(HOME)/.arduino15
BASE_USER_LIBS  = $(HOME)/Arduino/libraries
endif

SERIAL_PORT ?= /dev/ttyACM0
BAUD_RATE ?= 115200

# --- 1. Paths ---
ARDUINO_ROOT    = $(BASE_ARDUINO)/packages/STMicroelectronics
STM32_VER       = 2.12.0
CORE_PATH       = $(ARDUINO_ROOT)/hardware/stm32/$(STM32_VER)
TOOLS_PATH      = $(ARDUINO_ROOT)/tools/xpack-arm-none-eabi-gcc/14.2.1-1.1/bin
UPLOAD_TOOL     = $(ARDUINO_ROOT)/tools/STM32Tools/2.4.0/stm32CubeProg.sh
USER_LIB_PATH   = $(BASE_USER_LIBS)

# Project Name
TARGET = cck-door-sensor

# --- 2. Toolchain ---
CC      = $(TOOLS_PATH)/arm-none-eabi-gcc
CXX     = $(TOOLS_PATH)/arm-none-eabi-g++
OBJCOPY = $(TOOLS_PATH)/arm-none-eabi-objcopy
SIZE    = $(TOOLS_PATH)/arm-none-eabi-size

# --- 3. Board & Variant Specifics ---
BOARD_NAME    = FEATHER_F405
VARIANT_PATH  = $(CORE_PATH)/variants/STM32F4xx/F405RGT_F415RGT
LDSCRIPT      = $(VARIANT_PATH)/ldscript.ld

# --- 4. Compiler Flags ---
MCU_FLAGS = -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb

# Defines (Copied strictly from logs)
DEFINES  = -DSTM32F4xx -DARDUINO=10607 -DARDUINO_FEATHER_F405 -DARDUINO_ARCH_STM32
DEFINES += -DBOARD_NAME="\"$(BOARD_NAME)\"" -DVARIANT_H="\"variant_$(BOARD_NAME).h\""
DEFINES += -DSTM32F405xx -DUSBCON -DUSBD_VID=0x0483 -DUSBD_PID=0x5740
DEFINES += -DHAL_PCD_MODULE_ENABLED -DUSBD_USE_CDC -DHAL_UART_MODULE_ENABLED
DEFINES += -DVECT_TAB_OFFSET=0x0 -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -DNDEBUG

COMMON_FLAGS = $(MCU_FLAGS) -Os -w -ffunction-sections -fdata-sections --param max-inline-insns-single=500 -MMD

CFLAGS   = $(COMMON_FLAGS) -std=gnu17 $(DEFINES)
CXXFLAGS = $(COMMON_FLAGS) -std=gnu++17 -fno-threadsafe-statics -fno-rtti -fno-exceptions -fno-use-cxa-atexit $(DEFINES)

LDFLAGS  = $(MCU_FLAGS) -T$(LDSCRIPT) -Os --specs=nano.specs
LDFLAGS += -Wl,--defsym=LD_FLASH_OFFSET=0x0 -Wl,--defsym=LD_MAX_SIZE=1048576
LDFLAGS += -Wl,--defsym=LD_MAX_DATA_SIZE=131072 -Wl,--cref -Wl,--check-sections
LDFLAGS += -Wl,--gc-sections -Wl,--entry=Reset_Handler -Wl,--unresolved-symbols=report-all
LDFLAGS += -Wl,--warn-common -Wl,--no-warn-rwx-segments
LIBS     = -lc -lm -lgcc -lstdc++

# --- 5. Include Directories (Headers) ---
INCLUDES  = -I.
INCLUDES += -I$(USER_LIB_PATH)/STM32duino_STM32SD/src
INCLUDES += -I$(USER_LIB_PATH)/FatFs/src
INCLUDES += -I$(USER_LIB_PATH)/Adafruit_LSM6DS
INCLUDES += -I$(USER_LIB_PATH)/Adafruit_BusIO
INCLUDES += -I$(USER_LIB_PATH)/Adafruit_Unified_Sensor
INCLUDES += -I$(USER_LIB_PATH)/Adafruit_LIS3MDL
INCLUDES += -I$(CORE_PATH)/libraries/Wire/src
INCLUDES += -I$(CORE_PATH)/libraries/SPI/src
INCLUDES += -I$(CORE_PATH)/cores/arduino
INCLUDES += -I$(CORE_PATH)/cores/arduino/avr
INCLUDES += -I$(CORE_PATH)/cores/arduino/stm32
INCLUDES += -I$(CORE_PATH)/libraries/SrcWrapper/inc
INCLUDES += -I$(CORE_PATH)/libraries/SrcWrapper/inc/LL
INCLUDES += -I$(CORE_PATH)/system/Drivers/STM32F4xx_HAL_Driver/Inc
INCLUDES += -I$(CORE_PATH)/system/Drivers/STM32F4xx_HAL_Driver/Src
INCLUDES += -I$(CORE_PATH)/system/STM32F4xx
INCLUDES += -I$(CORE_PATH)/libraries/USBDevice/inc
INCLUDES += -I$(CORE_PATH)/system/Middlewares/ST/STM32_USB_Device_Library/Core/Inc
INCLUDES += -I$(CORE_PATH)/system/Middlewares/ST/STM32_USB_Device_Library/Core/Src
INCLUDES += -I$(ARDUINO_ROOT)/tools/CMSIS/6.2.0/CMSIS/Core/Include
INCLUDES += -I$(CORE_PATH)/system/Drivers/CMSIS/Device/ST/STM32F4xx/Include
INCLUDES += -I$(VARIANT_PATH)

# --- 6. Source Files ---

# 6a. Main Project
SRCS_CPP = main.cpp

# B. Core (Arduino Core Files)
SRCS_C   += $(wildcard $(CORE_PATH)/cores/arduino/*.c)
SRCS_C   += $(wildcard $(CORE_PATH)/cores/arduino/stm32/*.c)
SRCS_CPP += $(wildcard $(CORE_PATH)/cores/arduino/*.cpp)
SRCS_CPP += $(wildcard $(CORE_PATH)/cores/arduino/stm32/*.cpp)

# C. Variant
SRCS_C   += $(wildcard $(VARIANT_PATH)/*.c)
SRCS_CPP += $(wildcard $(VARIANT_PATH)/*.cpp)

# D. SrcWrapper (HAL/LL Drivers) - Based on log
SRCS_C   += $(wildcard $(CORE_PATH)/libraries/SrcWrapper/src/HAL/*.c)
SRCS_C   += $(wildcard $(CORE_PATH)/libraries/SrcWrapper/src/LL/*.c)
SRCS_C   += $(wildcard $(CORE_PATH)/libraries/SrcWrapper/src/stm32/*.c)
SRCS_C   += $(CORE_PATH)/libraries/SrcWrapper/src/syscalls.c
SRCS_CPP += $(wildcard $(CORE_PATH)/libraries/SrcWrapper/src/*.cpp)
SRCS_CPP += $(wildcard $(CORE_PATH)/libraries/SrcWrapper/src/stm32/*.cpp)

# E. USBDevice Library - Based on log
SRCS_C   += $(wildcard $(CORE_PATH)/libraries/USBDevice/src/*.c)
SRCS_C   += $(wildcard $(CORE_PATH)/libraries/USBDevice/src/cdc/*.c)
SRCS_C   += $(wildcard $(CORE_PATH)/libraries/USBDevice/src/hid/*.c)
SRCS_CPP += $(wildcard $(CORE_PATH)/libraries/USBDevice/src/*.cpp)

# F. Wire Library (Core)
SRCS_CPP += $(CORE_PATH)/libraries/Wire/src/Wire.cpp
SRCS_C   += $(CORE_PATH)/libraries/Wire/src/utility/twi.c

# G. SPI Library (Core)
SRCS_CPP += $(CORE_PATH)/libraries/SPI/src/SPI.cpp
SRCS_C   += $(CORE_PATH)/libraries/SPI/src/utility/spi_com.c

# H. STM32duino STM32SD
SRCS_CPP += $(wildcard $(USER_LIB_PATH)/STM32duino_STM32SD/src/*.cpp)
SRCS_C   += $(wildcard $(USER_LIB_PATH)/STM32duino_STM32SD/src/*.c)

# I. FatFs
# EXPLICIT LIST to avoid compiling ffsystem_cmsis_os.c (FreeRTOS)
FATFS_PATH = $(USER_LIB_PATH)/FatFs/src
SRCS_C   += $(FATFS_PATH)/diskio.c
SRCS_C   += $(FATFS_PATH)/drivers/sd_diskio.c
SRCS_C   += $(FATFS_PATH)/ff.c
SRCS_C   += $(FATFS_PATH)/ff_gen_drv.c
SRCS_C   += $(FATFS_PATH)/ffsystem.c
SRCS_C   += $(FATFS_PATH)/ffunicode.c

# J. Adafruit LSM6DS (Root)
SRCS_CPP += $(wildcard $(USER_LIB_PATH)/Adafruit_LSM6DS/*.cpp)

# K. Adafruit BusIO (Root)
SRCS_CPP += $(wildcard $(USER_LIB_PATH)/Adafruit_BusIO/*.cpp)

# L. Adafruit Unified Sensor (Root)
SRCS_CPP += $(wildcard $(USER_LIB_PATH)/Adafruit_Unified_Sensor/*.cpp)

# M. Adafruit LIS3MDL (Root)
SRCS_CPP += $(wildcard $(USER_LIB_PATH)/Adafruit_LIS3MDL/*.cpp)

# Object files
BUILD_DIR = build
OBJS  = $(addprefix $(BUILD_DIR)/, $(SRCS_CPP:.cpp=.o))
OBJS += $(addprefix $(BUILD_DIR)/, $(SRCS_C:.c=.o))

# --- 7. Rules ---

all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin size

# Link
$(BUILD_DIR)/$(TARGET).elf: $(OBJS)
	@echo "Linking $@"
	@$(CXX) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

# Compile C++
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	@echo "Compiling C++: $<"
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Compile C
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "Compiling C: $<"
	@$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Generate Binary
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	@$(OBJCOPY) -O binary $< $@

# Generate Hex
$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf
	@$(OBJCOPY) -O ihex $< $@

size: $(BUILD_DIR)/$(TARGET).elf
	@echo "--- Size Report ---"
	@$(SIZE) -A $<

upload: $(BUILD_DIR)/$(TARGET).bin
	@echo "Uploading via DFU..."
	@sh "$(UPLOAD_TOOL)" -i dfu -f "$<" -o 0x0 -v 0x0483 -p 0xdf11 -a 0x8000000 -s 0x8000000

clean:
	rm -rf $(BUILD_DIR)

monitor:
	@echo "Opening serial monitor on $(SERIAL_PORT) at $(BAUD_RATE) baud..."
	@stty -F $(SERIAL_PORT) $(BAUD_RATE) raw -clocal -echo
	@cat $(SERIAL_PORT)

# Send: Send a message to the serial port
# Usage: make send MSG="Hello World"
send:
	@if [ -z "$(MSG)" ]; then \
		echo "Usage: make send MSG=\"Your Message\""; \
	else \
		echo "Sending '$(MSG)' to $(SERIAL_PORT)..."; \
		stty -F $(SERIAL_PORT) $(BAUD_RATE) raw -clocal -echo; \
		echo "$(MSG)" > $(SERIAL_PORT); \
	fi

# Term: Interactive session (requires 'screen' installed)
term:
	@echo "Opening interactive terminal on $(SERIAL_PORT)..."
	@echo "Press Ctrl+A then K to exit."
	@screen $(SERIAL_PORT) $(BAUD_RATE)

.PHONY: all clean upload size monitor send term
