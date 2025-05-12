// packet_filter.sv

/**
 * Register mapping
 *
 * Addr / mode | Name               | Meaning
 *        0RW  |  ingress_port_mask |  Enable signal for input ports (active-high).
 *        4R   |        in_pkts_in0 |  Number of 16-byte packets received by ingress port 0
 *        5R   |        in_pkts_in1 |  Number of 16-byte packets received by ingress port 1
 *        6R   |        in_pkts_in2 |  Number of 16-byte packets received by ingress port 2
 *        7R   |        in_pkts_in3 |  Number of 16-byte packets received by ingress port 3
 *        8R   |    transf_pkts_in0 |  Number of 16-byte packets transferred from ingress port 0
 *        9R   |    transf_pkts_in1 |  Number of 16-byte packets transferred from ingress port 1
 *       10R   |    transf_pkts_in2 |  Number of 16-byte packets transferred from ingress port 2
 *       11R   |    transf_pkts_in3 |  Number of 16-byte packets transferred from ingress port 3
 *       12R   |      in_frames_in0 |  Number of complete frames received by ingress port 0
 *       13R   |      in_frames_in1 |  Number of complete frames received by ingress port 1
 *       14R   |      in_frames_in2 |  Number of complete frames received by ingress port 2
 *       15R   |      in_frames_in3 |  Number of complete frames received by ingress port 3
 *       16R   |  transf_frames_in0 |  Number of frames transferred from ingress port 0
 *       17R   |  transf_frames_in1 |  Number of frames transferred from ingress port 1
 *       18R   |  transf_frames_in2 |  Number of frames transferred from ingress port 2
 *       19R   |  transf_frames_in3 |  Number of frames transferred from ingress port 3
 *       20R   |     inv_frames_in0 |  Number of frames detected as invalid from ingress port 0
 *       21R   |     inv_frames_in1 |  Number of frames detected as invalid from ingress port 1
 *       22R   |     inv_frames_in2 |  Number of frames detected as invalid from ingress port 2
 *       23R   |     inv_frames_in3 |  Number of frames detected as invalid from ingress port 3
 *       24R   |    drop_frames_in0 |  Number of dropped frames from ingress port 0
 *       25R   |    drop_frames_in1 |  Number of dropped frames from ingress port 1
 *       26R   |    drop_frames_in2 |  Number of dropped frames from ingress port 2
 *       27R   |    drop_frames_in3 |  Number of dropped frames from ingress port 3
 */

`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`include "../include/synth_defs.svh"
`endif
`include "filter_defs.svh"

`ifdef TOP_TESTING

`timescale 1 ps / 1 ps
module packet_filter #(
        parameter STUBBING = `STUBBING_PASSTHROUGH,
        parameter ALMOST_FULL_THRESHOLD = 10,
        parameter ADDR_WIDTH = 11,
        parameter NUM_CYCLONE_5CSEMA5_BLOCKS = 4,
        parameter TIMEOUT_CTR_WIDTH = 3
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
    logic [31:0] readdata_int;
    logic [`NUM_INGRESS_PORTS-1:0] ingress_port_mask;

    // counter increment signals
    logic [`NUM_INGRESS_PORTS-1:0] invalid_frame;
    logic [`NUM_INGRESS_PORTS-1:0] timeout_req;

    // counters
    logic [1:0] counter_address;
    logic [31:0]       in_pkts [`NUM_INGRESS_PORTS-1:0];
    logic [31:0]   transf_pkts [`NUM_INGRESS_PORTS-1:0];
    logic [31:0]     in_frames [`NUM_INGRESS_PORTS-1:0];
    logic [31:0] transf_frames [`NUM_INGRESS_PORTS-1:0];
    logic [31:0]    inv_frames [`NUM_INGRESS_PORTS-1:0];
    logic [31:0]   drop_frames [`NUM_INGRESS_PORTS-1:0];

    /* Convert between Avalon wires and internal structures. */

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

    /* Functionality. */

generate
if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough

    // output AXIS assignments
	assign ingress_port_sink[0].tready  = egress_port_sink[0].tready;
	assign ingress_port_sink[1].tready  = egress_port_sink[1].tready;
	assign ingress_port_sink[2].tready  = egress_port_sink[2].tready;
	assign ingress_port_sink[3].tready  = egress_port_sink[3].tready;
	assign egress_port_source[0].tvalid = ingress_port_source[0].tvalid;
	assign egress_port_source[0].tdest  = '0;
	assign egress_port_source[0].tdata  = ingress_port_source[0].tdata;
	assign egress_port_source[0].tlast  = ingress_port_source[0].tlast;
	assign egress_port_source[1].tvalid = ingress_port_source[1].tvalid;
	assign egress_port_source[1].tdest  = '0;
	assign egress_port_source[1].tdata  = ingress_port_source[1].tdata;
	assign egress_port_source[1].tlast  = ingress_port_source[1].tlast;
	assign egress_port_source[2].tvalid = ingress_port_source[2].tvalid;
	assign egress_port_source[2].tdest  = '0;
	assign egress_port_source[2].tdata  = ingress_port_source[2].tdata;
	assign egress_port_source[2].tlast  = ingress_port_source[2].tlast;
	assign egress_port_source[3].tvalid = ingress_port_source[3].tvalid;
	assign egress_port_source[3].tdest  = '0;
	assign egress_port_source[3].tdata  = ingress_port_source[3].tdata;
	assign egress_port_source[3].tlast  = ingress_port_source[3].tlast;

	assign invalid_frame = '0;
	assign timeout_req = '0;

