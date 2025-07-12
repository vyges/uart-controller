#=============================================================================
# Makefile for UART Controller Cocotb Simulation
#=============================================================================
# Description: Makefile for running cocotb testbenches for the UART controller IP
#              with support for multiple simulators (Icarus, Verilator, etc.)
#
# Author: shivaram@vyges.com
# License: Apache-2.0
#=============================================================================

# Cocotb configuration
TOPLEVEL = uart_controller
TOPLEVEL_LANG = systemverilog
MODULE = test_uart_controller

# RTL files
VERILOG_SOURCES = ../../rtl/uart_controller.sv \
                  ../../rtl/sync_fifo.sv \
                  ../../rtl/uart_transmitter.sv \
                  ../../rtl/uart_receiver.sv

# Python test file
MODULE = test_uart_controller

# Simulator configuration (default to icarus)
SIM ?= icarus

# Cocotb configuration
COCOTB_REDUCED_LOG_FMT = 1
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

# Include cocotb makefiles
include $(shell cocotb-config --makefiles)/Makefile.sim

# Additional targets
.PHONY: help clean-all

# Help target
help:
	@echo "Cocotb Simulation Makefile for UART Controller"
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Run simulation with default simulator ($(SIM))"
	@echo "  icarus           - Run simulation with Icarus Verilog"
	@echo "  verilator        - Run simulation with Verilator"
	@echo "  modelsim         - Run simulation with ModelSim"
	@echo "  vcs              - Run simulation with VCS"
	@echo "  xcelium          - Run simulation with Xcelium"
	@echo "  clean            - Clean simulation files"
	@echo "  clean-all        - Clean all files including sim_build"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  SIM              - Simulator to use (default: $(SIM))"
	@echo "  TOPLEVEL         - Top-level module name (default: $(TOPLEVEL))"
	@echo "  MODULE           - Python test module (default: $(MODULE))"
	@echo ""
	@echo "Example usage:"
	@echo "  make SIM=icarus"
	@echo "  make SIM=verilator"
	@echo "  make clean"

# Clean all files including sim_build
clean-all: clean
	rm -rf sim_build
	rm -rf __pycache__
	rm -rf *.pyc
	rm -rf .pytest_cache
	rm -rf results.xml
	rm -rf dump.vcd
	rm -rf dump.fst
	rm -rf dump.ghw
	rm -rf *.log 