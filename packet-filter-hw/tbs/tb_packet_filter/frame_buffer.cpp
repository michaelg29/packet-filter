#include <iostream>
#include "Vframe_buffer.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

#define CLK 20
#define HFCLK 10

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  Vframe_buffer * dut = new Vframe_buffer;

  // Enable dumping a VCD file

  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("frame_buffer.vcd");

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
      dut->ingress_pkt = {0,0,0}; // data, valid, last
      dut->scan_frame = dut->scan_frame;
      dut->drop_write = 0;
      dut->frame_ren = 0;
      dut->frame_rrst = 0;
      dut->frame_rst_rptr = 0;

      // new stimulus
      switch (time) {
      case 50:
        dut->reset = 0;
        break;

      case 90:
        dut->ingress_pkt = {1,1,0};
        dut->scan_frame = 1;
        break;

      case 110:
        dut->ingress_pkt = {2,1,0};
        break;

      case 130:
        dut->frame_ren = 1;
        break;

      case 150:
        dut->ingress_pkt = {3,1,0};
        break;

      case 170:
        dut->ingress_pkt = {4,1,0};
        break;

      case 190:
        dut->ingress_pkt = {5,1,0};
        break;

      case 210:
        dut->frame_ren = 1;
        break;

      case 230:
        dut->frame_ren = 1;
        dut->ingress_pkt = {6,1,0};
        break;

      case 250:
        dut->frame_ren = 1;
        break;

      case 270:
        dut->frame_ren = 1;
        break;

      case 290:
        dut->ingress_pkt = {7,1,0};
        break;

      case 310:
        dut->ingress_pkt = {8,1,1};
        break;

      case 330:
        dut->frame_ren = 1;
        dut->scan_frame = 0;
        break;

      case 350:
        dut->frame_ren = 1;
        break;

      case 370:
        dut->frame_ren = 1;
        break;

      case 390:
        dut->frame_ren = 1;
        break;

      case 410:
        dut->frame_ren = 1;
        break;

      case 430:
        dut->frame_ren = 1;
        break;

      case 450:
        dut->reset = 1;
        break;

      case 490:
        dut->reset = 0;
        break;

      case 510:
        dut->ingress_pkt = {1,1,0};
        dut->scan_frame = 1;
        break;

      case 530:
        dut->ingress_pkt = {2,1,0};
        break;

      case 570:
        dut->ingress_pkt = {3,1,0};
        dut->drop_write = 1;
        dut->scan_frame = 0;
        break;

      case 590:
        dut->ingress_pkt = {4,1,0};
        break;

      case 610:
        dut->ingress_pkt = {5,1,0};
        break;

      case 630:
        dut->ingress_pkt = {6,1,1};
        break;

      case 650:
        dut->ingress_pkt = {1,1,0};
        dut->scan_frame = 1;
        break;

      case 670:
        dut->ingress_pkt = {2,1,0};
        break;

      case 690:
        dut->ingress_pkt = {3,1,1};
        dut->frame_ren = 1;
        break;

      case 710:
        dut->scan_frame = 0;
        dut->frame_ren = 1;
        break;

      case 730:
        dut->ingress_pkt = {11,1,0};
        dut->scan_frame = 1;
        break;

      case 750:
        dut->ingress_pkt = {12,1,0};
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

