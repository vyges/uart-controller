# UART Controller IP Overview

## Introduction

The UART Controller IP is a complete serial communication solution designed for embedded systems and SoC integration. It provides a configurable UART interface with APB slave connectivity, FIFO buffering, and interrupt capabilities.

## Architecture

### Block Diagram

```
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
│                    │   UART      │                          │
│                    │  TX/RX      │                          │
│                    └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

1. **APB Slave Interface**: Handles register access and APB protocol compliance
2. **Control Registers**: Configuration and status registers
3. **TX/RX FIFOs**: Buffering for transmit and receive data
4. **UART Transmitter**: Serial data transmission with configurable parameters
5. **UART Receiver**: Serial data reception with error detection
6. **Interrupt Controller**: Interrupt generation and management
7. **Error Detection**: Parity, framing, and overrun error handling

## Interface Details

### APB Slave Interface

The APB slave interface follows the AMBA APB protocol specification:

- **PCLK_i**: APB clock (50 MHz)
- **PRESETn_i**: Active-low reset
- **PSEL_i**: Slave select
- **PENABLE_i**: Enable signal
- **PWRITE_i**: Write enable
- **PADDR_i[7:0]**: Address bus
- **PWDATA_i[31:0]**: Write data
- **PRDATA_o[31:0]**: Read data
- **PREADY_o**: Ready signal
- **PSLVERR_o**: Slave error

### UART Interface

- **UART_TX_o**: Transmit output
- **UART_RX_i**: Receive input

### Interrupt Interface

- **IRQ_TX_EMPTY_o**: Transmit FIFO empty interrupt
- **IRQ_RX_FULL_o**: Receive FIFO full interrupt

## Register Map

### Control Register (0x00)
```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│  7  │  6  │  5  │  4  │  3  │  2  │  1  │  0  │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│     │     │     │PAR_T│PAR_E│ RX_E│ TX_E│ EN  │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

- Bit 0 (EN): Enable controller
- Bit 1 (TX_E): Enable transmitter
- Bit 2 (RX_E): Enable receiver
- Bit 3 (PAR_E): Enable parity
- Bit 4 (PAR_T): Parity type (0=Even, 1=Odd)

### Status Register (0x04)
```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│  7  │  6  │  5  │  4  │  3  │  2  │  1  │  0  │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│     │OVR_E│FRM_E│PAR_E│RX_E │TX_F │RX_B │TX_B │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

- Bit 0 (TX_B): TX busy
- Bit 1 (RX_B): RX busy
- Bit 2 (TX_F): TX FIFO full
- Bit 3 (RX_E): RX FIFO empty
- Bit 4 (PAR_E): Parity error
- Bit 5 (FRM_E): Frame error
- Bit 6 (OVR_E): Overrun error

### Data Registers

- **TXDATA (0x08)**: Write-only transmit data register
- **RXDATA (0x0C)**: Read-only receive data register

### Configuration Registers

- **BAUD (0x10)**: Baud rate configuration
- **FIFO (0x14)**: FIFO configuration
- **INT (0x18)**: Interrupt configuration

## FIFO Implementation

### TX FIFO
- Configurable depth (4-64 entries)
- Synchronous write from APB interface
- Asynchronous read by UART transmitter
- Full/empty status detection
- Overflow protection

### RX FIFO
- Configurable depth (4-64 entries)
- Asynchronous write from UART receiver
- Synchronous read from APB interface
- Full/empty status detection
- Overrun protection

### FIFO Status
- Gray code pointers for reliable status detection
- Single clock domain operation
- Automatic full/empty flag generation

## UART Protocol

### Frame Format
```
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│ Start   │ Data    │ Parity  │ Stop    │ Stop    │
│ Bit     │ Bits    │ Bit     │ Bit 1   │ Bit 2   │
│ (0)     │ (5-8)   │ (0/1)   │ (1)     │ (0/1)   │
└─────────┴─────────┴─────────┴─────────┴─────────┘
```

### Timing
- Configurable baud rate (9600-921600 bps)
- 16x oversampling for reliable reception
- Middle-of-bit sampling for noise immunity
- Automatic baud rate generation

### Error Detection
- **Parity Error**: Mismatch between received and expected parity
- **Frame Error**: Invalid stop bit detection
- **Overrun Error**: RX FIFO full when new data arrives

## Interrupt System

### Interrupt Sources
1. **TX FIFO Empty**: Triggered when TX FIFO becomes empty
2. **RX FIFO Full**: Triggered when RX FIFO becomes full

### Interrupt Control
- Individual enable/disable for each interrupt source
- Pending status bits for interrupt state
- Automatic clearing on read/write operations

### Interrupt Register (0x18)
```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│  7  │  6  │  5  │  4  │  3  │  2  │  1  │  0  │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│     │     │     │     │RX_P │TX_P │RX_E │TX_E │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

