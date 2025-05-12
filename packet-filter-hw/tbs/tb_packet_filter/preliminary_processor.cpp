#include <iostream>
#include "Vpreliminary_processor.h"
#include "../tb_common/packet_filter.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <stdio.h>

#define CLK 20
#define HFCLK 10
#define RESET_HALF_CYCLES 5

bool last_clock;
Vpreliminary_processor *dut;
VerilatedVcdC *tfp;
int realtime;

int tdata_cnt = 1;
eth_frame_t frame;

// realtime step
void tick(int half_cycles, int drop, int almost_full, int valid, int last) {
  for (int i = 0; i < half_cycles; ++i, realtime += HFCLK) {
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      // default stimulus
      dut->drop_write = drop;
      dut->almost_full = almost_full;
      dut->ingress_source = {tdata_cnt, valid, last}; // data, valid, last

      // reset values
      drop = 0;
      almost_full = almost_full;
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value
      if ((tdata_cnt <= last) && dut->ingress_sink.__PVT__tready) {
        tdata_cnt++;
      }
    }
    last_clock = dut->clk;
  }
}



void send_frame(int timeout_count) {
  int not_ready_count = 0;

  while (true) {
    // toggle clock
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      dut->drop_write = frame.drop;
      dut->almost_full = frame.almost_full;
      dut->ingress_source = {get_tdata(&frame), 1, frame.last};
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << dut->ingress_sink.__PVT__tready << "cursor is " << frame.cursor << " out of " << frame.last_cursor << std::endl; // Print the next value

      update_frame(&frame, dut->ingress_sink.__PVT__tready);

      if (frame.valid && !dut->ingress_sink.__PVT__tready) {
        ++not_ready_count;
      }
    }
    last_clock = dut->clk;
    realtime += HFCLK;

    if (frame.done) {
      std::cout << "Frame completed transmission." << std::endl;
      break;
    }

    if (not_ready_count >= timeout_count) {
      std::cout << "Transmission timed out" << std::endl;
      break;
    }
  }
}

void reset() {
  dut->reset = 1;
  tick(RESET_HALF_CYCLES, 0, 0, 0, 0);
  dut->reset = 0;
}

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  dut = new Vpreliminary_processor;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("preliminary_processor.vcd");

  // Initial values
  dut->reset = 1;
  init_statistics_collection(&frame);

  // first frame

  // simulation start
  last_clock = true;
  realtime = 0;

  reset();

  //init_frame(eth_frame_t *frame, uint32_t dest, uint32_t preamble_packets, uint32_t payload_length, bool init_almost_full, uint32_t almost_full_wait, uint32_t drop_wait)
  init_frame(&frame, 0, 11, 50, false, 0, 0);
  send_frame(30);

  tick(32, 0, 0, 0, 0);

  init_frame(&frame, 0, 11, 80, false, 30, 0);
  send_frame(30);

  tick(32, 0, 0, 0, 0);

  init_frame(&frame, 0, 11, 80, false, 0, 30);
  send_frame(30);

  tick(32, 0, 0, 0, 0);

  init_frame(&frame, 0, 11, 80, true, 0, 0);
  send_frame(30);

  tick(32, 0, 0, 0, 0);

  init_frame(&frame, 0, 11, 80, false, 0, 0);
  send_frame(30);

  tick(32, 0, 0, 0, 0);

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  report(&frame, realtime / CLK, CLK);

  return 0;
}

