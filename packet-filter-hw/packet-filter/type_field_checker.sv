
`include "packet_filter.svh"
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module type_field_checker (
    input  logic clk,
    input  logic reset,

    input  packet_source_t type_pkt,

    output drop_source_t drop
);

    packet_source_t type_pkt_q;
    logic valid_output, invalid_type;

    // validate type field
    always_ff @(posedge clk) begin
        if (reset) begin
            valid_output <= 1'b0;
            invalid_type <= 1'b0;
        end else begin
            valid_output <= type_pkt.tvalid;
            if (!(type_pkt.tdata < 16'h05DC || type_pkt.tdata > 16'h0600)) begin
                invalid_type <= 1'b1;
            end else begin
                invalid_type <= 1'b0;
            end
        end
    end

    // assign output
    assign drop.tvalid = valid_output;
    assign drop.tuser  = invalid_type;

endmodule
