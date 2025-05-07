
`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif
`include "filter_defs.svh"

`timescale 1 ps / 1 ps
module input_fsm #(
    parameter STUBBING = `STUBBING_PASSTHROUGH
) (
    // Clock and reset
    input  logic clk,
    input  logic reset,

    // Ingress AXIS interface
	input  axis_source_t ingress_source,
	output axis_sink_t   ingress_sink,

    // Input filter status
    input  logic drop_current,
    input  logic almost_full,

    // Output status
    output axis_source_t ingress_pkt,
    output logic         incomplete_frame,
    output frame_status  status
);

    // State definitions.
    localparam IDLE    = 3'b000; // waiting for start frame delimeter (SFD)
    localparam DST_MAC = 3'b010; // scanning destination MAC
    localparam SRC_MAC = 3'b011; // scanning source MAC
    localparam TYPE    = 3'b111; // scanning type field
    localparam FLUSH   = 3'b110; // flush after premature drop
    localparam PAYLOAD = 3'b101; // scanning payload
    localparam MASK    = 3'b100; // mask a dropped packet

    // State signals
    logic [2:0] state, state_d, next_state;
    logic state_transition_en, next_state_transition_en;
    logic [1:0] cycle_counter;

    // Status definitions.
    localparam FRAME_STATUS_IDLE    = 5'b00000;
    localparam FRAME_STATUS_DST_MAC = 5'b00011;
    localparam FRAME_STATUS_SRC_MAC = 5'b00101;
    localparam FRAME_STATUS_TYPE    = 5'b01001;
    localparam FRAME_STATUS_PAYLOAD = 5'b10001;

    // Status signals
    logic       prev_ready;
    logic [4:0] frame_status_str;

    // Ingress interface
    always_ff @(posedge clk) begin: p_ingress
        if (reset) begin
            ingress_pkt.tvalid <= 1'b0;
            ingress_pkt.tdata <= 16'b0;
            ingress_pkt.tlast <= 1'b0;
            prev_ready <= 1'b0;
        end else begin
            // save packet
            ingress_pkt <= ingress_source;
            prev_ready <= ingress_sink.tready;
        end
    end

    // assert backpressure when not enough space for a full frame
    //   and not done with the current frame if a frame is ingressing
    always_comb begin
        if (almost_full) begin
            if (state_transition_en) begin
                // hold ready until completed transaction
                ingress_sink.tready = ~ingress_pkt.tlast;
            end else begin
                // if no handshake, turn off with backpressure
                ingress_sink.tready = 1'b0;
            end
        end else begin
            // turn on immediately
            ingress_sink.tready = ingress_source.tvalid || prev_ready;
        end
    end

    // Compute duration in current state (only relevant for headers)
    always_ff @(posedge clk) begin: p_cnt
        if (reset) begin
            cycle_counter <= 2'b00;
        end else begin
            if (next_state !== state) begin
                // reset when transition to next field
                cycle_counter <= 2'b00;
            end else if (next_state_transition_en) begin
                // increment
                cycle_counter <= cycle_counter + 1;
            end else begin
                cycle_counter <= cycle_counter;
            end
        end
    end

    // Propagate next state to state
    assign next_state_transition_en =
        (ingress_source.tvalid & ingress_sink.tready)
        || (next_state === FLUSH);
    always_ff @(posedge clk) begin: p_propagate_next_state
        if (reset) begin
            state <= IDLE;
            state_transition_en <= 1'b0;
        end else begin
            state <= state_d;
            state_transition_en <= next_state_transition_en;
        end
    end

    // Calculate next state
    assign state_d =
    drop_current // all states transition to mask an invalid frame
        // do not wait for a second last signal from a frame that is already complete
        ? (ingress_pkt.tlast || state === IDLE
            ? IDLE : MASK)
        // otherwise, transition to next state
        : (state_transition_en
            ? next_state : state);
    always_comb begin: p_next_state
        next_state = state;
        case (state)
        IDLE: begin
            if (ingress_pkt.tlast) begin
                next_state = FLUSH;
            end else if (ingress_pkt.tdata === 16'hAAAB) begin
                next_state = DST_MAC;
            end
        end
        DST_MAC: begin
            if (ingress_pkt.tlast) begin
                next_state = FLUSH;
            end else if (cycle_counter === 2'b10) begin
                next_state = SRC_MAC;
            end
        end
        SRC_MAC: begin
            if (ingress_pkt.tlast) begin
                next_state = FLUSH;
            end else if (cycle_counter === 2'b10) begin
                next_state = TYPE;
            end
        end
        TYPE: begin
            if (ingress_pkt.tlast) begin
                next_state = FLUSH;
            end else begin
                next_state = PAYLOAD;
            end
        end
        FLUSH: begin
            next_state = IDLE;
        end
        PAYLOAD: begin
            if (ingress_pkt.tlast) begin
                next_state = IDLE;
            end
        end
        MASK: begin
            if (ingress_pkt.tlast) begin
                next_state = IDLE;
            end
        end
        default: begin
            next_state = IDLE;
        end
        endcase
    end

    // Generate output
    assign incomplete_frame = state === FLUSH ? 1'b1 : 1'b0;
    assign status.scan_frame   = frame_status_str[0];
    assign status.scan_dst_mac = frame_status_str[1];
    assign status.scan_src_mac = frame_status_str[2];
    assign status.scan_type    = frame_status_str[3];
    assign status.scan_payload = frame_status_str[4];
    always_comb begin: p_output
        case (state)
        IDLE: begin
            frame_status_str = FRAME_STATUS_IDLE;
        end
        DST_MAC: begin
            frame_status_str = FRAME_STATUS_DST_MAC;
        end
        SRC_MAC: begin
            frame_status_str = FRAME_STATUS_SRC_MAC;
        end
        TYPE: begin
            frame_status_str = FRAME_STATUS_TYPE;
        end
        PAYLOAD: begin
            frame_status_str = FRAME_STATUS_PAYLOAD;
        end
        FLUSH: begin
            frame_status_str = FRAME_STATUS_IDLE;
        end
        MASK: begin
            frame_status_str = FRAME_STATUS_IDLE;
        end
        default: begin
            frame_status_str = FRAME_STATUS_IDLE;
        end
        endcase
    end

`ifdef VERILATOR
    function string conv_state_to_str( logic [2:0] arg_state );
        case (arg_state)
        IDLE: begin
            conv_state_to_str = "IDLE";
        end
        DST_MAC: begin
            conv_state_to_str = "DST_MAC";
        end
        SRC_MAC: begin
            conv_state_to_str = "SRC_MAC";
        end
        TYPE: begin
            conv_state_to_str = "TYPE";
        end
        PAYLOAD: begin
            conv_state_to_str = "PAYLOAD";
        end
        FLUSH: begin
            conv_state_to_str = "FLUSH";
        end
        MASK: begin
            conv_state_to_str = "MASK";
        end
        default: begin
            conv_state_to_str = "dne";
        end
        endcase
    endfunction

    string state_str, state_d_str, next_state_str;
    assign state_str = conv_state_to_str(state);
    assign state_d_str = conv_state_to_str(state_d);
    assign next_state_str = conv_state_to_str(next_state);

    always @(posedge clk) begin
        $display("state is %s\n", state_str);
    end
`endif

`ifdef ASSERT
    /* Assertions */

    // assert grant is held for an entire frame
    assertion_input_fsm_frame_grant : assert property(
        @(posedge clk) disable iff (reset)
        ingress_source.tvalid & ingress_sink.tready & ~ingress_source.tlast
            |=> ingress_sink.tready || ingress_source.tlast
    ) else $error($sformatf("assertion_input_fsm_frame_grant failed at %0t", $realtime));

    // do not provide grants if almost full
    assertion_input_fsm_almost_full : assert property(
        @(posedge clk) disable iff (reset)
        almost_full && (~ingress_source.tvalid || ingress_source.tlast)
            |=> ~ingress_sink.tready
    ) else $error($sformatf("assertion_input_fsm_almost_full failed at %0t", $realtime));

    // assert do not accept packets when not ready
    assertion_input_fsm_tready : assert property(
        @(posedge clk) disable iff (reset)
        ~ingress_sink.tready |=> frame_status_str === FRAME_STATUS_IDLE
    ) else $error("Failed assertion");

    // assert mask a dropped frame (do not broadcast frame status until tlast asserted)
`ifdef VERILATOR
    logic current_frame_dropped;
    reg_set_clear r_current_frame_dropped
        (clk, reset, drop_current, ingress_source.tlast, current_frame_dropped);
    assertion_input_fsm_mask_dropped : assert property(
        @(posedge clk) disable iff (reset)
        current_frame_dropped |-> frame_status_str === FRAME_STATUS_IDLE || ingress_source.tlast
    ) else $error("Failed assertion");
`endif
`endif

endmodule
