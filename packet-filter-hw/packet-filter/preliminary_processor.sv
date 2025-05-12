
`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`include "../include/synth_defs.svh"
`endif
`include "filter_defs.svh"

`ifdef INTG_TESTING_1

// Integrate input_fsm, type_field_checker, and dest_calculator
`timescale 1 ps / 1 ps
module preliminary_processor #(
    parameter STUBBING = `STUBBING_PASSTHROUGH
) (
    input  logic clk,
    input  logic reset,

    input  axis_source_t ingress_source,
    output axis_sink_t   ingress_sink,
    output axis_source_t ingress_pkt,

    input  logic drop_write,
    input  logic almost_full,
    output frame_status status,
    output dest_source_t frame_dest,
    output drop_source_t frame_type

);

    frame_status f_status;
    packet_source_t dst_mac_source;
    packet_source_t type_source;

    assign status = f_status;
    assign dst_mac_source.tvalid = ingress_pkt.tvalid & f_status.scan_dst_mac;
    assign dst_mac_source.tdata = ingress_pkt.tdata;
    assign type_source.tvalid = ingress_pkt.tvalid & f_status.scan_type;
    assign type_source.tdata = ingress_pkt.tdata;

    // input FSM
    input_fsm #(
        .STUBBING(STUBBING)
    ) u_input_fsm (
        .clk(clk),
        .reset(reset),
        .ingress_source(ingress_source),
        .ingress_sink(ingress_sink),
        .drop_current(drop_write),
        .almost_full(almost_full),
        .ingress_pkt(ingress_pkt),
/* verilator lint_off PINCONNECTEMPTY */
        .incomplete_frame(), // TODO evaluate if need this
/* verilator lint_on PINCONNECTEMPTY */
        .status(f_status)
    );

    // destination calculator
    dest_calculator #(
        .STUBBING(STUBBING)
    ) u_dest_calculator (
        .clk(clk),
        .reset(reset),
        .dst_mac_pkt(dst_mac_source),
        .dest(frame_dest)
    );

    // type checker
    type_field_checker #(
        .STUBBING(STUBBING)
    ) u_type_checker (
        .clk(clk),
        .reset(reset),
        .type_pkt(type_source),
        .drop(frame_type)
    );

`ifdef ASSERT

    // assert grant is held for an entire frame
    assertion_preliminary_processor_frame_grant : assert property(
        @(posedge clk) disable iff (reset)
        ingress_source.tvalid & ingress_sink.tready & ~ingress_pkt.tlast
            |=> ingress_sink.tready || ingress_source.tlast
    ) else $error($sformatf("assertion_preliminary_processor_frame_grant failed at %0t", $realtime));

    // do not provide grants if almost full
    assertion_preliminary_processor_almost_full : assert property(
        @(posedge clk) disable iff (reset)
        almost_full && (~ingress_source.tvalid || ingress_pkt.tlast)
            |=> ~ingress_sink.tready
    ) else $error($sformatf("assertion_preliminary_processor_almost_full failed at %0t", $realtime));


`endif

endmodule

`endif
