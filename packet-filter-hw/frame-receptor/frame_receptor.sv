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

`include "../include/packet_filter.svh"

`timescale 1 ps / 1 ps
module frame_receptor #(
       // parameter STUBBING = `STUBBING_PASSTHROUGH
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

	/* Register file. */
	logic [7:0] inter_frame_wait;
    logic [7:0]  reg_file [0:16];
    logic [31:0] checksum;

// generate
// if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough

// 	assign ingress_port_tready = 1'b0;

// end else begin: g_functional

// end
// endgenerate
    assign ingress_port_tready = ingress_port_tlast ? 1 : 0;
    // register write interface
    always_ff @(posedge clk) begin
        if (reset) begin
            inter_frame_wait <= 8'h0;
            for (int i = 0; i <= 16; i++)
                reg_file[i] <= 8'h00;
            checksum <= 0;
        end else if (chipselect && write) begin
            if(address <= 16) begin
                reg_file[address] <= writedata;
            end
            else if(address > 16 && address < (16 + {reg_file[13], reg_file[12]})) begin
                checksum <= checksum + writedata;
            end
        end
    end

    // register read interface
    always_ff @(posedge clk) begin
        if (chipselect && read) begin
            if(address <= 16)
                readdata <= reg_file[address];
            else if (address >= 17 && address <= 20)
                case (address & 4)
                    0 : readdata <= checksum[31:24];
                    1 : readdata <= checksum[7:0];
                    2 : readdata <= checksum[15:8];
                    3 : readdata <= checksum[23:16];
                endcase
        end
        else begin
            readdata <= 8'h00;
        end
    end

endmodule
