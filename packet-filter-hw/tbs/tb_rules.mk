.PHONY: default clean $(DUT_TOP).vcd lint

HOST=$(shell hostname)

DUT_TOP ?= top
SVFILES ?= $(DUT_TOP).sv
VLOG_DEFINES ?=
VLOG_GENERICS ?=

INCLUDE_FLAG = -I../../include
ifdef SYS_PORTION
	INCLUDE_FLAG += -I../../$(SYS_PORTION)
endif

VERILATOR_WARN_FLAGS = -Wno-DECLFILENAME
VERILATOR_ASSERT_FLAG =
ifeq ($(findstring micro,$(HOST)),)
	VERILATOR_WARN_FLAGS += -Wno-UNUSEDSIGNAL -Wno-MISINDENT -Wno-UNUSEDPARAM
	VERILATOR_ASSERT_FLAG += -assert
	VLOG_DEFINES += +define+ASSERT=1
endif

$(info $(VERILATOR_ASSERT_FLAG))

VLOG_DEFINES += +define+VERILATOR=1

# create simulator object
obj_dir/V$(DUT_TOP): $(SVFILES) $(DUT_TOP).cpp
	verilator -trace -Wall -cc $(SVFILES) -exe $(DUT_TOP).cpp \
		$(VLOG_DEFINES) \
		$(VLOG_GENERICS) \
		$(INCLUDE_FLAG) \
		-top-module $(DUT_TOP) \
		$(VERILATOR_WARN_FLAGS) \
		$(VERILATOR_ASSERT_FLAG)
	cd obj_dir && make -j -f V$(DUT_TOP).mk

# run simulator object
$(DUT_TOP).vcd: obj_dir/V$(DUT_TOP)
	obj_dir/V$(DUT_TOP)

# view waveform
gtkwave: $(DUT_TOP).vcd
	gtkwave $(DUT_TOP).vcd

clean:
	rm -rf obj_dir *.vcd
