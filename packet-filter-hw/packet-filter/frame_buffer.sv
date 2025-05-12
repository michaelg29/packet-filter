
`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module frame_buffer #(
    parameter STUBBING = `STUBBING_PASSTHROUGH,
    parameter ALMOST_FULL_THRESHOLD = 10,
    parameter ADDR_WIDTH = 11,
    parameter NUM_CYCLONE_5CSEMA5_BLOCKS = 4
) (
    // clock and reset
    input  logic clk,
    input  logic reset,

    // ingress frame control
    input  axis_source_t ingress_pkt,
    input  logic         scan_frame,
    input  logic         drop_write,
    output logic         almost_full,
    output logic [ADDR_WIDTH:0] frame_wptr,

    // read frame control
    input  logic         frame_ren,
    input  logic         frame_rrst,
    input  logic [ADDR_WIDTH:0] frame_rst_rptr,
    output logic [ADDR_WIDTH:0] frame_rptr,
    output logic [19:0]  frame_rdata,
    output logic         last_entry
);

    // ingress frame control
    logic prev_scan_frame;
    logic frame_wen;
    logic [ADDR_WIDTH:0] frame_rst_wptr;
    logic [ADDR_WIDTH:0] next_frame_rptr;
    logic [19:0] frame_wdata;
    logic frame_full;
    logic next_almost_full;
    logic [ADDR_WIDTH:0] frame_ptr_diff;

    // egress frame control
    logic next_last_entry;

    // Register logic
    always_ff @(posedge clk) begin
        if (reset) begin
            prev_scan_frame <= 1'b0;
            frame_rst_wptr  <= '0;
            almost_full     <= 1'b0;
        end else begin
            // Frame start logic
            prev_scan_frame <= scan_frame;
            if (~prev_scan_frame & scan_frame) begin
                frame_rst_wptr <= frame_wptr;
            end else begin
                frame_rst_wptr <= frame_rst_wptr;
            end

            // Capacity logic
            almost_full <= next_almost_full;
            last_entry  <= next_last_entry;
        end
    end

    // Capacity logic
    assign next_frame_rptr = frame_rptr + 1;
    assign next_last_entry = (next_frame_rptr === frame_wptr) ? 1'b1 : 1'b0;
    assign frame_ptr_diff = frame_wptr - frame_rptr;
    always_comb begin
`ifdef VERILATOR
        if ({{(32-ADDR_WIDTH){1'b0}}, frame_ptr_diff[ADDR_WIDTH-1:0]} >= ALMOST_FULL_THRESHOLD) begin
`else
        if (frame_ptr_diff[ADDR_WIDTH-1:0] >= ALMOST_FULL_THRESHOLD) begin
`endif
            next_almost_full = 1'b1;
        end else begin
            next_almost_full = frame_full;
        end
    end

    /*
     * Frame FIFO.
     *
     * Using 4 blocks = 512*4 = 2048x20b words
     * Must address 2048 words => 11-bit address (12-bit cursor)
     * Can store 2.69829 full-sized frames (1518 Bytes = 759 queue words each)
     * Can store 64 min-sized frames (64 Bytes = 32 queue words each)
     *
     * TODO: add parity bits to pad 16-bit streaming words to 20-bit memory words
     */
    assign frame_wen = ingress_pkt.tvalid & scan_frame;
    assign frame_wdata = {4'b0, ingress_pkt.tdata};
    fifo_sync #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .W_EL(20),
        .NUM_CYCLONE_5CSEMA5_BLOCKS(NUM_CYCLONE_5CSEMA5_BLOCKS),
        .CAN_RESET_POINTERS(1)
    ) u_frame_fifo (
        .clk      (clk),
        .reset    (reset),
        .ren      (frame_ren),      // from switch FSM
        .rdata    (frame_rdata),    // to egress
/* verilator lint_off PINCONNECTEMPTY */
        .empty    (),               // open
/* verilator lint_on PINCONNECTEMPTY */
        .wdata    (frame_wdata),    // from ingress
        .wen      (frame_wen),      // from switch FSM
        .full     (frame_full),
        .rrst     (frame_rrst),     //
        .wrst     (drop_write),     //
        .rst_rptr (frame_rst_rptr), // from switch FSM
        .rst_wptr (frame_rst_wptr), // from switch FSM
        .rptr     (frame_rptr),     // to switch FSM
        .wptr     (frame_wptr)      // to switch FSM
    );

`ifdef VERILATOR
    integer fifo_rst_rptr, fifo_rst_wptr, fifo_rptr, fifo_wptr;
    integer wcnt, rcnt, size;

    assign fifo_rst_rptr = {{(32-ADDR_WIDTH-1){1'b0}}, u_frame_fifo.rst_rptr};
    assign fifo_rst_wptr = {{(32-ADDR_WIDTH-1){1'b0}}, u_frame_fifo.rst_wptr};
    assign fifo_rptr = {{(32-ADDR_WIDTH-1){1'b0}}, u_frame_fifo.rptr};
    assign fifo_wptr = {{(32-ADDR_WIDTH-1){1'b0}}, u_frame_fifo.wptr};
    assign size = wcnt - rcnt;
    always_ff @(posedge clk) begin
        if (reset) begin
            rcnt <= 0;
            wcnt <= 0;
        end else begin
            if (u_frame_fifo.rrst && u_frame_fifo.wrst) begin
                rcnt <= 0;
                wcnt <= fifo_rst_wptr - fifo_rst_rptr;
            end else if (u_frame_fifo.rrst && ~u_frame_fifo.wrst) begin
                rcnt <= 0;
                if (u_frame_fifo.wen && ~u_frame_fifo.full) begin
                    wcnt <= fifo_wptr - fifo_rst_rptr + 1;
                end else begin
                    wcnt <= fifo_wptr - fifo_rst_rptr;
                end
            end else if (~u_frame_fifo.rrst && u_frame_fifo.wrst) begin
                if (u_frame_fifo.ren && ~u_frame_fifo.empty) begin
                    rcnt <= 1;
                end else begin
                    rcnt <= 0;
                end
                wcnt <= fifo_rst_wptr - fifo_rptr;
            end else begin
                if (u_frame_fifo.wen && ~u_frame_fifo.full) begin
                    wcnt <= wcnt + 1;
                end
                if (u_frame_fifo.ren && ~u_frame_fifo.empty) begin
                    rcnt <= rcnt + 1;
                end
            end
        end
    end

`ifdef ASSERT
    assertion_frame_buffer_almost_full : assert property(
        @(posedge clk) disable iff (reset)
        (size >= ALMOST_FULL_THRESHOLD) |=> almost_full
    ) else $error("Failed assertion");

    assertion_frame_buffer_last_entry : assert property(
        @(posedge clk) disable iff (reset)
        (size === 1) |=> last_entry
    ) else $error("Failed assertion");
`endif
`endif

endmodule
