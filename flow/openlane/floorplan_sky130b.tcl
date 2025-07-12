#=============================================================================
# Floorplan Script for UART Controller - Sky130B PDK
#=============================================================================
# Description: Custom floorplan script for OpenLane flow
#              Defines die area, core area, and pin placement strategy
#
# Floorplan Strategy:
# - Die area: 1000x1000 microns (1mm x 1mm)
# - Core area: 800x800 microns (80% utilization)
# - Pin placement: APB on left, UART on right, interrupts on top
# - Power distribution: Standard cell power rails
#
# Author: shivaram@vyges.com
# License: Apache-2.0
#=============================================================================

# Die area definition (1000x1000 microns)
set die_area "0 0 1000 1000"
set core_area "100 100 900 900"

# Core utilization target
set core_utilization 0.80

# Pin placement strategy
set pin_placement_strategy "random"

# Power distribution
set power_distribution "standard"

# Tap cell placement
set tap_cell_distance 13

# Well tap cell type
set well_tap_cell "sky130_fd_sc_hd__tapvpwrvgnd_1"

# Endcap cell type
set endcap_cell "sky130_fd_sc_hd__decap_4"

# Power rail configuration
set power_rail_width 0.48
set power_rail_spacing 1.7

# Core ring configuration (disabled for small design)
set core_ring_enable 0
set core_ring_width 6.2
set core_ring_spacing 1.7

# IO ring configuration
set io_ring_width 1.6
set io_ring_spacing 1.7

# Metal layer configuration
set horizontal_metal_layer 4
set vertical_metal_layer 3
set horizontal_thickness_mult 2
set vertical_thickness_mult 2

# IO placement constraints
set io_min_distance 3
set io_mode 1
set io_unmatched_error 1

# Power domain configuration
set vdd_nets "vccd1 vccd2 vdda1 vdda2"
set vss_nets "vssd1 vssd2 vssa1 vssa2"
set vdd_pin "VPWR"
set vss_pin "VGND"
set vdd_voltage "1.80"

# Clock routing configuration
set clock_routing_layer "met5"
set clock_min_routing_layer "met5"

# Signal routing configuration
set signal_min_routing_layer "met1"
set signal_max_routing_layer "met5"

# Antenna configuration
set antenna_insertion 1
set antenna_repair 1

# Fill configuration
set fill_enable 1
set fill_cells "sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8"

# DRC configuration
set drc_enable 1
set drc_use_gds 1

# LVS configuration
set lvs_insert_power_pins 1

# GDS configuration
set gds_enable 1
set gds_generate 1

# LEF configuration
set lef_generate 1
set lef_write_full 0

# Netlist configuration
set netlist_enable 1
set netlist_include_power_pins 1

# Timing configuration
set timing_enable 1
set timing_optimize 1

# Area configuration
set area_target 0.1
set area_optimize 1

# Power configuration
set power_enable 1
set power_target_dynamic 5.0mW
set power_target_leakage 1.0uW

# End of floorplan configuration 