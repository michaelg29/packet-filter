
`timescale 1 ps / 1 ps
module switch_requester #(
    parameter ADDR_WIDTH = 11,
    parameter TIMEOUT_CTR_WIDTH = 9
) (
    // clock and reset
    input  logic clk,
    input  logic reset,

    // frame status
    input  logic scan_payload,

    // sideband buffer
    input  logic [19:0] sideband_rdata,
    input  logic sideband_empty,
    output logic sideband_ren,

    // frame buffer
    input  logic [15:0]         frame_rdata,
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
    logic [2:0] state, next_state;

    logic [ADDR_WIDTH:0] next_frame_rptr;
    logic next_rptr_is_last;
    logic [TIMEOUT_CTR_WIDTH:0] timeout_ctr;
    logic timeout;
    logic egress_handshake_complete;

    // register logic
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            timeout_ctr <= '0;
        end else begin
            state <= next_state;
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

    // egress handshake completion
    assign egress_handshake_complete = egress_sink.tready & egress_source.tvalid;

    // request has timed out when counter overflows
    assign timeout = timeout_ctr[TIMEOUT_CTR_WIDTH];

    // find the boundary for the next frame
    assign next_frame_rptr = sideband_rdata[ADDR_WIDTH+2:2];
    assign next_rptr_is_last = ((frame_rptr + 1) === next_frame_rptr) ? 1'b1 : 1'b0;

    // next state logic
    always_comb begin
        next_state = state;
        case (state)
        IDLE: begin
            // start making requests when frames exist in the sideband
            if (~sideband_empty) begin
                next_state = READ_SIDEBAND;
            end
        end
        READ_SIDEBAND: begin
            // allow cycle delay to read sideband buffer
            next_state = INIT_FRAME_PTR;
        end
        INIT_FRAME_PTR: begin
            // set pointers in frame FIFO
            if (scan_payload | ~sideband_empty) begin
                next_state = INIT_REQ;
            end
        end
        INIT_REQ: begin
            if (timeout) begin
                // timeout request
                next_state = IDLE;
            end else if (egress_sink.tready) begin
                // start with the granted request
                next_state = WRITE_FRAME;
            end
        end
        WAIT_FRAME: begin
            // assert last when one more entry in the current frame
            if ((sideband_empty & frame_last_entry) | next_rptr_is_last) begin
                next_state = LAST_PACKET;
            end
        end
        LAST_PACKET: begin
            // transition to IDLE after last handshake
            if (egress_handshake_complete) begin
                next_state = IDLE;
            end
        end
        default: begin
            next_state = IDLE;
        end
        endcase
    end

    // output generation
    always_comb begin
        case (next_state)
        IDLE: begin

        end
        READ_SIDEBAND: begin
        end
        INIT_FRAME_PTR: begin
        end
        INIT_REQ: begin
        end
        WAIT_FRAME: begin
        end
        default: begin
        end
        endcase
    end

endmodule