- Bit 0 (TX_E): TX empty interrupt enable
- Bit 1 (RX_E): RX full interrupt enable
- Bit 2 (TX_P): TX empty interrupt pending
- Bit 3 (RX_P): RX full interrupt pending

## Power Management

### Clock Gating
- Automatic clock gating when UART is idle
- Configurable sleep mode with wake-up on RX activity
- Power domain isolation for low-power operation

### Power States
1. **Active**: Full functionality enabled
2. **Idle**: Clock gated, wake-up on activity
3. **Sleep**: Minimal power consumption

## Performance Characteristics

### Timing
- **Maximum Frequency**: 50 MHz
- **APB Access Latency**: < 10 clock cycles
- **UART Transmission**: Full baud rate support
- **Interrupt Latency**: < 5 clock cycles

### Area and Power
- **Area**: < 0.1mm² (Sky130 PDK)
- **Dynamic Power**: < 5mW at 50MHz, 1.8V
- **Leakage Power**: < 1μW in sleep mode

### Reliability
- **Fault Tolerance**: Single bit error detection
- **Error Recovery**: Automatic retransmission on framing errors
- **Watchdog**: Configurable timeout for stuck conditions

## Integration Guidelines

### SoC Integration
1. **Clock Domain**: Single clock domain (PCLK)
2. **Reset**: Asynchronous reset with proper synchronization
3. **Interrupts**: Level-sensitive interrupt signals
4. **APB Interface**: Standard APB3 slave protocol

### Pin Assignment
- APB pins on left side
- UART pins on right side
- Interrupt pins on top
- Clock/reset pins on bottom

### Floorplan Considerations
- Aspect ratio: 1:1 to 2:1 (width:height)
- Core utilization: < 80%
- I/O ring: Standard cell I/O with ESD protection

## Verification Strategy

### Test Coverage
- **Functional Coverage**: 95% minimum
- **Code Coverage**: 90% minimum
- **Toggle Coverage**: 100% for all data signals
- **FSM Coverage**: 100% state and transition coverage

### Test Scenarios
1. **Basic Functionality**: TX/RX at all supported baud rates
2. **FIFO Operations**: Full/empty conditions, overflow/underflow
3. **Interrupt Testing**: All interrupt conditions and clearing
4. **Error Conditions**: Parity, framing, overrun error injection
5. **Performance Testing**: Maximum throughput and latency measurement
6. **Power Testing**: Clock gating and sleep mode validation

### Simulation Environment
- **SystemVerilog**: Primary testbench language
- **Cocotb**: Python-based verification for advanced scenarios
- **Verilator**: Fast simulation for regression testing
- **Coverage Analysis**: Automated coverage reporting

## Future Enhancements

### Planned Features
1. **DMA Support**: Direct memory access for high-throughput applications
2. **Multi-UART Support**: Multiple UART channels in single IP
3. **Advanced Error Correction**: Forward error correction (FEC)
4. **Flow Control**: Hardware flow control (RTS/CTS)
5. **Wake-up Patterns**: Configurable wake-up pattern detection

### Scalability
- **Parameterizable**: All key parameters configurable
- **Modular Design**: Easy to extend and modify
- **Standard Interfaces**: Compatible with industry standards
- **Documentation**: Comprehensive documentation and examples 