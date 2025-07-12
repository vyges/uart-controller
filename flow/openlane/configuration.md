# OpenLane Configuration for UART Controller - Sky130B PDK

This document describes the OpenLane configuration and flow setup for the UART Controller IP targeting the SkyWater 130nm Open Source PDK (SKY130 process node).

## PDK Support

### Sky130B PDK Configuration
- **Platform**: `sky130bhd` (high-density standard cell library)
- **PDK Source**: [github.com/google/skywater-pdk](https://github.com/google/skywater-pdk)
- **Standard Cell Library**: `sky130_fd_sc_hd`
- **Supply Voltage**: 1.8V nominal
- **Process Corners**: TT, FF, SS, FS, SF

### Configuration Files
- **Main Config**: `config_sky130b.json` - Sky130B-specific configuration
- **Template Config**: `config.template.json` - Template for other PDK variants
- **Timing Constraints**: `constraints_sky130b.sdc` - Design-specific timing
- **Pin Order**: `pin_order_sky130b.cfg` - I/O pin placement
- **Floorplan**: `floorplan_sky130b.tcl` - Custom floorplan configuration

## File Structure

```
flow/openlane/
├── config_sky130b.json           # Sky130B-specific OpenLane config
├── config.template.json          # Template configuration
├── constraints_sky130b.sdc       # Timing constraints for Sky130B
├── pin_order_sky130b.cfg         # I/O pin placement order
├── floorplan_sky130b.tcl         # Custom floorplan configuration
├── Makefile                      # OpenLane flow automation
└── configuration.md              # This documentation
```

## Usage

### Running the Flow

```bash
# From flow/openlane/ directory

# Run with Sky130B PDK (default)
make sky130b

# Run with Sky130A PDK (if needed)
make sky130a

# Run with default configuration
make run

# Show help
make help

# Collect final results
make final

# Clean generated files
make clean
```

### Configuration Parameters

#### Design Configuration
- **DESIGN_NAME**: `uart_controller` - Top-level module name
- **VERILOG_FILES**: RTL source files for UART controller modules
- **CLOCK_PORT**: `pclk_i` - APB clock input
- **CLOCK_PERIOD**: `20.0` - 50MHz operation (20ns period)
- **RESET_PORT**: `presetn_i` - APB reset input (active low)

#### PDK Configuration
- **PLATFORM**: `sky130bhd` - Sky130B high-density platform
- **PDK**: `sky130B` - SkyWater 130nm PDK
- **STD_CELL_LIBRARY**: `sky130_fd_sc_hd` - Standard cell library
- **LIB_SYNTH**: `sky130_fd_sc_hd__tt_025C_1v80` - Synthesis library

#### Physical Design Configuration
- **DIE_AREA**: `"0 0 1000 1000"` - 1mm x 1mm die area
- **FP_CORE_UTIL**: `50` - 50% core utilization target
- **PL_TARGET_DENSITY**: `0.45` - Placement density target
- **FP_PIN_ORDER_CFG**: `pin_order_sky130b.cfg` - Pin placement order

#### Power Configuration
- **VDD_NETS**: `"vccd1 vccd2 vdda1 vdda2"` - Power supply nets
- **VSS_NETS**: `"vssd1 vssd2 vssa1 vssa2"` - Ground nets
- **VDD_PIN**: `"VPWR"` - Power pin name
- **VSS_PIN**: `"VGND"` - Ground pin name
- **VDD_PIN_VOLTAGE**: `"1.80"` - Supply voltage

#### Routing Configuration
- **RT_CLOCK_ROUTING_LAYER**: `"met5"` - Clock routing layer
- **RT_MIN_LAYER**: `"met1"` - Minimum routing layer
- **TECH_METAL_LAYERS**: `"li1 met1 met2 met3 met4 met5"` - Available metal layers

## Pin Placement Strategy

The pin order configuration (`pin_order_sky130b.cfg`) follows this strategy:

### Left Side (APB Interface)
- Clock and reset signals
- APB control signals (PSEL, PENABLE, PWRITE)
- APB address bus (PADDR[7:0])
- APB write data bus (PWDATA[31:0])
- APB read data bus (PRDATA[31:0])
- APB response signals (PREADY, PSLVERR)

### Right Side (UART Interface)
- UART transmit output (UART_TX_o)
- UART receive input (UART_RX_i)

### Top Side (Interrupts)
- Transmit FIFO empty interrupt (IRQ_TX_EMPTY_o)
- Receive FIFO full interrupt (IRQ_RX_FULL_o)

### Distributed (Power/Ground)
- Power supply nets (VCCD1, VCCD2, VDDA1, VDDA2)
- Ground nets (VSSD1, VSSD2, VSSA1, VSSA2)

## Timing Constraints

The SDC file (`constraints_sky130b.sdc`) includes:

### Clock Constraints
- 50MHz clock (20ns period) for APB interface
- Clock uncertainty and jitter margins
- Clock gating checks

### Interface Timing
- APB interface setup/hold timing
- UART interface false paths (asynchronous)
- Interrupt signal timing

### Design Constraints
- Area target: < 0.1mm²
- Power targets: < 5mW dynamic, < 1μW leakage
- Load and drive strength constraints

## Floorplan Configuration

The floorplan script (`floorplan_sky130b.tcl`) defines:

### Die and Core Areas
- Die area: 1000x1000 microns (1mm x 1mm)
- Core area: 800x800 microns (80% utilization)
- Aspect ratio: 1:1 (square die)

### Power Distribution
- Standard cell power rails
- Power ring configuration (disabled for small design)
- Tap cell placement strategy

### Routing Configuration
- Metal layer assignments
- Antenna rules and repair
- Fill cell configuration

## Results and Outputs

After successful completion, the flow generates:

### Physical Design Files
- **GDS**: `final/uart_controller.gds` - Final layout
- **DEF**: `final/uart_controller.def` - Design exchange format
- **LEF**: `final/uart_controller.lef` - Library exchange format

### Timing and Power Reports
- **SDF**: `final/uart_controller.sdf` - Standard delay format
- **SPEF**: `final/uart_controller.spef` - Standard parasitic format
- **Timing reports**: STA results and timing analysis
- **Power reports**: Dynamic and leakage power analysis

### Verification Results
- **DRC reports**: Design rule check results
- **LVS reports**: Layout vs. schematic comparison
- **XOR reports**: Layout comparison results

## Troubleshooting

### Common Issues

1. **PDK not found**: Ensure SkyWater PDK is installed in `PDK_ROOT`
2. **OpenLane not found**: Install OpenLane toolchain
3. **Timing violations**: Review and adjust SDC constraints
4. **DRC violations**: Check design rules and adjust floorplan
5. **Power violations**: Review power distribution and constraints

### Debug Commands

```bash
# Check PDK installation
ls $PDK_ROOT/sky130B

# Check OpenLane installation
which openlane

# View detailed logs
tail -f runs/uart_controller/runtime/flow.log

# Check specific step results
ls runs/uart_controller/results/synthesis/
ls runs/uart_controller/results/placement/
ls runs/uart_controller/results/routing/
```

## References

- [SkyWater Open Source PDK](https://github.com/google/skywater-pdk)
- [OpenLane Documentation](https://openlane.readthedocs.io/)
- [Sky130 PDK Documentation](https://skywater-pdk.readthedocs.io/)
- [UART Controller Design Specification](../docs/UART_design_spec.md)
