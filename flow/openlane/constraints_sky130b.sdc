#=============================================================================
# Synthesis Constraints for UART Controller
#=============================================================================
# Description: Synopsys Design Constraints (SDC) file for UART controller
#              targeting SkyWater 130nm Open Source PDK.
#
# Features:
# - Clock constraints for 50MHz operation
# - Input/output timing constraints
# - Area and power constraints
# - False path and multicycle path definitions
#
# Author: shivaram@vyges.com
# License: Apache-2.0
#=============================================================================

# Clock definitions
create_clock -name pclk -period 20.0 -waveform {0 10} [get_ports pclk_i]

# Clock uncertainty
set_clock_uncertainty 0.1 [get_clocks pclk]

# Input delays
set_input_delay -clock pclk -max 2.0 [get_ports {psel_i penable_i pwrite_i paddr_i[*] pwdata_i[*] uart_rx_i}]
set_input_delay -clock pclk -min 0.5 [get_ports {psel_i penable_i pwrite_i paddr_i[*] pwdata_i[*] uart_rx_i}]

# Output delays
set_output_delay -clock pclk -max 3.0 [get_ports {prdata_o[*] pready_o pslverr_o uart_tx_o irq_tx_empty_o irq_rx_full_o}]
set_output_delay -clock pclk -min 0.5 [get_ports {prdata_o[*] pready_o pslverr_o uart_tx_o irq_tx_empty_o irq_rx_full_o}]

# Reset signal
set_false_path -from [get_ports presetn_i]

# UART signals (asynchronous)
set_false_path -from [get_ports uart_rx_i]
set_false_path -to [get_ports uart_tx_o]

# Interrupt signals (asynchronous)
set_false_path -to [get_ports {irq_tx_empty_o irq_rx_full_o}]

# APB interface timing
set_multicycle_path -setup 2 -from [get_clocks pclk] -to [get_clocks pclk] -through [get_pins */prdata_o[*]]
set_multicycle_path -hold 1 -from [get_clocks pclk] -to [get_clocks pclk] -through [get_pins */prdata_o[*]]

# FIFO operations (allow multiple cycles)
set_multicycle_path -setup 2 -from [get_clocks pclk] -to [get_clocks pclk] -through [get_pins */fifo_mem[*]]

# Area constraints
set_max_area 0.1

# Power constraints
set_max_dynamic_power 5.0mW
set_max_leakage_power 1.0uW

# Load constraints
set_load 10 [get_ports {prdata_o[*] pready_o pslverr_o uart_tx_o irq_tx_empty_o irq_rx_full_o}]

# Drive strength constraints
set_drive 1 [get_ports {psel_i penable_i pwrite_i paddr_i[*] pwdata_i[*] uart_rx_i}]

# Operating conditions
set_operating_conditions -library sky130_fd_sc_hd__tt_025C_1v80

# Wire load model
set_wire_load_model -name "sky130_fd_sc_hd__tt_025C_1v80"

# Don't touch nets
set_dont_touch_network [get_ports pclk_i]
set_dont_touch_network [get_ports presetn_i]

# Clock gating
set_clock_gating_check -setup 0.5 -hold 0.1

# Timing exceptions
set_false_path -through [get_pins */rx_sync]
set_false_path -through [get_pins */rx_prev]

# Group paths
group_path -name "apb_read" -from [get_ports {psel_i penable_i paddr_i[*]}] -to [get_ports {prdata_o[*] pready_o}]
group_path -name "apb_write" -from [get_ports {psel_i penable_i pwrite_i paddr_i[*] pwdata_i[*]}] -to [get_ports {pready_o pslverr_o}]
group_path -name "uart_tx" -from [get_pins */uart_tx_inst/*] -to [get_ports uart_tx_o]
group_path -name "uart_rx" -from [get_ports uart_rx_i] -to [get_pins */uart_rx_inst/*]

# End of constraints 