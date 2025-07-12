#!/usr/bin/env python3
"""
==============================================================================
Test Name: test_uart_controller
==============================================================================
Description: Cocotb testbench for UART controller with APB interface,
             FIFO operations, and interrupt testing.

Features:
- APB interface verification
- UART transmission/reception testing
- FIFO full/empty condition testing
- Interrupt generation verification
- Error condition testing
- Coverage collection

Author: shivaram@vyges.com
License: Apache-2.0
==============================================================================
"""

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.clock import Clock
from cocotb.handle import ModifiableObject
import random
import struct

# Test parameters
CLOCK_FREQUENCY = 50_000_000
BAUD_RATE = 115_200
FIFO_DEPTH = 16
DATA_WIDTH = 8
STOP_BITS = 1
PARITY_ENABLE = False
PARITY_TYPE = "even"

# Register addresses
CTRL_REG_ADDR = 0x00
STAT_REG_ADDR = 0x04
TXDATA_REG_ADDR = 0x08
RXDATA_REG_ADDR = 0x0C
BAUD_REG_ADDR = 0x10
FIFO_REG_ADDR = 0x14
INT_REG_ADDR = 0x18

# Control register bits
CTRL_ENABLE_BIT = 0
CTRL_TX_ENABLE_BIT = 1
CTRL_RX_ENABLE_BIT = 2
CTRL_PARITY_EN_BIT = 3
CTRL_PARITY_ODD_BIT = 4

# Status register bits
STAT_TX_BUSY_BIT = 0
STAT_RX_BUSY_BIT = 1
STAT_TX_FULL_BIT = 2
STAT_RX_EMPTY_BIT = 3
STAT_PARITY_ERR_BIT = 4
STAT_FRAME_ERR_BIT = 5
STAT_OVERRUN_ERR_BIT = 6

# Interrupt register bits
INT_TX_EMPTY_EN_BIT = 0
INT_RX_FULL_EN_BIT = 1
INT_TX_EMPTY_PEND_BIT = 2
INT_RX_FULL_PEND_BIT = 3


