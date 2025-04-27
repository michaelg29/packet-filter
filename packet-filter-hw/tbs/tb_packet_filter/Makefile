
SYS_PORTION ?= packet-filter
DUT_TOP ?= frame_buffer
ifeq ($(DUT_TOP), frame_buffer)
	VLOG_GENERICS ?= -GADDR_WIDTH=2 -GNUM_CYCLONE_5CSEMA5_BLOCKS=0 -GALMOST_FULL_THRESHOLD=3
endif
SVFILES ?= $(wildcard ../../$(SYS_PORTION)/*.sv) $(wildcard ../../include/*.sv)
-include ../tb_rules.mk
