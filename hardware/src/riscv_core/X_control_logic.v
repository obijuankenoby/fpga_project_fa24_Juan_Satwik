module X_CONTROL_LOGIC(instruction, IF_instruction, a_select, b_select, hazard1, hazard2, RS2_select, ALU_select, CSR_select, br_un, br_eq, br_lt, br_taken, br_pred_taken, br_pred_correct, br_result);
	input [31:0] instruction, IF_instruction;
  input br_eq, br_lt, br_pred_taken;

	output reg br_un, b_select;
	output reg [1:0] hazard1, hazard2, a_select, RS2_select, CSR_select;
	output reg [3:0] ALU_select;
  output reg br_taken;
  output br_pred_correct;
  output br_result;

  wire [4:0] IF_rd, x_rs1, x_rs2;
  assign IF_rd = IF_instruction[11:7];
  assign x_rs1 = instruction[19:15];
  assign x_rs2 = instruction[24:20];

  // Determining if branch prediction is correct
  assign br_pred_correct = (br_pred_taken == br_taken);

  assign br_result = br_pred_taken && !br_taken;

  // ALU to ALU and MEM to ALU
  always @(*) begin
    if (IF_instruction[6:2] == `OPC_BRANCH_5 || IF_instruction[6:2] == `OPC_STORE_5 || IF_rd == 5'b0) begin 
      hazard1 = 0;
      hazard2 = 0;
    end
    else if (IF_instruction[6:2] == `OPC_LOAD_5) begin
      if (IF_rd == x_rs1 && IF_rd == x_rs2) begin
        hazard1 = 2;
        hazard2 = 2;
      end
      else if (IF_rd == x_rs1) begin
        hazard1 = 2;
        hazard2 = 0;
      end
      else if (IF_rd == x_rs2) begin
        hazard1 = 0;
        hazard2 = 2;
      end
      else begin
        hazard1 = 0;
        hazard2 = 0;
      end
    end
    else begin
      if (IF_rd == x_rs1 && IF_rd == x_rs2) begin
        hazard1 = 1;
				hazard2 = 1;
      end
      else if (IF_rd == x_rs1) begin
				hazard1 = 1;
				hazard2 = 0;
			end
      else if (IF_rd == x_rs2) begin 
				hazard1 = 0;
        hazard2 = 1;
			end
      else begin
				hazard1 = 0;
				hazard2 = 0;
			end
    end
  end

  // ALU to MEM and MEM to MEM
  always @(*) begin
    case (instruction[6:2])
      `OPC_STORE_5: begin
        if (IF_instruction[6:2] == `OPC_LOAD_5 && IF_rd == x_rs2 && IF_rd != 5'b0) begin
          RS2_select = 2'd2; // MEM to MEM
        end
        else if (IF_rd != 5'b0 && IF_rd == x_rs2 && IF_instruction[6:2] != `OPC_STORE_5 && IF_instruction[6:2] != `OPC_BRANCH_5) begin
          RS2_select = 2'd1; // ALU to MEM
        end
        else begin
          RS2_select = 2'd0; // RS2 MUX2
        end
      end
      default: begin
        RS2_select = 2'd0;
      end
    endcase
  end

  // MEM to MEM
  always @(*) begin
    if (instruction[6:2] == `OPC_BRANCH_5 || instruction[6:2] == `OPC_JAL_5 || instruction[6:2] == `OPC_AUIPC_5) begin
      a_select = 2'd1; // PC
    end
    else begin
      case(IF_instruction[6:2])
        `OPC_LOAD_5: begin
          if (instruction[6:2] == `OPC_STORE_5 && IF_rd == instruction[19:15] && IF_rd != 5'b0) begin
            a_select = 2'd2; // MEM to MEM
          end
          else begin
            a_select = 2'd0; // RS1 MUX2
          end
        end
        default: begin
          a_select = 2'd0;
        end
      endcase
    end
  end
 
	always @(*) begin
		case(instruction[6:2])
			`OPC_ARI_RTYPE_5: begin
				br_un = 0;
				b_select = 0;
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
				CSR_select = 0;
			end
			`OPC_ARI_ITYPE_5: begin
				br_un = 0;
				b_select = 1;
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
				CSR_select = 0;
			end
      `OPC_LOAD_5: begin // load
				br_un = 0;
				b_select = 1;
        ALU_select = 4'b0000;
        CSR_select = 0;
      end
      `OPC_STORE_5: begin // S type
				br_un = 0;
				b_select = 1;
				ALU_select = 0;
				CSR_select = 0;
      end
			`OPC_BRANCH_5: begin // B-type
        if (instruction[14:12] == 3'b111 || instruction[14:12] == 3'b110) br_un = 1;
        else br_un = 0;
				b_select = 1;
				ALU_select = 0;
				CSR_select = 0;
			end
      `OPC_JAL_5: begin // J type
				br_un = 0;
				b_select = 1;
				ALU_select = 0;
				CSR_select = 0;
      end
      `OPC_JALR_5: begin // JALR
				br_un = 0;
				b_select = 1;
				ALU_select = 0;
				CSR_select = 0;
      end
      `OPC_AUIPC_5: begin // AUIPC
				br_un = 0;
				b_select = 1;
				ALU_select = 0;
				CSR_select = 0;
      end
      `OPC_LUI_5: begin // LUI
				br_un = 0;
				b_select = 1;
				ALU_select = 4'b1010;
				CSR_select = 0;
      end
	    5'b11100: begin // CSRR
	  	  if (instruction[14:12] == 3'b001) begin // CSRRW
					br_un = 0;
					b_select = 1;
					ALU_select = 0;
					CSR_select = 2;
				end
				else begin // CSRRWI
					br_un = 0;
					b_select = 1;
					ALU_select = 0;
					CSR_select = 1;
				end
	  end
			default: begin
				br_un = 0;
				b_select = 0;
				ALU_select = 0;
				CSR_select = 0;
			end
		endcase
	end

	always @(*) begin
		if (instruction[6:2] == `OPC_BRANCH_5) begin
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
