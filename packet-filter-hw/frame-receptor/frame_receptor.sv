// frame_receptor.sv


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
 *        6W   | Inter-frame wait |  Cycles to wait between frames.
  *       7R   |         dstcheck |  Destination check.
 *        8R   |         Checksum |  Payload checksum byte 0.
 *        9R   |         Checksum |  Payload checksum byte 1.
 *        10R  |         Checksum |  Payload checksum byte 2.
 *        11R  |         Checksum |  Payload checksum byte 3.
 */

`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif

`timescale 1 ps / 1 ps
module frame_receptor #(
       parameter STUBBING = `STUBBING_PASSTHROUGH,
       parameter CAN_RESET_POINTERS = 0
    ) (
		input  wire        clk,                 //          clock.clk
		input  wire        reset,               //          reset.reset
		input  wire [7:0]  writedata,           // avalon_slave_0.writedata
		input  wire        write,               //               .write
		input  wire        chipselect,          //               .chipselect
		input  wire [7:0]  address,             //               .address
		input  wire        read,                //               .read
		output logic [7:0]  readdata,            //               .readdata
		input  wire [15:0] ingress_port_tdata,  //   ingress_port.tdata
		input  wire        ingress_port_tvalid, //               .tvalid
		output logic        ingress_port_tready, //               .tready
		input  wire        ingress_port_tlast   //               .tlast
	);

	/* Register file. */
    logic [7:0] inter_frame_wait;
    logic [7:0]  reg_file [0:6];
    logic [7:0] dstcheck;
    logic [31:0] checksum;
    logic [7:0] input_counter;
    logic [7:0] frame_counter;
// generate
// if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough

// 	assign ingress_port_tready = 1'b0;

// end else begin: g_functional

// end
// endgenerate
    assign ingress_port_tready = (inter_frame_wait == 0) ? 1'b1 : 1'b0;
    // register write interface
    always_ff @(posedge clk) begin
        if(reset) begin
            for (int i = 0; i <= 6; i++)
                reg_file[i] <= 8'h00;
        end
        else if (chipselect && write)  begin
            if(address <= 6)
                reg_file[address[2:0]] <= writedata;
        end
    end
    //inter_frame_wait signal
    always_ff @(posedge clk) begin
        if(reset) begin
            inter_frame_wait <= 0;
        end
        if (ingress_port_tlast) begin
            inter_frame_wait <= reg_file[6];
        end else if (inter_frame_wait > 0 && (input_counter == 0)) begin
            inter_frame_wait <= inter_frame_wait - 8'h01;
        end
    end
    // register read interface
    always_ff @(posedge clk) begin
        if (chipselect && read) begin
            if(address <= 6)
                readdata <= reg_file[address[2:0]];
            else if (address >= 7 && address <= 11)
                case (address)
                    7  : readdata <= dstcheck;
                    8  : readdata <= checksum[7:0];
                    9  : readdata <= checksum[15:8];
                    10 : readdata <= checksum[23:16];
                    11 : readdata <= checksum[31:24];
                endcase
        end
        else begin
            readdata <= 8'h00;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            checksum <= 0;
            input_counter <= 0;
            frame_counter <= 0;
            dstcheck <= 0;
        end else if (ingress_port_tvalid && (inter_frame_wait == 0)) begin
            if(input_counter == 0) begin
                if({reg_file[1], reg_file[0]} == ingress_port_tdata) begin
                    dstcheck <= dstcheck + 8'h01;
                end
                checksum <= 0;
                dstcheck <= 0;
                input_counter <= input_counter + 8'h01;
            end else if(input_counter == 1) begin
                if({reg_file[3], reg_file[2]} == ingress_port_tdata) begin
                    dstcheck <= dstcheck + 8'h01;
                end
                input_counter <= input_counter + 8'h01;
            end else if(input_counter == 2) begin
                if({reg_file[5], reg_file[4]} == ingress_port_tdata) begin
                    dstcheck <= dstcheck + 8'h01;
                end
                input_counter <= input_counter + 8'h01;
            end else if(input_counter >= 3 && input_counter <= 6) begin
                input_counter <= input_counter + 8'h01;
            end else if(input_counter >= 7 && !ingress_port_tlast) begin
                checksum <= checksum + {16'h00, ingress_port_tdata};
                input_counter <= input_counter + 8'h01;
            end else if(input_counter >= 7 && ingress_port_tlast) begin
                checksum <= checksum + {16'h00, ingress_port_tdata};
                frame_counter <= frame_counter + 8'h01;
                input_counter <= 0;
            end
        end
    end
endmodule
