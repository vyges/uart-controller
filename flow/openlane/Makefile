# flow/openlane/Makefile
# Makefile for running OpenLane flow on top_wrapper
#
# This sets up and runs the OpenLane flow for your design using the official OpenLane Docker CLI.
# It assumes:
# - You’re running OpenLane via Docker.
# - Your design files and config.json are located under flow/openlane/.
# - Your design’s top module is top_wrapper.

# Note: Automatically mounts project and PDK directories and works with official OpenLane Docker environment.

# Usage:
# cd flow/openlane
# make run     # runs OpenLane flow using your config.json
# make final   # collects final results (GDS, DEF, etc.) into a final/ dir
# make clean   # removes run artifacts


# Design name
DESIGN_NAME := uart_controller

# Paths
FLOW_DIR := $(shell pwd)
OPENLANE_ROOT ?= $(HOME)/OpenLane
PDK := sky130B
PDK_ROOT ?= $(HOME)/pdks
CONFIG_FILE := config_sky130b.json

# Docker image/tag (change if using a different version)
OPENLANE_DOCKER_IMAGE := openlane:latest

# Docker run settings
DOCKER_CMD := docker run -it --rm \
	-v $(OPENLANE_ROOT):/openlane \
	-v $(PDK_ROOT):/pdks \
	-v $(FLOW_DIR):/project \
	-e PDK=$(PDK) \
	-e PDK_ROOT=/pdks \
	-e DESIGN_NAME=$(DESIGN_NAME) \
	-u $(shell id -u):$(shell id -g) \
	$(OPENLANE_DOCKER_IMAGE)

.PHONY: run clean final sky130a sky130b help

## Run the OpenLane flow
run:
	$(DOCKER_CMD) bash -c \
		"cd /openlane && \
		 flow.tcl -design /project -override_config_file /project/$(CONFIG_FILE)"

## Run with Sky130A PDK
sky130a:
	$(eval CONFIG_FILE := config_sky130a.json)
	$(eval PDK := sky130A)
	$(DOCKER_CMD) bash -c \
		"cd /openlane && \
		 flow.tcl -design /project -override_config_file /project/$(CONFIG_FILE)"

## Run with Sky130B PDK
sky130b:
	$(eval CONFIG_FILE := config_sky130b.json)
	$(eval PDK := sky130B)
	$(DOCKER_CMD) bash -c \
		"cd /openlane && \
		 flow.tcl -design /project -override_config_file /project/$(CONFIG_FILE)"

## Copy GDS, DEF, and netlist outputs to a local final/ directory
final:
	mkdir -p final
	cp -v runs/$(DESIGN_NAME)/results/final/gds/*.gds       final/ || true
	cp -v runs/$(DESIGN_NAME)/results/final/def/*.def       final/ || true
	cp -v runs/$(DESIGN_NAME)/results/final/verilog/*.v     final/ || true
	cp -v runs/$(DESIGN_NAME)/results/final/spef/*.spef     final/ || true
	cp -v runs/$(DESIGN_NAME)/results/final/sdf/*.sdf       final/ || true
	cp -v runs/$(DESIGN_NAME)/results/final/lef/*.lef       final/ || true

## Clean all generated output
clean:
	rm -rf runs final

## Show help
help:
	@echo "OpenLane Flow Makefile for UART Controller"
	@echo ""
	@echo "Available targets:"
	@echo "  run        - Run OpenLane flow with default config ($(CONFIG_FILE))"
	@echo "  sky130a    - Run OpenLane flow with Sky130A PDK"
	@echo "  sky130b    - Run OpenLane flow with Sky130B PDK (default)"
	@echo "  final      - Collect final results in final/ directory"
	@echo "  clean      - Clean all generated files"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  DESIGN_NAME: $(DESIGN_NAME)"
	@echo "  PDK: $(PDK)"
	@echo "  CONFIG_FILE: $(CONFIG_FILE)"
	@echo "  OPENLANE_ROOT: $(OPENLANE_ROOT)"
	@echo "  PDK_ROOT: $(PDK_ROOT)"
