#=============================================================================
# Makefile for UART Controller Simulation
#=============================================================================
# Description: Makefile for running SystemVerilog and cocotb testbenches
#              for the UART controller IP with multiple simulator support.
#
# Author: shivaram@vyges.com
# License: Apache-2.0
#=============================================================================

# Configuration
TOPLEVEL = uart_controller
TOPLEVEL_LANG = verilog
MODULE = test_uart_controller

# RTL files
RTL_FILES = ../rtl/uart_controller.sv \
            ../rtl/sync_fifo.sv \
            ../rtl/uart_transmitter.sv \
            ../rtl/uart_receiver.sv

# Testbench files
TB_FILES = ../tb/tb_uart_controller.sv
VERILATOR_TB_FILES = ../tb/verilator/tb_uart_controller_verilator.sv

# Simulator configuration
SIM = verilator
VERILOG_SOURCES = $(RTL_FILES)
TOPLEVEL = uart_controller
TOPLEVEL_LANG = systemverilog

# Cocotb configuration
COCOTB_REDUCED_LOG_FMT = 1
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

# Default target
all: help

# SystemVerilog simulation with Verilator
verilator: $(RTL_FILES) $(VERILATOR_TB_FILES)
	@echo "Running SystemVerilog simulation with Verilator..."
	verilator --cc --exe --build -j 0 \
		--top-module tb_uart_controller_verilator \
		$(RTL_FILES) $(VERILATOR_TB_FILES) \
		--trace --trace-structs \
		--exe verilator/sim_main.cpp
	./obj_dir/Vtb_uart_controller_verilator

# SystemVerilog simulation with Icarus Verilog
icarus: $(RTL_FILES) $(TB_FILES)
	@echo "Running SystemVerilog simulation with Icarus Verilog..."
	iverilog -g2012 -o simv $(RTL_FILES) $(TB_FILES)
	vvp simv

# Cocotb simulation
cocotb: $(RTL_FILES)
	@echo "Running cocotb simulation..."
	cd cocotb && make

# Cocotb with Icarus Verilog
cocotb-icarus: $(RTL_FILES)
	@echo "Running cocotb simulation with Icarus Verilog..."
	cd cocotb && make SIM=icarus

# Cocotb with Verilator
cocotb-verilator: $(RTL_FILES)
	@echo "Running cocotb simulation with Verilator..."
	cd cocotb && make SIM=verilator

# Run all simulations
test-all: verilator icarus cocotb
	@echo "All simulations completed!"

# Coverage analysis
coverage:
	@echo "Generating coverage report..."
	# Add coverage analysis commands here

# Waveform viewing
waves:
	@echo "Opening waveform viewer..."
	gtkwave uart_controller.vcd &

# Clean
clean:
	@echo "Cleaning build files..."
	rm -rf obj_dir
	rm -rf __pycache__
	rm -rf results.xml
	rm -rf dump.vcd
	rm -rf dump.fst
	rm -rf dump.ghw
	rm -rf sim_build
	rm -rf *.pyc
	rm -rf .pytest_cache
	rm -rf simv
	rm -rf *.log
	rm -rf uart_controller.vcd

# Help
help:
	@echo "Available targets:"
	@echo "  verilator      - Run SystemVerilog simulation with Verilator"
	@echo "  icarus         - Run SystemVerilog simulation with Icarus Verilog"
	@echo "  cocotb         - Run cocotb simulation with default simulator"
	@echo "  cocotb-icarus  - Run cocotb simulation with Icarus Verilog"
	@echo "  cocotb-verilator - Run cocotb simulation with Verilator"
	@echo "  test-all       - Run all simulation types"
	@echo "  coverage       - Generate coverage report"
	@echo "  waves          - Open waveform viewer"
	@echo "  clean          - Clean build files"
	@echo "  help           - Show this help message"
	@echo ""
	@echo "Simulation files:"
	@echo "  RTL: $(RTL_FILES)"
	@echo "  TB: $(TB_FILES)"
	@echo "  Verilator TB: $(VERILATOR_TB_FILES)"
	@echo ""
	@echo "Simulation directories:"
	@echo "  sim/verilator/ - Verilator simulation files"
	@echo "  sim/cocotb/    - Cocotb simulation files"
	@echo "  tb/cocotb/     - Cocotb testbench files"

.PHONY: all verilator icarus cocotb cocotb-icarus cocotb-verilator test-all coverage waves clean help

