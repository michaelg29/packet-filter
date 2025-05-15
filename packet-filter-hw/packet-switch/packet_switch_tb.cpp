#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vpacket_switch.h"
#include <vector>
#include <queue>
#include <random>
#include <bitset>
#include <iomanip>

#define MAX_SIM_TIME 10000
#define CLOCK_PERIOD 2
#define DATA_WIDTH 16
#define N_PORTS 4
#define IDX_WIDTH 2

class Packet {
public:
    uint16_t data;
    bool last;
    uint8_t dest;
    int size;
    int remaining;
    
    Packet(uint8_t d, int s, uint16_t start_data = 0) 
        : dest(d), size(s), remaining(s), data(start_data) {
        last = (size == 1);
    }
    
    bool advance() {
        remaining--;
        last = (remaining == 0);
        data++; 
        return last;
    }
};

class IngressPort {
public:
    std::queue<Packet> packets;
    bool active;
    uint8_t id;
    Packet* current_packet;
    
    IngressPort(uint8_t port_id) : id(port_id), active(false), current_packet(nullptr) {}
    
    void addPacket(Packet p) {
        packets.push(p);
    }
    
    bool hasPacket() {
        return !packets.empty() || active;
    }
    
    bool startNextPacket() {
        if (active || packets.empty()) return false;
        
        current_packet = new Packet(packets.front());
        packets.pop();
        active = true;
        return true;
    }
    
    void advancePacket() {
        if (!active || !current_packet) return;
        
        bool last = current_packet->advance();
        if (last) {
            delete current_packet;
            current_packet = nullptr;
            active = false;
        }
    }
    
    uint16_t getCurrentData() {
        return current_packet ? current_packet->data : 0;
    }
    
    bool isLast() {
        return current_packet ? current_packet->last : false;
    }
    
    uint8_t getDestination() {
        return current_packet ? current_packet->dest : 0;
    }
    
    ~IngressPort() {
        if (current_packet) delete current_packet;
    }
};

class EgressPort {
public:
    uint8_t id;
    bool ready;
    std::vector<uint16_t> received_data;
    int packets_received;
    
    EgressPort(uint8_t port_id) : id(port_id), ready(true), packets_received(0) {}
    
    void receiveData(uint16_t data, bool last) {
        received_data.push_back(data);
        if (last) packets_received++;
    }
    
