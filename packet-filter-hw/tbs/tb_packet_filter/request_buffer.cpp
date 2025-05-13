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
eth_frame_t frame;

// realtime step
void tick(int half_cycles, int tready) {
  uint16_t tdata;
  for (int i = 0; i < half_cycles; ++i, realtime += HFCLK) {
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      tdata = get_tdata(&frame);
      dut->status = { frame.status.a[0], frame.status.a[1], frame.status.a[2], frame.status.a[3], frame.status.a[4] }; // scan_frame, dst_mac, src_mac, type, payload
      dut->frame_type = { frame.status.a[3], 0 }; // valid, user
      dut->frame_dest = { 0, 0, 0 }; // data, valid, user
      dut->ingress_pkt = { tdata, frame.valid, frame.last }; // data, valid, last
      dut->egress_sink = { tready }; // tready
      //std::cout << "Set tdata to " << tdata << ", scan_frame is " << frame.status.a[0] << " or " << frame.status.s.scan_frame << std::endl;
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



void send_frame(bool type_valid, uint32_t dest, bool dest_valid, uint32_t ready_delay) {
  uint16_t tdata;
  while (true) {
    // toggle clock
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      tdata = get_tdata(&frame);
      dut->status = { frame.status.a[0], frame.status.a[1], frame.status.a[2], frame.status.a[3], frame.status.a[4] }; // scan_frame, dst_mac, src_mac, type, payload
      dut->frame_type = { frame.status.a[3], !type_valid }; // valid, user
      dut->frame_dest = { dest, frame.status.a[2], !dest_valid }; // data, valid, user
      dut->ingress_pkt = { tdata, 1, frame.last }; // data, valid, last
      dut->egress_sink = { ready_delay == 0 }; // tready
      //std::cout << "Set tdata to " << tdata << ", scan_frame is " << frame.status.a[0] << " or " << frame.status.s.scan_frame << std::endl;
    }

    // tick
    dut->eval();     // Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << "cursor is " << frame.cursor << " out of " << frame.last_cursor << std::endl; // Print the next value

      update_frame(&frame, 1);

      if (dut->egress_source.__PVT__tvalid && ready_delay) {
        ready_delay--;
      }
    }
    last_clock = dut->clk;
    realtime += HFCLK;

    if (frame.done) {
      std::cout << "Frame completed transmission." << std::endl;
      break;
    }
  }
}

void reset() {
  dut->reset = 1;
  tick(RESET_HALF_CYCLES, 0);
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

  init_frame(&frame, 1, 11, 50, false, 0, 0);
  send_frame(true, 1, true, 6);

  tick(80, 1);
  tick(32, 0);

  init_frame(&frame, 2, 11, 50, false, 0, 0);
  send_frame(false, 2, true, 6);

  tick(80, 1);
  tick(32, 0);

  init_frame(&frame, 3, 11, 50, false, 0, 0);
  send_frame(true, 3, true, 6);

  tick(80, 1);
  tick(32, 0);

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}

