
/**
 * Synchronous FIFO buffer.
 *
 * Main parameters:
 *   - ADDR_WIDTH: controls depth of the buffer
 *   - W_EL: data width
 *   - CAN_RESET_POINTERS: whether external control can reset the read and write pointers
 *
 * Configurable parameters for the Cyclone 5CSEMA5:
 *   - ADDR_WIDTH: address width = clog2(NUM_CYCLONE_5CSEMA5_BLOCKS) + 9
 *   - W_EL: data width (1 - 20)
 *   - NUM_CYCLONE_5CSEMA5_BLOCKS: number of 1280-Byte-blocks (512x20-word-blocks)
 */
`timescale 1 ps / 1 ps
module fifo_sync #(
    parameter ADDR_WIDTH = 11,
    parameter W_EL = 20,
    parameter NUM_CYCLONE_5CSEMA5_BLOCKS = 4,
    parameter CAN_RESET_POINTERS = 0
) (
    // clock and reset
    input  logic clk,
    input  logic reset,

    // read interface
    input  logic            ren,
    output logic [W_EL-1:0] rdata,
    output logic            empty,

    // write interface
    input  logic [W_EL-1:0] wdata,
    input  logic            wen,
    output logic            full,

    // cursor control (don't care if CAN_RESET_POINTERS == 0)
    input  logic                rrst,
    input  logic                wrst,
    input  logic [ADDR_WIDTH:0] rst_rptr,
    input  logic [ADDR_WIDTH:0] rst_wptr,
    output logic [ADDR_WIDTH:0] rptr,
    output logic [ADDR_WIDTH:0] wptr
);

    /* Assertions related to parameters. */
    initial begin
        if (
            NUM_CYCLONE_5CSEMA5_BLOCKS != 0 && (
                (ADDR_WIDTH != $clog2(NUM_CYCLONE_5CSEMA5_BLOCKS) + 9) ||
                (W_EL > 20)
            )
        )
            $error("Invalid generics in fifo_sync.");
            $finish;
    end

    // memory valid signals
    logic mem_wvalid, mem_rvalid;

    // cursors
    logic [ADDR_WIDTH:0] next_rptr;
    logic [ADDR_WIDTH:0] next_wptr;
    logic ptr_overlap;
    logic next_full, next_empty;

    /* Write logic. */
    assign mem_wvalid = wen && !full;
    generate
        if (CAN_RESET_POINTERS == 1) begin: g_resettable_wptr
            always @(posedge clk) begin
                if (reset) begin
                    wptr <= '0;
                    full <= 1'b0;
                end else if (wrst) begin
                    wptr <= rst_wptr;
                    full <= 1'b0;
                end else begin
                    wptr <= next_wptr;
                    full <= next_full;
                end
            end
        end else begin: g_wptr
            always @(posedge clk) begin
                if (reset) begin
                    wptr <= '0;
                    full <= 1'b0;
                end else begin
                    wptr <= next_wptr;
                    full <= next_full;
                end
            end
        end
    endgenerate
    always @(*) begin
        if (mem_wvalid) begin
            next_wptr = wptr + 1;
        end else begin
            next_wptr = wptr;
        end
    end

    /* Read logic. */
    assign mem_rvalid = ren && !empty;
    generate
        if (CAN_RESET_POINTERS == 1) begin: g_resettable_rptr
            always @(posedge clk) begin
                if (reset) begin
                    rptr <= '0;
                    empty <= 1'b0;
                end else if (rrst) begin
                    rptr <= rst_rptr;
                    empty <= 1'b0;
                end else begin
                    rptr <= next_rptr;
                    empty <= next_empty;
                end
            end
        end else begin: g_rptr
            always @(posedge clk) begin
                if (reset) begin
                    rptr <= '0;
                    empty <= 1'b0;
                end else begin
                    rptr <= next_rptr;
                    empty <= next_empty;
                end
            end
        end
    endgenerate
    always @(*) begin
        if (mem_rvalid) begin
            next_rptr = rptr + 1;
        end else begin
            next_rptr = rptr;
        end
    end

    // generate each block of memory
    genvar mem_block_i;
    generate
        if (NUM_CYCLONE_5CSEMA5_BLOCKS == 0) begin: g_mem
            logic [W_EL-1:0] mem [2**ADDR_WIDTH-1:0];

            // memory logic
            always_ff @(posedge clk) begin
                if (mem_wvalid) begin
                    mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
                end
                rdata <= mem[rptr[ADDR_WIDTH-1:0]];
            end
        end else if (NUM_CYCLONE_5CSEMA5_BLOCKS == 1) begin: g_single_block
            logic [W_EL-1:0] mem [511:0];

            // memory logic
            always_ff @(posedge clk) begin
                if (mem_wvalid) begin
                    mem[wptr[8:0]] <= wdata;
                end
                rdata <= mem[rptr[8:0]];
            end
        end else begin: g_mult_blocks
            logic [W_EL-1:0] mem_rdata [NUM_CYCLONE_5CSEMA5_BLOCKS-1:0];
            for (mem_block_i = 0; mem_block_i < NUM_CYCLONE_5CSEMA5_BLOCKS; ++mem_block_i) begin: g_cyclone_block
                // current memory block
                logic [W_EL-1:0] mem [511:0];

                // masked enable signal
                logic mem_block_wvalid;
                assign mem_block_wvalid = (wptr[ADDR_WIDTH-1:9] == mem_block_i) ? mem_wvalid : 1'b0;

                // memory logic
                always_ff @(posedge clk) begin
                    if (mem_block_wvalid) begin
                        mem[wptr[8:0]] <= wdata;
                    end
                    mem_rdata[mem_block_i] <= mem[rptr[8:0]];
                end
            end

            // select read output
            assign rdata = mem_rdata[rptr[ADDR_WIDTH-1:9]];
        end
    endgenerate

    // write intermediate signals
    assign ptr_overlap = (next_rptr[ADDR_WIDTH-1:0] === next_wptr[ADDR_WIDTH-1:0]) ? 1'b1 : 1'b0;
    assign next_full = (ptr_overlap && next_rptr[ADDR_WIDTH] !== next_wptr[ADDR_WIDTH]) ? 1'b1 : 1'b0;
    assign next_empty =  (ptr_overlap && next_rptr[ADDR_WIDTH] === next_wptr[ADDR_WIDTH]) ? 1'b1 : 1'b0;

    // assert FIFO displays full until a read completes
    assertion_fifo_sync_full_until_read : assert property(
        @(posedge clk) disable iff (rrst || wrst)
        $rose(full) |=> full || $past(ren, 1)
    ) else $error($sformatf("assertion_fifo_sync_full_until_read failed at %0t", $realtime));

    // assert FIFO displays empty until a write completes
    assertion_fifo_sync_empty_until_write : assert property(
        @(posedge clk) disable iff (rrst || wrst)
        $rose(empty) |=> empty || $past(wen, 1)
    ) else $error($sformatf("assertion_fifo_sync_empty_until_write failed at %0t", $realtime));

    // assert read reset and read enable not asserted at the same time
    assertion_fifo_sync_read_reset_enable : assert property(
        @(posedge clk) disable iff (reset)
        ~(rrst & ren)
    ) else $error("Read enable and read reset asserted in the same cycle");

    // assert write reset and write enable not asserted at the same time
    assertion_fifo_sync_write_reset_enable : assert property(
        @(posedge clk) disable iff (reset)
        ~(wrst & wen)
    ) else $error("Write enable and write reset asserted in the same cycle");

endmodule
