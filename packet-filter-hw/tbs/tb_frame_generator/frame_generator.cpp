#include <iostream>
#include <verilated.h>
#include "Vframe_generator.h"
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10
double sc_time_stamp() { return 0; }
int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  Vframe_generator * dut = new Vframe_generator;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("frame_generator.vcd");

  // Initial values

  dut->reset = 1;

  bool last_clock = true;
  int time;
  for (time = 0 ; time < 1040 ; time += HFCLK) {
	dut->clk = ((time % CLK) < HFCLK) ? 1 : 0; // Simulate a 50 MHz clock

	// stimulus on negative edge
	std::cout << "clk is " << dut->clk << " prev is " << (last_clock ? '1' : '0') << std::endl;
	if (!dut->clk && last_clock) {
  	// default stimulus
  	dut->reset = dut->reset;
  	dut->writedata = 0;
  	dut->write = 0;
  	dut->chipselect = 0;
  	dut->address = 0;
  	dut->read = 0;
  	dut->egress_port_tready = 1;

  	// new stimulus
  	switch (time) {
  	//reading address check
  	//case 50:
    	//dut->reset = 0;
	//dut->chipselect = 1;
    	//dut->writedata = 1;
    	//dut->write = 1;
    	//break;
  	//case 70:
	//dut->chipselect = 1;
    	//dut->writedata = 2;
    	//dut->write = 1;
    	//break;
  	//case 90:
	//dut->chipselect = 1;
    	//dut->writedata = 3;
    	//dut->write = 1;
    	//break;
  	//case 110:
	//dut->address = 0;
	//dut->chipselect = 1;
    	//dut->read = 1;
    	//break;
  	//case 130:
	//dut->address = 1;
	//dut->chipselect = 1;
    	//dut->read = 1;
   	// break;
  	//case 150:
	//dut->address = 2;
	//dut->chipselect = 1;
    	//dut->read = 1;
	//dut->reset = 1;
    	//break;

  	//write ethernet type packet
  	case 50:
    	dut->reset = 0;
    	dut->address = 0;
	dut->chipselect = 1;
    	dut->writedata = 1;
    	dut->write = 1;
	dut->egress_port_tready = 0;
    	break;
  	case 70:
	dut->chipselect = 1;
    	dut->address = 1;  
    	dut->writedata = 2;
    	dut->write = 1;
	dut->egress_port_tready = 0;
    	break;
  	case 90:
	dut->chipselect = 1;
    	dut->address = 2;
    	dut->writedata = 3;
    	dut->write = 1;
	dut->egress_port_tready = 0;
    	break;
  	case 110:
	dut->chipselect = 1;
    	dut->address = 3;
    	dut->writedata = 4;
    	dut->write = 1;
	dut->egress_port_tready = 0;
    	break;
  	case 130:
	dut->chipselect = 1;
    	dut->address = 4;
    	dut->writedata = 5;
    	dut->write = 1;
	dut->egress_port_tready = 0;
    	break;
  	case 150:
	dut->chipselect = 1;
    	dut->address = 5;
    	dut->writedata = 6;
    	dut->write = 1;
	dut->egress_port_tready = 0;
    	break;
  	case 170:
	dut->chipselect = 1;
    	dut->writedata = 7;
    	dut->write = 1;
    	dut->address = 6;
	dut->egress_port_tready = 0;
    	break;
  	case 190:
	dut->chipselect = 1;
    	dut->writedata = 8;
    	dut->write = 1;
    	dut->address = 7;
	dut->egress_port_tready = 0;
    	break;
  	case 210:
	dut->chipselect = 1;
    	dut->writedata = 9;
    	dut->write = 1;
    	dut->address = 8;
	dut->egress_port_tready = 0;
    	break;
  	case 230:
	dut->chipselect = 1;
    	dut->writedata = 10;
    	dut->write = 1;
    	dut->address = 9;
	dut->egress_port_tready = 0;
    	break;
  	case 250:
	dut->chipselect = 1;
    	dut->writedata = 11;
    	dut->write = 1;
    	dut->address = 10;
	dut->egress_port_tready = 0;
    	break;
  	case 270:
	dut->chipselect = 1;
    	dut->writedata = 12;
    	dut->write = 1;
    	dut->address = 11;
	dut->egress_port_tready = 0;
    	break;
  	case 290:
	dut->chipselect = 1;
    	dut->writedata = 0x01;
    	dut->write = 1;
    	dut->address = 12;
	dut->egress_port_tready = 0;
    	break;
  	case 310:
	dut->chipselect = 1;
    	dut->writedata = 0x00;
    	dut->write = 1;
    	dut->address = 13;
	dut->egress_port_tready = 0;
    	break;
  	case 330:
	dut->chipselect = 1;
    	dut->writedata = 0xFF;
    	dut->write = 1;
    	dut->address = 14;
	dut->egress_port_tready = 0;
    	break;
  	case 350:
	dut->chipselect = 1;
    	dut->writedata = 0xFF;
    	dut->write = 1;
    	dut->address = 15;
	dut->egress_port_tready = 0;
    	break;
  	case 370:
	dut->chipselect = 1;
    	dut->writedata = 10;
    	dut->write = 1;
    	dut->address = 16;
	dut->egress_port_tready = 0;
    	break;
  	case 390:
	dut->chipselect = 1;
    	dut->writedata = 10;
    	dut->write = 1;
    	dut->address = 17;
	dut->egress_port_tready = 1;
    	break;
  	case 410:
	dut->egress_port_tready = 1;
    	break;
  	case 430:
	dut->egress_port_tready = 1;
    	break;
  	};
	}

	// tick
	dut->eval(); 	// Run the simulation for a cycle
	tfp->dump(time); // Write the VCD file for this cycle
	if (dut->clk && !last_clock) {
  	if (time >= 60) std::cout << time << ": " << "readdata=" << dut->readdata << ", egress_port_tdata=" << dut->egress_port_tdata << ", egress_port_tvalid=" << dut->egress_port_tvalid << ", egress_port_tlast=" << dut->egress_port_tlast << std::endl; // Print the next value
	}
	last_clock = dut->clk;
  }

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}


