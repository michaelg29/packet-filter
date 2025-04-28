
`include "packet_filter.svh"
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module frame_buffer #(
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
    logic [ADDR_WIDTH:0] frame_wptr;
    logic [19:0] frame_wdata;
    logic frame_full;
    logic next_almost_full;
    logic [ADDR_WIDTH-1:0] frame_ptr_diff;

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

            // Almost full/empty logic
            almost_full <= next_almost_full;
            last_entry  <= next_last_entry;
        end
    end

    // Almost-full logic
    assign next_last_entry = ((frame_rptr + 1) == frame_wptr) ? 1'b1 : 1'b0;
    assign frame_ptr_diff = {frame_wptr - frame_rptr}[ADDR_WIDTH-1:0];
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

endmodule
