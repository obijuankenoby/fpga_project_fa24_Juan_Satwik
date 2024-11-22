include "opcodes.v";
module alu(
    input [31:0] instruction,
    input [31:0] amux_output,
    input [31:0] bmux_output,
    output [31:0] result
);

    reg [6:0] opcode;
    reg [6:0] funct7;
    reg [2:0] funct3;
    reg [31:0] result_reg;

    assign result = result_reg;

    always @(*) begin
        opcode = instruction[6:0];
        funct7 = instruction[31:25];
        funct3 = instruction[14:12];

        result_reg = 32'b0;

        case (opcode)
            OPC_ARI_RTYPE, OPC_ARI_ITYPE: begin
                case (funct3)
                    FUNCT3_ADD: result_reg = (funct7 == FUNCT7_SUB) ? amux_output - bmux_output : amux_output + bmux_output;
                    FUNCT3_SLL: result_reg = amux_output << bmux_output[4:0]; // We can only shift by 32 bits, so just take bottom 5 bits to be safe
                    FUNCT3_SLT: result_reg = ($signed(amux_output) < $signed(bmux_output)) ? 1 : 0;
                    FUNCT3_SLTU: result_reg = (amux_output < bmux_output) ? 1 : 0;
                    FUNCT3_XOR: result_reg = amux_output ^ bmux_output;
                    FUNCT3_SRL: result_reg = (funct7 == FUNCT7_SRA) ? $signed(amux_output) >>> bmux_output[4:0] : amux_output >> bmux_output[4:0];
                    FUNCT3_OR: result_reg = amux_output | bmux_output;
                    FUNCT3_AND: result_reg = amux_output & bmux_output;
                    default: result_reg = 32'b0;
                endcase
            end

            OPC_LUI: result_reg = bmux_output << 12;

            OPC_AUIPC: result_reg = amux_output + (bmux_output << 12);

            OPC_LOAD, OPC_STORE, OPC_BRANCH, OPC_JAL, OPC_JALR:
                // ED said that the compiler will provide offset from label for us, so no need to directly calculate or retreive it
                result_reg = amux_output + bmux_output;

            default:
                result_reg = 32'b0; // NOP for unsupported opcodes
        endcase
    end
endmodule