end else begin: g_functional

	ingress_filter #(
            .STUBBING(STUBBING),
            .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD),
            .ADDR_WIDTH(ADDR_WIDTH),
            .NUM_CYCLONE_5CSEMA5_BLOCKS(NUM_CYCLONE_5CSEMA5_BLOCKS),
            .TIMEOUT_CTR_WIDTH(TIMEOUT_CTR_WIDTH)
        ) u_filter[`NUM_INGRESS_PORTS-1:0] (
	    .clk  (clk),
	    .reset(reset),

	    .en(ingress_port_mask),

	    .ingress_source(ingress_port_source),
	    .ingress_sink  (ingress_port_sink),

	    .egress_source(egress_port_source),
	    .egress_sink  (egress_port_sink),

	    .drop_write(invalid_frame),
	    .timeout(timeout_req)
	);
end
endgenerate

    /* Register interface. */

    // register write interface
    always_ff @(posedge clk) begin
        if (reset) begin
            ingress_port_mask <= 4'b0;
        end else if (chipselect && write) begin
            case (address)
                8'h0 : ingress_port_mask <= writedata[3:0];
                default : ingress_port_mask <= ingress_port_mask;
            endcase
        end
    end

    // register read interface
    assign readdata = readdata_int;
    assign counter_address = address[1:0];
    always_ff @(posedge clk) begin
        if (reset) begin
            readdata_int <= 32'b0;
        end else if (chipselect && read) begin
            case (address[7:2])
                6'h0 : readdata_int <= {28'b0, ingress_port_mask};
                6'h1 : readdata_int <= in_pkts[counter_address];
                6'h2 : readdata_int <= transf_pkts[counter_address];
                6'h3 : readdata_int <= in_frames[counter_address];
                6'h4 : readdata_int <= transf_frames[counter_address];
                6'h5 : readdata_int <= inv_frames[counter_address];
                6'h6 : readdata_int <= drop_frames[counter_address];
                default : readdata_int <= '0;
            endcase
        end
    end

    // counters
    genvar i;
    generate
    for (i = 0; i < 4; ++i) begin: g_ingress_count
        always_ff @(posedge clk) begin
            if (reset) begin
                in_pkts[i] <= 32'b0;
                transf_pkts[i] <= 32'b0;
                in_frames[i] <= 32'b0;
                transf_frames[i] <= 32'b0;
                inv_frames[i] <= 32'b0;
                drop_frames[i] <= 32'b0;
            end else begin
                // accepted ingress packets
                if (ingress_port_source[i].tvalid & ingress_port_sink[i].tready) begin
                    in_pkts[i] <= in_pkts[i] + 1;
                end else begin
                    in_pkts[i] <= in_pkts[i];
                end

                // transferred ingress packets
                if (egress_port_source[i].tvalid & egress_port_sink[i].tready) begin
                    transf_pkts[i] <= transf_pkts[i] + 1;
                end else begin
                    transf_pkts[i] <= transf_pkts[i];
                end

                // accepted ingress frames
                if (ingress_port_source[i].tvalid & ingress_port_source[i].tlast & ingress_port_sink[i].tready) begin
                    in_frames[i] <= in_frames[i] + 1;
                end else begin
                    in_frames[i] <= in_frames[i];
                end

                // transferred ingress frames
                if (egress_port_source[i].tvalid & egress_port_source[i].tlast & egress_port_sink[i].tready) begin
                    transf_frames[i] <= transf_frames[i] + 1;
                end else begin
                    transf_frames[i] <= transf_frames[i];
                end

                // invalid frames
                if (invalid_frame[i]) begin
                    inv_frames[i] <= inv_frames[i] + 1;
                end else begin
                    inv_frames[i] <= inv_frames[i];
                end

                // dropped requests
                if (timeout_req[i]) begin
                    drop_frames[i] <= drop_frames[i] + 1;
                end else begin
                    drop_frames[i] <= drop_frames[i];
                end
            end
        end
    end
    endgenerate

	// interrupt interface
	assign irq = 1'b0;

endmodule

`endif
