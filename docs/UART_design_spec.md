# UART Design Specification

## Project Metadata

- Repository name/organization: https://github.com/vyges/uart-controller
- Author/maintainer information: shivaram@vyges.com
- License choice (MIT, Apache-2.0, etc.) - Apache-2.0 with attribution
- Version numbering scheme - 1.0.0
- Target platforms (ASIC only, or FPGA too?) - ASIC on Sky130

## Implementation Specifications

### RTL Coding Standards
- **Naming Convention**: snake_case for signals, UPPER_CASE for parameters
- **Module Header**: Vyges standard header with description, author, license
- **Code Style**: SystemVerilog with strict linting compliance
- **Comments**: Comprehensive inline documentation for all major blocks
- **Port Order**: Clock, reset, APB interface, UART interface, interrupts

### FIFO Implementation Details
- **Type**: Synchronous FIFO with configurable depth (default 16)
- **Clock Domain**: Single clock domain (PCLK)
- **Reset**: Asynchronous reset (PRESETn)
- **Full/Empty Detection**: Combinational logic for immediate status
- **Overflow Protection**: Hardware protection against FIFO overflow

### Error Handling & Recovery
- **Parity Errors**: Configurable parity checking with error flag
- **Framing Errors**: Start/stop bit validation with error reporting
- **Overrun Errors**: RX FIFO overflow detection and reporting
- **Timeout Errors**: Configurable timeout for incomplete transmissions
- **Recovery**: Automatic recovery with error status clearing

### Power Management
- **Clock Gating**: Automatic clock gating when UART is idle
- **Power Domains**: Single power domain (VDD)
- **Sleep Mode**: Configurable sleep mode with wake-up on RX activity
- **Dynamic Frequency**: Support for dynamic clock frequency changes

## Synthesis & Physical Design Constraints

