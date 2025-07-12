# Cocotb Simulation for UART Controller

This directory contains the cocotb simulation setup for the UART Controller IP.

## Overview

Cocotb (Coroutine-based Co-simulation TestBench) is a Python library that allows you to write testbenches in Python for hardware designs. This provides a more flexible and powerful verification environment compared to traditional SystemVerilog testbenches.

## Directory Structure

```
sim/cocotb/
├── Makefile          # Cocotb simulation makefile
├── README.md         # This file
└── .gitkeep          # Keep directory in git
```

## Testbench Location

The actual Python testbench is located in `tb/cocotb/test_uart_controller.py` and is referenced by this simulation setup.

## Usage

### Prerequisites

1. Install cocotb:
   ```bash
   pip install cocotb
   ```

2. Install a supported simulator (Icarus Verilog recommended for open-source):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install iverilog
   
   # macOS
   brew install icarus-verilog
   ```

### Running Simulations

From the `sim/cocotb/` directory:

```bash
# Run with default simulator (Icarus)
make

# Run with specific simulator
make SIM=icarus
make SIM=verilator
make SIM=modelsim
make SIM=vcs
make SIM=xcelium

# Show help
make help

# Clean simulation files
make clean
make clean-all
```

### Supported Simulators

- **Icarus Verilog** (recommended for open-source)
- **Verilator** (fast simulation)
- **ModelSim** (commercial)
- **VCS** (commercial)
- **Xcelium** (commercial)

## Configuration

The simulation is configured through the Makefile with the following key variables:

- `TOPLEVEL`: The top-level module name (`uart_controller`)
- `TOPLEVEL_LANG`: The language of the top-level module (`systemverilog`)
- `MODULE`: The Python test module name (`test_uart_controller`)
- `VERILOG_SOURCES`: List of RTL files to compile
- `SIM`: The simulator to use (default: `icarus`)

## Test Coverage

The cocotb testbench provides comprehensive coverage including:

- Basic UART transmission and reception
- FIFO operations (full/empty conditions)
- Interrupt generation and handling
- Error conditions (parity, framing, overrun)
- APB interface compliance
- Performance testing
- Power management features

## Waveform Generation

Waveforms are automatically generated during simulation and can be viewed with:

```bash
# For VCD files
gtkwave dump.vcd

# For FST files (Verilator)
gtkwave dump.fst

# For GHW files (GHDL)
gtkwave dump.ghw
```

## Integration with Main Simulation

This cocotb simulation is integrated with the main simulation framework in `sim/Makefile` through the `cocotb` targets.

## Troubleshooting

### Common Issues

1. **Simulator not found**: Ensure the simulator is installed and in your PATH
2. **Python module not found**: Ensure cocotb is installed: `pip install cocotb`
3. **RTL compilation errors**: Check that all RTL files exist and are syntactically correct
4. **Permission errors**: Ensure write permissions in the simulation directory

### Debug Mode

For debugging, you can enable verbose output:

```bash
COCOTB_LOG_LEVEL=DEBUG make
```

## References

- [Cocotb Documentation](https://docs.cocotb.org/)
- [Cocotb GitHub Repository](https://github.com/cocotb/cocotb)
- [Icarus Verilog Documentation](http://iverilog.icarus.com/) 