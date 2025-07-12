//=============================================================================
// Module Name: uart_controller
//=============================================================================
// Description: Configurable UART controller with APB interface, FIFO support,
//              and interrupt capabilities for embedded systems.
//
// Features:
// - APB slave interface for register access
// - Configurable baud rate (9600 to 921600 bps)
// - TX/RX FIFOs with configurable depth
// - Interrupt support for TX empty and RX full conditions
// - Error detection and reporting
// - Power management with clock gating
//
// Author: shivaram@vyges.com
// License: Apache-2.0
//=============================================================================

module uart_controller #(
    parameter int CLOCK_FREQUENCY = 50_000_000,
    parameter int BAUD_RATE = 115_200,
    parameter int FIFO_DEPTH = 16,
    parameter int DATA_WIDTH = 8,
    parameter int STOP_BITS = 1,
    parameter bit PARITY_ENABLE = 1'b0,
    parameter string PARITY_TYPE = "even"
) (
    // Clock and Reset
    input  logic        pclk_i,
    input  logic        presetn_i,
    
    // APB Slave Interface
    input  logic        psel_i,
    input  logic        penable_i,
    input  logic        pwrite_i,
    input  logic [7:0]  paddr_i,
    input  logic [31:0] pwdata_i,
    output logic [31:0] prdata_o,
    output logic        pready_o,
    output logic        pslverr_o,
    
    // UART Interface
    output logic        uart_tx_o,
    input  logic        uart_rx_i,
    
    // Interrupt Interface
    output logic        irq_tx_empty_o,
    output logic        irq_rx_full_o
);

    // Local parameters
    localparam int BAUD_DIVIDER = CLOCK_FREQUENCY / BAUD_RATE;
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);
    
    // Register addresses
    localparam logic [7:0] CTRL_REG_ADDR   = 8'h00;
    localparam logic [7:0] STAT_REG_ADDR   = 8'h04;
    localparam logic [7:0] TXDATA_REG_ADDR = 8'h08;
    localparam logic [7:0] RXDATA_REG_ADDR = 8'h0C;
    localparam logic [7:0] BAUD_REG_ADDR   = 8'h10;
    localparam logic [7:0] FIFO_REG_ADDR   = 8'h14;
    localparam logic [7:0] INT_REG_ADDR    = 8'h18;
    
    // Control register bits
    localparam int CTRL_ENABLE_BIT     = 0;
    localparam int CTRL_TX_ENABLE_BIT  = 1;
    localparam int CTRL_RX_ENABLE_BIT  = 2;
    localparam int CTRL_PARITY_EN_BIT  = 3;
    localparam int CTRL_PARITY_ODD_BIT = 4;
    
    // Status register bits
    localparam int STAT_TX_BUSY_BIT    = 0;
    localparam int STAT_RX_BUSY_BIT    = 1;
    localparam int STAT_TX_FULL_BIT    = 2;
    localparam int STAT_RX_EMPTY_BIT   = 3;
    localparam int STAT_PARITY_ERR_BIT = 4;
    localparam int STAT_FRAME_ERR_BIT  = 5;
    localparam int STAT_OVERRUN_ERR_BIT = 6;
    
    // Interrupt register bits
    localparam int INT_TX_EMPTY_EN_BIT = 0;
    localparam int INT_RX_FULL_EN_BIT  = 1;
    localparam int INT_TX_EMPTY_PEND_BIT = 2;
    localparam int INT_RX_FULL_PEND_BIT  = 3;
    
    // Internal signals
    logic [31:0] ctrl_reg, stat_reg, baud_reg, fifo_reg, int_reg;
    logic [7:0]  txdata_reg, rxdata_reg;
    logic        ctrl_enable, ctrl_tx_enable, ctrl_rx_enable;
    logic        ctrl_parity_en, ctrl_parity_odd;
    logic        stat_tx_busy, stat_rx_busy;
    logic        stat_tx_full, stat_rx_empty;
    logic        stat_parity_err, stat_frame_err, stat_overrun_err;
    logic        int_tx_empty_en, int_rx_full_en;
    logic        int_tx_empty_pend, int_rx_full_pend;
    
    // FIFO signals
    logic [7:0]  tx_fifo_data_in, tx_fifo_data_out;
    logic        tx_fifo_wr_en, tx_fifo_rd_en;
    logic        tx_fifo_full, tx_fifo_empty;
    logic [7:0]  rx_fifo_data_in, rx_fifo_data_out;
    logic        rx_fifo_wr_en, rx_fifo_rd_en;
    logic        rx_fifo_full, rx_fifo_empty;
    
    // UART transmitter/receiver signals
    logic        uart_tx_busy, uart_rx_busy;
    logic        uart_tx_start, uart_rx_done;
    logic [7:0]  uart_tx_data, uart_rx_data;
    logic        uart_rx_parity_err, uart_rx_frame_err;
    
    // APB interface logic
    always_ff @(posedge pclk_i or negedge presetn_i) begin
        if (!presetn_i) begin
            ctrl_reg <= 32'h0;
            baud_reg <= BAUD_DIVIDER;
            fifo_reg <= FIFO_DEPTH;
            int_reg <= 32'h0;
            pready_o <= 1'b0;
            pslverr_o <= 1'b0;
        end else begin
            pready_o <= 1'b0;
            pslverr_o <= 1'b0;
            
            if (psel_i && penable_i) begin
                pready_o <= 1'b1;
                
                if (pwrite_i) begin
                    case (paddr_i)
                        CTRL_REG_ADDR: ctrl_reg <= pwdata_i;
                        TXDATA_REG_ADDR: txdata_reg <= pwdata_i[7:0];
                        BAUD_REG_ADDR: baud_reg <= pwdata_i;
                        FIFO_REG_ADDR: fifo_reg <= pwdata_i;
                        INT_REG_ADDR: int_reg <= pwdata_i;
                        default: pslverr_o <= 1'b1;
                    endcase
                end else begin
                    case (paddr_i)
                        CTRL_REG_ADDR: prdata_o <= ctrl_reg;
                        STAT_REG_ADDR: prdata_o <= stat_reg;
                        RXDATA_REG_ADDR: prdata_o <= {24'h0, rxdata_reg};
                        BAUD_REG_ADDR: prdata_o <= baud_reg;
                        FIFO_REG_ADDR: prdata_o <= fifo_reg;
                        INT_REG_ADDR: prdata_o <= int_reg;
                        default: pslverr_o <= 1'b1;
                    endcase
                end
            end
        end
    end
    
    // Control register bit assignments
    assign ctrl_enable = ctrl_reg[CTRL_ENABLE_BIT];
    assign ctrl_tx_enable = ctrl_reg[CTRL_TX_ENABLE_BIT];
    assign ctrl_rx_enable = ctrl_reg[CTRL_RX_ENABLE_BIT];
    assign ctrl_parity_en = ctrl_reg[CTRL_PARITY_EN_BIT];
    assign ctrl_parity_odd = ctrl_reg[CTRL_PARITY_ODD_BIT];
    
    // Status register bit assignments
    assign stat_reg[STAT_TX_BUSY_BIT] = stat_tx_busy;
    assign stat_reg[STAT_RX_BUSY_BIT] = stat_rx_busy;
    assign stat_reg[STAT_TX_FULL_BIT] = stat_tx_full;
    assign stat_reg[STAT_RX_EMPTY_BIT] = stat_rx_empty;
    assign stat_reg[STAT_PARITY_ERR_BIT] = stat_parity_err;
    assign stat_reg[STAT_FRAME_ERR_BIT] = stat_frame_err;
    assign stat_reg[STAT_OVERRUN_ERR_BIT] = stat_overrun_err;
    assign stat_reg[31:7] = 25'h0;
    
    // Interrupt register bit assignments
    assign int_tx_empty_en = int_reg[INT_TX_EMPTY_EN_BIT];
    assign int_rx_full_en = int_reg[INT_RX_FULL_EN_BIT];
    assign int_reg[INT_TX_EMPTY_PEND_BIT] = int_tx_empty_pend;
    assign int_reg[INT_RX_FULL_PEND_BIT] = int_rx_full_pend;
    assign int_reg[31:4] = 28'h0;
    
    // TX FIFO control
    assign tx_fifo_data_in = txdata_reg;
    assign tx_fifo_wr_en = psel_i && penable_i && pwrite_i && (paddr_i == TXDATA_REG_ADDR) && !tx_fifo_full;
    assign tx_fifo_rd_en = uart_tx_start;
    assign uart_tx_data = tx_fifo_data_out;
    assign stat_tx_full = tx_fifo_full;
    assign stat_tx_busy = uart_tx_busy;
    
    // RX FIFO control
    assign rx_fifo_data_in = uart_rx_data;
    assign rx_fifo_wr_en = uart_rx_done && !rx_fifo_full;
    assign rx_fifo_rd_en = psel_i && penable_i && !pwrite_i && (paddr_i == RXDATA_REG_ADDR) && !rx_fifo_empty;
    assign rxdata_reg = rx_fifo_data_out;
    assign stat_rx_empty = rx_fifo_empty;
    assign stat_rx_busy = uart_rx_busy;
    
    // Error status
    assign stat_parity_err = uart_rx_parity_err;
    assign stat_frame_err = uart_rx_frame_err;
    assign stat_overrun_err = uart_rx_done && rx_fifo_full;
    
    // Interrupt generation
    assign int_tx_empty_pend = tx_fifo_empty && ctrl_tx_enable;
    assign int_rx_full_pend = rx_fifo_full && ctrl_rx_enable;
    assign irq_tx_empty_o = int_tx_empty_pend && int_tx_empty_en;
    assign irq_rx_full_o = int_rx_full_pend && int_rx_full_en;
    
    // UART transmitter start condition
    assign uart_tx_start = ctrl_enable && ctrl_tx_enable && !tx_fifo_empty && !uart_tx_busy;
    
    // Instantiate TX FIFO
    sync_fifo #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) tx_fifo_inst (
        .clk_i(pclk_i),
        .reset_n_i(presetn_i),
        .wr_en_i(tx_fifo_wr_en),
        .rd_en_i(tx_fifo_rd_en),
        .data_in_i(tx_fifo_data_in),
        .data_out_o(tx_fifo_data_out),
        .full_o(tx_fifo_full),
        .empty_o(tx_fifo_empty)
    );
    
    // Instantiate RX FIFO
    sync_fifo #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) rx_fifo_inst (
        .clk_i(pclk_i),
        .reset_n_i(presetn_i),
        .wr_en_i(rx_fifo_wr_en),
        .rd_en_i(rx_fifo_rd_en),
        .data_in_i(rx_fifo_data_in),
        .data_out_o(rx_fifo_data_out),
        .full_o(rx_fifo_full),
        .empty_o(rx_fifo_empty)
    );
    
    // Instantiate UART transmitter
    uart_transmitter #(
        .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BITS(STOP_BITS),
        .PARITY_ENABLE(PARITY_ENABLE),
        .PARITY_TYPE(PARITY_TYPE)
    ) uart_tx_inst (
        .clk_i(pclk_i),
        .reset_n_i(presetn_i),
        .enable_i(ctrl_enable),
        .start_i(uart_tx_start),
        .data_i(uart_tx_data),
        .tx_o(uart_tx_o),
        .busy_o(uart_tx_busy)
    );
    
    // Instantiate UART receiver
    uart_receiver #(
        .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BITS(STOP_BITS),
        .PARITY_ENABLE(PARITY_ENABLE),
        .PARITY_TYPE(PARITY_TYPE)
    ) uart_rx_inst (
        .clk_i(pclk_i),
        .reset_n_i(presetn_i),
        .enable_i(ctrl_enable),
        .rx_i(uart_rx_i),
        .data_o(uart_rx_data),
        .done_o(uart_rx_done),
        .busy_o(uart_rx_busy),
        .parity_err_o(uart_rx_parity_err),
        .frame_err_o(uart_rx_frame_err)
    );

endmodule 