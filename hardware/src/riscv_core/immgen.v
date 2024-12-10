`include "opcode.vh"

module IMM_GEN(
    input [31:0] inst,
    output [31:0] imm
);

    reg [31:0] imm_reg;

    assign imm = imm_reg;


    always @(*) begin
        imm_reg = 32'b0;
        case (inst[6:2])
            `OPC_LOAD_5: imm_reg = {{20{inst[31]}}, inst[31:20]};
		`OPC_ARI_ITYPE_5: begin
			if (inst[14:12] == 3'b001 || inst[14:12] == 3'b101) imm_reg = {{27{1'b0}}, inst[24:20]};
			else imm_reg = {{20{inst[31]}}, inst[31:20]}; // I-type instruction
		end
		`OPC_STORE_5: imm_reg = {{20{inst[31]}}, inst[31:25], inst[11:7]}; // S-type instruction
		`OPC_BRANCH_5: imm_reg = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; // B-type instruction
		`OPC_JAL_5: imm_reg = {{20{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // J-type instruction
		`OPC_AUIPC_5: imm_reg = {inst[31:12], {12{1'b0}}}; // AUIPC instruction (what to do with bottom bits)
		`OPC_LUI_5: imm_reg = {inst[31:12], {12{1'b0}}}; // LUI instruction
		`OPC_JALR_5: imm_reg = {{20{inst[31]}}, inst[31:20]};
		5'b11100: imm_reg = {{27{1'b0}}, inst[19:15]}; // CSR
		default: imm_reg = 32'b0; // CSR
        endcase
    end
endmodule
