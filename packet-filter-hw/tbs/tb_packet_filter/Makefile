
SYS_PORTION ?= packet-filter
DUT_TOP ?= packet_filter
VLOG_DEFINES ?= +define+UNIT_TESTING=1
ifeq ($(DUT_TOP), frame_buffer)
	VLOG_GENERICS ?= -GADDR_WIDTH=2 -GNUM_CYCLONE_5CSEMA5_BLOCKS=0 -GALMOST_FULL_THRESHOLD=3
else ifeq ($(DUT_TOP), preliminary_processor)
	VLOG_DEFINES += +define+INTG_TESTING_1=1
else ifeq ($(DUT_TOP), request_buffer)
	VLOG_DEFINES += +define+INTG_TESTING_1=1
else ifeq ($(DUT_TOP), ingress_filter)
	VLOG_DEFINES += +define+TOP_TESTING=1
else ifeq ($(DUT_TOP), packet_filter)
	VLOG_DEFINES += +define+TOP_TESTING=1
endif
SVFILES ?= $(wildcard ../../$(SYS_PORTION)/*.sv) $(wildcard ../../include/*.sv)
$(info DUT_TOP is $(DUT_TOP), TESTING_LEVEL is $(TESTING_LEVEL))
-include ../tb_rules.mk
