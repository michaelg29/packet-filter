
`timescale 1 ps / 1 ps
module sideband_buffer #(

) (
    input  logic clk,
    input  logic reset

);

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
    );*/

endmodule
