module WF_CU(rst, instruction, rf_we, wb_sel, ldx_sel, pc_sel, br_taken, jal, jalr);
  // needs branch logic, jalr, and jal (as inputs)
  input rst;
  input jal;
  input jalr;
	input [31:0] instruction;
  input br_taken;
	output reg rf_we;
  output reg [1:0] wb_sel;
	output reg [2:0] ldx_sel, pc_sel;

  always @(*) begin
    if (rst) pc_sel = 0;
    // else if (instruction[6:2] == `OPC_BRANCH_5 || instruction[6:2] == `OPC_JALR_5) pc_sel = 4;
    else if (jal) pc_sel = 1;
    else if (jalr) pc_sel = 3;
    else if (br_taken) pc_sel = 3;
    else pc_sel = 2;
  end
 
	always @(*) begin
		case(instruction[6:2]) // R
      `OPC_ARI_RTYPE_5: begin
				ldx_sel = 0;
				wb_sel = 1;
        rf_we = 1;
      end
      `OPC_ARI_ITYPE_5: begin // I and I*
				ldx_sel = 0;
				wb_sel = 1;
        rf_we = 1;
      end
      `OPC_LOAD_5: begin // I type for load
				wb_sel = 0;
        rf_we = 1;
        case(instruction[14:12])
          `FNC_LB: ldx_sel = 3'b100; // lb
          `FNC_LBU: ldx_sel = 3'b011; // lbu
          `FNC_LH: ldx_sel = 3'b010; // lh
          `FNC_LHU: ldx_sel = 3'b001; // lhu
          `FNC_LW: ldx_sel = 3'b000; // lw
          default: begin
            ldx_sel = 3'b000;
          end
        endcase
      end
      `OPC_STORE_5: begin // S-type (store)
				ldx_sel = 0;
				wb_sel = 0;
        rf_we = 0;
      end
      `OPC_BRANCH_5: begin // B-type
        ldx_sel = 0;
        wb_sel = 0;
        rf_we = 0;
      end
			`OPC_JAL_5: begin // J-Type
        ldx_sel = 0;
        wb_sel = 2;
        rf_we = 1;
      end
      `OPC_JALR_5: begin // JALR
        ldx_sel = 0;
        wb_sel = 2;
        rf_we = 1;
      end
      `OPC_AUIPC_5: begin // U (AUIPC) Type
        ldx_sel = 0;
        wb_sel = 1;
        rf_we = 1;
      end
      `OPC_LUI_5: begin // U (LUI) Type
        ldx_sel = 0;
        wb_sel = 1;
        rf_we = 1;
      end
	    7'b11100: begin // CSRR
        ldx_sel = 0;
        wb_sel = 0;
        rf_we = 0;
	  end
			default: begin
				ldx_sel = 0;
				wb_sel = 0;
        rf_we = 0;
			end
		endcase
	end
endmodule
