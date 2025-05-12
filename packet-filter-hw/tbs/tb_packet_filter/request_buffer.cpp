#include <iostream>
#include "Vrequest_buffer.h"
#include "../tb_common/packet_filter.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <stdio.h>

#define CLK 20
#define HFCLK 10
#define RESET_HALF_CYCLES 5

bool last_clock;
Vrequest_buffer *dut;
VerilatedVcdC *tfp;
int realtime;

int tdata_cnt = 1;

// realtime step
void tick(int half_cycles, int drop, int almost_full, int valid, int last) {
  for (int i = 0; i < half_cycles; ++i, realtime += HFCLK) {
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      dut->status = { 0, 0, 0, 0, 0 }; // scan_frame, dst_mac, src_mac, type, payload
      dut->frame_type = { 0, 0 }; // valid, user
      dut->frame_dest = { 0, 0, 0 }; // data, valid, user
      dut->ingress_pkt = { 0, 0, 0 }; // data, valid, last
      dut->egress_sink = { 0 }; // tready
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value
      //if ((tdata_cnt <= last) && dut->ingress_sink.__PVT__tready) {
      //  tdata_cnt++;
      //}
    }
    last_clock = dut->clk;
  }
}



void send_frame(int preamble_delay, int frame_length, int drop_count, int almost_full_count) {
  int this_tdata_cnt = 1;

  while (true) {
    // toggle clock
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    int tdata;
    if (this_tdata_cnt < preamble_delay) {
      tdata = 0xAAAA;
    }
    else if (this_tdata_cnt == preamble_delay) {
      tdata = 0xAAAB;
    }
    else {
      tdata = this_tdata_cnt;
    }

    if (!dut->clk && last_clock) {
      // default stimulus
      //dut->drop_write = this_tdata_cnt == drop_count;
      //dut->almost_full = almost_full_count > 0 && this_tdata_cnt >= almost_full_count;
      //dut->ingress_source = {tdata, // data
      //  this_tdata_cnt <= frame_length,  // valid
      //  this_tdata_cnt == frame_length}; // last
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value
      //if (dut->ingress_sink.__PVT__tready) {
      //  std::cout << "ready" << std::endl;
      //  this_tdata_cnt++;
      //}
      //else {
      //  std::cout << "not ready" << std::endl;
      //}
    }
    last_clock = dut->clk;
    realtime += HFCLK;

    if (this_tdata_cnt > frame_length) {
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

  dut = new Vrequest_buffer;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("request_buffer.vcd");

  // Initial values
  dut->reset = 1;

  // first frame

  // simulation start
  last_clock = true;
  realtime = 0;

  reset();

  send_frame(11, 50, 0, 0);

  tick(32, 0, 0, 0, 0);

  send_frame(11, 80, 30, 0);

  tick(32, 0, 0, 0, 0);

  send_frame(11, 80, 0, 30);

  tick(32, 0, 0, 0, 0);

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}

