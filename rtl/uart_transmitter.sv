//=============================================================================
// Module Name: uart_transmitter
//=============================================================================
// Description: UART transmitter with configurable baud rate, data width,
//              stop bits, and parity support.
//
// Features:
// - Configurable baud rate generation
// - Configurable data width (5-8 bits)
// - Configurable stop bits (1-2 bits)
// - Optional parity generation (even/odd)
// - Busy status indication
// - Automatic transmission timing
//
// Author: shivaram@vyges.com
// License: Apache-2.0
//=============================================================================

module uart_transmitter #(
    parameter int CLOCK_FREQUENCY = 50_000_000,
    parameter int BAUD_RATE = 115_200,
    parameter int DATA_WIDTH = 8,
    parameter int STOP_BITS = 1,
    parameter bit PARITY_ENABLE = 1'b0,
    parameter string PARITY_TYPE = "even"
) (
    // Clock and Reset
    input  logic                    clk_i,
    input  logic                    reset_n_i,
    
    // Control Interface
    input  logic                    enable_i,
    input  logic                    start_i,
    input  logic [DATA_WIDTH-1:0]   data_i,
    
    // UART Interface
    output logic                    tx_o,
    output logic                    busy_o
);

    // Local parameters
    localparam int BAUD_DIVIDER = CLOCK_FREQUENCY / BAUD_RATE;
    localparam int BIT_COUNTER_WIDTH = $clog2(BAUD_DIVIDER);
    localparam int FRAME_BITS = DATA_WIDTH + STOP_BITS + (PARITY_ENABLE ? 1 : 0);
    localparam int FRAME_COUNTER_WIDTH = $clog2(FRAME_BITS);
    
    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        PARITY_BIT,
        STOP_BITS
    } tx_state_t;
    
    // Internal signals
    tx_state_t tx_state, tx_next_state;
    logic [BIT_COUNTER_WIDTH-1:0] bit_counter;
    logic [FRAME_COUNTER_WIDTH-1:0] frame_counter;
    logic [DATA_WIDTH-1:0] tx_data_reg;
    logic [FRAME_BITS-1:0] tx_frame;
    logic bit_tick;
    logic parity_bit;
    
    // Output assignments
    assign busy_o = (tx_state != IDLE);
    assign tx_o = (tx_state == IDLE) ? 1'b1 : tx_frame[0];
    
    // Baud rate counter
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            bit_counter <= '0;
            bit_tick <= 1'b0;
        end else begin
            if (tx_state == IDLE) begin
                bit_counter <= '0;
                bit_tick <= 1'b0;
            end else begin
                if (bit_counter == BAUD_DIVIDER - 1) begin
                    bit_counter <= '0;
                    bit_tick <= 1'b1;
                end else begin
                    bit_counter <= bit_counter + 1;
                    bit_tick <= 1'b0;
                end
            end
        end
    end
    
    // Frame counter
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            frame_counter <= '0;
        end else begin
            if (tx_state == IDLE) begin
                frame_counter <= '0;
            end else if (bit_tick) begin
                if (frame_counter == FRAME_BITS - 1) begin
                    frame_counter <= '0;
                end else begin
                    frame_counter <= frame_counter + 1;
                end
            end
        end
    end
    
    // Data register
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            tx_data_reg <= '0;
        end else begin
            if (start_i && tx_state == IDLE) begin
                tx_data_reg <= data_i;
            end
        end
    end
    
    // Parity calculation
    always_comb begin
        if (PARITY_ENABLE) begin
            if (PARITY_TYPE == "even") begin
                parity_bit = ^tx_data_reg;
            end else begin
                parity_bit = ~^tx_data_reg;
            end
        end else begin
            parity_bit = 1'b0;
        end
    end
    
    // Frame construction
    always_comb begin
        tx_frame = '1; // Default to idle state
        if (PARITY_ENABLE) begin
            tx_frame = {1'b1, {STOP_BITS{1'b1}}, parity_bit, tx_data_reg, 1'b0};
        end else begin
            tx_frame = {1'b1, {STOP_BITS{1'b1}}, tx_data_reg, 1'b0};
        end
    end
    
    // State machine
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            tx_state <= IDLE;
        end else begin
            tx_state <= tx_next_state;
        end
    end
    
    // Next state logic
    always_comb begin
        tx_next_state = tx_state;
        
        case (tx_state)
            IDLE: begin
                if (start_i && enable_i) begin
                    tx_next_state = START_BIT;
                end
            end
            
            START_BIT: begin
                if (bit_tick) begin
                    tx_next_state = DATA_BITS;
                end
            end
            
            DATA_BITS: begin
                if (bit_tick && (frame_counter == DATA_WIDTH - 1)) begin
                    if (PARITY_ENABLE) begin
                        tx_next_state = PARITY_BIT;
                    end else begin
                        tx_next_state = STOP_BITS;
                    end
                end
            end
            
            PARITY_BIT: begin
                if (bit_tick) begin
                    tx_next_state = STOP_BITS;
                end
            end
            
            STOP_BITS: begin
                if (bit_tick && (frame_counter == FRAME_BITS - 1)) begin
                    tx_next_state = IDLE;
                end
            end
            
            default: begin
                tx_next_state = IDLE;
            end
        endcase
    end

endmodule 