    void setReady(bool r) {
        ready = r;
    }
};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    Vpacket_switch* dut = new Vpacket_switch;
  
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("packet_switch_trace.vcd");
    
    uint64_t sim_time = 0;
    uint8_t clk = 0;
    
    std::vector<IngressPort> ingress_ports;
    std::vector<EgressPort> egress_ports;
    for (int i = 0; i < N_PORTS; i++) {
        ingress_ports.push_back(IngressPort(i));
        egress_ports.push_back(EgressPort(i));
    }

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dst_dist(0, N_PORTS-1);
    std::uniform_int_distribution<> size_dist(1, 10);
    std::uniform_int_distribution<> data_dist(0, 65535);
    std::uniform_int_distribution<> prob_dist(0, 100);
    
    int total_packets_sent = 0;
    int total_packets_received = 0;
    std::vector<int> packets_per_ingress(N_PORTS, 0);
    std::vector<int> packets_per_egress(N_PORTS, 0);
    
    dut->reset = 1;
    dut->clk = 0;
    
    dut->chipselect = 0;
    dut->write = 0;
    dut->read = 0;
    dut->address = 0;
    dut->writedata = 0;

    dut->egress_port_0_tready = 1;
    dut->egress_port_1_tready = 1;
    dut->egress_port_2_tready = 1;
    dut->egress_port_3_tready = 1;
    
    dut->eval();
    tfp->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
    tfp->dump(sim_time++);
    
    dut->chipselect = 1;
    dut->write = 1;
    dut->address = 0;
    dut->writedata = 0xF; 
    dut->clk = 0;
    dut->eval();
    tfp->dump(sim_time++);
    dut->clk = 1;
    dut->eval();
    tfp->dump(sim_time++);
    
    dut->chipselect = 0;
    dut->write = 0;
    dut->reset = 0;

    while (sim_time < MAX_SIM_TIME) {
        clk = !clk;
        dut->clk = clk;

        if (clk == 0) {
            for (int i = 0; i < N_PORTS; i++) {
                if (!ingress_ports[i].hasPacket() && prob_dist(gen) < 15) {
                    uint8_t dest = dst_dist(gen);
                    int size = size_dist(gen);
                    uint16_t start_data = data_dist(gen);
                    ingress_ports[i].addPacket(Packet(dest, size, start_data));
                    total_packets_sent++;
                    packets_per_ingress[i]++;
                }

                ingress_ports[i].startNextPacket();
            }
            
            for (int i = 0; i < N_PORTS; i++) {
                egress_ports[i].setReady(prob_dist(gen) < 90);
            }
            
            dut->ingress_port_0_tvalid = ingress_ports[0].active;
            dut->ingress_port_0_tlast = ingress_ports[0].isLast();
            dut->ingress_port_0_tdest = ingress_ports[0].getDestination();
            dut->ingress_port_0_tdata = ingress_ports[0].getCurrentData();
            
            dut->ingress_port_1_tvalid = ingress_ports[1].active;
            dut->ingress_port_1_tlast = ingress_ports[1].isLast();
            dut->ingress_port_1_tdest = ingress_ports[1].getDestination();
            dut->ingress_port_1_tdata = ingress_ports[1].getCurrentData();
            
            dut->ingress_port_2_tvalid = ingress_ports[2].active;
            dut->ingress_port_2_tlast = ingress_ports[2].isLast();
            dut->ingress_port_2_tdest = ingress_ports[2].getDestination();
            dut->ingress_port_2_tdata = ingress_ports[2].getCurrentData();
            
            dut->ingress_port_3_tvalid = ingress_ports[3].active;
            dut->ingress_port_3_tlast = ingress_ports[3].isLast();
            dut->ingress_port_3_tdest = ingress_ports[3].getDestination();
            dut->ingress_port_3_tdata = ingress_ports[3].getCurrentData();
            
            dut->egress_port_0_tready = egress_ports[0].ready;
            dut->egress_port_1_tready = egress_ports[1].ready;
            dut->egress_port_2_tready = egress_ports[2].ready;
            dut->egress_port_3_tready = egress_ports[3].ready;
        }

        dut->eval();
        
        if (clk == 1) {
            if (dut->ingress_port_0_tready && ingress_ports[0].active) {
                ingress_ports[0].advancePacket();
            }
            if (dut->ingress_port_1_tready && ingress_ports[1].active) {
                ingress_ports[1].advancePacket();
            }
            if (dut->ingress_port_2_tready && ingress_ports[2].active) {
                ingress_ports[2].advancePacket();
            }
            if (dut->ingress_port_3_tready && ingress_ports[3].active) {
                ingress_ports[3].advancePacket();
            }
            
            if (dut->egress_port_0_tvalid && egress_ports[0].ready) {
                egress_ports[0].receiveData(dut->egress_port_0_tdata, dut->egress_port_0_tlast);
                if (dut->egress_port_0_tlast) {
                    packets_per_egress[0]++;
                    total_packets_received++;
                }
            }
            if (dut->egress_port_1_tvalid && egress_ports[1].ready) {
                egress_ports[1].receiveData(dut->egress_port_1_tdata, dut->egress_port_1_tlast);
                if (dut->egress_port_1_tlast) {
                    packets_per_egress[1]++;
                    total_packets_received++;
                }
            }
            if (dut->egress_port_2_tvalid && egress_ports[2].ready) {
                egress_ports[2].receiveData(dut->egress_port_2_tdata, dut->egress_port_2_tlast);
                if (dut->egress_port_2_tlast) {
                    packets_per_egress[2]++;
                    total_packets_received++;
                }
            }
            if (dut->egress_port_3_tvalid && egress_ports[3].ready) {
                egress_ports[3].receiveData(dut->egress_port_3_tdata, dut->egress_port_3_tlast);
                if (dut->egress_port_3_tlast) {
                    packets_per_egress[3]++;
                    total_packets_received++;
                }
            }
            
            if ((sim_time / CLOCK_PERIOD) % 100 == 0) {
                std::cout << "Time: " << sim_time 
                          << ", Packets sent: " << total_packets_sent
                          << ", Packets received: " << total_packets_received
                          << std::endl;

                std::cout << "Ingress ports - Valid: "
                          << dut->ingress_port_0_tvalid
                          << dut->ingress_port_1_tvalid
                          << dut->ingress_port_2_tvalid
                          << dut->ingress_port_3_tvalid
                          << " Ready: "
                          << dut->ingress_port_0_tready
                          << dut->ingress_port_1_tready
                          << dut->ingress_port_2_tready
                          << dut->ingress_port_3_tready
                          << std::endl;

                std::cout << "Egress ports - Valid: "
                          << dut->egress_port_0_tvalid
                          << dut->egress_port_1_tvalid
                          << dut->egress_port_2_tvalid
                          << dut->egress_port_3_tvalid
                          << " Ready: "
                          << dut->egress_port_0_tready
                          << dut->egress_port_1_tready
                          << dut->egress_port_2_tready
                          << dut->egress_port_3_tready
                          << std::endl;
            }
        }
   
        tfp->dump(sim_time++);
    }
    
    std::cout << "\n=== Simulation Statistics ===\n";
    std::cout << "Total packets sent: " << total_packets_sent << std::endl;
    std::cout << "Total packets received: " << total_packets_received << std::endl;
    
    std::cout << "Packets per ingress port:" << std::endl;
    for (int i = 0; i < N_PORTS; i++) {
        std::cout << "  Port " << i << ": " << packets_per_ingress[i] << std::endl;
    }
    
    std::cout << "Packets per egress port:" << std::endl;
    for (int i = 0; i < N_PORTS; i++) {
        std::cout << "  Port " << i << ": " << packets_per_egress[i] << std::endl;
    }
    
    tfp->close();
    delete tfp;
    delete dut;
    
    return 0;
}
