[![Vyges IP Template](https://img.shields.io/badge/template-vyges--ip--template-blue)](https://github.com/vyges/vyges-ip-template)
[![Use this template](https://img.shields.io/badge/Use%20this%20template-vyges--ip--template-brightgreen?style=for-the-badge)](https://github.com/vyges/vyges-ip-template/generate)
![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)
![Build](https://github.com/vyges/vyges-ip-template/actions/workflows/test.yml/badge.svg)

# UART Controller IP

A configurable UART controller with APB interface, FIFO support, and interrupt capabilities for embedded systems.

## Overview

The UART Controller IP provides a complete serial communication solution with the following features:

- **APB Slave Interface**: Standard APB3 protocol for register access
- **Configurable Baud Rate**: 9600 to 921600 bps
- **FIFO Support**: TX/RX FIFOs with configurable depth (4-64 entries)
- **Interrupt Support**: TX empty and RX full interrupt generation
- **Error Detection**: Parity, framing, and overrun error detection
- **Power Management**: Clock gating and sleep mode support
- **ASIC Ready**: Designed for SkyWater 130nm Open Source PDK

## Pinout

| Name             | Function    | Direction | Description                         |
|------------------|-------------|-----------|-------------------------------------|
| PCLK_i           | clock       | input     | APB clock input (50 MHz)            |
| PRESETn_i        | reset       | input     | APB reset input (active low)        |
| PSEL_i           | control     | input     | APB select input                    |
| PENABLE_i        | control     | input     | APB enable input                    |
| PWRITE_i         | control     | input     | APB write input                     |
| PADDR_i[7:0]     | data        | input     | APB address input (8-bit)           |
| PWDATA_i[31:0]   | data        | input     | APB write data input (32-bit)       |
| PRDATA_o[31:0]   | data        | output    | APB read data output (32-bit)       |
| PREADY_o         | status      | output    | APB ready output                    |
| PSLVERR_o        | status      | output    | APB slave error output              |
| UART_TX_o        | data        | output    | UART transmit output                |
| UART_RX_i        | data        | input     | UART receive input                  |
| IRQ_TX_EMPTY_o   | interrupt   | output    | Transmit FIFO empty interrupt       |
| IRQ_RX_FULL_o    | interrupt   | output    | Receive FIFO full interrupt         |

## Register Map

| Address | Name   | Access | Description                    |
|---------|--------|--------|--------------------------------|
| 0x00    | CTRL   | R/W    | Control Register               |
| 0x04    | STAT   | R      | Status Register                |
| 0x08    | TXDATA | W      | TX Data Register               |
| 0x0C    | RXDATA | R      | RX Data Register               |
| 0x10    | BAUD   | R/W    | Baud Rate Configuration        |
| 0x14    | FIFO   | R/W    | FIFO Configuration             |
| 0x18    | INT    | R/W    | Interrupt Configuration        |

### Control Register (CTRL)
- Bit 0: Enable
- Bit 1: TX Enable
- Bit 2: RX Enable
- Bit 3: Parity Enable
- Bit 4: Parity Type (0=Even, 1=Odd)

### Status Register (STAT)
- Bit 0: TX Busy
- Bit 1: RX Busy
- Bit 2: TX FIFO Full
- Bit 3: RX FIFO Empty
- Bit 4: Parity Error
- Bit 5: Frame Error
- Bit 6: Overrun Error

### Interrupt Register (INT)
- Bit 0: TX Empty Interrupt Enable
- Bit 1: RX Full Interrupt Enable
- Bit 2: TX Empty Interrupt Pending
- Bit 3: RX Full Interrupt Pending

## Parameters

| Parameter        | Default | Range | Description                    |
|------------------|---------|-------|--------------------------------|
| CLOCK_FREQUENCY  | 50MHz   | 1-100MHz | System clock frequency        |
| BAUD_RATE        | 115200  | 9600-921600 | UART baud rate               |
| FIFO_DEPTH       | 16      | 4-64  | FIFO depth for TX/RX          |
| DATA_WIDTH       | 8       | 5-8   | UART data width               |
| STOP_BITS        | 1       | 1-2   | Number of stop bits           |
| PARITY_ENABLE    | false   | bool  | Enable parity checking        |
| PARITY_TYPE      | "even"  | enum  | Parity type (even/odd/none)   |

## Usage Example

```systemverilog
// Instantiate UART controller
uart_controller #(
    .CLOCK_FREQUENCY(50_000_000),
    .BAUD_RATE(115_200),
    .FIFO_DEPTH(16),
    .DATA_WIDTH(8),
    .STOP_BITS(1),
    .PARITY_ENABLE(1'b0),
    .PARITY_TYPE("even")
) uart_inst (
    .pclk_i(pclk),
    .presetn_i(presetn),
    .psel_i(psel),
    .penable_i(penable),
    .pwrite_i(pwrite),
    .paddr_i(paddr),
    .pwdata_i(pwdata),
    .prdata_o(prdata),
    .pready_o(pready),
    .pslverr_o(pslverr),
    .uart_tx_o(uart_tx),
    .uart_rx_i(uart_rx),
    .irq_tx_empty_o(irq_tx_empty),
    .irq_rx_full_o(irq_rx_full)
);
```

## Testing

### Simulation Framework

The project includes comprehensive simulation support with multiple testbench types and simulators:

#### SystemVerilog Testbench
```bash
cd sim
make verilator    # SystemVerilog with Verilator
make icarus       # SystemVerilog with Icarus Verilog
```

#### Cocotb Testbench
```bash
cd sim
make cocotb              # Cocotb with default simulator (Icarus)
make cocotb-verilator    # Cocotb with Verilator
make cocotb-icarus       # Cocotb with Icarus Verilog
```

#### Run All Tests
```bash
cd sim
make test-all            # Run all simulation types
```

### Test Coverage

- **Functional Coverage**: 95% minimum target
- **Code Coverage**: 90% minimum target  
- **Toggle Coverage**: 100% for all data signals
- **FSM Coverage**: 100% state and transition coverage

## Physical Design

### OpenLane Flow (Sky130B PDK)

The IP is designed for synthesis with OpenLane targeting SkyWater 130nm Open Source PDK:

```bash
# From flow/openlane/ directory
make sky130b              # Run with Sky130B PDK (default)
make sky130a              # Run with Sky130A PDK
make help                 # Show all options
make final                # Collect final results
```

### Physical Design Files

- **Configuration**: `flow/openlane/config_sky130b.json`
- **Timing Constraints**: `flow/openlane/constraints_sky130b.sdc`
- **Pin Order**: `flow/openlane/pin_order_sky130b.cfg`
- **Floorplan**: `flow/openlane/floorplan_sky130b.tcl`

### ASIC Specifications

- **Technology**: SkyWater 130nm Open Source PDK (SKY130)
- **Platform**: sky130bhd (high-density standard cells)
- **Die Area**: 1mm x 1mm (1000x1000 microns)
- **Core Utilization**: 80%
- **Supply Voltage**: 1.8V nominal
- **Metal Layers**: 5 layers (li1, met1-met5)

## Performance

- **Maximum Frequency**: 50 MHz
- **Area**: < 0.1mm² (target)
- **Power**: < 5mW dynamic, < 1μW leakage at 50MHz, 1.8V
- **Latency**: < 10 clock cycles for APB access
- **Throughput**: Full baud rate support (9600-921600 bps)
- **Process Corners**: TT, FF, SS, FS, SF

## Project Structure

```
uart-controller/
├── rtl/                    # RTL implementation
│   ├── uart_controller.sv  # Main UART controller
│   ├── sync_fifo.sv        # Synchronous FIFO
│   ├── uart_transmitter.sv # UART transmitter
│   └── uart_receiver.sv    # UART receiver
├── tb/                     # Testbenches
│   ├── tb_uart_controller.sv           # SystemVerilog testbench
│   ├── verilator/          # Verilator-compatible testbench
│   └── cocotb/             # Python testbench
├── sim/                    # Simulation framework
│   ├── Makefile            # Main simulation makefile
│   ├── verilator/          # Verilator simulation files
│   └── cocotb/             # Cocotb simulation setup
├── flow/                   # Physical design flow
│   └── openlane/           # OpenLane configuration
├── docs/                   # Documentation
│   ├── overview.md         # Technical overview
│   ├── architecture.md     # Architecture documentation
│   └── UART_design_spec.md # Design specification
├── integration/            # Integration examples
└── vyges-metadata.json     # Vyges catalog metadata
```

## Documentation

- **[Technical Overview](docs/overview.md)** - Comprehensive technical specification
- **[Architecture Guide](docs/architecture.md)** - Detailed architecture documentation
- **[Design Specification](docs/UART_design_spec.md)** - Complete design requirements
- **[OpenLane Configuration](flow/openlane/configuration.md)** - Physical design flow guide

## License

Apache-2.0 License - see [LICENSE](LICENSE) file for details.

**Important**: The Apache-2.0 license applies to the **hardware IP content** (RTL, documentation, testbenches, etc.) that you create using this template. The template structure, build processes, tooling workflows, and AI context/processing engine are provided as-is for your use but are not themselves licensed under Apache-2.0.

For detailed licensing information, see [LICENSE_SCOPE.md](LICENSE_SCOPE.md).

## Author

Shivaram <shivaram@vyges.com>

## Repository

https://github.com/vyges/uart-controller

## Vyges IP Catalog

This IP is part of the Vyges IP catalog. For more information about Vyges IP development conventions and tools, visit:

- [Vyges IP Template](https://github.com/vyges/vyges-ip-template)
- [Vyges CLI](https://vyges.com/tools/)
- [Vyges Documentation](https://vyges.com/docs)
