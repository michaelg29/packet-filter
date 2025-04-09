// frame_generator.sv

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
//
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module frame_generator (
		input  wire        clk,                //          clock.clk
		input  wire        reset,              //          reset.reset
		input  wire [7:0]  writedata,          // avalon_slave_0.writedata
		input  wire        write,              //               .write
		input  wire        chipselect,         //               .chipselect
		input  wire [2:0]  address,            //               .address
		output wire [15:0] egress_port_tdata,  //    egress_port.tdata
		output wire        egress_port_tlast,  //               .tlast
		input  wire        egress_port_tready, //               .tready
		output wire        egress_port_tvalid  //               .tvalid
	);

	// TODO: Auto-generated HDL template

	assign egress_port_tvalid = 1'b0;

	assign egress_port_tdata = 16'b0000000000000000;

	assign egress_port_tlast = 1'b0;

endmodule
