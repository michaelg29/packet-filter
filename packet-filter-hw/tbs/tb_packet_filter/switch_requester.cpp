#include <iostream>
#include "Vswitch_requester.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10
#define RESET_HALF_CYCLES 5
#define NUM_FRAMES 3

bool last_clock;
Vswitch_requester *dut;
VerilatedVcdC *tfp;
int realtime;

typedef struct {
  int frame_rptr;
  int tdest;
} sideband_entry;

int encode_sideband_entry(sideband_entry e) {
  return (e.tdest & 0b11) | ((e.frame_rptr & 0b11111111111) << 2);
}

int frame_ren_cnt = 0;
int sideband_ren_cnt = 0;
sideband_entry sideband_rdata_arr[NUM_FRAMES] = {{2, 1}, {8, 2}, {17, 3}};

void tick(int half_cycles, int scan_payload, int sideband_empty, int frame_last_entry, int frame_rptr, int egress_tready) {
  for (int i = 0; i < half_cycles; ++i, realtime += HFCLK) {
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    // stimulus
    if (!dut->clk && last_clock) {
      dut->scan_payload = scan_payload;
      dut->sideband_rdata = encode_sideband_entry(sideband_rdata_arr[sideband_ren_cnt % NUM_FRAMES]);
      dut->sideband_empty = sideband_empty;
      dut->frame_rdata = frame_ren_cnt;
      dut->frame_last_entry = frame_last_entry;
      dut->frame_rptr = frame_rptr;
      dut->egress_sink = {egress_tready};

      // reset values
      scan_payload = scan_payload;
      sideband_empty = sideband_empty;
      frame_last_entry = frame_last_entry & ~dut->frame_ren;
      frame_rptr = frame_rptr;
      egress_tready = egress_tready;
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value

      // FIFO response on next rising edge
      if (!dut->reset) {
        frame_ren_cnt = frame_ren_cnt + (dut->frame_ren ? 1 : 0);
        sideband_ren_cnt = sideband_ren_cnt + (dut->sideband_ren ? 1 : 0);
      }
    }
    last_clock = dut->clk;
  }
}

void reset() {
  dut->reset = 1;
  tick(RESET_HALF_CYCLES, 0, 0, 0, 0, 0);
  dut->reset = 0;
}

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  dut = new Vswitch_requester;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("switch_requester.vcd");

  // Initial values
  dut->reset = 1;

  // simulation start
  last_clock = true;
  realtime = 0;

  // initial reset
  reset();

  // args: scan_payload, sideband_rdata, sideband_empty, frame_rdata, frame_last_entry, frame_rptr, egress_tready

  // idle state
  tick(8, 0, 1, 0, 0, 0);

  // write frame without asserting scan_payload
  tick(2, 0, 0, 0, 0, 0);
  tick(2, 0, 1, 0, 0, 0);
  tick(2, 0, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 1);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 1, 1, 0, 0, 0);
  tick(2, 0, 1, 0, 0, 0);

  // end of testcase
  tick(32, 0, 1, 0, 0, 0);

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}

