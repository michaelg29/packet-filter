// packet_filter.sv

/**
 * Register mapping
 *
 * Byte / mode | Name               | Meaning
 *        0RW  |  ingress_port_mask |  Enable signal for input ports (active-high).
 */

`include "../include/packet_filter.svh"

`timescale 1 ps / 1 ps
module packet_filter #(
        parameter STUBBING = `STUBBING_PASSTHROUGH
    ) (
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
		output wire [1:0]  egress_port_0_tdest,   //                        .tdest
		output wire [15:0] egress_port_1_tdata,   //           egress_port_1.tdata
		output wire        egress_port_1_tlast,   //                        .tlast
		input  wire        egress_port_1_tready,  //                        .tready
		output wire        egress_port_1_tvalid,  //                        .tvalid
		output wire [1:0]  egress_port_1_tdest,   //                        .tdest
		output wire [15:0] egress_port_2_tdata,   //           egress_port_2.tdata
		output wire        egress_port_2_tlast,   //                        .tlast
		input  wire        egress_port_2_tready,  //                        .tready
		output wire        egress_port_2_tvalid,  //                        .tvalid
		output wire [1:0]  egress_port_2_tdest,   //                        .tdest
		output wire [15:0] egress_port_3_tdata,   //           egress_port_3.tdata
		output wire        egress_port_3_tlast,   //                        .tlast
		input  wire        egress_port_3_tready,  //                        .tready
		output wire        egress_port_3_tvalid,  //                        .tvalid
		output wire [1:0]  egress_port_3_tdest,   //                        .tdest
		output wire        irq                    // packet_filter_interrupt.irq
	);

    // registers
    logic [`NUM_INGRESS_PORTS-1:0] ingress_port_mask;

generate
if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough

    // output AXIS assignments
	assign ingress_port_0_tready = egress_port_0_tready;
	assign ingress_port_1_tready = egress_port_1_tready;
	assign ingress_port_2_tready = egress_port_2_tready;
	assign ingress_port_3_tready = egress_port_3_tready;
	assign egress_port_0_tvalid  = ingress_port_0_tvalid;
	assign egress_port_0_tdest   = ingress_port_0_tdest;
	assign egress_port_0_tdata   = ingress_port_0_tdata;
	assign egress_port_0_tlast   = ingress_port_0_tlast;
	assign egress_port_1_tvalid  = ingress_port_1_tvalid;
	assign egress_port_1_tdest   = ingress_port_1_tdest;
	assign egress_port_1_tdata   = ingress_port_1_tdata;
	assign egress_port_1_tlast   = ingress_port_1_tlast;
	assign egress_port_2_tvalid  = ingress_port_2_tvalid;
	assign egress_port_2_tdest   = ingress_port_2_tdest;
	assign egress_port_2_tdata   = ingress_port_2_tdata;
	assign egress_port_2_tlast   = ingress_port_2_tlast;
	assign egress_port_3_tvalid  = ingress_port_3_tvalid;
	assign egress_port_3_tdest   = ingress_port_3_tdest;
	assign egress_port_3_tdata   = ingress_port_3_tdata;
	assign egress_port_3_tlast   = ingress_port_3_tlast;

end else begin: g_functional

	// internal AXIS wires
	axis_source_t   ingress_port_source [`NUM_INGRESS_PORTS-1:0];
	axis_sink_t     ingress_port_sink   [`NUM_INGRESS_PORTS-1:0];
	axis_d_source_t egress_port_source  [`NUM_INGRESS_PORTS-1:0];
	axis_d_sink_t   egress_port_sink    [`NUM_INGRESS_PORTS-1:0];

	// intermediate assignments
    assign ingress_port_source[0].tvalid = ingress_port_0_tvalid;
    assign ingress_port_source[0].tdata  = ingress_port_0_tdata;
    assign ingress_port_source[0].tlast  = ingress_port_0_tlast;
    assign ingress_port_source[1].tvalid = ingress_port_1_tvalid;
    assign ingress_port_source[1].tdata  = ingress_port_1_tdata;
    assign ingress_port_source[1].tlast  = ingress_port_1_tlast;
    assign ingress_port_source[2].tvalid = ingress_port_2_tvalid;
    assign ingress_port_source[2].tdata  = ingress_port_2_tdata;
    assign ingress_port_source[2].tlast  = ingress_port_2_tlast;
    assign ingress_port_source[3].tvalid = ingress_port_3_tvalid;
    assign ingress_port_source[3].tdata  = ingress_port_3_tdata;
    assign ingress_port_source[3].tlast  = ingress_port_3_tlast;
	assign egress_port_sink[0].tready = egress_port_0_tready;
	assign egress_port_sink[1].tready = egress_port_1_tready;
	assign egress_port_sink[2].tready = egress_port_2_tready;
	assign egress_port_sink[3].tready = egress_port_3_tready;

    // output AXIS assignments
	assign ingress_port_0_tready = ingress_port_sink[0].tready;
	assign ingress_port_1_tready = ingress_port_sink[1].tready;
	assign ingress_port_2_tready = ingress_port_sink[2].tready;
	assign ingress_port_3_tready = ingress_port_sink[3].tready;
	assign egress_port_0_tvalid  = egress_port_source[0].tvalid;
	assign egress_port_0_tdest   = egress_port_source[0].tdest;
	assign egress_port_0_tdata   = egress_port_source[0].tdata;
	assign egress_port_0_tlast   = egress_port_source[0].tlast;
	assign egress_port_1_tvalid  = egress_port_source[1].tvalid;
	assign egress_port_1_tdest   = egress_port_source[1].tdest;
	assign egress_port_1_tdata   = egress_port_source[1].tdata;
	assign egress_port_1_tlast   = egress_port_source[1].tlast;
	assign egress_port_2_tvalid  = egress_port_source[2].tvalid;
	assign egress_port_2_tdest   = egress_port_source[2].tdest;
	assign egress_port_2_tdata   = egress_port_source[2].tdata;
	assign egress_port_2_tlast   = egress_port_source[2].tlast;
	assign egress_port_3_tvalid  = egress_port_source[3].tvalid;
	assign egress_port_3_tdest   = egress_port_source[3].tdest;
	assign egress_port_3_tdata   = egress_port_source[3].tdata;
	assign egress_port_3_tlast   = egress_port_source[3].tlast;

	ingress_filter #() u_filter[`NUM_INGRESS_PORTS-1:0] (
	    .clk  (clk),
	    .reset(reset),

	    .en(ingress_port_mask),

	    .ingress_source(ingress_port_source),
	    .ingress_sink  (ingress_port_sink),

	    .egress_source(egress_port_source),
	    .egress_sink  (egress_port_sink)
	);
end
endgenerate

    // register write interface
	assign readdata = 8'b00000000;
    always_ff @(posedge clk) begin
        if (reset) begin
            ingress_port_mask <= 4'b0;
        end else if (chipselect && write) begin
            case (address)
                8'h0 : ingress_port_mask <= writedata[3:0];
            endcase
        end
    end

    // register read interface
    always_ff @(posedge clk) begin
        if (reset) begin
            readdata <= 8'b0;
        end else if (chipselect && read) begin
            case (address)
                8'h0 : readdata <= {4'b0, ingress_port_mask};
            endcase
        end
    end

	// interrupt interface
	assign irq = 1'b0;

endmodule
