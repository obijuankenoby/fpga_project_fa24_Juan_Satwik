include "opcode.v";

module immgen(
    input [31:0] instruction,
    output [31:0] imm
);

    reg [31:0] imm_reg;

    assign imm = imm_reg;


    always @(*) begin
        imm_reg = 32'b0;
        case (instruction[6:0])
            OPC_LUI, OPC_AUIPC:
                //U-type instructions
                imm_reg = {{12{instruction[31]}}, instruction[31:12]};

            OPC_ARI_ITYPE, OPC_LOAD, OPC_JALR:
                //I*-type instructions
                if ((instruction[14:12] == FNC_SLL) || 
                (instruction[14:12] == FNC_SRL) || 
                (instruction[14:12] == FNC_SRA)) begin
                    imm_reg = {27'b0, instruction[24:20] & 5'b11111};
                    //use a 5 bit mask with our instruction for immediate
                end
                else begin
                //I-type instructions
                    imm_reg = {{20{instruction[31]}}, instruction[31:20]};
                end
            OPC_STORE:
                //S-type instructions
                imm_reg = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            OPC_BRANCH:
                //B-type instructions
                imm_reg = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            OPC_JAL:
                //J-type instructions
                imm_reg = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            OPC_CSR:
                //CSR-type instructions
                imm_reg = {27'b0 ,instruction[19:15]};
            default:
                imm_reg = 32'b0;
        endcase
    end