module mux4to1 #(
    parameter N_PORTS = 4,
    parameter DATA_WIDTH = 32,
    parameter IDX_WIDTH = $clog2(N_PORTS)
)(
    input  logic [N_PORTS-1:0][DATA_WIDTH-1:0] ingress_data,
    input  logic [IDX_WIDTH-1:0]               selected_ingress,
    output logic [DATA_WIDTH-1:0]              egress_data
);

    always_comb begin
        egress_data = ingress_data[selected_ingress];
    end

endmodule
