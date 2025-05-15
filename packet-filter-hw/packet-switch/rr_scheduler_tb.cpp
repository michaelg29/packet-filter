#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vrr_scheduler.h"
#include <vector>
#include <queue>
#include <random>
#include <bitset>

#define MAX_SIM_TIME 1000
#define CLOCK_PERIOD 2

class Packet {
public:
    bool last;
    uint8_t dst;
    int size;
    int remaining;
    
    Packet(uint8_t d, int s) : dst(d), size(s), remaining(s) {
        last = false;
    }
    
    bool advance() {
        remaining--;
        last = (remaining == 0);
        return last;
    }
};

class IngressPort {
public:
    std::queue<Packet> packets;
    bool active;
    uint8_t id;
    
    IngressPort(uint8_t port_id) : id(port_id), active(false) {}
    
    void addPacket(Packet p) {
        packets.push(p);
    }
    
    bool hasPacket() {
        return !packets.empty();
    }
    
    Packet& currentPacket() {
        return packets.front();
    }
    
    void popPacket() {
        if (!packets.empty()) {
            packets.pop();
        }
    }
};

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    // Create an instance of our module
    Vrr_scheduler* dut = new Vrr_scheduler;
    
    // Initialize VCD tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("rr_scheduler_trace.vcd");
    
    // Initialize simulation time and clock
    uint64_t sim_time = 0;
    uint8_t clk = 0;
    
    // Test parameters
    const int N_PORTS = 4;
    const int IDX_WIDTH = 2;
    
    // Create ingress ports
    std::vector<IngressPort> ingress_ports;
    for (int i = 0; i < N_PORTS; i++) {
        ingress_ports.push_back(IngressPort(i));
    }
    
    // Random number generators
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dst_dist(0, N_PORTS-1);
    std::uniform_int_distribution<> size_dist(1, 10);
    std::uniform_int_distribution<> port_dist(0, N_PORTS-1);
    std::uniform_int_distribution<> prob_dist(0, 100);
    
    // Current egress port we're testing
    uint8_t current_egress_port = 0;
    int egress_port_hold_cycles = 0;
    
    // Statistics
    int total_packets_sent = 0;
    int cycles_active = 0;
    std::vector<int> packets_per_port(N_PORTS, 0);
    
    // Reset the DUT
    dut->reset = 1;
    dut->clk = 0;
    dut->eval();
    tfp->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
    tfp->dump(sim_time++);
    dut->reset = 0;
    
    // Main simulation loop
    while (sim_time < MAX_SIM_TIME) {
        // Toggle clock
        clk = !clk;
        dut->clk = clk;
        
        // On negative clock edge, update inputs
        if (clk == 0) {
            // Randomly generate new packets (20% chance per cycle)
            if (prob_dist(gen) < 20) {
                int port = port_dist(gen);
                if (!ingress_ports[port].active && !ingress_ports[port].hasPacket()) {
                    uint8_t dst = dst_dist(gen);
                    int size = size_dist(gen);
                    ingress_ports[port].addPacket(Packet(dst, size));
                }
            }
            
            // Periodically change egress port (every 10-20 cycles)
            if (egress_port_hold_cycles <= 0) {
                current_egress_port = dst_dist(gen);
                egress_port_hold_cycles = 10 + (prob_dist(gen) % 11);
            }
            egress_port_hold_cycles--;
            
            // Set egress port ID
            dut->egress_port_id = current_egress_port;
            
            // Set egress ready (80% chance of being ready)
            dut->egress_ready = (prob_dist(gen) < 80) ? 1 : 0;
            
            // Update ingress signals
            for (int i = 0; i < N_PORTS; i++) {
                // If port has a packet and isn't currently active
                if (ingress_ports[i].hasPacket() && !ingress_ports[i].active) {
                    ingress_ports[i].active = true;
                }
                
                // Set valid and destination signals
                if (ingress_ports[i].active) {
                    dut->ingress_valid |= (1 << i);
                    dut->ingress_dst[i] = ingress_ports[i].currentPacket().dst;
                if (ingress_ports[i].currentPacket().last) {
                    dut->ingress_last |= (1 << i);  // Set the bit
                } else {
                    dut->ingress_last &= ~(1 << i);  // Clear the bit
                }

                } else {
                    dut->ingress_valid &= ~(1 << i);
                    dut->ingress_last &= ~(1 << i);  // Clear the bit

                }
            }
        }
        
        // Evaluate the design
        dut->eval();
        
        // On positive clock edge, check outputs
        if (clk == 1) {
            // Check if any port is granted and ready
            for (int i = 0; i < N_PORTS; i++) {
                if ((dut->ingress_ready >> i) & 0x1) {
                    if (ingress_ports[i].active) {
                        // Advance the packet
                        bool last = ingress_ports[i].currentPacket().advance();
                        
                        // If this was the last flit, remove the packet
                        if (last) {
                            ingress_ports[i].popPacket();
                            ingress_ports[i].active = false;
                            total_packets_sent++;
                            packets_per_port[i]++;
                        }
                    }
                }
            }
            
            // Count active cycles
            if (dut->egress_valid) {
                cycles_active++;
            }
            
            // Print debug info every 20 cycles
            if ((sim_time / CLOCK_PERIOD) % 20 == 0) {
                std::cout << "Time: " << sim_time 
                          << ", Egress port: " << (int)current_egress_port
                          << ", Selected ingress: " << (int)dut->selected_ingress
                          << ", Valid: " << (dut->egress_valid ? "YES" : "NO")
                          << ", Last: " << (dut->egress_last ? "YES" : "NO")
                          << ", Ready: " << (dut->egress_ready ? "YES" : "NO")
                          << ", Ingress valid: " << std::bitset<N_PORTS>(dut->ingress_valid)
                          << ", Ingress ready: " << std::bitset<N_PORTS>(dut->ingress_ready)
                          << std::endl;
            }
        }
        
        // Dump signals to VCD
        tfp->dump(sim_time++);
    }
    
    // Print statistics
    std::cout << "\n=== Simulation Statistics ===\n";
    std::cout << "Total packets sent: " << total_packets_sent << std::endl;
    std::cout << "Active cycles: " << cycles_active << " (" 
              << (100.0 * cycles_active / (MAX_SIM_TIME/2)) << "%)" << std::endl;
    std::cout << "Packets per port:" << std::endl;
    for (int i = 0; i < N_PORTS; i++) {
        std::cout << "  Port " << i << ": " << packets_per_port[i] << std::endl;
    }
    
    // Cleanup
    tfp->close();
    delete tfp;
    delete dut;
    
    return 0;
}
