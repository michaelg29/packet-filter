# TCL File Generated by Component Editor 21.1
# Wed May 14 13:15:02 EDT 2025
# DO NOT MODIFY


# 
# frame_receptor "Frame Receptor" v1.0
#  2025.05.14.13:15:02
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module frame_receptor
# 
set_module_property DESCRIPTION ""
set_module_property NAME frame_receptor
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME "Frame Receptor"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL frame_receptor
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS true
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file frame_receptor.sv SYSTEM_VERILOG PATH frame-receptor/frame_receptor.sv TOP_LEVEL_FILE
add_fileset_file packet_filter.svh OTHER PATH include/packet_filter.svh


# 
# parameters
# 
add_parameter STUBBING INTEGER 0
set_parameter_property STUBBING DEFAULT_VALUE 0
set_parameter_property STUBBING DISPLAY_NAME STUBBING
set_parameter_property STUBBING TYPE INTEGER
set_parameter_property STUBBING UNITS None
set_parameter_property STUBBING ALLOWED_RANGES -2147483648:2147483647
set_parameter_property STUBBING HDL_PARAMETER true
add_parameter CAN_RESET_POINTERS INTEGER 0
set_parameter_property CAN_RESET_POINTERS DEFAULT_VALUE 0
set_parameter_property CAN_RESET_POINTERS DISPLAY_NAME CAN_RESET_POINTERS
set_parameter_property CAN_RESET_POINTERS TYPE INTEGER
set_parameter_property CAN_RESET_POINTERS UNITS None
set_parameter_property CAN_RESET_POINTERS ALLOWED_RANGES -2147483648:2147483647
set_parameter_property CAN_RESET_POINTERS HDL_PARAMETER true


# 
# module assignments
# 
set_module_assignment embeddedsw.dts.group packet_filter
set_module_assignment embeddedsw.dts.name frame_receptor
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

add_interface_port avalon_slave_0 writedata writedata Input 32
add_interface_port avalon_slave_0 write write Input 1
add_interface_port avalon_slave_0 chipselect chipselect Input 1
add_interface_port avalon_slave_0 address address Input 8
add_interface_port avalon_slave_0 read read Input 1
add_interface_port avalon_slave_0 readdata readdata Output 32
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point ingress_port
# 
add_interface ingress_port axi4stream end
set_interface_property ingress_port associatedClock clock
set_interface_property ingress_port associatedReset reset
set_interface_property ingress_port ENABLED true
set_interface_property ingress_port EXPORT_OF ""
set_interface_property ingress_port PORT_NAME_MAP ""
set_interface_property ingress_port CMSIS_SVD_VARIABLES ""
set_interface_property ingress_port SVD_ADDRESS_GROUP ""

add_interface_port ingress_port ingress_port_tdata tdata Input 16
add_interface_port ingress_port ingress_port_tvalid tvalid Input 1
add_interface_port ingress_port ingress_port_tready tready Output 1
add_interface_port ingress_port ingress_port_tlast tlast Input 1

