#include <iostream>
#include <verilated.h>
#include "Vframe_receptor.h"
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10
double sc_time_stamp() { return 0; }
int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  Vframe_receptor * dut = new Vframe_receptor;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("frame_receptor.vcd");

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
      dut->ingress_port_tdata = 0;
      dut->ingress_port_tvalid = 0;
      dut->ingress_port_tlast = 0;

      // new stimulus
      switch (time) {
      //write ethernet type packet
      case 50:
        dut->reset = 0;
	dut->chipselect = 1;
        dut->writedata = 1;
        dut->write = 1;
        dut->address = 0;
        break;
      case 70:
        dut->chipselect = 1;
        dut->writedata = 2;
        dut->write = 1;
        dut->address = 1;
        break;
      case 90:
	dut->chipselect = 1;
        dut->writedata = 3;
        dut->write = 1;
	dut->address = 2;
        break;
      case 110:
	dut->chipselect = 1;
        dut->writedata = 4;
        dut->write = 1;
        dut->address = 3;
        break;
      case 130:
	dut->chipselect = 1;
        dut->writedata = 5;
        dut->write = 1;
        dut->address = 4;
        break;
      case 150:
	dut->chipselect = 1;
        dut->writedata = 6;
        dut->write = 1;
        dut->address = 5;
        break;
      case 170:
	dut->chipselect = 1;
        dut->writedata = 7;
        dut->write = 1;
        dut->address = 6;
        break;
      // case 190:
	    //   dut->ingress_port_tvalid = 1;
      //   dut->ingress_port_tdata = 0xAAAA;
      //   break;
      // case 210:
      //   dut->ingress_port_tvalid = 1;
      //   dut->ingress_port_tdata = 0xAAAA;
      //   break;
      // case 230:
      //   dut->ingress_port_tvalid = 1;
      //   dut->ingress_port_tdata = 0xAAAB;
      //   break;
      case 250:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0x0201;
        break;
      case 270:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0x0403;
        break;
      case 290:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0x0605;
        break;
      case 310:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0xAAAA;
        break;
      case 330:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0xAAAA;
        break;
      case 350:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0xAAAA;
        break;
      case 370:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0xAAAA;
        break;
      case 390:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0x0001;
        break;
      case 410:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tdata = 0x0002;
        break;
      case 430:
        dut->ingress_port_tvalid = 1;
        dut->ingress_port_tlast = 1;
        dut->ingress_port_tdata = 0x0003;
        break;
      };
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(time); // Write the VCD file for this cycle
//     if (dut->clk && !last_clock) {
//       if (time >= 60) std::cout << time << ": " << "readdata=" << dut->readdata << ", egress_port_tdata=" << dut->egress_port_tdata << ", egress_port_tvalid=" << dut->egress_port_tvalid << ", egress_port_tlast=" << dut->egress_port_tlast << std::endl; // Print the next value
//     }
    last_clock = dut->clk;
  }

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}

