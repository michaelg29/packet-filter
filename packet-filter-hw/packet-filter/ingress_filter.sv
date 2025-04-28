
`include "packet_filter.svh"
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module ingress_filter (
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
            ingress_source_q.tvalid <= 1'b0;
            ingress_source_q.tdata <= 16'b0;
            ingress_source_q.tlast <= 1'b0;
            egress_sink_q.tready <= 1'b0;
        end else begin
            ingress_source_q <= ingress_source;
            egress_sink_q    <= egress_sink;
        end
    end


endmodule
