`include "../include/packet_filter.svh"

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

    // input FSM control
    logic frame_active;

    // frame FIFO control
    logic frame_ren;
    logic frame_empty;
    logic frame_wen;
    logic frame_full;
    logic [11:0] frame_rst_rptr;
    logic [11:0] frame_rst_wptr;
    logic [11:0] frame_rptr;
    logic [11:0] frame_wptr;
    logic [19:0] frame_rdata;
    logic [19:0] frame_wdata;

    /*
     * Frame FIFO.
     *
     * Using 4 blocks = 512*4 = 2048x20b words
     * Must address 2048 words => 11-bit address (12-bit cursor)
     * Can store 2.69829 full-sized frames (1518 Bytes = 759 half-words each)
     *
     * TODO: add parity bits to pad 16-bit streaming words to 20-bit memory words
     */
    /*assign frame_wen = ingress_source.tvalid & frame_active;
    assign frame_wdata = {4'b0, ingress_source.tdata};
    fifo_sync #(
        .ADDR_WIDTH(11),
        .W_EL(20),
        .NUM_CYCLONE_5CSEMA5_BLOCKS(4),
        .CAN_RESET_POINTERS(1)
    ) u_frame_fifo (
        .clk      (clk),
        .reset    (reset),
        .ren      (frame_ren),      // from switch FSM
        .rdata    (frame_rdata),    // to egress
        .empty    (frame_empty),    // to switch FSM
        .wdata    (frame_wdata),    // from ingress
        .wen      (frame_wen),      // from switch FSM
        .full     (frame_full),     // to input FSM
        .rrst     (frame_rrst),     //
        .wrst     (frame_wrst),     //
        .rst_rptr (frame_rst_rptr), // from switch FSM
        .rst_wptr (frame_rst_wptr), // from switch FSM
        .rptr     (frame_rptr),     // to switch FSM
        .wptr     (frame_wptr)      // to switch FSM
    );*/

    /*
     * Sideband FIFO.
     *
     * Using 1 block
     */
    /*fifo_sync #(
        .ADDR_WIDTH(9),
        .W_EL(20),
        .NUM_CYCLONE_5CSEMA5_BLOCKS(1),
        .CAN_RESET_POINTERS(0)
    ) u_sideband_fifo (
        .clk      (clk),
        .reset    (reset),
        .ren      (frame_ren),      // from switch FSM
        .rdata    (frame_rdata),    // to egress
        .empty    (frame_empty),    // to switch FSM
        .wdata    (frame_wdata),    // from ingress
        .wen      (frame_wen),      // from switch FSM
        .full     (frame_full),     // to input FSM
        .rst_rptr (),
        .rst_wptr (),
        .rptr     (),
        .wptr     ()
    );

    // unused signals
    logic __unused_okay__;
    assign __unused_okay__ = |{frame_rdata[19:16]};*/


endmodule
