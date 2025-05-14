
SYS_PORTION ?= packet-filter-switch
DUT_TOP ?= packet_filter_switch
VLOG_DEFINES ?= +define+TOP_TESTING=1
SVFILES ?= $(wildcard ../../$(SYS_PORTION)/*.sv) $(wildcard ../../include/*.sv) $(wildcard ../../packet-switch/*.sv ../../packet-filter/*.sv)
$(info DUT_TOP is $(DUT_TOP))
-include ../tb_rules.mk
