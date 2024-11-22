include "opcodes.v";

module regfile(
    input clk,
    input we,
    input [4:0] write_addr, a_addr, b_addr,
    input [31:0] write_back,
    output [31:0] a_data, b_data
);

    reg [31:0] register [31:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            register[i] = 32'b0;
        end
    end

    assign a_data = (a_addr == 5'b0) ? 32'b0 : register[a_addr];
    assign b_data = (b_addr == 5'b0) ? 32'b0 : register[b_addr];

    always @(posedge clk) begin
        if (we && (write_addr != 5'b0)) begin
            register[write_addr] <= write_back;
        end
    end