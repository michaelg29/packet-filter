# TCL File Generated by Component Editor 21.1
# Wed Apr 09 19:14:41 EDT 2025
# DO NOT MODIFY


# 
# packet_filter "Packet Filter" v1.0
#  2025.04.09.19:14:41
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module packet_filter
# 
set_module_property DESCRIPTION ""
set_module_property NAME packet_filter
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "Packet Filter"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL packet_filter
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file packet_filter.sv SYSTEM_VERILOG PATH packet-filter/packet_filter.sv TOP_LEVEL_FILE


# 
# parameters
# 


# 
# module assignments
# 
set_module_assignment embeddedsw.dts.group packet_filter
set_module_assignment embeddedsw.dts.name packet_filter
set_module_assignment embeddedsw.dts.vendor csee4840


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point avalon_slave_0
# 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 writedata writedata Input 8
add_interface_port avalon_slave_0 write write Input 1
add_interface_port avalon_slave_0 chipselect chipselect Input 1
add_interface_port avalon_slave_0 address address Input 8
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point ingress_port_0
# 
add_interface ingress_port_0 axi4stream end
set_interface_property ingress_port_0 associatedClock clock
set_interface_property ingress_port_0 associatedReset reset
set_interface_property ingress_port_0 ENABLED true
set_interface_property ingress_port_0 EXPORT_OF ""
set_interface_property ingress_port_0 PORT_NAME_MAP ""
set_interface_property ingress_port_0 CMSIS_SVD_VARIABLES ""
set_interface_property ingress_port_0 SVD_ADDRESS_GROUP ""

add_interface_port ingress_port_0 ingress_port_0_tdata tdata Input 16
add_interface_port ingress_port_0 ingress_port_0_tvalid tvalid Input 1
add_interface_port ingress_port_0 ingress_port_0_tready tready Output 1
add_interface_port ingress_port_0 ingress_port_0_tlast tlast Input 1


# 
# connection point ingress_port_1
# 
add_interface ingress_port_1 axi4stream end
set_interface_property ingress_port_1 associatedClock clock
set_interface_property ingress_port_1 associatedReset reset
set_interface_property ingress_port_1 ENABLED true
set_interface_property ingress_port_1 EXPORT_OF ""
set_interface_property ingress_port_1 PORT_NAME_MAP ""
set_interface_property ingress_port_1 CMSIS_SVD_VARIABLES ""
set_interface_property ingress_port_1 SVD_ADDRESS_GROUP ""

add_interface_port ingress_port_1 ingress_port_1_tdata tdata Input 16
add_interface_port ingress_port_1 ingress_port_1_tlast tlast Input 1
add_interface_port ingress_port_1 ingress_port_1_tvalid tvalid Input 1
add_interface_port ingress_port_1 ingress_port_1_tready tready Output 1


# 
# connection point ingress_port_2
# 
add_interface ingress_port_2 axi4stream end
set_interface_property ingress_port_2 associatedClock clock
set_interface_property ingress_port_2 associatedReset reset
set_interface_property ingress_port_2 ENABLED true
set_interface_property ingress_port_2 EXPORT_OF ""
set_interface_property ingress_port_2 PORT_NAME_MAP ""
set_interface_property ingress_port_2 CMSIS_SVD_VARIABLES ""
set_interface_property ingress_port_2 SVD_ADDRESS_GROUP ""

add_interface_port ingress_port_2 ingress_port_2_tdata tdata Input 16
add_interface_port ingress_port_2 ingress_port_2_tlast tlast Input 1
add_interface_port ingress_port_2 ingress_port_2_tvalid tvalid Input 1
add_interface_port ingress_port_2 ingress_port_2_tready tready Output 1


# 
# connection point ingress_port_3
# 
add_interface ingress_port_3 axi4stream end
set_interface_property ingress_port_3 associatedClock clock
set_interface_property ingress_port_3 associatedReset reset
set_interface_property ingress_port_3 ENABLED true
set_interface_property ingress_port_3 EXPORT_OF ""
set_interface_property ingress_port_3 PORT_NAME_MAP ""
set_interface_property ingress_port_3 CMSIS_SVD_VARIABLES ""
set_interface_property ingress_port_3 SVD_ADDRESS_GROUP ""

