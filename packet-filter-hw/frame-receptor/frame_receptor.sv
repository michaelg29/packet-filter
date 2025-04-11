// frame_receptor.v

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
// 
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module frame_receptor (
		input  wire        clk,                 //          clock.clk
		input  wire        reset,               //          reset.reset
		input  wire [7:0]  writedata,           // avalon_slave_0.writedata
		input  wire        write,               //               .write
		input  wire        chipselect,          //               .chipselect
		input  wire [2:0]  address,             //               .address
		input  wire        read,                //               .read
		output wire [7:0]  readdata,            //               .readdata
		input  wire [15:0] ingress_port_tdata,  //   ingress_port.tdata
		input  wire        ingress_port_tvalid, //               .tvalid
		output wire        ingress_port_tready, //               .tready
		input  wire        ingress_port_tlast   //               .tlast
	);

	// TODO: Auto-generated HDL template

	assign readdata = 8'b00000000;

	assign ingress_port_tready = 1'b0;

endmodule