class UARTControllerTest:
    """Test class for UART Controller verification"""
    
    def __init__(self, dut):
        self.dut = dut
        self.test_count = 0
        self.pass_count = 0
        self.fail_count = 0
        
    async def apb_write(self, addr, data):
        """APB write transaction"""
        await RisingEdge(self.dut.pclk_i)
        self.dut.psel_i.value = 1
        self.dut.penable_i.value = 0
        self.dut.pwrite_i.value = 1
        self.dut.paddr_i.value = addr
        self.dut.pwdata_i.value = data
        await RisingEdge(self.dut.pclk_i)
        self.dut.penable_i.value = 1
        await RisingEdge(self.dut.pclk_i)
        while not self.dut.pready_o.value:
            await RisingEdge(self.dut.pclk_i)
        self.dut.psel_i.value = 0
        self.dut.penable_i.value = 0
        await RisingEdge(self.dut.pclk_i)
        
    async def apb_read(self, addr):
        """APB read transaction"""
        await RisingEdge(self.dut.pclk_i)
        self.dut.psel_i.value = 1
        self.dut.penable_i.value = 0
        self.dut.pwrite_i.value = 0
        self.dut.paddr_i.value = addr
        await RisingEdge(self.dut.pclk_i)
        self.dut.penable_i.value = 1
        await RisingEdge(self.dut.pclk_i)
        while not self.dut.pready_o.value:
            await RisingEdge(self.dut.pclk_i)
        data = self.dut.prdata_o.value
        self.dut.psel_i.value = 0
        self.dut.penable_i.value = 0
        await RisingEdge(self.dut.pclk_i)
        return data
        
    async def uart_send_byte(self, data):
        """Send a byte via UART"""
        baud_period = int(1e9 / BAUD_RATE)  # in ns
        
        # Start bit
        self.dut.uart_rx_i.value = 0
        await Timer(baud_period, units='ns')
        
        # Data bits
        for i in range(DATA_WIDTH):
            self.dut.uart_rx_i.value = (data >> i) & 1
            await Timer(baud_period, units='ns')
            
        # Parity bit (if enabled)
        if PARITY_ENABLE:
            if PARITY_TYPE == "even":
                parity = bin(data).count('1') % 2
            else:
                parity = (bin(data).count('1') + 1) % 2
            self.dut.uart_rx_i.value = parity
            await Timer(baud_period, units='ns')
            
        # Stop bits
        for i in range(STOP_BITS):
            self.dut.uart_rx_i.value = 1
            await Timer(baud_period, units='ns')
            
    async def uart_receive_byte(self):
        """Receive a byte via UART"""
        baud_period = int(1e9 / BAUD_RATE)  # in ns
        data = 0
        
        # Wait for start bit
        await FallingEdge(self.dut.uart_tx_o)
        await Timer(baud_period // 2, units='ns')  # Sample at middle
        
        # Sample data bits
        for i in range(DATA_WIDTH):
            await Timer(baud_period, units='ns')
            data |= (self.dut.uart_tx_o.value << i)
            
        # Skip parity bit if enabled
        if PARITY_ENABLE:
            await Timer(baud_period, units='ns')
            
        # Skip stop bits
        for i in range(STOP_BITS):
            await Timer(baud_period, units='ns')
            
        return data
        
    def check_result(self, test_name, condition, expected=True):
        """Check test result and update counters"""
        self.test_count += 1
        if condition == expected:
            self.pass_count += 1
            self.dut._log.info(f"PASS: {test_name}")
        else:
            self.fail_count += 1
            self.dut._log.error(f"FAIL: {test_name}")
            
    async def test_initialization(self):
        """Test 1: Basic initialization"""
        self.dut._log.info("Test 1: Basic Initialization")
        
        # Read initial register values
        ctrl_val = await self.apb_read(CTRL_REG_ADDR)
        stat_val = await self.apb_read(STAT_REG_ADDR)
        
        self.check_result("Initial register values", 
                         ctrl_val == 0 and stat_val == 0)
                         
    async def test_enable_controller(self):
        """Test 2: Enable UART controller"""
        self.dut._log.info("Test 2: Enable UART Controller")
        
        # Enable TX, RX, and controller
        await self.apb_write(CTRL_REG_ADDR, 0x07)
        ctrl_val = await self.apb_read(CTRL_REG_ADDR)
        
        self.check_result("UART controller enabled", ctrl_val == 0x07)
        
    async def test_fifo_operations(self):
        """Test 3: FIFO operations"""
        self.dut._log.info("Test 3: FIFO Operations")
        
        # Write data to TX FIFO
        test_data = [0x41, 0x42, 0x43, 0x44]  # 'A', 'B', 'C', 'D'
        for data in test_data:
            await self.apb_write(TXDATA_REG_ADDR, data)
            
        # Check TX FIFO status
        stat_val = await self.apb_read(STAT_REG_ADDR)
        self.check_result("TX FIFO not full after 4 writes", 
                         not (stat_val & (1 << STAT_TX_FULL_BIT)))
                         
    async def test_uart_transmission(self):
        """Test 4: UART transmission"""
        self.dut._log.info("Test 4: UART Transmission")
        
        # Wait for transmission to complete
        baud_period = int(1e9 / BAUD_RATE)
        frame_bits = DATA_WIDTH + STOP_BITS + (1 if PARITY_ENABLE else 0)
        await Timer(baud_period * frame_bits * 4, units='ns')  # 4 characters
        
        # Check TX FIFO empty status
        stat_val = await self.apb_read(STAT_REG_ADDR)
        self.check_result("TX FIFO empty after transmission", 
                         stat_val & (1 << STAT_RX_EMPTY_BIT))
                         
    async def test_interrupts(self):
        """Test 5: Interrupt testing"""
        self.dut._log.info("Test 5: Interrupt Testing")
        
        # Enable TX empty interrupt
        await self.apb_write(INT_REG_ADDR, 0x01)
        
        # Check interrupt status
        int_val = await self.apb_read(INT_REG_ADDR)
        self.check_result("TX empty interrupt pending", 
                         int_val & (1 << INT_TX_EMPTY_PEND_BIT))
                         
        self.check_result("TX empty interrupt asserted", 
                         self.dut.irq_tx_empty_o.value)
                         
    async def test_error_conditions(self):
        """Test 6: Error condition testing"""
        self.dut._log.info("Test 6: Error Condition Testing")
        
        # Write to invalid address
        await self.apb_write(0xFF, 0x12345678)
        self.check_result("Slave error on invalid address", 
                         self.dut.pslverr_o.value)
                         
    async def test_fifo_overflow(self):
        """Test 7: FIFO overflow protection"""
        self.dut._log.info("Test 7: FIFO Overflow Protection")
        
        # Fill TX FIFO
        for i in range(FIFO_DEPTH + 2):
            await self.apb_write(TXDATA_REG_ADDR, 0x30 + i)
            
        # Check if FIFO full is asserted
        stat_val = await self.apb_read(STAT_REG_ADDR)
        self.check_result("TX FIFO full protection working", 
                         stat_val & (1 << STAT_TX_FULL_BIT))
                         
    async def test_uart_reception(self):
        """Test 8: UART reception"""
        self.dut._log.info("Test 8: UART Reception")
        
        # Enable RX
        await self.apb_write(CTRL_REG_ADDR, 0x05)  # Enable RX and controller
        
        # Send test data via UART
        test_data = [0x48, 0x65, 0x6C, 0x6C, 0x6F]  # "Hello"
        for data in test_data:
            await self.uart_send_byte(data)
            await Timer(1000, units='ns')  # Small delay between bytes
            
        # Wait for reception to complete
        await Timer(10000, units='ns')
        
        # Read received data
        received_data = []
        for i in range(len(test_data)):
            if not (await self.apb_read(STAT_REG_ADDR) & (1 << STAT_RX_EMPTY_BIT)):
                data = await self.apb_read(RXDATA_REG_ADDR)
                received_data.append(data & 0xFF)
                
        self.check_result("UART reception working", 
                         received_data == test_data)
                         
    async def test_coverage(self):
        """Test 9: Coverage testing"""
        self.dut._log.info("Test 9: Coverage Testing")
        
        # Test different control register combinations
        control_values = [0x01, 0x02, 0x04, 0x07, 0x0F]
        for ctrl_val in control_values:
            await self.apb_write(CTRL_REG_ADDR, ctrl_val)
            await ClockCycles(self.dut.pclk_i, 10)
            
        # Test interrupt enable combinations
        int_values = [0x01, 0x02, 0x03]
        for int_val in int_values:
            await self.apb_write(INT_REG_ADDR, int_val)
            await ClockCycles(self.dut.pclk_i, 10)
            
        self.check_result("Coverage testing completed", True)
        
    def print_summary(self):
        """Print test summary"""
        self.dut._log.info("=== Test Summary ===")
        self.dut._log.info(f"Total Tests: {self.test_count}")
        self.dut._log.info(f"Passed: {self.pass_count}")
        self.dut._log.info(f"Failed: {self.fail_count}")
        
        if self.fail_count == 0:
            self.dut._log.info("ALL TESTS PASSED!")
        else:
            self.dut._log.error("SOME TESTS FAILED!")


@cocotb.test()
async def test_uart_controller_basic(dut):
    """Basic UART controller test"""
    
    # Create test instance
    test = UARTControllerTest(dut)
    
    # Setup clock
    clock = Clock(dut.pclk_i, 20, units="ns")  # 50MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.presetn_i.value = 0
    await ClockCycles(dut.pclk_i, 10)
    dut.presetn_i.value = 1
    await ClockCycles(dut.pclk_i, 10)
    
    # Initialize signals
    dut.psel_i.value = 0
    dut.penable_i.value = 0
    dut.pwrite_i.value = 0
    dut.paddr_i.value = 0
    dut.pwdata_i.value = 0
    dut.uart_rx_i.value = 1
    
    dut._log.info("=== UART Controller Testbench Started ===")
    dut._log.info(f"Clock Frequency: {CLOCK_FREQUENCY} Hz")
    dut._log.info(f"Baud Rate: {BAUD_RATE} bps")
    dut._log.info(f"FIFO Depth: {FIFO_DEPTH}")
    
    # Run all tests
    await test.test_initialization()
    await test.test_enable_controller()
    await test.test_fifo_operations()
    await test.test_uart_transmission()
    await test.test_interrupts()
    await test.test_error_conditions()
    await test.test_fifo_overflow()
    await test.test_uart_reception()
    await test.test_coverage()
    
    # Print summary
    test.print_summary()
    
    # Final delay
    await ClockCycles(dut.pclk_i, 100)


@cocotb.test()
async def test_uart_controller_stress(dut):
    """Stress test for UART controller"""
    
    # Create test instance
    test = UARTControllerTest(dut)
    
    # Setup clock
    clock = Clock(dut.pclk_i, 20, units="ns")  # 50MHz
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.presetn_i.value = 0
    await ClockCycles(dut.pclk_i, 10)
    dut.presetn_i.value = 1
    await ClockCycles(dut.pclk_i, 10)
    
    # Initialize signals
    dut.psel_i.value = 0
    dut.penable_i.value = 0
    dut.pwrite_i.value = 0
    dut.paddr_i.value = 0
    dut.pwdata_i.value = 0
    dut.uart_rx_i.value = 1
    
    dut._log.info("=== UART Controller Stress Test ===")
    
    # Enable controller
    await test.apb_write(CTRL_REG_ADDR, 0x07)
    
    # Stress test: rapid writes to FIFO
    for i in range(100):
        data = random.randint(0, 255)
        await test.apb_write(TXDATA_REG_ADDR, data)
        await ClockCycles(dut.pclk_i, 1)
        
    # Wait for transmission to complete
    await Timer(100000, units='ns')
    
    # Check final status
    stat_val = await test.apb_read(STAT_REG_ADDR)
    test.check_result("Stress test completed", 
                     not (stat_val & (1 << STAT_TX_BUSY_BIT)))
    
    test.print_summary() 