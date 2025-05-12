// packet_switch.sv
`include "../include/packet_filter.svh"
`timescale 1 ps / 1 ps

module packet_switch #(
    parameter STUBBING   = `STUBBING_PASSTHROUGH,
    parameter N_PORTS    = 4,
    parameter DATA_WIDTH = 16,
    parameter IDX_WIDTH  = $clog2(N_PORTS)
)(
    input  wire              clk,
    input  wire              reset,

    // Avalon-MM register interface
    input  wire [7:0]        writedata,
    input  wire              write,
    input  wire              chipselect,
    input  wire [7:0]        address,
    input  wire              read,
    output reg  [7:0]        readdata,

    // Four AXIS ingress ports
    input  wire [DATA_WIDTH-1:0] ingress_port_0_tdata,
    input  wire                  ingress_port_0_tvalid,
    input  wire                  ingress_port_0_tlast,
    input  wire [IDX_WIDTH-1:0]  ingress_port_0_tdest,
    output wire                  ingress_port_0_tready,

    input  wire [DATA_WIDTH-1:0] ingress_port_1_tdata,
    input  wire                  ingress_port_1_tvalid,
    input  wire                  ingress_port_1_tlast,
    input  wire [IDX_WIDTH-1:0]  ingress_port_1_tdest,
    output wire                  ingress_port_1_tready,

    input  wire [DATA_WIDTH-1:0] ingress_port_2_tdata,
    input  wire                  ingress_port_2_tvalid,
    input  wire                  ingress_port_2_tlast,
    input  wire [IDX_WIDTH-1:0]  ingress_port_2_tdest,
    output wire                  ingress_port_2_tready,

    input  wire [DATA_WIDTH-1:0] ingress_port_3_tdata,
    input  wire                  ingress_port_3_tvalid,
    input  wire                  ingress_port_3_tlast,
    input  wire [IDX_WIDTH-1:0]  ingress_port_3_tdest,
    output wire                  ingress_port_3_tready,

    // Four AXIS egress ports
    output wire [DATA_WIDTH-1:0] egress_port_0_tdata,
    output wire                  egress_port_0_tvalid,
    output wire                  egress_port_0_tlast,
    input  wire                  egress_port_0_tready,

    output wire [DATA_WIDTH-1:0] egress_port_1_tdata,
    output wire                  egress_port_1_tvalid,
    output wire                  egress_port_1_tlast,
    input  wire                  egress_port_1_tready,

    output wire [DATA_WIDTH-1:0] egress_port_2_tdata,
    output wire                  egress_port_2_tvalid,
    output wire                  egress_port_2_tlast,
    input  wire                  egress_port_2_tready,

    output wire [DATA_WIDTH-1:0] egress_port_3_tdata,
    output wire                  egress_port_3_tvalid,
    output wire                  egress_port_3_tlast,
    input  wire                  egress_port_3_tready,

    // Unused IRQ
    output wire                  irq
);

    // ////////////////////////////////
    //  register (egress_mask) at address 0
    // ///////////////////////////////
    logic [N_PORTS-1:0] egress_mask;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)                      egress_mask <= '0;
        else if (chipselect && write && address == 8'h0)
                                        egress_mask <= writedata[N_PORTS-1:0];
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset)                      readdata <= 8'h00;
        else if (chipselect && read && address == 8'h0)
                                        readdata <= {{8-N_PORTS{1'b0}}, egress_mask};
    end
    assign irq = 1'b0;

generate
if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough
    // Just pass ingress→egress directly
    assign ingress_port_0_tready = egress_port_0_tready;
    assign ingress_port_1_tready = egress_port_1_tready;
    assign ingress_port_2_tready = egress_port_2_tready;
    assign ingress_port_3_tready = egress_port_3_tready;

    assign egress_port_0_tvalid = ingress_port_0_tvalid;
    assign egress_port_0_tdata  = ingress_port_0_tdata;
    assign egress_port_0_tlast  = ingress_port_0_tlast;
    assign egress_port_1_tvalid = ingress_port_1_tvalid;
    assign egress_port_1_tdata  = ingress_port_1_tdata;
    assign egress_port_1_tlast  = ingress_port_1_tlast;
    assign egress_port_2_tvalid = ingress_port_2_tvalid;
    assign egress_port_2_tdata  = ingress_port_2_tdata;
    assign egress_port_2_tlast  = ingress_port_2_tlast;
    assign egress_port_3_tvalid = ingress_port_3_tvalid;
    assign egress_port_3_tdata  = ingress_port_3_tdata;
    assign egress_port_3_tlast  = ingress_port_3_tlast;

end else begin: g_functional
    // ///////////////////////////////////////////
    // Wire up all four rr_scheduler + mux4to1 in a loop
    // ////////////////////////////////////

    // Pack ingress AXIS into arrays
    axis_d_source_t ingress_src   [N_PORTS];
    axis_d_sink_t   ingress_sink  [N_PORTS];
    axis_source_t   egress_src    [N_PORTS];
    axis_sink_t     egress_sink   [N_PORTS];

    // Flattened buses for rr_scheduler
    logic [N_PORTS-1:0]           bus_ing_valid,  bus_ing_last;
    logic [IDX_WIDTH-1:0]         bus_ing_dest   [N_PORTS];
    logic [IDX_WIDTH-1:0]         sched_sel      [N_PORTS];
    logic                         sched_val      [N_PORTS];
    logic                         sched_last     [N_PORTS];
    logic [N_PORTS-1:0]           sched_grant    [N_PORTS];
    logic [N_PORTS-1:0]           sched_ing_rdy  [N_PORTS][N_PORTS];

    // Build ingress arrays from top‑level ports
    assign ingress_src[0] = '{
        .tdata  (ingress_port_0_tdata),
        .tvalid (ingress_port_0_tvalid),
        .tdest  (ingress_port_0_tdest),
        .tlast  (ingress_port_0_tlast)
    };
    assign ingress_src[1] = '{
        .tdata  (ingress_port_1_tdata),
        .tvalid (ingress_port_1_tvalid),
        .tdest  (ingress_port_1_tdest),
        .tlast  (ingress_port_1_tlast)
    };
    assign ingress_src[2] = '{
        .tdata  (ingress_port_2_tdata),
        .tvalid (ingress_port_2_tvalid),
        .tdest  (ingress_port_2_tdest),
        .tlast  (ingress_port_2_tlast)
    };
    assign ingress_src[3] = '{
        .tdata  (ingress_port_3_tdata),
        .tvalid (ingress_port_3_tvalid),
        .tdest  (ingress_port_3_tdest),
        .tlast  (ingress_port_3_tlast)
    };

    // Handshake back‑pressure from schedulers into ingress sinks
    // (we OR across all egress schedulers)
    genvar i, j;
    for (i = 0; i < N_PORTS; i++) begin : R_IN_SINK
        assign ingress_sink[i].tready =
            |(sched_ing_rdy[0][i],
              sched_ing_rdy[1][i],
              sched_ing_rdy[2][i],
              sched_ing_rdy[3][i]);
    end

    // Expose those back‑pressure bits to the top‑level I/O
    assign ingress_port_0_tready = ingress_sink[0].tready;
    assign ingress_port_1_tready = ingress_sink[1].tready;
    assign ingress_port_2_tready = ingress_sink[2].tready;
    assign ingress_port_3_tready = ingress_sink[3].tready;

    // Build the valid/last/dest vectors for each scheduler (same for all four schedulers)
    always_comb begin
        for (j = 0; j < N_PORTS; j++) begin
            bus_ing_valid[j] = ingress_src[j].tvalid;
            bus_ing_last [j] = ingress_src[j].tlast;
            bus_ing_dest [j] = ingress_src[j].tdest;
        end
    end

    // Hook each egress_port_X_tready into our egress_sink array
    assign egress_sink[0].tready = egress_port_0_tready;
    assign egress_sink[1].tready = egress_port_1_tready;
    assign egress_sink[2].tready = egress_port_2_tready;
    assign egress_sink[3].tready = egress_port_3_tready;

    // Instantiate rr_scheduler + mux4to1 for each egress port
    for (i = 0; i < N_PORTS; i++) begin : SCHED_AND_MUX
        // Round‑Robin arbiter picks one ingress for this egress
        rr_scheduler #(
            .N_PORTS   (N_PORTS),
            .IDX_WIDTH (IDX_WIDTH)
        ) rr_sch (
            .clk             (clk),
            .reset           (reset),
            .ingress_valid   (bus_ing_valid),
            .ingress_last    (bus_ing_last),
            .ingress_dst     (bus_ing_dest),
            .egress_port_id  (i[IDX_WIDTH-1:0]),
            .egress_ready    (egress_sink[i].tready),
            .selected_ingress(sched_sel[i]),
            .egress_valid    (sched_val[i]),
            .egress_last     (sched_last[i]),
            .grant           (sched_grant[i]),
            .ingress_ready   (sched_ing_rdy[i])
        );

        // Cross‑bar: pick data from the winning ingress
        mux4to1 #(
            .N_PORTS    (N_PORTS),
            .DATA_WIDTH (DATA_WIDTH),
            .IDX_WIDTH  (IDX_WIDTH)
        ) mr (
            .ingress_data     ({
                ingress_src[3].tdata,
                ingress_src[2].tdata,
                ingress_src[1].tdata,
                ingress_src[0].tdata
            }),
            .selected_ingress (sched_sel[i]),
            .egress_data      (egress_src[i].tdata)
        );

        // Hook arbiter outputs into the egress AXIS source
        assign egress_src[i].tvalid = sched_val[i] & egress_mask[i];
        assign egress_src[i].tlast  = sched_last[i];
    end

    // Finally, route each egress_src into the top‑level egress_port_X_
    assign egress_port_0_tvalid = egress_src[0].tvalid;
    assign egress_port_0_tdata  = egress_src[0].tdata;
    assign egress_port_0_tlast  = egress_src[0].tlast;

    assign egress_port_1_tvalid = egress_src[1].tvalid;
    assign egress_port_1_tdata  = egress_src[1].tdata;
    assign egress_port_1_tlast  = egress_src[1].tlast;

    assign egress_port_2_tvalid = egress_src[2].tvalid;
    assign egress_port_2_tdata  = egress_src[2].tdata;
    assign egress_port_2_tlast  = egress_src[2].tlast;

    assign egress_port_3_tvalid = egress_src[3].tvalid;
    assign egress_port_3_tdata  = egress_src[3].tdata;
    assign egress_port_3_tlast  = egress_src[3].tlast;

end
endgenerate

endmodule



// // packet_switch.sv

// /**
//  * Register mapping
//  *
//  * Byte / mode | Name              | Meaning
//  *        0RW  |  Output port mask |  Enable signal for output ports (active-high).
//  */

// `include "../include/packet_filter.svh"

