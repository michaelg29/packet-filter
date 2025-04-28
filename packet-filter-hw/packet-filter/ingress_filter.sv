
`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module ingress_filter #(
        parameter STUBBING = `STUBBING_PASSTHROUGH
    ) (
		input  logic       clk,
		input  logic       reset,

		input  logic       en,

		input  axis_source_t ingress_source,
		output axis_sink_t   ingress_sink,

		output axis_d_source_t egress_source,
		input  axis_d_sink_t   egress_sink
	);

    /*
     * Wires
     */

    axis_source_t ingress_source_q;

    /*
     * Register logic
     */
    always_ff @(posedge clk) begin
        if (reset) begin
            egress_source.tvalid <= 1'b0;
            egress_source.tdata <= 16'b0;
            egress_source.tdest <= 2'b0;
            egress_source.tlast <= 1'b0;
            ingress_sink.tready <= 1'b0;
        end else begin
            egress_source <= ingress_source;
            ingress_sink  <= ingress_sink;
        end
    end


endmodule
