#include <iostream>
#include "Vdest_calculator.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  Vdest_calculator * dut = new Vdest_calculator;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("dest_calculator.vcd");

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
      dut->dst_mac_pkt = {0,0};

      // new stimulus
      switch (time) {
      case 50:
        dut->reset = 0;
        break;

      case 90:
        dut->dst_mac_pkt = {0x1234, 1};
        break;

      case 110:
        dut->dst_mac_pkt = {0x5678, 1};
        break;

      case 170:
        dut->dst_mac_pkt = {0x9ABC, 1};
        break;

      case 190:
        dut->dst_mac_pkt = {0xFFFF, 1};
        break;

      case 250:
        dut->dst_mac_pkt = {0xFFFF, 1};
        break;

      case 270:
        dut->dst_mac_pkt = {0xFFFF, 1};
        break;
      };
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

