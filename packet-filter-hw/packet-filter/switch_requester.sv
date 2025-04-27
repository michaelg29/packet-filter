
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
    logic next_rptr_is_last;
    logic [TIMEOUT_CTR_WIDTH:0] timeout_ctr;

    // frame buffer control
    logic [ADDR_WIDTH:0] next_frame_rptr;
    logic prev_frame_ren;

    // sideband buffer control
    logic prev_sideband_ren;

    // egress control
    logic tlast;
    logic [`AXIS_DEST_WIDTH-1:0] tdest;
    logic egress_handshake_complete;

    // latch sideband data
    always_ff @(posedge clk) begin
        if (reset) begin
            prev_sideband_ren <= 1'b0;
            frame_rst_rptr <= '0;
            tdest <= '0;
        end else begin
            prev_sideband_ren <= sideband_ren;
            if (prev_sideband_ren) begin
                frame_rst_rptr <= sideband_rdata[ADDR_WIDTH+`AXIS_DEST_WIDTH:`AXIS_DEST_WIDTH];
                tdest <= sideband_rdata[`AXIS_DEST_WIDTH-1:0];
            end else begin
                frame_rst_rptr <= frame_rst_rptr;
                tdest <= tdest;
            end
        end
    end

    // propagate state logic
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

    // egress handshake completion
    assign egress_handshake_complete = egress_sink.tready & egress_source.tvalid;

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
            // can start request when have begun receiving payload or there are more frames in the frame buffer
            if (scan_payload | ~sideband_empty) begin
                next_state = INIT_REQ;
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

    // control frame reading
    always_ff @(posedge clk) begin
        if (reset) begin
            frame_ren <= 1'b0;
            frame_rrst <= 1'b0;
        end else begin
            // read frame buffer with command and a completed transaction
            if (frame_rrst === 1'b1) begin
                frame_ren <= 1'b1;
            end else if (egress_handshake_complete) begin
                frame_ren <= 1'b1;
            end else begin
                frame_ren <= 1'b0;
            end

            // pulse frame read reset when enter the frame pointer state
            if (frame_rrst === 1'b1) begin
                frame_rrst <= 1'b0;
            end else if (next_state === INIT_FRAME_PTR && state !== INIT_FRAME_PTR) begin
                frame_rrst <= 1'b1;
            end else begin
                frame_rrst <= 1'b0;
            end
        end
    end

    // output generation
    assign egress_source.tlast = tlast;
    assign egress_source.tdata = frame_rdata;
    assign egress_source.tvalid = prev_frame_ren;
    assign egress_source.tdest = tdest;
    always_comb begin
        sideband_ren = 1'b0;
        tlast = 1'b0;
        case (state)
        IDLE: begin
        end
        READ_SIDEBAND: begin
            sideband_ren = 1'b1;
        end
        INIT_FRAME_PTR: begin
        end
        INIT_REQ: begin
        end
        WRITE_FRAME: begin
        end
        LAST_PACKET: begin
            tlast = 1'b1;
        end
        default: begin
        end
        endcase
    end

    // assert data does not get lost (tdata does not change while tvalid is high if tready was not asserted)

    // assert tdest is stable while tvalid is high

    //

endmodule
