#include <iostream>
#include "Vpacket_filter.h"
#include "../tb_common/packet_filter.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <stdio.h>

#define CLK 20
#define HFCLK 10
#define RESET_HALF_CYCLES 5

bool last_clock;
Vpacket_filter *dut;
VerilatedVcdC *tfp;
int realtime;

eth_frame_t ingress_0_frame;
eth_frame_t ingress_1_frame;
eth_frame_t ingress_2_frame;
eth_frame_t ingress_3_frame;

// realtime step
void tick(int half_cycles, int drop, int almost_full, int valid, int last) {
  for (int i = 0; i < half_cycles; ++i, realtime += HFCLK) {
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      // default stimulus
      dut->ingress_port_0_tvalid = 0;
      dut->ingress_port_1_tvalid = 0;
      dut->ingress_port_2_tvalid = 0;
      dut->ingress_port_3_tvalid = 0;
    }

    // tick
    dut->eval(); 	// Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value
    }
    last_clock = dut->clk;
  }
}

int timeout_count = 50;
void send_frame() {
  int not_ready_count = 0;

  while (true) {
    // toggle clock
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      // default stimulus
      dut->ingress_port_1_tvalid = 0;
      dut->ingress_port_2_tvalid = 0;
      dut->ingress_port_3_tvalid = 0;

      dut->ingress_port_0_tdata = get_tdata(&ingress_0_frame);
      dut->ingress_port_0_tvalid = ingress_0_frame.valid;
      dut->ingress_port_0_tlast = ingress_0_frame.last;

      dut->egress_port_0_tready = dut->egress_port_0_tvalid;
      dut->egress_port_1_tready = dut->egress_port_1_tvalid;
      dut->egress_port_2_tready = dut->egress_port_2_tvalid;
      dut->egress_port_3_tready = dut->egress_port_3_tvalid;
    }

    // tick
    dut->eval(); 	// Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value

      update_frame(&ingress_0_frame, dut->ingress_port_0_tready);
      if (ingress_0_frame.valid && !dut->ingress_port_0_tready) {
        ++not_ready_count;
      }
    }
    last_clock = dut->clk;
    realtime += HFCLK;

    if (ingress_0_frame.done) {
      std::cout << "Frame completed transmission." << std::endl;
      break;
    }

    if (not_ready_count >= timeout_count) {
      std::cout << "Transmission timed out" << std::endl;
      break;
    }
  }
}

void wait_flush() {
  while (true) {
    // toggle clock
    dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

    if (!dut->clk && last_clock) {
      // default stimulus
      dut->ingress_port_0_tvalid = 0;
      dut->ingress_port_1_tvalid = 0;
      dut->ingress_port_2_tvalid = 0;
      dut->ingress_port_3_tvalid = 0;

      dut->egress_port_0_tready = dut->egress_port_0_tvalid;
      dut->egress_port_1_tready = dut->egress_port_1_tvalid;
      dut->egress_port_2_tready = dut->egress_port_2_tvalid;
      dut->egress_port_3_tready = dut->egress_port_3_tvalid;
    }

    // tick
    dut->eval(); 	// Run the simulation for a cycle
    tfp->dump(realtime); // Write the VCD file for this cycle
    if (dut->clk && !last_clock) {
      if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value
    }
    last_clock = dut->clk;
    realtime += HFCLK;

    if (!dut->egress_port_0_tvalid &&
        !dut->egress_port_1_tvalid &&
        !dut->egress_port_2_tvalid &&
        !dut->egress_port_3_tvalid) {
      break;
    }
  }
}

#define NUM_CSRS 6
int csr_base_addresses[NUM_CSRS] = {
  4, 8, 12, 16, 20, 24
};
const char *csr_names[NUM_CSRS] = {
  "Ingress packets",
  "Transferred packets",
  "Ingress frames",
  "Transferred frames",
  "Invalid frames",
  "Dropped frames"
};
int csr_vals[4][NUM_CSRS];

void read_ingress_stats(int ingress_idx) {
  bool read;
  for (int i = 0; i < NUM_CSRS; ++i) {
    read = true;
    // send read request
    while (true) {
      // toggle clock
      dut->clk = ((realtime % CLK) < HFCLK) ? 1 : 0;

      if (!dut->clk && last_clock) {
        // default stimulus
        dut->chipselect = 1;
        dut->read = read;
        dut->address = csr_base_addresses[i] + ingress_idx;
      }

      // tick
      dut->eval(); 	// Run the simulation for a cycle
      tfp->dump(realtime); // Write the VCD file for this cycle
      if (dut->clk && !last_clock) {
        if (realtime >= 60) std::cout << realtime << ": " << std::endl; // Print the next value

        // read statistics
        csr_vals[ingress_idx][i] = dut->readdata;
      }
      last_clock = dut->clk;
      realtime += HFCLK;

      if (!read) break;
      read = false;
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

  dut = new Vpacket_filter;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("packet_filter.vcd");

  // Initial values
  dut->reset = 1;
  init_statistics_collection(&ingress_0_frame);

  // simulation start
  last_clock = true;
  realtime = 0;

  reset();

  tick(32, 0, 0, 0, 0);

  init_frame(&ingress_0_frame, 1, 11, 50, false, 0, 0);
  init_frame(&ingress_1_frame, 1, 11, 50, false, 0, 0);
  init_frame(&ingress_2_frame, 1, 11, 50, false, 0, 0);
  init_frame(&ingress_3_frame, 1, 11, 50, false, 0, 0);
  send_frame();

  tick(32, 0, 0, 0, 0);

  /*init_frame(&ingress_0_frame, 1, 11, 50, false, 0, 0);
  send_frame();

  tick(32, 0, 0, 0, 0);

  init_frame(&ingress_0_frame, 1, 11, 50, false, 0, 0);
  send_frame();

  tick(32, 0, 0, 0, 0);*/

  // allow for flush
  wait_flush();

  std::cout << "ingress_0 statistics" << std::endl;
  report(&ingress_0_frame, realtime / CLK, CLK);

  std::cout << "Reading from CSRs" << std::endl;
  read_ingress_stats(0);
  read_ingress_stats(1);
  read_ingress_stats(2);
  read_ingress_stats(3);

  std::cout << std::endl;

  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  std::cout << "Final CSRs:" << std::endl;
  std::cout << "ingress_port";
  for (int j = 0; j < NUM_CSRS; j++) {
    std::cout << "," << csr_names[j];
  }
  std::cout << std::endl;
  for (int i = 0; i < 4; i++) {
    std::cout << i;
    for (int j = 0; j < NUM_CSRS; j++) {
      std::cout << "," << csr_vals[i][j];
    }
    std::cout << std::endl;
  }

  return 0;
}



