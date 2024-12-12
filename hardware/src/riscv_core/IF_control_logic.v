module IF_CONTROL_LOGIC(rst, instruction, x_instruction, wb_select, pc_select, mem_mask_select, rf_we, jal, jalr, br_taken, br_pred_correct);
  input rst, jal, jalr, br_taken, br_pred_correct;
	input [31:0] instruction, x_instruction;
	output reg rf_we;
  output reg [1:0] wb_select;
	output reg [2:0] mem_mask_select, pc_select;

  always @(*) begin
    if (rst) pc_select = 0;
    else if (jal) pc_select = 1;
    else if (jalr) pc_select = 3;
    else if (!br_pred_correct && (x_instruction[6:2] == `OPC_BRANCH_5)) pc_select = 3;
    else pc_select = 2;
  end
 
	always @(*) begin
		case(instruction[6:2]) // R
      `OPC_ARI_RTYPE_5: begin
				mem_mask_select = 0;
				wb_select = 1;
        rf_we = 1;
      end
      `OPC_ARI_ITYPE_5: begin // I
				mem_mask_select = 0;
				wb_select = 1;
        rf_we = 1;
      end
      `OPC_LOAD_5: begin 
				wb_select = 0;
        rf_we = 1;
        case(instruction[14:12])
          `FNC_LB: mem_mask_select = 3'b100; // lb
          `FNC_LBU: mem_mask_select = 3'b011; // lbu
          `FNC_LH: mem_mask_select = 3'b010; // lh
          `FNC_LHU: mem_mask_select = 3'b001; // lhu
          `FNC_LW: mem_mask_select = 3'b000; // lw
          default: begin
            mem_mask_select = 3'b000;
          end
        endcase
      end
      `OPC_STORE_5: begin // S-type
				mem_mask_select = 0;
				wb_select = 0;
        rf_we = 0;
      end
      `OPC_BRANCH_5: begin // B-type
        mem_mask_select = 0;
        wb_select = 0;
        rf_we = 0;
      end
			`OPC_JAL_5: begin // J-Type
        mem_mask_select = 0;
        wb_select = 2;
        rf_we = 1;
      end
      `OPC_JALR_5: begin // JALR
        mem_mask_select = 0;
        wb_select = 2;
        rf_we = 1;
      end
      `OPC_AUIPC_5: begin // U (AUIPC) Type
        mem_mask_select = 0;
        wb_select = 1;
        rf_we = 1;
      end
      `OPC_LUI_5: begin // U (LUI) Type
        mem_mask_select = 0;
        wb_select = 1;
        rf_we = 1;
      end
	    7'b11100: begin // CSRR
        mem_mask_select = 0;
        wb_select = 0;
        rf_we = 0;
	  end
			default: begin
				mem_mask_select = 0;
				wb_select = 0;
        rf_we = 0;
			end
		endcase
	end
endmodule
