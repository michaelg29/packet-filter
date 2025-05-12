module rr_scheduler #(
    parameter N_PORTS = 4,
    parameter IDX_WIDTH = $clog2(N_PORTS)  // log2(N_PORTS)
)(
    input logic                  clk,
    input logic                  reset,

    // Inputs from ingress ports
    input logic [N_PORTS-1:0]    ingress_valid,
    input logic [N_PORTS-1:0]    ingress_last,
    input logic [IDX_WIDTH-1:0]  ingress_dst [N_PORTS],

    // Current egress port ID
    input logic [IDX_WIDTH-1:0]  egress_port_id,

    // Ready signal from egress port
    input logic                  egress_ready,

    // Outputs to multiplexer/crossbar
    output logic [IDX_WIDTH-1:0] selected_ingress,
    output logic                 egress_valid,
    output logic                 egress_last,

    // Grant signals back to ingress ports
    output logic [N_PORTS-1:0]   grant,
    output logic [N_PORTS-1:0]   ingress_ready
);

    typedef enum logic [0:0] { IDLE, SEND } state_t;
    state_t state, next_state;

    logic [IDX_WIDTH-1:0] next_rr, next_rr_next;
    logic [IDX_WIDTH-1:0] select, select_next;

    integer i;
    logic found;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            next_rr  <= '0;
            select   <= '0;
            grant    <= '0;
        end else begin
            state    <= next_state;
            next_rr  <= next_rr_next;
            select   <= select_next;

            ////////////////////////////////////////
            // Default clear all grants each cycle
            //grant <= '0;
            ///////////////////////////////////////

        //     if (state == IDLE && next_state == SEND)
        //         grant[select_next] <= 1'b1;
        //   //  else if (state == SEND && ingress_last[select])
        //       else if (state == SEND && egress_valid && egress_last && egress_ready)
        //         grant[select] <= 1'b0;
        //    // else
        //    // grant <= grant;  // explicitly hold current grant if none of the above conditions

        if (state == IDLE && next_state == SEND) begin
            grant <= '0;
            grant[select_next] <= 1'b1;
        end
        else if (state == SEND) begin
            if (egress_valid && egress_last && egress_ready) begin
                grant <= '0;  // clear after successful last transfer
            end
            else if (!ingress_valid[select]) begin
                grant <= '0;  // clear if ingress drops unexpectedly
            end
        end
        else begin
            grant <= grant;  // hold grant otherwise
        end

        end
    end

    always_comb begin
        next_state    = state;
        next_rr_next  = next_rr;
        select_next   = select;
        egress_valid  = 1'b0;
        egress_last   = 1'b0;
        ingress_ready = '0;

        case (state)
            IDLE: begin
                found = 1'b0;
                for (i = 0; i < N_PORTS; i++) begin
                    automatic logic [IDX_WIDTH-1:0] idx = next_rr + i[IDX_WIDTH-1:0];   // 2-bit add → no unused bit
                    if (!found && ingress_valid[idx] && ingress_dst[idx] == egress_port_id) begin
                        found = 1'b1;
                        select_next = idx;
                        next_state  = SEND;
                        egress_valid= 1'b1;
                    end
                end
            end

            SEND: begin
                egress_valid = ingress_valid[select];
                egress_last  = ingress_last[select];
                ingress_ready[select] = egress_ready;

                if (ingress_valid[select] && ingress_last[select]) begin
                    // one-line wrap-around
                    next_rr_next = select + 1'b1;   // 2-bit add, high bit discarded
                    //next_state   = IDLE;
                    next_state   = SEND;
                end
                //////////////////////////
                 else if (!ingress_valid[select]) begin
                    next_state = IDLE;  // if ingress becomes invalid, return to IDLE
                end
                ////////////////////////////
            end

            default: next_state = IDLE;  // explicitly handle all cases
        endcase
        selected_ingress = select;
    end

endmodule


// module rr_scheduler #(
//     parameter N_PORTS = 4,
//     parameter IDX_WIDTH = 2  // log2(N_PORTS)
// )(
//     input logic                  clk,
//     input logic                  reset,

//     // Inputs from ingress ports
//     input logic [N_PORTS-1:0]    ingress_valid,
//     input logic [N_PORTS-1:0]    ingress_last,
//     input logic [IDX_WIDTH-1:0]  ingress_dst [N_PORTS-1:0],

//     // Current egress port ID
//     input logic [IDX_WIDTH-1:0]  egress_port_id,

//     // Ready signal from egress port
//     input logic                  egress_ready,

//     // Outputs to multiplexer/crossbar
//     output logic [IDX_WIDTH-1:0] selected_ingress,
//     output logic                 egress_valid,
//     output logic                 egress_last,

//     // Grant signals back to ingress ports
//     output logic [N_PORTS-1:0]   grant,
//     output logic [N_PORTS-1:0]   ingress_ready
// );

//     typedef enum logic [0:0] { IDLE, SEND } state_t;
//     state_t state, next_state;

//     logic [IDX_WIDTH-1:0] next_rr, next_rr_next;
//     logic [IDX_WIDTH-1:0] select, select_next;

//     integer i;
//     logic found;

//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             state    <= IDLE;
//             next_rr  <= '0;
//             select   <= '0;
//             grant    <= '0;
//         end else begin
//             state    <= next_state;
//             next_rr  <= next_rr_next;
//             select   <= select_next;

//             if (state == IDLE && next_state == SEND)
//                 grant[select_next] <= 1'b1;
//             else if (state == SEND && ingress_last[select])
//                 grant[select] <= 1'b0;
//         end
//     end

//     always_comb begin
//         next_state    = state;
//         next_rr_next  = next_rr;
//         select_next   = select;
//         egress_valid  = 1'b0;
//         egress_last   = 1'b0;
//         ingress_ready = '0;

//         case (state)
//             IDLE: begin
//                 found = 1'b0;
//                 for (i = 0; i < N_PORTS; i++) begin
//                     automatic logic [IDX_WIDTH-1:0] idx = next_rr + i[IDX_WIDTH-1:0];   // 2-bit add → no unused bit
//                     if (!found && ingress_valid[idx] && ingress_dst[idx] == egress_port_id) begin
//                         found = 1'b1;
//                         select_next = idx;
//                         next_state  = SEND;
//                         egress_valid= 1'b1;
//                     end
//                 end
//             end

//             SEND: begin
//                 egress_valid = ingress_valid[select];
//                 egress_last  = ingress_last[select];
//                 ingress_ready[select] = egress_ready;

//                 if (ingress_valid[select] && ingress_last[select]) begin
//                     // one-line wrap-around
//                     next_rr_next = select + 1'b1;   // 2-bit add, high bit discarded
//                     next_state   = IDLE;
//                 end
//             end

//             default: next_state = IDLE;  // explicitly handle all cases
//         endcase
//         selected_ingress = select;
//     end

// endmodule
