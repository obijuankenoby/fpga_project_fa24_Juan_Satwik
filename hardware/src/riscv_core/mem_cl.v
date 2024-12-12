`include "opcode.vh"
// IO module
module MEM_CL (
    input [31:0] INST_X,
    input [31:0] ALU_out,
    output reg [3:0] dmem_we,
    output reg [3:0] imem_wea
);
    // DMEM WE
	always @(*) begin
		if (INST_X[6:2] == `OPC_STORE_5) begin
			if (ALU_out[1:0] == 0) begin
				case(INST_X[14:12])
    				3'b000: dmem_we = 4'b0001; 
					3'b001: dmem_we = 4'b0011;
					3'b010: dmem_we = 4'b1111;
                    default: dmem_we = 4'b0000;
				endcase
			end
			else if (ALU_out[1:0] == 1 && INST_X[14:12] == 3'b000) begin
				dmem_we = 4'b0010;
			end
			else if (ALU_out[1:0] == 2) begin
				case(INST_X[14:12])
    				3'b000: dmem_we = 4'b0100; 
					3'b001: dmem_we = 4'b1100;
                    default: dmem_we = 4'b0000;
				endcase
			end
			else if (ALU_out[1:0] == 3 && INST_X[14:12] == 3'b000) begin
				dmem_we = 4'b1000;
			end
            else dmem_we = 4'b0000;
		end
        else dmem_we = 4'b0000;
	end

    // IMEM WEA
    always @(*) begin
		if (INST_X[6:2] == `OPC_STORE_5) begin
			if (ALU_out[1:0] == 0) begin
				case(INST_X[14:12])
    				3'b000: imem_wea = 4'b0001; 
					3'b001: imem_wea = 4'b0011;
					3'b010: imem_wea = 4'b1111;
                    default: imem_wea = 4'b0000;
				endcase
			end
			else if (ALU_out[1:0] == 1 && INST_X[14:12] == 3'b000) begin
				imem_wea = 4'b0010;
			end
			else if (ALU_out[1:0] == 2) begin
				case(INST_X[14:12])
    				3'b000: imem_wea = 4'b0100;
					3'b001: imem_wea = 4'b1100;
                    default: imem_wea = 4'b0000;
				endcase
			end
			else if (ALU_out[1:0] == 3 && INST_X[14:12] == 3'b000) begin
				imem_wea = 4'b1000;
			end
            else imem_wea = 4'b0000;
		end
        else imem_wea = 4'b0000;
	end

endmodule
