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

`ifdef VERILATOR
`include "packet_filter.svh"
`else
`include "../include/packet_filter.svh"
`endif

`timescale 1 ps / 1 ps
module frame_generator #(
       parameter STUBBING = `STUBBING_PASSTHROUGH,
       parameter CAN_RESET_POINTERS = 0
    ) (
		input  wire         clk,                //          clock.clk
		input  wire         reset,              //          reset.reset
		input  wire  [31:0] writedata,          // avalon_slave_0.writedata
		input  wire         write,              //               .write
		input  wire         chipselect,         //               .chipselect
		input  wire  [7:0]  address,            //               .address
		input  wire         read,               //               .read
		output logic [31:0] readdata,           //               .readdata
		output logic [15:0] egress_port_tdata,  //    egress_port.tdata
		output logic        egress_port_tlast,  //               .tlast
		input  wire         egress_port_tready, //               .tready
		output logic        egress_port_tvalid  //               .tvalid
	);

	/* Register file. */
    logic [7:0]  reg_file [0:16];
    logic [31:0] checksum;
    logic [15:0] payload_byte;
    logic [15:0]  byte_counter;
    logic        sending;
    logic [7:0]  wait_counter;
    //logic [7:0] input_counter;
    logic [7:0] frame_counter;
    //logic [15:0] type_temp;
    // register write interface
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i <= 16; i++)
                reg_file[i] <= 8'h00;
            checksum <= 0;
            payload_byte <= 0;
	        //input_counter <= 0;
        end else if (chipselect && write) begin
            if(address <= 16) begin
                reg_file[address[4:0]] <= writedata[7:0];
            end else if(address > 16) begin
		        if({reg_file[13], reg_file[12]} != 0) begin
		            if({8'h00,address} <= (17 + {reg_file[13], reg_file[12]})) begin
		                if(!address[0])
                    	    payload_byte[7:0] <= writedata[7:0];
                    	else
                            payload_byte[15:8] <= writedata[7:0];
                        checksum <= checksum + {24'b0, writedata[7:0]};
		            end
                end
            end
		end          
    end	


    // register read interface
    always_ff @(posedge clk) begin
        if (reset) begin
            readdata <= 32'h0;
        end else if (chipselect && read) begin
            if(address <= 16)
                readdata[7:0] <= reg_file[address[4:0]];
            else if (address >= 17 && address <= 20)
                case (address)
                    17 : readdata[7:0] <= checksum[7:0];
                    18 : readdata[7:0] <= checksum[15:8];
                    19 : readdata[7:0] <= checksum[23:16];
                    20 : readdata[7:0] <= checksum[31:24];
                endcase
        end
        else begin
            readdata <= 32'h00;
        end
    end
    //Frame State Machine
    always_ff @(posedge clk) begin
        if(reset) begin
            sending <= 0;
            byte_counter <= 0;
            wait_counter <= 0;
            frame_counter <= 0;
        end
        else begin
            if(!sending && wait_counter == 0 && egress_port_tready) begin
                sending <= 1;
                byte_counter <= 0;
            end
            else if (sending && egress_port_tready) begin
                if(byte_counter >= (24 + {reg_file[13], reg_file[12]})) begin
                    frame_counter <= frame_counter + 8'h01;
                    sending <= 0;
                    wait_counter <= reg_file[16];
                end else
		    byte_counter <= byte_counter + 16'h02;
            end
            else if(!sending && wait_counter > 0) begin
                wait_counter <= wait_counter - 8'h01;
            end
        end
    end

    //Frame data
    always_comb begin
        egress_port_tvalid = sending;
        egress_port_tlast = (byte_counter == (24 + {reg_file[13], reg_file[12]} -2));
        egress_port_tdata = 16'h0000;
        if(sending) begin
            unique case (byte_counter)
		        //preamble
		        0  : egress_port_tdata = 16'hAAAA;
		        2  : egress_port_tdata = 16'hAAAA;
		        4  : egress_port_tdata = 16'hAAAA;
		        //preamble & sfd
		        6  : egress_port_tdata = 16'hAAAB;
                //dst
                8  : egress_port_tdata = {reg_file[0], reg_file[1]};
                10  : egress_port_tdata = {reg_file[2], reg_file[3]};
                12  : egress_port_tdata = {reg_file[4], reg_file[5]};
                //source
                14  : egress_port_tdata = {reg_file[6], reg_file[7]};
                16  : egress_port_tdata = {reg_file[8], reg_file[9]};
                18 : egress_port_tdata = {reg_file[10], reg_file[11]};
                //length
                20 : egress_port_tdata = {reg_file[12], reg_file[13]};
                //type
                22 : egress_port_tdata = {reg_file[14], reg_file[15]};
                default: begin
                    if(byte_counter >= 24) begin
		                if({reg_file[13], reg_file[12]} != 0) begin
			                if(byte_counter < (24 + {reg_file[13], reg_file[12]}))			
                            	egress_port_tdata = payload_byte;
			            end
		            end
                end
            endcase
	    end
    end
endmodule