### PDK and Flow Requirements
- **PDK**: SkyWater 130nm Open Source PDK (SKY130 process node)
- **OpenLane Platform**: Use `sky130bhd` (high-density) or `sky130b` as the platform in OpenLane config files
- **PDK Selection**: All flow scripts and Makefiles must allow explicit selection of the SkyWater PDK (e.g., `PDK := sky130B`)
- **PDK Versioning**: Document the exact PDK version used for reproducibility
- **PDK Source**: The SkyWater PDK is available at [github.com/google/skywater-pdk](https://github.com/google/skywater-pdk)

### Physical Design Files - Responsibilities

#### **Designer/Project Team Provides:**
- **OpenLane config**: `flow/openlane/config_sky130b.json` - Project-specific configuration
- **SDC constraints**: `flow/openlane/constraints_sky130b.sdc` - Design-specific timing constraints
- **Pin order**: `flow/openlane/pin_order_sky130b.cfg` - I/O pin placement order
- **Floorplan**: `flow/openlane/floorplan_sky130b.tcl` - Custom floorplan if needed
- **Documentation**: Update `flow/openlane/configuration.md` - Project-specific flow documentation

#### **PDK Vendor Provides (via SkyWater PDK Repository):**
- **Standard cell libraries** - Available in PDK installation from [github.com/google/skywater-pdk](https://github.com/google/skywater-pdk)
- **I/O cell libraries** - Available in PDK installation from [github.com/google/skywater-pdk](https://github.com/google/skywater-pdk)
- **Technology files** - LEF, GDS, SPICE models
- **Design rules** - DRC, LVS rules
- **Process corners** - TT, FF, SS, FS, SF corner data
- **Documentation** - Comprehensive design rule documentation

#### **OpenLane Tool Provides:**
- **Flow scripts** - Synthesis, placement, routing, DRC/LVS
- **Default configurations** - Base configs for each platform
- **Utility scripts** - For results collection, reporting

#### **Generated During Flow:**
- **Synthesis netlists** - Generated from RTL
- **Placement results** - DEF files, placement reports
- **Routing results** - Final DEF, routing reports
- **GDS output** - Final layout
- **Timing reports** - STA results
- **Power reports** - Power analysis results

### Sky130B PDK Specific Requirements
- **Technology**: SkyWater 130nm Open Source PDK, Sky130B variant
- **Supply Voltage**: 1.8V nominal (1.62V to 1.98V range)
- **Temperature Range**: -40°C to +125°C
- **Process Corners**: TT, FF, SS, FS, SF (ensure all corners are supported in flow)
- **Platform**: Set `PLATFORM` to `sky130bhd` or `sky130b` in OpenLane config

### Timing Constraints
- **Clock Frequency**: 50 MHz maximum (20ns period)
- **Setup Time**: 2ns minimum
- **Hold Time**: 1ns minimum
- **Clock-to-Q**: 3ns maximum
- **Baud Rate Accuracy**: ±2% tolerance
- **SDC File**: Provide a complete SDC file for synthesis and place & route

### Area & Power Targets
- **Area Target**: < 0.1mm² (including I/O cells)
- **Power Target**: < 5mW at 50MHz, 1.8V
- **Leakage Power**: < 1μW in sleep mode
- **Dynamic Power**: < 4mW during active transmission

### Floorplan Requirements
- **Aspect Ratio**: 1:1 to 2:1 (width:height)
- **Pin Placement**: APB pins on left, UART pins on right, interrupts on top
- **Core Utilization**: < 80% to allow for routing
- **I/O Ring**: Standard cell I/O with ESD protection
- **Pin Order File**: Provide a pin order file for OpenLane (`pin_order_sky130b.cfg`)

### Flow Automation & Reproducibility
- **Makefile**: The OpenLane Makefile must allow PDK/platform/config selection via variables or targets
- **Config Naming**: Use clear naming for config files (e.g., `config_sky130b.json`)
- **Results**: All final GDS, DEF, and netlists must be collected in a `final/` directory
- **Documentation**: All flow steps, file locations, and PDK-specific notes must be documented in `flow/openlane/configuration.md`

### File Creation and Maintenance

#### **Must Create (Designer Responsibility):**
1. **OpenLane Configuration**: Create `config_sky130b.json` with project-specific settings
2. **Timing Constraints**: Create `constraints_sky130b.sdc` with design-specific timing
3. **Pin Order**: Create `pin_order_sky130b.cfg` with I/O pin placement
4. **Floorplan**: Create `floorplan_sky130b.tcl` if custom floorplan needed
5. **Documentation**: Update `configuration.md` with project-specific notes

#### **Can Generate (Tool/Script Responsibility):**
1. **SDC Templates**: Can generate from RTL analysis
2. **Pin Order**: Can generate from module port analysis
3. **Floorplan**: Can generate basic floorplan from pin count/area estimates
4. **Config Templates**: Can generate from design parameters

#### **Must Install/Setup (Environment Responsibility):**
1. **PDK**: Install SkyWater PDK from [github.com/google/skywater-pdk](https://github.com/google/skywater-pdk) in standard location
2. **OpenLane**: Install OpenLane toolchain with Sky130 platform support
3. **Dependencies**: Install required tools (Yosys, OpenROAD, Magic, etc.)

## Quality & Validation Requirements

### Linting & Code Quality
- **Linting Tool**: Verilator with strict mode
- **Coding Standards**: IEEE 1800-2017 SystemVerilog standard
- **Complexity Limits**: Maximum 50 lines per always block
- **Fanout Limits**: Maximum 20 fanout per signal
- **Clock Domain**: Single clock domain verification

### Coverage Requirements
- **Functional Coverage**: 95% minimum
- **Code Coverage**: 90% minimum (statements, branches, expressions)
- **Toggle Coverage**: 100% for all data signals
- **FSM Coverage**: 100% state and transition coverage
- **Interface Coverage**: 100% APB and UART protocol coverage

### Performance Requirements
- **Maximum Frequency**: 50 MHz operation
- **Latency**: < 10 clock cycles for APB read/write
- **Throughput**: Full baud rate support (up to 921600 bps)
- **Interrupt Latency**: < 5 clock cycles from event to interrupt assertion

### Reliability Requirements
- **Fault Tolerance**: Single bit error detection in FIFO
- **Error Correction**: Automatic retransmission on framing errors
- **Watchdog**: Configurable watchdog timer for stuck conditions
- **Reset Recovery**: Guaranteed operation after power-on reset

## Test Strategy & Verification

### Testbench Requirements
- **Language**: SystemVerilog with UVM methodology
- **Coverage**: Functional, code, and assertion coverage
- **Randomization**: Constrained random testing for all interfaces
- **Assertions**: SVA assertions for protocol compliance
- **Waveforms**: Comprehensive waveform generation for debugging

### Test Scenarios
- **Basic Functionality**: TX/RX at all supported baud rates
- **FIFO Operations**: Full/empty conditions, overflow/underflow
- **Interrupt Testing**: All interrupt conditions and clearing
- **Error Conditions**: Parity, framing, overrun error injection
- **Performance Testing**: Maximum throughput and latency measurement
- **Power Testing**: Clock gating and sleep mode validation

### Simulation Environment
- **Simulator**: Verilator for fast simulation, ModelSim for detailed
- **Test Vectors**: Automated test vector generation
- **Regression**: Automated regression testing with CI/CD
- **Coverage Analysis**: Automated coverage reporting and analysis

## Integration & Packaging

### SoC Integration
- **Target Platforms**: OpenTitan, Caravel, OpenPiton
- **Interface Compatibility**: Standard APB3 slave interface
- **Clock Integration**: Single clock domain with clock gating
- **Reset Integration**: Asynchronous reset with proper synchronization

### Verification Environment
- **UVM Framework**: Standard UVM testbench structure
- **Cocotb Support**: Python-based verification for advanced scenarios
- **Formal Verification**: Model checking for critical properties
- **Emulation Support**: FPGA-based emulation for system-level testing

### Documentation Requirements
- **User Manual**: Complete user guide with examples
- **Integration Guide**: SoC integration instructions
- **API Reference**: Complete register map and interface specification
- **Timing Diagrams**: Detailed timing for all interfaces
- **Test Report**: Comprehensive test results and coverage

### Packaging & Distribution
- **Metadata**: Complete vyges-metadata.json for catalog
- **License**: Apache-2.0 with proper attribution
- **Examples**: Integration examples for common SoC platforms
- **Scripts**: Automated build and test scripts
- **CI/CD**: GitHub Actions for automated testing and validation

## Design UART IP Block

### Understanding the Design Flow

**🎯 Before Implementation: Design First**

```ascii
┌─────────────────────────────────────────────────────────────┐
│                    IP Design Flow                           │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   SPECIFY   │───▶│   DESIGN    │───▶│ IMPLEMENT   │      │
│  │ Requirements│    │ Architecture│    │   RTL       │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   VERIFY    │◀───│   TEST      │◀───│  VALIDATE   │      │
│  │  Coverage   │    │  Testbench  │    │  Synthesis  │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Design Considerations for UART Controller:**

### Functional Requirements
- **Baud Rate**: Configurable (9600 to 921600 bps)
- **Data Format**: 8-bit data, 1 stop bit, no parity (configurable)
- **FIFO Support**: TX/RX FIFOs for buffering
- **Interrupts**: TX empty, RX full, error conditions
- **APB Interface**: Standard APB slave for register access
- **Clock Domain**: Single clock domain operation

### Interface Design

```ascii
┌─────────────────────────────────────┐
│         UART_CONTROLLER             │
│                                     │
│  ┌─────────┐    ┌─────────┐         │
│  │ APB     │    │ UART    │         │
│  │ Slave   │    │ Master  │         │
│  └─────────┘    └─────────┘         │
│                                     │
│  ┌─────────┐    ┌─────────┐         │
│  │ Clock   │    │ Reset   │         │
│  │ Domain  │    │ Domain  │         │
│  └─────────┘    └─────────┘         │
└─────────────────────────────────────┘
```

### Architecture Design

```ascii
┌─────────────────────────────────────────────────────────────┐
│                    UART Controller Architecture             │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   APB       │    │   Control   │    │   UART      │      │
│  │  Slave      │◀──▶│  Registers  │◀──▶│  Interface  │      │
│  │ Interface   │    │             │    │             │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   TX        │    │   RX        │    │   Interrupt │      │
│  │  FIFO       │    │  FIFO       │    │  Controller │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   UART      │    │   UART      │    │   Error     │      │
│  │ Transmitter │    │  Receiver   │    │  Detection  │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
│         │                   │                      │        |
│         └───────────────────┴──────────────────────┘        |
│                           │                                 |
│                    ┌─────────────┐                          |
│                    │   UART      │                          |
│                    │  TX/RX      │                          |
│                    └─────────────┘                          |
└─────────────────────────────────────────────────────────────┘
```

### Register Map Design

```ascii
APB Register Map (8-bit address space):
┌─────────┬─────────┬─────────┬─────────────────────────────┐
│ Address │  Name   │ Access  │        Description          │
├─────────┼─────────┼─────────┼─────────────────────────────┤
│  0x00   │  CTRL   │  R/W    │ Control Register            │
│  0x04   │  STAT   │   R     │ Status Register             │
│  0x08   │  TXDATA │   W     │ TX Data Register            │
│  0x0C   │  RXDATA │   R     │ RX Data Register            │
│  0x10   │  BAUD   │  R/W    │ Baud Rate Configuration     │
│  0x14   │  FIFO   │  R/W    │ FIFO Configuration          │
│  0x18   │  INT    │  R/W    │ Interrupt Configuration     │
└─────────┴─────────┴─────────┴─────────────────────────────┘
```

### Timing Design

```ascii
UART Timing (115200 baud, 50MHz clock):
┌─────────────────────────────────────────────────────────────┐
│                    Timing Requirements                      │
│                                                             │
│  Clock Frequency: 50 MHz                                    │
│  Baud Rate: 115200 bps                                      │
│  Clock Divider: 50MHz / 115200 = 434.03 (round to 434)      │
│  Bit Time: 434 clock cycles                                 │
│  Sample Point: Middle of bit (217 cycles)                   │
│                                                             │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐    │
│  │Start│ │ D0  │ │ D1  │ │ D2  │ │ D3  │ │ D4  │ │ D5  │    │
│  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘    │
│                                                             │
│  ┌─────┐ ┌─────┐ ┌─────┐                                    │
│  │ D6  │ │ D7  │ │Stop │                                    │
│  └─────┘ └─────┘ └─────┘                                    │
└─────────────────────────────────────────────────────────────┘
```

### IP Block Pinout Design

```ascii
┌─────────────────────────────────────────────────────────────┐
│                    UART Controller IP Block                 │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 APB Slave Interface                 │   │
│  │                                                     │   │
│  │  PCLK_i     ────┐                                   │   │
│  │  PRESETn_i  ────┤                                   │   │
│  │  PSEL_i     ────┤                                   │   │
│  │  PENABLE_i  ────┤                                   │   │
│  │  PWRITE_i   ────┤                                   │   │
│  │  PADDR_i[7:0]───┤                                   │   │
│  │  PWDATA_i[31:0]─┤                                   │   │
│  │  PRDATA_o[31:0]─┤                                   │   │
│  │  PREADY_o   ────┤                                   │   │
│  │  PSLVERR_o  ────┘                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 UART Interface                      │   │
│  │                                                     │   │
│  │  UART_TX_o   ────┐                                 │   │
│  │  UART_RX_i   ────┘                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │               Interrupt Interface                   │   │
│  │                                                     │   │
│  │  IRQ_TX_EMPTY_o ────┐                              │   │
│  │  IRQ_RX_FULL_o  ────┘                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Configuration Interface                │   │
│  │                                                     │   │
│  │  CLOCK_FREQUENCY: 50 MHz (parameter)                │   │
│  │  BAUD_RATE: 115200 bps (parameter)                  │   │
│  │  FIFO_DEPTH: 16 entries (parameter)                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Pinout Table:**
The following table summarizes all external signals for the UART Controller IP block:

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

**Pinout Details:**

**APB Slave Interface (10 pins):**
- `PCLK_i`: APB clock input (50 MHz)
- `PRESETn_i`: APB reset input (active low)
- `PSEL_i`: APB select input
- `PENABLE_i`: APB enable input
- `PWRITE_i`: APB write input
- `PADDR_i[7:0]`: APB address input (8-bit)
- `PWDATA_i[31:0]`: APB write data input (32-bit)
- `PRDATA_o[31:0]`: APB read data output (32-bit)
- `PREADY_o`: APB ready output
- `PSLVERR_o`: APB slave error output

**UART Interface (2 pins):**
- `UART_TX_o`: UART transmit output
- `UART_RX_i`: UART receive input

**Interrupt Interface (2 pins):**
- `IRQ_TX_EMPTY_o`: Transmit FIFO empty interrupt
- `IRQ_RX_FULL_o`: Receive FIFO full interrupt

**Configuration Parameters:**
- `CLOCK_FREQUENCY`: System clock frequency (default: 50 MHz)
- `BAUD_RATE`: UART baud rate (default: 115200 bps)
- `FIFO_DEPTH`: FIFO depth for TX/RX (default: 16)

**Interface Summary:**
- **Total Pins**: 14 (10 APB + 2 UART + 2 Interrupt)
- **Input Pins**: 8 (7 APB + 1 UART)
- **Output Pins**: 6 (3 APB + 1 UART + 2 Interrupt)
- **Bidirectional Pins**: 0
- **Clock Domains**: 1 (single clock domain)
