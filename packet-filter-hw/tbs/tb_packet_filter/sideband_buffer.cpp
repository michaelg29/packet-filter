#include <iostream>
#include "Vsideband_buffer.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10
#define RESET_HALF_CYCLES 5
#define NUM_FRAMES 3

bool last_clock;
Vsideband_buffer *dut;
VerilatedVcdC *tfp;
int realtime;

void tick(int half_cycles, int scan_frame, int scan_payload, int frame_type_invalid, int ren, int frame_wptr, int frame_dest, int frame_dest_invalid) {
  for (int i = 0; i < half_cycles; ++i, realtime += HFCLK) {
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    // stimulus
    if (!dut->clk && last_clock) {
      dut->scan_frame = scan_frame;
      dut->scan_payload = scan_payload;
      dut->ren = ren;
      dut->frame_wptr = frame_wptr;
      dut->frame_type = {frame_type_invalid & 0b1, frame_type_invalid >> 1}; // tvalid, tuser
      dut->frame_dest = {frame_dest, frame_dest >= 0 ? 1 : 0, frame_dest_invalid}; // tdata, tvalid, tuser
    }

    // tick
    dut->eval();     // Run the simulation for a half cycle
    tfp->dump(realtime); // Write the VCD file for this half cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) {
        std::cout << realtime << ": " << std::endl; // Print the next value
      }

      // response on next rising edge
      if (!dut->reset) {
      }
    }
    last_clock = dut->clk;
  }
}

void reset() {
  dut->reset = 1;
  tick(RESET_HALF_CYCLES, 0, 0, 0, 0, 0, -1, 0);
  dut->reset = 0;
}

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  dut = new Vsideband_buffer;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("sideband_buffer.vcd");

  // Initial values
  dut->reset = 1;

  // simulation start
  last_clock = true;
  realtime = 0;

  // initial reset
  reset();
  tick(32, 0, 0, 0, 0, 0, -1, 0);

  // scan_frame, scan_payload, {frame_type_tvalid, frame_type_tuser}, ren, frame_wptr, frame_dest, frame_dest_invalid
  tick(2, 0, 1, 0b11, 0, 0, 5, 1);
  tick(32, 0, 0, 0, 0, 0, -1, 0);

  tick(2, 1, 0, 0b00, 0, 0, -1, 0);
  tick(2, 1, 0, 0b00, 0, 0, -1, 0);
  tick(2, 1, 0, 0b00, 0, 0, -1, 0);
  tick(2, 1, 0, 0b00, 0, 0, -1, 0);
  tick(2, 1, 0, 0b00, 0, 0, 3, 1);
  tick(2, 1, 0, 0b10, 0, 0, -1, 0);
  tick(32, 0, 0, 0, 0, 0, -1, 0);

  // end of testcase
  tick(32, 0, 0, 0, 0, 0, -1, 0);

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}

