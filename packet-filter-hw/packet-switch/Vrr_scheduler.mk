# Makefile for Verilator simulation

# Module name
MODULE = rr_scheduler

# Verilator flags
VERILATOR_FLAGS = -Wall -Wno-fatal --trace --trace-params --trace-structs --trace-underscore

# C++ flags
CFLAGS = -Wall -g -O2

# Build directory
BUILD_DIR = obj_dir

all: run

run: $(BUILD_DIR)/V$(MODULE)
	$(BUILD_DIR)/V$(MODULE)

$(BUILD_DIR)/V$(MODULE): $(MODULE).sv $(MODULE)_tb.cpp
	verilator $(VERILATOR_FLAGS) -cc $(MODULE).sv --exe $(MODULE)_tb.cpp
	make -C $(BUILD_DIR) -f V$(MODULE).mk

clean:
	rm -rf $(BUILD_DIR)
	rm -f *.vcd

.PHONY: all run clean
