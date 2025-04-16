#include <iostream>
#include "Vfifo_sync.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  Vfifo_sync * dut = new Vfifo_sync;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("fifo_sync.vcd");

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
      dut->ren = 0;
      dut->wen = 0;
      dut->wdata = 0;
      dut->rst_rptr = 0;
      dut->rst_wptr = 0;

      // new stimulus
      switch (time) {
      case 50:
        dut->reset = 0;
        break;
      case 70:
        dut->wen = 1;
        dut->wdata = 15;
        break;
      case 90:
        dut->ren = 1;
        break;

      case 130:
        dut->wrst = 1;
        dut->rst_rptr = 15;
        dut->rst_wptr = 0b01000000000;
        break;
      case 150:
        dut->wrst = 0;
        break;

      case 170:
        dut->wen = 1;
        dut->wdata = 3;
        break;
      case 190:
        dut->ren = 1;
        break;

      case 230:
        dut->rrst = 1;
        dut->rst_rptr = 0b01000000000;
        break;
      case 250:
        dut->rrst = 0;
        break;

      case 270:
        dut->wen = 1;
        dut->wdata = 4;
        break;
      case 290:
        dut->ren = 1;
        break;
      };
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(time); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (time >= 60) std::cout << time << ": " << "full=" << dut->full << ", empty=" << dut->empty << ", rdata=" << dut->rdata << ", rptr=" << dut->rptr << ", wptr=" << dut->wptr << std::endl; // Print the next value
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