// `timescale 1 ps / 1 ps
// module packet_switch #(
//         parameter STUBBING = `STUBBING_PASSTHROUGH
//     ) (
// 		input  wire        clk,                   //                   clock.clk
// 		input  wire        reset,                 //                   reset.reset
// 		input  wire [7:0]  writedata,             //          avalon_slave_0.writedata
// 		input  wire        write,                 //                        .write
// 		input  wire        chipselect,            //                        .chipselect
// 		input  wire [7:0]  address,               //                        .address
// 		input  wire        read,                  //                        .read
// 		output wire [7:0]  readdata,              //                        .readdata
// 		input  wire [15:0] ingress_port_0_tdata,  //          ingress_port_0.tdata
// 		input  wire        ingress_port_0_tvalid, //                        .tvalid
// 		output wire        ingress_port_0_tready, //                        .tready
// 		input  wire        ingress_port_0_tlast,  //                        .tlast
// 		input  wire [1:0]  ingress_port_0_tdest,  //                        .tdest
// 		input  wire [15:0] ingress_port_1_tdata,  //          ingress_port_1.tdata
// 		input  wire        ingress_port_1_tlast,  //                        .tlast
// 		input  wire        ingress_port_1_tvalid, //                        .tvalid
// 		output wire        ingress_port_1_tready, //                        .tready
// 		input  wire [1:0]  ingress_port_1_tdest,  //                        .tdest
// 		input  wire [15:0] ingress_port_2_tdata,  //          ingress_port_2.tdata
// 		input  wire        ingress_port_2_tlast,  //                        .tlast
// 		input  wire        ingress_port_2_tvalid, //                        .tvalid
// 		output wire        ingress_port_2_tready, //                        .tready
// 		input  wire [1:0]  ingress_port_2_tdest,  //                        .tdest
// 		input  wire [15:0] ingress_port_3_tdata,  //          ingress_port_3.tdata
// 		output wire        ingress_port_3_tready, //                        .tready
// 		input  wire        ingress_port_3_tlast,  //                        .tlast
// 		input  wire        ingress_port_3_tvalid, //                        .tvalid
// 		input  wire [1:0]  ingress_port_3_tdest,  //                        .tdest
// 		output wire [15:0] egress_port_0_tdata,   //           egress_port_0.tdata
// 		output wire        egress_port_0_tlast,   //                        .tlast
// 		input  wire        egress_port_0_tready,  //                        .tready
// 		output wire        egress_port_0_tvalid,  //                        .tvalid
// 		output wire [15:0] egress_port_1_tdata,   //           egress_port_1.tdata
// 		output wire        egress_port_1_tlast,   //                        .tlast
// 		input  wire        egress_port_1_tready,  //                        .tready
// 		output wire        egress_port_1_tvalid,  //                        .tvalid
// 		output wire [15:0] egress_port_2_tdata,   //           egress_port_2.tdata
// 		output wire        egress_port_2_tlast,   //                        .tlast
// 		input  wire        egress_port_2_tready,  //                        .tready
// 		output wire        egress_port_2_tvalid,  //                        .tvalid
// 		output wire [15:0] egress_port_3_tdata,   //           egress_port_3.tdata
// 		output wire        egress_port_3_tlast,   //                        .tlast
// 		input  wire        egress_port_3_tready,  //                        .tready
// 		output wire        egress_port_3_tvalid,  //                        .tvalid
// 		output wire        irq                    // packet_filter_interrupt.irq
// 	);

