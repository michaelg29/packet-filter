#include <iostream>
#include "Vinput_fsm.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10
#define RESET_HALF_CYCLES 5

bool last_clock;
Vinput_fsm *dut;
VerilatedVcdC *tfp;
int realtime;

// realtime step
void tick(int half_cycles, int tdata, int tvalid, int tlast, int drop_current, int almost_full) {
  for (int i = 0; i < half_cycles; ++i, realtime += HFCLK) {
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      // default stimulus
      dut->ingress_source = {tdata, tvalid, tlast}; // data, valid, last
      dut->drop_current = drop_current;
      dut->almost_full = almost_full;
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value
    }
    last_clock = dut->clk;

    // reset values
    tdata = 0;
    tvalid = 0;
    tlast = 0;
    drop_current = 0;
    almost_full = almost_full;
  }
}

void reset() {
  dut->reset = 1;
  tick(RESET_HALF_CYCLES, 0, 0, 0, 0, 0);
  dut->reset = 0;
}

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  dut = new Vinput_fsm;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("input_fsm.vcd");

  // Initial values
  dut->reset = 1;

  // simulation start
  last_clock = true;
  realtime = 0;

  reset();
  tick(8, 0, 0, 0, 0, 0);

  // first frame: valid
  tick(2, 0xAAAA, 1, 0, 0, 0);
  tick(2, 0xAAAB, 1, 0, 0, 0);
  for (int j = 0; j < 20; j++)
    tick(2, j, 1, 0, 0, 0);
  tick(2, 21, 1, 1, 0, 0);
  tick(8, 0, 0, 0, 0, 0);

  // second frame: premature last
  tick(2, 0xAAAB, 1, 0, 0, 0);
  tick(2, 0xDEEF, 1, 1, 0, 0);
  tick(8, 0, 0, 0, 0, 0);

  // third frame: premature last
  tick(2, 0xAAAB, 1, 1, 0, 0);
  tick(8, 0, 0, 0, 0, 0);

  // fourth frame: premature last
  tick(2, 0xAAAA, 1, 1, 0, 0);
  tick(8, 0, 0, 0, 0, 0);

  // fifth frame: backpressure in middle of frame
  tick(2, 0xAAAB, 1, 0, 0, 0);
  for (int j = 0; j < 20; j++)
    tick(2, j, 1, 0, 0, 1);
  tick(2, 21, 1, 1, 0, 1);
  tick(2, 0xAAAB, 1, 0, 0, 1);
  tick(8, 0, 0, 0, 0, 0);

  // sixth frame: backpressure before frame
  tick(2, 0xAAAA, 1, 0, 0, 1);
  tick(2, 0xAAAB, 1, 0, 0, 1);
  tick(8, 0, 0, 0, 0, 0);

  // seventh frame: drop frame
  tick(2, 0xAAAB, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 2, 1, 0, 0, 0);
  tick(2, 3, 1, 0, 0, 0);
  tick(2, 4, 1, 0, 1, 0);
  tick(2, 5, 1, 0, 0, 0);
  tick(2, 6, 1, 1, 0, 0);
  tick(2, 0xAAAB, 1, 0, 0, 0);
  for (int j = 0; j < 20; j++)
    tick(2, j, 1, 0, 0, 1);
  tick(2, 21, 1, 1, 0, 1);
  tick(8, 0, 0, 0, 0, 1);

  tick(8, 0, 0, 0, 0, 0);

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}

