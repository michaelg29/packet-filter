MODULE = packet_switch

VERILATOR_FLAGS = -Wall -Wno-fatal --trace --trace-params --trace-structs --trace-underscore

INCLUDE_PATHS = -I../include

CFLAGS = -Wall -g -O2

BUILD_DIR = obj_dir

SOURCES = packet_switch.sv rr_scheduler.sv mux4to1.sv

all: run

run: $(BUILD_DIR)/V$(MODULE)
	$(BUILD_DIR)/V$(MODULE)

$(BUILD_DIR)/V$(MODULE): $(SOURCES) $(MODULE)_tb.cpp
	verilator $(VERILATOR_FLAGS) $(INCLUDE_PATHS) -cc $(SOURCES) --exe $(MODULE)_tb.cpp
	make -C $(BUILD_DIR) -f V$(MODULE).mk

clean:
	rm -rf $(BUILD_DIR)
	rm -f *.vcd

view:
	gtkwave packet_switch_trace.vcd

.PHONY: all run clean view
