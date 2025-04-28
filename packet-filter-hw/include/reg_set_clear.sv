
module reg_set_clear (
    input  logic clk,
    input  logic reset,
    input  logic set,
    input  logic clear,
    output logic data
);

    always_ff @(posedge clk) begin
        if (reset) begin
            data <= 1'b0;
        end else begin
            if (set) begin
                data <= 1'b1;
            end else if (clear) begin
                data <= 1'b0;
            end else begin
                data <= data;
            end
        end
    end

endmodule
