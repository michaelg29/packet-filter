// frame_generator.sv

/**
 * Register mapping
 *
 * Byte / mode | Name             | Meaning
 *        0W   |  Destination MAC |  Destination MAC byte 0.
 *        1W   |  Destination MAC |  Destination MAC byte 1.
 *        2W   |  Destination MAC |  Destination MAC byte 2.
 *        3W   |  Destination MAC |  Destination MAC byte 3.
 *        4W   |  Destination MAC |  Destination MAC byte 4.
 *        5W   |  Destination MAC |  Destination MAC byte 5.
 *        6W   |       Source MAC |       Source MAC byte 0.
 *        7W   |       Source MAC |       Source MAC byte 1.
 *        8W   |       Source MAC |       Source MAC byte 2.
 *        9W   |       Source MAC |       Source MAC byte 3.
 *       10W   |       Source MAC |       Source MAC byte 4.
 *       11W   |       Source MAC |       Source MAC byte 5.
 *       12W   |   Payload length |   Payload length byte 0.
 *       13W   |   Payload length |   Payload length byte 1.
 *       14W   |       Type field |       Type field byte 0.
 *       15W   |       Type field |       Type field byte 1.
 *       16W   | Inter-frame wait |  Cycles to wait between frames.
 *       17R   |         Checksum | Payload checksum byte 0.
 *       18R   |         Checksum | Payload checksum byte 1.
 *       19R   |         Checksum | Payload checksum byte 2.
 *       20R   |         Checksum | Payload checksum byte 3.
 */

`timescale 1 ps / 1 ps
module frame_generator #(
        parameter STUBBING = `STUBBING_PASSTHROUGH
    ) (
		input  wire        clk,                //          clock.clk
		input  wire        reset,              //          reset.reset
		input  wire [7:0]  writedata,          // avalon_slave_0.writedata
		input  wire        write,              //               .write
		input  wire        chipselect,         //               .chipselect
		input  wire [7:0]  address,            //               .address
		input  wire        read,               //               .read
		output wire [7:0]  readdata,           //               .readdata
		output wire [15:0] egress_port_tdata,  //    egress_port.tdata
		output wire        egress_port_tlast,  //               .tlast
		input  wire        egress_port_tready, //               .tready
		output wire        egress_port_tvalid  //               .tvalid
	);

generate
if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough

	assign egress_port_tvalid = 1'b0;
	assign egress_port_tdata = 16'b0000000000000000;
	assign egress_port_tlast = 1'b0;

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
