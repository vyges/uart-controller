//=============================================================================
// Module Name: uart_wrapper
//=============================================================================
// Description: Integration wrapper for UART controller with APB interface.
//              Provides a clean interface for SoC integration.
//
// Features:
// - APB slave interface
// - UART TX/RX signals
// - Interrupt outputs
// - Clock and reset interface
// - Parameter configuration
//
// Author: shivaram@vyges.com
// License: Apache-2.0
//=============================================================================

module uart_wrapper #(
    parameter int CLOCK_FREQUENCY = 50_000_000,
    parameter int BAUD_RATE = 115_200,
    parameter int FIFO_DEPTH = 16,
    parameter int DATA_WIDTH = 8,
    parameter int STOP_BITS = 1,
    parameter bit PARITY_ENABLE = 1'b0,
    parameter string PARITY_TYPE = "even"
) (
    // Clock and Reset
    input  wire        pclk_i,
    input  wire        presetn_i,
    
    // APB Slave Interface
    input  wire        psel_i,
    input  wire        penable_i,
    input  wire        pwrite_i,
    input  wire [7:0]  paddr_i,
    input  wire [31:0] pwdata_i,
    output wire [31:0] prdata_o,
    output wire        pready_o,
    output wire        pslverr_o,
    
    // UART Interface
    output wire        uart_tx_o,
    input  wire        uart_rx_i,
    
    // Interrupt Interface
    output wire        irq_tx_empty_o,
    output wire        irq_rx_full_o
);

    // Instantiate UART controller
    uart_controller #(
        .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE),
        .FIFO_DEPTH(FIFO_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BITS(STOP_BITS),
        .PARITY_ENABLE(PARITY_ENABLE),
        .PARITY_TYPE(PARITY_TYPE)
    ) uart_ctrl_inst (
        .pclk_i(pclk_i),
        .presetn_i(presetn_i),
        .psel_i(psel_i),
        .penable_i(penable_i),
        .pwrite_i(pwrite_i),
        .paddr_i(paddr_i),
        .pwdata_i(pwdata_i),
        .prdata_o(prdata_o),
        .pready_o(pready_o),
        .pslverr_o(pslverr_o),
        .uart_tx_o(uart_tx_o),
        .uart_rx_i(uart_rx_i),
        .irq_tx_empty_o(irq_tx_empty_o),
        .irq_rx_full_o(irq_rx_full_o)
    );

endmodule 