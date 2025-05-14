// packet_filter.sv

/* verilator lint_off PINCONNECTEMPTY */

`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "./include/packet_filter.svh"
`include "./include/synth_defs.svh"
`endif

`timescale 1 ps / 1 ps
module packet_filter_switch #(
        // almost full when cannot store another full-sized frame
        parameter ALMOST_FULL_THRESHOLD = 760,
        // address 2048 words
        parameter ADDR_WIDTH = 11,
        parameter NUM_CYCLONE_5CSEMA5_BLOCKS = 4,
        // timeout after 512 waiting cycles
        parameter TIMEOUT_CTR_WIDTH = 9
    ) (
		input  wire        clk,                   //                   clock.clk
		input  wire        reset,                 //                   reset.reset
		input  wire [31:0] writedata,             //          avalon_slave_0.writedata
		input  wire        write,                 //                        .write
		input  wire        chipselect,            //                        .chipselect
		input  wire [7:0]  address,               //                        .address
		input  wire        read,                  //                        .read
		output wire [31:0] readdata,              //                        .readdata
		input  wire [15:0] ingress_port_0_tdata,  //          ingress_port_0.tdata
		input  wire        ingress_port_0_tvalid, //                        .tvalid
		output wire        ingress_port_0_tready, //                        .tready
		input  wire        ingress_port_0_tlast,  //                        .tlast
		input  wire [15:0] ingress_port_1_tdata,  //          ingress_port_1.tdata
		input  wire        ingress_port_1_tlast,  //                        .tlast
		input  wire        ingress_port_1_tvalid, //                        .tvalid
		output wire        ingress_port_1_tready, //                        .tready
		input  wire [15:0] ingress_port_2_tdata,  //          ingress_port_2.tdata
		input  wire        ingress_port_2_tlast,  //                        .tlast
		input  wire        ingress_port_2_tvalid, //                        .tvalid
		output wire        ingress_port_2_tready, //                        .tready
		input  wire [15:0] ingress_port_3_tdata,  //          ingress_port_3.tdata
		output wire        ingress_port_3_tready, //                        .tready
		input  wire        ingress_port_3_tlast,  //                        .tlast
		input  wire        ingress_port_3_tvalid, //                        .tvalid
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

	wire [15:0] immd_port_0_tdata;
    wire        immd_port_0_tlast;
    wire        immd_port_0_tready;
    wire        immd_port_0_tvalid;
    wire  [1:0] immd_port_0_tdest;
    wire [15:0] immd_port_1_tdata;
    wire        immd_port_1_tlast;
    wire        immd_port_1_tready;
    wire        immd_port_1_tvalid;
    wire  [1:0] immd_port_1_tdest;
    wire [15:0] immd_port_2_tdata;
    wire        immd_port_2_tlast;
    wire        immd_port_2_tready;
    wire        immd_port_2_tvalid;
    wire  [1:0] immd_port_2_tdest;
    wire [15:0] immd_port_3_tdata;
    wire        immd_port_3_tlast;
    wire        immd_port_3_tready;
    wire        immd_port_3_tvalid;
    wire  [1:0] immd_port_3_tdest;


	packet_filter #(
	    .STUBBING(1),
	    .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_CYCLONE_5CSEMA5_BLOCKS(NUM_CYCLONE_5CSEMA5_BLOCKS),
        .TIMEOUT_CTR_WIDTH(TIMEOUT_CTR_WIDTH)
	) u_filter (
	    .clk(clk),
	    .reset(reset),
	    .writedata(writedata),
        .write(write),
        .chipselect(chipselect),
        .address(address),
        .read(read),
        .readdata(readdata),

        .ingress_port_0_tdata (ingress_port_0_tdata ),
        .ingress_port_0_tvalid(ingress_port_0_tvalid),
        .ingress_port_0_tready(ingress_port_0_tready),
        .ingress_port_0_tlast (ingress_port_0_tlast ),
        .ingress_port_1_tdata (ingress_port_1_tdata ),
        .ingress_port_1_tlast (ingress_port_1_tlast ),
        .ingress_port_1_tvalid(ingress_port_1_tvalid),
        .ingress_port_1_tready(ingress_port_1_tready),
        .ingress_port_2_tdata (ingress_port_2_tdata ),
        .ingress_port_2_tlast (ingress_port_2_tlast ),
        .ingress_port_2_tvalid(ingress_port_2_tvalid),
        .ingress_port_2_tready(ingress_port_2_tready),
        .ingress_port_3_tdata (ingress_port_3_tdata ),
        .ingress_port_3_tready(ingress_port_3_tready),
        .ingress_port_3_tlast (ingress_port_3_tlast ),
        .ingress_port_3_tvalid(ingress_port_3_tvalid),

        .egress_port_0_tdata (immd_port_0_tdata),
        .egress_port_0_tlast (immd_port_0_tlast),
        .egress_port_0_tready(immd_port_0_tready),
        .egress_port_0_tvalid(immd_port_0_tvalid),
        .egress_port_0_tdest (immd_port_0_tdest),
        .egress_port_1_tdata (immd_port_1_tdata),
        .egress_port_1_tlast (immd_port_1_tlast),
        .egress_port_1_tready(immd_port_1_tready),
        .egress_port_1_tvalid(immd_port_1_tvalid),
        .egress_port_1_tdest (immd_port_1_tdest),
        .egress_port_2_tdata (immd_port_2_tdata),
        .egress_port_2_tlast (immd_port_2_tlast),
        .egress_port_2_tready(immd_port_2_tready),
        .egress_port_2_tvalid(immd_port_2_tvalid),
        .egress_port_2_tdest (immd_port_2_tdest),
        .egress_port_3_tdata (immd_port_3_tdata),
        .egress_port_3_tlast (immd_port_3_tlast),
        .egress_port_3_tready(immd_port_3_tready),
        .egress_port_3_tvalid(immd_port_3_tvalid),
        .egress_port_3_tdest (immd_port_3_tdest),

	    .irq(irq)
	);

	packet_switch #(
        .N_PORTS(4),
        .DATA_WIDTH(16),
        .IDX_WIDTH(2),
        .STUBBING(1)
    ) u_switch (
	    .clk(clk),
	    .reset(reset),
	    .writedata(32'b0),
	    .write(1'b0),
	    .chipselect(1'b0),
	    .address(8'b0),
	    .read(1'b0),
	    .readdata(),

        .ingress_port_0_tdata (immd_port_0_tdata),
        .ingress_port_0_tvalid(immd_port_0_tvalid),
        .ingress_port_0_tlast (immd_port_0_tlast),
        .ingress_port_0_tdest (immd_port_0_tdest),
        .ingress_port_0_tready(immd_port_0_tready),
        .ingress_port_1_tdata (immd_port_1_tdata),
        .ingress_port_1_tvalid(immd_port_1_tvalid),
        .ingress_port_1_tlast (immd_port_1_tlast),
        .ingress_port_1_tdest (immd_port_1_tdest),
        .ingress_port_1_tready(immd_port_1_tready),
        .ingress_port_2_tdata (immd_port_2_tdata),
        .ingress_port_2_tvalid(immd_port_2_tvalid),
        .ingress_port_2_tlast (immd_port_2_tlast),
        .ingress_port_2_tdest (immd_port_2_tdest),
        .ingress_port_2_tready(immd_port_2_tready),
        .ingress_port_3_tdata (immd_port_3_tdata),
        .ingress_port_3_tvalid(immd_port_3_tvalid),
        .ingress_port_3_tlast (immd_port_3_tlast),
        .ingress_port_3_tdest (immd_port_3_tdest),
        .ingress_port_3_tready(immd_port_3_tready),

        .egress_port_0_tdata (egress_port_0_tdata ),
        .egress_port_0_tvalid(egress_port_0_tvalid),
        .egress_port_0_tlast (egress_port_0_tlast ),
        .egress_port_0_tready(egress_port_0_tready),
        .egress_port_1_tdata (egress_port_1_tdata ),
        .egress_port_1_tvalid(egress_port_1_tvalid),
        .egress_port_1_tlast (egress_port_1_tlast ),
        .egress_port_1_tready(egress_port_1_tready),
        .egress_port_2_tdata (egress_port_2_tdata ),
        .egress_port_2_tvalid(egress_port_2_tvalid),
        .egress_port_2_tlast (egress_port_2_tlast ),
        .egress_port_2_tready(egress_port_2_tready),
        .egress_port_3_tdata (egress_port_3_tdata ),
        .egress_port_3_tvalid(egress_port_3_tvalid),
        .egress_port_3_tlast (egress_port_3_tlast ),
        .egress_port_3_tready(egress_port_3_tready),

        // Unused IRQ
        .irq()
    );

endmodule

/* verilator lint_on PINCONNECTEMPTY */
