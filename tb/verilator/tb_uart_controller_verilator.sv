//=============================================================================
// Testbench Name: tb_uart_controller_verilator
//=============================================================================
// Description: Verilator-compatible SystemVerilog testbench for UART controller
//              with APB interface, FIFO operations, and interrupt testing.
//
// Features:
// - APB interface verification
// - UART transmission/reception testing
// - FIFO full/empty condition testing
// - Interrupt generation verification
// - Error condition testing
// - Coverage collection
//
// Author: shivaram@vyges.com
// License: Apache-2.0
//=============================================================================

`timescale 1ns/1ps

module tb_uart_controller_verilator;

    // Testbench parameters
    localparam int CLOCK_FREQUENCY = 50_000_000;
    localparam int BAUD_RATE = 115_200;
    localparam int FIFO_DEPTH = 16;
    localparam int DATA_WIDTH = 8;
    localparam int STOP_BITS = 1;
    localparam bit PARITY_ENABLE = 1'b0;
    localparam string PARITY_TYPE = "even";
    localparam int CLOCK_PERIOD = 1_000_000_000 / CLOCK_FREQUENCY;
    localparam int BAUD_PERIOD = 1_000_000_000 / BAUD_RATE;
    
    // Clock and reset signals
    logic pclk_i;
    logic presetn_i;
    
    // APB interface signals
    logic        psel_i;
    logic        penable_i;
    logic        pwrite_i;
    logic [7:0]  paddr_i;
    logic [31:0] pwdata_i;
    logic [31:0] prdata_o;
    logic        pready_o;
    logic        pslverr_o;
    
    // UART interface signals
    logic uart_tx_o;
    logic uart_rx_i;
    
    // Interrupt signals
    logic irq_tx_empty_o;
    logic irq_rx_full_o;
    
    // Testbench internal signals
    logic [7:0] test_data [$];
    logic [7:0] received_data [$];
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Clock generation
    initial begin
        pclk_i = 0;
        forever #(CLOCK_PERIOD/2) pclk_i = ~pclk_i;
    end
    
    // Reset generation
    initial begin
        presetn_i = 0;
        #(CLOCK_PERIOD * 10);
        presetn_i = 1;
    end
    
    // DUT instantiation
    uart_controller #(
        .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE),
        .FIFO_DEPTH(FIFO_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BITS(STOP_BITS),
        .PARITY_ENABLE(PARITY_ENABLE),
        .PARITY_TYPE(PARITY_TYPE)
    ) dut (
        .pclk_i(pclk_i),
        .presetn_i(presetn_i),
        .psel_i(psel_i),
        .penable_i(penable_i),
        .pwrite_i(pwrite_i),
        .paddr_i(paddr_i),
        .pwdata_i(pwdata_i),
        .prdata_o(prdata_o),
        .pready_o(pready_o),
        .pslverr_o(pslverr_o),
        .uart_tx_o(uart_tx_o),
        .uart_rx_i(uart_rx_i),
        .irq_tx_empty_o(irq_tx_empty_o),
        .irq_rx_full_o(irq_rx_full_o)
    );
    
    // APB task for register access
    task automatic apb_write(input logic [7:0] addr, input logic [31:0] data);
        @(posedge pclk_i);
        psel_i = 1'b1;
        penable_i = 1'b0;
        pwrite_i = 1'b1;
        paddr_i = addr;
        pwdata_i = data;
        @(posedge pclk_i);
        penable_i = 1'b1;
        @(posedge pclk_i);
        while (!pready_o) @(posedge pclk_i);
        psel_i = 1'b0;
        penable_i = 1'b0;
        @(posedge pclk_i);
    endtask
    
    task automatic apb_read(input logic [7:0] addr, output logic [31:0] data);
        @(posedge pclk_i);
        psel_i = 1'b1;
        penable_i = 1'b0;
        pwrite_i = 1'b0;
        paddr_i = addr;
        @(posedge pclk_i);
        penable_i = 1'b1;
        @(posedge pclk_i);
        while (!pready_o) @(posedge pclk_i);
        data = prdata_o;
        psel_i = 1'b0;
        penable_i = 1'b0;
        @(posedge pclk_i);
    endtask
    
    // UART receiver task
    task automatic uart_receive(output logic [7:0] data);
        logic [7:0] rx_data;
        int bit_count;
        
        // Wait for start bit
        @(negedge uart_tx_o);
        #(BAUD_PERIOD/2);
        
        // Sample data bits
        for (int i = 0; i < DATA_WIDTH; i++) begin
            #(BAUD_PERIOD);
            rx_data[i] = uart_tx_o;
        end
        
        // Skip parity bit if enabled
        if (PARITY_ENABLE) begin
            #(BAUD_PERIOD);
        end
        
        // Skip stop bits
        for (int i = 0; i < STOP_BITS; i++) begin
            #(BAUD_PERIOD);
        end
        
        data = rx_data;
    endtask
    
    // Test stimulus
    initial begin
        // Initialize signals
        psel_i = 0;
        penable_i = 0;
        pwrite_i = 0;
        paddr_i = 0;
        pwdata_i = 0;
        uart_rx_i = 1;
        
        // Wait for reset
        wait(presetn_i);
        #(CLOCK_PERIOD * 10);
        
        $display("=== UART Controller Verilator Testbench Started ===");
        $display("Clock Frequency: %d Hz", CLOCK_FREQUENCY);
        $display("Baud Rate: %d bps", BAUD_RATE);
        $display("FIFO Depth: %d", FIFO_DEPTH);
        
        // Test 1: Basic initialization
        test_count++;
        $display("\nTest %0d: Basic Initialization", test_count);
        
        // Read initial register values
        logic [31:0] ctrl_val, stat_val, baud_val;
        apb_read(8'h00, ctrl_val); // CTRL register
        apb_read(8'h04, stat_val); // STAT register
        apb_read(8'h10, baud_val); // BAUD register
        
        if (ctrl_val == 32'h0 && stat_val == 32'h0) begin
            $display("PASS: Initial register values correct");
            pass_count++;
        end else begin
            $display("FAIL: Initial register values incorrect");
            fail_count++;
        end
        
        // Test 2: Enable UART controller
        test_count++;
        $display("\nTest %0d: Enable UART Controller", test_count);
        
        apb_write(8'h00, 32'h07); // Enable TX, RX, and controller
        apb_read(8'h00, ctrl_val);
        
        if (ctrl_val == 32'h07) begin
            $display("PASS: UART controller enabled");
            pass_count++;
        end else begin
            $display("FAIL: UART controller not enabled");
            fail_count++;
        end
        
        // Test 3: FIFO operations
        test_count++;
        $display("\nTest %0d: FIFO Operations", test_count);
        
        // Write data to TX FIFO
        for (int i = 0; i < 4; i++) begin
            apb_write(8'h08, 32'h41 + i); // Write 'A', 'B', 'C', 'D'
            test_data.push_back(8'h41 + i);
        end
        
        // Check TX FIFO status
        apb_read(8'h04, stat_val);
        if (!(stat_val & 32'h04)) begin // TX_FULL should be 0
            $display("PASS: TX FIFO not full after 4 writes");
            pass_count++;
        end else begin
            $display("FAIL: TX FIFO full after 4 writes");
            fail_count++;
        end
        
        // Test 4: UART transmission
        test_count++;
        $display("\nTest %0d: UART Transmission", test_count);
        
        // Wait for transmission to complete
        #(BAUD_PERIOD * 12 * 4); // 4 characters * 12 bits each
        
        // Check TX FIFO empty status
        apb_read(8'h04, stat_val);
        if (stat_val & 32'h08) begin // TX_EMPTY should be 1
            $display("PASS: TX FIFO empty after transmission");
            pass_count++;
        end else begin
            $display("FAIL: TX FIFO not empty after transmission");
            fail_count++;
        end
        
        // Test 5: Interrupt testing
        test_count++;
        $display("\nTest %0d: Interrupt Testing", test_count);
        
        // Enable TX empty interrupt
        apb_write(8'h18, 32'h01);
        
        // Check interrupt status
        logic [31:0] int_val;
        apb_read(8'h18, int_val);
        if (int_val & 32'h04) begin // TX_EMPTY_PEND should be 1
            $display("PASS: TX empty interrupt pending");
            pass_count++;
        end else begin
            $display("FAIL: TX empty interrupt not pending");
            fail_count++;
        end
        
        if (irq_tx_empty_o) begin
            $display("PASS: TX empty interrupt asserted");
            pass_count++;
        end else begin
            $display("FAIL: TX empty interrupt not asserted");
            fail_count++;
        end
        
        // Test 6: Error condition testing
        test_count++;
        $display("\nTest %0d: Error Condition Testing", test_count);
        
        // Write to invalid address
        apb_write(8'hFF, 32'h12345678);
        if (pslverr_o) begin
            $display("PASS: Slave error on invalid address");
            pass_count++;
        end else begin
            $display("FAIL: No slave error on invalid address");
            fail_count++;
        end
        
        // Test 7: FIFO overflow protection
        test_count++;
        $display("\nTest %0d: FIFO Overflow Protection", test_count);
        
        // Fill TX FIFO
        for (int i = 0; i < FIFO_DEPTH + 2; i++) begin
            apb_write(8'h08, 32'h30 + i);
        end
        
        // Check if FIFO full is asserted
        apb_read(8'h04, stat_val);
        if (stat_val & 32'h04) begin // TX_FULL should be 1
            $display("PASS: TX FIFO full protection working");
            pass_count++;
        end else begin
            $display("FAIL: TX FIFO full protection not working");
            fail_count++;
        end
        
        // Test summary
        $display("\n=== Test Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        
        // End simulation
        #(CLOCK_PERIOD * 100);
        $finish;
    end
    
    // Monitor for UART transmission
    initial begin
        forever begin
            @(posedge uart_tx_o);
            if (uart_tx_o == 0) begin // Start bit detected
                uart_receive(received_data[received_data.size()]);
                $display("Received: 0x%02h", received_data[received_data.size()-1]);
            end
        end
    end
    
    // Coverage collection
    covergroup uart_cg @(posedge pclk_i);
        ctrl_enable: coverpoint dut.ctrl_enable;
        ctrl_tx_enable: coverpoint dut.ctrl_tx_enable;
        ctrl_rx_enable: coverpoint dut.ctrl_rx_enable;
        tx_fifo_full: coverpoint dut.tx_fifo_full;
        tx_fifo_empty: coverpoint dut.tx_fifo_empty;
        rx_fifo_full: coverpoint dut.rx_fifo_full;
        rx_fifo_empty: coverpoint dut.rx_fifo_empty;
        irq_tx_empty: coverpoint irq_tx_empty_o;
        irq_rx_full: coverpoint irq_rx_full_o;
    endgroup
    
    uart_cg uart_cov = new();

endmodule 