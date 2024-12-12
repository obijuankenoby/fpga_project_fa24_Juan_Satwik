`include "opcode.vh"
// IO module
module IO_MEMORY_MAP #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC = 32'h4000_0000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input rst,
    input serial_in,
    input [31:0] instruction,
    input [31:0] INST_uart_lw,
    input [31:0] instruction_D,
    input [31:0] addr,
    input [31:0] Addr_uart_lw,
    input [31:0] Addr_uart_sw,
    input [7:0] uart_tx_data_in,
    input br_pred_correct_X,
    output reg [31:0] uart_out,
    output serial_out
);
    // On-chip UART
    //// UART Receiver
    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    reg uart_rx_data_out_ready;
    //// UART Transmitter
    // wire [7:0] uart_tx_data_in;
    reg uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;
    uart #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) on_chip_uart (
        .clk(clk),
        .reset(rst),

        .serial_in(serial_in),
        .data_out(uart_rx_data_out),
        .data_out_valid(uart_rx_data_out_valid),
        .data_out_ready(uart_rx_data_out_ready),

        .serial_out(serial_out),
        .data_in(uart_tx_data_in),
        .data_in_valid(uart_tx_data_in_valid),
        .data_in_ready(uart_tx_data_in_ready)
    );

    // Cycle Counter
    reg [31:0] Cycle_counter = 0;
    always @(posedge clk) begin
        if (addr == 32'h80000018) Cycle_counter <= 0;
        else Cycle_counter <= Cycle_counter + 1;
    end

    // Instruction Counter
    reg [31:0] INST_counter = 0;
    always @(posedge clk) begin
        if (addr == 32'h80000018) INST_counter <= 0;
        else if (instruction == 32'b0000_0000_0000_0000_0000_0000_0001_0011) INST_counter <= INST_counter;
        else INST_counter <= INST_counter + 1;
    end

    // Total Branch Instructions
    reg [31:0] Branch_counter = 0;
    always @(posedge clk) begin
        if (addr == 32'h80000018) Branch_counter <= 0;
        else if (instruction_D[6:2] == `OPC_BRANCH_5) Branch_counter <= Branch_counter + 1;
        else Branch_counter <= Branch_counter;
    end

    // Correct Predictions
    reg [31:0] Correct_pred_counter = 0;
    always @(posedge clk) begin
        if (addr == 32'h80000018) Correct_pred_counter <= 0;
        else if (instruction_D[6:2] == `OPC_BRANCH_5 && br_pred_correct_X) Correct_pred_counter <= Correct_pred_counter + 1;
        else Correct_pred_counter <= Correct_pred_counter;
    end

     always @(*) begin
        if (INST_uart_lw[6:2] == `OPC_LOAD_5 && Addr_uart_lw == 32'h80000004) begin
            uart_rx_data_out_ready = 1;
            uart_tx_data_in_valid = 0;
        end
        else if (instruction[6:2] == `OPC_STORE_5 && Addr_uart_sw == 32'h80000008) begin
            uart_rx_data_out_ready = 0;
            uart_tx_data_in_valid = 1;
        end
        else begin
            uart_rx_data_out_ready = 0;
            uart_tx_data_in_valid = 0;
        end
    end

    always @(*) begin
        case(Addr_uart_lw)
            32'h80000000: uart_out = {30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready};
            32'h80000004: uart_out = {24'b0, uart_rx_data_out};
            32'h80000010: uart_out = Cycle_counter;
            32'h80000014: uart_out = INST_counter;
            32'h8000001c: uart_out = Branch_counter;
            32'h80000020: uart_out = Correct_pred_counter;
            default: begin
                uart_out = 32'h00000000;
            end
        endcase
    end

endmodule