add_interface_port ingress_port_3 ingress_port_3_tdata tdata Input 16
add_interface_port ingress_port_3 ingress_port_3_tready tready Output 1
add_interface_port ingress_port_3 ingress_port_3_tlast tlast Input 1
add_interface_port ingress_port_3 ingress_port_3_tvalid tvalid Input 1


# 
# connection point egress_port_0
# 
add_interface egress_port_0 axi4stream start
set_interface_property egress_port_0 associatedClock clock
set_interface_property egress_port_0 associatedReset reset
set_interface_property egress_port_0 ENABLED true
set_interface_property egress_port_0 EXPORT_OF ""
set_interface_property egress_port_0 PORT_NAME_MAP ""
set_interface_property egress_port_0 CMSIS_SVD_VARIABLES ""
set_interface_property egress_port_0 SVD_ADDRESS_GROUP ""

add_interface_port egress_port_0 egress_port_0_tdata tdata Output 16
add_interface_port egress_port_0 egress_port_0_tlast tlast Output 1
add_interface_port egress_port_0 egress_port_0_tready tready Input 1
add_interface_port egress_port_0 egress_port_0_tvalid tvalid Output 1


# 
# connection point egress_port_1
# 
add_interface egress_port_1 axi4stream start
set_interface_property egress_port_1 associatedClock clock
set_interface_property egress_port_1 associatedReset reset
set_interface_property egress_port_1 ENABLED true
set_interface_property egress_port_1 EXPORT_OF ""
set_interface_property egress_port_1 PORT_NAME_MAP ""
set_interface_property egress_port_1 CMSIS_SVD_VARIABLES ""
set_interface_property egress_port_1 SVD_ADDRESS_GROUP ""

add_interface_port egress_port_1 egress_port_1_tdata tdata Output 16
add_interface_port egress_port_1 egress_port_1_tlast tlast Output 1
add_interface_port egress_port_1 egress_port_1_tready tready Input 1
add_interface_port egress_port_1 egress_port_1_tvalid tvalid Output 1


# 
# connection point egress_port_2
# 
add_interface egress_port_2 axi4stream start
set_interface_property egress_port_2 associatedClock clock
set_interface_property egress_port_2 associatedReset reset
set_interface_property egress_port_2 ENABLED true
set_interface_property egress_port_2 EXPORT_OF ""
set_interface_property egress_port_2 PORT_NAME_MAP ""
set_interface_property egress_port_2 CMSIS_SVD_VARIABLES ""
set_interface_property egress_port_2 SVD_ADDRESS_GROUP ""

add_interface_port egress_port_2 egress_port_2_tdata tdata Output 16
add_interface_port egress_port_2 egress_port_2_tlast tlast Output 1
add_interface_port egress_port_2 egress_port_2_tready tready Input 1
add_interface_port egress_port_2 egress_port_2_tvalid tvalid Output 1


# 
# connection point egress_port_3
# 
add_interface egress_port_3 axi4stream start
set_interface_property egress_port_3 associatedClock clock
set_interface_property egress_port_3 associatedReset reset
set_interface_property egress_port_3 ENABLED true
set_interface_property egress_port_3 EXPORT_OF ""
set_interface_property egress_port_3 PORT_NAME_MAP ""
set_interface_property egress_port_3 CMSIS_SVD_VARIABLES ""
set_interface_property egress_port_3 SVD_ADDRESS_GROUP ""

add_interface_port egress_port_3 egress_port_3_tdata tdata Output 16
add_interface_port egress_port_3 egress_port_3_tlast tlast Output 1
add_interface_port egress_port_3 egress_port_3_tready tready Input 1
add_interface_port egress_port_3 egress_port_3_tvalid tvalid Output 1


# 
# connection point packet_filter_interrupt
# 
add_interface packet_filter_interrupt interrupt end
set_interface_property packet_filter_interrupt associatedAddressablePoint ""
set_interface_property packet_filter_interrupt associatedClock clock
set_interface_property packet_filter_interrupt bridgedReceiverOffset ""
set_interface_property packet_filter_interrupt bridgesToReceiver ""
set_interface_property packet_filter_interrupt ENABLED true
set_interface_property packet_filter_interrupt EXPORT_OF ""
set_interface_property packet_filter_interrupt PORT_NAME_MAP ""
set_interface_property packet_filter_interrupt CMSIS_SVD_VARIABLES ""
set_interface_property packet_filter_interrupt SVD_ADDRESS_GROUP ""

add_interface_port packet_filter_interrupt irq irq Output 1

