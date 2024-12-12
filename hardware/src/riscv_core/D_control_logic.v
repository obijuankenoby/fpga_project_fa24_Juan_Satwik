module D_CU(instruction, pc, pc_thirty, nop_sel, orange_sel, green_sel, jalr, br_taken, IF_instruction, x_instruction, br_pred_correct);
	input [31:0] instruction, pc, IF_instruction, x_instruction;
  input jalr;
  input br_taken;
  input br_pred_correct;
  // input br_taken, jalr; need br_taken and jalr for later
	output reg orange_sel, green_sel;
  output pc_thirty, nop_sel;

	assign pc_thirty = pc[30];

  assign nop_sel = (jalr || (!br_pred_correct && (x_instruction[6:2] == `OPC_BRANCH_5))) ? 1 : 0;

  // 2 Cycle Hazard
  always @(*) begin
    if (IF_instruction[6:2] == `OPC_BRANCH_5 || IF_instruction[6:2] == `OPC_STORE_5) begin
      orange_sel = 0;
      green_sel = 0;
    end
    else begin
      if (IF_instruction[11:7] == 5'b0) begin
        orange_sel = 0;
        green_sel = 0;
      end 
      else if (IF_instruction[11:7] == instruction[19:15] && IF_instruction[11:7] == instruction[24:20]) begin
        orange_sel = 1;
        green_sel = 1;
      end
      else if (IF_instruction[11:7] == instruction[19:15]) begin
        orange_sel = 1;
        green_sel = 0;
      end
      else if (IF_instruction[11:7] == instruction[24:20]) begin
        orange_sel = 0;
        green_sel = 1;
      end
      else begin
        orange_sel = 0;
        green_sel = 0;
      end
    end
  end
endmodule