//     // registers
//     logic [`NUM_EGRESS_PORTS-1:0] egress_mask;

// generate
// if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough

//     // output AXIS assignments
// 	assign ingress_port_0_tready = egress_port_0_tready;
// 	assign ingress_port_1_tready = egress_port_1_tready;
// 	assign ingress_port_2_tready = egress_port_2_tready;
// 	assign ingress_port_3_tready = egress_port_3_tready;
// 	assign egress_port_0_tvalid  = ingress_port_0_tvalid;
// 	assign egress_port_0_tdata   = ingress_port_0_tdata;
// 	assign egress_port_0_tlast   = ingress_port_0_tlast;
// 	assign egress_port_1_tvalid  = ingress_port_1_tvalid;
// 	assign egress_port_1_tdata   = ingress_port_1_tdata;
// 	assign egress_port_1_tlast   = ingress_port_1_tlast;
// 	assign egress_port_2_tvalid  = ingress_port_2_tvalid;
// 	assign egress_port_2_tdata   = ingress_port_2_tdata;
// 	assign egress_port_2_tlast   = ingress_port_2_tlast;
// 	assign egress_port_3_tvalid  = ingress_port_3_tvalid;
// 	assign egress_port_3_tdata   = ingress_port_3_tdata;
// 	assign egress_port_3_tlast   = ingress_port_3_tlast;

