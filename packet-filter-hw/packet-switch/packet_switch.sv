// packet_switch.v

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
// 
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module packet_switch (
		input  wire        clk,                   //                   clock.clk
		input  wire        reset,                 //                   reset.reset
		input  wire [7:0]  writedata,             //          avalon_slave_0.writedata
		input  wire        write,                 //                        .write
		input  wire        chipselect,            //                        .chipselect
		input  wire [7:0]  address,               //                        .address
		input  wire        read,                  //                        .read
		output wire [7:0]  readdata,              //                        .readdata
		input  wire [15:0] ingress_port_0_tdata,  //          ingress_port_0.tdata
		input  wire        ingress_port_0_tvalid, //                        .tvalid
		output wire        ingress_port_0_tready, //                        .tready
		input  wire        ingress_port_0_tlast,  //                        .tlast
		input  wire [1:0]  ingress_port_0_tdest,  //                        .tdest
		input  wire [15:0] ingress_port_1_tdata,  //          ingress_port_1.tdata
		input  wire        ingress_port_1_tlast,  //                        .tlast
		input  wire        ingress_port_1_tvalid, //                        .tvalid
		output wire        ingress_port_1_tready, //                        .tready
		input  wire [1:0]  ingress_port_1_tdest,  //                        .tdest
		input  wire [15:0] ingress_port_2_tdata,  //          ingress_port_2.tdata
		input  wire        ingress_port_2_tlast,  //                        .tlast
		input  wire        ingress_port_2_tvalid, //                        .tvalid
		output wire        ingress_port_2_tready, //                        .tready
		input  wire [1:0]  ingress_port_2_tdest,  //                        .tdest
		input  wire [15:0] ingress_port_3_tdata,  //          ingress_port_3.tdata
		output wire        ingress_port_3_tready, //                        .tready
		input  wire        ingress_port_3_tlast,  //                        .tlast
		input  wire        ingress_port_3_tvalid, //                        .tvalid
		input  wire [1:0]  ingress_port_3_tdest,  //                        .tdest
		output wire [15:0] egress_port_0_tdata,   //           egress_port_0.tdata
		output wire        egress_port_0_tlast,   //                        .tlast
		input  wire        egress_port_0_tready,  //                        .tready
		output wire        egress_port_0_tvalid,  //                        .tvalid
		output wire [15:0] egress_port_1_tdata,   //           egress_port_1.tdata
		output wire        egress_port_1_tlast,   //                        .tlast
		input  wire        egress_port_1_tready,  //                        .tready
		output wire        egress_port_1_tvalid,  //                        .tvalid
		output wire [15:0] egress_port_2_tdata,   //           egress_port_2.tdata
		output wire        egress_port_2_tlast,   //                        .tlast
		input  wire        egress_port_2_tready,  //                        .tready
		output wire        egress_port_2_tvalid,  //                        .tvalid
		output wire [15:0] egress_port_3_tdata,   //           egress_port_3.tdata
		output wire        egress_port_3_tlast,   //                        .tlast
		input  wire        egress_port_3_tready,  //                        .tready
		output wire        egress_port_3_tvalid,  //                        .tvalid
		output wire        irq                    // packet_filter_interrupt.irq
	);

	// TODO: Auto-generated HDL template

	assign readdata = 8'b00000000;

	assign ingress_port_0_tready = 1'b0;

	assign ingress_port_1_tready = 1'b0;

	assign ingress_port_2_tready = 1'b0;

	assign ingress_port_3_tready = 1'b0;

	assign egress_port_0_tvalid = 1'b0;

	assign egress_port_0_tdata = 16'b0000000000000000;

	assign egress_port_0_tlast = 1'b0;

	assign egress_port_1_tvalid = 1'b0;

	assign egress_port_1_tdata = 16'b0000000000000000;

	assign egress_port_1_tlast = 1'b0;

	assign egress_port_2_tvalid = 1'b0;

	assign egress_port_2_tdata = 16'b0000000000000000;

	assign egress_port_2_tlast = 1'b0;

	assign egress_port_3_tvalid = 1'b0;

	assign egress_port_3_tdata = 16'b0000000000000000;

	assign egress_port_3_tlast = 1'b0;

	assign irq = 1'b0;

endmodule
