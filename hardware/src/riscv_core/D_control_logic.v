module D_CU(instruction, pc, pc_thirty, nop_sel, orange_sel, green_sel, jalr, br_taken, wf_instruction);
	input [31:0] instruction, pc, wf_instruction;
  input jalr;
  input br_taken;
  // input br_taken, jalr; need br_taken and jalr for later
	output reg orange_sel, green_sel;
  output nop_sel, pc_thirty;

	assign pc_thirty = pc[30];

  assign nop_sel = (jalr || br_taken) ? 1 : 0;

  // 2 Cycle Hazard
  always @(*) begin
    if (wf_instruction[6:2] == `OPC_BRANCH_5 || wf_instruction[6:2] == `OPC_STORE_5) begin
      orange_sel = 0;
      green_sel = 0;
    end
    else begin
      if (wf_instruction[11:7] == 5'b0) begin
        orange_sel = 0;
        green_sel = 0;
      end 
      else if (wf_instruction[11:7] == instruction[19:15] && wf_instruction[11:7] == instruction[24:20]) begin
        orange_sel = 1;
        green_sel = 1;
      end
      else if (wf_instruction[11:7] == instruction[19:15]) begin
        orange_sel = 1;
        green_sel = 0;
      end
      else if (wf_instruction[11:7] == instruction[24:20]) begin
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
