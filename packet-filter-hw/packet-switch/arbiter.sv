module rr_arbiter (
    input  logic        clk,
    input  logic        reset,

    // Ingress signals
    input  logic [3:0]        ingress_valid,    // Valid from each ingress
    input  logic [3:0][1:0]   ingress_dest,     // Destinations for each ingress word
    input  logic [3:0]        ingress_last,     // Last signals for each ingress

    // Egress signals
    input  logic [1:0]        egress_index,     // This egress port index (0 to 3)
    input  logic              egress_ready,     // Ready from egress port

    // Arbiter outputs
    output logic [1:0]        select,           // Selected ingress index
    output logic              grant,            // Grant valid
    output logic [3:0]        ingress_ready     // Ready signals to ingress ports (only one asserted)
);

    // Internal state
    typedef enum logic {IDLE, SEND} state_t;
    state_t state, next_state;

    logic [1:0] next_rr;      // Round robin pointer (next ingress to try)
    logic [1:0] cur_grant;    // Currently granted ingress index

    // Registered outputs for pipelined arbitration
    logic [1:0] select_r;
    logic       grant_r;

    // Helper signals
    logic [3:0] valid_match;  // ingress_valid & (ingress_dest == egress_index)
    logic [3:0] rotated_valid; // rotated valid vector for priority encoding

    // Rotate valid vector by next_rr pointer for round robin priority
    function automatic logic [3:0] rotate_left(input logic [3:0] vec, input logic [1:0] amt);
        rotate_left = (vec << amt) | (vec >> (4 - amt));
    endfunction

    // Priority encoder to select first valid ingress after rotation
    function automatic logic [1:0] priority_encode(input logic [3:0] vec);
        if (vec[0]) priority_encode = 2'd0;
        else if (vec[1]) priority_encode = 2'd1;
        else if (vec[2]) priority_encode = 2'd2;
        else if (vec[3]) priority_encode = 2'd3;
        else priority_encode = 2'd0; // default (no valid)
    endfunction

    // Compute valid_match: ingress_valid && (ingress_dest == egress_index)
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin
            assign valid_match[i] = ingress_valid[i] && (ingress_dest[i] == egress_index);
        end
    endgenerate

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            next_rr <= 2'd0;
            cur_grant <= 2'd0;
            select_r <= 2'd0;
            grant_r <= 1'b0;
        end else begin
            state <= next_state;
            if (state == IDLE) begin
                // Update pointer only when not locked
                next_rr <= next_rr;
            end else if (state == SEND && ingress_last[cur_grant] && grant_r && egress_ready) begin
                // Frame done, advance pointer
                next_rr <= next_rr + 1;
            end

            // Register outputs (select/grant) delayed by one cycle
            select_r <= cur_grant;
            grant_r <= (state == SEND);
        end
    end

    // Combinational next state and grant logic
    always_comb begin
        next_state = state;
        cur_grant = select_r; // default hold previous grant

        // Default ingress_ready all zero
        ingress_ready = 4'b0000;

        case (state)
            IDLE: begin
                // Rotate valid vector by next_rr pointer
                rotated_valid = rotate_left(valid_match, next_rr);

                if (|rotated_valid) begin
                    // Select first valid ingress after rotation
                    logic [1:0] idx = priority_encode(rotated_valid);
                    // Map back to actual ingress index
                    cur_grant = (idx + next_rr) & 2'd3;

                    // Grant and move to SEND state
                    next_state = SEND;
                end else begin
                    // No valid ingress, stay IDLE
                    cur_grant = next_rr;
                end
            end

            SEND: begin
                // Stay locked to cur_grant ingress until frame ends
                if (ingress_last[cur_grant] && grant_r && egress_ready) begin
                    // Frame done, go back to IDLE to arbitrate next
                    next_state = IDLE;
                end
            end
        endcase

        // Set ingress_ready only for currently granted ingress if egress ready
        ingress_ready[cur_grant] = egress_ready && (state == SEND);
    end

    // Outputs
    assign select = select_r;
    assign grant = grant_r;

endmodule
