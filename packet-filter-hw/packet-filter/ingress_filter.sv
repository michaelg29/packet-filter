
`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif
`include "filter_defs.svh"

`ifdef TOP_TESTING

// Integrate preliminary_processor and request_buffer
`timescale 1 ps / 1 ps
module ingress_filter #(
        parameter STUBBING = `STUBBING_PASSTHROUGH,
        parameter ALMOST_FULL_THRESHOLD = 10,
        parameter ADDR_WIDTH = 11,
        parameter NUM_CYCLONE_5CSEMA5_BLOCKS = 4,
        parameter TIMEOUT_CTR_WIDTH = 3
    ) (
		input  logic       clk,
		input  logic       reset,

		input  logic       en,

		input  axis_source_t ingress_source,
		output axis_sink_t   ingress_sink,

		output axis_d_source_t egress_source,
		input  axis_d_sink_t   egress_sink,

		// status signals
		output logic drop_write,
		output logic timeout
	);

    /*
     * Wires
     */

    axis_source_t ingress_source_q;

    /*
     * Register logic
     */
generate
if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough
    always_ff @(posedge clk) begin
        if (reset) begin
            egress_source.tvalid <= 1'b0;
            egress_source.tdata <= 16'b0;
            egress_source.tdest <= 2'b0;
            egress_source.tlast <= 1'b0;
            ingress_sink.tready <= 1'b0;
        end else begin
            egress_source.tvalid <= ingress_source.tvalid;
            egress_source.tdata <= ingress_source.tdata;
            egress_source.tdest <= 2'b0;
            egress_source.tlast <= ingress_source.tlast;
            ingress_sink <= egress_sink;
        end
    end

end else begin: g_functional

    axis_source_t ingress_pkt;
    logic almost_full;
    frame_status status;
    dest_source_t frame_dest;
    drop_source_t frame_type;

    preliminary_processor #(
        .STUBBING(STUBBING)
    ) u_processor (
        .clk(clk),
        .reset(reset),
        .ingress_source(ingress_source),
        .ingress_sink(ingress_sink),
        .ingress_pkt(ingress_pkt),
        .drop_write(drop_write),
        .almost_full(almost_full),
        .status(status),
        .frame_dest(frame_dest),
        .frame_type(frame_type)
    );

    request_buffer #(
        .STUBBING(STUBBING),
        .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_CYCLONE_5CSEMA5_BLOCKS(NUM_CYCLONE_5CSEMA5_BLOCKS),
        .TIMEOUT_CTR_WIDTH(TIMEOUT_CTR_WIDTH)
    ) u_requester (
        .clk(clk),
        .reset(reset),
        .status(status),
        .frame_type(frame_type),
        .frame_dest(frame_dest),
        .ingress_pkt(ingress_pkt),
        .drop_write(drop_write),
        .almost_full(almost_full),
        .timeout(timeout),
        .egress_source(egress_source),
        .egress_sink(egress_sink)
    );

end
endgenerate

endmodule

`endif