// end else begin: g_functional

//     // registers
//     logic [`NUM_EGRESS_PORTS-1:0] egress_mask;

// 	// internal AXIS wires
// 	axis_d_source_t ingress_port_source [`NUM_INGRESS_PORTS-1:0];
// 	axis_d_sink_t   ingress_port_sink   [`NUM_INGRESS_PORTS-1:0];
// 	axis_source_t   egress_port_source  [`NUM_EGRESS_PORTS-1:0];
// 	axis_sink_t     egress_port_sink    [`NUM_EGRESS_PORTS-1:0];

// 	// intermediate assignments
//     assign ingress_port_source[0].tvalid = ingress_port_0_tvalid;
//     assign ingress_port_source[0].tdata  = ingress_port_0_tdata;
//     assign ingress_port_source[0].tdest  = ingress_port_0_tdest;
//     assign ingress_port_source[0].tlast  = ingress_port_0_tlast;
//     assign ingress_port_source[1].tvalid = ingress_port_1_tvalid;
//     assign ingress_port_source[1].tdata  = ingress_port_1_tdata;
//     assign ingress_port_source[1].tdest  = ingress_port_1_tdest;
//     assign ingress_port_source[1].tlast  = ingress_port_1_tlast;
//     assign ingress_port_source[2].tvalid = ingress_port_2_tvalid;
//     assign ingress_port_source[2].tdata  = ingress_port_2_tdata;
//     assign ingress_port_source[2].tdest  = ingress_port_2_tdest;
//     assign ingress_port_source[2].tlast  = ingress_port_2_tlast;
//     assign ingress_port_source[3].tvalid = ingress_port_3_tvalid;
//     assign ingress_port_source[3].tdata  = ingress_port_3_tdata;
//     assign ingress_port_source[3].tdest  = ingress_port_3_tdest;
//     assign ingress_port_source[3].tlast  = ingress_port_3_tlast;
// 	assign egress_port_sink[0].tready = egress_port_0_tready;
// 	assign egress_port_sink[1].tready = egress_port_1_tready;
// 	assign egress_port_sink[2].tready = egress_port_2_tready;
// 	assign egress_port_sink[3].tready = egress_port_3_tready;

