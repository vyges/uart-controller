//=============================================================================
// File Name: sim_main.cpp
//=============================================================================
// Description: Main simulation file for UART controller testbench
//              using Verilator.
//
// Author: shivaram@vyges.com
// License: Apache-2.0
//=============================================================================

#include "Vtb_uart_controller.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    // Create DUT
    Vtb_uart_controller* dut = new Vtb_uart_controller;
    
    // Create trace file
    VerilatedVcdC* trace = new VerilatedVcdC;
    dut->trace(trace, 99);
    trace->open("uart_controller.vcd");
    
    // Initialize signals
    dut->pclk_i = 0;
    dut->presetn_i = 0;
    dut->psel_i = 0;
    dut->penable_i = 0;
    dut->pwrite_i = 0;
    dut->paddr_i = 0;
    dut->pwdata_i = 0;
    dut->uart_rx_i = 1;
    
    // Reset sequence
    for (int i = 0; i < 10; i++) {
        dut->pclk_i = 0;
        dut->eval();
        trace->dump(i * 2);
        dut->pclk_i = 1;
        dut->eval();
        trace->dump(i * 2 + 1);
    }
    
    dut->presetn_i = 1;
    
    // Run simulation
    for (int i = 0; i < 10000; i++) {
        dut->pclk_i = 0;
        dut->eval();
        trace->dump(i * 2);
        dut->pclk_i = 1;
        dut->eval();
        trace->dump(i * 2 + 1);
        
        // Check for simulation end
        if (Verilated::gotFinish()) {
            break;
        }
    }
    
    // Cleanup
    trace->close();
    delete dut;
    delete trace;
    
    std::cout << "Simulation completed successfully!" << std::endl;
    return 0;
} 