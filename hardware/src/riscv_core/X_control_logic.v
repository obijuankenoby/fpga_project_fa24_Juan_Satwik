module X_CU(instruction, orange_sel, green_sel, br_un, br_eq, br_lt, a_sel, b_sel, rs2_sel, ALU_select, csr_sel, br_taken, IF_instruction, br_pred_taken, br_pred_correct, br_result);
	input [31:0] instruction, IF_instruction;
  input br_eq, br_lt, br_pred_taken;

	output reg br_un, b_sel;
	output reg [1:0] orange_sel, green_sel, a_sel, rs2_sel, csr_sel;
	output reg [3:0] ALU_select;
  output reg br_taken; // add br_taken logic
  output br_pred_correct;
  output br_result;

  wire [4:0] wf_rd, x_rs1, x_rs2;
  assign wf_rd = IF_instruction[11:7];
  assign x_rs1 = instruction[19:15];
  assign x_rs2 = instruction[24:20];

  // Determining if branch prediction is correct
  assign br_pred_correct = (br_pred_taken == br_taken);

  assign br_result = br_pred_taken && !br_taken;

  // ALU to ALU and MEM to ALU
  always @(*) begin
    if (IF_instruction[6:2] == `OPC_BRANCH_5 || IF_instruction[6:2] == `OPC_STORE_5 || wf_rd == 5'b0) begin // check if store necessary
      orange_sel = 0;
      green_sel = 0;
    end
    else if (IF_instruction[6:2] == `OPC_LOAD_5) begin
      if (wf_rd == x_rs1 && wf_rd == x_rs2) begin
        orange_sel = 2;
        green_sel = 2;
      end
      else if (wf_rd == x_rs1) begin
        orange_sel = 2;
        green_sel = 0;
      end
      else if (wf_rd == x_rs2) begin
        orange_sel = 0;
        green_sel = 2;
      end
      else begin
        orange_sel = 0;
        green_sel = 0;
      end
    end
    else begin
      if (wf_rd == x_rs1 && wf_rd == x_rs2) begin
        orange_sel = 1;
				green_sel = 1;
      end
      else if (wf_rd == x_rs1) begin // WF_rd == X_rs1
				orange_sel = 1;
				green_sel = 0;
			end
      else if (wf_rd == x_rs2) begin // WF_rd == X_rs2
				orange_sel = 0;
        green_sel = 1;
			end
      else begin
				orange_sel = 0;
				green_sel = 0;
			end
    end
  end

  // ALU to MEM and MEM to MEM
  always @(*) begin
    case (instruction[6:2])
      `OPC_STORE_5: begin
        if (IF_instruction[6:2] == `OPC_LOAD_5 && wf_rd == x_rs2 && wf_rd != 5'b0) begin
          rs2_sel = 2'd2; // MEM to MEM
        end
        else if (wf_rd != 5'b0 && wf_rd == x_rs2 && IF_instruction[6:2] != `OPC_STORE_5 && IF_instruction[6:2] != `OPC_BRANCH_5) begin
          rs2_sel = 2'd1; // ALU to MEM
        end
        else begin
          rs2_sel = 2'd0; // RS2_MUX2
        end
      end
      default: begin
        rs2_sel = 2'd0;
      end
    endcase
  end

  // MEM to MEM (is this correct?)
  always @(*) begin
    if (instruction[6:2] == `OPC_BRANCH_5 || instruction[6:2] == `OPC_JAL_5 || instruction[6:2] == `OPC_AUIPC_5) begin
      a_sel = 2'd1; // PC
    end
    else begin
      case(IF_instruction[6:2])
        `OPC_LOAD_5: begin
          if (instruction[6:2] == `OPC_STORE_5 && wf_rd == instruction[19:15] && wf_rd != 5'b0) begin
            a_sel = 2'd2; // MEM to MEM
          end
          else begin
            a_sel = 2'd0; // RS1_MUX2
          end
        end
        default: begin
          a_sel = 2'd0;
        end
      endcase
    end
  end
 
	always @(*) begin
		case(instruction[6:2])
			`OPC_ARI_RTYPE_5: begin // If R-type AKA type = 0
				br_un = 0;
				b_sel = 0;
				case(instruction[14:12])
          `FNC_ADD_SUB: begin // add 
            if (instruction[30] == `FNC2_SUB) ALU_select = 4'b0001;
            else ALU_select = 4'b0000;
          end
          `FNC_AND: ALU_select = 4'b0010; // and
          `FNC_OR: ALU_select = 4'b0011; // or
          `FNC_XOR: ALU_select = 4'b0100; // xor
          `FNC_SLL: ALU_select = 4'b0101; // sll
          `FNC_SRL_SRA: begin // srl and sra
            if (instruction[30] == `FNC2_SRA) ALU_select = 4'b0111; // sra
            else ALU_select = 4'b0110; // srl
          end
          `FNC_SLT: ALU_select = 4'b1000; // slt
          `FNC_SLTU: ALU_select = 4'b1001; // sltu
          default: begin
            ALU_select = 4'b0000;
          end
        endcase
				csr_sel = 0;
			end
			`OPC_ARI_ITYPE_5: begin // If I-type (I and I*)
				br_un = 0;
				b_sel = 1;
				case(instruction[14:12])
          `FNC_ADD_SUB: ALU_select = 4'b0000; // addi
          `FNC_AND: ALU_select = 4'b0010; // andi
          `FNC_OR: ALU_select = 4'b0011; // ori
          `FNC_XOR: ALU_select = 4'b0100; // xori
          `FNC_SLL: ALU_select = 4'b0101; // slli
          `FNC_SRL_SRA: begin
            if (instruction[30] == `FNC2_SRL) ALU_select = 4'b0110; // srli
            else ALU_select = 4'b0111; // srai
          end
          `FNC_SLT: ALU_select = 4'b1000; // slti
          `FNC_SLTU: ALU_select = 4'b1001; // sltiu
        endcase
				csr_sel = 0;
			end
      `OPC_LOAD_5: begin // load (I type)
				br_un = 0;
				b_sel = 1;
        ALU_select = 4'b0000;
        csr_sel = 0;
      end
      `OPC_STORE_5: begin // S type
				br_un = 0;
				b_sel = 1;
				ALU_select = 0;
				csr_sel = 0;
      end
			`OPC_BRANCH_5: begin // B-type
        if (instruction[14:12] == 3'b111 || instruction[14:12] == 3'b110) br_un = 1;
        else br_un = 0;
				b_sel = 1;
				ALU_select = 0;
				csr_sel = 0;
			end
      `OPC_JAL_5: begin // J type (jal)
				br_un = 0;
				b_sel = 1;
				ALU_select = 0;
				csr_sel = 0;
      end
      `OPC_JALR_5: begin // JALR (I type)
				br_un = 0;
				b_sel = 1;
				ALU_select = 0;
				csr_sel = 0;
      end
      `OPC_AUIPC_5: begin // AUIPC
				br_un = 0;
				b_sel = 1;
				ALU_select = 0;
				csr_sel = 0;
      end
      `OPC_LUI_5: begin // LUI
				br_un = 0;
				b_sel = 1;
				ALU_select = 4'b1010;
				csr_sel = 0;
      end
	    5'b11100: begin // CSRR
	  	  if (instruction[14:12] == 3'b001) begin // CSRRW
					br_un = 0;
					b_sel = 1;
					ALU_select = 0;
					csr_sel = 2;
				end
				else begin // CSRRWI
					br_un = 0;
					b_sel = 1;
					ALU_select = 0;
					csr_sel = 1;
				end
	  end
			default: begin
				br_un = 0;
				b_sel = 0;
				ALU_select = 0;
				csr_sel = 0;
			end
		endcase
	end

	always @(*) begin
		if (instruction[6:2] == `OPC_BRANCH_5) begin // If it is a branch inst
			case(instruction[14:12])
				`FNC_BEQ: begin // beq
					if (br_eq) br_taken = 1;
					else br_taken = 0;
				end
				`FNC_BGE: begin // bge
					if (!br_lt || br_eq) br_taken = 1;
					else br_taken = 0;
				end
				`FNC_BGEU: begin // bgeu
					if (!br_lt || br_eq) br_taken = 1;
					else br_taken = 0;
				end
				`FNC_BLT: begin // blt
					if (br_lt) br_taken = 1;
					else br_taken = 0;
				end
				`FNC_BLTU: begin // bltu
					if (br_lt) br_taken = 1;
					else br_taken = 0;
				end
				`FNC_BNE: begin // bne
					if (!br_eq) br_taken = 1;
					else br_taken = 0;
				end
			endcase
		end
    else br_taken = 0;
	end
endmodule
