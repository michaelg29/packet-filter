// frame_receptor.sv

/**
 * Register mapping
 *
 * Byte / mode | Name             | Meaning
 *        0W   | Inter-frame wait |  Cycles to wait between frames (de-assert tready).
 *        1R   |         Checksum | Payload checksum byte 0.
 *        2R   |         Checksum | Payload checksum byte 1.
 *        3R   |         Checksum | Payload checksum byte 2.
 *        4R   |         Checksum | Payload checksum byte 3.
 */

`timescale 1 ps / 1 ps
module frame_receptor #(
        parameter STUBBING = `STUBBING_PASSTHROUGH
    ) (
		input  wire        clk,                 //          clock.clk
		input  wire        reset,               //          reset.reset
		input  wire [7:0]  writedata,           // avalon_slave_0.writedata
		input  wire        write,               //               .write
		input  wire        chipselect,          //               .chipselect
		input  wire [7:0]  address,             //               .address
		input  wire        read,                //               .read
		output wire [7:0]  readdata,            //               .readdata
		input  wire [15:0] ingress_port_tdata,  //   ingress_port.tdata
		input  wire        ingress_port_tvalid, //               .tvalid
		output wire        ingress_port_tready, //               .tready
		input  wire        ingress_port_tlast   //               .tlast
	);

generate
if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough

	assign ingress_port_tready = 1'b0;

end else begin: g_functional

end
endgenerate

    // register write interface
	assign readdata = 8'b00000000;
    always_ff @(posedge clk) begin
        if (reset) begin

        end else if (chipselect && write) begin
            case (address)

            endcase
        end
    end

    // register read interface
    always_ff @(posedge clk) begin
        if (reset) begin
            readdata <= 8'b0;
        end else if (chipselect && read) begin
            case (address)

            endcase
        end
    end

	// interrupt interface
	assign irq = 1'b0;

endmodule
