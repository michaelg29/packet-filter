
`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module sideband_buffer #(
    parameter STUBBING = `STUBBING_PASSTHROUGH,
    parameter ADDR_WIDTH = 11
) (
    input  logic clk,
    input  logic reset,

    // frame status
    input  logic scan_frame,
    input  logic scan_payload,
    input  drop_source_t frame_type,
    output logic frame_drop,

    // destination

    input  dest_source_t frame_dest,

    // frame buffer
    input  logic [ADDR_WIDTH:0] frame_wptr,

    // read interface
    input  logic        ren,
    output logic        empty,
    output logic [19:0] rdata,

    // write interface
    output logic        full

);

    localparam NUM_FIELDS = 3;
    localparam FIELD_IDX_DEST = 0;
    localparam FIELD_IDX_WPTR = 1;
    localparam FIELD_IDX_TYPE = 2;

    // write control
    logic [NUM_FIELDS-1:0] valid_fields;
    logic        wen;
    logic        written;
    logic [19:0] wdata;

    // registers to delay empty signaling
    logic prev_reset;
    logic fifo_empty;

    always_ff @(posedge clk) begin
        wdata[19:ADDR_WIDTH+`AXIS_DEST_WIDTH+1] <= '0;
        prev_reset <= reset;
        if (reset) begin
            wen <= 1'b0;
            written <= 1'b0;
            wdata <= '0;
            valid_fields <= '0;
            frame_drop <= 1'b0;
            empty <= 1'b1;
        end else begin
            empty <= fifo_empty | prev_reset;
            if (scan_frame) begin
                // save destination
                if (frame_dest.tvalid) begin
                    wdata[`AXIS_DEST_WIDTH-1:0] <= frame_dest.tdata;
                    valid_fields[FIELD_IDX_DEST] <= ~frame_dest.tuser;
                end

                // save type
                if (frame_type.tvalid) begin
                    valid_fields[FIELD_IDX_TYPE] <= ~frame_type.tuser;
                end

                // save frame pointer
                wdata[ADDR_WIDTH+`AXIS_DEST_WIDTH:`AXIS_DEST_WIDTH] <= wdata[ADDR_WIDTH+`AXIS_DEST_WIDTH:`AXIS_DEST_WIDTH];
                valid_fields[FIELD_IDX_WPTR] <= 1'b1;

                // write enable
                wen <= &valid_fields & ~written & ~wen;
                written <= wen | written;

                // drop detection
                frame_drop <= frame_drop
                    | (frame_dest.tvalid & frame_dest.tuser)
                    | (frame_type.tvalid & frame_type.tuser);
            end else begin
                wen <= 1'b0;
                written <= 1'b0;
                wdata[ADDR_WIDTH+`AXIS_DEST_WIDTH:`AXIS_DEST_WIDTH] <= frame_wptr;
                wdata[`AXIS_DEST_WIDTH-1:0] <= '0;
                valid_fields <= '0;
                frame_drop <= 1'b0;
            end
        end
    end

    /*
     * Sideband FIFO.
     *
     * Using 1 block
     * Can store 512 words (more than the maximum number of frames in the frame buffer)
     */
    /* verilator lint_off PINCONNECTEMPTY */
    fifo_sync #(
        .ADDR_WIDTH(9),
        .W_EL(20),
        .NUM_CYCLONE_5CSEMA5_BLOCKS(1),
        .CAN_RESET_POINTERS(0)
    ) u_sideband_fifo (
        .clk      (clk),
        .reset    (reset),
        .ren      (ren),
        .rdata    (rdata),
        .empty    (fifo_empty),
        .wdata    (wdata),
        .wen      (wen),
        .full     (full),
        .rrst     (),
        .wrst     (),
        .rst_rptr (),
        .rst_wptr (),
        .rptr     (),
        .wptr     ()
    );
    /* verilator lint_on PINCONNECTEMPTY */

`ifdef ASSERT
    /* Assertions. */

    // only write valid frames
    assertion_sideband_buffer_valid_frame_wen : assert property(
        @(posedge clk) disable iff (reset)
        wen |-> scan_frame & &valid_fields & ~frame_drop
    ) else $error("Failed assertion");

    // latch error status
    assertion_sideband_buffer_erroneous_dest : assert property(
        @(posedge clk) disable iff (reset)
        frame_dest.tvalid & frame_dest.tuser |=> (~valid_fields[FIELD_IDX_DEST] & frame_drop) | ~scan_frame
    ) else $error("Failed assertion");
    assertion_sideband_buffer_erroneous_type : assert property(
        @(posedge clk) disable iff (reset)
        frame_type.tvalid & frame_type.tuser |=> (~valid_fields[FIELD_IDX_TYPE] & frame_drop) | ~scan_frame
    ) else $error("Failed assertion");

    // only indicate drop when scanning a frame
    assertion_sideband_buffer_drop_scanned_frame : assert property(
        @(posedge clk) disable iff (reset)
        frame_drop |-> scan_frame || $past(scan_frame, 1)
    ) else $error("Failed assertion");
`endif

endmodule
