`include "opcode.vh"

module ALU(
    input [3:0] alu_select,
    input [31:0] amux_output,
    input [31:0] bmux_output,
    output [31:0] result
);
    reg [31:0] result_reg;

    assign result = result_reg;

    always @(*) begin
        case (alu_select)
            4'b0000: result_reg = amux_output + bmux_output; // add
            4'b0001: result_reg = amux_output - bmux_output; // sub
            4'b0010: result_reg = amux_output & bmux_output; // and
            4'b0011: result_reg = amux_output | bmux_output; // or
            4'b0100: result_reg = amux_output ^ bmux_output; // xor
            4'b0101: result_reg = amux_output << bmux_output[4:0]; // sll
            4'b0110: result_reg = amux_output >> bmux_output[4:0]; // srl
            4'b0111: result_reg = $signed(amux_output) >>> bmux_output[4:0]; // sra
            4'b1000: result_reg = ($signed(amux_output) < $signed(bmux_output)) ? 1 : 0; // slt
            4'b1001: result_reg = (amux_output < bmux_output) ? 1 : 0; // sltu
            4'b1010: result_reg = bmux_output;
            default: result_reg = 0;
        endcase
    end
endmodule
