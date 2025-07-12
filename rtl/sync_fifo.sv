//=============================================================================
// Module Name: sync_fifo
//=============================================================================
// Description: Synchronous FIFO with configurable depth and data width.
//              Provides full/empty detection and overflow protection.
//
// Features:
// - Configurable data width and FIFO depth
// - Full/empty status flags
// - Overflow protection
// - Synchronous read/write operations
// - Gray code pointers for reliable status detection
//
// Author: shivaram@vyges.com
// License: Apache-2.0
//=============================================================================

module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH = 16
) (
    // Clock and Reset
    input  logic                    clk_i,
    input  logic                    reset_n_i,
    
    // Write Interface
    input  logic                    wr_en_i,
    input  logic [DATA_WIDTH-1:0]   data_in_i,
    output logic                    full_o,
    
    // Read Interface
    input  logic                    rd_en_i,
    output logic [DATA_WIDTH-1:0]   data_out_o,
    output logic                    empty_o
);

    // Local parameters
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);
    localparam int PTR_WIDTH = ADDR_WIDTH + 1;
    
    // Internal signals
    logic [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];
    logic [PTR_WIDTH-1:0]  wr_ptr, rd_ptr;
    logic [PTR_WIDTH-1:0]  wr_ptr_gray, rd_ptr_gray;
    logic [PTR_WIDTH-1:0]  wr_ptr_gray_sync, rd_ptr_gray_sync;
    logic                  full, empty;
    logic                  wr_valid, rd_valid;
    
    // Write and read valid signals
    assign wr_valid = wr_en_i && !full;
    assign rd_valid = rd_en_i && !empty;
    
    // Full and empty detection
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2], 
                                   rd_ptr_gray_sync[PTR_WIDTH-3:0]});
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync);
    
    // Output assignments
    assign full_o = full;
    assign empty_o = empty;
    assign data_out_o = fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];
    
    // FIFO memory write
    always_ff @(posedge clk_i) begin
        if (wr_valid) begin
            fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in_i;
        end
    end
    
    // Write pointer logic
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            wr_ptr <= '0;
            wr_ptr_gray <= '0;
        end else begin
            if (wr_valid) begin
                wr_ptr <= (wr_ptr == FIFO_DEPTH) ? '0 : wr_ptr + 1;
                wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
            end
        end
    end
    
    // Read pointer logic
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            rd_ptr <= '0;
            rd_ptr_gray <= '0;
        end else begin
            if (rd_valid) begin
                rd_ptr <= (rd_ptr == FIFO_DEPTH) ? '0 : rd_ptr + 1;
                rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
            end
        end
    end
    
    // Synchronize read pointer to write clock domain
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            rd_ptr_gray_sync <= '0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end
    
    // Synchronize write pointer to read clock domain (for future use)
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            wr_ptr_gray_sync <= '0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

endmodule 