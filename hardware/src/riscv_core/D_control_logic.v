module D_CONTROL_LOGIC(instruction, IF_instruction, X_instruction, PC, PC30, NOP_select, hazard1, hazard2, jalr, br_taken, br_pred_correct);
	input [31:0] instruction, IF_instruction, X_instruction, PC;
  input jalr, br_taken, br_pred_correct;

	output reg hazard1, hazard2;
  output PC30, NOP_select;


	assign PC30 = PC[30];
  assign NOP_select = (jalr || (!br_pred_correct && (X_instruction[6:2] == `OPC_BRANCH_5))) ? 1 : 0;

  // 2 Cycle Hazard
  always @(*) begin
    if (IF_instruction[6:2] == `OPC_BRANCH_5 || IF_instruction[6:2] == `OPC_STORE_5) begin
      hazard1 = 0;
      hazard2 = 0;
    end
    else begin
      if (IF_instruction[11:7] == 5'b0) begin
        hazard1 = 0;
        hazard2 = 0;
      end 
      else if (IF_instruction[11:7] == instruction[19:15] && IF_instruction[11:7] == instruction[24:20]) begin
        hazard1 = 1;
        hazard2 = 1;
      end
      else if (IF_instruction[11:7] == instruction[19:15]) begin
        hazard1 = 1;
        hazard2 = 0;
      end
      else if (IF_instruction[11:7] == instruction[24:20]) begin
        hazard1 = 0;
        hazard2 = 1;
      end
      else begin
        hazard1 = 0;
        hazard2 = 0;
      end
    end
  end
endmodule
