
typedef union {
    logic [47:0] bits;
    logic [ 7:0] bytes  [5:0];
    logic [15:0] hwords [2:0];
} mac_t;

module dest_calculator (
    input  logic clk,
    input  logic reset,

    input  logic        dst_mac_valid,
    input  logic [15:0] data,

    output logic        dest_valid,
    output logic [ 1:0] dest
);

    mac_t dst_mac, next_dst_mac;
    logic [1:0] cnt, next_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            dst_mac.bits <= 48'b0;
            cnt <= 2'b0;
        end else begin
            dst_mac <= next_dst_mac;
            cnt <= next_cnt;
        end
    end

    always_comb begin: g_next_dst
        if (dst_mac_valid) begin
            next_dst_mac.hwords[2] = dst_mac.hwords[1];
            next_dst_mac.hwords[1] = dst_mac.hwords[0];
            next_dst_mac.hwords[0] = data;
        end else begin
            next_dst_mac = dst_mac;
        end
    end

    always_comb begin: g_next_cnt
        if (cnt === 2'b11) begin
            next_cnt = 2'b00;
        end else if (dst_mac_valid) begin
            next_cnt = cnt + 1;
        end else begin
            next_cnt = cnt;
        end
    end

    assign dest = dst_mac.bits[1:0];
    assign dest_valid = (cnt === 2'b11) ? 1'b1 : 1'b0;

endmodule
