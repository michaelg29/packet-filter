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

`include "../include/packet_filter.svh"

`timescale 1 ps / 1 ps
module frame_generator #(
       // parameter STUBBING = `STUBBING_PASSTHROUGH      
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

	/* Register file. */
    logic [7:0]  reg_file [0:16];
    logic [31:0] checksum;
    logic [15:0] payload_len;
    logic [15:0] payload_byte;
    logic [7:0]  byte_counter;
    logic        sending;
    logic [7:0]  wait_counter;

// generate
// if (STUBBING == `STUBBING_PASSTHROUGH) begin: g_passthrough

// 	assign egress_port_tvalid = 1'b0;
// 	assign egress_port_tdata = 16'b0000000000000000;
// 	assign egress_port_tlast = 1'b0;

// end else begin: g_functional

// end
// endgenerate

    // register write interface
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i <= 16; i++)
                reg_file[i] <= 8'h00;
            checksum <= 0;
            payload_byte <= 0;
        end else if (chipselect && write) begin
            if(address <= 16) begin
                reg_file[address] <= writedata;
            end
            else if(address > 16 && address < (16 + {reg_file[13], reg_file[12]})) begin
                if(address % 2)
                    payload_byte[7:0] <= writedata;
                else
                    payload_byte[15:8] <= writedata;
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

    //Frame State Machine
    always_ff @(poesdge clk) begin
        if(reset) begin
            sending <= 0;
            byte_counter <= 0;
            wait_counter <= 0;
        end 
        else begin
            payload_len = {reg_file[13], reg_file[12]};
            if(!sending && wait_counter == 0) begin
                sending <= 1;
                byte_counter <= 0;
            end
            else if (sending && egress_port_tready) begin
                byte_counter <= byte_counter + 2;
                if(byte_counter == (16 + payload_len - 2)) begin
                    sending <= 0;
                    wait_counter <= reg_file[16];
                end
            end
            else if(!sending && wait_counter > 0) begin
                wait_counter <= wait_counter - 1;
            end
        end
    end

    //Frame data
    always_comb begin
        egress_port_tvalid = sending;
        egress_port_tlast = (byte_counter >= (16 + payload_len -2));
        egress_port_tdata = 16'h0000;
        if(sending) begin
            unique case (byte_counter)
                //dst
                0  : egress_port_tdata = {reg_file[0], reg_file[1]};
                2  : egress_port_tdata = {reg_file[2], reg_file[3]};
                4  : egress_port_tdata = {reg_file[4], reg_file[5]};
                //source
                6  : egress_port_tdata = {reg_file[6], reg_file[7]};
                8  : egress_port_tdata = {reg_file[8], reg_file[9]};
                10 : egress_port_tdata = {reg_file[10], reg_file[11]};
                //length
                12 : egress_port_tdata = {reg_file[12], reg_file[13]};
                //type
                14 : egress_port_tdata = {reg_file[14], reg_file[15]};
                default: begin
                    if(byte_counter >= 16 && byte_counter < (16 + payload_len)) begin
                        egress_port_tdata = payload_byte;
                    end
                end
            endcase
        end
    end
endmodule
