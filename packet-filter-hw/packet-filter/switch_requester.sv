
`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module switch_requester #(
    parameter STUBBING = `STUBBING_PASSTHROUGH,
    parameter ADDR_WIDTH = 11,
    parameter TIMEOUT_CTR_WIDTH = 3
) (
    // clock and reset
    input  logic clk,
    input  logic reset,

    // frame status
    input  logic scan_payload,
    output logic timeout,

    // sideband buffer
    input  logic [19:0] sideband_rdata,
    input  logic sideband_empty,
    output logic sideband_ren,

    // frame buffer
    input  logic [19:0]         frame_rdata,
    input  logic                frame_last_entry,
    input  logic [ADDR_WIDTH:0] frame_rptr,
    output logic                frame_ren,
    output logic                frame_rrst,
    output logic [ADDR_WIDTH:0] frame_rst_rptr,

    // egress interface
    input  axis_d_sink_t   egress_sink,
    output axis_d_source_t egress_source

);

    // State definitions.
    localparam IDLE           = 3'b000; // waiting for sideband buffer to show an entry
    localparam READ_SIDEBAND  = 3'b010; // read sideband information
    localparam INIT_FRAME_PTR = 3'b011; // set pointers in frame buffer
    localparam INIT_REQ       = 3'b001; // make request to switch
    localparam WRITE_FRAME    = 3'b101; // writing frame
    localparam LAST_PACKET    = 3'b100; // last packet to write

    // State signals
    logic [2:0]                 state, next_state;
    logic [TIMEOUT_CTR_WIDTH:0] timeout_ctr;
    logic                       next_rptr_is_last;
    logic                       first_req;

    // frame buffer control
    logic                next_frame_ren;
    logic [ADDR_WIDTH:0] next_frame_rptr;
    logic                prev_frame_ren;
    logic                first_frame_rrst;
    logic                prev_frame_rrst;

    // sideband buffer control
    logic first_sideband_ren;

    // egress control
    logic first_last;
    logic tlast;
    logic egress_handshake_complete;
    logic prev_egress_request;

    /* Save input data. */

    // latch sideband data
    always_ff @(posedge clk) begin
        if (reset) begin
            frame_rst_rptr <= '0;
            egress_source.tdest <= '0;
        end else begin
            if (first_sideband_ren) begin
                frame_rst_rptr <= next_frame_rptr;
                egress_source.tdest <= sideband_rdata[`AXIS_DEST_WIDTH-1:0];
            end else begin
                frame_rst_rptr <= frame_rst_rptr;
                egress_source.tdest <= egress_source.tdest;
            end
        end
    end

    /* Propagate next state. */
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            prev_frame_ren <= 1'b0;
            timeout_ctr <= '0;
        end else begin
            state <= next_state;
            prev_frame_ren <= frame_ren;
            if (state === IDLE || egress_handshake_complete) begin
                // reset counter with no request or granted request
                timeout_ctr <= '0;
            end else if (egress_source.tvalid & ~egress_sink.tready) begin
                // increment counter when making a request that is not granted
                timeout_ctr <= timeout_ctr + 1;
            end else begin
                // persist count if pausing a request
                timeout_ctr <= timeout_ctr;
            end
        end
    end

    /* Generate next state. */

    // egress handshake completion
    assign prev_egress_request = ~egress_sink.tready & egress_source.tvalid;
    assign egress_handshake_complete = egress_sink.tready & egress_source.tvalid;

    // find the boundary for the next frame
    assign next_frame_rptr = sideband_rdata[ADDR_WIDTH+`AXIS_DEST_WIDTH:`AXIS_DEST_WIDTH];
    assign next_rptr_is_last = ((frame_rptr + 1) === next_frame_rptr) ? 1'b1 : 1'b0;

    // next state (and state transition indicator) logic
    always_comb begin
        next_state = state;
        first_sideband_ren = 1'b0;
        first_frame_rrst = 1'b0;
        first_req = 1'b0;
        first_last = 1'b0;
        case (state)
        IDLE: begin
            // start making requests when frames exist in the sideband
            if (~sideband_empty) begin
                next_state = READ_SIDEBAND;
                first_sideband_ren = 1'b1;
            end
        end
        READ_SIDEBAND: begin
            // allow cycle delay to read sideband buffer
            next_state = INIT_FRAME_PTR;
            first_frame_rrst = 1'b1;
        end
        INIT_FRAME_PTR: begin
            // set pointers in frame FIFO
            // can start request when have begun receiving payload or there are more frames in the frame buffer (after read current sideband)
            if (scan_payload | ~sideband_empty) begin
                next_state = INIT_REQ;
                first_req = 1'b1;
            end
        end
        INIT_REQ: begin
            if (timeout_ctr[TIMEOUT_CTR_WIDTH]) begin
                // timeout request when counter overflows
                next_state = IDLE;
            end else if (egress_sink.tready) begin
                // start with the granted request
                next_state = WRITE_FRAME;
            end
        end
        WRITE_FRAME: begin
            // assert last when one more entry in the current frame
            if ((sideband_empty & frame_last_entry) | next_rptr_is_last) begin
                next_state = LAST_PACKET;
                first_last = 1'b1;
            end else if (timeout_ctr[TIMEOUT_CTR_WIDTH]) begin
                // timeout request when counter overflows
                next_state = IDLE;
            end
        end
        LAST_PACKET: begin
            // transition to IDLE after last handshake
            if (egress_handshake_complete) begin
                next_state = IDLE;
            end else if (timeout_ctr[TIMEOUT_CTR_WIDTH]) begin
                // timeout request when counter overflows
                next_state = IDLE;
            end
        end
        default: begin
            next_state = IDLE;
        end
        endcase
    end

    /* Write output data. */

    // control frame read enable
    always_comb begin
        // read frame buffer with initial request and every completed transaction
        if (first_req || (egress_handshake_complete & (state !== LAST_PACKET))) begin
            next_frame_ren = 1'b1;
        end else begin
            next_frame_ren = 1'b0;
        end
    end

    // control frame cursor reset
    always_ff @(posedge clk) begin
        if (reset) begin
            frame_rrst <= 1'b0;
            prev_frame_rrst <= 1'b0;
        end else begin
            prev_frame_rrst <= frame_rrst;

            // pulse frame read reset when enter the frame pointer state
            if (frame_rrst === 1'b1) begin
                frame_rrst <= 1'b0;
            end else if (first_frame_rrst) begin
                frame_rrst <= 1'b1;
            end else begin
                frame_rrst <= 1'b0;
            end
        end
    end

    // output generation
    assign timeout = timeout_ctr[TIMEOUT_CTR_WIDTH];
    always_ff @(posedge clk) begin
        if (reset) begin
            frame_ren <= 1'b0;
            sideband_ren <= 1'b0;
            egress_source.tdata <= '0;
            egress_source.tlast <= 1'b0;
        end else begin
            frame_ren <= next_frame_ren;
            sideband_ren <= first_sideband_ren;

            // latch read data
            if (next_frame_ren) begin
                egress_source.tdata <= frame_rdata[15:0];
            end else begin
                egress_source.tdata <= egress_source.tdata;
            end

            // assert tlast when going to or staying in LAST_PACKET state
            egress_source.tlast <= (next_state === LAST_PACKET) ? 1'b1 : 1'b0;

            // valid when read from FIFO or previous request not granted
            egress_source.tvalid <= (first_req || next_frame_ren || prev_egress_request) && ~timeout_ctr[TIMEOUT_CTR_WIDTH];
        end
    end

`ifdef ASSERT
    /* Assertions. */

    // assert data does not get lost (tdata does not change while tvalid is high if tready was not asserted)
    assertion_switch_requester_stable_tdata : assert property(
        @(posedge clk) disable iff (reset)
        egress_source.tvalid & ~egress_sink.tready |=> $stable(egress_source.tdata)
    ) else $error("Failed assertion");

    // assert tdest is stable while tvalid is high
    assertion_switch_requester_stable_tdest : assert property(
        @(posedge clk) disable iff (reset)
        egress_source.tvalid & egress_sink.tready & ~egress_source.tlast |=> $stable(egress_source.tdest)
    ) else $error("Failed assertion");

    // assert tvalid stays high until timeout or last
    assertion_switch_requester_stable_tvalid : assert property(
        @(posedge clk) disable iff (reset)
        egress_source.tvalid & ~egress_source.tlast |=> egress_source.tvalid || timeout_ctr[TIMEOUT_CTR_WIDTH]
    ) else $error("Failed assertion");

    // assert do not read another frame when the last packet is being read
    assertion_switch_requester_last_packet_ren : assert property(
        @(posedge clk) disable iff (reset)
        egress_source.tlast |=> ~frame_ren
    ) else $error("Failed assertion");

    // assert do not read from FIFO until receive payload of the first frame
    assertion_switch_requester_premature_read : assert property(
        @(posedge clk) disable iff (reset)
        ~scan_payload && sideband_empty |-> ~frame_ren
    ) else $error("Failed assertion");

    // assert do not read from an empty FIFO (will fail if empty transitions high in middle of cycle as in the testbench)
    //assertion_switch_requester_empty_read : assert property(
    //    @(posedge clk) disable iff (reset)
    //    sideband_empty |-> ~sideband_ren
    //) else $error("Failed assertion");

    // assert state transition signals are pulsed
    assertion_switch_requester_pulse_first_sideband_ren : assert property(
        @(posedge clk) disable iff (reset)
        first_sideband_ren |=> ~first_sideband_ren
    ) else $error("Failed assertion");
    assertion_switch_requester_pulse_first_frame_rrst : assert property(
        @(posedge clk) disable iff (reset)
        first_frame_rrst |=> ~first_frame_rrst
    ) else $error("Failed assertion");
    assertion_switch_requester_pulse_first_req : assert property(
        @(posedge clk) disable iff (reset)
        first_req |=> ~first_req
    ) else $error("Failed assertion");
    assertion_switch_requester_pulse_first_last : assert property(
        @(posedge clk) disable iff (reset)
        first_last |=> ~first_last
    ) else $error("Failed assertion");
`endif

endmodule
