#include <iostream>
#include "Vinput_fsm.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  Vinput_fsm * dut = new Vinput_fsm;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("input_fsm.vcd");

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
      dut->ingress_source = {0,0,0}; // data, valid, last
      dut->drop_current = 0;
      dut->almost_full = 0;

      // new stimulus
      switch (time) {
      case 50:
        dut->reset = 0;
        break;

// first frame: valid
      case 90:
        dut->ingress_source = {0xAAAA, 1, 0};
        break;

      case 110:
        dut->ingress_source = {0xAAAB, 1, 0};
        break;

      case 130:
        dut->ingress_source = {0xDEEF, 1, 0};
        break;

      case 150:
        dut->ingress_source = {0xCAFE, 1, 0};
        break;

      case 170:
        dut->ingress_source = {0xBE31, 1, 0};
        break;

      case 190:
        dut->ingress_source = {0x1234, 1, 0};
        break;

      case 210:
        dut->ingress_source = {0x5678, 1, 0};
        break;

      case 250:
        dut->ingress_source = {0x9ABC, 1, 0};
        break;

      case 350:
        dut->ingress_source = {0x9ABC, 1, 0};
        break;

      case 390:
        dut->ingress_source = {0x9ABC, 1, 0};
        break;

      case 410:
        dut->ingress_source = {0x9ABC, 1, 1};
        break;

// second frame: premature drop
      case 490:
        dut->ingress_source = {0xAAAB, 1, 0};
        break;

      case 510:
        dut->ingress_source = {0xDEEF, 1, 1};
        break;

// third frame: premature drop
      case 590:
        dut->ingress_source = {0xAAAB, 1, 1};
        break;

// fourth frame: premature drop
      case 650:
        dut->ingress_source = {0xAAAB, 0, 1};
        break;
      }
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(time); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (time >= 60) std::cout << time << ": " << std::endl; // Print the next value
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