//     // output AXIS assignments
// 	assign ingress_port_0_tready = ingress_port_sink[0].tready;
// 	assign ingress_port_1_tready = ingress_port_sink[1].tready;
// 	assign ingress_port_2_tready = ingress_port_sink[2].tready;
// 	assign ingress_port_3_tready = ingress_port_sink[3].tready;
// 	assign egress_port_0_tvalid  = egress_port_source[0].tvalid;
// 	assign egress_port_0_tdata   = egress_port_source[0].tdata;
// 	assign egress_port_0_tlast   = egress_port_source[0].tlast;
// 	assign egress_port_1_tvalid  = egress_port_source[1].tvalid;
// 	assign egress_port_1_tdata   = egress_port_source[1].tdata;
// 	assign egress_port_1_tlast   = egress_port_source[1].tlast;
// 	assign egress_port_2_tvalid  = egress_port_source[2].tvalid;
// 	assign egress_port_2_tdata   = egress_port_source[2].tdata;
// 	assign egress_port_2_tlast   = egress_port_source[2].tlast;
// 	assign egress_port_3_tvalid  = egress_port_source[3].tvalid;
// 	assign egress_port_3_tdata   = egress_port_source[3].tdata;
// 	assign egress_port_3_tlast   = egress_port_source[3].tlast;

// end
// endgenerate

//     // register write interface
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             egress_mask <= 4'b0;
//         end else if (chipselect && write) begin
//             case (address)
//                 8'h0 : egress_mask <= writedata[3:0];
//             endcase
//         end
//     end

//     // register read interface
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             readdata <= 8'b0;
//         end else if (chipselect && read) begin
//             case (address)
//                 8'h0 : readdata <= {4'b0, egress_mask};
//             endcase
//         end
//     end

// 	// interrupt interface
// 	assign irq = 1'b0;

// endmodule
