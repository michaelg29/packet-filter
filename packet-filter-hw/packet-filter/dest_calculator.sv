
`include "packet_filter.svh"
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module dest_calculator (
    input  logic clk,
    input  logic reset,

    input  packet_source_t dst_mac_pkt,

    output dest_source_t dest
);

    logic [15:0] dst_mac [2:0];
    logic [15:0] next_dst_mac [2:0];
    logic [ 1:0] cnt, next_cnt;
    logic        valid_output, invalid_dst_mac;

    // latch new state
    always_ff @(posedge clk) begin
        if (reset) begin
            dst_mac[0] <= 16'h0;
            dst_mac[1] <= 16'h0;
            dst_mac[2] <= 16'h0;
            cnt <= 2'b0;
        end else begin
            dst_mac <= next_dst_mac;
            cnt <= next_cnt;
        end
    end

    // shift in new bytes when scanning the destination MAC field
    always_comb begin: g_next_dst
        if (dst_mac_pkt.tvalid) begin
            next_dst_mac[2] = dst_mac[1];
            next_dst_mac[1] = dst_mac[0];
            next_dst_mac[0] = dst_mac_pkt.tdata;
        end else begin
            next_dst_mac = dst_mac;
        end
    end

    // increment counter
    always_comb begin: g_next_cnt
        if (cnt === 2'b11) begin
            next_cnt = dst_mac_pkt.tvalid ? 2'b01 : 2'b00;
        end else if (dst_mac_pkt.tvalid) begin
            next_cnt = cnt + 1;
        end else begin
            next_cnt = cnt;
        end
    end

    // set invalid bit when tdest_valid is high
    always_comb begin: g_invalid_detection
        if (cnt === 2'b11) begin
            valid_output = 1'b1;
            if (dst_mac[2][15:14] === 2'b11) begin
                invalid_dst_mac = 1'b1;
            end else begin
                invalid_dst_mac = 1'b0;
            end
        end else begin
            valid_output = 1'b0;
            invalid_dst_mac = 1'b0;
        end
    end

    assign dest.tdata  = dst_mac[0][1:0];
    assign dest.tvalid = valid_output;
    assign dest.tuser  = invalid_dst_mac;

endmodule
