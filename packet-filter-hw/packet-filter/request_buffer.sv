
`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif
`include "filter_defs.svh"

// Integrate sideband_buffer, frame_buffer, and switch_requester
`timescale 1 ps / 1 ps
module request_buffer #(
    parameter STUBBING = `STUBBING_PASSTHROUGH,
    parameter ALMOST_FULL_THRESHOLD = 10,
    parameter ADDR_WIDTH = 11,
    parameter NUM_CYCLONE_5CSEMA5_BLOCKS = 4,
    parameter TIMEOUT_CTR_WIDTH = 3
) (
    input  logic clk,
    input  logic reset,

    input  frame_status status,
    input  drop_source_t frame_type,
    input  dest_source_t frame_dest,
    input  axis_source_t ingress_pkt,

    output logic drop_write,
    output logic almost_full,

    output axis_d_source_t egress_source,
	input  axis_d_sink_t   egress_sink

);

    logic [ADDR_WIDTH:0] frame_wptr;

    logic sideband_ren;
    logic sideband_empty;
    logic [19:0] sideband_rdata;
    logic sideband_full;

    logic                frame_ren;
    logic                frame_rrst;
    logic [ADDR_WIDTH:0] frame_rptr;
    logic [ADDR_WIDTH:0] frame_rst_rptr;
    logic         [19:0] frame_rdata;
    logic                frame_last_entry;
    logic                frame_almost_full;

    // output assignments
    assign almost_full = sideband_full | frame_almost_full;

    // sideband buffer
    sideband_buffer #(
        .STUBBING(STUBBING),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_sideband (
        .clk(clk),
        .reset(reset),
        .scan_frame(status.scan_frame),
        .scan_payload(status.scan_payload),
        .frame_type(frame_type),
        .frame_drop(drop_write),
        .frame_dest(frame_dest),
        .frame_wptr(frame_wptr),
        .ren(sideband_ren),
        .empty(sideband_empty),
        .rdata(sideband_rdata),
        .full(sideband_full)
    );

    // frame buffer
    frame_buffer #(
        .STUBBING(STUBBING),
        .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_CYCLONE_5CSEMA5_BLOCKS(NUM_CYCLONE_5CSEMA5_BLOCKS)
    ) u_frame (
        .clk(clk),
        .reset(reset),
        .ingress_pkt(ingress_pkt),
        .scan_frame(status.scan_frame),
        .drop_write(drop_write),
        .almost_full(frame_almost_full),
        .frame_ren(frame_ren),
        .frame_rrst(frame_rrst),
        .frame_rst_rptr(frame_rst_rptr),
        .frame_rptr(frame_rptr),
        .frame_rdata(frame_rdata),
        .last_entry(frame_last_entry)
    );

    // switch requester
    switch_requester #(
        .STUBBING(STUBBING),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TIMEOUT_CTR_WIDTH(TIMEOUT_CTR_WIDTH)
    ) u_requester (
        .clk(clk),
        .reset(reset),
        .scan_payload(status.scan_payload),
        .sideband_rdata(sideband_rdata),
        .sideband_empty(sideband_empty),
        .sideband_ren(sideband_ren),
        .frame_rdata(frame_rdata),
        .frame_last_entry(frame_last_entry),
        .frame_rptr(frame_rptr),
        .frame_ren(frame_ren),
        .frame_rrst(frame_rrst),
        .frame_rst_rptr(frame_rst_rptr),
        .egress_sink(egress_sink),
        .egress_source(egress_source)
    );

endmodule
